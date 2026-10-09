import { LightningElement, api, track, wire } from 'lwc';
import { loadStyle } from "lightning/platformResourceLoader";
import { updateRecord } from "lightning/uiRecordApi";
import LightningConfirm from 'lightning/confirm';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getBussinessPlan from '@salesforce/apex/DMT_BussinessPlanController_Client.getBussinessPlan';
import getBusinessPlanOpportunity from '@salesforce/apex/DMT_BussinessPlanController.getBussinessPlan';
import getBussinessPlanByClient from '@salesforce/apex/DMT_BussinessPlanController.getBussinessPlanByClient';
import GroupSelectorModal from 'c/dmt_bp_group_selector_modal';
import DMT_Styles from "@salesforce/resourceUrl/DMT_Styles";
import pubsub from 'omnistudio/pubsub';
import { publish, subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import XSELL_SYNC_CHANNEL from '@salesforce/messageChannel/DmtXSellSync__c';
import LOCALE from '@salesforce/i18n/locale';

import DMT_modify_financials_table from '@salesforce/label/c.DMT_modify_financials_table';
import DTM_overwrite_confirmation from '@salesforce/label/c.DTM_overwrite_confirmation';

const EVENT_SAVE = 'Save';
const EVENT_BUTTON = 'Button';
const EVENT_SET = 'Set';
const NA_VALUE = '-';
const ERROR_INVALID_NUMBER = 'DmtBusinessPlanTableClient Please enter valid numbers in the numeric fields of the table.';
const ERROR_INVALID_STYLE = 'Error loading static resource styles.';
const ERROR_INVALID_UPDATE = 'Error in data saving.';
const ERROR_INVALID_LOADING = 'Error loading data.';
const THOUSAND = 1000;

// Amount fields: stored in DB as real amounts, displayed in the table in thousands.
// The two gf_* fields (% Cross Border Revenues and Transactional KPI) are NOT amounts and are not converted.
const BP_AMOUNT_FIELDS = new Set([
    'Current_FY_Corp_Synd_Lending_amount__c',
    'Current_FY_Structured_Finance_amount__c',
    'Current_FY_Str_Trade_Finance_amount__c',
    'Current_FY_Rates_amount__c',
    'Current_FY_GTF_amount__c',
    'Current_FY_Working_Capital_amount__c',
    'Current_FY_Total_Non_X_Sell_amount__c',
    'Current_FY_ECM_M_A_Amount__c',
    'Current_FY_M_A_amount__c',
    'Current_FY_DCM_amount__c',
    'Current_FY_Credit_Equity_amount__c',
    'Current_FY_FX_CCS_amount__c',
    'Current_FY_Cash_Management_amount__c',
    'Current_FY_Client_Resources_amount__c',
    'Current_FY_Securities_Services_amount__c',
    'Current_FY_Total_X_Sell_amount__c',
    'Current_FY_Total_Revenues_amount__c'
]);

// DB records (real amounts) -> copies with amounts in thousands.
// Copies instead of mutating: arrays received via @api from the parent are read-only.
function recordsToThousands(records) {
    return (records || []).map(rec => {
        const copy = { ...rec };
        BP_AMOUNT_FIELDS.forEach(f => {
            if (typeof copy[f] === 'number') copy[f] = copy[f] / THOUSAND;
        });
        return copy;
    });
}

// Table value (thousands) -> value to save in DB.
// Rounds to avoid JS floating-point noise:
function toSaveValue(apiField, value) {
    if (value === NA_VALUE || value === '' || value === null || value === undefined) return null;
    const num = Number(value);
    if (Number.isNaN(num)) return null;
    return BP_AMOUNT_FIELDS.has(apiField) ? Math.round(num * THOUSAND) : num;
}

// Geography options for the inline picklist (always editable)
const GEO_OPTIONS = [
    { label: 'GLOBAL', value: 'GLOBAL' },
    { label: 'SPAIN', value: 'SPAIN' },
    { label: 'FRANCE', value: 'FRANCE' },
    { label: 'ITALY', value: 'ITALY' },
    { label: 'GERMANY', value: 'GERMANY' },
    { label: 'UK', value: 'UK' },
    { label: 'ASIA', value: 'ASIA' },
    { label: 'NY', value: 'NY' },
    { label: 'BRASIL', value: 'BRASIL' },
    { label: 'MEXICO', value: 'MEXICO' },
    { label: 'COLOMBIA', value: 'COLOMBIA' },
    { label: 'PERU', value: 'PERU' },
    { label: 'CHILE', value: 'CHILE' },
    { label: 'ARGENTINA', value: 'ARGENTINA' },
    { label: 'TURKEY', value: 'TURKEY' },
    { label: 'OTHERS', value: 'OTHERS' }
];

export default class DmtBusinessPlanTableGeography extends LightningElement {

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
    _rawOpportunityRecords = null;
    _rawAccountRecords = null;
    _defaultGroupId = null; // Group derived from the Opportunity/FlexCard, used when the override is reset
    @track _overrideGroupId = null;   // Group Id explicitly picked by the user via "Retrieve another Group's table"
    @track _overrideGroupName = null; // Label of the overridden Group, shown next to the button
    _businessPlanId = null;
    _yearRecordIds = { pastYear2: null, pastYear: null, currentYear: null, nextYear: null, nextYear2: null };
    _pendingEdits = new Map(); // geographyCode → { data, businessPlanId, yearRecordIds, activeValue }
    @track _activeValue = true;   // DMT_Active__c for current geography
    _activeOriginal = true;       // Snapshot at load time for change detection
    _preloadedRecordsMode = false; // true when parent provides records via preloadedRecords
    _closeDate;
    _isClosed = false;

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
    get isClosed() {
        return this._isClosed;
    }

    set isClosed(value) {
        this._isClosed = value === true || value === 'true';
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

    @api
    get closeDate() {
        return this._closeDate;
    }

    set closeDate(value) {
        this._closeDate = value;
    }

    get isEditPencilEnabled() {
        return this._isReadOnly === false
            && this._bookingGeography !== 'GLOBAL'
            && (this._stageName === 'Draft' || this._stageName === 'Proposal');
    }

    get isRedoAllowed() {
        return !this._isReadOnly;
    }

    get hasGroupOverride() {
        return !!this._overrideGroupId;
    }

    get groupOverrideName() {
        return this._overrideGroupName;
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
        const hasDataChanges = currentUpdates.length > 0; // track before Active merge

        console.log('[BP] collectBpChanges START: changedRows=', currentChangedRows.length,
            '| dataUpdates=', currentUpdates.length,
            '| geo=', this._bookingGeography,
            '| activeValue=', this._activeValue, '| activeOrig=', this._activeOriginal);
        if (currentUpdates.length > 0) {
            console.log('[BP] collectBpChanges dataUpdates[0]:', JSON.stringify(currentUpdates[0]));
        }

        // Build Active updates separately to avoid interference with data objects
        const activeUpdates = [];
        if (this._bookingGeography !== 'GLOBAL' && this._activeValue !== this._readActiveFromRecords(this._bookingGeography)) {
            console.log('[BP-ACTIVE] collectBpChanges: Active changed for', this._bookingGeography,
                '| value=', this._activeValue, '| original=', this._activeOriginal,
                '| yearRecordIds=', JSON.stringify(this._yearRecordIds));
            this._injectActiveIntoUpdates(activeUpdates, this._yearRecordIds, this._bookingGeography);
        }

        let hasPendingDataChanges = false;
        const pendingUpdates = [];
        console.log('[BP-DUP] collectBpChanges: current geo=', this._bookingGeography,
            '| _pendingEdits keys=', JSON.stringify([...this._pendingEdits.keys()]));
        if (this._pendingEdits.has(this._bookingGeography)) {
            console.warn('[BP-DUP] *** STALE ENTRY DETECTED *** _pendingEdits still contains the CURRENT geography (',
                this._bookingGeography, ') at save time — this WILL cause duplicate records.');
        }
        this._pendingEdits.forEach((pending, geo) => {
            const rows = (pending.data || []).filter(row => row.hasChanged);
            const refOriginal = pending.originalData || this._buildOriginalDataForGeo(geo);
            const updates = this.buildUpdateObject(rows, pending.yearRecordIds || {}, geo, refOriginal);
            console.log('[BP-DUP] pending geo=', geo, '| changedRows=', rows.length, '| updates=', JSON.stringify(updates));
            if (updates.length > 0) hasPendingDataChanges = true;
            // Inject Active from pending edit if it was changed
            const pendingActiveOrig = this._readActiveFromRecords(geo);
            if (pending.activeValue !== undefined && pending.activeValue !== pendingActiveOrig && geo !== 'GLOBAL') {
                this._injectActiveIntoUpdates(updates, pending.yearRecordIds || {}, geo);
            }
            pendingUpdates.push(...updates);
        });

        // Merge Active updates into data updates by ID (Active objects only add DMT_Active__c)
        activeUpdates.forEach(au => {
            if (au.Id) {
                const existing = currentUpdates.find(u => u.Id === au.Id);
                if (existing) {
                    existing.DMT_Active__c = au.DMT_Active__c;
                } else {
                    currentUpdates.push(au);
                }
            } else {
                // New-record stubs: merge with any existing stub for same year+geo
                const existingStub = currentUpdates.find(u =>
                    !u.Id && u.DMT_Year__c === au.DMT_Year__c && u.DMT_Booking_Geography__c === au.DMT_Booking_Geography__c
                );
                if (existingStub) {
                    existingStub.DMT_Active__c = au.DMT_Active__c;
                } else {
                    currentUpdates.push(au);
                }
            }
        });

        // Only include GLOBAL aggregated updates when there are actual DATA field changes
        // (not just Active-only changes). Parent handles GLOBAL Active independently.
        const hasRealDataChanges = hasDataChanges || hasPendingDataChanges;
        const globalUpdates = hasRealDataChanges ? this._buildGlobalSaveObjects() : [];

        console.log('[BP] collectBpChanges END: currentUpdates=', currentUpdates.length,
            '| pendingUpdates=', pendingUpdates.length,
            '| globalUpdates=', globalUpdates.length,
            '| hasRealDataChanges=', hasRealDataChanges,
            '| TOTAL=', currentUpdates.length + pendingUpdates.length + globalUpdates.length);

        const allUpdates = [...currentUpdates, ...pendingUpdates, ...globalUpdates];
        console.log('[BP] collectBpChanges FULL PAYLOAD:', JSON.stringify(allUpdates));

        // Diagnostic: detect if the payload has 2+ no-Id (new record) objects targeting the
        // same year+geography -- this is exactly the condition that causes duplicate BP records.
        const noIdGroups = {};
        allUpdates.filter(u => !u.Id).forEach(u => {
            const key = u.DMT_Year__c + '|' + u.DMT_Booking_Geography__c;
            noIdGroups[key] = (noIdGroups[key] || 0) + 1;
        });
        Object.entries(noIdGroups).forEach(([key, count]) => {
            if (count > 1) {
                console.error('[BP-DUP] *** DUPLICATE NEW-RECORD STUBS IN PAYLOAD *** year|geo=', key,
                    '| count=', count, '| this will insert', count, 'separate records for the same year+geography!');
            }
        });
        return allUpdates;
    }

    /**
    /**
     * Clears pending edit state after the parent has successfully saved via Apex.
     * Called by the parent so the table does not re-save stale data on next save.
     */
    @api
    clearPendingEdits() {
        this._pendingEdits.clear();
        this._activeOriginal = this._activeValue;
        if (this.data) {
            this.data = this.data.map(row => ({ ...row, hasChanged: false }));
            this.originalData = JSON.parse(JSON.stringify(this.data));
        }
    }

    /**
     * Returns true when any row in the current data or pending edits has unsaved changes.
     */
    @api
    get hasPendingChanges() {
        if (this.data && this.data.some(row => row.hasChanged)) return true;
        if (this._bookingGeography !== 'GLOBAL' && this._activeValue !== this._readActiveFromRecords(this._bookingGeography)) return true;
        if (this._pendingEdits.size > 0) return true;
        return false;
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
        const hasDataChanges = currentUpdates.length > 0;

        // Build Active updates separately (same approach as collectBpChanges)
        const activeUpdates = [];
        if (this._bookingGeography !== 'GLOBAL' && this._activeValue !== this._readActiveFromRecords(this._bookingGeography)) {
            this._injectActiveIntoUpdates(activeUpdates, this._yearRecordIds, this._bookingGeography);
        }

        // All pending geographies (user edited then switched away)
        let hasPendingDataChanges = false;
        const pendingUpdates = [];
        this._pendingEdits.forEach((pending, geo) => {
            const rows = (pending.data || []).filter(row => row.hasChanged);
            const refOriginal = pending.originalData || this._buildOriginalDataForGeo(geo);
            const updates = this.buildUpdateObject(rows, pending.yearRecordIds || {}, geo, refOriginal);
            if (updates.length > 0) hasPendingDataChanges = true;
            const pendingActiveOrig = this._readActiveFromRecords(geo);
            if (pending.activeValue !== undefined && pending.activeValue !== pendingActiveOrig && geo !== 'GLOBAL') {
                this._injectActiveIntoUpdates(updates, pending.yearRecordIds || {}, geo);
            }
            pendingUpdates.push(...updates);
        });

        // Merge Active updates into data updates by ID
        activeUpdates.forEach(au => {
            if (au.Id) {
                const existing = currentUpdates.find(u => u.Id === au.Id);
                if (existing) {
                    existing.DMT_Active__c = au.DMT_Active__c;
                } else {
                    currentUpdates.push(au);
                }
            } else {
                const existingStub = currentUpdates.find(u =>
                    !u.Id && u.DMT_Year__c === au.DMT_Year__c && u.DMT_Booking_Geography__c === au.DMT_Booking_Geography__c
                );
                if (existingStub) {
                    existingStub.DMT_Active__c = au.DMT_Active__c;
                } else {
                    currentUpdates.push(au);
                }
            }
        });

        // Only include GLOBAL aggregated updates when there are actual DATA field changes
        const hasRealDataChanges = hasDataChanges || hasPendingDataChanges;
        const globalUpdates = hasRealDataChanges ? this._buildGlobalSaveObjects() : [];

        const allUpdates = [...currentUpdates, ...pendingUpdates, ...globalUpdates];
        if (allUpdates.length === 0) return; // Nothing to save

        // updateRecord (LDS) requires an existing Id — new records can only be created via Apex upsert path
        const updatableRecords = allUpdates.filter(u => u.Id);
        if (updatableRecords.length === 0) return;
        await Promise.all(updatableRecords.map(fields => updateRecord({ fields })));

        this.data = this.data.map(row => ({ ...row, hasChanged: false }));
        this.originalData = JSON.parse(JSON.stringify(this.data));
        this._activeOriginal = this._activeValue;
        this._pendingEdits.clear();
    }

    /**
     * Discards all unsaved edits and restores the last-loaded data.
     * Called by the parent when the user cancels edit mode.
     */
    @api
    reset() {
        this._pendingEdits.clear();
        this._activeValue = this.originalData ? this._hasAnyEditableValue(this.originalData) : this._activeOriginal;
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
    get preloadedRecords() { return this._rawOpportunityRecords; }
    set preloadedRecords(value) {
        if (!Array.isArray(value)) return; // null/undefined = not ready yet, ignore
        if (value === this._rawOpportunityRecords) {
            console.log('[BP-PASTE] preloadedRecords setter SKIPPED (same reference)');
            return; // Same reference — skip re-filter to preserve in-memory edits
        }
        console.log('[BP-PASTE] preloadedRecords setter CALLED with NEW reference, count:', value?.length);
        this._preloadedRecordsMode = true;
        this._rawOpportunityRecords = value;
        this._allOpportunityRecords = recordsToThousands(value);
        if (this._isOpportunity) {
            this._applyGeographyFilter();
        }
    }

    /**
     * Allows the parent to supply Client BP records for Redo comparison in preloaded mode.
     */
    @api
    get preloadedAccountRecords() { return this._rawAccountRecords; }
    set preloadedAccountRecords(value) {
        console.log('[BP-REDO] preloadedAccountRecords setter called, count:', value?.length, '| isArray:', Array.isArray(value));
        if (!Array.isArray(value)) return;
        if (value === this._rawAccountRecords) return; // Same reference — skip re-filter to preserve in-memory edits
        this._rawAccountRecords = value;
        this._allAccountRecords = recordsToThousands(value);
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
        // Persist unsaved edits (including Active) before switching away from the current geography.
        // originalData is snapshotted too so change-detection for this geography is compared
        // against its OWN baseline later, instead of whatever geography happens to be active then.
        if (this.data && (this.data.some(r => r.hasChanged) || (this._bookingGeography !== 'GLOBAL' && this._activeValue !== this._readActiveFromRecords(this._bookingGeography)))) {
            this._pendingEdits.set(this._bookingGeography, {
                data: JSON.parse(JSON.stringify(this.data)),
                originalData: this.originalData ? JSON.parse(JSON.stringify(this.originalData)) : null,
                businessPlanId: this._businessPlanId,
                yearRecordIds: { ...this._yearRecordIds },
                activeValue: this._activeValue
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

    _getBaseFinancialYear() {
        let referenceDate = new Date();

        const isClosedOpportunity = this._isOpportunity && this._isClosed;

        if (isClosedOpportunity && this._closeDate) {
            const dateParts = this._closeDate.split('-');

            referenceDate = new Date(
                Number(dateParts[0]),
                Number(dateParts[1]) - 1,
                Number(dateParts[2])
            );
        }





        const fecha = new Date(2026, 0, 15);

        return referenceDate.getMonth() >= 12
            ? referenceDate.getFullYear() - 1
            : referenceDate.getFullYear() - 2;
    }

    get columns() {
        const baseYear = this._getBaseFinancialYear();

        const fields = [
            'pastYear2',
            'pastYear',
            'currentYear',
            'nextYear',
            'nextYear2'
        ];
        console.log('[BP] columns getter: fields=', fields.join(', '));
        const years = fields.map(
            (_, index) => baseYear + index
        );
        console.log('[BP] columns getter: baseYear=', baseYear, '| years=', years.join(', '));
        return [
            {
                label: '',
                fieldName: 'category',
                type: 'text',
                isEditable: false
            },
            ...fields.map((fieldName, index) => ({
                label: `FY${years[index]}${index > 0 ? 'E' : ''}`,
                fieldName,
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

    // ─── Inline Geography Picklist (always editable) ───────────────────────────
    get geographyOptions() {
        return GEO_OPTIONS;
    }

    get selectedGeographyValue() {
        return this._bookingGeography;
    }

    // ─── Inline Active Checkbox ────────────────────────────────────────────────
    get isActiveChecked() {
        return this._activeValue === true || this._activeValue === 'true';
    }

    get isActiveDisabled() {
        return this._bookingGeography === 'GLOBAL' || !this._isEditMode;
    }

    handleActiveChange(event) {
        if (this._bookingGeography === 'GLOBAL') {
            this._activeValue = true;
        } else {
            this._syncActiveFromCurrentGeography();
        }
        console.log('[BP-ACTIVE] handleActiveChange: checked=', this._activeValue, '| original=', this._activeOriginal);
        // Notify parent of dirty state
        this.dispatchEvent(new CustomEvent('fieldchange'));
    }

    /**
     * Reads DMT_Active__c from BP records for the given geography.
     * GLOBAL is always true. Non-GLOBAL defaults to false unless DB has true.
     */
    _readActiveFromRecords(geography) {
        if (geography === 'GLOBAL') return true;
        if (!Array.isArray(this._allOpportunityRecords)) return false;
        const geoRecords = this._allOpportunityRecords.filter(
            r => r.DMT_Booking_Geography__c === geography
        );
        return geoRecords.some(r => r.DMT_Active__c === true);
    }

    _hasAnyEditableValue(rows) {
        if (!Array.isArray(rows)) return false;

        const editableFields = ['pastYear2', 'pastYear', 'currentYear', 'nextYear', 'nextYear2'];

        return rows.some(row => {
            if (!row || (row.category && row.category.includes('Total'))) return false;
            return editableFields.some(field => {
                const value = row[field];
                return value !== undefined &&
                    value !== null &&
                    value !== '' &&
                    value !== NA_VALUE;
            });
        });
    }

    _syncActiveFromCurrentGeography() {
        if (this._bookingGeography === 'GLOBAL') return;
        this._activeValue = this._hasAnyEditableValue(this.data);
    }

    /**
     * Injects DMT_Active__c into update objects for the given geography's year records.
     * If no updates exist yet for a year that has a record ID, creates one.
     * If no year records exist at all, creates new-record stubs with Active + context fields.
     */
    _injectActiveIntoUpdates(updates, yearRecordIds, geography) {
        const cols = ['pastYear2', 'pastYear', 'currentYear', 'nextYear', 'nextYear2'];
        let injected = false;

        cols.forEach(col => {
            const recordId = yearRecordIds?.[col];
            if (!recordId) return;
            const activeVal = this._bookingGeography === geography
                ? (this._activeValue === true)
                : ((this._pendingEdits.get(geography)?.activeValue === true) || this._readActiveFromRecords(geography));
            const existing = updates.find(u => u.Id === recordId);
            if (existing) {
                existing.DMT_Active__c = activeVal;
            } else {
                updates.push({ Id: recordId, DMT_Active__c: activeVal });
            }
            injected = true;
        });

        // If no existing records, create stubs so the Active value can be saved to new records.
        // IMPORTANT: `updates` may already contain a new-record stub (no Id) for the same
        // year+geography pushed by buildUpdateObject (e.g. a data field change). Without
        // checking for it here, we'd push a SECOND separate stub for the same year+geography,
        // and since neither has an Id, Apex upsert inserts both — producing duplicate BP records.
        if (!injected && this._isOpportunity) {
            const reverseYearMap = {};
            Object.entries(this._yearColumnMap).forEach(([year, c]) => { reverseYearMap[c] = Number(year); });
            const activeVal = this._bookingGeography === geography
                ? (this._activeValue === true)
                : ((this._pendingEdits.get(geography)?.activeValue === true) || this._readActiveFromRecords(geography));
            cols.forEach(col => {
                const year = reverseYearMap[col];
                const existingStub = updates.find(u =>
                    !u.Id && u.DMT_Year__c === year && u.DMT_Booking_Geography__c === geography
                );
                if (existingStub) {
                    existingStub.DMT_Active__c = activeVal;
                } else {
                    updates.push({
                        DMT_Year__c: year,
                        DMT_Booking_Geography__c: geography,
                        DMT_Active__c: activeVal,
                        ...(this._recordId ? { DMT_Opportunity__c: this._recordId } : {})
                    });
                }
            });
            console.log('[BP-ACTIVE] Created/merged new-record stubs for Active in geography:', geography);
        }
    }

    handleGeographyChange(event) {
        const newGeo = event.detail.value;
        if (newGeo === this._bookingGeography) return;

        // Persist unsaved edits (including Active) before switching. originalData is snapshotted
        // too so this geography's changes are diffed against its OWN baseline when saved later.
        if (this.data && (this.data.some(r => r.hasChanged) || (this._bookingGeography !== 'GLOBAL' && this._activeValue !== this._readActiveFromRecords(this._bookingGeography)))) {
            this._pendingEdits.set(this._bookingGeography, {
                data: JSON.parse(JSON.stringify(this.data)),
                originalData: this.originalData ? JSON.parse(JSON.stringify(this.originalData)) : null,
                businessPlanId: this._businessPlanId,
                yearRecordIds: { ...this._yearRecordIds },
                activeValue: this._activeValue
            });
        }
        this._bookingGeography = newGeo;

        if (this._isOpportunity && this.isValidSalesforceId(this._recordId)) {
            if (this._allOpportunityRecords !== null) {
                this._applyGeographyFilter();
            } else {
                this.fetchBusinessFromApexOpportunity();
            }
        }

        // Notify the parent so it can sync its own geography state
        this.dispatchEvent(new CustomEvent('geographychange', {
            detail: { value: newGeo }
        }));
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
                if (cell.field === 'pastYear2') { cell.value = totalPY; cell.displayValue = this.formatDisplayValue(totalPY); }
                if (cell.field === 'pastYear') { cell.value = totalCY; cell.displayValue = this.formatDisplayValue(totalCY); }
                if (cell.field === 'currentYear') { cell.value = totalNY; cell.displayValue = this.formatDisplayValue(totalNY); }
                if (cell.field === 'nextYear') { cell.value = totalNY1; cell.displayValue = this.formatDisplayValue(totalNY1); }
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

            this.transformApexData(recordsToThousands(result));

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
            this._defaultGroupId = clientId;
            // If the user already picked another Group in a previous load, keep using it
            if (this.isValidSalesforceId(this._overrideGroupId)) {
                clientId = this._overrideGroupId;
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
            this._allAccountRecords = recordsToThousands(accountRecords);

            // Cache ALL records for client-side geography filtering
            this._allOpportunityRecords = recordsToThousands(opportunityData);

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

        // GLOBAL is always calculated as the sum of all other geographies (non-editable)
        // Do NOT reset _isEditMode here so it is restored when switching back to a non-GLOBAL geography
        if (this._bookingGeography === 'GLOBAL') {
            this._yearRecordIds = { ...EMPTY_YEAR_IDS };
            this._activeValue = true;
            this._activeOriginal = true;
            this._buildGlobalAggregatedRows();
            return;
        }

        // Restore pending unsaved edits if the user already edited this geography.
        // Also restore this geography's own originalData baseline — without this, this.originalData
        // would still hold whatever geography was active before, causing change-detection on save
        // (buildUpdateObject) to diff against the WRONG baseline and create spurious/duplicate records.
        if (this._pendingEdits.has(this._bookingGeography)) {
            const pending = this._pendingEdits.get(this._bookingGeography);
            this.data = pending.data;
            this.originalData = pending.originalData || this._buildOriginalDataForGeo(this._bookingGeography);
            this._yearRecordIds = pending.yearRecordIds || { ...EMPTY_YEAR_IDS };
            this._syncActiveFromCurrentGeography();
            this._activeOriginal = this._readActiveFromRecords(this._bookingGeography);
            // CRITICAL: remove this geography's entry from _pendingEdits now that it has been
            // restored back into this.data/this._bookingGeography (the "current" geography).
            // Without this, the entry lingers in the Map, and collectBpChanges()/save() would
            // process the SAME geography TWICE at save time: once via the "current geography"
            // path (this.data) and once via the stale _pendingEdits loop, building two separate
            // (near-)identical update/stub objects for the same year+geography with no shared
            // reference to dedup against each other -> duplicate inserted records.
            console.log('[BP-DUP] _applyGeographyFilter: restoring pending edits for', this._bookingGeography,
                '| deleting from _pendingEdits. Map keys before delete:', JSON.stringify([...this._pendingEdits.keys()]));
            this._pendingEdits.delete(this._bookingGeography);
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
            this._activeValue = false;
            this._activeOriginal = false;
            this._buildEmptyRows();
            if (this._isEditMode) {
                this.toggleEditMode(true);
            }
            return;
        }

        // Read Active from the filtered records
        this._activeValue = this._readActiveFromRecords(this._bookingGeography);
        this._activeOriginal = this._activeValue;

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
            PY:  xSellSums.pastYear2 !== null ? Math.round(xSellSums.pastYear2 * 100) / 100 : null,
            CY:  xSellSums.pastYear !== null ? Math.round(xSellSums.pastYear * 100) / 100 : null,
            NY:  xSellSums.currentYear !== null ? Math.round(xSellSums.currentYear * 100) / 100 : null,
            NY1: xSellSums.nextYear !== null ? Math.round(xSellSums.nextYear * 100) / 100 : null
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
        this._syncActiveFromCurrentGeography();
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

    /**
     * Opens the Group selector modal so the user can infer this Business Plan
     * table from a Group other than the Opportunity's own Account.
     */
    async handleRetrieveAnotherGroup() {
        try {
            const result = await GroupSelectorModal.open({
                size: 'small',
                currentGroupId: this._overrideGroupId,
                currentGroupName: this._overrideGroupName
            });

            if (!result) {
                return;
            }

            if (result.reset) {
                await this._resetGroupOverride();
            } else if (this.isValidSalesforceId(result.groupId)) {
                await this._applyGroupOverride(result.groupId, result.groupName);
            } else {
                this._notifyGroupOverrideError('Could not identify the selected Group. Please pick a suggestion from the list before confirming.');
                return;
            }

            if (!this._allAccountRecords || this._allAccountRecords.length === 0) {
                this._notifyGroupOverrideError('The selected Group has no Business Plan data.');
                return;
            }

            const hasChanges = this.redoAllTable();
            if (!hasChanges) {
                this._notifyGroupOverrideError('The selected Group has no Business Plan data for the current geography/years.');
            } else {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Retrieve another Group\'s table',
                    message: result.reset
                        ? 'Table reverted to the Opportunity\'s Group.'
                        : `Table updated from Group: ${this._overrideGroupName}.`,
                    variant: 'success'
                }));
            }
        } catch (e) {
            const errorMessage = e && e.body && e.body.message ? e.body.message : (e && e.message ? e.message : JSON.stringify(e));
            console.error('Error retrieving another Group\'s table:', errorMessage);
            this._notifyGroupOverrideError(ERROR_INVALID_LOADING);
        }
    }

    /**
     * Surfaces an error both through pubsub (for pages with a listener) and through a
     * native toast, so the user always sees feedback regardless of the page context.
     */
    _notifyGroupOverrideError(message) {
        pubsub.fire(EVENT_SET, 'Error', { errorMessage: message });
        this.dispatchEvent(new ShowToastEvent({
            title: 'Retrieve another Group\'s table',
            message,
            variant: 'error',
            mode: 'sticky'
        }));
    }

    /**
     * Fetches the Business Plan of the selected Group and uses it as the
     * comparison/source data for the Redo feature instead of the Opportunity's own Group.
     */
    async _applyGroupOverride(groupId, groupName) {
        const accountRecords = await getBussinessPlanByClient({ clientId: groupId });
        this._allAccountRecords = recordsToThousands(accountRecords);
        this._overrideGroupId = groupId;
        this._overrideGroupName = groupName || null;
    }

    /**
     * Reverts back to the Opportunity's own Group as the comparison/source data.
     */
    async _resetGroupOverride() {
        this._overrideGroupId = null;
        this._overrideGroupName = null;
        if (this.isValidSalesforceId(this._defaultGroupId)) {
            const accountRecords = await getBussinessPlanByClient({ clientId: this._defaultGroupId });
            this._allAccountRecords = recordsToThousands(accountRecords);
        } else {
            this._allAccountRecords = [];
        }
    }

    redoAllTable() {
        if (!this._allAccountRecords || this._allAccountRecords.length === 0) return false;
        try {
            if (this._bookingGeography === 'GLOBAL') {
                return this._redoFromGlobal();
            }
            return this._redoCurrentGeography();
        } catch (e) {
            console.error('Error en redoAllTable:', e);
            return false;
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

        let anyChanged = false;
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
            if (changed) {
                row.hasChanged = true;
                anyChanged = true;
            }
            return row;
        });

        this._recalculateAllTotals();
        this.processDataForView();
        this._syncActiveFromCurrentGeography();
        if (this._isEditMode) this.toggleEditMode(true);
        this.dispatchEvent(new CustomEvent('redosave'));
        return anyChanged;
    }

    handleRedo(event) {
        const rowId = event.target.dataset.id;
        const fieldName = event.target.dataset.field; // column: pastYear2, pastYear, etc.

        if (!this._allAccountRecords || this._allAccountRecords.length === 0) return;

        if (this._bookingGeography === 'GLOBAL') {
            this._redoCellFromGlobal(rowId, fieldName);
        } else {
            this._redoCellCurrentGeography(rowId, fieldName);
        }
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
        this._syncActiveFromCurrentGeography();
        if (this._isEditMode) this.toggleEditMode(true);
        this.dispatchEvent(new CustomEvent('redosave'));
    }

    /** Maps calendar years to internal columns, shifting on September 1. */
    get _yearColumnMap() {
        const baseYear = this._getBaseFinancialYear();

        const columns = [
            'pastYear2',
            'pastYear',
            'currentYear',
            'nextYear',
            'nextYear2'
        ];

        const result = {};

        columns.forEach((column, index) => {
            result[baseYear + index] = column;
        });

        return result;
    }

    /**
     * Builds GLOBAL rows by summing all non-GLOBAL geography records.
     * Uses pending edits when available, otherwise uses original opportunity records.
     */
    _buildGlobalAggregatedRows() {
        const yearColMap = this._yearColumnMap;
        const cols = ['pastYear2', 'pastYear', 'currentYear', 'nextYear', 'nextYear2'];

        // Collect all non-GLOBAL geographies
        const allGeos = new Set();
        (this._allOpportunityRecords || []).forEach(r => {
            if (r.DMT_Booking_Geography__c && r.DMT_Booking_Geography__c !== 'GLOBAL') allGeos.add(r.DMT_Booking_Geography__c);
        });
        this._pendingEdits.forEach((_, geo) => { if (geo !== 'GLOBAL') allGeos.add(geo); });

        // Pre-compute account aggregation for Redo comparison
        const accountAggregated = this._isOpportunity
            ? this._aggregateRecordsByYear(this._allAccountRecords || [], yearColMap)
            : {};

        this.data = this.rowDefinitions.map((rowDef, index) => {
            const fieldMap = this.getFieldMapping(rowDef.value);
            const row = {
                Id: index,
                category: rowDef.label,
                isEditable: false,
                class: rowDef.label.includes('Total') ? 'slds-hint-parent dmt-table-title' : 'slds-hint-parent'
            };

            cols.forEach(col => {
                let sum = null;
                const apiField = fieldMap[col];
                allGeos.forEach(geo => {
                    if (this._pendingEdits.has(geo)) {
                        const pendingRow = this._pendingEdits.get(geo).data.find(r => r.Id === index);
                        if (pendingRow) {
                            const val = pendingRow[col];
                            if (val !== NA_VALUE && val !== null && val !== undefined && !isNaN(Number(val))) {
                                sum = (sum === null ? 0 : sum) + Number(val);
                            }
                        }
                    } else if (apiField) {
                        (this._allOpportunityRecords || [])
                            .filter(r => r.DMT_Booking_Geography__c === geo && yearColMap[Number(r.DMT_Year__c)] === col)
                            .forEach(rec => {
                                if (rec[apiField] !== undefined && rec[apiField] !== null && typeof rec[apiField] === 'number') {
                                    sum = (sum === null ? 0 : sum) + rec[apiField];
                                }
                            });
                    }
                });
                row[col] = sum !== null ? Math.round(sum * 100) / 100 : NA_VALUE;

                // Account comparison (sum of all non-GLOBAL account records)
                if (this._isOpportunity) {
                    const accountSrc = accountAggregated[col];
                    row[col + 'Account'] = (apiField && accountSrc && accountSrc[apiField] !== undefined) ? accountSrc[apiField] : NA_VALUE;
                }
            });

            return row;
        });

        this.originalData = JSON.parse(JSON.stringify(this.data));
        this.processDataForView();
    }

    /**
     * Builds update/insert objects for GLOBAL records by summing all non-GLOBAL
     * geography values (using pending edits when available, current this.data for
     * the active geography, and original DB records otherwise).
     * If existing GLOBAL records are found in _allOpportunityRecords their Ids are
     * reused (update); otherwise context fields are included so Apex can insert.
     * @returns {Object[]} Array of update objects ready for Apex upsert.
     */
    _buildGlobalSaveObjects() {
        if (!this._isOpportunity) return [];

        const yearColMap = this._yearColumnMap;
        const cols = ['pastYear2', 'pastYear', 'currentYear', 'nextYear', 'nextYear2'];
        const reverseYearMap = {};
        Object.entries(yearColMap).forEach(([year, c]) => { reverseYearMap[c] = Number(year); });

        // Map existing GLOBAL record by column
        const globalRecordByCol = {};
        (this._allOpportunityRecords || [])
            .filter(r => r.DMT_Booking_Geography__c === 'GLOBAL')
            .forEach(rec => {
                const col = yearColMap[Number(rec.DMT_Year__c)];
                if (col) globalRecordByCol[col] = rec;
            });

        // Collect all non-GLOBAL geographies
        const allGeos = new Set();
        (this._allOpportunityRecords || []).forEach(r => {
            if (r.DMT_Booking_Geography__c && r.DMT_Booking_Geography__c !== 'GLOBAL') allGeos.add(r.DMT_Booking_Geography__c);
        });
        this._pendingEdits.forEach((_, geo) => { if (geo !== 'GLOBAL') allGeos.add(geo); });
        // Ensure the currently active geography is included even if it has no existing DB records
        if (this._bookingGeography && this._bookingGeography !== 'GLOBAL') {
            allGeos.add(this._bookingGeography);
        }

        const updates = [];

        cols.forEach(col => {
            const existingRec = globalRecordByCol[col];
            const updateObj = existingRec
                ? { Id: existingRec.Id }
                : {
                    DMT_Year__c: reverseYearMap[col],
                    DMT_Booking_Geography__c: 'GLOBAL',
                    ...(this._recordId ? { DMT_Opportunity__c: this._recordId } : {})
                };

            let hasFields = false;

            this.rowDefinitions.forEach((rowDef, index) => {
                const fieldMap = this.getFieldMapping(rowDef.value);
                const apiField = fieldMap[col];
                if (!apiField) return;

                let sum = null;
                allGeos.forEach(geo => {
                    let geoVal = null;

                    if (this._bookingGeography !== 'GLOBAL' && geo === this._bookingGeography && this.data) {
                        // Active geography — use live this.data (may contain unsaved edits)
                        const row = this.data.find(r => r.Id === index);
                        if (row) {
                            const v = row[col];
                            if (v !== NA_VALUE && v !== null && v !== undefined && !isNaN(Number(v))) {
                                geoVal = Number(v);
                            }
                        }
                    } else if (this._pendingEdits.has(geo)) {
                        // Pending edit geography
                        const pendingRow = this._pendingEdits.get(geo).data.find(r => r.Id === index);
                        if (pendingRow) {
                            const v = pendingRow[col];
                            if (v !== NA_VALUE && v !== null && v !== undefined && !isNaN(Number(v))) {
                                geoVal = Number(v);
                            }
                        }
                    } else {
                        // Original records from DB
                        (this._allOpportunityRecords || [])
                            .filter(r => r.DMT_Booking_Geography__c === geo && yearColMap[Number(r.DMT_Year__c)] === col)
                            .forEach(rec => {
                                if (rec[apiField] !== undefined && rec[apiField] !== null && typeof rec[apiField] === 'number') {
                                    geoVal = rec[apiField];
                                }
                            });
                    }

                    if (geoVal !== null) {
                        sum = (sum === null ? 0 : sum) + geoVal;
                    }
                });

                updateObj[apiField] = sum !== null ? toSaveValue(apiField, Math.round(sum * 100) / 100) : null;
                hasFields = true;
            });

            if (hasFields) {
                updateObj.DMT_Active__c = true; // GLOBAL is always active
                updates.push(updateObj);
            }
        });

        console.log('[BP] _buildGlobalSaveObjects: updates=', updates.length,
            '| existing GLOBAL records=', Object.keys(globalRecordByCol).length);
        return updates;
    }

    /**
     * Aggregates non-GLOBAL records by year, summing all numeric fields.
     * Returns { pastYear2: {field: sum}, pastYear: {...}, ... }
     */
    _aggregateRecordsByYear(records, yearColMap) {
        const result = { pastYear2: null, pastYear: null, currentYear: null, nextYear: null, nextYear2: null };
        if (!records || records.length === 0) return result;

        const nonGlobal = records.filter(r => r.DMT_Booking_Geography__c !== 'GLOBAL');
        nonGlobal.forEach(rec => {
            const col = yearColMap[Number(rec.DMT_Year__c)];
            if (!col) return;
            if (!result[col]) result[col] = {};

            Object.keys(rec).forEach(field => {
                if (field === 'Id' || field === 'DMT_Year__c' || field === 'DMT_Booking_Geography__c' ||
                    field === 'DMT_Opportunity__c' || field === 'DMT_Opportunity__r' ||
                    field === 'attributes' || typeof rec[field] !== 'number') return;
                if (result[col][field] === undefined) {
                    result[col][field] = rec[field];
                } else {
                    result[col][field] += rec[field];
                }
            });
        });
        return result;
    }

    /**
     * Redo from GLOBAL: propagates account values to each individual booking geography.
     */
    _redoFromGlobal() {
        if (!this._allAccountRecords || this._allAccountRecords.length === 0) return false;

        const yearColMap = this._yearColumnMap;
        const cols = ['pastYear2', 'pastYear', 'currentYear', 'nextYear', 'nextYear2'];
        let anyChanged = false;

        // Get all non-GLOBAL geographies from account records
        const geoSet = new Set();
        this._allAccountRecords.forEach(rec => {
            if (rec.DMT_Booking_Geography__c && rec.DMT_Booking_Geography__c !== 'GLOBAL') {
                geoSet.add(rec.DMT_Booking_Geography__c);
            }
        });

        geoSet.forEach(geo => {
            const accountRecordByCol = {};
            this._allAccountRecords.forEach(rec => {
                if (rec.DMT_Booking_Geography__c !== geo) return;
                const col = yearColMap[Number(rec.DMT_Year__c)];
                if (col) accountRecordByCol[col] = rec;
            });

            const oppRecordByCol = {};
            (this._allOpportunityRecords || []).filter(r => r.DMT_Booking_Geography__c === geo).forEach(rec => {
                const col = yearColMap[Number(rec.DMT_Year__c)];
                if (col) oppRecordByCol[col] = rec;
            });

            const geoYearIds = { pastYear2: null, pastYear: null, currentYear: null, nextYear: null, nextYear2: null };
            cols.forEach(col => { if (oppRecordByCol[col]?.Id) geoYearIds[col] = oppRecordByCol[col].Id; });

            const geoData = this.rowDefinitions.map((rowDef, index) => {
                const fieldMap = this.getFieldMapping(rowDef.value);
                const row = {
                    Id: index,
                    category: rowDef.label,
                    isEditable: !rowDef.label.includes('Total'),
                    class: rowDef.label.includes('Total') ? 'slds-hint-parent dmt-table-title' : 'slds-hint-parent',
                    hasChanged: false
                };
                if (rowDef.label.includes('Total')) {
                    cols.forEach(col => { row[col] = NA_VALUE; });
                    return row;
                }
                let changed = false;
                cols.forEach(col => {
                    const oppSrc = oppRecordByCol[col];
                    const accountSrc = accountRecordByCol[col];
                    const apiField = fieldMap[col];
                    row[col] = (apiField && oppSrc) ? (oppSrc[apiField] ?? NA_VALUE) : NA_VALUE;
                    if (apiField && accountSrc && accountSrc[apiField] !== undefined && accountSrc[apiField] !== null) {
                        row[col] = accountSrc[apiField];
                        changed = true;
                        anyChanged = true;
                    }
                });
                if (changed) row.hasChanged = true;
                return row;
            });

            this._pendingEdits.set(geo, { data: geoData, businessPlanId: null, yearRecordIds: geoYearIds });
        });

        // Rebuild GLOBAL view with updated pending edits
        this._buildGlobalAggregatedRows();
        this.dispatchEvent(new CustomEvent('redosave'));
        return anyChanged;
    }

    /**
     * Single-cell redo from GLOBAL: propagates that cell's account value to all individual geographies.
     */
    _redoCellFromGlobal(rowId, fieldName) {
        if (!this._allAccountRecords || this._allAccountRecords.length === 0) return;

        const yearColMap = this._yearColumnMap;
        const cols = ['pastYear2', 'pastYear', 'currentYear', 'nextYear', 'nextYear2'];
        const row = this.data.find(r => r.Id == rowId);
        if (!row) return;
        const rowDef = this.rowDefinitions.find(rd => rd.label === row.category);
        if (!rowDef || rowDef.label.includes('Total')) return;
        const fieldMap = this.getFieldMapping(rowDef.value);
        const apiField = fieldMap[fieldName];
        if (!apiField) return;

        const geoSet = new Set();
        this._allAccountRecords.forEach(rec => {
            if (rec.DMT_Booking_Geography__c && rec.DMT_Booking_Geography__c !== 'GLOBAL') {
                geoSet.add(rec.DMT_Booking_Geography__c);
            }
        });

        geoSet.forEach(geo => {
            const accountRec = this._allAccountRecords.find(rec =>
                rec.DMT_Booking_Geography__c === geo &&
                yearColMap[Number(rec.DMT_Year__c)] === fieldName
            );
            const accountValue = accountRec ? accountRec[apiField] : undefined;
            if (accountValue === undefined || accountValue === null) return;

            if (!this._pendingEdits.has(geo)) {
                const oppRecordByCol = {};
                (this._allOpportunityRecords || []).filter(r => r.DMT_Booking_Geography__c === geo).forEach(rec => {
                    const col = yearColMap[Number(rec.DMT_Year__c)];
                    if (col) oppRecordByCol[col] = rec;
                });
                const geoYearIds = { pastYear2: null, pastYear: null, currentYear: null, nextYear: null, nextYear2: null };
                cols.forEach(col => { if (oppRecordByCol[col]?.Id) geoYearIds[col] = oppRecordByCol[col].Id; });

                const geoData = this.rowDefinitions.map((rd, idx) => {
                    const fm = this.getFieldMapping(rd.value);
                    const r = {
                        Id: idx, category: rd.label,
                        isEditable: !rd.label.includes('Total'),
                        class: rd.label.includes('Total') ? 'slds-hint-parent dmt-table-title' : 'slds-hint-parent',
                        hasChanged: false
                    };
                    cols.forEach(c => {
                        const src = oppRecordByCol[c];
                        const af = fm[c];
                        r[c] = (af && src) ? (src[af] ?? NA_VALUE) : NA_VALUE;
                    });
                    return r;
                });
                this._pendingEdits.set(geo, { data: geoData, businessPlanId: null, yearRecordIds: geoYearIds });
            }

            const pending = this._pendingEdits.get(geo);
            const targetRow = pending.data.find(r => r.Id == rowId);
            if (targetRow) {
                targetRow[fieldName] = accountValue;
                targetRow.hasChanged = true;
            }
        });

        this._buildGlobalAggregatedRows();
        this.dispatchEvent(new CustomEvent('redosave'));
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

    formatDisplayValue(value) {
        if (value === undefined || value === null || value === '' || value === NA_VALUE) {
            return value;
        }
        const num = typeof value === 'number' ? value : parseFloat(value);
        if (isNaN(num)) {
            return value;
        }
        return new Intl.NumberFormat(LOCALE, {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2,
            useGrouping: 'always'
        }).format(num);
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
                    // Valor formateado para visualización (solo lectura)
                    displayValue: this.formatDisplayValue(value),
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
        const rawValue = event.target.value;

        // Round to 2 decimals to prevent floating-point accumulation in totals
        let newValue = rawValue;
        if (rawValue !== '' && rawValue !== null && !isNaN(Number(rawValue))) {
            newValue = Math.round(Number(rawValue) * 100) / 100;
        }

        console.log('[BP] handleInputChange: id=', id, '| field=', field, '| value=', newValue,
            '| activeValue=', this._activeValue);

        // 1. Update the background save data. Recompute hasChanged against the original
        // value (instead of forcing true) so reverting a field back to its original value
        // correctly clears the dirty flag and doesn't leave stale/no-op data to be saved.
        const rowIndex = this.data.findIndex(row => row.Id == id);
        if (rowIndex !== -1) {
            const updatedRow = { ...this.data[rowIndex], [field]: newValue };
            const originalRow = this.originalData ? this.originalData.find(o => o.Id === updatedRow.Id) : null;
            updatedRow.hasChanged = this._rowHasChanged(updatedRow, originalRow);
            this.data[rowIndex] = updatedRow;
        }
        
        // 2. CRITICAL FIX: Update the foreground UI data so it survives LMS re-renders
        const pRowIndex = this.processedData.findIndex(row => row.Id == id);
        if (pRowIndex !== -1) {
            const cell = this.processedData[pRowIndex].values.find(c => c.field === field);
            if (cell) {
                cell.value = newValue;
                cell.displayValue = this.formatDisplayValue(newValue);
            }
        }

        // 3. Recalculate section totals for the edited column
        this._recalculateSectionTotals(field);
        this._syncActiveFromCurrentGeography();

        // 4. Notify parent that data has changed (dirtyTabs)
        this.dispatchEvent(new CustomEvent('fieldchange'));
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

        const round2 = v => v !== null ? Math.round(v * 100) / 100 : null;

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
            return round2(total);
        };

        const nonXSellTotal = sumRows(NON_X_SELL_CATEGORIES);
        const xSellTotal    = sumRows(X_SELL_CATEGORIES);
        // Show N/A when both halves have no values; otherwise sum them (absent half counts as 0)
        const totalRevenues = (nonXSellTotal !== null || xSellTotal !== null)
            ? round2((nonXSellTotal ?? 0) + (xSellTotal ?? 0))
            : null;

        // Always sync total rows to the freshly computed value (N/A when no component data
        // exists). Previously a null total left the row's PRIOR stale value in place while still
        // flagging the row as changed, so clearing all inputs for a geography could still save a
        // stale total as real data — creating spurious/inconsistent BP records.
        const updates = {
            'Total Non X-Sell': nonXSellTotal === null ? NA_VALUE : nonXSellTotal,
            'Total X-Sell': xSellTotal === null ? NA_VALUE : xSellTotal,
            'Total Revenues': totalRevenues === null ? NA_VALUE : totalRevenues
        };

        // Keep baseXSellTotals in sync so recalculateTotalXSell doesn't overwrite with stale values
        const colToBase = { pastYear2: 'PY', pastYear: 'CY', currentYear: 'NY', nextYear: 'NY1' };
        if (xSellTotal !== null && colToBase[changedField]) {
            this.baseXSellTotals[colToBase[changedField]] = xSellTotal;
        }

        Object.entries(updates).forEach(([category, newVal]) => {
            const idx = this.data.findIndex(r => r.category === category);
            if (idx === -1) return;
            const currentRow = this.data[idx];
            if (currentRow[changedField] === newVal) return; // already in sync, nothing to do
            const updatedRow = { ...currentRow, [changedField]: newVal };
            const originalRow = this.originalData ? this.originalData.find(o => o.Id === updatedRow.Id) : null;
            updatedRow.hasChanged = this._rowHasChanged(updatedRow, originalRow);
            this.data[idx] = updatedRow;
        });

        // Sync to processedData for immediate UI feedback
        if (this.processedData) {
            this.processedData.forEach(row => {
                if (Object.prototype.hasOwnProperty.call(updates, row.category)) {
                    const cell = row.values?.find(c => c.field === changedField);
                    if (cell) {
                        cell.value = updates[row.category];
                        cell.displayValue = this.formatDisplayValue(updates[row.category]);
                    }
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
                    if (isEditing && cell.isEditable && cell.value === NA_VALUE) {
                        // Entering edit mode: clear N/A so text input shows blank
                        cell.value = '';
                    } else if (!isEditing && cell.isEditable && (cell.value === '' || cell.value === null || cell.value === undefined)) {
                        // Exiting edit mode: restore blank back to N/A for display
                        cell.value = NA_VALUE;
                    }
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
        console.log('[BP-PASTE] handlePasteData CALLED, pastedRows count:', pastedRows?.length,
            '| this.data count:', this.data?.length,
            '| sample pasted:', JSON.stringify(pastedRows?.[0]));
        if (!pastedRows || !Array.isArray(pastedRows) || !this.data) return;

        const TOTAL_CATEGORIES = new Set(['Total Non X-Sell', 'Total X-Sell', 'Total Revenues']);
        const EDITABLE_FIELDS = ['pastYear2', 'pastYear', 'currentYear', 'nextYear', 'nextYear2'];

        let totalChanged = 0;
        // Build a new data array to guarantee LWC reactivity
        const newData = this.data.map((existingRow, index) => {
            if (index >= pastedRows.length) return existingRow;
            if (TOTAL_CATEGORIES.has(existingRow.category)) return existingRow;

            const pastedRow = pastedRows[index];
            let changed = false;
            const updates = {};

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
                    updates[f] = newVal;
                    changed = true;
                }
            });

            if (changed) {
                totalChanged++;
                return { ...existingRow, ...updates, hasChanged: true };
            }
            return existingRow;
        });

        this.data = newData;

        console.log('[BP-PASTE] Rows changed:', totalChanged,
            '| sample data[0] after paste:', JSON.stringify({
                cat: this.data[0]?.category,
                py2: this.data[0]?.pastYear2,
                py: this.data[0]?.pastYear,
                cy: this.data[0]?.currentYear
            }));

        this._recalculateAllTotals();
        this.processDataForView();
        this._syncActiveFromCurrentGeography();

        console.log('[BP-PASTE] processDataForView done. processedData[0]:', JSON.stringify({
            cat: this.processedData?.[0]?.category,
            vals: this.processedData?.[0]?.values?.filter(v => v.field !== 'category').map(v => ({ f: v.field, v: v.value }))
        }));

        // In edit mode: don't save now — the general Save button will collect changes later.
        // Outside edit mode: save immediately (same as Redo button).
        if (this._isEditMode) {
            console.log('[BP-PASTE] edit mode — deferring save to general Save button');
            this.dispatchEvent(new CustomEvent('fieldchange'));
        } else if (this._preloadedRecordsMode) {
            console.log('[BP-PASTE] dispatching redosave for DB persistence');
            this.dispatchEvent(new CustomEvent('redosave'));
        } else {
            this.handleSave();
        }
    }

    /**
     * Rebuilds the original (last-known-DB) baseline rows for a given geography from the
     * cached _allOpportunityRecords, without touching this.data/this.originalData. Used as a
     * fallback when a pending edit's own originalData snapshot isn't available, so change
     * detection always compares against the CORRECT geography's baseline instead of whichever
     * geography happens to be active at save time (which previously caused spurious/duplicate
     * records to be created for other geographies).
     */
    _buildOriginalDataForGeo(geography) {
        const yearColMap = this._yearColumnMap;
        const cols = ['pastYear2', 'pastYear', 'currentYear', 'nextYear', 'nextYear2'];
        const recordByCol = {};
        (this._allOpportunityRecords || []).forEach(rec => {
            if (rec.DMT_Booking_Geography__c !== geography) return;
            const col = yearColMap[Number(rec.DMT_Year__c)];
            if (col) recordByCol[col] = rec;
        });
        return this.rowDefinitions.map((rowDef, index) => {
            const fieldMap = this.getFieldMapping(rowDef.value);
            const row = { Id: index, category: rowDef.label };
            cols.forEach(col => {
                const src = recordByCol[col];
                const apiField = fieldMap[col];
                row[col] = (apiField && src != null) ? (src[apiField] ?? NA_VALUE) : NA_VALUE;
            });
            return row;
        });
    }

    /**
     * Determines whether a row's year-column values actually differ from its original
     * (last-loaded/last-saved) counterpart. Treats '', null, undefined and NA_VALUE as
     * equivalent "empty" states so clearing a field back to its initial state is not
     * considered a change. Used to keep `hasChanged` accurate instead of sticking to true
     * forever once a field is touched, which could otherwise leave stale/no-op data that
     * gets saved as a real (spurious) BP record.
     */
    _rowHasChanged(currentRow, originalRow) {
        if (!originalRow) return true;
        const cols = ['pastYear2', 'pastYear', 'currentYear', 'nextYear', 'nextYear2'];
        const isEmpty = v => v === undefined || v === null || v === '' || v === NA_VALUE;
        return cols.some(col => {
            const a = currentRow[col];
            const b = originalRow[col];
            if (isEmpty(a) && isEmpty(b)) return false;
            return String(a) !== String(b);
        });
    }

    buildUpdateObject(changedRows, yearRecordIds = this._yearRecordIds, geography = this._bookingGeography, refOriginalData = this.originalData) {

        if (this.isClient) {
            // Client path: single record, all columns in one update
            const fields = { Id: this._clientFinancialsId };
            changedRows.forEach(row => {
                const originalRow = refOriginalData.find(orig => orig.Id === row.Id);
                if (!originalRow) return;
                const rowDefinition = this.rowDefinitions.find(r => r.label === originalRow.category);
                if (!rowDefinition) return;
                const fieldMap = this.getFieldMapping(rowDefinition.value);
                Object.entries(fieldMap).forEach(([fieldName, apiFieldName]) => {
                    if (row[fieldName] != originalRow[fieldName]) {
                        fields[apiFieldName] = toSaveValue(apiFieldName, row[fieldName]);
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
            const originalRow = refOriginalData.find(orig => orig.Id === row.Id);
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
                        target[apiField] = toSaveValue(apiField, row[col]);
                    }
                });
            } else {
                // BP rows: each column → its own year record
                cols.forEach(col => {
                    if (!updatesByCol[col]) return;
                    if (row[col] != originalRow[col]) {
                        updatesByCol[col][fieldMap[col]] = toSaveValue(fieldMap[col], row[col]);
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