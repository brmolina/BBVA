import { LightningElement, api, wire } from 'lwc';
import { refreshApex }            from '@salesforce/apex';
import { ShowToastEvent }         from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue, updateRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import getOpportunityLineItemsByOpportunityId from '@salesforce/apex/DMT_OpportunityProductsController.getOpportunityLineItemsByOpportunityId';
import getRiskTypeOptions                     from '@salesforce/apex/DMT_OpportunityProductsController.getRiskTypeOptions';
import getProductLineTypeOptions              from '@salesforce/apex/DMT_OpportunityProductsController.getProductLineTypeOptions';
import getTaxonomyCatalogValues               from '@salesforce/apex/DMT_OpportunityProductsController.getTaxonomyCatalogValues';
import cloneOpportunityLineItem               from '@salesforce/apex/DMT_OpportunityProductsController.cloneOpportunityLineItem';
import deleteOpportunityLineItem              from '@salesforce/apex/DMT_OpportunityProductsController.deleteOpportunityLineItem';
import getPicklistValues                      from '@salesforce/apex/DMT_SustainableDealController.getPicklistValues';
import DmtOppProductCreateModal               from 'c/dmt_opp_product_create_modal';
//import DmtOppProductLineSelectorModal         from 'c/dmt_opp_product_line_selector_modal';
import DmtProfitabilityDealManagement         from 'c/dmt_profitability_Deal_Management';
import DMT_STAGE_NAME_FIELD        from '@salesforce/schema/Opportunity.StageName';
import DMT_REQUESTED_PASSPORT_FIELD from '@salesforce/schema/Opportunity.DMT_Requested_Passport__c';

const FIELDS          = [DMT_STAGE_NAME_FIELD, DMT_REQUESTED_PASSPORT_FIELD];
const EDITABLE_STAGES = new Set(['Draft', 'Ready to close']);

const PRODUCT_NAME_FIELD = 'DMT_TXT_ProductNameOLI__c';
const AMOUNT_FIELD       = 'DMT_Deal_Amount_Tenors__c';
const CURRENCY_FIELD     = 'g_currency_id__c';

export default class Dmt_opp_products extends LightningElement {

    @api recordId;
    @api canEdit;
    @api stageRecord;

    isLoading         = true;
    lineItems         = [];
    error;
    wiredProductList;
    modalProfitability= false;
    activeTabId       = null;
    stageName;
    requestedPassport;
    selectedProductContext;

    _riskTypeOptions        = [];
    _productLineTypeOptions = [];
    _taxonomyCatalogValues  = {};
    _assessmentOptions      = [];
    _subtypeOptions         = [];

    // ─── Computed ─────────────────────────────────────────────────────────────

    get activeProductName() { return this.activeProduct?.DES_Product_Name__c; }
    get activeProductCode() { return this.activeProduct?.ProductCode; }

    get hasLineItems() { return this.lineItems && this.lineItems.length > 0; }

    get buttonProfitability() {
        return this.isLoading || this.stageName === 'Closed' || this.requestedPassport === false;
    }

    get disabledButtons() {
        return !this.canEdit || this.isLoading;
    }

    get activeProduct() {
        if (!this.activeTabId) return null;
        return this.lineItems.find(li => li.Id === this.activeTabId) || null;
    }

    get tabsConfig() {
        return {
            nameField    : PRODUCT_NAME_FIELD,
            amountField  : AMOUNT_FIELD,
            currencyField: CURRENCY_FIELD,
            products     : this._sortByPriority(this.lineItems)
        };
    }

    get productFieldOptions() {
        return {
            riskTypeOptions       : this._riskTypeOptions        || [],
            productLineTypeOptions: this._productLineTypeOptions || [],
            catalogValues         : this._taxonomyCatalogValues,
            assessmentOptions     : this._assessmentOptions      || [],
            subtypeOptions        : this._subtypeOptions         || []
        };
    }

