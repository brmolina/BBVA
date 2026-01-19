import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import OPP_ID_FIELD from '@salesforce/schema/Opportunity.DMT_Opp_Id__c';
import getDocuments from '@salesforce/apex/DMT_OpportunityCoreDocuments.getExpedientFolders';
import uploadFileToApex from '@salesforce/apex/DMT_OpportunityCoreDocuments.uploadFile';
import downloadFile from '@salesforce/apex/DMT_OpportunityCoreDocuments.downloadFile';
import updateFileMetadata from '@salesforce/apex/DMT_OpportunityCoreDocuments.updateFileMetadata';

const COLUMNS = [
    {
        label: 'File Name',
        type: 'button',
        typeAttributes: {
            label: { fieldName: 'name' },
            name: 'download',
            variant: 'base',
            title: 'Click to download',
            iconName: { fieldName: 'iconName' },
            iconPosition: 'left'
        },
        cellAttributes: {
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
                let allFiles = [];
                if (data.data && Array.isArray(data.data)) {
                    data.data.forEach(folder => {
                        if (folder.children && Array.isArray(folder.children)) {
                            const folderFiles = folder.children.map(child => {
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
        return this.files && this.files.length > 0;
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
        console.log('DEBUG: Starting upload via Apex proxy');
        console.log('DEBUG: File:', file.name, file.size, file.type);

        return new Promise((resolve, reject) => {
            const fileReader = new FileReader();
            fileReader.onload = async () => {
                try {
                    const fileContent = fileReader.result.split(',')[1];

                    const fileId = await uploadFileToApex({
                        fileName: file.name,
                        base64Data: fileContent,
                        fileType: file.type || 'application/octet-stream'
                    });

                    console.log('DEBUG: Upload successful, fileId:', fileId);
                    resolve(fileId);
                } catch (error) {
                    console.error('Upload failed:', error);
                    reject(error);
                }
            };
            fileReader.onerror = (error) => reject(error);
            fileReader.readAsDataURL(file);
        });
    }

    // --- DOWNLOAD ---

    async handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'download') {
            this.isLoading = true;
            try {
                const base64Content = await downloadFile({ contentLocator: row.contentLocator });
                this.downloadBase64File(base64Content, row.name);
                this.showToast('Success', 'File downloaded successfully', 'success');
            } catch (error) {
                const msg = error.body ? error.body.message : error.message;
                this.showToast('Error', 'Could not download file: ' + msg, 'error');
            } finally {
                this.isLoading = false;
            }
        }
    }

    downloadBase64File(base64Data, fileName) {
        const byteCharacters = atob(base64Data);
        const byteNumbers = new Array(byteCharacters.length);
        for (let i = 0; i < byteCharacters.length; i++) {
            byteNumbers[i] = byteCharacters.charCodeAt(i);
        }
        const byteArray = new Uint8Array(byteNumbers);
        const blob = new Blob([byteArray], { type: 'application/octet-stream' });

        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = fileName;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(link.href);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}