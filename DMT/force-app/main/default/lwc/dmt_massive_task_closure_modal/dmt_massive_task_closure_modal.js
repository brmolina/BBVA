import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTasksForMassiveClosure from '@salesforce/apex/DMT_Massive_Task_Closure_Controller.getTasksForMassiveClosure';
import confirmMassiveClosure from '@salesforce/apex/DMT_Massive_Task_Closure_Controller.confirmMassiveClosure';
import getDocuments from '@salesforce/apex/DMT_CoreDocuments_Controller.getDocuments';
import getDownloadEndpoint from '@salesforce/apex/DMT_CoreDocuments_Controller.getDownloadEndpoint';
import getDownloadHeaders from '@salesforce/apex/DMT_CoreDocuments_Controller.getDownloadHeaders';
import getUploadConfig from '@salesforce/apex/DMT_CoreDocuments_Controller.getUploadConfig';
import updateFileMetadataWithObjectCode from '@salesforce/apex/DMT_CoreDocuments_Controller.updateFileMetadataWithObjectCode';

export default class Dmt_massive_task_closure_modal extends LightningElement {
    @api selectedKeys;
    @api closeForReview = false;
    @track closureData = [];
    @track bulkResult = '';
    @track bulkComment = '';
        @track bulkApproverLabel = '';
    @track columnWidths = ['28%', '18%', '22%', '18%', '14%'];
    @track globalResultOptions = [];
    hasGlobalWarning = false;
    @track isLoading = false;
    @track errorMessage = '';
    openDropdownTaskId = null;
    openFilesCaseId = null;
    openBulkResultDropdown = false;
    openBulkCommentEditor = false;
    openBulkApproverLabelEditor = false;
    dropdownTop = 0;
    dropdownLeft = 0;
    dropdownWidth = 0;
    filesDropdownTop = 0;
    filesDropdownLeft = 0;

    sortBy = 'task';
    sortDirection = 'asc';
    isResizingColumn = false;
    resizingColumnIndex;
    resizeStartX = 0;
    resizeStartWidths = [];
    resizingRightColumnIndex;
    minColumnWidths = [140, 120, 180, 140, 90];
    downloadHeadersPromise;
    isFileOpening = false;
    openingFileName = '';
    isFileUploading = false;
    uploadingCaseId = null;
    uploadingFileName = '';
    selectedUploadCaseId = null;
    snapshotsInProgress = false;
    showSnapshotWorkerPreview = false;
    viewPreloadInProgress = false;
    viewPreloadCompleted = false;
    viewPreloadFailed = false;
    viewPreloadMessage = 'Case views are not generated yet.';
    pendingFocusBulkComment = false;
    pendingFocusBulkApproverLabel = false;
    pendingFocusTaskCommentId = null;
    _viewPreloadStarted = false;
    _viewPreloadPromise = null;

    constructor() {
        super();
        this.boundHandleColumnResize = this.handleColumnResize.bind(this);
        this.boundHandleResizeEnd = this.handleResizeEnd.bind(this);
        this.boundCloseAllDropdowns = this.closeAllDropdowns.bind(this);
    }

    connectedCallback() {
        if (this.selectedKeys) {
            this.loadTasks();
        }
        globalThis.addEventListener('click', this.boundCloseAllDropdowns);
    }

    disconnectedCallback() {
        globalThis.removeEventListener('mousemove', this.boundHandleColumnResize);
        globalThis.removeEventListener('mouseup', this.boundHandleResizeEnd);
        globalThis.removeEventListener('click', this.boundCloseAllDropdowns);
    }

    get isCloseForReviewMode() {
        return this.closeForReview === true || this.closeForReview === 'true';
    }

    get reviewBlockedCount() {
        return this.closureData.filter(row => row.reviewBlocked === true).length;
    }

    get reviewEligibleCount() {
        return this.closureData.filter(row => row.reviewBlocked !== true).length;
    }

    get displayedClosureData() {
        if (!this.isCloseForReviewMode) {
            return this.closureData;
        }
        return this.closureData.filter(row => row.reviewBlocked !== true);
    }

    get modalTitle() {
        return this.isCloseForReviewMode ? 'Close for review' : 'Close the approval';
    }

    get confirmButtonLabel() {
        if (!this.isCloseForReviewMode) {
            return 'Close the approval';
        }
        return `Close for review (${this.reviewEligibleCount}/${this.closureData.length})`;
    }


    get isConfirmDisabled() {
        return this.isLoading || this.snapshotsInProgress || this.viewPreloadInProgress;
    }

    get tableColumns() {
        return [
            { key: 'task', label: 'Task', sortIcon: this.getSortIcon('task'), isResizable: true },
            { key: 'result', label: 'Result', sortIcon: this.getSortIcon('result'), isResizable: true },
            { key: 'comments', label: 'Comments', sortIcon: this.getSortIcon('comments'), isResizable: true },
            { key: 'approverLabel', label: 'Approver Label', sortIcon: this.getSortIcon('approverLabel'), isResizable: true },
            { key: 'files', label: 'Files', sortIcon: this.getSortIcon('files'), isResizable: false }
        ];
    }


    renderedCallback() {
        this.applyColumnWidths();
        this.applyPendingTextareaFocus();
    }

