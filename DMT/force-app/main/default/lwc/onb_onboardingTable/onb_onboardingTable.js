import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { createRecord, updateRecord, deleteRecord } from 'lightning/uiRecordApi';

import cloneFundWithLines from '@salesforce/apex/ONB_FundItemController.cloneFundWithLines';

import ONB_LEI_20_CHAR from '@salesforce/label/c.ONB_LEI_20_CHAR';

export default class Onb_onboardingTable extends LightningElement {
    @api lineType;
    @api title;
    @api iconName;

    @api toggleText;
    @api toggleFieldApiName;
    @api cellDisabledWhen;

    @api showFundsToolbar = false;
    @api fundFinalListLabel = 'Is the list of funds the final list?';
    @api fundFinalListValue = 'No';

    @api connectAllFundsToggleLabel = 'Connect all spot FX and bond products to all funds';
    @api connectAllFundsHelpText = 'If you enable this option, all FX spot and Bonds created in the previous step will be automatically linked to all funds.';
    @api connectAllFundsToggleValue = false;

    fundFinalListOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

    @api objectApiName;
    @api recordTypeId;
    @api columns = [];
    @api parentFieldApiName;
    @api rowReadOnlyWhen;
    @api defaultValues = {};

    @api picklistAllowedValuesByField = {};
    @api lineTypeSubtypeMaxRules = [];
    @api restrictProductCategoryForNoMasterAgreement = false;
    @api clientId;

    connectLabelFieldName = 'connectLabel';

    // UI flags
    @api showAdd = false;
    @api showAddAux = false;
    @api showDelete = false;
    @api showClone = false;
    @api showConnect = false;
    @api showAuxButton = false;
    @api showSave = false;
    @api addLabel;
    @api addLabelAux;
    @api emptyStateMessage;
    @api disableAdd = false;
    @api actionsColumnPosition = 'start';
    @api actionsColumnLabel = '';
    @api connectTooltipText;

    @api createRecordOnAdd = false;

    //Required fields
    @api requiredFieldApiNames = []; // ej: ['Booking_Entity__c','Product_Category__c','Product2Id__c']
    @api conditionalRequiredRules = [];

    @api productOptionsByRowId = {};
    @api contractTypeOptionsByRowId = {};

    rows = [];
    deletedRecordIds = new Set();
    objectInfo;

    // Picklists
    picklistOptionsByField = {};
    recordTypePicklistBundle;

    _initialRows = [];
    _hasUserInteracted = false;
    _recordId;

