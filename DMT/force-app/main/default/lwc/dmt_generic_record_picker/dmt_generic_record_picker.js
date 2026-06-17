import { LightningElement, api, track } from 'lwc';

export default class Dmt_generic_record_picker extends LightningElement {

    static delegatesFocus = true;

    @api value;
    @api fieldname;
    @api placeholder;
    @api disabled;
    @api variant;
    @api label;

    _context;
    @api get context() { return this._context; }
    set context(v) { this._context = v; }

    @api options = []; 
    
    @track searchText = '';
    @track showDropdown = false;
    @track selectedLabel = '';
    
    @track _displayOptions = [];
    @track highlightedIndex = 0;

    // Coordinates for the floating dropdown
    @track _coords = { top: 0, left: 0, width: 0 };

    _preventBlurClose = false;
    _isFocused = false;
    _handlerScroll;

    connectedCallback() {
        this._handlerScroll = this.handleWindowScroll.bind(this);
        console.log(`[PICKER-DEBUG] connectedCallback - Row ID: ${this.context} | Initial Value: ${this.value} | Initial Label: ${this.label}`);
    }

    handleWindowScroll() {
        if (this.showDropdown) {
            this.closeDropdown();
        }
    }

    // Coordinates for the floating dropdown
    @track _coords = { left: 0, width: 0, val: 0, placement: 'bottom', isModal: false };

    // Dynamic CSS for the floating dropdown (Only dynamic values)
    get dropdownStyle() {
        if (!this.showDropdown) {
            return 'display:none;';
        }

        const posStrategy = this._coords.isModal ? 'absolute' : 'fixed';

        // If inside a modal, we use absolute positioning and calculate top manually when opening upwards
        const verticalStyle = this._coords.placement === 'bottom'
            ? `top: ${this._coords.val}px; bottom: auto;`
            : `bottom: ${this._coords.isModal ? 'auto' : this._coords.val + 'px'}; top: ${this._coords.isModal ? (this._coords.val - 200) + 'px' : 'auto'};`;

        return `position: ${posStrategy}; left: ${this._coords.left}px; width: ${this._coords.width}px; ${verticalStyle}`;
    }

    // Adds 'slds-has-focus' class to the item currently highlighted by keyboard
    get computedOptions() {
        return this._displayOptions.map((opt, index) => {
            return {
                ...opt,
                cssClass: index === this.highlightedIndex 
                    ? 'slds-listbox__option slds-listbox__option_plain slds-media slds-media_small slds-media_center slds-p-around_x-small slds-has-focus'
                    : 'slds-listbox__option slds-listbox__option_plain slds-media slds-media_small slds-media_center slds-p-around_x-small'
            };
        });
    }

    // Calculates position relative to viewport and checks for Modal boundaries
    _measurePosition() {
        const inputWrapper = this.template.querySelector('lightning-input');
        if (!inputWrapper) return;

        let targetElement = inputWrapper;
        if (inputWrapper.shadowRoot) {
            const native = inputWrapper.shadowRoot.querySelector('input');
            if (native) targetElement = native;
        }

        const r = targetElement.getBoundingClientRect();
        
        // Modal detection logic (Exactly the same as the Picklist)
        const modalElement = this.template.host.closest('.slds-modal__container');
        let leftOffset = 0;
        let topOffset = 0;

        if (modalElement) {
            const modalRect = modalElement.getBoundingClientRect();
            leftOffset = modalRect.left;
            topOffset = modalRect.top;
        }

        const spaceBelow = window.innerHeight - r.bottom;
        const dropdownHeight = 200; 
        
        let placement = spaceBelow < dropdownHeight ? 'top' : 'bottom';
        
        // Adjust vertical value if in modal
        let verticalVal;
        if (placement === 'top') {
            verticalVal = modalElement ? (r.top - topOffset - 5) : (window.innerHeight - r.top + 5);
        } else {
            verticalVal = modalElement ? (r.bottom - topOffset + 5) : (r.bottom + 5);
        }

        this._coords = { 
            left: r.left - leftOffset, 
            width: r.width,
            placement: placement,
            val: verticalVal,
            isModal: !!modalElement
        };
    }

    handleFocus = () => {
        this._isFocused = true;
        // Notify parent datatable to help sync focus
        this.dispatchEvent(new CustomEvent('focus', { bubbles: true, composed: true }));
        
        this.filterOptions(this.searchText);
        if (this._displayOptions.length > 0) {
            this.openDropdown();
        }
    };

