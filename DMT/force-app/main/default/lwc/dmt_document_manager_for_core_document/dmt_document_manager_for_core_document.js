import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getRecordUi, getFieldValue } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import Id from '@salesforce/user/Id';

import LINE_ID_FIELD from '@salesforce/schema/DMT_Line__c.Line_Id__c';
import NAME_FIELD from '@salesforce/schema/DMT_Line__c.Name';
import STATUS_FIELD from '@salesforce/schema/DMT_Line__c.Status__c';
import LINE_RT_DEV_NAME from '@salesforce/schema/DMT_Line__c.RecordType.DeveloperName';
import LINE_BOOKING_GEO from '@salesforce/schema/DMT_Line__c.Booking_Geography__c';
import LINE_CLIENT_FIELD from '@salesforce/schema/DMT_Line__c.Client__c';

import OPP_ID_FIELD from '@salesforce/schema/Opportunity.DMT_Opp_Id__c';
import STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';
import OPP_NAME_FIELD from '@salesforce/schema/Opportunity.Name';
import OPP_RT_DEV_NAME from '@salesforce/schema/Opportunity.RecordType.DeveloperName';
import OPP_ENTIFIC from '@salesforce/schema/Opportunity.Entific__c';
import OPP_ACCOUNT_FIELD from '@salesforce/schema/Opportunity.AccountId';

import CASE_ID_FIELD from '@salesforce/schema/Case.Id';

import USER_NAME_FIELD from '@salesforce/schema/User.Name';

import getAttachments from '@salesforce/apex/DMT_AttachmentController.getAttachments';
import getAttachmentBase64 from '@salesforce/apex/DMT_AttachmentController.getAttachmentBase64';
import hasEditAccess from '@salesforce/apex/DMT_AttachmentController.hasEditAccess';

import getDocuments from '@salesforce/apex/DMT_CoreDocuments_Controller.getDocuments';
import getDownloadHeaders from '@salesforce/apex/DMT_CoreDocuments_Controller.getDownloadHeaders';
import getUploadConfig from '@salesforce/apex/DMT_CoreDocuments_Controller.getUploadConfig';
import getDownloadEndpoint from '@salesforce/apex/DMT_CoreDocuments_Controller.getDownloadEndpoint';
import downloadFileBase64 from '@salesforce/apex/DMT_CoreDocuments_Controller.downloadFileBase64';
import updateFileMetadataWithObjectCode from '@salesforce/apex/DMT_CoreDocuments_Controller.updateFileMetadataWithObjectCode';
import getCatalogsDescriptions from '@salesforce/apex/DMT_CoreDocuments_Controller.getCatalogsDescriptions';
import appendTaxonomyValue from '@salesforce/apex/DMT_CoreDocuments_Controller.appendTaxonomyValue';
import triggerPassportUpdate from '@salesforce/apex/DMT_CoreDocuments_Controller.triggerPassportUpdate';
import isDocumentDeletionAllowed from '@salesforce/apex/DMT_CoreDocuments_Controller.isDocumentDeletionAllowed';
import LightningConfirm from 'lightning/confirm';

const VALID_MIME_TYPES = {
    'application/pdf': true,
    'application/octet-stream': true,
    'application/msword': true,
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document': true,
    'application/vnd.ms-excel': true,
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': true,
    'text/plain': true,
    'image/jpeg': true,
    'image/png': true,
    'image/gif': true,
    'application/vnd.ms-office': true,
    'application/x-msword': true,
    'application/x-zip-compressed': true,
    'application/zip': true
};

const COLUMNS = [
    { 
        label: 'View', 
        type: 'button-icon', 
        initialWidth: 70,
        cellAttributes: { style: 'text-align: center;' },
        typeAttributes: {
            iconName: { fieldName: 'actionIcon' },
            title: { fieldName: 'actionTitle' },
            name: 'download',
            variant: 'border-filled',
            alternativeText: { fieldName: 'actionTitle' },
        }
    },
    {
        label: 'File Name',
        type: 'text',
        fieldName: 'cleanName',
        initialWidth: 450,
        cellAttributes: {
            iconName: { fieldName: 'iconName' }, 
            iconPosition: 'left',
            class: 'file-name-cell',
            style: 'text-align: center;'
        },initialWidth: 380
    },
    {label: 'Owner',fieldName: 'ownerName', type: 'text', cellAttributes: { style: 'text-align: center;' },initialWidth: 240 },
    {label: 'Upload Date', fieldName: 'uploadDate', type: 'text', cellAttributes: { style: 'text-align: center;' },initialWidth: 120},
    {label: 'Document Type', fieldName: 'documentTypeLabel', type: 'text', cellAttributes: { style: 'text-align: center;' }, initialWidth: 365 },
    {
        label: '',
        type: 'button-icon',
        initialWidth: 70,
        cellAttributes: { style: 'text-align: center;' },
        typeAttributes: {
            iconName: 'utility:delete',
            title: 'Delete document',
            name: 'delete',
            variant: 'border-filled',
            alternativeText: 'Delete document',
            disabled: { fieldName: 'deleteDisabled' }
        }
    }

];

