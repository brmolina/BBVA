import { LightningElement, api, track } from 'lwc';
import searchClientsFromLocal from '@salesforce/apex/DMT_UnderwritingFormController.searchClientsFromLocal';

export default class Dmt_generic_record_picker extends LightningElement {
    @api value;
    @api fieldname;
    @api placeholder;
    @api disabled;
    @api variant;
    @api label;

    _context;
    @api get context() { return this._context; }
    set context(v) { this._context = v; }

    @track searchText = '';
    @track options = [];
    @track isLoading = false;
    @track showDropdown = false;
    @track selectedLabel = '';

    dropdownStyle = 'display:none;';
    _preventBlurClose = false;
    _isFocused = false;
    _isTyping = false;

    updateDropdownPosition() {
        const input = this.template.querySelector('lightning-input');
        const native = input?.shadowRoot?.querySelector('input');
        if (!native) return;

        const r = native.getBoundingClientRect();
        const top = r.bottom + 4;
        const left = r.left;
        const width = r.width;

        this.dropdownStyle = `
            position: fixed;
            top: ${top}px;
            left: ${left}px;
            width: ${width}px;
            z-index: 999999;
            max-height: 220px;
            overflow-y: auto;
            display: block;
        `;
    }

    handleFocus = () => {
        this._isFocused = true;
        this._isTyping = false;

        if (this.options.length || this.isLoading) {
            this.showDropdown = true;
            this.updateDropdownPosition();
        }
    };

    handleBlur = () => {
        this._isFocused = false;

        window.setTimeout(() => {
            if (this._preventBlurClose) return;
            this.showDropdown = false;
            this.dropdownStyle = 'display:none;';
            this._isTyping = false;
        }, 150);
    };

    handleDropdownMouseDown = () => {
        this._preventBlurClose = true;
        window.setTimeout(() => (this._preventBlurClose = false), 0);
    };

    async handleInputChange(event) {
        this._isTyping = true;
        this.searchText = event.target.value;
        console.log('input:', event.target.value);

        if (!this.searchText) {
            this.value = null;
            this.selectedLabel = '';
            this.options = [];
            this.showDropdown = false;

            this.dispatchEvent(new CustomEvent('recordpickerchange', {
                composed: true,
                bubbles: true,
                detail: {
                    data: {
                        context: this.context,
                        value: null,
                        label: '',
                        fieldname: this.fieldname
                    }
                }
            }));
            return;
        }

        if (this.value && this.searchText !== this.selectedLabel) {
            this.value = null;
            this.selectedLabel = '';
        }

        if (!this.searchText || this.searchText.length < 2) {
            this.options = [];
            this.showDropdown = false;
            this.dropdownStyle = 'display:none;';
            return;
        }

        this.isLoading = true;
        this.showDropdown = true;
        this.updateDropdownPosition();

        try {
            const result = await searchClientsFromLocal({ searchTerm: this.searchText });
            console.log('output:', result);
            this.options = (result || []).map(r => ({
                value: r.value,
                label: r.label
            }));

            if (this.options.length) {
                this.showDropdown = true;
                this.updateDropdownPosition();
            }
        } catch (error) {
            console.error('Error searching clients', error);
            this.options = [];
        } finally {
            this.isLoading = false;
        }
    }

    handleSelect(event) {
        event.preventDefault();
        event.stopPropagation();
        const recordId = event.currentTarget.dataset.id || event.currentTarget.dataset.value;
        const recordLabel = event.currentTarget.dataset.label;
    
        if (!recordId) {
            console.warn('No recordId found in dataset. Check data-id/data-value in HTML.', event.currentTarget.dataset);
            return;
        }
    
        this._preventBlurClose = true;
        this.value = recordId;
        this.selectedLabel = recordLabel;
        this.searchText = recordLabel;
        this.showDropdown = false;
        this.dropdownStyle = 'display:none;';
    
        this.dispatchEvent(new CustomEvent('recordpickerchange', {
            composed: true,
            bubbles: true,
            detail: {
                data: {
                    context: this.context,
                    value: recordId,
                    label: recordLabel,
                    fieldname: this.fieldname
                }
            }
        }));

        window.setTimeout(() => (this._preventBlurClose = false), 0);
    }

    renderedCallback() {
        if (!this._isFocused && !this._isTyping && this.value && this.label && this.searchText !== this.label) {
            this.searchText = this.label;
            this.selectedLabel = this.label;
        }

        if (!this.value && !this._isFocused && !this._isTyping && this.searchText) {
            this.searchText = '';
            this.selectedLabel = '';
        }
    }
    
}