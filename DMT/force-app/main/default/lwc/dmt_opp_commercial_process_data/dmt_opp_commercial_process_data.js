import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import PRODUCT_AREA_FIELD from '@salesforce/schema/Opportunity.DMT_Product_Area__c';
import { applyNbcMarks } from 'c/dmt_nbc_marks';
import { clientNeedFields, clientSolutionFields } from './dmt_opp_commercial_process_data_fields';
import getCommercialProcessData  from '@salesforce/apex/DMT_CommercialProcessDataController.getCommercialProcessData';
import saveCommercialProcessData from '@salesforce/apex/DMT_CommercialProcessDataController.saveCommercialProcessData';
import getOppLineItems           from '@salesforce/apex/DMT_CommercialProcessDataController.getOppLineItems';
import previewCommercialProcessDataSave from '@salesforce/apex/DMT_CommercialProcessDataController.previewCommercialProcessDataSave'; // CIBGLOBALD-4811
import LightningConfirm from 'lightning/confirm'; // CIBGLOBALD-4811

const DEFAULT_READONLY_NEED     = new Map(clientNeedFields.map(f => [f.id, f.isReadOnly]));
const DEFAULT_READONLY_SOLUTION = new Map(clientSolutionFields.map(f => [f.id, f.isReadOnly]));

export default class DmtOppCommercialProcessData extends LightningElement {

    // ─── Public API ───────────────────────────────────────────────────────────

    _recordId;
    @api get recordId() { return this._recordId; }
    set recordId(v) {
        this._recordId = v;
        if (v) this._loadData();
    }

    _stageRecord;
    @api get stageRecord() { return this._stageRecord; }
    set stageRecord(value) {
        this._stageRecord = value;
        this._applyReadOnlyRules();
    }

    _canEdit = true;
    @api get canEdit() { return this._canEdit; }
    set canEdit(value) {
        this._canEdit = !!value;
        if (!this._canEdit && this.isEditMode) this._exitEditMode();
        this._applyReadOnlyRules();
    }

    // ─── State ────────────────────────────────────────────────────────────────

    isEditMode = false;
    isLoading  = false;
    hasError   = false;
    errorMessage = '';

    @track fieldsClientNeed     = [...clientNeedFields];
    @track fieldsClientSolution  = [...clientSolutionFields];
    isSectionNeedOpen     = true;
    isSectionSolutionOpen = true;
    allSections           = ['clientNeed', 'clientSolution', 'productFees'];
    _snapshot = null;
    _options  = {};
    tableLineItems          = null;
    _tableLineItemsSnapshot = null;

    // NBC Local/Global marks: driven by each field's own `nbcScope` in
    // dmt_opp_commercial_process_data_fields.js. No field currently sets nbcScope
    // on this tab — this wiring is dormant until one does.
    isGtb = false;
    _recordTypeDeveloperName = null; // CIBGLOBALD-4811

    @wire(getRecord, { recordId: '$recordId', fields: [PRODUCT_AREA_FIELD], optionalFields: ['Opportunity.RecordType.DeveloperName'] }) // CIBGLOBALD-4811
    wiredProductArea({ data }) {
        if (!data) return;
        this._recordTypeDeveloperName = data.fields.RecordType?.value?.fields?.DeveloperName?.value; // CIBGLOBALD-4811
        const productArea = data.fields.DMT_Product_Area__c?.value;
        const isGtb = productArea === 'GTB';
        if (isGtb === this.isGtb) return;
        this.isGtb = isGtb;
        this.fieldsClientNeed = applyNbcMarks(this.fieldsClientNeed, isGtb);
        this.fieldsClientSolution = applyNbcMarks(this.fieldsClientSolution, isGtb);
    }

    // ─── Computed ─────────────────────────────────────────────────────────────

    get disableEdit() {
        return !this._canEdit;
    }

    get formContainerClass() {
        return this.isEditMode ? 'slds-is-relative form-container--edit-mode' : 'slds-is-relative';
    }

    // ─── Edit mode ────────────────────────────────────────────────────────────

    handleEditModeChange(event) {
        if (!event.detail?.isEditMode || this.disableEdit) return;
        const fromTable = event.detail?.source === 'table';
        this._enterEditMode();
        if (fromTable) {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            Promise.resolve().then(() => {
                const tableEl = this.refs?.tableCommercialProcess;
                if (tableEl) {
                    tableEl.scrollIntoView({ behavior: 'auto', block: 'center' });
                }
            });
        }
    }

