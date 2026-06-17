import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent }  from 'lightning/platformShowToastEvent';
import { deleteRecord }    from 'lightning/uiRecordApi';
import LightningConfirm    from 'lightning/confirm';
import syncTenors          from '@salesforce/apex/DMT_TableTenors.syncTenors';
import DMT_Repayment_Schedule from '@salesforce/label/c.DMT_Repayment_Schedule';

const AMORT_TYPE_USER_DEFINED = 'User-Defined';
const MAX_DRAWN_SPREAD_BPS    = 999;
const PAGE_SIZE               = 10;
const ROLE_INIT               = 'INIT';
const ROLE_MIDDLE             = 'MIDDLE';
const ROLE_END                = 'END';
const TEMP_ID_PREFIX          = 'NEW_';

const NOMINAL_FIELDS      = ['gj_nominal_amount_db__c', 'gf_nominal_amount_fb__c'];
const BPS_FIELDS          = ['gf_spread_db__c', 'gf_spread_fb__c', 'gf_accrual_fees_bp__c', 'gf_non_accrual_fees_bp__c'];
const ALL_NUMERIC_FIELDS  = [...NOMINAL_FIELDS, ...BPS_FIELDS];
const BUSINESS_FIELDS     = ['Id', 'gf_tenor_date__c', ...ALL_NUMERIC_FIELDS, 'DMT_Opportunity_Product__c'];

const isTempId = (id) => !!id && String(id).startsWith(TEMP_ID_PREFIX);
const isRealId = (id) => !!id && !isTempId(id);

export default class DmtOppProductsTableTenors extends LightningElement {

    label = { DMT_Repayment_Schedule };

    @api oppProduct;

    _isEditMode       = false;
    _canEdit          = true;
    _initialDate      = '';
    _maturityDate     = '';
    _amortizationType = '';
    _currencyCode     = '';
    _data             = [];

    // ─── Public API ───────────────────────────────────────────────────────────

    @api get isEditMode() { return this._isEditMode; }
    set isEditMode(value) {
        const newVal = (typeof value === 'boolean') ? value : (String(value).toLowerCase() === 'true');
        if (this._isEditMode === newVal) return;
        this._isEditMode = newVal;
        this.columns = this._buildColumns();
        this._updatePagination();
        if (this._isEditMode) {
            if (!this._snapshot) this._snapshot = this.rows.map(r => ({ ...r }));
        } else {
            this._snapshot = null;
        }
    }

    @api get initialDate() { return this._initialDate; }
    set initialDate(value) {
        this._initialDate = value || '';
        this.columns = this._buildColumns();
        this._applyContextToRows();
    }

    @api get maturityDate() { return this._maturityDate; }
    set maturityDate(value) {
        this._maturityDate = value || '';
        this.columns = this._buildColumns();
        this._applyContextToRows();
    }

    @api get amortizationType() { return this._amortizationType; }
    set amortizationType(value) {
        const prev = this._amortizationType;
        const next = value || '';
        if (prev === next) return;
        this._amortizationType = next;
        // When switching away from User-Defined, collapse middle rows
        if (prev === AMORT_TYPE_USER_DEFINED && next !== AMORT_TYPE_USER_DEFINED) {
            this._collapseToInitAndEnd();
        }
        this._applyContextToRows();
    }

    @api get currencyCode() { return this._currencyCode; }
    set currencyCode(value) {
        this._currencyCode = value || '';
        this.columns = this._buildColumns();
    }

    @api get data() { return this._data; }
    set data(value) {
        const newArr = Array.isArray(value) ? value : [];
        if (this._data === newArr) return;
        this._data = newArr;
        // Skip reload if user is editing (snapshot active) to preserve in-memory changes
        if (this._snapshot) return;
        this._loadFromData();
    }

    @api get totalRowsCount() {
        return this.rows.filter(r => !r._deleted).length;
    }

    @api restoreSnapshot() {
        if (this._snapshot) {
            this.rows      = this._snapshot.map(r => ({ ...r }));
            this._snapshot = null;
            this._refreshDerivedState();
        }
    }

