import { LightningElement, api, track } from 'lwc';
import { lineDescriptionFields } from './dmt_opp_product_details_line_description_fields';

export default class DmtOppProductDetailsLineDescription extends LightningElement {

    isEditMode = false;

    @track fields = [...lineDescriptionFields];

    _fieldsOriginal = [...lineDescriptionFields];
    _options = {};
    _data;
    _lineAmountValue = null;
    _oldMoneyValue = null;
    _snapshot = null;
    _readOnlySnapshot = null;
    _expectedFinalTakeOverridden = false;
    _expectedFinalTakeValue = null;
    _expectedFinalTakeOverriddenSnapshot = null;

    @api get data() { return this._data; }
    set data(value) {
        this._data = value;
        this._lineAmountValue = value?.DMT_Line_Amount__c ?? null;
        this._oldMoneyValue = null;  // Reset on data load
        this._expectedFinalTakeOverridden = !this._isEmpty(value?.syndicated_loan_drawn_amount__c);

        this._recompute();
    }

    @api get fieldOptions() { return this._options; }
    set fieldOptions(value) {
        this._options = {
            g_currency_id__c: value?.catalogValues?.['C264'] || []
        };
        this._recompute();
    }

    @api enterEditMode() {
        this.isEditMode = true;
        this._snapshot = this.fields.map(f => ({ ...f }));
        this._expectedFinalTakeOverriddenSnapshot = this._expectedFinalTakeOverridden;
    }

    @api restoreSnapshot() {
        if (this._snapshot) this.fields = this._snapshot;
        this._snapshot = null;
        if (this._expectedFinalTakeOverriddenSnapshot !== undefined) {
            this._expectedFinalTakeOverridden = this._expectedFinalTakeOverriddenSnapshot;
            this._expectedFinalTakeOverriddenSnapshot = undefined;
        }
    }

    @api commitEdit() {
        this.isEditMode = false;
        this._snapshot = null;
    }

