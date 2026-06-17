import { LightningElement, api, track } from "lwc";

export default class SearchableCombobox extends LightningElement {

    @api pickListOrdered;
    searchResults;
    selectedSearchResult;
    @api selectedSearchlabel;
    @api selectedSearchvalue;
    selectedValue;
    @api context;
    @api readonlyAttr;
    @api fieldname;
    readonly = false;
    typeInput = 'search';
    @track showResults = false;
    isInitialized = false;
    @api requieresvaluerecopick;
    @api isdisabled;


    //pass style dynamically so we can handle  dropdown visibility
    @track dropdownStyle = '';
    //flag to handle scrolling inside the dropdown and blur when outside
    _isInsideDropdown = false;
    @api
    get changeread() {
        return this.changereadvalue;
    }
    set changeread(value) {
        this.readonly = value;
    }

    @api
    get selectedSearchChange() {
        return this.selectedSearchChangeval;
    }
    set selectedSearchChange(value) {
        this.selectedValue = value;
    }

    @api
    get readOnlyUser() {
        return this.readonly || (this.isdisabled || this.requieresvaluerecopick);
    }

    connectedCallback() {
        this.selectedSearchResult = { value: this.selectedSearchvalue, label: this.selectedSearchlabel };
        this.selectedValue = this.selectedSearchResult?.label ?? '';
        if (this.readonlyAttr === "All") {
            this.readonly = true;
            this.typeInput = 'text';
        }
        this.addEventListener('changepicklist', this.handlePicklistChange.bind(this));
    }

    renderedCallback() {
        //initialized flag to control redered callback
        if (!this.isInitialized) {
            //main click listener inside the input that displays dropdown, stopped propagation so it doesnt bubble outside our component
            this.template.querySelector('.inputClass').addEventListener('click', (event) => {
                this.showPickListOptions();
                event.stopPropagation();
            });

            // when clicking outside the component, we blur and hide dropdown
            document.addEventListener('click', () => {
                this.removeFocus();
            });

            // function passed to scroll event to handle hiding when scrolling but allowing scrolling inside dropdown
            const closeDropdownOnMove = () => {
                if (this._isInsideDropdown) {
                    return;
                }

                 if (this.showResults) {
                    this.showResults = false;
                }
            };
            //adding scrolling listeners
            window.addEventListener('scroll', closeDropdownOnMove, true);
            window.addEventListener('wheel', closeDropdownOnMove, true);
            window.addEventListener('touchmove', closeDropdownOnMove, true);

            this.isInitialized = true;
        }
    }



    handlePicklistChange(event) {
        if (event.detail.fieldname === this.fieldname && event.detail.context === this.context) {
            this.searchResults = JSON.parse(JSON.stringify(event.detail.data));
        }
    }

    search(event) {
        const input = event.detail.value.toLowerCase();
        if (this.selectedValue && (!input || (input && input.length == 0))) {
            this.showResults = true;
        } else {
            this.showResults = true;
            this.selectedValue = '';
        }
        const result = this.pickListOrdered.filter((pickListOption) =>
            pickListOption.label.toLowerCase().includes(input)
        );
        this.searchResults = result;
        this.dispatchEvent(new CustomEvent('removesearch', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: this.context
        }));
    }

    removeFocus() {
        setTimeout(() => {
            this.showResults = false;
        }, 200);
    }

    handleClear(event) {
        if (!event.target.value.length) {
            this.value = undefined;
            this.dispatchEvent(new CustomEvent('comboboxchange', {
                composed: true,
                bubbles: true,
                cancelable: true,
                detail: {
                    data: { context: this.context, value: this.value, fieldname: this.fieldname }
                }
            }));
        }
    }

    selectSearchResult(event) {
        this.showResults = true;
        const selectedValue = event.currentTarget.dataset.value;
        this.selectedSearchResult = this.pickListOrdered.find(
            (pickListOption) => pickListOption.value === selectedValue
        );
        this.selectedValue = this.selectedSearchResult.label;
        this.searchResults = JSON.parse(JSON.stringify(this.pickListOrdered));

        //show the selected value on UI
        this.value = selectedValue;

        //fire event to send context and selected value to the data table
        this.dispatchEvent(new CustomEvent('comboboxchange', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                data: { context: this.context, value: this.value, fieldname: this.fieldname }
            }
        }));

        this.showResults = false;
    }

    // main dropdown display. first
    showPickListOptions() {
        this.searchResults = JSON.parse(JSON.stringify(this.pickListOrdered));
        this.showResults = true;

        // Find the wrapper div to measure
        const anchorElement = this.template.querySelector('.anchor-measurement');

        if (anchorElement) {
            const rect = anchorElement.getBoundingClientRect();

            // Force fixed positioning, override SLDS transforms and margins
            this.dropdownStyle = `
                position: fixed;
                top: ${rect.bottom}px;
                left: ${rect.left}px;
                width: ${rect.width}px;
                z-index: 9999;
                margin: 0;
                transform: none;
                overscroll-behavior: contain;
            `;
        }
    }

    handleDropdownEnter() {
        this._isInsideDropdown = true;
    }

    handleDropdownLeave() {
        this._isInsideDropdown = false;
    }
}