const DOC_TYPES = [
    { label: 'Descripción de la oportunidad / Línea', value: 'CO-OF-00240' },
    { label: 'Documentos de soporte de validaciones / aprobaciones', value: 'CO-OF-00241' },
    { label: 'Dictamen Oportunidad / Línea', value: 'CO-OF-00242' }
];

export default class dmt_document_manager_for_core_document extends LightningElement {
    @api recordId;

    lineId;
    userId = Id;
    currentUserName;
    objectApiName; // Will hold "Opportunity" or "DMT_Line__c"

    @track files = [];
    @track isLoading = true;
    @track isDragging = false;
    @track isModalOpen = false;
    @track isPreviewLoading = false;
    @track selectedFile = null;
    @track selectedDocType = '';
    @track isModaViewOpen = false;
    @track pdfData;
    @track wiredFields = []; // reactive field list for getRecord
    @track attachments = [];// Archivos de Salesforce(Attachments)
    @track coreFiles = [];    // Archivos externos (Core Documents)
    @track combinedFiles = []; // Lo que realmente muestra la tabla (data={combinedFiles})
    @track taxonomyOptions = []; // Almacena las opciones dinámicas traídas de Apex
    @track catalogValue3; // Global variable for filtering taxonomy (e.g. 'OP' or 'TO')
    @track entific; // Global variable for filtering taxonomy
    @track recordTypeDevName; // Global variable to pass to Apex
    @track clientId; // Global variable to pass to Passport Payload
    @track canDeleteDocuments = false; // False while the related record is in a final state (Closed Won / closed Case)

    _lastLoadedLineId = null; // Guard: tracks the lineId already loaded to prevent redundant service calls
    _hasEditAccess = false;

