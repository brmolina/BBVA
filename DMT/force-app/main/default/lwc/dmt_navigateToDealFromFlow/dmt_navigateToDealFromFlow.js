import { api, LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Dmt_navigateToDealFromFlow extends LightningElement {
    @api recordAcc;
    @api invoke() {
        this.dispatchEvent(new ShowToastEvent({
            title: 'True delete success',
            message: 'The line and all records associated with it have been successfully deleted. You will be redirected to Deal Management',
            variant: 'success',
            mode: 'sticky'
        }));

        setTimeout(() => {
            window.open(window.location.origin + '/lightning/n/DMT_Page?c__recordId=' + this.recordAcc, '_self');
        }, 2000);
    }
}