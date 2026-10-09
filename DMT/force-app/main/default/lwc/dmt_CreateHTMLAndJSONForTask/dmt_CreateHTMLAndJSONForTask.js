import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { getRecord, getFieldValue} from 'lightning/uiRecordApi';

// --- NATIVE LMS IMPORTS (Listening to sibling dmt_view_lwc) ---
import { subscribe, MessageContext, APPLICATION_SCOPE } from 'lightning/messageService';
import DMT_VIEW_DATA_CHANNEL from '@salesforce/messageChannel/DmtViewData__c';

// --- OMNISTUDIO PUBSUB IMPORT (Listening to FlexCard) ---
import pubsub from 'omnistudio/pubsub';

// --- APEX IMPORTS ---
import saveNativeSnapshots from '@salesforce/apex/DMT_ViewController.saveNativeSnapshots';
import getItemsToDisplay from '@salesforce/apex/DMT_ViewController.getItemsToDisplay';
import loadComponentsForView from '@salesforce/apex/DMT_ViewController.loadComponentsForView';
import getFeatures from '@salesforce/apex/DMT_ViewController.getFeatures';
import getUploadConfig from '@salesforce/apex/DMT_CoreDocuments_Controller.getUploadConfig';
import updateFileMetadata from '@salesforce/apex/DMT_CoreDocuments_Controller.updateFileMetadata';
import preparePdfAssets from '@salesforce/apex/DMT_PdfService.preparePdfAssets';
import generateFinalPdf from '@salesforce/apex/DMT_PdfService.generateFinalPdf';

// --- SCHEMA IMPORTS FOR REFERENTIAL INTEGRITY & CROSS-OBJECT FETCHING ---
import CASE_TYPE_FIELD from '@salesforce/schema/Case.DMT_LineOpportunity__c';
import CASE_OPP_NAME_FIELD from '@salesforce/schema/Case.opportunity_id__r.Name';
import OPP_EXTERNALID_FIELD from '@salesforce/schema/Case.opportunity_id__r.DMT_Opp_Id__c';
import CASE_LINE_NAME_FIELD from '@salesforce/schema/Case.DMT_Line__r.Name';
import LINE_EXTERNALID_FIELD from '@salesforce/schema/Case.DMT_Line__r.Line_Id__c';

const CASE_FIELDS = [CASE_TYPE_FIELD, CASE_OPP_NAME_FIELD, CASE_LINE_NAME_FIELD, OPP_EXTERNALID_FIELD, LINE_EXTERNALID_FIELD];
export default class dmt_CreateHTMLAndJSONForTask extends NavigationMixin(LightningElement) {

    @track isProcessingClosure = false;

    GENERATE_PDF_CLIENT_SIDE = false;
    CREATE_PDF_ON_PAYLOAD_RECEIVED = false;

    // --- CACHE STATE ---
    cachedHtml = null;
    cachedJson = null;
    cachedPdfBlob = null;
    pdfGenerationPromise = null;
    subscription = null;

    // --- CONTEXT VARIABLES ---
    @api recordId; // Primary FlexiPage Context
    @api skipNavigation = false; // If true, will not auto-navigate after processing and will emit an event instead
    _caseId;
    _taskId;
    _lineId;

    // --- DYNAMIC DATA ---
    _caseType; // 'L' or 'O'
    _relatedRecordName = 'Task';
    profitability = null; // bound to the hidden c-dmt_profitability_chart for self-fetch image capture

    @wire(MessageContext)
    messageContext;

