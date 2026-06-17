import { LightningElement, api, wire } from 'lwc';
import hasWriteAccess from '@salesforce/apex/DMT_Utils.hasWriteAccess';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getApproversViews from '@salesforce/apex/DMT_ScreenViewManagementController.getApproversViews';
import getItemsForView from '@salesforce/apex/DMT_ScreenViewManagementController.getItemsForView';
import getDMTTypePicklistOptions from '@salesforce/apex/DMT_ScreenViewManagementController.getDMTTypePicklistOptions';
import upsertApproversViewWithItems from '@salesforce/apex/DMT_ScreenViewManagementController.upsertApproversViewWithItems';

const COLUMNS = [
    { label: 'Approvers View Name', fieldName: 'Name', type: 'text', sortable: true, hideDefaultActions: true },
    { label: 'Type', fieldName: 'DMT_Type__c', type: 'text', sortable: true, hideDefaultActions: true }
];
export default class Dmt_screen_view_management extends LightningElement {
    @api viewName = ''; // Name of the view to be created or edited
    @api isProfitability = false; // Whether the view is for profitability
    approversViews = [];
    filteredApproversViews = [];
    searchKey = '';
    @api selectedItems = [];

    @api viewSource = 'dmtScreenViewManagement';

    @api isVersionView = false;
    @api isOppScreenView = false;
    @api displayInOpportunity = false;

    @api currencyIsoCode = 'EUR';

    inputsDisabled = false;
    @api writeAccess;

    get submitLabel(){
        return  this.showTable ? "Edit Selected View" : "Save";
    }

    @api viewType = ''; // Line_Treasury or Line / Opportunity
    @api viewTypeOptions = [];

    // Pagination state
    currentPage = 1;
    pageSize = 10;
    totalPages = 1;
    pagedApproversViews = [];

    // Sorting state
    sortedBy = 'LastModifiedDate';
    sortedDirection = 'desc';

    // Row selection state
    selectedRows = [];
    @api recordId = null;

    @api oppId = null;

    columns = COLUMNS;

    // Table visibility state
    showTable = true;

    get isOpportunity(){
        return this.viewType === 'Opportunity';
    }

    get isConfigScreenView(){
        return !this.isOppScreenView;
    }

    //hide or show cancel button
    get showCancelButton(){
        return !this.showTable;
    }

    //hide or show create new button
    get showCreateNewButton(){
        return this.showTable && !this.isOppScreenView;
    }
    get showSaveButton(){
        return !this.isOppScreenView;
    }

    selectViewTitle;

   @wire(hasWriteAccess)
    wiredAccess({ error, data }) {
        if (data !== undefined) {
            this.writeAccess = data;
        } else if (error) {
            this.writeAccess = false;
            console.error(error);
        }
    }

    /* get hasWriteAccess() {
        return this.writeAccess; // Check if the user has write access
    } */

    get createNewViewDisabled() {
        return !this.writeAccess; // reactive, works perfectly
    }

    get editSelectedViewDisabled() {
        // Disabled if no record is selected
        return !this.recordId;
    }

    get isSaveDisabled() {
        return !this.writeAccess || this.inputsDisabled || this.selectedItems.length === 0 || this.viewName == '';
    }

    get showTooltip(){
        if(this.writeAccess){
            return this.selectedItems.length === 0 || this.viewName == '';
        } else {
            return false;
        }
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }
    get isLastPage() {
        return this.currentPage === this.totalPages;
    }

    // List length properties for footer
    get actualListLength() {
        return this.pagedApproversViews.length;
    }

    get totalListLength() {
        return this.filteredApproversViews.length;
    }

    get saveTooltip() {
        if (this.selectedItems.length === 0) {
            return 'Select at least one component item.';
        } else if (!this.viewName) {
            return 'Enter a name for the view.';
        }
        return '';
    }

    connectedCallback() {
        console.log('dmt_screen_view_management connectedCallback isOppScreenView:', this.isOppScreenView);
        this.oppId = this.recordId;
        // dynamic select view title
        this.selectViewTitle = this.isOppScreenView ? 'Opportunity Approvers View' : 'Approvers View';

     //   this.checkAccess();
        this.loadApproversViews();
        this.loadViewTypeOptions();

        if(!this.isOppScreenView){
            COLUMNS.push({ label: 'Is Version View', fieldName: 'IsVersionView__c', type: 'boolean', sortable: true, hideDefaultActions: true });
            COLUMNS.push({ label: 'Display in Opportunity', fieldName: 'DisplayInOpportunity__c', type: 'boolean', sortable: true, hideDefaultActions: true });
        }
    }

