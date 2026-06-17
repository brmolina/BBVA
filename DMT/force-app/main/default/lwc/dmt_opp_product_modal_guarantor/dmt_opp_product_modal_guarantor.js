import { api, track }              from 'lwc';
import LightningModal              from 'lightning/modal';
import { createRecord, updateRecord } from 'lightning/uiRecordApi';
import { guarantorFields }         from './dmt_opp_product_modal_guarantor_fields';
import getMitigantsData            from '@salesforce/apex/DMT_OpportunityProductsController.getMitigantsData';

const F_COUNTERPART    = 'Counterpart__c';
const FIN_INST_VALUES  = new Set(['Fin Inst-I', 'Fin Inst', 'Fin Inst-B']);
const FIN_INST_FIELDS  = new Set(['AVC_Check__c', 'European_Bank_Check__c', 'SCRA__c']);
// SCRA__c and External_Rating__c are mutually exclusive: at least one must be filled for Fin Inst
const FIN_INST_MUTEX   = new Set(['External_Rating__c', 'SCRA__c']);
const SOV_VALUE        = 'Sov';
const SOV_FIELDS       = new Set(['DMT_Country_Guarantor__c']);

const CATALOG_MAP = {
    Counterpart__c          : 'D971',
    External_Rating__c      : 'C009',
    Internal_Rating__c      : 'C204',
    DMT_Currency__c         : 'C264',
    DMT_Country_Guarantor__c: 'C245'
};

const OBJECT_API_NAME = 'DMT_Opportunity_Mitigant__c';

export default class DmtOppProductModalGuarantor extends LightningModal {

    @api record;
    @api oppProduct;
    @api endDateProduct;
    @api entity;

    _catalogValues  = {};
    _fieldsOriginal = guarantorFields.map(f => ({ ...f }));

    @track fields           = [];
    @track showErrorPopover = false;
    @track errorMessage     = '';

    isLoading = false;

    // ─── Computed ─────────────────────────────────────────────────────────────

    get hasError()    { return !!this.errorMessage; }
    get modalTitle()  { return this.record ? 'Edit Guarantor' : 'New Guarantor'; }
    get saveLabel()   { return this.record ? 'Save' : 'Create'; }
    get isEditMode()  { return !!this.record; }

    // ─── Public API ───────────────────────────────────────────────────────────

    @api get catalogValues() { return this._catalogValues; }
    set catalogValues(value) {
        if (!value || typeof value !== 'object') return;
        this._catalogValues = value;
        if (this.fields.length > 0) {
            this._assignPicklistOptions();
        }
    }

    // ─── Lifecycle ────────────────────────────────────────────────────────────

    connectedCallback() {
        // Apply entity filter to the local client lookup field
        const entityPrefix = this.entity ? `%${this.entity}%` : '%%';
        this.fields = this._fieldsOriginal.map(f => {
            if (f.apiName !== 'DMT_Local_Client__c') return { ...f };
            return {
                ...f,
                filters: { AND: [{ field: 'Alpha_code__c', operator: 'LIKE', value: entityPrefix }] }
            };
        });
        this._assignPicklistOptions();
        if (this.record) {
            this._loadRecord(this.record);
        } else {
            this.fields = this._applyCounterpartRules(this.fields, '');
        }
    }

    // ─── Event handlers ───────────────────────────────────────────────────────

    handleFieldChange(event) {
        const { fieldId, value } = event.detail;
        const idx = this.fields.findIndex(f => f.id === fieldId);
        if (idx === -1) return;
        const field  = this.fields[idx];
        let newArr   = this.fields.slice();
        newArr[idx]  = { ...field, value };
        if (field.apiName === F_COUNTERPART) {
            newArr = this._applyCounterpartRules(newArr, value);
        }
        this.fields = newArr;
    }

    handleCancel() {
        this.close();
    }

    handleErrorButtonClick() {
        this.showErrorPopover = !this.showErrorPopover;
    }

    closeErrorPopover() {
        this.showErrorPopover = false;
    }

    async handleSave() {
        if (!this._validate()) return;

        const result = this.fields.reduce((acc, f) => {
            acc[f.apiName] = f.isHidden ? (f.type === 'checkbox' ? false : null) : (f.value ?? null);
            return acc;
        }, {});
        result.DMT_Opportunity_Product__c = this.oppProduct;

        try {
            this.isLoading = true;
            if (this.record?.Id) {
                await updateRecord({ fields: { Id: this.record.Id, ...result } });
            } else {
                await createRecord({ apiName: OBJECT_API_NAME, fields: result });
            }
            const mitigantsResult = await getMitigantsData({ opportunityLineItemId: this.oppProduct });
            this.close(mitigantsResult);
        } catch (error) {
            this.errorMessage    = error?.body?.message || error?.message || 'An unexpected error occurred.';
            this.showErrorPopover = true;
        }
        this.isLoading = false;
    }