    applyPendingTextareaFocus() {
        if (this.pendingFocusBulkComment) {
            const bulkCommentTextarea = this.template.querySelector('.bulk-comment-popover textarea.native-comment-textarea');
            if (bulkCommentTextarea) {
                bulkCommentTextarea.focus();
                const valueLength = (bulkCommentTextarea.value || '').length;
                bulkCommentTextarea.setSelectionRange(valueLength, valueLength);
                this.pendingFocusBulkComment = false;
            }
        }

        if (this.pendingFocusBulkApproverLabel) {
            const approverInput = this.template.querySelector('.bulk-approver-label-popover input.native-approver-input');
            if (approverInput) {
                approverInput.focus();
                const valueLength = (approverInput.value || '').length;
                approverInput.setSelectionRange(valueLength, valueLength);
                this.pendingFocusBulkApproverLabel = false;
            }
        }

        if (this.pendingFocusTaskCommentId) {
            const taskId = this.pendingFocusTaskCommentId;
            const rowCommentTextarea = this.template.querySelector(`.row-comment-popover textarea.native-comment-textarea[data-id="${taskId}"]`);
            if (rowCommentTextarea) {
                rowCommentTextarea.focus();
                const valueLength = (rowCommentTextarea.value || '').length;
                rowCommentTextarea.setSelectionRange(valueLength, valueLength);
                this.pendingFocusTaskCommentId = null;
            }
        }
    }


    get snapshotPreviewButtonLabel() {
        return this.showSnapshotWorkerPreview ? 'Hide generated view' : 'Show generated view';
    }

    get snapshotStatusClass() {
        if (this.viewPreloadFailed) {
            return 'snapshot-status snapshot-status_error';
        }
        if (this.viewPreloadCompleted) {
            return 'snapshot-status snapshot-status_success';
        }
        if (this.viewPreloadInProgress) {
            return 'snapshot-status snapshot-status_progress';
        }
        return 'snapshot-status';
    }

    toggleSnapshotWorkerPreview() {
        this.showSnapshotWorkerPreview = !this.showSnapshotWorkerPreview;
    }

    getSnapshotWorker() {
        return this.template.querySelector('c-dmt_massive_snapshot_worker');
    }

    async waitForSnapshotWorker(timeoutMs = 5000) {
        const startedAt = Date.now();
        let worker = this.getSnapshotWorker();

        while (!worker && Date.now() - startedAt < timeoutMs) {
            await new Promise(resolve => setTimeout(resolve, 100));
            worker = this.getSnapshotWorker();
        }

        if (!worker) {
            throw new Error('Snapshot worker is not rendered yet.');
        }

        return worker;
    }

    scheduleViewPreload() {
        if (this._viewPreloadStarted) {
            return;
        }

        this._viewPreloadStarted = true;
        setTimeout(() => {
            this.preloadViewsForCurrentRows().catch(error => {
                this.viewPreloadInProgress = false;
                this.viewPreloadCompleted = false;
                this.viewPreloadFailed = true;
                this.viewPreloadMessage = error?.message || 'Could not generate one or more case views.';
                console.error('[MASSIVE MODAL] Initial view preload failed', error);
            });
        }, 0);
    }

    async preloadViewsForCurrentRows() {
        const rowsToPrepare = this.isCloseForReviewMode
            ? this.displayedClosureData
            : this.closureData;

        const caseIds = this.getUniqueCaseIdsFromRows(rowsToPrepare);
        if (caseIds.length === 0) {
            this.viewPreloadMessage = 'No Case views to generate.';
            this.viewPreloadCompleted = true;
            return;
        }

        return this.preloadCaseViews(caseIds);
    }

    async ensureViewsReadyForPayloads(payloads) {
        const caseIds = this.getUniqueCaseIdsFromPayloads(payloads);
        if (caseIds.length === 0) {
            return;
        }

        const worker = await this.waitForSnapshotWorker();

        const missingCaseIds = [];
        for (const caseId of caseIds) {
            // hasCachedView is exposed by c-dmt_massive_snapshot_worker.
            if (!worker.hasCachedView(caseId)) {
                missingCaseIds.push(caseId);
            }
        }

        if (missingCaseIds.length > 0) {
            await this.preloadCaseViews(missingCaseIds);
        }
    }

    async preloadCaseViews(caseIds) {
        if (this._viewPreloadPromise) {
            return this._viewPreloadPromise;
        }

        this._viewPreloadPromise = this.doPreloadCaseViews(caseIds);
        try {
            return await this._viewPreloadPromise;
        } finally {
            this._viewPreloadPromise = null;
        }
    }

    async doPreloadCaseViews(caseIds) {
        const worker = await this.waitForSnapshotWorker();

        this.viewPreloadInProgress = true;
        this.viewPreloadCompleted = false;
        this.viewPreloadFailed = false;

        let generated = 0;
        const total = caseIds.length;

        for (const caseId of caseIds) {
            generated++;
            this.viewPreloadMessage = `Generating case view ${generated}/${total}: ${caseId}`;

            await worker.generateView({
                caseId,
                timeoutMs: 90000
            });
        }

        this.viewPreloadInProgress = false;
        this.viewPreloadCompleted = true;
        this.viewPreloadFailed = false;
        this.viewPreloadMessage = `Generated ${total} case view(s). Ready to close approvals.`;
    }

    getUniqueCaseIdsFromRows(rows) {
        return [...new Set(
            (rows || [])
                .map(row => row?.caseId ? String(row.caseId) : null)
                .filter(caseId => !!caseId)
        )];
    }