    // ─── Wire: Opportunity record ─────────────────────────────────────────────

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecordOpp({ data, error }) {
        if (data) {
            this.stageName        = getFieldValue(data, DMT_STAGE_NAME_FIELD);
            this.requestedPassport= getFieldValue(data, DMT_REQUESTED_PASSPORT_FIELD);
        }
        if (error) this.error = error;
    }

    // ─── Wire: Product list ───────────────────────────────────────────────────

    // Only updates lineItems when data is present; intermediate states during
    // refreshApex (no data, no error) are intentionally ignored to prevent
    // the slot from unmounting and causing a flicker.
    @wire(getOpportunityLineItemsByOpportunityId, { opportunityId: '$recordId' })
    wiredLineItems(result) {
        this.wiredProductList = result;
        if (result.data !== undefined) {
            this.lineItems    = result.data;
            this.error        = undefined;
            this.isLoading    = false;
            // Keep active tab if the product still exists; fall back to the first one
            const stillExists = this.activeTabId && this.lineItems.some(li => li.Id === this.activeTabId);
            if (!stillExists) {
                const sorted     = this._sortByPriority(this.lineItems);
                this.activeTabId = sorted.length > 0 ? sorted[0].Id : null;
            }
        } else if (result.error) {
            this.error     = result.error;
            this.lineItems = [];
            this.isLoading = false;
            console.error('[dmt_opp_products] Error:', result.error);
        }
    }

    // ─── Wire: Field options ──────────────────────────────────────────────────

    @wire(getProductLineTypeOptions, { productName: '$activeProductName', productCode: '$activeProductCode' })
    wiredProductLineTypeOptions({ data, error }) {
        if (data)  this._productLineTypeOptions = data;
        else if (error) console.error('[dmt_opp_products] getProductLineTypeOptions error:', error);
    }

    @wire(getRiskTypeOptions)
    wiredRiskTypeOptions({ data, error }) {
        if (data)  this._riskTypeOptions = data;
        else if (error) console.error('[dmt_opp_products] getRiskTypeOptions error:', error);
    }

    @wire(getTaxonomyCatalogValues)
    wiredTaxonomyCatalogValues({ data, error }) {
        if (data)  this._taxonomyCatalogValues = data;
        else if (error) console.error('[dmt_opp_products] getTaxonomyCatalogValues error:', error);
    }

    @wire(getPicklistValues, { fieldName: 'DMT_sustainable_deal_assessment__c' })
    wiredAssessmentOptions({ data, error }) {
        if (data)  this._assessmentOptions = this._mapToOptions(data);
        else if (error) console.error('[dmt_opp_products] getPicklistValues (assessment) error:', error);
    }

    @wire(getPicklistValues, { fieldName: 'DMT_Sustainable_Deal_Subtype__c' })
    wiredSubtypeOptions({ data, error }) {
        if (data)  this._subtypeOptions = this._mapToOptions(data);
        else if (error) console.error('[dmt_opp_products] getPicklistValues (subtype) error:', error);
    }

    // ─── Event handlers ───────────────────────────────────────────────────────

    async handleTabChange(event) {
        const newTabId = event.detail.tabId;
        const component = this.refs.oppProductDetails;

        const isEditing = component?.getEditMode();

        if (isEditing) {
            this.dispatchEvent(new CustomEvent('editmodetab', {
                detail   : { editMode: false },
                bubbles  : true,
                composed : true
            }));
        }
        this.activeTabId = newTabId;
    }

    handleRecordSaved() {
        this.refreshData();
    }

    async handleProfitability() {

        try {
            await DmtProfitabilityDealManagement.open({
                size           : 'small',
                label: "Profitability ",
                accountId      : this.activeProduct?.Opportunity.AccountId,
                oppId          : this.activeProduct?.Opportunity.DMT_Opp_Id__c,
                productSelected: this.activeProduct?.Id
            });
        } catch (error) {
            console.error('Error opening profitability modal:', error);
            console.error('Error message:', error?.message);
            console.error('Full error:', JSON.parse(JSON.stringify(error)));
            this._toast('Unexpected Error', error?.message || 'Unknown error', 'error');

        }
    }

