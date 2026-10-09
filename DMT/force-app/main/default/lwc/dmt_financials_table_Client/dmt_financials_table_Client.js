import { LightningElement, api, track } from 'lwc';
import LightningConfirm from 'lightning/confirm';
import pubsub from 'omnistudio/pubsub';

import getFinancialsByOpportunity from '@salesforce/apex/DMT_FinancialsNewController.getFinancialsByOpportunity';
import getFinancialsByClient from '@salesforce/apex/DMT_FinancialsNewController.getFinancialsByClient';
import getFinancialsAccountComparison from '@salesforce/apex/DMT_FinancialsNewController.getFinancialsAccountComparison';
import saveFinancials from '@salesforce/apex/DMT_FinancialsNewController.saveFinancials';

import DMT_modify_financials_table from '@salesforce/label/c.DMT_modify_financials_table';
import DTM_overwrite_confirmation from '@salesforce/label/c.DTM_overwrite_confirmation';

const EVENT_SAVE = 'Save';
const EVENT_BUTTON = 'Button';
const EVENT_SET = 'Set';
const NA_VALUE = 'N/A';
const ERROR_INVALID_UPDATE = 'Error in data saving.';
const ERROR_INVALID_LOADING = 'Error loading data.';

/**
 * Row definitions: label shown in UI -> API field on DMT_Opportunity_Business_Plan__c.
 * One field per metric; the year dimension is handled by DMT_Year__c on the record.
 */
const ROW_DEFINITIONS = [
    { label: 'Revenues',          apiField: 'DMT_Revenues_number__c' },
    { label: 'EBITDA',            apiField: 'DMT_EBITDA_number__c' },
    { label: 'EBIT',              apiField: 'DMT_EBIT_number__c' },
    { label: 'Net Income',        apiField: 'DMT_Net_Income_number__c' },
    { label: 'Free Cash Flow',    apiField: 'DMT_Free_Cash_Flow_number__c' },
    { label: 'Debt / EBITDA',     apiField: 'DMT_Debt_EBITDA_number__c' },
    { label: 'Net Debt / EBITDA', apiField: 'DMT_Net_Debt_EBITDA_number__c' }
];

const YEAR_COLUMNS = ['pastYear2', 'pastYear', 'currentYear', 'nextYear', 'nextYear2'];

const MILLION = 1000000;

// Redondea para evitar los decimales basura de JS: 1.1 * 1000000 = 1100000.0000000002
function toRealAmount(value) {
    const num = Number(value);
    return Number.isNaN(num) ? null : Math.round(num * MILLION);
}

// Importe real (BBDD) -> millones (pantalla)
function toMillions(value) {
    return Number(value) / MILLION;
}

export default class DmtFinancialsTableClient extends LightningElement {

    _recordId;
    _opportunityClientId;
    _groupId;
    _isClient = false;
    _isOpportunity = false;
    _isEditMode = false;
    _isReadOnly = false;
    _isOppView = false;
    _stageName;
    _closeDate;
    _isClosed = false;

    // Year-record model state
    _allRecords = null;
    _allAccountRecords = null;
    _yearRecordIds = { pastYear2: null, pastYear: null, currentYear: null, nextYear: null, nextYear2: null };
    _preloadedRecordsMode = false;

    @track originalData;
    @track data;
    @track processedData;
    isDataProcessed = false;

    label = {
        DMT_modify_financials_table,
        DTM_overwrite_confirmation
    }

    // --- Public API properties ---

    @api
    set isOppView(value) {
        this._isOppView = (value == 'true' || value === true);
    }
    get isOppView() {
        return this._isOppView;
    }

    @api
    get stageName() { return this._stageName; }
    set stageName(value) { this._stageName = value; }

    @api
    get closeDate() {
        return this._closeDate;
    }

    set closeDate(value) {
        this._closeDate = value;
    }

    @api
    get isClosed() {
        return this._isClosed;
    }

    set isClosed(value) {
        this._isClosed = value === true || value === 'true';
    }

    get isEditPencilEnabled() {
        if (this._isReadOnly) return false;
        if (this._isClient) return true;
        return this._stageName === 'Draft' || this._stageName === 'Proposal';
    }

