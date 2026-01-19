import { LightningElement, api } from 'lwc';

export default class Kpi_detail_button extends LightningElement {

    @api buttonVariant;
    @api buttonLabel;
    @api eventName;
    @api eventValue;

    handleClick() {
        var ev = new CustomEvent(this.eventName, {
            bubbles: true,
            composed: true,
            detail: {
                label: this.buttonLabel,
                value: this.eventValue
            }
        });
        console.log(ev);
        this.dispatchEvent(ev);
    }
}