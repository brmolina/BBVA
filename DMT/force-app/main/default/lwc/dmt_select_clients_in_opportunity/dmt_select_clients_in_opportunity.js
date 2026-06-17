import { LightningElement, api, track } from 'lwc';
import { labels } from './dmt_select_clients_in_opportunity_labels.js';
import fetchInitialData from '@salesforce/apex/DMT_HPG_MainTableCustomController.fetchInitialData';
import fetchData from '@salesforce/apex/DMT_HPG_MainTableCustomController.fetchData';

function normalizeToArray(value) {
    if (Array.isArray(value)) return value.filter(Boolean);
    if (value && typeof value === 'object') return [value];
    return [];
}

export default class DmtSelectClientsInOpportunity extends LightningElement {

    // ─── @api props passed by parent ──────────────────────────────────────────
    @api recordId;
    @api selectedTab  = 'tcmopp';
    @api countries    = ['ALL'];
    @api page         = '1';
    @api pageSize     = '5000';
    @api booking;
    @api isLoading;

    /** When true the table body shows a service-unavailable message instead of data. */
    @api serviceUnavailable = false;

    // ─── @api getter/setter props ─────────────────────────────────────────────
    _clientId;
    _isReadOnlyUser;
    _isSubsidiary = false;
    _stageName;
    _searchDate;

    @api get clientId() { return this._clientId; }
    set clientId(v) {
        const next    = v || null;
        const changed = this._clientId !== next;
        this._clientId = next;
        if (changed && this._clientId) this._loadInitialData();
    }

    @api get isReadOnlyUser() { return this._isReadOnlyUser; }
    set isReadOnlyUser(v) { this._isReadOnlyUser = v; }

    @api get searchDate() { return this._searchDate; }
    set searchDate(v) {
        const next    = v || null;
        const changed = this._searchDate !== next;
        this._searchDate = next;
        if (changed && this._searchDate && this._clientId) this._loadInitialData();
    }

    @api get stageName() { return this._stageName; }
    set stageName(v) { this._stageName = v; }

    @api get isSubsidiary() { return this._isSubsidiary; }
    set isSubsidiary(v) { this._isSubsidiary = v === true || v === 'true'; }

    @api get mainHolderCurrent() { return this._mainHolderCustomer; }
    set mainHolderCurrent(v) {
        if (v && typeof v === 'string' && v.trim() !== '' && v !== 'null') {
            this._mainHolderCustomer = v;
        }
    }

    // ─── priorselectedRows ────────────────────────────────────────────────────
    @api get priorselectedRows() { return this._priorselectedRows; }
    set priorselectedRows(value) {
        this._priorselectedRows = normalizeToArray(value);
        if (this._hasInitializedSelection) return;

        this.selectedClients       = this._priorselectedRows.map(item => ({ ...item, mainHolder: null }));
        this._mainHolderSelectRows = this.selectedClients.map(c => c.customerId);

        const mainHolderFromData = this._priorselectedRows.find(
            item => item.mainHolder && item.mainHolder !== 'null'
        )?.mainHolder;
        if (mainHolderFromData) this._mainHolderCustomer = mainHolderFromData;

        if (this._hasLoadedOnce) {
            this._hasInitializedSelection = true;
        } else {
            this._pendingInitialSelection = true;
        }
    }

    // ─── @api command methods ─────────────────────────────────────────────────
    @api getSelectionData() {
        return {
            selectedClients: this.selectedClients.map(c => ({ ...c })),
            mainHolder:      this._mainHolderCustomer || null
        };
    }

    @api restoreSelection(snapshot) {
        if (!snapshot) return;
        const { selectedClients = [], mainHolder = null } = snapshot;
        this.selectedClients       = selectedClients.map(c => ({ ...c, mainHolder: null }));
        this._mainHolderSelectRows = this.selectedClients.map(c => c.customerId);
        this._mainHolderCustomer   = mainHolder || '';
        this.errorMainHolder       = false;
    }

    @api clearSelection() {
        this.selectedClients       = [];
        this._mainHolderSelectRows = [];
        this._mainHolderCustomer   = '';
        this.errorMainHolder       = false;
    }

    // ─── @track reactive state ────────────────────────────────────────────────
    @track allAvailableClients = [];
    @track searchText          = '';
    @track filterClients       = 'Y';
    @track showLoading         = false;
    @track errorMainHolder     = false;

    // ─── private state ────────────────────────────────────────────────────────
    labels                   = labels;
    selectedClients          = [];
    _mainHolderCustomer      = '';
    _mainHolderSelectRows    = [];
    _priorselectedRows       = [];
    _hasInitializedSelection = false;
    _pendingInitialSelection = false;
    _hasLoadedOnce           = false;
    groupedData              = [];
    batchSize                = 100;
    visibleRowLimit          = 100;
    isFetchingPage           = false;

    // ─── lifecycle ────────────────────────────────────────────────────────────
    connectedCallback() {
        if (this._isSubsidiary || !this._clientId) return;
        this._loadInitialData();
    }

