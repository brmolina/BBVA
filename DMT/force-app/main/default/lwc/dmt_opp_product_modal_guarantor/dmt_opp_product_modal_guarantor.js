import { api, track }              from 'lwc';
import LightningModal              from 'lightning/modal';
import { createRecord, updateRecord } from 'lightning/uiRecordApi';
import { guarantorFields }         from './dmt_opp_product_modal_guarantor_fields';
import getMitigantsData            from '@salesforce/apex/DMT_OpportunityProductsController.getMitigantsData';
import { mergeSavedTypes }         from 'c/dmt_mitigant_utils';
import { ShowToastEvent }          from 'lightning/platformShowToastEvent';
import getGuarantorHpgData         from '@salesforce/apex/DMT_OpportunityProductsController.getGuarantorHpgData';

const F_COUNTERPART    = 'Counterpart__c';
const F_GUARANTOR      = 'DMT_Guarantor_Account__c';
// CIBGLOBALD-4630 - fields preloaded from the HPG service when a Guarantor is selected
const HPG_FIELDS       = new Set(['DMT_Scoring__c', 'Internal_Rating__c', 'External_Rating__c']);
const FIN_INST_VALUES  = new Set(['Fin Inst-I', 'Fin Inst', 'Fin Inst-B']);
const FIN_INST_FIELDS  = new Set(['AVC_Check__c', 'European_Bank_Check__c', 'SCRA__c']);
// SCRA__c and External_Rating__c are mutually exclusive: at least one must be filled for Fin Inst
const FIN_INST_MUTEX   = new Set(['External_Rating__c', 'SCRA__c']);
const SOV_VALUE        = 'Sov';
const SOV_FIELDS       = new Set(['DMT_Country_Guarantor__c']);

const CATALOG_MAP = {
    Mitigant_Type__c        : 'E895',
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
    _hpgRequestId = 0;

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
            if (f.apiName !== 'DMT_Guarantor_Account__c') return { ...f };
            return {
                ...f,
                filters: { AND: [{ field: 'g_customer_id__c', operator: 'LIKE', value: entityPrefix }] }
            };
        });
        if (this.record) {
            this._loadRecord(this.record);
        } else {
            this.fields = this._applyCounterpartRules(this.fields, '');
        }
        this._assignPicklistOptions();
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
        const guarantorChanged = field.apiName === F_GUARANTOR && field.value !== value;
        if (guarantorChanged) {
            // CIBGLOBALD-4630 - never keep the HPG values of the previously selected Guarantor
            newArr = this._clearHpgFields(newArr);
        }
        this.fields = newArr;
        if (guarantorChanged) {
            this._preloadFromHpg(value);
        }
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

    // ─── HPG preload (CIBGLOBALD-4630) ────────────────────────────────────────

    _clearHpgFields(fieldsArray) {
        return fieldsArray.map(f => (HPG_FIELDS.has(f.apiName) ? { ...f, value: '' } : f));
    }

    // CIBGLOBALD-4630 - Called when a Guarantor is selected (not when the modal opens). Fills Scoring,
    // Internal Rating and External Rating from HPG. Values HPG does not return stay blank, so required
    // fields remain required for the user. Political and Commercial Risk are not preloaded: HPG does not
    // return them, or the properties that represent them are unknown (see getGuarantorHpgData).
    async _preloadFromHpg(guarantorValue) {
        const requestId = ++this._hpgRequestId;
        const accountId = guarantorValue && typeof guarantorValue === 'object'
            ? guarantorValue.id
            : guarantorValue;
        if (!accountId) {
            this.isLoading = false;
            return;
        }

        this.isLoading = true;
        try {
            const result = await getGuarantorHpgData({ guarantorAccountId: accountId });
            // A newer Guarantor selection supersedes this response
            if (requestId !== this._hpgRequestId) return;

            if (result?.found) {
                const hpgValues = {
                    DMT_Scoring__c    : result.scoring,
                    Internal_Rating__c: result.internalRating,
                    External_Rating__c: result.externalRating
                };
                this.fields = this.fields.map(f => {
                    const hpgValue = hpgValues[f.apiName];
                    return hpgValue !== undefined && hpgValue !== null ? { ...f, value: hpgValue } : f;
                });
            } else {
                this._notifyHpgUnavailable();
            }
        } catch (error) {
            if (requestId !== this._hpgRequestId) return;
            console.error('HPG preload error:', error?.body?.message || error?.message);
            this._notifyHpgUnavailable();
        } finally {
            if (requestId === this._hpgRequestId) {
                this.isLoading = false;
            }
        }
    }

    _notifyHpgUnavailable() {
        this.dispatchEvent(new ShowToastEvent({
            title  : 'HPG data not available',
            message: 'Scoring and ratings could not be retrieved from HPG for this Guarantor. Please fill them in manually.',
            variant: 'warning'
        }));
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
                // External_Rating__c stays visible and editable for every Guarantor Type,
                // unlike SCRA__c above which is only shown for Fin Inst — so its value
                // must never be cleared based on counterpart type.
                return { ...f, isRequired: false };
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
            if (f.apiName === 'Mitigant_Type__c') {
                return {
                    ...f,
                    options: mergeSavedTypes(
                        Array.isArray(options) ? options : [],
                        [f.value]
                    )
                };
            }
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