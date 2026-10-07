import { LightningElement, api, track } from 'lwc';
import { generalInfoFields } from './dmt_opp_product_details_general_information_fields';

// Emits 'sectionchange' on every field change so the parent can propagate
// cross-section dependencies (currency, dates) to sibling components

const F_CURRENCY     = 'g_currency_id__c';
const F_INITIAL_DATE = 'gf_initial_date__c';
const F_MATURITY_DATE= 'gf_maturity_date__c';

export default class DmtOppProductDetailsGeneralInformation extends LightningElement {

    isEditMode = false;

    @track fields = [...generalInfoFields];

    _fieldsOriginal   = [...generalInfoFields];
    _data;
    _options          = {};
    _currencyCode     = '';
    _snapshot         = null;
    _readOnlySnapshot = null;

    // ─── Public API ───────────────────────────────────────────────────────────

    @api get data() { return this._data; }
    set data(value) {
        this._data = value;
        if (value && value[F_CURRENCY] && !this._currencyCode) {
            this._currencyCode = value[F_CURRENCY];
        }
        this._recompute();
    }

    @api get fieldOptions() { return this._options; }
    set fieldOptions(value) {
        this._options = {
            DMT_Risk_Type__c               : value.riskTypeOptions        || [],
            DMT_Line_Oneoffdeal__c         : value.oneoffDealOptions      || []
        };
        this._recompute();
    }

    @api get currencyCode() { return this._currencyCode; }
    set currencyCode(value) {
        this._currencyCode = value || '';
        this.fields = this._applyCurrency(this.fields);
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
        this.isEditMode = false;
        this._snapshot  = null;
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
/* 
    @api collectInvalidFields() {
        const invalidFields = this.fields
            .filter(f => f.isFieldValid === false)
            .map(f => f.label || f.apiName);
        return { isValid: invalidFields.length === 0, invalidFields };
    } */

    // ─── Event handlers ───────────────────────────────────────────────────────

    handleEditModeChange(event) {
        this.dispatchEvent(new CustomEvent('editmodechange', { detail: event.detail }));
    }

    handleFieldChange(event) {
        const { fieldId, value, isFieldValid } = event.detail;
        const idx = this.fields.findIndex(f => f.id === fieldId);
        if (idx === -1) return;
        const field   = this.fields[idx];
        const apiName = field.apiName;
        const newArr  = this.fields.slice();
        newArr[idx]   = { ...field, value, isFieldValid };
        this.fields   = newArr;
        if (apiName === F_CURRENCY) {
            this._currencyCode = value || '';
            this.fields = this._applyCurrency(this.fields);
        }
        this.dispatchEvent(new CustomEvent('sectionchange', { detail: { apiName, value } }));
    }

    // ─── Recompute ────────────────────────────────────────────────────────────

    _recompute() {
        let next = this._fieldsOriginal.map(f => ({ ...f }));
        if (this._data) {
            next = next.map(f => ({ ...f, value: this._data[f.apiName] }));
        }
        next        = this._applyOptions(next);
        next        = this._applyCurrency(next);
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
            let mergedOptions = options;
            if (f.type === 'picklist' && f.value !== null && f.value !== undefined && f.value !== '') {
                const valueAsString = String(f.value);
                const hasCurrentValue = options.some(opt => String(opt.value) === valueAsString);
                if (!hasCurrentValue) {
                    // Keep showing persisted value even if it is not present in active picklist options.
                    mergedOptions = [{ label: valueAsString, value: valueAsString }, ...options];
                }
            }
            const merged     = { ...f, options: mergedOptions };
            const originalRO = this._isOriginallyReadOnly(f.apiName);
            if (f.type === 'picklist' && !originalRO) merged.isReadOnly = mergedOptions.length === 0;
            return merged;
        });
    }

    _applyCurrency(fieldsArray) {
        if (!this._currencyCode) return fieldsArray;
        return fieldsArray.map(f =>
            f.type === 'numberWithCurrency' ? { ...f, currencyCode: this._currencyCode } : f
        );
    }

    _isOriginallyReadOnly(apiName) {
        return this._fieldsOriginal.find(o => o.apiName === apiName)?.isReadOnly === true;
    }
}