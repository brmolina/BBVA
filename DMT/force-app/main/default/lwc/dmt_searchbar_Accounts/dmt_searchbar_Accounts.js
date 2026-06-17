import { LightningElement, api } from 'lwc';

export default class Dmt_searchbar_accounts extends LightningElement {
    @api filter;

    handleChange(event) {
        const filter = event.target.value;
        const selectedAccount = new CustomEvent('selectedAccount', {
            bubbles: true,
            composed: true,
            detail: filter
        });
        this.dispatchEvent(selectedAccount);
    }
}