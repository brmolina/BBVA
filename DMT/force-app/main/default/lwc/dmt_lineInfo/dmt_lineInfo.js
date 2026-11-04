import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getRecordNotifyChange, updateRecord } from 'lightning/uiRecordApi';
import checkEditPermission from '@salesforce/apex/DMT_LineController.checkEditPermission';
// Changes been made for CIBGLOBALD-4741
import setLineEditLock from '@salesforce/apex/DMT_LineController.setLineEditLock';
import saveTreasuryLineInfo from '@salesforce/apex/DMT_LineController.saveTreasuryLineInfo';
// Changes been made for CIBGLOBALD-4763 - Import approval-state UI edit eligibility for line info.
import canEditLineInApprovalStateUi from '@salesforce/apex/DMT_LineController.canEditLineInApprovalStateUi';
import getTypeOfRiskOptions from '@salesforce/apex/DMT_LineController.getTypeOfRiskOptions';
import getCommitmentOptions from '@salesforce/apex/DMT_LineController.getCommitmentOptions';
import getCurrencyOptions from '@salesforce/apex/DMT_LineController.getCurrencyOptions';
// Changes been made for CIBGLOBALD-4741
import getCurrencyLabel from '@salesforce/apex/DMT_Currency_Conversion_Utils.getCurrencyLabel';
import getEntificDisplayValue from '@salesforce/apex/DMT_LineController.getEntificDisplayValue';
import hasLineGodPermission from '@salesforce/customPermission/DMT_Line_God';
import LightningConfirm from 'lightning/confirm'; // CIBGLOBALD-4811
import previewCompareUnsavedChanges from '@salesforce/apex/DMT_ApprovalChangeStep_Handler.previewCompareUnsavedChanges'; // CIBGLOBALD-4811
import { otherProductsFields } from './dmt_lineInfo_otherProducts_fields.js';
import { sanctionFields } from './dmt_lineInfo_sanction_fields.js';
// Changes been made for CIBGLOBALD-4741
import { treasuryFields } from './dmt_lineInfo_treasury_fields.js';

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

// Changes been made for CIBGLOBALD-4741
const RECORD_FIELDS = [
    NAME_FIELD, BOOKING_GEOGRAPHY_FIELD, RISK_APPROVAL_START_FIELD, RISK_APPROVAL_END_FIELD,
    AMOUNT_FIELD, CURRENCY_ISO_CODE_FIELD, LAST_LEVEL_ID_FIELD,
    OFICINA_FIELD, INDIVIDUAL_DISPOSAL_APPROVAL_FIELD, COMMITMENT_LEVEL_TYPE_FIELD,
    RISK_APPROVAL_TERM_FIELD, BUSINESS_APPROVAL_START_FIELD, BUSINESS_APPROVAL_END_FIELD,
    BUSINESS_APPROVAL_TERM_FIELD, MIN_RAROEC_FIELD, MIN_RORC_FIELD, COMMENTS_FIELD, STATUS_FIELD,
    'DMT_Line__c.RecordType.DeveloperName'
];

// Changes been made for CIBGLOBALD-4741
// RecordType.DeveloperName (not Name/label — labels are admin-editable) → the field config that
// record type renders. Add an entry here, and its own dmt_lineInfo_<recordType>_fields.js module,
// to give another record type its own field set. A record type with no entry renders nothing.
const FIELDS_BY_RECORD_TYPE = new Map([
    ['Sanction', sanctionFields],
    ['OtherProducts', otherProductsFields],
    // Changes been made for CIBGLOBALD-4741
    ['Treasury', treasuryFields],
    ['TreasurySettlement', treasuryFields]
]);
// Changes been made for CIBGLOBALD-4741
const TREASURY_RECORD_TYPES = new Set(['Treasury', 'TreasurySettlement']);
// CIBGLOBALD-4811 - record types the Line trigger checkpoint 3 takes part in (DMT_Line_Helper).
const REOPEN_CHECK_RECORD_TYPES = new Set(['TreasurySettlement', 'OtherProducts']);

