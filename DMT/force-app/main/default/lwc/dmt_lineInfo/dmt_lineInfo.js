import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getRecordNotifyChange, updateRecord } from 'lightning/uiRecordApi';
import checkEditPermission from '@salesforce/apex/DMT_LineController.checkEditPermission';
import getTypeOfRiskOptions from '@salesforce/apex/DMT_LineController.getTypeOfRiskOptions';
import getCommitmentOptions from '@salesforce/apex/DMT_LineController.getCommitmentOptions';
import getCurrencyOptions from '@salesforce/apex/DMT_LineController.getCurrencyOptions';
import getEntificDisplayValue from '@salesforce/apex/DMT_LineController.getEntificDisplayValue';
import hasLineGodPermission from '@salesforce/customPermission/DMT_Line_God';
import { otherProductsFields } from './dmt_lineInfo_otherProducts_fields.js';
import { sanctionFields } from './dmt_lineInfo_sanction_fields.js';

import NAME_FIELD from '@salesforce/schema/DMT_Line__c.Name';
import BOOKING_GEOGRAPHY_FIELD from '@salesforce/schema/DMT_Line__c.Booking_Geography__c';
import RISK_APPROVAL_START_FIELD from '@salesforce/schema/DMT_Line__c.Start_Date__c';
import RISK_APPROVAL_END_FIELD from '@salesforce/schema/DMT_Line__c.End_Date__c';
import AMOUNT_FIELD from '@salesforce/schema/DMT_Line__c.Amount__c';
import CURRENCY_ISO_CODE_FIELD from '@salesforce/schema/DMT_Line__c.CurrencyIsoCode';
import LAST_LEVEL_ID_FIELD from '@salesforce/schema/DMT_Line__c.DMT_LastLevelId__c';
import OFICINA_FIELD from '@salesforce/schema/DMT_Line__c.DMT_Oficina__c';
import INDIVIDUAL_DISPOSAL_APPROVAL_FIELD from '@salesforce/schema/DMT_Line__c.DMT_Individual_Disposal_Approval__c';
import COMMITMENT_LEVEL_TYPE_FIELD from '@salesforce/schema/DMT_Line__c.g_line_commitment_level_type__c';
import RISK_APPROVAL_TERM_FIELD from '@salesforce/schema/DMT_Line__c.DMT_Risk_Approval_Term__c';
import BUSINESS_APPROVAL_START_FIELD from '@salesforce/schema/DMT_Line__c.DMT_Bussiness_Approved_Date__c';
import BUSINESS_APPROVAL_END_FIELD from '@salesforce/schema/DMT_Line__c.DMT_Business_Approved_End_Date__c';
import BUSINESS_APPROVAL_TERM_FIELD from '@salesforce/schema/DMT_Line__c.DMT_Business_Approval_Term_n__c';
import MIN_RAROEC_FIELD from '@salesforce/schema/DMT_Line__c.gf_min_raroec_wo_fcg_per__c';
import MIN_RORC_FIELD from '@salesforce/schema/DMT_Line__c.gf_min_rorc_wo_fcg_per__c';
import COMMENTS_FIELD from '@salesforce/schema/DMT_Line__c.DMT_Comments__c';
import STATUS_FIELD from '@salesforce/schema/DMT_Line__c.Status__c';

const RECORD_FIELDS = [
    NAME_FIELD, BOOKING_GEOGRAPHY_FIELD, RISK_APPROVAL_START_FIELD, RISK_APPROVAL_END_FIELD,
    AMOUNT_FIELD, CURRENCY_ISO_CODE_FIELD, LAST_LEVEL_ID_FIELD,
    OFICINA_FIELD, INDIVIDUAL_DISPOSAL_APPROVAL_FIELD, COMMITMENT_LEVEL_TYPE_FIELD,
    RISK_APPROVAL_TERM_FIELD, BUSINESS_APPROVAL_START_FIELD, BUSINESS_APPROVAL_END_FIELD,
    BUSINESS_APPROVAL_TERM_FIELD, MIN_RAROEC_FIELD, MIN_RORC_FIELD, COMMENTS_FIELD, STATUS_FIELD,
    'DMT_Line__c.RecordType.DeveloperName'
];