    @api commitEdit() {
        this.rows      = this.rows.filter(r => !r._deleted);
        this.rows      = this._applyRolesAndConstraints(this.rows);
        this._snapshot = null;
        this._loadFromData();
    }

    @api collectChanges() {
        const tenorData  = this.rows.filter(r => !r._deleted).map(r => this._cleanRow(r));
        const deletedIds = this.rows.filter(r => r._deleted && isRealId(r.Id)).map(r => r.Id);
        return { tenorData, deletedIds };
    }

    @api getCurrentRows() {
        return this.rows.filter(r => !r._deleted).map(r => this._cleanRow(r));
    }

    @api setReadOnlyMode(readOnly) {
        const newCanEdit = !readOnly;
        if (this._canEdit === newCanEdit) return;
        this._canEdit = newCanEdit;
        this._refreshDerivedState();
    }

    @api collectBpsFieldsValidation() {
        const invalidFields = [];
        
        // Construye el mapa de apiName -> label desde las columnas ya existentes
        const labelMap = {};
        for (const col of this.columns) {
            if (col.fieldName && BPS_FIELDS.includes(col.fieldName)) {
                labelMap[col.fieldName] = col.label;
            }
        }
        
        for (const row of this.rows.filter(r => !r._deleted)) {
            for (const fieldApi of BPS_FIELDS) {
                const value = row[fieldApi];
                if (value !== null && value !== undefined && value !== '') {
                    const decimalPart = value.toString().split('.')[1];
                    if (decimalPart && decimalPart.length > 2) {
                        const label = labelMap[fieldApi] || fieldApi;
                        if (!invalidFields.includes(label)) {
                            invalidFields.push(label);
                        }
                    }
                }
            }
        }
        
        return {
            isValid: invalidFields.length === 0,
            invalidFields
        };
    }

    @api collectNegativeFieldsValidation() {
        const invalidFields = [];

        const labelMap = {};
        for (const col of this.columns) {
            if (col.fieldName && ALL_NUMERIC_FIELDS.includes(col.fieldName)) {
                labelMap[col.fieldName] = col.label;
            }
        }

        for (const row of this.rows.filter(r => !r._deleted)) {
            for (const fieldApi of ALL_NUMERIC_FIELDS) {
                const value = row[fieldApi];
                if (value !== null && value !== undefined && value !== '') {
                    if (Number(value) < 0) {
                        const label = labelMap[fieldApi] || fieldApi;
                        if (!invalidFields.includes(label)) {
                            invalidFields.push(label);
                        }
                    }
                }
            }
        }

        return {
            isValid: invalidFields.length === 0,
            invalidFields
        };
    }
    
    // ─── Internal state ───────────────────────────────────────────────────────

    @track rows          = [];
    @track paginatedRows = [];
    @track columns       = [];
    @track isLoading     = false;
    @track copyPasteRows    = [];
    @track copyPasteColumns = [];

    _snapshot       = null;
    _tempIdCounter  = 0;
    currentPage     = 1;
    totalPages      = 1;
    disablePrevious = true;
    disableNext     = true;
    showPagination  = false;

    get isReadOnly() { return !this._canEdit; }

    connectedCallback() {
        this.columns = this._buildColumns();
    }

    // ─── Load ─────────────────────────────────────────────────────────────────

    _loadFromData() {
        const incoming = this._data.map(r => this._decorateNewRow(r));
        this.rows      = this._applyRolesAndConstraints(incoming);
        this._refreshDerivedState();
    }

    _decorateNewRow(row) {
        const hasRealId = isRealId(row.Id);
        return {
            ...row,
            Id      : hasRealId ? row.Id : this._newTempId(),
            _role   : ROLE_MIDDLE,
            _deleted: false,
            _isNew  : !hasRealId
        };
    }

    _newTempId() {
        this._tempIdCounter += 1;
        return `${TEMP_ID_PREFIX}${Date.now()}_${this._tempIdCounter}`;
    }