    // --- CurrentPageReference Fallback ---
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            const urlRecordId = currentPageReference.state?.c__recordId || currentPageReference.attributes?.recordId;
            if(urlRecordId && !this.recordId) {
                this.recordId = urlRecordId;
                this._caseId = urlRecordId;
            } else if (this.recordId && !this._caseId) {
                this._caseId = this.recordId;
            }
        }
    }

    // --- WIRE TO GET CASE DATA FOR DYNAMIC NAMING/TYPE ---
    @wire(getRecord, { recordId: '$_caseId', fields: CASE_FIELDS })
    wiredCase({ error, data }) {
        if (data) {
            this._caseType = getFieldValue(data, CASE_TYPE_FIELD);
            const oppName = getFieldValue(data, CASE_OPP_NAME_FIELD);
            const lineName = getFieldValue(data, CASE_LINE_NAME_FIELD);

            if (this._caseType === 'O' && oppName) {
                this._relatedRecordName = oppName;
                this._lineId = getFieldValue(data, OPP_EXTERNALID_FIELD);
            } else if (this._caseType === 'L' && lineName) {
                this._relatedRecordName = lineName;
                this._lineId = getFieldValue(data, LINE_EXTERNALID_FIELD);
            }
        } else if (error) {
            console.error('[ORCHESTRATOR] Error fetching Case details:', error);
        }
    }

    connectedCallback() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                DMT_VIEW_DATA_CHANNEL,
                (message) => this.handleLmsViewDataLoaded(message),
                { scope: APPLICATION_SCOPE }
            );
        }

        pubsub.register('DmtTaskChannel', {
            taskClosed: this.handleFlexCardTaskClosed.bind(this)
        });
    }

    disconnectedCallback() {
        pubsub.unregister('DmtTaskChannel', { taskClosed: this.handleFlexCardTaskClosed.bind(this) });
    }

    // --- EVENT HANDLER 1: Native Data from Sibling ---
    handleLmsViewDataLoaded(message) {
        this.cachedHtml = message.htmlPayload;
        this.cachedJson = message.jsonPayload;

        // Pre-generate PDF server-side in background as soon as HTML arrives
        if (this.cachedHtml) {
            this.preGenerateServerPdfInBackground();
        }
    }

    // --- EVENT HANDLER 2: Trigger from FlexCard ---
    async handleFlexCardTaskClosed(message) {
        console.log('=== [EVENT RECEIVED] FlexCard Task/Case Closed ===');
        console.log('Payload from FlexCard:', JSON.stringify(message));
        this.isProcessingClosure = true;

        if (message.taskId) this._taskId = message.taskId;
        if (message.caseId) this._caseId = message.caseId;

        await this.processClosureSnapshots();
    }

    receivedFlexcardEvent = false;

    /**
     * Waits for the LMS data cache to be populated.
     * Polls every 500ms up to a maximum timeout (default 10s).
     * Resolves true when data is available, false on timeout.
     */
    waitForCacheData(timeoutMs = 10000) {
        return new Promise((resolve) => {
            // NOTE: only cachedHtml gates readiness. cachedJson (the legacy pdfmake-JSON
            // payload) is no longer produced by the renderer response at all since the
            // HTML-snapshot migration (DMT_ViewController.loadComponentsForView's resultMap
            // has no PDF/JSON key) — the PDF is built directly from cachedHtml via
            // DMT_PdfService, so requiring cachedJson here was gating on a field that can
            // never be truthy anymore.
            if (this.cachedHtml) {
                resolve(true);
                return;
            }
            const interval = 500;
            let elapsed = 0;
            const timer = setInterval(() => {
                elapsed += interval;
                if (this.cachedHtml) {
                    clearInterval(timer);
                    resolve(true);
                } else if (elapsed >= timeoutMs) {
                    clearInterval(timer);
                    resolve(false);
                }
            }, interval);
        });
    }
    // --- MAIN ORCHESTRATION LOGIC ---
    async processClosureSnapshots() {
        if (this.receivedFlexcardEvent) return;
        this.receivedFlexcardEvent = true;
        let snapshotsSaved = false;
        try {
            // Wait for the LMS data to arrive (handles race condition with dmt_view_lwc)
            let dataReady = await this.waitForCacheData();

            if (!dataReady || !this.cachedHtml) {
                // The sibling dmt_view_lwc never delivered data in time (remount, slow render,
                // or it never rendered for this record at all). Don't just give up — actively
                // fetch the view ourselves, the same way dmt_massive_snapshot_worker already
                // does successfully for the bulk-closure path, instead of depending on a
                // passively-received message that may never arrive.
                console.error('=== [CACHE MISS] No data from sibling after waiting. Attempting self-fetch fallback. ===');
                dataReady = await this.selfFetchViewData();
            }

            let htmlToSave = this.cachedHtml;
            // cachedJson (legacy pdfmake JSON) was deprecated in this same ticket (CIBGLOBALD-3731)
            // when renderers moved to HTML-only snapshots — it's never populated anymore, so it
            // must not gate this flow. Only used below as a best-effort, optional fallback payload.
            let jsonToProcess = this.cachedJson;

            if (!dataReady || !htmlToSave) {
                console.error('=== [FATAL ERROR] CACHE MISS: No HTML in memory after waiting and self-fetch fallback. ===');
                return;
            }

            // --- STEP 1: ALWAYS SAVE HTML NATIVELY ---
            await saveNativeSnapshots({
                taskId: this._taskId,
                htmlString: htmlToSave,
                jsonString: null,
                fileBlob: null
            });

            // --- STEP 2: TRY CORE DOCUMENTS ---
            console.log('[STEP 2] Attempting CoreDocs Upload...');
            await this.attemptPdfUploadWithFallback(jsonToProcess);
            if(!this.cachedPdfBlob) {
                await saveNativeSnapshots({
                    taskId: this._taskId,
                    htmlString: null,
                    jsonString: jsonToProcess,
                    fileBlob: null
                });
            }


            snapshotsSaved = true;
        } catch (error) {
            console.error('=== [FATAL ERROR] ORCHESTRATION CRASHED ===', JSON.stringify(error));
        } finally {
            if (snapshotsSaved) {
                console.log('=== Orchestration complete. Navigating user back to Case Tasks. ===');
                await new Promise(resolve => setTimeout(resolve, 1000));
                this.navigateToCaseTasks();
            } else {
                console.error('=== Snapshots NOT saved. Staying on page so the user can retry. ===');
                this.receivedFlexcardEvent = false;
                this.isProcessingClosure = false;
            }
        }
    }

    // --- Smart PDF Orchestrator (now uses server-side PDF) ---
    async attemptPdfUploadWithFallback(jsonString) {
        let pdfBlob;

        try {
            pdfBlob = this.cachedPdfBlob;

            if (pdfBlob) {
                console.info('[PDF] Using PRE-GENERATED cached server PDF Blob.');
            } else if (this.pdfGenerationPromise) {
                console.info('[PDF] Waiting for in-progress server PDF generation...');
                pdfBlob = await this.pdfGenerationPromise;
            } else {
                console.info('[PDF] No cached PDF. Generating server PDF on-demand...');
                pdfBlob = await this.generateServerPdf(this.cachedHtml);
            }

            // Attempt the upload
            if (pdfBlob) {
                await this.uploadToCoreDocuments(pdfBlob);
                console.info('[CORE DOCS] ✅ Success. PDF is in external vault.');
            }

        } catch (error) {
            // --- STEP 3: ONLY SAVE JSON IF STEP 2 FAILED ---
            console.error('[❌ CORE DOCS FAILED] Error Reason:', (error.body ? error.body.message : error.message));

            try {
                if (pdfBlob) {
                    //Guardado de PDF falló, pero al menos se generó el Blob. Intentamos guardar el PDF como archivo en Salesforce Files para no perderlo completamente.
                    const fallbackBlob = new Blob([pdfBlob], { type: 'application/pdf' });
                    await saveNativeSnapshots({
                        taskId: this._taskId,
                        htmlString: null,
                        jsonString: null,
                        fileBlob: fallbackBlob
                    });
                    console.info('[FALLBACK] ✅ PDF backup successfully saved to Salesforce Files.');

                }else if(!pdfBlob) {
                    // Se guarda HTMl y JSON en Salesforce Files como fallback mínimo para no perder toda la información textual, aunque el PDF se haya perdido.
                    await saveNativeSnapshots({
                        taskId: this._taskId,
                        htmlString: null,
                        jsonString: jsonString,
                        fileBlob: null
                    });
                    console.info('[FALLBACK] ✅ JSON backup successfully saved to Salesforce Files.');
                }
            } catch (fallbackError) {
                console.error('[CRITICAL] Native JSON fallback save failed!', fallbackError);
            }
        }
    }

    // --- INTEGRATION FETCH ---
    async uploadToCoreDocuments(pdfBlob) {
        const config = await getUploadConfig();

        let selectedDocType = 'CO-OF-00241'; // Default

        const dateStr = new Date().toISOString().replace(/T/, '_').replace(/\..+/, '').replace(/:/g, '-');
        const finalFileName = `${this._relatedRecordName} task completed on ${dateStr}.pdf`;

        const formData = new FormData();
        formData.append('file', pdfBlob, finalFileName);
        formData.append('folderId', this._taskId);
        formData.append('folderCode', this._taskId);

        const response = await fetch(config.endpoint, {
            method: 'POST',
            headers: config.headers,
            body: formData
        });

        if (!response.ok) {
            const errorBody = await response.text();
            console.error('[UPLOAD-FATAL] External system rejected the upload. Response Body:', errorBody);
            throw new Error(`HTTP Error: ${response.status} ${response.statusText} - ${errorBody}`);
        }

        const result = await response.json();

        if (result && result.data && result.data.fileId) {
            await updateFileMetadata({
                fileId: result.data.fileId,
                fileName: finalFileName,
                docType: selectedDocType,
                folderId: this._taskId
            });

        } else {
            throw new Error('Upload succeeded HTTP 200, but missing fileId in CoreDocuments JSON response payload.');
        }
    }

    // --- SELF-SUFFICIENT FALLBACK ---
    // Actively fetches the case view instead of passively waiting on the sibling
    // dmt_view_lwc's LMS publish, which can miss the window (remount, slow render,
    // or a page where dmt_view_lwc never renders in time for this record).
    async selfFetchViewData() {
        const caseId = this._caseId || this.recordId;
        if (!caseId) {
            console.error('[SELF-FETCH] No caseId available (both _caseId and recordId are empty) — cannot self-fetch.');
            return false;
        }

        try {
            console.log('[SELF-FETCH] Actively fetching view for case', caseId);
            const itemsResponse = await getItemsToDisplay({ recordOrLineId: caseId, objectApiName: 'Case' });
            if (!itemsResponse) {
                console.error('[SELF-FETCH] getItemsToDisplay returned empty response for', caseId);
                return false;
            }

            const parsedItemsResponse = JSON.parse(itemsResponse);
            const selectedItems = JSON.parse(parsedItemsResponse.items || '[]');
            const recordOrLineId = parsedItemsResponse.recordId || caseId;
            const viewType = parsedItemsResponse.viewType || 'Case';
            const recordTypeApiName = parsedItemsResponse.recordTypeApiName || 'Approval';
            const productId = parsedItemsResponse.productId || null;

            if (!selectedItems.length) {
                console.error('[SELF-FETCH] No selected items returned for case', caseId);
                return false;
            }

            const hasLimitVisual = selectedItems.some(item => item.component === 'Limit Visual');
            let imageData = null;

            if (hasLimitVisual) {
                const features = await getFeatures({ id: recordOrLineId });
                const chartInputs = this.buildChartInputs(features || [], recordTypeApiName);

                if (chartInputs.hasImage) {
                    const dataToPass = recordTypeApiName === 'DMT_Opportunity'
                        ? chartInputs.profitability
                        : chartInputs.allLimits;

                    imageData = await this.getImageB64(dataToPass, recordTypeApiName);

                    if (!imageData) {
                        console.error('[SELF-FETCH] Limit Visual requires chart images, but none could be generated for', caseId);
                        return false;
                    }
                }
            }

            const response = await loadComponentsForView({
                recordOrLineId,
                viewType,
                selectedItems: JSON.stringify(selectedItems),
                productId,
                itemsImg: imageData ? JSON.stringify(imageData) : null
            });

            const parsedView = response ? JSON.parse(response) : null;
            if (!parsedView) {
                console.error('[SELF-FETCH] loadComponentsForView returned empty response for', caseId);
                return false;
            }
            if (parsedView.error) {
                console.error('[SELF-FETCH] loadComponentsForView returned an error for', caseId, ':', parsedView.error);
                return false;
            }

            const html = parsedView.HTML || '';
            // No PDF/JSON key is returned by loadComponentsForView anymore (deprecated in
            // CIBGLOBALD-3731 alongside renderPdfJson) — kept as '' for the optional
            // last-resort text fallback in attemptPdfUploadWithFallback, never required.
            const json = '';

            if (!html) {
                console.error('[SELF-FETCH] Empty HTML returned for case', caseId);
                return false;
            }

            this.cachedHtml = html;
            this.cachedJson = json;
            console.log('[SELF-FETCH] ✅ View data self-fetched successfully for', caseId);
            return true;
        } catch (error) {
            console.error('[SELF-FETCH] ❌ Failed to self-fetch view data:', error && error.message ? error.message : error);
            return false;
        }
    }

    buildChartInputs(features, recordTypeApiName) {
        let profitabilityData = null;
        let hasImage = false;
        const allLimitsLocal = [];

        const profitabilityFeature = (features || []).find(f => f.name && f.name.includes('Profitability') && f.profitability);
        if (profitabilityFeature) {
            hasImage = true;
            profitabilityData = profitabilityFeature.profitability;
            this.profitability = profitabilityData;
        }

        for (const key in features) {
            const f = features[key];
            if (f && f.consumptionLimits !== undefined) {
                hasImage = true;
                const conditions = [];
                const currencies = [];
                const labels = [];
                const limitLights = [];
                const targets = [];
                const dataDraw = [];
                const dataUndrawnCommitted = [];
                const dataUndrawnUncommitted = [];
                const dataPendingAuthorized = [];
                const dataNewOpportunity = [];

                const toNum = value => {
                    const n = Number(value);
                    return Number.isFinite(n) ? n : 0;
                };

                (f.consumptionLimits || []).forEach(cl => {
                    if (cl && cl.stateName !== undefined) {
                        conditions.push(cl?.conditionDesc || '');
                        currencies.push(cl?.currencyId || '');
                        labels.push(cl?.limitDesc || '');
                        limitLights.push((cl?.stateName || 'GRAY').toUpperCase());

                        const cmtDisposed = toNum(cl?.amount?.cmtContDisposedAmount);
                        const uncmtDisposed = toNum(cl?.amount?.uncmtContDisposedAmount);

                        targets.push(toNum(cl?.amount?.currentApprovedAmount));
                        dataDraw.push(cmtDisposed + uncmtDisposed);
                        dataUndrawnCommitted.push(toNum(cl?.amount?.cmtContNonDspsAmount));
                        dataUndrawnUncommitted.push(toNum(cl?.amount?.uncmtContNonDspsAmount));
                        dataPendingAuthorized.push(toNum(cl?.amount?.authorizedRiskAmount));
                        dataNewOpportunity.push(toNum(cl?.amount?.notSignedTrConsumptionAmount));
                    }
                });

                const sections = ['Drawn', 'Undrawn committed', 'Undrawn uncommitted', 'Pending authorized', 'New Opportunity'];
                const datasets = [
                    { backgroundColor: 'rgba(4, 50, 99, 1)', data: dataDraw, hoverBackgroundColor: 'rgba(4, 50, 99, 1)', label: 'Drawn' },
                    { backgroundColor: 'rgba(20, 100, 165, 1)', data: dataUndrawnCommitted, hoverBackgroundColor: 'rgba(20, 100, 165, 1)', label: 'Undrawn committed' },
                    { backgroundColor: 'rgba(36, 150, 234, 1)', data: dataUndrawnUncommitted, hoverBackgroundColor: 'rgba(36, 150, 234, 1)', label: 'Undrawn uncommitted' },
                    { backgroundColor: 'rgba(45, 204, 205, 1)', data: dataPendingAuthorized, hoverBackgroundColor: 'rgba(45, 204, 205, 1)', label: 'Pending authorized' },
                    { backgroundColor: 'rgba(189, 189, 189, 1)', data: dataNewOpportunity, hoverBackgroundColor: 'rgba(189, 189, 189, 1)', label: 'New Opportunity' }
                ];

                const limitsObj = {
                    conditions,
                    currencies,
                    datasets,
                    labels,
                    limitLights,
                    originCurrency: currencies.find(Boolean) || '',
                    sections,
                    targetColor: 'red',
                    targets
                };

                allLimitsLocal.push({
                    format: 'JPEG',
                    quality: 0.7,
                    wrapperData: limitsObj
                });
            }
        }

        return {
            allLimits: allLimitsLocal.length ? allLimitsLocal : null,
            hasImage,
            profitability: profitabilityData,
            recordTypeApiName
        };
    }

    async getImageB64(limit, recordTypeApiName) {
        try {
            await this.waitNextTick();

            const image64AllLocal = [];

            if (recordTypeApiName === 'DMT_Opportunity') {
                const chartComponent = this.template.querySelector('c-dmt_profitability_chart');
                if (!chartComponent || !limit) {
                    return '';
                }

                chartComponent.profitability = limit;
                await this.waitNextTick();

                const result = await chartComponent.getChartImage(300, 100);
                if (result) {
                    image64AllLocal.push({ imgB64: result });
                }
            } else {
                const imageGenerator = this.template.querySelector('c-dmt_subfeature_chart');
                if (!imageGenerator || !Array.isArray(limit) || !limit.length) {
                    return '';
                }

                const promises = limit.map(async item => {
                    try {
                        return await imageGenerator.getChartImage(200, 100, JSON.parse(JSON.stringify(item)));
                    } catch (e) {
                        console.error('[SELF-FETCH] Chart image generation failed:', e);
                        return null;
                    }
                });

                const resolved = await Promise.all(promises);
                resolved.forEach(result => {
                    if (result) {
                        image64AllLocal.push({ imgB64: result });
                    }
                });
            }

            return image64AllLocal.length > 0 ? image64AllLocal : '';
        } catch (error) {
            console.error('[SELF-FETCH] getImageB64 failed:', error);
            return '';
        }
    }

    waitNextTick() {
        return new Promise(resolve => setTimeout(resolve, 0));
    }

    // --- Background Worker (server-side) ---
    async preGenerateServerPdfInBackground() {
        try {
            console.log('[BACKGROUND] Starting server-side PDF pre-generation...');
            this.pdfGenerationPromise = await this.generateServerPdf(this.cachedHtml);
            this.cachedPdfBlob =  this.pdfGenerationPromise;
            console.info('[BACKGROUND] ✅ Server PDF pre-generated and cached.');
        } catch (error) {
            console.error('[BACKGROUND] ❌ Failed to pre-generate server PDF.', error);
            this.cachedPdfBlob = null;
            this.pdfGenerationPromise = null;
        }
    }

    /**
     * Genera el PDF server-side en dos transacciones Apex:
     *   TX1 → Persiste imágenes base64 como Documents temporales.
     *   TX2 → Blob.toPdf() resuelve las URLs y limpia los Documents temporales.
     *
     * @param {String} rawHtml - HTML que puede contener src="data:image/..."
     * @returns {Promise<Blob>} PDF como Blob listo para upload
     */
    async generateServerPdf(rawHtml) {
        if (!rawHtml) {
            throw new Error('[PDF] No HTML provided.');
        }

        // ── TX 1: persistir imágenes ────────────────────────────
        console.log('[PDF] ⏳ TX1 — Persisting inline images...');
        const prep = await preparePdfAssets({ originalHtml: rawHtml });
        console.log('[PDF] ✅ TX1 — Temp docs created:', prep.documentIds?.length || 0);

        // ── TX 2: generar PDF (Documents ya commiteados) ────────
        console.log('[PDF] ⏳ TX2 — Generating PDF...');
        const pdfBase64 = await generateFinalPdf({
            finalHtml: prep.modifiedHtml,
            docIds: prep.documentIds || []
        });
        console.info('[PDF] ✅ TX2 — PDF generated. Base64 size:', pdfBase64?.length || 0);

        // ── Convertir base64 → Blob ─────────────────────────────
        const byteChars = atob(pdfBase64);
        const byteArray = new Uint8Array(byteChars.length);
        for (let i = 0; i < byteChars.length; i++) {
            byteArray[i] = byteChars.charCodeAt(i);
        }

        const pdfBlob = new Blob([byteArray], { type: 'application/pdf' });
        console.log('[PDF] Final PDF Blob size (bytes):', pdfBlob.size);
        return pdfBlob;
    }

    // --- NAVIGATION ---
    navigateToCaseTasks() {
        const targetUrl = '/lightning/n/Case_Tasks';
        window.location.href = targetUrl;
    }
}