    getUniqueCaseIdsFromPayloads(payloads) {
        return [...new Set(
            (payloads || [])
                .map(payload => payload?.caseId ? String(payload.caseId) : null)
                .filter(caseId => !!caseId)
        )];
    }

    getRelatedRecordNameForCase(caseId) {
        const row = this.closureData.find(item => String(item.caseId) === String(caseId));
        return row?.client || row?.taskName || 'Task';
    }

    loadTasks() {
        getTasksForMassiveClosure({ selectionKeys: this.selectedKeys })
            .then(result => {
                this.globalResultOptions = [
                    { label: 'Yes', value: 'Yes' },
                    { label: 'No', value: 'No' },
                    { label: 'N/A', value: 'N/A' }
                ];

                let enhancedData = result.map(item => {
                    let taskAllowedOptions = [];
                    let allowedValues = new Set();
                    let inClosingTasks = false;

                    let yesF = item.yesFlag || 'Yes';
                    let noF = item.noFlag || 'No';
                    let naF = item.naFlag || 'N/A';

                    try {
                        const closingTasks = JSON.parse(item.closingTasksJson || '[]');
                        const config = closingTasks.find(ct => String(ct.id) === String(item.externalId));

                        if (config) {
                            inClosingTasks = true;
                            if (config.yesFlag) yesF = config.yesFlag;
                            if (config.noFlag) noF = config.noFlag;
                            if (config.naFlag) naF = config.naFlag;
                        }
                    } catch (e) {
                         console.error('Error parsing closingTasksJson', e);
                    }

                    if (inClosingTasks) {
                        allowedValues.add('Yes');
                        allowedValues.add('No');
                        allowedValues.add('N/A');
                    } else {
                        // Si no aparece, solo debe dejar cerrar con la opción de No
                        allowedValues.add('No');
                    }

                    // Siempre mostramos las 3 opciones genéricas en el dropdown
                    taskAllowedOptions = [
                        { label: 'Yes', value: 'Yes' },
                        { label: 'No', value: 'No' },
                        { label: 'N/A', value: 'N/A' }
                    ];

                    // Derivar genericResult a partir del valor previo (si existe)
                    let gResult = '';
                    if (item.result === yesF) gResult = 'Yes';
                    else if (item.result === noF) gResult = 'No';
                    else if (item.result === naF) gResult = 'N/A';

                    let initialWarning = false;
                    let invalidGeneric = null;

                    // Si ya viene de base de datos con un valor que ahora vemos que NO está permitido
                    if (gResult && !allowedValues.has(gResult)) {
                        initialWarning = true;
                        invalidGeneric = gResult;
                        gResult = '';
                    }

                    const defaultGenericResult = this.isCloseForReviewMode ? 'No' : gResult;
                    const reviewBlocked = this.isCloseForReviewMode && item.returnToProposalDisabled === true;
                    const hasWarning = this.isCloseForReviewMode ? reviewBlocked : initialWarning;

                    return {
                        ...item,
                        genericResult: defaultGenericResult,
                        invalidGenericResult: this.isCloseForReviewMode ? null : invalidGeneric,
                        resultDisplay: '',
                        badgeClass: 'slds-badge',
                        comments: '',
                        caseUrl: '/' + item.caseId,
                        lineOppId: item.lineOppId || '',
                        client: item.client || '',
                        committeeLabel: item.committeeLabel || '',
                        fileCount: item.fileCount || 0,
                        filesLabel: `${item.fileCount || 0} attached file(s)`,
                        files: item.files || [],
                        allowedOptions: taskAllowedOptions,
                        allowedValuesSet: allowedValues,
                        yesLabel: yesF,
                        noLabel: noF,
                        naLabel: naF,
                        reviewBlocked,
                        hasWarning,
                        rowClass: '',
                        dropdownClass: 'slds-dropdown-trigger slds-dropdown-trigger_click',
                        isEditingComment: false
                    };
                });

                this.closureData = this.sortRows(enhancedData.map(item => this.updateRowVisuals(item)));
                this.checkGlobalWarningState();

                if (this.isCloseForReviewMode && this.reviewEligibleCount === 0) {
                    this.errorMessage = 'None of the selected tasks are available to be closed for review.';
                    this.showToast('No eligible tasks', this.errorMessage, 'warning');
                }

                this.loadFilesForRows();
                this.scheduleViewPreload();
            })
            .catch(error => console.error('Error loading tasks:', error));
    }

    async loadFilesForRows() {
        const updatedRows = await Promise.all(
            this.closureData.map(async row => {
                const fileData = await this.fetchTaskFiles(row.caseId);
                return {
                    ...row,
                    fileCount: fileData.count,
                    filesLabel: `${fileData.count} attached file(s)`,
                    files: fileData.files
                };
            })
        );

        this.closureData = this.sortRows(updatedRows);
    }

    async fetchTaskFiles(caseId) {
        if (!caseId) {
            return { count: 0, files: [] };
        }

        try {
            const response = await getDocuments({ folderCode: caseId });
            const files = [];

            if (response?.success && Array.isArray(response.data)) {
                response.data.forEach(folder => {
                    if (Array.isArray(folder.children)) {
                        folder.children.forEach(child => {
                            files.push({
                                id: child.id,
                                name: child.objectName || child.name || 'File',
                                contentLocator: child.contentLocator,
                                documentType: child.documentType,
                                createdDate: child.createdDate || null
                            });
                        });
                    }
                });
            }

            return { count: files.length, files };
        } catch (error) {
            console.error(`[CORE DOCS] Error fetching documents for case ${caseId}:`, error);
            return { count: 0, files: [] };
        }
    }