    @wire(hasEditAccess, { recordId: '$recordId' })
    wiredHasEditAccess({ error, data }) {
        if (data !== undefined) {
            this._hasEditAccess = data;
            this.combineAllFiles();
        } else if (error) {
            console.error('Error checking edit access:', error);
            this._hasEditAccess = false;
            this.combineAllFiles();
        }
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            // Check standard and custom state parameters
            this.recordId = currentPageReference.state?.recordId || currentPageReference.state?.c__recordId || currentPageReference.attributes?.recordId;
        }
    }
    
    // Wire fires reactively once $entific and $catalogValue3 are populated
    @wire(getCatalogsDescriptions, { docTypeCodes: ['CO-OF-00240'], entific: '$entific', catalogValue3: '$catalogValue3' })
    wiredTaxonomy({ error, data }) {
        if (data) {
            // Apex already built the perfect object, just assign it directly!
            this.taxonomyOptions = data;
        } else if (error) {
            console.error('Error fetching taxonomy options:', error);
        }
    }

    // Traemos el nombre del usuario logueado
    @wire(getRecord, { recordId: '$userId', fields: [USER_NAME_FIELD] })
    wiredUser({ error, data }) {
        if (data) {
            this.currentUserName = getFieldValue(data, USER_NAME_FIELD);
        }
    }

    @wire(isDocumentDeletionAllowed, { recordId: '$recordId' })
    wiredDeletionAllowed({ error, data }) {
        if (data !== undefined) {
            this.canDeleteDocuments = data;
            this.combineAllFiles();
        } else if (error) {
            console.error('Error checking document deletion permission:', error);
            this.canDeleteDocuments = false;
        }
    }
            //Detect object type from recordId
    @wire(getRecordUi, { recordIds: '$recordId', layoutTypes: ['Full'], modes: ['View'] })
    wiredRecordUi({ error, data }) {
        if (data) {
            // Only set objectApiName and wiredFields once per recordId to avoid
            // cascading re-fires of @wire(getRecord) from new array references
            const detectedApi = data.records[this.recordId].apiName;
            if (this.objectApiName === detectedApi && this.wiredFields.length > 0) {
                return; // Already resolved — skip redundant assignment
            }
            this.objectApiName = detectedApi;
            console.log('Detected object:', this.objectApiName);
            if (this.objectApiName === 'DMT_Line__c') {
                this.wiredFields = [STATUS_FIELD, LINE_ID_FIELD, NAME_FIELD, LINE_RT_DEV_NAME, LINE_BOOKING_GEO, LINE_CLIENT_FIELD];
            } else if (this.objectApiName === 'Opportunity') {
                this.wiredFields = [STAGE_FIELD, OPP_ID_FIELD, OPP_NAME_FIELD, OPP_RT_DEV_NAME, OPP_ENTIFIC, OPP_ACCOUNT_FIELD];
            } else if (this.objectApiName === 'Case') {
                 this.wiredFields = [CASE_ID_FIELD]; 
            }
        } else if (error) {
            console.error('Error retrieving object info:', error);
            this.isLoading = false;
        }
    }

    // Wire record with dynamic fields
    @wire(getRecord, { recordId: '$recordId', fields: '$wiredFields' })
    wiredRecord({ error, data }) {
        if (data) {
            if (this.objectApiName === 'DMT_Line__c') {
                this.lineId = getFieldValue(data, LINE_ID_FIELD);
                this.clientId = getFieldValue(data, LINE_CLIENT_FIELD);
                
                // Assign Catalog and Entific global variables
                const rtDevName = getFieldValue(data, LINE_RT_DEV_NAME);
                this.recordTypeDevName = rtDevName; // Save globally
                
                if (rtDevName === 'Sanction') {
                    this.catalogValue3 = 'TO';
                }
                this.entific = getFieldValue(data, LINE_BOOKING_GEO);

                if (this.lineId && this.lineId !== this._lastLoadedLineId) {
                    this.loadDocuments();
                } else {
                    this.isLoading = false;
                }
            } else if (this.objectApiName === 'Opportunity') {
                this.lineId = getFieldValue(data, OPP_ID_FIELD);
                this.clientId = getFieldValue(data, OPP_ACCOUNT_FIELD);
                
                // Assign Catalog and Entific global variables
                const rtDevName = getFieldValue(data, OPP_RT_DEV_NAME);
                this.recordTypeDevName = rtDevName; // Save globally
                
                if (rtDevName === 'DMT_Opportunity') {
                    this.catalogValue3 = 'OP';
                }
                this.entific = getFieldValue(data, OPP_ENTIFIC);

                if (this.lineId && this.lineId !== this._lastLoadedLineId) {
                    this.loadDocuments();
                } else {
                    this.isLoading = false;
                }
            }
            else if (this.objectApiName === 'Case') {
                this.lineId = getFieldValue(data, CASE_ID_FIELD);
                if (this.lineId && this.lineId !== this._lastLoadedLineId) {
                    this.loadDocuments();
                } else {
                    this.isLoading = false;
                }
            }

        } else if (error) {
            console.error('Error loading opportunity record', error);
            this.showToast('Error', 'Could not load Opportunity ID', 'error');
            this.isLoading = false;
        }
    }
    @wire(getAttachments, { parentId: '$recordId' })
    wiredAttachments(result) {
        if (result.data) {
            // Mapeamos los attachments locales
            this.attachments = result.data.map(f => ({
                id: f.id,
                cleanName: f.name, // Ajustado para que coincida con la columna "File Name"
                ownerName: f.createdBy || (f.CreatedBy ? f.CreatedBy.Name : 'N/A'), 
                uploadDate: this.formatDisplayDate(f.createdDate),
                documentTypeLabel: 'Attachment (Salesforce)',
                iconName: this.getIconName(f.name), // Reutilizamos lógica de iconos
                isAttachment: true, // Flag para saber que es de SF
                link: `/servlet/servlet.FileDownload?file=${f.id}`,
                ...this.getActionIconAndTitle(f.name)
            }));
            this.combineAllFiles(); // Mezclar datos
        } else if (result.error) {
            console.error('Error fetching attachments:', result.error);
        }

    }

    getActionIconAndTitle(filename) {
        const isPdf = filename && filename.toLowerCase().endsWith('.pdf');
        return {
            actionIcon: isPdf ? 'action:preview' : 'action:download',
            actionTitle: isPdf ? 'Click to View PDF' : 'Click to Download',
            isPdf: isPdf
        };
    }
    columns = COLUMNS;
    get docTypeOptions() {
        const labelsMap = {
            'DMT_Line__c': { suffix: 'Line', dictamen: 'Line' },
            'Opportunity': { suffix: 'Opportunity', dictamen: 'Opportunity' },
            'Case': { suffix: 'Case', dictamen: 'Case' }
        };
        const config = labelsMap[this.objectApiName] || labelsMap['Opportunity'];
        
        const baseOptions = [
            { label: `${config.suffix} Description`, value: 'CO-OF-00240' }/* ,
            { label: 'Validation / Approval Support Documents', value: 'CO-OF-00241' }, kept for future reference
            { label: `${config.dictamen} Assessment`, value: 'CO-OF-00242' } kept for future reference*/ 
        ];

        // Se agregan las opciones dinámicas extraídas desde DMT_Taxonomy_Values__c y se ordenan alfabéticamente
        // Se excluye CO-OF-00242 de la UI porque no debe mostrarse como tipo seleccionable.
        const filteredBaseOptions = baseOptions.filter(opt => opt.value !== 'CO-OF-00242');
        const filteredTaxonomyOptions = (this.taxonomyOptions || []).filter(opt => opt.value !== 'CO-OF-00242');
        const allOptions = [...filteredBaseOptions, ...filteredTaxonomyOptions];
        return allOptions.sort((a, b) => a.label.localeCompare(b.label));
    }

    getIconName(filename) {
        if (!filename) return 'doctype:unknown';
        const ext = filename.split('.').pop().toLowerCase();
        switch (ext) {
            case '7z':
            case 'rar':
            case 'zip':
                return 'doctype:zip';
            case 'csv':
                return 'doctype:csv';
            case 'doc':
            case 'docx':
            case 'odt':
                return 'doctype:word';
            case 'eml':
            case 'msg':
            case 'oft':
                return 'doctype:gdoc';
            case 'htm':
            case 'html':
            case 'mht':
                return 'doctype:html';
            case 'jpeg':
            case 'jpg':
            case 'png':
            case 'tif':
                return 'doctype:image';
            case 'log':
            case 'txt':
                return 'doctype:txt';
            case 'ods':
            case 'xls':
            case 'xlsb':
            case 'xlsm':
            case 'xlsx':
                return 'doctype:excel';
            case 'pdf':
            case 'xps':
                return 'doctype:pdf';
            case 'ppsx':
            case 'ppt':
            case 'pptx':
                return 'doctype:ppt';
            case 'rtf':
                return 'doctype:rtf';
            case 'xml':
                return 'doctype:xml';
            default:
                return 'doctype:unknown';
        }
    }

    async loadDocuments() {
        if (!this.lineId) {
            this.isLoading = false;
            return;
        }
        // Mark this lineId as loaded to prevent redundant service calls from wire re-fires
        this._lastLoadedLineId = this.lineId;
        this.isLoading = true;
        this.files = [];
        try {
            const data = await getDocuments({ folderCode: this.lineId });
            if (data && data.success) {
                console.log('core documenr child getDocuments-->', JSON.stringify(data));
                let allFiles = [];
                if (data.data && Array.isArray(data.data)) {
                    data.data.forEach(folder => {
                        if (folder.children && Array.isArray(folder.children)) {
                            const folderFiles = folder.children.map(child => {
                                const originalName = child.objectName || '';
                                console.log('core documenr child -->', JSON.stringify(child));
                                
                                // --- NEW MAPPING LOGIC ---
                                // Prioritize the specific objectCode (Taxonomy), fallback to documentType (Base Code)
                                const targetCode = child.objectCode || child.documentType;
                                if (targetCode === 'CO-OF-00242') {
                                    return null;
                                }
                                const docTypeEntry = this.docTypeOptions.find(dt => dt.value === targetCode);
                                
                                let cleanName = originalName;
                                let uploadDate = 'N/A';
                                let ownerName = 'N/A';
                                // Dividimos por el separador doble '__'
                                const parts = originalName.split('__');

                                if (parts.length >= 3) {
                                    uploadDate = parts[1];
                                    // Limpiamos la extensión del nombre del usuario y cambiamos guiones por espacios
                                    let rawUser = parts[2];
                                    const lastDot = rawUser.lastIndexOf('.');
                                    if (lastDot !== -1) rawUser = rawUser.substring(0, lastDot);
                                    
                                    ownerName = rawUser.replace(/-/g, ' '); // "Jorge-Andrés" -> "Jorge Andrés"
                                    cleanName = parts[0] + (originalName.substring(originalName.lastIndexOf('.')) || '');

                                }else {
                                    const legacyRegex = /_(\d{1,2}-\d{1,2}-\d{4})_([^_]+)/;
                                    const match = originalName.match(legacyRegex);
                            
                                    if (match) {
                                        //Limpiamos el nombre original para la columna File Name
                                        uploadDate = match[1];
                                        let rawOwner = match[2];
                                        ownerName = rawOwner.split('.')[0].replace(/-/g, ' ');  
                                        cleanName = originalName.split('_' + uploadDate)[0];
                                    }
                                }
                                // Asegurarnos de que el nombre limpio conserve su extensión original si se perdió
                                if (!cleanName.includes('.')) {
                                    const ext = originalName.substring(originalName.lastIndexOf('.'));
                                    cleanName += ext;
                                }
                                return {
                                    ...child,
                                    cleanName: cleanName,
                                    uploadDate: parts[1],
                                    ownerName: ownerName,
                                    id: child.id,
                                    name: child.objectName,
                                    // Use the matched label, or fallback to the raw code so it's not blank
                                    documentTypeLabel: docTypeEntry ? docTypeEntry.label : targetCode,
                                    type: child.documentType,
                                    folderCode: folder.businessCode ? folder.businessCode.folderCode : '',
                                    iconName: this.getIconName(child.objectName),
                                    ...this.getActionIconAndTitle(child.objectName)
                                };
                            });
                            allFiles = [...allFiles, ...folderFiles.filter(file => file !== null)];
                        }
                    });
                }
                this.coreFiles = allFiles;
                this.combineAllFiles();

            } else {
                const msg = data ? data.errorMessage : 'Unknown error';
                this.showToast('Error', 'Could not load documents: ' + msg, 'error');
                this.coreFiles = [];
            }
        } catch (error) {
            const msg = error.body ? error.body.message : error.message;
            this.showToast('Error', 'Could not load documents: ' + msg, 'error');
            this.coreFiles = [];
        }finally {
            setTimeout(() => {
                this.isLoading = false;
            }, 100);
        }
    }
    

    get hasFiles() {
        return  this.combinedFiles && this.combinedFiles.length > 0;
    }

    get isUploadDisabled() {
        console.log('this._hasEditAccess --> ', this._hasEditAccess);
        return !this._hasEditAccess;
    }

    // --- DRAG AND DROP ---

    handleDragOver(event) {
        if (!this._hasEditAccess) return; // Prevent drag if user lacks edit access
        event.preventDefault();
        this.isDragging = true;
    }

    handleDragLeave(event) {
        if (!this._hasEditAccess) return; // Prevent drag if user lacks edit access
        event.preventDefault();
        this.isDragging = false;
    }

    handleDrop(event) {
        event.preventDefault();
        this.isDragging = false;

        if (!this._hasEditAccess) return; // Prevent drop if user lacks edit access
        if (!this.lineId) {
            this.showToast('Error', 'Opportunity does not have an ID', 'error');
            return;
        }

        if (event.dataTransfer.files && event.dataTransfer.files.length > 0) {
            this.openModal(event.dataTransfer.files[0]);
        }
    }

    // --- DIALOG ---

    openModal(file) {
        this.selectedFile = file;
        if (!this.isModalOpen) {
             this.selectedDocType = '';
        }
        this.isModalOpen = true;
    }

    handleModalCancel() {
        this.isModalOpen = false;
        this.selectedFile = null;
        this.selectedDocType = '';
    }

    // Tracks the extra properties for later use (e.g., 'OTHR', '7901')
    @track selectedTaxonomyMetadata = {}; 

    handleDocTypeChange(event) {
        const selectedVal = event.detail.value;
        
        // Find the full object from our sorted list
        const selectedOption = this.docTypeOptions.find(opt => opt.value === selectedVal);
        
        if (selectedOption) {
            // If it's from the DB, it has a docTypeCode. If it's a base option, the value ITSELF is the docType.
            this.selectedDocType = selectedOption.docTypeCode || selectedOption.value;
            
            // Save the extra DB properties in memory for when you need them later
            this.selectedTaxonomyMetadata = {
                taxonomyValue: selectedOption.docTypeCode ? selectedOption.value : null,
                externalId: selectedOption.externalId || null,
                entific: selectedOption.entific || null,
                catalogCode: selectedOption.catalogCode || null
            };
        }
        console.log('Selected Doc Type:', this.selectedDocType);
        console.log('Selected Taxonomy Metadata:', JSON.stringify(this.selectedTaxonomyMetadata));
    }

    get selectedFileName() {
        return this.selectedFile ? this.selectedFile.name : '';
    }

    get isModalUploadDisabled() {
        return !this.selectedFile || !this.selectedDocType;
    }

    async handleModalUpload() {
        console.log('🔵 [UPLOAD BUTTON CLICKED] handleModalUpload() invoked at', new Date().toLocaleTimeString());
    
        if (!this.selectedFile || !this.selectedDocType) return;

        this.isModalOpen = false;
        this.isLoading = true;

        try {
            const finalFileName = this.formatFileNameWithDate(this.selectedFile.name);
            const fileId = await this.uploadFile(this.selectedFile, finalFileName);
            
            // Determine objectCode: Use taxonomyValue if available, otherwise fallback to the base docType
            const targetObjectCode = (Object.keys(this.selectedTaxonomyMetadata).length > 0 && this.selectedTaxonomyMetadata.taxonomyValue) 
                ? this.selectedTaxonomyMetadata.taxonomyValue 
                : this.selectedDocType;
            
            console.log('targetObjectCode to update in Apex --> ', targetObjectCode);

            // Pass the 5th parameter securely to Apex
            await updateFileMetadataWithObjectCode({
                fileId: fileId,
                fileName: finalFileName,
                docType: this.selectedDocType,
                folderId: this.lineId,
                objectCode: targetObjectCode
            });

            this.showToast('Success', 'File uploaded successfully', 'success');

            // Reset guard so loadDocuments fetches fresh data after upload
            this._lastLoadedLineId = null;
            await this.loadDocuments();

            console.log('--- POST UPLOAD FOLLOW UP ---');
            
            // Safely check if the object is populated with keys
            if (Object.keys(this.selectedTaxonomyMetadata).length > 0 && this.selectedTaxonomyMetadata.taxonomyValue) {
                console.log('✅ Taxonomy metadata is fully populated and ready:', JSON.stringify(this.selectedTaxonomyMetadata));
                
                // Call Apex to concatenate the value in SYSTEM_MODE
                const appendResult = await appendTaxonomyValue({
                    recordId: this.recordId,
                    objectApiName: this.objectApiName,
                    recordTypeDevName: this.recordTypeDevName,
                    taxonomyValue: this.selectedTaxonomyMetadata.taxonomyValue
                });
                
                console.log('✅ Apex Concatenation Result:', appendResult);
                
                // If taxonomy saved successfully, imperatively update the Passport payload
                /* if (this.clientId) {
                    console.log('🚀 Triggering Passport Service Update...');
                    try {
                        console.log('this.recordId --> ', this.recordId);
                        console.log('this.clientId --> ', this.clientId);
                        console.log('this.objectApiName --> ', this.objectApiName);
                        const passportResult = await triggerPassportUpdate({
                            recordId: this.recordId,
                            clientId: this.clientId,
                            objectApiName: this.objectApiName
                        });
                        console.log('✅ Passport Update Result:', passportResult);

                    } catch (passportErr) {
                        console.error('❌ Passport Update Failed:', passportErr);
                        // We show a warning toast, but we don't crash the upload process since the file is already safe in CoreDocs
                        this.showToast('Warning', 'Document uploaded, but Passport update failed. Please refresh manually.', 'warning');
                    }
                } else {
                    console.error('❌ Cannot trigger Passport: clientId is missing.');
                } */
                
            } else {
                console.log('ℹ️ No extra taxonomy metadata (User selected a Base Option).');
            }
            

        } catch (error) {
            const msg = error.body ? error.body.message : error.message;
            this.showToast('Error', msg, 'error');
        } finally {
            this.isLoading = false;
            this.selectedFile = null;
            this.selectedDocType = '';
        }
    }

    // --- UPLOAD ---

    handleUploadClick() {
        if (!this.lineId) {
            this.showToast('Error', 'Opportunity does not have an ID', 'error');
            return;
        }

        const fileInput = this.template.querySelector('.hidden-file-input');
        fileInput.value = null;
        fileInput.click();
    }

    handleModalSelectFile() {
        const fileInput = this.template.querySelector('.hidden-file-input');
        fileInput.value = null;
        fileInput.click();
    }

    handleFileSelected(event) {
        const file = event.target.files[0];
        if (!file) return;
        if (this.isModalOpen) {
            this.selectedFile = file;
        } else {
            this.openModal(file);
        }
    }

    async uploadFile(file, newName) {

        const config = await getUploadConfig();
        console.log('File Name 1 ---> ', file);
        console.log('newName  ---> ', newName);
        // Generamos el nombre limpio con la fecha de "ahora"
        const formData = new FormData();
        const renamedFile = new File([file], newName, { type: file.type });
        console.log('File Name 2 ---> ', renamedFile);
        formData.append('file', renamedFile);
        //Send the mapped "active" folder details to the backend
        formData.append('opportunityId', this.lineId);
        formData.append('folderId', this.lineId);

        const response = await fetch(config.endpoint, {
            method: 'POST',
            headers: config.headers,
            body: formData
        });

        if (!response.ok) {
            throw new Error(response.statusText);
        }

        const result = await response.json();
        // Assuming the response structure matches the mock: { data: { fileId: "..." } }
        if (result && result.data && result.data.fileId) {
            return result.data.fileId;
        } else {
            throw new Error('File ID not found in upload response');
        }
    }

    // --- DOWNLOAD ---

    async handleRowAction(event) {

        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'delete') {
            //await this.handleDeleteDocument(row);
            return;
        }

        if (actionName === 'download') {
            try {
                let fileName = row.cleanName || row.name;
                const isPdf = this.isPdfFile(fileName);

                if (!isPdf) {
                    this.isModaViewOpen = false;
                    this.isPreviewLoading = false;
                    //window.alert('Preview is not available for this file type.');

                    let downloadSuccess = false;
                    if (row.isAttachment) {
                        this.triggerDirectDownload(row.link, fileName);
                        downloadSuccess = true;
                    } else {
                        try {
                            const payload = await downloadFileBase64({ contentLocator: row.contentLocator });
                            if (payload && payload.base64Data) {
                                console.log(`Downloading file: ${fileName}, MIME type received: ${payload.contentType}`);
                                const blob = this.base64ToBlob(payload.base64Data, payload.contentType);
                                console.log(`Blob created with type: ${blob.type}`);
                                this.downloadBlob(blob, fileName);
                                downloadSuccess = true;
                            } else {
                                throw new Error('No data received from download');
                            }
                        } catch (error) {
                            console.error('Error in Core document download:', error);
                            console.error('Full error details:', JSON.stringify(error));
                            this.showToast('Error', `Failed to download file: ${error.message}`, 'error');
                        }
                    }

                    if (downloadSuccess) {
                        this.showToast('Success', `File ${fileName} downloaded successfully`, 'success');
                    }
                    return;
                }

                // EVALUAMOS SI ES UN ARCHIVO DE SALESFORCE (ATTACHMENT)
                if (row.isAttachment) {
                    this.isModaViewOpen = true;
                    this.isPreviewLoading = true;
                    // Si es PDF, pedimos el Base64 a Apex para evitar el CORS
                    const base64Data = await getAttachmentBase64({ attachmentId: row.id });
                    
                    // Pasamos el Base64 directamente al previsualizador
                    this.pdfData = base64Data;
                    await Promise.resolve(); // Esperamos que el DOM se actualice
                    
                    const previewPdf = this.template.querySelector('c-preview-pdf');
                    if (previewPdf) {
                        previewPdf.preview(this.pdfData,fileName);
                        this.isPreviewLoading = false;
                    }

                // EVALUAMOS SI ES UN CORE DOCUMENT
                } else {
                    const endpoint = await getDownloadEndpoint({ contentLocator: row.contentLocator });
                    this.isModaViewOpen = true;
                    this.isPreviewLoading = true;

                    const headers = await getDownloadHeaders();
                    const response = await fetch(endpoint, {
                        method: 'GET',
                        headers: headers
                    });

                    if (!response.ok) {
                        throw new Error(response.statusText);
                    }

                    const blob = await response.blob();

                    // Flujo original para PDFs del Core
                    await this.previewPdf(blob, fileName);
                    this.isPreviewLoading = false;
                }

            } catch (error) {
                console.error('Error en handleRowAction:', error);
                this.isModaViewOpen = false;
                this.isPreviewLoading = false;
                this.showToast('Error', `Failed to process the file: ${error.message}`, 'error');
            }
/*             const endpoint = await getDownloadEndpoint({
                contentLocator: row.contentLocator
            });
            const headers = await getDownloadHeaders();

            const response = await fetch(endpoint, {
                method: 'GET',
                headers: headers
            });

            if (!response.ok) {
                throw new Error(response.statusText);
            }

            const blob = await response.blob();
            console.log('blob.type--> ', blob.type);
            if(blob.type !== 'application/pdf'){
                const link = document.createElement('a');
                link.href = URL.createObjectURL(blob);
                link.download = row.name;
                document.body.appendChild(link);
                link.click();   
                document.body.removeChild(link);
                URL.revokeObjectURL(link.href);

            }else{
                await this.previewPdf(blob);
                
            }

 

            
            this.showToast('Success', 'File downloaded successfully', 'success'); */

        }
    }
    isPdfFile(fileName) {
        return !!fileName && fileName.toLowerCase().endsWith('.pdf');
    }

    triggerDirectDownload(url, fileName) {
        const link = document.createElement('a');
        link.href = url;
        link.target = '_blank';
        if (fileName) {
            link.download = fileName;
        }
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }

    downloadBlob(blob, fileName) {
        try {
            // LWS requires application/octet-stream for URL.createObjectURL
            // Recreate blob with safe MIME type if needed
            let downloadBlob = blob;
            if (blob.type && blob.type !== 'application/octet-stream' && blob.type !== 'application/pdf') {
                console.log(`Recreating blob with safe MIME type. Original: ${blob.type}`);
                downloadBlob = new Blob([blob], { type: 'application/octet-stream' });
            }
            
            const blobUrl = URL.createObjectURL(downloadBlob);
            const link = document.createElement('a');
            link.href = blobUrl;
            link.download = fileName;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            
            // Revocamos la URL después de un delay para asegurar que se completó la descarga
            setTimeout(() => {
                URL.revokeObjectURL(blobUrl);
            }, 100);
        } catch (error) {
            console.error('Error downloading blob:', error);
            this.showToast('Error', `Failed to download file: ${error.message}`, 'error');
        }
    }

    async previewPdf(blob, fileName) {
        this.isPreviewLoading = false;
        try {
            this.pdfData = await  this.blobToBase64(blob);
            
            await Promise.resolve();
            const previewPdf = this.template.querySelector('c-preview-pdf');
            if (previewPdf) {
                console.log('The file name received --> ' + fileName);
                previewPdf.preview(this.pdfData,fileName);
            } else {
                console.error('previewPdf component not found in CD.');
            }
        } catch (error) {
            console.error('Error in previewPdf CD:',JSON.stringify(error));
            throw new Error('Failed to preview PDF in CD.');
        }
    }
    blobToBase64(blob) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onloadend = () => {
                const base64String = reader.result.split(',')[1];
                resolve(base64String);
            };
            reader.onerror = reject;
            reader.readAsDataURL(blob);
        });
    }

    base64ToBlob(base64Data, contentType) {
        // Validate base64Data early
        if (typeof base64Data !== 'string' || base64Data.length === 0) {
            throw new Error('Invalid base64 data: expected non-empty string');
        }

        // Determine MIME type with fallback strategy
        let mimeType = 'application/octet-stream'; // Default safe MIME type
        
        // If contentType is provided and valid, use it
        if (contentType && VALID_MIME_TYPES[contentType]) {
            mimeType = contentType;
        } else if (contentType) {
            // Map common MIME type variations to valid ones
            const mimeTypeMap = {
                'application/word': 'application/msword',
                'application/x-msword': 'application/msword',
                'application/vnd.ms-word': 'application/msword',
                'application/vnd.ms-office': 'application/octet-stream',
                'application/x-zip': 'application/zip',
                'application/x-zip-compressed': 'application/zip'
            };
            
            if (mimeTypeMap[contentType]) {
                mimeType = mimeTypeMap[contentType];
            } else {
                console.warn(`Unknown MIME type "${contentType}", using application/octet-stream`);
                mimeType = 'application/octet-stream';
            }
        }

        try {
            // Decode base64 safely and convert to Uint8Array
            const binaryString = window.atob(base64Data);
            const bytes = new Uint8Array([...binaryString].map(char => char.charCodeAt(0)));
            return new Blob([bytes], { type: mimeType });
        } catch (error) {
            const msg = error.message || 'Unknown error';
            console.error(`Base64 conversion failed: ${msg}`);
            throw new Error(`Failed to process file data: ${msg}`);
        }
    }

    // --- DELETE ---

    async handleDeleteDocument(row) {
        if (row.isAttachment || !this.canDeleteDocuments || !this._hasEditAccess) {
            return; // Icon is disabled in this case; guard against programmatic/stale invocations
        }
        const fileLabel = row.cleanName || row.name;
        const confirmed = await LightningConfirm.open({
            message: `Are you sure you want to delete "${fileLabel}"? This action cannot be undone.`,
            variant: 'header',
            label: 'Confirm document deletion',
            theme: 'warning'
        });
        if (!confirmed) {
            return;
        }
        //JIRA 4332
        /*try {
            await deleteDocument({
                recordId: this.recordId,
                fileId: row.id,
                contentLocator: row.contentLocator
            });
            this.showToast('Success', `Document "${fileLabel}" deleted successfully`, 'success');
            // Only refresh from CoreDocuments after a confirmed deletion — never remove the row locally
            await this.loadDocuments();
        } catch (error) {
            const msg = error.body ? error.body.message : error.message;
            this.showToast('Error', `Could not delete the document: ${msg}`, 'error');
        }*/
    }

    formatFileNameWithDate(originalName) {
        const now = new Date();
        const dateStamp = `${now.getDate()}-${now.getMonth() + 1}-${now.getFullYear()}`;
        
        // Cambiamos espacios por guiones para el nombre físico del archivo
        const safeUserName = this.currentUserName ? this.currentUserName.replace(/\s+/g, '-') : 'Anonimo';
    
        const lastDotIndex = originalName.lastIndexOf('.');
        let baseName = lastDotIndex !== -1 ? originalName.substring(0, lastDotIndex) : originalName;
        const extension = lastDotIndex !== -1 ? originalName.substring(lastDotIndex) : '';
    
        // Limpiamos subidas previas para no repetir
        baseName = baseName.split('__')[0].trim();
    
        // Estructura: NombreArchivo__DD-MM-YYYY__Usuario.ext
        return `${baseName}__${dateStamp}__${safeUserName}${extension}`;
    }
    combineAllFiles() {
        // Combinamos ambos arrays. Delete only applies to CoreDocuments files, not Salesforce Attachments.
        const rawList = [...this.attachments, ...this.coreFiles].map(file => ({
            ...file,
            deleteDisabled: file.isAttachment
                || !this.canDeleteDocuments
                || !this._hasEditAccess
        }));
    
        // Ordenamos por fecha (Descendente: más nuevo arriba)
        this.combinedFiles = rawList.sort((a, b) => {
            // Convertimos a objeto Date para comparar. 
            // Si uploadDate es 'N/A', lo mandamos al final.
            const dateA = a.uploadDate !== 'N/A' ? new Date(this.parseDate(a.uploadDate)) : new Date(0);
            const dateB = b.uploadDate !== 'N/A' ? new Date(this.parseDate(b.uploadDate)) : new Date(0);
            
            return dateB - dateA; 
        });
    
        this.size = this.combinedFiles.length;
    }
    
    /**
     * Función auxiliar para normalizar fechas manuales (DD-MM-YYYY) 
     * a un formato que el constructor de Date entienda (YYYY-MM-DD)
     */
    parseDate(dateStr) {
        if (!dateStr || dateStr === 'N/A') return 0;
        // Si ya viene con guiones (DD-MM-YYYY), lo reordenamos
        const parts = dateStr.split('-');
        if (parts.length === 3) {
            return `${parts[2]}-${parts[1]}-${parts[0]}`;
        }
        return dateStr; // Si ya es formato estándar
    }

    formatDisplayDate(dateValue) {
        if (!dateValue) return 'N/A';

        const rawValue = String(dateValue);
        const datePart = rawValue.includes('T') ? rawValue.split('T')[0] : rawValue;
        const parts = datePart.split('-');

        if (parts.length === 3) {
            const year = parts[0];
            const month = String(parseInt(parts[1], 10));
            const day = String(parseInt(parts[2], 10));

            if (!isNaN(day) && !isNaN(month) && !isNaN(parseInt(year, 10))) {
                return `${day}-${month}-${year}`;
            }
        }

        const parsed = new Date(rawValue);
        if (!isNaN(parsed.getTime())) {
            return `${parsed.getDate()}-${parsed.getMonth() + 1}-${parsed.getFullYear()}`;
        }

        return 'N/A';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    closeModal() {
        this.isModaViewOpen = false;
        this.pdfData = null;
    }

}