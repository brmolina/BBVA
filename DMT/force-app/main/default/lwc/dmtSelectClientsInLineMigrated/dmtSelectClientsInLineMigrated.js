import { LightningElement, api, track } from 'lwc';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import loadDatasourceForMode from '@salesforce/apex/DMT_SelectClientsInLineService.loadDatasourceForMode';
import getAvailableClientsPage from '@salesforce/apex/DMT_SelectClientsInLineService.getAvailableClientsPage';
import getAvailableClientsPageForLine from '@salesforce/apex/DMT_SelectClientsInLineService.getAvailableClientsPageForLine';
import saveSelection from '@salesforce/apex/DMT_SelectClientsInLineService.saveSelection';
import saveGoldenSelection from '@salesforce/apex/DMT_SelectClientsInLineService.saveGoldenSelection';
import clearGoldenSelection from '@salesforce/apex/DMT_SelectClientsInLineService.clearGoldenSelection';
import deleteCustomAssociation from '@salesforce/apex/DMT_SelectClientsInLineService.deleteCustomAssociation';
// Changes been made for CIBGLOBALD-4763 - Import approval-state UI edit eligibility for clients.
import canEditLineInApprovalStateUi from '@salesforce/apex/DMT_LineController.canEditLineInApprovalStateUi';
import previewLineClientSave from '@salesforce/apex/DMT_SelectClientsInLineService.previewLineClientSave'; // CIBGLOBALD-4811
import LightningConfirm from 'lightning/confirm'; // CIBGLOBALD-4811
import pubsub from 'omnistudio/pubsub';

export default class DmtSelectClientsInLineMigrated extends LightningElement {
    _recordId;
    _lineStatus = '';
    _currency = '';
    _pendingViewMode = null;
    @api accountId;
    @api lineId;
    @api externallineId;
    @api booking;
    @api clientPosition = 'Y';
    @api selectedTab = 'tcm';
    @api returnedDate;
    @api priorselectedRows = [];
    @api selectedRows = [];

    @track availableClients = [];
    @track allAvailableClients = [];
    // Changes been made for CIBGLOBALD-4687
    @track availableClientsAccountId;
    @track searchText = '';
    @track isSaving = false;
    @track groupId;
    @track groupSfId;
    @track viewMode = 'multiholder'; // 'multiholder' | 'global'
    @track showModeChangeWarning = false;


    @track filterClients = 'Y';
    @track mainHolder = '';
    @track errorMainHolder = false;
    @track errorMessage = '';
    @track showLoading = false;
    @track isDirty = false;
    @track hasLoadedOnce = false;
    @track lineClientType = '';
    // Changes been made for CIBGLOBALD-4687
    @track lineAccountClientType = '';
    @track lineTemplateType = '';
    @track hasCustomAssociation = false;
    // Changes been made for CIBGLOBALD-4687
    @track savedGoldenCode = '';
    isIfiLine = false;
    @track isSelectionLocked = false;
    @track canEditByBusinessRule = true;
    @track showLineVersionsModal = false;

    // CIBGLOBALD-4344 - Tracks whether the user has deliberately picked a filter option, so the
    // With-Exposure-empty fallback only acts on the default/initial load, never overriding a
    // choice the user made themselves.
    _userManuallyChangedFilter = false;
    _hasAutoSwitchedExposure = false;

    baselineState = '';
    batchSize = 50;
    visibleRowLimit = 50;
    serverPageSize = 200;
    currentPage = 1;
    totalPages = 1;
    isFetchingPage = false;
    isFetchingAllForSearch = false;
    lastEditingState;
    hasEditSession = false;
    isApplyingDatasource = false;
    contextRefreshTimer;
    hasBoundLineVersionsReload = false;
    pubsubChannelLineTab = 'linestab';
    pubsubEventsLineTab = {
        refresh: this.handleLineTabRefresh.bind(this)
    };

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        const nextValue = value || null;
        const changed = this._recordId !== nextValue;
        this._recordId = nextValue;

        if (changed) {
            this.isIfiLine = false;
            this.savedGoldenCode = '';
            this._pendingViewMode = null;
            this.showModeChangeWarning = false;
            this.hasLoadedOnce = false;
            this.viewMode = 'multiholder';
            this.isSaving = false;
            this.isFetchingPage = false;
            this.isFetchingAllForSearch = false;
            this.isApplyingDatasource = false;
        }

