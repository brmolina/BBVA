import { LightningElement, api, track } from 'lwc';
import searchRecords  from '@salesforce/apex/DMT_FormLookupController.searchRecords';
import getRecordLabel from '@salesforce/apex/DMT_FormLookupController.getRecordLabel';

const SEARCH_DELAY = 300;
const KEY_ESCAPE   = 27;
const KEY_UP       = 38;
const KEY_DOWN     = 40;
const KEY_ENTER    = 13;

export default class dmt_custom_lookup extends LightningElement {

    @api primaryField    = 'Name';
    @api secondaryFields = [];
    @api searchFields    = [];
    @api returnFields    = [];
    @api objectApiName   = '';
    @api filters         = null;
    @api label           = '';
    @api placeholder     = 'Search...';
    @api required        = false;
    @api disabled        = false;
    @api iconName        = 'standard:record';
    @api recordLimit     = 20;

    get disabledInput() {
        return this.showInputSpinner || this.disabled;
    }

    @api get value() {
        return this._value;
    }
    set value(v) {
        if (v && typeof v === 'string' && v !== 'null' && v !== 'undefined') {
            this._value = v;
            // Skip resolving if the record was already set from the results list with this same Id
            const alreadyResolved = this._selectedRecord &&
                (this._selectedRecord.id || this._selectedRecord.Id) === v;
            if (this.objectApiName && !alreadyResolved) {
                this._resolveById(v);
            }
        } else {
            this._value          = null;
            this._selectedRecord = null;
        }
    }

    _value            = null;
    @track _searchTerm       = '';
    @track _hasFocus         = false;
    @track _selectedRecord   = null;
    @track _focusedIndex     = null;
    @track _options          = [];
    @track _isLoading        = false;
    @track _isResolvingLabel = false;

    _cancelBlur     = false;
    _searchTimeout  = null;
    _lastSearchTerm = null;

    // ─── Computed properties ──────────────────────────────────────────────────

    get _filteredOptions() {
        return this._options;
    }

    get displayOptions() {
        return this._filteredOptions.map((opt, i) => {
            const secondary = this._buildSecondaryLabel(opt);
            let cls = 'slds-media slds-media_center slds-listbox__option slds-listbox__option_entity';
            if (secondary)               cls += ' slds-listbox__option_has-meta';
            if (this._focusedIndex === i) cls += ' slds-has-focus';
            return {
                ...opt,
                _primaryLabel  : String(opt[this.primaryField] ?? ''),
                _secondaryLabel: secondary,
                _hasSecondary  : !!secondary,
                _itemClass     : cls
            };
        });
    }

    get _hasSelection() { return this._selectedRecord !== null; }
    get _hasResults()   { return this._options.length > 0; }
    get isListboxOpen() { return this._hasFocus && !this._hasSelection; }

    get showNoResults() {
        return !this._isLoading && !this._hasResults && this._hasFocus && !this._hasSelection;
    }

    get comboboxClass() {
        return 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ' +
               (this.isListboxOpen ? 'slds-is-open' : '');
    }

    get inputFormClass() {
        return 'slds-combobox__form-element slds-input-has-icon ' +
               (this._hasSelection ? 'slds-input-has-icon_left-right' : 'slds-input-has-icon_right');
    }

    get inputClass() {
        return 'slds-input slds-combobox__input ' +
               (this._hasSelection ? 'slds-combobox__input-value' : '');
    }

    get listboxClass() { return 'slds-dropdown slds-dropdown_fluid'; }

    get selectIconClass() {
        return 'slds-combobox__input-entity-icon ' + (this._hasSelection ? '' : 'slds-hide');
    }

    get searchIconClass() {
        return 'slds-input__icon slds-input__icon_right ' +
               (this._hasSelection || this._isLoading || this._isResolvingLabel ? 'slds-hide' : '');
    }

    get clearButtonClass() {
        return 'slds-button slds-button_icon slds-input__icon slds-input__icon_right ' +
               (this._hasSelection && !this._isResolvingLabel ? '' : 'slds-hide');
    }

    get showInputSpinner() { return this._isResolvingLabel; }

    get inputValue() {
        return this._hasSelection
            ? String(this._selectedRecord[this.primaryField] ?? '')
            : this._searchTerm;
    }

    // ─── Private helpers ──────────────────────────────────────────────────────

    // Fetches the label for a record Id set externally (e.g. from a parent component)
    _resolveById(recordId) {
        if (!recordId || !this.objectApiName || !this.primaryField) return;
        this._isResolvingLabel = true;
        getRecordLabel({ objectApiName: this.objectApiName, recordId, labelField: this.primaryField })
            .then(label => {
                if (this._value === recordId && label) {
                    this._selectedRecord = { id: recordId, [this.primaryField]: label };
                }
            })
            .catch(error => {
                console.error('dmt_custom_lookup _resolveById error:', error);
            })
            .finally(() => {
                this._isResolvingLabel = false;
            });
    }

    _buildSecondaryLabel(opt) {
        return (Array.isArray(this.secondaryFields) ? this.secondaryFields : [])
            .map(f => opt[f])
            .filter(v => v !== null && v !== undefined && v !== '')
            .join(' - ');
    }

    _dispatchChange(recordId) {
        this.dispatchEvent(new CustomEvent('change', {
            detail  : { recordId },
            bubbles : true,
            composed: true
        }));
    }

