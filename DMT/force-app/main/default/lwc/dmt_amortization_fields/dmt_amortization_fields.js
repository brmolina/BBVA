import { LightningElement, api } from 'lwc';

export default class BbvaAmortizationFields extends LightningElement {

    @api isEdit = false;

    // Valores por defecto para pruebas en FlexCard
    @api DMT_NewMoney_BBVA__c = 1000000.00;
    @api DMT_OldMoney_BBVA__c = 500000.00;
    @api DMT_ExpectedFinal_Take__c = 1200000.00;
    @api DMT_Expected_Drawn__c = 65;
    @api DMT_Extension_Duration_Fees__c = 35;
    @api DMT_PricingGrid_OR_StepUps__c = "Pricing grid sample text for testing";

    connectedCallback() {
        window.addEventListener("editModeEvent", this.handleEditMode);
    }

    disconnectedCallback() {
        window.removeEventListener("editModeEvent", this.handleEditMode);
    }

    handleEditMode = (event) => {
        this.isEdit = event.detail?.isEdit;
    }

    handleChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;

        this[field] = value;

        this.dispatchEvent(new CustomEvent("change", {
            detail: { field, value }
        }));
    }
}