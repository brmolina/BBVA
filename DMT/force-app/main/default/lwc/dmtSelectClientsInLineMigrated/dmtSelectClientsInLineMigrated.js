import { LightningElement, api, track } from 'lwc';
import loadDatasource from '@salesforce/apex/DMT_SelectClientsInLineService.loadDatasource';
import getAvailableClientsPage from '@salesforce/apex/DMT_SelectClientsInLineService.getAvailableClientsPage';
import saveSelection from '@salesforce/apex/DMT_SelectClientsInLineService.saveSelection';
import pubsub from 'omnistudio/pubsub';

export default class DmtSelectClientsInLineMigrated extends LightningElement {
    _recordId;
    _lineStatus = '';
    _currency = '';
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
    @track searchText = '';
    @track isSaving = false;
    @track groupId;
    @track groupSfId;

    @track filterClients = 'Y';
    @track mainHolder = '';
    @track errorMainHolder = false;
    @track errorMessage = '';
    @track showLoading = false;
    @track isDirty = false;
    @track hasLoadedOnce = false;
    @track lineClientType = '';
    @track isSelectionLocked = false;
    @track canEditByBusinessRule = true;
    @track showLineVersionsModal = false;

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

        if (changed && this._recordId) {
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

        const query = String(this.searchText || '').trim().toLowerCase();
        const filtered = this.allAvailableClients
            .filter((row) => {
                const selected = selectedById.has(row.customerId);
                if (this.filterClients === 'true' && !selected) {
                    return false;
                }

                if (!this.matchesBookingGeography(row.customerId)) {
                    return false;
                }

                if (!query) {
                    return true;
                }

                const name = (row.customerName || '').toLowerCase();
                const id = (row.customerId || '').toLowerCase();
                const country = (row.countryIfoId || '').toLowerCase();
                return name.includes(query) || id.includes(query) || country.includes(query);
            });

        const limited = query ? filtered : filtered.slice(0, this.visibleRowLimit);
        return limited
            .map((row) => {
                const selected = selectedById.get(row.customerId);
                const merged = selected ? { ...row, ...selected } : { ...row };
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

    get canSelectClients() {
        return !this.isSelectionLocked && !this.isSelectionReadOnlyByStatus;
    }

    get isClientSelectionDisabled() {
        return !this.canSelectClients;
    }

    get showNoClientsForGeography() {
        return !this.showLoading && !this.hasError && this.allAvailableClients.length === 0;
    }

    get isCustomerLevelLine() {
        return this.lineClientType === 'customer';
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
            total += 1;
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

    get showFooter() {
        return this.isDirty && !this.isSelectionLocked && !this.isSelectionReadOnlyByStatus;
    }

    get selectionSummary() {
        return `Selected records: ${this.selectedCount}`;
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

    async loadDatasource() {
        if (!this.recordId) {
            return;
        }

        try {
            this.showLoading = true;
            this.errorMessage = '';
            this.visibleRowLimit = this.batchSize;
            const fetchClientPosition = this.filterClients === 'true' ? 'Y/N' : this.clientPosition;
            const response = await loadDatasource({
                recordId: this.recordId,
                clientPosition: fetchClientPosition
            });

            this.isApplyingDatasource = true;
            this.accountId = this.accountId || response.accountId;
            this.lineId = this.lineId || response.lineId;
            this.externallineId = this.externallineId || response.externallineId;
            this._lineStatus = response.lineStatus || this._lineStatus;
            this.booking = this.booking || response.booking;
            this._currency = response.currency || this._currency;
            this.canEditByBusinessRule = response.canEditSelection !== false;
            this.returnedDate = this.returnedDate || response.returnedDate;
            this.lineClientType = String(response.lineclienttype || this.lineClientType || '').toLowerCase();
            this.clientPosition = this.filterClients === 'true'
                ? 'true'
                : (response.clientPosition || this.clientPosition);
            this.groupId = response.groupId || this.groupId;
            this.groupSfId = response.groupSfId || this.groupSfId;
            this.currentPage = Number(response.page || 1);
            this.totalPages = Number(response.totalPages || 1);

            if (!this.selectedTab || this.selectedTab === 'tcm') {
                const derivedTab = this.resolveSelectedTab(response.lineTemplateType, response.lineclienttype);
                this.selectedTab = derivedTab;
            }

            this.allAvailableClients = this.applyRatingExpiration(response.availableClients || [])
                .filter((row) => this.matchesBookingGeography(row.customerId));
            this.availableClients = this.allAvailableClients;
            this.priorselectedRows = response.priorselectedRows || [];
            this.selectedRows = this.normalizeSelectedRowsFromService(
                this.applyRatingExpiration((response.selectedRows || []).map((row) => ({ ...row })))
                    .filter((row) => this.matchesBookingGeography(row.customerId)),
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

            const sourceMainHolder = this.priorselectedRows[0]?.mainHolder || this.selectedRows[0]?.mainHolder || '';
            this.mainHolder = sourceMainHolder;
            this.snapshotBaseline();
            this.hasEditSession = false;
            this.hasLoadedOnce = true;
        } catch (error) {
            this.errorMessage = this.resolveUserMessage('load', error);
        } finally {
            this.isApplyingDatasource = false;
            this.showLoading = false;
        }
    }

    handleSearchChange(event) {
        this.searchText = event?.detail?.value ?? event?.target?.value ?? '';
        if (this.searchText && this.filterClients !== 'true') {
            this.loadAllPagesForSearch();
        }
    }

    async handleFilterChange(event) {
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
        if (this.isFetchingPage || this.currentPage >= this.totalPages || !this.accountId) {
            return;
        }

        this.isFetchingPage = true;
        this.showLoading = true;
        try {
            const nextPage = this.currentPage + 1;
            const response = await getAvailableClientsPage({
                accountId: this.accountId,
                clientPosition: this.clientPosition === 'true' ? 'Y/N' : this.clientPosition,
                page: String(nextPage),
                pageSize: String(this.serverPageSize)
            });

            const incoming = this.applyRatingExpiration(response.availableClients || [])
                .filter((row) => this.matchesBookingGeography(row.customerId));

            this.allAvailableClients = this.mergeByCustomerId(this.allAvailableClients, incoming);
            this.availableClients = this.allAvailableClients;
            this.currentPage = Number(response.page || nextPage);
            this.totalPages = Number(response.totalPages || this.totalPages);
            this.visibleRowLimit = Math.min(this.visibleRowLimit + this.batchSize, this.allAvailableClients.length);
        } catch (error) {
            this.errorMessage = this.resolveUserMessage('load', error);
        } finally {
            this.isFetchingPage = false;
            if (!this.isFetchingAllForSearch) {
                this.showLoading = false;
            }
        }
    }

    async loadAllPagesForSearch() {
        if (this.isFetchingAllForSearch || this.isFetchingPage || this.currentPage >= this.totalPages || this.filterClients === 'true') {
            return;
        }

        this.isFetchingAllForSearch = true;
        this.showLoading = true;
        try {
            while (this.currentPage < this.totalPages) {
                // Sequential page loading avoids concurrent callouts and keeps order predictable.
                // eslint-disable-next-line no-await-in-loop
                await this.fetchNextServerPage();
            }
        } finally {
            this.isFetchingAllForSearch = false;
            this.showLoading = false;
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
        if (!customerId) {
            return;
        }

        const existing = this.selectedRows.find((row) => row.customerId === customerId);
        const isChecked = forcedChecked === undefined ? !Boolean(existing) : Boolean(forcedChecked);
        const sourceRow = this.allAvailableClients.find((row) => row.customerId === customerId);

        if (!sourceRow) {
            return;
        }

        if (isChecked) {
            if (!existing) {
                this.selectedRows = [...this.selectedRows, { ...sourceRow }];
            }
        } else {
            if (existing) {
                this.allAvailableClients = this.allAvailableClients.map((row) =>
                    row.customerId === customerId ? { ...row, ...existing } : row
                );
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

    async handleSave() {
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

        try {
            this.isSaving = true;
            this.showLoading = true;
            this.errorMessage = '';
            const selectedRowsForSave = this.normalizeSelectedRowsFromService(this.selectedRows, this.allAvailableClients);
            const response = await saveSelection({
                lineId: this.lineId,
                mainHolderAlphaCode: this.mainHolder,
                currencyLine: this.currency,
                groupId: this.groupId,
                groupSfId: this.groupSfId,
                externallineId: this.externallineId,
                selectedRows: selectedRowsForSave
            });

            if (response.success) {
                this.selectedRows = selectedRowsForSave;
                this.priorselectedRows = this.selectedRows.map((row) => ({ ...row, mainHolder: this.mainHolder }));
                this.snapshotBaseline();
                this.hasEditSession = false;
                if (this.shouldOpenClosedVersionsModal) {
                    this.showLineVersionsModal = true;
                } else {
                    this.dispatchEvent(new CustomEvent('reloadcard'));
                }
                return;
            }

            this.errorMessage = this.resolveUserMessage('save', response.error);
        } catch (error) {
            this.errorMessage = this.resolveUserMessage('save', error);
        } finally {
            this.isSaving = false;
            this.showLoading = false;
        }
    }

    handleCloseLineVersionsModal() {
        this.showLineVersionsModal = false;
        this.dispatchEvent(new CustomEvent('reloadcard'));
    }

    applyRatingExpiration(rows) {
        const now = Date.now();
        const oneYearMs = 31556952000;
        const nineteenMonthsMs = 49965174000;

        return (rows || []).map((source) => {
            const row = { ...source };
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
                customerName: serviceRow.customerName || row.customerName || ''
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