    handleBlur = () => {
        this._isFocused = false;
        window.setTimeout(() => {
            if (this._preventBlurClose) return;
            this.closeDropdown();
        }, 200);
    };

    handleDropdownMouseDown = () => {
        this._preventBlurClose = true;
        window.setTimeout(() => (this._preventBlurClose = false), 0);
    };

    handleInputChange(event) {
        this.searchText = event.target.value;

        // If cleared via 'X' button or backspace, close immediately
        if (!this.searchText) {
            this.notifyChange(null, '');
            this.closeDropdown();
            return;
        }

        if (this.value && this.searchText !== this.selectedLabel) {
            this.notifyChange(null, '');
        }

        this.filterOptions(this.searchText);

        if (this._displayOptions.length > 0) {
            this.openDropdown();
        } else {
            this.closeDropdown();
        }
    }

    openDropdown() {
        this.showDropdown = true;
        window.addEventListener('scroll', this._handlerScroll, true); 
        // Use requestAnimationFrame to ensure DOM is ready for measurement
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        requestAnimationFrame(() => this._measurePosition());
    }

    closeDropdown() {
        this.showDropdown = false;
        window.removeEventListener('scroll', this._handlerScroll, true);
    }

    filterOptions(term) {
        this.highlightedIndex = 0;
        if (!this.options || this.options.length === 0) {
            this._displayOptions = [];
            return;
        }
        if (!term) {
            this._displayOptions = [...this.options];
        } else {
            const lowerTerm = term.toLowerCase();
            this._displayOptions = this.options.filter(opt => 
                opt.label && opt.label.toLowerCase().includes(lowerTerm)
            );
        }
    }

    handleSelect(event) {
        event.preventDefault();
        event.stopPropagation();
        const recordId = event.currentTarget.dataset.value;
        const recordLabel = event.currentTarget.dataset.label;
    
        this._preventBlurClose = true;
        this.searchText = recordLabel;
        
        this.closeDropdown();
        this.notifyChange(recordId, recordLabel);

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        window.setTimeout(() => (this._preventBlurClose = false), 0);
    }

    notifyChange(val, lbl) {
        this.value = val;
        this.selectedLabel = lbl;
        
        this.dispatchEvent(new CustomEvent('recordpickerchange', {
            composed: true,
            bubbles: true,
            detail: {
                data: {
                    context: this.context,
                    value: val,
                    label: lbl,
                    fieldname: this.fieldname
                }
            }
        }));
    }

    renderedCallback() {
        console.log(`[PICKER-DEBUG] renderedCallback - Row ID: ${this.context} | Current searchText: ${this.searchText} | Incoming @api label: ${this.label} | Incoming @api value: ${this.value}`);
        if (!this._isFocused && this.value && this.label && this.searchText !== this.label) {
            console.log(`[PICKER-DEBUG] Overwriting searchText with label: ${this.label}`);
            this.searchText = this.label;
            this.selectedLabel = this.label;
        }
    }

    handleKeyDown(event) {
        if (!this.showDropdown || this._displayOptions.length === 0) return;

        if (event.key === 'ArrowDown') {
            event.preventDefault(); 
            event.stopPropagation();
            if (this.highlightedIndex < this._displayOptions.length - 1) {
                this.highlightedIndex++;
                this.scrollToHighlighted();
            }
        } 
        else if (event.key === 'ArrowUp') {
            event.preventDefault();
            event.stopPropagation();
            if (this.highlightedIndex > 0) {
                this.highlightedIndex--;
                this.scrollToHighlighted();
            }
        } 
        else if (event.key === 'Enter' || event.key === 'Tab') {
            const selectedOption = this._displayOptions[this.highlightedIndex];
            
            if (selectedOption) {
                this.searchText = selectedOption.label;
                this.notifyChange(selectedOption.value, selectedOption.label);
                this.closeDropdown();
                
                // On Enter, we prevent the form submit but keep focus in the input
                // so the user can hit Tab manually to move to the next field.
                if (event.key === 'Enter') {
                    event.preventDefault();
                    event.stopPropagation();
                }
            }
        }
        
        // Escape closes the list AND clears the value
        if (event.key === 'Escape') {
            event.preventDefault();
            this.closeDropdown();
            this.searchText = '';
            this.notifyChange(null, '');
        }
    }

    scrollToHighlighted() {
        const el = this.template.querySelector(`[data-index="${this.highlightedIndex}"]`);
        if (el) {
            el.scrollIntoView({ block: 'nearest' });
        }
    }
}