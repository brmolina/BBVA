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
            if (this.cachedHtml && this.cachedJson) {
                resolve(true);
                return;
            }
            const interval = 500;
            let elapsed = 0;
            const timer = setInterval(() => {
                elapsed += interval;
                if (this.cachedHtml && this.cachedJson) {
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
            const dataReady = await this.waitForCacheData();

            let htmlToSave = this.cachedHtml;
            let jsonToProcess = this.cachedJson;

            if (!dataReady || !htmlToSave || !jsonToProcess) {
                console.error('=== [FATAL ERROR] CACHE MISS: No data in memory after waiting. ===');
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