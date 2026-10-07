import { LightningElement, api, wire } from 'lwc';
import { refreshApex }    from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import DmtOppMoneyModal   from 'c/dmt_opp_money_modal';
import getOpportunityLineItemData from '@salesforce/apex/DMT_OpportunityProductsController.getOpportunityLineItemData';
import getTenorsData              from '@salesforce/apex/DMT_TableTenors.getTenorsData';
import getMitigantsData           from '@salesforce/apex/DMT_OpportunityProductsController.getMitigantsData';
import saveOpportunityProduct     from '@salesforce/apex/DMT_OpportunityProductsController.saveOpportunityProduct';
import ERR_NEGATIVE_VALUE_SUMMARY from '@salesforce/label/c.DMT_Negative_Validation_Summary';

const SECTION_REF_NAMES = ['generalInfo', 'dealDescription', 'schedule', 'costOfFunding', 'sustainability', 'countryRisk', 'mitigants', 'unfundedMitigants'];

export default class DmtOppProductDetails extends LightningElement {

    // ─── State ────────────────────────────────────────────────────────────────

    label = {
        ERR_NEGATIVE_VALUE_SUMMARY
    };

    isEditMode  = false;
    isLoading   = false;
    isLoadingSaving = false;
    hasError    = false;
    errorMessage= '';
    recordData;
    optionsMap  = {};
    tenorsData  = [];
    mitigantsData = [];
    fieldsWithErrors = new Map(); // key: apiName, value: label

    currentCurrencyCode = '';
    currentInitialDate  = null;
    currentMaturityDate = null;
    allSections         = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
    currentRecordId;

    _wiredResult     = null;
    _canEdit         = true;
    _readOnlyApplied = false;

    // ─── Public API ───────────────────────────────────────────────────────────