    updateRowVisuals(row) {
        row.rowClass = row.hasWarning ? 'row-warning-highlight' : '';
        row.dropdownClass = 'slds-dropdown-trigger slds-dropdown-trigger_click';
        row.badgeClass = 'slds-badge';
        row.warningTitle = row.reviewBlocked === true
            ? 'Task cannot be closed for review with current conditions'
            : 'Value not allowed for this task';

        // Mostrar el valor inválido si lo hay, si no el consolidado
        let valToDisplay = row.hasWarning && row.invalidGenericResult ? row.invalidGenericResult : row.genericResult;

        let displayStr = '';
        if (valToDisplay === 'Yes') displayStr = row.yesLabel;
        else if (valToDisplay === 'No') displayStr = row.noLabel;
        else if (valToDisplay === 'N/A') displayStr = row.naLabel;

        row.resultDisplay = displayStr;

        if (valToDisplay === 'Yes') {
            row.badgeClass = 'square-badge badge-success';
        } else if (valToDisplay === 'No') {
            row.badgeClass = 'square-badge badge-error';
        } else if (valToDisplay === 'N/A') {
            row.badgeClass = 'square-badge badge-na';
        } else {
            row.badgeClass = 'square-badge';
        }

        return row;
    }

    handleBulkResultChange(event) { this.bulkResult = event.detail.value; }
    handleBulkCommentChange(event) {
        this.bulkComment = event.detail?.value ?? event.target?.value ?? '';
    }

    handleToggleBulkApproverLabelEditor(event) {
        event.stopPropagation();
        this.openBulkApproverLabelEditor = !this.openBulkApproverLabelEditor;
        this.pendingFocusBulkApproverLabel = this.openBulkApproverLabelEditor;
    }

    handleBulkApproverLabelEditorClick(event) {
        event.stopPropagation();
    }

    handleBulkApproverLabelChange(event) {
        this.bulkApproverLabel = event.target?.value ?? '';
    }

    handleToggleBulkCommentEditor(event) {
        event.stopPropagation();
        this.openBulkCommentEditor = !this.openBulkCommentEditor;
        this.pendingFocusBulkComment = this.openBulkCommentEditor;
    }

    handleBulkCommentEditorClick(event) {
        event.stopPropagation();
    }

    get bulkResultDisplay() {
        return this.bulkResult;
    }

    get bulkResultBadgeClass() {
        if (this.bulkResult === 'Yes') {
            return 'square-badge badge-success';
        }
        if (this.bulkResult === 'No') {
            return 'square-badge badge-error';
        }
        if (this.bulkResult === 'N/A') {
            return 'square-badge badge-na';
        }
        return 'square-badge';
    }

    handleToggleBulkResultDropdown(event) {
        if (this.isCloseForReviewMode) {
            return;
        }
        event.stopPropagation();
        this.openBulkResultDropdown = !this.openBulkResultDropdown;
    }

    handleBulkResultDropdownPanelClick(event) {
        event.stopPropagation();
    }

    handleBulkResultSelect(event) {
        event.stopPropagation();
        this.bulkResult = event.currentTarget.dataset.value;
        this.openBulkResultDropdown = false;
    }

    applyBulkChanges() {
        this.closureData = this.sortRows(this.closureData.map(item => {
            let appliedGeneric = item.genericResult;
            let invalidGeneric = item.invalidGenericResult;
            let warning = item.reviewBlocked === true;

            if (!this.isCloseForReviewMode && this.bulkResult) {
                const isAllowed = item.allowedValuesSet.has(this.bulkResult);
                if (isAllowed) {
                    appliedGeneric = this.bulkResult;
                    invalidGeneric = null;
                    warning = false;
                } else {
                    warning = true;
                    invalidGeneric = this.bulkResult;
                    appliedGeneric = '';
                }
            }

            const newRow = {
                ...item,
                genericResult: appliedGeneric,
                invalidGenericResult: invalidGeneric,
                comments: this.bulkComment || item.comments,
                committeeLabel: this.bulkApproverLabel || item.committeeLabel,
                hasWarning: warning,
                isEditingComment: false
            };

            return this.updateRowVisuals(newRow);
        }));

        this.checkGlobalWarningState();
        this.bulkResult = '';
        this.bulkComment = '';
        this.bulkApproverLabel = '';
        this.openBulkResultDropdown = false;
        this.openBulkCommentEditor = false;
        this.openBulkApproverLabelEditor = false;
    }

    get openDropdownRow() {
        if (!this.openDropdownTaskId) return null;
        const row = this.closureData.find(r => r.taskId === this.openDropdownTaskId);
        if (!row) return null;

        // Clonamos el objeto para no modificar la fila original directamente
        const rowClone = { ...row };

        // Si tiene warning, filtramos las opciones para que solo aparezca "No"
        if (rowClone.hasWarning) {
            rowClone.allowedOptions = rowClone.allowedOptions.filter(opt => opt.value === 'No');
        }

        rowClone.allowedOptions = rowClone.allowedOptions.map(opt => {
            let displayLabel = opt.value;
            let badgeClass = 'square-badge';

            if (opt.value === 'Yes') {
                badgeClass = 'square-badge badge-success';
            } else if (opt.value === 'No') {
                badgeClass = 'square-badge badge-error';
            } else if (opt.value === 'N/A') {
                badgeClass = 'square-badge badge-na';
            }

            return {
                ...opt,
                displayLabel,
                badgeClass
            };
        });

        return rowClone;
    }

