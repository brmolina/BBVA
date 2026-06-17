import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class Onb_cancelAction extends LightningElement {

    @api recordId;
    notes = '';

    handleNotes(event) {
        this.notes = event.target.value;
    }

    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleCancelProcess() {
        // TODO: handle logic
        this.dispatchEvent(new CloseActionScreenEvent());
    }



}