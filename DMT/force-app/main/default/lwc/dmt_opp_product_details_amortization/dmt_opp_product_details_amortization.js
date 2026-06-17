import { LightningElement, api, track } from 'lwc';
import { amortizationsFields, extrafieldsAmortizations } from './dmt_opp_product_details_amortization_fields';
import LightningConfirm from 'lightning/confirm';

const AMORT_TYPE_USER_DEFINED = 'User-Defined';
const F_AMORT_TYPE  = 'gf_amortization_type__c';
const F_CURRENCY    = 'g_currency_id__c';
const F_BULLET      = 'DMT_bullet_amortization_indicator__c';
const F_BALLOON     = 'DMT_balloon_amortization_indicator__c';
const BULLET_BALLOON_SET = new Set([F_BULLET, F_BALLOON]);

export default class DmtOppProductDetailsAmortization extends LightningElement {

    isEditMode = false;

    @api recordId;
    @api initialDate;
    @api maturityDate;

    canEdit;

    _tenorsData = [];
    @api get tenorsData() { return this._tenorsData; }
    set tenorsData(value) {
        this._tenorsData = Array.isArray(value) ? value : [];
    }

    @track fields      = [...amortizationsFields];
    @track extraFields = [...extrafieldsAmortizations];
    @track currentAmortizationType = '';

    _fieldsOriginal     = [...amortizationsFields];
    _extraOriginal      = [...extrafieldsAmortizations];
    _data;
    _options            = {};
    _currencyCode       = '';
    _snapshot           = null;
    _extraSnapshot      = null;
    _readOnlySnapshot   = null;
    _extraReadOnlySnapshot = null;

    // ─── Public API ───────────────────────────────────────────────────────────

    @api get data() { return this._data; }
    set data(value) {
        this._data = value;
        if (value) {
            // Only update amortization type when not editing to avoid overwriting in-progress changes
            if (!this._snapshot) {
                this.currentAmortizationType = value[F_AMORT_TYPE] || '';
            }
            if (value[F_CURRENCY] && !this._currencyCode) {
                this._currencyCode = value[F_CURRENCY];
            }
        }
        if (!this._snapshot) {
            this._recompute();
        }
    }

    @api get fieldOptions() { return this._options; }
    set fieldOptions(value) {
        this._options = {
            g_currency_id__c   : value.catalogValues['C264'] || [],
            gf_country_risk__c : value.catalogValues['C245'] || [],
            gf_country_rating__c: value.catalogValues['C204'] || []
        };
        if (!this._snapshot) {
            this._recompute();
        }
    }

    @api get currencyCode() { return this._currencyCode; }
    set currencyCode(value) {
        this._currencyCode = value || '';
        this.fields = this._applyCurrency(this.fields);
    }

    @api enterEditMode() {
        this._snapshot      = this.fields.map(f => ({ ...f }));
        this._extraSnapshot = this.extraFields.map(f => ({ ...f }));
        this.isEditMode     = true;
    }

    @api restoreSnapshot() {
        if (this._snapshot)      this.fields      = this._snapshot;
        if (this._extraSnapshot) this.extraFields  = this._extraSnapshot;
        this._snapshot      = null;
        this._extraSnapshot = null;
        if (this._data) {
            this.currentAmortizationType = this._data[F_AMORT_TYPE] || '';
        }
        this.refs?.tableTenors?.restoreSnapshot?.();
    }

    @api commitEdit() {
        this._snapshot      = null;
        this._extraSnapshot = null;
        this.isEditMode     = false;
        this.refs?.tableTenors?.commitEdit?.();
    }

    @api setReadOnlyMode(readOnly) {
        this.canEdit = !readOnly;
        if (readOnly) {
            // Snapshot original isReadOnly values before forcing everything to true,
            // so they can be correctly restored when read-only mode is lifted
            if (!this._readOnlySnapshot) {
                this._readOnlySnapshot      = this.fields.map(f => ({ id: f.id, isReadOnly: f.isReadOnly }));
                this._extraReadOnlySnapshot = this.extraFields.map(f => ({ id: f.id, isReadOnly: f.isReadOnly }));
            }
            this.fields      = this.fields.map(f => ({ ...f, isReadOnly: true }));
            this.extraFields = this.extraFields.map(f => ({ ...f, isReadOnly: true }));
        } else {
            if (!this._readOnlySnapshot) {
                this.refs?.tableTenors?.setReadOnlyMode?.(readOnly);
                return;
            }
            // Restore each field's original isReadOnly value from the snapshot
            const roMap      = new Map(this._readOnlySnapshot.map(f => [f.id, f.isReadOnly]));
            const roExtraMap = new Map(this._extraReadOnlySnapshot.map(f => [f.id, f.isReadOnly]));
            this.fields      = this.fields.map(f => ({ ...f, isReadOnly: roMap.has(f.id) ? roMap.get(f.id) : f.isReadOnly }));
            this.extraFields = this.extraFields.map(f => ({ ...f, isReadOnly: roExtraMap.has(f.id) ? roExtraMap.get(f.id) : f.isReadOnly }));
            this._readOnlySnapshot      = null;
            this._extraReadOnlySnapshot = null;
        }
        this.refs?.tableTenors?.setReadOnlyMode?.(readOnly);
    }