    loadViewTypeOptions() {
        getDMTTypePicklistOptions()
            .then(result => {
                const options = JSON.parse(result);
                this.viewTypeOptions = options.map(option => ({
                    label: option.label,
                    value: option.value
                }));
                console.log('View Type Options:', JSON.stringify(this.viewTypeOptions));
            })
            .catch(error => {
                console.error('Error loading view type options:', error);
            });
    }

    handleViewTypeChanged(event) {
        console.log('dmt_screen_view_management handleViewTypeChanged event:', JSON.stringify(event.detail));
        this.viewType = event.detail.viewType;
        console.log('dmt_screen_view_management View type received: ', this.viewType);
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        console.log('Selected rows:', JSON.stringify(selectedRows));
        if (selectedRows.length > 0) {
            this.selectedRows = [selectedRows[0].Id];
            this.recordId = selectedRows[0].Id;
            this.viewName = selectedRows[0].Name;
            this.isProfitability = selectedRows[0].Profitability__c;
            this.isVersionView = selectedRows[0].IsVersionView__c;
            this.displayInOpportunity = selectedRows[0].DisplayInOpportunity__c;

            const selectedType = selectedRows[0]?.DMT_Type__c;
            const matchedOption = this.viewTypeOptions.find(option => option.label === selectedType);

            if (matchedOption) {
                this.viewType = matchedOption.value;
            } else {
                console.warn('Selected type not recognized:', selectedType);
            }

            console.log('viewType set to:', this.viewType);
            getItemsForView({ recordId: this.recordId })
            .then(result => {
                const items = JSON.parse(result);
                this.selectedItems = items.map(item => ({
                    id: item.Id,
                    orderDisplay: item.DMT_order_display__c || 0,
                    type: item.Type_Item__c || '',
                    component: item.DMT_Component_Item__c || '',
                    textValue: item.DMT_Text__c || ''
                }));
                console.log('dmt_screen_view_management selectedItems:', JSON.stringify(this.selectedItems));
            })
            .catch(error => {
                console.error('Error retrieving items for view:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Failed to retrieve items for the selected view.',
                        variant: 'error'
                    })
                );
            });
        } else {
            this.selectedRows = [];
            this.recordId = null;
        }
    }

    loadApproversViews() {
        getApproversViews().then(result => {
            console.log('Approvers views:', result);
            this.approversViews = JSON.parse(result);
            if(this.isOppScreenView){
                this.approversViews = this.approversViews.filter(view => view.DisplayInOpportunity__c === true);
            }
            this.filterApproversViews();
        }).catch(error => {
            console.error('Error loading approvers views:', error.message);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to load approvers views.',
                    variant: 'error'
                })
            );
        });
    }

    handleViewNameChanged(event) {
        console.log('dmt_screen_view_management handleViewNameChanged event:', JSON.stringify(event.detail));
        this.viewName = event.detail.viewName;
        console.log('dmt_screen_view_management viewName updated: ', this.viewName);
    }

    handleCreateNewView() {
        this.viewType = ''; // Reset the view type for new view creation
        this.viewName = ''; // Reset the view name for new view creation
        this.selectedItems = [];
        this.recordId = null; // Clear the selected record ID
        this.searchKey = ''; // Clear the search key
        this.filteredApproversViews = [...this.approversViews]; // Reset the filtered views
        this.currentPage = 1; // Reset to first page
        this.updatePagination(); // Update pagination based on the reset views
        this.selectedRows = []; // Clear selected rows
        this.showTable = false;
        this.isProfitability = false;
    }

    handleEditSelectedView() {
        this.showTable = false; // Hide the table to show the item selector
    }

    handleItemSelected(event) {
        console.log('dmt_screen_view_management handleItemSelected:', JSON.stringify(event.detail));
        this.selectedItems = event.detail; // Update the save button state
    }

    handleSave() {
        console.log('handleSave recordId, ', this.recordId);
        console.log('viewname, ', this.viewName);
        console.log('viewType, ', this.viewType);
        console.log('handleSave called with selectedItems:', JSON.stringify(this.selectedItems));

        const payload = {
            recordId: this.recordId,
            viewName: this.viewName,
            viewType: this.viewType,
            items: this.selectedItems, // Pass the array directly!
            isVersionView: this.isVersionView,
            displayInOpportunity: this.displayInOpportunity
        };
        

        upsertApproversViewWithItems({jsonPayload: JSON.stringify(payload)})
        .then(result => {
            console.log('handleSave upsertApproversViewWithItems result:', result);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Approvers view and items saved successfully.',
                    variant: 'success'
                })
            );
        })
        .catch(error => {
            console.error('Save failed', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body?.message || 'Unknown error occurred',
                    variant: 'error'
                })
            );
        })
        .finally(() => {
            this.loadApproversViews(); // Reload the approvers views
            this.handleCancel(); //return to main screen
        });
    }

    handleCancel() {
        this.selectedItems = [];
        this.recordId = null; // Clear the selected record ID
        this.searchKey = ''; // Clear the search key
        this.filteredApproversViews = [...this.approversViews]; // Reset the filtered views
        this.currentPage = 1; // Reset to first page
        this.updatePagination(); // Update pagination based on the reset views
        this.selectedRows = []; // Clear selected rows
        this.showTable = true;
        this.isProfitability = false;
        this.isVersionView = false;
        this.displayInOpportunity = false;
    }

    handleSearchKeyChange(event) {
        this.searchKey = event.target.value;
        this.currentPage = 1; // Reset to first page on search
        this.filterApproversViews();
    }

    handleSort(event) {
        const { fieldName, sortDirection } = event.detail;
        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;
        this.currentPage = 1; // Reset to first page on sort
        this.filterApproversViews();
    }

    filterApproversViews() {
        let views = [...this.approversViews];
        if (this.searchKey) {
            const key = this.searchKey.toLowerCase();
            views = views.filter(row =>
                row.Name && row.Name.toLowerCase().includes(key)
            );
        }
        // Sort
        views = this.sortViews(views, this.sortedBy, this.sortedDirection);
        this.filteredApproversViews = views;
        this.updatePagination();
        // Clear selection if selected row is not in the current page
        if (this.recordId && !this.pagedApproversViews.some(row => row.Id === this.recordId)) {
            this.selectedRows = [];
            this.recordId = null;
        }
    }

    sortViews(data, field, direction) {
        const sorted = [...data].sort((a, b) => {
            let aVal = a[field] || '';
            let bVal = b[field] || '';
            // Case-insensitive sort for strings
            if (typeof aVal === 'string' && typeof bVal === 'string') {
                aVal = aVal.toLowerCase();
                bVal = bVal.toLowerCase();
            }
            if (aVal < bVal) return direction === 'asc' ? -1 : 1;
            if (aVal > bVal) return direction === 'asc' ? 1 : -1;
            return 0;
        });
        return sorted;
    }

    updatePagination() {
        this.totalPages = Math.max(1, Math.ceil(this.filteredApproversViews.length / this.pageSize));
        if (this.currentPage > this.totalPages) {
            this.currentPage = this.totalPages;
        }
        const startIdx = (this.currentPage - 1) * this.pageSize;
        const endIdx = startIdx + this.pageSize;
        this.pagedApproversViews = this.filteredApproversViews.slice(startIdx, endIdx);
    }

    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePagination();
        }
    }

    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePagination();
        }
    }

    handleDisableInputs(event) {
        console.log('dmt_view_structure Disabling inputs for processing...', JSON.stringify(event.detail));
        event.stopPropagation(); // Evitar que el evento se propague más allá de este componente
        this.inputsDisabled = true; // Deshabilitar inputs durante el procesamiento
    }

    handleEnableInputs(event) {
        console.log('dmt_view_structure Enabling inputs after processing...', JSON.stringify(event.detail));
        event.stopPropagation(); // Evitar que el evento se propague más allá de este componente
        this.inputsDisabled = false; // Habilitar inputs después del procesamiento
    }

    handleIsVersionViewChange(event) {
        this.isVersionView = event.target.checked;
        console.log('isVersionView toggled to:', this.isVersionView);
    }

    handleDisplayInOpportunityChange(event) {
        this.displayInOpportunity = event.target.checked;
        console.log('Display in Opportunity toggled to:', this.displayInOpportunity);
    }
}