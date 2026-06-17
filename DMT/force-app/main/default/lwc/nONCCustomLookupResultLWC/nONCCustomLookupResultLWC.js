/*CAMBIOS MIGRACIÓN A LWC GLOBAL BANKER*/
import { api, LightningElement } from 'lwc';

export default class NONCCustomLookupResultLWC extends LightningElement {
    @api record;
    @api iconName = 'standard:account';

    handleSelectRecord() {
        this.dispatchEvent(
            new CustomEvent('recordselected', {
                detail: this.record,
                bubbles: true,
                composed: true
            })
        );
    }

    get recordName() {
        return this.record?.Name || '';
    }
}