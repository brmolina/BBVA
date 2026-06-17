import { LightningElement, api, track } from 'lwc';
import getItemsToDisplay from '@salesforce/apex/DMT_ViewController.getItemsToDisplay';
import loadComponentsForView from '@salesforce/apex/DMT_ViewController.loadComponentsForView';
import getFeatures from '@salesforce/apex/DMT_ViewController.getFeatures';
import saveNativeSnapshots from '@salesforce/apex/DMT_ViewController.saveNativeSnapshots';
import getUploadConfig from '@salesforce/apex/DMT_CoreDocuments_Controller.getUploadConfig';
import updateFileMetadata from '@salesforce/apex/DMT_CoreDocuments_Controller.updateFileMetadata';
import preparePdfAssets from '@salesforce/apex/DMT_PdfService.preparePdfAssets';
import generateFinalPdf from '@salesforce/apex/DMT_PdfService.generateFinalPdf';

export default class Dmt_massive_snapshot_worker extends LightningElement {
    @api showPreview = false;

    @track activeCaseId = null;
    @track statusMessage = 'Idle';
    @track isWorking = false;
    @track previewTitle = 'No Case view generated yet';

    profitability = null;

    _cacheByCaseId = {};
    _pdfByCaseId = {};
    _activeTaskId = null;
    _relatedRecordName = 'Task';
    _lastPreviewHtml = '';
    _previewPaintQueued = false;

    get hasPreviewHtml() {
        return !!this._lastPreviewHtml;
    }

    renderedCallback() {
        this.paintPreviewHtml();
    }

    @api
    hasCachedView(caseId) {
        const key = this.normalizeCaseId(caseId);
        return !!(key && this._cacheByCaseId[key]?.html);
    }

    @api
    getCachedView(caseId) {
        const key = this.normalizeCaseId(caseId);
        return key ? this._cacheByCaseId[key] : null;
    }

    @api
    async generateView(params) {
        const caseId = this.normalizeCaseId(params?.caseId || params);

        if (!caseId || !caseId.startsWith('500')) {
            throw new Error(`[MASSIVE SNAPSHOT WORKER] Expected Case.Id but received ${caseId}`);
        }

        if (this._cacheByCaseId[caseId]?.html) {
            this.activeCaseId = caseId;
            this.statusMessage = `View already generated for ${caseId}`;
            this.previewTitle = `Cached Case view: ${caseId}`;
            this.setPreviewHtml(this._cacheByCaseId[caseId].html);
            return this._cacheByCaseId[caseId];
        }

        this.activeCaseId = caseId;
        this.statusMessage = `Generating view for ${caseId}`;
        this.previewTitle = `Generating Case view: ${caseId}`;
        this.isWorking = true;
        this.setPreviewHtml('<div class="slds-p-around_medium slds-text-color_weak">Generating Case view...</div>');

        try {
            const generated = await this.generateCaseViewHtml(caseId);

            if (!generated?.html) {
                throw new Error(`[MASSIVE SNAPSHOT WORKER] Empty HTML returned for Case ${caseId}`);
            }

            this._cacheByCaseId[caseId] = {
                html: generated.html,
                json: generated.json || ''
            };

            this.preGenerateServerPdfInBackground(caseId, generated.html);

            this.statusMessage = `Generated view for ${caseId}`;
            this.previewTitle = `Generated Case view: ${caseId}`;
            this.setPreviewHtml(generated.html);

            return this._cacheByCaseId[caseId];
        } catch (error) {
            this.statusMessage = `View generation failed for ${caseId}`;
            this.previewTitle = `Generation failed: ${caseId}`;
            const message = error?.body?.message || error?.message || String(error);
            this.setPreviewHtml(`<div class="slds-p-around_medium slds-text-color_error">${this.escapeHtml(message)}</div>`);
            throw error;
        } finally {
            this.isWorking = false;
        }
    }

