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
import DMT_Repayment_Schedule from  '@salesforce/label/c.DMT_Repayment_Schedule';

const EVENT_CLICK = 'click';
const MAX_DRAWN_SPREAD_BPS = 999;

export default class Dmt_table_tenors extends LightningElement {
    label= {DMT_Repayment_Schedule};

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
    get initialDate() { return this._initialDate; }
    set initialDate(value) {
        console.info('Initial Date set to:', value);
        if (value !== this._initialDate) {
            this._initialDate = value;
            this._handleContextChange(); // Trigger Reactivity
        }
    }

    @api
    get maturityDate() { return this._maturityDate; }
    set maturityDate(value) {
        console.info('Maturity Date set to:', value);
        if (value !== this._maturityDate) {
            this._maturityDate = value;
            this._handleContextChange(); // Trigger Reactivity
        }
    }

    @api
    get amortizationtype() { return this._amortizationType; }
    set amortizationtype(value) {
        console.info('Amortization Type set to:', value);
        if (value !== this._amortizationType) {
            this._amortizationType = value;
            this._handleContextChange(); // Trigger Reactivity
            
        }
    }

    @api
    get table() { return this.tableData; }
    set table(value) {
        console.log('🔵🔵🔵 [LWC-DEBUG 1] @api set table TRIGGERED (Receiving from FlexCard)');
        console.log('🔵🔵🔵 [LWC-DEBUG 1] RAW PAYLOAD: ', JSON.stringify(value));
        
        if (Array.isArray(value) && value.length > 1) {
            console.log('🔵🔵🔵 [LWC-DEBUG 1] Parent has data. Locking out Apex overwrite.');
            this._dataLoadedFromParent = true;
            this.tableData = this._decorateRows(value);
            this.setData(this.tableData);
        } else {
            console.log('🔵🔵🔵 [LWC-DEBUG 1] Parent data is empty or invalid. Array check failed.');
        }
    }

    // The Parent controls Edit Mode
    @api
    get isEditMode() { return this._isEditMode; }
    set isEditMode(value) {
        const newEditMode = (typeof value === 'boolean') ? value : (String(value).toLowerCase() === 'true');
        console.log('🟠🟠🟠 [LWC-DEBUG 2] @api set isEditMode TRIGGERED. Changing to: ' + newEditMode);
        
        if (this._isEditMode !== newEditMode) {
            this._isEditMode = newEditMode;
            this.setColumnsEdit();

            if (this.tableData && this.tableData.length > 0) {
                console.log('🟠🟠🟠 [LWC-DEBUG 2] Re-decorating rows for Edit Mode change...');
                const pureNativeData = this._cleanForParent(this.tableData);
                this.tableData = this._decorateRows(pureNativeData);
                this.setData(this.tableData);
            }
        }
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
            console.log('Currency --> ' + this._currency);
            this.columns = this.getColumnsDefinition();
            this.updateCopyPasteColumns();
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
                console.log('🟢🟢🟢 [LWC-DEBUG 3] loadData() TRIGGERED (Receiving from Apex)');
                console.log('🟢🟢🟢 [LWC-DEBUG 3] RAW APEX PAYLOAD: ', JSON.stringify(apexRows));

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
                        this.tableData = this._decorateRows(apexRows);
                        //update the data on the flexcard
                        this.dispatchEvent(new CustomEvent('tableTenorschange', { bubbles: true, composed: true, detail: { data: this._cleanForParent(this.tableData) } }));
                        this.setColumnsEdit();
                        this.setData(this.tableData);
                        return; // Keep Parent Data, exit.
                    }

