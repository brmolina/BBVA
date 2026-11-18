import { LightningElement, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import SHEETJS from '@salesforce/resourceUrl/DMT_SheetJS';
import LightningConfirm from 'lightning/confirm'; // CIBGLOBALD-4851
import submitLinesApex       from '@salesforce/apex/DMT_BulkImportController.submitLines';
import getExistingLinesApex     from '@salesforce/apex/DMT_BulkImportController.getExistingLines';
import getExistingTermsForLinesApex from '@salesforce/apex/DMT_BulkImportController.getExistingTermsForLines';
import getExistingProductItemsForLinesApex from '@salesforce/apex/DMT_BulkImportController.getExistingProductItemsForLines'; // CIBGLOBALD-4851
import queryCreatedLinesApex    from '@salesforce/apex/DMT_BulkImportController.queryCreatedLines';
import updateLineStatusApex     from '@salesforce/apex/DMT_BulkImportController.updateLineStatus';
import hasDMTLineGod    from '@salesforce/customPermission/DMT_Line_God';
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

const LINES_REQUIRED    = ['Line_Id__c']; // CIBGLOBALD-4851 - only the org-required column; the client is checked in Apex (DMT_BulkImportBatch)

// CIBGLOBALD-4851 - DMT_Line__c columns compared with Salesforce (New / Will Update / No Changes), by type. Only the
// columns present in the file are compared and saved (DMT_BulkImportBatch.LINE_FILE_FIELDS); a blank cell clears the field.
const LINE_COMPARE_FIELDS = {
    Name: 'text', Booking_Geography__c: 'text', DMT_Client_Entific__c: 'text', CurrencyIsoCode: 'text',
    Start_Date__c: 'date', End_Date__c: 'date', Client_Code__c: 'text', Golden_Code__c: 'text',
    FD_Amount__c: 'number', DvP_Amount__c: 'number', Breakclause_Frequency__c: 'text', First_Breakclause__c: 'text',
    Waiver__c: 'boolean', DMT_Mitigant_Agreement_comments__c: 'text', DMT_Comments__c: 'text',
    DMT_Additional_Restrictions__c: 'text', DMT_Client_Use__c: 'text', DMT_LastLevelId__c: 'text',
    g_line_status_type__c: 'text', DMT_ID_User__c: 'text'
};
// CIBGLOBALD-4851 - a blank cell in these columns keeps the Salesforce value (DMT_BulkImportBatch.KEEP_WHEN_BLANK_FIELDS)
const KEEP_WHEN_BLANK_FIELDS = ['First_Breakclause__c', 'Breakclause_Frequency__c'];
// CIBGLOBALD-4851 - columns that only exist in child files (Risk Line Terms, Line Product Items): a pasted table with
// one of them is not a Lines file.
const CHILD_FILE_COLUMNS = ['g_amortization_type__c', 'Line__r.Line_Id__c', 'DMT_Line__r.Line_Id__c', 'Product_Code_Value__c', 'DMT_Risk_Type__c'];

// CIBGLOBALD-4851 - child tables of the loaded lines. When a child file has rows for a line, every record of that object
// on that line is deleted and the file rows are inserted (Process); a line without rows in the file keeps its records.
// lineIdColumns: accepted names of the column that holds the parent Line_Id__c. fingerprint: columns that identify the
// file type (wrong drop zone check). displayFields: columns always shown, filled from the Salesforce records.
const CHILD_ZONES = {
    rlt: {
        label: 'Risk Line Terms',
        sfRelationship: 'DMT_Line__r',
        lineIdColumns: ['DMT_Line__r.Line_Id__c', 'Line_Id__c'],
        fingerprint: ['DMT_Line__r.Line_Id__c', 'DMT_Risk_Type__c', 'DMT_RiskLineTermId__c', 'DMT_Init_Term__c', 'DMT_End_Term__c',
                      'DMT_Risk_Line_Term__c DMT_Init_Term__c', 'DMT_Risk_Line_Term__c DMT_Amount__c', 'g_amortization_type__c'],
        displayFields: ['DMT_Risk_Type__c', 'DMT_RiskLineTermId__c', 'DMT_Amount__c', 'CurrencyIsoCode', 'DMT_Init_Term__c',
                        'DMT_End_Term__c', 'g_global_product_family_id__c', 'g_global_product_subfamily_id__c',
                        'g_global_product_category_id__c']
    },
    lpi: {
        label: 'Line Product Items',
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
const CHILD_STATUS_CLASS  = {
    [CHILD_STATUS_NEW]: 'slds-text-color_success', [CHILD_STATUS_DELETE]: 'slds-text-color_error', [CHILD_STATUS_KEPT]: 'slds-text-color_weak'
};
// Old Other Products files name the term columns 'DMT_Risk_Line_Term__c <field>'; the tables show them as <field>
const TERM_COLUMN_PREFIX  = 'DMT_Risk_Line_Term__c ';
const CHILD_ERROR_LIMIT   = 20;
const emptyChildState = () => ({ fileName: '', fileRows: [], sfRows: [], errors: [] });

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
    // CIBGLOBALD-4851 - child tables: per zone (rlt, lpi) the file rows (New) and the Salesforce records of the loaded
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

    handleLineTypeChange(event) {
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
            const text = event.clipboardData && event.clipboardData.getData('text');
            if (text) this._processPastedText(text);
        };
        document.addEventListener('paste', this._pasteHandler);
    }

    disconnectedCallback() {
        this._unsubscribe(this.linesSubscription);
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
    get linesSubmitDisabled()       {
        return this.linesState !== 'ready' ||
               this.linesRows.every(r => r.__status === 'No Changes');
    }
    get linesProgress()             { return this.linesTotal > 0 ? Math.round(this.linesProcessed / this.linesTotal * 100) : 0; }
    get linesHasResultErrors()      { return this.linesResultErrors.length > 0; }
    get linesDropZoneClass()  {
        return 'drop-zone' +
            (this.linesDragging  ? ' drop-zone_active'  : '') +
            (this.linesRows.length > 0 ? ' drop-zone_compact' : '');
    }
    get linesDropZoneText()   {
        return this.linesRows.length > 0
            ? `${this.linesRowCount} rows loaded — drop or paste (Ctrl+V) to add / update lines`
            : 'Drop Lines XLSX or CSV here, or paste with Ctrl+V';
    }
    get linesRetryDropZoneClass()   { return 'drop-zone drop-zone_compact' + (this.linesRetryDragging ? ' drop-zone_active' : ''); }
    get hasLinesCreatedRecords()    { return this.linesCreatedRecords && this.linesCreatedRecords.length > 0; }
    get hasLinesEnrichedStats()     { return this.linesEnrichedStats !== null; }

    // Update Line Status is offered once the lines were submitted, or when every line is already No Changes
    get step2Enabled() {
        const allNoChanges = this.linesRows.length > 0 &&
                             this.linesState === 'ready' &&
                             this.linesRows.every(r => r.__status === 'No Changes');
        return (this.linesState === 'done' && this.linesSuccessCount > 0) || allNoChanges;
    }

    // ── CIBGLOBALD-4851 - Child tables (Risk Line Terms, Line Product Items) ──

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
                    dropZoneClass: 'drop-zone drop-zone_compact' + (this.childDragZone === zone ? ' drop-zone_active' : ''),
                    dropZoneText: state.fileRows.length > 0
                        ? `${state.fileName}: ${state.fileRows.length} rows. Drop or paste (Ctrl+V) another ${label} file to replace them`
                        : `Drop ${label} XLSX or CSV here, or paste with Ctrl+V`,
                    hasErrors: state.errors.length > 0,
                    errors: state.errors,
                    hasRows: rows.length > 0,
                    newCount: count(CHILD_STATUS_NEW),
                    deleteCount: count(CHILD_STATUS_DELETE),
                    keptCount: count(CHILD_STATUS_KEPT),
                    columns: this._childColumns(zone, rows),
                    rows: this._childDisplayRows(rows)
                };
            });
    }

    /**
     * File rows (New) plus the Salesforce records of the loaded lines: Will Be Deleted when the file has rows for
     * their line, Kept otherwise. Sorted by line, file rows first.
     */
    _childRowsFor(zone) {
        const state   = this.childState[zone];
        const covered = new Set(state.fileRows.map(r => r.__lineId));
        const sfRows  = state.sfRows.map(r => ({ ...r, __status: covered.has(r.__lineId) ? CHILD_STATUS_DELETE : CHILD_STATUS_KEPT }));
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
            const flat = { __key: r.__key, __lineId: r.__lineId, __status: r.__status, __statusClass: CHILD_STATUS_CLASS[r.__status] };
            Object.keys(r).forEach(k => {
                if (k.startsWith('__')) return;
                const v = r[k];
                flat[this._safeKey(k)] = (v === null || v === undefined) ? '' : String(v);
            });
            return flat;
        });
    }

    // Only file rows can be removed; Salesforce records follow the replace rule
    _childRowActions = (row, doneCallback) => {
        doneCallback([{ label: 'Remove row', name: 'remove', disabled: row.__status !== CHILD_STATUS_NEW }]);
    };

    handleChildRowAction(event) {
        if (event.detail.action.name !== 'remove') return;
        const zone  = event.target.dataset.zone;
        const key   = event.detail.row.__key;
        const state = this.childState[zone];
        this._setChildState(zone, { fileRows: state.fileRows.filter(r => r.__key !== key) });
    }

    _setChildState(zone, changes) {
        this.childState = { ...this.childState, [zone]: { ...this.childState[zone], ...changes } };
    }

    _resetChildren() {
        this.childState = { rlt: emptyChildState(), lpi: emptyChildState() };
    }

    openChildFilePicker(event) {
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
        this._setChildState(zone, { fileName, fileRows: accepted, errors });
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
            Object.keys(record).forEach(k => { if (k !== 'Id' && k !== relationship) child[k] = record[k]; });
            return child;
        });
        this._setChildState(zone, { sfRows });
    }

    // Old Other Products Lines file: its term columns are the Risk Line Terms file rows
    _loadTermsFromLinesFile() {
        if (this.pendingTermsFromLines.length === 0) return;
        const rows = this.pendingTermsFromLines.map((t, i) => ({ ...t, __rowIndex: i + 2 }));
        this._loadChildFile('rlt', rows, `${this.linesFileName} (term columns)`);
    }

    // Product amount per line in Salesforce now (Risk Line Terms), for the Update Line Status pre-check
    _sfTermAmountForLine(lineId) {
        return this.childState.rlt.sfRows
            .filter(r => r.__lineId === lineId)
            .reduce((sum, r) => sum + (parseFloat(r.DMT_Amount__c) || 0), 0);
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
    get showUpdateLineStatus()      { return this.step2Enabled; } // CIBGLOBALD-4851

    // Record-type + target-status data requirements this predictive check mirrors (both are
    // currently-active, enforced server-side regardless of what this getter decides):
    //   - TreasurySettlement, any line targeting a non-Draft code: DMT_TRSR_Line_Validations
    //     requires at least one product term with a positive amount (or FD_Amount__c/DvP_Amount__c
    //     on the line itself, which Bulk Import never sets). That flow has an admin / DMT_Line_God
    //     bypass, but that bypass exists for ACCESS restrictions elsewhere in it, not this amount
    //     check — it is intentionally NOT treated as a way around this requirement here, so the
    //     button reflects what a real, non-privileged user will experience.
    //   - OtherProducts, only lines targeting Proposal ('PR'): CompulsoryAmountLastLevel requires
    //     Amount__c or DMT_LastLevelId__c populated, and CheckAmountsInLine requires the products'
    //     total to cover the line's own Amount__c. Neither of those has any bypass.
    // This is a best-effort mirror of the rules as they stand today, not a guarantee — a row can
    // still come back Failed if the underlying data or rules have moved since this was written.
    // Backend now does a per-row partial save (Database.update(lines, false)) in Bulk Import mode:
    // one line failing validation is reported (email + exception log) without blocking the rest of
    // the import. So the button only needs to stay disabled when NO line stands a chance at all -
    // it does not need every line to be eligible, only at least one.
    get linesBlockingUpdateLineStatus() {
        const isTreasury = this.selectedRecordType === 'TreasurySettlement';
        // CIBGLOBALD-4851 - only the Risk Line Terms in Salesforce count (child table records, _sfTermAmountForLine):
        // file rows are not saved yet.
        return this.importedLineIds
            .map(lineId => this.linesRows.find(r => r['Line_Id__c'] === lineId))
            .filter(Boolean)
            .filter(line => {
                const code = line['g_line_status_type__c'];
                if (!code || code === 'DR') return false; // stays Draft — no gate applies

                const productsTotal = this._sfTermAmountForLine(line['Line_Id__c']); // CIBGLOBALD-4851

                if (isTreasury) {
                    return productsTotal <= 0;
                }
                if (code !== 'PR') return false; // OtherProducts: only the Proposal code is gated
                const lineAmount    = parseFloat(line['DMT_Risk_Line_Term__c DMT_Amount__c']) || 0;
                const hasLastLevel  = !!(line['DMT_LastLevelId__c'] && String(line['DMT_LastLevelId__c']).trim());
                const compulsoryOk  = lineAmount > 0 || hasLastLevel;
                const rollupOk      = productsTotal >= lineAmount;
                return !(compulsoryOk && rollupOk);
            })
            .map(line => line['Line_Id__c']);
    }

    // Informational — when SOME lines are still eligible, this does not block the click, it just
    // names what will likely fail. When ALL lines are blocking there is no "rest" to proceed with,
    // so the wording (and updateLineStatusDisabled below) must not imply otherwise.
    get updateLineStatusBlockedMessage() {
        const blocking = this.linesBlockingUpdateLineStatus;
        const total = this.importedLineIds.length;
        if (blocking.length === 0) return '';
        const shown = blocking.slice(0, 5).join(', ') + (blocking.length > 5 ? `, +${blocking.length - 5} more` : '');
        return blocking.length >= total
            ? `All ${total} line(s) are missing the product amounts needed for this status update and would fail: ${shown}.`
            : `${blocking.length} of ${total} line(s) are missing the product amounts needed for this status update and will likely be reported as failed: ${shown}. You can still proceed for the rest.`;
    }

    get updateLineStatusDisabled() {
        return this.lineStatusUpdateState !== 'idle' ||
               this.linesBlockingUpdateLineStatus.length >= this.importedLineIds.length;
    }

    updateLineStatus() {
        const lineIds = this.importedLineIds;
        if (lineIds.length === 0) return;

        this.lineStatusUpdateState = 'launching';
        updateLineStatusApex({ lineIds })
            .then(asyncJobId => {
                this.lineStatusUpdateState = 'launched';
                this._toast('Update Line Status launched',
                    `Draft lines of this import are being updated to the status informed in the file (job ${asyncJobId}). You will receive an email when it finishes.`,
                    'success');
            })
            .catch(e => {
                console.error('updateLineStatus error', e);
                this.lineStatusUpdateState = 'idle';
                this._toast('Update Line Status failed', (e && e.body && e.body.message) || 'Unexpected error');
            });
    }

    // ── File picker triggers ──────────────────────────────────────────────────

    openLinesFilePicker() {
        this.template.querySelector('input[data-section="lines"]').click();
    }

    handleFileInputChange(event) {
        const file    = event.target.files[0];
        const section = event.target.dataset.section;
        if (file) this._processFile(file, section);
        event.target.value = '';
    }

    // ── Drag and drop ─────────────────────────────────────────────────────────

    // CIBGLOBALD-4851 - Lines drop zone only; the child zones use handleChildDragOver / handleChildDragLeave
    handleDragOver(event) {
        event.preventDefault();
        this.linesDragging = true;
    }

    handleDragLeave() {
        this.linesDragging = false;
    }

    handleLinesFileDrop(event) {
        event.preventDefault();
        this.linesDragging = false;
        const file = event.dataTransfer.files[0];
        if (file) this._processFile(file, 'lines');
    }

    handleRetryDragOver(event) {
        event.preventDefault();
        this.linesRetryDragging = true;
    }

    handleRetryDragLeave() {
        this.linesRetryDragging = false;
    }

    handleRetryFileDrop(event) {
        event.preventDefault();
        this.linesRetryDragging = false;
        const file = event.dataTransfer.files[0];
        if (file) this._processRetryFile(file);
    }

    openRetryFilePicker() {
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

    get hasAnyData() { return this.linesRows.length > 0; } // CIBGLOBALD-4851 - child rows exist only with lines

    resetAll() {
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
        this._resetChildren(); // CIBGLOBALD-4851

        this.lineStatusUpdateState    = 'idle';
    }

    // ── Clear file ────────────────────────────────────────────────────────────

    clearLinesFile() {
        this.linesState            = 'idle';
        this.linesFileName         = '';
        this.linesRowCount         = 0;
        this.linesRows             = [];
        this.linesValidationErrors = [];
        this.linesPreviewColumns   = [];
        this.linesPreviewRows      = [];
        this.linesEnrichedStats    = null;
        this.pendingTermsFromLines = [];
        this._resetChildren(); // CIBGLOBALD-4851 - child rows belong to the lines
    }

    // ── Clipboard paste (Ctrl+V) ──────────────────────────────────────────────

    _processPastedText(text) {
        const rows = this._parseCSV(text); // CIBGLOBALD-4851 - same quote-aware parser as a dropped CSV
        if (rows.length === 0) return;
        const headers = Object.keys(rows[0]).filter(k => k !== '__rowIndex'); // CIBGLOBALD-4851

        // Bail silently if content doesn't look like a Salesforce data file at all
        if (!headers.some(h => h.includes('__c') || h === 'gf_cutoff_date')) return;

        // CIBGLOBALD-4851 - route by the columns (Lines, Risk Line Terms, Line Product Items)
        const section = this._detectFileType(headers);
        if (!section) return;
        if (section === 'lines') this._onRowsParsed(rows, 'Clipboard', section);
        else this._loadChildFile(section, rows, 'Clipboard');
    }

    // ── File parsing ──────────────────────────────────────────────────────────

    _processFile(file, section) {
        const ext = file.name.split('.').pop().toLowerCase();
        if (!['csv', 'xlsx', 'xls'].includes(ext)) {
            this._zoneErrors(section, [{ key: 'ext', message: `File type .${ext} is not supported. Use CSV, XLSX or XLS.` }]); // CIBGLOBALD-4851
            return;
        }

        const reader = new FileReader();

        if (ext === 'csv') {
            reader.onload = e => {
                const rows = this._parseCSV(e.target.result);
                this._routeParsedRows(rows, file.name, section); // CIBGLOBALD-4851
            };
            reader.readAsText(file);
        } else {
            if (!this.sheetJsLoaded) {
                this._zoneErrors(section, [{ key: 'sheetjs', message: 'SheetJS library is still loading. Try again in a moment.' }]); // CIBGLOBALD-4851
                return;
            }
            reader.onload = e => {
                const rows = this._parseXLSX(e.target.result);
                this._routeParsedRows(rows, file.name, section); // CIBGLOBALD-4851
            };
            reader.readAsArrayBuffer(file);
        }
    }

    /**
     * CIBGLOBALD-4851 - Delimited text (CSV file or pasted table) to row objects keyed by header. Values in double
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

        const nonBlank = records.filter(r => r.some(v => v.trim() !== ''));
        if (nonBlank.length < 2) return [];
        const headers = nonBlank[0].map(h => h.trim());
        return nonBlank.slice(1).map((values, idx) => {
            const row = { __rowIndex: idx + 2 };
            headers.forEach((h, i) => { if (h) row[h] = (values[i] || '').trim(); });
            return row;
        });
    }

    _parseXLSX(arrayBuffer) {
        // eslint-disable-next-line no-undef
        const workbook = XLSX.read(new Uint8Array(arrayBuffer), { type: 'array', cellDates: true });
        const sheet    = workbook.Sheets[workbook.SheetNames[0]];
        // eslint-disable-next-line no-undef
        const rawRows  = XLSX.utils.sheet_to_json(sheet, { header: 1, defval: '' });
        if (rawRows.length < 2) return [];
        const headers = rawRows[0].map(h => String(h).trim());
        return rawRows.slice(1).map((values, idx) => {
            const row = { __rowIndex: idx + 2 };
            headers.forEach((h, i) => {
                const v = values[i];
                row[h] = v instanceof Date
                    ? v.toISOString().substring(0, 10)
                    : (v !== undefined && v !== null ? String(v).trim() : '');
            });
            return row;
        });
    }

    // CIBGLOBALD-4851 - Lines rows only: child files load through _loadChildFile (section kept for the callers)
    _onRowsParsed(rows, fileName, section) {
        if (section !== 'lines') return;

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
        // CIBGLOBALD-4851 - null = header-driven file (Lines): only the required columns must be there
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

    // CIBGLOBALD-4851 - Lines only: child tables keep their own errors (_zoneErrors)
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

        if (section === 'lines') { // CIBGLOBALD-4851 - the child tables build their rows in childSections
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

    // CIBGLOBALD-4851 - the columns of the loaded Lines rows (header-driven), in file order
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
            const term = { 'Line_Id__c': row['Line_Id__c'] || '' };
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

    _updateSubmissionStatuses(section, failedIds) {
        if (section === 'lines') {
            this.linesRows = this.linesRows.map(r => {
                if (r.__status === 'No Changes') return r;
                if (failedIds.has(r['Line_Id__c'])) return { ...r, __status: 'Failed' };
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
            const [existingLines, existingTerms, existingItems] = await Promise.all([ // CIBGLOBALD-4851
                getExistingLinesApex({ lineIds }),
                getExistingTermsForLinesApex({ lineIds }),
                getExistingProductItemsForLinesApex({ lineIds }) // CIBGLOBALD-4851
            ]);
            // Guard: user may have cleared or resubmitted the file while we were loading
            if (this.linesState !== 'ready') return;
            this._applyLineEnrichment(rows, existingLines);
            // CIBGLOBALD-4851 - Salesforce records of the loaded lines in the child tables; term columns of an old
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
            this._buildPreview(this.linesRows, this._linePreviewHeaders(this._linesFileHeaders()), 'lines'); // CIBGLOBALD-4851
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

        let newCount = 0, updateCount = 0, noChangeCount = 0;

        const enrichedRows = csvRows.map(row => {
            const sf      = sfMap.get(row['Line_Id__c']);
            const enriched = { ...row };

            if (!sf) {
                enriched.__status      = 'New';
                enriched.__statusClass = 'status-new';
                newCount++;
            } else {
                // CIBGLOBALD-4851 - no backfill of blank cells with the Salesforce values: a column in the file is
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
        const previewHeaders  = this._linePreviewHeaders(this._linesFileHeaders()); // CIBGLOBALD-4851
        const nonIdHeaders    = previewHeaders.filter(h => h !== 'Line_Id__c');
        const hasAnyExisting  = enrichedRows.every(r => r.__sfId);
        const lineIdCol       = hasAnyExisting
            ? { label: 'Line_Id__c', fieldName: '__lineUrl', type: 'url',
                typeAttributes: { label: { fieldName: 'Line_Id__c' }, target: '_blank' }, initialWidth: 200, wrapText: false }
            : { label: 'Line_Id__c', fieldName: 'Line_Id__c', type: 'text', initialWidth: 180, wrapText: false };
        this.linesPreviewColumns = [
            { label: 'Status', fieldName: '__status', type: 'text', initialWidth: 100, wrapText: false },
            lineIdCol,
            ...nonIdHeaders.map(h => ({ label: h, fieldName: this._safeKey(h), type: 'text', initialWidth: 160, wrapText: false }))
        ];
        this.linesPreviewRows = enrichedRows.slice(0, PREVIEW_ROW_LIMIT).map((row, idx) => {
            const flat = { __previewKey: String(idx), __status: row.__status, 'Line_Id__c': row['Line_Id__c'] || '' };
            flat.__lineUrl = row.__sfId ? (window.location.origin + '/' + row.__sfId) : null;
            nonIdHeaders.forEach(h => { flat[this._safeKey(h)] = row[h] || ''; });
            return flat;
        });

        this.linesEnrichedStats = { newCount, updateCount, noChangeCount };
    }

    /**
     * CIBGLOBALD-4851 - True when a column of the file differs from the line in Salesforce. Only the columns present
     * in the file are compared (LINE_COMPARE_FIELDS); a blank cell differs from a filled field because saving clears it.
     * Status__c is never compared: DMT_BulkImportBatch ignores it (new lines start in Draft, existing ones keep theirs).
     */
    _hasLineChanges(csvRow, sf) {
        const text = v => (v === null || v === undefined) ? '' : String(v).trim();
        const normalise = (type, v) => {
            const s = text(v);
            if (type === 'date') {
                const dmy = s.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/); // dd/mm/yyyy, also accepted by the Apex save
                return dmy ? `${dmy[3]}-${dmy[2].padStart(2, '0')}-${dmy[1].padStart(2, '0')}` : s.substring(0, 10);
            }
            if (type === 'number')  return s === '' ? '' : String(Number(s.replace(',', '.')));
            if (type === 'boolean') return ['true', '1', 'yes'].includes(s.toLowerCase()) ? 'true' : 'false';
            return s;
        };
        return Object.keys(LINE_COMPARE_FIELDS)
            .filter(field => field in csvRow)
            .filter(field => !(KEEP_WHEN_BLANK_FIELDS.includes(field) && text(csvRow[field]) === '')) // CIBGLOBALD-4851
            .some(field => {
                const type = LINE_COMPARE_FIELDS[field];
                return normalise(type, csvRow[field]) !== normalise(type, sf[field]);
            });
    }

    // ── Submit ────────────────────────────────────────────────────────────────

    submitLines() {
        // Only submit rows that actually need a DML — skip "No Changes"
        const payload = this.linesRows
            .filter(r => r.__status !== 'No Changes')
            .map(r => this._cleanRow(r));
        if (payload.length === 0) return;

        this.linesState     = 'submitting';
        this.linesJobId     = this._newJobId();
        this.linesProcessed = 0;
        this.linesTotal     = payload.length;
        // New lines submitted → allow launching Update Line Status again for them
        this.lineStatusUpdateState = 'idle';

        this._subscribeProgress(this.linesJobId, 'lines');

        submitLinesApex({ rowsJson: JSON.stringify(payload), jobId: this.linesJobId, recordTypeName: this.selectedRecordType })
            .then(() => { this.linesState = 'processing'; })
            .catch(e => {
                console.error('submitLines error', e);
                this.linesState = 'idle';
                this._unsubscribe(this.linesSubscription);
            });
    }

    // ── Platform Events ───────────────────────────────────────────────────────

    _subscribeProgress(jobId, section) {
        subscribe(EVENT_CHANNEL, -1, event => {
            this._handleProgressEvent(event, jobId, section);
        }).then(sub => {
            if (section === 'lines')    this.linesSubscription    = sub;
        });
    }

    // CIBGLOBALD-4851 - Lines progress only (child rows are saved with Process)
    _handleProgressEvent(event, expectedJobId, section) {
        const payload = event.data.payload;
        if (payload.Job_Id__c !== expectedJobId || section !== 'lines') return;

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
        }
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
        this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode: 'sticky' }));
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
            unsubscribe(subscription).catch(e => console.error('unsubscribe error', e));
        }
    }
}