// RecordType.DeveloperName (not Name/label — labels are admin-editable) → the field config that
// record type renders. Add an entry here, and its own dmt_lineInfo_<recordType>_fields.js module,
// to give another record type its own field set. A record type with no entry renders nothing.
const FIELDS_BY_RECORD_TYPE = new Map([
    ['Sanction', sanctionFields],
    ['OtherProducts', otherProductsFields]
]);

// CIBGLOBALD-3779: native LWC replacement for the Line Info tab for OtherProducts and Sanction
// ("Approval") lines. Placed either inside dmt_lines_tab (OtherProducts) or directly on the
// Sanction_Line_RP flexipage (Sanction), so it resolves its own recordId/status rather than
// depending on a parent.
export default class Dmt_lineInfo extends LightningElement {
    // ─── Public API ───────────────────────────────────────────────────────────
    // recordId is auto-populated by Lightning App Builder on any Record Page, and passed
    // explicitly when embedded inside dmt_lines_tab.
    @api recordId;

    // ─── State ────────────────────────────────────────────────────────────────
    isEditMode = false;
    isLoading = false;
    hasError = false;
    errorMessage = '';
    _canEdit = false;
    _lineStatus;
    _geographyCode;

    // Empty until wiredRecord resolves the record type and picks a field set — nothing renders
    // for a record type with no entry in FIELDS_BY_RECORD_TYPE.
    @track fields = [];
    // The field config currently backing this.fields, read by _applyReadOnlyRules to restore
    // each field's correct per-record-type baseline isReadOnly.
    _baseFields = [];
    _snapshot = null;
    wiredRecordResult;

    // Cached separately from this.fields (which starts empty and is only built once wiredRecord
    // resolves a record type) because these 3 wires don't depend on recordId and can resolve
    // before wiredRecord ever runs — with nothing yet in this.fields to attach options to, and
    // these Apex wires only firing once (no reactive params to retrigger them), the options would
    // otherwise be lost for good. wiredRecord reads from these caches when it (re)builds fields.
    _typeOfRiskOptions = [];
    _commitmentOptions = [];
    _currencyOptions = [];

    // ─── Wire ─────────────────────────────────────────────────────────────────
    // Type of risk picklist's options — same catalog ('B444') the old FlexCard's combobox used.
    @wire(getTypeOfRiskOptions)
    wiredTypeOfRiskOptions({ data, error }) {
        if (data) {
            this._typeOfRiskOptions = data.map((o) => ({ label: o.label, value: o.value }));
            this._applyCachedOptions('DMT_LastLevelId__c', this._typeOfRiskOptions);
        } else if (error) {
            this.hasError = true;
            this.errorMessage = this._extractErrorMessage(error, 'Error loading type of risk options.');
        }
    }

    // Committed/Uncommitted picklist's options — same catalog ('H405') the old FlexCard's
    // combobox used.
    @wire(getCommitmentOptions)
    wiredCommitmentOptions({ data, error }) {
        if (data) {
            this._commitmentOptions = data.map((o) => ({ label: o.label, value: o.value }));
            this._applyCachedOptions('g_line_commitment_level_type__c', this._commitmentOptions);
        } else if (error) {
            this.hasError = true;
            this.errorMessage = this._extractErrorMessage(error, 'Error loading commitment options.');
        }
    }

    // Currency picklist's options, from the org's active currencies.
    @wire(getCurrencyOptions)
    wiredCurrencyOptions({ data, error }) {
        if (data) {
            this._currencyOptions = data.map((o) => ({ label: o.label, value: o.value }));
            this._applyCachedOptions('CurrencyIsoCode', this._currencyOptions);
        } else if (error) {
            this.hasError = true;
            this.errorMessage = this._extractErrorMessage(error, 'Error loading currency options.');
        }
    }

    // Merges newly-arrived options into this.fields if that field is already present (i.e. this
    // wire resolved after wiredRecord already built the array) — a no-op otherwise, since
    // wiredRecord itself pulls from the option caches whenever it (re)builds this.fields.
    // Skipped mid-edit for the same reason as _applyReadOnlyRules: dmt_form_renderer only commits
    // a field's value on blur, so reassigning this.fields before that blur would redraw any
    // in-progress, not-yet-committed edit back to its last saved value.
    _applyCachedOptions(fieldId, options) {
        if (this._snapshot) {
            return;
        }
        this.fields = this.fields.map((f) => (f.id === fieldId ? { ...f, options } : f));
    }

