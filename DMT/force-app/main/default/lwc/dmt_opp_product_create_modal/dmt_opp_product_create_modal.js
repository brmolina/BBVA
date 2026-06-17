import { LightningElement, api } from 'lwc';
import LightningModal        from 'lightning/modal';
import { ShowToastEvent }    from 'lightning/platformShowToastEvent';
import createProductsOpportunity from '@salesforce/apex/DMT_OpportunityProductsController.createProductsOpportunity';

export default class dmt_opp_product_create_modal extends LightningModal {

    @api recordId;
    @api contextCode;

    filterInput    = '';
    productsToSend = [];
    isSaving       = false;

    get isSaveDisabled() {
        return this.isSaving || !this.productsToSend || this.productsToSend.length === 0;
    }

    handleClose() {
        this.close(false);
    }

    handleInput(event) {
        this.filterInput = event.target.value;
    }

    handleProductsToSend(event) {
        this.productsToSend = event.detail.selectedCodesId || [];
    }

    async handleSave() {
        this.isSaving = true;
        try {
            const result = await createProductsOpportunity({
                products     : this.productsToSend,
                opportunityId: this.recordId
            });
            if (result && result.created) {
                this._toast('Products Created', 'Products were added successfully.', 'success');
                this.close(result);
            } else {
                this._toast('Error', result.errorMessage || 'There was a problem adding the products.', 'error');
            }
        } catch (error) {
            const msg = error?.body?.message || 'Unknown error';
            this._toast('Unexpected Error', msg, 'error');
        } finally {
            this.isSaving = false;
        }
    }

    _toast(title, message, variant = 'info') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}