    @api
    get recordId() { return this._recordId; }
    set recordId(value) {
        this._recordId = value;
        if (!this._preloadedRecordsMode) this.loadFinancialData();
    }

    @api
    get groupId() { return this._groupId; }
    set groupId(value) {
        this._groupId = value;
        if (!this._preloadedRecordsMode) this.loadFinancialData();
    }

    @api
    get opportunityClientId() { return this._opportunityClientId; }
    set opportunityClientId(value) { this._opportunityClientId = value; }

    @api
    get isOpportunity() { return this._isOpportunity; }
    set isOpportunity(value) {
        this._isOpportunity = (value == 'true' || value === true);
        if (!this._preloadedRecordsMode) this.loadFinancialData();
    }

    get showUndo() {
        return this._isOpportunity && !this._isReadOnly;
    }

    @api
    get isClient() { return this._isClient; }
    set isClient(value) {
        this._isClient = (value == 'true' || value === true);
        if (!this._preloadedRecordsMode) this.loadFinancialData();
    }

    @api
    get isReadOnlyUser() { return this._isReadOnly; }
    set isReadOnlyUser(value) {
        this._isReadOnly = (value === true || value === 'true');
        if (this.processedData) {
            const shouldEdit = this._isEditMode && !this._isReadOnly;
            this.toggleEditMode(shouldEdit);
        }
    }

    @api
    get isEditMode() { return this._isEditMode; }
    set isEditMode(value) {
        const wasEditing = this._isEditMode;
        this._isEditMode = (value === true || value === 'true');
        if (wasEditing && !this._isEditMode) {
            if (this.processedData) this.toggleEditMode(false);
        }
        if (this._isEditMode && this.processedData) {
            this.toggleEditMode(true);
        }
    }

    /**
     * Preloaded records mode: parent provides DMT_Opportunity_Business_Plan__c records.
     * Enables parent-driven save flow (Opportunity case).
     */
    @api
    get preloadedRecords() { return this._allRecords; }
    set preloadedRecords(value) {
        if (!Array.isArray(value)) return;
        if (value === this._allRecords) return;
        this._preloadedRecordsMode = true;
        this._allRecords = value;
        this._buildTableData();
    }

    /**
     * Allows the parent to supply Account comparison records for Redo.
     */
    @api
    get preloadedAccountRecords() { return this._allAccountRecords; }
    set preloadedAccountRecords(value) {
        if (!Array.isArray(value)) return;
        if (value === this._allAccountRecords) return;
        this._allAccountRecords = value;
        if (this._allRecords) this._buildTableData();
    }

    // --- Computed properties ---

    /**
     * Obtiene el primer año que debe mostrarse.
     * A partir del 1 de septiembre se avanza un año.
     * Las oportunidades cerradas utilizan su fecha de cierre.
     */
    _getFirstDisplayedYear() {
        let referenceDate = new Date();

        const isClosedOpportunity =
            this._isOpportunity && this._isClosed;

        if (isClosedOpportunity && this._closeDate) {
            const [year, month, day] =
                this._closeDate.split('-').map(Number);

            referenceDate = new Date(
                year,
                month - 1,
                day
            );
        }

        return referenceDate.getMonth() >= 9
            ? referenceDate.getFullYear() - 1
            : referenceDate.getFullYear() - 2;
    }

    get _yearColumnMap() {
        const firstYear = this._getFirstDisplayedYear();

        const columns = [
            'pastYear2',
            'pastYear',
            'currentYear',
            'nextYear',
            'nextYear2'
        ];

        const result = {};

        for (let index = 0; index < columns.length; index++) {
            result[firstYear + index] = columns[index];
        }

        return result;
    }

