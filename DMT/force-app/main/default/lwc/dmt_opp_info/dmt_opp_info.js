import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { oppInfoFields } from './dmt_opp_info_fields.js';
import getOpportunityInfoContext from '@salesforce/apex/DMT_OppInfoController.getOpportunityInfoContext';
import getPicklistOptions from '@salesforce/apex/DMT_OppInfoController.getPicklistOptions';
import saveOpportunity from '@salesforce/apex/DMT_OppInfoController.saveOpportunity';
import { getFieldValue, getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';

import getFormattedAmountsForCurrency from '@salesforce/apex/DMT_OppInfoController.getFormattedAmountsForCurrency';
import getCurrencyLabel from '@salesforce/apex/DMT_Currency_Conversion_Utils.getCurrencyLabel';
import { applyNbcMarks } from 'c/dmt_nbc_marks';

// Maps a Booking Geography value to a default Booking EFAN value.
// TODO: Populate this map once taxonomy catalog values are confirmed by business.
const BOOKING_EFAN_DEFAULTS = {
    // Example: 'GEO_VALUE': 'EFAN_VALUE'
};


const DEFAULT_READONLY = new Map(oppInfoFields.map(f => [f.id, f.isReadOnly]));
const RELATED_OPPORTUNITY_FIELDS = oppInfoFields
    .filter(f => f.sourceField)
    .map(f => f.sourceField);

export default class Dmt_opp_info extends LightningElement {
    // ─── Public API ───────────────────────────────────────────────────────────
    @api recordId;

    // Fields required by the "Passport" service that are missing on this tab, as an array of
    // { apiName, label } (per DMT_FieldsRequiredParser.parse()). Used to highlight them in the form.
    _missingPassportFields = [];
    @api
    get missingPassportFields() {
        return this._missingPassportFields;
    }
    set missingPassportFields(value) {
        this._missingPassportFields = value || [];
        if (this._dataLoaded) {
            this._applyMissingPassportHighlight();
        }
    }

    // True when the user selected a single field from dmt_missingFieldsPopover (as opposed to
    // "Review all", which sends every pending field across every tab). Only in that case do we
    // warn about a requested field that doesn't exist on this tab. Needs its own setter (instead
    // of a plain @api field) because the template sets `missing-passport-fields` before
    // `is-single-field-warning`: without this, _applyMissingPassportHighlight() would run with the
    // previous event's value, making the toasts appear one event late.
    _isSingleFieldWarning = false;
    @api
    get isSingleFieldWarning() {
        return this._isSingleFieldWarning;
    }
    set isSingleFieldWarning(value) {
        this._isSingleFieldWarning = value;
        if (this._dataLoaded) {
            this._applyMissingPassportHighlight();
        }
    }

    _stageRecord;
    @api
    get stageRecord() {
        return this._stageRecord;
    }
    set stageRecord(value) {
        this._stageRecord = value;
        this._applyReadOnlyRules();
    }

    _canEdit = true;
    @api
    get canEdit() {
        return this._canEdit;
    }
    set canEdit(value) {
        this._canEdit = !!value;
        if (!this._canEdit && this.isEditMode) {
            this._exitEditMode();
        }
        this._applyReadOnlyRules();
    }

    // ─── State ────────────────────────────────────────────────────────────────
    isEditMode = false;
    isLoading = true;
    hasError = false;
    errorMessage = '';
    isDateConsistent = true;

    @track fields = [...oppInfoFields];
    _snapshot = null;
    _options = {};
    _currencyExtraText = '';
    _maxMaturityDate = null;
    _initialDate = null;
    _minTenorValue = null;
    _dataLoaded = false;
    _relatedOpportunityRecord = null;
    // Dedupe key for the last "field not found" toast shown, so the same unmatched
    // Passport field(s) don't re-trigger the toast on every re-render/save.
    _lastUnmatchedPassportFieldsKey = null;
    // Dedupe key for the last "field already filled in" toast shown (single-field selection only).
    _lastAlreadyFilledFieldKey = null;

    // ─── Wire ─────────────────────────────────────────────────────────────────
    @wire(getPicklistOptions, { opportunityId: '$recordId' })
    wiredPicklistOptions({ data, error }) {
        if (data) {
            this._options = {
                DMT_CurrencyText__c       : data['C264']                    || [],
                DMT_branch_id_c__c  : data['bookingGeographyOptions'] || [],
                DMT_Booking_EFAN__c : data['bookingEFANOptions']       || []
            };
            this._applyOptionsToFields();
        } else if (error) {
            console.error('[dmt_opp_info] getPicklistOptions error:', error);
        }
    }

    @wire(getRecord, { recordId: '$recordId', optionalFields: RELATED_OPPORTUNITY_FIELDS })
    wiredRelatedOpportunity({ data, error }) {
        if (data) {
            this._relatedOpportunityRecord = data;
            this._applyRelatedFieldValues();
            this._applyVisibilityRules();
        } else if (error) {
            console.error('[dmt_opp_info] related approval fields error:', error);
        }
    }

    // ─── Lifecycle ────────────────────────────────────────────────────────────
    async connectedCallback() {
        try {
            
            const result = await getOpportunityInfoContext({ opportunityId: this.recordId });
            const data = result.opportunity;
            this._maxMaturityDate = result.maxMaturityDate || null;
            this._initialDate = data ? (data['DMT_DATE_Initial_Date__c'] || null) : null;
            if (this._maxMaturityDate && this._initialDate) {
                this._minTenorValue = this._wholeMonthsBetween(this._initialDate, this._maxMaturityDate);
            }

            if (data) {
                let tenorRaw = data['DMT_Tenor__c'];
                if (tenorRaw != null) {
                    tenorRaw = String(tenorRaw).match(/\d+/)?.[0] ?? tenorRaw;
                }
                this.isDateConsistent = this._isTenorConsistent(parseInt(tenorRaw, 10));

                this.fields = this.fields.map(f => {
                    let rawValue = data[f.id];
                    
                    if (f.id === 'DMT_Tenor__c' && rawValue != null) {
                        rawValue = String(rawValue).match(/\d+/)?.[0] ?? rawValue;
                    }

                    if (f.id === 'DMT_Tenor__c') {
                        const warningText = !this.isDateConsistent
                            ? 'Opportunity Tenor is inconsistent with Opportunity Products Dates'
                            : null;
                        return { ...f, value: rawValue != null ? rawValue : '', warningText, min: this._minTenorValue ?? f.min };
                    }

                    return { ...f, value: rawValue != null ? rawValue : (f.type === 'checkbox' ? false : '') };
                });

                this._applyRelatedFieldValues();
                this._applyVisibilityRules();
                const currencyValue = (this.fields.find(f => f.id === 'DMT_CurrencyText__c') || {}).value;
                this._loadCurrencyLabel(currencyValue);
            }
        } catch (error) {
            console.error('[dmt_opp_info][load]', error);
        }
        this._dataLoaded = true;
        this._applyMissingPassportHighlight();
        this.isLoading = false;
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
        this._enterEditMode();
    }

    _enterEditMode() {
        this._snapshot = {
            fields: this.fields.map(f => ({ ...f }))
        };
        this.isEditMode = true;
        this.notifyEditMode(true);
    }

    // ─── Field change ─────────────────────────────────────────────────────────
    handleFieldChange(event) {
        const { fieldId, value } = event.detail;
        const idx = this.fields.findIndex(f => f.id === fieldId);
        if (idx === -1) return;
        const updated = this.fields.slice();
        updated[idx] = { ...this.fields[idx], value };
        this.fields = updated;
        if (fieldId === 'DMT_Product_Area__c') {
            this._applyVisibilityRules();
        }
        if (fieldId === 'DMT_CurrencyText__c') {
            this._applyVisibilityRules();
            this._loadCurrencyLabel(value);
            this._recalcAmountsForCurrency(value);
        }
        if (fieldId === 'DMT_Tenor__c') {
            this._updateTenorWarning(value);
        }
        if (fieldId === 'DMT_branch_id_c__c') {
            this._autoFillBookingEFAN(value);
        }
    }

    // ─── Cancel ───────────────────────────────────────────────────────────────
    handleCancel() {
        if (this._snapshot) {
            this.fields = this._snapshot.fields;
        }
        this._exitEditMode();
    }

    // ─── Save ─────────────────────────────────────────────────────────────────
    async handleSave() {
        this.isLoading = true;
        this.hasError = false;
        this.errorMessage = '';

        try {
            const missingRequired = this.fields.filter(f =>
                f.isRequired && !f.isReadOnly && !f.isHidden &&
                (f.value === null || f.value === undefined || f.value === '')
            );

            if (missingRequired.length > 0) {
                const labels = missingRequired.map(f => f.label).join(', ');
                this.hasError = true;
                this.errorMessage = `Please fill in the following required fields: ${labels}`;
                this.isLoading = false;
                return;
            }

            const fieldValues = {};
            for (const f of this.fields) {
                if (!f.isReadOnly) {
                    fieldValues[f.apiName] = f.value;
                }
            }

            await saveOpportunity({ opportunityId: this.recordId, fieldValues });
            getRecordNotifyChange([{ recordId: this.recordId }]);

            this._applyMissingPassportHighlight();
            this._notifyConfidentialIfChanged();
            this._snapshot = null;
            this._exitEditMode();
            this.dispatchEvent(
                new ShowToastEvent({ title: 'Success', message: 'Opportunity saved successfully.', variant: 'success' })
            );

        } catch (error) {
            this._handleApexError('save', error);
        } finally {
            this.isLoading = false;
        }
    }

    // ─── Private ──────────────────────────────────────────────────────────────
    _notifyConfidentialIfChanged() {
        const current = this.fields.find(f => f.id === 'DMT_Confidential__c')?.value ?? false;
        const previous = this._snapshot?.fields.find(f => f.id === 'DMT_Confidential__c')?.value ?? false;
        if (current === previous) return;
        this.dispatchEvent(new CustomEvent('saveconfidential', {
            detail  : { confidential: current },
            bubbles : true,
            composed: true
        }));
    }

    // Parses only the yyyy-MM-dd portion of a date string, ignoring any trailing
    // time/offset info (defensive against backend values like 'yyyy-MM-dd HH:mm:ss').
    _parseDateOnly(dateStr) {
        const match = String(dateStr || '').match(/^(\d{4})-(\d{2})-(\d{2})/);
        if (!match) return null;
        return new Date(Date.UTC(Number(match[1]), Number(match[2]) - 1, Number(match[3])));
    }

    // Returns the whole number of months between two date strings (yyyy-MM-dd, with
    // or without a trailing time), ignoring any leftover days (e.g. 50 months and
    // 14 days => 50).
    _wholeMonthsBetween(startDateStr, endDateStr) {
        const d1 = this._parseDateOnly(startDateStr);
        const d2 = this._parseDateOnly(endDateStr);
        if (!d1 || !d2) return NaN;
        let months = (d2.getUTCFullYear() - d1.getUTCFullYear()) * 12 + (d2.getUTCMonth() - d1.getUTCMonth());
        if (d2.getUTCDate() < d1.getUTCDate()) {
            months -= 1;
        }
        return months;
    }

    // Compares the given tenor (in months) against the whole-months distance between
    // the initial date and the max product maturity date, ignoring leftover days.
    _isTenorConsistent(months) {
        if (!this._maxMaturityDate || !this._initialDate || isNaN(months)) {
            return true;
        }
        return months === this._wholeMonthsBetween(this._initialDate, this._maxMaturityDate);
    }

    _updateTenorWarning(tenorValue) {
        const months = parseInt(tenorValue, 10);
        const consistent = this._isTenorConsistent(months);
        this.isDateConsistent = consistent;
        const idx = this.fields.findIndex(f => f.id === 'DMT_Tenor__c');
        if (idx !== -1) {
            const updated = this.fields.slice();
            updated[idx] = { ...this.fields[idx], warningText: consistent ? null : 'Opportunity Tenor is inconsistent with Opportunity Products Dates' };
            this.fields = updated;
        }
    }

    async _recalcAmountsForCurrency(currencyText) {
        if (!currencyText) return;
        try {
            const result = await getFormattedAmountsForCurrency({ opportunityId: this.recordId, currencyText });
            if (!result) return;
            this.fields = this.fields.map(f => {
                if (f.id === 'DMT_CUR_Notional_Amount__c' || f.id === 'DMT_Opportunity_amount__c') {
                    const newValue = result[f.id];
                    return newValue != null ? { ...f, value: newValue } : f;
                }
                return f;
            });
        } catch (error) {
            console.error('[dmt_opp_info][_recalcAmountsForCurrency]', error);
            if (this._snapshot) {
                const snapshotFields = this._snapshot.fields;
                this.fields = this.fields.map(f => {
                    if (f.id === 'DMT_CUR_Notional_Amount__c' || f.id === 'DMT_Opportunity_amount__c') {
                        const snap = snapshotFields.find(s => s.id === f.id);
                        return snap ? { ...f, value: snap.value, extraText: snap.extraText } : f;
                    }
                    if (f.id === 'DMT_CurrencyText__c') {
                        const snap = snapshotFields.find(s => s.id === f.id);
                        return snap ? { ...f, value: snap.value } : f;
                    }
                    return f;
                });
            } 
            this.dispatchEvent(
                new ShowToastEvent({ title: 'Error', message: 'Could not retrieve formatted amounts. Previous values have been restored.', variant: 'error' })
            );
        }
    }

    _applyOptionsToFields() {
        this.fields = this.fields.map(f => {
            if (f.type !== 'picklist') return f;
            const options = this._options[f.id];
            return options ? { ...f, options } : f;
        });
        this._applyVisibilityRules();
    }

    _applyRelatedFieldValues() {
        if (!this._relatedOpportunityRecord) return;

        this.fields = this.fields.map(f => {
            if (!f.sourceField) return f;
            const value = getFieldValue(this._relatedOpportunityRecord, f.sourceField);
            return { ...f, value: value ?? '' };
        });
    }

    _loadCurrencyLabel(currencyIsoCode) {
        if (!currencyIsoCode) return;
        getCurrencyLabel({ currencyIsoCode })
            .then(result => {
                this._currencyExtraText = result || currencyIsoCode;
                this._applyVisibilityRules();
            })
            .catch(() => {
                this._currencyExtraText = currencyIsoCode;
                this._applyVisibilityRules();
            });
    }

    _applyVisibilityRules() {
        const productArea = (this.fields.find(f => f.id === 'DMT_Product_Area__c') || {}).value;
        const showContingent = productArea === 'IB&F';
        const showStructuredGTB = (productArea || '').trim() === 'GTB';
        const extraText = this._currencyExtraText || (this.fields.find(f => f.id === 'DMT_CurrencyText__c') || {}).value || '';
        this.fields = this.fields.map(f => {
            if (f.hideWhenEmpty) {
                const isEmpty = f.value === null || f.value === undefined || String(f.value).trim() === '';
                return f.isHidden === isEmpty ? f : { ...f, isHidden: isEmpty };
            }
            if (f.id === 'DMT_ContingentCommitments__c') {
                return f.isHidden === !showContingent ? f : { ...f, isHidden: !showContingent };
            }
            if (f.id === 'DMT_Structured_GTB__c') {
                return f.isHidden === !showStructuredGTB ? f : { ...f, isHidden: !showStructuredGTB };
            }
            if (f.id === 'DMT_Opportunity_amount__c' || f.id === 'DMT_CUR_Notional_Amount__c') {
                return f.extraText === extraText ? f : { ...f, extraText };
            }
            return f;
        });
        // NBC Local/Global marks: driven by each field's own `nbcScope` in dmt_opp_info_fields.js.
        this.fields = applyNbcMarks(this.fields, showStructuredGTB);
    }

    _applyReadOnlyRules() {
        const locked = this.disableEdit;
        this.fields = this.fields.map(f => {
            const defaultReadOnly = DEFAULT_READONLY.get(f.id) ?? false;
            const newReadOnly = locked ? true : defaultReadOnly;
            return newReadOnly === f.isReadOnly ? f : { ...f, isReadOnly: newReadOnly };
        });
    }

    // Highlights fields present in _missingPassportFields whose value is currently empty, and
    // reports up to the parent (via `passportwarningchange`) whether any are still empty so the
    // tab/More button can show a warning icon. Hidden fields are skipped entirely. Re-evaluates on
    // every call (e.g. after save) so a field that was just filled in, or hidden, stops being
    // highlighted.
    _applyMissingPassportHighlight() {
        const missing = this._missingPassportFields;
        if (!missing || missing.length === 0) {
            this._lastUnmatchedPassportFieldsKey = null;
            this._lastAlreadyFilledFieldKey = null;
            this._dispatchPassportWarningChange(false);
            return;
        }
        const missingApiNames = new Set(missing.map(entry => entry?.apiName ?? entry));
        let hasWarning = false;
        let alreadyFilledField = null;
        this.fields = this.fields.map(f => {
            if (!missingApiNames.has(f.id)) return f;
            if (f.isHidden) {
                return f.isHighlighted ? { ...f, isHighlighted: false } : f;
            }
            const isEmpty = f.value === null || f.value === undefined || f.value === '';
            if (isEmpty) {
                hasWarning = true;
            } else {
                alreadyFilledField = f;
            }
            return f.isHighlighted === isEmpty ? f : { ...f, isHighlighted: isEmpty };
        });
        if (this.isSingleFieldWarning) {
            this._notifyUnmatchedPassportFields(missing);
            this._notifyAlreadyFilledField(alreadyFilledField);
        }
        this._dispatchPassportWarningChange(hasWarning);
    }

    // Warns the user (and asks them to notify an administrator) when a single field requested via
    // dmt_missingFieldsPopover isn't actually present on this tab (e.g. missing from
    // dmt_opp_info_fields.js, or a stale/typo'd Field_Api_Name__c in
    // DMT_FieldsRequiredPassport__mdt). Only called when isSingleFieldWarning is true, and deduped
    // so it only fires once per distinct set of unmatched fields.
    _notifyUnmatchedPassportFields(missing) {
        const knownFieldIds = new Set(this.fields.map(f => f.id));
        const unmatched = missing.filter(entry => !knownFieldIds.has(entry?.apiName ?? entry));

        if (unmatched.length === 0) {
            this._lastUnmatchedPassportFieldsKey = null;
            return;
        }

        const unmatchedKey = unmatched.map(entry => entry?.apiName ?? entry).sort().join('|');
        if (unmatchedKey === this._lastUnmatchedPassportFieldsKey) return;
        this._lastUnmatchedPassportFieldsKey = unmatchedKey;

        const labels = unmatched.map(entry => entry?.label || entry?.apiName || entry).join(', ');
        this.dispatchEvent(new ShowToastEvent({
            title: 'Field not found',
            message: `We couldn't find the field(s) "${labels}" on this tab. Please search for it manually and notify an administrator so it can be configured.`,
            variant: 'warning',
            mode: 'sticky'
        }));
    }

    // Tells the user that the single field they clicked from dmt_missingFieldsPopover already has
    // a value (so there's nothing to highlight), and that the Passport should be refreshed to
    // reflect it. Deduped so it only fires once per field.
    _notifyAlreadyFilledField(field) {
        if (!field) {
            this._lastAlreadyFilledFieldKey = null;
            return;
        }
        if (field.id === this._lastAlreadyFilledFieldKey) return;
        this._lastAlreadyFilledFieldKey = field.id;

        this.dispatchEvent(new ShowToastEvent({
            title: 'Field already filled in',
            message: `"${field.label}" already has a value. Please update the Passport so it reflects the current data.`,
            variant: 'info',
            mode: 'dismissable'
        }));
    }

    _dispatchPassportWarningChange(hasWarning) {
        this.dispatchEvent(new CustomEvent('passportwarningchange', {
            detail  : { hasWarning },
            bubbles : true,
            composed: true
        }));
    }

    // ─── Auto-fill Booking EFAN based on Booking Geography ───────────────────
    _autoFillBookingEFAN(bookingGeoValue) {
        // Booking EFAN shares the same catalog as Booking Geography.
        // BOOKING_EFAN_DEFAULTS allows explicit overrides; otherwise the geo value itself is the default.
        const defaultEFAN = BOOKING_EFAN_DEFAULTS[bookingGeoValue] ?? bookingGeoValue ?? '';
        const idx = this.fields.findIndex(f => f.id === 'DMT_Booking_EFAN__c');
        if (idx !== -1 && defaultEFAN) {
            const updated = this.fields.slice();
            updated[idx] = { ...this.fields[idx], value: defaultEFAN };
            this.fields = updated;
        }
    }

    _exitEditMode() {
        this._snapshot = null;
        this.isEditMode = false;
        this.hasError = false;
        this.errorMessage = '';
        this.notifyEditMode(false);
    }

    notifyEditMode(value) {
        this.dispatchEvent(new CustomEvent('editmodetab', {
            detail   : { editMode: value },
            bubbles  : true,
            composed : true
        }));
    }

    // ─── Error handling ───────────────────────────────────────────────────────
    _handleApexError(context, error) {
        const message = error?.body?.message || error?.message || 'An unexpected error occurred. Please contact an administrator.';
        console.error(`[dmt_opp_info][${context}]`, message, error);
        this.hasError = true;
        this.errorMessage = message;
    }
}