    get openFilesRow() {
        if (!this.openFilesCaseId) return null;
        return this.closureData.find(r => r.caseId === this.openFilesCaseId) || null;
    }

    get dropdownStyle() {
        return `top: ${this.dropdownTop}px; left: ${this.dropdownLeft}px; width: ${this.dropdownWidth}px;`;
    }

    get filesDropdownStyle() {
        return `top: ${this.filesDropdownTop}px; left: ${this.filesDropdownLeft}px;`;
    }

    handleToggleDropdown(event) {
        if (this.isCloseForReviewMode) {
            return;
        }
        event.stopPropagation();
        const taskId = event.currentTarget.dataset.id;

        if (this.openDropdownTaskId === taskId) {
            this.openDropdownTaskId = null;
            return;
        }

        // Usamos directamente el botón (currentTarget) para medir el contenedor completo de la celda
        const anchor = event.currentTarget;
        const rect = anchor.getBoundingClientRect();

        const container = this.template.querySelector('.slds-modal__container');
        const containerRect = container ? container.getBoundingClientRect() : { top: 0, left: 0 };

        this.dropdownTop = (rect.bottom - containerRect.top) + 2;
        // Quitamos el -16 para que se alinee perfectamente con el borde izquierdo del botón
        this.dropdownLeft = rect.left - containerRect.left;
        // Capturamos el ancho exacto que tiene el botón en pantalla
        this.dropdownWidth = rect.width;

        this.openDropdownTaskId = taskId;
    }

    closeAllDropdowns() {
        if (this.openBulkCommentEditor) {
            const bulkCommentTextarea = this.template.querySelector('.bulk-comment-popover textarea.native-comment-textarea');
            if (bulkCommentTextarea) {
                this.bulkComment = bulkCommentTextarea.value || '';
            }
        }

        if (this.openBulkApproverLabelEditor) {
            const approverInput = this.template.querySelector('.bulk-approver-label-popover input.native-approver-input');
            if (approverInput) {
                this.bulkApproverLabel = approverInput.value || '';
            }
        }

        this.pendingFocusBulkComment = false;
        this.pendingFocusBulkApproverLabel = false;
        this.pendingFocusTaskCommentId = null;

        this.openDropdownTaskId = null;
        this.openFilesCaseId = null;
        this.openBulkResultDropdown = false;
        this.openBulkCommentEditor = false;
        this.openBulkApproverLabelEditor = false;

        if (this.closureData.some(row => row.isEditingComment || row.isEditingApproverLabel)) {
            this.closureData = this.closureData.map(row => ({
                ...row,
                isEditingComment: false,
                isEditingApproverLabel: false
            }));
        }
    }

    handleDropdownPanelClick(event) {
        event.stopPropagation();
    }

    handleToggleFilesDropdown(event) {
        event.stopPropagation();
        const caseId = event.currentTarget.dataset.id;

        if (this.openFilesCaseId === caseId) {
            this.openFilesCaseId = null;
            return;
        }

        const rect = event.currentTarget.getBoundingClientRect();

        // 1. Obtenemos las coordenadas del contenedor modal para ajustar el desfase
        const container = this.template.querySelector('.slds-modal__container');
        const containerRect = container ? container.getBoundingClientRect() : { top: 0, left: 0 };

        // 2. Calculamos top y left restando el offset del modal
        this.filesDropdownTop = (rect.bottom - containerRect.top) + 10;

        // 3. Alineamos el centro de la flecha (26px) con el centro del icono
        this.filesDropdownLeft = (rect.left - containerRect.left) + (rect.width / 2) - 26;

        this.openFilesCaseId = caseId;
    }

    handleFilesDropdownPanelClick(event) {
        event.stopPropagation();
    }

    get isUploadBusy() {
        return this.isFileUploading;
    }

    isRowUploading(caseId) {
        return this.isFileUploading && String(this.uploadingCaseId) === String(caseId);
    }

    async handleRowUploadClick(event) {
        event.stopPropagation();

        if (this.isUploadBusy) {
            return;
        }

        const caseId = event.currentTarget.dataset.id;
        if (!caseId) {
            this.showToast('Error', 'Case identifier is missing for upload.', 'error');
            return;
        }

        this.selectedUploadCaseId = String(caseId);
        const fileInput = this.template.querySelector('.hidden-row-file-input');
        if (fileInput) {
            fileInput.value = null;
            fileInput.click();
        }
    }

