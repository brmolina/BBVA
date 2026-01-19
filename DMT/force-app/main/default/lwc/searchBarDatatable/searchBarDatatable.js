import { LightningElement, api, track } from 'lwc';
import { FlexCardMixin } from 'omnistudio/flexCardMixin';

export default class SearchBarDatatable extends FlexCardMixin(LightningElement) {

    @track info;

    initialRecords = [];
    catalog;
    _isLwc = false;
    searchTimeout;

    // --- API properties ---
    @api
    get infoName() {
        return this.info;
    }

    set infoName(value) {
        if (value && Array.isArray(value)) {
            // Precompute a flattened searchable string for each record
            this.initialRecords = value.map(r => ({
                ...r,
                searchableText: this.flattenRecord(r)
            }));
        } else {
            this.initialRecords = [];
        }

        this.info = this.initialRecords;
    }

    @api
    get catalogName() {
        return this.catalog;
    }

    set catalogName(value) {
        this.catalog = value;
    }

    @api
    set isLwc(value) {
        this._isLwc = value;
    }

    get isLwc() {
        return this._isLwc;
    }

    // --- Helper: Flatten record into a searchable string ---
    flattenRecord(record) {
        let result = '';

        for (let val of Object.values(record)) {
            if (val && typeof val === 'object') {
                result += ' ' + Object.values(val).join(' ');
            } else if (val != null) {
                result += ' ' + val;
            }
        }

        return result.toLowerCase();
    }

    // --- Row selection event ---
    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows;
        this.dispatchEvent(
            new CustomEvent('rowselected', {
                bubbles: true,
                composed: true,
                detail: { rowSelect: this.selectedRows[0]?.Id }
            })
        );
    }

    // --- Debounced search handler ---
    handleSearch(event) {
        clearTimeout(this.searchTimeout);
        const value = event.target.value;

        // Debounce: wait 250ms after user stops typing
        this.searchTimeout = setTimeout(() => {
            this.performSearch(value);
        }, 250);
    }

    // --- Perform the actual search ---
    performSearch(searchKey) {
        const key = (searchKey || '').toLowerCase();
        const eventName = this._isLwc ? 'datasearch' : 'dataSearch';

        if (key) {
            this.info = this.initialRecords.filter(r => r.searchableText.includes(key));
        } else {
            this.info = this.initialRecords;
        }

        this.dispatchEvent(
            new CustomEvent(eventName, {
                bubbles: true,
                composed: true,
                detail: { dataFind: this.info, catalog: this.catalog }
            })
        );
    }
}