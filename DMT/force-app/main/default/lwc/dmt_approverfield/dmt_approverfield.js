import { LightningElement, api, track, wire } from 'lwc';
import searchApprovers from '@salesforce/apex/DMT_ApproverLookupController.searchApprovers';
import getApproverById from '@salesforce/apex/DMT_ApproverLookupController.getApproverById';

export default class Dmt_approverfield extends LightningElement {
    @api label = 'Approver';
    @api required = false;
    @api disabled = false;
    @api placeholder = 'Search approvers...';
    
    haveMembers = false
    @track searchResults = [];
    @track selectedApprover = null;
    @track showDropdown = true;
    @track isLoading = false;
    @track searchTerm = '';
    
    renderedCallback(){
        console.log('showDropdown', this.showDropdown);
    }
    // Manejar la selección
    handleSelect(event) {
        const approverId = event.currentTarget.dataset.id;
        this.handleLookupSelection(approverId);
    }
    
    // Buscar approvers
    handleSearch(event) {
        this.searchTerm = event.target.value;
        
        if (this.searchTerm.length < 2) {
            this.searchResults = [];
            this.showDropdown = false;
            return;
        }
        
        this.isLoading = true;
        
        searchApprovers({ 
            searchTerm: this.searchTerm, 
            maxResults: 10 
        })
        .then(results => {
            this.searchResults = results;
            this.showDropdown = true;
            this.isLoading = false;
            this.haveMembers = true
        })
        .catch(error => {
            console.error('Error searching approvers:', error);
            this.isLoading = false;
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
            this.dispatchEvent(new CustomEvent('change', {
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
        
        this.dispatchEvent(new CustomEvent('change', {
            detail: null
        }));
    }
    
    // Cerrar dropdown al hacer clic fuera
    handleBlur() {
        setTimeout(() => {
            this.showDropdown = false;
        }, 200);
    }
}