    async handleRowFileSelected(event) {
        const file = event.target?.files?.[0];
        const caseId = this.selectedUploadCaseId;

        event.target.value = null;
        this.selectedUploadCaseId = null;

        if (!file || !caseId) {
            return;
        }

        this.isFileUploading = true;
        this.uploadingCaseId = caseId;
        this.uploadingFileName = file.name;
        this.setRowUploading(caseId, true);

        try {
            const finalFileName = this.formatFileNameWithDate(file.name);
            const fileId = await this.uploadFileToCoreDocuments(file, finalFileName, caseId);

            await updateFileMetadataWithObjectCode({
                fileId,
                fileName: finalFileName,
                docType: 'CO-OF-00241',
                folderId: caseId,
                objectCode: 'CO-OF-00241'
            });

            await this.refreshFilesForCase(caseId);
            this.showToast('Success', 'File uploaded successfully.', 'success');
        } catch (error) {
            const message = error?.body?.message || error?.message || 'File upload failed.';
            this.showToast('Error', message, 'error');
            console.error('[CORE DOCS] Individual upload failed:', error);
        } finally {
            this.isFileUploading = false;
            this.uploadingCaseId = null;
            this.uploadingFileName = '';
            this.setRowUploading(caseId, false);
        }
    }

    async uploadFileToCoreDocuments(file, newName, caseId) {
        const config = await getUploadConfig();
        const formData = new FormData();
        const renamedFile = new File([file], newName, { type: file.type });

        formData.append('file', renamedFile);
        formData.append('opportunityId', caseId);
        formData.append('folderId', caseId);
        formData.append('folderCode', caseId);

        const response = await fetch(config.endpoint, {
            method: 'POST',
            headers: config.headers,
            body: formData
        });

        if (!response.ok) {
            throw new Error(response.statusText || 'CoreDocuments upload request failed.');
        }

        const result = await response.json();
        if (result && result.data && result.data.fileId) {
            return result.data.fileId;
        }

        throw new Error('File ID not found in upload response.');
    }

    setRowUploading(caseId, uploading) {
        this.closureData = this.closureData.map(row =>
            String(row.caseId) === String(caseId) ? { ...row, isUploading: uploading } : row
        );
    }

    async refreshFilesForCase(caseId) {
        const fileData = await this.fetchTaskFiles(caseId);
        this.closureData = this.sortRows(this.closureData.map(row => {
            if (String(row.caseId) !== String(caseId)) {
                return row;
            }

            return {
                ...row,
                fileCount: fileData.count,
                filesLabel: `${fileData.count} attached file(s)`,
                files: fileData.files
            };
        }));
    }

    formatFileNameWithDate(originalName) {
        const now = new Date();
        const dateStamp = `${now.getDate()}-${now.getMonth() + 1}-${now.getFullYear()}`;
        const lastDotIndex = originalName.lastIndexOf('.');
        let baseName = lastDotIndex !== -1 ? originalName.substring(0, lastDotIndex) : originalName;
        const extension = lastDotIndex !== -1 ? originalName.substring(lastDotIndex) : '';
        baseName = baseName.split('__')[0].trim();
        return `${baseName}__${dateStamp}__Massive-Closure${extension}`;
    }

    getDownloadHeadersCached() {
        if (!this.downloadHeadersPromise) {
            this.downloadHeadersPromise = getDownloadHeaders();
        }
        return this.downloadHeadersPromise;
    }

    async handleOpenFileInNewTab(event) {
        event.stopPropagation();

        if (this.isFileOpening) {
            return;
        }

        const contentLocator = event.currentTarget.dataset.locator;
        const fileName = event.currentTarget.dataset.name;

        if (!contentLocator) {
            return;
        }

        this.isFileOpening = true;
        this.openingFileName = fileName || 'file';

        try {
            const endpoint = await getDownloadEndpoint({ contentLocator });
            const headers = await this.getDownloadHeadersCached();

            const response = await fetch(endpoint, {
                method: 'GET',
                headers
            });

            if (!response.ok) {
                throw new Error(`HTTP Error ${response.status}: ${response.statusText}`);
            }

            const blob = await response.blob();
            const blobUrl = URL.createObjectURL(blob);

            const openedTab = window.open(blobUrl, '_blank');

            if (!openedTab) {
                const fallbackLink = document.createElement('a');
                fallbackLink.href = blobUrl;
                fallbackLink.target = '_blank';
                fallbackLink.rel = 'noopener noreferrer';
                document.body.appendChild(fallbackLink);
                fallbackLink.click();
                fallbackLink.remove();
            }

            setTimeout(() => URL.revokeObjectURL(blobUrl), 60000);
        } catch (error) {
            console.error('[CORE DOCS] Error opening file in new tab:', error);
        } finally {
            this.isFileOpening = false;
            this.openingFileName = '';
        }
    }

    handleDropdownSelect(event) {
        if (this.isCloseForReviewMode) {
            return;
        }
        event.stopPropagation();
        const taskId = event.currentTarget.dataset.id;
        const newValue = event.currentTarget.dataset.value;
        this.openDropdownTaskId = null;
        const rowIndex = this.closureData.findIndex(row => row.taskId === taskId);

        if (rowIndex !== -1) {
            const currentRow = this.closureData[rowIndex];
            const isAllowed = currentRow.allowedValuesSet.has(newValue);
            let updatedRow = {
                ...currentRow,
                genericResult: isAllowed ? newValue : '',
                invalidGenericResult: isAllowed ? null : newValue,
                hasWarning: !isAllowed
            };
            updatedRow = this.updateRowVisuals(updatedRow);
            this.closureData = [...this.closureData.slice(0, rowIndex), updatedRow, ...this.closureData.slice(rowIndex + 1)];
        }
        this.checkGlobalWarningState();
    }