    // Resolves the Entific display value (Booking_Geography__c expanded to "code - country name")
    // once the record wire below has populated _geographyCode. Reactive on that property rather
    // than recordId directly, so it only re-runs when the underlying code actually changes.
    @wire(getEntificDisplayValue, { geographyCode: '$_geographyCode' })
    wiredEntificDisplayValue({ data, error }) {
        if (data) {
            if (!this._snapshot) {
                this.fields = this.fields.map((f) => (f.id === 'Entific' ? { ...f, value: data } : f));
            }
        } else if (error) {
            this.hasError = true;
            this.errorMessage = this._extractErrorMessage(error, 'Error loading Entific value.');
        }
    }

    // Self-sufficient: reads Status__c off the same wired record rather than depending on a
    // parent-passed prop, so this component works both embedded (dmt_lines_tab) and placed
    // directly on a record page (Sanction_Line_RP). Can refire independently of anything the user
    // does in this tab (e.g. LDS cache invalidation triggered elsewhere on the page).
    @wire(getRecord, { recordId: '$recordId', fields: RECORD_FIELDS })
    wiredRecord(result) {
        this.wiredRecordResult = result;
        const { data, error } = result;
        if (data) {
            const recordTypeDeveloperName = data.fields.RecordType?.value?.fields?.DeveloperName?.value;
            const baseFields = FIELDS_BY_RECORD_TYPE.get(recordTypeDeveloperName);
            if (!baseFields) {
                console.info(`dmt_lineInfo: no field config for record type '${recordTypeDeveloperName}', nothing to render.`);
                return;
            }
            // Tracked separately from this.fields (which gets live edits merged in) so
            // _applyReadOnlyRules always has the correct per-record-type baseline to restore to —
            // a single merged map across both field sets would collide on shared ids like
            // Start_Date__c/End_Date__c, which have different isReadOnly values per record type.
            this._baseFields = baseFields;
            const currencyCode = data.fields.CurrencyIsoCode?.value || '';
            // Options come from the dedicated caches (see _typeOfRiskOptions etc. above), not from
            // whatever this.fields currently holds, since this wire can (re)build the array before
            // those wires have ever run.
            const optionsByFieldId = {
                DMT_LastLevelId__c: this._typeOfRiskOptions,
                g_line_commitment_level_type__c: this._commitmentOptions,
                CurrencyIsoCode: this._currencyOptions
            };
            // Entific isn't a real DMT_Line__c field — its value comes from
            // wiredEntificDisplayValue, so it's carried over from this.fields instead of rebuilt.
            const currentEntificField = this.fields.find((f) => f.id === 'Entific');
            if (!this._snapshot) {
                this.fields = baseFields.map((f) => {
                    if (f.id === 'Entific') {
                        return currentEntificField ?? f;
                    }
                    const rawValue = data.fields[f.apiName] ? data.fields[f.apiName].value : null;
                    const emptyValue = f.type === 'checkbox' ? false : '';
                    const placeholder = f.id === 'Amount__c' ? currencyCode : f.placeholder;
                    const options = optionsByFieldId[f.id] ?? f.options;
                    return { ...f, value: rawValue != null ? rawValue : emptyValue, placeholder, options };
                });
            }
            this._lineStatus = data.fields.Status__c?.value;
            this._geographyCode = data.fields.Booking_Geography__c?.value;
            this._resolveEditPermission();
        } else if (error) {
            this.hasError = true;
            this.errorMessage = this._extractErrorMessage(error, 'Error loading line information.');
        }
    }

    async _resolveEditPermission() {
        try {
            if (hasLineGodPermission) {
                this._canEdit = this._lineStatus === 'Draft';
                return;
            }
            const result = await checkEditPermission({ recordId: this.recordId });
            this._canEdit = this._lineStatus === 'Draft' && !!result?.accessLevel_edit;
        } catch (error) {
            this._canEdit = false;
        } finally {
            this._applyReadOnlyRules();
        }
    }

