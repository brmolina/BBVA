import { LightningElement, api, track } from 'lwc';
import searchRecords from '@salesforce/apex/DMT_LookupController.searchRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CustomLookup extends LightningElement {

    @api fieldName;
    @api label;
    @api value;
    @api objectApiName;
    @api config = {};
    
    @track searchTerm = '';
    @track searchResults = [];
    @track isLoading = false;
    @track isOpen = false;
    @track selectedRecord = null;
    @track displayValue = '';
    @track debounceTimer;

    connectedCallback() {
        if (this.value) {
            this.loadInitialValue();
        }
    }

    async loadInitialValue() {
        try {
            const results = await searchRecords({
                objectName: this.objectApiName,
                searchTerm: '',
                filters: [
                    { field: 'Id', operator: '=', value: this.value }
                ],
                additionalFields: this.config.additionalFields || []
            });
            
            if (results && results.length > 0) {
                this.selectedRecord = results[0];
                this.displayValue = this.getDisplayValue(this.selectedRecord);
            }
        } catch (error) {
            console.error('Error loading initial value:', error);
        }
    }

    getDisplayValue(record) {
        let display = record.Name || '';
        
        if (this.config.additionalFields) {
            this.config.additionalFields.forEach(field => {
                if (record[field] && field !== 'Name') {
                    display = display + ' (' + record[field] + ')';
                }
            });
        }
        
        return display;
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
        this.displayValue = this.searchTerm;
        
        if (this.searchTerm.length < 2) {
            this.searchResults = [];
            this.isOpen = false;
            return;
        }
        
        clearTimeout(this.debounceTimer);
        this.debounceTimer = setTimeout(() => {
            this.performSearch();
        }, 300);
    }

    async performSearch() {
        this.isLoading = true;
        this.isOpen = true;
        
        try {
            let filters = this.config.filters || [];
            
            if (this.config.dependentFields) {
                const dependentFilters = await this.getDependentFilters();
                if (dependentFilters && dependentFilters.length > 0) {
                    filters = filters.concat(dependentFilters);
                }
            }
            
            const results = await searchRecords({
                objectName: this.objectApiName,
                searchTerm: this.searchTerm,
                filters: filters,
                additionalFields: this.config.additionalFields || []
            });
            
            this.searchResults = results.map(record => {
                return {
                    ...record,
                    displayValue: this.getDisplayValue(record)
                };
            });
            
        } catch (error) {
            console.error('Search error:', error);
            this.searchResults = [];
            this.showToast('Error', 'Error en búsqueda', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async getDependentFilters() {
        const filters = [];
        
        if (!this.config.dependentFields || !this.config.fieldMappings) {
            return filters;
        }
        
        try {
            for (const depField of this.config.dependentFields) {
                const mapping = this.config.fieldMappings[depField];
                if (!mapping) continue;
                
                const fieldElement = this.template.closest('lightning-record-edit-form')
                    .querySelector('[data-field-name="' + depField + '"]');
                
                if (fieldElement && fieldElement.value) {
                    filters.push({
                        field: mapping.targetField,
                        operator: mapping.operator || '=',
                        value: fieldElement.value
                    });
                }
            }
            
            return filters;
        } catch (error) {
            console.error('Error getting dependent filters:', error);
            return filters;
        }
    }

    handleSelect(event) {
        const recordId = event.currentTarget.dataset.id;
        const record = this.searchResults.find(r => r.Id === recordId);
        
        if (record) {
            this.selectedRecord = record;
            this.displayValue = this.getDisplayValue(record);
            this.searchResults = [];
            this.isOpen = false;
            this.searchTerm = '';
            
            this.dispatchEvent(new CustomEvent('select', {
                detail: {
                    field: this.fieldName,
                    record: record
                }
            }));
        }
    }

    handleClear() {
        this.selectedRecord = null;
        this.displayValue = '';
        this.searchTerm = '';
        this.searchResults = [];
        this.isOpen = false;
        
        this.dispatchEvent(new CustomEvent('select', {
            detail: {
                field: this.fieldName,
                record: null
            }
        }));
    }

    handleFocus() {
        if (!this.selectedRecord && this.searchTerm && this.searchTerm.length >= 2) {
            this.isOpen = true;
        }
    }

    handleBlur() {
        setTimeout(() => {
            this.isOpen = false;
        }, 200);
    }

    handleKeyDown(event) {
        if (event.key === 'Escape') {
            this.isOpen = false;
        }
        if (event.key === 'ArrowDown') {
            this.focusFirstResult();
            event.preventDefault();
        }
    }

    focusFirstResult() {
        const firstResult = this.template.querySelector('.search-result-item');
        if (firstResult) {
            firstResult.focus();
        }
    }

    handleMouseDown(event) {
        event.preventDefault();
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    // Propiedades computadas para el template
    get hasValue() {
        return this.selectedRecord !== null;
    }

    get searchIconClass() {
        let className = 'slds-input__icon slds-input__icon_right';
        if (this.isLoading) {
            className = className + ' slds-is-loading';
        }
        return className;
    }

    get resultsClass() {
        let className = 'slds-dropdown slds-dropdown_length-5 slds-dropdown_fluid';
        if (this.isOpen) {
            className = className + ' slds-is-open';
        }
        return className;
    }

    get showNoResults() {
        return !this.isLoading && this.searchResults.length === 0 && 
               this.searchTerm && this.searchTerm.length >= 2 && this.isOpen;
    }

    get required() {
        return this.config && this.config.required === true;
    }
}