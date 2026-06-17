import { LightningElement, api, track } from 'lwc';
import { dealDescriptionFields } from './dmt_opp_product_details_deal_description_fields';

export default class DmtOppProductDetailsDealDescription extends LightningElement {

    isEditMode = false;

    @track fields = [...dealDescriptionFields];

    _fieldsOriginal = [...dealDescriptionFields];
    _data;
    _options = {};
    _snapshot = null;
    _readOnlySnapshot = null;

    @api get data() { return this._data; }
    set data(value) {
        this._data = value;
        this._recompute();
    }

    @api get fieldOptions() { return this._options; }
    set fieldOptions(value) {
        this._options = value || {};
        this._recompute();
    }

    @api enterEditMode() {
        this.isEditMode = true;
        this._snapshot = this.fields.map(f => ({ ...f }));
    }

    @api restoreSnapshot() {
        if (this._snapshot) this.fields = this._snapshot;
        this._snapshot = null;
    }

    @api commitEdit() {
        this._snapshot = null;
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
        }
    }

    @api collectChanges() {
        if (!this._snapshot) return {};
        const changes = {};
        const snapMap = new Map(this._snapshot.map(f => [f.id, f]));

        for (const f of this.fields) {
            if (this._isOriginallyReadOnly(f.apiName)) continue;
            if (f.isHidden) continue;

            const original = snapMap.get(f.id);
            const hasChanged = String(f.value ?? '') !== String(original?.value ?? '');
            if (!hasChanged) continue;

            changes[f.apiName] = (f.value === '' || f.value === undefined) ? null : f.value;
        }

        const inferredTargets = ['DMT_NewMoney_BBVA__c', 'syndicated_loan_drawn_amount__c'];
        for (const apiName of inferredTargets) {
            if (changes[apiName] !== undefined) continue;

            const persistedValue = this._data?.[apiName];
            const fieldValue = this._getFieldValue(this.fields, apiName);
            if (this._isEmpty(persistedValue) && !this._isEmpty(fieldValue)) {
                changes[apiName] = fieldValue;
            }
        }

        return changes;
    }

    @api getFieldLabel(apiName) {
        const f = this.fields.find(x => x.apiName === apiName);
        return f ? f.label : null;
    }

    @api collectBpsFieldsValidation() {
        const invalidFields = [];

        for (const field of this.fields) {
            if (!this._isBpsLabel(field.label)) continue;
            if (field.value === null || field.value === undefined || field.value === '') continue;
            if (this._hasMoreThanTwoDecimals(field.value)) {
                invalidFields.push(field.label || field.apiName);
            }
        }

        return {
            isValid: invalidFields.length === 0,
            invalidFields
        };
    }

    @api collectNegativeFieldsValidation() {
        const invalidFields = [];

        for (const field of this.fields) {
            if (this._isOriginallyReadOnly(field.apiName)) continue;
            if (field.isHidden) continue;
            if (field.min === undefined || field.min === null) continue;
            if (field.value === null || field.value === undefined || field.value === '') continue;
            if (Number(field.value) < field.min) {
                invalidFields.push(field.label || field.apiName);
            }
        }

        return {
            isValid: invalidFields.length === 0,
            invalidFields
        };
    }

    handleEditModeChange(event) {
        this.dispatchEvent(new CustomEvent('editmodechange', { detail: event.detail }));
    }

    handleFieldChange(event) {
        const { fieldId, value } = event.detail;
        const idx = this.fields.findIndex(f => f.id === fieldId);
        if (idx === -1) return;

        const field = this.fields[idx];
        const newArr = this.fields.slice();
        newArr[idx] = { ...field, value };
        this.fields = this._applyCalculatedFields(newArr);
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
            next = next.map(f => ({ ...f, value: this._data[f.apiName] }));
        }

        next = this._applyCalculatedFields(next);
        next = this._preserveInProgressValues(next);
        this.fields = this._applyCalculatedFields(next);

        if (this._readOnlySnapshot) {
            this.fields = this.fields.map(f => ({ ...f, isReadOnly: true }));
        }
    }

    _preserveInProgressValues(nextFields) {
        if (!this.isEditMode || !this._snapshot || !Array.isArray(this.fields) || this.fields.length === 0) {
            return nextFields;
        }

        const currentMap = new Map(this.fields.map(field => [field.id, field.value]));
        return nextFields.map(field => {
            if (this._isOriginallyReadOnly(field.apiName)) return field;
            if (!currentMap.has(field.id)) return field;

            const currentValue = currentMap.get(field.id);
            const hasChangedVsRecomputed = String(currentValue ?? '') !== String(field.value ?? '');
            return hasChangedVsRecomputed ? { ...field, value: currentValue } : field;
        });
    }

    _applyCalculatedFields(fields) {
        const bbvaRaw = this._getFieldValue(fields, 'bbva_prtcp_tranche_amount__c');
        const bbvaHasValue = !this._isEmpty(bbvaRaw);
        const bbvaCommitment = bbvaHasValue ? this._toNumber(bbvaRaw) : null;

        const newMoneyValue = this._inferFromBbvaIfEmpty(this._getFieldValue(fields, 'DMT_NewMoney_BBVA__c'), bbvaCommitment);
        const finalTake = this._inferFromBbvaIfEmpty(this._getFieldValue(fields, 'syndicated_loan_drawn_amount__c'), bbvaCommitment);

        const newMoney = this._isEmpty(newMoneyValue) ? null : this._toNumber(newMoneyValue);
        const oldMoney = (bbvaCommitment === null || newMoney === null) ? null : (bbvaCommitment - newMoney);

        return fields.map(field => {
            if (field.apiName === 'DMT_OldMoney_BBVA__c') {
                return { ...field, value: oldMoney };
            }
            if (field.apiName === 'DMT_NewMoney_BBVA__c') {
                return { ...field, value: newMoneyValue };
            }
            if (field.apiName === 'syndicated_loan_drawn_amount__c') {
                return { ...field, value: finalTake };
            }
            return field;
        });
    }

    _getFieldValue(fields, apiName) {
        return fields.find(field => field.apiName === apiName)?.value;
    }

    _toNumber(value) {
        const numericValue = Number(value);
        return Number.isFinite(numericValue) ? numericValue : 0;
    }

    _inferFromBbvaIfEmpty(value, bbvaCommitment) {
        if (!this._isEmpty(value)) {
            return value;
        }
        return this._isEmpty(bbvaCommitment) ? null : bbvaCommitment;
    }

    _isEmpty(value) {
        return value === null || value === undefined || value === '';
    }

    _isBpsLabel(label) {
        return typeof label === 'string' && label.toLowerCase().includes('bps');
    }

    _hasMoreThanTwoDecimals(value) {
        const stringValue = String(value);
        const decimalPart = stringValue.split('.')[1];
        return !!decimalPart && decimalPart.length > 2;
    }

    _isOriginallyReadOnly(apiName) {
        return this._fieldsOriginal.find(o => o.apiName === apiName)?.isReadOnly === true;
    }
}