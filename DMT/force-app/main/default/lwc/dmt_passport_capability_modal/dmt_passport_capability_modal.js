import { LightningElement,api } from 'lwc';

export default class Dmt_passport_capability_modal extends LightningElement {
    @api isOpen=false;
    @api modalHeader="Default Modal";
    @api showHeader;

    closeModal() {
        this.isOpen = false;
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }
    
}