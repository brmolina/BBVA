import { LightningElement, api, track } from 'lwc';
import { sustainabilityFields }        from './dmt_opp_product_details_sustainability_fields';
import getCatalogByAssessment          from '@salesforce/apex/DMT_SustainableDealController.getCatalogByAssessment';
import getCatalogBySubtype             from '@salesforce/apex/DMT_SustainableDealController.getCatalogBySubtype';
import getDependentPicklistValues      from '@salesforce/apex/DMT_SustainableDealController.getDependentPicklistValues';


const ASSESSMENT_NONE                  = '1';
const SUSTAINABLE_USE_OF_PROCEEDS      = '6';
const SUBCATEGORY_TRIGGER_VALUES       = ['5', '6', '7'];
const ASSESSMENT_DIRECT_CATALOG_VALUES = ['2', '3', '4', '5'];
const SSL_ONLY_VALUES                  = ['2', '3', '4'];
const BONUS_AUTO_TRUE_SUBTYPES         = ['Green', 'Social', 'Green and social'];
const TXT_GREEN                        = 'Green';
const ENABLE_GREEN_FILTER              = true;

const PH_DEFAULT               = 'Select an Option';
const PH_SUBTYPE_DISABLED      = 'Select an Assessment with subcategory';
const PH_GREEN_FILTER_DISABLED = 'Not available for the selected deal subcategory';
const PH_CATALOG_DISABLED      = 'Complete previous sustainability fields';

const F_ASSESSMENT   = 'DMT_sustainable_deal_assessment__c';
const F_SUBTYPE      = 'DMT_Sustainable_Deal_Subtype__c';
const F_GREEN_FILTER = 'DMT_Sustainability_deal_value_criteria__c';
const F_CATALOG      = 'DMT_sustainable_deal_value__c';
const F_BONUS        = 'DMT_Sustainability_bonus_eligible__c';

export default class DmtOppProductDetailsSustainability extends LightningElement {

    isEditMode = false;

    @track fields = [...sustainabilityFields];

    _fieldsOriginal   = [...sustainabilityFields];
    _data;
    _options          = {};
    _snapshot         = null;
    _readOnlySnapshot = null;

    selectedAssessment  = '';
    selectedSubtype     = '';
    selectedGreenFilter = '';

    // ─── Public API ───────────────────────────────────────────────────────────

    @api get data() { return this._data; }
    set data(value) {
        this._data = value;
        this._recompute();
    }