        if (changed && this._recordId) {
            // CIBGLOBALD-4344 - A new Line context resets the With-Exposure-empty fallback so it
            // can re-arm for that line, even if the user had manually overridden it previously.
            this._userManuallyChangedFilter = false;
            this._hasAutoSwitchedExposure = false;
            this.loadDatasource();
        }
    }

    @api
    get lineStatus() {
        return this._lineStatus;
    }

    set lineStatus(value) {
        const nextValue = value || '';
        const changed = this._lineStatus !== nextValue;
        this._lineStatus = nextValue;
        this.handleExternalContextChange(changed);
    }

    @api
    get currency() {
        return this._currency;
    }

    set currency(value) {
        const nextValue = value || '';
        const changed = this._currency !== nextValue;
        this._currency = nextValue;
        this.handleExternalContextChange(changed);
    }

    connectedCallback() {
        if (this.recordId) {
            this.loadDatasource();
        }

        pubsub.register(this.pubsubChannelLineTab, this.pubsubEventsLineTab);
    }

    disconnectedCallback() {
        if (this.contextRefreshTimer) {
            clearTimeout(this.contextRefreshTimer);
            this.contextRefreshTimer = null;
        }

        pubsub.unregister(this.pubsubChannelLineTab, this.pubsubEventsLineTab);
    }

    renderedCallback() {
        if (!this.showLineVersionsModal || this.hasBoundLineVersionsReload) {
            return;
        }

        const lineVersionsCmp = this.template.querySelector('c-dmt_line-versions');
        if (!lineVersionsCmp) {
            return;
        }

        // Some emitters use reloadCard (camelCase), others use reloadcard (lowercase).
        lineVersionsCmp.addEventListener('reloadCard', this.handleLineVersionsReload.bind(this));
        lineVersionsCmp.addEventListener('reloadcard', this.handleLineVersionsReload.bind(this));
        this.hasBoundLineVersionsReload = true;
    }

    @api
    refreshLineContext(context = {}) {
        this._lineStatus = context.lineStatus ?? this._lineStatus;
        this._currency = context.currency ?? this._currency;

        if (!this.recordId || !this.hasLoadedOnce) {
            return;
        }

        this.queueDatasourceRefresh();
    }

    handleLineTabRefresh() {
        if (!this.recordId) {
            return;
        }

        this.queueDatasourceRefresh();
    }

    get filterOptions() {
        return [
            { label: 'Only selected clients', value: 'true' },
            { label: 'With Exposure', value: 'Y' },
            { label: 'With and Without Exposure', value: 'Y/N' }
        ];
    }

    get visibleClients() {
        const selectedById = new Map();
        for (const row of this.selectedRows) {
            selectedById.set(row.customerId, row);
        }

        const sourceRows = this.filterClients === 'true'
            ? this.mergeRowsForSelectedFilter(this.allAvailableClients, this.selectedRows)
            : this.allAvailableClients;

        const query = String(this.searchText || '').trim().toLowerCase();
        const filtered = sourceRows
            .filter((row) => {
                const selected = selectedById.has(row.customerId);
                if (this.filterClients === 'true' && !selected) {
                    return false;
                }

                if (this.viewMode === 'global' && !row.goldenCustomerId) {
                    return false;
                }    

                const geoMatch = this.matchesClientContext(row.customerId);
                if (!geoMatch) {
                    return false;
                }

                if (!query) {
                    return true;
                }

                const name = (row.customerName || '').toLowerCase();
                const id = (row.customerId || '').toLowerCase();
                const country = (row.countryIfoId || '').toLowerCase();
                const matchesBaseColumns = name.includes(query)
                    || id.includes(query)
                    || country.includes(query);

                if (matchesBaseColumns || !this.showOlOpServiceColumns) {
                    return matchesBaseColumns;
                }

                const scoring = String(row.totalRatingScoreNumber || '').toLowerCase();
                const leveragedLending = String(row.leveragedLendingIndType || '').toLowerCase();
                const assetAllocationSector = String(row.assetAllocationSectorType || '').toLowerCase();
                return scoring.includes(query)
                    || leveragedLending.includes(query)
                    || assetAllocationSector.includes(query);
            });

        // Changes been made for CIBGLOBALD-4687
        const rowsByGoldenCode = new Map();
        for (const row of filtered) {
            const goldenCode = this.normalizeGoldenCode(row.goldenCustomerId);
            const current = rowsByGoldenCode.get(goldenCode);
            if (!current || selectedById.has(row.customerId)) {
                rowsByGoldenCode.set(goldenCode, row);
            }
        }
        const rowsForMode = this.viewMode === 'global'
            ? [...rowsByGoldenCode.values()]
            : filtered;
        const rowsForDisplay = rowsForMode;
        const limited = query
            ? rowsForMode
            : rowsForDisplay.slice(0, this.visibleRowLimit);
        return limited
            .map((row) => {
                const selected = selectedById.get(row.customerId);
                const merged = selected
                    ? this.mergeServiceRowWithSelectedEditableFields(row, selected)
                    : { ...row };
                // Always prefer service identity data to avoid showing stale custom-association names.
                merged.customerName = row.customerName || merged.customerName || '';
                merged.isSelected = Boolean(selected);
                merged.isMainHolder = merged.customerId === this.mainHolder;
                merged.mainHolderDisabled = !this.canSelectClients;
                merged.mainHolderToggleClass = this.canSelectClients
                    ? 'main-holder-toggle'
                    : 'main-holder-toggle main-holder-toggle--disabled';
                merged.rowClass = merged.isSelected ? 'selected-row' : '';
                merged.disabled = !merged.isSelected || this.isSelectionReadOnlyByStatus;
                merged.displayCurrency = this.currency || merged.currency || '';
                return merged;
            });
    }

    get loadingMessage() {
        if (this.isSaving) {
            return 'Saving selected records, please wait...';
        }

        if (this.isFetchingAllForSearch) {
            return 'Searching across all records, please wait...';
        }

        if (this.showLoading) {
            return 'Loading information, please wait...';
        }

        return '';
    }

    get showSavingOverlay() {
        return this.isSaving;
    }

    get showGlobalLoadingOverlay() {
        return this.showLoading && !this.isSaving && !this.isFetchingPage;
    }

    get showTableLoadingOverlay() {
        return this.showLoading && !this.showGlobalLoadingOverlay && !this.isSaving;
    }

    get showInitialLoadingState() {
        return this.showLoading && !this.hasLoadedOnce;
    }

    get isTcm() {
        return this.selectedTab === 'tcm';
    }

    get isTcmCustomer() {
        return this.selectedTab === 'tcmcustomer';
    }

    get isTcmOtherLines() {
        return this.selectedTab === 'tcmotherlines';
    }

    get isTcmOpp() {
        return this.selectedTab === 'tcmopp';
    }

    get isTcmOppMitigants() {
        return this.selectedTab === 'tcmoppMitigants';
    }

    get isClosedLine() {
        return String(this.lineStatus || '').toLowerCase() === 'closed';
    }

    get shouldOpenClosedVersionsModal() {
        const normalizedStatus = String(this.lineStatus || '').trim().toLowerCase();
        return normalizedStatus === 'closed' || normalizedStatus === 'closed won';
    }

    get isSelectionReadOnlyByStatus() {
        return !this.canEditByBusinessRule;
    }

    get showStarCode() {
        return this.isTcm || this.isTcmCustomer;
    }

    get showMitigantContracts() {
        return this.isTcm || this.isTcmCustomer;
    }

    get mainToggleLabel() {
        return this.isTcm || this.isTcmCustomer ? 'Main Borrower' : 'Main Holder';
    }

    get showInternalRating() {
        return this.isTcm || this.isTcmCustomer || this.isTcmOtherLines || this.isTcmOpp || this.isTcmOppMitigants;
    }

    get showCurrentRatingDate() {
        return this.showInternalRating;
    }

    get showExpirationRatingDate() {
        return this.isTcm;
    }

    get showExternalRating() {
        return this.isTcmOpp || this.isTcmOppMitigants;
    }

    get showOlOpServiceColumns() {
        return this.isTcmOtherLines || this.isTcmOpp || this.isTcmOppMitigants;
    }

    get showEditableFinancialColumns() {
        return this.isTcm;
    }

    get termOptions() {
        return [
            { label: 'Select...', value: '' },
            { label: '0D', value: '0D' },
            { label: '2D', value: '2D' },
            { label: '3D', value: '3D' },
            { label: '4D', value: '4D' },
            { label: '7D', value: '7D' },
            { label: '10D', value: '10D' },
            { label: '15D', value: '15D' },
            { label: '20D', value: '20D' },
            { label: '1M', value: '1M' },
            { label: '45D', value: '45D' },
            { label: '2M', value: '2M' },
            { label: '3M', value: '3M' },
            { label: '4M', value: '4M' },
            { label: '5M', value: '5M' },
            { label: '6M', value: '6M' },
            { label: '9M', value: '9M' },
            { label: '1Y', value: '1Y' },
            { label: '18M', value: '18M' },
            { label: '2Y', value: '2Y' },
            { label: '3Y', value: '3Y' },
            { label: '4Y', value: '4Y' },
            { label: '5Y', value: '5Y' },
            { label: '6Y', value: '6Y' },
            { label: '7Y', value: '7Y' },
            { label: '8Y', value: '8Y' },
            { label: '9Y', value: '9Y' },
            { label: '10Y', value: '10Y' },
            { label: '11Y', value: '11Y' },
            { label: '12Y', value: '12Y' },
            { label: '13Y', value: '13Y' },
            { label: '14Y', value: '14Y' },
            { label: '15Y', value: '15Y' },
            { label: '16Y', value: '16Y' },
            { label: '17Y', value: '17Y' },
            { label: '18Y', value: '18Y' },
            { label: '19Y', value: '19Y' },
            { label: '20Y', value: '20Y' },
            { label: '21Y', value: '21Y' },
            { label: '22Y', value: '22Y' },
            { label: '25Y', value: '25Y' },
            { label: '27Y', value: '27Y' },
            { label: '30Y', value: '30Y' },
            { label: '32Y', value: '32Y' },
            { label: '35Y', value: '35Y' },
            { label: '37Y', value: '37Y' },
            { label: '40Y', value: '40Y' },
            { label: '42Y', value: '42Y' },
            { label: '45Y', value: '45Y' }
        ];
    }

    get tableLabelName() {
        return this.isTcmOppMitigants ? 'Guarantor Name' : 'Client Name';
    }

    get tableClass() {
        return this.isTcmOtherLines
            ? 'client-table client-table--compact'
            : 'client-table';
    }

    get isSaveDisabled() {
        return this.isSaving || this.isSelectionReadOnlyByStatus || !this.isDirty || this.selectedRows.length === 0;
    }

    get hasError() {
        return this.errorMessage !== '';
    }

    get hasVisibleClients() {
        return this.visibleClients.length > 0;
    }

    // Changes been made for CIBGLOBALD-4687
    get canSelectClients() {
        return this.hasLoadedOnce && !this.showLoading && !this.isSaving
            && (!this.isSelectionLocked || this.isGlobalMode) && !this.isSelectionReadOnlyByStatus;
    }

    get isClientSelectionDisabled() {
        return !this.canSelectClients;
    }

    get showNoClientsForGeography() {
        return !this.showLoading && !this.hasError && this.filterClients !== 'true' && this.allAvailableClients.length === 0;
    }

    get isCustomerLevelLine() {
        return this.lineClientType === 'customer';
    }

    get isClientLevelLine() {
        return this.lineClientType === 'client';
    }

    get showToolbarFilters() {
        return !this.isCustomerLevelLine && !this.isClientLevelLine;
    }

    get showSelectionSummary() {
        return !this.isCustomerLevelLine;
    }

    get tableFrameClass() {
        return this.isCustomerLevelLine ? 'table-frame table-frame--fit-content' : 'table-frame';
    }

    get noClientsMessage() {
        return 'No clients found for this geography.';
    }

    get totalColumns() {
        let total = 1;
        if (this.showGoldenColumn) {
            total += 1;
        }
        if (this.showStarCode) {
            total += 1;
        }
        if (this.showMitigantContracts) {
            total += 1;
        }
        if (this.showInternalRating) {
            total += 1;
        }
        if (this.showCurrentRatingDate) {
            total += 2;
        }
        if (this.showOlOpServiceColumns) {
            total += 3;
        }
        if (this.showExpirationRatingDate) {
            total += 1;
        }
        if (this.showExternalRating) {
            total += 1;
        }
        if (this.showEditableFinancialColumns) {
            total += 5;
        }
        return total;
    }

    get selectedCount() {
        return this.selectedRows.length;
    }

    // Changes been made for CIBGLOBALD-4687
    get showFooter() {
        return this.isDirty && this.canSelectClients;
    }

    get selectionSummary() {
        return `Selected records: ${this.selectedCount}`;
    }

    // Changes been made for CIBGLOBALD-4687
    get viewModeOptions() {
        return [
            { label: this.isCustomerProvTitleLine ? 'Customer' : 'Multiholder', value: 'multiholder' },
            { label: 'Global Clients', value: 'global' }
        ];
    }

    // Changes been made for CIBGLOBALD-4687
    get isCustomerProvTitleLine() {
        return this.isCustomerLevelLine || this.lineAccountClientType === 'subsidiary';
    }

    get isGlobalMode() {
        return this.viewMode === 'global';
    }

    get isMultiholderMode() {
        return this.viewMode === 'multiholder';
    }

    // Changes been made for CIBGLOBALD-4687
    get showViewModeToggle() {
        if (this.lineTemplateType !== 'OL' && this.lineTemplateType !== 'TL') {
            return false;
         }
        if (this.hasGoldenCode) {
            return true;
        }
        const clientType = String(this.lineClientType || '').toLowerCase();
        return clientType === 'group' || clientType === 'golden' || clientType === 'custom' || clientType === 'customer';
    }


    get showGoldenColumn() {
        return this.viewMode === 'global';
    }

    // Changes been made for CIBGLOBALD-4687
    get hasGoldenCode() {
        return Boolean(this.normalizeGoldenCode(this.savedGoldenCode));
    }

    // Changes been made for CIBGLOBALD-4687
    get modeChangeWarningMessage() {
        if (this._pendingViewMode === 'global') {
            return 'Switching to Global Clients will remove the existing Customer or custom association selection. Continue?';
        }
        return 'Switching to Customer will clear the saved Golden Code. Continue?';
    }

    get showMainHolderToggle() {
        return this.isMultiholderMode;
    }

    // Changes been made for CIBGLOBALD-4687
    get isViewModeToggleDisabled() {
        return !this.hasLoadedOnce || this.isSelectionReadOnlyByStatus || this.isSaving || this.showLoading;
    }


    serializeState(rows, mainHolder) {
        const normalizedRows = (rows || [])
            .map((row) => ({
                customerId: row.customerId || '',
                term: row.term || '',
                amount: row.amount ?? null,
                amountFD: row.amountFD ?? null,
                amountDVP: row.amountDVP ?? null
            }))
            .sort((a, b) => a.customerId.localeCompare(b.customerId));

        return JSON.stringify({
            mainHolder: mainHolder || '',
            selectedRows: normalizedRows
        });
    }

    refreshDirtyState() {
        this.isDirty = this.serializeState(this.selectedRows, this.mainHolder) !== this.baselineState;
        this.notifyEditingState();
    }

    snapshotBaseline() {
        this.baselineState = this.serializeState(this.selectedRows, this.mainHolder);
        this.isDirty = false;
        this.notifyEditingState();
    }

    notifyEditingState() {
        if (this.lastEditingState === this.isDirty) {
            return;
        }

        this.lastEditingState = this.isDirty;
        this.dispatchEvent(new CustomEvent('editingtab', {
            detail: {
                tab: this.isDirty ? 'client' : null
            }
        }));
    }

    requestEditSessionBeforeSelection() {
        if (!this.canSelectClients) {
            return false;
        }

        if (this.hasEditSession) {
            return true;
        }

        this.dispatchEvent(new CustomEvent('editingtab', {
            detail: {
                tab: 'client'
            }
        }));

        this.hasEditSession = true;
        return true;
    }

    handleExternalContextChange(changed) {
        if (!changed || !this.recordId || !this.hasLoadedOnce || this.isApplyingDatasource) {
            return;
        }

        this.queueDatasourceRefresh();
    }

    queueDatasourceRefresh() {
        if (this.contextRefreshTimer) {
            clearTimeout(this.contextRefreshTimer);
        }

        // Batch lineStatus/currency changes from parent into a single refresh.
        this.contextRefreshTimer = setTimeout(() => {
            this.contextRefreshTimer = null;
            this.loadDatasource();
        }, 0);
    }

    async loadDatasource(viewModeForDatasource = this.viewMode) {
        if (!this.recordId) {
            return;
        }
        const requestedRecordId = this.recordId;

        try {
            this.showLoading = true;
            this.errorMessage = '';
            this.visibleRowLimit = this.batchSize;
            const fetchClientPosition = this.isCustomerLevelLine || this.filterClients === 'true' ? 'Y/N' : this.clientPosition;
            // Changes been made for CIBGLOBALD-4763 - Resolve client data and approval-state UI access together.
            const [response, canEditApprovalStateUi] = await Promise.all([
                loadDatasourceForMode({
                    recordId: this.recordId,
                    clientPosition: fetchClientPosition,
                    viewMode: viewModeForDatasource
                }),
                canEditLineInApprovalStateUi({ recordId: this.recordId }).catch(() => false)
            ]);

            if (this.recordId !== requestedRecordId) {
                return;
            }
            this.isApplyingDatasource = true;
            this.isIfiLine = response.isIfiLine === true;
            this.accountId = response.accountId || this.accountId;
            this.lineId = response.lineId || this.lineId;
            // Changes been made for CIBGLOBALD-4687
            this.availableClientsAccountId = response.availableClientsAccountId || response.accountId || this.accountId;
            this.externallineId = response.externallineId || this.externallineId;
            this._lineStatus = response.lineStatus || this._lineStatus;
            this.booking = response.booking || this.booking;
            this._currency = response.currency || this._currency;
            // Changes been made for CIBGLOBALD-4763 - Enable client edit controls for qualified approval-state users.
            this.canEditByBusinessRule = response.canEditSelection !== false || canEditApprovalStateUi === true;
            this.returnedDate = this.returnedDate || response.returnedDate;
            // Changes been made for CIBGLOBALD-4687
            this.lineClientType = String(response.lineclienttype || this.lineClientType || '').toLowerCase();
            // Changes been made for CIBGLOBALD-4687
            this.lineAccountClientType = String(response.clientAccountType || '').toLowerCase();
            // Changes been made for CIBGLOBALD-4687
            this.savedGoldenCode = this.normalizeGoldenCode(response.goldenCode);
            this.clientPosition = this.filterClients === 'true'
                ? 'true'
                : (response.clientPosition || this.clientPosition);
            this.groupId = response.groupId || this.groupId;
            this.groupSfId = response.groupSfId || this.groupSfId;
            this.currentPage = Number(response.page || 1);
            this.totalPages = Number(response.totalPages || 1);
            this.lineTemplateType = response.lineTemplateType;   
            this.hasCustomAssociation = response.hasCustomAssociation === true;

            // Changes been made for CIBGLOBALD-4687
            if (this.hasGoldenCode) {
                this.viewMode = 'global';
            } else {
                this.viewMode = viewModeForDatasource === 'global' ? 'global' : 'multiholder';
            }

            if (!this.selectedTab || this.selectedTab === 'tcm') {
                const derivedTab = this.resolveSelectedTab(response.lineTemplateType, response.lineclienttype);
                this.selectedTab = derivedTab;
            }

            this.allAvailableClients = this.applyRatingExpiration(response.availableClients || [])
                .filter((row) => this.matchesClientContext(row.customerId));
            this.availableClients = this.allAvailableClients;
            this.priorselectedRows = response.priorselectedRows || [];
            this.selectedRows = this.normalizeSelectedRowsFromService(
                this.applyRatingExpiration((response.selectedRows || []).map((row) => ({ ...row })))
                    .filter((row) => this.matchesClientContext(row.customerId)),
                this.allAvailableClients
            );
            this.priorselectedRows = this.normalizeSelectedRowsFromService(
                this.priorselectedRows,
                this.allAvailableClients
            );

            this.isSelectionLocked = this.lineClientType === 'customer' && this.allAvailableClients.length <= 1;
            if (this.isSelectionLocked) {
                this.priorselectedRows = [];
                this.selectedRows = [];
            }

            // Reconstruir la selección Golden al cargar (modo Global no persiste selectedRows, solo el Golden_Code__c)
            // Changes been made for CIBGLOBALD-4687
            if (this.savedGoldenCode) {
                this.selectedRows = this.allAvailableClients
                    .filter((row) => this.normalizeGoldenCode(row.goldenCustomerId) === this.savedGoldenCode)
                    .slice(0, 1)
                    .map((row) => ({ ...row }));
                this.mainHolder = '';
            } else {
                const sourceMainHolder = this.priorselectedRows[0]?.mainHolder || this.selectedRows[0]?.mainHolder || '';
                this.mainHolder = sourceMainHolder;
            }
            
            this.hasEditSession = false;
            this.hasLoadedOnce = true;

            await this.ensureInitialGeographyRows();
            if (this.recordId !== requestedRecordId) {
                return;
            }
            await this.ensureServiceRowsForSelectedClients();
            if (this.recordId !== requestedRecordId) {
                return;
            }
            // Changes been made for CIBGLOBALD-4687
            await this.ensureSavedGoldenRowLoaded();
            if (this.recordId === requestedRecordId) {
                this.snapshotBaseline();
            }
        } catch (error) {
            if (this.recordId === requestedRecordId) {
                this.errorMessage = this.resolveUserMessage('load', error);
            }
        } finally {
            if (this.recordId === requestedRecordId) {
                this.isApplyingDatasource = false;
                this.showLoading = false;
            }
        }
    }

    async ensureInitialGeographyRows() {
        const requestedRecordId = this.recordId;
        if (this.filterClients === 'true') {
            return;
        }

        if (this.allAvailableClients.length > 0) {
            return;
        }

        while (this.currentPage < this.totalPages && this.allAvailableClients.length === 0) {
            const pageBeforeFetch = this.currentPage;
            // If first page has no rows for booking geography, keep loading pages until we find matches.
            // This prevents a dead-end empty table with no scroll to trigger pagination.
            // eslint-disable-next-line no-await-in-loop
            await this.fetchNextServerPage();
            if (this.recordId !== requestedRecordId || this.currentPage === pageBeforeFetch) {
                return;
            }
        }
        // CIBGLOBALD-4344 - Every page under "With Exposure" is exhausted and still nothing matches
        // this line's booking geography. On the default/initial load (never on a manual filter
        // change), fall back to "With and Without Exposure" so the tab isn't left empty.
        if (
            this.allAvailableClients.length === 0 &&
            this.filterClients === 'Y' &&
            !this._userManuallyChangedFilter &&
            !this._hasAutoSwitchedExposure
        ) {
            this._hasAutoSwitchedExposure = true;
            this.filterClients = 'Y/N';
            this.clientPosition = 'Y/N';
            await this.loadDatasource();
        }
    }

    async ensureServiceRowsForSelectedClients() {
        const requestedRecordId = this.recordId;
        if (this.filterClients !== 'true' || this.selectedRows.length === 0) {
            return;
        }

        let missingCustomerIds = this.getSelectedCustomerIdsMissingInService();
        while (missingCustomerIds.size > 0 && this.currentPage < this.totalPages) {
            const pageBeforeFetch = this.currentPage;
            // Pull extra pages only while selected clients are missing from service rows.
            // eslint-disable-next-line no-await-in-loop
            await this.fetchNextServerPage();
            if (this.recordId !== requestedRecordId || this.currentPage === pageBeforeFetch) {
                return;
            }
            missingCustomerIds = this.getSelectedCustomerIdsMissingInService();
        }
    }

    getSelectedCustomerIdsMissingInService() {
        const serviceCustomerIds = new Set((this.allAvailableClients || []).map((row) => row.customerId));
        const missingIds = new Set();

        for (const row of this.selectedRows || []) {
            if (!serviceCustomerIds.has(row.customerId)) {
                missingIds.add(row.customerId);
            }
        }

        return missingIds;
    }

    // Changes been made for CIBGLOBALD-4687
    async ensureSavedGoldenRowLoaded() {
        const requestedRecordId = this.recordId;
        if (!this.savedGoldenCode) {
            return;
        }

        const hasSavedGoldenRow = () => this.allAvailableClients.some(
            (row) => this.normalizeGoldenCode(row.goldenCustomerId) === this.savedGoldenCode
        );

        while (!hasSavedGoldenRow() && this.currentPage < this.totalPages) {
            const pageBeforeFetch = this.currentPage;
            // eslint-disable-next-line no-await-in-loop
            await this.fetchNextServerPage();
            if (this.recordId !== requestedRecordId) {
                return;
            }
            if (this.currentPage === pageBeforeFetch) {
                break;
            }
        }

        if (hasSavedGoldenRow()) {
            // Changes been made for CIBGLOBALD-4687
            const savedGoldenIndex = this.allAvailableClients.findIndex(
                (row) => this.normalizeGoldenCode(row.goldenCustomerId) === this.savedGoldenCode
            );
            this.selectedRows = this.allAvailableClients
                .filter((row) => this.normalizeGoldenCode(row.goldenCustomerId) === this.savedGoldenCode)
                .slice(0, 1)
                .map((row) => ({ ...row }));
            this.priorselectedRows = this.selectedRows.map((row) => ({ ...row }));
            this.visibleRowLimit = Math.max(this.visibleRowLimit, savedGoldenIndex + 1);
            this.mainHolder = '';
        }
    }

    handleSearchChange(event) {
        this.searchText = event?.detail?.value ?? event?.target?.value ?? '';
        if (this.searchText && this.filterClients !== 'true') {
            this.loadAllPagesForSearch();
        }
    }

    async handleFilterChange(event) {
        this._userManuallyChangedFilter = true;
        this.filterClients = event.detail.value;
        this.clientPosition = this.filterClients;
        await this.loadDatasource();
    }

    handleTableScroll(event) {
        const container = event.target;
        if (!container || this.searchText) {
            return;
        }

        const remaining = container.scrollHeight - container.scrollTop - container.clientHeight;
        if (remaining >= 120) {
            return;
        }

        if (this.visibleRowLimit < this.allAvailableClients.length) {
            this.visibleRowLimit = Math.min(this.visibleRowLimit + this.batchSize, this.allAvailableClients.length);
            return;
        }

        if (this.filterClients !== 'true') {
            this.fetchNextServerPage();
        }
    }

    async fetchNextServerPage() {
        const clientsAccountId = this.availableClientsAccountId || this.accountId;
        if (this.isFetchingPage || this.currentPage >= this.totalPages || !clientsAccountId) {
            return;
        }
        const requestedRecordId = this.recordId;

        this.isFetchingPage = true;
        this.showLoading = true;
        try {
            const nextPage = this.currentPage + 1;
            const pagingParameters = {
                clientPosition: this.clientPosition === 'true' ? 'Y/N' : this.clientPosition,
                page: String(nextPage),
                pageSize: String(this.serverPageSize)
            };
            const response = this.lineId
                ? await getAvailableClientsPageForLine({
                    ...pagingParameters, lineId: this.lineId, viewMode: this.viewMode
                })
                : await getAvailableClientsPage({ ...pagingParameters, accountId: clientsAccountId });

            if (this.recordId !== requestedRecordId) {
                return;
            }

            const incoming = this.applyRatingExpiration(response.availableClients || [])
                .filter((row) => this.matchesClientContext(row.customerId));

            this.allAvailableClients = this.mergeByCustomerId(this.allAvailableClients, incoming);
            this.availableClients = this.allAvailableClients;
            this.currentPage = Number(response.page || nextPage);
            this.totalPages = Number(response.totalPages || this.totalPages);
            this.visibleRowLimit = Math.min(this.visibleRowLimit + this.batchSize, this.allAvailableClients.length);
        } catch (error) {
            if (this.recordId === requestedRecordId) {
                this.errorMessage = this.resolveUserMessage('load', error);
            }
        } finally {
            if (this.recordId === requestedRecordId) {
                this.isFetchingPage = false;
                if (!this.isFetchingAllForSearch) {
                    this.showLoading = false;
                }
            }
        }
    }

    async loadAllPagesForSearch() {
        if (this.isFetchingAllForSearch || this.isFetchingPage || this.currentPage >= this.totalPages || this.filterClients === 'true') {
            return;
        }
        const requestedRecordId = this.recordId;

        this.isFetchingAllForSearch = true;
        this.showLoading = true;
        try {
            while (this.currentPage < this.totalPages) {
                const pageBeforeFetch = this.currentPage;
                // Sequential page loading avoids concurrent callouts and keeps order predictable.
                // eslint-disable-next-line no-await-in-loop
                await this.fetchNextServerPage();
                if (this.recordId !== requestedRecordId || this.currentPage === pageBeforeFetch) {
                    break;
                }
            }
        } finally {
            if (this.recordId === requestedRecordId) {
                this.isFetchingAllForSearch = false;
                this.showLoading = false;
            }
        }
    }

    handleRowToggle(event) {
        if (!this.canSelectClients) {
            event.target.checked = false;
            return;
        }

        if (!this.requestEditSessionBeforeSelection()) {
            event.target.checked = false;
            return;
        }

        const customerId = event.target.dataset.id;
        const isChecked = Boolean(event.target.checked);
        this.toggleClientSelection(customerId, isChecked);
    }

    handleClientNameToggle(event) {
        if (!this.canSelectClients) {
            return;
        }

        if (!this.requestEditSessionBeforeSelection()) {
            return;
        }

        const customerId = event.currentTarget?.dataset?.id;
        this.toggleClientSelection(customerId);
    }

    toggleClientSelection(customerId, forcedChecked) {
        if (this.viewMode === 'global') {
            this.toggleGoldenClientSelection(customerId);
            return;
        }    

        if (!customerId) {
            return;
        }

        const existing = this.selectedRows.find((row) => row.customerId === customerId);
        const isChecked = forcedChecked === undefined ? !Boolean(existing) : Boolean(forcedChecked);
        const sourceRow = this.allAvailableClients.find((row) => row.customerId === customerId);

        if (isChecked) {
            if (!sourceRow) {
                return;
            }

            if (!existing) {
                this.selectedRows = [...this.selectedRows, { ...sourceRow }];
            }
        } else {
            if (existing) {
                if (sourceRow) {
                    this.allAvailableClients = this.allAvailableClients.map((row) =>
                        row.customerId === customerId ? { ...row, ...existing } : row
                    );
                }
            }
            this.selectedRows = this.selectedRows.filter((row) => row.customerId !== customerId);
            if (this.mainHolder === customerId) {
                this.mainHolder = '';
            }
        }

        if (this.mainHolder && !this.selectedRows.some((row) => row.customerId === this.mainHolder)) {
            this.mainHolder = '';
        }

        if (!this.mainHolder && this.selectedRows.length === 1) {
            this.mainHolder = this.selectedRows[0].customerId;
        }

        this.errorMainHolder = false;
        this.refreshDirtyState();
    }

    toggleGoldenClientSelection(customerId) {
        // Changes been made for CIBGLOBALD-4687
        const clicked = this.allAvailableClients.find((row) => row.customerId === customerId);
        if (!clicked || !clicked.goldenCustomerId) {
            return;
        }

        const clickedGoldenCode = this.normalizeGoldenCode(clicked.goldenCustomerId);
        const alreadySelectedSameGroup = this.selectedRows.length > 0
            && this.normalizeGoldenCode(this.selectedRows[0].goldenCustomerId) === clickedGoldenCode;

        if (alreadySelectedSameGroup) {
            this.selectedRows = [];
            this.mainHolder = '';
        } else {
            this.selectedRows = [{ ...clicked }];
            this.mainHolder = '';
        }
        this.errorMainHolder = false;
        this.refreshDirtyState();
    }

    

    handleMainHolderToggle(event) {
        if (this.isSelectionReadOnlyByStatus) {
            return;
        }

        const customerId = event.target.dataset.id;
        const isChecked = event.target.checked;

        if (!customerId) {
            return;
        }

        if (!isChecked && this.mainHolder === customerId) {
            this.mainHolder = '';
        }

        if (isChecked) {
            this.mainHolder = customerId;
        }

        this.errorMainHolder = false;
        this.refreshDirtyState();
    }

    handleRowFieldChange(event) {
        if (this.isSelectionReadOnlyByStatus) {
            return;
        }

        const customerId = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.detail?.value ?? event.target.value;

        this.selectedRows = this.selectedRows.map((row) => {
            if (row.customerId !== customerId) {
                return row;
            }

            return { ...row, [field]: value };
        });

        this.refreshDirtyState();
    }

    handleCancel() {
        this.selectedRows = this.priorselectedRows.map((row) => ({ ...row }));
        this.mainHolder = this.priorselectedRows[0]?.mainHolder || '';
        this.errorMainHolder = false;
        this.errorMessage = '';
        this.snapshotBaseline();
        this.hasEditSession = false;
    }

    async refreshPersistedLine(lineId) {
        if (!lineId) {
            return '';
        }

        try {
            // Apex writes do not automatically refresh Client Type in LDS consumers.
            await notifyRecordUpdateAvailable([{ recordId: lineId }]);
            return '';
        } catch (error) {
            // eslint-disable-next-line no-console
            console.error('[dmtSelectClientsInLineMigrated][refresh]', error);
            return 'Your changes were saved, but Client Type could not be refreshed. Please refresh the page.';
        }
    }

    /**
     * CIBGLOBALD-4811 - Asks before an action that would reopen approval tasks: 'selection' (handleSave),
     * 'golden' (handleSaveGolden, or the switch to multiholder that clears the golden code) and 'deleteAssociation'
     * (the switch to global that deletes the association). Only in Ready to close; the record type filter of the
     * Line trigger checkpoint 3 is applied in DMT_SelectClientsInLineService.previewLineClientSave, which builds what
     * the action writes from the same values and compares it with the snapshots, without saving. A failed check
     * counts as no reopen.
     * @returns true to go ahead, false when the user cancels
     */
    async _confirmReopen(action, goldenCode) {
        if (this._lineStatus !== 'Ready to close') {
            return true;
        }
        try {
            const features = await previewLineClientSave({
                caseTypeToCheck: 'readytoclose',
                action,
                lineId: this.lineId,
                mainHolderAlphaCode: this.mainHolder,
                currencyLine: this.currency,
                groupId: this.groupId,
                groupSfId: this.groupSfId,
                externallineId: this.externallineId,
                selectedRows: action === 'selection'
                    ? this.normalizeSelectedRowsFromService(this.selectedRows, this.allAvailableClients)
                    : null,
                goldenCode
            });
            if (!features || features.length === 0) {
                return true;
            }
        } catch (error) {
            console.error('[dmtSelectClientsInLineMigrated][_confirmReopen]', error);
            return true;
        }
        return LightningConfirm.open({
            label: 'Modify Line?',
            message: 'The Line will be modified and the associated cases and tasks will be reopened.' +
                '\n\nDo you want to modify the Line?',
            theme: 'warning'
        });
    }

    async handleSave() {
        if (this.viewMode === 'global') {
            return this.handleSaveGolden();
        }    

        if (this.isSelectionReadOnlyByStatus) {
            this.errorMessage = 'This line can no longer be edited.';
            return;
        }

        if (!this.accountId) {
            this.errorMessage = 'AccountId is required to save selected clients.';
            return;
        }

        if (this.selectedRows.length > 0 && !this.mainHolder) {
            this.errorMainHolder = true;
            this.errorMessage = 'No main holder has been selected for the multiclient group.';
            return;
        }

        // CIBGLOBALD-4811 - Ready to close: ask before a save that would reopen tasks
        if (!await this._confirmReopen('selection', null)) return;

        const requestedRecordId = this.recordId;
        const requestedLineId = this.lineId;
        try {
            this.isSaving = true;
            this.showLoading = true;
            this.errorMessage = '';
            const selectedRowsForSave = this.normalizeSelectedRowsFromService(this.selectedRows, this.allAvailableClients);
            const response = await saveSelection({
                lineId: requestedLineId,
                mainHolderAlphaCode: this.mainHolder,
                currencyLine: this.currency,
                groupId: this.groupId,
                groupSfId: this.groupSfId,
                externallineId: this.externallineId,
                selectedRows: selectedRowsForSave
            });

            if (response.success) {
                const refreshWarning = await this.refreshPersistedLine(requestedLineId);
                if (this.recordId !== requestedRecordId) {
                    return;
                }
                this.selectedRows = selectedRowsForSave;
                this.priorselectedRows = this.selectedRows.map((row) => ({ ...row, mainHolder: this.mainHolder }));
                this.snapshotBaseline();
                window.dispatchEvent(new CustomEvent('dmtlinerefresh', { 
                    detail: { lineId: this.lineId }
                }));
                this.hasEditSession = false;
                await this.loadDatasource();
                if (this.recordId !== requestedRecordId) {
                    return;
                }
                this.errorMessage = this.errorMessage || refreshWarning;
                if (this.shouldOpenClosedVersionsModal) {
                    this.showLineVersionsModal = true;
                } else {
                    this.dispatchEvent(new CustomEvent('reloadcard'));
                }
                return;
            }

            if (this.recordId === requestedRecordId) {
                this.errorMessage = this.resolveUserMessage('save', response.error);
            }
        } catch (error) {
            if (this.recordId === requestedRecordId) {
                this.errorMessage = this.resolveUserMessage('save', error);
            }
        } finally {
            if (this.recordId === requestedRecordId) {
                this.isSaving = false;
                this.showLoading = false;
            }
        }
    }
    
    async handleSaveGolden() {
        if (this.isSelectionReadOnlyByStatus || this.isSaving || this.showLoading) {
            return;
        }
        if (this.selectedRows.length === 0) {
            this.errorMessage = 'Select a Customer before saving.';
            return;
        }

        // CIBGLOBALD-4811 - Ready to close: ask before a save that would reopen tasks
        if (!await this._confirmReopen('golden', this.normalizeGoldenCode(this.selectedRows[0].goldenCustomerId))) return;

        const requestedRecordId = this.recordId;
        const requestedLineId = this.lineId;
        try {
            this.isSaving = true;
            this.showLoading = true;
            this.errorMessage = '';

            const goldenCode = this.normalizeGoldenCode(this.selectedRows[0].goldenCustomerId);
            const response = await saveGoldenSelection({
                lineId: requestedLineId,
                goldenCode: goldenCode
            });

            if (response.success) {
                const refreshWarning = await this.refreshPersistedLine(requestedLineId);
                if (this.recordId !== requestedRecordId) {
                    return;
                }
                this.snapshotBaseline();
                this.hasEditSession = false;
                await this.loadDatasource();
                if (this.recordId !== requestedRecordId) {
                    return;
                }
                this.errorMessage = this.errorMessage || refreshWarning;
                this.dispatchEvent(new CustomEvent('reloadcard'));
                return;
            }
            if (this.recordId === requestedRecordId) {
                this.errorMessage = this.resolveUserMessage('save', response.error);
            }
        } catch (error) {
            if (this.recordId === requestedRecordId) {
                this.errorMessage = this.resolveUserMessage('save', error);
            }
        } finally {
            if (this.recordId === requestedRecordId) {
                this.isSaving = false;
                this.showLoading = false;
            }
        }
    }

    handleCloseLineVersionsModal() {
        this.showLineVersionsModal = false;
        this.hasBoundLineVersionsReload = false;
        this.dispatchEvent(new CustomEvent('reloadcard'));
    }

    handleLineVersionsReload(event) {
        event?.stopPropagation?.();
        this.handleCloseLineVersionsModal();
    }

    async handleViewModeChange(event) {
        if (this.isViewModeToggleDisabled) {
            return;
        }
        
        const newMode = event.detail.value;
        if (newMode === this.viewMode) {
            return;
        }
        // Changes been made for CIBGLOBALD-4687
        if (newMode === 'global' && this.viewMode !== 'global' && this.hasCustomAssociation) {
            this._pendingViewMode = newMode;
            this.showModeChangeWarning = true;
            return;
        }

        // Changes been made for CIBGLOBALD-4687
        if (newMode === 'multiholder' && this.viewMode === 'global' && this.hasGoldenCode) {
            this._pendingViewMode = newMode;
            this.showModeChangeWarning = true;
            return;
        }

        this.applyViewModeChange(newMode);
        // Changes been made for CIBGLOBALD-4687
        if (newMode === 'global' && this.isCustomerProvTitleLine) {
            await this.loadDatasource('global');
        }
    }

    applyViewModeChange(newMode) {
        this.viewMode = newMode;
        this.selectedRows = [];
        this.mainHolder = '';
        this.errorMainHolder = false;
        this.errorMessage = '';
        this.refreshDirtyState();
    }

    async handleConfirmModeChange() {
        const mode = this._pendingViewMode;
        const requestedRecordId = this.recordId;
        const requestedLineId = this.lineId;
        this.showModeChangeWarning = false;
        this._pendingViewMode = null;

        if (this.isViewModeToggleDisabled || !['global', 'multiholder'].includes(mode)) {
            return;
        }
        // CIBGLOBALD-4811 - Ready to close: the switch deletes the association or clears the golden code; ask first
        const reopenAction = mode === 'global' && this.hasCustomAssociation
            ? 'deleteAssociation'
            : (mode === 'multiholder' && this.hasGoldenCode ? 'golden' : null);
        if (reopenAction && !await this._confirmReopen(reopenAction, null)) return;
        try {
            this.showLoading = true;
            let refreshWarning = '';
            // Changes been made for CIBGLOBALD-4687
            if (mode === 'global' && this.hasCustomAssociation) {
                const response = await deleteCustomAssociation({ lineId: requestedLineId });
                if (response.success) {
                    refreshWarning = await this.refreshPersistedLine(requestedLineId);
                }
                if (this.recordId !== requestedRecordId) {
                    return;
                }
                if (!response.success) {
                    this.errorMessage = this.resolveUserMessage('save', response.error);
                    return;
                }
            // Changes been made for CIBGLOBALD-4687
            } else if (mode === 'multiholder' && this.hasGoldenCode) {
                const response = await clearGoldenSelection({ lineId: requestedLineId });
                if (response.success) {
                    refreshWarning = await this.refreshPersistedLine(requestedLineId);
                }
                if (this.recordId !== requestedRecordId) {
                    return;
                }
                if (!response.success) {
                    this.errorMessage = this.resolveUserMessage('save', response.error);
                    return;
                }
            }

            if (mode) {
                await this.loadDatasource(mode);
                if (this.recordId === requestedRecordId) {
                    this.errorMessage = this.errorMessage || refreshWarning;
                    this.dispatchEvent(new CustomEvent('reloadcard'));
                }
            }
        } catch (error) {
            if (this.recordId === requestedRecordId) {
                this.errorMessage = this.resolveUserMessage('save', error);
            }
        }  finally {
            if (this.recordId === requestedRecordId) {
                this.showLoading = false;
            }
        }
    }

    handleCancelModeChange() {
        this.showModeChangeWarning = false;
        this._pendingViewMode = null;
        // Forzar re-render del radio-group para que vuelva al modo real
        const currentMode = this.viewMode;
        this.viewMode = null;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        Promise.resolve().then(() => {
            this.viewMode = currentMode;
        });
    }

    applyRatingExpiration(rows) {
        const now = Date.now();
        const oneYearMs = 31556952000;
        const nineteenMonthsMs = 49965174000;

        return (rows || []).map((source) => {
            const row = { ...source, goldenCustomerId: this.normalizeGoldenCode(source.goldenCustomerId) };
            const scaleLast = this.parseDate(row.scaleLastUpdDate);
            const ratingValidity = this.parseDate(row.ratingValidityStartDate);
            const currentRating = this.parseDate(row.currentRatingToolDate);
            const ffssRegulatory = this.parseDate(row.ffssRegulatoryRatingDate);

            let expirationTs;
            if (scaleLast) {
                expirationTs = now - scaleLast.getTime() >= oneYearMs
                    ? scaleLast.getTime() + oneYearMs
                    : (ratingValidity ? ratingValidity.getTime() + nineteenMonthsMs : undefined);
            } else {
                row.updSmsclInternalRatgType = row.smsclInternalRatgType || row.updSmsclInternalRatgType;
                expirationTs = currentRating && (now - currentRating.getTime() >= oneYearMs)
                    ? currentRating.getTime() + oneYearMs
                    : (ffssRegulatory ? ffssRegulatory.getTime() + nineteenMonthsMs : undefined);
            }

            if (expirationTs && Number.isFinite(expirationTs)) {
                row.expirationRatingDate = this.formatDate(new Date(expirationTs));
            } else if (!row.expirationRatingDate) {
                row.expirationRatingDate = '';
            }

            return row;
        });
    }

    parseDate(value) {
        if (!value) {
            return null;
        }

        const parsed = new Date(value);
        return Number.isNaN(parsed.getTime()) ? null : parsed;
    }

    formatDate(dateValue) {
        if (!(dateValue instanceof Date) || Number.isNaN(dateValue.getTime())) {
            return '';
        }

        return dateValue.toISOString().slice(0, 10);
    }

    resolveUserMessage(context, error) {
        const rawMessage = this.extractErrorMessage(error);
        // Keep technical detail in console logs for diagnostics, not for end users.
        // eslint-disable-next-line no-console
        console.error(`[dmtSelectClientsInLineMigrated][${context}]`, rawMessage, error);

        return this.classifyUserMessage(context, rawMessage);
    }

    classifyUserMessage(context, rawMessage) {
        const text = String(rawMessage || '').trim();
        const lower = text.toLowerCase();

        if (
            lower.includes('hpg') ||
            lower.includes('global position') ||
            lower.includes('service unavailable') ||
            lower.includes('statuscode') ||
            lower.includes('status code') ||
            lower.includes('callout') ||
            lower.includes('read timed out') ||
            lower.includes('connect timed out')
        ) {
            return 'HPG service is temporarily unavailable. Please try again in a few minutes.';
        }

        if (
            lower.includes('attempt to de-reference a null object') ||
            lower.includes('nullpointer') ||
            lower.includes('null pointer') ||
            lower.includes('script-thrown exception') ||
            lower.includes('internal server error')
        ) {
            return context === 'save'
                ? 'We could not save your changes due to an internal error. Please try again.'
                : 'We could not load client information due to an internal error. Please try again.';
        }

        if (context === 'save') {
            return 'We could not save your changes. Please review the information and try again.';
        }

        return 'We could not load client information. Please try again.';
    }

    extractErrorMessage(error) {
        if (!error) {
            return 'Unknown error.';
        }

        if (typeof error === 'string') {
            return error;
        }

        const body = error.body;
        if (Array.isArray(body) && body.length > 0) {
            return body.map((entry) => entry.message).filter(Boolean).join(' | ');
        }

        if (body?.message) {
            return body.message;
        }

        if (error.message) {
            return error.message;
        }

        return JSON.stringify(error);
    }

    // Changes been made for CIBGLOBALD-4687
    matchesClientContext(customerId) {
        return this.isIfiLine || (this.isGlobalMode && this.isCustomerProvTitleLine)
            || this.matchesBookingGeography(customerId);
    }

    normalizeGoldenCode(value) {
        return String(value ?? '').trim();
    }

    matchesBookingGeography(customerId) {
        const bookingPrefix = String(this.booking || '').trim().toUpperCase();
        if (!bookingPrefix) {
            return true;
        }

        const customer = String(customerId || '').toUpperCase();
        return customer.startsWith(bookingPrefix);
    }

    mergeByCustomerId(existingRows, incomingRows) {
        const mergedMap = new Map();
        for (const row of existingRows || []) {
            mergedMap.set(row.customerId, row);
        }
        for (const row of incomingRows || []) {
            mergedMap.set(row.customerId, row);
        }
        return Array.from(mergedMap.values());
    }

    mergeRowsForSelectedFilter(serviceRows, selectedRows) {
        const mergedMap = new Map();
        for (const row of serviceRows || []) {
            mergedMap.set(row.customerId, { ...row });
        }

        for (const row of selectedRows || []) {
            const existing = mergedMap.get(row.customerId);
            if (!existing) {
                mergedMap.set(row.customerId, { ...row });
                continue;
            }

            mergedMap.set(
                row.customerId,
                this.mergeServiceRowWithSelectedEditableFields(existing, row)
            );
        }

        return Array.from(mergedMap.values());
    }

    mergeServiceRowWithSelectedEditableFields(serviceRow, selectedRow) {
        const merged = { ...serviceRow };
        if (!selectedRow) {
            return merged;
        }

        if (Object.prototype.hasOwnProperty.call(selectedRow, 'amount')) {
            merged.amount = selectedRow.amount;
        }
        if (Object.prototype.hasOwnProperty.call(selectedRow, 'amountFD')) {
            merged.amountFD = selectedRow.amountFD;
        }
        if (Object.prototype.hasOwnProperty.call(selectedRow, 'amountDVP')) {
            merged.amountDVP = selectedRow.amountDVP;
        }
        if (Object.prototype.hasOwnProperty.call(selectedRow, 'term')) {
            merged.term = selectedRow.term;
        }

        return merged;
    }

    normalizeSelectedRowsFromService(selectedRows, serviceRows) {
        const serviceById = new Map();
        for (const row of serviceRows || []) {
            serviceById.set(row.customerId, row);
        }

        return (selectedRows || []).map((row) => {
            const serviceRow = serviceById.get(row.customerId);
            if (!serviceRow) {
                return { ...row };
            }

            return {
                ...row,
                customerName: serviceRow.customerName || row.customerName || '',
                totalRatingScoreNumber: serviceRow.totalRatingScoreNumber ?? row.totalRatingScoreNumber ?? '',
                leveragedLendingIndType: serviceRow.leveragedLendingIndType ?? row.leveragedLendingIndType ?? '',
                assetAllocationSectorType: serviceRow.assetAllocationSectorType ?? row.assetAllocationSectorType ?? ''
            };
        });
    }

    resolveSelectedTab(lineTemplateType, lineClientType) {
        const template = String(lineTemplateType || '').toUpperCase();
        const clientType = String(lineClientType || '').toLowerCase();

        if (template && template !== 'TL') {
            return 'tcmotherlines';
        }

        if (clientType === 'customer') {
            return 'tcmcustomer';
        }

        return 'tcm';
    }
}