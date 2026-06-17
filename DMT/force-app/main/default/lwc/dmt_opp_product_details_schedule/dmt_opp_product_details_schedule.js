import { LightningElement, api, track } from 'lwc';
import { scheduleFields } from './dmt_opp_product_details_schedule_fields';

const F_CURRENCY = 'g_currency_id__c';
const F_AMORT_TYPE = 'gf_amortization_type__c';

export default class DmtOppProductDetailsSchedule extends LightningElement {

    isEditMode = false;

    @track fields = [...scheduleFields];

    _fieldsOriginal = [...scheduleFields];
    _data;
    _options = {};
    _snapshot = null;
    _readOnlySnapshot = null;
    _tenorsData = [];
    _recordId = null;
    _initialDate = null;
    _maturityDate = null;
    _currencyCode = '';
    _currentAmortizationType = '';

    @api get data() { return this._data; }
    set data(value) {
        this._data = value;
        this._recompute();
    }

    @api get fieldOptions() { return this._options; }
    set fieldOptions(value) {
        this._options = {
            g_currency_id__c: value?.catalogValues?.['C264'] || []
        };
        this._recompute();
    }

    @api get tenorsData() { return this._tenorsData; }
    set tenorsData(value) {
        this._tenorsData = Array.isArray(value) ? value : [];
    }

    @api get recordId() { return this._recordId; }
    set recordId(value) {
        this._recordId = value;
    }

    @api get initialDate() { return this._initialDate; }
    set initialDate(value) {
        this._initialDate = value || null;
    }

    @api get maturityDate() { return this._maturityDate; }
    set maturityDate(value) {
        this._maturityDate = value || null;
    }

    @api get currencyCode() { return this._currencyCode; }
    set currencyCode(value) {
        this._currencyCode = value || '';
    }

    @api get currentAmortizationType() { return this._currentAmortizationType; }
    set currentAmortizationType(value) {
        this._currentAmortizationType = value || '';
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
        this.isEditMode = false;
        this._snapshot = null;
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

        const tenorsBps = this.refs?.tableTenors?.collectBpsFieldsValidation?.();
        if (tenorsBps?.invalidFields?.length > 0) invalidFields.push(...tenorsBps.invalidFields);

        const tenorsNeg = this.refs?.tableTenors?.collectNegativeFieldsValidation?.();
        if (tenorsNeg?.invalidFields?.length > 0) invalidFields.push(...tenorsNeg.invalidFields);

        return { isValid: invalidFields.length === 0, invalidFields };
    }

    @api collectTenorsChanges() {
        const tableRef = this.refs?.tableTenors;
        if (!tableRef) return { upserts: [], deletes: [] };
        const changes = tableRef.collectChanges?.() || { tenorData: [], deletedIds: [] };
        return {
            upserts: changes.tenorData || [],
            deletes: changes.deletedIds || []
        };
    }

    @api collectTenorsBpsValidation() {
        const tableRef = this.refs?.tableTenors;
        if (!tableRef) return { isValid: true, invalidFields: [] };
        return tableRef.collectBpsFieldsValidation?.() || { isValid: true, invalidFields: [] };
    }

    @api collectTenorsNegativeValidation() {
        const tableRef = this.refs?.tableTenors;
        if (!tableRef) return { isValid: true, invalidFields: [] };
        return tableRef.collectNegativeFieldsValidation?.() || { isValid: true, invalidFields: [] };
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

    handleEditModeChange(event) {
        this.dispatchEvent(new CustomEvent('editmodechange', { detail: event.detail }));
    }

    handleFieldChange(event) {
        const { fieldId, value, isFieldValid } = event.detail;
        const idx = this.fields.findIndex(f => f.id === fieldId);
        if (idx === -1) return;

        const field = this.fields[idx];
        const apiName = field.apiName;
        const newArr = this.fields.slice();
        newArr[idx] = { ...field, value, isFieldValid };
        this.fields = newArr;

        if (apiName === F_CURRENCY) {
            this._currencyCode = value || '';
        } else if (apiName === F_AMORT_TYPE) {
            this._currentAmortizationType = value || '';
        }

        console.log('**** handlefield '+ JSON.stringify(event.detail));
        this.dispatchEvent(new CustomEvent('sectionchange', { detail: { apiName, value,isFieldValid } }));
    }

    handleTenorsChange() {
        // Parent pulls tenor changes on save via collectTenorsChanges.
    }

    handleTenorsValidation() {
        // Parent pulls tenor validation on save via collectTenorsBpsValidation.
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
            this._currencyCode = this._data[F_CURRENCY] || this._currencyCode;
            this._currentAmortizationType = this._data[F_AMORT_TYPE] || this._currentAmortizationType;
        }

        this.fields = next;

        if (this._readOnlySnapshot) {
            this.fields = this.fields.map(f => ({ ...f, isReadOnly: true }));
        }
    }

    _isOriginallyReadOnly(apiName) {
        return this._fieldsOriginal.find(o => o.apiName === apiName)?.isReadOnly === true;
    }

    _isBpsLabel(label) {
        return typeof label === 'string' && label.toLowerCase().includes('bps');
    }

    _hasMoreThanTwoDecimals(value) {
        const stringValue = String(value);
        const decimalPart = stringValue.split('.')[1];
        return !!decimalPart && decimalPart.length > 2;
    }
}