import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import DmtOppMoneyModal from 'c/dmt_opp_money_modal';
import getOpportunityLineItemData from '@salesforce/apex/DMT_OpportunityProductsController.getOpportunityLineItemData';
import getUnderlyingsData        from '@salesforce/apex/DMT_OpportunityProductsController.getUnderlyingsData';
import getMitigantsData          from '@salesforce/apex/DMT_OpportunityProductsController.getMitigantsData';
import saveOpportunityProduct    from '@salesforce/apex/DMT_OpportunityProductsController.saveOpportunityProduct';
import previewOpportunityProductSave from '@salesforce/apex/DMT_OpportunityProductsController.previewOpportunityProductSave'; // CIBGLOBALD-4811
import LightningConfirm from 'lightning/confirm'; // CIBGLOBALD-4811

// CIBGLOBALD-4811 - same text as the other Opportunity tabs (dmt_opp_info, dmt_opp_client)
const REOPEN_LABEL   = 'Modify Opportunity?';
const REOPEN_MESSAGE = 'The Opportunity will be modified and the associated cases and tasks will be reopened.' +
    '\n\nDo you want to modify the Opportunity?';

const SECTION_REF_NAMES = ['generalInfo', 'lineDescription', 'underlyings', 'costOfFunding', 'sustainability', 'countryRisk', 'mitigants','unfundedMitigants'];

export default class DmtOppProductDetailsLine extends LightningElement {

    isEditMode = false;
    isLoading = false;
    isLoadingSaving = false;
    hasError = false;
    errorMessage = '';
    recordData;
    draftRecordData = null;
    underlyingsData = [];
    mitigantsData = [];
    optionsMap = {};
    allSections = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
    currentRecordId;

    _wiredResult = null;
    _wiredUnderlyingsResult = null;
    _canEdit = true;
    // CIBGLOBALD-4811 - set by dmt_opp_products: Ready to close and record type DMT_Opportunity
    @api checkReopen = false;
    _readOnlyApplied = false;

    @api get recordId() { return this.currentRecordId; }
    set recordId(value) {
        this.currentRecordId = value;
        this.isLoading = true;
        if (value) {
            this._loadMitigantsData();
        }
    }

    @api get fieldOptions() { return this.optionsMap; }
    set fieldOptions(value) {
        this.optionsMap = value || {};
    }

    @api get canEdit() { return this._canEdit; }
    set canEdit(value) {
        const newValue = !!value;
        if (newValue !== this._canEdit) {
            this._canEdit = newValue;
            this._readOnlyApplied = false;
            if (!newValue && this.isEditMode) {
                this.handleCancel();
            }
            this._applyReadOnlyToSection();
        }
    }

    get currentSectionData() {
        return this.draftRecordData || this.recordData;
    }

    get currentMaturityDate() {
        return this.currentSectionData?.gf_maturity_date__c || '';
    }

    get referenceUpfrontFees() {
        return this.currentSectionData?.DMT_Reference_Upfront_Fees__c ?? null;
    }

    get productCode() {
        return this.recordData?.ProductCode ?? null;
    }

    get opportunityCurrency() {
        return this.currentSectionData?.g_currency_id__c ?? '';
    }

    @wire(getOpportunityLineItemData, { opportunityLineItemId: '$currentRecordId' })
    wiredRecord(result) {
        this._wiredResult = result;
        if (result.data) {
            this.recordData = result.data;
        } else if (result.error) {
            console.error('[dmt_opp_product_details_line] getOpportunityLineItemData error:', result.error);
        }
        this.isLoading = false;
    }

    @wire(getUnderlyingsData, { opportunityLineItemId: '$currentRecordId' })
    wiredUnderlyings(result) {
        this._wiredUnderlyingsResult = result;
        if (result.data) {
            this.underlyingsData = [...result.data];
        } else if (result.error) {
            console.error('[dmt_opp_product_details_line] getUnderlyingsData error:', result.error);
        }
    }

    _loadMitigantsData() {
        if (!this.currentRecordId) return Promise.resolve();
        return getMitigantsData({ opportunityLineItemId: this.currentRecordId })
            .then(data => {
                this.mitigantsData = [...data];
            })
            .catch(error => {
                console.error('[dmt_opp_product_details_line] getMitigantsData error:', error);
            });
    }

    renderedCallback() {
        if (!this._readOnlyApplied) {
            this._applyReadOnlyToSection();
        }
    }

