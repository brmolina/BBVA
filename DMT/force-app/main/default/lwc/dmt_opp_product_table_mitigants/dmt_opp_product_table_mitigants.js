import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { deleteRecord } from 'lightning/uiRecordApi';
import LightningConfirm from 'lightning/confirm';
import TITLETABLE from '@salesforce/label/c.dmt_cl_Collateral_Guarantees_Text';

const TEMP_ID_PREFIX = 'NEW_';
const VALID_MITIGANT_TYPES_REAL = new Set([
    'Real > Mortgage guarantee',
    'Real > Cash',
    'Real > Gold Bullion',
    'Real > Debt securities',
    'Real > Debt securities issued by central governments or central Banks',
    'Real > Receivables',
    'Real > Index equities and Index convertible bonds',
    'Real > Securitisation',
    'Real > Others real'
]);
const LIQUIDATION_ENABLED_TYPES = new Set([
    'Real > Cash',
    'Real > Gold Bullion',
    'Real > Debt securities',
    'Real > Debt securities issued by central governments or central Banks',
    'Real > Index equities and Index convertible bonds',
    'Real > Securitisation'
]);
const LIQUIDATION_PERIOD_OPTIONS = [
    { label: '5 días', value: '5' },
    { label: '10 días', value: '10' },
    { label: '20 días', value: '20' }
];
const BUSINESS_FIELDS = [
    'Mitigant_Type__c',
    'Commercial_Percentage__c',
    'Political_Percentage__c',
    'End_Date__c',
    'Internal_Rating__c',
    'External_Rating__c',
    'CurrencyIsoCode',
    'DMT_Country_Guarantor__c',
    'Liquidation_Period__c',
    'DMT_Opportunity_Product__c'
];
const COLUMN_WIDTHS = {
    Mitigant_Type__c        : 270,
    Commercial_Percentage__c: 142,
    Political_Percentage__c : 120,
    EndDate                 : 133,
    Internal_Rating__c      : 112,
    External_Rating__c      : 112,
    CurrencyIsoCode         : 113,
    Country_Guarantor__c    : 145,
    Liquidation_Period__c   : 135,
    button                  : 60
};
const FIELD_LABELS = {
    Mitigant_Type__c        : 'Collateral Type',
    Commercial_Percentage__c: 'Commercial Risk (%)',
    Political_Percentage__c : 'Political Risk (%)',
    End_Date__c             : 'End Date',
    Internal_Rating__c      : 'Internal Rating',
    External_Rating__c      : 'External Rating',
    CurrencyIsoCode         : 'Currency',
    DMT_Country_Guarantor__c: 'Country Collateral',
    Liquidation_Period__c   : 'Liquidation Period'
};

export default class DmtOppProductTableMitigants extends LightningElement {

    label = { TITLETABLE };

    @api oppProduct;
    @api endDateProduct;

    _isEditMode = false;
    _canEdit    = true;
    _data       = [];
    _termOptions           = [];
    _currencyOptions       = [];
    _countryOptions        = [];
    _internalRatingOptions = [];
    _externalRatingOptions = [];

    get isReadOnly() { return !this._canEdit; }

    @api get data() { return this._data; }
    set data(value) {
        this._data = Array.isArray(value) ? value : [];
        if (this._snapshot) return;
        this._loadFromData();
    }

    @api get catalogValues() { return {}; }
    set catalogValues(value) {
        if (!value || typeof value !== 'object') return;
        this._termOptions = (value['E895'] || [])
            .filter(o => VALID_MITIGANT_TYPES_REAL.has(o.label))
            .map(o => ({ label: o.label, value: o.label }));
        this._internalRatingOptions = value['C204'] || [];
        this._externalRatingOptions = value['C009'] || [];
        this._countryOptions        = value['C245'] || [];
        this._currencyOptions       = value['C264'] || [];
        if (!this._isEditMode) {
            this.columns = this._buildColumns();
        }
    }

    @track rows        = [];
    @track displayRows = [];
    @track columns     = [];
    @track isLoading   = false;

    _snapshot      = null;
    _tempIdCounter = 0;

    connectedCallback() {
        this.columns = this._buildColumns();
    }

    @api enterEditMode() {
        if (this._isEditMode) return;
        if (!this._snapshot) {
            this._snapshot = this.rows.map(r => ({ ...r }));
        }
        this._isEditMode = true;
        this.columns = this._buildColumns();
        this._refreshDerivedState();
    }

