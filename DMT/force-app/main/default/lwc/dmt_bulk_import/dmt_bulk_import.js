import { LightningElement, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import SHEETJS from '@salesforce/resourceUrl/DMT_SheetJS';
import submitLinesApex       from '@salesforce/apex/DMT_BulkImportController.submitLines';
import submitProductsApex    from '@salesforce/apex/DMT_BulkImportController.submitProducts';
import getExistingLinesApex     from '@salesforce/apex/DMT_BulkImportController.getExistingLines';
import getExistingTermsForLinesApex from '@salesforce/apex/DMT_BulkImportController.getExistingTermsForLines';
import queryCreatedLinesApex    from '@salesforce/apex/DMT_BulkImportController.queryCreatedLines';
import updateLineStatusApex     from '@salesforce/apex/DMT_BulkImportController.updateLineStatus';
import hasDMTLineGod    from '@salesforce/customPermission/DMT_Line_God';
import hasConsultationIT from '@salesforce/customPermission/ConsultationIT';
import hasDMTReadOnly    from '@salesforce/customPermission/DMT_Read_Only';
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

const PRODUCTS_HEADERS = [
    'Booking_Geography__c', 'Line_Id__c', 'Client_Code__c', 'Client__c',
    'g_group_id', 'End_Date__c', 'Start_Date__c', 'DMT_LastLevelId__c',
    'g_risk_level_clsfn_type__c', 'g_global_product_family_id__c',
    'g_global_product_subfamily_id__c', 'g_global_product_category_id__c',
    'g_gbl_product_subcategory_id__c', 'g_global_product_id__c',
    'DMT_Risk_Line_Term__c DMT_Init_Term__c', 'DMT_Risk_Line_Term__c DMT_End_Term__c',
    'DMT_Parent_Line__c', 'DMT_Risk_Line_Term__c DMT_Amount__c',
    'CurrencyIsoCode', 'owner User id_user__c', 'DMT_Comments__c',
    'Createbydate', 'Breakclause_Frequency__c', 'DMT_RiskLineTermId__c',
    'gf_priority_line_id__c', 'Name',
    'gf_group_priority_line_id__c', 'g_multioperation_ind_type__c',
    'g_line_status_type__c', 'Status__c', 'g_expert_criteria_risk_type__c',
    'g_amortization_type__c', 'gf_inscol_months_grace_number__c', 'gf_payment_frequency__c'
];

const LINES_REQUIRED    = ['Line_Id__c', 'Name', 'Client_Code__c', 'Start_Date__c', 'End_Date__c', 'CurrencyIsoCode', 'Booking_Geography__c'];
const PRODUCTS_REQUIRED = ['Line_Id__c', 'DMT_RiskLineTermId__c'];

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
    // Raw DMT_Risk_Line_Term__c records fetched alongside line enrichment (getExistingTermsForLines),
    // kept regardless of whether the Lines file also embedded term columns — see
    // preExistingProductsToLoad / loadPreExistingProducts.
    existingTermsFromServer = [];
    productsPreloaded      = false;
    @track productsState = 'idle';
    productsFileName     = '';
    productsRowCount     = 0;
    @track productsValidationErrors  = [];
    @track productsPreviewColumns    = [];
    @track productsPreviewRows       = [];
    productsRows         = [];
    productsJobId        = '';
    productsTotal        = 0;
    productsProcessed    = 0;
    productsSuccessCount = 0;
    productsErrorCount   = 0;
    @track productsResultErrors      = [];
    productsSubscription = null;

    // Queried after products batch completes — shown as a result table with navigation links
    @track productsCreatedRecords = null;

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
    productsDragging = false;

    // ── Constant exposed to template ─────────────────────────────────────────
    get previewRowLimit() { return PREVIEW_ROW_LIMIT; }
    get hasAccess()       { return hasDMTLineGod && !hasConsultationIT && !hasDMTReadOnly; }

    get linesPreviewLabel() {
        return this.linesRowCount <= PREVIEW_ROW_LIMIT
            ? `Showing all ${this.linesRowCount} rows`
            : `Showing first ${PREVIEW_ROW_LIMIT} of ${this.linesRowCount} rows`;
    }

    get productsPreviewLabel() {
        const count = this.productsRowCount <= PREVIEW_ROW_LIMIT
            ? `Showing all ${this.productsRowCount} rows`
            : `Showing first ${PREVIEW_ROW_LIMIT} of ${this.productsRowCount} rows`;
        // Reflects the CURRENT rows, not just "was anything ever preloaded" — a row dropped from a
        // file that happens to overlap a preloaded one replaces it (see _mergeTermRowsUpdate), so
        // the preloaded count must be recomputed from productsRows each time, not a sticky flag.
        const preloadedCount = this.productsRows.filter(r => r.__preloaded).length;
        if (preloadedCount === 0) return count;
        if (preloadedCount === this.productsRows.length) return `${count} — pre-loaded from lines file`;
        return `${count}, ${preloadedCount} pre-loaded from lines file`;
    }

    get productsShowAddMore() {
        return this.productsPreloaded && this.productsState === 'ready';
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

    get productsCreatedColumns() {
        return [
            { label: 'Term ID', fieldName: 'termUrl', type: 'url',
              typeAttributes: { label: { fieldName: 'DMT_RiskLineTermId__c' }, target: '_blank' }, initialWidth: 200 },
            { label: 'Name', fieldName: 'Name', type: 'text', initialWidth: 200 },
            { label: 'Line', fieldName: 'lineName', type: 'text', initialWidth: 200 },
            { label: 'Line ID', fieldName: 'lineId', type: 'text', initialWidth: 160 }
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
        this._unsubscribe(this.productsSubscription);
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
    get productsShowSubmit()        { return ['ready', 'error', 'done'].includes(this.productsState); }
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

    get productsEnrichedStats() {
        if (this.productsRows.length === 0) return null;
        let newCount = 0, updateCount = 0, noChangeCount = 0;
        this.productsRows.forEach(r => {
            const s = r.__status || '';
            if (s === 'New' || s === 'Created')              newCount++;
            else if (s === 'Will Update' || s === 'Updated') updateCount++;
            else if (s === 'No Changes')                     noChangeCount++;
            // 'Existing' and 'Failed' rows are intentionally excluded from this summary
        });
        return { newCount, updateCount, noChangeCount };
    }
    get hasProductsEnrichedStats()  { return this.productsRows.length > 0; }

    // Step 2 is ENABLED when lines were submitted, OR when all lines are No Changes (nothing to submit)
    get step2Enabled() {
        const allNoChanges = this.linesRows.length > 0 &&
                             this.linesState === 'ready' &&
                             this.linesRows.every(r => r.__status === 'No Changes');
        return (this.linesState === 'done' && this.linesSuccessCount > 0) || allNoChanges;
    }
    // Step 2 is VISIBLE (read-only preview) as soon as products rows exist, even before lines are submitted
    get step2Visible()              { return this.step2Enabled || this.productsRows.length > 0; }
    // When visible but not yet submittable — show informational notice
    get step2ReadOnly()             { return this.step2Visible && !this.step2Enabled; }
    get step2Disabled()             { return !this.step2Enabled && this.productsRows.length === 0; }
    get productsCardClass()         { return 'slds-card' + (this.step2Disabled ? ' section-disabled' : ''); }

    get productsIsIdle()            { return this.productsState === 'idle'; }
    get productsHasFile()           { return ['ready', 'error', 'submitting', 'processing', 'done'].includes(this.productsState); }
    get productsHasValidationErrors() { return this.productsState === 'error' && this.productsValidationErrors.length > 0; }
    get productsShowPreview()       { return ['ready', 'submitting', 'processing', 'done'].includes(this.productsState); }
    get productsIsProcessing()      { return ['submitting', 'processing'].includes(this.productsState); }
    get productsIsDone()            { return this.productsState === 'done'; }
    // Disabled when: step 1 not done, OR state not ready, OR every row is No Changes/Existing
    get productsSubmitDisabled()    {
        return !this.step2Enabled ||
               this.productsState !== 'ready' ||
               this.productsRows.every(r => r.__status === 'No Changes' || r.__status === 'Existing');
    }
    get productsProgress()          { return this.productsTotal > 0 ? Math.round(this.productsProcessed / this.productsTotal * 100) : 0; }
    get productsHasResultErrors()   { return this.productsResultErrors.length > 0; }
    get productsDropZoneClass() {
        return 'drop-zone' +
            (this.productsDragging ? ' drop-zone_active'  : '') +
            (this.productsRows.length > 0 ? ' drop-zone_compact' : '');
    }
    get productsDropZoneText() {
        return this.productsRows.length > 0
            ? `${this.productsRowCount} rows loaded — drop or paste (Ctrl+V) to add / update products`
            : 'Drop Products XLSX or CSV here, or paste with Ctrl+V';
    }
    get hasProductsCreatedRecords() { return this.productsCreatedRecords && this.productsCreatedRecords.length > 0; }

    // ── Pre-existing products (Salesforce terms not yet reflected in productsRows) ─────────────

    // Only the ones not already represented in productsRows — once a matching row is there
    // (whether the user's own file or a prior click of this same link), it drops off this list,
    // and once the list is empty the link disappears.
    get preExistingProductsToLoad() {
        if (this.existingTermsFromServer.length === 0) return [];
        const loadedIds = new Set(this.productsRows.map(r => r['DMT_RiskLineTermId__c']).filter(Boolean));
        return this.existingTermsFromServer.filter(t => !loadedIds.has(t.DMT_RiskLineTermId__c));
    }
    get showPreExistingProductsLink()  { return this.preExistingProductsToLoad.length > 0; }
    get preExistingProductsLinkLabel() {
        const n = this.preExistingProductsToLoad.length;
        return `${n} pre-existing product${n === 1 ? '' : 's'} found for ${n === 1 ? 'this line' : 'these lines'} — click to load`;
    }

    loadPreExistingProducts() {
        const toLoad = this.preExistingProductsToLoad;
        if (toLoad.length === 0) return;
        const sfRows = toLoad.map(t => ({ ...this._sfTermToRow(t), __status: 'Existing', __preloaded: true }));
        const merged = this._mergeTermRows(this.productsRows, sfRows);
        this.productsRows      = merged;
        this.productsRowCount  = merged.length;
        this.productsPreloaded = true;
        if (this.productsState === 'idle') this.productsState = 'ready';
        this._buildPreview(merged, this._termPreviewHeaders(PRODUCTS_HEADERS), 'products');
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
    get showUpdateLineStatus()      { return this.step2Enabled && !this.productsIsProcessing; }

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
        // Only rows already persisted in Salesforce count — 'New'/'Will Update' are still just
        // parsed from the file and have not been submitted (Create / Update Products not clicked
        // yet, or still in flight), and 'Failed' means the submission did not actually save. Counting
        // those would tell the user a line is covered when the server still sees no term at all.
        const PERSISTED_PRODUCT_STATUSES = new Set(['No Changes', 'Existing', 'Created', 'Updated']);
        return this.importedLineIds
            .map(lineId => this.linesRows.find(r => r['Line_Id__c'] === lineId))
            .filter(Boolean)
            .filter(line => {
                const code = line['g_line_status_type__c'];
                if (!code || code === 'DR') return false; // stays Draft — no gate applies

                const productsTotal = this.productsRows
                    .filter(p => p['Line_Id__c'] === line['Line_Id__c'] && PERSISTED_PRODUCT_STATUSES.has(p.__status))
                    .reduce((sum, p) => sum + (parseFloat(p['DMT_Risk_Line_Term__c DMT_Amount__c']) || 0), 0);

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

    openProductsFilePicker() {
        this.template.querySelector('input[data-section="products"]').click();
    }

    handleFileInputChange(event) {
        const file    = event.target.files[0];
        const section = event.target.dataset.section;
        if (file) this._processFile(file, section);
        event.target.value = '';
    }

    // ── Drag and drop ─────────────────────────────────────────────────────────

    handleDragOver(event) {
        event.preventDefault();
        const section = this._sectionFromEvent(event);
        if (section === 'lines')    this.linesDragging    = true;
        if (section === 'products') this.productsDragging = true;
    }

    handleDragLeave(event) {
        const section = this._sectionFromEvent(event);
        if (section === 'lines')    this.linesDragging    = false;
        if (section === 'products') this.productsDragging = false;
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

    handleProductsFileDrop(event) {
        event.preventDefault();
        this.productsDragging = false;
        const file = event.dataTransfer.files[0];
        if (file) this._processFile(file, 'products');
    }

    // ── After products complete: allow uploading another CATEGORIAS file ───────

    resetProductsForMore() {
        this.productsCreatedRecords = null;
        this.productsResultErrors   = [];
        this.productsPreloaded      = false;
        // productsRows was trimmed to failed-only rows in _handleProgressEvent;
        // if empty, start fresh; if has failures, pre-load them for retry
        if (this.productsRows.length > 0) {
            this.productsState    = 'ready';
            this.productsRowCount = this.productsRows.length;
            this._buildPreview(this.productsRows, this._termPreviewHeaders(PRODUCTS_HEADERS), 'products');
        } else {
            this.productsState          = 'idle';
            this.productsRowCount       = 0;
            this.productsPreviewColumns = [];
            this.productsPreviewRows    = [];
            this.productsFileName       = '';
        }
    }

    // ── Start Over ────────────────────────────────────────────────────────────

    get hasAnyData() { return this.linesRows.length > 0 || this.productsRows.length > 0; }

    resetAll() {
        this._unsubscribe(this.linesSubscription);
        this._unsubscribe(this.productsSubscription);
        this.linesSubscription    = null;
        this.productsSubscription = null;

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
        this.existingTermsFromServer = [];

        this.productsState            = 'idle';
        this.productsFileName         = '';
        this.productsRowCount         = 0;
        this.productsRows             = [];
        this.productsValidationErrors = [];
        this.productsPreviewColumns   = [];
        this.productsPreviewRows      = [];
        this.productsResultErrors     = [];
        this.productsSuccessCount     = 0;
        this.productsErrorCount       = 0;
        this.productsPreloaded        = false;

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
        this.existingTermsFromServer = [];

        // If Step 2 was pre-loaded from this lines file, clear it too
        if (this.productsPreloaded) {
            this.productsState            = 'idle';
            this.productsFileName         = '';
            this.productsRowCount         = 0;
            this.productsRows             = [];
            this.productsValidationErrors = [];
            this.productsPreviewColumns   = [];
            this.productsPreviewRows      = [];
            this.productsPreloaded        = false;
        }
    }

    clearProductsFile() {
        this.productsState            = 'idle';
        this.productsFileName         = '';
        this.productsRowCount         = 0;
        this.productsRows             = [];
        this.productsValidationErrors = [];
        this.productsPreviewColumns   = [];
        this.productsPreviewRows      = [];
    }

    // ── Clipboard paste (Ctrl+V) ──────────────────────────────────────────────

    _processPastedText(text) {
        const lines = text.split(/\r?\n/).filter(l => l.trim());
        if (lines.length < 2) return;

        // Detect delimiter: tab (Excel/Sheets), pipe (our format), or comma (exported CSV)
        const delimiter = lines[0].includes('\t') ? '\t' : lines[0].includes('|') ? '|' : ',';

        const headers = lines[0].split(delimiter).map(h => h.trim());
        const rows = lines.slice(1).map((line, idx) => {
            const values = line.split(delimiter);
            const row = { __rowIndex: idx + 2 };
            headers.forEach((h, i) => { row[h] = (values[i] !== undefined ? String(values[i]).trim() : ''); });
            return row;
        });

        // Bail silently if content doesn't look like a Salesforce data file at all
        const headerSet = new Set(headers);
        if (!headers.some(h => h.includes('__c') || h === 'gf_cutoff_date')) return;

        // Route by header fingerprint: gf_cutoff_date = lines file; g_amortization_type__c = products file
        let section;
        if (headerSet.has('gf_cutoff_date'))              section = 'lines';
        else if (headerSet.has('g_amortization_type__c')) section = 'products';
        if (!section) return;

        this._onRowsParsed(rows, 'Clipboard', section);
    }

    // ── File parsing ──────────────────────────────────────────────────────────

    _processFile(file, section) {
        const ext = file.name.split('.').pop().toLowerCase();
        if (!['csv', 'xlsx', 'xls'].includes(ext)) {
            this._setValidationErrors(section, [{ key: 'ext', message: `File type .${ext} is not supported. Use CSV, XLSX or XLS.` }]);
            return;
        }

        const reader = new FileReader();

        if (ext === 'csv') {
            reader.onload = e => {
                const rows = this._parseCSV(e.target.result);
                this._onRowsParsed(rows, file.name, section);
            };
            reader.readAsText(file);
        } else {
            if (!this.sheetJsLoaded) {
                this._setValidationErrors(section, [{ key: 'sheetjs', message: 'SheetJS library is still loading. Try again in a moment.' }]);
                return;
            }
            reader.onload = e => {
                const rows = this._parseXLSX(e.target.result);
                this._onRowsParsed(rows, file.name, section);
            };
            reader.readAsArrayBuffer(file);
        }
    }

    _parseCSV(text) {
        const lines = text.split(/\r?\n/).filter(l => l.trim());
        if (lines.length < 2) return [];
        const firstLine = lines[0];
        const delimiter = firstLine.includes('\t') ? '\t' : firstLine.includes('|') ? '|' : ',';
        const headers = firstLine.split(delimiter).map(h => h.trim());
        return lines.slice(1).map((line, idx) => {
            const values = line.split(delimiter);
            const row = { __rowIndex: idx + 2 };
            headers.forEach((h, i) => { row[h] = (values[i] || '').trim(); });
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

    _onRowsParsed(rows, fileName, section) {
        const expectedHeaders = section === 'lines' ? LINES_HEADERS  : PRODUCTS_HEADERS;
        const requiredFields  = section === 'lines' ? LINES_REQUIRED : PRODUCTS_REQUIRED;

        if (section === 'lines') {
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
        } else {
            // Duplicate DMT_RiskLineTermId__c detection — remove ALL occurrences and toast
            const termIdRows = {};
            rows.forEach(r => {
                const id = r['DMT_RiskLineTermId__c'];
                if (id) (termIdRows[id] = termIdRows[id] || []).push(r.__rowIndex);
            });
            const termDupes = Object.entries(termIdRows).filter(([, rns]) => rns.length > 1);
            if (termDupes.length > 0) {
                const msg = termDupes.map(([id, rns]) => `${id} (rows ${rns.join(', ')})`).join(' | ');
                this._toast('Duplicate Term IDs detected', `Each Term ID must appear only once. Removed: ${msg}`, 'error');
                const dupeSet = new Set(termDupes.map(([id]) => id));
                rows = rows.filter(r => !dupeSet.has(r['DMT_RiskLineTermId__c']));
            }
            // For any Line_Id__c not in the lines table, extract the line data from the products
            // row itself (the products file contains all line fields) and add it to the lines table
            const knownLineIds = new Set(this.linesRows.map(r => r['Line_Id__c']).filter(Boolean));
            const newLinesSeen = new Set();
            const newLineRows  = [];
            rows.forEach(r => {
                const id = r['Line_Id__c'];
                if (!id || knownLineIds.has(id) || newLinesSeen.has(id)) return;
                newLinesSeen.add(id);
                const lineRow = { __rowIndex: r.__rowIndex };
                LINES_HEADERS.forEach(h => { lineRow[h] = r[h] || ''; });
                newLineRows.push(lineRow);
            });
            if (newLineRows.length > 0) {
                const mergedLines = this._mergeLineRows(this.linesRows, newLineRows);
                this.linesRows             = mergedLines;
                this.linesRowCount         = mergedLines.length;
                this.pendingTermsFromLines = this._extractTermRows(mergedLines);
                if (this.linesState === 'idle') {
                    this.linesFileName = fileName;
                    this.linesState    = 'ready';
                }
                this._buildPreview(mergedLines, this._linePreviewHeaders(LINES_HEADERS), 'lines');
                this._enrichLinesPreview(mergedLines);
            }
            // Tag product status before merging
            const existingTermIds = new Set(this.productsRows.map(r => r['DMT_RiskLineTermId__c']).filter(Boolean));
            rows = rows.map(r => ({
                ...r,
                __status: existingTermIds.has(r['DMT_RiskLineTermId__c']) ? 'Will Update' : 'New'
            }));
            // Incoming file rows override existing rows for same term ID
            const merged           = this._mergeTermRowsUpdate(this.productsRows, rows);
            this.productsFileName  = fileName;
            this.productsRowCount  = merged.length;
            this.productsRows      = merged;
        }

        const errors = this._validate(
            section === 'lines' ? this.linesRows : this.productsRows,
            expectedHeaders, requiredFields
        );

        if (errors.length > 0) {
            this._setValidationErrors(section, errors);
        } else {
            this._setValidationErrors(section, []);
            const previewHeaders = section === 'lines'
                ? this._linePreviewHeaders(expectedHeaders)
                : this._termPreviewHeaders(expectedHeaders);
            const previewRows = section === 'lines' ? this.linesRows : this.productsRows;
            this._buildPreview(previewRows, previewHeaders, section);
            if (section === 'lines') {
                this.linesState = 'ready';
                this._enrichLinesPreview(this.linesRows);
            }
            if (section === 'products') {
                this.productsState = 'ready';
                this._enrichProductsPreview(this.productsRows);
            }
        }
    }

    // ── Validation ────────────────────────────────────────────────────────────

    _validate(rows, expectedHeaders, requiredFields) {
        const errors = [];

        if (!rows || rows.length === 0) {
            errors.push({ key: 'empty', message: 'The file contains no data rows.' });
            return errors;
        }

        const actualHeaders = Object.keys(rows[0]).filter(k => k !== '__rowIndex');
        const missing = expectedHeaders.filter(h => !actualHeaders.includes(h));
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

    _setValidationErrors(section, errors) {
        if (section === 'lines') {
            this.linesValidationErrors = errors;
            this.linesState = errors.length > 0 ? 'error' : this.linesState;
        } else {
            this.productsValidationErrors = errors;
            this.productsState = errors.length > 0 ? 'error' : this.productsState;
        }
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

        if (section === 'lines') {
            this.linesPreviewColumns = columns;
            this.linesPreviewRows    = tableRows;
        } else {
            this.productsPreviewColumns = columns;
            this.productsPreviewRows    = tableRows;
        }
    }

    _safeKey(str) {
        return str.replace(/\s+/g, '_');
    }

    _isTermCol(col) {
        return TERM_COLS.has(col) || col.startsWith('DMT_Risk_Line_Term__c ');
    }

    _linePreviewHeaders(headers) {
        const cols = headers.filter(h => !this._isTermCol(h));
        return ['Line_Id__c', ...cols.filter(h => h !== 'Line_Id__c')];
    }

    _termPreviewHeaders(headers) {
        const cols = headers.filter(h => this._isTermCol(h) && h !== 'DMT_RiskLineTermId__c');
        return ['Line_Id__c', 'DMT_RiskLineTermId__c', ...cols];
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

    _mergeTermRows(existing, incoming) {
        // Existing wins — used when CSV rows take precedence over SF-loaded rows
        const seen = new Set(existing.map(r => r['DMT_RiskLineTermId__c']).filter(Boolean));
        const toAdd = incoming.filter(r => {
            const id = r['DMT_RiskLineTermId__c'];
            return !id || !seen.has(id);
        });
        return [...existing, ...toAdd];
    }

    _mergeTermRowsUpdate(existing, incoming) {
        // Incoming wins — used when a manually uploaded file should override existing rows
        const incomingIds  = new Set(incoming.map(r => r['DMT_RiskLineTermId__c']).filter(Boolean));
        const keepExisting = existing.filter(r => !incomingIds.has(r['DMT_RiskLineTermId__c']));
        return [...incoming, ...keepExisting];
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
        } else {
            this.productsRows = this.productsRows.map(r => {
                if (r.__status === 'No Changes' || r.__status === 'Existing') return r;
                if (failedIds.has(r['DMT_RiskLineTermId__c'])) return { ...r, __status: 'Failed' };
                return { ...r, __status: r.__status === 'New' ? 'Created' : 'Updated' };
            });
            if (!this.productsPreviewColumns.some(c => c.fieldName === '__status')) {
                this.productsPreviewColumns = [
                    { label: 'Status', fieldName: '__status', type: 'text', initialWidth: 100, wrapText: false },
                    ...this.productsPreviewColumns
                ];
            }
            const statusMap = new Map(this.productsRows.map(r => [r['DMT_RiskLineTermId__c'], r.__status]));
            this.productsPreviewRows = this.productsPreviewRows.map(row => ({
                ...row, __status: statusMap.get(row['DMT_RiskLineTermId__c']) || row.__status || ''
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
            const [existingLines, existingTerms] = await Promise.all([
                getExistingLinesApex({ lineIds }),
                getExistingTermsForLinesApex({ lineIds })
            ]);
            // Guard: user may have cleared or resubmitted the file while we were loading
            if (this.linesState !== 'ready') return;
            this._applyLineEnrichment(rows, existingLines);
            this._loadExistingTermsToStep2(existingTerms);
        } catch (e) {
            // CIBGLOBALD-4157 - a failed enrichment call used to leave every row's __status
            // unset, which made _buildPreview's `rows.some(r => r.__status)` gate drop the
            // whole Status column rather than just the values in it. Falling back to 'Unknown'
            // keeps the column (and the rest of the table) visible and tells the user plainly
            // that the New/Update/No Changes comparison against Salesforce could not be made.
            console.error('enrichment query failed', e);
            this.linesRows = this.linesRows.map(r => ({ ...r, __status: r.__status || 'Unknown' }));
            this._buildPreview(this.linesRows, this._linePreviewHeaders(LINES_HEADERS), 'lines');
            this._toast(
                'Could not check existing Salesforce data',
                'The New / Will Update / No Changes status could not be determined for these lines. You can still proceed, but double-check for duplicates yourself.',
                'warning'
            );
        }
    }

    /**
     * Products-drop counterpart to _enrichLinesPreview: the synchronous tagging done inline in
     * _onRowsParsed (New / Will Update, based only on whether the term ID is already sitting in
     * the client-side table) is just a first guess for immediate feedback - it never checks
     * Salesforce, so a term dropped into an empty table always reads "New" even when it already
     * exists, and one that happens to already be on screen reads "Will Update" even when nothing
     * about it actually changed. This corrects both, the same way _enrichLinesPreview corrects
     * lines: queries the real records and re-tags via field comparison (_hasTermChanges).
     */
    async _enrichProductsPreview(rows) {
        const lineIds = [...new Set(rows.map(r => r['Line_Id__c']).filter(Boolean))];
        if (lineIds.length === 0) return;
        try {
            const existingTerms = await getExistingTermsForLinesApex({ lineIds });
            // Guard: user may have cleared or resubmitted while this was loading
            if (this.productsState !== 'ready') return;
            const sfMap     = new Map((existingTerms || []).map(t => [t.DMT_RiskLineTermId__c, t]));
            const lineIdSet = new Set(lineIds);
            this.productsRows = this.productsRows.map(row => {
                // Rows from another line batch not covered by this fetch, or already tagged
                // 'Existing' by a preload source (not a file drop), are left untouched.
                if (row.__preloaded || !lineIdSet.has(row['Line_Id__c'])) return row;
                const sfTerm = sfMap.get(row['DMT_RiskLineTermId__c']);
                let status;
                if (!sfTerm)                                status = 'New';
                else if (this._hasTermChanges(row, sfTerm)) status = 'Will Update';
                else                                        status = 'No Changes';
                return { ...row, __status: status };
            });
            this._buildPreview(this.productsRows, this._termPreviewHeaders(PRODUCTS_HEADERS), 'products');
        } catch (e) {
            // CIBGLOBALD-4157 - same fallback as _enrichLinesPreview's catch: keep whatever
            // provisional status _onRowsParsed already guessed (New / Will Update) rather than
            // losing it, and only default to 'Unknown' for rows that have none yet, so the
            // Status column stays visible instead of disappearing entirely.
            console.error('products enrichment query failed', e);
            this.productsRows = this.productsRows.map(r => ({ ...r, __status: r.__status || 'Unknown' }));
            this._buildPreview(this.productsRows, this._termPreviewHeaders(PRODUCTS_HEADERS), 'products');
            this._toast(
                'Could not check existing Salesforce data',
                'The New / Will Update / No Changes status could not be determined for these products. You can still proceed, but double-check for duplicates yourself.',
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
                // Backfill empty CSV cells with existing SF values
                if (!enriched['Name']                    && sf.Name)                    enriched['Name']                    = sf.Name;
                if (!enriched['Booking_Geography__c']    && sf.Booking_Geography__c)    enriched['Booking_Geography__c']    = sf.Booking_Geography__c;
                if (!enriched['Client_Code__c']          && sf.Client_Code__c)          enriched['Client_Code__c']          = sf.Client_Code__c;
                if (!enriched['Client__c']               && sf.Client__r)               enriched['Client__c']               = sf.Client__r.Name;
                if (!enriched['Start_Date__c']           && sf.Start_Date__c)           enriched['Start_Date__c']           = String(sf.Start_Date__c).substring(0, 10);
                if (!enriched['End_Date__c']             && sf.End_Date__c)             enriched['End_Date__c']             = String(sf.End_Date__c).substring(0, 10);
                if (!enriched['DMT_LastLevelId__c']      && sf.DMT_LastLevelId__c)      enriched['DMT_LastLevelId__c']      = sf.DMT_LastLevelId__c;
                if (!enriched['CurrencyIsoCode']         && sf.CurrencyIsoCode)         enriched['CurrencyIsoCode']         = sf.CurrencyIsoCode;
                if (!enriched['DMT_Comments__c']         && sf.DMT_Comments__c)         enriched['DMT_Comments__c']         = sf.DMT_Comments__c;
                if (!enriched['Breakclause_Frequency__c']&& sf.Breakclause_Frequency__c) enriched['Breakclause_Frequency__c'] = sf.Breakclause_Frequency__c;
                if (!enriched['g_line_status_type__c']   && sf.g_line_status_type__c)   enriched['g_line_status_type__c']   = sf.g_line_status_type__c;
                if (!enriched['Status__c']               && sf.Status__c)               enriched['Status__c']               = sf.Status__c;

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

        // Update linesRows with backfilled values so submission uses them
        this.linesRows = enrichedRows;

        // Rebuild preview: Line_Id__c is a URL column (clickable) when SF records exist, plain text otherwise.
        // lightning-datatable URL type renders nothing when the URL field is null, so we only use it
        // when at least one row already exists in SF (ensuring the label is always visible).
        const previewHeaders  = this._linePreviewHeaders(LINES_HEADERS);
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

    _hasLineChanges(csvRow, sf) {
        const sfDate = v => v ? String(v).substring(0, 10) : '';
        const sfStr  = v => v != null ? String(v) : '';
        const csv    = v => String(v || '').trim();
        // Status__c: DMT_BulkImportBatch.buildLine treats a blank CSV value as "no opinion" -
        // new lines default to Draft, existing ones keep whatever they already have - it is
        // never overwritten to blank. Comparing it literally would flag every line as
        // "Will Update" forever whenever the file (like this org's real import files) never
        // carries a Status__c column value at all, even though nothing would actually change.
        const csvStatus     = csv(csvRow['Status__c']);
        const statusChanged = csvStatus !== '' && csvStatus !== sfStr(sf.Status__c);
        return (
            csv(csvRow['Name'])                     !== sfStr(sf.Name)                     ||
            csv(csvRow['Booking_Geography__c'])      !== sfStr(sf.Booking_Geography__c)     ||
            csv(csvRow['Client_Code__c'])            !== sfStr(sf.Client_Code__c)           ||
            csv(csvRow['Start_Date__c'])             !== sfDate(sf.Start_Date__c)           ||
            csv(csvRow['End_Date__c'])               !== sfDate(sf.End_Date__c)             ||
            csv(csvRow['DMT_LastLevelId__c'])        !== sfStr(sf.DMT_LastLevelId__c)       ||
            csv(csvRow['CurrencyIsoCode'])           !== sfStr(sf.CurrencyIsoCode)          ||
            csv(csvRow['DMT_Comments__c'])           !== sfStr(sf.DMT_Comments__c)          ||
            csv(csvRow['Breakclause_Frequency__c'])  !== sfStr(sf.Breakclause_Frequency__c) ||
            csv(csvRow['g_line_status_type__c'])     !== sfStr(sf.g_line_status_type__c)    ||
            statusChanged
        );
    }

    _hasTermChanges(csvRow, sfTerm) {
        const sfDate  = v => v ? String(v).substring(0, 10) : '';
        const sfStr   = v => v != null ? String(v) : '';
        const sfBool  = v => v ? '1' : '0';
        const csv     = v => String(v || '').trim();
        // Amount comparison: normalize to float to avoid "5000000.00" !== "5000000" false positives
        const csvAmt  = v => { const s = csv(v); return s === '' ? null : parseFloat(s); };
        // Unlike every other field here, this one was compared against sfTerm.DMT_Amount__c
        // directly with no null/undefined normalizer - when the field is genuinely blank on both
        // sides, Salesforce can hand back undefined rather than null for it (the same reason
        // _sfTermToRow reads it via a truthy check, not != null), so a strict null !== undefined
        // falsely flagged a real "No Changes" row as "Will Update".
        const sfAmt   = v => (v === null || v === undefined) ? null : v;
        return (
            csv(csvRow['DMT_Risk_Line_Term__c DMT_Init_Term__c']) !== sfDate(sfTerm.DMT_Init_Term__c)                ||
            csv(csvRow['DMT_Risk_Line_Term__c DMT_End_Term__c'])  !== sfDate(sfTerm.DMT_End_Term__c)                 ||
            csvAmt(csvRow['DMT_Risk_Line_Term__c DMT_Amount__c']) !== sfAmt(sfTerm.DMT_Amount__c)                    ||
            csv(csvRow['g_global_product_family_id__c'])           !== sfStr(sfTerm.g_global_product_family_id__c)   ||
            csv(csvRow['g_global_product_subfamily_id__c'])        !== sfStr(sfTerm.g_global_product_subfamily_id__c)||
            csv(csvRow['g_global_product_category_id__c'])         !== sfStr(sfTerm.g_global_product_category_id__c) ||
            csv(csvRow['g_gbl_product_subcategory_id__c'])         !== sfStr(sfTerm.g_gbl_product_subcategory_id__c) ||
            csv(csvRow['g_global_product_id__c'])                  !== sfStr(sfTerm.g_global_product_id__c)          ||
            csv(csvRow['g_multioperation_ind_type__c'])            !== sfBool(sfTerm.g_multioperation_ind_type__c)   ||
            csv(csvRow['g_expert_criteria_risk_type__c'])          !== sfStr(sfTerm.g_expert_criteria_risk_type__c)  ||
            csv(csvRow['g_amortization_type__c'])                  !== sfStr(sfTerm.g_amortization_type__c)          ||
            csv(csvRow['gf_payment_frequency__c'])                 !== sfStr(sfTerm.gf_payment_frequency__c)         ||
            csv(csvRow['gf_group_priority_line_id__c'])            !== sfStr(sfTerm.gf_group_priority_line_id__c)    ||
            csv(csvRow['gf_inscol_months_grace_number__c'])        !== sfStr(sfTerm.gf_inscol_months_grace_number__c)
        );
    }

    _loadExistingTermsToStep2(existingTerms) {
        // Keep the raw fetch regardless of what follows, so a link can offer these later even when
        // the Lines file didn't embed term columns (the early-return below).
        this.existingTermsFromServer = existingTerms || [];
        if (this.pendingTermsFromLines.length === 0) return;
        const sfMap  = new Map((existingTerms || []).map(t => [t.DMT_RiskLineTermId__c, t]));
        // SF terms get "Existing" status; they are the current DB values
        const sfRows = (existingTerms || []).map(t => ({ ...this._sfTermToRow(t), __status: 'Existing', __preloaded: true }));
        // CSV terms: compare field-by-field against SF to determine status (all "New" if no SF terms).
        // __preloaded: these came from columns embedded in the Lines file, not a Products file drop.
        const csvTagged = this.pendingTermsFromLines.map(t => {
            const sfTerm = sfMap.get(t['DMT_RiskLineTermId__c']);
            let status;
            if (!sfTerm)                              status = 'New';
            else if (this._hasTermChanges(t, sfTerm)) status = 'Will Update';
            else                                      status = 'No Changes';
            return { ...t, __status: status, __preloaded: true };
        });
        // CSV takes precedence; SF fills in for lines not covered by CSV
        const merged = this._mergeTermRows(csvTagged, sfRows);
        if (merged.length === 0) return;
        this.productsRows      = merged;
        this.productsRowCount  = merged.length;
        this.productsPreloaded = true;
        this.productsState     = 'ready';
        this._buildPreview(merged, this._termPreviewHeaders(LINES_HEADERS), 'products');
    }

    _sfTermToRow(term) {
        const lineId = term.DMT_Line__r ? term.DMT_Line__r.Line_Id__c : '';
        return {
            '__rowIndex'                             : 0,
            'Line_Id__c'                             : lineId,
            'DMT_RiskLineTermId__c'                  : term.DMT_RiskLineTermId__c || '',
            'DMT_Risk_Line_Term__c DMT_Init_Term__c' : term.DMT_Init_Term__c  ? String(term.DMT_Init_Term__c)  : '',
            'DMT_Risk_Line_Term__c DMT_End_Term__c'  : term.DMT_End_Term__c   ? String(term.DMT_End_Term__c)   : '',
            'DMT_Risk_Line_Term__c DMT_Amount__c'    : term.DMT_Amount__c     ? String(term.DMT_Amount__c)     : '',
            'CurrencyIsoCode'                        : term.CurrencyIsoCode   || '',
            'DMT_LastLevelId__c'                     : term.DMT_LastLevelId__c || '',
            'owner User id_user__c'                  : term.DMT_ID_User__c    || '',
            'g_global_product_family_id__c'          : term.g_global_product_family_id__c    || '',
            'g_global_product_subfamily_id__c'       : term.g_global_product_subfamily_id__c || '',
            'g_global_product_category_id__c'        : term.g_global_product_category_id__c  || '',
            'g_gbl_product_subcategory_id__c'        : term.g_gbl_product_subcategory_id__c  || '',
            'g_global_product_id__c'                 : term.g_global_product_id__c           || '',
            'g_multioperation_ind_type__c'           : term.g_multioperation_ind_type__c ? '1' : '0',
            'g_expert_criteria_risk_type__c'         : term.g_expert_criteria_risk_type__c   || '',
            'g_amortization_type__c'                 : term.g_amortization_type__c           || '',
            'gf_payment_frequency__c'                : term.gf_payment_frequency__c          || '',
            'gf_group_priority_line_id__c'           : term.gf_group_priority_line_id__c     || '',
            'gf_inscol_months_grace_number__c'       : term.gf_inscol_months_grace_number__c != null ? String(term.gf_inscol_months_grace_number__c) : '',
            'Booking_Geography__c'                   : '',
            'Client_Code__c'                         : '',
            'Client__c'                              : '',
            'g_group_id'                             : '',
            'End_Date__c'                            : '',
            'Start_Date__c'                          : '',
            'g_risk_level_clsfn_type__c'             : '',
            'DMT_Parent_Line__c'                     : '',
            'DMT_Comments__c'                        : '',
            'Createbydate'                           : '',
            'Breakclause_Frequency__c'               : '',
            'gf_priority_line_id__c'                 : '',
            'Name'                                   : '',
            'g_line_status_type__c'                  : '',
            'Status__c'                              : ''
        };
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

    submitProducts() {
        // Skip rows that don't need DML
        const payload = this.productsRows
            .filter(r => r.__status !== 'No Changes' && r.__status !== 'Existing')
            .map(r => this._cleanRow(r));
        if (payload.length === 0) return;

        this.productsState     = 'submitting';
        this.productsJobId     = this._newJobId();
        this.productsProcessed = 0;
        this.productsTotal     = payload.length;

        this._subscribeProgress(this.productsJobId, 'products');

        submitProductsApex({ rowsJson: JSON.stringify(payload), jobId: this.productsJobId })
            .then(() => { this.productsState = 'processing'; })
            .catch(e => {
                console.error('submitProducts error', e);
                this.productsState = 'idle';
                this._unsubscribe(this.productsSubscription);
            });
    }

    // ── Platform Events ───────────────────────────────────────────────────────

    _subscribeProgress(jobId, section) {
        subscribe(EVENT_CHANNEL, -1, event => {
            this._handleProgressEvent(event, jobId, section);
        }).then(sub => {
            if (section === 'lines')    this.linesSubscription    = sub;
            if (section === 'products') this.productsSubscription = sub;
        });
    }

    _handleProgressEvent(event, expectedJobId, section) {
        const payload = event.data.payload;
        if (payload.Job_Id__c !== expectedJobId) return;

        const processed = payload.Processed__c || 0;
        const total     = payload.Total__c || 0;
        const success   = payload.Success_Count__c || 0;
        const errors    = payload.Error_Count__c || 0;
        const status    = payload.Status__c;
        const errJson   = payload.Errors_JSON__c || '[]';

        if (section === 'lines') {
            this.linesProcessed    = processed;
            this.linesTotal        = total;
            this.linesSuccessCount = success;
            this.linesErrorCount   = errors;
        } else {
            this.productsProcessed    = processed;
            this.productsTotal        = total;
            this.productsSuccessCount = success;
            this.productsErrorCount   = errors;
        }

        if (status === 'COMPLETED' || status === 'FAILED') {
            let resultErrors = [];
            try { resultErrors = JSON.parse(errJson); } catch (e) {}

            if (section === 'lines') {
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

                // Add any pending terms not yet in the products table (e.g. for newly created lines).
                // productsRows wins — it carries the enriched status; pendingTermsFromLines only fills gaps.
                const pendingTagged = this.pendingTermsFromLines.map(t => ({ ...t, __status: t.__status || 'New', __preloaded: true }));
                const merged = this._mergeTermRows(this.productsRows, pendingTagged);
                if (merged.length > this.productsRows.length) {
                    // Only update if new rows were actually added — don't touch enriched table otherwise
                    this.productsRows      = merged;
                    this.productsRowCount  = merged.length;
                    this.productsPreloaded = true;
                    if (this.productsState === 'idle') this.productsState = 'ready';
                    this._buildPreview(merged, this._termPreviewHeaders(LINES_HEADERS), 'products');
                }

            } else {
                this.productsResultErrors = resultErrors;
                this.productsState        = 'done';
                this._unsubscribe(this.productsSubscription);

                const failedTermIds = new Set(resultErrors.map(e => e.id).filter(Boolean));

                // Update the Status column in the existing preview table — don't replace it
                this._updateSubmissionStatuses('products', failedTermIds);
            }
        }
    }

    // ── Error log download ────────────────────────────────────────────────────

    downloadLinesErrorLog() {
        this._downloadCSV(this.linesResultErrors, 'lines_errors.csv',
            ['Row', 'Line_Id__c', 'Name', 'Error'],
            e => [e.row, e.id, e.label, e.message]);
    }

    downloadProductsErrorLog() {
        this._downloadCSV(this.productsResultErrors, 'products_errors.csv',
            ['Row', 'Term_Id__c', 'Line_Id__c', 'Error'],
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

    _sectionFromEvent(event) {
        const target = event.currentTarget;
        if (target && target.classList.contains('drop-zone')) {
            const cards = this.template.querySelectorAll('.slds-card');
            if (cards[0] && cards[0].contains(target)) return 'lines';
            if (cards[1] && cards[1].contains(target)) return 'products';
        }
        return null;
    }
}