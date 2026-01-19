import { LightningElement,track, api } from 'lwc';

export default class Dmt_main_view extends LightningElement {
    @api selectedItems = [];
    @api itemsCollectionList = [];
    @api viewId;
    @api viewType = "";
    @api ItemsList;
    @api viewName;
    @api isProfitability = false; // New property to indicate if the view is for profitability test

    @api searchIdLabel = 'Search Id';

    @api viewTypeOptions = [];

    @track inputsDisabled = false;

    @api writeAccess;

    connectedCallback() {
        console.log('dmt_main_view writeAccess:', JSON.stringify(this.writeAccess));
        console.log('dmt_main_view selectedItems:', JSON.stringify(this.selectedItems));
        console.log('dmt_main_view itemsCollectionList:', JSON.stringify(this.itemsCollectionList));
        console.log('dmt_main_view viewTypeOptions:', JSON.stringify(this.viewTypeOptions));
        if (this.viewName){
            console.log('ViewName :'+this.viewName);
        }
        console.log('dmt_main_view viewType :'+this.viewType);
        console.log('itemsCollectionList :'+this.itemsCollectionList);
    }

    // Manejar el evento "itemselected" desde dmt_item_selector
    handleItemSelected(event) {
        console.log('dmt_main_view handleItemSelected ', JSON.stringify(event.detail));
        this.selectedItems = [...event.detail]; // Crear una nueva copia del array de ítems

        const itemSelectedEvent = new CustomEvent('itemselected', {
            detail: [...this.selectedItems]
        });
        this.dispatchEvent(itemSelectedEvent);
    }

    handleViewNameChanged(event) {
        console.log('dmt_main_view handleViewNameChanged ', JSON.stringify(event.detail));
        this.viewName = event.detail.viewName;
        const viewNameChangedEvent = new CustomEvent('viewnamechanged', {
            detail: { viewName: this.viewName }
        });
        this.dispatchEvent(viewNameChangedEvent);
    }

    handleViewTypeChanged(event) {
        console.log('dmt_main_view handleViewTypechanged ', JSON.stringify(event.detail));
        this.searchIdLabel = event.detail.searchIdLabel;
        this.viewType = event.detail.viewType;
        const viewTypeChangedEvent = new CustomEvent('viewtypechanged', {
            detail: { viewType: this.viewType }
        });
        this.dispatchEvent(viewTypeChangedEvent);
    }

    handleDisableInputs(event) {
        console.log('dmt_view_structure Disabling inputs for processing...', JSON.stringify(event.detail));
        this.inputsDisabled = true;
    }

    handleEnableInputs(event) {
        console.log('dmt_view_structure Enabling inputs after processing...', JSON.stringify(event.detail));
        this.inputsDisabled = false;
    }
}