    @api restoreSnapshot() {
        if (!this._snapshot) return;
        this.rows        = this._snapshot.map(r => ({ ...r }));
        this._snapshot   = null;
        this._isEditMode = false;
        this.columns     = this._buildColumns();
        this._refreshDerivedState();
    }

    @api commitEdit() {
        this.rows        = this.rows.filter(r => !r._deleted);
        this._snapshot   = null;
        this._isEditMode = false;
        this.columns     = this._buildColumns();
        this._loadFromData();
    }

    @api collectMitigantsChanges() {
        return {
            mitigantsToUpsert: this.rows
                .filter(r => !r._deleted)
                .map(r => this._cleanRow(r)),
            mitigantsToDelete: this.rows
                .filter(r => r._deleted && r.Id && !r.Id.startsWith(TEMP_ID_PREFIX))
                .map(r => r.Id)
        };
    }

    @api setReadOnlyMode(readOnly) {
        const newCanEdit = !readOnly;
        if (this._canEdit === newCanEdit) return;
        this._canEdit = newCanEdit;
        this.columns  = this._buildColumns();
        this._refreshDerivedState();
    }

    @api getFieldLabel(apiName) {
        return FIELD_LABELS[apiName] || null;
    }

    @api collectInvalidFields() {
        const { isValid, invalidFields } = this.collectNegativeFieldsValidation();
        return { isValid, invalidFields };
    }

    @api get totalRowsCount() {
        return this.rows.filter(r => !r._deleted).length;
    }

    collectNegativeFieldsValidation() {
        const invalidFields = [];
        const activeRows = this.rows.filter(r => !r._deleted);
        
        const hasNegativeCommercial = activeRows.some(r => parseFloat(r.Commercial_Percentage__c || 0) < 0);
        if (hasNegativeCommercial) invalidFields.push(FIELD_LABELS.Commercial_Percentage__c);
        
        const hasNegativePolitical = activeRows.some(r => parseFloat(r.Political_Percentage__c || 0) < 0);
        if (hasNegativePolitical) invalidFields.push(FIELD_LABELS.Political_Percentage__c);

        return {
            isValid: invalidFields.length === 0,
            invalidFields: [...new Set(invalidFields)]
        };
    }

    _loadFromData() {
        this.rows = this._data
            .filter(item => VALID_MITIGANT_TYPES_REAL.has(item.Mitigant_Type__c) || !item.Mitigant_Type__c)
            .map(r => this._decorateNewRow(r));
        this._refreshDerivedState();
    }

    _decorateNewRow(row) {
        const isNew        = !row.Id || row.Id.startsWith(TEMP_ID_PREFIX);
        const mitigantType = row.Mitigant_Type__c || '';
        return {
            ...row,
            Id                        : isNew ? this._newTempId() : row.Id,
            External_Rating__c        : row.External_Rating__c    || 'NR',
            Commercial_Percentage__c  : row.Commercial_Percentage__c ?? '0',
            Political_Percentage__c   : row.Political_Percentage__c  ?? '0',
            End_Date__c               : row.End_Date__c || this.endDateProduct || '',
            DMT_Opportunity_Product__c: row.DMT_Opportunity_Product__c || this.oppProduct || null,
            _deleted                  : false,
            _isNew                    : isNew,
            isLiquidationEditable     : !LIQUIDATION_ENABLED_TYPES.has(mitigantType)
        };
    }

    _newTempId() {
        this._tempIdCounter += 1;
        return `${TEMP_ID_PREFIX}${Date.now()}_${this._tempIdCounter}`;
    }

    handleRowAction(event) {
        const { action, row } = event.detail;
        switch (action.name) {
            case 'editRecord'  : this._handleEditClick();     break;
            case 'addRecord'   : this._handleAddRow(row.Id);  break;
            case 'deleteRecord': this._requestDelete(row.Id); break;
            default: break;
        }
    }

    handleAddRowGlobal() {
        this._handleAddRow(null);
    }

    _handleEditClick() {
        this.dispatchEvent(new CustomEvent('editmodechange', {
            bubbles : true,
            composed: true,
            detail  : { isEditMode: true }
        }));
    }