    @api collectChanges() {
        const result = {};
        this._collectFromArray(result, this.fields, this._snapshot);
        this._collectFromArray(result, this.extraFields, this._extraSnapshot);
        return result;
    }

    @api getFieldLabel(apiName) {
        const f = this.fields.find(x => x.apiName === apiName) ||
                  this.extraFields.find(x => x.apiName === apiName);
        return f ? f.label : null;
    }

    @api collectTenorsChanges() {
        const tableTenorsRef = this.refs?.tableTenors;
        if (!tableTenorsRef) return { upserts: [], deletes: [] };
        return tableTenorsRef.collectChanges?.() || { upserts: [], deletes: [] };
    }

    @api collectBpsFieldsValidation() {
        const invalidFields = [];
        
        const renderers = this.template.querySelectorAll('c-dmt_form_renderer');
        for (const renderer of renderers) {
            const fields = renderer.getChanges?.() || [];
            for (const field of fields) {
                if (field.type === 'number' && field.step === 0.01 && field.value !== null && field.value !== undefined && field.value !== '') {
                    const decimalPart = field.value.toString().split('.')[1];
                    if (decimalPart && decimalPart.length > 2) {
                        invalidFields.push(field.label);
                    }
                }
            }
        }
        
        return {
            isValid: invalidFields.length === 0,
            invalidFields
        };
    }

    @api collectTenorsBpsValidation() {
        const tableTenorsRef = this.refs?.tableTenors;
        if (!tableTenorsRef) return { isValid: true, invalidFields: [] };
        return tableTenorsRef.collectBpsFieldsValidation?.() || { isValid: true, invalidFields: [] };
    }


    // ─── Event handlers ───────────────────────────────────────────────────────

    handleEditModeChange(event) {
        this.dispatchEvent(new CustomEvent('editmodechange', { detail: event.detail }));
    }

    handleFieldChange(event) {
        const { fieldId, value } = event.detail;
        const idx   = this.fields.findIndex(f => f.id === fieldId);
        if (idx === -1) return;
        const field   = this.fields[idx];
        const apiName = field.apiName;

        // Changing amortization type away from User-Defined destroys the tenor schedule;
        // confirm with the user before proceeding if any tenors are configured
        if (
            apiName === F_AMORT_TYPE &&
            this.currentAmortizationType === AMORT_TYPE_USER_DEFINED &&
            value !== AMORT_TYPE_USER_DEFINED &&
            this._hasConfiguredTenors()
        ) {
            this._confirmAmortizationTypeChange(fieldId, idx, field, value);
            return;
        }
        this._applyFieldChange(fieldId, idx, field, value);
    }

    handleExtraFieldChange(event) {
        const { fieldId, value } = event.detail;
        const idx = this.extraFields.findIndex(f => f.id === fieldId);
        if (idx === -1) return;
        const newArr  = this.extraFields.slice();
        newArr[idx]   = { ...this.extraFields[idx], value };
        this.extraFields = newArr;
        this.dispatchEvent(new CustomEvent('sectionchange', {
            detail: { apiName: newArr[idx].apiName, value }
        }));
    }

    // ─── Field change logic ───────────────────────────────────────────────────

    async _confirmAmortizationTypeChange(fieldId, idx, field, value) {
        const result = await LightningConfirm.open({
            message: 'Are you sure you want to change the Amortization Type? The current Repayment Schedule configuration will be lost.',
            variant: 'header',
            label  : 'Confirm Amortization Type change',
            theme  : 'warning'
        });
        if (result) {
            this._applyFieldChange(fieldId, idx, field, value);
        } else {
            // Revert the field visually to the previous amortization type
            const newArr  = this.fields.slice();
            newArr[idx]   = { ...field, value: this.currentAmortizationType };
            this.fields   = newArr;
        }
    }

