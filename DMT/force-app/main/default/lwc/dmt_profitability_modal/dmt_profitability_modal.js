import { LightningElement } from 'lwc';

export default class Dmt_profitability_modal extends LightningElement {
    isOpen = false;

    openModal() {
        this.isOpen = true;
    }

    closeModal() {
        this.isOpen = false;
    }
}