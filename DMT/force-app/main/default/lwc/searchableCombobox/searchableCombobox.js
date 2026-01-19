import { LightningElement,api } from "lwc";

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
    showResults = false;
    isInitialized = false;
    @api requieresvaluerecopick;
    @api isdisabled;
    @api
     get  changeread() {
       return this.changereadvalue;
     }
     set changeread(value) {
       this.readonly = value;
    }

     @api
     get  selectedSearchChange() {
       return this.selectedSearchChangeval;
     }
     set selectedSearchChange(value) {
       this.selectedValue = value;
    }

    @api
    get readOnlyUser(){
        return this.readonly || (this.isdisabled || this.requieresvaluerecopick);
    }

    connectedCallback() {
       
        this.selectedSearchResult = {value: this.selectedSearchvalue, label:this.selectedSearchlabel};
        this.selectedValue = this.selectedSearchResult?.label ?? '';
        if(this.readonlyAttr === "All"){
            this.readonly = true;
            this.typeInput = 'text';
        }
        this.addEventListener('changepicklist', this.handlePicklistChange.bind(this));
    }

    renderedCallback() {
        if (!this.isInitialized) {
            this.template.querySelector('.inputClass').addEventListener('click', (event) => {
                this.showPickListOptions(event.target);
                event.stopPropagation();
            });
            this.template.addEventListener('click', (event) => {
                event.stopPropagation();
            });
            document.addEventListener('click', () => {
                this.removeFocus();
            });
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
                //setTimeout(() => {
                    this.showResults = true;
                //}, 200.05);
            }else{
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
                }
            ));
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
                    data: { context: this.context, value: this.value, fieldname: this.fieldname}
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
            data: { context: this.context, value: this.value, fieldname: this.fieldname}
            }
            }));

            this.showResults = false;
    }

    /*clearSearchResults() {
        this.searchResults = null;
    }*/

    showPickListOptions() {
        //if (!this.searchResults) {
            this.searchResults = JSON.parse(JSON.stringify(this.pickListOrdered));
        //}
        this.showResults = true;
    }
}