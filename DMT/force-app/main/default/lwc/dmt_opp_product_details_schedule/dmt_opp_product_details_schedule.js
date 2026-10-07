import { LightningElement, api, track } from 'lwc';
import { scheduleFields } from './dmt_opp_product_details_schedule_fields';

const F_CURRENCY = 'g_currency_id__c';
const F_AMORT_TYPE = 'gf_amortization_type__c';
const F_PAYMENT_FREQ = 'gf_payment_frequency__c';

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
            if (!this._readOnlySnapshot) {
                this.refs?.tableTenors?.setReadOnlyMode?.(readOnly);
                return;
            }
            const roMap = new Map(this._readOnlySnapshot.map(f => [f.id, f.isReadOnly]));
            this.fields = this.fields.map(f => ({
                ...f,
                isReadOnly: roMap.has(f.id) ? roMap.get(f.id) : f.isReadOnly
            }));
            this._readOnlySnapshot = null;
        }
        this.refs?.tableTenors?.setReadOnlyMode?.(readOnly);
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

    @api collectTenorsChanges() {
        const tableRef = this.refs?.tableTenors;
        if (!tableRef) return { upserts: [], deletes: [] };
        const changes = tableRef.collectChanges?.() || { tenorData: [], deletedIds: [] };
        return {
            upserts: changes.tenorData || [],
            deletes: changes.deletedIds || []
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
            this.fields = this.fields.map(f =>
                f.apiName === F_PAYMENT_FREQ ? { ...f, isHidden: value === 'Bullet' } : f
            );
        }

        console.log('**** handlefield '+ JSON.stringify(event.detail));
        this.dispatchEvent(new CustomEvent('sectionchange', { detail: { apiName, value } }));
    }

    handleTenorsChange() {
        // Get current edited tenors from the table component
        const tableRef = this.refs?.tableTenors;
        if (tableRef) {
            const currentTenors = tableRef.getCurrentRows?.();
            if (Array.isArray(currentTenors)) {
                this._tenorsData = currentTenors;
            }
        }
        
        // Emit updated tenors to parent so dealDescription can recalculate BBVA Commitment in real-time
        this.dispatchEvent(new CustomEvent('sectionchange', {
            detail: {
                updatedTenors: this._tenorsData
            },
            bubbles: true,
            composed: true
        }));
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

        const amortType = next.find(f => f.apiName === F_AMORT_TYPE)?.value;
        next = next.map(f =>
            f.apiName === F_PAYMENT_FREQ ? { ...f, isHidden: amortType === 'Bullet' } : f
        );

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

}