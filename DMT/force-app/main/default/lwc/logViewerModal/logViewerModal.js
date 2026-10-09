import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class LogViewerModal extends LightningModal {
    @api content;   // The Log Body text
    @api isLoading; // Spinner state

    handleClose() {
        this.close('okay');
    }
}