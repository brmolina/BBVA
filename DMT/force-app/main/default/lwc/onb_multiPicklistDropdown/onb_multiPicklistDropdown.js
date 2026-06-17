import { LightningElement, api } from 'lwc';

export default class Onb_multiPicklistDropdown extends LightningElement {
    @api options = [];                 // [{label, value}]
    @api value = '';                   // Salesforce format: "A;B;C"
    @api placeholder = 'Select an option';
    @api disabled = false;

    isOpen = false;

    _docClickHandler;

    connectedCallback() {
        this._docClickHandler = () => {
            if (this.isOpen) this.isOpen = false;
        };
        document.addEventListener('click', this._docClickHandler);
    }

    disconnectedCallback() {
        document.removeEventListener('click', this._docClickHandler);
    }

    // Prevent clicks inside from closing (document listener)
    handleInsideClick(event) {
        event.stopPropagation();
    }

    get selectedValues() {
        if (!this.value) return [];
        return this.value.split(';').filter(Boolean);
    }

    get selectedCount() {
        return this.selectedValues.length;
    }

    get displayText() {
        return this.selectedCount ? `${this.selectedCount} selected` : this.placeholder;
    }

    get comboboxClass() {
        return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ${this.isOpen ? 'slds-is-open' : ''}`;
    }

    get hasOptions() {
        return Array.isArray(this.options) && this.options.length > 0;
    }

    get optionsWithChecked() {
        const selected = new Set(this.selectedValues);
        return (this.options || []).map(o => ({ ...o, _checked: selected.has(o.value) }));
    }

    toggle(event) {
        event.stopPropagation();
        if (this.disabled) return;
        this.isOpen = !this.isOpen;
    }

    // Avoid double toggle when clicking checkbox (bubbles to option div otherwise)
    handleCheckboxClick(event) {
        event.stopPropagation();
    }

    // Click anywhere on the option row toggles selection
    handleOptionClick(event) {
        event.stopPropagation();
        const v = event.currentTarget.dataset.value;
        if (!v) return;

        const set = new Set(this.selectedValues);
        if (set.has(v)) set.delete(v);
        else set.add(v);

        this.applyNewValue(Array.from(set).join(';'));
    }

    // Checkbox change also updates selection
    handleToggleValue(event) {
        event.stopPropagation();

        const v = event.currentTarget.dataset.value;
        const checked = event.target.checked;

        const set = new Set(this.selectedValues);
        if (checked) set.add(v);
        else set.delete(v);

        this.applyNewValue(Array.from(set).join(';'));
    }

    applyNewValue(newValue) {
        this.value = newValue;
        this.dispatchEvent(new CustomEvent('change', {
            detail: { value: newValue },
            bubbles: true,
            composed: true
        }));
    }
}