    get columns() {
        const firstYear = this._getFirstDisplayedYear();

        return [
            {
                label: '',
                fieldName: 'category',
                type: 'text',
                isEditable: false
            },
            {
                label: String(firstYear),
                fieldName: 'pastYear2',
                type: 'text',
                isEditable: true
            },
            {
                label: `${firstYear + 1} (optional)`,
                fieldName: 'pastYear',
                type: 'text',
                isEditable: true
            },
            {
                label: `${firstYear + 2} (optional)`,
                fieldName: 'currentYear',
                type: 'text',
                isEditable: true
            },
            {
                label: `${firstYear + 3} (optional)`,
                fieldName: 'nextYear',
                type: 'text',
                isEditable: true
            },
            {
                label: `${firstYear + 4} (optional)`,
                fieldName: 'nextYear2',
                type: 'text',
                isEditable: true
            }
        ];
    }

    get copyPasteColumns() {
        return this.columns.map(col => ({
            label: col.label || 'Category',
            fieldName: col.fieldName,
            type: 'text',
            editable: true
        }));
    }

    get copyPasteRows() {
        if (!this.data) return [];
        return this.data.map(row => ({
            ...row,
            pastYear2: row.pastYear2 === NA_VALUE ? '' : row.pastYear2,
            pastYear: row.pastYear === NA_VALUE ? '' : row.pastYear,
            currentYear: row.currentYear === NA_VALUE ? '' : row.currentYear,
            nextYear: row.nextYear === NA_VALUE ? '' : row.nextYear,
            nextYear2: row.nextYear2 === NA_VALUE ? '' : row.nextYear2
        }));
    }

    get isCopyPasteDisabled() {
        return !this.isEditPencilEnabled;
    }

    // --- Lifecycle ---

    connectedCallback() {
        this.eventHandlers = {
            DMT_CLIENT_GROUP_V2: this.handleSave.bind(this)
        };
        pubsub.register(EVENT_SAVE, this.eventHandlers);
    }

    disconnectedCallback() {
        pubsub.unregister(EVENT_SAVE, this.eventHandlers);
    }

    // --- Data loading ---

    loadFinancialData() {
        if (this._preloadedRecordsMode) return;

        if (this._isClient && this._isValidSalesforceId(this._recordId)) {
            this._fetchFinancialsClient();
        }
        if (this._isOpportunity && this._isValidSalesforceId(this._recordId)) {
            this._fetchFinancialsOpportunity();
        }
    }

    async _fetchFinancialsOpportunity() {
        try {
            const records = await getFinancialsByOpportunity({ recordId: this._recordId });
            this._allRecords = records || [];

            // Load account comparison records for Redo
            let accountId = this._groupId;
            if (!accountId && records && records.length > 0) {
                const withAccount = records.find(r => r.DMT_Opportunity__r && r.DMT_Opportunity__r.AccountId);
                if (withAccount) accountId = withAccount.DMT_Opportunity__r.AccountId;
            }
            if (accountId) {
                try {
                    this._allAccountRecords = await getFinancialsAccountComparison({ accountId });
                } catch (e) {
                    this._allAccountRecords = [];
                }
            }

            this._buildTableData();
            if (this._isEditMode) this.toggleEditMode(true);
        } catch (error) {
            this.data = [];
            this.processDataForView();
            pubsub.fire(EVENT_SET, 'Error', { errorMessage: ERROR_INVALID_LOADING });
            console.error('[Financials] Error loading opportunity data:', error);
        }
    }

    async _fetchFinancialsClient() {
        try {
            const records = await getFinancialsByClient({ clientId: this._recordId });
            this._allRecords = records || [];
            this._buildTableData();
            if (this._isEditMode) this.toggleEditMode(true);
        } catch (error) {
            this.data = [];
            this.processDataForView();
            pubsub.fire(EVENT_SET, 'Error', { errorMessage: ERROR_INVALID_LOADING });
            console.error('[Financials] Error loading client data:', error);
        }
    }

    // --- Year-record model -> table data transformation ---

    _toDisplayValue(record, rowDef) {
        const raw = record ? record[rowDef.apiField] : null;
        return raw == null ? NA_VALUE : toMillions(raw);
    }

