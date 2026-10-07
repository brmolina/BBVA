import { LightningElement, api, track, wire } from 'lwc';
import { loadStyle } from "lightning/platformResourceLoader";
import { updateRecord } from "lightning/uiRecordApi";
import LightningConfirm from 'lightning/confirm';

import getBussinessPlan from '@salesforce/apex/DMT_BussinessPlanController_Client.getBussinessPlan';
import getBusinessPlanOpportunity from '@salesforce/apex/DMT_BussinessPlanController.getBussinessPlan';
import getBussinessPlanByClient from '@salesforce/apex/DMT_BussinessPlanController.getBussinessPlanByClient';
import DMT_Styles from "@salesforce/resourceUrl/DMT_Styles";
import pubsub from 'omnistudio/pubsub';
import { publish, subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import XSELL_SYNC_CHANNEL from '@salesforce/messageChannel/DmtXSellSync__c';

import DMT_modify_financials_table from '@salesforce/label/c.DMT_modify_financials_table';
import DTM_overwrite_confirmation from '@salesforce/label/c.DTM_overwrite_confirmation';

const EVENT_SAVE = 'Save';
const EVENT_BUTTON = 'Button';
const EVENT_SET = 'Set';
const NA_VALUE = 'N/A';
const ERROR_INVALID_NUMBER = 'DmtBusinessPlanTableClient Please enter valid numbers in the numeric fields of the table.';
const ERROR_INVALID_STYLE = 'Error loading static resource styles.';
const ERROR_INVALID_UPDATE = 'Error in data saving.';
const ERROR_INVALID_LOADING = 'Error loading data.';

export default class DmtBusinessPlanTableClient extends LightningElement {

    @wire(MessageContext)
    messageContext;

    subscription = null;

    _recordId;
    _groupId;
    _isOpportunity = false;
    _isClient = false;
    _isEditMode = false;
    _isReadOnly = false;
    _stageName;
    _stylesLoaded = false;
    _isOppView = false;
    _opportunityClientId;
    _clientFinancialsId;
    _bookingGeography = 'GLOBAL';
    _allOpportunityRecords = null;
    _allAccountRecords = null; // Client BP records for Redo comparison (year + geography model)
    _businessPlanId = null;
    _yearRecordIds = { pastYear2: null, pastYear: null, currentYear: null, nextYear: null, nextYear2: null };
    _pendingEdits = new Map(); // geographyCode → { data, businessPlanId, yearRecordIds }
    _preloadedRecordsMode = false; // true when parent provides records via preloadedRecords

    label = {
        DMT_modify_financials_table,
        DTM_overwrite_confirmation
    }

    @api 
    set isOppView(value){
        this._isOppView = (value == 'true' || value === true);
    }
    get isOppView(){
        return this._isOppView;
    }

    @api
    get stageName() {
        return this._stageName;
    }
    set stageName(value) {
        console.log('dmt_opp_approval_business_plan: stageName set to', value);
        this._stageName = value;
    }

    @api
    get StageName() {
        return this._stageName;
    }
    set StageName(value) {
        this._stageName = value;
    }

    @api
    get isReadOnlyUser() {
        return this._isReadOnly;
    }
    set isReadOnlyUser(value) {
        this._isReadOnly = (value == true || value == 'true');
    }

    get isEditPencilEnabled() {
        return this._isReadOnly === false
            && (this._stageName === 'Draft' || this._stageName === 'Proposal');
    }

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        this.loadBusinessPlanData();
    }

    @api
    get groupId() {
        return this._groupId;
    }
    set groupId(value) {
        this._groupId = value;
        this.loadBusinessPlanData();
    }

    @api
    get isOpportunity() {
        return this._isOpportunity;
    }
    set isOpportunity(value) {
        this._isOpportunity = (value == 'true' || value === true);
        this.loadBusinessPlanData();
    }

    @api
    get isClient() {
        return this._isClient;
    }
    set isClient(value) {
        this._isClient = (value == 'true' || value === true);
        this.loadBusinessPlanData();
    }

    @api
    get isEditMode() {
        return this._isEditMode;
    }
    set isEditMode(value) {
        const wasEditing = this._isEditMode;
        this._isEditMode = (value == 'true' || value === true);
        if (wasEditing && !this._isEditMode) {
            // Edit mode exited (save or cancel) — clear pending edits and update cell visual state
            this._pendingEdits.clear();
            if (this.processedData) this.toggleEditMode(false);
        }
        if (this._isEditMode && this.processedData) {
            console.log('dmt_opp_approval_business_plan: isEditMode set to true, toggling edit mode');
            this.toggleEditMode(true);
        }
    }

    @api
    get opportunityClientId() {
        return this._opportunityClientId;
    }
    set opportunityClientId(value) {
        this._opportunityClientId = value;
    }

    /**
     * Collects all pending BP record changes (current geography + _pendingEdits)
     * and returns them as an array of update objects to be saved by the parent.
     * Does NOT perform any DML — use this in the opportunity preloaded-records flow.
     */
    @api
    collectBpChanges() {
        if (!this._isOpportunity || !this.data) return [];

        const currentChangedRows = this.data.filter(row => row.hasChanged);
        const currentUpdates = this.buildUpdateObject(currentChangedRows, this._yearRecordIds);

        const pendingUpdates = [];
        this._pendingEdits.forEach((pending, geo) => {
            const rows = (pending.data || []).filter(row => row.hasChanged);
            const updates = this.buildUpdateObject(rows, pending.yearRecordIds || {}, geo);
            pendingUpdates.push(...updates);
        });

        console.log('[BP] collectBpChanges: currentUpdates=', currentUpdates.length,
            '| pendingUpdates=', pendingUpdates.length);

        return [...currentUpdates, ...pendingUpdates];
    }

    /**
    /**
     * Clears pending edit state after the parent has successfully saved via Apex.
     * Called by the parent so the table does not re-save stale data on next save.
     */
    @api
    clearPendingEdits() {
        this._pendingEdits.clear();
        if (this.data) {
            this.data = this.data.map(row => ({ ...row, hasChanged: false }));
            this.originalData = JSON.parse(JSON.stringify(this.data));
        }
    }

    /**
     * Saves all pending BP record changes:\n     *   - Current geography (this.data)
     *   - Any other geographies stored in _pendingEdits
     * Throws on DML error so the caller can handle it.
     * Used in standalone (non-preloaded) mode or when the table saves independently.
     */
    @api
    async save() {
        if (!this.data) return;

        // Current geography
        const currentChangedRows = this.data.filter(row => row.hasChanged);
        const currentUpdates = this.buildUpdateObject(currentChangedRows, this._yearRecordIds);

        // All pending geographies (user edited then switched away)
        const pendingUpdates = [];
        this._pendingEdits.forEach((pending, geo) => {
            const rows = (pending.data || []).filter(row => row.hasChanged);
            const updates = this.buildUpdateObject(rows, pending.yearRecordIds || {}, geo);
            pendingUpdates.push(...updates);
        });

        const allUpdates = [...currentUpdates, ...pendingUpdates];
        if (allUpdates.length === 0) return; // Nothing to save

        // updateRecord (LDS) requires an existing Id — new records can only be created via Apex upsert path
        const updatableRecords = allUpdates.filter(u => u.Id);
        if (updatableRecords.length === 0) return;
        await Promise.all(updatableRecords.map(fields => updateRecord({ fields })));

        this.data = this.data.map(row => ({ ...row, hasChanged: false }));
        this.originalData = JSON.parse(JSON.stringify(this.data));
        this._pendingEdits.clear();
    }

    /**
     * Discards all unsaved edits and restores the last-loaded data.
     * Called by the parent when the user cancels edit mode.
     */
    @api
    reset() {
        this._pendingEdits.clear();
        if (this.originalData) {
            this.data = JSON.parse(JSON.stringify(this.originalData));
            this.processDataForView();
        }
    }

    /**
     * When set by a parent component, uses these records directly instead of making
     * an Apex call. The parent becomes the single source of truth for BP data.
     * Passing null/undefined is a no-op (records not ready yet).
     */
    @api
    get preloadedRecords() { return this._allOpportunityRecords; }
    set preloadedRecords(value) {
        if (!Array.isArray(value)) return; // null/undefined = not ready yet, ignore
        this._preloadedRecordsMode = true;
        this._allOpportunityRecords = value;
        if (this._isOpportunity) {
            this._applyGeographyFilter();
        }
    }

    /**
     * Allows the parent to supply Client BP records for Redo comparison in preloaded mode.
     */
    @api
    get preloadedAccountRecords() { return this._allAccountRecords; }
    set preloadedAccountRecords(value) {
        console.log('[BP-REDO] preloadedAccountRecords setter called, count:', value?.length, '| isArray:', Array.isArray(value));
        if (!Array.isArray(value)) return;
        this._allAccountRecords = value;
        if (value.length > 0) console.log('[BP-REDO] Sample preloaded account rec:', JSON.stringify(value[0]));
        // Re-apply geography filter to refresh comparison values
        if (this._isOpportunity && this._allOpportunityRecords) {
            console.log('[BP-REDO] preloadedAccountRecords: triggering _applyGeographyFilter');
            this._applyGeographyFilter();
        } else {
            console.log('[BP-REDO] preloadedAccountRecords: NOT triggering filter. isOpp:', this._isOpportunity, '| hasOppRecs:', !!this._allOpportunityRecords);
        }
    }

    @api
    get bookingGeography() { return this._bookingGeography; }
    set bookingGeography(value) {
        const normalized = value || 'GLOBAL';
        if (normalized === this._bookingGeography) return;
        // Persist unsaved edits before switching away from the current geography
        if (this.data && this.data.some(r => r.hasChanged)) {
            this._pendingEdits.set(this._bookingGeography, {
                data: JSON.parse(JSON.stringify(this.data)),
                businessPlanId: this._businessPlanId,
                yearRecordIds: { ...this._yearRecordIds }
            });
        }
        this._bookingGeography = normalized;
        if (this._isOpportunity && this.isValidSalesforceId(this._recordId)) {
            if (this._allOpportunityRecords !== null) {
                // Records already cached — re-filter locally without a new Apex call
                this._applyGeographyFilter();
            } else {
                this.fetchBusinessFromApexOpportunity();
            }
        }
    }

    @track originalData;
    @track data;
    @track processedData;
    isDataProcessed = false;

    // Track original base and child sums separately for fidelity 
    baseXSellTotals = { PY: 0, CY: 0, NY: 0, NY1: 0 };
    childXSellTotals = { PY: 0, CY: 0, NY: 0, NY1: 0 };
    _hasReceivedChildTotals = false; // Prevents UI flashing to 0 before LMS connects

    get columns() {
        const y = new Date().getFullYear();
        const q = Math.ceil((new Date().getMonth() + 1) / 3); // 1=Q1, 4=Q4
        const offset = q === 4 ? 1 : 0; // Q4 shifts window 1 year forward
        const fields = ['pastYear2', 'pastYear', 'currentYear', 'nextYear', 'nextYear2'];
        const years = fields.map((_, i) => y - 2 + i + offset);
        return [
            { label: '', fieldName: 'category', type: 'text', isEditable: false },
            ...fields.map((f, i) => ({
                label: `FY${years[i]}${years[i] > y ? 'E' : ''}`,
                fieldName: f,
                type: 'text',
                isEditable: true
            }))
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
        return this.data.map(row => {
            const clean = { Id: row.Id, category: row.category };
            ['pastYear2', 'pastYear', 'currentYear', 'nextYear', 'nextYear2'].forEach(f => {
                const v = row[f];
                clean[f] = (v === NA_VALUE || v === null || v === undefined) ? '' : String(v);
            });
            return clean;
        });
    }

    get isCopyPasteDisabled() {
        return !this.isEditPencilEnabled;
    }

    rowDefinitions = [
        {label: 'Corp. Synd. Lending', value: 'Corp_Synd_Lending'},
        {label: 'Structured Finance', value: 'Structured_Finance'},
        {label: 'Structured Trade Finance', value: 'Str_Trade_Finance'},
        {label: 'Rates', value: 'Rates'},
        {label: 'GTF', value: 'GTF'},
        {label: 'Working Capital', value: 'Working_Capital'},
        {label: 'Total Non X-Sell', value: 'Total_Non_X_Sell'},
        {label: 'ECM', value: 'ECM_M_A'},
        {label: 'M&A', value: 'M_A'},
        {label: 'DCM', value: 'DCM'},
        {label: 'Credit/Equity', value: 'Credit_Equity'},
        {label: 'FX/CCS', value: 'FX_CCS'},
        {label: 'Cash Management', value: 'Cash_Management'},
        {label: 'Client Resources', value: 'Client_Resources'},
        {label: 'Securities Services', value: 'Securities_Services'},
        {label: 'Total X-Sell', value: 'Total_X_Sell'},
        {label: 'Total Revenues', value: 'Total_Revenues'},
        {label: '% Cross Border Revenues', value: 'gf_kpi_trans_fees'},
        {label: 'Transactional KPI', value: 'gf_xb_cust_ope_revenue'}
    ];

    connectedCallback() {
        this.eventHandlers = {
            DMT_CLIENT_GROUP_V2: this.handleSave.bind(this),
        };
        pubsub.register(EVENT_SAVE, this.eventHandlers);
        console.log('[BP-TABLE] connectedCallback — registered Save/DMT_CLIENT_GROUP_V2');

        // Native LMS Subscription
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                XSELL_SYNC_CHANNEL,
                (message) => {
                    console.log('[BP] LMS RECEIVED', JSON.stringify(message));
                    this.handleXSellTotals(message);
                }
            );
        }

        publish(this.messageContext, XSELL_SYNC_CHANNEL, {
            action: 'REQUEST_TOTALS'
        });

        this.loadComponentStyles();
    }

    disconnectedCallback() {
        pubsub.unregister(EVENT_SAVE, this.eventHandlers);
        
        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
        }
    }

    /**
     * Catches real-time sum updates from the native LMS channel.
     * Replaces the child totals (handling live edits/deletes) and recalculates.
     */
    handleXSellTotals(message) {

        if (message.action === 'REQUEST_TOTALS') {
            return;
        }

        this._hasReceivedChildTotals = true;

        this.childXSellTotals = {
            PY: Number(message.PY) || 0,
            CY: Number(message.CY) || 0,
            NY: Number(message.NY) || 0,
            NY1: Number(message.NY1) || 0
        };

        if (this.data) {
            this.recalculateTotalXSell();
        }
    }

    /**
     * The Master Math Engine: Displayed Total = Current Child Table Sum.
     * ONLY updates the UI DOM (processedData). Prevents DML crashes by leaving hasChanged = false.
     */
    recalculateTotalXSell() {

        if (!this.data) {
            console.log('[BP] EXITING - data not loaded yet');
            return;
        }

        // Use child LMS totals only when the child table has actual X-Sell data (at least one
        // non-zero value). If the child sends all-zero totals (no child X-Sell records), fall
        // back to the parent-computed base totals (sum of ECM + M&A + etc. rows).
        const hasChildData = this._hasReceivedChildTotals &&
            (this.childXSellTotals.PY !== 0 || this.childXSellTotals.CY !== 0 ||
             this.childXSellTotals.NY !== 0 || this.childXSellTotals.NY1 !== 0);
        // When base value is null (no component rows have values), display N/A — not 0.
        const baseVal = v => (v !== null && v !== undefined) ? v : NA_VALUE;
        const totalPY  = hasChildData ? this.childXSellTotals.PY  : baseVal(this.baseXSellTotals.PY);
        const totalCY  = hasChildData ? this.childXSellTotals.CY  : baseVal(this.baseXSellTotals.CY);
        const totalNY  = hasChildData ? this.childXSellTotals.NY  : baseVal(this.baseXSellTotals.NY);
        const totalNY1 = hasChildData ? this.childXSellTotals.NY1 : baseVal(this.baseXSellTotals.NY1);

        // Update underlying data for internal consistency, but DO NOT set hasChanged = true.
        const targetRow = this.data.find(row => row.category === 'Total X-Sell');
        if (targetRow) {
            targetRow.pastYear2 = totalPY;
            targetRow.pastYear = totalCY;
            targetRow.currentYear = totalNY;
            targetRow.nextYear = totalNY1;
        }

        // Ensure processedData exists before mapping
        if (!this.processedData || this.processedData.length === 0) {
            this.processDataForView();
            return; // processDataForView will map from this.data, which we just updated above
        }

        // CRITICAL FIX: Mutate the target row IN PLACE rather than remapping the entire array.
        // This prevents LWC from forcefully re-rendering the whole table and wiping out active user typing.
        const targetProcessedRow = this.processedData.find(row => row.category === 'Total X-Sell');
        if (targetProcessedRow && targetProcessedRow.values) {
            targetProcessedRow.values.forEach(cell => {
                if (cell.field === 'pastYear2') cell.value = totalPY;
                if (cell.field === 'pastYear') cell.value = totalCY;
                if (cell.field === 'currentYear') cell.value = totalNY;
                if (cell.field === 'nextYear') cell.value = totalNY1;
                cell.isEditable = false; 
            });
        }
    }

    loadComponentStyles() {
        if (this._stylesLoaded) {
            return;
        }
        loadStyle(this, DMT_Styles)
            .then(() => {
                this._stylesLoaded = true;
            })
            .catch(error => {
                pubsub.fire(EVENT_SET, "Error", { errorMessage: ERROR_INVALID_STYLE });
                console.error('Error loading static resource styles:', error);
            });
    }

    async loadBusinessPlanData() {

        // When a parent provides records via preloadedRecords, skip all internal Apex fetches.
        if (this._preloadedRecordsMode) return;

        try {

            if (this.isClient && this.isValidSalesforceId(this.recordId)) {
                this.fetchBusinessFromApex();
            }

            // En Opportunity ya no se exige groupId para cargar. Si no viene, igualmente se muestra la tabla con los datos de Opportunity.
            if (this.isOpportunity && this.isValidSalesforceId(this.recordId)) {
                this.fetchBusinessFromApexOpportunity();
            }
        } catch (error) {
            pubsub.fire(EVENT_SET, "Error", { errorMessage: ERROR_INVALID_LOADING });
            console.log('DmtBusinessPlanTableClient loadBusinessPlanData error' + error);
            this.showToast('Error al cargar datos', error.body.message, 'error');
        }
    }

    async fetchBusinessFromApex() {
        try {
            const result = await getBussinessPlan({ recordId: this.recordId });

            if (!result || result.length === 0) {
                this._clientFinancialsId = null;
                this.data = [];
                // Se evita spinner infinito en modo Client.
                this.processDataForView();
                return;
            }

            this._clientFinancialsId = result[0].Id;

            this.transformApexData(result);

            if (this.isEditMode) {
                this.toggleEditMode(true);
            }
        } catch (error) {
            // Se evita spinner infinito si falla la carga.
            this.data = [];
            this.processDataForView();
            pubsub.fire("Set", "Error", { errorMessage: ERROR_INVALID_LOADING });
            console.error('Error detallado al obtener datos Business Plan:', JSON.stringify(error));
        }
    }

    async fetchBusinessFromApexOpportunity() {
        // Parent component already supplied records — don't make a redundant Apex call.
        if (this._preloadedRecordsMode) return;
        try {
            // Always fetch ALL records — geography filtering is done client-side
            const opportunityData = await getBusinessPlanOpportunity({ recordId: this.recordId, bookingGeography: null });

            // Guard: if preloadedRecords arrived while this call was in-flight, discard the result.
            if (this._preloadedRecordsMode) return;

            // La comparación contra cliente/grupo es opcional — usa el mismo modelo year+geography.
            let accountRecords = [];
            // Si groupId no viene del FlexCard, derivarlo del AccountId de la Opportunity
            let clientId = this.groupId;
            if (!this.isValidSalesforceId(clientId) && opportunityData?.length > 0) {
                const firstRec = opportunityData[0];
                if (firstRec.DMT_Opportunity__r && firstRec.DMT_Opportunity__r.AccountId) {
                    clientId = firstRec.DMT_Opportunity__r.AccountId;
                    console.log('[BP-REDO] groupId derivado de Opportunity.AccountId:', clientId);
                }
            }
            console.log('[BP-REDO] clientId final:', clientId, '| isValid:', this.isValidSalesforceId(clientId));
            if (this.isValidSalesforceId(clientId)) {
                try {
                    accountRecords = await getBussinessPlanByClient({ clientId: clientId });
                    console.log('[BP-REDO] getBussinessPlanByClient returned', accountRecords?.length, 'records');
                    if (accountRecords?.length > 0) {
                        console.log('[BP-REDO] Sample account record:', JSON.stringify(accountRecords[0]));
                    }
                } catch (accountError) {
                    console.error('[BP-REDO] Error cargando datos de comparación (group/client):', accountError);
                }
            }
            this._allAccountRecords = accountRecords || [];

            // Cache ALL records for client-side geography filtering
            this._allOpportunityRecords = opportunityData || [];

            if (this._allOpportunityRecords.length === 0) {
                this._businessPlanId = null;
                this._buildEmptyRows();
                return;
            }

            this._applyGeographyFilter();

        } catch (error) {
            // Se evita spinner infinito si falla la carga.
            this.data = [];
            this.processDataForView();
            pubsub.fire("Set", "Error", { errorMessage: ERROR_INVALID_LOADING });
            console.error('Error detallado al obtener datos Business Plan:', JSON.stringify(error));
        }
    }

    /**
     * Filtra los registros cacheados según el geography seleccionado.
     * Todos los geographies (incluyendo GLOBAL) se tratan de la misma forma:
     * se filtran los registros por DMT_Booking_Geography__c.
     */
    _applyGeographyFilter() {
        const EMPTY_YEAR_IDS = { pastYear2: null, pastYear: null, currentYear: null, nextYear: null, nextYear2: null };

        // Restore pending unsaved edits if the user already edited this geography
        if (this._pendingEdits.has(this._bookingGeography)) {
            const pending = this._pendingEdits.get(this._bookingGeography);
            this.data = pending.data;
            this._yearRecordIds = pending.yearRecordIds || { ...EMPTY_YEAR_IDS };
            // Re-populate account comparison values so Redo icons reflect current account data
            if (this._isOpportunity && this._allAccountRecords?.length > 0) {
                const yearColMap = this._yearColumnMap;
                const cols = ['pastYear2', 'pastYear', 'currentYear', 'nextYear', 'nextYear2'];
                const accountRecordByCol = this._buildAccountRecordByCol(yearColMap, cols);
                this.data.forEach(row => {
                    const rowDef = this.rowDefinitions.find(rd => rd.label === row.category);
                    if (!rowDef) return;
                    const fieldMap = this.getFieldMapping(rowDef.value);
                    cols.forEach(col => {
                        const accountSrc = accountRecordByCol[col];
                        const apiField = fieldMap[col];
                        row[col + 'Account'] = (apiField && accountSrc) ? (accountSrc[apiField] ?? NA_VALUE) : NA_VALUE;
                    });
                });
            }
            this.processDataForView();
            if (this._isEditMode) {
                this.toggleEditMode(true);
            }
            return;
        }

        const filtered = (this._allOpportunityRecords || []).filter(
            r => r.DMT_Booking_Geography__c === this._bookingGeography
        );
        if (!filtered || filtered.length === 0) {
            this._yearRecordIds = { ...EMPTY_YEAR_IDS };
            this._buildEmptyRows();
            if (this._isEditMode) {
                this.toggleEditMode(true);
            }
            return;
        }
        this.transformApexData(filtered);

        // Rebuild processedData from current this.data so isEditable reflects the new geography
        this.processDataForView();
        if (this.isEditMode) {
            this.toggleEditMode(true);
        }
    }

    transformApexData(apexData) {
        if (!apexData || apexData.length === 0) {
            this.data = [];
            this.processDataForView();
            return;
        }

        const yearColMap = this._yearColumnMap;
        const cols = ['pastYear2', 'pastYear', 'currentYear', 'nextYear', 'nextYear2'];

        // Index records by year column (one record per year via DMT_Year__c)
        const recordByCol = { pastYear2: null, pastYear: null, currentYear: null, nextYear: null, nextYear2: null };
        apexData.forEach(rec => {
            const col = yearColMap[Number(rec.DMT_Year__c)];
            if (col) recordByCol[col] = rec;
        });

        // Track record IDs per year column for saving
        this._yearRecordIds = {
            pastYear2:   recordByCol.pastYear2?.Id   ?? null,
            pastYear:    recordByCol.pastYear?.Id    ?? null,
            currentYear: recordByCol.currentYear?.Id ?? null,
            nextYear:    recordByCol.nextYear?.Id    ?? null,
            nextYear2:   recordByCol.nextYear2?.Id   ?? null
        };

        // Build account comparison map indexed by year column for current geography (Redo)
        console.log('[BP-REDO] _allAccountRecords count:', this._allAccountRecords?.length, '| bookingGeography:', this._bookingGeography);
        const accountRecordByCol = this._buildAccountRecordByCol(yearColMap, cols);
        console.log('[BP-REDO] accountRecordByCol:', JSON.stringify(Object.entries(accountRecordByCol).map(([k,v]) => [k, v ? 'HAS DATA' : null])));

        this.data = this.rowDefinitions.map((rowDef, index) => {
            const fieldMap = this.getFieldMapping(rowDef.value);
            const row = {
                Id: index,
                category: rowDef.label,
                isEditable: !rowDef.label.includes('Total'),
                class: rowDef.label.includes('Total') ? 'slds-hint-parent dmt-table-title' : 'slds-hint-parent'
            };
            cols.forEach(col => {
                const src = recordByCol[col];
                const apiField = fieldMap[col];
                row[col] = (apiField && src != null) ? (src[apiField] ?? NA_VALUE) : NA_VALUE;
                if (this.isOpportunity) {
                    const accountSrc = accountRecordByCol[col];
                    row[col + 'Account'] = (apiField && accountSrc) ? (accountSrc[apiField] ?? NA_VALUE) : NA_VALUE;
                }
            });
            return row;
        });

        this.originalData = JSON.parse(JSON.stringify(this.data));

        // Debug: sample row account values
        const sampleRow = this.data?.[0];
        if (sampleRow) {
            console.log('[BP-REDO] transformApexData row[0] account cols:', JSON.stringify({
                cat: sampleRow.category,
                py2A: sampleRow.pastYear2Account,
                pyA: sampleRow.pastYearAccount,
                cyA: sampleRow.currentYearAccount,
                nyA: sampleRow.nextYearAccount,
                ny2A: sampleRow.nextYear2Account
            }));
        }

        // Compute X-Sell base totals by summing individual component rows.
        // Current_FY_Child_X_Sell_amount__c is often null in DB, so using it as baseline
        // would show 0 after every reload. Sum ECM + M&A + etc. rows directly instead.
        const X_SELL_ROW_LABELS = new Set(['ECM', 'M\u0026A', 'DCM', 'Credit/Equity', 'FX/CCS', 'Cash Management', 'Client Resources', 'Securities Services']);
        const xSellSums = { pastYear2: null, pastYear: null, currentYear: null, nextYear: null };
        this.data.forEach(row => {
            if (!X_SELL_ROW_LABELS.has(row.category)) return;
            ['pastYear2', 'pastYear', 'currentYear', 'nextYear'].forEach(col => {
                const v = row[col];
                if (v !== null && v !== undefined && v !== NA_VALUE && !isNaN(Number(v))) {
                    xSellSums[col] = (xSellSums[col] === null ? 0 : xSellSums[col]) + Number(v);
                }
            });
        });
        this.baseXSellTotals = {
            PY:  xSellSums.pastYear2,
            CY:  xSellSums.pastYear,
            NY:  xSellSums.currentYear,
            NY1: xSellSums.nextYear
        };
        // Apply computed sums directly to the Total X-Sell row so the UI shows the
        // correct value immediately, before the LMS child channel responds.
        // null (no component values) → NA_VALUE so display is consistent with other total rows.
        const totalXSellRow = this.data.find(r => r.category === 'Total X-Sell');
        if (totalXSellRow) {
            totalXSellRow.pastYear2   = xSellSums.pastYear2   !== null ? xSellSums.pastYear2   : NA_VALUE;
            totalXSellRow.pastYear    = xSellSums.pastYear    !== null ? xSellSums.pastYear    : NA_VALUE;
            totalXSellRow.currentYear = xSellSums.currentYear !== null ? xSellSums.currentYear : NA_VALUE;
            totalXSellRow.nextYear    = xSellSums.nextYear    !== null ? xSellSums.nextYear    : NA_VALUE;
        }
        // Reset so recalculateTotalXSell picks up the fresh baseXSellTotals above
        // rather than stale child LMS values captured before the reload.
        this._hasReceivedChildTotals = false;
        this.recalculateTotalXSell();
    }
    async handleRedoAllTable() {
        try {
            const result = await LightningConfirm.open({
                message: this.label.DTM_overwrite_confirmation,
                variant: 'header',
                label: 'Confirmation of Change',
                theme: 'alt-inverse'
            });
            if (result) {
                this.redoAllTable();
            }
        } catch (e) {
            console.error('Error mostrando LightningConfirm:', JSON.stringify(e));
        }
    }

    redoAllTable() {
        if (!this._allAccountRecords || this._allAccountRecords.length === 0) return;
        try {
            this._redoCurrentGeography();
        } catch (e) {
            console.error('Error en redoAllTable:', e);
        }
    }

    /**
     * Redo from a specific geography: copy account values for this geo into current data rows.
     */
    _redoCurrentGeography() {
        const yearColMap = this._yearColumnMap;
        const cols = ['pastYear2', 'pastYear', 'currentYear', 'nextYear', 'nextYear2'];
        const accountRecordByCol = {};
        this._allAccountRecords.forEach(rec => {
            if (rec.DMT_Booking_Geography__c !== this._bookingGeography) return;
            const col = yearColMap[Number(rec.DMT_Year__c)];
            if (col) accountRecordByCol[col] = rec;
        });

        this.data = this.data.map(row => {
            if (row.category.includes('Total')) return row;
            const rowDef = this.rowDefinitions.find(rd => rd.label === row.category);
            if (!rowDef) return row;
            const fieldMap = this.getFieldMapping(rowDef.value);
            let changed = false;
            cols.forEach(col => {
                const src = accountRecordByCol[col];
                const apiField = fieldMap[col];
                if (apiField && src && src[apiField] !== undefined && src[apiField] !== null) {
                    row[col] = src[apiField];
                    changed = true;
                }
            });
            if (changed) row.hasChanged = true;
            return row;
        });

        this._recalculateAllTotals();
        this.processDataForView();
        if (this._isEditMode) this.toggleEditMode(true);
        this.dispatchEvent(new CustomEvent('redosave'));
    }

    handleRedo(event) {
        const rowId = event.target.dataset.id;
        const fieldName = event.target.dataset.field; // column: pastYear2, pastYear, etc.

        if (!this._allAccountRecords || this._allAccountRecords.length === 0) return;

        this._redoCellCurrentGeography(rowId, fieldName);
    }

    /**
     * Single cell redo in specific geography: copy one value from account.
     */
    _redoCellCurrentGeography(rowId, fieldName) {
        const row = this.data.find(r => r.Id == rowId);
        if (!row) return;
        const accountValue = row[fieldName + 'Account'];
        if (accountValue === undefined || accountValue === NA_VALUE) return;

        row[fieldName] = accountValue;
        row.hasChanged = true;
        this.data[row.Id] = row;

        this._recalculateSectionTotals(fieldName);
        this.processDataForView();
        if (this._isEditMode) this.toggleEditMode(true);
        this.dispatchEvent(new CustomEvent('redosave'));
    }

    /** Maps actual calendar year → internal column name, based on current quarter */
    get _yearColumnMap() {
        const y = new Date().getFullYear();
        const q = Math.ceil((new Date().getMonth() + 1) / 3);
        const offset = q === 4 ? 1 : 0;
        const cols = ['pastYear2', 'pastYear', 'currentYear', 'nextYear', 'nextYear2'];
        const result = {};
        cols.forEach((col, i) => { result[y - 2 + i + offset] = col; });
        return result;
    }

    /**
     * Builds the account comparison map indexed by year column.
     * Filters account records by the current booking geography.
     */
    _buildAccountRecordByCol(yearColMap, cols) {
        const accountRecordByCol = { pastYear2: null, pastYear: null, currentYear: null, nextYear: null, nextYear2: null };
        if (!this._allAccountRecords || this._allAccountRecords.length === 0) return accountRecordByCol;

        this._allAccountRecords.forEach(rec => {
            if (rec.DMT_Booking_Geography__c !== this._bookingGeography) return;
            const col = yearColMap[Number(rec.DMT_Year__c)];
            if (col) accountRecordByCol[col] = rec;
        });
        return accountRecordByCol;
    }

    /**
     * Recalculates all total rows (Non X-Sell, X-Sell, Revenues) for all columns.
     * Used after bulk redo operations that modify multiple cells at once.
     */
    _recalculateAllTotals() {
        const cols = ['pastYear2', 'pastYear', 'currentYear', 'nextYear', 'nextYear2'];
        cols.forEach(col => this._recalculateSectionTotals(col));
    }

    _isGfRow(columnValue) {
        // Model changed: gf_* fields now use a single field + DMT_Year__c (like BP rows)
        return false;
    }

    getFieldMapping(columnValue) {
        // All rows now use single-field + DMT_Year__c model (one record per year)
        if (columnValue === 'gf_xb_cust_ope_revenue') {
            const f = 'gf_xb_cust_ope_revenue_cyr_per__c';
            return { pastYear2: f, pastYear: f, currentYear: f, nextYear: f, nextYear2: f };
        }
        if (columnValue === 'gf_kpi_trans_fees') {
            const f = 'gf_kpi_trans_fees_cyr_amount__c';
            return { pastYear2: f, pastYear: f, currentYear: f, nextYear: f, nextYear2: f };
        }
        const f = columnValue === 'ECM_M_A'
            ? `Current_FY_${columnValue}_Amount__c`
            : `Current_FY_${columnValue}_amount__c`;
        return { pastYear2: f, pastYear: f, currentYear: f, nextYear: f, nextYear2: f };
    }

    /**
     * Este método prepara los datos para ser renderizados en la tabla personalizada.
     */
    processDataForView() {
        this.processedData = this.data.map(row => {
            const isTotalRow = row.category && row.category.includes('Total');
            const values = this.columns.map(column => {
                const accountValueRaw = row[column.fieldName + 'Account'];

                // Solo hay comparación real si existe valor origen
                const hasComparisonValue = accountValueRaw !== undefined && accountValueRaw !== null && accountValueRaw !== '' && accountValueRaw !== NA_VALUE;
                // Visualmente se muestra N/A cuando no hay dato origen
                const accountValue = hasComparisonValue ? accountValueRaw : NA_VALUE;
                const value = row[column.fieldName];

                return {
                    field: column.fieldName,
                    label: column.label,
                    // Valor actual en Opportunity
                    value: value,
                    // Valor origen del Client/Account
                    accountValue: accountValue,
                    // Solo comparar si existe dato real de origen
                    isEquals: hasComparisonValue ? accountValue === value : true,
                    // Esta propiedad sirve para saber si hay comparación real
                    hasComparisonValue: !isTotalRow && hasComparisonValue,
                    isEditing: false,
                    isEditable: column.isEditable && row.isEditable,
                    // El botón redo aparece solo si NO es total, hay comparación real y además es distinto
                    styleRedo: !isTotalRow && hasComparisonValue && accountValue !== value ? '' : 'display:none;',
                    // Ajuste visual cuando no hay redo
                    withoutRedo: hasComparisonValue && accountValue === value ? 'margin-top: 40% !important;' : '',
                    cellClass: "slds-has-button slds-has-flexi-truncate"
                };
            });

            return { ...row, values, id: row.Id};
        } );

        // Debug: check redo visibility for first row
        const samplePRow = this.processedData?.[0];
        if (samplePRow) {
            const redoCells = samplePRow.values.filter(c => c.styleRedo === '');
            console.log('[BP-REDO] processDataForView row[0] redo-visible:', redoCells.length,
                '| details:', JSON.stringify(samplePRow.values.filter(c => c.field !== 'category').map(c => ({
                    f: c.field, hasComp: c.hasComparisonValue, accVal: c.accountValue, val: c.value, redo: c.styleRedo
                })))
            );
        }

        this.isDataProcessed = true;
    }

    handleInputChange(event) {
        const { id, field } = event.target.dataset;
        const newValue = event.target.value;

        // 1. Update the background save data
        const rowIndex = this.data.findIndex(row => row.Id == id);
        if (rowIndex !== -1) {
            this.data[rowIndex] = { ...this.data[rowIndex], [field]: newValue, hasChanged: true };
        }
        
        // 2. CRITICAL FIX: Update the foreground UI data so it survives LMS re-renders
        const pRowIndex = this.processedData.findIndex(row => row.Id == id);
        if (pRowIndex !== -1) {
            const cell = this.processedData[pRowIndex].values.find(c => c.field === field);
            if (cell) {
                cell.value = newValue;
            }
        }

        // 3. Recalculate section totals for the edited column
        this._recalculateSectionTotals(field);
    }

    /**
     * Recalculates Total Non X-Sell, Total X-Sell and Total Revenues live as the user edits a cell.
     */
    _recalculateSectionTotals(changedField) {
        const NON_X_SELL_CATEGORIES = new Set([
            'Corp. Synd. Lending', 'Structured Finance', 'Structured Trade Finance',
            'Rates', 'GTF', 'Working Capital'
        ]);
        const X_SELL_CATEGORIES = new Set([
            'ECM', 'M&A', 'DCM', 'Credit/Equity', 'FX/CCS',
            'Cash Management', 'Client Resources', 'Securities Services'
        ]);

        const sumRows = (categorySet) => {
            let total = null;
            this.data.forEach(row => {
                if (!categorySet.has(row.category)) return;
                const val = row[changedField];
                if (val !== null && val !== undefined && val !== NA_VALUE) {
                    const num = Number(val);
                    if (!isNaN(num)) total = (total === null ? 0 : total) + num;
                }
            });
            return total;
        };

        const nonXSellTotal = sumRows(NON_X_SELL_CATEGORIES);
        const xSellTotal    = sumRows(X_SELL_CATEGORIES);
        // Show N/A when both halves have no values; otherwise sum them (absent half counts as 0)
        const totalRevenues = (nonXSellTotal !== null || xSellTotal !== null)
            ? (nonXSellTotal ?? 0) + (xSellTotal ?? 0)
            : null;

        // Update total rows in data.
        // Only overwrite a total when at least one of its component rows has a numeric value;
        // if all are N/A, the total is null and we preserve the existing displayed value.
        // This prevents overwriting Total Non X-Sell with N/A when the user only edits X-Sell fields.
        const updates = {};
        if (nonXSellTotal !== null) {
            updates['Total Non X-Sell'] = nonXSellTotal;
        }
        if (xSellTotal !== null) {
            updates['Total X-Sell'] = xSellTotal;
            // Keep baseXSellTotals in sync so recalculateTotalXSell doesn't overwrite with stale values
            const colToBase = { pastYear2: 'PY', pastYear: 'CY', currentYear: 'NY', nextYear: 'NY1' };
            if (colToBase[changedField]) {
                this.baseXSellTotals[colToBase[changedField]] = xSellTotal;
            }
        }
        if (totalRevenues !== null) {
            updates['Total Revenues'] = totalRevenues;
        }
        Object.entries(updates).forEach(([category, newVal]) => {
            const idx = this.data.findIndex(r => r.category === category);
            if (idx !== -1) {
                this.data[idx] = { ...this.data[idx], [changedField]: newVal, hasChanged: true };
            }
        });

        // Sync to processedData for immediate UI feedback
        if (this.processedData) {
            this.processedData.forEach(row => {
                if (Object.prototype.hasOwnProperty.call(updates, row.category)) {
                    const cell = row.values?.find(c => c.field === changedField);
                    if (cell) cell.value = updates[row.category];
                }
            });
        }
    }

    _buildEmptyRows() {
        const yearColMap = this._yearColumnMap;
        const cols = ['pastYear2', 'pastYear', 'currentYear', 'nextYear', 'nextYear2'];
        const accountRecordByCol = this._buildAccountRecordByCol(yearColMap, cols);

        this.data = this.rowDefinitions.map((rowDef, index) => {
            const row = {
                Id: index,
                category: rowDef.label,
                isEditable: !rowDef.label.includes('Total'),
                class: rowDef.label.includes('Total') ? 'slds-hint-parent dmt-table-title' : 'slds-hint-parent',
                pastYear2: NA_VALUE,
                pastYear: NA_VALUE,
                currentYear: NA_VALUE,
                nextYear: NA_VALUE,
                nextYear2: NA_VALUE
            };
            // Include account comparison values so Redo icons appear even when Opportunity has no data
            if (this._isOpportunity) {
                const fieldMap = this.getFieldMapping(rowDef.value);
                cols.forEach(col => {
                    const accountSrc = accountRecordByCol[col];
                    const apiField = fieldMap[col];
                    row[col + 'Account'] = (apiField && accountSrc) ? (accountSrc[apiField] ?? NA_VALUE) : NA_VALUE;
                });
            }
            return row;
        });
        this.originalData = JSON.parse(JSON.stringify(this.data));
        // Always refresh processedData so old rows are replaced even when switching geographies
        this.processDataForView();
    }

    toggleEditMode(isEditing) {
        this._isEditMode = isEditing;
        if(this.processedData) {
            this.processedData = this.processedData.map(row => {
                row.values = row.values.map(cell => {
                    cell.isEditing = isEditing;
                    return cell;
                });
                return row;
            });
        }
    }

    /**
     * Valida si una cadena es un ID de Salesforce válido.
     */
    isValidSalesforceId(id) {
        return id && /^[a-zA-Z0-9]{15}(|([a-zA-Z0-9]{3}))$/.test(id);
    }

    /**
     * Maneja el evento de guardado. Valida los datos y prepara el objeto para enviarlo a la base de datos.
     * El uso de `async/await` mejora la legibilidad.
     */
    async handleSave() {
        console.log('[BP-TABLE] handleSave FIRED. _preloadedRecordsMode=', this._preloadedRecordsMode);
        // In preloaded-records mode the parent component owns the full save lifecycle.
        // For Account: _handleAccountSave (pubsub) handles saving — nothing to do here.
        // For Opportunity: dispatch redosave so the parent collects changes and persists.
        if (this._preloadedRecordsMode) {
            const isAccount = typeof this._recordId === 'string' && this._recordId.startsWith('001');
            if (!isAccount) {
                console.log('[BP-TABLE] dispatching redosave event');
                this.dispatchEvent(new CustomEvent('redosave'));
            }
            return;
        }

        this.isDataProcessed = false;
        try {
            await this.save();
            this.toggleEditMode(false);
            pubsub.fire(EVENT_BUTTON, "BusinessSave", {});
            this.isDataProcessed = true;
        } catch (error) {
            console.error('DmtBusinessPlanTableClient Error detallado al obtener datos Business Plan:', JSON.stringify(error));
            pubsub.fire(EVENT_SET, "Error", { errorMessage: ERROR_INVALID_UPDATE });
        }
        this.loadBusinessPlanData();
    }

    handlePasteData(event) {
        event.stopPropagation();
        const pastedRows = event.detail.data;
        if (!pastedRows || !Array.isArray(pastedRows) || !this.data) return;

        const TOTAL_CATEGORIES = new Set(['Total Non X-Sell', 'Total X-Sell', 'Total Revenues']);
        const EDITABLE_FIELDS = ['pastYear2', 'pastYear', 'currentYear', 'nextYear', 'nextYear2'];

        pastedRows.forEach((pastedRow, index) => {
            if (index >= this.data.length) return;
            const existingRow = this.data[index];
            if (TOTAL_CATEGORIES.has(existingRow.category)) return;

            let changed = false;
            EDITABLE_FIELDS.forEach(f => {
                const rawVal = pastedRow[f];
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
                    existingRow[f] = newVal;
                    changed = true;
                }
            });
            if (changed) existingRow.hasChanged = true;
        });

        this._recalculateAllTotals();
        this.processDataForView();
    }

    buildUpdateObject(changedRows, yearRecordIds = this._yearRecordIds, geography = this._bookingGeography) {

        if (this.isClient) {
            // Client path: single record, all columns in one update
            const fields = { Id: this._clientFinancialsId };
            changedRows.forEach(row => {
                const originalRow = this.originalData.find(orig => orig.Id === row.Id);
                if (!originalRow) return;
                const rowDefinition = this.rowDefinitions.find(r => r.label === originalRow.category);
                if (!rowDefinition) return;
                const fieldMap = this.getFieldMapping(rowDefinition.value);
                Object.entries(fieldMap).forEach(([fieldName, apiFieldName]) => {
                    if (row[fieldName] != originalRow[fieldName]) {
                        fields[apiFieldName] = (row[fieldName] == NA_VALUE || row[fieldName] == '' || row[fieldName] == null) ? null : Number(row[fieldName]);
                    }
                });
            });
            return [fields];
        }

        // Opportunity path: one update object per year record (DMT_Year__c model)
        const cols = ['pastYear2', 'pastYear', 'currentYear', 'nextYear', 'nextYear2'];
        // Reverse map: column name → calendar year number (needed as context for new records)
        const reverseYearMap = {};
        Object.entries(this._yearColumnMap).forEach(([year, c]) => { reverseYearMap[c] = Number(year); });
        const updatesByCol = {};
        cols.forEach(col => {
            const recordId = yearRecordIds?.[col] ?? null;
            if (recordId) {
                // Existing BP record — update by Id
                updatesByCol[col] = { Id: recordId };
            } else {
                // No existing BP record for this year — include context fields so Apex can upsert (insert)
                updatesByCol[col] = {
                    DMT_Year__c: reverseYearMap[col],
                    DMT_Booking_Geography__c: geography,
                    ...(this._isOpportunity && this._recordId ? { DMT_Opportunity__c: this._recordId } : {})
                };
            }
        });

        changedRows.forEach(row => {
            const originalRow = this.originalData.find(orig => orig.Id === row.Id);
            if (!originalRow) return;
            const rowDefinition = this.rowDefinitions.find(r => r.label === originalRow.category);
            if (!rowDefinition) return;
            const fieldMap = this.getFieldMapping(rowDefinition.value);
            const isGf = this._isGfRow(rowDefinition.value);

            if (isGf) {
                // gf_* rows: all 4 field variants live on one record (prefer currentYear)
                const target = updatesByCol.currentYear || updatesByCol.pastYear || updatesByCol.pastYear2 || updatesByCol.nextYear;
                if (!target) return;
                cols.forEach(col => {
                    const apiField = fieldMap[col];
                    if (!apiField) return; // nextYear2 has no gf_* field
                    if (row[col] != originalRow[col]) {
                        target[apiField] = (row[col] == NA_VALUE || row[col] == '' || row[col] == null) ? null : Number(row[col]);
                    }
                });
            } else {
                // BP rows: each column → its own year record
                cols.forEach(col => {
                    if (!updatesByCol[col]) return;
                    if (row[col] != originalRow[col]) {
                        updatesByCol[col][fieldMap[col]] = (row[col] == NA_VALUE || row[col] == '' || row[col] == null) ? null : Number(row[col]);
                    }
                });
            }
        });

        // Return only objects that have at least one actual data field change.
        // Existing records: must have Id + at least one other field.
        // New records:      must have at least one field beyond the upsert context fields.
        const UPSERT_CONTEXT_FIELDS = new Set(['Id', 'DMT_Year__c', 'DMT_Booking_Geography__c', 'DMT_Opportunity__c']);
        return Object.values(updatesByCol).filter(u =>
            Object.keys(u).some(k => !UPSERT_CONTEXT_FIELDS.has(k))
        );
    }

    /**
     * @description Dispara un evento para notificar a otros componentes que se ha iniciado la edición.
     */
    handleEdit(event) {
        if (!this.isEditPencilEnabled) {
            return;
        }
        this._isEditMode = true;
        this.toggleEditMode(true);
        // Notify parent via DOM event; the parent routes to the correct mechanism:
        // - Opportunity: re-dispatches 'editmodechange' up to dmt_opp_approval_details
        // - Account/FlexCard: fires pubsub 'Button'/'Edit' for the FlexCard
        this.dispatchEvent(new CustomEvent('editmodechange'));
    }
}