    // ─── Nuevos métodos para la creación directa ───────────────────────────────

    async handleAddOneOffDeal() {
        this.selectedProductContext = 'OPP';
        await this.openCreateModal();
    }

    async handleAddLine() {
        // Enviamos ambos valores. Si DmtOppProductCreateModal espera un string
        // en lugar de un array, puedes cambiarlo a: 'LC,LNC'
        this.selectedProductContext = 'LC,LNC';
        await this.openCreateModal();
    }

    async openCreateModal() {
        const result = await DmtOppProductCreateModal.open({
            size: 'medium',
            recordId: this.recordId,
            contextCode: this.selectedProductContext
        });

        if (result && result.created) {
            const newProducts = Array.isArray(result.productId) ? result.productId : [];
            const newId       = newProducts[0]?.Id || null;
            this.isLoading    = true;
            try {
                // Refrescamos primero para que lineItems se actualice antes de cambiar de tab
                await refreshApex(this.wiredProductList);
                if (newId) this.activeTabId = newId;
            } finally {
                this.isLoading = false;
            }
        }
    }

    async handleCloneProduct() {
        this.isLoading = true;
        try {
            const result = await cloneOpportunityLineItem({ opportunityLineItemId: this.activeTabId });
            if (result.clonedOpportunityLineItemId) {
                const newId = result.clonedOpportunityLineItemId;
                // Refresh first so lineItems already contains the cloned product before switching tabs
                this.activeTabId = newId;
                await refreshApex(this.wiredProductList);
                this._toast('Product Cloned', 'Product was cloned successfully.', 'success');
            } else {
                this._toast('Error', result.errorMessage || 'There was a problem cloning the product.', 'error');
            }
        } catch (error) {
            console.error('Error opening profitability modal:', error);
            console.error('Error message:', error?.message);
            console.error('Full error:', JSON.parse(JSON.stringify(error)));
            this._toast('Unexpected Error', error?.message || 'Unknown error', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleDeleteProduct() {
        this.isLoading = true;
        try {
            const deletedId = this.activeTabId;
            // Compute the next active tab before deleting to avoid setting activeTabId = null
            // while products still exist, which would unmount the slot content and cause a flicker
            const sorted    = this._sortByPriority(this.lineItems);
            const idx       = sorted.findIndex(li => li.Id === deletedId);
            const nextActive= sorted[idx + 1]?.Id || sorted[idx - 1]?.Id || null;

            const result = await deleteOpportunityLineItem({ opportunityLineItemId: deletedId });
            if (result) {
                this.activeTabId = nextActive;
                await refreshApex(this.wiredProductList);
                this._toast('Product Deleted', 'Product was deleted successfully.', 'success');
            } else {
                this._toast('Error', 'There was a problem deleting the product.', 'error');
            }
        } catch (error) {
            this._toast('Unexpected Error', error?.body?.message || 'Unknown error', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    async refreshData() {
        this.isLoading = true;
        try {
            await refreshApex(this.wiredProductList);
        } finally {
            this.isLoading = false;
        }
    }

    // Sorts ascending by gf_group_priority_opportunity_id__c; nulls go last
    _sortByPriority(products) {
        if (!Array.isArray(products) || products.length === 0) return [];
        return [...products].sort((a, b) => {
            const pa      = a?.gf_group_priority_opportunity_id__c;
            const pb      = b?.gf_group_priority_opportunity_id__c;
            const aIsNull = pa === null || pa === undefined;
            const bIsNull = pb === null || pb === undefined;
            if (aIsNull && bIsNull) return 0;
            if (aIsNull) return 1;
            if (bIsNull) return -1;
            return pa - pb;
        });
    }

    _mapToOptions(data) {
        if (!Array.isArray(data)) return [];
        return data.map(entry => ({ label: entry.label, value: entry.value }));
    }

    _toast(title, message, variant = 'info') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}