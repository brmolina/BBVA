import { LightningElement, api, track } from 'lwc';
import DMT_HELPTEXT_WARNING from '@salesforce/label/c.DMT_ReadOnly_Warningtooltip';

export default class DatatablePicklist extends LightningElement {
    @api label;
    @api placeholder;
    @api options;
    @api value;
    @api context;
    @api fieldname;
    @api isdisabled;
    @api requieresvaluerecopick;
    @api showreadonlywarning;
    @api optionslimit;

    @track optionsValue = [];
    @track showDropdown = false;
    @track _coords = { left: 0, width: 0, val: 0, placement: 'bottom' };
    @track focusedIndex = -1;

    _readOnly = false;
    _preventBlurClose = false;
    _handlerScroll;

    labels = { DMT_HELPTEXT_WARNING };

    @api
    get readonlyAttr() {
        return this._readOnly;
    }
    set readonlyAttr(val) {
        this._readOnly = val;
        if (this.value === "All") {
            this._readOnly = true;
        }
    }

    @api
    focus() {
        const input = this.template.querySelector('.picklist-trigger');
        if (input) {
            input.focus();
        }
    }

    @api
    get readonlywarning() {     
        return (this.value == "Edit" || this.value == "All") && this.showreadonlywarning;
    }

    connectedCallback() {
        this.initOptions();
        this._handlerScroll = this.handleWindowScroll.bind(this);
    }

    // Standardized option initialization
    initOptions() {
        let opts = Array.isArray(this.options) ? JSON.parse(JSON.stringify(this.options)) : [];
        if (this.optionslimit) {
            const index = opts.findIndex(o => o.value === this.optionslimit);
            if (index !== -1) opts = opts.slice(index + 1);
        }
        if (this.value && !opts.find(o => o.value === this.value)) {
            opts.push({ label: this.label || this.value, value: this.value });
        }
        this.optionsValue = opts.map(opt => ({
            ...opt,
            className: 'slds-media slds-listbox__option slds-listbox__option_plain slds-media_small'
        }));
    }

    updateOptionsWithFocus() {
        this.optionsValue = this.optionsValue.map((opt, index) => ({
            ...opt,
            className: index === this.focusedIndex 
                ? 'slds-media slds-listbox__option slds-listbox__option_plain slds-media_small slds-has-focus' 
                : 'slds-media slds-listbox__option slds-listbox__option_plain slds-media_small'
        }));
    }

    get selectedLabel() {
        if (!this.value) return '';
        const found = this.optionsValue.find(opt => opt.value === this.value);
        return found ? found.label : this.value;
    }

    @api get readOnlyField() {
        return this._readOnly || (this.isdisabled || this.requieresvaluerecopick);
    }

    get dropdownStyle() {
        if (!this.showDropdown) return 'display:none;';
        const verticalStyle = this._coords.placement === 'bottom'
            ? `top: ${this._coords.val}px; bottom: auto;`
            : `bottom: ${this._coords.val}px; top: auto;`;

        return `position: fixed; left: ${this._coords.left}px; width: ${this._coords.width}px; ${verticalStyle} z-index: 999999; max-height: 200px; overflow-y: auto; background: white; border: 1px solid #dddbda; border-radius: 0.25rem; box-shadow: 0 2px 3px 0 rgba(0, 0, 0, 0.16);`;
    }

    // --- KEYBOARD & FOCUS LOGIC ---

    handleWrapperFocus(event) {
        // Prevents infinite loops and forces focus to the actual input
        if (event.target === event.currentTarget) {
            this.focus();
        }
    }

    handleKeyDown(event) {
        const keyCode = event.keyCode;

        // Open on Up (38), Down (40), or Enter (13) if closed
        if ((keyCode === 38 || keyCode === 40 || keyCode === 13) && !this.showDropdown) {
            event.preventDefault();
            event.stopPropagation();
            this.openDropdown();
            return;
        }

        if (this.showDropdown) {
            if (keyCode === 40) { // Down
                event.preventDefault();
                event.stopPropagation();
                this.focusedIndex = (this.focusedIndex >= this.optionsValue.length - 1) ? 0 : this.focusedIndex + 1;
                this.updateOptionsWithFocus();
                this.scrollToFocusedOption();
            } 
            else if (keyCode === 38) { // Up
                event.preventDefault();
                event.stopPropagation();
                this.focusedIndex = (this.focusedIndex <= 0) ? this.optionsValue.length - 1 : this.focusedIndex - 1;
                this.updateOptionsWithFocus();
                this.scrollToFocusedOption();
            } 
            else if (keyCode === 13 || keyCode === 9) { // Enter or Tab
                if (this.focusedIndex >= 0) {
                    if (keyCode === 13) {
                        event.preventDefault();
                        event.stopPropagation();
                    }
                    this.selectOption(this.optionsValue[this.focusedIndex].value);
                } else {
                    this.closeDropdown();
                }
            } 
            else if (keyCode === 27) { // Esc
                event.preventDefault();
                event.stopPropagation();
                this.closeDropdown();
            }
        }
    }

