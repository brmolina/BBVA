/*
 * Bulk Import screen (Configuration > Bulk Import, DMT_Line_God only). Reworked in CIBGLOBALD-4851: Treasury Lines
 * files, products tables replaced per line, preview of what Process will save and of each line's status move (with the
 * reason when a row will not be saved or a line stays in Draft, rules copied in bulkImportRules.js), Process and Update
 * Line Status in the background, Add OU.
 */
import { LightningElement, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import SHEETJS from '@salesforce/resourceUrl/DMT_SheetJS';
import LightningConfirm from 'lightning/confirm';
import processImportApex     from '@salesforce/apex/DMT_BulkImportController.processImport';
import getExistingLinesApex     from '@salesforce/apex/DMT_BulkImportController.getExistingLines';
import getExistingTermsForLinesApex from '@salesforce/apex/DMT_BulkImportController.getExistingTermsForLines';
import getExistingProductItemsForLinesApex from '@salesforce/apex/DMT_BulkImportController.getExistingProductItemsForLines';
import previewCompareUnsavedChangesApex from '@salesforce/apex/DMT_ApprovalChangeStep_Handler.previewCompareUnsavedChanges';
import addOuParticipantsApex from '@salesforce/apex/DMT_BulkImportController.addOuParticipants';
import getStatusContextApex from '@salesforce/apex/DMT_BulkImportController.getStatusContext';
import getCustomAssociationClientsApex from '@salesforce/apex/DMT_BulkImportController.getCustomAssociationClients';
import getJobStateApex from '@salesforce/apex/DMT_BulkImportController.getJobState';
import getStatusJobAfterLoadApex from '@salesforce/apex/DMT_BulkImportController.getStatusJobAfterLoad';
import countMissingOuParticipantsApex from '@salesforce/apex/DMT_BulkImportController.countMissingOuParticipants';
import searchOusApex            from '@salesforce/apex/DMT_BulkImportController.searchOus';
import queryCreatedLinesApex    from '@salesforce/apex/DMT_BulkImportController.queryCreatedLines';
import updateLineStatusApex     from '@salesforce/apex/DMT_BulkImportController.updateLineStatus';
import hasDMTLineGod    from '@salesforce/customPermission/DMT_Line_God';
// copies of the org rules a status move or a save must pass, and the value helpers they share; the
// 'keep in sync' list of every copied rule is at the top of bulkImportRules.js
import {
    valueText, normaliseValue, TERM_COLUMN_PREFIX, termValue, stepRuleReasons, termContinuityReasons, prospectReasons,
    otherProductsFlowReasons, productsTotalReasons, treasuryFlowReasons, approvalDataEditReasons, reasonText, reasonShortText,
    logRuleReasons, rowSaveError
} from './bulkImportRules';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// ─── Fixed column schemas ────────────────────────────────────────────────────

const LINES_HEADERS = [
    'Booking_Geography__c', 'Line_Id__c', 'Client_Code__c', 'Client__c',
    'g_group_id', 'End_Date__c', 'Start_Date__c', 'DMT_LastLevelId__c',
    'g_risk_level_clsfn_type__c', 'g_global_product_family_id__c',
    'g_global_product_subfamily_id__c', 'g_global_product_category_id__c',
    'g_gbl_product_subcategory_id__c', 'g_global_product_id__c',
    'DMT_Risk_Line_Term__c DMT_Init_Term__c', 'DMT_Risk_Line_Term__c DMT_End_Term__c',
    'DMT_Parent_Line__c', 'DMT_Risk_Line_Term__c DMT_Amount__c',
    'CurrencyIsoCode', 'owner User id_user__c', 'DMT_Comments__c',
    'Createbydate', 'Breakclause_Frequency__c', 'DMT_RiskLineTermId__c',
    'gf_priority_line_id__c', 'Name', 'gf_cutoff_date',
    'gf_group_priority_line_id__c', 'g_multioperation_ind_type__c',
    'g_line_status_type__c', 'Status__c', 'g_expert_criteria_risk_type__c'
];

const LINES_REQUIRED    = ['Line_Id__c']; // only the org-required column; the client is checked in Apex (DMT_BulkImportBatch)

// DMT_Line__c columns compared with Salesforce (New / Will Update / No Changes), by type. Only the
// columns present in the file are compared and saved (DMT_BulkImportBatch.LINE_FILE_FIELDS); a blank cell clears the field.
const LINE_COMPARE_FIELDS = {
    Name: 'text', Booking_Geography__c: 'text', DMT_Client_Entific__c: 'text', CurrencyIsoCode: 'text',
    Start_Date__c: 'date', End_Date__c: 'date', Client_Code__c: 'text', Golden_Code__c: 'text',
    FD_Amount__c: 'number', DvP_Amount__c: 'number', Breakclause_Frequency__c: 'text', First_Breakclause__c: 'text',
    Waiver__c: 'boolean', DMT_Mitigant_Agreement_comments__c: 'text', DMT_Comments__c: 'text',
    DMT_Additional_Restrictions__c: 'text', DMT_Client_Use__c: 'text', DMT_LastLevelId__c: 'text',
    g_line_status_type__c: 'text', DMT_ID_User__c: 'text'
};
// a blank cell in these columns keeps the Salesforce value (DMT_BulkImportBatch.KEEP_WHEN_BLANK_FIELDS)
const KEEP_WHEN_BLANK_FIELDS = ['First_Breakclause__c', 'Breakclause_Frequency__c'];
// order of the line columns in the preview (the status code before the currency)
const LINE_COLUMN_ORDER = ['Name', 'Booking_Geography__c', 'DMT_Client_Entific__c', 'g_line_status_type__c', 'CurrencyIsoCode',
    ...Object.keys(LINE_COMPARE_FIELDS).filter(f => !['Name', 'Booking_Geography__c', 'DMT_Client_Entific__c', 'g_line_status_type__c',
                                                     'CurrencyIsoCode'].includes(f))];
// child tables of the loaded lines. When a child file has rows for a line, every record of that object
// on that line is deleted and the file rows are inserted (Process); a line without rows in the file keeps its records.
// lineIdColumns: accepted names of the column that holds the parent Line_Id__c. fingerprint: columns that identify the
// file type (wrong drop zone check). displayFields: columns always shown, filled from the Salesforce records.
const CHILD_ZONES = {
    rlt: {
        label: 'Risk Line Terms',
        objectApiName: 'DMT_Risk_Line_Term__c',
        sfRelationship: 'DMT_Line__r',
        lineIdColumns: ['DMT_Line__r.Line_Id__c', 'Line_Id__c'],
        // The old 'DMT_Risk_Line_Term__c <field>' columns are not in it: a Lines file can carry the line amount in
        // 'DMT_Risk_Line_Term__c DMT_Amount__c'; the old Products file is recognised by DMT_RiskLineTermId__c.
        fingerprint: ['DMT_Line__r.Line_Id__c', 'DMT_Risk_Type__c', 'DMT_RiskLineTermId__c', 'DMT_Init_Term__c', 'DMT_End_Term__c',
                      'g_amortization_type__c'],
        displayFields: ['DMT_Risk_Type__c', 'DMT_RiskLineTermId__c', 'DMT_Amount__c', 'CurrencyIsoCode', 'DMT_Init_Term__c',
                        'DMT_End_Term__c', 'g_global_product_family_id__c', 'g_global_product_subfamily_id__c',
                        'g_global_product_category_id__c']
    },
    lpi: {
        label: 'Line Product Items',
        objectApiName: 'DMT_Line_Product_Item__c',
        sfRelationship: 'Line__r',
        lineIdColumns: ['Line__r.Line_Id__c', 'Line_Id__c'],
        fingerprint: ['Line__r.Line_Id__c', 'Product_Code_Value__c', 'Max_Tenor_WC__c', 'DMT_DerivativeRestriction__c',
                      'DMT_FDRestriction__c', 'DMT_DVPRestriction__c'],
        displayFields: ['Product_Code_Value__c', 'Max_Tenor_WC__c', 'DMT_DerivativeRestriction__c', 'DMT_FDRestriction__c',
                        'DMT_DVPRestriction__c']
    }
};
const CHILD_STATUS_NEW    = 'New';
const CHILD_STATUS_DELETE = 'Will Be Deleted';
const CHILD_STATUS_KEPT   = 'Kept';
const CHILD_STATUS_CREATED = 'Created'; // after Process: the records the load inserted
const CHILD_STATUS_CLASS  = {
    [CHILD_STATUS_NEW]: 'slds-text-color_success', [CHILD_STATUS_DELETE]: 'slds-text-color_error', [CHILD_STATUS_KEPT]: 'slds-text-color_weak',
    [CHILD_STATUS_CREATED]: 'slds-text-color_success'
};
// Old Other Products files name the term columns 'DMT_Risk_Line_Term__c <field>'; the tables show them as <field>
const CHILD_ERROR_LIMIT   = 20;

// status rules of the load (DMT_BulkImportBatch.planStatus, approved by Diego 2026-11-16)
const STATUS_BY_CODE = { DR: 'Draft', PR: 'Proposal', AP: 'Approval', RC: 'Ready to close', CL: 'Closed', CW: 'Closed' };
// File columns of the fields the validation rule AvoidEditNotDraft blocks outside Draft (DMT_BulkImportBatch.BLOCKED_OUTSIDE_DRAFT);
// Client_Code__c stands for Client__c; Amount__c comes from the old amount column (_changedLineFields)
const BLOCKED_FILE_COLUMNS = ['Name', 'Booking_Geography__c', 'CurrencyIsoCode', 'Start_Date__c', 'DvP_Amount__c', 'FD_Amount__c',
                              'First_Breakclause__c', 'Breakclause_Frequency__c', 'Waiver__c', 'DMT_LastLevelId__c', 'Client_Code__c',
                              'Amount__c'];
const LEGACY_AMOUNT_COLUMN = 'DMT_Risk_Line_Term__c DMT_Amount__c';
// background jobs of the screen. Events (DMT_BulkImportProgress__e, Phase__c set by
// DMT_BulkImportBatch.publishEvent) bring the progress and the row messages; the end of each job is read by polling its
// AsyncApexJob every POLL_MS (DMT_BulkImportController.getJobState), so a lost event never leaves the screen waiting.
const PHASE_PROCESS = 'PROCESS'; // DMT_BulkImportBatch.IMPORT_TYPE_PROCESS
const PHASE_STATUS = 'STATUS';
const POLL_MS = 4000;
const OU_SEARCH_MIN_CHARS = 2; // OU search from this many characters (DMT_BulkImportController.searchOus)
const OU_SEARCH_DELAY_MS = 300; // search after the user stops typing
const EVENT_GRACE_MS = 5000;        // after the job ends, time for its last event to bring the row messages
const POLL_MAX_FAILURES = 5;        // consecutive failed polls before the screen gives up and says so
const POLL_MAX_MS = 600000; // a job followed longer than this: the screen reads the org and stops waiting
const STATUS_JOB_FIND_MS = 60000;   // time for the status job started by a load to appear
const JOB_END_STATES = ['Completed', 'Failed', 'Aborted'];
// marked: Ids of Salesforce records the user removed one by one (that table not loaded)
// lineIds: the lines a loaded table applies to (null = every line of the load)
const emptyChildState = () => ({ fileName: '', fileRows: [], sfRows: [], errors: [], marked: [], lineIds: null });

// Fields that belong to DMT_Risk_Line_Term__c (confirmed by deploy errors + prefix convention)
const TERM_COLS = new Set([
    'DMT_RiskLineTermId__c',
    'g_risk_level_clsfn_type__c',
    'g_global_product_family_id__c', 'g_global_product_subfamily_id__c',
    'g_global_product_category_id__c', 'g_gbl_product_subcategory_id__c',
    'g_global_product_id__c',
    'gf_priority_line_id__c', 'gf_group_priority_line_id__c',
    'g_multioperation_ind_type__c', 'g_expert_criteria_risk_type__c',
    'g_amortization_type__c', 'gf_inscol_months_grace_number__c', 'gf_payment_frequency__c'
]);

const PREVIEW_ROW_LIMIT = 10;
const EVENT_CHANNEL     = '/event/DMT_BulkImportProgress__e';

export default class DmtBulkImport extends LightningElement {

    // SheetJS
    sheetJsLoaded = false;

    // ── Section 1 state ──────────────────────────────────────────────────────
    @track linesState = 'idle'; // idle | ready | error | submitting | processing | done
    linesFileName     = '';
    linesRowCount     = 0;
    @track linesValidationErrors  = [];
    @track linesPreviewColumns    = [];
    @track linesPreviewRows       = [];
    linesRows         = [];
    linesJobId        = '';
    linesTotal        = 0;
    linesProcessed    = 0;
    linesSuccessCount = 0;
    linesErrorCount   = 0;
    @track linesResultErrors      = [];
    linesSubscription = null;
    linesFailedIds    = new Set();
    linesRetryDragging = false;

    // Queried after lines batch completes — shown as a result table with navigation links
    @track linesCreatedRecords = null;

    // Summary shown after enrichment: { newCount, updateCount, noChangeCount }
    @track linesEnrichedStats = null;

    // ── Section 2 state ──────────────────────────────────────────────────────
    pendingTermsFromLines  = [];
    // child tables: per zone (rlt, lpi) the file rows (New) and the Salesforce records of the loaded
    // lines (Will Be Deleted / Kept, computed in _childRowsFor)
    @track childState = { rlt: emptyChildState(), lpi: emptyChildState() };
    childDragZone = '';

    // ── Line type selection (record type for DMT_Line__c) ────────────────────
    selectedRecordType = 'TreasurySettlement';

    get lineTypeOptions() {
        return [
            { label: 'Line Treasury',          value: 'TreasurySettlement' },
            { label: 'Line (Other Products)',   value: 'OtherProducts'      }
        ];
    }

    // one record type per load: locked once a file or paste is loaded, until Start Over
    get lineTypeLocked() {
        return this.isBusy || !this.linesIsIdle || Object.values(this.childState).some(state => !!state.fileName);
    }

    get lineTypeHelp() {
        return this.lineTypeLocked && !this.isBusy ? 'Click Start Over to change the Line Type.' : null;
    }

    handleLineTypeChange(event) {
        if (this._waitForJob() || this.lineTypeLocked) return;
        this.selectedRecordType = event.detail.value;
    }

    // ── Drag state ───────────────────────────────────────────────────────────
    linesDragging    = false;

    // ── Constant exposed to template ─────────────────────────────────────────
    get previewRowLimit() { return PREVIEW_ROW_LIMIT; }
    get hasAccess()       { return hasDMTLineGod; }

    get linesPreviewLabel() {
        return this.linesRowCount <= PREVIEW_ROW_LIMIT
            ? `Showing all ${this.linesRowCount} rows`
            : `Showing first ${PREVIEW_ROW_LIMIT} of ${this.linesRowCount} rows`;
    }

    // ── Created-records result table columns ─────────────────────────────────

    get linesCreatedColumns() {
        return [
            { label: 'Line ID', fieldName: 'lineUrl', type: 'url',
              typeAttributes: { label: { fieldName: 'Line_Id__c' }, target: '_blank' }, initialWidth: 180 },
            { label: 'Name', fieldName: 'Name', type: 'text', initialWidth: 220 },
            { label: 'Status', fieldName: 'Status__c', type: 'text', initialWidth: 100 },
            { label: 'Currency', fieldName: 'CurrencyIsoCode', type: 'text', initialWidth: 90 },
            { label: 'Geography', fieldName: 'Booking_Geography__c', type: 'text', initialWidth: 100 }
        ];
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    connectedCallback() {
        loadScript(this, SHEETJS)
            .then(() => { this.sheetJsLoaded = true; })
            .catch(e => console.error('SheetJS failed to load', e));

        onError(err => console.error('EmpApi error', err));

        this._pasteHandler = (event) => {
            const active = document.activeElement;
            if (active && (active.tagName === 'INPUT' || active.tagName === 'TEXTAREA' || active.isContentEditable)) return;
            // nothing new is loaded while a job runs on the lines
            if (this._waitForJob()) return;
            const text = event.clipboardData && event.clipboardData.getData('text');
            if (text) this._processPastedText(text);
        };
        document.addEventListener('paste', this._pasteHandler);
    }

    disconnectedCallback() {
        this._unsubscribe(this.linesSubscription);
        this._endAllWatches();
        document.removeEventListener('paste', this._pasteHandler);
    }

    // ── State getters ─────────────────────────────────────────────────────────

    get linesIsIdle()               { return this.linesState === 'idle'; }
    // Include processing states so the table stays visible during and after batch
    get linesHasFile()              { return ['ready', 'error', 'submitting', 'processing', 'done'].includes(this.linesState); }
    get linesHasValidationErrors()  { return this.linesState === 'error' && this.linesValidationErrors.length > 0; }
    get linesShowPreview()          { return ['ready', 'submitting', 'processing', 'done'].includes(this.linesState); }
    get linesIsProcessing()         { return ['submitting', 'processing'].includes(this.linesState); }
    get linesShowSubmit()           { return ['ready', 'error', 'done'].includes(this.linesState); }
    get linesIsDone()               { return this.linesState === 'done'; }
    // Disabled when not ready OR when every row is already "No Changes"
    get linesProgress()             { return this.linesTotal > 0 ? Math.round(this.linesProcessed / this.linesTotal * 100) : 0; }
    get linesHasResultErrors()      { return this.linesResultErrors.length > 0; }
    get linesDropZoneClass()  {
        return 'drop-zone' +
            (this.linesDragging  ? ' drop-zone_active'  : '') +
            (this.linesRows.length > 0 ? ' drop-zone_compact' : '') +
            (this.isBusy ? ' drop-zone_disabled' : '');
    }
    get linesDropZoneText()   {
        return this.linesRows.length > 0
            ? `${this.linesRowCount} rows loaded. Drop a file on this section or paste (Ctrl+V) to add / update lines`
            : 'Drop Lines XLSX or CSV here, or paste with Ctrl+V';
    }
    get linesRetryDropZoneClass()   { return 'drop-zone drop-zone_compact' + (this.linesRetryDragging ? ' drop-zone_active' : '') + (this.isBusy ? ' drop-zone_disabled' : ''); }
    get hasLinesCreatedRecords()    { return this.linesCreatedRecords && this.linesCreatedRecords.length > 0; }
    get hasLinesEnrichedStats()     { return this.linesEnrichedStats !== null; }

    // Update Line Status is offered once the lines were submitted, or when every line is already No Changes
    get step2Enabled() {
        // with a loaded table the button shows; updateLineStatusDisabled decides when it can be clicked
        const loaded = this.linesRows.length > 0 && this.linesState === 'ready';
        return (this.linesState === 'done' && (this.linesSuccessCount > 0 || this._loadJobCompleted)) || loaded;
    }

    // ── Child tables (Risk Line Terms, Line Product Items) ──

    get isTreasury()        { return this.selectedRecordType === 'TreasurySettlement'; }
    // The child zones open once the Lines table has rows: child rows are accepted only for those lines
    get childrenEnabled()   { return this.linesRows.length > 0; }
    get childrenDisabled()  { return !this.childrenEnabled; }
    get childCardClass()    { return 'slds-card' + (this.childrenEnabled ? '' : ' section-disabled'); }

    // One entry per visible zone, rendered with for:each (Line Product Items only for Treasury lines)
    get childSections() {
        return Object.keys(CHILD_ZONES)
            .filter(zone => zone !== 'lpi' || this.isTreasury)
            .map(zone => {
                const state = this.childState[zone];
                const rows  = this._childRowsFor(zone);
                const count = status => rows.filter(r => r.__status === status).length;
                const label = CHILD_ZONES[zone].label;
                return {
                    key: zone,
                    label,
                    dropZoneClass: 'drop-zone drop-zone_compact' + (this.childDragZone === zone ? ' drop-zone_active' : '') + (this.isBusy ? ' drop-zone_disabled' : ''),
                    dropZoneText: state.fileRows.length > 0
                        ? `${state.fileName}: ${state.fileRows.length} rows. Drop another ${label} file on this section or paste (Ctrl+V) to replace them`
                        : `Drop ${label} XLSX or CSV here, or paste with Ctrl+V`,
                    hasErrors: state.errors.length > 0,
                    errors: state.errors,
                    hasRows: rows.length > 0,
                    newCount: count(CHILD_STATUS_NEW),
                    deleteCount: count(CHILD_STATUS_DELETE),
                    keptCount: count(CHILD_STATUS_KEPT),
                    // after Process: Created / Deleted / Kept (_processedChildren)
                    showResult: this._showChildResult,
                    createdCount: count(CHILD_STATUS_CREATED),
                    deletedCount: this._deletedChildCount(zone),
                    columns: this._childColumns(zone, rows),
                    rows: this._childDisplayRows(rows)
                };
            });
    }

    /**
     * File rows (New) plus the Salesforce records of the loaded lines: Will Be Deleted when that table is loaded (it
     * replaces the records of every line of the load, _zoneLoaded), Kept when it is not. After Process only the lines
     * that failed keep their file rows for a retry. Sorted by line, file rows first.
     */
    _childRowsFor(zone) {
        const state   = this.childState[zone];
        // requirement point 2 (Diego, 2026-11-13): a loaded table replaces the records of every line of
        // the load, also the lines without rows in it
        const covered = this._zoneLoaded(zone) && !this.linesIsDone
            ? new Set(this.linesRows.map(r => r['Line_Id__c']).filter(lineId => this._zoneCovers(zone, lineId)))
            : new Set(state.fileRows.map(r => r.__lineId));
        // after Process, the records of the lines whose products the load replaced were created by it
        const created = this._showChildResult ? this._savedReplacedLines(zone) : new Set();
        // only the records of the lines still in the load; a record removed one by one shows Will Be
        // Deleted with Restore (__marked)
        const loadedLines = new Set(this.linesRows.map(r => r['Line_Id__c']));
        const marked  = new Set(state.marked || []);
        const sfRows  = state.sfRows.filter(r => loadedLines.has(r.__lineId)).map(r => {
            if (covered.has(r.__lineId)) return { ...r, __status: CHILD_STATUS_DELETE, __marked: false };
            if (marked.has(r.__sfId))    return { ...r, __status: CHILD_STATUS_DELETE, __marked: true };
            return { ...r, __status: created.has(r.__lineId) ? CHILD_STATUS_CREATED : CHILD_STATUS_KEPT, __marked: false };
        });
        return [...state.fileRows, ...sfRows]
            .map((r, idx) => ({ r, idx }))
            .sort((a, b) => a.r.__lineId.localeCompare(b.r.__lineId) || a.idx - b.idx)
            .map(x => x.r);
    }

    _childColumns(zone, rows) {
        const fields = [...CHILD_ZONES[zone].displayFields];
        rows.forEach(r => Object.keys(r).forEach(k => { if (!k.startsWith('__') && !fields.includes(k)) fields.push(k); }));
        return [
            { label: 'Status', fieldName: '__status', type: 'text', initialWidth: 130,
              cellAttributes: { class: { fieldName: '__statusClass' } } },
            { label: 'Line_Id__c', fieldName: '__lineId', type: 'text', initialWidth: 180 },
            ...fields.map(f => ({ label: f, fieldName: this._safeKey(f), type: 'text', initialWidth: 160 })),
            { type: 'action', typeAttributes: { rowActions: this._childRowActions } }
        ];
    }

    _childDisplayRows(rows) {
        return rows.map(r => {
            const flat = { __key: r.__key, __lineId: r.__lineId, __status: r.__status, __statusClass: CHILD_STATUS_CLASS[r.__status],
                           __marked: !!r.__marked };
            Object.keys(r).forEach(k => {
                if (k.startsWith('__')) return;
                const v = r[k];
                flat[this._safeKey(k)] = (v === null || v === undefined) ? '' : String(v);
            });
            return flat;
        });
    }

    // a Salesforce record removed one by one (marked) or put back
    _setMarked(zone, recordId, on) {
        const marked = (this.childState[zone].marked || []).filter(id => id !== recordId);
        if (on) marked.push(recordId);
        this._setChildState(zone, { marked });
    }

    // Ids removed one by one, by line (none when the table is loaded: it replaces everything)
    _markedByLine(zone) {
        const byLine = new Map();
        if (zone === 'lpi' && !this.isTreasury) return byLine;
        const marked = new Set(this.childState[zone].marked || []);
        // a line the loaded table applies to has all its records replaced
        this.childState[zone].sfRows.filter(r => marked.has(r.__sfId) && !this._zoneCovers(zone, r.__lineId)).forEach(r => {
            if (!byLine.has(r.__lineId)) byLine.set(r.__lineId, []);
            byLine.get(r.__lineId).push(r.__sfId);
        });
        return byLine;
    }

    // result of the last Process for the child tables: per zone the lines whose products were replaced
    // and how many Salesforce records they had (deleted). Cleared when a new file is loaded.
    get _showChildResult() { return this.linesIsDone && !!this._processedChildren; }

    _savedReplacedLines(zone) {
        const result = this._processedChildren && this._processedChildren[zone];
        if (!result) return new Set();
        return new Set([...result.lines].filter(lineId => !this.linesFailedIds.has(lineId)));
    }

    _deletedChildCount(zone) {
        if (!this._showChildResult) return 0;
        const result = this._processedChildren[zone];
        return [...result.deletedByLine.entries()]
            .filter(([lineId]) => !this.linesFailedIds.has(lineId))
            .reduce((sum, [, count]) => sum + count, 0);
    }

    // at Process: the lines each zone replaces and their Salesforce records (to be deleted)
    _snapshotChildChanges(units) {
        this._processedChildren = {};
        ['rlt', 'lpi'].forEach(zone => {
            const lines = new Set(units.filter(u => u[zone]).map(u => u.line['Line_Id__c']));
            const deletedByLine = new Map();
            this.childState[zone].sfRows.filter(r => lines.has(r.__lineId))
                .forEach(r => deletedByLine.set(r.__lineId, (deletedByLine.get(r.__lineId) || 0) + 1));
            // records removed one by one
            units.filter(u => u[zone + 'Delete']).forEach(u => {
                const lineId = u.line['Line_Id__c'];
                deletedByLine.set(lineId, (deletedByLine.get(lineId) || 0) + u[zone + 'Delete'].length);
            });
            this._processedChildren[zone] = { lines, deletedByLine };
        });
    }

    // File rows can be removed; a Kept Salesforce record can be removed one by one (before Process) and put back with
    // Restore; records a loaded table replaces cannot
    _childRowActions = (row, doneCallback) => {
        if (row.__marked) {
            doneCallback([{ label: 'Restore', name: 'restore' }]);
            return;
        }
        const removable = row.__status === CHILD_STATUS_NEW || (row.__status === CHILD_STATUS_KEPT && this.linesState === 'ready');
        doneCallback([{ label: 'Remove row', name: 'remove', disabled: !removable }]);
    };

    handleChildRowAction(event) {
        if (this._waitForJob()) return;
        const zone  = event.target.dataset.zone;
        const key   = event.detail.row.__key;
        // a Salesforce record removed one by one (Kept -> Will Be Deleted) and Restore
        if (event.detail.action.name === 'restore') {
            this._setMarked(zone, key, false);
            return;
        }
        if (event.detail.action.name !== 'remove') return;
        if (event.detail.row.__status === CHILD_STATUS_KEPT) {
            this._setMarked(zone, key, true);
            this._showUndo(`${CHILD_ZONES[zone].label} record of line ${event.detail.row.__lineId} will be deleted.`,
                () => this._setMarked(zone, key, false));
            return;
        }
        const state = this.childState[zone];
        // the removed row can be put back for 5 seconds (Undo)
        const index = state.fileRows.findIndex(r => r.__key === key);
        if (index < 0) return;
        const removed = state.fileRows[index];
        this._setChildState(zone, { fileRows: state.fileRows.filter(r => r.__key !== key) });
        this._showUndo(`${CHILD_ZONES[zone].label} row of line ${removed.__lineId} removed.`, () => {
            const rows = [...this.childState[zone].fileRows];
            rows.splice(Math.min(index, rows.length), 0, removed);
            this._setChildState(zone, { fileRows: rows });
        });
    }

    // ── Remove a line before Process (with its product rows of the files), Undo for 5 seconds ──────

    _lineRowActions = (row, doneCallback) => {
        doneCallback([{ label: 'Remove row', name: 'remove', disabled: this.linesState !== 'ready' }]);
    };

    handleLineRowAction(event) {
        if (this._waitForJob()) return;
        if (event.detail.action.name !== 'remove' || this.linesState !== 'ready') return;
        const lineId = event.detail.row['Line_Id__c'];
        const index  = this.linesRows.findIndex(r => r['Line_Id__c'] === lineId);
        if (index < 0) return;
        const removedLine = this.linesRows[index];
        const removedChildren = {};
        ['rlt', 'lpi'].forEach(zone => {
            removedChildren[zone] = this.childState[zone].fileRows.filter(r => r.__lineId === lineId);
            if (removedChildren[zone].length > 0) {
                this._setChildState(zone, { fileRows: this.childState[zone].fileRows.filter(r => r.__lineId !== lineId) });
            }
        });
        this._setLineRows(this.linesRows.filter((r, i) => i !== index));
        const childCount = removedChildren.rlt.length + removedChildren.lpi.length;
        this._showUndo(`Line ${lineId} removed${childCount > 0 ? ` with its ${childCount} product row(s) of the files` : ''}.`, () => {
            const rows = [...this.linesRows];
            rows.splice(Math.min(index, rows.length), 0, removedLine);
            this._setLineRows(rows);
            ['rlt', 'lpi'].forEach(zone => {
                if (removedChildren[zone].length > 0) {
                    this._setChildState(zone, { fileRows: [...this.childState[zone].fileRows, ...removedChildren[zone]] });
                }
            });
        });
    }

    // The Lines table after a remove / undo: same comparison with Salesforce, nothing queried again
    _setLineRows(rows) {
        this.linesRows = rows;
        this.linesRowCount = rows.length;
        if (this._sfLinesById) {
            this._applyLineEnrichment(rows, [...this._sfLinesById.values()]);
        } else {
            const ids = new Set(rows.map(r => r['Line_Id__c']));
            this.linesPreviewRows = this.linesPreviewRows.filter(p => ids.has(p['Line_Id__c']));
        }
    }

    // A bar at the bottom of the screen with the message and Undo; it closes after 5 seconds
    undoNotice = null;

    _showUndo(message, undo) {
        clearTimeout(this._undoTimer);
        this.undoNotice = { message };
        this._undoAction = undo;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._undoTimer = setTimeout(() => { this.undoNotice = null; this._undoAction = null; }, 5000);
    }

    handleUndo() {
        if (this.isBusy) return;
        clearTimeout(this._undoTimer);
        const undo = this._undoAction;
        this.undoNotice = null;
        this._undoAction = null;
        if (undo) undo();
    }

    _setChildState(zone, changes) {
        this.childState = { ...this.childState, [zone]: { ...this.childState[zone], ...changes } };
        // the products change the Status Change cells (products total, Ready to close recheck)
        if (this.linesPreviewRows && this.linesPreviewRows.length > 0) this._refreshStatusCells();
    }

    _resetChildren() {
        this.childState = { rlt: emptyChildState(), lpi: emptyChildState() };
    }

    openChildFilePicker(event) {
        if (this._waitForJob()) return;
        const zone = event.target.dataset.zone;
        this.template.querySelector(`input[data-zone="${zone}"]`).click();
    }

    handleChildFileInputChange(event) {
        const file = event.target.files[0];
        if (file) this._processFile(file, event.target.dataset.zone);
        event.target.value = '';
    }

    handleChildDragOver(event) {
        event.preventDefault();
        const zone = event.currentTarget.dataset.zone;
        if (this.childDragZone !== zone) this.childDragZone = zone; // dragover fires continuously: re-render only on change
    }

    handleChildDragLeave() {
        this.childDragZone = '';
    }

    handleChildFileDrop(event) {
        event.preventDefault();
        if (this._waitForJob()) return;
        this.childDragZone = '';
        const file = event.dataTransfer.files[0];
        if (file) this._processFile(file, event.currentTarget.dataset.zone);
    }

    /**
     * File type from its columns: 'lines', 'rlt', 'lpi' or null. The old Other Products Lines file carries term columns
     * too and is recognised by gf_cutoff_date.
     */
    _detectFileType(headers) {
        const set = new Set(headers);
        if (set.has('gf_cutoff_date')) return 'lines';
        if (CHILD_ZONES.lpi.fingerprint.some(c => set.has(c))) return 'lpi';
        if (CHILD_ZONES.rlt.fingerprint.some(c => set.has(c))) return 'rlt';
        if (set.has('Line_Id__c')) return 'lines';
        return null;
    }

    _zoneLabel(zone) {
        return zone === 'lines' ? 'Lines' : CHILD_ZONES[zone].label;
    }

    /**
     * Sends parsed rows to the zone they belong to. A file dropped in another zone than its columns say asks first
     * (LightningConfirm) and, on OK, loads where it belongs.
     */
    async _routeParsedRows(rows, fileName, zone) {
        if (rows.length === 0) {
            this._zoneErrors(zone, [{ key: 'empty', message: 'The file contains no data rows.' }]);
            return;
        }
        const detected = this._detectFileType(Object.keys(rows[0]).filter(k => k !== '__rowIndex'));
        let target = zone;
        if (detected && detected !== zone) {
            const confirmed = await LightningConfirm.open({
                label: 'Wrong drop zone',
                message: `${fileName} looks like a ${this._zoneLabel(detected)} file, not a ${this._zoneLabel(zone)} file. Load it as ${this._zoneLabel(detected)}?`,
                theme: 'warning'
            });
            if (!confirmed) return;
            target = detected;
        }
        if (target === 'lines') this._onRowsParsed(rows, fileName, 'lines');
        else this._loadChildFile(target, rows, fileName);
    }

    _zoneErrors(zone, errors) {
        if (zone === 'lines') this._setValidationErrors('lines', errors);
        else this._setChildState(zone, { errors });
    }

    /**
     * A child file replaces that table's file rows. Rows without a line id, or for a line that is not in the Lines
     * table, are rejected and listed.
     */
    _loadChildFile(zone, rows, fileName) {
        this._processedChildren = null; // a new load: no Created / Deleted result
        this._processedPlans = null;
        const conf = CHILD_ZONES[zone];
        if (zone === 'lpi' && !this.isTreasury) {
            this._toast('Line Product Items not loaded', 'Line Product Items are only loaded for Treasury lines. Select Line Treasury as Line Type.');
            return;
        }
        if (!this.childrenEnabled) {
            this._toast(`${conf.label} not loaded`, 'Load the Lines file first: child rows are accepted only for the lines in the Lines table.');
            return;
        }
        const headers      = Object.keys(rows[0]).filter(k => k !== '__rowIndex');
        const lineIdColumn = conf.lineIdColumns.find(c => headers.includes(c));
        if (!lineIdColumn) {
            this._setChildState(zone, { errors: [{ key: 'line-id-column', message: `Missing column: ${conf.lineIdColumns.join(' or ')}` }] });
            return;
        }
        const knownLineIds = new Set(this.linesRows.map(r => r['Line_Id__c']));
        const accepted = [];
        const rejected = [];
        rows.forEach(row => {
            const lineId = String(row[lineIdColumn] || '').trim();
            if (!lineId) rejected.push(`Row ${row.__rowIndex}: ${lineIdColumn} is blank. Row not loaded.`);
            else if (!knownLineIds.has(lineId)) rejected.push(`Row ${row.__rowIndex}: line ${lineId} is not in the Lines table. Row not loaded.`);
            else accepted.push(this._fileRowToChild(zone, row, lineId));
        });
        const errors = rejected.slice(0, CHILD_ERROR_LIMIT).map((message, i) => ({ key: `rejected-${i}`, message }));
        if (rejected.length > CHILD_ERROR_LIMIT) {
            errors.push({ key: 'rejected-more', message: `${rejected.length - CHILD_ERROR_LIMIT} more rows not loaded.` });
        }
        this._setChildState(zone, { fileName, fileRows: accepted, errors, lineIds: null });
    }

    // A file row keyed by field name: line id columns become __lineId, 'DMT_Risk_Line_Term__c <field>' becomes <field>
    _fileRowToChild(zone, row, lineId) {
        const child = { __key: `${zone}-file-${row.__rowIndex}`, __rowIndex: row.__rowIndex, __lineId: lineId, __status: CHILD_STATUS_NEW };
        Object.keys(row).forEach(k => {
            if (k === '__rowIndex' || CHILD_ZONES[zone].lineIdColumns.includes(k)) return;
            child[k.startsWith(TERM_COLUMN_PREFIX) ? k.substring(TERM_COLUMN_PREFIX.length) : k] = row[k];
        });
        return child;
    }

    _setSfChildren(zone, records) {
        const relationship = CHILD_ZONES[zone].sfRelationship;
        const sfRows = (records || []).map(record => {
            const child = { __key: record.Id, __sfId: record.Id, __lineId: record[relationship] ? record[relationship].Line_Id__c : '' };
            // the parent lookup Id (DMT_Line__c / Line__c) comes with the relationship and is not shown
            const lookupField = relationship.replace(/__r$/, '__c');
            Object.keys(record).forEach(k => { if (k !== 'Id' && k !== relationship && k !== lookupField) child[k] = record[k]; });
            return child;
        });
        // marks of records that no longer exist (deleted by the load) are dropped
        const ids = new Set(sfRows.map(r => r.__sfId));
        this._setChildState(zone, { sfRows, marked: (this.childState[zone].marked || []).filter(id => ids.has(id)) });
    }

    // Old Other Products Lines file: its term columns are the Risk Line Terms file rows
    _loadTermsFromLinesFile() {
        if (this.pendingTermsFromLines.length === 0) return;
        const rows = this.pendingTermsFromLines; // each term keeps the row of its line in the Lines file
        this._loadChildFile('rlt', rows, `${this.linesFileName} (term columns)`);
    }

    // ── Update Line Status ────────────────────────────────────────────────────

    lineStatusUpdateState = 'idle'; // idle | launching | launched

    // Line_Id__c of this import that exist in Salesforce — failed rows are excluded
    get importedLineIds() {
        return this.linesRows
            .filter(r => r.__status !== 'Failed')
            .map(r => r['Line_Id__c'])
            .filter(Boolean);
    }
    get showUpdateLineStatus()      { return this.step2Enabled; }

    /**
     * The lines the button moves: existing Draft lines whose code points to another status (plan
     * byButton), with the plan of the moment of Process once processed; lines it already moved are left out. Lines
     * Process moves itself are not the button's.
     */
    get _buttonPlans() {
        const frozen = this._processedPlans && this.linesState !== 'ready';
        return this.importedLineIds
            .map(lineId => this.linesRows.find(r => r['Line_Id__c'] === lineId))
            .filter(Boolean)
            .map(row => ({ row, plan: frozen ? (this._processedPlans.get(row['Line_Id__c']) || null) : this._statusPlan(row) }))
            .filter(p => {
                const result = this._statusResults ? this._statusResults.get(p.row['Line_Id__c']) : null;
                return p.plan && p.plan.byButton && !(result && result.state === 'moved');
            });
    }

    get linesWithStatusCode() {
        return this._buttonPlans.map(p => p.row);
    }

    // lines or products of the file not saved yet: the button reads the lines from Salesforce, so it
    // waits for Process
    get _hasUnsavedChanges() {
        return this.linesState === 'ready' && this._buildUnits().length > 0;
    }

    // status of the line's code once saved: the file column when present, else the stored code
    _savedCodeStatus(row) {
        const sf = this._sfLinesById ? this._sfLinesById.get(row['Line_Id__c']) : null;
        const code = 'g_line_status_type__c' in row ? row['g_line_status_type__c'] : (sf ? sf.g_line_status_type__c : '');
        return STATUS_BY_CODE[valueText(code).toUpperCase()] || null;
    }

    // lines with a code that the org rules would reject (same check as Process, _stayDraftReasons):
    // they are not sent, so no failure email; [{ lineId, reasons }]. Replaces the old products-amount pre-check: the
    // Treasury flow DMT_TRSR_Line_Validations is skipped for DMT_Line_God, which this screen requires.
    get linesBlockingUpdateLineStatus() {
        return this._buttonPlans.filter(p => p.plan.stayDraft)
            .map(p => ({ lineId: p.row['Line_Id__c'], reasons: p.plan.stayDraft }));
    }

    get updateLineStatusBlockedMessage() {
        // why the button is disabled or what it will skip
        if (this._backgroundJobRunning && this.lineStatusUpdateState === 'idle') {
            return 'Wait: another job is running on these lines (Process, status move or Add OU).';
        }
        if (this._hasUnsavedChanges) {
            return 'Process first: the file has lines or products not saved yet, and Update Line Status moves the lines as they are in Salesforce.';
        }
        const blocking = this.linesBlockingUpdateLineStatus;
        if (blocking.length === 0) return '';
        const shown = blocking.slice(0, 5).map(b => `${b.lineId} (${reasonText(b.reasons)})`).join(' | ')
                      + (blocking.length > 5 ? ` | +${blocking.length - 5} more` : '');
        return `${blocking.length} of ${this.linesWithStatusCode.length} line(s) with a status code will stay in Draft and are not sent: ${shown}.`;
    }

    // enabled only with nothing left to save and at least one line it can move
    get updateLineStatusDisabled() {
        const movable = this.linesWithStatusCode.length - this.linesBlockingUpdateLineStatus.length;
        return this._backgroundJobRunning || this._hasUnsavedChanges || movable <= 0;
    }

    async updateLineStatus() {
        const blocking = this.linesBlockingUpdateLineStatus;
        const blocked = new Set(blocking.map(b => b.lineId));
        const lineIds = this.importedLineIds.filter(lineId => !blocked.has(lineId));
        if (lineIds.length === 0) return;

        this.lineStatusUpdateState = 'launching';
        // the lines with a code follow the job: events (Phase STATUS, this jobId) and the job state
        const jobId = this._newJobId();
        const moves = this.linesWithStatusCode
            .filter(line => !blocked.has(line['Line_Id__c']))
            .map(line => ({ lineId: line['Line_Id__c'], target: this._savedCodeStatus(line) }));
        await this._watchStatusMoves(jobId, moves);
        updateLineStatusApex({ lineIds, jobId })
            .then(asyncJobId => {
                this.lineStatusUpdateState = 'launched';
                this._startStatusWait(moves, () => Promise.resolve(asyncJobId));
                this._toast('Update Line Status running in the background',
                    `${moves.length} line(s) move to the status of their code. The result will show in the Validation / Status Change column.`,
                    'info');
            })
            .catch(e => {
                console.error('updateLineStatus error', e);
                this.lineStatusUpdateState = 'idle';
                this._endWatch(PHASE_STATUS);
                this._toast('Update Line Status failed', (e && e.body && e.body.message) || 'Unexpected error');
            });
    }

    // ── Add OU ──────────────────────────────────────────────
    // One OU per load (Diego): after Process, the users of the OU with a DMT Read/Write role and each line's owner become
    // participants (Edit, Approval Edit) of the lines of the load (DMT_BulkImportController.addOuParticipants).

    ouCode  = '';
    ouState = 'idle'; // idle | running | done
    ouResultText = '';
    ouOptions = null; // OU search result (null = no search)
    ouOptionsOpen = false;
    ouResultIsError = false;
    // background status move: progress text and the result per Line_Id__c (_finishStatusMoves)
    statusProgressText = '';
    _statusMoves = []; // lines of the status move being followed
    _statusDone = false;
    _statusResults = new Map();
    _loadJobCompleted = false; // the load job Completed while its final event was lost (_onLoadJobDone)

    // after Process, or before it when every line of the table already exists in Salesforce (a line to
    // create gets its participants only once Process has created it)
    get showAddOu() {
        if (this.linesIsDone) return this.importedLineIds.length > 0;
        return this.linesState === 'ready' && this.linesRows.length > 0 && !!this._sfLinesById
               && this.linesRows.every(r => this._sfLinesById.has(r['Line_Id__c']));
    }
    get ouLocked()      { return this.ouState !== 'idle'; }
    get ouResultClass() {
        const colour = this.ouState === 'running' ? 'slds-text-color_weak' : (this.ouResultIsError ? 'slds-text-color_error' : 'slds-text-color_success');
        return 'slds-m-left_small slds-text-body_small ' + colour;
    }
    get addOuDisabled() { return this.ouLocked || !this.ouCode.trim() || this._backgroundJobRunning; }

    handleOuChange(event) {
        this.ouCode = event.detail.value || '';
        // OU search: from 2 characters, once the user stops typing
        clearTimeout(this._ouSearchTimer);
        const text = this.ouCode.trim();
        if (text.length < OU_SEARCH_MIN_CHARS) {
            this.ouOptions = null;
            return;
        }
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._ouSearchTimer = setTimeout(() => this._searchOus(text), OU_SEARCH_DELAY_MS);
    }

    // up to 10 OUs that contain the text and have Read/Write users (the ones Add OU adds)
    async _searchOus(text) {
        try {
            const found = await searchOusApex({ prefix: text });
            if (text !== this.ouCode.trim()) return; // the user kept typing: a newer search follows
            this.ouOptions = found.map(o => ({ code: o.code, users: `${o.users} user(s)` }));
            this.ouOptionsOpen = true;
        } catch (e) {
            console.error('OU search failed', e);
            this.ouOptions = null;
        }
    }

    // the list under the OU input: the OUs found, or a line saying none was found
    get showOuOptions()  { return this.ouOptionsOpen && !!this.ouOptions && !this.ouLocked; }
    get ouOptionsEmpty() { return !!this.ouOptions && this.ouOptions.length === 0; }

    handleOuPick(event) {
        event.preventDefault(); // mousedown before the input blur, so the click is not lost
        this.ouCode = event.currentTarget.dataset.code;
        this.ouOptionsOpen = false;
    }

    handleOuFocus() {
        if (this.ouOptions) this.ouOptionsOpen = true;
    }

    handleOuBlur() {
        this.ouOptionsOpen = false;
    }

    handleOuKeyDown(event) {
        if (event.key === 'Escape') this.ouOptionsOpen = false;
    }

    // The batch adds the participants in the background; the screen follows the job and, when it ends, checks in
    // Salesforce that every OU user and owner is a participant (countMissingOuParticipants): success or the number missing
    addOu() {
        const lineIds = this.importedLineIds;
        if (this.addOuDisabled || lineIds.length === 0) return;
        const ouCode = this.ouCode.trim();
        this.ouState = 'running';
        this._ouLineIds = new Set(lineIds); // the lines this OU is added to
        this.ouResultText = 'Adding participants…';
        this.ouResultIsError = false;
        addOuParticipantsApex({ ouCode, lineIds })
            .then(result => {
                this._toast('Add OU running in the background', `Adding ${result.users} users to the ${lineIds.length} lines of the load.`, 'info');
                this._pollJob('OU', () => Promise.resolve(result.asyncJobId), state => this._finishAddOu(ouCode, lineIds, result.users, state));
            })
            .catch(e => {
                this.ouState = 'idle';
                this.ouResultText = '';
                this._toast('Add OU failed', (e && e.body && e.body.message) || 'Unexpected error');
            });
    }

    async _finishAddOu(ouCode, lineIds, users, state) {
        let missing = null;
        try {
            missing = await countMissingOuParticipantsApex({ ouCode, lineIds });
        } catch (e) {
            console.error('Add OU result check failed', e);
        }
        this.ouState = 'done';
        // the result stays next to the Add OU button
        this.ouResultText = missing === 0 ? `${users} participant(s) added to all ${lineIds.length} line(s).`
            : missing === null ? 'Add OU ended but the result could not be checked. Check the participants of the lines.'
            : `${missing} participant(s) missing or without Edit / Approval Edit. Check the exception log.`;
        this.ouResultIsError = missing !== 0;
        if (missing === 0) {
            this._toast('Add OU finished', `${users} users added to all the lines of the load.`, 'success');
        } else if (missing === null) {
            this._toast('Add OU finished', `The job ended (${state.status}) but the result could not be checked. Check the participants of the lines.`, 'warning');
        } else {
            this._toast('Add OU finished with errors',
                `${missing} participant(s) are missing or without Edit / Approval Edit.${state.extendedStatus ? ' ' + state.extendedStatus : ''} Check the exception log.`,
                'error');
        }
    }

    // ── File picker triggers ──────────────────────────────────────────────────

    openLinesFilePicker() {
        if (this._waitForJob()) return;
        this.template.querySelector('input[data-section="lines"]').click();
    }

    handleFileInputChange(event) {
        const file    = event.target.files[0];
        const section = event.target.dataset.section;
        if (file) this._processFile(file, section);
        event.target.value = '';
    }

    // ── Drag and drop ─────────────────────────────────────────────────────────

    // Lines drop zone only; the child zones use handleChildDragOver / handleChildDragLeave
    handleDragOver(event) {
        event.preventDefault();
        this.linesDragging = true;
    }

    handleDragLeave() {
        this.linesDragging = false;
    }

    handleLinesFileDrop(event) {
        event.preventDefault();
        if (this._waitForJob()) return;
        this.linesDragging = false;
        const file = event.dataTransfer.files[0];
        if (file) this._processFile(file, 'lines');
    }

    // the retry zone sits inside the Lines section, which takes drops too: the event stops here
    handleRetryDragOver(event) {
        event.preventDefault();
        event.stopPropagation();
        this.linesRetryDragging = true;
    }

    handleRetryDragLeave(event) {
        event.stopPropagation();
        this.linesRetryDragging = false;
    }

    handleRetryFileDrop(event) {
        event.preventDefault();
        event.stopPropagation();
        if (this._waitForJob()) return;
        this.linesRetryDragging = false;
        const file = event.dataTransfer.files[0];
        if (file) this._processRetryFile(file);
    }

    openRetryFilePicker() {
        if (this._waitForJob()) return;
        this.template.querySelector('input[data-section="lines-retry"]').click();
    }

    handleRetryFileInputChange(event) {
        const file = event.target.files[0];
        if (file) this._processRetryFile(file);
        event.target.value = '';
    }

    _processRetryFile(file) {
        const failedIds = this.linesFailedIds;
        const ext = file.name.split('.').pop().toLowerCase();
        if (!['csv', 'xlsx', 'xls'].includes(ext)) return;
        const reader = new FileReader();
        const onParsed = (rows) => {
            const retryRows = rows.filter(r => failedIds.has(r['Line_Id__c']));
            if (retryRows.length === 0) {
                this._onRowsParsed(rows, file.name, 'lines');
                return;
            }
            this.linesState        = 'idle';
            this.linesResultErrors = [];
            this.linesFailedIds    = new Set();
            this._onRowsParsed(retryRows, `${file.name} (${retryRows.length} failed rows)`, 'lines');
        };
        if (ext === 'csv') {
            reader.onload = e => onParsed(this._parseCSV(e.target.result));
            reader.readAsText(file);
        } else {
            if (!this.sheetJsLoaded) return;
            reader.onload = e => onParsed(this._parseXLSX(e.target.result));
            reader.readAsArrayBuffer(file);
        }
    }

    // ── Start Over ────────────────────────────────────────────────────────────

    get hasAnyData() { return this.linesRows.length > 0; } // child rows exist only with lines

    resetAll() {
        if (this._waitForJob()) return;
        this._resetLoadState();
        this._unsubscribe(this.linesSubscription);
        this.linesSubscription    = null;

        this.linesState            = 'idle';
        this.linesFileName         = '';
        this.linesRowCount         = 0;
        this.linesRows             = [];
        this.linesValidationErrors = [];
        this.linesPreviewColumns   = [];
        this.linesPreviewRows      = [];
        this.linesEnrichedStats    = null;
        this.linesResultErrors     = [];
        this.linesSuccessCount     = 0;
        this.linesErrorCount       = 0;
        this.linesFailedIds        = new Set();
        this.pendingTermsFromLines = [];
        this._resetChildren();
        this.ouCode  = '';
        this.ouOptions = null;
        this.ouOptionsOpen = false;
        this.ouState = 'idle';
        this.lineStatusUpdateState    = 'idle';
    }

    /**
     * Everything a load leaves behind (Start Over and a cleared Lines file): background follow-up
     * (events, polls, results, plans), the Salesforce data of its lines (existing lines, client context, custom association
     * clients), and an open Undo bar, whose Undo would otherwise put a row of the old load back.
     */
    _resetLoadState() {
        this._endAllWatches();
        this.ouResultText = '';
        this.ouResultIsError = false;
        this._ouLineIds = null;
        this._loggedReasons = null;
        this._processedChildren = null;
        this._processedPlans = null;
        this._statusResults = new Map();
        this._statusMoves = [];
        this._statusDone = false;
        this._pendingMoves = [];
        this._loadAsyncJobId = null;
        this._loadJobCompleted = false;
        this._sfLinesById = null;
        this._statusContext = null;
        this._associationClientsByLine = null;
        this.statusProgressText = '';
        clearTimeout(this._undoTimer);
        this.undoNotice = null;
        this._undoAction = null;
    }

    // ── Clear file ────────────────────────────────────────────────────────────

    clearLinesFile() {
        this._resetLoadState();
        this.linesState            = 'idle';
        this.linesFileName         = '';
        this.linesRowCount         = 0;
        this.linesRows             = [];
        this.linesValidationErrors = [];
        this.linesPreviewColumns   = [];
        this.linesPreviewRows      = [];
        this.linesEnrichedStats    = null;
        this.pendingTermsFromLines = [];
        this._resetChildren(); // child rows belong to the lines
    }

    // ── Clipboard paste (Ctrl+V) ──────────────────────────────────────────────

    _processPastedText(text) {
        const rows = this._parseCSV(text); // same quote-aware parser as a dropped CSV
        if (rows.length === 0) return;
        const headers = Object.keys(rows[0]).filter(k => k !== '__rowIndex');

        // Bail silently if content doesn't look like a Salesforce data file at all
        if (!headers.some(h => h.includes('__c') || h === 'gf_cutoff_date')) return;

        // route by the columns (Lines, Risk Line Terms, Line Product Items)
        const section = this._detectFileType(headers);
        if (!section) return;
        if (section === 'lines') this._onRowsParsed(rows, 'Clipboard', section);
        else this._loadChildFile(section, rows, 'Clipboard');
    }

    // ── File parsing ──────────────────────────────────────────────────────────

    _processFile(file, section) {
        const ext = file.name.split('.').pop().toLowerCase();
        if (!['csv', 'xlsx', 'xls'].includes(ext)) {
            this._zoneErrors(section, [{ key: 'ext', message: `File type .${ext} is not supported. Use CSV, XLSX or XLS.` }]);
            return;
        }

        const reader = new FileReader();

        if (ext === 'csv') {
            reader.onload = e => {
                const rows = this._parseCSV(e.target.result);
                this._routeParsedRows(rows, file.name, section);
            };
            reader.readAsText(file);
        } else {
            if (!this.sheetJsLoaded) {
                this._zoneErrors(section, [{ key: 'sheetjs', message: 'SheetJS library is still loading. Try again in a moment.' }]);
                return;
            }
            reader.onload = e => {
                const rows = this._parseXLSX(e.target.result);
                this._routeParsedRows(rows, file.name, section);
            };
            reader.readAsArrayBuffer(file);
        }
    }

    /**
     * Delimited text (CSV file or pasted table) to row objects keyed by header. Values in double
     * quotes may contain the delimiter, line breaks and doubled quotes (""), as Excel exports them. Delimiter from the
     * header line: tab, pipe, semicolon (when there is no comma) or comma. Blank lines are skipped.
     */
    _parseCSV(text) {
        const source    = String(text || '').replace(/^﻿/, '');
        const firstLine = source.split(/\r?\n/, 1)[0] || '';
        const delimiter = firstLine.includes('\t') ? '\t'
            : firstLine.includes('|') ? '|'
            : (firstLine.includes(';') && !firstLine.includes(',')) ? ';'
            : ',';

        const records = [];
        let record = [];
        let value = '';
        let inQuotes = false;
        for (let i = 0; i < source.length; i++) {
            const ch = source[i];
            if (inQuotes) {
                if (ch === '"' && source[i + 1] === '"') { value += '"'; i++; }
                else if (ch === '"') { inQuotes = false; }
                else { value += ch; }
            } else if (ch === '"') {
                inQuotes = true;
            } else if (ch === delimiter) {
                record.push(value); value = '';
            } else if (ch === '\n' || ch === '\r') {
                if (ch === '\r' && source[i + 1] === '\n') i++;
                record.push(value); value = '';
                records.push(record); record = [];
            } else {
                value += ch;
            }
        }
        record.push(value);
        records.push(record);

        // Enhancement fix to existing process: __rowIndex is the row in Excel (blank rows count, a quoted
        // line break stays in its row); it used to count only the non-blank rows, so messages after a blank row were off
        const nonBlank = records.map((values, idx) => ({ values, rowNumber: idx + 1 }))
            .filter(r => r.values.some(v => v.trim() !== ''));
        if (nonBlank.length < 2) return [];
        const headers = nonBlank[0].values.map(h => h.trim());
        return nonBlank.slice(1).map(({ values, rowNumber }) => {
            const row = { __rowIndex: rowNumber };
            headers.forEach((h, i) => { if (h) row[h] = (values[i] || '').trim(); });
            return row;
        });
    }

    _parseXLSX(arrayBuffer) {
        // eslint-disable-next-line no-undef
        const workbook = XLSX.read(new Uint8Array(arrayBuffer), { type: 'array', cellDates: true });
        const sheet    = workbook.Sheets[workbook.SheetNames[0]];
        // eslint-disable-next-line no-undef
        // Enhancement fix to existing process: blank rows are kept so __rowIndex is the Excel row (the
        // used range may start below row 1), then skipped like in a CSV file
        const rawRows  = XLSX.utils.sheet_to_json(sheet, { header: 1, defval: '', blankrows: true });
        // eslint-disable-next-line no-undef
        const firstRow = sheet['!ref'] ? XLSX.utils.decode_range(sheet['!ref']).s.r + 1 : 1;
        const nonBlank = rawRows.map((values, idx) => ({ values, rowNumber: firstRow + idx }))
            .filter(r => r.values.some(v => v !== undefined && v !== null && String(v).trim() !== ''));
        if (nonBlank.length < 2) return [];
        const headers = nonBlank[0].values.map(h => String(h).trim());
        return nonBlank.slice(1).map(({ values, rowNumber }) => {
            const row = { __rowIndex: rowNumber };
            headers.forEach((h, i) => {
                const v = values[i];
                // Enhancement fix to existing process: a date cell is the local midnight of that day;
                // toISOString() turned it into UTC and saved the previous day (UTC+1 / UTC+2), so the local date is used.
                row[h] = v instanceof Date
                    ? `${v.getFullYear()}-${String(v.getMonth() + 1).padStart(2, '0')}-${String(v.getDate()).padStart(2, '0')}`
                    : (v !== undefined && v !== null ? String(v).trim() : '');
            });
            return row;
        });
    }

    // Lines rows only: child files load through _loadChildFile (section kept for the callers)
    _onRowsParsed(rows, fileName, section) {
        if (section !== 'lines') return;
        this._processedChildren = null; // a new load: no Created / Deleted result
        this._processedPlans = null;

        // Reject any rows missing Line_Id__c — it is the external key from the source system
        const missingIdRows = rows.filter(r => !r['Line_Id__c'] || !String(r['Line_Id__c']).trim());
        if (missingIdRows.length > 0) {
            const rowNums = missingIdRows.map(r => `Row ${r.__rowIndex}`).join(', ');
            this._setValidationErrors('lines', [{
                key: 'missing-line-id',
                message: `Line_Id__c is required for all rows but was blank in: ${rowNums}`
            }]);
            this.linesState = 'error';
            return;
        }

        // Duplicate Line_Id__c detection — remove ALL occurrences and toast
        const lineIdRows = {};
        rows.forEach(r => {
            const id = r['Line_Id__c'];
            if (id) (lineIdRows[id] = lineIdRows[id] || []).push(r.__rowIndex);
        });
        const dupes = Object.entries(lineIdRows).filter(([, rns]) => rns.length > 1);
        if (dupes.length > 0) {
            const msg = dupes.map(([id, rns]) => `${id} (rows ${rns.join(', ')})`).join(' | ');
            this._toast('Duplicate Line IDs detected', `Each Line ID must appear only once. Removed: ${msg}`, 'error');
            const dupeSet = new Set(dupes.map(([id]) => id));
            rows = rows.filter(r => !dupeSet.has(r['Line_Id__c']));
        }
        // Merge with existing rows (incoming overrides existing for same Line_Id__c)
        const merged              = this._mergeLineRows(this.linesRows, rows);
        this.linesFileName        = fileName;
        this.linesRowCount        = merged.length;
        this.linesRows            = merged;
        this.pendingTermsFromLines = this._extractTermRows(merged);

        const errors = this._validate(this.linesRows, null, LINES_REQUIRED);
        if (errors.length > 0) {
            this._setValidationErrors('lines', errors);
            return;
        }
        this._setValidationErrors('lines', []);
        this._buildPreview(this.linesRows, this._linePreviewHeaders(this._linesFileHeaders()), 'lines');
        this.linesState = 'ready';
        this._enrichLinesPreview(this.linesRows);
    }

    // ── Validation ────────────────────────────────────────────────────────────

    _validate(rows, expectedHeaders, requiredFields) {
        const errors = [];

        if (!rows || rows.length === 0) {
            errors.push({ key: 'empty', message: 'The file contains no data rows.' });
            return errors;
        }

        const actualHeaders = Object.keys(rows[0]).filter(k => k !== '__rowIndex');
        // null = header-driven file (Lines): only the required columns must be there
        const missing = (expectedHeaders || requiredFields).filter(h => !actualHeaders.includes(h));
        if (missing.length > 0) {
            errors.push({ key: 'headers', message: `Missing columns: ${missing.join(', ')}` });
            return errors;
        }

        rows.forEach(row => {
            if (errors.length >= 20) return;
            requiredFields.forEach(field => {
                if (!row[field] || !String(row[field]).trim()) {
                    errors.push({
                        key: `${row.__rowIndex}-${field}`,
                        message: `Row ${row.__rowIndex}: "${field}" is required.`
                    });
                }
            });
        });

        return errors;
    }

    // Lines only: child tables keep their own errors (_zoneErrors)
    _setValidationErrors(section, errors) {
        if (section !== 'lines') return;
        this.linesValidationErrors = errors;
        this.linesState = errors.length > 0 ? 'error' : this.linesState;
    }

    // ── Preview table builder ────────────────────────────────────────────────

    _buildPreview(rows, headers, section) {
        const hasStatus  = rows.some(r => r.__status);
        const statusCol  = hasStatus
            ? [{ label: 'Status', fieldName: '__status', type: 'text', initialWidth: 120, wrapText: false }]
            : [];
        const dataCols   = headers.map(h => ({
            label: h, fieldName: this._safeKey(h), type: 'text', initialWidth: 160, wrapText: false
        }));
        const columns    = [...statusCol, ...dataCols];

        const tableRows = rows.slice(0, PREVIEW_ROW_LIMIT).map((row, idx) => {
            const flat = { __previewKey: String(idx) };
            if (hasStatus) flat.__status = row.__status || '';
            headers.forEach(h => { flat[this._safeKey(h)] = row[h] || ''; });
            return flat;
        });

        if (section === 'lines') { // the child tables build their rows in childSections
            this.linesPreviewColumns = columns;
            this.linesPreviewRows    = tableRows;
        }
    }

    _safeKey(str) {
        return str.replace(/\s+/g, '_');
    }

    _isTermCol(col) {
        return TERM_COLS.has(col) || col.startsWith('DMT_Risk_Line_Term__c ');
    }

    // the columns of the loaded Lines rows (header-driven), in file order
    _linesFileHeaders() {
        const headers = [];
        this.linesRows.forEach(row => Object.keys(row).forEach(k => {
            if (!k.startsWith('__') && !headers.includes(k)) headers.push(k);
        }));
        return headers;
    }

    _linePreviewHeaders(headers) {
        const cols = headers.filter(h => !this._isTermCol(h));
        return ['Line_Id__c', ...cols.filter(h => h !== 'Line_Id__c')];
    }

    _extractTermRows(rows) {
        const termHeaders = LINES_HEADERS.filter(h => this._isTermCol(h));
        const seen = new Set();
        const dupeIds = [];
        const extracted = [];
        rows.forEach(row => {
            const term = { 'Line_Id__c': row['Line_Id__c'] || '', __rowIndex: row.__rowIndex };
            termHeaders.forEach(h => { term[h] = row[h] || ''; });
            const id = term['DMT_RiskLineTermId__c'];
            if (!id) return;
            if (seen.has(id)) { dupeIds.push(id); return; }
            seen.add(id);
            extracted.push(term);
        });
        if (dupeIds.length > 0) {
            this._toast(
                'Duplicate Term IDs in lines file',
                `Term ID must be unique. Duplicates ignored: ${[...new Set(dupeIds)].join(', ')}`,
                'warning'
            );
        }
        return extracted;
    }

    _mergeLineRows(existing, incoming) {
        // Incoming overrides existing rows with same Line_Id__c; new IDs are appended
        const incomingMap  = new Map(incoming.map(r => [r['Line_Id__c'], r]));
        const existingIds  = new Set(existing.map(r => r['Line_Id__c']).filter(Boolean));
        const updated      = existing.map(r => incomingMap.has(r['Line_Id__c']) ? incomingMap.get(r['Line_Id__c']) : r);
        const added        = incoming.filter(r => r['Line_Id__c'] && !existingIds.has(r['Line_Id__c']));
        return [...updated, ...added];
    }

    // ── Post-batch: update status column in-place, table stays unchanged ─────

    // Lines count bar after Process: what the load did (Status column), like the child tables
    get linesResultStats() {
        const count = status => this.linesRows.filter(r => r.__status === status).length;
        return { createdCount: count('Created'), updatedCount: count('Updated'),
                 noChangeCount: count('No Changes'), failedCount: count('Failed') };
    }

    _updateSubmissionStatuses(section, failedIds) {
        if (section === 'lines') {
            this.linesRows = this.linesRows.map(r => {
                if (failedIds.has(r['Line_Id__c'])) return { ...r, __status: 'Failed' }; // products-only lines can fail too
                if (r.__status === 'No Changes') return r;
                return { ...r, __status: r.__status === 'New' ? 'Created' : 'Updated' };
            });
            // Ensure status column is present in preview columns
            if (!this.linesPreviewColumns.some(c => c.fieldName === '__status')) {
                this.linesPreviewColumns = [
                    { label: 'Status', fieldName: '__status', type: 'text', initialWidth: 100, wrapText: false },
                    ...this.linesPreviewColumns
                ];
            }
            const statusMap = new Map(this.linesRows.map(r => [r['Line_Id__c'], r.__status]));
            this.linesPreviewRows = this.linesPreviewRows.map(row => ({
                ...row, __status: statusMap.get(row['Line_Id__c']) || row.__status || ''
            }));
        }
    }

    // ── Post-batch: backfill SF record IDs for newly created lines ────────────

    async _backfillCreatedLineUrls(lineIds) {
        try {
            const records = await queryCreatedLinesApex({ lineIds });
            const idMap = new Map(records.map(r => [r.Line_Id__c, r.Id]));
            this.linesPreviewRows = this.linesPreviewRows.map(row => {
                const sfId = idMap.get(row['Line_Id__c']);
                if (!sfId) return row;
                return { ...row, __lineUrl: window.location.origin + '/' + sfId };
            });
            // If all preview rows now have a URL, switch Line_Id__c column to url type
            if (this.linesPreviewRows.every(r => r.__lineUrl)) {
                this.linesPreviewColumns = this.linesPreviewColumns.map(col => {
                    if (col.fieldName !== 'Line_Id__c') return col;
                    return { ...col, fieldName: '__lineUrl', type: 'url',
                             typeAttributes: { label: { fieldName: 'Line_Id__c' }, target: '_blank' } };
                });
            }
        } catch (e) {
            console.error('backfill created line URLs failed', e);
        }
    }

    // ── Enrichment: query SF for existing lines + terms after CSV parse ────────

    async _enrichLinesPreview(rows) {
        const lineIds = [...new Set(rows.map(r => r['Line_Id__c']).filter(Boolean))];
        if (lineIds.length === 0) return;
        try {
            const clientCodes = [...new Set(rows.map(r => valueText(r['Client_Code__c']).toUpperCase()).filter(Boolean))];
            const [existingLines, existingTerms, existingItems, statusContext, associationClients] = await Promise.all([
                getExistingLinesApex({ lineIds }),
                getExistingTermsForLinesApex({ lineIds }),
                getExistingProductItemsForLinesApex({ lineIds }),
                getStatusContextApex({ clientCodes }),
                getCustomAssociationClientsApex({ lineIds }) // Custom lines (bulkImportRules.treasuryFlowReasons)
            ]);
            // Guard: user may have cleared or resubmitted the file while we were loading
            if (this.linesState !== 'ready') return;
            this._statusContext = statusContext; // _stayDraftReasons
            this._associationClientsByLine = new Map(); // bulkImportRules.treasuryFlowReasons
            (associationClients || []).forEach(client => {
                const lineId = client.Custom_Association__r && client.Custom_Association__r.DMT_Line__r
                    ? client.Custom_Association__r.DMT_Line__r.Line_Id__c : '';
                if (!this._associationClientsByLine.has(lineId)) this._associationClientsByLine.set(lineId, []);
                this._associationClientsByLine.get(lineId).push(client);
            });
            this._applyLineEnrichment(rows, existingLines);
            // Salesforce records of the loaded lines in the child tables; term columns of an old
            // Other Products Lines file become the Risk Line Terms file rows
            this._setSfChildren('rlt', existingTerms);
            this._setSfChildren('lpi', existingItems);
            this._loadTermsFromLinesFile();
        } catch (e) {
            // CIBGLOBALD-4157 - a failed enrichment call used to leave every row's __status
            // unset, which made _buildPreview's `rows.some(r => r.__status)` gate drop the
            // whole Status column rather than just the values in it. Falling back to 'Unknown'
            // keeps the column (and the rest of the table) visible and tells the user plainly
            // that the New/Update/No Changes comparison against Salesforce could not be made.
            console.error('enrichment query failed', e);
            this.linesRows = this.linesRows.map(r => ({ ...r, __status: r.__status || 'Unknown' }));
            this._buildPreview(this.linesRows, this._linePreviewHeaders(this._linesFileHeaders()), 'lines');
            this._toast(
                'Could not check existing Salesforce data',
                'The New / Will Update / No Changes status could not be determined for these lines. You can still proceed, but double-check for duplicates yourself.',
                'warning'
            );
        }
    }

    _applyLineEnrichment(csvRows, existingLines) {
        const sfMap = new Map();
        existingLines.forEach(rec => sfMap.set(rec.Line_Id__c, rec));
        this._sfLinesById = sfMap; // status plan (_statusPlan) and reopen check

        let newCount = 0, updateCount = 0, noChangeCount = 0;

        const enrichedRows = csvRows.map(row => {
            const sf      = sfMap.get(row['Line_Id__c']);
            const enriched = { ...row };

            if (!sf) {
                enriched.__status      = 'New';
                enriched.__statusClass = 'status-new';
                newCount++;
            } else {
                // no backfill of blank cells with the Salesforce values: a column in the file is
                // saved as it is (a blank cell clears the field), a column not in the file is not touched.
                enriched.__sfId = sf.Id;

                if (this._hasLineChanges(enriched, sf)) {
                    enriched.__status      = 'Will Update';
                    enriched.__statusClass = 'status-update';
                    updateCount++;
                } else {
                    enriched.__status      = 'No Changes';
                    enriched.__statusClass = 'status-no-change';
                    noChangeCount++;
                }
            }
            return enriched;
        });

        // Update linesRows with the status tags so submission uses them
        this.linesRows = enrichedRows;

        // Rebuild preview: Line_Id__c is a URL column (clickable) when SF records exist, plain text otherwise.
        // lightning-datatable URL type renders nothing when the URL field is null, so we only use it
        // when at least one row already exists in SF (ensuring the label is always visible).
        const previewHeaders  = this._linePreviewHeaders(this._linesFileHeaders());
        // the line columns in one order (LINE_COLUMN_ORDER): a file column shows the file value, the others
        // the Salesforce value of existing lines (shown only, never saved); file columns this screen does not use, at the end
        const standardHeaders = LINE_COLUMN_ORDER.filter(h => previewHeaders.includes(h) || sfMap.size > 0);
        const nonIdHeaders    = [...standardHeaders, ...previewHeaders.filter(h => h !== 'Line_Id__c' && !LINE_COLUMN_ORDER.includes(h))];
        const hasAnyExisting  = enrichedRows.every(r => r.__sfId);
        const lineIdCol       = hasAnyExisting
            ? { label: 'Line_Id__c', fieldName: '__lineUrl', type: 'url',
                typeAttributes: { label: { fieldName: 'Line_Id__c' }, target: '_blank' }, initialWidth: 200, wrapText: false }
            : { label: 'Line_Id__c', fieldName: 'Line_Id__c', type: 'text', initialWidth: 180, wrapText: false };
        this.linesPreviewColumns = [
            { type: 'action', typeAttributes: { rowActions: this._lineRowActions } }, // Remove row
            { label: 'Status', fieldName: '__status', type: 'text', initialWidth: 100, wrapText: false },
            // what the load does to the line's status (_statusPlan)
            { label: 'Validation / Status Change', fieldName: '__statusPlan', type: 'text', initialWidth: 320, wrapText: true,
              cellAttributes: { iconName: { fieldName: '__statusPlanIcon' }, iconPosition: 'left',
                                class: { fieldName: '__statusPlanClass' } } },
            lineIdCol,
            ...nonIdHeaders.map(h => ({ label: h, fieldName: this._safeKey(h), type: 'text', initialWidth: 160, wrapText: false }))
        ];
        this.linesPreviewRows = enrichedRows.slice(0, PREVIEW_ROW_LIMIT).map((row, idx) => {
            const flat = { __previewKey: String(idx), __status: row.__status, 'Line_Id__c': row['Line_Id__c'] || '',
                           ...this._statusCellFields(row) };
            flat.__lineUrl = row.__sfId ? (window.location.origin + '/' + row.__sfId) : null;
            const sf = sfMap.get(row['Line_Id__c']);
            nonIdHeaders.forEach(h => { flat[this._safeKey(h)] = h in row ? (row[h] || '') : (sf ? valueText(sf[h]) : ''); });
            return flat;
        });

        this.linesEnrichedStats = { newCount, updateCount, noChangeCount };
    }

    /**
     * True when a column of the file differs from the line in Salesforce. Only the columns present
     * in the file are compared (LINE_COMPARE_FIELDS); a blank cell differs from a filled field because saving clears it.
     * Status__c is never compared: DMT_BulkImportBatch ignores it (new lines start in Draft, existing ones keep theirs).
     */
    _hasLineChanges(csvRow, sf) {
        return this._changedLineFields(csvRow, sf).length > 0;
    }

    // the file columns (LINE_COMPARE_FIELDS) whose value differs from the line in Salesforce; the
    // old amount column of the Other Products files (saved to Amount__c by DMT_BulkImportBatch.buildLine) counts as Amount__c
    _changedLineFields(csvRow, sf) {
        const changed = Object.keys(LINE_COMPARE_FIELDS)
            .filter(field => field in csvRow)
            .filter(field => !(KEEP_WHEN_BLANK_FIELDS.includes(field) && valueText(csvRow[field]) === ''))
            .filter(field => {
                const type = LINE_COMPARE_FIELDS[field];
                return normaliseValue(type, csvRow[field]) !== normaliseValue(type, sf[field]);
            });
        if (LEGACY_AMOUNT_COLUMN in csvRow && valueText(csvRow[LEGACY_AMOUNT_COLUMN]) !== ''
            && normaliseValue('number', csvRow[LEGACY_AMOUNT_COLUMN]) !== normaliseValue('number', sf.Amount__c)) {
            changed.push('Amount__c');
        }
        return changed;
    }

    /**
     * What the load does to the line's status (same rules as DMT_BulkImportBatch.planStatus):
     * { toDraft, from, target, checks } or null when the status is not touched. New line with a code other than DR:
     * created in Draft, then moved to that status. Existing line not in Draft whose file changes a blocked field, or whose
     * code points to another status: saved in Draft, then moved to the code's status (file value, else the stored one),
     * or back to its previous status; a Closed line without a code stays in Draft. Existing Draft lines keep the Update
     * Line Status button. The move is one update straight to the target (DMT_BatchSanctionAMIWEB), so the only checkpoint
     * it passes is Draft to Proposal: checks = ['passport'] when the target is Proposal. Line staying in Ready to close
     * with a change (line or products): ['readytoclose']. stayDraft = the reasons the move would be rejected
     * (_stayDraftReasons): the line is saved but not moved (DMT_BulkImportBatch.UNIT_STAY_DRAFT) and nothing reopens.
     */
    _statusPlan(row) {
        const plan = this._statusMove(row);
        if (!plan || !plan.target) return plan;
        const reasons = this._stayDraftReasons(row, plan.target);
        return reasons.length > 0 ? { ...plan, stayDraft: reasons, checks: [] } : plan;
    }

    // the status move of the load before the org rules check (see _statusPlan)
    _statusMove(row) {
        const sf       = this._sfLinesById ? this._sfLinesById.get(row['Line_Id__c']) : null;
        const codeText = ('g_line_status_type__c' in row ? row['g_line_status_type__c'] : (sf ? sf.g_line_status_type__c : '')) || '';
        const code       = String(codeText).trim().toUpperCase();
        const codeStatus = STATUS_BY_CODE[code] || null;
        if (!sf) {
            return codeStatus && codeStatus !== 'Draft'
                ? { toDraft: false, from: 'Draft', target: codeStatus, checks: codeStatus === 'Proposal' ? ['passport'] : [] } : null;
        }
        const current = sf.Status__c;
        // an existing Draft line with a code is moved by the Update Line Status button, not by Process
        if (current === 'Draft') {
            return codeStatus && codeStatus !== 'Draft'
                ? { toDraft: false, from: 'Draft', target: codeStatus, byButton: true, checks: [] } : null;
        }
        const changed  = this._changedLineFields(row, sf);
        // a field blocked outside Draft (AvoidEditNotDraft), or a field the rule ApprovalProcessDataEdit
        // rejects in the current status (it reads the new status): both are saved through Draft
        const blocked  = BLOCKED_FILE_COLUMNS.some(column => changed.includes(column))
                         || approvalDataEditReasons({ status: current, closed: sf.Closed__c, allowApprovalEdit: sf.DMT_Allow_Approval_Edit__c },
                                                    changed, this.isTreasury).length > 0;
        const codeMoves = codeStatus !== null && codeStatus !== current;
        if (!blocked && !codeMoves) {
            const productsChange = this._zoneCovers('rlt', row['Line_Id__c']) || this._zoneCovers('lpi', row['Line_Id__c'])
                                   || this._markedByLine('rlt').has(row['Line_Id__c']) || this._markedByLine('lpi').has(row['Line_Id__c']);
            return current === 'Ready to close' && (changed.length > 0 || productsChange)
                ? { toDraft: false, from: current, target: null, checks: ['readytoclose'] } : null;
        }
        let target = codeStatus || current;
        if (!codeStatus && current === 'Closed') target = null;
        return { toDraft: true, from: current, target, checks: target === 'Proposal' ? ['passport'] : [] };
    }

    _statusPlanLabel(plan) {
        if (!plan) return '';
        if (plan.toDraft) return `${plan.from} → Draft${plan.target ? ' → ' + plan.target : ''}`;
        if (plan.target)  return `Draft → ${plan.target}`;
        return '';
    }

    /**
     * The Status Change cell (text, icon, SLDS text colour) of a row: the result of the background
     * status move when there is one (_statusResults: moving / moved / not moved), else the plan of the load. A line the
     * org rules would not let move (plan.stayDraft) shows a warning icon in red.
     */
    _statusCellFields(row) {
        const result = this._statusResults ? this._statusResults.get(row['Line_Id__c']) : null;
        let cell;
        if (row.__status === 'Failed') {
            cell = { text: 'Not saved, no status change', icon: 'utility:ban', cls: 'slds-text-color_weak' };
        } else if (result && result.state === 'moving') {
            cell = { text: `Moving to ${result.target}…`, icon: 'utility:clock', cls: 'slds-text-color_weak' };
        } else if (result && result.state === 'moved') {
            cell = { text: `Moved to ${result.target}`, icon: 'utility:success', cls: 'slds-text-color_success' };
        } else if (result) {
            cell = { text: `Not moved to ${result.target}: ${result.message}`, icon: 'utility:error', cls: 'slds-text-color_error' };
        } else {
            // from Process on, the plan of that moment (_processedPlans): the file rows become Salesforce
            // records, and a plan computed again would describe a move that is not going to happen
            const frozen = this._processedPlans && this.linesState !== 'ready';
            const plan = frozen ? (this._processedPlans.get(row['Line_Id__c']) || null) : this._statusPlan(row);
            // a row Process will reject (DMT_BulkImportBatch.buildUnit), shown before Process
            const saveError = frozen ? null : this._saveError(row);
            // the reason in a short sentence; the org message and its source go to the console once
            if (saveError) {
                this._logReasonsOnce(row['Line_Id__c'], 'will not be saved', [saveError]);
                cell = { text: `Will not be saved: ${saveError.short}`, icon: 'utility:error', cls: 'slds-text-color_error' };
            } else if (plan && plan.byButton && plan.stayDraft) {
                // the button will not send it: the org rules would reject the move
                this._logReasonsOnce(row['Line_Id__c'], `stays in Draft, Update Line Status will not move it to ${plan.target}`, plan.stayDraft);
                cell = { text: `Stays in Draft, the button will not move it to ${plan.target}: ${reasonShortText(plan.stayDraft)}`,
                         icon: 'utility:warning', cls: 'slds-text-color_error' };
            } else if (plan && plan.byButton) {
                cell = { text: `Draft → ${plan.target} when you click Update Line Status`, icon: 'utility:refresh', cls: 'slds-text-color_weak' };
            } else if (plan && plan.stayDraft) {
                const verb = this.linesIsDone ? 'Stayed' : 'Stays';
                this._logReasonsOnce(row['Line_Id__c'], `stays in Draft, not moved to ${plan.target}`, plan.stayDraft);
                cell = { text: `${plan.toDraft ? plan.from + ' → ' : ''}${verb} in Draft, not moved to ${plan.target}: ${reasonShortText(plan.stayDraft)}`,
                         icon: 'utility:warning', cls: 'slds-text-color_error' };
            } else {
                const text = this._statusPlanLabel(plan);
                cell = { text, icon: text ? 'utility:forward' : '', cls: '' };
            }
        }
        return { __statusPlan: cell.text, __statusPlanIcon: cell.icon, __statusPlanClass: cell.cls };
    }

    /**
     * The error Process would reject the row with (bulkImportRules.rowSaveError, a copy of
     * DMT_BulkImportBatch.buildUnit), or null: the line columns when the line is saved (not No Changes, same as
     * _buildUnits), its client (found by getStatusContext, the same query as the batch) and the product rows the load
     * sends for it. Unknown context (getStatusContext failed): null, the batch still checks.
     */
    _saveError(row) {
        const context = this._statusContext;
        if (!context || !context.fileValueRules) return null;
        const lineId = row['Line_Id__c'];
        const sf = this._sfLinesById ? this._sfLinesById.get(lineId) : null;
        const clientTypeByCode = context.clientTypeByCode || {};
        const line = row.__status === 'No Changes' ? null
            : { row, isNewLine: !sf, clientFound: code => code.toUpperCase() in clientTypeByCode };
        const productRows = zone => (this._zoneCovers(zone, lineId) ? this._replacementRows(zone, lineId) : null);
        return rowSaveError(line, productRows('rlt'), productRows('lpi'), context.fileValueRules);
    }

    // console.info of the reasons a cell shows (bulkImportRules.logRuleReasons), each reason once per line
    // in a load, so the console has the org message and its source without repeating at every redraw
    _logReasonsOnce(lineId, what, reasons) {
        this._loggedReasons = this._loggedReasons || new Set();
        const fresh = reasons.filter(r => !this._loggedReasons.has(`${lineId}|${what}|${r.message}`));
        fresh.forEach(r => this._loggedReasons.add(`${lineId}|${what}|${r.message}`));
        if (fresh.length > 0) logRuleReasons(lineId, what, fresh);
    }

    // redraws the Status Change cells of the preview rows (after a background result)
    _refreshStatusCells() {
        const rowsById = new Map(this.linesRows.map(r => [r['Line_Id__c'], r]));
        this.linesPreviewRows = this.linesPreviewRows.map(flat => {
            const row = rowsById.get(flat['Line_Id__c']);
            return row ? { ...flat, ...this._statusCellFields(row) } : flat;
        });
    }

    /**
     * Why the org would reject moving the line from Draft to target after the load: the values the line
     * has once saved (file column if present, else Salesforce), its products once saved, and the copies of the org rules
     * in bulkImportRules.js (each names its exact source). Empty = the move is tried. Unknown context (getStatusContext
     * failed): no reason, the move is tried.
     */
    _stayDraftReasons(row, target) {
        const context = this._statusContext;
        if (!context || !target || target === 'Draft') return [];
        const lineId = row['Line_Id__c'];
        const sf     = this._sfLinesById ? this._sfLinesById.get(lineId) : null;
        const saved  = field => (field in row ? valueText(row[field]) : valueText(sf ? sf[field] : ''));
        const code   = valueText('g_line_status_type__c' in row ? row['g_line_status_type__c'] : (sf ? sf.g_line_status_type__c : '')).toUpperCase();
        const terms  = this._savedChildRows('rlt', lineId);
        const reasons = [
            ...stepRuleReasons(target, context.profileName),
            ...termContinuityReasons(terms),
            ...prospectReasons(target, code, this._savedClientRecordType(row, sf))
        ];
        const clientType = this._savedClientType(row, sf, saved);
        if (this.isTreasury) {
            const clients = (this._associationClientsByLine && this._associationClientsByLine.get(lineId)) || [];
            return [...reasons, ...treasuryFlowReasons({
                bookingGeography: saved('Booking_Geography__c'), endDate: saved('End_Date__c'), clientType,
                fdAmount: saved('FD_Amount__c'), dvpAmount: saved('DvP_Amount__c'), waiver: saved('Waiver__c')
            }, this._savedChildRows('lpi', lineId), terms, clients)];
        }
        // Other Products: the line amount comes from the old amount column of the file, else Salesforce
        const amount = LEGACY_AMOUNT_COLUMN in row && valueText(row[LEGACY_AMOUNT_COLUMN]) !== ''
            ? row[LEGACY_AMOUNT_COLUMN] : (sf ? sf.Amount__c : null);
        const line = { clientType, typeOfRisk: saved('DMT_LastLevelId__c'), amount };
        return [...reasons, ...otherProductsFlowReasons(line), ...productsTotalReasons(line, terms, target, code)];
    }

    // the products of the line once saved: the replacement rows when the load replaces them, else the
    // Salesforce records
    _savedChildRows(zone, lineId) {
        return this._replacementRows(zone, lineId) || this.childState[zone].sfRows.filter(r => r.__lineId === lineId);
    }

    // DMT_Line__c.Client_Type__c once saved (formula order: Golden_Code__c, Custom_Association__c, client)
    _savedClientType(row, sf, saved) {
        if (saved('Golden_Code__c') !== '') return 'Golden';
        if (sf && sf.Custom_Association__c) return 'Custom';
        const code = valueText(row['Client_Code__c']).toUpperCase();
        if (code) return this._statusContext.clientTypeByCode[code] || '';
        return sf ? (sf.Client_Type__c || '') : '';
    }

    // record type DeveloperName of the line's client once saved (file Client_Code__c, else Salesforce)
    _savedClientRecordType(row, sf) {
        const code = valueText(row['Client_Code__c']).toUpperCase();
        if (code) return (this._statusContext.clientRecordTypeByCode || {})[code] || '';
        return sf && sf.Client__r && sf.Client__r.RecordType ? sf.Client__r.RecordType.DeveloperName || '' : '';
    }

    // ── Process ───────────────────────────────────────────────────────────────

    /**
     * One unit per line for DMT_BulkImportController.processImport (keys = DMT_BulkImportBatch.UNIT_*):
     * the line row (updated unless No Changes) and, when that table has file rows for the line, its Risk Line Terms /
     * Line Product Items rows (the line's records of that object are replaced). Lines with nothing to save are left out.
     */
    _buildUnits() {
        const rltMarks = this._markedByLine('rlt');
        const lpiMarks = this._markedByLine('lpi');
        const units = [];
        this.linesRows.forEach(row => {
            const lineId     = row['Line_Id__c'];
            const updateLine = row.__status !== 'No Changes';
            const rltDelete = rltMarks.get(lineId); // records removed one by one
            const lpiDelete = lpiMarks.get(lineId);
            const rltLoaded = this._zoneCovers('rlt', lineId);
            const lpiLoaded = this._zoneCovers('lpi', lineId);
            if (!updateLine && !rltLoaded && !lpiLoaded && !rltDelete && !lpiDelete) return;
            const unit = { line: this._cleanRow(row), rowNumber: row.__rowIndex, updateLine };
            const plan = this._statusPlan(row); // a move the org rules would reject is not tried
            if (plan && plan.stayDraft && !plan.byButton) unit.stayDraft = true;
            if (rltLoaded) unit.rlt = this._replacementRows('rlt', lineId); // maybe empty: all deleted
            if (lpiLoaded) unit.lpi = this._replacementRows('lpi', lineId);
            if (rltDelete) unit.rltDelete = rltDelete; // DMT_BulkImportBatch.UNIT_RLT_DELETE
            if (lpiDelete) unit.lpiDelete = lpiDelete; // DMT_BulkImportBatch.UNIT_LPI_DELETE
            units.push(unit);
        });
        return units;
    }

    /**
     * A products table is part of the load when a file or a pasted table was loaded in its zone (Line
     * Product Items only for Treasury lines). Requirement point 2: then it is the complete list for every line of the load;
     * a line without rows in it loses all its records of that object. A table not loaded leaves that object untouched.
     */
    _zoneLoaded(zone) {
        // after Process the file rows are Salesforce records (only failed lines keep theirs for a retry)
        return (zone !== 'lpi' || this.isTreasury) && !!this.childState[zone].fileName && !this.linesIsDone;
    }

    // the loaded table applies to this line (every line of the load, or after Process only the failed ones)
    _zoneCovers(zone, lineId) {
        const lineIds = this.childState[zone].lineIds;
        return this._zoneLoaded(zone) && (!lineIds || lineIds.has(lineId));
    }

    // the rows the line will have of that object after the load: the file rows (maybe none) when the
    // table is loaded, null when the object is not touched
    _replacementRows(zone, lineId) {
        if (this._zoneCovers(zone, lineId)) return this._fileRowsByLine(zone).get(lineId) || [];
        const marked = this._markedByLine(zone).get(lineId);
        if (!marked) return null;
        // records removed one by one: the line keeps its other Salesforce records
        return this.childState[zone].sfRows.filter(r => r.__lineId === lineId && !marked.includes(r.__sfId));
    }

    _fileRowsByLine(zone) {
        const byLine = new Map();
        this.childState[zone].fileRows.forEach(row => {
            if (!byLine.has(row.__lineId)) byLine.set(row.__lineId, []);
            byLine.get(row.__lineId).push(this._cleanRow(row));
        });
        return byLine;
    }

    // one background job at a time on the lines of the load: the load (Process), the status moves
    // (Process or Update Line Status) and Add OU write the same lines, so each button waits for the others to finish
    get _backgroundJobRunning() {
        return this.linesState === 'submitting' || this.linesState === 'processing'
               || this.lineStatusUpdateState !== 'idle' || this.ouState === 'running'
               || (this._statusMoves.length > 0 && !this._statusDone);
    }

    // while a job runs the screen waits: loading controls disabled, drop zones greyed, paste, drop,
    // row actions and Undo ignored; the progress bar and texts stay visible
    get isBusy() { return this._backgroundJobRunning; }

    // true (with a toast) when an action must wait for the running job
    _waitForJob() {
        if (!this.isBusy) return false;
        this._toast('Please wait', this.busyText, 'info');
        return true;
    }

    get busyText() {
        if (this.linesState === 'submitting' || this.linesState === 'processing') return 'Processing the lines. Please wait until it finishes.';
        if (this.ouState === 'running') return 'Adding the OU participants. Please wait until it finishes.';
        return `${this.statusProgressText || 'Moving statuses.'} Please wait until it finishes.`;
    }

    get processDisabled() {
        return this.linesState !== 'ready' || this._buildUnits().length === 0 || this._backgroundJobRunning;
    }

    async processImport() {
        const units = this._buildUnits();
        if (units.length === 0) return;

        this.linesState     = 'submitting';
        this.linesJobId     = this._newJobId();
        this.linesProcessed = 0;
        this.linesTotal     = units.length;
        // New lines submitted → allow launching Update Line Status again for them
        this.lineStatusUpdateState = 'idle';
        // one OU per load: an OU already added to every line of this Process stays (locked, with its
        // result); lines it did not reach (pasted after Add OU) open Add OU again
        const ouCoversLoad = this.ouState === 'done' && !!this._ouLineIds
                             && this.linesRows.every(r => this._ouLineIds.has(r['Line_Id__c']));
        if (!ouCoversLoad) {
            this.ouState = 'idle';
            this.ouResultText = '';
        }

        // features that will reopen (4811 check) and lines whose status continues in the background
        const plans = this.linesRows.map(row => ({ row, plan: this._statusPlan(row) })).filter(p => p.plan);
        this._processedPlans = new Map(plans.map(p => [p.row['Line_Id__c'], p.plan])); // frozen plans
        this._snapshotChildChanges(units); // Created / Deleted badges after Process
        // lines the status move after the load handles (only lines sent in a unit): its result comes with
        // this jobId (Phase STATUS)
        const sentLineIds = new Set(units.map(u => u.line['Line_Id__c']));
        this._statusResults = new Map();
        this._pendingMoves = plans.filter(p => p.plan.target && !p.plan.stayDraft && !p.plan.byButton && sentLineIds.has(p.row['Line_Id__c']))
            .map(p => ({ lineId: p.row['Line_Id__c'], target: p.plan.target }));
        if (this._pendingMoves.length > 0) {
            await this._watchStatusMoves(this.linesJobId, this._pendingMoves);
        }
        const reopens = await this._previewReopens(plans);
        if (reopens.length > 0) {
            this._toast('Features that will reopen', reopens.join(' | '), 'warning');
        }

        this._subscribeProgress(this.linesJobId, 'lines');

        processImportApex({ unitsJson: JSON.stringify(units), jobId: this.linesJobId, recordTypeName: this.selectedRecordType })
            .then(asyncJobId => {
                this.linesState = 'processing';
                this._loadJobCompleted = false;
                // the end of the load is also read from its job (_onLoadJobDone)
                this._loadAsyncJobId = asyncJobId;
                this._pollJob(PHASE_PROCESS, () => Promise.resolve(asyncJobId), state => this._onLoadJobDone(state));
            })
            .catch(e => {
                console.error('processImport error', e);
                this.linesState = 'idle';
                this._unsubscribe(this.linesSubscription);
                this._endWatch(PHASE_STATUS);
                this._toast('Process failed', (e && e.body && e.body.message) || 'Unexpected error');
            });
    }

    /**
     * The 4811 check (DMT_ApprovalChangeStep_Handler.previewCompareUnsavedChanges) for every checkpoint
     * a line passes with this load: the line values the file changes and its product rows (Salesforce records replaced =
     * deleted, file rows = new). One line at a time (9 SOQL per check). Saves nothing; a failed check counts as no reopen.
     * @returns one entry per line with features to reopen: 'Line_Id__c: feature, feature'
     */
    async _previewReopens(plans) {
        const results = [];
        for (const { row, plan } of plans) {
            const sf = this._sfLinesById ? this._sfLinesById.get(row['Line_Id__c']) : null;
            if (!sf || plan.checks.length === 0) continue;
            const unsavedValues = this._unsavedLineValues(row, sf);
            const unsavedRows   = this._unsavedChildRows(row['Line_Id__c']);
            const featureNames  = new Set();
            for (const caseTypeToCheck of plan.checks) {
                try {
                    // eslint-disable-next-line no-await-in-loop
                    const features = await previewCompareUnsavedChangesApex({ recordId: sf.Id, caseTypeToCheck, unsavedValues, unsavedRows });
                    (features || []).forEach(f => featureNames.add(f.featureName));
                } catch (e) {
                    console.error('reopen check failed', row['Line_Id__c'], caseTypeToCheck, e);
                }
            }
            if (featureNames.size > 0) results.push(`${row['Line_Id__c']}: ${[...featureNames].join(', ')}`);
        }
        return results;
    }

    // field API name -> value of the line fields the file changes, typed as the check expects
    _unsavedLineValues(row, sf) {
        const values = {};
        this._changedLineFields(row, sf).filter(field => field !== 'Amount__c').forEach(field => {
            const v = normaliseValue(LINE_COMPARE_FIELDS[field], row[field]);
            values[field] = LINE_COMPARE_FIELDS[field] === 'boolean' ? v === 'true' : (v === '' ? null : v);
        });
        if (LEGACY_AMOUNT_COLUMN in row && valueText(row[LEGACY_AMOUNT_COLUMN]) !== '') {
            values.Amount__c = normaliseValue('number', row[LEGACY_AMOUNT_COLUMN]);
        }
        return values;
    }

    // product rows of the line as the check expects ({objectApiName, rowId, values, deleted})
    _unsavedChildRows(lineId) {
        const rows = [];
        Object.keys(CHILD_ZONES).forEach(zone => {
            if (zone === 'lpi' && !this.isTreasury) return;
            const objectApiName = CHILD_ZONES[zone].objectApiName;
            // records removed one by one: only those are deleted, nothing new
            const marked = this._markedByLine(zone).get(lineId);
            if (marked) {
                marked.forEach(rowId => rows.push({ objectApiName, rowId, deleted: true }));
                return;
            }
            const fileRows = this._replacementRows(zone, lineId); // every record replaced when loaded
            if (!fileRows) return;
            this.childState[zone].sfRows
                .filter(r => r.__lineId === lineId)
                .forEach(r => rows.push({ objectApiName, rowId: r.__sfId, deleted: true }));
            fileRows.forEach(fileRow => {
                const values = {};
                Object.keys(fileRow).forEach(k => {
                    const v = valueText(fileRow[k]);
                    if (/^(true|false)$/i.test(v))            values[k] = v.toLowerCase() === 'true';
                    else if (/^-?\d+([.,]\d+)?$/.test(v))    values[k] = v.replace(',', '.');
                    else                                      values[k] = v === '' ? null : v;
                });
                rows.push({ objectApiName, values });
            });
        });
        return rows;
    }

    /**
     * After Process: the file rows of the lines saved are now Salesforce records, so the child tables
     * reload from Salesforce; file rows of failed lines stay for a retry.
     */
    async _reloadChildrenAfterProcess(failedIds) {
        ['rlt', 'lpi'].forEach(zone => {
            const state = this.childState[zone];
            const fileRows = state.fileRows.filter(r => failedIds.has(r.__lineId));
            // the file's rejected-row messages belong to the rows just saved; the table now applies only to the failed
            // lines (their retry), and to no line when none failed, so a later paste of lines does not replace the
            // products of the lines just saved
            const retry = failedIds.size > 0 && !!state.fileName;
            this._setChildState(zone, { fileRows, errors: fileRows.length > 0 ? state.errors : [],
                                        fileName: retry ? state.fileName : '', lineIds: retry ? new Set(failedIds) : null });
        });
        const lineIds = this.linesRows.map(r => r['Line_Id__c']).filter(Boolean);
        try {
            const [terms, items] = await Promise.all([
                getExistingTermsForLinesApex({ lineIds }),
                getExistingProductItemsForLinesApex({ lineIds })
            ]);
            this._setSfChildren('rlt', terms);
            this._setSfChildren('lpi', items);
        } catch (e) {
            console.error('reload children failed', e);
        }
    }

    // ── Platform Events ───────────────────────────────────────────────────────

    _subscribeProgress(jobId, section) {
        subscribe(EVENT_CHANNEL, -1, event => {
            this._handleProgressEvent(event, jobId, section);
        }).then(sub => {
            if (section === 'lines')    this.linesSubscription    = sub;
        });
    }

    /**
     * The load job ended (polled). When its COMPLETED event did not arrive within EVENT_GRACE_MS, the
     * screen ends Process anyway: the job state is shown and the row-by-row result is missing (lost event); the status
     * move of the load is still followed by its job.
     */
    _onLoadJobDone(state) {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            if (this.linesState !== 'processing') return;
            this._unsubscribe(this.linesSubscription);
            this.linesState = 'done';
            this._loadJobCompleted = state.status === 'Completed'; // Update Line Status and Add OU stay available
            const failed = state.status !== 'Completed' || state.errors > 0;
            // an Unknown job (not readable, or still running after POLL_MAX_MS) says why
            const detail = state.status === 'Unknown' ? `Job status unknown (${state.extendedStatus})`
                : `Job ${state.status}${state.errors ? `, ${state.errors} failed part(s): ${state.extendedStatus}` : ''}`;
            this._toast(failed ? 'The load ended with errors' : 'The load ended',
                `${detail}. The row by row result did not reach the screen: check the lines in Salesforce.`,
                failed ? 'error' : 'warning');
            this._reloadChildrenAfterProcess(this.linesFailedIds); // the product tables as they are in Salesforce
            const moves = this._pendingMoves || [];
            if (moves.length > 0) this._startStatusWait(moves, this._statusJobOfLoad(this._loadAsyncJobId));
        }, EVENT_GRACE_MS);
    }

    // progress of Process (lines and their products, one unit per line)
    _handleProgressEvent(event, expectedJobId, section) {
        const payload = event.data.payload;
        if (payload.Job_Id__c !== expectedJobId || section !== 'lines') return;
        // the status move after the load reports with the same jobId (Phase STATUS, _watchStatusMoves)
        if (payload.Phase__c !== PHASE_PROCESS) return;

        const status    = payload.Status__c;
        const errJson   = payload.Errors_JSON__c || '[]';

        this.linesProcessed    = payload.Processed__c || 0;
        this.linesTotal        = payload.Total__c || 0;
        this.linesSuccessCount = payload.Success_Count__c || 0;
        this.linesErrorCount   = payload.Error_Count__c || 0;

        if (status === 'COMPLETED' || status === 'FAILED') {
            let resultErrors = [];
            try { resultErrors = JSON.parse(errJson); } catch (e) {}

            this.linesResultErrors = resultErrors;
            this.linesFailedIds    = new Set(resultErrors.map(e => e.id).filter(Boolean));
            this.linesState        = 'done';
            this._unsubscribe(this.linesSubscription);

            // Update the Status column in the existing preview table — don't replace it
            this._updateSubmissionStatuses('lines', this.linesFailedIds);

            // Backfill SF record IDs for newly created lines so their Line_Id__c becomes a clickable link
            const createdIds = this.linesRows
                .filter(r => r.__status === 'Created')
                .map(r => r['Line_Id__c'])
                .filter(Boolean);
            if (createdIds.length > 0) this._backfillCreatedLineUrls(createdIds);
            this._reloadChildrenAfterProcess(this.linesFailedIds);
            // automatic status change after the load (DMT_BatchSanctionAMIWEB), one line at a time: the
            // lines saved now wait for its result (Phase STATUS); the failed ones were not saved, so they do not move
            const moves = (this._pendingMoves || []).filter(m => !this.linesFailedIds.has(m.lineId));
            if (moves.length === 0) {
                this._endWatch(PHASE_STATUS);
            } else {
                this._startStatusWait(moves, this._statusJobOfLoad(this._loadAsyncJobId));
                this._toast('Status update running in the background',
                    `${moves.length} line(s) move to their status: ${moves.map(m => `${m.lineId} (${m.target})`).join(', ')}. The result will show in the Validation / Status Change column.`,
                    'info');
            }
        }
    }

    // ── Background results (status move, Update Line Status, Add OU) ──────────────────────────────

    /**
     * Follows one job (key PROCESS / STATUS / OU): every POLL_MS reads its AsyncApexJob (getJobState) and calls onDone
     * with the state once it is Completed, Failed or Aborted. getAsyncId resolves the job Id (null while it does not exist
     * yet). After POLL_MAX_FAILURES failed reads, or when the job never appears, onDone gets status 'Unknown'.
     */
    _pollJob(key, getAsyncId, onDone) {
        this._stopPoll(key);
        const poll = { timer: null, failures: 0, started: Date.now() };
        this._polls = this._polls || {};
        this._polls[key] = poll;
        const finish = state => {
            if (this._polls[key] !== poll) return;
            this._stopPoll(key);
            onDone(state);
        };
        const tick = async () => {
            if (this._polls[key] !== poll) return;
            try {
                const asyncJobId = await getAsyncId();
                if (asyncJobId === false) {
                    finish({ status: 'Unknown', errors: 0, extendedStatus: 'the job did not start' });
                    return;
                }
                if (asyncJobId) {
                    const state = await getJobStateApex({ asyncJobId });
                    poll.failures = 0;
                    if (JOB_END_STATES.includes(state.status)) {
                        finish(state);
                        return;
                    }
                }
            } catch (e) {
                console.error('job state read failed', key, e);
                poll.failures++;
                if (poll.failures >= POLL_MAX_FAILURES) {
                    finish({ status: 'Unknown', errors: 0, extendedStatus: 'the job state could not be read' });
                    return;
                }
            }
            // safety net: the screen does not wait for ever; the onDone handlers read the result from the org
            if (Date.now() - poll.started > POLL_MAX_MS) {
                finish({ status: 'Unknown', errors: 0, extendedStatus: 'still running after 10 minutes' });
                return;
            }
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            poll.timer = setTimeout(tick, POLL_MS);
        };
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        poll.timer = setTimeout(tick, POLL_MS);
    }

    _stopPoll(key) {
        const poll = this._polls && this._polls[key];
        if (!poll) return;
        clearTimeout(poll.timer);
        delete this._polls[key];
    }

    // The status job a load started (DMT_BulkImportController.getStatusJobAfterLoad); false when it does not appear
    // within STATUS_JOB_FIND_MS
    _statusJobOfLoad(loadAsyncJobId) {
        const started = Date.now();
        let found = null;
        return async () => {
            if (found) return found;
            found = await getStatusJobAfterLoadApex({ loadAsyncJobId });
            if (!found && Date.now() - started > STATUS_JOB_FIND_MS) return false;
            return found;
        };
    }

    /**
     * Subscribes to the events of one background job (Job_Id__c + Phase__c of DMT_BulkImportProgress__e): progress and
     * row messages. One subscription per phase. Returns false when the subscription fails (the job is still followed by
     * polling).
     */
    async _watchJob(jobId, phase, onEvent) {
        this._endWatch(phase);
        const watch = { jobId, sub: null };
        this._watches = this._watches || {};
        this._watches[phase] = watch;
        try {
            watch.sub = await subscribe(EVENT_CHANNEL, -1, event => {
                const payload = event.data.payload;
                if (payload.Job_Id__c !== jobId || payload.Phase__c !== phase || this._watches[phase] !== watch) return;
                onEvent(payload);
            });
            return true;
        } catch (e) {
            console.error('background result subscription failed', phase, e);
            delete this._watches[phase];
            return false;
        }
    }

    _endWatch(phase) {
        const watch = this._watches && this._watches[phase];
        if (!watch) return;
        this._unsubscribe(watch.sub);
        delete this._watches[phase];
    }

    _endAllWatches() {
        this._endWatch(PHASE_STATUS);
        [PHASE_PROCESS, PHASE_STATUS, 'OU'].forEach(key => this._stopPoll(key));
    }

    /**
     * Events of the status move of the given lines ({ lineId, target }): progress in statusProgressText; the COMPLETED /
     * FAILED event ends it with the row messages (_finishStatusMoves). The job is followed by _startStatusWait.
     */
    async _watchStatusMoves(jobId, moves) {
        // the list can shrink when the load ends (_startStatusWait drops the lines that failed to save)
        this._statusMoves = moves;
        return this._watchJob(jobId, PHASE_STATUS, payload => {
            if (payload.Status__c === 'IN_PROGRESS') {
                this.statusProgressText = `Moving statuses: ${payload.Processed__c || 0} of ${this._statusMoves.length} line(s) done.`;
                return;
            }
            this._finishStatusMoves(this._statusMoves, this._parseErrors(payload.Errors_JSON__c),
                payload.Status__c === 'FAILED' ? { status: 'Failed', errors: 1, extendedStatus: '' } : null);
        });
    }

    // The lines wait for their move (cells 'Moving'); the job (getAsyncId) is polled and, when it ends without the final
    // event, the result is read from Salesforce
    _startStatusWait(moves, getAsyncId) {
        this._statusMoves = moves;
        this._statusDone = false;
        moves.forEach(m => this._statusResults.set(m.lineId, { state: 'moving', target: m.target }));
        this.statusProgressText = `Moving statuses: 0 of ${moves.length} line(s) done.`;
        this._refreshStatusCells();
        this._pollJob(PHASE_STATUS, getAsyncId, state => {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => this._finishStatusMoves(this._statusMoves, [], state), EVENT_GRACE_MS);
        });
    }

    /**
     * The end of a status move (event or job), once: the status of each line is read from Salesforce, so the cell shows
     * what really happened (moved, or not moved with the row message, the job's error, or the line's current status). One
     * final toast: success when every line moved, error otherwise.
     */
    async _finishStatusMoves(moves, errors, jobState) {
        if (this._statusDone) return;
        this._statusDone = true;
        this._endWatch(PHASE_STATUS);
        this._stopPoll(PHASE_STATUS);
        const messageById = new Map(errors.filter(e => e.id).map(e => [e.id, e.message]));
        const general = [...errors.filter(e => !e.id).map(e => e.message),
                         jobState && jobState.extendedStatus ? jobState.extendedStatus : ''].filter(Boolean).join(' ');
        const statusById = new Map();
        let readFailed = false;
        try {
            const records = await getExistingLinesApex({ lineIds: moves.map(m => m.lineId) });
            records.forEach(r => statusById.set(r.Line_Id__c, r.Status__c));
            // the screen keeps the lines as they are now (a moved line is no longer a Draft line to move)
            if (this._sfLinesById) records.forEach(r => this._sfLinesById.set(r.Line_Id__c, r));
        } catch (e) {
            console.error('status result read failed', e);
            readFailed = true;
        }
        const notMoved = [];
        moves.forEach(m => {
            const now = statusById.get(m.lineId);
            if (!readFailed && now === m.target) {
                this._statusResults.set(m.lineId, { state: 'moved', target: m.target });
                return;
            }
            const message = messageById.get(m.lineId)
                || general
                || (readFailed ? 'the status could not be read; check the email'
                    : now && now !== 'Draft' ? `the line is in ${now} (only Draft lines are moved)` : `the line is in ${now || 'an unknown status'}`);
            this._statusResults.set(m.lineId, { state: 'failed', target: m.target, message });
            notMoved.push(`${m.lineId}: ${message}`);
        });
        this.statusProgressText = '';
        this._refreshStatusCells();
        // the button is free again; it enables when some line can move and nothing is left to save
        if (this.lineStatusUpdateState === 'launched') this.lineStatusUpdateState = 'idle';
        const moved = moves.length - notMoved.length;
        if (notMoved.length === 0) {
            this._toast('Status update finished', `${moved} line(s) moved to their status.`, 'success');
        } else {
            this._toast(jobState && jobState.status !== 'Completed' ? 'Status update failed' : 'Status update finished with errors',
                `${moved} moved, ${notMoved.length} not moved: ${notMoved.slice(0, 5).join(' | ')}${notMoved.length > 5 ? ' | ...' : ''}`, 'error');
        }
    }

    _parseErrors(errorsJson) {
        try { return JSON.parse(errorsJson || '[]'); } catch (e) { return []; }
    }

    // ── Error log download ────────────────────────────────────────────────────

    downloadLinesErrorLog() {
        this._downloadCSV(this.linesResultErrors, 'lines_errors.csv',
            ['Row', 'Line_Id__c', 'Name', 'Error'],
            e => [e.row, e.id, e.label, e.message]);
    }

    _downloadCSV(data, filename, headers, rowMapper) {
        const csvContent = [headers, ...data.map(rowMapper)]
            .map(r => r.map(v => `"${String(v || '').replace(/"/g, '""')}"`).join(','))
            .join('\n');

        const url  = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvContent);
        const link = document.createElement('a');
        link.href  = url;
        link.setAttribute('download', filename);
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }

    // ── Utilities ─────────────────────────────────────────────────────────────

    _toast(title, message, variant = 'error') {
        // errors and warnings stay until closed; success and info close by themselves, so they do not
        // pile up (Lightning shows only a few toasts at a time and hides the newest)
        const mode = variant === 'error' || variant === 'warning' ? 'sticky' : 'dismissible';
        this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode }));
    }

    _newJobId() {
        return `bulk-${Date.now()}-${Math.random().toString(36).substring(2, 8)}`;
    }

    _cleanRow(row) {
        const clean = {};
        Object.keys(row).forEach(k => { if (!k.startsWith('__')) clean[k] = row[k]; });
        return clean;
    }

    _unsubscribe(subscription) {
        if (subscription) {
            // Enhancement fix to existing process: empApi unsubscribe needs a callback
            // ('Invalid or missing callback' in the console after every load)
            unsubscribe(subscription, () => {});
        }
    }
}
