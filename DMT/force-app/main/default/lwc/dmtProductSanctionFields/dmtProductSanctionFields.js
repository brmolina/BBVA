import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRelatedSelections from '@salesforce/apex/DMT_ProductSanctionMigrationController.getRelatedSelections';
import saveRelatedSelections from '@salesforce/apex/DMT_ProductSanctionMigrationController.saveRelatedSelections';

const OBJECT_API = 'DMT_Risk_Line_Term__c';
const ID_FIELD = `${OBJECT_API}.Id`;
const CURRENCY_FIELD = `${OBJECT_API}.CurrencyIsoCode`;
const WARRANTY_FIELD_KEY = 'DMT_Warranty__c.g_limits_grid_guarantee_type__c';
const CURRENCY_PROVISION_FIELD_KEY = 'DMT_Currency_Provision__c.g_currency_id__c';

export default class DmtProductSanctionFields extends LightningElement {
    _riskId;
    _fieldConfigs = [];

    @api
    get riskId() {
        return this._riskId;
    }

    set riskId(value) {
        if (this._riskId === value) {
            return;
        }
        this._riskId = value;
        this._resetForContextChange();
    }

    @api
    get fieldConfigs() {
        return this._fieldConfigs;
    }

    set fieldConfigs(value) {
        this._fieldConfigs = value || [];
        this.changedValues = {};
        this.fieldValidity = {};
        this._rebuildFields();
    }

    @api canEdit = false;
    @api entific;
    @api lineStatus;
    @api lineType;
    @api lineId;
    @api lineBusinessId;
    @api lineClientType;
    @api clientId;
    @api groupCode;
    @api groupAccount;
    @api mainHolderCustomer;
    @api riskPriorityId;
    @api hideInlineFooter = false;

    get showInlineFooter() {
        return !this.hideInlineFooter;
    }

    _editState = false;

    @api
    get editState() {
        return this._editState;
    }

    set editState(value) {
        this._editState = !!value;
        this.isEditMode = this._editState;
        this._rebuildFields();
    }

    @track recordData = {};
    @track fields = [];

    isEditMode = false;
    isSaving = false;
    changedValues = {};
    fieldValidity = {};
    wiredRecordResult;
    _relatedLoadToken = 0;

    connectedCallback() {
        this.isEditMode = !!this._editState;
        this._rebuildFields();
    }

    _resetForContextChange() {
        this.isEditMode = false;
        this.isSaving = false;
        this.changedValues = {};
        this.fieldValidity = {};
        this.recordData = {};
        this.fields = [];
        this._relatedLoadToken++;
        this._rebuildFields();
    }

    @api
    getEditMode() {
        return this.isEditMode;
    }

    @api
    async saveFromParent() {
        await this.handleSave();
    }

    @api
    cancelFromParent() {
        this.handleCancel();
    }

    get hasConfiguredFields() {
        return this.fields.length > 0;
    }

    get containerClass() {
        const hasFooter = this.isEditMode && this.showInlineFooter;
        return hasFooter ? 'sanction-fields has-fixed-footer' : 'sanction-fields';
    }

    get showClientsSection() {
        return this.isOtherProductsLine && String(this.lineClientType || this.recordData.Client_Type__c || '').toLowerCase() === 'custom';
    }

    get isOtherProductsLine() {
        const value = String(this.lineType || '').trim().toLowerCase();
        return value === 'line (other products)' || value === 'ol';
    }

    get recordFields() {
        const fields = new Set([ID_FIELD, CURRENCY_FIELD]);
        (this.fieldConfigs || []).forEach((cfg) => {
            const apiName = cfg?.fieldApiName;
            if (apiName) {
                if (this._isRelatedField(apiName)) {
                    return;
                }
                fields.add(apiName.includes('.') ? apiName : `${OBJECT_API}.${apiName}`);
            }
        });
        return Array.from(fields);
    }

