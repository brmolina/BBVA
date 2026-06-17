import { LightningElement, api, track } from 'lwc';
import searchRecords from '@salesforce/apex/DMT_LineController.searchRecords';

export default class Dmt_view_structure extends LightningElement {
    @api viewType = '';
    @track _selectedItems = [];
    @track searchTerm = ''; // Término de búsqueda
    @track filteredLineOptions = []; // Opciones filtradas para el combobox
    @api recordId = '';
    @track showDropdown = false; // Controla si el dropdown está visible

    @api currencyIsoCode = null;

    @api objectApiName = '';
    @api recordTypeApiName = '';

    @api viewTypeOptions = [];
    @api searchIdLabel = 'Search Id'; 

    @track inputsDisabled = false; 

    get isSearchIdInputsDisabled() {
        return this._selectedItems.length === 0 || this.inputsDisabled;
    }

    connectedCallback(){
        console.log('dmt_view_structure connectedCallback viewType:', this.viewType);
        
    }
    
    renderedCallback() {
        console.log('dmt_view_structure renderedCallback viewType:', this.viewType);
        if(this.viewType != '' && this.objectApiName == ''){
            this.updateObjectAndRecordType(this.viewType);
        }
    }

    updateObjectAndRecordType(viewType) {
        switch (viewType) {
            case 'Line_Treasury':
                this.objectApiName = 'DMT_Line__c';
                this.recordTypeApiName = 'TreasurySettlement';
                break;
            case 'Line':
                this.objectApiName = 'DMT_Line__c';
                this.recordTypeApiName = 'OtherProducts';
                break;
            case 'Line_Sanction':
                this.objectApiName = 'DMT_Line__c';
                this.recordTypeApiName = 'Sanction';
                break;
            case 'Opportunity':
                this.objectApiName = 'Opportunity';
                this.recordTypeApiName = 'DMT_Opportunity';
                break;
            default:
                console.warn('selected type not recognized:', this.type);
                break;
        }
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
        console.log('searchTerm:', this.searchTerm);
        console.log('objectApiName:', this.objectApiName);
        console.log('recordTypeApiName:', this.recordTypeApiName);

        if (this.searchTerm.length >= 2) { // Comenzar la búsqueda después de 2 caracteres
            searchRecords({objectApiName: this.objectApiName, recordTypeApiName: this.recordTypeApiName, searchTerm: this.searchTerm})
            .then(result => {
                this.filteredLineOptions = result.map(record => ({
                    label: record.label, // Line_Id__c or DMT_Opp_Id__c
                    value: record.id, // Id
                    currencyIsoCode: record.currencyIsoCode // Agregar currencyIsoCode si es necesario
                }));
                this.showDropdown = true; // Mostrar el dropdown con las sugerencias
                })
                .catch(error => {
                    console.error('Error fetching '+ this.type +' records:', error);
                    this.filteredLineOptions = [];
                    this.showDropdown = false;
                });
        } else {
            this.filteredLineOptions = [];
            this.showDropdown = false; // Ocultar el dropdown si no hay resultados
        }
    }

    clearSearchTerm() {
        // Copy to clipboard before clearing
        if (this.searchTerm) {
            console.log('clearing search term, ', this.searchTerm);
        }
        this.searchTerm = ''; // Limpiar el campo de búsqueda
        this.filteredLineOptions = []; // Limpiar las opciones filtradas
        this.showDropdown = false; // Ocultar el dropdown
    }

    // Manejar la selección de una línea
    handleLineSelect(event) {
        event.preventDefault();
        const lineId = event.currentTarget.dataset.value;
        this.searchTerm = event.currentTarget.dataset.label; // Actualizar el campo de búsqueda con la etiqueta seleccionada
        this.currencyIsoCode = event.currentTarget.dataset.currencyisocode; // Actualizar currencyIsoCode si es necesario
        console.log('dmt_view_structure currencyIsoCode selected:', this.currencyIsoCode);
        this.recordId = lineId;
        this.showDropdown = false; // Ocultar el dropdown después de seleccionar una opción
    }

    // Ocultar el dropdown si no hay resultados
    get showDropdownList() {
        return this.showDropdown && this.filteredLineOptions.length > 0;
    }

    @api
    set selectedItems(value) {
        this._selectedItems = [...value]; // Copiamos el array para asegurarnos de que es reactivo
        this.sortItems();
    }

    get selectedItems() {
        return this._selectedItems;
    }

    get sortedItems() {
        return [...this._selectedItems].sort((a, b) => a.orderDisplay - b.orderDisplay);
    }

    get hasItems() {
        return this._selectedItems.length > 0;
    }

    sortItems() {
        // Este método se asegura de que los items siempre se ordenan cuando se actualizan
        console.log('Items en dmt_view_structure: ', JSON.stringify(this._selectedItems));
    }

    handleDisableInputs(event) {
        console.log('dmt_view_structure Disabling inputs for processing...', JSON.stringify(event.detail));
        this.inputsDisabled = true; // Deshabilitar inputs durante el procesamiento
    }

    handleEnableInputs(event) {
        console.log('dmt_view_structure Enabling inputs after processing...', JSON.stringify(event.detail));
        this.inputsDisabled = false; // Habilitar inputs después del procesamiento
    }
}