    // Without this, every field's pencil (dmt_form_renderer only hides it when field.isReadOnly
    // is true) stays visible even when the user can't actually edit — clicking it then silently
    // no-ops in handleEditModeChange's disableEdit guard, which looks like a broken button instead
    // of a permission boundary.
    _applyReadOnlyRules() {
        // Skipped mid-edit so an in-progress, not-yet-saved change isn't overwritten — disableEdit
        // still reflects the latest _canEdit, this just defers the fields-array rewrite.
        if (this._snapshot) {
            return;
        }
        const locked = this.disableEdit;
        const defaultReadOnlyById = new Map(this._baseFields.map((f) => [f.id, f.isReadOnly]));
        this.fields = this.fields.map((f) => {
            const defaultReadOnly = defaultReadOnlyById.get(f.id) ?? false;
            const newReadOnly = locked ? true : defaultReadOnly;
            return newReadOnly === f.isReadOnly ? f : { ...f, isReadOnly: newReadOnly };
        });
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
        if (!event.detail?.isEditMode || this.disableEdit) {
            return;
        }
        this._snapshot = { fields: this.fields.map((f) => ({ ...f })) };
        this.isEditMode = true;
        this._notifyEditingTab(true);
    }

    handleFieldChange(event) {
        const { fieldId, value } = event.detail;
        const idx = this.fields.findIndex((f) => f.id === fieldId);
        if (idx === -1) {
            return;
        }
        const updated = this.fields.slice();
        updated[idx] = { ...this.fields[idx], value };
        this.fields = updated;

        // Start/End Date/Term stay mutually consistent: editing Term recalculates End Date
        // (Start fixed); editing either date recalculates Term from the pair (matching what's
        // now on screen), never the other date. Same pattern for both Risk Approval and Business
        // Approval (Business Approval's Start Date is a read-only formula off the Opportunity, so
        // only its Term/End Date are ever edited here).
        if (fieldId === 'DMT_Risk_Approval_Term__c') {
            this._recalculateEndDateFromTerm('Start_Date__c', 'End_Date__c', value);
        } else if (fieldId === 'Start_Date__c' || fieldId === 'End_Date__c') {
            this._recalculateTermFromDates('Start_Date__c', 'End_Date__c', 'DMT_Risk_Approval_Term__c');
        } else if (fieldId === 'DMT_Business_Approval_Term_n__c') {
            this._recalculateEndDateFromTerm('DMT_Bussiness_Approved_Date__c', 'DMT_Business_Approved_End_Date__c', value);
        } else if (fieldId === 'DMT_Business_Approved_End_Date__c') {
            this._recalculateTermFromDates('DMT_Bussiness_Approved_Date__c', 'DMT_Business_Approved_End_Date__c', 'DMT_Business_Approval_Term_n__c');
        } else if (fieldId === 'CurrencyIsoCode') {
            // Amount's placeholder mirrors whatever currency is currently selected.
            this._setFieldPlaceholder('Amount__c', value || '');
        }
    }

    handleCancel() {
        if (this._snapshot) {
            this.fields = this._snapshot.fields;
        }
        this._exitEditMode();
    }

    async handleSave() {
        this.isLoading = true;
        this.hasError = false;
        this.errorMessage = '';

        try {
            const fieldValues = { Id: this.recordId };
            this.fields.forEach((f) => {
                // Skip read-only fields (e.g. the Business Approval Start Date formula, sourced
                // from the Opportunity) — LDS rejects updateRecord calls that include a
                // non-createable/updateable field.
                if (f.isReadOnly) {
                    return;
                }
                fieldValues[f.apiName] = f.value === '' ? null : f.value;
            });

            await updateRecord({ fields: fieldValues });
            getRecordNotifyChange([{ recordId: this.recordId }]);

            this._snapshot = null;
            this._exitEditMode();
            this.dispatchEvent(
                new ShowToastEvent({ title: 'Success', message: 'Line info saved successfully.', variant: 'success' })
            );
        } catch (error) {
            this.hasError = true;
            this.errorMessage = this._extractErrorMessage(error, 'An unexpected error occurred while saving.');
        } finally {
            this.isLoading = false;
        }
    }

