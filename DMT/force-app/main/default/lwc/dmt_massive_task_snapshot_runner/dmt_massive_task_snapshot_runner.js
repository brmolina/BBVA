import { LightningElement } from 'lwc';
import { createMessageContext, releaseMessageContext, subscribe, publish, APPLICATION_SCOPE } from 'lightning/messageService';
import DMT_VIEW_DATA_CHANNEL from '@salesforce/messageChannel/DmtViewData__c';
import DMT_TASK_CLOSURE_CHANNEL from '@salesforce/messageChannel/DmtTaskClosure__c';

import saveNativeSnapshots from '@salesforce/apex/DMT_ViewController.saveNativeSnapshots';
import getUploadConfig from '@salesforce/apex/DMT_CoreDocuments_Controller.getUploadConfig';
import updateFileMetadata from '@salesforce/apex/DMT_CoreDocuments_Controller.updateFileMetadata';
import preparePdfAssets from '@salesforce/apex/DMT_PdfService.preparePdfAssets';
import generateFinalPdf from '@salesforce/apex/DMT_PdfService.generateFinalPdf';

export default class Dmt_massive_task_snapshot_runner extends LightningElement {
    viewRecordId;
    renderHiddenView = true;

    cachedHtml = null;
    cachedJson = '';
    cachedPdfBlob = null;
    pdfGenerationPromise = null;

    _subscription;
    _closureSubscription;
    _isRunning = false;
    _cacheByCaseId = {};

    _taskId;
    _caseId;
    _relatedRecordName = 'Task';
    _messageContext = createMessageContext();

    connectedCallback() {
        if (!this._subscription) {
            this._subscription = subscribe(
                this._messageContext,
                DMT_VIEW_DATA_CHANNEL,
                (message) => this.handleLmsViewDataLoaded(message),
                { scope: APPLICATION_SCOPE }
            );
        }

        if (!this._closureSubscription) {
            this._closureSubscription = subscribe(
                this._messageContext,
                DMT_TASK_CLOSURE_CHANNEL,
                (message) => this.handleClosureMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    disconnectedCallback() {
        releaseMessageContext(this._messageContext);
    }

    handleLmsViewDataLoaded(message) {
        this.cachedHtml = message?.htmlPayload || null;
        this.cachedJson = message?.jsonPayload ?? '';
        if (this.cachedHtml) {
            this.preGenerateServerPdfInBackground();
        }
    }

    handleClosureMessage(message) {
        if (!message || message.type !== 'massiveTasksClosed') {
            return;
        }
        this.runMassive(message.tasks || []);
    }

    async runMassive(tasks) {
        if (this._isRunning) {
            return;
        }
        this._isRunning = true;
        this._cacheByCaseId = {};

        let completed = 0;
        let failed = 0;

        for (const task of tasks) {
            try {
                await this.processSingleTask(task?.taskId, task?.caseId);
                completed++;
            } catch (error) {
                console.error('[MASSIVE RUNNER] Task failed', task?.taskId, error);
                failed++;
            }
        }

        this._isRunning = false;

        publish(this._messageContext, DMT_TASK_CLOSURE_CHANNEL, {
            type: 'closureComplete',
            completed,
            failed
        });

        this.dispatchEvent(new CustomEvent('runnercomplete', {
            detail: { completed, failed },
            bubbles: true,
            composed: true
        }));
    }

    async processSingleTask(taskId, caseId) {
        const previousTaskId = this._taskId;
        const previousCaseId = this._caseId;
        const previousViewRecordId = this.viewRecordId;
        const previousRenderHiddenView = this.renderHiddenView;

        try {
            this._taskId = taskId;
            this._caseId = caseId;

            let htmlToSave;
            let jsonToProcess;
            const cachedCase = this._caseId ? this._cacheByCaseId[this._caseId] : null;

            if (cachedCase && cachedCase.html) {
                htmlToSave = cachedCase.html;
                jsonToProcess = cachedCase.json || '';
            } else {
                this.renderHiddenView = false;
                this.viewRecordId = null;
                await Promise.resolve();

                this.cachedHtml = null;
                this.cachedJson = '';
                this.cachedPdfBlob = null;
                this.pdfGenerationPromise = null;

                this.viewRecordId = this._caseId;
                this.renderHiddenView = true;
                await Promise.resolve();

                const ready = await this.waitForNextCacheData();
                htmlToSave = this.cachedHtml;
                jsonToProcess = this.cachedJson || '';

                if (!ready || !htmlToSave) {
                    throw new Error(`CACHE MISS for case ${this._caseId}`);
                }

                this._cacheByCaseId[this._caseId] = {
                    html: htmlToSave,
                    json: jsonToProcess
                };
            }

            await saveNativeSnapshots({
                taskId: this._taskId,
                htmlString: htmlToSave,
                jsonString: null,
                fileBlob: null
            });

            this.cachedHtml = htmlToSave;
            this.cachedJson = jsonToProcess;
            this.cachedPdfBlob = null;
            this.pdfGenerationPromise = null;

            await this.attemptPdfUploadWithFallback(jsonToProcess);

            if (!this.cachedPdfBlob) {
                await saveNativeSnapshots({
                    taskId: this._taskId,
                    htmlString: null,
                    jsonString: jsonToProcess || null,
                    fileBlob: null
                });
            }
        } finally {
            this._taskId = previousTaskId;
            this._caseId = previousCaseId;
            this.viewRecordId = previousViewRecordId;
            this.renderHiddenView = previousRenderHiddenView;
        }
    }

    waitForNextCacheData(timeoutMs = 15000) {
        return new Promise((resolve) => {
            const interval = 250;
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

            if (pdfBlob) {
                await this.uploadToCoreDocuments(pdfBlob);
                console.info('[CORE DOCS] ✅ Success. PDF is in external vault.');
            }
        } catch (error) {
            console.error('[❌ CORE DOCS FAILED] Error Reason:', (error.body ? error.body.message : error.message));

            try {
                if (pdfBlob) {
                    const fallbackBlob = new Blob([pdfBlob], { type: 'application/pdf' });
                    await saveNativeSnapshots({
                        taskId: this._taskId,
                        htmlString: null,
                        jsonString: null,
                        fileBlob: fallbackBlob
                    });
                    console.info('[FALLBACK] ✅ PDF backup successfully saved to Salesforce Files.');
                } else {
                    await saveNativeSnapshots({
                        taskId: this._taskId,
                        htmlString: null,
                        jsonString: jsonString || null,
                        fileBlob: null
                    });
                    console.info('[FALLBACK] ✅ JSON backup successfully saved to Salesforce Files.');
                }
            } catch (fallbackError) {
                console.error('[CRITICAL] Native JSON fallback save failed!', fallbackError);
            }
        }
    }

    async uploadToCoreDocuments(pdfBlob) {
        const config = await getUploadConfig();
        const selectedDocType = 'CO-OF-00241';
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
            throw new Error('Upload succeeded HTTP 200, but missing fileId in CoreDocuments response.');
        }
    }

    async preGenerateServerPdfInBackground() {
        try {
            this.pdfGenerationPromise = await this.generateServerPdf(this.cachedHtml);
            this.cachedPdfBlob = this.pdfGenerationPromise;
        } catch (error) {
            this.cachedPdfBlob = null;
            this.pdfGenerationPromise = null;
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
}