    // ─── computed getters ─────────────────────────────────────────────────────
    get showInternalRating()    { return true; }
    get showCurrentRatingDate() { return true; }
    get showExternalRating() {
        return this.selectedTab === 'tcmopp' || this.selectedTab === 'tcmoppMitigants';
    }

    get filterOptions() {
        return [
            { label: 'Only selected clients',     value: 'true' },
            { label: 'With Exposure',             value: 'Y'    },
            { label: 'With and Without Exposure', value: 'Y/N'  }
        ];
    }

    get selectedCount()            { return this.selectedClients.length; }
    get showGlobalLoadingOverlay() { return this.showLoading && !this.isFetchingPage; }
    get showTableLoadingOverlay()  { return this.showLoading && !this.showGlobalLoadingOverlay; }
    get loadingMessage()           { return this.showLoading ? 'Loading information, please wait...' : ''; }

    get canSelectClients() {
        return !this._isReadOnlyUser &&
            (this._stageName === 'Draft' || this._stageName === 'Ready to close');
    }

    get isClientSelectionDisabled() { return !this.canSelectClients; }

    get showNoClients() {
        return !this.showLoading && this._hasLoadedOnce && this.allAvailableClients.length === 0;
    }

    get hasLoadedOnce() { return this._hasLoadedOnce; }

    get totalColumns() {
        return 3 + (this.showExternalRating ? 1 : 0);
    }

    get visibleClients() {
        const selectedById = new Map(this.selectedClients.map(c => [c.customerId, c]));
        const query        = String(this.searchText || '').trim().toLowerCase();

        const filtered = this.allAvailableClients.filter(row => {
            const id = row.customerId || row[6];
            if (this.booking && id && !id.startsWith(this.booking)) return false;
            if (this.filterClients === 'true' && !selectedById.has(id)) return false;
            if (!query) return true;
            const name    = (row.customerName || row[9] || '').toLowerCase();
            const country = (row.countryIfoId || row[7] || '').toLowerCase();
            return name.includes(query) || (id || '').toLowerCase().includes(query) || country.includes(query);
        });

        const limited = query ? filtered : filtered.slice(0, this.visibleRowLimit);
        return limited.map(row => {
            const id       = row.customerId || row[6];
            const selected = selectedById.get(id);
            return {
                ...row,
                customerId:   id,
                customerName: row.customerName || row[9],
                countryIfoId: row.countryIfoId || row[7],
                isSelected:   Boolean(selected),
                isMainHolder: id === this._mainHolderCustomer,
                rowClass:     selected ? 'selected-row' : ''
            };
        });
    }

    get hasVisibleClients() { return this.visibleClients.length > 0; }

    // ─── data loading ─────────────────────────────────────────────────────────
    async _loadInitialData() {
        if (this._isSubsidiary || !this._clientId || !this._searchDate) return;

        this.showLoading    = true;
        this.visibleRowLimit = this.batchSize;
        const clientPosition = this.filterClients === 'true' ? 'Y/N' : (this.filterClients || 'Y');

        try {
            const data = await fetchInitialData({
                selectedTab:         this.selectedTab,
                clientId:            this._clientId,
                lCountries:          this.countries,
                searchDate:          this._searchDate,
                clientPositionsType: clientPosition,
                page:                this.page,
                pageSize:            this.pageSize
            });

            if (data?.success) {
                this.groupedData         = data.data || [];
                this.allAvailableClients = this._applyRatingExpiration(this.groupedData);
                this._hasLoadedOnce      = true;
                if (this._pendingInitialSelection) this._finalizeInitialSelection();
            } else {
                this._dispatchLoadError(data?.errorMessage || 'Unknown error loading data');
            }
        } catch (error) {
            this._dispatchLoadError(error);
        } finally {
            this.showLoading = false;
        }
    }

    @api fetchData(params) {
        if (this._isSubsidiary) return;
        fetchData(params)
            .then(data => {
                if (data.success) {
                    this.groupedData = this.groupedData.concat(data.data);
                    if (data.pagination.totalPages > data.pagination.page) {
                        this._fetchMore(data.pagination.page + 1, data.pagination.pageSize);
                    }
                } else {
                    this._dispatchLoadError(data.errorMessage || 'Unknown error');
                }
            })
            .catch(error => this._dispatchLoadError(error));
    }

    _fetchMore(page, pageSz) {
        const clientPosition = this.filterClients === 'true' ? 'Y/N' : (this.filterClients || 'Y');
        this.fetchData({
            selectedTab:         this.selectedTab,
            clientId:            this._clientId,
            lCountries:          this.countries,
            searchDate:          this._searchDate,
            clientPositionsType: clientPosition,
            page,
            pageSize:            pageSz,
            bubbles:             false
        });
    }

    _finalizeInitialSelection() {
        this._pendingInitialSelection = false;
        this._hasInitializedSelection = true;
    }