    _enterEditMode() {
        this._snapshot = {
            fieldsClientNeed    : this.fieldsClientNeed.map(f => ({ ...f })),
            fieldsClientSolution: this.fieldsClientSolution.map(f => ({ ...f }))
        };
        this._tableLineItemsSnapshot = this.tableLineItems
            ? JSON.parse(JSON.stringify(this.tableLineItems))
            : null;
        this.isEditMode = true;
        this._notifyEditMode(true);
    }

    _exitEditMode() {
        this._snapshot = null;
        this.isEditMode = false;
        this.hasError = false;
        this.errorMessage = '';
        this._notifyEditMode(false);
    }

    // ─── Save / Cancel ────────────────────────────────────────────────────────

    async handleSave() {
        this.hasError    = false;
        this.errorMessage = '';

        const validationError = this._validateRequiredFields();
        if (validationError) {
            this.hasError     = true;
            this.errorMessage = validationError;
            return;
        }

        this.isLoading = true;
        try {
            const tableRef  = this.refs.tableCommercialProcess;
            const lineItems = tableRef ? tableRef.getTableData() : [];
            console.log('[dmt_opp_commercial_process_data][lineItems]', JSON.stringify(lineItems));

            // CIBGLOBALD-4811 - Ready to close: ask before a save that would reopen tasks; Cancel keeps edit mode
            if (!await this._confirmReopen(lineItems)) return;

            await saveCommercialProcessData({
                opportunityId: this._recordId,
                fieldValues  : this._buildPayload(),
                lineItems
            });

            this.tableLineItems = lineItems;
            this._exitEditMode();
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Record saved successfully.',
                variant: 'success'
            }));
        } catch (error) {
            console.error('[dmt_opp_commercial_process_data][save]', error);
            this.hasError = true;
            this.errorMessage = this._extractErrorMessage(error);
        } finally {
            this.isLoading = false;
        }
    }

    handleCancel() {
        if (this._snapshot) {
            this.fieldsClientNeed     = this._snapshot.fieldsClientNeed;
            this.fieldsClientSolution = this._snapshot.fieldsClientSolution;
        }
        if (this._tableLineItemsSnapshot !== null) {
            this.tableLineItems = JSON.parse(JSON.stringify(this._tableLineItemsSnapshot));
        }
        this._exitEditMode();
    }

    handleToggleNeed() {
        this.isSectionNeedOpen = !this.isSectionNeedOpen;
    }

    handleToggleSolution() {
        this.isSectionSolutionOpen = !this.isSectionSolutionOpen;
    }

    // ─── Field change ─────────────────────────────────────────────────────────

    handleFieldChangeNeed(event) {
        this.fieldsClientNeed = this._applyFieldChange(this.fieldsClientNeed, event.detail);
    }

    handleFieldChangeSolution(event) {
        this.fieldsClientSolution = this._applyFieldChange(this.fieldsClientSolution, event.detail);
    }

    _applyFieldChange(fields, { fieldId, value }) {
        const idx = fields.findIndex(f => f.id === fieldId);
        if (idx === -1) return fields;
        const updated = fields.slice();
        updated[idx] = { ...fields[idx], value };
        return updated;
    }

    // ─── Data load ────────────────────────────────────────────────────────────

    async _loadData() {
        if (!this._recordId) return;
        this.isLoading = true;
        try {
            const [data, lineItems] = await Promise.all([
                getCommercialProcessData({ opportunityId: this._recordId }),
                getOppLineItems({ opportunityId: this._recordId })
            ]);
            if (data) {
                this.fieldsClientNeed = this.fieldsClientNeed.map(
                    f => ({ ...f, value: data[f.id] ?? f.value })
                );
                this.fieldsClientSolution = this.fieldsClientSolution.map(
                    f => ({ ...f, value: data[f.id] ?? f.value })
                );
                this.fieldsClientNeed = applyNbcMarks(this.fieldsClientNeed, this.isGtb);
                this.fieldsClientSolution = applyNbcMarks(this.fieldsClientSolution, this.isGtb);
            }
            this.tableLineItems = lineItems || [];
        } catch (error) {
            console.error('[dmt_opp_commercial_process_data][load]', error);
        } finally {
            this.isLoading = false;
        }
    }

    // ─── Private ──────────────────────────────────────────────────────────────

    _applyReadOnlyRules() {
        const locked = this.disableEdit;
        this.fieldsClientNeed = this.fieldsClientNeed.map(f => {
            const defaultRO = DEFAULT_READONLY_NEED.get(f.id) ?? false;
            const newRO = locked ? true : defaultRO;
            return newRO === f.isReadOnly ? f : { ...f, isReadOnly: newRO };
        });
        this.fieldsClientSolution = this.fieldsClientSolution.map(f => {
            const defaultRO = DEFAULT_READONLY_SOLUTION.get(f.id) ?? false;
            const newRO = locked ? true : defaultRO;
            return newRO === f.isReadOnly ? f : { ...f, isReadOnly: newRO };
        });
    }

    _buildPayload() {
        const toEntries = fields =>
            fields.filter(f => !f.isHidden).map(f => [f.id, f.value ?? null]);
        return Object.fromEntries([
            ...toEntries(this.fieldsClientNeed),
            ...toEntries(this.fieldsClientSolution)
        ]);
    }

    // ─── Ready-to-close guard ─────────────────────────────────────────────────
    /**
     * @description CIBGLOBALD-4811 - Asks before saving when the save would reopen approval tasks. Same filter as
     * the Opportunity trigger checkpoint 3 (DMT_OpportunityTriggerHandler: record type DMT_Opportunity, stage
     * Ready to close before and after, Cases 'readytoclose'). DMT_CommercialProcessDataController.previewCommercialProcessDataSave
     * gets the same payload as the save, builds what the save writes and compares it with the snapshots, without
     * saving. Nothing changed since edit mode started: no call. A failed check counts as no reopen. Returns true to
     * save, false to stay in edit mode.
     */
    async _confirmReopen(lineItems) {
        if (this._stageRecord !== 'Ready to close' || this._recordTypeDeveloperName !== 'DMT_Opportunity'
            || !this._hasUnsavedChanges(lineItems)) {
            return true;
        }
        let reopens = false;
        try {
            const features = await previewCommercialProcessDataSave({
                caseTypeToCheck: 'readytoclose',
                opportunityId: this._recordId,
                fieldValues: this._buildPayload(),
                lineItems
            });
            reopens = !!(features && features.length > 0);
        } catch (error) {
            console.error('[dmt_opp_commercial_process_data][_confirmReopen]', error);
        }
        if (!reopens) return true;
        return LightningConfirm.open({
            label: 'Modify Opportunity?',
            message: 'The Opportunity will be modified and the associated cases and tasks will be reopened.' +
                '\n\nDo you want to modify the Opportunity?',
            theme: 'warning'
        });
    }

    // CIBGLOBALD-4811 - true when a form field or a fees table value differs from the edit-start copy.
    _hasUnsavedChanges(lineItems) {
        if (!this._snapshot) return false;
        const sameValue = (a, b) => JSON.stringify(a ?? null) === JSON.stringify(b ?? null)
            || String(a ?? '') === String(b ?? '');
        const before = new Map([...this._snapshot.fieldsClientNeed, ...this._snapshot.fieldsClientSolution].map(f => [f.id, f.value]));
        const fieldChanged = [...this.fieldsClientNeed, ...this.fieldsClientSolution]
            .some(f => !f.isHidden && !sameValue(f.value, before.get(f.id)));
        const rowsBefore = new Map((this._tableLineItemsSnapshot || []).map(row => [row.Id, row]));
        const rowChanged = (lineItems || []).some(row => {
            const old = rowsBefore.get(row.Id);
            return !old || Object.keys(old).some(field => !sameValue(row[field], old[field]));
        });
        return fieldChanged || rowChanged;
    }

    _notifyEditMode(value) {
        this.dispatchEvent(new CustomEvent('editmodetab', {
            detail  : { editMode: value },
            bubbles : true,
            composed: true
        }));
    }

    _validateRequiredFields() {
        const allFields = [...this.fieldsClientNeed, ...this.fieldsClientSolution];
        const errors = allFields
            .filter(f => f.isRequired && !f.isHidden)
            .filter(f => this._isFieldValueEmpty(f.value))
            .map(f => `${f.label} cannot be empty.`);
        return errors.length ? errors.join('\n') : null;
    }

    _isFieldValueEmpty(value) {
        if (Array.isArray(value)) {
            return value.length === 0;
        }
        if (typeof value === 'string') {
            return value.trim() === '' || value === 'null';
        }
        return value === null || value === undefined;
    }

    _extractErrorMessage(error) {
        return error?.body?.message || error?.message || 'An unexpected error occurred.';
    }
}