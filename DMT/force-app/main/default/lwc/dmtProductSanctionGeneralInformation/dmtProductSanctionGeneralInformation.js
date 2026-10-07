import { LightningElement, api, track } from 'lwc';

export default class DmtProductSanctionGeneralInformation extends LightningElement {

    @track fields = [];

    _fieldsOriginal = [];
    _data = {};
    _currencyCode = '';
    _snapshot = null;
    _readOnlySnapshot = null;
    _isEditMode = false;

    @api
    get data() {
        return this._data;
    }
    set data(value) {
        this._data = value || {};
        if (this._data.CurrencyIsoCode && !this._currencyCode) {
            this._currencyCode = this._data.CurrencyIsoCode;
        }
        this._recompute();
    }

    @api
    get sectionFields() {
        return this._fieldsOriginal;
    }
    set sectionFields(value) {
        this._fieldsOriginal = Array.isArray(value) ? value.map(f => ({ ...f })) : [];
        this._recompute();
    }

    @api
    get currencyCode() {
        return this._currencyCode;
    }
    set currencyCode(value) {
        this._currencyCode = value || '';
        this.fields = this._applyCurrency(this.fields);
    }

    @api
    get editState() {
        return this._isEditMode;
    }
    set editState(value) {
        const next = !!value;
        if (next === this._isEditMode) {
            return;
        }
        if (next) {
            this.enterEditMode();
        } else {
            this.commitEdit();
        }
    }

    get isEditMode() {
        return this._isEditMode;
    }

    @api
    enterEditMode() {
        this._isEditMode = true;
        this._snapshot = this.fields.map(f => ({ ...f }));
    }

    @api
    restoreSnapshot() {
        if (this._snapshot) {
            this.fields = this._snapshot.map(f => ({ ...f }));
        }
        this._snapshot = null;
    }

    @api
    commitEdit() {
        this._isEditMode = false;
        this._snapshot = null;
    }

    @api
    setReadOnlyMode(readOnly) {
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

    @api
    collectChanges() {
        if (!this._snapshot) return {};
        const changes = {};
        const snapMap = new Map(this._snapshot.map(f => [f.id, f]));
        for (const f of this.fields) {
            if (f.isReadOnly || f.isHidden) continue;
            const original = snapMap.get(f.id);
            const hasChanged = String(f.value ?? '') !== String(original?.value ?? '');
            if (!hasChanged) continue;
            changes[f.apiName] = (f.value === '' || f.value === undefined) ? null : f.value;
        }
        return changes;
    }

    @api
    getFieldLabel(apiName) {
        const f = this.fields.find(x => x.apiName === apiName);
        return f ? f.label : null;
    }

    @api
    collectInvalidFields() {
        const invalidFields = this.fields
            .filter(f => f.isFieldValid === false)
            .map(f => f.apiName);
        return { isValid: invalidFields.length === 0, invalidFields };
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
        const next = this.fields.slice();
        next[idx] = { ...field, value, isFieldValid };
        this.fields = next;

        if (apiName === 'CurrencyIsoCode') {
            this._currencyCode = value || '';
            this.fields = this._applyCurrency(this.fields);
        }

        this.dispatchEvent(new CustomEvent('sectionchange', {
            detail: { apiName, value }
        }));
    }

    _recompute() {
        let next = this._fieldsOriginal.map(f => ({ ...f }));
        if (this._data) {
            next = next.map(f => ({ ...f, value: this._data[f.apiName] }));
        }
        next = this._applyCurrency(next);
        this.fields = next;

        if (this._readOnlySnapshot) {
            this.fields = this.fields.map(f => ({ ...f, isReadOnly: true }));
        }
    }

    _applyCurrency(fieldsArray) {
        if (!this._currencyCode) return fieldsArray;
        return fieldsArray.map(f =>
            f.type === 'numberWithCurrency' ? { ...f, currencyCode: this._currencyCode } : f
        );
    }
}