    // ─── selection logic ──────────────────────────────────────────────────────
    handleClientNameToggle(event) {
        if (!this.canSelectClients) return;
        const customerId = event.currentTarget?.dataset?.id;
        if (!customerId) return;

        this._dispatchEditMode();
        const idx = this.selectedClients.findIndex(c => c.customerId === customerId);
        if (idx !== -1) {
            this.selectedClients = this.selectedClients.filter(c => c.customerId !== customerId);
            if (this._mainHolderCustomer === customerId) {
                this._mainHolderCustomer = this.selectedClients[0]?.customerId || '';
            }
        } else {
            const full = this.groupedData.find(c => c.customerId === customerId);
            if (full) this.selectedClients = [...this.selectedClients, { ...full }];
            if (!this._mainHolderCustomer && this.selectedClients.length === 1) {
                this._mainHolderCustomer = customerId;
            }
        }

        this._mainHolderSelectRows = this.selectedClients.map(c => c.customerId);
        this.errorMainHolder       = false;
        this._dispatchViewModeSelection();
        this._dispatchViewModeMainHolder();
    }

    // ─── main borrower toggle ─────────────────────────────────────────────────
    handleMainHolderToggle(event) {
        if (!this.canSelectClients) return;
        const customerId = event.target.dataset.id;
        if (!customerId) return;

        this._dispatchEditMode();
        this._mainHolderCustomer = event.target.checked ? customerId
            : (this._mainHolderCustomer === customerId ? '' : this._mainHolderCustomer);
        this.errorMainHolder = false;
        this._dispatchViewModeMainHolder();
    }

    // ─── search & filter ──────────────────────────────────────────────────────
    handleSearchChange(event) {
        this.searchText = event?.detail?.value ?? event?.target?.value ?? '';
    }

    async handleFilterChange(event) {
        this.filterClients = event.detail.value;
        await this._loadInitialData();
    }

    handleTableScroll(event) {
        const el = event.target;
        if (!el || this.searchText) return;
        const remaining = el.scrollHeight - el.scrollTop - el.clientHeight;
        if (remaining < 120 && this.visibleRowLimit < this.allAvailableClients.length) {
            this.visibleRowLimit = Math.min(
                this.visibleRowLimit + this.batchSize,
                this.allAvailableClients.length
            );
        }
    }

    // ─── rating expiration ────────────────────────────────────────────────────
    _applyRatingExpiration(rows) {
        const now            = Date.now();
        const ONE_YEAR       = 31556952000;
        const NINETEEN_MONTHS = 49965174000;

        return (rows || []).map(source => {
            const row            = { ...source };
            const scaleLast      = this._parseDate(row.scaleLastUpdDate);
            const ratingValidity = this._parseDate(row.ratingValidityStartDate);
            const currentRating  = this._parseDate(row.currentRatingToolDate);
            const ffssRegulatory = this._parseDate(row.ffssRegulatoryRatingDate);

            let expirationTs;
            if (scaleLast) {
                expirationTs = (now - scaleLast.getTime() >= ONE_YEAR)
                    ? scaleLast.getTime() + ONE_YEAR
                    : (ratingValidity ? ratingValidity.getTime() + NINETEEN_MONTHS : undefined);
            } else {
                row.updSmsclInternalRatgType = row.smsclInternalRatgType || row.updSmsclInternalRatgType;
                expirationTs = currentRating && (now - currentRating.getTime() >= ONE_YEAR)
                    ? currentRating.getTime() + ONE_YEAR
                    : (ffssRegulatory ? ffssRegulatory.getTime() + NINETEEN_MONTHS : undefined);
            }

            row.expirationRatingDate = (expirationTs && Number.isFinite(expirationTs))
                ? this._formatDate(new Date(expirationTs))
                : (row.expirationRatingDate || '');
            return row;
        });
    }

    _parseDate(value) {
        if (!value) return null;
        const d = new Date(value);
        return Number.isNaN(d.getTime()) ? null : d;
    }

    _formatDate(d) {
        return (d instanceof Date && !Number.isNaN(d.getTime())) ? d.toISOString().slice(0, 10) : '';
    }

    // ─── event dispatching ────────────────────────────────────────────────────
    _dispatchEditMode() {
        this.dispatchEvent(new CustomEvent('editmode', { bubbles: true, composed: true, cancelable: true }));
    }

    _dispatchViewModeSelection() {
        this.dispatchEvent(new CustomEvent('viewmodeselection', {
            bubbles: true, composed: true, cancelable: true,
            detail: {
                selectedClients: this.selectedClients.map(c => ({ customerId: c.customerId, mainHolder: null })),
                isUserAction: true
            }
        }));
    }

    _dispatchViewModeMainHolder() {
        this.dispatchEvent(new CustomEvent('viewmodemainholder', {
            bubbles: true, composed: true, cancelable: true,
            detail: { mainHolder: this._mainHolderCustomer || null, isUserAction: true }
        }));
    }

    _dispatchLoadError(error) {
        const rawMessage = (error && typeof error === 'object')
            ? (error.body?.message || error.message || JSON.stringify(error))
            : String(error);
        this.dispatchEvent(new CustomEvent('loaderror', {
            bubbles: true, composed: true, cancelable: true,
            detail: { error, message: rawMessage }
        }));
    }
    get showSelectionSummary() {
    return !this.serviceUnavailable;
    }

    get isFiltersDisabled() {
        return this.serviceUnavailable || this.isLoading;
    }
}