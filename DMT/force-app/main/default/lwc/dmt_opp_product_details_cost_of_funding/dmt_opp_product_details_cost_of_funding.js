import { LightningElement, api, track } from 'lwc';
import { costOfFundingFields } from './dmt_opp_product_details_cost_of_funding_fields';


const FUNDING_CURVE_MANUAL  = 'Manual';
const FUNDING_CURVE_BBVA    = 'BBVA SA';
const LIFE_FUNDING_TERM     = 'Term';
const F_FUNDING_CURVE       = 'Funding_Curve__c';
const F_LIFE_FUNDING_TYPE   = 'Life_Funding_Type__c';
const F_FUNDING_DRAWN       = 'gf_funding_cost_db__c';
const F_FUNDING_UNDRAWN     = 'gf_funding_cost_fb__c';
const F_CURRENCY            = 'g_currency_id__c';
const F_MARGIN_RATE_TYPE    = 'DMT_RateType__c';
const FUNDING_DRAWN_API_NAMES = new Set([F_FUNDING_DRAWN, F_FUNDING_UNDRAWN]);
const AUTO_MANUAL_CURRENCIES = new Set(['EUR', 'USD', 'GBP']);

export default class DmtOppProductDetailsCostOfFunding extends LightningElement {

    isEditMode = false;

    @track fields = [...costOfFundingFields];

    _fieldsOriginal   = [...costOfFundingFields];
    _data;
    _underlyingsData = [];
    _options          = {};
    _snapshot         = null;
    _readOnlySnapshot = null;
    _currencyForcedByUnderlyingState = false;
    _fundingCurveBeforeUnderlyingForce = null;

    // ─── Public API ───────────────────────────────────────────────────────────

    @api get data() { return this._data; }
    set data(value) {
        this._data = value;
        this._recompute();
    }

    @api get underlyingsData() { return this._underlyingsData; }
    set underlyingsData(value) {
        this._underlyingsData = Array.isArray(value) ? value : [];
        this._recompute();
    }

    @api get fieldOptions() { return this._options; }
    set fieldOptions(value) {
        this._options = value || {};
        this._recompute();
    }

    @api enterEditMode() {
        this.isEditMode = true;
        this._snapshot  = this.fields.map(f => ({ ...f }));
    }

    @api restoreSnapshot() {
        if (this._snapshot) this.fields = this._snapshot;
        this._snapshot = null;
    }

    @api commitEdit() {
        this._snapshot  = null;
        this.isEditMode = false;
    }

    @api setReadOnlyMode(readOnly) {
        if (readOnly) {
            if (!this._readOnlySnapshot) {
                this._readOnlySnapshot = this.fields.map(f => ({ id: f.id, isReadOnly: f.isReadOnly }));
            }
            this.fields = this.fields.map(f => ({ ...f, isReadOnly: true }));
        } else {
            if (!this._readOnlySnapshot) return;
            const roMap = new Map(this._readOnlySnapshot.map(f => [f.id, f.isReadOnly]));
            this.fields = this.fields.map(f => ({
                ...f,
                isReadOnly: roMap.has(f.id) ? roMap.get(f.id) : f.isReadOnly
            }));
            this._readOnlySnapshot = null;
            this._applyUnderlyingCurrencyLockToFields();
        }
    }

    // Funding_Curve__c is compared as boolean and sent as 'Manual'/'BBVA SA'.
    // Persistence rules are enforced based on the FINAL state of Funding_Curve,
    // not on whether it changed in this submit, to guarantee DB consistency.
    @api collectChanges() {
        if (!this._snapshot) return {};

        const changes  = {};
        const snapMap  = new Map(this._snapshot.map(f => [f.id, f]));
        const finalIsManual = this._getFundingCurveValue();

        for (const f of this.fields) {
            if (this._isOriginallyReadOnly(f.apiName) && f.apiName !== F_FUNDING_CURVE) continue;

            const original = snapMap.get(f.id);
            let hasChanged, valueToSend;

            if (f.apiName === F_FUNDING_CURVE) {
                const curBool  = this._normalizeToBoolean(f.value);
                const origBool = this._normalizeToBoolean(original?.value);
                hasChanged  = curBool !== origBool;
                valueToSend = curBool ? FUNDING_CURVE_MANUAL : FUNDING_CURVE_BBVA;
            } else {
                hasChanged  = String(f.value ?? '') !== String(original?.value ?? '');
                valueToSend = (f.value === '' || f.value === undefined) ? null : f.value;
            }

            if (!hasChanged) continue;
            changes[f.apiName] = valueToSend;
        }

        // Enforce persistence rules based on the final Funding_Curve state
        if (finalIsManual) {
            // Manual: Life_Funding_Type__c is hidden/not applicable, so persist the default value.
            if (this._wasOriginally(F_LIFE_FUNDING_TYPE, snapMap, val => val !== null && val !== '' && val !== undefined)) {
                changes[F_LIFE_FUNDING_TYPE] = LIFE_FUNDING_TERM;
            }
        } else {
            // BBVA SA: nullify drawn/undrawn fields if they had a value
            if (this._wasOriginally(F_FUNDING_DRAWN, snapMap, val => val !== null && val !== '' && val !== undefined && val !== 0)) {
                changes[F_FUNDING_DRAWN] = null;
            }
            if (this._wasOriginally(F_FUNDING_UNDRAWN, snapMap, val => val !== null && val !== '' && val !== undefined && val !== 0)) {
                changes[F_FUNDING_UNDRAWN] = null;
            }
            // Do not force Life_Funding_Type__c here; keep user's selected value (e.g. AvgLife).
        }

        return changes;
    }