    _buildFiltersJson() {
        if (!this.filters) return null;
        if (Array.isArray(this.filters) && this.filters.length === 0) return null;
        try {
            return JSON.stringify(this.filters);
        } catch (e) {
            console.error('dmt_custom_lookup: invalid filters config', e);
            return null;
        }
    }

    _buildReturnFields() {
        const set = new Set(['Id']);
        set.add(this.primaryField);
        (this.secondaryFields || []).forEach(f => set.add(f));
        (this.returnFields    || []).forEach(f => set.add(f));
        return [...set];
    }

    // Debounces Apex calls; fires immediately for empty term (initial open)
    _search(term) {
        if (term === this._lastSearchTerm) return;
        this._lastSearchTerm = term;

        if (this._searchTimeout) {
            clearTimeout(this._searchTimeout);
            this._searchTimeout = null;
        }

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._searchTimeout = setTimeout(() => {
            this._searchTimeout = null;
            this._isLoading = true;
            searchRecords({
                objectApiName: this.objectApiName,
                searchTerm   : term,
                searchFields : this.searchFields.length > 0 ? this.searchFields : [this.primaryField],
                filtersJson  : this._buildFiltersJson(),
                returnFields : this._buildReturnFields(),
                primaryField : this.primaryField,
                recordLimit  : this.recordLimit || 20
            })
            .then(results => {
                this._options   = results || [];
                this._isLoading = false;
            })
            .catch(error => {
                console.error('dmt_custom_lookup search error:', error);
                this._options   = [];
                this._isLoading = false;
            });
        }, term === '' ? 0 : SEARCH_DELAY);
    }

    _scrollFocused() {
        const opt = this._options[this._focusedIndex];
        if (!opt) return;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            const el = this.template.querySelector(`[data-recordid="${opt.id || opt.Id}"]`);
            if (el) el.scrollIntoView({ block: 'nearest' });
        }, 0);
    }

    // ─── Lifecycle ────────────────────────────────────────────────────────────

    connectedCallback() {
        if (this._value && !this._selectedRecord) {
            this._resolveById(this._value);
        }
    }

    disconnectedCallback() {
        if (this._searchTimeout) clearTimeout(this._searchTimeout);
    }

    // ─── Event handlers ───────────────────────────────────────────────────────

    handleFocus() {
        if (this.disabled || this._hasSelection) return;
        this._hasFocus     = true;
        this._focusedIndex = null;
        this._isLoading    = true;
        this._search(this._searchTerm.trim());
    }

    handleBlur() {
        if (this.disabled || this._hasSelection || this._cancelBlur) return;
        this._hasFocus       = false;
        this._lastSearchTerm = null;
    }

    handleInput(event) {
        if (this._hasSelection) return;
        this._searchTerm   = event.target.value;
        this._focusedIndex = null;
        this._search(this._searchTerm.trim());
    }

    handleListboxMouseDown(event) {
        // Prevent blur from firing before click is processed
        if (event.button === 0) this._cancelBlur = true;
    }

    handleListboxMouseUp() {
        this._cancelBlur = false;
        this.template.querySelector('input').focus();
    }

    handleResultClick(event) {
        const recordId = event.currentTarget.dataset.recordid;
        const record   = this._options.find(o => (o.id || o.Id) === recordId);
        if (!record) return;
        this._selectedRecord = record;
        this._value          = record.id || record.Id;
        this._hasFocus       = false;
        this._focusedIndex   = null;
        this._options        = [];
        this._lastSearchTerm = null;
        this._dispatchChange(this._value);
    }

    handleClear(event) {
        event.stopPropagation();
        this._selectedRecord = null;
        this._value          = null;
        this._searchTerm     = '';
        this._hasFocus       = false;
        this._options        = [];
        this._lastSearchTerm = null;
        this._dispatchChange(null);
    }

    handleKeyDown(event) {
        if (this._focusedIndex === null) this._focusedIndex = -1;

        if (event.keyCode === KEY_ESCAPE) {
            this._hasFocus       = false;
            this._searchTerm     = '';
            this._options        = [];
            this._lastSearchTerm = null;
            return;
        }

        const opts = this._options;
        if (!opts.length) return;

        if (event.keyCode === KEY_DOWN) {
            event.preventDefault();
            this._focusedIndex = (this._focusedIndex + 1) >= opts.length ? 0 : this._focusedIndex + 1;
            this._scrollFocused();
        } else if (event.keyCode === KEY_UP) {
            event.preventDefault();
            this._focusedIndex = (this._focusedIndex - 1) < 0 ? opts.length - 1 : this._focusedIndex - 1;
            this._scrollFocused();
        } else if (event.keyCode === KEY_ENTER && this._focusedIndex >= 0) {
            event.preventDefault();
            const opt = opts[this._focusedIndex];
            if (opt) {
                const el = this.template.querySelector(`[data-recordid="${opt.id || opt.Id}"]`);
                if (el) el.click();
            }
        }
    }

    // ─── Public API ───────────────────────────────────────────────────────────

    @api clearSelection() {
        this._selectedRecord = null;
        this._value          = null;
        this._searchTerm     = '';
        this._hasFocus       = false;
        this._options        = [];
        this._lastSearchTerm = null;
    }

    @api validate() {
        const input = this.template.querySelector('input');
        return input ? input.reportValidity() : true;
    }
}