import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { deleteRecord } from 'lightning/uiRecordApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import STAGE_NAME_FIELD from '@salesforce/schema/Opportunity.StageName';
import MATURITY_DATE_FIELD from '@salesforce/schema/OpportunityLineItem.gf_maturity_date__c';
import AMORTIZATION_TYPE_FIELD from '@salesforce/schema/OpportunityLineItem.gf_amortization_type__c';
import INITIAL_DATE_FIELD from '@salesforce/schema/OpportunityLineItem.gf_initial_date__c';
import CURRENCY_FIELD from '@salesforce/schema/OpportunityLineItem.g_currency_id__c';
import getTenorsData from '@salesforce/apex/DMT_TableTenors.getTenorsData';
import syncTenors from '@salesforce/apex/DMT_TableTenors.syncTenors';
import hasLineGodPermission from '@salesforce/customPermission/DMT_Line_God';
import calculateReadOnlyStatus from '@salesforce/apex/DMT_TableTenors.calculateReadOnlyStatus';

const EVENT_CLICK = 'click';

export default class Dmt_table_tenors extends LightningElement {

    // --- INPUTS (From FlexCard / Parent) ---
    _oppProduct;
    _recordId;
    _dataLoadedFromParent = false;

    // --- INTERNAL STATE ---
    @track tableData = [];
    @track paginatedData = [];
    @track columns = [];
    @track isLoading = false;

    // Internal Context
    _initialDate;
    _maturityDate;
    _amortizationType;
    _oppState;
    _currency;
    _isGodMode = false;
    _isReadOnlyUser = false;

    // Backing field for Edit Mode
    _isEditMode = false;

    // --- COPY PASTE VARIABLES ---
    // Kept as @track (Internal) because FlexCard shouldn't dictate these, the LWC generates them.
    @track rowstablecopypaste = [];
    @track columnstablecopypaste = [];

    // Pagination
    datatablePageSize = 10;
    currentPage = 1;
    totalPages = 0;
    showPagination = false;

    // Deletion Logic
    _pendingDeletes = new Set();

    // --- GETTERS & SETTERS ---

    @api
    get recordId() { return this._recordId; }
    set recordId(value) {
        this._recordId = value;
    }

    @api
    get oppProduct() { return this._oppProduct; }
    set oppProduct(value) {
        if (value && value !== this._oppProduct) {
            this._oppProduct = value;
            this.loadData();
        } else {
            this._oppProduct = value;
        }
    }

    @api
    get table() { return this.tableData; }
    set table(value) {
        if (Array.isArray(value) && value.length > 0) {
            console.log('Parent has data. Locking out Apex overwrite.');
            this._dataLoadedFromParent = true;
            this.tableData = this._decorateRows(value);
            this.setData(this.tableData);
        }
    }

    // [RESTORED] The Parent controls Edit Mode
    @api
    get isEditMode() { return this._isEditMode; }
    set isEditMode(value) {
        this._isEditMode = (typeof value === 'boolean') ? value : (String(value).toLowerCase() === 'true');
        this.setColumnsEdit();
    }

