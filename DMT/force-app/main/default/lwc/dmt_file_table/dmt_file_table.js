import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getTaskFilesWithAttachments from '@salesforce/apex/DMT_Case_Steps_Controller.getTaskFilesWithAttachments';

export default class Dmt_file_table extends NavigationMixin(LightningElement) {
    @api recordId; // Task Id passed to the component
    @api doReload;
    @track files = [];
    @track error;

    @wire(getTaskFilesWithAttachments, { taskId: '$recordId', reload:'$doReload' })
    wiredFiles({ error, data }) {
        if (data) {
            this.files = data.map(file => ({
                ...file,
                formattedSize: this.formattedFileSize(file.size)
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.files = undefined;
        }
    }

    // Método para formatear el tamaño del archivo
    formattedFileSize(size) {
        return `${(size / 1024).toFixed(2)} KB`;
    }

    handleDownload(event) {
        const id = event.target.dataset.id;
        const file = this.files.find(f => f.contentDocumentId === id);
    
        if (file.type === 'ContentDocument') {
            window.open(`/sfc/servlet.shepherd/document/download/${id}`);
        } else if (file.type === 'Attachment') {
            window.open(`/servlet/servlet.FileDownload?file=${id}`);
        }
    }

    handleOpenFileClick(event) {
        const id = event.currentTarget.dataset.id;
        const file = this.files.find(f => f.contentDocumentId === id);

        if (file.type === 'ContentDocument') {
            this[NavigationMixin.Navigate]({
                type: 'standard__namedPage',
                attributes: { pageName: 'filePreview' },
                state: { selectedRecordId: id }
            });
        } else if (file.type === 'Attachment') {
            window.open(`/servlet/servlet.FileDownload?file=${id}`);
        }
    }
}