// Changes been made for CIBGLOBALD-4741
// Native Line Info component for Treasury, OtherProducts, and Sanction lines. Placed inside
// dmt_lines_tab or directly on the Sanction_Line_RP flexipage, so it resolves its own recordId
// and status rather than depending on a parent.
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
    // Changes been made for CIBGLOBALD-4741
    _recordTypeDeveloperName;

    // Empty until wiredRecord resolves the record type and picks a field set — nothing renders
    // for a record type with no entry in FIELDS_BY_RECORD_TYPE.
    @track fields = [];
    // The field config currently backing this.fields, read by _applyReadOnlyRules to restore
    // each field's correct per-record-type baseline isReadOnly.
    _baseFields = [];
    _snapshot = null;
    _lockHeld = false;
    wiredRecordResult;

    // Cached separately from this.fields (which starts empty and is only built once wiredRecord
    // resolves a record type) because these 3 wires don't depend on recordId and can resolve
    // before wiredRecord ever runs — with nothing yet in this.fields to attach options to, and
    // these Apex wires only firing once (no reactive params to retrigger them), the options would
    // otherwise be lost for good. wiredRecord reads from these caches when it (re)builds fields.
    _typeOfRiskOptions = [];
    _commitmentOptions = [];
    _currencyOptions = [];
    // Changes been made for CIBGLOBALD-4741
    _currencySuffixCode;
    _currencyExtraText = '';
    _currencyLabelRequests = new Map();
    _currencyLabelRequestId = 0;

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
                    // Changes been made for CIBGLOBALD-4741
                    const value = f.isPercent
                        ? this._toPercentagePoints(rawValue)
                        : (rawValue != null ? rawValue : emptyValue);
                    // Changes been made for CIBGLOBALD-4741
                    const extraText = f.id === 'Amount__c'
                        ? (this._currencySuffixCode === currencyCode ? this._currencyExtraText : currencyCode)
                        : f.extraText;
                    const options = optionsByFieldId[f.id] ?? f.options;
                    const minDate = f.id === 'End_Date__c' ? data.fields.Start_Date__c?.value || '' : f.minDate;
                    return { ...f, value, extraText, options, minDate };
                });
                // Changes been made for CIBGLOBALD-4741
                this._loadCurrencySuffix(currencyCode);
            }
            this._lineStatus = data.fields.Status__c?.value;
            this._geographyCode = data.fields.Booking_Geography__c?.value;
            // Changes been made for CIBGLOBALD-4741
            this._recordTypeDeveloperName = recordTypeDeveloperName;
            this._resolveEditPermission();
        } else if (error) {
            this.hasError = true;
            this.errorMessage = this._extractErrorMessage(error, 'Error loading line information.');
        }
    }

    async _resolveEditPermission() {
        try {
            if (hasLineGodPermission && this._lineStatus === 'Draft') {
                this._canEdit = this._lineStatus === 'Draft';
                return;
            }
            if (this._lineStatus === 'Draft') {
                const result = await checkEditPermission({ recordId: this.recordId });
                this._canEdit = !!result?.accessLevel_edit;
            } else {
                // Changes been made for CIBGLOBALD-4763 - Allow qualified line users to edit approval-state fields.
                this._canEdit = await canEditLineInApprovalStateUi({ recordId: this.recordId });
            }
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

    // Changes been made for CIBGLOBALD-4741
    get isTreasuryLine() {
        return TREASURY_RECORD_TYPES.has(this._recordTypeDeveloperName);
    }

    get formContainerClass() {
        return this.isEditMode ? 'slds-is-relative form-container--edit-mode' : 'slds-is-relative';
    }

    // ─── Edit mode ────────────────────────────────────────────────────────────
    // Changes been made for CIBGLOBALD-4741
    async handleEditModeChange(event) {
        if (!event.detail?.isEditMode || this.disableEdit || this.isLoading) {
            return;
        }
        this.isLoading = true;
        this.hasError = false;
        this.errorMessage = '';
        this._notifyEditingTab(true, { lockManaged: true, lockPending: true });
        try {
            const acquired = await setLineEditLock({ recordId: this.recordId, acquireLock: true });
            if (!acquired) {
                this._notifyEditingTab(false, { lockManaged: true, lockDenied: true });
                return;
            }
            this._lockHeld = true;
            this._snapshot = { fields: this.fields.map((f) => ({ ...f })) };
            this.isEditMode = true;
            getRecordNotifyChange([{ recordId: this.recordId }]);
            this._notifyEditingTab(true, { lockManaged: true });
        } catch (error) {
            this.hasError = true;
            this.errorMessage = this._extractErrorMessage(error, 'Unable to acquire the line edit lock.');
            this._notifyEditingTab(false, { lockManaged: true });
        } finally {
            this.isLoading = false;
        }
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

        // Changes been made for CIBGLOBALD-4741
        if (fieldId === 'Start_Date__c' && this.isTreasuryLine) {
            this._setFieldMinDate('End_Date__c', value || '');
        }

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
            // Changes been made for CIBGLOBALD-4741
            this._loadCurrencySuffix(value || '');
        }
    }

    async handleCancel() {
        if (this._snapshot) {
            this.fields = this._snapshot.fields;
            // Changes been made for CIBGLOBALD-4741
            this._loadCurrencySuffix(this._getFieldValue('CurrencyIsoCode') || '');
        }
        await this._exitEditMode();
    }

    // Changes been made for CIBGLOBALD-4741
    async handleSave() {
        this.isLoading = true;
        this.hasError = false;
        this.errorMessage = '';

        try {
            if (this._recordTypeDeveloperName !== 'Treasury') {
                const ownsLock = await setLineEditLock({ recordId: this.recordId, acquireLock: true });
                if (!ownsLock) {
                    throw new Error('The line edit lock is no longer owned by this user.');
                }
            }

            if (this.isTreasuryLine) {
                const startDate = this._getFieldValue('Start_Date__c');
                const endDate = this._getFieldValue('End_Date__c');
                if (startDate && endDate && endDate < startDate) {
                    this.hasError = true;
                    this.errorMessage = 'End Date must be on or after Start Date.';
                    return;
                }
            }

            const fieldValues = { Id: this.recordId };
            this.fields.forEach((f) => {
                // Skip read-only fields (e.g. the Business Approval Start Date formula, sourced
                // from the Opportunity) — LDS rejects updateRecord calls that include a
                // non-createable/updateable field.
                if (f.isReadOnly) {
                    return;
                }
                // Changes been made for CIBGLOBALD-4741
                fieldValues[f.apiName] = this._getPersistedFieldValue(f);
            });

            // CIBGLOBALD-4811 - Cancel keeps the tab in edit mode with the typed values.
            if (!(await this._confirmReopen())) {
                return;
            }

            if (this.isTreasuryLine) {
                const result = await saveTreasuryLineInfo({ recordId: this.recordId, fieldValues });
                if (result?.error === 'KO' || result?.error === true || result?.success === false) {
                    throw new Error(result?.message || 'The line information could not be saved.');
                }
            } else {
                await updateRecord({ fields: fieldValues });
            }
            getRecordNotifyChange([{ recordId: this.recordId }]);

            this._snapshot = null;
            await this._exitEditMode();
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

    /**
     * CIBGLOBALD-4811 - Asks before a save that would reopen features. Same filter as the Line trigger
     * checkpoint 3 (DMT_Line_Helper.restartApprovalTasksOnLineResubmission): record type TreasurySettlement
     * or OtherProducts, status Ready to close before and after the save, Cases 'readytoclose'. Only the
     * editable fields changed since edit mode started are sent, with the value the save stores
     * (_getPersistedFieldValue), to DMT_ApprovalChangeStep_Handler.previewCompareUnsavedChanges; none
     * changed -> no call. A failed check returns true: the save goes ahead.
     * @returns true to save, false when the user cancels
     */
    async _confirmReopen() {
        if (this._lineStatus !== 'Ready to close' || !REOPEN_CHECK_RECORD_TYPES.has(this._recordTypeDeveloperName) || !this._snapshot) {
            return true;
        }

        const unsavedValues = {};
        for (const f of this.fields) {
            const before = this._snapshot.fields.find((s) => s.id === f.id);
            if (!f.isReadOnly && before && f.value !== before.value) {
                unsavedValues[f.apiName] = this._getPersistedFieldValue(f);
            }
        }
        if (Object.keys(unsavedValues).length === 0) {
            return true;
        }

        try {
            const features = await previewCompareUnsavedChanges({
                recordId: this.recordId,
                caseTypeToCheck: 'readytoclose',
                unsavedValues
            });
            if (!features || features.length === 0) {
                return true;
            }
        } catch (error) {
            console.error('[dmt_lineInfo][_confirmReopen]', error);
            return true;
        }

        return LightningConfirm.open({
            label: 'Modify Line?',
            message: 'The Line will be modified and the associated cases and tasks will be reopened.' +
                '\n\nDo you want to modify the Line?',
            theme: 'warning'
        });
    }

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

    // Changes been made for CIBGLOBALD-4741
    _toPercentagePoints(value) {
        return value == null || value === '' ? '' : Number((Number(value) * 100).toFixed(4));
    }

    // Changes been made for CIBGLOBALD-4741
    _getPersistedFieldValue(field) {
        if (field.value == null || field.value === '') {
            return null;
        }
        if (!field.isPercent) {
            return field.value;
        }
        const percentage = Number(field.value);
        if (!Number.isFinite(percentage) || percentage < 0 || percentage > 100) {
            throw new Error(`${field.label} must be a percentage between 0 and 100.`);
        }
        return Number((percentage / 100).toFixed(6));
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

    // Changes been made for CIBGLOBALD-4741
    async _loadCurrencySuffix(currencyCode) {
        if (!this.fields.some((field) => field.id === 'Amount__c')
            || currencyCode === this._currencySuffixCode) {
            return;
        }
        this._currencySuffixCode = currencyCode;
        const requestId = ++this._currencyLabelRequestId;
        this._applyCurrencySuffix(currencyCode);
        if (!currencyCode) {
            return;
        }

        try {
            if (!this._currencyLabelRequests.has(currencyCode)) {
                this._currencyLabelRequests.set(currencyCode, getCurrencyLabel({ currencyIsoCode: currencyCode }));
            }
            const label = await this._currencyLabelRequests.get(currencyCode);
            if (requestId === this._currencyLabelRequestId) {
                this._applyCurrencySuffix(label || currencyCode);
            }
        } catch (error) {
            this._currencyLabelRequests.delete(currencyCode);
            if (requestId === this._currencyLabelRequestId) {
                this._applyCurrencySuffix(currencyCode);
            }
        }
    }

    // Changes been made for CIBGLOBALD-4741
    _applyCurrencySuffix(extraText) {
        this._currencyExtraText = extraText;
        this.fields = this.fields.map((field) => field.id === 'Amount__c'
            ? { ...field, extraText }
            : field);
    }

    _setFieldMinDate(fieldId, minDate) {
        const idx = this.fields.findIndex((f) => f.id === fieldId);
        if (idx === -1) {
            return;
        }
        const updated = this.fields.slice();
        updated[idx] = { ...this.fields[idx], minDate };
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

    // Changes been made for CIBGLOBALD-4741
    async _exitEditMode() {
        this._snapshot = null;
        this.isEditMode = false;
        this.hasError = false;
        this.errorMessage = '';
        if (this._lockHeld) {
            try {
                const released = await setLineEditLock({ recordId: this.recordId, acquireLock: false });
                if (!released) {
                    throw new Error('The line edit lock could not be released.');
                }
                this._lockHeld = false;
                getRecordNotifyChange([{ recordId: this.recordId }]);
            } catch (error) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Edit lock not released',
                    message: this._extractErrorMessage(error, 'The line edit lock could not be released.'),
                    variant: 'warning'
                }));
            }
        }
        this._notifyEditingTab(false, { lockManaged: true });
    }

    _notifyEditingTab(isEditing, extraDetail = {}) {
        this.dispatchEvent(new CustomEvent('editingtab', {
            detail: { tab: isEditing ? 'lineinfo' : null, ...extraDetail },
            bubbles: true,
            composed: true
        }));
    }
}