    @api validate() {
        const renderer = this.template.querySelector('c-dmt_form_renderer');
        const rendererResult = renderer?.validate?.() ?? { isValid: true, invalidFields: [] };
        const rendererIsValid = typeof rendererResult === 'object' ? rendererResult.isValid : !!rendererResult;
        const rendererInvalidFields = (typeof rendererResult === 'object' && Array.isArray(rendererResult.invalidFields))
            ? rendererResult.invalidFields
            : [];

        const invalidFieldSet = new Set(rendererInvalidFields);
        for (const field of this.fields) {
            if (!field.isRequired || field.isHidden) continue;
            const value = field.value;
            let fieldValid;
            if (Array.isArray(value)) {
                fieldValid = value.length > 0;
            } else if (value && typeof value === 'object') {
                fieldValid = !!(value.id || value.Id);
            } else {
                fieldValid = value !== null && value !== undefined && value !== '';
            }
            if (!fieldValid) {
                invalidFieldSet.add(field.label || field.apiName);
            }
        }

        const expectedDrawnValue = this._getFieldValue(this.fields, 'DMT_Expected_Drawn__c');
        if (!this._isExpectedDrawnValid(expectedDrawnValue)) {
            invalidFieldSet.add(this.getFieldLabel('DMT_Expected_Drawn__c') || 'Expected Drawn (%)');
        }

        const invalidFields = [...invalidFieldSet];
        return { isValid: rendererIsValid && invalidFields.length === 0, invalidFields };
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
        }
    }

    @api collectChanges() {
        if (!this._snapshot) return {};
        const changes = {};
        const snapMap = new Map(this._snapshot.map(f => [f.id, f]));
        for (const f of this.fields) {
            if (this._isOriginallyReadOnly(f.apiName) && f.apiName !== 'syndicated_loan_drawn_amount__c') continue;
            if (f.isHidden) continue;
            const original = snapMap.get(f.id);
            const hasChanged = String(f.value ?? '') !== String(original?.value ?? '');
            if (!hasChanged) continue;
            // Convert multipicklist array values to semicolon-separated string
            let finalValue = f.value;
            if (Array.isArray(finalValue)) {
                finalValue = finalValue.join(';');
            }
            changes[f.apiName] = (finalValue === '' || finalValue === undefined) ? null : finalValue;
        }
        //changes.syndicated_loan_drawn_amount__c = this._lineAmountValue;
        changes.syndicated_loan_drawn_amount__c = this._expectedFinalTakeValue;
        changes.DMT_OldMoney_BBVA__c = this._oldMoneyValue;
        if (this._isEmpty(this._data?.DMT_Expected_Drawn__c) && !this._isEmpty(this._getFieldValue(this.fields, 'DMT_Expected_Drawn__c'))) {
            changes.DMT_Expected_Drawn__c = this._getFieldValue(this.fields, 'DMT_Expected_Drawn__c');
        }
        return changes;
    }

    @api collectBpsFieldsValidation() {
        const invalidFields = [];
        for (const field of this.fields) {
            if (field.type !== 'number') continue;
            if (field.value === null || field.value === undefined || field.value === '') continue;
            if (this._hasMoreThanTwoDecimals(field.value)) {
                invalidFields.push(field.label || field.apiName);
            }
        }
        return { isValid: invalidFields.length === 0, invalidFields };
    }

    @api getFieldLabel(apiName) {
        const f = this.fields.find(x => x.apiName === apiName);
        return f ? f.label : null;
    }

    handleEditModeChange(event) {
        this.dispatchEvent(new CustomEvent('editmodechange', { detail: event.detail }));
    }

    handleFieldChange(event) {
        const { fieldId, value, isFieldValid } = event.detail;
        const idx = this.fields.findIndex(f => f.id === fieldId);
        if (idx === -1) return;
        const field = this.fields[idx];

        if (field.apiName === 'syndicated_loan_drawn_amount__c') {
            // Si el usuario escribe algo entonces override. Si lo deja vacío, vuelve al modo automático.
            this._expectedFinalTakeOverridden = !this._isEmpty(value);
        }

        const normalizedValue = field.apiName === 'DMT_Expected_Drawn__c'
            ? this._normalizeExpectedDrawnValue(value)
            : value;

        const newArr = this.fields.slice();
        newArr[idx] = { ...field, value: normalizedValue, isFieldValid };
        this.fields = this._applyCalculatedFields(newArr);
        this.dispatchEvent(new CustomEvent('sectionchange', { detail: { apiName: field.apiName, value: normalizedValue } }));
    }

    _recompute() {
        let next = this._fieldsOriginal.map(f => ({ ...f }));

        if (this._options) {
            next = next.map(f => {
                const options = this._options[f.apiName];
                if (!options) return f;
                const merged = { ...f, options };
                const originalRO = this._isOriginallyReadOnly(f.apiName);
                if (f.type === 'picklist' && !originalRO) merged.isReadOnly = options.length === 0;
                return merged;
            });
        }

        if (this._data) {
            next = next.map(f => ({ ...f, value: this._normalizeFieldValue(f, this._data[f.apiName]) }));
        }
        next = this._applyCalculatedFields(next);
        this.fields = next;
        if (this._readOnlySnapshot) {
            this.fields = this.fields.map(f => ({ ...f, isReadOnly: true }));
        }
    }

    _applyCalculatedFields(fields) {
        const lineAmount = this._toNumber(this._getFieldValue(fields, 'bbva_prtcp_tranche_amount__c'));
        this._lineAmountValue = lineAmount;

        // Calculate OldMoney = bbva_prtcp_tranche_amount__c - DMT_NewMoney_BBVA__c
        const bbvaCommitment = this._toNumber(this._getFieldValue(fields, 'bbva_prtcp_tranche_amount__c'));
        const newMoney = this._toNumber(this._getFieldValue(fields, 'DMT_NewMoney_BBVA__c'));
        this._oldMoneyValue = (bbvaCommitment === null || newMoney === null) ? null : (bbvaCommitment - newMoney);
        const oldMoneyWarning = this._oldMoneyValue < 0
            ? 'Old Money for BBVA is negative. Please review BBVA Commitment Line Amount and New Money for BBVA.'
            : '';

        const rawExpectedValue = this._getFieldValue(fields, 'syndicated_loan_drawn_amount__c');
        this._expectedFinalTakeValue = this._expectedFinalTakeOverridden ? this._toNumber(rawExpectedValue) : bbvaCommitment;

        return fields.map(field => {
            if (field.apiName === 'syndicated_loan_drawn_amount__c') {
                // const persistedValue = this._data?.syndicated_loan_drawn_amount__c;
                return { 
                    ...field, 
                    value: this._expectedFinalTakeValue 
                };
            }
            if (field.apiName === 'DMT_OldMoney_BBVA__c') {
                return {
                    ...field,
                    value: this._oldMoneyValue,
                    warningText: oldMoneyWarning
                };
            }
            if (field.apiName === 'DMT_Expected_Drawn__c') {
                return {
                    ...field,
                    value: this._normalizeExpectedDrawnValue(field.value)
                };
            }
            return field;
        });
    }

    _normalizeFieldValue(field, value) {
        if (field?.apiName === 'DMT_Expected_Drawn__c') {
            return this._normalizeExpectedDrawnValue(value);
        }
        return value;
    }

    _normalizeExpectedDrawnValue(value) {
        if (this._isEmpty(value)) return 0;
        const numericValue = Number(value);
        return Number.isFinite(numericValue) ? numericValue : 0;
    }

    _isExpectedDrawnValid(value) {
        if (this._isEmpty(value)) return false;
        const numericValue = Number(value);
        return Number.isFinite(numericValue) && numericValue >= 0 && numericValue <= 100;
    }

    _getFieldValue(fields, apiName) {
        return fields.find(field => field.apiName === apiName)?.value;
    }

    _toNumber(value) {
        if (value === null || value === undefined || value === '') return null;
        const numericValue = Number(value);
        return Number.isFinite(numericValue) ? numericValue : null;
    }

    _isEmpty(value) {
        return value === null || value === undefined || value === '';
    }

    _isOriginallyReadOnly(apiName) {
        // Exceptions: calculated fields that should persist
        if (apiName === 'DMT_OldMoney_BBVA__c')  return false;

        return this._fieldsOriginal.find(o => o.apiName === apiName)?.isReadOnly === true;
    }

    _hasMoreThanTwoDecimals(value) {
        const decimalPart = String(value).split('.')[1];
        return !!decimalPart && decimalPart.length > 2;
    }
}