    _applyFieldChange(fieldId, idx, field, value) {
        const apiName         = field.apiName;
        const normalizedValue = BULLET_BALLOON_SET.has(apiName) ? this._normalizeToBoolean(value) : value;

        let newArr  = this.fields.slice();
        newArr[idx] = { ...field, value: normalizedValue };

        // Bullet and balloon are mutually exclusive — enabling one disables the other
        if (BULLET_BALLOON_SET.has(apiName) && normalizedValue === true) {
            const otherFieldName = apiName === F_BULLET ? F_BALLOON : F_BULLET;
            const otherIdx       = newArr.findIndex(f => f.apiName === otherFieldName);
            if (otherIdx !== -1) {
                newArr[otherIdx] = { ...newArr[otherIdx], value: false };
            }
        }

        if (apiName === F_AMORT_TYPE) {
            this.currentAmortizationType = normalizedValue || '';
            newArr = this._applyAmortizationTypeRules(newArr, this.currentAmortizationType);
        } else if (apiName === F_CURRENCY) {
            this._currencyCode = normalizedValue || '';
            newArr = this._applyCurrency(newArr);
        }

        this.fields = newArr;
        this.dispatchEvent(new CustomEvent('sectionchange', {
            detail: { apiName, value: normalizedValue }
        }));
    }

    _hasConfiguredTenors() {
        const childCount = this.refs?.tableTenors?.totalRowsCount;
        if (typeof childCount === 'number') return childCount > 2;
        return Array.isArray(this._tenorsData) && this._tenorsData.length > 2;
    }

    // ─── Recompute / options / rules ──────────────────────────────────────────

    _recompute() {
        let next = this._applyOptions(this._fieldsOriginal, this._fieldsOriginal);
        if (this._data) {
            next = next.map(f => {
                let value = this._data[f.apiName];
                if (BULLET_BALLOON_SET.has(f.apiName)) {
                    value = this._normalizeToBoolean(value);
                }
                return { ...f, value };
            });
        }
        next        = this._applyAmortizationTypeRules(next, this.currentAmortizationType);
        next        = this._applyCurrency(next);
        this.fields = next;

        let nextExtra = this._applyOptions(this._extraOriginal, this._extraOriginal);
        if (this._data) {
            nextExtra = nextExtra.map(f => ({ ...f, value: this._data[f.apiName] }));
        }
        this.extraFields = nextExtra;

        // Re-apply forced read-only if the mode was active before recompute
        if (this._readOnlySnapshot) {
            this.fields      = this.fields.map(f => ({ ...f, isReadOnly: true }));
            this.extraFields = this.extraFields.map(f => ({ ...f, isReadOnly: true }));
        }
    }

    _applyOptions(originalArray, sourceForRO) {
        const baseArr = originalArray.map(f => ({ ...f }));
        if (!this._options) return baseArr;
        return baseArr.map(f => {
            const options = this._options[f.apiName];
            if (!options) return f;
            const merged      = { ...f, options };
            const originalRO  = sourceForRO.find(o => o.apiName === f.apiName)?.isReadOnly;
            // Disable picklist fields when no options are available
            if (f.type === 'picklist' && !originalRO) {
                merged.isReadOnly = options.length === 0;
            }
            return merged;
        });
    }

    _applyAmortizationTypeRules(fieldsArray, amortType) {
        const isUserDefined = amortType === AMORT_TYPE_USER_DEFINED;
        return fieldsArray.map(f => {
            if (!BULLET_BALLOON_SET.has(f.apiName)) return f;
            // Bullet and balloon only apply to User-Defined amortization
            return { ...f, isHidden: !isUserDefined, value: isUserDefined ? f.value : false };
        });
    }

    _applyCurrency(fieldsArray) {
        return fieldsArray.map(f =>
            f.type === 'numberWithCurrency' ? { ...f, currencyCode: this._currencyCode } : f
        );
    }

    // ─── Change collection ────────────────────────────────────────────────────

    _collectFromArray(result, currentArr, snapshotArr) {
        const isExtra = currentArr === this.extraFields;
        if (!snapshotArr) return;

        const snapMap = new Map(snapshotArr.map(f => [f.id, f]));
        for (const f of currentArr) {
            if (this._isOriginallyReadOnly(f.apiName, isExtra)) continue;
            // Hidden non-checkbox fields are excluded from the diff
            if (f.isHidden && !BULLET_BALLOON_SET.has(f.apiName)) continue;

            const original = snapMap.get(f.id);
            let hasChanged;
            if (BULLET_BALLOON_SET.has(f.apiName)) {
                hasChanged = this._normalizeToBoolean(f.value) !== this._normalizeToBoolean(original?.value);
            } else {
                hasChanged = String(f.value ?? '') !== String(original?.value ?? '');
            }
            if (!hasChanged) continue;

            result[f.apiName] = BULLET_BALLOON_SET.has(f.apiName)
                ? this._normalizeToBoolean(f.value)
                : (f.value === '' || f.value === undefined ? null : f.value);
        }
    }

    _isOriginallyReadOnly(apiName, isExtra = false) {
        const source   = isExtra ? this._extraOriginal : this._fieldsOriginal;
        const original = source.find(o => o.apiName === apiName);
        return original?.isReadOnly === true;
    }

    _normalizeToBoolean(value) {
        return value === true || value === 'true' || value === 'Yes';
    }
}