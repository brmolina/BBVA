import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ONB_NO_FIELDS from '@salesforce/label/c.ONB_NO_FIELDS';

export default class Onb_onboardingForm extends LightningElement {
    //@api objectApiName;
    @api recordId;

    // When true: do NOT save here; emit valuechange and let wrapper save.
    @api handleSaveOnWrapper = false;

    // Existing API
    @api fieldCustomLabels;       // { Field__c: 'Custom Label' }
    @api fieldRules = {};

    @api title;
    @api iconName;
    @api allRequired = false;

    @track fieldsConfig = [];     // render model
    valuesByField = {};           // { apiName: value }
    recordTypeId;
    objectInfo;
    picklistData;
    fieldsToQuery = [];

    _fieldNames; // ['Status__c', 'Category__c']
    _objectApiName;

    @api
    get objectApiName() {
        return this._objectApiName;
    }
    set objectApiName(v) {
        this._objectApiName = v;
        this.rebuildFieldsToQuery();
    }

    @api
    get fieldNames() {
        return this._fieldNames;
    }
    set fieldNames(v) {
        this._fieldNames = v;
        this.rebuildFieldsToQuery();
    }

    label = { ONB_NO_FIELDS };

    dirtyFields = new Set();

    @api
    getValues() {
        // Devuelve una copia de todo lo que el formulario tiene en pantalla ahora mismo
        return this.valuesByField ? { ...this.valuesByField } : {};
    }

    connectedCallback() {
    }

    rebuildFieldsToQuery() {
        if (!Array.isArray(this.fieldNames) || !this.objectApiName) {
            this.fieldsToQuery = [];
            return;
        }
        const base = this.fieldNames.map(f => `${this.objectApiName}.${f}`);
        const hasRecordTypeId = !!this.objectInfo?.fields?.RecordTypeId;
        this.fieldsToQuery = hasRecordTypeId
            ? [...base, `${this.objectApiName}.RecordTypeId`]
            : base;
    }

    get hasFields() {
        return Array.isArray(this.fieldNames) && this.fieldNames.length > 0;
    }

    get cardTitle() {
        return (this.title && this.title.trim().length > 0) ? this.title : '\u00A0';
    }

    get effectiveRecordTypeId() {
        const id = this.recordTypeId || this.objectInfo?.defaultRecordTypeId;
        return id || null;
    }

