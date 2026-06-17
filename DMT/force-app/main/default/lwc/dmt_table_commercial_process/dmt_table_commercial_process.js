import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const READ_COLUMNS = [
    { type: 'button-icon', hideDefaultActions: true, initialWidth: 60, cellAttributes: { alignment: 'center' }, typeAttributes: { iconName: 'utility:edit', label: ' ', name: 'editRecord', variant: 'bare' } },
    { fieldName: 'Name', label: 'PRODUCT NAME', initialWidth: 180, type: 'text', hideDefaultActions: true, editable: false, cellAttributes: { alignment: 'left' } },
    { fieldName: 'deferred_fee_amount_display', label: 'DEFERRED FEES (AMOUNT)', initialWidth: 200, type: 'text', hideDefaultActions: true, editable: false, cellAttributes: { alignment: 'center' } },
    { fieldName: 'no_deferred_fee_amount_display', label: 'NON DEFERRED FEES (AMOUNT)', initialWidth: 200, type: 'text', hideDefaultActions: true, editable: false, cellAttributes: { alignment: 'center' } },
    { fieldName: 'undrawn_fee_next_12m_amount_display', label: 'ANNUAL COMMITMENT FEE NEXT 12 M (AMOUNT)', initialWidth: 200, type: 'text', hideDefaultActions: true, editable: false, cellAttributes: { alignment: 'center' } },
    { fieldName: 'pre_net_margin_next_12m_amount_display', label: 'MARGIN NET OF FUNDING COST (AMOUNT)', initialWidth: 200, type: 'text', hideDefaultActions: true, editable: false, cellAttributes: { alignment: 'center' } },
    { fieldName: 'periodic_fee_amount_display', label: 'RECURRENT FEES NEXT 12 MONTHS (AMOUNT)', initialWidth: 200, type: 'text', hideDefaultActions: true, editable: false, cellAttributes: { alignment: 'center' } },
    { fieldName: 'fee_next_12m_amount_display', label: 'FEES NEXT 12 MONTHS (AMOUNT)', initialWidth: 200, type: 'text', hideDefaultActions: true, editable: false, cellAttributes: { alignment: 'center' } },
    { fieldName: 'pre_oppy_revenue_next_12m_amount_display', label: 'POTENTIAL REVENUES NEXT 12 MTHS (AMOUNT)', initialWidth: 200, type: 'text', hideDefaultActions: true, editable: false, cellAttributes: { alignment: 'center' } },
    { fieldName: 'funding_cost_per_display', label: 'COST OF FUNDING (BPS)', initialWidth: 180, type: 'text', hideDefaultActions: true, editable: false, cellAttributes: { alignment: 'center' } },
    { fieldName: 'credit_drawn_next_12m_per_display', label: 'AVERAGE DRAWN NEXT 12 MONTHS (%)', initialWidth: 180, type: 'text', hideDefaultActions: true, editable: false, cellAttributes: { alignment: 'center' } },
    { fieldName: 'pre_gross_margin_next_12m_per_display', label: 'GROSS MARGIN NEXT 12 MONTHS (BPS)', initialWidth: 180, type: 'text', hideDefaultActions: true, editable: false, cellAttributes: { alignment: 'center' } },
];

const EDITABLE_AMOUNT_FIELDS = [
    'deferred_fee_amount__c',
    'no_deferred_fee_amount__c',
    'undrawn_fee_next_12m_amount__c',
    'pre_net_margin_next_12m_amount__c',
    'periodic_fee_amount__c',
    'fee_next_12m_amount__c',
    'pre_oppy_revenue_next_12m_amount__c',
];

const EDITABLE_PERCENT_FIELDS = [
    'funding_cost_per__c',
    'credit_drawn_next_12m_per__c',
    'pre_gross_margin_next_12m_per__c',
];

export default class dmt_table_commercial_process extends LightningElement {

    // ─── Public API ──────────────────────────────────────────────────────────

    @api oppState;
    @api columnstablecopypaste = [];
    @api stageName;

    @api
    get isReadOnlyUser() {
        return this._isReadOnlyUser;
    }
    set isReadOnlyUser(value) {
        this._isReadOnlyUser = (value === true || value === 'true');
        this._refreshColumnsByPermission();
    }

    @api
    get editState() {
        return this._editState;
    }
    set editState(value) {
        const bool = value === true || value === 'true';
        this._editState = bool;
        if (bool) {
            this.isEditMode = true;
            this.columns = this._buildEditColumns();
        } else {
            this.isEditMode = false;
            this.columns = this._buildReadColumns();
        }
    }

    @api
    get tableInput() {
        return this._rawInput;
    }
    set tableInput(value) {
        this._rawInput = value;
        this._initTableData(value);
    }


    _rawInput         = [];
    _editState        = false;
    _isReadOnlyUser   = false;
    @track tableData  = [];
    @track columns    = this._buildReadColumns();
    @track isEditMode = false;

    get isEditPencilEnabled() {
        return this._isReadOnlyUser === false
            && (this.stageName === 'Draft' || this.stageName === 'Proposal');
    }