    // --- WIRE SERVICES ---

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state?.recordId || currentPageReference.state?.c__recordId || currentPageReference.attributes?.recordId;
        }
    }

    @wire(calculateReadOnlyStatus, { opportunityId: '$recordId' })
    wiredReadOnly({ error, data }) {
        if (data !== undefined) {
            console.log('LDS Calculated Read Only Status:', data);
            this._isReadOnlyUser = data;
            this.refreshTableLocking();
        } else if (error) {
            console.error('Error calculating read only status:', error);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [STAGE_NAME_FIELD] })
    wiredOpp({ error, data }) {
        if (data) {
            this._oppState = getFieldValue(data, STAGE_NAME_FIELD);
            console.log('LDS Loaded Stage:', this._oppState);
            this.refreshTableLocking();
        } else if (error) {
            console.error('LDS Error fetching stage:', error);
        }
    }

    @wire(getRecord, { recordId: '$_oppProduct', fields: [MATURITY_DATE_FIELD, AMORTIZATION_TYPE_FIELD, INITIAL_DATE_FIELD, CURRENCY_FIELD] })
    wiredOppLineItem({ error, data }) {
        if (data) {
            this._maturityDate = getFieldValue(data, MATURITY_DATE_FIELD);
            this._amortizationType = getFieldValue(data, AMORTIZATION_TYPE_FIELD);
            this._initialDate = getFieldValue(data, INITIAL_DATE_FIELD);
            this._currency = getFieldValue(data, CURRENCY_FIELD);
            console.log('LDS Fetched Line Item Info:', this._maturityDate, this._amortizationType);
            this.refreshTableLocking();
        } else if (error) {
            console.error('LDS Error fetching OLI:', error);
        }
    }

    refreshTableLocking() {
        if (this.tableData && this.tableData.length > 0) {
            this.tableData = this._decorateRows(this.tableData);
            this.setData(this.tableData);
        }
    }

    get isTableLocked() {
        const isDraftOrReady = (this._oppState === 'Draft' || this._oppState === 'Ready to close');
        const canEdit = isDraftOrReady && (this._isGodMode || !this._isReadOnlyUser);
        return !canEdit;
    }

    // --- LIFECYCLE ---

    connectedCallback() {
        this._isGodMode = hasLineGodPermission;
        this.columns = this.getColumnsDefinition();
        this.updateCopyPasteColumns();
        if (this._oppProduct && !this.isLoading) {
            this.loadData();
        }

        this._onGlobalClickCapture = () => {
            const active = this.template.activeElement || document.activeElement;
            try { if (active) active.blur(); } catch (e) { }
        };
        window.addEventListener(EVENT_CLICK, this._onGlobalClickCapture, true);
    }

    disconnectedCallback() {
        if (this._onGlobalClickCapture) {
            window.removeEventListener(EVENT_CLICK, this._onGlobalClickCapture, true);
            this._onGlobalClickCapture = null;
        }
    }

    // --- DATA LOADING ---

    loadData() {
        if (!this._oppProduct) return;
        this.isLoading = true;

        getTenorsData({ oppLineItemId: this._oppProduct })
            .then(result => {
                const apexRows = result.tenors || [];

                // VALIDATION: Does the Parent Data have the required Anchors?
                if (this._dataLoadedFromParent && apexRows.length > 0) {

                    // 1. Get "Truth" Dates from Apex (Guaranteed to be loaded)
                    const requiredInit = apexRows[0].gf_tenor_date__c;
                    const requiredMaturity = apexRows[apexRows.length - 1].gf_tenor_date__c;

                    // 2. Check if our current (Parent) table has these dates
                    const hasInit = this.tableData.some(r => r.gf_tenor_date__c === requiredInit);
                    const hasMaturity = this.tableData.some(r => r.gf_tenor_date__c === requiredMaturity);

                    // 3. Decision
                    if (hasInit && hasMaturity) {
                        console.log('Parent data is valid (Has Init & Maturity). Ignoring Apex.');
                        return; // Keep Parent Data, exit.
                    }

                    console.warn('Parent data incomplete (Missing Init or Maturity). Forcing overwrite with Apex data.');
                }

                // OVERWRITE: Use Apex Data
                this.tableData = this._decorateRows(apexRows);
                this.setColumnsEdit();
                this.setData(this.tableData);
            })
            .catch(error => {
                console.error('Error loading data', error);
                this.showToast('Error', 'Could not load Tenor Data: ' + (error.body?.message || error.message), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // --- UI DECORATOR ---
    _decorateRows(rows) {
        if (!Array.isArray(rows)) return [];
        const decorated = JSON.parse(JSON.stringify(rows));
        const canEdit = !this.isTableLocked;

        // Determine if Adding Rows is allowed globally for this table
        // Only 'User-Defined' allows adding rows. Others (Bullet, Linear) are fixed structure.
        const canAddRows = canEdit && (this._amortizationType === 'User-Defined');

        // 1. INIT ROW
        if (decorated.length > 0) {
            const first = decorated[0];
            first.__role = 'INIT';
            first.lockDate = true;
            first.aviableItem = false;
            first.deleteDisabled = true;
            first.editDisabled = !canEdit;
            first.buttonDisabled = !canAddRows;
            this._applyZeroDefaults(first);
        }

        // 2. END ROW
        if (decorated.length > 1) {
            const last = decorated[decorated.length - 1];
            last.__role = 'END';
            last.lockDate = true;
            last.aviableItem = true;
            last.deleteDisabled = true;
            last.editDisabled = true;
            last.buttonDisabled = true; // End row add is always disabled

            ['gj_nominal_amount_db__c','gf_nominal_amount_fb__c','gf_spread_db__c','gf_spread_fb__c','gf_accrual_fees_bp__c','gf_non_accrual_fees_bp__c']
                .forEach(f => last[f] = 0);
        }

        // 3. MIDDLE ROWS
        for (let i = 1; i < decorated.length - 1; i++) {
            const mid = decorated[i];
            if (mid.__role === 'INIT' || mid.__role === 'END') continue;

            mid.aviableItem = false;
            mid.buttonDisabled = !canAddRows;
            mid.editDisabled   = !canEdit;
            mid.deleteDisabled = !canEdit;
            this._applyZeroDefaults(mid);
        }

        return decorated;
    }

    // --- SAVING LOGIC ---

    handlePasteData(event) {
        event.stopPropagation();
        this.upsertTenorsList(event.detail.data);
    }

    upsertTenorsList(rows, isSilent = false) {
        if (!isSilent) this.isLoading = true;

        let rowsToSend = JSON.parse(JSON.stringify(rows));

        if (this._maturityDate) {
            const maturityRow = rowsToSend.find(r => r.gf_tenor_date__c === this._maturityDate);
            if (maturityRow) {
                ['gj_nominal_amount_db__c','gf_nominal_amount_fb__c','gf_spread_db__c','gf_spread_fb__c','gf_accrual_fees_bp__c','gf_non_accrual_fees_bp__c']
                    .forEach(f => maturityRow[f] = 0);
            }
        }

        const payload = { oppLineItemId: this._oppProduct, tenorData: rowsToSend };

        syncTenors({ payload: JSON.stringify(payload) })
            .then(resultString => {
                const rawRows = JSON.parse(resultString);
                this.tableData = this._decorateRows(rawRows);
                this.setData(this.tableData);

                if(this._isEditMode) this.setColumnsEdit();

                if (!isSilent) this.showToast('Success', 'Tenors saved successfully!', 'success');
                else console.log('Silent save completed.');
            })
            .catch(error => {
                console.error('Save failed:', error);
                if (!isSilent) {
                    this.showToast('Error saving data', error.body?.message || error.message, 'error');
                }
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // --- USER ACTIONS ---

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        switch (action.name) {
            case 'editRecord':
                this.isEditMode = !this.isEditMode; // Use setter to trigger update
                this.dispatchEvent(new CustomEvent('editModeTable', { bubbles: true, composed: true, detail: { editmodetable: this.isEditMode } }));
                break;

            case 'deleteRecord':
                if (row.gf_tenor_date__c === this._maturityDate || row.__role === 'END' || row.Id === 'END') return;

                const isTempRow = (!row.Id || row.Id.startsWith('NEW_'));

                if (isTempRow) {
                    this.tableData = this.tableData.filter(item => item.Id !== row.Id);
                    this.setData(this.tableData);
                    this.dispatchEvent(new CustomEvent('tableTenorschange', { bubbles: true, composed: true, detail: { data: this._cleanForParent(this.tableData) } }));
                } else {
                    this.isLoading = true;
                    deleteRecord(row.Id)
                        .then(() => {
                            this.showToast('Success', 'Record deleted', 'success');
                            this.tableData = this.tableData.filter(item => item.Id !== row.Id);
                            this.setData(this.tableData);
                            this.dispatchEvent(new CustomEvent('tableTenorschange', { bubbles: true, composed: true, detail: { data: this._cleanForParent(this.tableData) } }));
                        })
                        .catch(error => {
                            this.showToast('Error', 'Could not delete record: ' + (error.body?.message || error.message), 'error');
                        })
                        .finally(() => {
                            this.isLoading = false;
                        });
                }
                break;

            case 'addRecord':
                if (this._amortizationType && this._amortizationType !== 'User-Defined') return;

                const index = this.tableData.findIndex(dataRow => dataRow.Id === row.Id);
                const newRow = {
                    Id: `NEW_${Date.now()}_${Math.random().toString(36).slice(2,7)}`,
                    __isTemp: true,
                    gf_tenor_date__c: '',
                    gj_nominal_amount_db__c: 0,
                    gf_nominal_amount_fb__c: 0,
                    gf_spread_db__c: 0,
                    gf_spread_fb__c: 0,
                    gf_accrual_fees_bp__c: 0,
                    gf_non_accrual_fees_bp__c: 0,
                    DMT_Opportunity_Product__c: this._oppProduct,
                    buttonDisabled: false, deleteDisabled: false, editDisabled: false
                };

                const newData = [...this.tableData];
                newData.splice(index + 1, 0, newRow);

                this.tableData = this._decorateRows(newData);
                this.setData(this.tableData);

                // Force Edit Mode
                this.isEditMode = true; // Use setter

                this.dispatchEvent(new CustomEvent('tableTenorschange', { bubbles: true, composed: true, detail: { data: this._cleanForParent(this.tableData) } }));
                this.dispatchEvent(new CustomEvent('editModeTable', { bubbles:true, composed:true, detail:{ editmodetable:true }}));
                break;
        }
    }

    textInputChanged(event) {
        event.stopPropagation();
        let val = event.detail.data.value;
        if (val === '') val = 0;

        const id = event.detail.data.context;
        const field = event.detail.data.fieldname;
        const rowIndex = this.tableData.findIndex(r => r.Id === id);

        if (rowIndex !== -1) {
            let row = { ...this.tableData[rowIndex] };
            row[field] = val;
            this.tableData[rowIndex] = row;
            this.tableData = [...this.tableData];
            this.setData(this.tableData);

            this.dispatchEvent(new CustomEvent('tableTenorschange', {
                bubbles: true, composed: true,
                detail: { data: this._cleanForParent(this.tableData) }
            }));
        }
    }

    // --- HELPERS ---

    setData(data) {
        this.tableData = data || [];
        // 1. Clean rows for the parent/modal
        let cleanRows = this._cleanForParent(this.tableData);

        // 2. [INJECT] Amortization Type into every row for the Modal
        // This allows the generic Child Component to read the context from the data itself
        if (this._amortizationType) {
            cleanRows = cleanRows.map(row => ({
                ...row,
                amortizationType: this._amortizationType
            }));
        }

        this.rowstablecopypaste = cleanRows;
        const totalPages = Math.ceil(this.tableData.length / this.datatablePageSize) || 1;
        if (this.currentPage > totalPages) this.currentPage = totalPages;
        else if (!this.currentPage) this.currentPage = 1;

        this.totalPages = totalPages;
        this.showPagination = this.totalPages > 1;
        this.updatePaginatedData();
        this.updatePaginationButtons();
    }

    updatePaginatedData() {
        const start = (this.currentPage - 1) * this.datatablePageSize;
        const end = this.currentPage * this.datatablePageSize;
        this.paginatedData = this.tableData.slice(start, end);
    }

    updatePaginationButtons() {
        this.disablePrevious = this.currentPage === 1;
        this.disableNext = this.currentPage === this.totalPages;
    }

    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePaginatedData();
            this.updatePaginationButtons();
        }
    }

    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePaginatedData();
            this.updatePaginationButtons();
        }
    }

    _applyZeroDefaults(row) {
        if (!row) return;
        ['gj_nominal_amount_db__c','gf_nominal_amount_fb__c','gf_spread_db__c','gf_spread_fb__c','gf_accrual_fees_bp__c','gf_non_accrual_fees_bp__c'].forEach(f => {
            if (row[f] === '' || row[f] == null) row[f] = 0;
        });
    }

    _cleanForParent(rows) {
        const isRealId = (v) => !!v && v !== '0' && v !== 'END' && v !== 'INIT' && !String(v).startsWith('NEW_');
        return (rows || []).map(r => {
            const { __role, __isTemp, __key, ...rest } = r || {};
            if (!isRealId(rest.Id)) rest.Id = null;
            return rest;
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    // --- COLUMNS ---
    getColumnsDefinition() {
        const isEdit = this._isEditMode;

        return [
            {
                label: 'PAYMENT DATE', fieldName: 'gf_tenor_date__c',
                type: isEdit ? 'customdateRow' : 'date',
                hideDefaultActions:true, cellAttributes:{style: 'text-align: center;'},
                typeAttributes: { aviableItem: {fieldName: 'aviableItem'}, dateValue: { fieldName: 'gf_tenor_date__c' }, fieldName: 'gf_tenor_date__c', context: { fieldName: 'Id' }, maxDate: { fieldName: 'maxDate'}, lockDate: { fieldName: 'lockDate' } }
            },
            {
                label: 'DRAWN NOTIONAL AMOUNT', fieldName: 'gj_nominal_amount_db__c',
                type: isEdit ? 'custominputRow' : 'currency',
                hideDefaultActions:true, cellAttributes:{style: 'text-align: center;'},
                typeAttributes: { currencyCode: this._currency, step: '0.001', aviableItem: {fieldName: 'aviableItem'}, inputValue: { fieldName: 'gj_nominal_amount_db__c' }, fieldName: 'gj_nominal_amount_db__c', context: { fieldName: 'Id' } }
            },
            {
                label: 'UNDRAWN NOTIONAL AMOUNT', fieldName: 'gf_nominal_amount_fb__c',
                type: isEdit ? 'custominputRow' : 'currency',
                hideDefaultActions:true, cellAttributes:{style: 'text-align: center;'},
                typeAttributes: { currencyCode: this._currency, step: '0.001', aviableItem: {fieldName: 'aviableItem'}, inputValue: { fieldName: 'gf_nominal_amount_fb__c' }, fieldName: 'gf_nominal_amount_fb__c', context: { fieldName: 'Id' } }
            },
            {
                label: 'DRAWN SPREAD (BPS)', fieldName: 'gf_spread_db__c',
                type: isEdit ? 'custominputRow' : 'number',
                hideDefaultActions:true, cellAttributes:{style: 'text-align: center;'},
                typeAttributes: { aviableItem: {fieldName: 'aviableItem'}, inputValue: { fieldName: 'gf_spread_db__c' }, fieldName: 'gf_spread_db__c', context: { fieldName: 'Id' } }
            },
            {
                label: 'UNDRAWN SPREAD (BPS)', fieldName: 'gf_spread_fb__c',
                type: isEdit ? 'custominputRow' : 'number',
                hideDefaultActions:true, cellAttributes:{style: 'text-align: center;'},
                typeAttributes: { aviableItem: {fieldName: 'aviableItem'}, inputValue: { fieldName: 'gf_spread_fb__c' }, fieldName: 'gf_spread_fb__c', context: { fieldName: 'Id' } }
            },
            {
                label: 'OTHER FEES (BPS)', fieldName: 'gf_accrual_fees_bp__c',
                type: isEdit ? 'custominputRow' : 'number',
                hideDefaultActions:true, cellAttributes:{style: 'text-align: center;'},
                typeAttributes: { aviableItem: {fieldName: 'aviableItem'}, inputValue: { fieldName: 'gf_accrual_fees_bp__c' }, fieldName: 'gf_accrual_fees_bp__c', context: { fieldName: 'Id' } }
            },
            {
                label: 'NON ACCRUAL FEES (BPS)', fieldName: 'gf_non_accrual_fees_bp__c',
                type: isEdit ? 'custominputRow' : 'number',
                hideDefaultActions:true, cellAttributes:{style: 'text-align: center;'},
                typeAttributes: { aviableItem: {fieldName: 'aviableItem'}, inputValue: { fieldName: 'gf_non_accrual_fees_bp__c' }, fieldName: 'gf_non_accrual_fees_bp__c', context: { fieldName: 'Id' } }
            },
            {
                type: 'button', hideDefaultActions:true, initialWidth: 60, cellAttributes: { alignment: 'center' },
                typeAttributes: { iconName: 'utility:delete', label: ' ', name: 'deleteRecord', title: '', disabled: {fieldName: 'deleteDisabled'} }
            },
            {
                type: 'button', hideDefaultActions:true, initialWidth: 60, cellAttributes: { alignment: 'center' },
                typeAttributes: { iconName: 'utility:edit', label: ' ', name: 'editRecord', title: '', disabled: {fieldName: 'editDisabled'} }
            },
            {
                type: 'button', hideDefaultActions:true, initialWidth: 60, cellAttributes: { alignment: 'center' },
                typeAttributes: { iconName: 'utility:add', label: '    ', name: 'addRecord', title: '        ', disabled: {fieldName: 'buttonDisabled'} }
            }
        ];
    }

    setColumnsEdit(){
        this.columns = this.getColumnsDefinition();

        this.updateCopyPasteColumns();
    }

    updateCopyPasteColumns() {
        // 1. Filter out buttons/actions
        // 2. Map over the remaining columns and force 'editable: true'
        //    (This satisfies the Copy/Paste component check without affecting main table)
        this.columnstablecopypaste = this.columns
            .filter(col => col.type !== 'button' && col.type !== 'action')
            .map(col => {
                return { ...col, editable: true };
            });
    }
}