    handleEditModeChange() {
        if (this.isEditMode || !this._canEdit) return;
        this.draftRecordData = { ...(this.recordData || {}) };
        for (const ref of this._sectionRefs()) {
            ref.enterEditMode?.();
        }
        this.isEditMode = true;
        this.notifyEditMode(true);
    }

    get isRenewal() {
        return !!this.recordData?.Opportunity?.DMT_Parent_Opportunity__c;
    }

    get oldMoneyBtnDisabled() {
        return this.isRenewal || !this._canEdit;
    }

    async handleOpenOldMoneyModal() {
        if (!this.isEditMode) {
            this.handleEditModeChange();
        }
        await DmtOppMoneyModal.open({
            size: 'medium',
            oppProductId: this.currentRecordId
        });
    }

    handleSectionChange(event) {
        const { apiName, value, changes } = event.detail || {};

        const nextChanges = changes && typeof changes === 'object'
            ? changes
            : (apiName ? { [apiName]: value } : null);

        if (!nextChanges) return;

        const baseData = this.draftRecordData || this.recordData || {};
        const nextData = {
            ...baseData,
            ...nextChanges
        };

        if (this.isEditMode || this.draftRecordData) {
            this.draftRecordData = nextData;
            return;
        }

        this.recordData = nextData;
    }

    handleUnderlyingsChange(event) {
        const rows = Array.isArray(event.detail?.rows) ? event.detail.rows : [];
        const nextRows = [...rows];
        if (JSON.stringify(nextRows) === JSON.stringify(this.underlyingsData)) {
            return;
        }
        this.underlyingsData = nextRows;
    }

    @api getEditMode() {
        return this.isEditMode;
    }

    async handleSave() {
        this.hasError = false;

        const lineDescBpsValidation    = this.refs?.lineDescription?.collectBpsFieldsValidation?.();
        const underlyingsBpsValidation = this.refs?.underlyings?.collectBpsFieldsValidation?.();
        const invalidBpsFields = [
            ...(lineDescBpsValidation?.invalidFields    || []),
            ...(underlyingsBpsValidation?.invalidFields || [])
        ];
        if (invalidBpsFields.length > 0) {
            this.hasError     = true;
            this.errorMessage = `The following fields have invalid values: ${invalidBpsFields.join(', ')}`;
            return;
        }

        const validation = this._validateBeforeSave();
        if (!validation.isValid) {
            this.hasError = true;
            this.errorMessage = validation.invalidFields.length > 0
                ? `Please complete all required fields before saving: ${validation.invalidFields.join(', ')}.`
                : 'Please complete all required fields before saving.';
            return;
        }

        this.isLoadingSaving = true;

        try {
            const recordFields = { Id: this.currentRecordId };
            for (const ref of this._sectionRefs()) {
                const changes = ref.collectChanges?.();
                if (changes) Object.assign(recordFields, changes);
            }

            const underlyingsRef = this.refs?.underlyings;
            const underlyingsChanges = underlyingsRef?.collectUnderlyingsChanges?.() || { underlyingsToUpsert: [], underlyingsToDelete: [] };
            const hasUnderlyingsChanges = underlyingsChanges.underlyingsToUpsert.length > 0 || underlyingsChanges.underlyingsToDelete.length > 0;

            const mitigantsRef = this.refs?.mitigants;
            const mitigantsChanges = mitigantsRef?.collectMitigantsChanges?.() || { mitigantsToUpsert: [], mitigantsToDelete: [] };
            const hasMitigantsChanges = mitigantsChanges.mitigantsToUpsert.length > 0 || mitigantsChanges.mitigantsToDelete.length > 0;

            const hasFieldChanges = Object.keys(recordFields).length > 1;
            if (!hasFieldChanges && !hasUnderlyingsChanges && !hasMitigantsChanges) {
                this._exitEditMode();
                return;
            }

            const toDateOnly = (v) => (typeof v === 'string' ? v.substring(0, 10) : v);
            // CIBGLOBALD-4811 - one payload for the reopen check and the save; Cancel keeps edit mode and the values
            const savePayload = {
                recordFields,
                tenorsToUpsert      : [],
                tenorsToDelete      : [],
                mitigantsToUpsert   : mitigantsChanges.mitigantsToUpsert,
                mitigantsToDelete   : mitigantsChanges.mitigantsToDelete,
                underlyingsToUpsert : underlyingsChanges.underlyingsToUpsert,
                underlyingsToDelete : underlyingsChanges.underlyingsToDelete,
                initialDate  : toDateOnly(this.recordData?.gf_initial_date__c),
                maturityDate : toDateOnly(this.recordData?.gf_maturity_date__c),
                oppId: this._wiredResult?.data?.OpportunityId
            };
            if (!await this._confirmReopen(savePayload)) return;
            const result = await saveOpportunityProduct(savePayload); // CIBGLOBALD-4811

            if (result?.success === false) {
                this.hasError = true;
                this.errorMessage = result.errorMessage || 'The validation process encountered an unhandled error. Please contact your administrator.';
                return;
            }

            await refreshApex(this._wiredResult);
            if (this._wiredUnderlyingsResult) await refreshApex(this._wiredUnderlyingsResult);
            await this._loadMitigantsData();
            this._notifySuccess('Record updated successfully.');
            this._exitEditMode();
        } catch (error) {
            this._notifyError(error);
        } finally {
            this.isLoadingSaving = false;
        }
    }