    async generateCaseViewHtml(caseId) {
        console.log('[MASSIVE SNAPSHOT WORKER] Loading view metadata', { caseId });

        const itemsResponse = await getItemsToDisplay({
            recordOrLineId: caseId,
            objectApiName: 'Case'
        });

        if (!itemsResponse) {
            throw new Error(`[MASSIVE SNAPSHOT WORKER] getItemsToDisplay returned empty response for Case ${caseId}`);
        }

        const parsedItemsResponse = JSON.parse(itemsResponse);
        const selectedItems = JSON.parse(parsedItemsResponse.items || '[]');
        const recordOrLineId = parsedItemsResponse.recordId || caseId;
        const viewType = parsedItemsResponse.viewType || 'Case';
        const recordTypeApiName = parsedItemsResponse.recordTypeApiName || 'Approval';
        const productId = parsedItemsResponse.productId || null;

        console.log('[MASSIVE SNAPSHOT WORKER] View metadata loaded', {
            caseId,
            recordOrLineId,
            viewType,
            recordTypeApiName,
            selectedItemsCount: selectedItems.length
        });

        if (!selectedItems.length) {
            throw new Error(`[MASSIVE SNAPSHOT WORKER] No selected items returned for Case ${caseId}`);
        }

        const hasLimitVisual = selectedItems.some(item => item.component === 'Limit Visual');
        let imageData = null;

        if (hasLimitVisual) {
            this.statusMessage = `Generating chart images for ${caseId}`;
            const features = await getFeatures({ id: recordOrLineId });
            const chartInputs = this.buildChartInputs(features || [], recordTypeApiName);

            if (chartInputs.hasImage) {
                const dataToPass = recordTypeApiName === 'DMT_Opportunity'
                    ? chartInputs.profitability
                    : chartInputs.allLimits;

                imageData = await this.getImageB64(dataToPass, recordTypeApiName);

                if (!imageData) {
                    throw new Error(`[MASSIVE SNAPSHOT WORKER] Limit Visual requires chart images, but no image was generated for Case ${caseId}`);
                }
            }
        }

        this.statusMessage = `Loading components for ${caseId}`;
        const response = await loadComponentsForView({
            recordOrLineId,
            viewType,
            selectedItems: JSON.stringify(selectedItems),
            productId,
            itemsImg: imageData ? JSON.stringify(imageData) : null
        });

        const parsedView = response ? JSON.parse(response) : null;

        if (!parsedView) {
            throw new Error(`[MASSIVE SNAPSHOT WORKER] loadComponentsForView returned empty response for Case ${caseId}`);
        }

        if (parsedView.error) {
            throw new Error(parsedView.error);
        }

        const html = parsedView.HTML || '';
        const json = parsedView.PDF || '';

        if (this.validateResponseForErrors(html, selectedItems)) {
            throw new Error(`[MASSIVE SNAPSHOT WORKER] View HTML contains only component errors for Case ${caseId}`);
        }

        console.log('[MASSIVE SNAPSHOT WORKER] View HTML generated', {
            caseId,
            htmlLength: html.length,
            jsonLength: json ? json.length : 0
        });

        return { html, json };
    }

    buildChartInputs(features, recordTypeApiName) {
        let profitability = null;
        let hasImage = false;
        const allLimitsLocal = [];

        const profitabilityFeature = (features || []).find(f => f.name && f.name.includes('Profitability') && f.profitability);
        if (profitabilityFeature) {
            hasImage = true;
            profitability = profitabilityFeature.profitability;
            this.profitability = profitability;
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
            profitability,
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
                        console.error('[MASSIVE SNAPSHOT WORKER] Chart image generation failed:', e);
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
            console.error('[MASSIVE SNAPSHOT WORKER] getImageB64 failed:', error);
            return '';
        }
    }

    @api
    async saveSnapshot(params) {
        const taskId = params?.taskId ? String(params.taskId) : null;
        const caseId = this.normalizeCaseId(params?.caseId);
        const relatedRecordName = params?.relatedRecordName || 'Task';

        if (!taskId) {
            throw new Error('[MASSIVE SNAPSHOT WORKER] Missing taskId.');
        }
        if (!caseId) {
            throw new Error('[MASSIVE SNAPSHOT WORKER] Missing caseId.');
        }

        const cachedView = this._cacheByCaseId[caseId] || await this.generateView({ caseId });
        const htmlToSave = cachedView.html;
        const jsonToProcess = cachedView.json || '';

        this._activeTaskId = taskId;
        this._relatedRecordName = relatedRecordName;
        this.statusMessage = `Saving snapshot for task ${taskId}`;
        this.isWorking = true;

        await saveNativeSnapshots({
            taskId,
            htmlString: htmlToSave,
            jsonString: null,
            fileBlob: null
        });

        await this.attemptPdfUploadWithFallback(taskId, caseId, htmlToSave, jsonToProcess);

        this.statusMessage = `Snapshot saved for task ${taskId}`;
        this.isWorking = false;

        return { taskId, caseId, success: true };
    }

    async attemptPdfUploadWithFallback(taskId, caseId, htmlString, jsonString) {
        let pdfBlob = null;

        try {
            pdfBlob = await this.getOrCreatePdfBlob(caseId, htmlString);

            if (pdfBlob) {
                await this.uploadToCoreDocuments(pdfBlob);
                console.info('[MASSIVE SNAPSHOT WORKER] CoreDocs upload success.');
            }
        } catch (error) {
            console.error('[MASSIVE SNAPSHOT WORKER] CoreDocs/PDF failed:', error?.body?.message || error?.message || error);

            try {
                if (pdfBlob) {
                    await saveNativeSnapshots({
                        taskId,
                        htmlString: null,
                        jsonString: null,
                        fileBlob: pdfBlob
                    });
                } else {
                    await saveNativeSnapshots({
                        taskId,
                        htmlString: null,
                        jsonString: jsonString || null,
                        fileBlob: null
                    });
                }
            } catch (fallbackError) {
                console.error('[MASSIVE SNAPSHOT WORKER] Native fallback save failed:', fallbackError);
                throw fallbackError;
            }
        }
    }

