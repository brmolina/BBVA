import { LightningElement, api, wire , track} from 'lwc';
import getAttachments from '@salesforce/apex/DMT_AttachmentController.getAttachments';
import uploadAttachment from '@salesforce/apex/DMT_AttachmentController.uploadAttachment';
import deleteAttachment from '@salesforce/apex/DMT_AttachmentController.deleteAttachment';
import hasEditAccess from '@salesforce/apex/DMT_AttachmentController.hasEditAccess';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { getRecord } from 'lightning/uiRecordApi';
import { getRecordUi } from 'lightning/uiRecordApi';
import { getRecords } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
const  DTM_FIELDS = ['DMT_TeamMember__c.Id', 'DMT_TeamMember__c.AccessLevel__c'];
import DMT_LINE_OBJECT from '@salesforce/schema/DMT_Line__c';
import OWNER_ID_FIELD from '@salesforce/schema/DMT_Line__c.OwnerId';
import OWNER_ID_FIELD_OPP from '@salesforce/schema/Opportunity.OwnerId';

export default class DMT_upload_files extends LightningElement {
    @api recordId;
    filesToUpload = [];
    showEditControls = false;
    isLoading = false;
    wiredAttachmentsResult;
    @track attachments = [];
    MAX_FILE_SIZE_KB = 4;
    size;
    fields;
    objectApiName
    columns = [
        {
            label: 'Title',
            fieldName: 'link',
            type: 'url',
            hideDefaultActions:true,
            typeAttributes: { label: { fieldName: 'name' }, target: '_blank' },

        },
        { label: 'Owner',hideDefaultActions:true, fieldName: 'createdBy' },
        { label: 'Upload Date',hideDefaultActions:true, fieldName: 'createdDate', type: 'date', typeAttributes : {
            day:'2-digit',
            month:'2-digit',
             year:'2-digit',
             hour:'2-digit',
             minute:'2-digit'
            }
        },
        { label: 'Size (KB)',hideDefaultActions:true, fieldName: 'sizeKb', type: 'text' },
        // {
        //     type: 'action',
        //     typeAttributes: {
        //         rowActions: [
        //             { label: 'Delete', name: 'delete' }
        //         ]
        //     }
        // }
    ];
    @wire(getRecordUi, { recordIds: '$recordId', layoutTypes: ['Full'], modes: ['View'] })
    recordUiHandler({ data, error }) {
        if (data) {
            this.objectApiName = data.records[this.recordId].objectApiName;

            if (this.objectApiName === 'Opportunity') {
                this.fields = [OWNER_ID_FIELD_OPP];
            } else if (this.objectApiName === 'DMT_Line__c') {
                this.fields = [OWNER_ID_FIELD];
            }
        } else if (error) {
            console.error('Error fetching record UI metadata:', error);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields:'$fields' })
    lineRecord;

    @wire(hasEditAccess, { recordId: '$recordId' })
    handleHasEditAccess(result) {console.log('resulkt',JSON.stringify(result.data))
        if (result.data) {
            this.showEditControls = true;
            this.columns = [
                {
                    label: 'Title',
                    fieldName: 'link',
                    type: 'url',
                    hideDefaultActions:true,
                    typeAttributes: { label: { fieldName: 'name' }, target: '_blank' },
        
                },
                { label: 'Owner',hideDefaultActions:true, fieldName: 'createdBy' },
                { label: 'Upload Date',hideDefaultActions:true, fieldName: 'createdDate', type: 'date', typeAttributes : {
                    day:'2-digit',
                    month:'2-digit',
                     year:'2-digit',
                     hour:'2-digit',
                     minute:'2-digit'
                    }
                },
                { label: 'Size (KB)',hideDefaultActions:true, fieldName: 'sizeKb', type: 'text' },
                 {
                     type: 'action',
                     typeAttributes: {
                         rowActions: [
                             { label: 'Delete', name: 'delete' }
                         ]
                     }
                 }
            ];
        } else if (result.error) {
            console.error('Erro getting user permission:', result.error);
            this.showErrorToast(result.error);
        }
    }

    @wire(getAttachments, { parentId: '$recordId' })
    wiredAttachments(result) {
        this.wiredAttachmentsResult = result;
        if (result.data) {
            this.attachments = result.data.map(f => ({
                ...f,
                link: `/servlet/servlet.FileDownload?file=${f.id}`,
                createdDateFormatted: new Date(f.createdDate).toLocaleDateString()
            }));
            this.size = this.attachments.length;
        } else if (result.error) {
            console.error('Error when getting attachments:', result.error);
            this.showErrorToast(result.error);
        }
    }

    triggerFileSelect() {
        const fileInput = this.template.querySelector('.hiddenFileInput');
        if (fileInput) {
            fileInput.click();
        }
    }
    
    async handleFileChange(event) {
        this.filesToUpload = Array.from(event.target.files);
        if (this.filesToUpload.length > 0) {
            this.isLoading = true;
            try {
                for (let file of this.filesToUpload) {
                    
                    if(file.size > this.MAX_FILE_SIZE_KB * 1048576) {
                        console.log('file.size', file.size);
                        var error = {message: 'File size too large', name: 'File Size Error', title: 'File Size Error'};
                        this.showErrorToast(error)
                    }
                    else if(file.type != 'application/pdf'){
                        console.log('file.size', file.type);
                        var error = {message: 'Only PDF files are supported', name: 'Unsupported File Type', title: 'File Type Error'};
                        this.showErrorToast(error)
                    }
                    else{
                        const base64 = await this.toBase64(file);
                        await uploadAttachment({
                        parentId: this.recordId,
                        fileName: file.name,
                        base64Data: base64
                    });
                    }
                    
                }
                await refreshApex(this.wiredAttachmentsResult);
            } catch (error) {
                console.error('Error when uploading files:', error);
                this.showErrorToast(error);
            } finally {
                this.isLoading = false;
                this.filesToUpload = [];
            }
        }
    }

    resetFileAttachmentInput(event){
        event.target.value = null;
    }

    showErrorToast(error) {
        let message = 'An unexpected error occurred';
        
        // Intenta extraer mensaje legible del error
        if (error && error.body && error.body.message) {
            message = error.body.message;
        } else if (error && error.message) {
            message = error.message;
        }
    
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: message,
                variant: 'error',
                mode: 'dismissible'
            })
        );
    }

    async uploadFiles() {
        this.isLoading = true;
        try {
            for (let file of this.filesToUpload) {
                const base64 = await this.toBase64(file);
                await uploadAttachment({
                    parentId: this.recordId,
                    fileName: file.name,
                    base64Data: base64
                });
            }
            await refreshApex(this.wiredAttachmentsResult);
            this.filesToUpload = [];
        } catch (error) {
            console.error('Error al subir archivos:', error);
        } finally {
            this.isLoading = false;
        }
    }

    toBase64(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onloadend = () => resolve(reader.result.split(',')[1]);
            reader.onerror = reject;
            reader.readAsDataURL(file);
        });
    }

    async handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
    
        if (actionName === 'delete') {
            this.isLoading = true;
            try {
                await deleteAttachment({ attachmentId: row.id });
                await refreshApex(this.wiredAttachmentsResult);
            } catch (error) {
                console.error('Error al eliminar archivo:', error);
            } finally {
                this.isLoading = false;
            }
        }
    }
}