    //Modal
    //Nombre del lwc que se va a abrir en el modal manager
    @api modalComponentName;
    @api modalButtonLabel;

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        this._hasUserInteracted = false;
    }

    @api
    get initialRows() {
        return this._initialRows;
    }

    set initialRows(value) {
        this._initialRows = Array.isArray(value) ? value : [];

        this.rows = this._initialRows.map((r, idx) => ({
            ...r,
            _key: r._key || r.Id || crypto.randomUUID(),
            rowIndex: idx
        }));
    }

    get addLabelEffective() {
        return this.addLabel || 'Add';
    }

    get addLabelEffectiveAux() {
        return this.addLabelAux || 'Add';
    }

    get hasButtons() {
        return this.showDelete || this.showClone || this.showConnect || this.showAuxButton;
    }

    get showActionsColumnAtStart() {
        return this.hasButtons && this.actionsColumnPosition !== 'end';
    }

    get showActionsColumnAtEnd() {
        return this.hasButtons && this.actionsColumnPosition === 'end';
    }

    get hasConnectTooltip() {
        return this.connectTooltipText && this.connectTooltipText.trim().length > 0;
    }

    getDisabledFieldsToClear(row) {
        if (typeof this.cellDisabledWhen !== 'function') {
            return [];
        }

        return (this.columns || [])
            .filter(col => {
                try {
                    return !!this.cellDisabledWhen(row, col) && !!row?.[col.fieldName];
                } catch (e) {
                    console.error('getDisabledFieldsToClear', e);
                    return false;
                }
            })
            .map(col => col.fieldName);
    }

    /* ---------------- Object Info ---------------- */
    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    wiredObjectInfo({ data, error }) {
        if (data) {
            this.objectInfo = data;
        } else if (error) {
            console.error('Error in getObjectInfo', JSON.stringify(error));
        }
    }

    get effectiveRecordTypeId() {
        return this.recordTypeId || this.objectInfo?.defaultRecordTypeId;
    }

    /* ---------------- Picklists ---------------- */
    @wire(getPicklistValuesByRecordType, {
        objectApiName: '$objectApiName',
        recordTypeId: '$effectiveRecordTypeId'
    })
    wiredPicklists({ data, error }) {
        if (error) {
            console.error('getPicklistValuesByRecordType error:', JSON.stringify(error));
            return;
        }
        if (!data) return;

        this.recordTypePicklistBundle = data.picklistFieldValues;

        const map = {};
        const fieldNames = new Set((this.columns || []).map(c => c.fieldName));

        fieldNames.forEach(fieldName => {
            const fd = data.picklistFieldValues?.[fieldName];
            if (fd?.values) {
                map[fieldName] = fd.values.map(v => ({ label: v.label, value: v.value }));
            }
        });

        this.picklistOptionsByField = map;
    }

    /* ---------------- Validation helpers ---------------- */
    isFieldRequired(fieldName) {
        return Array.isArray(this.requiredFieldApiNames) && this.requiredFieldApiNames.includes(fieldName);
    }

    isRowReadOnly(row) {
        try {
            return typeof this.rowReadOnlyWhen === 'function'
                ? !!this.rowReadOnlyWhen(row)
                : false;
        } catch (e) {
            console.error('rowReadOnlyWhen error', e);
            return false;
        }
    }

    getMissingRequiredForRow(row) {
        // Required estáticos
        const baseRequired = Array.isArray(this.requiredFieldApiNames)
            ? this.requiredFieldApiNames
            : [];

        // Set para no duplicar campos
        const required = new Set(baseRequired);

        // Required condicionales
        (this.conditionalRequiredRules || []).forEach(rule => {
            try {
                if (typeof rule.when === 'function' && rule.when(row)) {
                    (rule.requiredFields || []).forEach(f => required.add(f));
                }
            } catch (e) {
                console.error('getMissingRequiredForRow', e);
            }
        });

        return [...required].filter(field => !row?.[field]);
    }

    isFieldConditionallyRequired(fieldName, row) {
        return (this.conditionalRequiredRules || []).some(rule => {
            try {
                const applies = typeof rule.when === 'function' ? rule.when(row) : false;
                return applies && (rule.requiredFields || []).includes(fieldName);
            } catch (e) {
                console.error('isFieldConditionallyRequired', e);
                return false;
            }
        });
    }

    isFieldRequiredForRow(fieldName, row) {
        const base = Array.isArray(this.requiredFieldApiNames)
            ? this.requiredFieldApiNames.includes(fieldName)
            : false;
        const conditional = (this.conditionalRequiredRules || []).some(rule => {
            try {
                return typeof rule.when === 'function'
                && rule.when(row)
                && (rule.requiredFields || []).includes(fieldName);
            } catch (e) {
            return false;
            }
        });

        return base || conditional;
    }

    getColumnByField(fieldName) {
        return (this.columns || []).find(c => c.fieldName === fieldName);
    }

    _picklistActive = false;
    _picklistDebounceTimer = null;

    get needsBottomPadding() {
        return this.columns?.some(col =>
            ['picklist', 'dependentPicklist', 'lookup', 'multipicklist'].includes(col.type)
        );
    }

    get tableScrollClass() {
        return `table-scroll ${(this.needsBottomPadding && this._picklistActive) ? 'table-scroll--with-padding' : ''}`;
    }

    handlePicklistFocusIn() {
        if (!this.needsBottomPadding) return;
        clearTimeout(this._picklistDebounceTimer);
        this._picklistActive = true;
    }

    handlePicklistFocusOut() {
        if (!this.needsBottomPadding) return;
        this._picklistDebounceTimer = setTimeout(() => {
            this._picklistActive = false;
        }, 200);
    }

    patchRow(rowIndex, patch) {
        const updated = [...this.rows];
        updated[rowIndex] = { ...updated[rowIndex], ...patch };
        this.rows = updated;
    }

    get hasRows() {
        return Array.isArray(this.rowsForRender) && this.rowsForRender.length > 0;
    }

    get hasToggleText() {
        return !!this.toggleText;
    }

    get hasTopToolbar() {
        return this.showFundsToolbar || this.hasToggleText || this.showAdd || !!this.modalComponentName || this.showAddAux;
    }

    getPicklistOptionsForRow(fieldName, row) {
        const baseOptions = this.picklistOptionsByField?.[fieldName] || [];
        const allowedValues = this.picklistAllowedValuesByField?.[fieldName];

        if (!Array.isArray(allowedValues) || !allowedValues.length) {
            return baseOptions;
        }

        const allowedSet = new Set(allowedValues);

        return baseOptions.filter(opt =>
            allowedSet.has(opt.value) || opt.value === row?.[fieldName]
        );
    }

    filterProductCategoryOptions(options, row, col) {
        if (
            !this.restrictProductCategoryForNoMasterAgreement ||
            this.objectApiName !== 'ONB_Onboarding_Line__c' ||
            col?.fieldName !== 'Product_Category__c'
        ) {
            return options;
        }

        const allowedValues = new Set(['FX', 'Fixed Income & Rates']);

        return (options || []).filter(opt =>
            allowedValues.has(opt.value) || opt.value === row?.[col.fieldName]
        );
    }

    getCellTypeFlags(col) {
        return {
            isPicklist: col.type === 'picklist',
            isDependentPicklist: col.type === 'dependentPicklist',
            isMultipicklist: col.type === 'multipicklist',
            isLookup: col.type === 'lookup',
            isTextarea: col.type === 'textarea',
            isBoolean: col.type === 'boolean',
            isEmail: col.type === 'email',
            isNumber: col.type === 'number',
            isDate: col.type === 'date',
            isToggle: col.type === 'toggle',
            isBadge: col.type === 'badge',
            isIcon: col.type === 'icon'
        };
    }

    getOptionsByCellType(row, rowIndex, col, flags) {
        const {
            isPicklist,
            isDependentPicklist,
            isMultipicklist
        } = flags;

        let options = [];

        if (isPicklist) {
            options = this.getPicklistOptionsForRow(col.fieldName, row);
            options = this.applyLineTypeMaxRowsFilter(options, row, col, isPicklist);
        }

        if (isMultipicklist) {
            if (col.controllerFieldName) {
                options = this.getDependentOptionsForRow(row, col);
            } else {
                options = this.picklistOptionsByField?.[col.fieldName] || [];
            }
        }

        if (isDependentPicklist) {
            if (col.fieldName === 'Product2Id__c' && col.controllerFieldName === 'Product_Category__c') {
                const rowKey = row?._key || row?.Id || `${rowIndex}`;
                options = this.productOptionsByRowId?.[rowKey] || [];
            } else if (col.fieldName === 'master_agreement_type__c') {
                const metadataDependentOptions = this.getDependentOptionsForRow(row, col);
                const rowKey = row?._key || row?.Id || `${rowIndex}`;
                const allowedByMetadata = this.contractTypeOptionsByRowId?.[rowKey] || [];
                options = this.intersectOptions(metadataDependentOptions, allowedByMetadata, row?.[col.fieldName]);
            } else {
                options = this.getDependentOptionsForRow(row, col);
            }
        }

        options = this.applySettlementSubtypeUniqueFilter(options, row, col);
        options = this.applyLineSubtypeMaxRules(options, row, col, isDependentPicklist);

        return options;
    }

    intersectOptions(baseOptions, allowedOptions, selectedValue) {
        const base = Array.isArray(baseOptions) ? baseOptions : [];
        const allowed = Array.isArray(allowedOptions) ? allowedOptions : [];

        if (!allowed.length) {
            return base;
        }

        const allowedSet = new Set(allowed.map(opt => opt.value));

        if (!base.length) {
            return allowed.filter(opt => allowedSet.has(opt.value) || opt.value === selectedValue);
        }

        return base.filter(opt => allowedSet.has(opt.value) || opt.value === selectedValue);
    }

    applyLineTypeMaxRowsFilter(options, row, col, isPicklist) {
        if (
            this.objectApiName !== 'ONB_Line__c' ||
            !isPicklist ||
            col.fieldName !== 'Line_Type__c'
        ) {
            return options;
        }

        const parentId = row?.[this.parentFieldApiName] || this.recordId;
        const maxRowsByType = this.getMaxRowsByType();
        const rowCountByType = this.getRowCountByType(parentId);
        const currentRowType = row?.Line_Type__c;

        return (options || []).filter(opt => {
            const typeValue = opt.value;

            if (typeValue === currentRowType) {
                return true;
            }
            const maxRows = maxRowsByType[typeValue];

            if (!maxRows || maxRows <= 0) {
                return true;
            }
            const currentCount = rowCountByType[typeValue] || 0;
            return currentCount < maxRows;
        });
    }

    applySettlementSubtypeUniqueFilter(options, row, col) {
        if (
            this.objectApiName !== 'ONB_Line__c' ||
            col.fieldName !== 'ONB_Line_Subtype__c' ||
            !['LC_DVP', 'LC_REPOS'].includes(this.lineType)
        ) {
            return options;
        }

        const usedSubtypes = new Set(
            (this.rows || [])
                .map(r => r.ONB_Line_Subtype__c)
                .filter(v => !!v)
        );

        return (options || []).filter(
            opt => opt.value === row?.[col.fieldName] || !usedSubtypes.has(opt.value)
        );
    }

    applyLineSubtypeMaxRules(options, row, col, isDependentPicklist) {
        if (
            this.objectApiName !== 'ONB_Line__c' ||
            !isDependentPicklist ||
            col.fieldName !== 'ONB_Line_Subtype__c' ||
            col.controllerFieldName !== 'Line_Type__c'
        ) {
            return options;
        }

        const rules = Array.isArray(this.lineTypeSubtypeMaxRules) ? this.lineTypeSubtypeMaxRules : [];
        if (!rules.length) {
            return options;
        }

        const fundId = row?.[this.parentFieldApiName] || this.recordId;
        const typeValue = row?.Line_Type__c;

        const counts = new Map();
        (this.rows || []).forEach(r => {
            const fId = r?.[this.parentFieldApiName] || this.recordId;
            if (!fId) return;

            const t = r?.Line_Type__c;
            const s = r?.ONB_Line_Subtype__c;
            if (!t || !s) return;

            const key = `${fId}||${t}||${s}`;
            counts.set(key, (counts.get(key) || 0) + 1);
        });

        return (options || []).filter(opt => {
            if (row?.ONB_Line_Subtype__c && opt.value === row.ONB_Line_Subtype__c) {
                return true;
            }

            const rule = rules.find(rr => rr.typeValue === typeValue && rr.subtypeValue === opt.value);
            if (!rule) return true;

            const key = `${fundId}||${typeValue}||${opt.value}`;
            const existing = counts.get(key) || 0;
            return existing < (rule.max ?? 1);
        });
    }

    buildCellRenderModel(row, rowIndex, rowKey, rowReadOnly, col, colIndex) {
        let disabled = typeof this.cellDisabledWhen === 'function' ? !!this.cellDisabledWhen(row, col) : false;
        const flags = this.getCellTypeFlags(col);
        const options = this.getOptionsByCellType(row, rowIndex, col, flags);

        const hasNoOptions = Array.isArray(options) && options.length === 0;
        if ((flags.isPicklist || flags.isDependentPicklist || flags.isMultipicklist) && hasNoOptions) {
            disabled = true;
        }

        const required = this.isFieldRequiredForRow(col.fieldName, row);
        const hasError = required && !row?.[col.fieldName];
        const columnKey = col.key || col.fieldName || `col-${colIndex}`;

        let badgeText = '';
        let badgeClass = '';
        if (flags.isBadge) {
            const originValue = row[col.fieldName];
            if (originValue === 'Existing') {
                badgeText = 'Existing contract';
                badgeClass = 'slds-badge';
            } else {
                badgeText = 'New contract';
                badgeClass = 'slds-badge slds-theme_info';
            }
        }
        return {
            key: `${rowKey}-${columnKey}`,
            fieldName: col.fieldName,
            value: row[col.fieldName] ?? '',
            label: col.label,
            readOnly: disabled || rowReadOnly,
            required,
            missingMessage: required ? 'Complete this field.' : '',
            iconName: row[col.fieldName] || '',
            iconTooltip: row[col.tooltipFieldName || `${col.fieldName}Tooltip`] || '',

            ...flags,

            badgeText: badgeText,
            badgeClass: badgeClass,
            maxLength: col.maxLength,
            options,
            lookupObjectApiName: col.lookupObjectApiName,
            placeholder: col.placeholder,
            lookupFilter: col.lookupFilter,

            tdClass: flags.isBoolean ? 'td-boolean' : '',
            controlClass: (hasError ? 'cell-control cell-error' : 'cell-control') + (flags.isBoolean ? ' cell-control-boolean' : '') + (flags.isBadge ? ' cell-control-badge' : '') + (flags.isIcon ? ' cell-control-icon' : '')
        };
    }

    buildRowRenderModel(row, rowIndex) {
        const connectLabelField = this.connectLabelFieldName;
        const connectLabel = row?.[connectLabelField] ?? '';
        const missingRequired = this.getMissingRequiredForRow(row);
        const rowKey = row._key || row.Id || `${rowIndex}`;
        const rowReadOnly = this.isRowReadOnly(row);
        const disableClone =
            this.objectApiName === 'ONB_Line__c' &&
            ['LC_DVP', 'LC_REPOS'].includes(row?.Line_Type__c);

        return {
            key: rowKey,
            rowIndex,
            rowClass: missingRequired.length ? 'row-has-errors' : '',
            connectLabel,
            rowReadOnly,
            disableClone,
            cells: (this.columns || []).map((col, colIndex) =>
                this.buildCellRenderModel(row, rowIndex, rowKey, rowReadOnly, col, colIndex)
            )
        };
    }

    /* ---------------- Render model ---------------- */
    get rowsForRender() {
        return (this.rows || []).map((row, rowIndex) => this.buildRowRenderModel(row, rowIndex));
    }

    clearNoLongerRequiredValidity(rowIndex, prevRow, nextRow) {
        const cols = Array.isArray(this.columns) ? this.columns : [];
        cols.forEach(col => {
            const fieldName = col.fieldName;
            const wasRequired = this.isFieldRequiredForRow(fieldName, prevRow);
            const isRequiredNow = this.isFieldRequiredForRow(fieldName, nextRow);

            if (wasRequired && !isRequiredNow) {
                requestAnimationFrame(() => {
                    this.clearCellValidity(rowIndex, fieldName);
                });
            }
        });
    }

    clearCellValidity(rowIndex, fieldName) {
       const selector = `lightning-input[data-row-index="${rowIndex}"][data-field="${fieldName}"],
                      lightning-textarea[data-row-index="${rowIndex}"][data-field="${fieldName}"],
                      lightning-combobox[data-row-index="${rowIndex}"][data-field="${fieldName}"],
                      lightning-record-picker[data-row-index="${rowIndex}"][data-field="${fieldName}"]`;

        const el = this.template.querySelector(selector);
        if (!el) return;

        if (typeof el.setCustomValidity === 'function') {
            el.setCustomValidity('');
        }

        if (typeof el.reportValidity === 'function') {
            el.reportValidity();
        }
    }

    getDependentOptionsForRow(row, col) {
        const bundle = this.recordTypePicklistBundle?.[col.fieldName];
        if (!bundle) return [];

        const controllerValue = row?.[col.controllerFieldName];
        if (!controllerValue) return [];

        const controllerKey = bundle.controllerValues?.[controllerValue];
        if (controllerKey === undefined) return [];

        let options = (bundle.values || [])
            .filter(v => (v.validFor || []).includes(controllerKey))
            .map(v => ({ label: v.label, value: v.value }));

        options = this.filterProductCategoryOptions(options, row, col);

        return options;
    }

    getMaxRowsByType() {
        const result = {};

        const typeField = 'Line_Type__c';
        const subtypeField = 'ONB_Line_Subtype__c';

        const typeMeta = this.recordTypePicklistBundle?.[typeField];
        const subtypeMeta = this.recordTypePicklistBundle?.[subtypeField];

        if (!typeMeta || !subtypeMeta) return result;

        const controllerValues = subtypeMeta.controllerValues || {};
        const subtypeValues = subtypeMeta.values || [];
        const typeValues = typeMeta.values || [];

        typeValues.forEach(typeOption => {
            const typeValue = typeOption.value;
            const controllerIndex = controllerValues[typeValue];

            if (controllerIndex === undefined) {
                result[typeValue] = 0;
                return;
            }

            const allowedSubtypes = subtypeValues.filter(sub =>
                Array.isArray(sub.validFor) && sub.validFor.includes(controllerIndex)
            );

            result[typeValue] = allowedSubtypes.length;
        });

        return result;
    }

    getRowCountByType(parentIdToMatch = null) {
        const counts = {};

        (this.rows || []).forEach(row => {
            const type = row?.Line_Type__c;
            if (!type) return;

            // Si estamos en líneas de fondo, contamos por fondo
            if (parentIdToMatch && this.parentFieldApiName) {
                const rowParentId = row?.[this.parentFieldApiName] || this.recordId;
                if (rowParentId !== parentIdToMatch) return;
            }

            counts[type] = (counts[type] || 0) + 1;
        });

        return counts;
    }

    async handleAddRow() {
        if (this.disableAdd) {
            return;
        }

        this._hasUserInteracted = true;

        const tempKey = crypto.randomUUID();
        const newRow = {
            _key: tempKey,
            ...(this.defaultValues || {})
        };

        if (this.parentFieldApiName && this.recordId) {
            newRow[this.parentFieldApiName] = this.recordId;
        }
        if (this.lineType) {
            newRow.Line_Type__c = this.lineType;
            newRow.AccountId__c = this.clientId;
        }

        this.rows = [...this.rows, newRow];

        requestAnimationFrame(() => {
            this.validate();
        });

        if (!this.createRecordOnAdd) return;

        try {
            const fields = { ...(this.defaultValues || {}) };

            if (this.parentFieldApiName && this.recordId) {
                fields[this.parentFieldApiName] = this.recordId;
            }
            if (this.lineType) {
                fields.Line_Type__c = this.lineType;
                fields.AccountId__c = this.clientId;
            }

            const result = await createRecord({
                apiName: this.objectApiName,
                fields
            });

            this.rows = (this.rows || []).map(r => (
                r._key === tempKey ? { ...r, Id: result.id } : r
            ));

            this.dispatchEvent(new CustomEvent('rowcreated', {
                detail: { id: result.id },
                bubbles: true,
                composed: true
            }));

            requestAnimationFrame(() => {
                this.validate();
            });
        } catch (e) {
            console.error('Error creating row (raw):', e);
            console.error('Error creating row (json):', JSON.stringify(e));
            console.error('Error body:', JSON.stringify(e?.body));
            this.rows = (this.rows || []).filter(r => r._key !== tempKey);
            console.error('Error creating row', JSON.stringify(e));
        }
    }

    async handleDeleteRow(event) {
        this._hasUserInteracted = true;
        const idx = Number(event.currentTarget.dataset.rowIndex);
        const row = this.rows?.[idx];
        if (!row) return;

        try {
            if (row?.Id && !this.isRowReadOnly(row)) {
                // Delete the record created by the new row
                await deleteRecord(row.Id);
                this.dispatchEvent(new CustomEvent('rowdeleted', {
                    detail: { id: row.Id, rowIndex: idx },
                    bubbles: true,
                    composed: true
                }));
            } else {
                // Delete only the relation between the parent and the new row, not the record
                await this.updateRowServer(idx, this.parentFieldApiName);
                this.dispatchEvent(new CustomEvent('rowunlink', {
                    detail: { row, id: row?.Id, rowIndex: idx },
                    bubbles: true,
                    composed: true
                }));
            }

            this.rows = (this.rows || []).filter((_, i) => i !== idx);
        } catch (e) {
            console.error('Error deleting row', e);
        }
    }


    async handleAddRowAux() {
        this.dispatchEvent(
            new CustomEvent('addexistingcontract', {
                bubbles: true,
                composed: true
            })
        );
    }

    async handleCloneRow(event) {
        this._hasUserInteracted = true;

        const idx = Number(event.currentTarget.dataset.rowIndex);
        const sourceRow = this.rows?.[idx];
        if (!sourceRow) return;

        if (this.objectApiName === 'ONB_Fund_Item__c' && sourceRow?.Id) {
            try {
                const res = await cloneFundWithLines({ fundId: sourceRow.Id });

                this.dispatchEvent(new CustomEvent('rowcreated', {
                    detail: { id: res?.newFundId, clonedLines: res?.clonedLines, sourceId: sourceRow.Id },
                    bubbles: true,
                    composed: true
                }));

                return;
            } catch (e) {
                console.error('Error cloning fund with lines (raw):', e);
                console.error('Error cloning fund with lines (json):', JSON.stringify(e));
                console.error('Error body:', JSON.stringify(e?.body));
                return;
            }
        }

        const fields = {};
        (this.columns || []).forEach(col => {
            const apiName = col.fieldName;
            if (!apiName) return;

            const value = sourceRow[apiName];
            if (value !== undefined) {
                fields[apiName] = value;
            }
        });

        if (this.parentFieldApiName && this.recordId) {
            fields[this.parentFieldApiName] = this.recordId;
        }

        const tempKey = crypto.randomUUID();
        const optimisticRow = {
            ...sourceRow,
            Id: undefined,
            _key: tempKey
        };

        const updated = [...(this.rows || [])];
        updated.splice(idx + 1, 0, optimisticRow);
        this.rows = updated;

        try {
            const result = await createRecord({
                apiName: this.objectApiName,
                fields
            });

            this.rows = (this.rows || []).map(r =>
                r._key === tempKey ? { ...r, Id: result.id } : r
            );

            this.dispatchEvent(new CustomEvent('rowcreated', {
                detail: { id: result.id },
                bubbles: true,
                composed: true
            }));

            requestAnimationFrame(() => {
                this.validate();
            });

        } catch (e) {
            console.error('Error cloning row (raw):', e);
            console.error('Error cloning row (json):', JSON.stringify(e));
            console.error('Error body:', JSON.stringify(e?.body));

            this.rows = (this.rows || []).filter(r => r._key !== tempKey);
        }
    }

    async handleConnectRow(event) {
        this._hasUserInteracted = true;

        const idx = Number(event.currentTarget.dataset.rowIndex);
        const row = this.rows?.[idx];
        if (!row) return;

        this.dispatchEvent(new CustomEvent('rowconnect', {
            detail: {
            rowIndex: idx,
            row
            },
            bubbles: true,
            composed: true
        }));
    }

    async handleAuxButtonRow(event) {
        this._hasUserInteracted = true;

        const idx = Number(event.currentTarget.dataset.rowIndex);
        const row = this.rows?.[idx];
        if (!row) return;

        this.dispatchEvent(new CustomEvent('auxbuttonrow', {
            detail: {
            rowIndex: idx,
            row
            },
            bubbles: true,
            composed: true
        }));
    }

    handleFundFinalListChange(event) {
        this.fundFinalListValue = event.detail.value;

        this.dispatchEvent(new CustomEvent('fundfinallistchange', {
            detail: {
                value: this.fundFinalListValue
            },
            bubbles: true,
            composed: true
        }));
    }

    handleConnectAllFundsToggleChange(event) {
        this.connectAllFundsToggleValue = event.target.checked;

        this.dispatchEvent(new CustomEvent('connectallfundstogglechange', {
            detail: {
                value: this.connectAllFundsToggleValue
            },
            bubbles: true,
            composed: true
        }));
    }


    /* ---------------- Auto-save (update per change) ---------------- */
    async updateRowServer(rowIndex, changedField) {
        const row = this.rows?.[rowIndex];
        if (!row?.Id) return;

        const fields = { Id: row.Id };
        fields[changedField] = row[changedField] ?? null;

        if (changedField === this.parentFieldApiName && this.parentFieldApiName) {
            fields[this.parentFieldApiName] = row[this.parentFieldApiName] ?? null;
        }

        try {
            await updateRecord({ fields });
        } catch (e) {
            console.error('Error updating row', JSON.stringify(e));
        }
    }

    @api
    async setCellValue(rowIndex, fieldName, value) {
        const updated = [...this.rows];
        const prevRow = this.rows?.[rowIndex] ? { ...this.rows[rowIndex] } : {};
        updated[rowIndex] = { ...updated[rowIndex], [fieldName]: value };
        this.rows = updated;

        this.clearNoLongerRequiredValidity(rowIndex, prevRow, this.rows[rowIndex]);
        await this.updateRowServer(rowIndex, fieldName);
    }

    async handleCellChange(event) {
        this._hasUserInteracted = true;
        this.clearComponentValidity(event.target);

        const rowIndex = Number(event.currentTarget.dataset.rowIndex);
        const field = event.currentTarget.dataset.field;

        if (field === 'lei_id__c') {
            const value = event.detail?.value ?? event.target?.value ?? '';
            if (!value || value.trim().length === 20) {
                this.clearComponentValidity(event.target);
            }
        }
        const target = event.target;
        const isCheckbox = target?.type === 'checkbox';
        const value = isCheckbox
            ? target.checked
            : (event.detail?.value ?? target.value ?? null);

        const prevRow = this.rows?.[rowIndex] ? { ...this.rows[rowIndex] } : {};

        const updated = [...this.rows];
        updated[rowIndex] = { ...updated[rowIndex], [field]: value };

        const dependentCols = (this.columns || []).filter(
            (c) => (c.type === 'dependentPicklist' || c.type === 'multipicklist') && c.controllerFieldName === field
        );

        dependentCols.forEach((dc) => {
            updated[rowIndex][dc.fieldName] = (dc.type === 'multipicklist') ? '' : null;
        });

        const nextRow = updated[rowIndex];
        const fieldsCleared = this.getDisabledFieldsToClear(nextRow);

        fieldsCleared.forEach((fieldName) => {
            nextRow[fieldName] = null;
        });

        this.rows = updated;
        this.clearNoLongerRequiredValidity(rowIndex, prevRow, this.rows[rowIndex]);

        const rowId = this.rows?.[rowIndex]?.Id;
        const rowKey = this.rows?.[rowIndex]?._key || rowId || `idx-${rowIndex}`;

        if (field === 'Booking_Entity__c') {
            this.dispatchEvent(
                new CustomEvent('bookingentitychange', {
                    detail: {
                        rowIndex,
                        rowId,
                        rowKey,
                        fieldName: field,
                        bookingEntity: value
                    },
                    bubbles: true,
                    composed: true
                })
            );
        }

        if (field === 'Product_Category__c') {
            this.dispatchEvent(
                new CustomEvent('productcategorychange', {
                    detail: {
                        rowIndex,
                        rowId,
                        rowKey,
                        fieldName: field,
                        productCategory: value
                    },
                    bubbles: true,
                    composed: true
                })
            );
        }

        await this.updateRowServer(rowIndex, field);

        for (const dc of dependentCols) {
            await this.updateRowServer(rowIndex, dc.fieldName);
        }

        for (const fc of fieldsCleared) {
            await this.updateRowServer(rowIndex, fc);
        }

        if (field === 'Product2Id__c') {
            this.dispatchEvent(
                new CustomEvent('productchange', {
                    detail: {
                        rowIndex,
                        rowId,
                        rowKey,
                        fieldName: field,
                        productId: value
                    },
                    bubbles: true,
                    composed: true
                })
            );
        }
    }

     async handleLookupChange(event) {
        this._hasUserInteracted = true;
        this.clearComponentValidity(event.target);

        const rowIndex = Number(event.currentTarget.dataset.rowIndex);
        const field = event.currentTarget.dataset.field;
        const value = event.detail?.recordId;

        const updated = [...this.rows];
        updated[rowIndex] = { ...updated[rowIndex], [field]: value };
        this.rows = updated;

        await this.updateRowServer(rowIndex, field);

        //TODO: verificar el componente desde el que se esta llamando o algun otro condicional para evitar llamados innecesarios
        this.dispatchEvent(
            new CustomEvent('lookupchange', {
                detail: { rowIndex, fieldName: field, recordId: value },
                bubbles: true,
                composed: true
            })
        );
    }

    @api
    validate() {
        this._forceShowErrors = true;

        let allOk = true;

        (this.rows || []).forEach((row) => {
            const missing = this.getMissingRequiredForRow(row);
            if (missing.length) allOk = false;
        });

        if (this.objectApiName === 'ONB_Fund_Item__c') {
            (this.rows || []).forEach((row, rowIndex) => {
                const leiPending = !!row?.ONB_LEI_Pending_Create__c;
                const lei = (row?.lei_id__c || '').trim();

                if (!leiPending) {
                    const leiCmp = this.template.querySelector(
                        `lightning-input[data-row-index="${rowIndex}"][data-field="lei_id__c"]`
                    );

                    if (lei && lei.length !== 20) {
                        allOk = false;
                        if (leiCmp && typeof leiCmp.setCustomValidity === 'function') {
                            leiCmp.setCustomValidity(ONB_LEI_20_CHAR);
                            leiCmp.reportValidity();
                        }
                    } else if (leiCmp && typeof leiCmp.setCustomValidity === 'function') {
                        leiCmp.setCustomValidity('');
                        leiCmp.reportValidity();
                    }
                }
            });
        }

        const inputs = this.template.querySelectorAll(
            'lightning-input, lightning-textarea, lightning-combobox, lightning-record-picker'
        );

        inputs.forEach((cmp) => {
            // solo valida los marcados como required (dataset llega como string)
            const isReq = cmp?.dataset?.required === 'true';
            if (!isReq && cmp?.dataset?.field !== 'lei_id__c') return;

            // reportValidity aplica estilo rojo
            if (typeof cmp.reportValidity === 'function') {
                const ok = cmp.reportValidity();
                if (!ok) allOk = false;
            }
        });

        return allOk;
    }

    // -------- Helpers para limpiar errores visuales al escribir --------
    clearComponentValidity(cmp) {
        if (!cmp) return;
        if (typeof cmp.setCustomValidity === 'function') {
            cmp.setCustomValidity('');
        }
        if (typeof cmp.reportValidity === 'function') {
            cmp.reportValidity();
        }
    }

    pasarEventoArriba(event) {
        // El aviso viene del Toggle
        if (event.type === 'togglechange') {
            this.dispatchEvent(new CustomEvent('togglechange', {
                detail: event.detail
            }));
        }
        // El aviso viene del Modal
        else {
            this.dispatchEvent(new CustomEvent('refrescartabla'));
        }
    }
}