    _buildTableData() {
        const yearColMap = this._yearColumnMap;

        // Index records by year column
        const recordByCol = {};
        YEAR_COLUMNS.forEach(c => { recordByCol[c] = null; });
        (this._allRecords || []).forEach(rec => {
            const col = yearColMap[Number(rec.DMT_Year__c)];
            if (col) recordByCol[col] = rec;
        });

        // Store record IDs for save
        this._yearRecordIds = {};
        YEAR_COLUMNS.forEach(col => {
            this._yearRecordIds[col] = recordByCol[col] ? recordByCol[col].Id : null;
        });

        // Index account comparison records
        const accountRecordByCol = {};
        (this._allAccountRecords || []).forEach(rec => {
            const col = yearColMap[Number(rec.DMT_Year__c)];
            if (col) accountRecordByCol[col] = rec;
        });

        // Build data rows
        this.data = ROW_DEFINITIONS.map((rowDef, index) => {
            const row = {
                Id: index,
                category: rowDef.label,
                isEditable: true,
                hasChanged: false
            };
            YEAR_COLUMNS.forEach(col => {
                row[col] = this._toDisplayValue(recordByCol[col], rowDef);
                // Account comparison
                if (this._isOpportunity) {
                    row[col + 'Account'] = this._toDisplayValue(accountRecordByCol[col], rowDef);
                }
            });
            return row;
        });

        this.originalData = JSON.parse(JSON.stringify(this.data));
        this.processDataForView();
    }

    // --- UI rendering ---

    processDataForView() {
        this.processedData = this.data.map(row => ({
            ...row,
            values: this.columns.map(column => {
                const value = row[column.fieldName];
                const accountValueRaw = row[column.fieldName + 'Account'];
                const hasComparisonValue = accountValueRaw !== undefined && accountValueRaw !== null
                    && accountValueRaw !== '' && accountValueRaw !== NA_VALUE;
                const accountValue = hasComparisonValue ? accountValueRaw : NA_VALUE;

                return {
                    field: column.fieldName,
                    label: column.label,
                    value: value,
                    accountValue: accountValue,
                    isEquals: hasComparisonValue ? accountValue == value : true,
                    hasComparisonValue: hasComparisonValue,
                    isEditing: false,
                    isEditable: column.isEditable && row.isEditable,
                    styleRedo: hasComparisonValue && accountValue !== value ? '' : 'display:none;',
                    withoutRedo: hasComparisonValue && accountValue === value ? 'margin-top: 40% !important;' : '',
                    cellClass: 'slds-has-button slds-has-flexi-truncate'
                };
            })
        }));
        this.isDataProcessed = true;
    }

    toggleEditMode(isEditing) {
        this._isEditMode = isEditing;
        if (this.processedData) {
            this.processedData = this.processedData.map(row => {
                row.values = row.values.map(cell => {
                    cell.isEditing = isEditing && cell.isEditable;
                    if (isEditing && cell.isEditable && cell.value === NA_VALUE) {
                        cell.value = '';
                    } else if (!isEditing && cell.isEditable && (cell.value === '' || cell.value == null)) {
                        cell.value = NA_VALUE;
                    }
                    return cell;
                });
                return row;
            });
        }
    }

    // --- Event handlers ---

    handleEdit() {
        if (!this.isEditPencilEnabled) return;
        this._isEditMode = true;
        this.toggleEditMode(true);
        // Notify parent via DOM event (Opportunity preloaded mode) or pubsub (Account/FlexCard mode)
            this.dispatchEvent(new CustomEvent('editmodechange', { bubbles: true, composed: true }));
            pubsub.fire(EVENT_BUTTON, 'Edit', {});
    }

    handleInputChange(event) {
        const { id, field } = event.target.dataset;
        const newValue = event.target.value;

        const rowIndex = this.data.findIndex(row => row.Id == id);
        if (rowIndex !== -1) {
            this.data[rowIndex] = { ...this.data[rowIndex], [field]: newValue, hasChanged: true };
        }

        // Sync processedData for immediate UI feedback
        const pRowIndex = this.processedData.findIndex(row => row.Id == id);
        if (pRowIndex !== -1) {
            const cell = this.processedData[pRowIndex].values.find(c => c.field === field);
            if (cell) cell.value = newValue;
        }

        this.dispatchEvent(new CustomEvent('fieldchange', { bubbles: true, composed: true }));
    }