    @api getFieldLabel(apiName) {
        const f = this.fields.find(x => x.apiName === apiName);
        return f ? f.label : null;
    }

    @api collectInvalidFields() {
        const invalidFields = this.fields
            .filter(f => f.isFieldValid === false)
            .map(f => f.label || f.apiName);
        return { isValid: invalidFields.length === 0, invalidFields };
    }

    @api validate() {
        const renderer = this.template.querySelector('c-dmt_form_renderer');
        const rendererResult = renderer?.validate?.() ?? { isValid: true, invalidFields: [] };
        const rendererIsValid = typeof rendererResult === 'object' ? rendererResult.isValid : !!rendererResult;
        const rendererInvalidFields = (typeof rendererResult === 'object' && Array.isArray(rendererResult.invalidFields))
            ? rendererResult.invalidFields : [];

        const invalidFieldSet = new Set(rendererInvalidFields);
        for (const field of this.fields) {
            if (!field.isRequired || field.isHidden || field.isReadOnly) continue;
            const value = field.value;
            let fieldValid;
            if (Array.isArray(value)) {
                fieldValid = value.length > 0;
            } else if (value && typeof value === 'object') {
                fieldValid = !!(value.id || value.Id);
            } else if (field.type === 'number' || field.type === 'currency' || field.type === 'percent') {
                fieldValid = value !== null && value !== undefined && value !== '';
            } else {
                fieldValid = value !== null && value !== undefined && value !== '';
            }
            if (!fieldValid) {
                invalidFieldSet.add(field.label || field.apiName);
            }
        }

        const invalidFields = [...invalidFieldSet];
        return { isValid: rendererIsValid && invalidFields.length === 0, invalidFields };
    }

    // ─── Event handlers ───────────────────────────────────────────────────────

    handleEditModeChange(event) {
        this.dispatchEvent(new CustomEvent('editmodechange', { detail: event.detail }));
    }

    handleFieldChange(event) {
        const { fieldId, value, isFieldValid } = event.detail;
        const idx = this.fields.findIndex(f => f.id === fieldId);
        if (idx === -1) return;

        const field           = this.fields[idx];
        const apiName         = field.apiName;
        const normalizedValue = apiName === F_FUNDING_CURVE ? this._normalizeToBoolean(value) : value;
        const sectionChanges  = { [apiName]: normalizedValue };

        let newArr  = this.fields.slice();
        newArr[idx] = { ...field, value: normalizedValue, isFieldValid };

        if (apiName === F_FUNDING_CURVE) {
            const isManual = normalizedValue === true;
            // When switching to Manual, clear Life_Funding_Type__c immediately
            if (isManual) {
                newArr = this._setFieldValue(newArr, F_LIFE_FUNDING_TYPE, null);
                sectionChanges[F_LIFE_FUNDING_TYPE] = null;
            }
            // Drawn/Undrawn values are kept in memory when switching to BBVA SA so the user
            // doesn't lose them if they switch back; final nullification is done in collectChanges
            newArr = this._applyVisibilityRules(newArr, isManual);
        }

        this.fields = newArr;
        this.dispatchEvent(new CustomEvent('sectionchange', {
            detail: { changes: sectionChanges },
            bubbles: true,
            composed: true
        }));
        this.dispatchEvent(new CustomEvent('fieldchange', { detail: { fieldId, value: normalizedValue } }));
    }

