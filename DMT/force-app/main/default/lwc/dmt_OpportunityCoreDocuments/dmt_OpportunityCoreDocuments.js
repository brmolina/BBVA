import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import OPP_ID_FIELD from '@salesforce/schema/Opportunity.DMT_Opp_Id__c';
import getDocuments from '@salesforce/apex/DMT_OpportunityCoreDocuments.getDocuments';
import getDownloadHeaders from '@salesforce/apex/DMT_OpportunityCoreDocuments.getDownloadHeaders';
import getUploadHeaders from '@salesforce/apex/DMT_OpportunityCoreDocuments.getUploadHeaders';
import getUploadEndpoint from '@salesforce/apex/DMT_OpportunityCoreDocuments.getUploadEndpoint';
import getDownloadEndpoint from '@salesforce/apex/DMT_OpportunityCoreDocuments.getDownloadEndpoint';
import updateFileMetadata from '@salesforce/apex/DMT_OpportunityCoreDocuments.updateFileMetadata';

const COLUMNS = [
    { 
        label: 'View', 
        type: 'button-icon', 
        initialWidth: 50,
        cellAttributes: { style: 'text-align: center;' },
        typeAttributes: {
            iconName: 'action:preview',
            title: 'Click to View',
            name: 'download',
            variant: 'border-filled',
            alternativeText: 'View',
        }
    },
    {
        label: 'File Name',
        type: 'text',
        fieldName: 'name',
        initialWidth: 400,
        cellAttributes: {
            iconName: { fieldName: 'iconName' }, 
            iconPosition: 'left',
            class: 'file-name-cell'
        },
        wrapText: true
    },
    { label: 'Document Type', fieldName: 'documentTypeLabel', type: 'text', initialWidth: 300 }

];

const DOC_TYPES = [
    { label: 'Descripción de la oportunidad / Línea', value: 'CO-OF-00240' },
    { label: 'Documentos de soporte de validaciones / aprobaciones', value: 'CO-OF-00241' },
    { label: 'Dictamen Oportunidad / Línea', value: 'CO-OF-00242' }
];

export default class Dmt_OpportunityCoreDocuments extends LightningElement {
    @api recordId;
    dmtOppId;

    @wire(getRecord, { recordId: '$recordId', fields: [OPP_ID_FIELD] })
    wiredRecord({ error, data }) {
        if (data) {
            this.dmtOppId = getFieldValue(data, OPP_ID_FIELD);
            if (this.dmtOppId) {
                this.loadDocuments();
            } else {
                this.isLoading = false;
            }
        } else if (error) {
            console.error('Error loading opportunity record', error);
            this.showToast('Error', 'Could not load Opportunity ID', 'error');
            this.isLoading = false;
        }
    }

    @track files = [];
    @track isLoading = true;
    @track isDragging = false;
    @track isModalOpen = false;
    @track selectedFile = null;
    @track selectedDocType = '';
    @track isModaViewOpen = false;
    @track pdfData;

    columns = COLUMNS;
    docTypeOptions = DOC_TYPES;

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
        if (!this.dmtOppId) {
            this.isLoading = false;
            return;
        }
        this.isLoading = true;
        try {
            const data = await getDocuments({ opportunityId: this.dmtOppId });
            if (data && data.success) {
                console.log('core documenr child getDocuments-->');
                let allFiles = [];
                if (data.data && Array.isArray(data.data)) {
                    data.data.forEach(folder => {
                        if (folder.children && Array.isArray(folder.children)) {
                            const folderFiles = folder.children.map(child => {
                                console.log('core documenr child -->', JSON.stringify(child));
                                const docTypeEntry = DOC_TYPES.find(dt => dt.value === child.documentType);
                                return {
                                    ...child,
                                    name: child.objectName,
                                    documentTypeLabel: docTypeEntry ? docTypeEntry.label : child.documentType,
                                    type: child.documentType,
                                    folderCode: folder.businessCode ? folder.businessCode.folderCode : '',
                                    iconName: this.getIconName(child.objectName)
                                };
                            });
                            allFiles = [...allFiles, ...folderFiles];
                        }
                    });
                }
                this.files = allFiles;

            } else {
                const msg = data ? data.errorMessage : 'Unknown error';
                this.showToast('Error', 'Could not load documents: ' + msg, 'error');
                this.files = [];
            }
        } catch (error) {
            const msg = error.body ? error.body.message : error.message;
            this.showToast('Error', 'Could not load documents: ' + msg, 'error');
            this.files = [];
        } finally {
            this.isLoading = false;
        }
    }

    get hasFiles() {
        return  this.files && this.files.length > 0;
    }

    get isUploadDisabled() {
        return false;
    }

    // --- DRAG AND DROP ---

    handleDragOver(event) {
        event.preventDefault();
        this.isDragging = true;
    }

    handleDragLeave(event) {
        event.preventDefault();
        this.isDragging = false;
    }

    handleDrop(event) {
        event.preventDefault();
        this.isDragging = false;

        if (!this.dmtOppId) {
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

    handleDocTypeChange(event) {
        this.selectedDocType = event.detail.value;
    }

    get selectedFileName() {
        return this.selectedFile ? this.selectedFile.name : '';
    }

    get isModalUploadDisabled() {
        return !this.selectedFile || !this.selectedDocType;
    }

    async handleModalUpload() {
        if (!this.selectedFile || !this.selectedDocType) return;

        this.isModalOpen = false;
        this.isLoading = true;

        try {
            const fileId = await this.uploadFile(this.selectedFile);
            await updateFileMetadata({
                fileId: fileId,
                fileName: this.selectedFile.name,
                docType: this.selectedDocType,
                opportunityId: this.dmtOppId
            });

            this.showToast('Success', 'File uploaded successfully', 'success');
            await this.loadDocuments();
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
        if (!this.dmtOppId) {
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

    async uploadFile(file) {
        const endpoint = await getUploadEndpoint();
        const headers = await getUploadHeaders();

        const formData = new FormData();
        formData.append('file', file);

        //Send the mapped "active" folder details to the backend
        formData.append('opportunityId', this.dmtOppId);
        formData.append('folderId', this.dmtOppId);

        const response = await fetch(endpoint, {
            method: 'POST',
            headers: headers,
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
        this.isModaViewOpen = true;
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        console.log('actionName --> ', actionName);
        console.log('row --> ', JSON.stringify(row) );
        if (actionName === 'download') {

            const endpoint = await getDownloadEndpoint({
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

            await this.previewPdf(blob);
            this.selectedFileName = row.name;
            
            this.showToast('Success', 'File downloaded successfully', 'success');

        }
    }
    async previewPdf(blob) {
        try {
            this.pdfData = await  this.blobToBase64(blob);

            await Promise.resolve();

            const previewPdf = this.template.querySelector('c-preview-pdf');
            if (previewPdf) {
                previewPdf.preview(this.pdfData);
            } else {
                console.error('previewPdf component not found in CD.');
            }
        } catch (error) {
            console.error('Error in previewPdf CD:', error);
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
    closeModal() {
        this.isModaViewOpen = false;
        this.pdfData = null;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}