    // ─── Counterpart rules ────────────────────────────────────────────────────

    _applyCounterpartRules(fieldsArray, counterpartValue) {
        let result = fieldsArray;
        result = this._applyFinInstRules(result, counterpartValue);
        result = this._applySovRules(result, counterpartValue);
        return result;
    }

    // Fin Inst counterparts show AVC, European Bank and SCRA fields;
    // SCRA and External Rating become optional (mutex pair — at least one required)
    _applyFinInstRules(fieldsArray, counterpartValue) {
        const isFinInst = FIN_INST_VALUES.has(counterpartValue);
        return fieldsArray.map(f => {
            if (FIN_INST_FIELDS.has(f.apiName)) {
                const isMutexToo = FIN_INST_MUTEX.has(f.apiName);
                return {
                    ...f,
                    isHidden : !isFinInst,
                    isRequired: isMutexToo ? false : f.isRequired,
                    value    : isFinInst ? f.value : (f.type === 'checkbox' ? false : '')
                };
            }
            if (FIN_INST_MUTEX.has(f.apiName)) {
                return { ...f, isRequired: false, value: isFinInst ? f.value : '' };
            }
            return f;
        });
    }

    // Sov counterpart shows the Country Guarantor field
    _applySovRules(fieldsArray, counterpartValue) {
        const show = counterpartValue === SOV_VALUE;
        return fieldsArray.map(f => {
            if (!SOV_FIELDS.has(f.apiName)) return f;
            return { ...f, isHidden: !show, value: show ? f.value : '' };
        });
    }

    // ─── Record loading ───────────────────────────────────────────────────────

    _loadRecord(record) {
        const counterpartValue = record[F_COUNTERPART] || '';
        let loaded = this.fields.map(f => ({
            ...f,
            value: record[f.apiName] !== undefined ? record[f.apiName] : f.value
        }));
        loaded      = this._applyCounterpartRules(loaded, counterpartValue);
        this.fields = loaded;
    }

    _assignPicklistOptions() {
        this.fields = this.fields.map(f => {
            if (f.type !== 'picklist') return f;
            const catalogKey = CATALOG_MAP[f.apiName];
            if (!catalogKey) return f;
            const options = this._catalogValues[catalogKey];
            return {
                ...f,
                options: Array.isArray(options) && options.length > 0 ? options : f.options || []
            };
        });
    }

    // ─── Validation ───────────────────────────────────────────────────────────

    _validate() {
        const missing = this.fields.find(
            f => f.isRequired && !f.isHidden &&
                 (f.value === '' || f.value === null || f.value === undefined)
        );
        if (missing) {
            this.errorMessage    = `${missing.label} is required.`;
            this.showErrorPopover = true;
            return false;
        }

        const counterpartValue = this.fields.find(f => f.apiName === F_COUNTERPART)?.value || '';

        // Fin Inst: at least External Rating or SCRA must be filled (mutex pair)
        if (FIN_INST_VALUES.has(counterpartValue)) {
            const externalRating = this.fields.find(f => f.apiName === 'External_Rating__c');
            const scra           = this.fields.find(f => f.apiName === 'SCRA__c');
            const hasExternal    = externalRating?.value !== '' && externalRating?.value != null;
            const hasScra        = scra?.value !== ''           && scra?.value != null;
            if (!hasExternal && !hasScra) {
                this.errorMessage    = 'At least one of External Rating or SCRA must be filled in.';
                this.showErrorPopover = true;
                return false;
            }
        }

        // Sov: at least External Rating or Country Guarantor must be filled
        if (counterpartValue === SOV_VALUE) {
            const externalRating   = this.fields.find(f => f.apiName === 'External_Rating__c');
            const countryGuarantor = this.fields.find(f => f.apiName === 'DMT_Country_Guarantor__c');
            const hasExternal      = externalRating?.value   !== '' && externalRating?.value   != null;
            const hasCountry       = countryGuarantor?.value !== '' && countryGuarantor?.value != null;
            if (!hasExternal && !hasCountry) {
                this.errorMessage    = 'At least one of External Rating or Country Guarantor must be filled in.';
                this.showErrorPopover = true;
                return false;
            }
        }

        this.errorMessage    = '';
        this.showErrorPopover = false;
        return true;
    }
}