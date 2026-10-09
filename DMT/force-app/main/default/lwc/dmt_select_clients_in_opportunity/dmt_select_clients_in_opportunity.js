import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { labels } from './dmt_select_clients_in_opportunity_labels.js';
import fetchInitialData from '@salesforce/apex/DMT_HPG_MainTableCustomController.fetchInitialData';
import fetchData from '@salesforce/apex/DMT_HPG_MainTableCustomController.fetchData';
import lastDate from '@salesforce/apex/DMT_HPG_Utils.lastDate';

const CUSTOM_EVENT_OPTIONS = { bubbles: true, composed: true, cancelable: true };

const MAIN_BORROWER_TOAST = {
    title: 'Action not allowed',
    message: 'You cannot remove the Main Borrower. Please select a different client as Main Borrower first.',
    variant: 'warning',
    mode: 'dismissable'
};

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
   // @api serviceUnavailable = false;

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
        if (changed && this._clientId) {
            // CIBGLOBALD-4344 - A new opportunity/client context resets the With-Exposure-empty
            // fallback so it can re-arm, even if the user had manually overridden it previously.
            this._userManuallyChangedFilter = false;
            this._hasAutoSwitchedExposure   = false;
            this._fetchDateAndLoad();
        }
    }

    @api get isReadOnlyUser() { return this._isReadOnlyUser; }
    set isReadOnlyUser(v) { this._isReadOnlyUser = v; }

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

        this.selectedClients       = this._cloneClients(this._priorselectedRows);
        this._mainHolderSelectRows = this._selectedCustomerIds;

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

    @api getSelectionData() {
        return {
            selectedClients: this._cloneClients(this.selectedClients),
            mainHolder:      this._mainHolderCustomer || null
        };
    }

    @api restoreSelection(snapshot) {
        if (!snapshot) return;
        const { selectedClients = [], mainHolder = null } = snapshot;
        this.selectedClients       = this._cloneClients(selectedClients);
        this._mainHolderSelectRows = this._selectedCustomerIds;
        this._mainHolderCustomer   = mainHolder || '';
        this.errorMainHolder       = false;
    }

    @api clearSelection() {
        this.selectedClients       = [];
        this._mainHolderSelectRows = [];
        this._mainHolderCustomer   = '';
        this.errorMainHolder       = false;
    }
    @track filterClientsValue;
    @api get filterClients() { return this.filterClientsValue; }
    set filterClients(v) {
        const next    = v || null;
        const changed = this.filterClientsValue !== next;
        this.filterClientsValue = next;
        if (changed) {
            if (this._searchDate) {
                this._loadInitialData();
            } else {
                this._fetchDateAndLoad();
            }
        }
    }

    // ─── @track reactive state ────────────────────────────────────────────────
    @track allAvailableClients = [];
    @track searchText          = '';
    @track errorMainHolder     = false;
    @track _internalError      = false;

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
        if (!this._clientId) return;
        this._fetchDateAndLoad();
    }

    // ─── computed getters ─────────────────────────────────────────────────────
    get showInternalRating()    { return true; }
    get showCurrentRatingDate() { return true; }
    get showExpirationRatingDate() {
        return this.selectedTab === 'tcmopp';
    }
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

    get canSelectClients() {
        return !this._isReadOnlyUser && !this._isSubsidiary &&
            (this._stageName === 'Draft' || this._stageName === 'Ready to close');
    }

    get isClientSelectionDisabled() { return !this.canSelectClients; }

    get hasLoadedOnce() { return this._hasLoadedOnce; }

    get tableFrameClass() {
        return this._isSubsidiary ? 'table-frame table-frame--compact' : 'table-frame';
    }

    get showFilters() { return !this._isSubsidiary; }

    get totalColumns() {
        return 4
            + (this.showExpirationRatingDate ? 1 : 0)
            + (this.showExternalRating ? 1 : 0);
    }

    get visibleClients() {
        const selectedById = new Map(this.selectedClients.map(c => [c.customerId, c]));
        const query        = String(this.searchText || '').trim().toLowerCase();

        const filtered = this.allAvailableClients.filter(row => {
            const id = row.customerId || row[6];

            // Subsidiaries: informational display of the single associated client only.
            if (this._isSubsidiary) {
                return id === this._mainHolderCustomer;
            }

            if (!this.matchesBookingGeography(id)) return false;
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

    get showNoClientsForGeography() {
        return !this.isLoading && this.allAvailableClients.length === 0;
    }

    get noClientsMessage() {
        return 'No clients found for this geography.';
    }

    get isServiceUnavailable() { return this.serviceUnavailable || this._internalError; }

    get showSelectionSummary() { return !this.isServiceUnavailable && !this._isSubsidiary; }

    get isFiltersDisabled() { return this.isServiceUnavailable || this.isLoading || this._isSubsidiary; }

    // ─── private computed helpers ─────────────────────────────────────────────
    get _selectedCustomerIds() {
        return this.selectedClients.map(c => c.customerId);
    }


    // ─── data loading ─────────────────────────────────────────────────────────
    async _fetchDateAndLoad() {
        if (!this._searchDate) {
            try {
                const date = await lastDate();
                this._searchDate = date || null;
            } catch (error) {
                this._internalError = true;
                console.error('[dmt_select_clients_in_opportunity][lastDate]', error);
                return;
            }
        }
        await this._loadInitialData();
    }
    _hasAutoSwitchedExposure = false;
    // CIBGLOBALD-4344 - Tracks whether the user has deliberately picked a filter option, so the
    // With-Exposure-empty fallback only acts on the default/initial load, never overriding a
    // choice the user made themselves.
    _userManuallyChangedFilter = false;
    async _loadInitialData() {
        if (!this._clientId || !this._searchDate || !this.filterClientsValue) return;
        this.isLoading     = true;
        this.visibleRowLimit = this.batchSize;

        try {
            const data = await fetchInitialData(
                this._buildFetchParams({ page: this.page, pageSize: this.pageSize })
            );

            if (data?.success) {
                this._internalError      = false;
                this.groupedData         = data.data || [];
                if (this._shouldSwitchToAllExposure()) {
                     this._hasAutoSwitchedExposure = true;
                    this.filterClientsValue = 'Y/N';
                    await this._loadInitialData();
                return;
            }
                this.allAvailableClients = this._applyRatingExpiration(this.groupedData);
                this._hasLoadedOnce      = true;
                if (this._pendingInitialSelection) this._finalizeInitialSelection();
            } else {
                this._internalError = true;
                this._dispatchLoadError(data?.errorMessage || 'Unknown error loading data');
            }
        } catch (error) {
            this._internalError = true;
            this._dispatchLoadError(error);
        } finally {
            this.isLoading = false;
        }
    }
    // CIBGLOBALD-4344 - Also switches when, after applying this opportunity's booking geography,
    // the "With Exposure" result is empty altogether (not just missing the saved Main Holder).
    _shouldSwitchToAllExposure() {
        if (this._hasAutoSwitchedExposure || this._userManuallyChangedFilter || this.filterClientsValue !== 'Y') {
            return false;
        }

        const hasGeographyMatch = this.groupedData.some(c => this.matchesBookingGeography(c.customerId));
        if (!hasGeographyMatch) {
            return true;
        }

        return Boolean(this._mainHolderCustomer)
            && !this.groupedData.some(c => c.customerId === this._mainHolderCustomer);
    }
    @api fetchData(params) {
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
        this.fetchData(this._buildFetchParams({ page, pageSize: pageSz, bubbles: false }));
    }

    _finalizeInitialSelection() {
        this._pendingInitialSelection = false;
        this._hasInitializedSelection = true;
    }

    _buildFetchParams(overrides = {}) {
        return {
            selectedTab:         this.selectedTab,
            clientId:            this._clientId,
            lCountries:          this.countries,
            searchDate:          this._searchDate,
            clientPositionsType: this.filterClients,
            ...overrides
        };
    }

    _cloneClients(arr) {
        return arr.map(c => ({ ...c }));
    }

    // ─── selection logic ──────────────────────────────────────────────────────
    handleClientNameToggle(event) {
        if (!this.canSelectClients) return;
        const customerId = event.currentTarget?.dataset?.id;
        if (!customerId) return;

        const idx = this.selectedClients.findIndex(c => c.customerId === customerId);
        if (idx !== -1) {
            if (this._mainHolderCustomer === customerId && this.selectedClients.length === 1) {
                this._showMainBorrowerProtectionToast();
                return;
            }

            this._dispatchEditMode();
            this.selectedClients = this.selectedClients.filter(c => c.customerId !== customerId);

            if (this._mainHolderCustomer === customerId) {
                this._mainHolderCustomer = this.selectedClients[0]?.customerId || '';
                this.errorMainHolder     = false;
                this._dispatchViewModeMainHolder();
            }
        } else {
            this._dispatchEditMode();
            const full = this.groupedData.find(c => c.customerId === customerId);
            if (full) this.selectedClients = [...this.selectedClients, { ...full }];
            if (!this._mainHolderCustomer && this.selectedClients.length === 1) {
                this._mainHolderCustomer = customerId;
            }
        }

        this._mainHolderSelectRows = this._selectedCustomerIds;
        this.errorMainHolder       = false;
        this._dispatchViewModeSelection();
    }

    // ─── main borrower toggle ─────────────────────────────────────────────────
    handleMainHolderToggle(event) {
        if (!this.canSelectClients) return;
        const customerId = event.target.dataset.id;
        if (!customerId) return;

        if (!event.target.checked && this._mainHolderCustomer === customerId) {
            event.target.checked = true;
            this._showMainBorrowerProtectionToast();
            return;
        }

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
        this._userManuallyChangedFilter = true;
        this.filterClientsValue = event.detail.value;
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
    _dispatchCustomEvent(name, detail) {
        this.dispatchEvent(new CustomEvent(name, { ...CUSTOM_EVENT_OPTIONS, detail }));
    }

    _dispatchEditMode() {
        this._dispatchCustomEvent('editmode');
    }

    _dispatchViewModeSelection() {
        this._dispatchCustomEvent('viewmodeselection', {
            selectedClients: this._selectedCustomerIds.map(customerId => ({ customerId })),
            isUserAction: true
        });
    }

    _dispatchViewModeMainHolder() {
        const originalRecord = this.groupedData.find(c => c.customerId === this._mainHolderCustomer)
            || this.selectedClients.find(c => c.customerId === this._mainHolderCustomer)
            || null;
        this._dispatchCustomEvent('viewmodemainholder', {
            mainHolder: this._mainHolderCustomer || null, originalRecord, isUserAction: true
        });
    }

    _dispatchLoadError(error) {
        const rawMessage = (error && typeof error === 'object')
            ? (error.body?.message || error.message || JSON.stringify(error))
            : String(error);
        this._dispatchCustomEvent('loaderror', { error, message: rawMessage });
    }

    matchesBookingGeography(customerId) {
        const bookingPrefix = String(this.booking || '').trim().toUpperCase();
        if (!bookingPrefix) {
            return true;
        }

        const customer = String(customerId || '').toUpperCase();
        return customer.startsWith(bookingPrefix);
    }

    _showMainBorrowerProtectionToast() {
        this.dispatchEvent(new ShowToastEvent(MAIN_BORROWER_TOAST));
    }

}