    // ---------------------------------------------
    // Wires
    // ---------------------------------------------
    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    wiredObjectInfo({ data, error }) {
         if (data) {
            this.objectInfo = data;
            this.rebuildFieldsToQuery();
            this.buildFieldsConfig();
        } else if (error) {
            console.error('Error in getObjectInfo', error);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$fieldsToQuery' })
    wiredRecord({ data, error }) {
        if (data) {
            this.recordTypeId = data.fields.RecordTypeId?.value;

            const next = { ...this.valuesByField };

            this.fieldNames.forEach(fieldApiName => {
                if (this.dirtyFields.has(fieldApiName)) return;

                const fieldData = data.fields[fieldApiName];
                next[fieldApiName] = fieldData ? fieldData.value : null;
            });

            this.valuesByField = next;
            this.buildFieldsConfig();
        } else if (error) {
            console.error('Error in getRecord', error);
        }
    }


    @wire(getPicklistValuesByRecordType, {
        objectApiName: '$objectApiName',
        recordTypeId: '$effectiveRecordTypeId'
    })
    wiredPicklists({ data, error }) {
        if (data) {
            this.picklistData = data.picklistFieldValues;
            this.buildFieldsConfig();
        } else if (error) {
            console.error('Error in getPicklistValuesByRecordType', error);
        }
    }

    clearValuesForNewlyDisabledFields(prevConfig) {
        if (!Array.isArray(prevConfig) || !Array.isArray(this.fieldsConfig)) return;

        const prevByApi = new Map(prevConfig.map(f => [f.apiName, f]));
        const fieldsToClear = [];
        this.fieldsConfig.forEach(curr => {
            const prev = prevByApi.get(curr.apiName);
            const wasDisabled = prev ? !!prev.disabled : false;
            const isDisabledNow = !!curr.disabled;

            if (!wasDisabled && isDisabledNow) fieldsToClear.push(curr.apiName);
        });

        if (fieldsToClear.length === 0) return;

        const nextValues = { ...this.valuesByField };

        fieldsToClear.forEach(apiName => {
            const el = this.template.querySelector(`[data-field="${apiName}"]`);
            const oldValue = (el && 'value' in el) ? el.value : this.valuesByField[apiName];

            if (el && 'value' in el) {
                try { el.value = null; } catch (e) { /* no-op */ }
                if (typeof el.setCustomValidity === 'function') el.setCustomValidity('');
                if (typeof el.reportValidity === 'function') el.reportValidity();
            }

            nextValues[apiName] = null;
            this.dirtyFields.add(apiName);
            this.dispatchEvent(new CustomEvent('valuechange', {
                detail: { fieldApiName: apiName, value: null, oldValue }
            }));
        });

        this.valuesByField = nextValues;
        this.recomputeDynamicState();

        requestAnimationFrame(() => {
            fieldsToClear.forEach(apiName => {
                const el = this.template.querySelector(`[data-field="${apiName}"]`);
                if (!el) return;

                if (typeof el.setCustomValidity === 'function') el.setCustomValidity('');
                if (typeof el.reportValidity === 'function') el.reportValidity();
            });
        });

        if (!this.handleSaveOnWrapper) {
            fieldsToClear.reduce((p, apiName) => p.then(() => this.saveSingleField(apiName)), Promise.resolve())
                .catch(err => {
                    console.error('Error clearing disabled fields', err);
                    this.showErrorToast(err);
                });
        }
    }

    // ---------------------------------------------
    // Rule evaluation
    // ---------------------------------------------
    evaluateRule(rule) {
        if (!rule) return true;

        const evalOne = (r) => {
            const left = this.valuesByField?.[r.field];
            const right = r.value;

            switch (r.op) {
                case 'eq': return left === right;
                case 'ne': return left !== right;
                case 'in': return Array.isArray(right) && right.includes(left);
                case 'notIn': return Array.isArray(right) && !right.includes(left);
                case 'isBlank': return left === null || left === undefined || left === '';
                case 'isNotBlank': return !(left === null || left === undefined || left === '');
                default: return true;
            }
        };

        if (rule.all) return rule.all.every(evalOne);
        if (rule.any) return rule.any.some(evalOne);
        return evalOne(rule);
    }

    getFieldRule(apiName) {
        return (this.fieldRules && this.fieldRules[apiName]) ? this.fieldRules[apiName] : {};
    }

    // ---------------------------------------------
    // Build render model
    // ---------------------------------------------
    buildFieldsConfig() {
        if (!this.objectInfo || !Array.isArray(this.fieldNames)) return;

        const result = [];
        const customLabels = this.fieldCustomLabels || {};

        this.fieldNames.forEach(apiName => {
            const describe = this.objectInfo.fields[apiName];
            if (!describe) return;

            // Picklist (no multiselect)
            const isPicklist = describe.dataType === 'Picklist';
            // Text Area
            const isTextArea = describe.dataType === 'TextArea';
            // Lookup inferred automatically from describe
            const isLookup = describe.dataType === 'Reference';
            // Email
            const isEmail = describe.dataType === 'Email';
            // Text
            const isString = describe.dataType === 'String';
            const maxLength = (isString || isEmail) ? (describe.length ?? null) : null;

            let options = [];
            if (isPicklist && this.picklistData?.[apiName]) {
                options = this.picklistData[apiName].values.map(v => ({ label: v.label, value: v.value }));
            }

            const value = this.valuesByField[apiName];
            const standardLabel = describe.label;
            const displayLabel = customLabels[apiName] || standardLabel;
            const rule = this.getFieldRule(apiName);
            const isVisible = rule.visibleWhen ? this.evaluateRule(rule.visibleWhen) : true;

            const requiredByRule =
                (rule.required === true) ||
                (rule.requiredWhen ? this.evaluateRule(rule.requiredWhen) : false);

            const disabled =
                (rule.disabled === true) ||
                (rule.disabledWhen ? this.evaluateRule(rule.disabledWhen) : false);

            const isReadOnly =
                (rule.readOnly === true) ||
                (rule.readOnlyWhen ? this.evaluateRule(rule.readOnlyWhen) : false);

            const required = (!isReadOnly && !disabled) && ((this.allRequired === true) || requiredByRule);

            // Read-only display (picklist shows label)
            let displayValue = value;
            if (isPicklist) {
                const found = options.find(o => o.value === value);
                displayValue = found ? found.label : value;
            }
            if (displayValue === null || displayValue === undefined || displayValue === '') {
                displayValue = '—';
            }

            result.push({
                apiName,
                label: standardLabel,
                displayLabel,
                value,
                isPicklist,
                isTextArea,
                isLookup,
                isEmail,
                options,
                isVisible,
                required,
                disabled: disabled || isReadOnly, // readOnly implies not editable
                isReadOnly,
                displayValue,
                maxLength
            });
        });
        this.fieldsConfig = result;
    }

    // Light recompute after local changes (without re-pulling describe/picklists)
    recomputeDynamicState() {
        this.fieldsConfig = this.fieldsConfig.map(f => {
            const rule = this.getFieldRule(f.apiName);
            const isVisible = rule.visibleWhen ? this.evaluateRule(rule.visibleWhen) : true;

            const requiredByRule =
                (rule.required === true) ||
                (rule.requiredWhen ? this.evaluateRule(rule.requiredWhen) : false);

            const disabled =
                (rule.disabled === true) ||
                (rule.disabledWhen ? this.evaluateRule(rule.disabledWhen) : false);

            const isReadOnly =
                (rule.readOnly === true) ||
                (rule.readOnlyWhen ? this.evaluateRule(rule.readOnlyWhen) : false);

            const required = (!isReadOnly && !disabled) && ((this.allRequired === true) || requiredByRule);

            let displayValue = this.valuesByField[f.apiName];
            if (f.isPicklist) {
                const found = (f.options || []).find(o => o.value === displayValue);
                displayValue = found ? found.label : displayValue;
            }
            if (displayValue === null || displayValue === undefined || displayValue === '') {
                displayValue = '—';
            }

            return {
                ...f,
                isVisible,
                required,
                disabled: disabled || isReadOnly,
                isReadOnly,
                value: this.valuesByField[f.apiName],
                displayValue
            };
        });
    }

    // ---------------------------------------------
    // Change handling (auto-save OR wrapper-save)
    // ---------------------------------------------
    handlePicklistChange(event) {
        const apiName = event.target.dataset.field;
        const value = event.detail.value;
        this.processFieldChange(apiName, value);
    }

    handleInputBlur(event) {
        const apiName = event.target.dataset.field;
        const value = event.target.value;
        this.processFieldChange(apiName, value, event.target);
    }

    handleLookupChange(event) {
        const apiName = event.target.dataset.field;
        const value = (event.detail && 'value' in event.detail) ? event.detail.value : event.target.value;
        this.processFieldChange(apiName, value);
    }

    async processFieldChange(apiName, newValue, el) {
        const fieldModel = this.fieldsConfig.find(f => f.apiName === apiName);
        if (!fieldModel || fieldModel.disabled || fieldModel.isReadOnly) return;

        const oldValue = this.valuesByField[apiName];
        const prevConfig = this.fieldsConfig.map(f => ({ ...f }));

        this.updateLocalValue(apiName, newValue);
        this.recomputeDynamicState();
        this.clearValuesForNewlyDisabledFields(prevConfig);

        const isValid = this.validateElement(apiName, el);
        if (!isValid) return;

        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: { fieldApiName: apiName, value: newValue, oldValue }
        }));