    get isEditable() {
        return this.oppState === 'Draft' || this.oppState === 'Ready to close';
    }

    get isEmpty() {
        if (!this.tableData || this.tableData.length === 0) return true;
        return this.tableData.every(row => !row.Id && !row.Name);
    }

    get columnsResolved() {
        if (this.isEmpty) {
            return this.isEditPencilEnabled ? this.columns.slice(1) : this.columns;
        }
        return this.columns;
    }

    get tableDataResolved() {
        return this.isEmpty ? [] : this.tableData;
    }


    _normalize(value) {
        try {
            const obj = typeof value === 'string' ? JSON.parse(value) : value;
            if (obj && typeof obj === 'object' && !Array.isArray(obj)) {
                if (Array.isArray(obj.OppLineItems)) return obj.OppLineItems;
                return [obj];
            }
            if (Array.isArray(obj)) return obj.filter(i => i && typeof i === 'object');
        } catch (e) {
            console.error('[dmt_table_oli_fees] Error parsing tableInput:', e);
        }
        return [];
    }

    _toNum(val) {
        if (val === '' || val === null || val === undefined) return 0;
        const n = Number(val);
        return isNaN(n) ? 0 : n;
    }

    _initTableData(value) {
        const normalized = this._normalize(value);
        console.log('normalized FEES -> ' + JSON.stringify(normalized));
        this.tableData = normalized.map(item => {
            console.log('currency row -> ' + item.Id + ' / ' + item.g_currency_id__c);
            const deferred = this._toNum(item.deferred_fee_amount__c);
            const noDeferred = this._toNum(item.no_deferred_fee_amount__c);
            const annual = this._toNum(item.undrawn_fee_next_12m_amount__c);
            const netMargin = this._toNum(item.pre_net_margin_next_12m_amount__c);
            const periodic = this._toNum(item.periodic_fee_amount__c);
            const feeNext = this._toNum(item.fee_next_12m_amount__c);
            const potential = this._toNum(item.pre_oppy_revenue_next_12m_amount__c);
            const currency = item.g_currency_id__c || 'EUR';

            return {
                ...item,
                g_currency_id__c: currency,
                deferred_fee_amount__c: deferred,
                no_deferred_fee_amount__c: noDeferred,
                undrawn_fee_next_12m_amount__c: annual,
                pre_net_margin_next_12m_amount__c: netMargin,
                periodic_fee_amount__c: periodic,
                fee_next_12m_amount__c: feeNext,
                pre_oppy_revenue_next_12m_amount__c: potential,
                funding_cost_per__c: this._toNum(item.funding_cost_per__c),
                credit_drawn_next_12m_per__c: this._toNum(item.credit_drawn_next_12m_per__c),
                pre_gross_margin_next_12m_per__c: this._toNum(item.pre_gross_margin_next_12m_per__c),

                deferred_fee_amount_display: this._formatAmountWithCurrency(deferred, currency),
                no_deferred_fee_amount_display: this._formatAmountWithCurrency(noDeferred, currency),
                undrawn_fee_next_12m_amount_display: this._formatAmountWithCurrency(annual, currency),
                pre_net_margin_next_12m_amount_display: this._formatAmountWithCurrency(netMargin, currency),
                periodic_fee_amount_display: this._formatAmountWithCurrency(periodic, currency),
                fee_next_12m_amount_display: this._formatAmountWithCurrency(feeNext, currency),
                pre_oppy_revenue_next_12m_amount_display: this._formatAmountWithCurrency(potential, currency),

                funding_cost_per_display: this._formatWithSuffix(item.funding_cost_per__c, 'bps'),
                credit_drawn_next_12m_per_display: this._formatWithSuffix(item.credit_drawn_next_12m_per__c, '%'),
                pre_gross_margin_next_12m_per_display: this._formatWithSuffix(item.pre_gross_margin_next_12m_per__c, 'bps'),

                editDisabled: !this.isEditable,
            };
        });

        if (!this._editState) {
            this.isEditMode = false;
            this.columns = this._buildReadColumns();
        } else {
            this.columns = this._buildEditColumns();
        }
    }

    _buildReadColumns() {
        return this.isEditPencilEnabled ? READ_COLUMNS : READ_COLUMNS.slice(1);
    }

    _refreshColumnsByPermission() {
        if (this._editState) {
            this.columns = this._buildEditColumns();
        } else {
            this.columns = this._buildReadColumns();
        }
    }

    _deepCopy(list) {
        return list.map(item => JSON.parse(JSON.stringify(item)));
    }