    handleRowResultChange(event) {
        if (this.isCloseForReviewMode) {
            return;
        }
        // kept for compatibility – actual selection now goes through handleDropdownSelect
        const taskId = event.currentTarget.dataset.id;
        const newValue = event.detail.value;
        const rowIndex = this.closureData.findIndex(row => row.taskId === taskId);

        if (rowIndex !== -1) {
            let updatedRow = { ...this.closureData[rowIndex], genericResult: newValue, invalidGenericResult: null, hasWarning: false };
            updatedRow = this.updateRowVisuals(updatedRow);
            this.closureData = [...this.closureData.slice(0, rowIndex), updatedRow, ...this.closureData.slice(rowIndex + 1)];
        }
        this.checkGlobalWarningState();
    }

    handleEditComment(event) {
        event.stopPropagation();
        const taskId = event.currentTarget.dataset.id;
        const rowIndex = this.closureData.findIndex(row => row.taskId === taskId);
        if (rowIndex !== -1) {
            this.pendingFocusTaskCommentId = taskId;
            this.closureData = this.closureData.map(row => ({
                ...row,
                isEditingComment: row.taskId === taskId
            }));
        }
    }

    handleRowCommentEditorClick(event) {
        event.stopPropagation();
    }

    handleRowCommentChange(event) {
        const taskId = event.currentTarget.dataset.id;
        const newValue = event.detail?.value ?? event.target?.value ?? '';
        const rowIndex = this.closureData.findIndex(row => row.taskId === taskId);

        if (rowIndex !== -1) {
            const updatedRow = { ...this.closureData[rowIndex], comments: newValue };
            this.closureData = [...this.closureData.slice(0, rowIndex), updatedRow, ...this.closureData.slice(rowIndex + 1)];
        }
    }

    handleApproverLabelChange(event) {
        const taskId = event.currentTarget.dataset.id;
        const newValue = event.target?.value ?? '';
        const rowIndex = this.closureData.findIndex(row => row.taskId === taskId);

        if (rowIndex !== -1) {
            const updatedRow = { ...this.closureData[rowIndex], committeeLabel: newValue };
            this.closureData = [...this.closureData.slice(0, rowIndex), updatedRow, ...this.closureData.slice(rowIndex + 1)];
        }
    }

    handleEditApproverLabel(event) {
        event.stopPropagation();
        const taskId = event.currentTarget.dataset.id;
        this.closureData = this.closureData.map(row => ({
            ...row,
            isEditingApproverLabel: row.taskId === taskId
        }));
    }

    handleRowApproverLabelEditorClick(event) {
        event.stopPropagation();
    }

    checkGlobalWarningState() {
        this.hasGlobalWarning = this.closureData.some(row => row.hasWarning);
    }

    handleSort(event) {
        const field = event.currentTarget.dataset.field;

        if (this.sortBy === field) {
            this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
        } else {
            this.sortBy = field;
            this.sortDirection = 'asc';
        }

        this.closureData = this.sortRows([...this.closureData]);
    }

    handleResizeStart(event) {
        event.preventDefault();
        event.stopPropagation();

        const index = Number(event.currentTarget.dataset.index);
        const rightIndex = index + 1;
        const headerCells = this.template.querySelectorAll('th[data-col-index]');

        if (Number.isNaN(index) || rightIndex >= this.columnWidths.length || !headerCells || headerCells.length === 0) {
            return;
        }

        this.isResizingColumn = true;
        this.resizingColumnIndex = index;
        this.resizingRightColumnIndex = rightIndex;
        this.resizeStartX = event.clientX;
        this.resizeStartWidths = Array.from(headerCells).map(cell => cell.offsetWidth);

        this.columnWidths = this.resizeStartWidths.map(width => `${width}px`);
        this.applyColumnWidths();

        globalThis.addEventListener('mousemove', this.boundHandleColumnResize);
        globalThis.addEventListener('mouseup', this.boundHandleResizeEnd);
    }

    handleColumnResize(event) {
        if (!this.isResizingColumn) { return; }

        const deltaX = event.clientX - this.resizeStartX;
        const leftIndex = this.resizingColumnIndex;
        const rightIndex = this.resizingRightColumnIndex;
        const leftStartWidth = this.resizeStartWidths[leftIndex];
        const rightStartWidth = this.resizeStartWidths[rightIndex];
        const leftMin = this.minColumnWidths[leftIndex] || 100;
        const rightMin = this.minColumnWidths[rightIndex] || 100;

        const minDelta = -(leftStartWidth - leftMin);
        const maxDelta = rightStartWidth - rightMin;
        const constrainedDelta = Math.min(maxDelta, Math.max(minDelta, deltaX));

        const leftNextWidth = leftStartWidth + constrainedDelta;
        const rightNextWidth = rightStartWidth - constrainedDelta;
        const nextWidths = this.resizeStartWidths.map(width => `${width}px`);

        nextWidths[leftIndex] = `${leftNextWidth}px`;
        nextWidths[rightIndex] = `${rightNextWidth}px`;
        this.columnWidths = nextWidths;
        this.applyColumnWidths();
    }

    handleResizeEnd() {
        this.isResizingColumn = false;
        this.resizingColumnIndex = undefined;
        this.resizingRightColumnIndex = undefined;
        this.resizeStartWidths = [];
        globalThis.removeEventListener('mousemove', this.boundHandleColumnResize);
        globalThis.removeEventListener('mouseup', this.boundHandleResizeEnd);
    }