    // updateRecord's top-level error.body.message is often a generic wrapper (e.g. 'An error
    // occurred while trying to update the record'); the specific reason — a field-precision
    // error, a validation rule, etc. — lives in error.body.output.fieldErrors (single-field
    // errors) or error.body.output.errors (record-level errors) instead.
    _extractErrorMessage(error, fallback) {
        const fieldErrors = error?.body?.output?.fieldErrors;
        if (fieldErrors) {
            const firstFieldMessage = Object.values(fieldErrors)[0]?.[0]?.message;
            if (firstFieldMessage) {
                return firstFieldMessage;
            }
        }
        const pageErrorMessage = error?.body?.output?.errors?.[0]?.message;
        if (pageErrorMessage) {
            return pageErrorMessage;
        }
        return error?.body?.message || error?.message || fallback;
    }

    // ─── Private ──────────────────────────────────────────────────────────────

    // Recalculates End Date from the (fixed) Start Date + the edited term, in whole months.
    // Shared by Risk Approval (Start_Date__c/End_Date__c/DMT_Risk_Approval_Term__c) and Business
    // Approval (DMT_Bussiness_Approved_Date__c/DMT_Business_Approved_End_Date__c/
    // DMT_Business_Approval_Term_n__c) — see handleFieldChange.
    _recalculateEndDateFromTerm(startFieldId, endFieldId, termValue) {
        const startDate = this._parseDateOnly(this._getFieldValue(startFieldId));
        const months = parseInt(termValue, 10);
        if (!startDate || Number.isNaN(months)) {
            return;
        }

        const end = new Date(Date.UTC(startDate.getUTCFullYear(), startDate.getUTCMonth() + months, startDate.getUTCDate()));
        this._setFieldValue(endFieldId, end.toISOString().slice(0, 10));
    }

    // Recalculates Term from the current Start/End Date pair, whichever one was just edited.
    // Mirrors dmt_opp_info.js's _wholeMonthsBetween (whole calendar months, ignoring any leftover
    // days unless the end day-of-month falls before the start day-of-month).
    _recalculateTermFromDates(startFieldId, endFieldId, termFieldId) {
        const months = this._wholeMonthsBetween(
            this._getFieldValue(startFieldId),
            this._getFieldValue(endFieldId)
        );
        if (Number.isNaN(months)) {
            return;
        }
        this._setFieldValue(termFieldId, months);
    }

    _wholeMonthsBetween(startDateStr, endDateStr) {
        const d1 = this._parseDateOnly(startDateStr);
        const d2 = this._parseDateOnly(endDateStr);
        if (!d1 || !d2) {
            return NaN;
        }
        let months = (d2.getUTCFullYear() - d1.getUTCFullYear()) * 12 + (d2.getUTCMonth() - d1.getUTCMonth());
        if (d2.getUTCDate() < d1.getUTCDate()) {
            months -= 1;
        }
        return months;
    }

    _getFieldValue(fieldId) {
        return this.fields.find((f) => f.id === fieldId)?.value;
    }

    _setFieldValue(fieldId, value) {
        const idx = this.fields.findIndex((f) => f.id === fieldId);
        if (idx === -1) {
            return;
        }
        const updated = this.fields.slice();
        updated[idx] = { ...this.fields[idx], value };
        this.fields = updated;
    }

    _setFieldPlaceholder(fieldId, placeholder) {
        const idx = this.fields.findIndex((f) => f.id === fieldId);
        if (idx === -1) {
            return;
        }
        const updated = this.fields.slice();
        updated[idx] = { ...this.fields[idx], placeholder };
        this.fields = updated;
    }

    // Parses only the yyyy-MM-dd portion of a date string.
    _parseDateOnly(dateStr) {
        const match = String(dateStr || '').match(/^(\d{4})-(\d{2})-(\d{2})/);
        if (!match) {
            return null;
        }
        return new Date(Date.UTC(Number(match[1]), Number(match[2]) - 1, Number(match[3])));
    }

    _exitEditMode() {
        this._snapshot = null;
        this.isEditMode = false;
        this.hasError = false;
        this.errorMessage = '';
        this._notifyEditingTab(false);
    }

    _notifyEditingTab(isEditing) {
        this.dispatchEvent(new CustomEvent('editingtab', {
            detail: { tab: isEditing ? 'lineinfo' : null },
            bubbles: true,
            composed: true
        }));
    }
}