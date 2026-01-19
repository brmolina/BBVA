import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import verifyAccess from '@salesforce/apex/Account_NPS_ButtonCnt.verifyAccess';

export default class NpsManager extends LightningElement {

    @api recordId;
    @track error;
    @track success;
    @track openmodel = false;
    @track isChecked;
    @track resCheckData;
    @track hasAccess
    @track resultNPS;
    @track displayUpdate = false;
    @track pending = false;



    openmodal() {
        this.openmodel = true;
    }
    closeModal() {
        this.openmodel = false;
        this.resetDefaulValues();
    }
    saveMethod() {
        this.closeModal();
    }
    // method for verifyAccess
    connectedCallback() {
        verifyAccess({ recordId: this.recordId })
            .then(result => {
                let res = JSON.parse(result);
                this.hasAccess = res.userWithAccess;
                this.resCheckData = res;
                this.error = null;

            })
            .catch(error => {
                this.hasAccess = null;
                this.error = error;

            });
    }
    handleSubmit(event) {
        this.pending = true;
    }
    handleSuccess(event) {
        const updatedRecord = event.detail.id;

        if (updatedRecord) {
            this.resetDefaulValues();
            this.dispatchEvent(
                new ShowToastEvent({
                    title: ' NPS updated successfully',
                    message: 'NPS has been changed successfully',
                    variant: 'success',
                }),
            );
            this.closeModal();
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error while updating NPS in this Client, please contact with your Admin',
                    variant: 'error',
                }),
            );
        }
    }
    toggleUpdateButton() {
        if (this.displayUpdate) {
            this.displayUpdate = false;
        } else {
            this.displayUpdate = true;
        }
    }
    resetDefaulValues() {
        this.displayUpdate = false;
        this.pending = false;
    }
}