                    console.warn('Parent data incomplete (Missing Init or Maturity). Forcing overwrite with Apex data.');
                }

                // OVERWRITE: Use Apex Data
                this.tableData = this._decorateRows(apexRows);
                //update the data on the flexcard
                this.dispatchEvent(new CustomEvent('tableTenorschange', { bubbles: true, composed: true, detail: { data: this._cleanForParent(this.tableData) } }));
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

    // Updates the table view and notifies parent without hitting DB
    _handleContextChange() {
        // Only run if we actually have data to update
        if (this.tableData && this.tableData.length > 0) {
            
            // 1. Re-run decoration. 
            // _decorateRows uses this._initialDate, this._maturityDate, and this._amortizationType
            // to inject values and set button states.
            this.tableData = this._decorateRows(this.tableData);
            
            // 2. Refresh Pagination/View
            this.setData(this.tableData);

            // 3. Notify Parent (FlexCard) of the updated list
            this.dispatchEvent(new CustomEvent('tableTenorschange', { 
                bubbles: true, 
                composed: true, 
                detail: { data: this._cleanForParent(this.tableData) } 
            }));
        }
    }

    // --- UI DECORATOR ---
    _decorateRows(rows) {
        if (!Array.isArray(rows)) return [];
        const decorated = JSON.parse(JSON.stringify(rows));
        const canEdit = !this.isTableLocked;

        decorated.forEach((r, index) => {
             // If Id is null (Apex placeholder) or empty, assign a temp ID.
             if (!r.Id) {
                 r.Id = `NEW_PH_${Date.now()}_${index}_${Math.random().toString(36).slice(2,5)}`;
                 r.__isTemp = true; // Mark as temp so we know to strip it later
             }

             if (r.Id && !r.updateKeyId && !String(r.Id).startsWith('NEW_')) {
                 r.updateKeyId = r.Id;
             }
        });

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

            if (this._initialDate) {
                first.gf_tenor_date__c = this._initialDate;
            }

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

            if (this._maturityDate) {
                last.gf_tenor_date__c = this._maturityDate;
            }

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
        if(this.isEditMode){
            let nominalFields = ['gj_nominal_amount_db__c', 'gf_nominal_amount_fb__c'];
            let bpsFields = ['gf_spread_db__c', 'gf_spread_fb__c', 'gf_accrual_fees_bp__c', 'gf_non_accrual_fees_bp__c'];
            
            decorated.forEach(row => {
                nominalFields.forEach(field => {
                    if (row[field] !== null && row[field] !== undefined && row[field] !== '') {
                        row[field] = this.formatForEditMode(row[field], false); // false = 0 decimals
                    }
                });
                bpsFields.forEach(field => {
                    if (row[field] !== null && row[field] !== undefined && row[field] !== '') {
                        row[field] = this.formatForEditMode(row[field], true); // true = up to 2 decimals
                    }
                });
            });
        }

        let bpsFields = ['gf_spread_db__c', 'gf_spread_fb__c', 'gf_accrual_fees_bp__c', 'gf_non_accrual_fees_bp__c'];
        decorated.forEach(row => {
            bpsFields.forEach(field => {
                if (row[field] !== null && row[field] !== undefined && row[field] !== '') {
                    row[field] = this.formatForEditMode(row[field], true); // true = up to 2 decimals
                }
            });
        });
        
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

        rowsToSend = rowsToSend.map(row => ({
            ...row,
            gf_spread_db__c: this._clampDrawnSpreadBps(row.gf_spread_db__c)
        }));

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
        let shouldForceSpreadRefresh = false;

        const id = event.detail.data.context;
        const field = event.detail.data.fieldname;
        const rowIndex = this.tableData.findIndex(r => r.Id === id);
        
        const nominalFields = ['gj_nominal_amount_db__c', 'gf_nominal_amount_fb__c'];
        const bpsFields = ['gf_spread_db__c', 'gf_spread_fb__c', 'gf_accrual_fees_bp__c', 'gf_non_accrual_fees_bp__c'];

        if (nominalFields.includes(field)) {
            val = this.formatNominalInput(val);
        } else if (bpsFields.includes(field)) {
            val = this.formatDecimalWithDots(val);

            if (field === 'gf_spread_db__c') {
                const parsed = this.parseAbbreviatedNumber(val, false);
                if (parsed !== null && parsed > MAX_DRAWN_SPREAD_BPS) {
                    val = 0;
                    shouldForceSpreadRefresh = true;
                    this.showToast('Warning', 'Drawn Spread (BPS) cannot exceed 999. Value was reset to 0.', 'warning');
                }
            }
        }

        if (rowIndex !== -1) {
            let row = { ...this.tableData[rowIndex] };
            if (field === 'gf_spread_db__c') {
                val = this._clampDrawnSpreadBps(val);
                if (shouldForceSpreadRefresh) {
                    row.__spreadResetNonce = Date.now();
                }
            }
            row[field] = val;
            this.tableData[rowIndex] = row;
            this.tableData = [...this.tableData];
            this.setData(this.tableData);

            this.dispatchEvent(new CustomEvent('tableTenorschange', {
                bubbles: true,
                composed: true,
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

        const nominalFields = ['gj_nominal_amount_db__c', 'gf_nominal_amount_fb__c'];
        const allFields = [
            'gj_nominal_amount_db__c',
            'gf_nominal_amount_fb__c',
            'gf_spread_db__c',
            'gf_spread_fb__c',
            'gf_accrual_fees_bp__c',
            'gf_non_accrual_fees_bp__c'
        ];

        allFields.forEach(f => {
            if (row[f] === '' || row[f] == null) {
                row[f] = 0;
            } else if (typeof row[f] === 'string') {
                const parsed = nominalFields.includes(f)
                    ? this.parseAbbreviatedNumber(row[f], true)
                    : this.parseAbbreviatedNumber(row[f], false);

                row[f] = parsed !== null ? parsed : 0;
            }
        });
    }

    _cleanForParent(rows) {
        const isRealId = (v) => !!v && v !== '0' && v !== 'END' && v !== 'INIT' && !String(v).startsWith('NEW_');        
        const nominalFields = ['gj_nominal_amount_db__c', 'gf_nominal_amount_fb__c'];

        const cleanedArray = (rows || []).map(r => {
            const { __role, __isTemp, __key, __spreadResetNonce, ...rest } = r || {};
            
            if (isRealId(rest.Id)) {
                if (!rest.updateKeyId) rest.updateKeyId = rest.Id;
            } else {
                rest.Id = null; 
                delete rest.updateKeyId; 
            }

            const numFields = [
                'gj_nominal_amount_db__c',
                'gf_nominal_amount_fb__c',
                'gf_spread_db__c',
                'gf_spread_fb__c',
                'gf_accrual_fees_bp__c',
                'gf_non_accrual_fees_bp__c'
            ];
            
            numFields.forEach(f => {
                const v = rest[f];

                if (v === '' || v === null || v === undefined) {
                    rest[f] = 0;
                } else if (typeof v === 'number') {
                    rest[f] = v;
                } else {
                    const parsed = nominalFields.includes(f)
                        ? this.parseAbbreviatedNumber(v, true)
                        : this.parseAbbreviatedNumber(v, false);

                    rest[f] = parsed !== null ? parsed : 0;
                }

                if (f === 'gf_spread_db__c') {
                    rest[f] = this._clampDrawnSpreadBps(rest[f]);
                }
            });

            return rest;
        });

        console.log('🟣🟣🟣 [LWC-DEBUG 4] _cleanForParent OUTBOUND PAYLOAD (Sending to FlexCard)');
        console.log('🟣🟣🟣 [LWC-DEBUG 4] CLEANED DATA: ', JSON.stringify(cleanedArray));
        
        return cleanedArray;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    // --- COLUMNS ---
    getColumnsDefinition() {
        const isEdit = this._isEditMode;
        console.log('Currency 2 -- > ' + this._currency);

        return [
            {
                label: 'Payment Date', fieldName: 'gf_tenor_date__c',
                type: isEdit ? 'customdateRow' : 'date',
                hideDefaultActions:true, cellAttributes:{style: 'text-align: center;'},
                typeAttributes: { aviableItem: {fieldName: 'aviableItem'}, dateValue: { fieldName: 'gf_tenor_date__c' }, fieldName: 'gf_tenor_date__c', context: { fieldName: 'Id' }, maxDate: { fieldName: 'maxDate'}, lockDate: { fieldName: 'lockDate' } }
            },
            {
                label: 'Notional Drawn', fieldName: 'gj_nominal_amount_db__c',
                type: isEdit ? 'custominputRow' : 'currency',
                hideDefaultActions:true, cellAttributes:{style: 'text-align: center;'},
                typeAttributes: { currencyCode: this._currency, currencyDisplayAs: 'code', step: '0.001', aviableItem: {fieldName: 'aviableItem'}, inputValue: { fieldName: 'gj_nominal_amount_db__c' }, fieldName: 'gj_nominal_amount_db__c', context: { fieldName: 'Id' } }
            },
            {
                label: 'Notional Undrawn', fieldName: 'gf_nominal_amount_fb__c',
                type: isEdit ? 'custominputRow' : 'currency',
                hideDefaultActions:true, cellAttributes:{style: 'text-align: center;'},
                typeAttributes: { currencyCode: this._currency, currencyDisplayAs: 'code', step: '0.001', aviableItem: {fieldName: 'aviableItem'}, inputValue: { fieldName: 'gf_nominal_amount_fb__c' }, fieldName: 'gf_nominal_amount_fb__c', context: { fieldName: 'Id' } }
            },
            {
                label: 'Drawn Spread (BPS)', fieldName: 'gf_spread_db__c',
                type: isEdit ? 'custominputRow' : 'text',
                hideDefaultActions:true, cellAttributes:{style: 'text-align: center;'},
                typeAttributes: { aviableItem: {fieldName: 'aviableItem'}, inputValue: { fieldName: 'gf_spread_db__c' }, fieldName: 'gf_spread_db__c', context: { fieldName: 'Id' }, resetNonce: { fieldName: '__spreadResetNonce' } }
            },
            {
                label: 'Undrawn Spread (BPS)', fieldName: 'gf_spread_fb__c',
                type: isEdit ? 'custominputRow' : 'text',
                hideDefaultActions:true, cellAttributes:{style: 'text-align: center;'},
                typeAttributes: { aviableItem: {fieldName: 'aviableItem'}, inputValue: { fieldName: 'gf_spread_fb__c' }, fieldName: 'gf_spread_fb__c', context: { fieldName: 'Id' } }
            },
            {
                label: 'Other Fees (BPS)', fieldName: 'gf_accrual_fees_bp__c',
                type: isEdit ? 'custominputRow' : 'text',
                hideDefaultActions:true, cellAttributes:{style: 'text-align: center;'},
                typeAttributes: { aviableItem: {fieldName: 'aviableItem'}, inputValue: { fieldName: 'gf_accrual_fees_bp__c' }, fieldName: 'gf_accrual_fees_bp__c', context: { fieldName: 'Id' } }
            },
            {
                label: 'Non Accrual Fees (BPS)', fieldName: 'gf_non_accrual_fees_bp__c',
                type: isEdit ? 'custominputRow' : 'text',
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

    formatDecimalWithDots(value) {
        if (value === null || value === undefined || value === '') return '';

        // 1. If it's a raw number loaded directly from the database
        if (typeof value === 'number') {
            return new Intl.NumberFormat('es-ES', { 
                minimumFractionDigits: 0, 
                maximumFractionDigits: 2,
                useGrouping: 'always' 
            }).format(value);
        }

        // 2. If it's a string (the user is actively typing)
        let strVal = value.toString().trim();
        
        // Does the string have a comma?
        let hasComma = strVal.includes(',');
        
        // Does the string have NO comma, but ends with a dot followed by 1 or 2 digits? (e.g., "1000.5" or "12500.78")
        let isEnglishDecimal = !hasComma && /\.\d{1,2}$/.test(strVal);

        if (hasComma || isEnglishDecimal) {
            // If they typed an English decimal, swap that specific dot to a comma for parsing
            if (isEnglishDecimal) {
                let lastDot = strVal.lastIndexOf('.');
                strVal = strVal.substring(0, lastDot) + ',' + strVal.substring(lastDot + 1);
            }

            // Split into Integer and Decimal parts
            let parts = strVal.split(',');
            let integerPart = parts[0].replace(/\D/g, '') || '0'; // Strip non-digits from integer
            let decimalPart = parts[1].replace(/\D/g, '').substring(0, 2); // Strip non-digits and enforce max 2 decimals

            // Format the integer part with thousands separators
            let formattedInteger = new Intl.NumberFormat('es-ES', { 
                useGrouping: 'always',
                minimumFractionDigits: 0,
                maximumFractionDigits: 2
            }).format(parseInt(integerPart, 10));

            return formattedInteger + ',' + decimalPart;
        } else {
            // It's a pure integer, OR a giant number with thousands dots already applied (e.g., "1.250.078")
            let integerPart = strVal.replace(/\D/g, '');
            if (!integerPart) return '';
            return new Intl.NumberFormat('es-ES', { 
                useGrouping: 'always',
                minimumFractionDigits: 0,
                maximumFractionDigits: 2
            }).format(parseInt(integerPart, 10));
        }
    }

    formatForEditMode(value, isBps) {
        if (value === null || value === undefined || value === '') return '';

        let num;

        if (isBps) {
            if (typeof value === 'number') {
                num = value;
            } else {
                const parsed = this.parseAbbreviatedNumber(value, false);
                num = parsed;
            }
        } else {
            num = this.parseAbbreviatedNumber(value, true);
        }

        if (num === null || Number.isNaN(num)) return value;

        return new Intl.NumberFormat('es-ES', {
            useGrouping: true,
            minimumFractionDigits: 0,
            maximumFractionDigits: isBps ? 2 : 0
        }).format(num);
    }
    parseAbbreviatedNumber(value, allowSuffix = false) {
        if (value === null || value === undefined || value === '') return null;
        if (typeof value === 'number') return Number.isNaN(value) ? null : value;

        let raw = String(value)
            .trim()
            .toUpperCase()
            .replace(/\s+/g, '')
            .replace(/€/g, '')
            .replace(/\$/g, '')
            .replace(/_/g, '')
            .replace(/'/g, '');

        if (!raw) return null;

        let multiplier = 1;
        const suffixMatch = raw.match(/([KMBT])$/);

        if (suffixMatch) {
            if (!allowSuffix) return null;

            const multipliers = {
                K: 1_000,
                M: 1_000_000,
                B: 1_000_000_000,
                T: 1_000_000_000_000
            };

            multiplier = multipliers[suffixMatch[1]] || 1;
            raw = raw.slice(0, -1);
        }

        if (!raw) return null;

        const commaCount = (raw.match(/,/g) || []).length;
        const dotCount = (raw.match(/\./g) || []).length;

        let normalized = raw;

        if (commaCount > 0 && dotCount > 0) {
            const lastComma = raw.lastIndexOf(',');
            const lastDot = raw.lastIndexOf('.');
            const decimalSeparator = lastComma > lastDot ? ',' : '.';

            if (decimalSeparator === ',') {
                normalized = raw.replace(/\./g, '').replace(',', '.');
            } else {
                normalized = raw.replace(/,/g, '');
            }
        }
        // Solo comas
        else if (commaCount > 0) {
            if (commaCount === 1) {
                const decimalPart = raw.split(',')[1] || '';
                if (decimalPart.length <= 2) {
                    normalized = raw.replace(',', '.');
                } else {
                    normalized = raw.replace(/,/g, '');
                }
            } else {
                normalized = raw.replace(/,/g, '');
            }
        }
        // Solo puntos
        else if (dotCount > 0) {
            if (dotCount === 1) {
                const decimalPart = raw.split('.')[1] || '';

                if (suffixMatch && decimalPart.length <= 2) {
                    normalized = raw;
                } else if (decimalPart.length === 3) {
                    normalized = raw.replace(/\./g, '');
                } else if (decimalPart.length <= 2) {
                    normalized = raw;
                } else {
                    normalized = raw.replace(/\./g, '');
                }
            } else {
                const lastDot = raw.lastIndexOf('.');
                const decimalPart = raw.slice(lastDot + 1);

                if (suffixMatch && decimalPart.length <= 2) {
                    normalized =
                        raw.slice(0, lastDot).replace(/\./g, '') +
                        '.' +
                        decimalPart;
                } else {
                    normalized = raw.replace(/\./g, '');
                }
            }
        }

        normalized = normalized.replace(/[^0-9.-]/g, '');

        if (!normalized || normalized === '.' || normalized === '-' || normalized === '-.') {
            return null;
        }

        const parsed = parseFloat(normalized);
        if (Number.isNaN(parsed)) return null;

        return parsed * multiplier;
    }

formatNominalInput(value) {
    const parsed = this.parseAbbreviatedNumber(value, true);
    if (parsed === null) return '';

    return new Intl.NumberFormat('es-ES', {
        useGrouping: true,
        minimumFractionDigits: 0,
        maximumFractionDigits: 2
    }).format(parsed);
}

    _clampDrawnSpreadBps(value) {
        if (value === null || value === undefined || value === '') return 0;

        const parsed = typeof value === 'number'
            ? value
            : this.parseAbbreviatedNumber(value, false);

        if (parsed === null || Number.isNaN(parsed)) return 0;
        return parsed > MAX_DRAWN_SPREAD_BPS ? 0 : parsed;
    }
    
}