    async handleRedoAllTable() {
        try {
            const result = await LightningConfirm.open({
                message: this.label.DTM_overwrite_confirmation,
                label: 'Confirmation of Change',
                theme: 'alt-inverse'
            });
            if (result) {
                this._redoAllFromAccount();
            }
        } catch (e) {
            console.error('Error showing LightningConfirm:', e);
        }
    }

    handleRedo(event) {
        const { id: rowId, field: fieldName } = event.target.dataset;
        const row = this.data.find(r => r.Id == rowId);
        if (!row) return;

        const accountValue = row[fieldName + 'Account'];
        if (accountValue === undefined || accountValue === NA_VALUE) return;

        row[fieldName] = accountValue;
        row.hasChanged = true;

        this.processDataForView();
        if (this._isEditMode) this.toggleEditMode(true);

        if (this._preloadedRecordsMode) {
            this.dispatchEvent(new CustomEvent('redosave'));
        } else {
            this.handleSave();
        }
    }

    _redoAllFromAccount() {
        if (!this.data) return;

        this.data = this.data.map(row => {
            let changed = false;
            YEAR_COLUMNS.forEach(col => {
                const accountValue = row[col + 'Account'];
                if (accountValue !== undefined && accountValue !== NA_VALUE) {
                    row[col] = accountValue;
                    changed = true;
                }
            });
            if (changed) row.hasChanged = true;
            return row;
        });

        this.processDataForView();
        if (this._isEditMode) this.toggleEditMode(true);

        if (this._preloadedRecordsMode) {
            this.dispatchEvent(new CustomEvent('redosave'));
        } else {
            this.handleSave();
        }
    }

    // --- Save logic ---

    /**
     * Builds update objects from changed data rows (year-record model).
     * Returns an array of record objects for upsert.
     */
    buildUpdateObject(changedRows) {
        const reverseYearMap = {};
        Object.entries(this._yearColumnMap).forEach(([year, col]) => { reverseYearMap[col] = Number(year); });

        const updatesByCol = {};
        YEAR_COLUMNS.forEach(col => {
            const recordId = this._yearRecordIds ? this._yearRecordIds[col] : null;
            if (recordId) {
                updatesByCol[col] = { Id: recordId };
            } else {
                updatesByCol[col] = {
                    DMT_Year__c: reverseYearMap[col],
                    DMT_Booking_Geography__c: 'GLOBAL'
                };
                if (this._isOpportunity && this._recordId) {
                    updatesByCol[col].DMT_Opportunity__c = this._recordId;
                }
                if (this._isClient && this._recordId) {
                    updatesByCol[col].DMT_Client__c = this._recordId;
                }
            }
        });

        changedRows.forEach(row => {
            const originalRow = this.originalData.find(orig => orig.Id === row.Id);
            if (!originalRow) return;
            const rowDef = ROW_DEFINITIONS.find(rd => rd.label === originalRow.category);
            if (!rowDef) return;

            YEAR_COLUMNS.forEach(col => {
                if (!updatesByCol[col]) return;
                if (row[col] != originalRow[col]) {
                    const value = row[col];
                    const isEmpty = value == NA_VALUE || value === '' || value == null;
                    updatesByCol[col][rowDef.apiField] = isEmpty ? null : toRealAmount(value);
                }
            });
        });

        // Only return objects with actual field changes
        const CONTEXT_FIELDS = new Set(['Id', 'DMT_Year__c', 'DMT_Booking_Geography__c', 'DMT_Opportunity__c', 'DMT_Client__c']);
        return Object.values(updatesByCol).filter(u =>
            Object.keys(u).some(k => !CONTEXT_FIELDS.has(k))
        );
    }

    /**
     * Collects financials changes for the parent-driven save flow (Opportunity).
     * Returns an array of update objects compatible with Apex upsert.
     */
    @api
    collectFinancialsChanges() {
        if (!this.data) return [];
        const changedRows = this.data.filter(row => row.hasChanged);
        if (changedRows.length === 0) return [];
        return this.buildUpdateObject(changedRows);
    }