    _applyRolesAndConstraints(rowsArr) {
        const active = rowsArr.filter(r => !r._deleted);
        if (active.length === 0) return rowsArr;

        active.forEach((r, i) => {
            if (i === 0)                    r._role = ROLE_INIT;
            else if (i === active.length - 1) r._role = ROLE_END;
            else                             r._role = ROLE_MIDDLE;
        });

        // Lock first row date to initialDate and last row date to maturityDate
        if (active.length > 0 && this._initialDate) {
            active[0].gf_tenor_date__c = this._initialDate;
        }
        if (active.length > 1 && this._maturityDate) {
            const last = active[active.length - 1];
            last.gf_tenor_date__c = this._maturityDate;
            ALL_NUMERIC_FIELDS.forEach(f => { last[f] = 0; });
        }

        // Ensure no numeric field is null/empty
        active.forEach(r => {
            ALL_NUMERIC_FIELDS.forEach(f => {
                if (r[f] === '' || r[f] == null) r[f] = 0;
            });
        });

        return rowsArr;
    }

    _collapseToInitAndEnd() {
        if (!this.rows || this.rows.length === 0) return;
        this.rows = this.rows.map(r => {
            if (r._deleted)              return r;
            if (r._role === ROLE_MIDDLE) return { ...r, _deleted: true };
            return r;
        });
    }

    _applyContextToRows() {
        if (!this.rows || this.rows.length === 0) return;
        this.rows = this._applyRolesAndConstraints(this.rows.map(r => ({ ...r })));
        this._refreshDerivedState();
    }

    // ─── User actions ─────────────────────────────────────────────────────────

    handleRowAction(event) {
        const { action, row } = event.detail;
        const id = row.Id;
        switch (action.name) {
            case 'editRecord'  : this._handleEditClick();    break;
            case 'addRecord'   : this._handleAddRow(id);     break;
            case 'deleteRecord': this._requestDelete(id);    break;
            default: break;
        }
    }

    _handleEditClick() {
        this.dispatchEvent(new CustomEvent('editmodechange', {
            bubbles: true, composed: true, detail: { isEditMode: true }
        }));
    }

    _handleAddRow(afterId) {
        if (!this._canAddRows()) return;
        if (!this._isEditMode) {
            this.dispatchEvent(new CustomEvent('editmodechange', {
                bubbles: true, composed: true, detail: { isEditMode: true }
            }));
            this._snapshot = this.rows.map(r => ({ ...r }));
        }

        const newRow = {
            Id                       : this._newTempId(),
            DMT_Opportunity_Product__c: this.oppProduct || null,
            gf_tenor_date__c         : '',
            gj_nominal_amount_db__c  : 0,
            gf_nominal_amount_fb__c  : 0,
            gf_spread_db__c          : 0,
            gf_spread_fb__c          : 0,
            gf_accrual_fees_bp__c    : 0,
            gf_non_accrual_fees_bp__c: 0,
            _role   : ROLE_MIDDLE,
            _deleted: false,
            _isNew  : true
        };

        const idx      = this.rows.findIndex(r => r.Id === afterId);
        const insertAt = idx === -1 ? this.rows.length - 1 : idx + 1;
        const newArr   = [...this.rows];
        newArr.splice(insertAt, 0, newRow);
        this.rows = this._applyRolesAndConstraints(newArr);
        this._refreshDerivedState();
    }

    async _requestDelete(id) {
        const row = this.rows.find(r => r.Id === id);
        if (!row || row._role !== ROLE_MIDDLE) return;

        // New or in-edit rows are removed directly without confirmation
        if (row._isNew || this._isEditMode) {
            this._performDelete(id);
            return;
        }

        const result = await LightningConfirm.open({
            message: 'Delete this row? This action cannot be undone.',
            variant: 'header',
            label  : 'Confirm deletion',
            theme  : 'warning'
        });
        if (result) this._performDelete(id);
    }