    @api get fieldOptions() { return this._options; }
    set fieldOptions(value) {
        this._options = {
            DMT_sustainable_deal_assessment__c     : value.assessmentOptions || [],
            DMT_Sustainable_Deal_Subtype__c        : value.subtypeOptions    || [],
            DMT_sustainable_deal_value__c          : [],
            DMT_Sustainability_deal_value_criteria__c: [
                { label: 'Delegated Label',    value: 'delegated' },
                { label: 'Other Green Activity', value: 'other' }
            ]
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

    // Bonus is compared as boolean and sent as 'Yes'/'No'.
    // Cascade resets are included as null values so the backend clears them.
    @api collectChanges() {
        if (!this._snapshot) return {};
        const changes = {};
        const snapMap = new Map(this._snapshot.map(f => [f.id, f]));

        for (const f of this.fields) {
            if (this._isOriginallyReadOnly(f.apiName)) continue;
            const original = snapMap.get(f.id);
            let hasChanged, valueToSend;

            if (f.apiName === F_BONUS) {
                const curBool  = this._normalizeBonusToBoolean(f.value);
                const origBool = this._normalizeBonusToBoolean(original?.value);
                hasChanged  = curBool !== origBool;
                valueToSend = curBool ? 'Yes' : 'No';
            } else {
                hasChanged  = String(f.value ?? '') !== String(original?.value ?? '');
                valueToSend = (f.value === '' || f.value === undefined) ? null : f.value;
            }

            if (!hasChanged) continue;
            changes[f.apiName] = valueToSend;
        }
        return changes;
    }

    @api getFieldLabel(apiName) {
        const f = this.fields.find(x => x.apiName === apiName);
        return f ? f.label : null;
    }

    // ─── Cascade state getters ────────────────────────────────────────────────

    get isSubtypeDisabled() {
        return !SUBCATEGORY_TRIGGER_VALUES.includes(this.selectedAssessment);
    }

    get isGreenFilterDisabled() {
        return !(this.selectedAssessment === SUSTAINABLE_USE_OF_PROCEEDS && this.selectedSubtype === TXT_GREEN);
    }

    get isCatalogDisabled() {
        const hasSubtypeSelected = SUBCATEGORY_TRIGGER_VALUES.includes(this.selectedAssessment) && this.selectedSubtype !== '';
        const isSSL              = SSL_ONLY_VALUES.includes(this.selectedAssessment);

        if (!ENABLE_GREEN_FILTER) return !(hasSubtypeSelected || isSSL);

        const needsGreenFilter = this.selectedAssessment === SUSTAINABLE_USE_OF_PROCEEDS && this.selectedSubtype === TXT_GREEN;
        if (needsGreenFilter) {
            const greenFilterOk = !this.isGreenFilterDisabled && this.selectedGreenFilter !== '';
            return !(hasSubtypeSelected && greenFilterOk);
        }
        return !hasSubtypeSelected && !isSSL;
    }

    get subtypePlaceholder()     { return this.isSubtypeDisabled    ? PH_SUBTYPE_DISABLED      : PH_DEFAULT; }
    get greenFilterPlaceholder() { return this.isGreenFilterDisabled ? PH_GREEN_FILTER_DISABLED : PH_DEFAULT; }
    get catalogPlaceholder()     { return this.isCatalogDisabled     ? PH_CATALOG_DISABLED      : PH_DEFAULT; }

    // ─── Event handlers ───────────────────────────────────────────────────────

    handleEditModeChange(event) {
        this.dispatchEvent(new CustomEvent('editmodechange', { detail: event.detail }));
    }

    handleFieldChange(event) {
        const { fieldId, value, isFieldValid } = event.detail;
        const idx = this.fields.findIndex(f => f.id === fieldId);
        if (idx === -1) return;

        const field           = this.fields[idx];
        const apiName         = field.apiName;
        const normalizedValue = apiName === F_BONUS ? this._normalizeBonusToBoolean(value) : value;
        const sectionChanges  = { [apiName]: normalizedValue };

        let newArr  = this.fields.slice();
        newArr[idx] = { ...field, value: normalizedValue, isFieldValid };

        switch (apiName) {
            case F_ASSESSMENT:
                this.selectedAssessment  = normalizedValue || '';
                this.selectedSubtype     = '';
                this.selectedGreenFilter = '';
                newArr = this._resetDependentFields(newArr);
                sectionChanges[F_SUBTYPE] = '';
                sectionChanges[F_GREEN_FILTER] = '';
                sectionChanges[F_CATALOG] = '';
                // Assessment '1' (None) automatically disables bonus
                if (this.selectedAssessment === ASSESSMENT_NONE) {
                    newArr = this._setFieldValue(newArr, F_BONUS, false);
                    sectionChanges[F_BONUS] = false;
                }
                this._loadDependentPicklist();
                break;
            case F_SUBTYPE:
                this.selectedSubtype     = normalizedValue || '';
                this.selectedGreenFilter = '';
                newArr = this._clearCatalogAndGreenFilter(newArr);
                sectionChanges[F_GREEN_FILTER] = '';
                sectionChanges[F_CATALOG] = '';
                // Green/Social subtypes automatically enable bonus
                if (BONUS_AUTO_TRUE_SUBTYPES.includes(this.selectedSubtype)) {
                    newArr = this._setFieldValue(newArr, F_BONUS, true);
                    sectionChanges[F_BONUS] = true;
                }
                break;
            case F_GREEN_FILTER:
                this.selectedGreenFilter = normalizedValue || '';
                newArr = this._setFieldValue(newArr, F_CATALOG, '');
                sectionChanges[F_CATALOG] = '';
                break;
            default:
                break;
        }

        this.fields = this._applyFieldStateRules(newArr);
        this.dispatchEvent(new CustomEvent('sectionchange', {
            detail: { changes: sectionChanges },
            bubbles: true,
            composed: true
        }));
        this.dispatchEvent(new CustomEvent('fieldchange', { detail: { fieldId, value: normalizedValue } }));
        this._loadCatalogIfNeeded();
    }

    // ─── Recompute ────────────────────────────────────────────────────────────

    _recompute() {
        let next = this._fieldsOriginal.map(f => ({ ...f }));

        // Apply dynamic options from parent
        if (this._options) {
            next = next.map(f => {
                const options = this._options[f.apiName];
                if (!options) return f;
                const merged     = { ...f, options };
                const originalRO = this._isOriginallyReadOnly(f.apiName);
                if (f.type === 'picklist' && !originalRO) merged.isReadOnly = options.length === 0;
                return merged;
            });
        }

        // Map record values and track current selections for cascade getters;
        // bonus is always normalized to boolean on load
        if (this._data) {
            next = next.map(f => {
                let value = this._data[f.apiName];
                if      (f.apiName === F_ASSESSMENT)   this.selectedAssessment   = value || '';
                else if (f.apiName === F_SUBTYPE)       this.selectedSubtype      = value || '';
                else if (f.apiName === F_GREEN_FILTER)  this.selectedGreenFilter  = value || '';
                else if (f.apiName === F_BONUS)         value = this._normalizeBonusToBoolean(value);
                return { ...f, value };
            });
        }

        this.fields = this._applyFieldStateRules(next);

        // Re-apply forced read-only if the mode was active before recompute
        if (this._readOnlySnapshot) {
            this.fields = this.fields.map(f => ({ ...f, isReadOnly: true }));
        }

        if (this._data) {
            this._loadDependentPicklist();
            this._loadCatalogIfNeeded();
        }
    }

    // Applies cascade state to dependent fields: disabled, isReadOnly, placeholder
    _applyFieldStateRules(fieldsArray) {
        return fieldsArray.map(f => {
            const originalRO = this._isOriginallyReadOnly(f.apiName);
            switch (f.apiName) {
                case F_SUBTYPE: {
                    const disabled = this.isSubtypeDisabled;
                    return { ...f, disabled, isReadOnly: originalRO || disabled, placeholder: this.subtypePlaceholder };
                }
                case F_GREEN_FILTER: {
                    const disabled = this.isGreenFilterDisabled;
                    return { ...f, disabled, isReadOnly: originalRO || disabled, placeholder: this.greenFilterPlaceholder };
                }
                case F_CATALOG: {
                    const disabled = this.isCatalogDisabled;
                    return { ...f, disabled, isReadOnly: originalRO || disabled, placeholder: this.catalogPlaceholder };
                }
                default: return f;
            }
        });
    }

    // ─── Pure array mutators ──────────────────────────────────────────────────

    _resetDependentFields(fieldsArray) {
        const toReset = new Set([F_SUBTYPE, F_CATALOG, F_GREEN_FILTER]);
        return fieldsArray.map(f => toReset.has(f.apiName) ? { ...f, value: '' } : f);
    }

    _clearCatalogAndGreenFilter(fieldsArray) {
        const toClear = new Set([F_CATALOG, F_GREEN_FILTER]);
        return fieldsArray.map(f => toClear.has(f.apiName) ? { ...f, value: '' } : f);
    }

    _setFieldValue(fieldsArray, apiName, value) {
        return fieldsArray.map(f => f.apiName === apiName ? { ...f, value } : f);
    }

    _setFieldOptions(fieldsArray, apiName, options) {
        return fieldsArray.map(f => f.apiName === apiName ? { ...f, options } : f);
    }

    // ─── Apex calls ───────────────────────────────────────────────────────────

    _loadDependentPicklist() {
        if (!SUBCATEGORY_TRIGGER_VALUES.includes(this.selectedAssessment)) {
            this.fields = this._setFieldOptions(this.fields, F_SUBTYPE, []);
            return;
        }
        getDependentPicklistValues({ controllingFieldValue: this.selectedAssessment })
            .then(result => {
                this.fields = this._setFieldOptions(this.fields, F_SUBTYPE, this._mapToOptions(result));
            })
            .catch(error => {
                console.error('[sustainability] Error loading dependent picklist:', error);
            });
    }

    async _loadCatalogIfNeeded() {
        if (this.isCatalogDisabled) {
            this.fields = this._setFieldOptions(this.fields, F_CATALOG, []);
            return;
        }
        try {
            const result = ASSESSMENT_DIRECT_CATALOG_VALUES.includes(this.selectedAssessment)
                ? await getCatalogByAssessment({ assessmentValue: this.selectedAssessment })
                : await getCatalogBySubtype({
                    subtypeValue     : this.selectedSubtype,
                    greenFilter      : this.selectedGreenFilter,
                    enableGreenFilter: ENABLE_GREEN_FILTER
                });
            this.fields = this._setFieldOptions(this.fields, F_CATALOG, this._mapToOptions(result));
        } catch (error) {
            console.error('[sustainability] Error loading catalog:', error);
        }
    }

    _mapToOptions(data) {
        if (!Array.isArray(data)) return [];
        return data.map(({ label, value }) => ({ label, value }));
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    // Accepts true/false, 'Yes'/'No', 'true'/'false', null/undefined
    _normalizeBonusToBoolean(value) {
        return value === true || value === 'Yes' || value === 'true';
    }

    _isOriginallyReadOnly(apiName) {
        return this._fieldsOriginal.find(o => o.apiName === apiName)?.isReadOnly === true;
    }
}