    @api
    collectChanges() {
        const changed = this.data ? this.data.filter(r => r.hasChanged) : [];
        return changed.length > 0 ? { _financialsTableHasChanges: true } : {};
    }

    @api
    get hasPendingChanges() {
        return this.data ? this.data.some(row => row.hasChanged) : false;
    }

    @api
    clearPendingEdits() {
        if (this.data) {
            this.data = this.data.map(row => ({ ...row, hasChanged: false }));
            this.originalData = JSON.parse(JSON.stringify(this.data));
        }
    }

    @api
    restoreSnapshot() {
        this.data = JSON.parse(JSON.stringify(this.originalData));
        this.processDataForView();
        if (this._isEditMode) this.toggleEditMode(true);
    }

    @api
    commitEdit() {
        this.originalData = JSON.parse(JSON.stringify(this.data));
        this.data.forEach(r => { r.hasChanged = false; });
        this.processDataForView();
        if (this._isEditMode) this.toggleEditMode(true);
    }

    /**
     * Standalone save (FlexCard/PubSub or direct call).
     */
    @api
    async handleSave() {
        const changedRows = this.data ? this.data.filter(row => row.hasChanged) : [];
        if (changedRows.length === 0) return;

        // In preloaded-records mode, the parent owns the save lifecycle
        if (this._preloadedRecordsMode) {
            this.dispatchEvent(new CustomEvent('redosave'));
            return;
        }

        this.isDataProcessed = false;
        const updates = this.buildUpdateObject(changedRows);

        try {
            await saveFinancials({ financialsJson: JSON.stringify(updates) });

            this.data = this.data.map(row => ({ ...row, hasChanged: false }));
            this.originalData = JSON.parse(JSON.stringify(this.data));
            pubsub.fire(EVENT_BUTTON, 'FinancialsSave', {});
            this.isDataProcessed = true;
        } catch (error) {
            console.error('[Financials] Save error:', error);
            pubsub.fire(EVENT_SET, 'Error', { errorMessage: ERROR_INVALID_UPDATE });
            this.isDataProcessed = true;
        }

        // Reload fresh data
        this.loadFinancialData();
    }

    // --- Copy / Paste ---

    handlePasteData(event) {
        event.stopPropagation();
        const pastedRows = event.detail.data;
        if (!pastedRows || !Array.isArray(pastedRows) || !this.data) return;

        pastedRows.forEach((pastedRow, index) => {
            if (index >= this.data.length) return;
            const existingRow = this.data[index];
            let changed = false;

            YEAR_COLUMNS.forEach(col => {
                const rawVal = pastedRow[col];
                if (rawVal === undefined || rawVal === null || rawVal === '' || rawVal === NA_VALUE) return;

                let numStr = String(rawVal).trim().replace(/\s/g, '');
                if (numStr.includes(',') && numStr.includes('.')) {
                    if (numStr.lastIndexOf(',') > numStr.lastIndexOf('.')) {
                        numStr = numStr.replace(/\./g, '').replace(',', '.');
                    } else {
                        numStr = numStr.replace(/,/g, '');
                    }
                } else if (numStr.includes(',')) {
                    const parts = numStr.split(',');
                    if (parts.length === 2 && parts[1].length <= 2) {
                        numStr = numStr.replace(',', '.');
                    } else {
                        numStr = numStr.replace(/,/g, '');
                    }
                }

                const newVal = Number(numStr);
                if (!isNaN(newVal)) {
                    existingRow[col] = newVal;
                    changed = true;
                }
            });
            if (changed) existingRow.hasChanged = true;
        });

        this.processDataForView();
        if (this._isEditMode) this.toggleEditMode(true);

        if (!this._isEditMode) {
            if (this._preloadedRecordsMode) {
                this.dispatchEvent(new CustomEvent('redosave'));
            } else {
                this.handleSave();
            }
        } else {
            this.dispatchEvent(new CustomEvent('fieldchange', { bubbles: true, composed: true }));
        }
    }

    // --- Utilities ---

    _isValidSalesforceId(id) {
        return id && /^[a-zA-Z0-9]{15}([a-zA-Z0-9]{3})?$/.test(id);
    }
}