import { LightningElement, api, track } from 'lwc';
import { dealDescriptionFields } from './dmt_opp_product_details_deal_description_fields';
import getCurrencyLabel from '@salesforce/apex/DMT_Currency_Conversion_Utils.getCurrencyLabel';

export default class DmtOppProductDetailsDealDescription extends LightningElement {

    isEditMode = false;

    @track fields = [...dealDescriptionFields];

    _fieldsOriginal = [...dealDescriptionFields];
    _data;
    _tenorsData = [];
    _options = {};
    _snapshot = null;
    _readOnlySnapshot = null;
    _currencyExtraText = '';

    @api get data() { return this._data; }
    set data(value) {
        const dataChanged = JSON.stringify(this._data) !== JSON.stringify(value);
        this._data = value;
        if (dataChanged) {
            this._recompute();
            this._loadCurrencyLabel(value?.g_currency_id__c);
        }
    }

    @api get tenorsData() { return this._tenorsData; }
    set tenorsData(value) {
        this._tenorsData = value || [];
        this._recompute();
    }

    @api get fieldOptions() { return this._options; }
    set fieldOptions(value) {
        this._options = value || {};
        this._recompute();
        this._applyVisibilityRules(this.fields);
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

    @api validate() {
        const renderer = this.template.querySelector('c-dmt_form_renderer');
        const rendererResult = renderer?.validate?.() ?? { isValid: true, invalidFields: [] };
        const rendererIsValid = typeof rendererResult === 'object' ? rendererResult.isValid : !!rendererResult;
        const rendererInvalidFields = (typeof rendererResult === 'object' && Array.isArray(rendererResult.invalidFields))
            ? rendererResult.invalidFields : [];

        const invalidFieldSet = new Set(rendererInvalidFields);
        const derivedFieldLabels = new Set(
            this._fieldsOriginal
                .filter(field => this._isOriginallyReadOnly(field.apiName))
                .flatMap(field => [field.label, field.apiName].filter(Boolean))
        );
        for (const invalidField of [...invalidFieldSet]) {
            if (derivedFieldLabels.has(invalidField)) {
                invalidFieldSet.delete(invalidField);
            }
        }

        for (const field of this.fields) {
            if (!field.isRequired || field.isHidden || this._isOriginallyReadOnly(field.apiName)) continue;
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
            if (this._isOriginallyReadOnly(f.apiName)) continue;
            if (f.isHidden) continue;

            const original = snapMap.get(f.id);
            const hasChanged = String(f.value ?? '') !== String(original?.value ?? '');
            if (!hasChanged) continue;

            let finalValue = f.value;
            if (Array.isArray(finalValue)) {
                finalValue = finalValue.join(';');
            }
            changes[f.apiName] = (finalValue === '' || finalValue === undefined) ? null : finalValue;
        }

        const inferredTargets = ['DMT_NewMoney_BBVA__c', 'syndicated_loan_drawn_amount__c', 'DMT_OldMoney_BBVA__c', 'bbva_prtcp_tranche_amount__c'];
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


    handleEditModeChange(event) {
        this.dispatchEvent(new CustomEvent('editmodechange', { detail: event.detail }));
    }

    handleFieldChange(event) {
        const { fieldId, value, isFieldValid } = event.detail;
        const idx = this.fields.findIndex(f => f.id === fieldId);
        if (idx === -1) return;

        const field = this.fields[idx];
        const newArr = this.fields.slice();
        newArr[idx] = { ...field, value, isFieldValid };
        
        // Critical: Ensure BBVA commitment has a real value BEFORE calculating oldMoney
        const bbvaIdx = newArr.findIndex(f => f.apiName === 'bbva_prtcp_tranche_amount__c');
        if (bbvaIdx !== -1) {
            const bbvaField = newArr[bbvaIdx];
            const currentBbvaValue = this._toNumber(bbvaField.value);
            
            // Only try to fetch from data if BBVA is 0 or empty
            if (currentBbvaValue === 0 && this._data) {
                // Try multiple sources in order of preference
                let bbvaFromData = null;
                if (this._data.bbva_prtcp_tranche_amount__c) {
                    bbvaFromData = this._toNumber(this._data.bbva_prtcp_tranche_amount__c);
                } else if (this._data.DMT_Commitment_Line_Amount__c) {
                    bbvaFromData = this._toNumber(this._data.DMT_Commitment_Line_Amount__c);
                }
                
                if (bbvaFromData && bbvaFromData > 0) {
                    newArr[bbvaIdx] = { ...bbvaField, value: bbvaFromData };
                }
            }
        }
        
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
            next = next.map(f => ({ ...f, value: this._normalizeFieldValue(f, this._data[f.apiName]) }));
        }

        next = this._applyCalculatedFields(next);
        next = this._preserveInProgressValues(next);
        this.fields = this._applyCalculatedFields(next);
        
        if (this._readOnlySnapshot) {
            this.fields = this.fields.map(f => ({ ...f, isReadOnly: true }));
        }
        this._applyVisibilityRules(this.fields);
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
        // Get BBVA commitment from multiple sources - prioritize tenors calculation
        let bbvaRaw = this._getFieldValue(fields, 'bbva_prtcp_tranche_amount__c');
        let bbvaSource = 'field';
        
        // First, try to calculate from tenors if available
        //if ((this._isEmpty(bbvaRaw) || this._toNumber(bbvaRaw) === 0)) {
            const bbvaFromTenors = this._calculateBbvaCommitmentFromTenors();
            if (bbvaFromTenors !== null) {
                bbvaRaw = bbvaFromTenors;
                bbvaSource = 'tenors_calculation';
            }
        //}
        
        // If no tenors, try to get from data
        if ((this._isEmpty(bbvaRaw) || this._toNumber(bbvaRaw) === 0)) {
            if (this._data?.bbva_prtcp_tranche_amount__c && this._toNumber(this._data.bbva_prtcp_tranche_amount__c) > 0) {
                bbvaRaw = this._data.bbva_prtcp_tranche_amount__c;
                bbvaSource = 'data.bbva_prtcp_tranche_amount__c';
            } else if (this._data?.DMT_Commitment_Line_Amount__c && this._toNumber(this._data.DMT_Commitment_Line_Amount__c) > 0) {
                bbvaRaw = this._data.DMT_Commitment_Line_Amount__c;
                bbvaSource = 'data.DMT_Commitment_Line_Amount__c';
            }
        }
        
        const bbvaCommitment = this._toNumber(bbvaRaw);

        const newMoneyValue = this._inferFromBbvaIfEmpty(this._getFieldValue(fields, 'DMT_NewMoney_BBVA__c'), bbvaCommitment);
        const finalTake = this._inferFromBbvaIfEmpty(this._getFieldValue(fields, 'syndicated_loan_drawn_amount__c'), bbvaCommitment);
        const expectedDrawnValue = this._normalizeExpectedDrawnValue(this._getFieldValue(fields, 'DMT_Expected_Drawn__c'));

        const newMoney = this._isEmpty(newMoneyValue) ? 0 : this._toNumber(newMoneyValue);
        const oldMoney = bbvaCommitment - newMoney;  // Always calculate, even if values are 0
        const oldMoneyWarning = oldMoney < 0
            ? 'Old money for BBVA is negative. Please review BBVA commitment amount and New money for BBVA.'
            : '';
        const expectedDrawnWarning = expectedDrawnValue > 100
            ? 'Expected Drawn (%) cannot exceed 100. Please review the value.'
            : '';
       
        return fields.map(field => {
            if (field.apiName === 'bbva_prtcp_tranche_amount__c') {
                // Always show calculated or inferred BBVA commitment
                return { ...field, value: bbvaCommitment };
            }
            if (field.apiName === 'DMT_OldMoney_BBVA__c') {
                return { ...field, value: oldMoney, warningText: oldMoneyWarning };
            }
            if (field.apiName === 'DMT_NewMoney_BBVA__c') {
                return { ...field, value: newMoneyValue };
            }
            if (field.apiName === 'syndicated_loan_drawn_amount__c') {
                return { ...field, value: finalTake };
            }
            if (field.apiName === 'DMT_Expected_Drawn__c') {
                return {
                    ...field,
                    value: expectedDrawnValue,
                    warningText: expectedDrawnWarning
                };
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
        return this._isEmpty(value) ? bbvaCommitment : value;
    }

    _normalizeFieldValue(field, value) {
        // For BBVA commitment, try to get from multiple sources
        if (field?.apiName === 'bbva_prtcp_tranche_amount__c') {
            // First, use the passed value if it's valid
            if (!this._isEmpty(value) && this._toNumber(value) > 0) {
                return value;
            }
            
            // Then try data sources
            if (this._data) {
                // Try direct field
                if (this._data.bbva_prtcp_tranche_amount__c && this._toNumber(this._data.bbva_prtcp_tranche_amount__c) > 0) {
                    return this._data.bbva_prtcp_tranche_amount__c;
                }
                // Try template line amount
                if (this._data.DMT_Commitment_Line_Amount__c && this._toNumber(this._data.DMT_Commitment_Line_Amount__c) > 0) {
                    return this._data.DMT_Commitment_Line_Amount__c;
                }
                // Try opportunity commitment
                if (this._data.Amount && this._toNumber(this._data.Amount) > 0) {
                    return this._data.Amount;
                }
            }
            
            // Default to 0 - field is not required so this is OK
            return 0;
        }
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

    _isEmpty(value) {
        return value === null || value === undefined || value === '';
    }

    _isBpsLabel(label) {
        return typeof label === 'string' && label.toLowerCase().includes('bps');
    }


    _isOriginallyReadOnly(apiName) {
        // Exceptions: calculated fields that should persist
        if (apiName === 'DMT_OldMoney_BBVA__c') return false;
        if (apiName === 'bbva_prtcp_tranche_amount__c') return false;
        
        return this._fieldsOriginal.find(o => o.apiName === apiName)?.isReadOnly === true;
    }
    _loadCurrencyLabel(currencyIsoCode) {
        if (!currencyIsoCode) return;
        getCurrencyLabel({ currencyIsoCode })
            .then(result => {
                this._currencyExtraText = result || currencyIsoCode;
                this._applyVisibilityRules(this.fields);
            })
            .catch(() => {
                this._currencyExtraText = currencyIsoCode;
                this._applyVisibilityRules(this.fields);
            });
    }

    _applyVisibilityRules(fields) {
        const extraText = this._currencyExtraText;
        this.fields = fields.map(field => {
            if (field.id === 'DMT_Deal_amount__c' || field.id === 'bbva_prtcp_tranche_amount__c'  || field.id === 'DMT_NewMoney_BBVA__c'  || field.id === 'DMT_OldMoney_BBVA__c' || field.id === 'syndicated_loan_drawn_amount__c') {
                return field.extraText === extraText ? field : { ...field, extraText };
            }
            return field;
        });
    }

    _calculateBbvaCommitmentFromTenors() {
        if (!this._tenorsData || !Array.isArray(this._tenorsData) || this._tenorsData.length === 0) {
            return null;
        }

        // Sum all Drawn Amount (gj_nominal_amount_db__c) + Undrawn Amount (gf_nominal_amount_fb__c)
        let totalBbva = 0;
        this._tenorsData.forEach(tenor => {
            const drawnAmount = this._toNumber(tenor.gj_nominal_amount_db__c || 0);
            const undrawnAmount = this._toNumber(tenor.gf_nominal_amount_fb__c || 0);
            totalBbva += (drawnAmount + undrawnAmount);
        });

        return totalBbva > 0 ? totalBbva : null;
    }
    
}