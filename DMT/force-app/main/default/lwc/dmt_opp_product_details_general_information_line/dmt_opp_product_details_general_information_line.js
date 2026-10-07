import { LightningElement, api, track } from 'lwc';
import { generalInfoFields, lineTenorValueLabelList } from './dmt_opp_product_details_general_information_line_fields';

const F_CURRENCY = 'g_currency_id__c';
const F_LINE_LC_LNC = 'DMT_Line_LC_LNC__c';
const F_LINE_ONEOFF_DEAL = 'DMT_Line_Oneoffdeal__c';
const F_LINE_COMMITMENT = 'g_line_commitment_level_type__c';
const F_LINE_TENOR = 'DMT_Line_Tenor__c';
const LINE_COMMITED = 'Committed';
const LINE_UNCOMMITED = 'Uncommitted';
const LINE_TENOR_ONE_YEAR = '366';

export default class DmtOppProductDetailsGeneralInformationLine extends LightningElement {

    isEditMode = false;

    @track fields = [...generalInfoFields];

    _fieldsOriginal = [...generalInfoFields];
    _data;
    _options = {};
    _currencyCode = '';
    _snapshot = null;
    _readOnlySnapshot = null;

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
            DMT_Risk_Type__c: value.riskTypeOptions || [],
            DMT_Line_Oneoffdeal__c: value.oneoffDealOptions || [],
            g_line_commitment_level_type__c: value.lineTypeOptions || []
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

    @api setReadOnlyMode(readOnly) {
        if (readOnly) {
            if (!this._readOnlySnapshot) {
                this._readOnlySnapshot = this.fields.map(f => ({ id: f.id, isReadOnly: f.isReadOnly }));
            }
            this.fields = this.fields.map(f => ({ ...f, isReadOnly: true }));
        } else {
            if (!this._readOnlySnapshot) return;
            const roMap = new Map(this._readOnlySnapshot.map(f => [f.id, f.isReadOnly]));
            let restored = this.fields.map(f => ({
                ...f,
                isReadOnly: roMap.has(f.id) ? roMap.get(f.id) : f.isReadOnly
            }));
            restored = this._applyLineCommitmentRule(restored);
            restored = this._applyLineTenorRule(restored);
            this.fields = restored;
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

        const forcedCommitmentValue = this._getForcedLineCommitmentValue();
        if (forcedCommitmentValue) {
            changes[F_LINE_COMMITMENT] = forcedCommitmentValue;
        }

        const commitmentValue = changes[F_LINE_COMMITMENT]
            ?? this.fields.find(f => f.apiName === F_LINE_COMMITMENT)?.value;
        if (commitmentValue === LINE_UNCOMMITED) {
            const tenorValue = this.fields.find(f => f.apiName === F_LINE_TENOR)?.value;
            // Persist current tenor in Uncommited lines; fallback to 1 year only if empty.
            changes[F_LINE_TENOR] = (tenorValue === '' || tenorValue === undefined || tenorValue === null)
                ? LINE_TENOR_ONE_YEAR
                : tenorValue;
        }

        return changes;
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
        const apiName = field.apiName;
        const newArr = this.fields.slice();
        newArr[idx] = { ...field, value, isFieldValid };
        this.fields = newArr;
        if (apiName === F_LINE_COMMITMENT) {
            this.fields = this._applyLineTenorRule(this.fields, false);
            const tenorField = this.fields.find(f => f.apiName === F_LINE_TENOR);
            this.dispatchEvent(new CustomEvent('sectionchange', {
                detail: { apiName: F_LINE_TENOR, value: tenorField?.value ?? '' }
            }));
        }
        if (apiName === F_CURRENCY) {
            this._currencyCode = value || '';
            this.fields = this._applyCurrency(this.fields);
        }
        this.dispatchEvent(new CustomEvent('sectionchange', { detail: { apiName, value } }));
    }

    _recompute() {
        let next = this._fieldsOriginal.map(f => ({ ...f }));
        if (this._data) {
            next = next.map(f => ({ ...f, value: this._data[f.apiName] }));
        }
        next = this._applyOptions(next);
        next = this._applyLineCommitmentRule(next);
        next = this._applyLineTenorRule(next, false);
        next = this._applyCurrency(next);
        this.fields = next;
        if (this._readOnlySnapshot) {
            this.fields = this.fields.map(f => ({ ...f, isReadOnly: true }));
        }
    }

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
                    mergedOptions = [{ label: valueAsString, value: valueAsString }, ...options];
                }
            }
            const merged = { ...f, options: mergedOptions };
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

    _applyLineCommitmentRule(fieldsArray) {
        const sourceValue = this._data?.[F_LINE_LC_LNC] || this._data?.[F_LINE_ONEOFF_DEAL] || '';
        const rawLineTypeValue = String(sourceValue).toUpperCase();
        const hasLC = /\bLC\b/.test(rawLineTypeValue);
        const hasLNC = /\bLNC\b/.test(rawLineTypeValue);

        return fieldsArray.map(f => {
            if (f.apiName !== F_LINE_COMMITMENT) return f;

            const currentOptions = Array.isArray(f.options) ? f.options : [];
            const commitedOption = currentOptions.find(opt => String(opt.value) === LINE_COMMITED)
                || { label: LINE_COMMITED, value: LINE_COMMITED };
            const uncommitedOption = currentOptions.find(opt => String(opt.value) === LINE_UNCOMMITED)
                || { label: LINE_UNCOMMITED, value: LINE_UNCOMMITED };

            if (hasLC && hasLNC) {
                return {
                    ...f,
                    options: [commitedOption, uncommitedOption],
                    isReadOnly: this._isOriginallyReadOnly(f.apiName)
                };
            }

            if (hasLC) {
                return {
                    ...f,
                    options: [commitedOption],
                    value: LINE_COMMITED,
                    isReadOnly: true
                };
            }

            if (hasLNC) {
                return {
                    ...f,
                    options: [uncommitedOption],
                    value: LINE_UNCOMMITED,
                    isReadOnly: true
                };
            }

            return f;
        });
    }

    _getForcedLineCommitmentValue() {
        const sourceValue = this._data?.[F_LINE_LC_LNC] || this._data?.[F_LINE_ONEOFF_DEAL] || '';
        const rawLineTypeValue = String(sourceValue).toUpperCase();
        const hasLC = /\bLC\b/.test(rawLineTypeValue);
        const hasLNC = /\bLNC\b/.test(rawLineTypeValue);

        if (hasLC && !hasLNC) return LINE_COMMITED;
        if (hasLNC && !hasLC) return LINE_UNCOMMITED;
        return null;
    }

    _applyLineTenorRule(fieldsArray, forceDefaultForUncommited = false) {
        const commitmentValue = fieldsArray.find(f => f.apiName === F_LINE_COMMITMENT)?.value;
        return fieldsArray.map(f => {
            if (f.apiName !== F_LINE_TENOR) return f;
            let nextValue = f.value ?? '';
            const isEmpty = nextValue === '' || nextValue === null || nextValue === undefined;
            if (commitmentValue === LINE_UNCOMMITED && (forceDefaultForUncommited || isEmpty)) {
                nextValue = LINE_TENOR_ONE_YEAR;
            }
            return {
                ...f,
                options: lineTenorValueLabelList,
                value: nextValue
            };
        });
    }

    _isOriginallyReadOnly(apiName) {
        return this._fieldsOriginal.find(o => o.apiName === apiName)?.isReadOnly === true;
    }
}