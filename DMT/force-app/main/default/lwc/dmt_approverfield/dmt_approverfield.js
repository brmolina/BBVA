import { LightningElement, api, track, wire } from 'lwc';
import searchApprovers from '@salesforce/apex/DMT_ApproverLookupController.searchApprovers';
import getApproverById from '@salesforce/apex/DMT_ApproverLookupController.getApproverById';

export default class Dmt_approverfield extends LightningElement {
    @api label = 'Approver';
    @api required = false;
    @api disabled = false;
    @api placeholder = 'Search approvers...';
    @api appType = 'Risk';
    @api appEntific = 'ES';
    @api fieldApiName;

    haveMembers = false
    @track searchResults = [];
    @track selectedApprover = null;
    @track showDropdown = false;
    @track isLoading = false;
    @track searchTerm = '';
    @track hasSearched = false;
    _valueId;
    _valueName;

    @api
    get valueId() { return this._valueId; }
    set valueId(v) {
        this._valueId = v;
        this.syncFromParent();
    }

    @api
    get valueName() { return this._valueName; }
    set valueName(v) {
        this._valueName = v;
        this.syncFromParent();
    }

    get hasSelection() {
    return !!this.selectedApprover?.id;
    }


    get hasResults() {
        return this.searchResults && this.searchResults.length > 0;
    }

    get showNoResults() {
        return this.hasSearched && !this.isLoading && !this.hasResults;
    }

     syncFromParent() {
    if (this._valueId === undefined) return;

    if (!this._valueId) {
      this.selectedApprover = null;
      this.searchTerm = '';
      return;
    }

    // Con Name ya no necesitas llamar a Apex
    this.selectedApprover = { id: this._valueId, name: this._valueName || '' };
    this.searchTerm = this._valueName || '';
  }




    renderedCallback(){
        console.log('showDropdown', this.showDropdown);
    }
    // Manejar la selección
    handleSelect(event) {
        event.preventDefault();
        event.stopPropagation();
        const approverId = event.target.dataset.id;
        console.log('JACG ' + approverId)
        this.handleLookupSelection(approverId);
    }

    // Buscar approvers
    handleSearch(event) {
        if (this.hasSelection) return;
        this.searchTerm = event.target.value;

        if (this.searchTerm.length < 2) {
            this.searchResults = [];
            this.showDropdown = false;
            this.hasSearched = false;
            return;
        }

        this.isLoading = true;
        this.hasSearched = false;

        searchApprovers({
            searchTerm: this.searchTerm,
            maxResults: 10 ,
            appType: this.appType,
            appEntific: this.appEntific,
            fieldApiName: this.fieldApiName
        })
        .then(results => {
            this.searchResults = results;
            this.showDropdown = true;
            this.isLoading = false;
            this.haveMembers = true;
            this.hasSearched = true;
        })
        .catch(error => {
            console.error('Error searching approvers:', error);
            this.isLoading = false;
            this.hasSearched = true;
        });
        this.showDropdown = true;
        console.log('len', this.searchResults?.length);
        console.log('searchApprovers', JSON.stringify(this.searchResults));
    }

    // Manejar selección de approver
    handleLookupSelection(approverId) {console.log('handleLookupSelection', approverId);
        getApproverById({ approverId: approverId })
        .then(result => {
            this.selectedApprover = result;
            this.searchTerm = result.name;
            this.showDropdown = false;
            this.searchResults = [];

            // Disparar evento de cambio
            this.dispatchEvent(new CustomEvent('changeedit', {
                detail: {
                    id: result.id,
                    name: result.name,
                    data: result
                }
            }));
        })
        .catch(error => {
            console.error('Error getting approver:', error);
        });
    }

    // Limpiar selección
    handleClear() {
    this.selectedApprover = null;
    this.searchTerm = '';
    this.searchResults = [];
    this.showDropdown = false;
    this.hasSearched = false;

    this.dispatchEvent(new CustomEvent('change', { detail: null }));

    // vuelve a focus para buscar otro
    requestAnimationFrame(() => {
      this.template.querySelector('input')?.focus();
    });
  }

    handleFocus() {
        if (this.searchTerm.length > 0) {
            this.showDropdown = true;
        }
    }

    // Cerrar dropdown al hacer clic fuera
    handleBlur() {
        setTimeout(() => {
            this.showDropdown = false;
        }, 500);
    }

    get comboboxClass() {
    return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ${this.showDropdown ? 'slds-is-open' : ''}`;
    }

    // Getter para cambiar el icono de búsqueda a "X" (clear)
    get rightIconName() {
        return this.searchTerm ? 'utility:clear' : 'utility:search';
    }
}