        if (this.handleSaveOnWrapper) return;

        if (oldValue !== newValue) {
            try {
                await this.saveSingleField(apiName);
            } catch (err) {
                this.showErrorToast(err);
            }
        }
    }

    updateLocalValue(apiName, value) {
        this.dirtyFields.add(apiName);
        this.valuesByField = { ...this.valuesByField, [apiName]: value };
    }

    async saveSingleField(apiName) {
        const fields = { Id: this.recordId, [apiName]: this.valuesByField[apiName] };
        await updateRecord({ fields });
        this.dirtyFields.delete(apiName);
    }


    // ---------------------------------------------
    // Validation (red state)
    // ---------------------------------------------
    validateField(apiName) {
        const el = this.template.querySelector(`[data-field="${apiName}"]`);
        return this.validateElement(apiName, el);
    }

    validateElement(apiName, el) {
        const model = this.fieldsConfig.find(f => f.apiName === apiName);
        if (!model || !model.isVisible || model.isReadOnly || model.disabled) return true;

        if (!el) {
            el = this.template.querySelector(`[data-field="${apiName}"]`);
            if (!el) return true;
        }

        if (el.tagName === 'LIGHTNING-INPUT-FIELD') {
            return el.reportValidity();
        }

        if (typeof el.setCustomValidity === 'function') el.setCustomValidity('');

        const value = (el && 'value' in el) ? el.value : model.value;
        const str = value == null ? '' : String(value).trim();
        const isEmpty = str === '';

        if (model.required && isEmpty) {
            el.setCustomValidity('Complete this field.');
            el.reportValidity();
            return false;
        }

        if (model.isEmail && !isEmpty) {
            const ok = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(str);
            if (!ok) {
                el.setCustomValidity('Enter a valid email address, such as name@email.com.');
                el.reportValidity();
                return false;
            }
        }

        return el.reportValidity();
    }


    @api validate() {
        let ok = true;

        const fields = (this.fieldsConfig || [])
            .filter(f => f.isVisible && !f.isReadOnly && !f.disabled);

        fields.forEach(f => {
            const el = this.template.querySelector(`[data-field="${f.apiName}"]`);
            if (!el) return;

            if (el.tagName === 'LIGHTNING-INPUT-FIELD') {
                if (!el.reportValidity()) ok = false;
                    return;
            }

            if (typeof el.setCustomValidity === 'function') el.setCustomValidity('');

            const raw = ('value' in el) ? el.value : f.value;
            const str = raw == null ? '' : String(raw).trim();
            const isEmpty = str === '';

            if (f.required && isEmpty) {
                el.setCustomValidity('Complete this field.');
                ok = false;
            }

            if (f.isEmail && !isEmpty) {
                const emailOk = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(str);
                if (!emailOk) {
                    el.setCustomValidity('Enter a valid email address, such as name@email.com.');
                    ok = false;
                }
            }

            if (typeof el.reportValidity === 'function') {
                if (!el.reportValidity()) ok = false;
            }
        });

        return ok;
    }

    showErrorToast(error) {
        let message = 'Unknown error';
        if (error?.body?.message) message = error.body.message;

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error saving',
                message,
                variant: 'error'
            })
        );
    }
}