    _performDelete(id) {
        const row = this.rows.find(r => r.Id === id);
        if (!row) return;

        if (row._isNew) {
            this.rows = this._applyRolesAndConstraints(this.rows.filter(r => r.Id !== id));
            this._refreshDerivedState();
            return;
        }

        if (this._isEditMode) {
            this.rows = this._applyRolesAndConstraints(
                this.rows.map(r => r.Id === id ? { ...r, _deleted: true } : r)
            );
            this._refreshDerivedState();
            return;
        }

        this.isLoading = true;
        deleteRecord(id)
            .then(() => {
                this._toast('Success', 'Row deleted successfully', 'success');
                this.dispatchEvent(new CustomEvent('recordsaved', { bubbles: true, composed: true }));
                this.rows = this._applyRolesAndConstraints(this.rows.filter(r => r.Id !== id));
                this._refreshDerivedState();
            })
            .catch(error => {
                this._toast('Error', 'Could not delete: ' + (error.body?.message || error.message), 'error');
                console.error('Error message:', error.body?.message || error.message);
                console.error('Full error:', JSON.parse(JSON.stringify(error)));
            })
            .finally(() => { this.isLoading = false; });
    }

    // ─── Paste ────────────────────────────────────────────────────────────────

    handlePasteData(event) {
        event.stopPropagation();
        const pasted = event.detail.data;
        if (!Array.isArray(pasted) || pasted.length === 0) return;
        if (this._isEditMode) {
            this._loadPastedRowsInMemory(pasted);
        } else {
            this._persistPastedRows(pasted);
        }
    }

    _loadPastedRowsInMemory(pasted) {
        const incoming = pasted.map(r => this._decorateNewRow(r));
        this.rows      = this._applyRolesAndConstraints(incoming);
        this._refreshDerivedState();
    }

    _persistPastedRows(pasted) {
        if (!this.oppProduct) {
            this._toast('Error', 'Cannot save: missing OpportunityLineItem.', 'error');
            return;
        }
        this.isLoading  = true;
        let rowsToSend  = JSON.parse(JSON.stringify(pasted));
        rowsToSend      = rowsToSend.map(row => ({
            ...row,
            gf_spread_db__c: this._clampDrawnSpreadBps(row.gf_spread_db__c)
        }));

        if (this._maturityDate) {
            const maturityRow = rowsToSend.find(r => r.gf_tenor_date__c === this._maturityDate);
            if (maturityRow) ALL_NUMERIC_FIELDS.forEach(f => { maturityRow[f] = 0; });
        }

        syncTenors({ payload: JSON.stringify({ oppLineItemId: this.oppProduct, tenorData: rowsToSend }) })
            .then(resultString => {
                const rawRows  = JSON.parse(resultString);
                const incoming = rawRows.map(r => this._decorateNewRow(r));
                this.rows      = this._applyRolesAndConstraints(incoming);
                this._refreshDerivedState();
                this._toast('Success', 'Tenors saved successfully!', 'success');
            })
            .catch(error => {
                this._toast('Error saving data', error.body?.message || error.message, 'error');
                console.error('Error message:', error.body?.message || error.message);
                console.error('Full error:', JSON.parse(JSON.stringify(error)));
            })
            .finally(() => { this.isLoading = false; });
    }

    _clampDrawnSpreadBps(value) {
        if (value === null || value === undefined || value === '') return 0;
        const parsed = typeof value === 'number' ? value : this._parseNumeric(value, false);
        if (parsed === null || Number.isNaN(parsed)) return 0;
        return parsed > MAX_DRAWN_SPREAD_BPS ? 0 : parsed;
    }

    // ─── Cell change ──────────────────────────────────────────────────────────

    handleCellInput(event) {
        event.stopPropagation();
        const { context: id, fieldname: field } = event.detail.data;
        let value = event.detail.data.value;
        const idx = this.rows.findIndex(r => r.Id === id);
        if (idx === -1) return;

        const row = this.rows[idx];
        if (row._role === ROLE_END) return;
        if (row._role === ROLE_INIT && field === 'gf_tenor_date__c') return;

        if (value === '') value = 0;

        if (NOMINAL_FIELDS.includes(field)) {
            value = this._parseNumeric(value, true);
        } else if (BPS_FIELDS.includes(field)) {
            value = this._parseNumeric(value, false);
            if (field === 'gf_spread_db__c' && value > MAX_DRAWN_SPREAD_BPS) {
                this._toast('Warning', `Drawn Spread (BPS) cannot exceed ${MAX_DRAWN_SPREAD_BPS}. Reset to 0.`, 'warning');
                value = 0;
            }
        }

        const newArr  = [...this.rows];
        newArr[idx]   = { ...row, [field]: value };
        this.rows     = newArr;
        this._refreshDerivedState();
    }