    // ─── Recompute ────────────────────────────────────────────────────────────

    _recompute() {
        let next = this._fieldsOriginal.map(f => ({ ...f }));

        // Apply dynamic options from parent
        if (this._options) {
            next = next.map(f => {
                const options = this._options[f.apiName];
                if (!options) return f;
                const merged     = { ...f, options };
                const originalRO = this._isOriginallyReadOnly(f.apiName);
                if (f.type === 'picklist' && !originalRO) merged.isReadOnly = options.length === 0;
                return merged;
            });
        }

        // Funding curve is forced only when margin rate type is Fixed.
        let isManual = false;
        let isFundingCurveReadOnly = false;
        if (this._data) {
            isFundingCurveReadOnly = this._isFixedMarginRateType(this._data);
            isManual = isFundingCurveReadOnly
                ? true
                : this._normalizeToBoolean(this._data[F_FUNDING_CURVE]);

            const shouldForceManual = this._shouldForceManualByUnderlyingCurrency();
            if (shouldForceManual) {
                if (!this._currencyForcedByUnderlyingState) {
                    this._fundingCurveBeforeUnderlyingForce = isManual;
                }
                this._currencyForcedByUnderlyingState = true;
                isManual = true;
                isFundingCurveReadOnly = true;
            } else if (this._currencyForcedByUnderlyingState) {
                isManual = this._fundingCurveBeforeUnderlyingForce !== null
                    ? this._normalizeToBoolean(this._fundingCurveBeforeUnderlyingForce)
                    : isManual;
                this._currencyForcedByUnderlyingState = false;
                this._fundingCurveBeforeUnderlyingForce = null;
            }

            next = next.map(f => ({
                ...f,
                value: f.apiName === F_FUNDING_CURVE ? isManual : this._data[f.apiName]
            }));
        }

        next = next.map(f => {
            if (f.apiName === F_FUNDING_CURVE) {
                return { ...f, value: isManual, isReadOnly: isFundingCurveReadOnly || this._currencyForcedByUnderlyingState };
            }
            return f;
        });

        this.fields = this._applyVisibilityRules(next, isManual);

        // Re-apply forced read-only if the mode was active before recompute
        if (this._readOnlySnapshot) {
            this.fields = this.fields.map(f => ({ ...f, isReadOnly: true }));
        }

        this._applyUnderlyingCurrencyLockToFields();
    }

    _applyVisibilityRules(fieldsArray, isManual) {
        return fieldsArray.map(f => {
            if (FUNDING_DRAWN_API_NAMES.has(f.apiName)) return { ...f, isHidden: !isManual };
            if (f.apiName === F_LIFE_FUNDING_TYPE)      return { ...f, isHidden:  isManual };
            return f;
        });
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    _isOriginallyReadOnly(apiName) {
        return this._fieldsOriginal.find(o => o.apiName === apiName)?.isReadOnly === true;
    }

    _normalizeToBoolean(value) {
        return value === true || value === FUNDING_CURVE_MANUAL || value === 'true';
    }

    _getFundingCurveValue() {
        const f = this.fields.find(x => x.apiName === F_FUNDING_CURVE);
        return this._normalizeToBoolean(f?.value);
    }

    _isFixedMarginRateType(data) {
        const marginRateType = String(data?.[F_MARGIN_RATE_TYPE] || '').trim();
        return marginRateType === 'Fixed';
    }

    _shouldForceManualByUnderlyingCurrency() {
        if (!this._data || this._data.DMT_Line_Oneoffdeal__c !== 'Line') {
            return false;
        }
        return Array.isArray(this._underlyingsData) && this._underlyingsData.some(row => {
            if (!row || row._deleted) return false;
            const currency = String(row.DMT_Currency__c || '').trim();
            return currency !== '' && !AUTO_MANUAL_CURRENCIES.has(currency);
        });
    }

    _applyUnderlyingCurrencyLockToFields() {
        if (!this._currencyForcedByUnderlyingState) return;
        this.fields = this.fields.map(f => f.apiName === F_FUNDING_CURVE
            ? { ...f, isReadOnly: true }
            : f);
    }

    _wasOriginally(apiName, snapMap, predicate) {
        const fieldFromSnapshot = [...snapMap.values()].find(f => f.apiName === apiName);
        return fieldFromSnapshot && predicate(fieldFromSnapshot.value);
    }

    _setFieldValue(fieldsArray, apiName, value) {
        return fieldsArray.map(f => f.apiName === apiName ? { ...f, value } : f);
    }
}