    _handleAddRow(afterId) {
        if (!this._canEdit) return;
        if (!this._snapshot) {
            this._snapshot = this.rows.map(r => ({ ...r }));
        }
        const newRow = this._decorateNewRow({
            Id                        : null,
            Mitigant_Type__c          : '',
            Commercial_Percentage__c  : '0',
            Political_Percentage__c   : '0',
            End_Date__c               : this.endDateProduct || '',
            Internal_Rating__c        : '',
            External_Rating__c        : 'NR',
            CurrencyIsoCode           : '',
            DMT_Country_Guarantor__c  : '',
            Liquidation_Period__c     : '',
            DMT_Opportunity_Product__c: this.oppProduct || null
        });
        if (afterId == null) {
            this.rows = [...this.rows, newRow];
        } else {
            const idx    = this.rows.findIndex(r => r.Id === afterId);
            const newArr = [...this.rows];
            newArr.splice(idx === -1 ? newArr.length : idx + 1, 0, newRow);
            this.rows = newArr;
        }
        this._refreshDerivedState();
        if (!this._isEditMode) {
            this.dispatchEvent(new CustomEvent('editmodechange', {
                bubbles : true,
                composed: true,
                detail  : { isEditMode: true }
            }));
        }
    }

    async _requestDelete(id) {
        const row = this.rows.find(r => r.Id === id);
        if (!row) return;
        if (row._isNew || this._isEditMode) {
            this._performDelete(id);
            return;
        }
        const confirmed = await LightningConfirm.open({
            message: 'Are you sure you want to delete this Collateral Guarantee? This action cannot be undone.',
            variant: 'header',
            label  : 'Confirm deletion',
            theme  : 'warning'
        });
        if (confirmed) this._performDelete(id);
    }

    _performDelete(id) {
        const row = this.rows.find(r => r.Id === id);
        if (!row) return;
        if (row._isNew) {
            this.rows = this.rows.filter(r => r.Id !== id);
            this._refreshDerivedState();
            this._toast('Record deleted', 'The Collateral Guarantee was successfully deleted.', 'success');
            return;
        }
        if (this._isEditMode) {
            this.rows = this.rows.map(r => r.Id === id ? { ...r, _deleted: true } : r);
            this._refreshDerivedState();
            return;
        }
        this.isLoading = true;
        deleteRecord(id)
            .then(() => {
                this._toast('Record deleted', 'The Collateral Guarantee was successfully deleted.', 'success');
                this.rows = this.rows.filter(r => r.Id !== id);
                this._refreshDerivedState();
            })
            .catch(error => {
                this._toast('Error deleting', error?.body?.message || error?.message || 'Could not delete the record.', 'error');
                console.error('Error message:', error.body?.message || error.message);
                console.error('Full error:', JSON.parse(JSON.stringify(error)));
            })
            .finally(() => { this.isLoading = false; });
    }

    _handleCellChange(event) {
        event.stopPropagation();
        const { context: id, fieldname: field, value } = event.detail.data;
        const idx = this.rows.findIndex(r => r.Id === id);
        if (idx === -1) return;
        const newRow = { ...this.rows[idx], [field]: value };
        if (field === 'Mitigant_Type__c') {
            newRow.isLiquidationEditable = !LIQUIDATION_ENABLED_TYPES.has(value || '');
            if (newRow.isLiquidationEditable) newRow.Liquidation_Period__c = '';
        }
        const newArr = [...this.rows];
        newArr[idx]  = newRow;
        this.rows    = newArr;
        this._refreshDerivedState();
    }

    handlePicklistChange(event) { this._handleCellChange(event); }
    handleCellInput(event)      { this._handleCellChange(event); }
    handleCellNumber(event)     { this._handleCellChange(event); }
    handleCellDate(event)       { this._handleCellChange(event); }

    _refreshDerivedState() {
        this.displayRows = this.rows
            .filter(r => !r._deleted)
            .map(r => ({
                ...r,
                deleteDisabled: !this._canEdit,
                editDisabled  : !this._canEdit,
                buttonDisabled: !this._canEdit
            }));
        this.displayRows = [...this.displayRows];
    }

    get hasRows()           { return this.displayRows.length > 0; }
    get globalAddDisabled() { return !this._canEdit; }

