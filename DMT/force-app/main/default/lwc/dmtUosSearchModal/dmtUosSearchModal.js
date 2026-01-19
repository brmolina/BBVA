import { LightningElement, api } from 'lwc';

export default class DmtUosSearchModal extends LightningElement {

    @api isOpen=false;
    @api modalHeader="Default Modal";
    @api showHeader;
    saveButtonDisabled = true;

    @api
    updateButtonState(disabled) {
        this.saveButtonDisabled = disabled;
    }

    closeModal() {
        this.isOpen = false;
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }

    saveModal() {
        this.dispatchEvent(new CustomEvent('save'));
    }

}