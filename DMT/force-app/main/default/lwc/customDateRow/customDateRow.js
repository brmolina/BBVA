import { LightningElement, api } from 'lwc';

export default class CustomDateRow extends LightningElement {
    @api aviableItem;
    @api dateValue;
    @api fieldname;
    @api context;
    @api maxdate;
    @api lockDate;

    get isDisabled() {
        return !!this.lockDate || !!this.aviableItem;
    }
    
    handleDateChange(event) {
        this.dateValue = event.target.value;
        console.log("Selected Date:", this.dateValue);
        console.log("maxdate:", this.maxdate);

        this.dispatchEvent(new CustomEvent('customdateinputchanged', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                data: { context: this.context, value: this.dateValue, fieldname: this.fieldname }
            }
        }));
    }
}