    _buildColumns() {
        const e = this._isEditMode;
        return [
            this._searchComboColumn('Collateral Type',     'Mitigant_Type__c',         this._termOptions,           e, COLUMN_WIDTHS.Mitigant_Type__c),
            this._numericColumn    ('Commercial Risk (%)', 'Commercial_Percentage__c',                               e),
            this._numericColumn    ('Political Risk (%)',  'Political_Percentage__c',                                e),
            this._dateColumn       ('End Date',            'End_Date__c',                                            e),
            this._picklistColumn   ('Internal Rating',     'Internal_Rating__c',        this._internalRatingOptions, e, COLUMN_WIDTHS.Internal_Rating__c),
            this._picklistColumn   ('External Rating',     'External_Rating__c',        this._externalRatingOptions, e, COLUMN_WIDTHS.External_Rating__c),
            this._searchComboColumn('Currency',            'CurrencyIsoCode',           this._currencyOptions,       e, COLUMN_WIDTHS.CurrencyIsoCode),
            this._searchComboColumn('Country Collateral',  'DMT_Country_Guarantor__c',  this._countryOptions,        e, COLUMN_WIDTHS.Country_Guarantor__c),
            this._liquidationColumn(e),
            this._buttonColumn('utility:delete', 'deleteRecord', 'deleteDisabled'),
            this._buttonColumn('utility:edit',   'editRecord',   'editDisabled'),
            this._buttonColumn('utility:add',    'addRecord',    'buttonDisabled'),
        ];
    }

    _searchComboColumn(label, field, options, isEdit, width) {
        return {
            label,
            fieldName         : field,
            type              : isEdit ? 'searchcombobox' : 'text',
            editable          : false,
            hideDefaultActions: true,
            initialWidth      : width,
            cellAttributes    : { alignment: 'center' },
            typeAttributes    : {
                pickListOrdered    : options,
                fieldName          : field,
                selectedSearchlabel: { fieldName: field },
                context            : { fieldName: 'Id' }
            }
        };
    }

    _picklistColumn(label, field, options, isEdit, width) {
        return {
            label,
            fieldName         : field,
            type              : isEdit ? 'picklist' : 'text',
            editable          : false,
            hideDefaultActions: true,
            initialWidth      : width,
            cellAttributes    : { alignment: 'center' },
            typeAttributes    : {
                placeholder: 'Select..',
                options,
                value      : { fieldName: field },
                context    : { fieldName: 'Id' },
                fieldName  : field
            }
        };
    }

    _numericColumn(label, field, isEdit) {
        return {
            label,
            fieldName         : field,
            type              : isEdit ? 'customnumberRow' : 'percent-fixed',
            editable          : false,
            hideDefaultActions: true,
            initialWidth      : COLUMN_WIDTHS[field] || 140,
            cellAttributes    : { alignment: 'center' },
            typeAttributes    : {
                step            : 'any',
                aviableItem     : { fieldName: true },
                numberValue     : { fieldName: field },
                fieldName       : field,
                context         : { fieldName: 'Id' },
                validateNegative: !!isEdit
            }
        };
    }

    _dateColumn(label, field, isEdit) {
        return {
            label,
            fieldName         : field,
            type              : isEdit ? 'customdateRow' : 'date',
            editable          : false,
            hideDefaultActions: true,
            initialWidth      : COLUMN_WIDTHS.EndDate,
            cellAttributes    : { style: 'text-align: center;' },
            typeAttributes    : {
                aviableItem: { fieldName: 'aviableItem' },
                dateValue  : { fieldName: field },
                fieldName  : field,
                value      : { fieldName: field },
                context    : { fieldName: 'Id' }
            }
        };
    }

    _liquidationColumn(isEdit) {
        return {
            label             : 'Liquidation Period',
            fieldName         : 'Liquidation_Period__c',
            type              : isEdit ? 'picklist' : 'text',
            editable          : false,
            hideDefaultActions: true,
            initialWidth      : COLUMN_WIDTHS.Liquidation_Period__c,
            cellAttributes    : { alignment: 'center' },
            typeAttributes    : {
                placeholder: 'Select..',
                options    : LIQUIDATION_PERIOD_OPTIONS,
                value      : { fieldName: 'Liquidation_Period__c' },
                context    : { fieldName: 'Id' },
                fieldName  : 'Liquidation_Period__c',
                isDisabled : { fieldName: 'isLiquidationEditable' },
                inputValue : { fieldName: 'Liquidation_Period__c' }
            }
        };
    }

    _buttonColumn(iconName, actionName, disabledField) {
        return {
            type              : 'button-icon',
            hideDefaultActions: true,
            initialWidth      : COLUMN_WIDTHS.button,
            cellAttributes    : { alignment: 'center' },
            typeAttributes    : {
                iconName,
                label   : ' ',
                variant : 'bare',
                name    : actionName,
                disabled: { fieldName: disabledField }
            }
        };
    }

    _cleanRow(row) {
        const cleaned = { Id: row.Id?.startsWith(TEMP_ID_PREFIX) ? null : row.Id };
        for (const f of BUSINESS_FIELDS) {
            cleaned[f] = row[f] !== undefined ? row[f] : null;
        }
        return cleaned;
    }

    _toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}