    _buildEditColumns() {
        const nameCol = {
            fieldName: 'Name',
            label: 'PRODUCT NAME',
            initialWidth: 180,
            type: 'text',
            editable: false,
            hideDefaultActions: true,
            cellAttributes: { alignment: 'left' },
        };

        const amountLabels = {
            deferred_fee_amount__c:              'DEFERRED FEES (AMOUNT)',
            no_deferred_fee_amount__c:           'NON DEFERRED FEES (AMOUNT)',
            undrawn_fee_next_12m_amount__c:      'ANNUAL COMMITMENT FEE NEXT 12 M (AMOUNT)',
            pre_net_margin_next_12m_amount__c:   'MARGIN NET OF FUNDING COST (AMOUNT)',
            periodic_fee_amount__c:              'RECURRENT FEES NEXT 12 MONTHS (AMOUNT)',
            fee_next_12m_amount__c:              'FEES NEXT 12 MONTHS (AMOUNT)',
            pre_oppy_revenue_next_12m_amount__c: 'POTENTIAL REVENUES NEXT 12 MTHS (AMOUNT)',
        };

        const amountCols = EDITABLE_AMOUNT_FIELDS.map(field => ({
            fieldName: field,
            label: amountLabels[field],
            initialWidth: 200,
            type: 'custominputRow',
            editable: false,
            hideDefaultActions: true,
            cellAttributes: { alignment: 'center' },
            typeAttributes: {
                suffix: { fieldName: 'g_currency_id__c' },
                step: '0.01',
                aviableItem: { fieldName: true },
                inputValue: { fieldName: field },
                fieldName: field,
                context: { fieldName: 'Id' },
                value: { fieldName: field },
            },
        }));

        const percentLabels = {
            funding_cost_per__c:              'COST OF FUNDING (BPS)',
            credit_drawn_next_12m_per__c:     'AVERAGE DRAWN NEXT 12 MONTHS (%)',
            pre_gross_margin_next_12m_per__c: 'GROSS MARGIN NEXT 12 MONTHS (BPS)',
        };

        const percentCols = EDITABLE_PERCENT_FIELDS.map(field => ({
            fieldName: field,
            label: percentLabels[field],
            initialWidth: 180,
            type: 'custominputRow',
            editable: false,
            hideDefaultActions: true,
            cellAttributes: { alignment: 'center' },
            typeAttributes: {
                suffix: field === 'credit_drawn_next_12m_per__c' ? '%' : 'bps',
                step: '0.001',
                aviableItem: { fieldName: true },
                inputValue: { fieldName: field },
                fieldName: field,
                context: { fieldName: 'Id' },
                value: { fieldName: field },
            },
        }));

        const editBtnCol = {
            type: 'button-icon',
            hideDefaultActions: true,
            initialWidth: 60,
            cellAttributes: { alignment: 'center' },
            typeAttributes: {
                iconName: 'utility:edit',
                label: ' ',
                name: 'editRecord',
                variant: 'bare',
            },
        };

        const cols = [nameCol, ...amountCols, ...percentCols];
        if (this.isEditPencilEnabled) {
            cols.unshift(editBtnCol);
        }
        return cols;
    }


    handleRowAction(event) {
        console.log('ABS edit button '+ JSON.stringify(event.detail.action));
        const action = event.detail.action;
        if (action.name !== 'editRecord') return;
        if (!this.isEditPencilEnabled) return;

        this.dispatchEvent(new CustomEvent('editModeTableOliFees', {
            bubbles: true,
            composed: true,
            detail: { editState: true },
        }));
    }

    textInputChanged(event) {
        event.stopPropagation();
        const { context, fieldname, value } = event.detail.data;
        this._applyUpdate({ Id: context, [fieldname]: value });
    }

    handleChangeCell(event) {
        const draftValues = event.detail.draftValues;
        if (!draftValues || !draftValues.length) return;
        draftValues.forEach(draft => this._applyUpdate(draft));
    }


    _applyUpdate(updateItem) {
        const copy = this._deepCopy(this.tableData);
        const idx  = copy.findIndex(row => row.Id === updateItem.Id);
        if (idx !== -1) {
            Object.keys(updateItem).forEach(key => {
                if (updateItem[key] !== undefined) {
                    const isNumericField = 
                        EDITABLE_AMOUNT_FIELDS.includes(key) || 
                        EDITABLE_PERCENT_FIELDS.includes(key);
                    copy[idx][key] = isNumericField 
                        ? this._toNum(updateItem[key]) 
                        : updateItem[key];
                }
            });
        }
        this.tableData = copy;
        this._dispatchChange(copy);
    }

    _dispatchChange(data) {
        const cleanData = data.map(({ editDisabled, ...rest }) => rest);
        console.log('ABS DATA -> '+JSON.stringify(cleanData));

        this.dispatchEvent(new CustomEvent('tableOliFeesChange', {
            bubbles: true,
            composed: true,
            detail: { cleanData },
        }));
    }

    _formatAmountWithCurrency(amount, currencyCode) {
        const value = this._toNum(amount);

        const formattedNumber = new Intl.NumberFormat('es-ES', {
            minimumFractionDigits: 0,
            maximumFractionDigits: 10
        }).format(value);

        const currencyMap = {
            EUR: '€'
        };

        const symbol = currencyMap[currencyCode];

        return symbol 
            ? `${formattedNumber} ${symbol}` 
            : `${formattedNumber} ${currencyCode || ''}`.trim();
    }

    _formatWithSuffix(value, suffix) {
        const formatted = new Intl.NumberFormat('es-ES', {
            minimumFractionDigits: 0,
            maximumFractionDigits: 10
        }).format(this._toNum(value));
        return `${formatted} ${suffix}`;
    }
}