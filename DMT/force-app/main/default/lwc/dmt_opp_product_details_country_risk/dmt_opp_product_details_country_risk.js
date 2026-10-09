import { LightningElement, api, track } from 'lwc';
import { countryRiskFields } from './dmt_opp_product_details_country_risk_fields';

const EMPTY_OPTION = { label: ' ', value: '' };

export default class DmtOppProductDetailsCountryRisk extends LightningElement {
    

    isEditMode = false;

    @track fields = [...countryRiskFields];

    _fieldsOriginal   = [...countryRiskFields];
    _data;
    _options          = {};
    _snapshot         = null;
    _readOnlySnapshot = null;
    

    // ─── Public API ───────────────────────────────────────────────────────────

    @api get data() { return this._data; }
    set data(value) {
        this._data = value;
        this._recompute();
    }

    @api get fieldOptions() { return this._options; }
        set fieldOptions(value) {
            const catalogValues = value?.catalogValues || {};

            this._options = {
                gf_country_risk__c  : this._addEmptyOption(catalogValues['C245'])
            };

            this._recompute();
        }

    @api enterEditMode() {
        this._snapshot  = this.fields.map(f => ({ ...f }));
        this.isEditMode = true;
    }

    @api restoreSnapshot() {
        if (this._snapshot) this.fields = this._snapshot;
        this._snapshot = null;
    }

    @api commitEdit() {
        this._snapshot  = null;
        this.isEditMode = false;
    }

    @api validate() {
        const renderer = this.template.querySelector('c-dmt_form_renderer');
        return renderer?.validate?.() ?? true;
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
            const original   = snapMap.get(f.id);
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

    // ─── Event handlers ───────────────────────────────────────────────────────

    handleEditModeChange(event) {
        this.dispatchEvent(new CustomEvent('editmodechange', { detail: event.detail }));
    }

    handleFieldChange(event) {
        const { fieldId, value, isFieldValid } = event.detail;
        const idx = this.fields.findIndex(f => f.id === fieldId);
        if (idx === -1) return;
        const field  = this.fields[idx];
        const newArr = this.fields.slice();
        newArr[idx]  = { ...field, value, isFieldValid };
        this.fields  = newArr;
        this.dispatchEvent(new CustomEvent('sectionchange', {
            detail: { apiName: field.apiName, value }
        }));
    }

    // ─── Recompute ────────────────────────────────────────────────────────────

    _recompute() {
        let next = this._applyOptions(this._fieldsOriginal);
        if (this._data) {
            next = next.map(f => ({ ...f, value: this._data[f.apiName] }));
        }
        this.fields = next;
        // Re-apply forced read-only if the mode was active before recompute
        if (this._readOnlySnapshot) {
            this.fields = this.fields.map(f => ({ ...f, isReadOnly: true }));
        }
    }

    // Picklist fields with no available options are marked read-only,
    // unless they were already read-only by original configuration
    _applyOptions(originalArray) {
        const baseArr = originalArray.map(f => ({ ...f }));
        if (!this._options) return baseArr;
        return baseArr.map(f => {
            const options = this._options[f.apiName];
            if (!options) return f;
            const merged     = { ...f, options };
            const originalRO = this._isOriginallyReadOnly(f.apiName);
            if (f.type === 'picklist' && !originalRO) merged.isReadOnly = options.length === 0;
            return merged;
        });
    }

    _addEmptyOption(options) {
        const safeOptions = Array.isArray(options) ? options : [];

        const alreadyHasEmpty = safeOptions.some(opt => opt?.value === '');

        if (alreadyHasEmpty) {
            return safeOptions;
        }

        return [EMPTY_OPTION, ...safeOptions];
    }

    _isOriginallyReadOnly(apiName) {
        return this._fieldsOriginal.find(o => o.apiName === apiName)?.isReadOnly === true;
    }
}