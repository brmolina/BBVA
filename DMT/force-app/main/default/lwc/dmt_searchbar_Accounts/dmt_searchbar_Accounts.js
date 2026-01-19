import { LightningElement, api } from 'lwc';

export default class Dmt_searchbar_Accounts extends LightningElement {

    @api filter;

    handleChange(event) {
        let filter = event.target.value;
        const selectedAccount = new CustomEvent("selectedAccount", {bubbles:true, composed:true, detail: filter });
        this.dispatchEvent(selectedAccount);
    }
}