    openDropdown() {
        if (this.readOnlyField || this.showDropdown) return;
        
        this.showDropdown = true;
        const currentIdx = this.optionsValue.findIndex(opt => opt.value === this.value);
        this.focusedIndex = currentIdx >= 0 ? currentIdx : 0;
        this.updateOptionsWithFocus();

        window.addEventListener('scroll', this._handlerScroll, true);
        requestAnimationFrame(() => {
            this._measurePosition();
            this.scrollToFocusedOption();
        });
    }

    handleInputClick() {
        if (this.showDropdown) {
            this.closeDropdown();
        } else {
            this.openDropdown();
        }
    }

    selectOption(newVal) {
        // [CRITICAL] This updates the internal value so the UI and Parent see the change
        this.value = newVal; 
        
        this.closeDropdown();

        // Ensure the event detail structure matches exactly what the Master branch did
        this.dispatchEvent(new CustomEvent('picklistchanged', {
            composed: true, 
            bubbles: true, 
            cancelable: true,
            detail: { 
                data: { 
                    context: this.context, 
                    value: this.value, 
                    fieldname: this.fieldname 
                } 
            }
        }));
    }

    closeDropdown() {
        this.showDropdown = false;
        this.focusedIndex = -1;
        this.updateOptionsWithFocus();
        window.removeEventListener('scroll', this._handlerScroll, true);
    }

    handleSelect(event) {
        this.selectOption(event.currentTarget.dataset.value);
    }

    scrollToFocusedOption() {
        // Use timeout to ensure DOM update is finished
        setTimeout(() => {
            const container = this.template.querySelector('.slds-listbox');
            const focusedElement = this.template.querySelector('.slds-has-focus');
            if (container && focusedElement) {
                const containerRect = container.getBoundingClientRect();
                const focusedRect = focusedElement.getBoundingClientRect();
                if (focusedRect.bottom > containerRect.bottom) {
                    container.scrollTop += (focusedRect.bottom - containerRect.bottom);
                } else if (focusedRect.top < containerRect.top) {
                    container.scrollTop -= (containerRect.top - focusedRect.top);
                }
            }
        }, 0);
    }

    _measurePosition() {
    const inputElement = this.template.querySelector('.picklist-trigger');
    if (!inputElement) return;

    const r = inputElement.getBoundingClientRect();
    
    // Check if we are inside a Modal by looking for the SLDS modal class
    const modalElement = this.template.host.closest('.slds-modal__container');
    let leftOffset = 0;
    let topOffset = 0;

    if (modalElement) {
        const modalRect = modalElement.getBoundingClientRect();
        // If we are in a modal, we subtract the modal's starting position
        // because 'position: fixed' inside a transform acts like 'position: absolute'
        leftOffset = modalRect.left;
        topOffset = modalRect.top;
    }

    const spaceBelow = window.innerHeight - r.bottom;
    let placement = spaceBelow < 200 ? 'top' : 'bottom';
    
    // Adjust vertical value if in modal
    let verticalVal;
    if (placement === 'top') {
        verticalVal = modalElement ? (r.top - topOffset - 5) : (window.innerHeight - r.top + 5);
    } else {
        verticalVal = modalElement ? (r.bottom - topOffset + 5) : (r.bottom + 5);
    }

    this._coords = { 
        left: r.left - leftOffset, // Subtract the modal's left position
        width: r.width, 
        placement: placement, 
        val: verticalVal 
    };
}

    handleBlur() {
        setTimeout(() => { if (!this._preventBlurClose) this.closeDropdown(); }, 200);
    }

    handleDropdownMouseDown() {
        this._preventBlurClose = true;
        setTimeout(() => (this._preventBlurClose = false), 0);
    }

    handleWindowScroll() {
        if (this.showDropdown) this.closeDropdown();
    }
}