    @api get recordId() { return this.currentRecordId; }
    set recordId(value) {
        this.currentRecordId = value;
        this.isLoading       = true;
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
            this._applyReadOnlyToSections();
        }
    }

    // ─── Data loading ─────────────────────────────────────────────────────────

    @wire(getOpportunityLineItemData, { opportunityLineItemId: '$currentRecordId' })
    async wiredRecord(result) {
        this._wiredResult = result;
        if (result.data) {
            const data              = result.data;
            this.currentCurrencyCode = data.g_currency_id__c    || '';
            this.currentInitialDate  = data.gf_initial_date__c  || null;
            this.currentMaturityDate = data.gf_maturity_date__c || null;
            this.recordData          = data;
            await this._loadRelatedData();
        } else if (result.error) {
            console.error('[dmt_opp_product_details] getOpportunityLineItemData error:', result.error);
        }
        this.isLoading = false;
    }

    async _loadRelatedData() {
        try {
            const tenorsResult    = await getTenorsData({ oppLineItemId: this.currentRecordId });
            if (tenorsResult)     this.tenorsData = tenorsResult.tenors || [];

            const mitigantsResult = await getMitigantsData({ opportunityLineItemId: this.currentRecordId });
            if (mitigantsResult)  this.mitigantsData = [...mitigantsResult];
        } catch (error) {
            console.error('[dmt_opp_product_details] Error loading related data:', error);
        }
    }

    // ─── Lifecycle ────────────────────────────────────────────────────────────

    renderedCallback() {
        if (!this._readOnlyApplied) {
            this._applyReadOnlyToSections();
        }
    }

    // ─── Cross-section coordination ───────────────────────────────────────────

    // Keeps local copies of date/currency in sync so child sections share the same context
    handleSectionChange(event) {
        const detail  = event.detail || {};
        const changes = detail.changes
            ? detail.changes
            : (detail.apiName ? { [detail.apiName]: detail.value } : null);

        // Handle real-time tenor updates from schedule for BBVA Commitment recalculation
        if (detail.updatedTenors && Array.isArray(detail.updatedTenors)) {
            this.tenorsData = detail.updatedTenors;
        }

        if (!changes) return;

        if ('gf_initial_date__c' in changes)  this.currentInitialDate  = changes.gf_initial_date__c  || null;
        if ('gf_maturity_date__c' in changes) this.currentMaturityDate = changes.gf_maturity_date__c || null;
        if ('g_currency_id__c' in changes)    this.currentCurrencyCode = changes.g_currency_id__c    || '';

        this.recordData = { ...this.recordData, ...changes };
    }

    //Intercept field (dmt_form_renderer) changes to validate information on parent
    handleFieldChange(event) {
        const { apiName, label, isFieldValid } = event.detail;

        if (isFieldValid === false) {
            this.fieldsWithErrors.set(apiName, label ?? apiName);
        } else {
            this.fieldsWithErrors.delete(apiName);
        }
    }

    // ─── Edit mode ────────────────────────────────────────────────────────────

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

    handleEditModeChange() {
        if (this.isEditMode || !this._canEdit) return;
        for (const ref of this._sectionRefs()) ref.enterEditMode?.();
        this.isEditMode = true;
        this.notifyEditMode(true);
    }
 
    @api getEditMode() {
        return this.isEditMode;
    }

    // ─── Save / Cancel ────────────────────────────────────────────────────────

    async handleSave() {
        this.isLoadingSaving = true;
        this.hasError  = false;

        try {
            // 0. Validate required fields before saving
            const validation = this._validateBeforeSave();
            if (!validation.isValid) {
                this.hasError = true;
                this.errorMessage = validation.invalidFields.length > 0
                    ? `Please complete all required fields before saving: ${validation.invalidFields.join(', ')}.`
                    : 'Please complete all required fields before saving.';
                this.isLoadingSaving = false;
                return;
            }

            // 1. Collect field changes and invalid fields from all sections
            const recordFields = { Id: this.currentRecordId };

            for (const ref of this._sectionRefs()) {
                const changes = ref.collectChanges?.();
                if (changes) Object.assign(recordFields, changes);
                console.log('Collected changes from section:', JSON.stringify(changes));
            }

            if (this.fieldsWithErrors.size > 0) {
                this.hasError = true;
                this.errorMessage = this.fieldsWithErrors.size > 3
                    ? 'Review errors on this page'
                    : `The following fields have invalid values: ${[...this.fieldsWithErrors.values()].join(', ')}`;
                this.isLoadingSaving = false;
                return;
            }

            const hasFieldChanges = Object.keys(recordFields).length > 1;

            // 2. Collect tenor changes
            const { tenorsToUpsert, tenorsToDelete } = this._collectTenorsChanges();
            const hasTenorChanges = tenorsToUpsert.length > 0 || tenorsToDelete.length > 0;

            // 3. Collect mitigant changes
            const { mitigantsToUpsert, mitigantsToDelete } = this._collectMitigantsChanges();
            const hasMitigantChanges = mitigantsToUpsert.length > 0 || mitigantsToDelete.length > 0;

            // 4. Nothing changed — exit silently without calling Apex
            if (!hasFieldChanges && !hasTenorChanges && !hasMitigantChanges) {
                this._exitEditMode();
                return;
            }

            // 5. Single transactional Apex call
            const toDateOnly = (v) => (typeof v === 'string' ? v.substring(0, 10) : v);

            const result = await saveOpportunityProduct({
                recordFields,
                tenorsToUpsert,
                tenorsToDelete,
                mitigantsToUpsert,
                mitigantsToDelete,
                initialDate : toDateOnly(this.currentInitialDate),
                maturityDate: toDateOnly(this.currentMaturityDate),
                oppId: this._wiredResult?.data?.OpportunityId
            });

            // 6. Business validation failed (not an exception — returned as success:false)
            if (result?.success === false) {
                this.hasError     = true;
                this.errorMessage = result.errorMessage || 'The validation process encountered an unhandled error. Please contact your administrator.';
                return;
            }

            // 7. Success: exit edit mode first (clears snapshots), then refresh data
            this._exitEditModeWithoutRefresh();
            await refreshApex(this._wiredResult);
            await this._loadRelatedData();
            this._notifySuccess('Record updated successfully.');

        } catch (error) {
            this._notifyError(error);
        } finally {
            this.isLoadingSaving = false;
        }
    }

    @api notifyEditMode(value) {
        this.dispatchEvent(new CustomEvent('editmodetab', {
            detail   : { editMode: value },
            bubbles  : true,
            composed : true
        }));
    }

    handleCancel() {
        for (const ref of this._sectionRefs()) ref.restoreSnapshot?.();
        if (this._wiredResult?.data) {
            const data              = this._wiredResult.data;
            this.currentCurrencyCode = data.g_currency_id__c    || '';
            this.currentInitialDate  = data.gf_initial_date__c  || null;
            this.currentMaturityDate = data.gf_maturity_date__c || null;
        }
        this._exitEditMode();
    }

    _exitEditMode() {
        this._exitEditModeWithoutRefresh();
    }

    _exitEditModeWithoutRefresh() {
        this.isEditMode   = false;
        for (const ref of this._sectionRefs()) ref.commitEdit?.();
        this.hasError     = false;
        this.errorMessage = '';
        this.notifyEditMode(false);
    }

    _collectTenorsChanges() {
        const empty      = { tenorsToUpsert: [], tenorsToDelete: [] };
        const scheduleRef = this.refs?.schedule;
        if (!scheduleRef) return empty;
        const changes    = scheduleRef.collectTenorsChanges?.();
        if (!changes)    return empty;
        return {
            tenorsToUpsert: changes.upserts    || changes.tenorData   || [],
            tenorsToDelete: changes.deletes    || changes.deletedIds   || []
        };
    }

    _collectMitigantsChanges() {
        const empty        = { mitigantsToUpsert: [], mitigantsToDelete: [] };
        const mitigantsRef = this.refs?.mitigants;
        if (!mitigantsRef) return empty;
        const changes      = mitigantsRef.collectMitigantsChanges?.();
        if (!changes)      return empty;
        return {
            mitigantsToUpsert: changes.mitigantsToUpsert || [],
            mitigantsToDelete: changes.mitigantsToDelete || []
        };
    }

    // ─── Read-only mode ───────────────────────────────────────────────────────

    _applyReadOnlyToSections() {
        const refs = this._sectionRefs();
        if (refs.length === 0) return;
        for (const ref of refs) ref.setReadOnlyMode?.(!this._canEdit);
        this._readOnlyApplied = true;
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

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

    getFieldLabel(apiName) {
        for (const ref of this._sectionRefs()) {
            const label = ref.getFieldLabel?.(apiName);
            if (label) return label;
        }
        return null;
    }

    // ─── Notifications ────────────────────────────────────────────────────────

    _notifySuccess(message) {
        this.dispatchEvent(new CustomEvent('recordsaved', { bubbles: true, composed: true }));
        this.dispatchEvent(new ShowToastEvent({ title: 'Success', message, variant: 'success' }));
    }

    _notifyError(error) {
        let errorMsg        = error.body ? error.body.message : error.message;
        const fieldErrors   = error.body?.output?.fieldErrors;
        const generalErrors = error.body?.output?.errors;

        if (fieldErrors && Object.keys(fieldErrors).length > 0) {
            const fieldName      = Object.keys(fieldErrors)[0];
            const fieldError     = fieldErrors[fieldName][0];
            const msgFromError   = fieldError.message || errorMsg;
            const correctLabel   = this.getFieldLabel(fieldName);
            // Replace Salesforce API field name with the human-readable label when available
            errorMsg = correctLabel
                ? this._replaceFieldNameInMessage(msgFromError, correctLabel)
                : msgFromError;
        } else if (generalErrors?.length > 0) {
            errorMsg = generalErrors[0].message || errorMsg;
        }

        this.hasError     = true;
        this.errorMessage = errorMsg;
    }

    // Replaces the API field name prefix (before the colon) with the display label
    _replaceFieldNameInMessage(message, label) {
        const colonIndex = message.indexOf(':');
        return colonIndex !== -1 ? label + message.substring(colonIndex) : message;
    }
}