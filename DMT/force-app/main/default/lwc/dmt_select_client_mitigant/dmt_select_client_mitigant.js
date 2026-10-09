import { LightningElement, api, track } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import searchLocalClients from '@salesforce/apex/DMT_LocalClientSearchController.searchLocalClients';
import getLocalClientById from '@salesforce/apex/DMT_LocalClientSearchController.getLocalClientById';

export default class LocalClientPicker extends LightningElement {

     @api mitangt;
    @api disabled = false;

    @track searchTerm = '';
    @track results = [];
    @track isOpen = false;
    @track isLoading = false;

    _entityId;
    _searchTimeout;
    _clientId;
    @track showTooltip = false;

    handleTooltipShow() {
        this.showTooltip = true;
    }

    handleTooltipHide() {
        this.showTooltip = false;
    }

    @api
    get clientId() {
        return this._clientId;
    }

    set clientId(value) {
        console.log('ABS CLIENT VALUE '+value);
        this._clientId = value;
        if (value && value !== '' && value !== 'null' && value !== 'undefined') {
            this.loadExistingClient(value);
        }
    }

    @api
    get entityId() {
        return this._entityId;
    }

    set entityId(value) {
        this._entityId = value;
    }

    get labelValue() {
        return this.mitangt ? 'Select Guarantor' : 'Local Client';
    }

    get placeholderValue() {
        return this.mitangt ? 'Search Guarantor...' : 'Search Clients...';
    }

    get hasResults() {
        return this.results && this.results.length > 0;
    }

    get comboboxClass() {
        return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ${this.isOpen ? 'slds-is-open' : ''}`;
    }

    handleInput(event) {
        this.searchTerm = event.target.value;

        clearTimeout(this._searchTimeout);

        if (this.searchTerm.length < 2) {
            this.results = [];
            this.isOpen = false;
            return;
        }

        this.isLoading = true;
        this.isOpen = true;

        this._searchTimeout = setTimeout(() => {
            this.search();
        }, 300);
    }

    async search() {
        try {
            const data = await searchLocalClients({
                searchTerm: this.searchTerm,
                entityId: this._entityId
            });

            this.results = data.map(record => ({
                id: record.Id,
                name: record.Name,
                alphaCode: record.g_customer_id__c || '',
                fiscalId: record.DES_Tax_Identification_Number__c || ''
            }));

        } catch (e) {
            console.error('Error searching local clients:', e);
            this.results = [];
        } finally {
            this.isLoading = false;
        }
    }

    handleFocus() {
        if (this.searchTerm.length >= 2) {
            this.isOpen = true;
        }
    }

    handleBlur() {
        // Pequeño delay para permitir que onmousedown del item se ejecute antes
        setTimeout(() => {
            this.isOpen = false;
        }, 200);
    }

    handleSelect(event) {
        const recordId = event.currentTarget.dataset.id;
        const selected = this.results.find(r => r.id === recordId);

        if (selected) {
            this.searchTerm = selected.name;
            this._clientId = recordId;
            this.isOpen = false;

            const selectedEvent = new CustomEvent('recordselected', {
                bubbles: true,
                composed: true,
                detail: { recordId }
            });
            this.dispatchEvent(selectedEvent);

            const attributeChangeEvent = new FlowAttributeChangeEvent('clientId', recordId);
            this.dispatchEvent(attributeChangeEvent);
        }
    }


async loadExistingClient(recordId) {
    try {
        const record = await getLocalClientById({ recordId });
        if (record) {
            this.searchTerm = record.Name;
            console.log('ABS this.searchterm '+this.searchTerm);
        }
    } catch (e) {
        console.error('Error loading existing client:', e);
    }
} 
}