    /**
     * CIBGLOBALD-4811 - Asks before a save that would reopen approval tasks. Runs only when the parent
     * (dmt_opp_products) sets checkReopen: Opportunity in Ready to close with record type DMT_Opportunity.
     * DMT_OpportunityProductsController.previewOpportunityProductSave runs the Ready to close comparison of
     * the Opportunity trigger (DMT_OpportunityTriggerHandler checkpoint 3) on what this save writes, without
     * saving. The reopen itself happens when leaving edit mode releases the Opportunity edit lock
     * (dmt_opp_custom_page). A failed check counts as no reopen. Returns true to save, false to stay in edit mode.
     */
    async _confirmReopen(savePayload) {
        if (!this.checkReopen) return true;
        let reopens = false;
        try {
            const features = await previewOpportunityProductSave({ caseTypeToCheck: 'readytoclose', ...savePayload });
            reopens = !!(features && features.length > 0);
        } catch (error) {
            console.error('[dmt_opp_product_details_line][_confirmReopen]', error);
        }
        if (!reopens) return true;
        return LightningConfirm.open({ label: REOPEN_LABEL, message: REOPEN_MESSAGE, theme: 'warning' });
    }

    handleCancel() {
        for (const ref of this._sectionRefs()) {
            ref.restoreSnapshot?.();
        }
        this.draftRecordData = null;
        this._exitEditMode(false);
    }

    @api notifyEditMode(value) {
        this.dispatchEvent(new CustomEvent('editmodetab', {
            detail: { editMode: value },
            bubbles: true,
            composed: true
        }));
    }

    _exitEditMode(commitSections = true) {
        this.isEditMode = false;
        if (commitSections) {
        for (const ref of this._sectionRefs()) {
            ref.commitEdit?.();
            }
        }
        this.draftRecordData = null;
        this.hasError = false;
        this.errorMessage = '';
        this.notifyEditMode(false);
    }

    _applyReadOnlyToSection() {
        const refs = this._sectionRefs();
        if (refs.length === 0) return;
        for (const ref of refs) {
            ref.setReadOnlyMode?.(!this._canEdit);
        }
        this._readOnlyApplied = true;
    }

    _sectionRefs() {
        const refs = [];
        for (const name of SECTION_REF_NAMES) {
            const ref = this.refs?.[name];
            if (ref) refs.push(ref);
        }
        return refs;
    }

    _validateBeforeSave() {
        let isValid = true;
        const invalidFields = [];
        for (const ref of this._sectionRefs()) {
            if (typeof ref.validate === 'function') {
                const result = ref.validate();
                if (result && typeof result === 'object') {
                    if (!result.isValid) {
                        isValid = false;
                        if (Array.isArray(result.invalidFields)) {
                            invalidFields.push(...result.invalidFields);
                        }
                    }
                } else if (!result) {
                    isValid = false;
                }
            }
        }
        return { isValid, invalidFields };
    }

    _notifySuccess(message) {
        this.dispatchEvent(new CustomEvent('recordsaved', { bubbles: true, composed: true }));
        this.dispatchEvent(new ShowToastEvent({ title: 'Success', message, variant: 'success' }));
    }

    _notifyError(error) {
        let errorMsg = error?.body?.message || error?.message || 'Unknown error';
        const generalErrors = error?.body?.output?.errors;
        if (generalErrors?.length > 0) {
            errorMsg = generalErrors[0].message || errorMsg;
        }
        this.hasError = true;
        this.errorMessage = errorMsg;
    }
}