    getSortIcon(field) {
        if (this.sortBy !== field) { return 'utility:dash'; }
        return this.sortDirection === 'asc' ? 'utility:arrowup' : 'utility:arrowdown';
    }

    sortRows(rows) {
        const direction = this.sortDirection === 'asc' ? 1 : -1;
        const keyByField = {
            task: row => `${row.taskName || ''} ${row.caseNumber || ''}`,
            result: row => row.resultDisplay || row.genericResult || '',
            comments: row => row.comments || '',
            files: row => this.getFilesCount(row)
        };

        const extractor = keyByField[this.sortBy] || keyByField.task;

        return [...rows].sort((left, right) => {
            const leftValue = extractor(left);
            const rightValue = extractor(right);

            if (this.sortBy === 'files') {
                return (leftValue - rightValue) * direction;
            }

            return String(leftValue).localeCompare(String(rightValue), undefined, { sensitivity: 'base' }) * direction;
        });
    }

    getFilesCount(row) {
        if (row.fileCount !== undefined && row.fileCount !== null) { return Number(row.fileCount) || 0; }
        if (row.filesCount !== undefined && row.filesCount !== null) { return Number(row.filesCount) || 0; }
        if (Array.isArray(row.files)) { return row.files.length; }
        return 0;
    }

    applyColumnWidths() {
        const headerCells = this.template.querySelectorAll('th[data-col-index]');
        if (!headerCells || headerCells.length === 0) { return; }
        headerCells.forEach(headerCell => {
            const index = Number(headerCell.dataset.colIndex);
            if (!Number.isNaN(index) && this.columnWidths[index]) {
                headerCell.style.width = this.columnWidths[index];
            }
        });
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    showToast(title, message, variant = 'info') {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }

    showWarningMessage(title, message) {
        this.errorMessage = message;
        this.showToast(title, message, 'warning');
        const modalContent = this.template.querySelector('.slds-modal__content');
        if (modalContent) {
            modalContent.scrollTop = 0;
        }
    }


    async handleConfirmAll() {
        if (this.isLoading || this.snapshotsInProgress) {
            return;
        }

        const rowsToProcess = this.isCloseForReviewMode
            ? this.displayedClosureData
            : this.closureData;

        if (this.isCloseForReviewMode && rowsToProcess.length === 0) {
            this.showWarningMessage(
                'No eligible tasks',
                'None of the selected tasks are available to be closed for review.'
            );
            return;
        }

        const missing = rowsToProcess.filter(row => !row.result && !row.genericResult);
        if (missing.length > 0) {
            this.showWarningMessage(
                'Missing data',
                `${missing.length} task(s) are missing a result. Please fill in all results before closing.`
            );
            return;
        }
        this.errorMessage = '';

        const payloads = rowsToProcess.map(row => {
            const genericResult = row?.genericResult || '';

            return {
                taskId: row?.taskId ? String(row.taskId) : null,
                caseId: row?.caseId ? String(row.caseId) : null,
                result: genericResult,
                comments: row?.comments || '',
                committeeLabel: row?.committeeLabel || '',
                updateToDraft: this.isCloseForReviewMode === true
            };
        }).filter(payload => payload.taskId);

        if (payloads.length === 0) {
            this.showWarningMessage('Missing data', 'No valid tasks were found to process.');
            return;
        }

        console.log('JACG payloads ' + JSON.stringify(payloads));

        this.isLoading = true;

        try {
            // Important: generate/cache every Case view BEFORE changing the approval state.
            await this.ensureViewsReadyForPayloads(payloads);

            const result = await confirmMassiveClosure({ payloadJson: JSON.stringify(payloads) });

            if (result?.success) {
                this.showToast('Success', 'Approvals closed successfully.', 'success');
                this.snapshotsInProgress = true;
                const summary = await this.runMassiveSnapshots(payloads);
                this.snapshotsInProgress = false;
                this.dispatchEvent(new CustomEvent('apply', { detail: summary }));
                this.closeModal();
            } else {
                this.errorMessage = (result && result.errorMessage)
                    ? result.errorMessage
                    : 'An unexpected error occurred during massive closure.';
                this.showToast('Error', this.errorMessage, 'error');
            }
        } catch (error) {
            this.snapshotsInProgress = false;
            this.errorMessage = error?.body?.message || error?.message || 'An unexpected error occurred during massive closure.';
            this.showToast('Error', this.errorMessage, 'error');
            console.error('[MASSIVE MODAL] Confirm all failed', error);
        } finally {
            this.isLoading = false;
        }
    }


    async runMassiveSnapshots(payloads) {
        let completed = 0;
        let failed = 0;
        const worker = await this.waitForSnapshotWorker();

        for (const payload of payloads) {
            try {
                const relatedRecordName = this.getRelatedRecordNameForCase(payload.caseId);
                await worker.saveSnapshot({
                    taskId: payload.taskId,
                    caseId: payload.caseId,
                    relatedRecordName
                });
                completed++;
            } catch (error) {
                console.error('[MASSIVE MODAL] Snapshot save failed', {
                    taskId: payload.taskId,
                    caseId: payload.caseId,
                    message: error?.message,
                    bodyMessage: error?.body?.message,
                    stack: error?.stack,
                    raw: error
                });
                failed++;
            }
        }

        return { completed, failed };
    }
}