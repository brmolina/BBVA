import { LightningElement, api,track } from 'lwc';
import { FlowAttributeChangeEvent} from 'lightning/flowSupport';
import searchClient from '@salesforce/apex/DMT_Client_Selector.searchClient';
import{loadStyle} from 'lightning/platformResourceLoader';
import pillStyle from '@salesforce/resourceUrl/DMT_PillStyle';
const DEBOUNCE_DELAY = 300; // 300ms de espera antes de buscar
// LABELS
import DMT_HELPTEXT_GROUPCODE from '@salesforce/label/c.DMT_Groupcode_Searchtooltip';

export default class Dmt_search_record_info extends LightningElement
{
    // bookingGeography is deprecated and replaced by clientEntific, but it is retained for compatibility with existing "Clone Line" flow versions
    @api bookingGeography;
    @api clientEntific;
    @api accountOrLocalClient;
    @api clientId;
    @api localClientId;
    @api isSubsidiary;
    @api accountName;
    // Estado interno del componente
    searchTerm = '';
    searchResults = [];
    selectedClient = null; // Almacena el objeto completo del cliente seleccionado
    isSearching = false;
    isDropdownOpen = false;
    debounceTimeout;
    //LABELS
    labels = {
        DMT_HELPTEXT_GROUPCODE
    }
    filter={};
    accountValue = null;
    disabledAccount = false;

    matchingInfoAccount = {
        primaryField: { fieldPath: 'DES_Group_Code__c' }
    }

    displayInfoAccount = {
        primaryField: 'Name',
        additionalFields: ['DES_Group_Code__c'],
    };

    connectedCallback()
    {
        this.filter = {
            criteria: [
                {
                    fieldPath: 'country_id__c',
                    operator: 'eq',
                    value: this.clientEntific,
                }
            ]
        };
    }

    renderedCallback(){
        Promise.all([
            loadStyle(this, pillStyle)
        ]).then(() => {
            console.log('Styles loaded');
        }).catch(error => {
            console.error('Error loading styles:', error);
        });
    }


    // --- Lógica de la Búsqueda ---
    handleSearch(event) {
        this.searchTerm = event.target.value;
            if (this.searchTerm.length < 2) {
                this.searchResults = [];
                return;
            }
            this.isSearching = true;
            this.isDropdownOpen = true;
            console.log('this.searchTerm', this.searchTerm);
            searchClient({ searchTerm: this.searchTerm })
                .then(result => {
                    this.searchResults = result
                        .filter(client => client.DES_Group_Code__c || client.g_customer_id__c)
                        .map(client => {
                            const secondaryField = client.DES_Group_Code__c || client.g_customer_id__c || 'Ubicación no disponible';
                            return { ...client, secondaryField };
                        });
                    console.log('this.searchResults', JSON.stringify(this.searchResults));
                })
                .catch(error => {
                    console.error('Search error:', error);
                    this.searchResults = [];
                })
                .finally(() => {
                    this.isSearching = false;
                });
    }
    // Se activa cuando el usuario selecciona un item de la lista
    // Usamos onmousedown en lugar de onclick para evitar conflictos con el evento onblur
    handleSelect(event) {
        const selectedId = event.currentTarget.dataset.id;
        this.selectedClient = this.searchResults.find(client => client.Id === selectedId);
        this.isSubsidiary = !this.selectedClient.DES_Group_Code__c && this.selectedClient.g_customer_id__c !== null;
        this.accountValue = selectedId;
        this.localClientValue = null;
        this.clientId = selectedId;
        this.isDropdownOpen = false;
        console.log('Group Code Selected --> ' , event.currentTarget);

        if(this.accountValue === null )
        {
            this.disabledAccount = false;
        }
        else
        {
            this.disabledAccount = false;
        }

        const attributeChangeEvent = new FlowAttributeChangeEvent('clientId',this.clientId);
        this.dispatchEvent(attributeChangeEvent);
        const attributeChangeEventclientId = new FlowAttributeChangeEvent('localClientId', this.localClientId);
        this.dispatchEvent(attributeChangeEventclientId);
        const attributeChangeEventSubsidiary = new FlowAttributeChangeEvent('isSubsidiary', this.isSubsidiary);
        this.dispatchEvent(attributeChangeEventSubsidiary);

        const inputElement = this.template.querySelector('lightning-input');
        inputElement.setCustomValidity('');
        inputElement.reportValidity();
    }
    // Limpia la selección de la "píldora"
    handleClearSelection() {
        this.selectedClient = null;
        this.clientId = null;
        this.searchTerm = '';
        this.searchResults = [];
        this.accountValue = null;
        // Notifica al Flow que la selección se ha limpiado
        const attributeChangeEvent = new FlowAttributeChangeEvent('clientId',null);
        this.dispatchEvent(attributeChangeEvent);
    }
    // Controla la visibilidad del desplegable
    handleFocus() {
        if (this.searchTerm.length > 3) {
            this.isDropdownOpen = true;
        }
    }
    handleBlur() {
        // Pequeño retardo para permitir que el click en un item se registre antes de cerrar
       setTimeout(() => {
            this.isDropdownOpen = false;
            this.searchResults = [];

            const inputElement = this.template.querySelector('lightning-input');

            if (this.searchTerm && ! this.selectedClient) {
                inputElement.setCustomValidity('Select an option or remove the entered text.');
            } else {
                inputElement.setCustomValidity('');
            }
            inputElement.reportValidity();
        }, 300);
    }
    // Propiedades computadas para la plantilla
    get noResultsFound() {
        return !this.isSearching && this.searchTerm.length >= 2 && this.searchResults.length === 0;
    }
}