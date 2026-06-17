import { LightningElement, api,track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import updateFileMetadata from '@salesforce/apex/DMT_CoreDocuments_Controller.updateFileMetadata';
import getUploadConfig from '@salesforce/apex/DMT_CoreDocuments_Controller.getUploadConfig';

import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

// --- NEW IMPORTS FOR CORE DOCUMENTS RETRIEVAL ---
import getDocuments from '@salesforce/apex/DMT_CoreDocuments_Controller.getDocuments';
import getDownloadEndpoint from '@salesforce/apex/DMT_CoreDocuments_Controller.getDownloadEndpoint';
import getDownloadHeaders from '@salesforce/apex/DMT_CoreDocuments_Controller.getDownloadHeaders';

import deleteNativeSnapshots from '@salesforce/apex/DMT_ViewController.deleteNativeSnapshots';

// Task Level
import getTaskDetails from '@salesforce/apex/DMT_CoreDocuments_Controller.getTaskDetails';

// Case Level (Spanning to Parents)
import CASE_TYPE_FIELD from '@salesforce/schema/Case.DMT_LineOpportunity__c';
import CASE_OPP_NAME_FIELD from '@salesforce/schema/Case.opportunity_id__r.Name';
import OPP_EXTERNALID_FIELD from '@salesforce/schema/Case.opportunity_id__r.DMT_Opp_Id__c';
import CASE_LINE_NAME_FIELD from '@salesforce/schema/Case.DMT_Line__r.Name';
import LINE_EXTERNALID_FIELD from '@salesforce/schema/Case.DMT_Line__r.Line_Id__c';

const CASE_FIELDS = [
    CASE_TYPE_FIELD, 
    CASE_OPP_NAME_FIELD, 
    CASE_LINE_NAME_FIELD, 
    OPP_EXTERNALID_FIELD, 
    LINE_EXTERNALID_FIELD
];


export default class Dmt_case_history_modal_pawif extends NavigationMixin(LightningElement) {
    @api closecallback;
    @api record;

    // --- Exclusive UX Control ---
    @track isHealingPDF = false; // Controls the full-screen spinner for the Generate button
    @track coreDocsStatusMessage = 'Checking for snapshots...'; // Dynamic table message
    @track isCheckingCoreDocs = true;

    // --- NEW VARIABLES FOR CORE DOCUMENTS ---
    @track externalFiles = [];
    hasExternalFiles = false;
    _cachedJsonSnapshot;
    _relatedRecordName;

    _taskId

    _lineId;
    _caseIdFromTask; // Reactive trigger for the second wire

    get modalHeaderText() {
        const feature = this.record?.featureName;
        return feature ? `${feature}: Task detail` : 'Task detail';
    }

    get closeButtonDisabled(){
        // Disable the Close button if we're in the middle of healing or checking CoreDocs
        return this.isHealingPDF;
    }

    // STEP 2: Get the Parent Data (Line/Opp) from the Case
    @wire(getRecord, { recordId: '$_caseIdFromTask', fields: CASE_FIELDS })
    wiredCase({ error, data }) {
        if (data) {
            const type = getFieldValue(data, CASE_TYPE_FIELD);
            this._caseType = type;

            if (type === 'O') {
                this._relatedRecordName = getFieldValue(data, CASE_OPP_NAME_FIELD);
                this._lineId = getFieldValue(data, OPP_EXTERNALID_FIELD); 
            } else if (type === 'L') {
                this._relatedRecordName = getFieldValue(data, CASE_LINE_NAME_FIELD);
                this._lineId = getFieldValue(data, LINE_EXTERNALID_FIELD); 
            }

            this.checkAndFetchCoreDocs();
        } else if (error) {
            console.error('[MODAL] Error fetching Case details:', error);
        }
    }

    closeModal() {
        if (this.closecallback) {
            this.closecallback();
        }
    }

    checkAndFetchCoreDocs() {
        console.log('[MODAL] Checking if we can fetch CoreDocs. Task Id:', this._taskId);
        console.log('[MODAL] Checking if we can fetch CoreDocs. Line ID:', this._lineId);
        
        // We need both _taskId (for the folder) and _lineId (for dynamic metadata logic)
        if (this._taskId && this._lineId) {
            console.log('[MODAL] Dependencies resolved. Fetching CoreDocs now...');
            this._hasFetchedCoreDocs = true;
            this.fetchExternalFiles();
        }
    }

    // =========================================================================
    // === NEW METHODS FOR CORE DOCUMENTS INTEGRATION                        ===
    // =========================================================================

    // --- FETCH EXTERNAL LIST ---
    async fetchExternalFiles() {
        this.isCheckingCoreDocs = true; 
        this.coreDocsStatusMessage = 'Checking CoreDocuments vault...';
        
        if (!this._taskId) {
            console.warn('[CORE DOCS - ABORT] No _taskId provided to modal.');
            return;
        }

        try {
            console.time('[CORE DOCS - TIMING] Fetch external files total time');
            const response = await getDocuments({ folderCode: this._taskId });
            
            let fileFound = false;
            let firstFileLocator = null;

            if (response.success && response.data && response.data.length > 0) {
                let parsedFiles = [];
                
                response.data.forEach((folder) => {
                    if (folder.children && folder.children.length > 0) {
                        folder.children.forEach((child) => {
                            fileFound = true;
                            // Capture the first file's locator to display in the UI
                            if (!firstFileLocator) {
                                firstFileLocator = child.contentLocator;
                            }
                            
                            const name = child.objectName;
                            const dateMatch = name.match(/(\d{4}-\d{2}-\d{2})/);
                            const extractedDate = dateMatch ? dateMatch[0] : null;

                            const entity = this._caseType === 'O' ? 'Opportunity' : (this._caseType === 'L' ? 'Line' : 'Line/Opportunity');
                            const dynamicDocTypeMap = {
                                'CO-OF-00240': `${entity} Description`,
                                'CO-OF-00241': 'Validation / Approval Support Documents',
                                'CO-OF-00242': `${entity} Assessment`
                            };

                            parsedFiles.push({
                                id: child.id,
                                name: child.objectName,
                                contentLocator: child.contentLocator,
                                createdDate: extractedDate, 
                                documentType: dynamicDocTypeMap[child.documentType] || child.documentType     
                            });
                        });
                    } 
                });
                
                this.externalFiles = parsedFiles;
                this.hasExternalFiles = this.externalFiles.length > 0;
            }

            // --- DECISION FORK ---
            if (fileFound && firstFileLocator) {
                console.info('[CORE DOCS - SUCCESS] File found in vault. Fetching PDF for preview...');
                this.coreDocsStatusMessage = 'File found in vault. Fetching PDF for preview...';
                //await this.displayPdf(firstFileLocator);
            } else {
                console.warn('[CORE DOCS - EMPTY] No file found in folder. Falling back to HTML generation.');
                this.hasExternalFiles = false;
                this.coreDocsStatusMessage = 'No PDF snapshot available for this task.';
                //this.getTypeFile(); // Trigger the HTML flow
            }

            console.timeEnd('[CORE DOCS - TIMING] Fetch external files total time');
        } catch (error) {
            console.error('[CORE DOCS - FATAL ERROR] Failed to fetch external files:', JSON.stringify(error));
            this.hasExternalFiles = false;
            this.coreDocsStatusMessage = 'Error connecting to Document Vault.';
            //this.getTypeFile(); // Fallback to HTML if API crashes
        } finally {
            this.isCheckingCoreDocs = false; 
        }
    }

    async connectedCallback() {
        console.log('[MODAL] Connected to DOM. Initial record:', JSON.stringify(this.record));
        
        if (this.record && this.record.taskId) {
            this._taskId = this.record.taskId;
            await this.fetchTaskDetailsImperatively();
        } else {
            console.warn('[MODAL] No taskId provided upon initialization.');
        }
    }

    async fetchTaskDetailsImperatively() {
        try {
            const taskData = await getTaskDetails({ taskId: this._taskId });
            
            if (taskData && taskData.WhatId) {
                const whatId = taskData.WhatId;
                
                // Verify it's a Case ID (starts with 500)
                if (whatId.startsWith('500')) {
                    // Setting this property will reactively trigger wiredCase method
                    this._caseIdFromTask = whatId; 
                }
            }
            // Proceed to evaluate core docs based on whatever data was retrieved
            this.checkAndFetchCoreDocs();
            
        } catch (error) {
            console.error('[MODAL] Error fetching Task parent via imperative Apex:', error);
            // Optionally set this.isLoading = false or display a toast message to the user here
        }
    }

    // --- NEW: DOWNLOAD EXTERNAL FILE BLOB ---
    // --- DOWNLOAD EXTERNAL FILE BLOB (WITH CACHE CHECK) ---
    async handleDownloadExternalFile(event) {
        const contentLocator = event.currentTarget.dataset.locator;
        const fileName = event.currentTarget.dataset.name;

        if (!contentLocator) {
            console.error('[CORE DOCS - DOWNLOAD ABORTED] No content locator found.');
            return;
        }

        try {
            let blobToDownload = null;

            // --- 1. CHECK CACHE FIRST ---
            if (this._cachedPdfBlob) {
                console.info('[CORE DOCS] Using cached PDF Blob for instant download.');
                blobToDownload = this._cachedPdfBlob;
            } else {
                // --- 2. FALLBACK TO FETCH IF NO CACHE ---
                console.info('[CORE DOCS] Fetching PDF Blob from server...');
                const endpoint = await getDownloadEndpoint({ contentLocator: contentLocator });
                const headers = await getDownloadHeaders();
                
                const response = await fetch(endpoint, {
                    method: 'GET',
                    headers: headers
                });

                if (!response.ok) {
                    throw new Error(`HTTP Error ${response.status}: ${response.statusText}`);
                }

                blobToDownload = await response.blob();

                // --- 100% CONFIRMED SAFE ---
                // The PDF has successfully arrived from CoreDocs and is rendering. 
                // We can now safely destroy the Salesforce ContentVersion backups.
                this.deleteNativeFiles();
            }
            
            // --- 3. TRIGGER DOWNLOAD ---
            const link = document.createElement('a');
            const blobUrl = URL.createObjectURL(blobToDownload);
            link.href = blobUrl;
            link.download = fileName || 'CoreDocument.pdf';
            
            document.body.appendChild(link);
            link.click();
            
            document.body.removeChild(link);
            URL.revokeObjectURL(blobUrl);

        } catch (error) {
            console.error('[CORE DOCS - FATAL ERROR] File download process failed:', error);
        }
    }

    // --- NEW: Generate PDF on the fly if missing in CoreDocs ---
    async handleGenerateAndUploadMissingPdf() {
        if (!this._cachedJsonSnapshot) {
            console.error('[HEAL] No JSON found in memory. Aborting.');
            return;
        }

        this.isHealingPDF = true; 

        try {
            // STEP 1: Generate PDF
            console.log('[HEAL] 1. Initializing PDF Generator with JSON data...');
            const pdfGenerator = this.template.querySelector('c-pdf-generator');
            pdfGenerator.jsonData = JSON.parse(this._cachedJsonSnapshot);
            pdfGenerator.output = 'blob';
            
            console.log('[HEAL] 2. Calling pdfGenerator.generatePDF()...');
            await new Promise(resolve => setTimeout(resolve, 100));
            const pdfBlob = await pdfGenerator.generatePDF();
            console.log('[HEAL] 3. PDF Generation Complete. Blob Size:', pdfBlob?.size, 'bytes');

            if (!pdfBlob || pdfBlob.size === 0) {
                throw new Error('Generated PDF Blob is empty or null.');
            }

            // STEP 2: CoreDocs Upload
            console.log('[HEAL] 4. Fetching Upload Config from Apex...');
            const config = await getUploadConfig();
            console.log('[HEAL] 5. Config retrieved.');

            const dateStr = new Date().toISOString().replace(/T/, '_').replace(/\..+/, '').replace(/:/g, '-');
            const finalFileName = `${this._relatedRecordName || 'Manual_Fix'} task completed on ${dateStr}.pdf`;
            const selectedDocType = 'CO-OF-00241';

            console.log('[HEAL] 6. Building FormData. Folder ID (Line):', this._taskId);
            if (!this._taskId) {
                throw new Error('Folder ID (_taskId) is missing. Has the wire finished loading?');
            }

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
                const errorText = await response.text();
                throw new Error(`Upload Failed (HTTP ${response.status}): ${errorText}`);
            }
            
            const uploadResult = await response.json();

            // STEP 3: Register Metadata
            if (uploadResult && uploadResult.data && uploadResult.data.fileId) {
                await updateFileMetadata({
                    fileId: uploadResult.data.fileId,
                    fileName: finalFileName,
                    docType: selectedDocType,
                    folderId: this._taskId 
                });

                console.log('[HEAL] 11. Metadata Success. Refreshing list...');
                await this.fetchExternalFiles();
            } else {
                throw new Error('Upload succeeded but no fileId was returned by CoreDocs.');
            }

        } catch (error) {
            let message = 'Unknown Error';
            if (error.body && error.body.message) {
                message = error.body.message; 
            } else if (error.message) {
                message = error.message; 
            } else {
                message = JSON.stringify(error);
            }
            console.error('[HEAL] FATAL ERROR:', message);
            console.error('[HEAL] Full Error Object:', error);
        } finally {
            this.isHealingPDF = false; 
        }
    }

    // --- Cleanup Native Salesforce Files ---
    async deleteNativeFiles() {
        if (!this._taskId) return;
        try {
            const resultMsg = await deleteNativeSnapshots({ taskId: this._taskId });
            console.log('[CLEANUP]', resultMsg); // Will print "No content documents..." or "1 documents deleted."
        } catch (error) {
            console.error('[CLEANUP ERROR] Failed to delete native snapshots:', error);
        }
    }
}