    get currencyCode() {
        return this._getRecordValue('CurrencyIsoCode') || 'USD';
    }

    @wire(getRecord, { recordId: '$riskId', fields: '$recordFields' })
    wiredRecord(result) {
        this.wiredRecordResult = result;
        const { data, error } = result;
        if (data) {
            this.recordData = this._flattenRecord(data);
            this._rebuildFields();
            this._loadRelatedSelections();
        } else if (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error loading risk details.',
                    variant: 'error'
                })
            );
        }
    }

    handleEdit() {
        if (!this.canEdit) {
            return;
        }
        this.isEditMode = true;
        this.changedValues = {};
        this.fieldValidity = {};
        this._rebuildFields();
        this._notifyEditModeChange();
    }

    handleEditModeChange(event) {
        if (event.detail?.isEditMode) {
            this.handleEdit();
        }
    }

    handleFieldChange(event) {
        const { apiName, fieldId, value, isFieldValid } = event.detail || {};
        const key = apiName || fieldId;
        if (!key) {
            return;
        }

        console.debug('[dmtProductSanctionFields] field change', JSON.stringify({
            key,
            value: Array.isArray(value) ? value : String(value ?? ''),
            isFieldValid
        }));

        this.changedValues = {
            ...this.changedValues,
            [key]: value
        };

        if (typeof isFieldValid === 'boolean') {
            this.fieldValidity = {
                ...this.fieldValidity,
                [key]: isFieldValid
            };
        }

        this._rebuildFields();
    }

    handleCancel() {
        if (this.isSaving) {
            return;
        }
        this.isEditMode = false;
        this.changedValues = {};
        this.fieldValidity = {};
        this._rebuildFields();
        this.dispatchEvent(new CustomEvent('canceledit'));
    }

    async handleSave() {
        if (!this.isEditMode || this.isSaving) {
            return;
        }

        this._setSaving(true);

        if (!this._validateBeforeSave()) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Validation error',
                    message: 'Review required fields before saving.',
                    variant: 'error'
                })
            );
            this._setSaving(false);
            return;
        }

        const changedKeys = Object.keys(this.changedValues || {});
        if (changedKeys.length === 0) {
            this.isEditMode = false;
            this._rebuildFields();
            this.dispatchEvent(new CustomEvent('recordsaved', {
                detail: {
                    recordId: this.riskId,
                    fields: {}
                }
            }));
            this._setSaving(false);
            return;
        }

        const riskFieldChanges = {};
        const relatedFieldChanges = {};
        changedKeys.forEach((fieldKey) => {
            if (this._isRelatedField(fieldKey)) {
                relatedFieldChanges[fieldKey] = this.changedValues[fieldKey];
            } else {
                const field = this.fields.find((candidate) => candidate.apiName === fieldKey);
                const value = this.changedValues[fieldKey];
                riskFieldChanges[this._normalizeApiName(fieldKey)] = field?.isPercent
                    ? this._toStoredPercent(value)
                    : value;
            }
        });

        const hasRiskChanges = Object.keys(riskFieldChanges).length > 0;
        const hasRelatedChanges = Object.keys(relatedFieldChanges).length > 0;

        console.debug('[dmtProductSanctionFields] save start', JSON.stringify({
            changedKeys,
            riskFieldKeys: Object.keys(riskFieldChanges),
            relatedFieldKeys: Object.keys(relatedFieldChanges)
        }));

        try {
            if (hasRiskChanges) {
                const updatePayload = { Id: this.riskId, ...riskFieldChanges };
                await updateRecord({ fields: updatePayload });
            }

            if (hasRelatedChanges) {
                const relatedPayload = {};
                if (Object.prototype.hasOwnProperty.call(relatedFieldChanges, WARRANTY_FIELD_KEY)) {
                    relatedPayload[WARRANTY_FIELD_KEY] = this._normalizeMultiValuePayload(relatedFieldChanges[WARRANTY_FIELD_KEY]);
                }
                if (Object.prototype.hasOwnProperty.call(relatedFieldChanges, CURRENCY_PROVISION_FIELD_KEY)) {
                    relatedPayload[CURRENCY_PROVISION_FIELD_KEY] = this._normalizeMultiValuePayload(relatedFieldChanges[CURRENCY_PROVISION_FIELD_KEY]);
                }

                console.debug('[dmtProductSanctionFields] related payload to Apex', JSON.stringify(relatedPayload));

                await saveRelatedSelections({
                    lineId: this.lineId,
                    riskId: this.riskId,
                    relatedValues: relatedPayload
                });
                await this._reloadRelatedSelections();
            }

            const savedRiskFields = { ...riskFieldChanges };
            this.recordData = {
                ...this.recordData,
                ...savedRiskFields
            };
            this.isEditMode = false;
            this.changedValues = {};
            this.fieldValidity = {};
            this._notifyEditModeChange();
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Changes saved successfully.',
                    variant: 'success'
                })
            );
            this.dispatchEvent(new CustomEvent('recordsaved', {
                detail: {
                    recordId: this.riskId,
                    fields: savedRiskFields
                }
            }));
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this._extractErrorMessage(error),
                    variant: 'error'
                })
            );
        } finally {
            this._setSaving(false);
            this._rebuildFields();
        }
    }

    _rebuildFields() {
        const sortedConfigs = [...(this.fieldConfigs || [])]
            .filter((cfg) => !!cfg?.fieldApiName)
            .sort((a, b) => {
                const sectionA = Number.isFinite(a.sectionOrder) ? a.sectionOrder : 999;
                const sectionB = Number.isFinite(b.sectionOrder) ? b.sectionOrder : 999;
                if (sectionA !== sectionB) {
                    return sectionA - sectionB;
                }
                const orderA = Number.isFinite(a.fieldOrder) ? a.fieldOrder : 999;
                const orderB = Number.isFinite(b.fieldOrder) ? b.fieldOrder : 999;
                return orderA - orderB;
            });

        this.fields = sortedConfigs
            .map((cfg) => this._toRendererField(cfg))
            .filter((field) => !!field);
    }

    _toRendererField(cfg) {
        const fieldKey = cfg.fieldApiName;
        const recordApiName = this._normalizeApiName(cfg.fieldApiName);
        if (!fieldKey || !recordApiName) {
            return null;
        }

        const isViewDisabled = cfg?.viewDisabled === true || cfg?.isVisible === false;
        const isEditDisabled = cfg?.editDisabled === true || cfg?.isEditable === false;
        const hiddenByRule = this._evaluateVisibilityRule(cfg?.visibilityRule);
        const isPercent = String(cfg.dataType || '').toLowerCase().trim() === 'percent';
        const hasChangedValue = Object.prototype.hasOwnProperty.call(this.changedValues, fieldKey);
        const recordValue = this._getRecordValue(fieldKey);

        const value = hasChangedValue
            ? this.changedValues[fieldKey]
            : (isPercent && this._isNumericValue(recordValue) ? Number(recordValue) * 100 : recordValue);

        const options = this._resolveOptions(cfg);
        const type = this._mapRendererType(cfg.dataType, options);
        const inputAttributes = this._resolveInputAttributes(cfg);

        return {
            id: fieldKey,
            apiName: fieldKey,
            label: cfg.displayLabel || cfg.fieldLabel || recordApiName,
            type,
            isPercent,
            percentFractionDigits: inputAttributes.fractionDigits,
            value,
            options,
            size: cfg.fieldApiName === 'DMT_Comments__c' ? '1-of-1' : '1-of-2',
            isRequired: !!cfg.isRequired,
            helpText: cfg.helpText,
            isReadOnly: this.isSaving || !this.canEdit || isEditDisabled,
            isHidden: isViewDisabled || hiddenByRule,
            currencyCode: this.currencyCode,
            maxLength: inputAttributes.maxLength,
            placeholder: inputAttributes.placeholder,
            min: inputAttributes.min,
            max: inputAttributes.max,
            step: inputAttributes.step,
            showCharacterCounter: type === 'textarea'
        };
    }

    _evaluateVisibilityRule(rule) {
        if (!rule || typeof rule !== 'string') {
            return false;
        }

        // Rule returns true when field must be hidden.
        // Supported operators: ==, !=, >, >=, <, <=, in, not in. Supports && and ||.
        const normalizedRule = rule.trim();
        if (!normalizedRule) {
            return false;
        }

        const orGroups = normalizedRule.split(/\s*\|\|\s*/);
        return orGroups.some((group) => {
            const andConditions = group.split(/\s*&&\s*/);
            return andConditions.every((condition) => this._evaluateSingleCondition(condition));
        });
    }

    _evaluateSingleCondition(conditionRaw) {
        const condition = (conditionRaw || '').trim();
        if (!condition) {
            return false;
        }

        const inMatch = condition.match(/^([A-Za-z0-9_.]+)\s+(not\s+in|in)\s*\[(.*)\]$/i);
        if (inMatch) {
            const leftField = this._normalizeApiName(inMatch[1]);
            const operator = inMatch[2].toLowerCase().replace(/\s+/g, ' ');
            const values = (inMatch[3] || '')
                .split(',')
                .map((item) => this._normalizeLiteral(item))
                .filter((item) => item !== '');
            const leftValue = this._normalizeLiteral(this._getRecordValue(leftField));
            const includes = values.includes(leftValue);
            return operator === 'in' ? includes : !includes;
        }

        const operatorMatch = condition.match(/^([A-Za-z0-9_.]+)\s*(==|!=|>=|<=|>|<)\s*(.+)$/);
        if (!operatorMatch) {
            return false;
        }

        const leftField = this._normalizeApiName(operatorMatch[1]);
        const operator = operatorMatch[2];
        const rightRaw = operatorMatch[3];
        const leftValue = this._getRecordValue(leftField);
        const rightValue = this._parseLiteral(rightRaw);

        if (['>', '>=', '<', '<='].includes(operator)) {
            const leftNumber = Number(leftValue);
            const rightNumber = Number(rightValue);
            if (Number.isNaN(leftNumber) || Number.isNaN(rightNumber)) {
                return false;
            }
            if (operator === '>') {
                return leftNumber > rightNumber;
            }
            if (operator === '>=') {
                return leftNumber >= rightNumber;
            }
            if (operator === '<') {
                return leftNumber < rightNumber;
            }
            return leftNumber <= rightNumber;
        }

        const leftNormalized = this._normalizeLiteral(leftValue);
        const rightNormalized = this._normalizeLiteral(rightValue);
        return operator === '==' ? leftNormalized === rightNormalized : leftNormalized !== rightNormalized;
    }

    _parseLiteral(rawValue) {
        const value = (rawValue || '').trim();
        if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
            return value.substring(1, value.length - 1);
        }
        if (/^(true|false)$/i.test(value)) {
            return value.toLowerCase() === 'true';
        }
        if (/^-?\d+(\.\d+)?$/.test(value)) {
            return Number(value);
        }
        return value;
    }

    _normalizeLiteral(value) {
        if (value === null || value === undefined) {
            return '';
        }
        if (typeof value === 'boolean') {
            return value ? 'true' : 'false';
        }
        return String(value).trim();
    }

    _getRecordValue(apiName) {
        if (Object.prototype.hasOwnProperty.call(this.changedValues, apiName)) {
            return this.changedValues[apiName];
        }
        const normalizedApiName = this._normalizeApiName(apiName);
        if (Object.prototype.hasOwnProperty.call(this.changedValues, normalizedApiName)) {
            return this.changedValues[normalizedApiName];
        }
        if (Object.prototype.hasOwnProperty.call(this.recordData, apiName)) {
            return this.recordData[apiName];
        }
        if (Object.prototype.hasOwnProperty.call(this.recordData, normalizedApiName)) {
            return this.recordData[normalizedApiName];
        }
        return this.recordData[apiName];
    }

    _setSaving(value) {
        this.isSaving = !!value;
        this.dispatchEvent(new CustomEvent('savingchange', {
            detail: {
                isSaving: this.isSaving
            },
            bubbles: true,
            composed: true
        }));
    }

    _validateBeforeSave() {
        return this.fields.every((field) => {
            if (field.isHidden || field.isReadOnly) {
                return true;
            }

            const key = field.apiName || field.id;
            const candidateValue = Object.prototype.hasOwnProperty.call(this.changedValues, key)
                ? this.changedValues[key]
                : field.value;

            if (field.isRequired && this._isBlank(candidateValue)) {
                return false;
            }

            if (Object.prototype.hasOwnProperty.call(this.fieldValidity, key)) {
                return this.fieldValidity[key] !== false;
            }

            return true;
        });
    }

    _resolveOptions(cfg) {
        const isPicklistType = this._isPicklistDataType(cfg?.dataType);
        const parsedOptionsJson = this._parseOptionsJson(cfg?.optionsJson);

        if (!isPicklistType) {
            if (parsedOptionsJson !== null) {
                if (parsedOptionsJson && typeof parsedOptionsJson === 'object' && Array.isArray(parsedOptionsJson.options)) {
                    return this._normalizeOptionList(parsedOptionsJson.options);
                }
                return this._normalizeOptionList(parsedOptionsJson);
            }
            return [];
        }

        const hasTaxonomySource = typeof cfg?.taxonomyCatalog === 'string' && cfg.taxonomyCatalog.trim().length > 0;

        if (hasTaxonomySource) {
            // Taxonomy path for picklists: backend can send dependency payload in optionsJson.
            if (parsedOptionsJson !== null) {
                const parsed = parsedOptionsJson;

                // Taxonomy dependency payload.
                if (parsed && typeof parsed === 'object' &&
                    (parsed.type === 'taxonomyDependency' || parsed.optionsByValue || parsed.defaultOptions)) {
                    const controllerApi = this._normalizeApiName(cfg.dependsOnField);
                    const localControllerValue = this._normalizeLiteral(this._getRecordValue(controllerApi));
                    const payloadControllerValue = this._normalizeLiteral(parsed.controllerValue);
                    const controllerValue = localControllerValue || payloadControllerValue;
                    const dependentOptions = this._normalizeOptionList(parsed.optionsByValue?.[controllerValue]);
                    if (dependentOptions.length > 0) {
                        return dependentOptions;
                    }
                    const defaultOptions = this._normalizeOptionList(parsed.defaultOptions);
                    if (defaultOptions.length > 0) {
                        return defaultOptions;
                    }
                }

                // Custom override payload even when taxonomy exists.
                if (Array.isArray(parsed) || (parsed && typeof parsed === 'object' && Array.isArray(parsed.options))) {
                    const customOptions = this._normalizeOptionList(Array.isArray(parsed) ? parsed : parsed.options);
                    if (customOptions.length > 0) {
                        return customOptions;
                    }
                }
            }

            // Fallback taxonomy options prebuilt by backend.
            if (Array.isArray(cfg.picklistOptions) && cfg.picklistOptions.length > 0) {
                return this._normalizeOptionList(cfg.picklistOptions);
            }

            return [];
        }

        // Non-taxonomy picklist: custom JSON first, then metadata picklist options.
        if (parsedOptionsJson !== null) {
            if (parsedOptionsJson && typeof parsedOptionsJson === 'object' && Array.isArray(parsedOptionsJson.options)) {
                return this._normalizeOptionList(parsedOptionsJson.options);
            }
            return this._normalizeOptionList(parsedOptionsJson);
        }

        if (Array.isArray(cfg.picklistOptions) && cfg.picklistOptions.length > 0) {
            return this._normalizeOptionList(cfg.picklistOptions);
        }

        return [];
    }

    _isPicklistDataType(dataType) {
        const normalized = String(dataType || '').toLowerCase().trim();
        const compact = normalized.replace(/[^a-z]/g, '');
        return compact === 'picklist' || compact === 'multipicklist';
    }

    _mapRendererType(dataType, options) {
        const normalized = String(dataType || '').toLowerCase().trim();
        const compact = normalized.replace(/[^a-z]/g, '');

        if (compact.includes('textarea') || compact.includes('longtextarea') || compact.includes('richtextarea')) {
            return 'textarea';
        }

        if (compact === 'multipicklist') {
            return 'multipicklist';
        }

        if (Array.isArray(options) && options.length > 0) {
            return 'picklist';
        }

        switch (normalized) {
            case 'boolean':
            case 'checkbox':
                return 'checkbox';
            case 'currency':
                return 'currency';
            case 'double':
            case 'integer':
            case 'percent':
            case 'number':
                return 'number';
            case 'date':
                return 'date';
            case 'datetime':
                return 'datetime';
            case 'picklist':
            case 'multipicklist':
                return 'picklist';
            case 'textarea':
            case 'longtextarea':
                return 'textarea';
            case 'email':
                return 'email';
            case 'phone':
                return 'phone';
            case 'url':
                return 'url';
            default:
                return 'text';
        }
    }

    _normalizeOptionList(rawOptions) {
        if (Array.isArray(rawOptions)) {
            return rawOptions
                .map((opt) => {
                    if (opt && typeof opt === 'object') {
                        const value = opt.value ?? opt.label;
                        const label = opt.label ?? opt.value;
                        if (value === undefined || value === null || label === undefined || label === null) {
                            return null;
                        }
                        return {
                            label: String(label),
                            value: String(value)
                        };
                    }

                    if (opt === undefined || opt === null) {
                        return null;
                    }

                    return {
                        label: String(opt),
                        value: String(opt)
                    };
                })
                .filter((opt) => !!opt);
        }

        if (rawOptions && typeof rawOptions === 'object') {
            if (Array.isArray(rawOptions.options)) {
                return this._normalizeOptionList(rawOptions.options);
            }

            return Object.keys(rawOptions).map((key) => ({
                label: String(rawOptions[key]),
                value: String(key)
            }));
        }

        return [];
    }

    _flattenRecord(record) {
        const flat = {};
        Object.keys(record?.fields || {}).forEach((fieldApiName) => {
            flat[fieldApiName] = record.fields[fieldApiName]?.value;
        });
        return flat;
    }

    _normalizeApiName(qualifiedName) {
        if (!qualifiedName) {
            return null;
        }
        const parts = qualifiedName.split('.');
        return parts[parts.length - 1];
    }

    _extractErrorMessage(error) {
        if (error?.body?.output?.errors?.length) {
            return error.body.output.errors.map((e) => e.message).join(', ');
        }
        if (error?.body?.message) {
            return error.body.message;
        }
        return 'Unknown error while saving changes.';
    }

    _isNumericValue(value) {
        return value !== null && value !== undefined && value !== '' && Number.isFinite(Number(value));
    }

    _toStoredPercent(value) {
        if (!this._isNumericValue(value)) {
            return value;
        }
        return (Number(value) / 100).toFixed(6);
    }

    _isBlank(value) {
        if (Array.isArray(value)) {
            return value.length === 0;
        }
        return value === null || value === undefined || value === '';
    }

    async _loadRelatedSelections() {
        if (!this.riskId) {
            return;
        }

        const hasRelatedConfigs = (this.fieldConfigs || []).some((cfg) => this._isRelatedField(cfg?.fieldApiName));
        if (!hasRelatedConfigs) {
            return;
        }

        const currentToken = ++this._relatedLoadToken;
        try {
            await this._reloadRelatedSelections(currentToken);
        } catch (error) {
            // Ignore load failures for related helper fields to avoid blocking base form.
        }
    }

    async _reloadRelatedSelections(expectedToken) {
        const selections = await getRelatedSelections({ riskId: this.riskId });
        if (expectedToken && expectedToken !== this._relatedLoadToken) {
            return;
        }

        this.recordData = {
            ...this.recordData,
            [WARRANTY_FIELD_KEY]: this._normalizeMultiValuePayload(selections?.[WARRANTY_FIELD_KEY]),
            [CURRENCY_PROVISION_FIELD_KEY]: this._normalizeMultiValuePayload(selections?.[CURRENCY_PROVISION_FIELD_KEY])
        };
        this._rebuildFields();
    }

    _isRelatedField(fieldApiName) {
        return fieldApiName === WARRANTY_FIELD_KEY || fieldApiName === CURRENCY_PROVISION_FIELD_KEY;
    }

    _notifyEditModeChange() {
        this.dispatchEvent(new CustomEvent('editmodechange', {
            detail: {
                isEditMode: this.isEditMode
            },
            bubbles: true,
            composed: true
        }));
    }

    _normalizeMultiValuePayload(rawValue) {
        if (Array.isArray(rawValue)) {
            return rawValue
                .map((item) => (item === null || item === undefined ? '' : String(item).trim()))
                .filter((item) => item.length > 0);
        }
        if (rawValue === null || rawValue === undefined) {
            return [];
        }
        const candidate = String(rawValue).trim();
        if (!candidate) {
            return [];
        }
        return candidate.split(';').map((item) => item.trim()).filter((item) => item.length > 0);
    }

    _parseOptionsJson(optionsJson) {
        if (typeof optionsJson !== 'string' || optionsJson.trim().length === 0) {
            return null;
        }
        try {
            return JSON.parse(optionsJson);
        } catch (e) {
            return null;
        }
    }

    _resolveInputAttributes(cfg) {
        const normalizedDataType = String(cfg?.dataType || '').toLowerCase().trim();
        const isPercent = normalizedDataType === 'percent';
        const parsed = this._parseOptionsJson(cfg?.optionsJson);
        const attrs = parsed && typeof parsed === 'object'
            ? (parsed.inputAttributes || parsed.attributes || parsed.ui || null)
            : null;

        if (!attrs || typeof attrs !== 'object') {
            return {
                maxLength: null,
                placeholder: null,
                min: isPercent ? 0 : null,
                max: isPercent ? 100 : null,
                step: isPercent ? 0.000001 : null,
                fractionDigits: isPercent ? 6 : null
            };
        }

        const toNumberOrNull = (value) => {
            if (value === null || value === undefined || value === '') {
                return null;
            }
            const parsedNumber = Number(value);
            return Number.isNaN(parsedNumber) ? null : parsedNumber;
        };

        const maxLengthValue = toNumberOrNull(attrs.maxLength);
        const min = toNumberOrNull(attrs.min);
        const max = toNumberOrNull(attrs.max);
        const step = toNumberOrNull(attrs.step);
        const fractionDigits = step && step > 0
            ? Math.max(0, String(step).replace(/0+$/, '').split('.')[1]?.length || 0)
            : (isPercent ? 2 : null);

        return {
            maxLength: maxLengthValue,
            placeholder: attrs.placeholder ? String(attrs.placeholder) : null,
            min: min === null && isPercent ? 0 : min,
            max: max === null && isPercent ? 100 : max,
            step: step === null && isPercent ? 0.000001 : step,
            fractionDigits: fractionDigits === null && isPercent ? 6 : fractionDigits
        };
    }
}