    async uploadToCoreDocuments(pdfBlob) {
        const config = await getUploadConfig();
        const selectedDocType = 'CO-OF-00241';
        const safeName = this.sanitizeFileName(this._relatedRecordName || 'Task');
        const dateStr = new Date().toISOString().replace(/T/, '_').replace(/\..+/, '').replace(/:/g, '-');
        const finalFileName = `${safeName} task completed on ${dateStr}.pdf`;

        const formData = new FormData();
        formData.append('file', pdfBlob, finalFileName);
        formData.append('folderId', this._activeTaskId);
        formData.append('folderCode', this._activeTaskId);

        const response = await fetch(config.endpoint, {
            method: 'POST',
            headers: config.headers,
            body: formData
        });

        if (!response.ok) {
            const errorBody = await response.text();
            throw new Error(`HTTP Error: ${response.status} ${response.statusText} - ${errorBody}`);
        }

        const result = await response.json();

        if (result && result.data && result.data.fileId) {
            await updateFileMetadata({
                fileId: result.data.fileId,
                fileName: finalFileName,
                docType: selectedDocType,
                folderId: this._activeTaskId
            });
        } else {
            throw new Error('Upload succeeded HTTP 200, but missing fileId in CoreDocuments response.');
        }
    }

    async generateServerPdf(rawHtml) {
        if (!rawHtml) {
            throw new Error('[PDF] No HTML provided.');
        }

        const prep = await preparePdfAssets({ originalHtml: rawHtml });
        const pdfBase64 = await generateFinalPdf({
            finalHtml: prep.modifiedHtml,
            docIds: prep.documentIds || []
        });

        const byteChars = atob(pdfBase64);
        const byteArray = new Uint8Array(byteChars.length);
        for (let i = 0; i < byteChars.length; i++) {
            byteArray[i] = byteChars.charCodeAt(i);
        }

        return new Blob([byteArray], { type: 'application/pdf' });
    }

    preGenerateServerPdfInBackground(caseId, htmlString) {
        const normalizedCaseId = this.normalizeCaseId(caseId);
        if (!normalizedCaseId || !htmlString) {
            return;
        }

        const existing = this._pdfByCaseId[normalizedCaseId];
        if (existing?.blob || existing?.promise) {
            return;
        }

        const promise = this.generateServerPdf(htmlString)
            .then(pdfBlob => {
                this._pdfByCaseId[normalizedCaseId] = { blob: pdfBlob, promise: null };
                return pdfBlob;
            })
            .catch(error => {
                this._pdfByCaseId[normalizedCaseId] = { blob: null, promise: null };
                console.error('[MASSIVE SNAPSHOT WORKER] Background PDF pre-generation failed:', error);
                throw error;
            });

        this._pdfByCaseId[normalizedCaseId] = { blob: null, promise };
    }

    async getOrCreatePdfBlob(caseId, htmlString) {
        const normalizedCaseId = this.normalizeCaseId(caseId);
        if (!normalizedCaseId) {
            throw new Error('[MASSIVE SNAPSHOT WORKER] Missing caseId for PDF generation.');
        }

        const existing = this._pdfByCaseId[normalizedCaseId];
        if (existing?.blob) {
            return existing.blob;
        }

        if (existing?.promise) {
            return existing.promise;
        }

        this.preGenerateServerPdfInBackground(normalizedCaseId, htmlString);
        const created = this._pdfByCaseId[normalizedCaseId];
        if (created?.promise) {
            return created.promise;
        }

        throw new Error('[MASSIVE SNAPSHOT WORKER] Could not prepare PDF blob.');
    }

    validateResponseForErrors(htmlString, selectedItems) {
        if (!htmlString) {
            return false;
        }

        if (selectedItems && selectedItems.length === 1) {
            return false;
        }

        const divs = htmlString.match(/<div>(.*?)<\/div>/g) || [];
        const contents = divs.map(div => div.replace(/<\/?div>/g, '').trim());
        return contents.length > 0 && contents.every(content => content.startsWith('Error:'));
    }

    setPreviewHtml(html) {
        this._lastPreviewHtml = html || '';
        this.queuePreviewPaint();
    }

    queuePreviewPaint() {
        if (this._previewPaintQueued) {
            return;
        }

        this._previewPaintQueued = true;
        setTimeout(() => {
            this._previewPaintQueued = false;
            this.paintPreviewHtml();
        }, 0);
    }

    paintPreviewHtml() {
        const container = this.template.querySelector('.snapshot-worker-html');
        if (!container) {
            return;
        }

        try {
            container.innerHTML = this._lastPreviewHtml || '<div class="slds-p-around_medium slds-text-color_weak">No preview HTML.</div>';
        } catch (error) {
            console.error('[MASSIVE SNAPSHOT WORKER] Could not paint preview HTML:', error);
        }
    }

    waitNextTick() {
        return new Promise(resolve => setTimeout(resolve, 0));
    }

    normalizeCaseId(caseId) {
        return caseId ? String(caseId) : null;
    }

    sanitizeFileName(value) {
        return String(value || 'Task')
            .replace(/[\\/:*?"<>|]/g, '-')
            .replace(/\s+/g, ' ')
            .trim()
            .substring(0, 120) || 'Task';
    }

    escapeHtml(value) {
        return String(value || '')
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    }
}