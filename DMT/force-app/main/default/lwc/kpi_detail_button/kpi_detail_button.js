import { LightningElement, api } from 'lwc';

export default class Kpi_detail_button extends LightningElement {

    @api buttonVariant;
    @api buttonLabel;
    @api eventName;

    handleClick() {
        var ev = new CustomEvent(this.eventName, {
            bubbles: true,
            composed: true,
            data: { label: this.buttonLabel }
        });
        this.dispatchEvent(ev);
    }
}