    // ─── Derived state ────────────────────────────────────────────────────────

    _refreshDerivedState() {
        this._updatePagination();
        this._updateCopyPasteData();
    }

    // ─── Pagination ───────────────────────────────────────────────────────────

    _updatePagination() {
        const visible = this.rows.filter(r => !r._deleted).map(r => this._decorateForDisplay(r));
        const total   = Math.ceil(visible.length / PAGE_SIZE) || 1;
        if (this.currentPage > total) this.currentPage = total;
        this.totalPages      = total;
        this.showPagination  = total > 1;
        this.disablePrevious = this.currentPage === 1;
        this.disableNext     = this.currentPage === total;
        const start          = (this.currentPage - 1) * PAGE_SIZE;
        this.paginatedRows   = visible.slice(start, start + PAGE_SIZE);
    }

    _decorateForDisplay(row) {
        const canInteract   = this._canEdit;
        const isUserDefined = this._amortizationType === AMORT_TYPE_USER_DEFINED;
        let deleteDisabled, editDisabled, addDisabled, lockDate;

        if (row._role === ROLE_INIT) {
            deleteDisabled = true;
            editDisabled   = !canInteract;
            addDisabled    = !(canInteract && isUserDefined);
            lockDate       = true;
        } else if (row._role === ROLE_END) {
            deleteDisabled = true;
            editDisabled   = true;
            addDisabled    = true;
            lockDate       = true;
        } else {
            deleteDisabled = !canInteract;
            editDisabled   = !canInteract;
            addDisabled    = !(canInteract && isUserDefined);
            lockDate       = false;
        }

        return {
            ...row,
            deleteDisabled,
            editDisabled,
            buttonDisabled: addDisabled,
            lockDate,
            aviableItem: row._role === ROLE_END
        };
    }

    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this._updatePagination();
        }
    }

    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this._updatePagination();
        }
    }

    // ─── Columns ──────────────────────────────────────────────────────────────

    _buildColumns() {
        const isEdit = this._isEditMode;
        return [
            {
                label    : 'Payment Date',
                fieldName: 'gf_tenor_date__c',
                type     : isEdit ? 'customdateRow' : 'date',
                hideDefaultActions: true,
                cellAttributes: { style: 'text-align: center;' },
                typeAttributes: {
                    aviableItem: { fieldName: 'aviableItem' },
                    dateValue  : { fieldName: 'gf_tenor_date__c' },
                    fieldName  : 'gf_tenor_date__c',
                    context    : { fieldName: 'Id' },
                    minDate    : this._initialDate,
                    maxDate    : this._maturityDate,
                    lockDate   : { fieldName: 'lockDate' }
                }
            },
            this._numericColumn('Drawn Amount',         'gj_nominal_amount_db__c',   true,  isEdit),
            this._numericColumn('Undrawn Amount',        'gf_nominal_amount_fb__c',   true,  isEdit),
            this._numericColumn('Drawn Spread (BPS)',      'gf_spread_db__c',           false, isEdit),
            this._numericColumn('Undrawn Spread (BPS)',    'gf_spread_fb__c',           false, isEdit),
            this._numericColumn('Non Accrual Fees (amount)',        'gf_accrual_fees_bp__c',     false, isEdit),
            this._numericColumn('Non Accrual Fees (BPS)',  'gf_non_accrual_fees_bp__c', false, isEdit),
            {
                type: 'button-icon', hideDefaultActions: true, initialWidth: 60,
                cellAttributes: { alignment: 'center' },
                typeAttributes: { iconName: 'utility:delete', label: ' ', variant: 'bare', name: 'deleteRecord', disabled: { fieldName: 'deleteDisabled' } }
            },
            {
                type: 'button-icon', hideDefaultActions: true, initialWidth: 60,
                cellAttributes: { alignment: 'center' },
                typeAttributes: { iconName: 'utility:edit', label: ' ', variant: 'bare', name: 'editRecord', disabled: { fieldName: 'editDisabled' } }
            },
            {
                type: 'button-icon', hideDefaultActions: true, initialWidth: 60,
                cellAttributes: { alignment: 'center' },
                typeAttributes: { iconName: 'utility:add', label: ' ', variant: 'bare', name: 'addRecord', disabled: { fieldName: 'buttonDisabled' } }
            }
        ];
    }

    _numericColumn(label, field, isCurrency, isEdit) {
        const baseType  = isEdit ? 'custominputRow' : (isCurrency ? 'currency' : 'text');
        const typeAttrs = {
            aviableItem: { fieldName: 'aviableItem' },
            inputValue : { fieldName: field },
            fieldName  : field,
            context    : { fieldName: 'Id' }
        };
        if (isCurrency) {
            typeAttrs.currencyCode      = this._currencyCode;
            typeAttrs.currencyDisplayAs = 'code';
            typeAttrs.step              = '0.001';
        }
        if (isEdit) {
            typeAttrs.validateNegative = true;
        }
        return { label, fieldName: field, type: baseType, hideDefaultActions: true, cellAttributes: { style: 'text-align: center;' }, typeAttributes: typeAttrs };
    }

    // ─── Copy / Paste ─────────────────────────────────────────────────────────

    _updateCopyPasteData() {
        this.copyPasteRows    = this.getCurrentRows().map(r => ({ ...r, amortizationType: this._amortizationType }));
        this.copyPasteColumns = this.columns
            .filter(c => c.type !== 'button' && c.type !== 'action' && c.type !== 'button-icon')
            .map(c => ({ ...c, editable: true }));
    }

    // ─── Numeric helpers ──────────────────────────────────────────────────────

    // Parses human-friendly numeric strings including K/M/B/T suffixes and mixed separators
    _parseNumeric(value, allowSuffix) {
        if (value === null || value === undefined || value === '') return 0;
        if (typeof value === 'number') return Number.isNaN(value) ? 0 : value;

        let raw        = String(value).trim().toUpperCase().replace(/\s+/g, '').replace(/€/g, '').replace(/\$/g, '');
        let multiplier = 1;

        const suffixMatch = raw.match(/([KMBT])$/);
        if (suffixMatch && allowSuffix) {
            const multipliers = { K: 1e3, M: 1e6, B: 1e9, T: 1e12 };
            multiplier = multipliers[suffixMatch[1]] || 1;
            raw        = raw.slice(0, -1);
        }

        const commaCount = (raw.match(/,/g) || []).length;
        const dotCount   = (raw.match(/\./g) || []).length;

        if (commaCount && dotCount) {
            const lastComma = raw.lastIndexOf(',');
            const lastDot   = raw.lastIndexOf('.');
            if (lastComma > lastDot) raw = raw.replace(/\./g, '').replace(',', '.');
            else                     raw = raw.replace(/,/g, '');
        } else if (commaCount === 1 && raw.split(',')[1].length <= 2) {
            raw = raw.replace(',', '.');
        } else if (commaCount) {
            raw = raw.replace(/,/g, '');
        } else if (dotCount > 1) {
            raw = raw.replace(/\./g, '');
        }

        const parsed = parseFloat(raw);
        if (Number.isNaN(parsed)) return 0;
        return parsed * multiplier;
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    _cleanRow(row) {
        const cleaned = {};
        for (const f of BUSINESS_FIELDS) {
            cleaned[f] = row[f] !== undefined ? row[f] : null;
        }
        if (isTempId(cleaned.Id)) cleaned.Id = null;
        return cleaned;
    }

    _canAddRows() {
        return this._amortizationType === AMORT_TYPE_USER_DEFINED;
    }

    _toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}