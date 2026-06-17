import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOpportunityInfo from '@salesforce/apex/OpportunityInfoTabService.getOpportunityInfo';
import saveOpportunityInfo from '@salesforce/apex/OpportunityInfoTabService.saveOpportunityInfo';

export default class DmtOpportunityInfoTab extends LightningElement {
    @api recordId;

    // UI State
    isLoading = false;
    isSaving = false;
    isEditingMode = false;
    showError = false;
    errorMessage = '';

    // Data
    opportunityData = {};
    formData = {};
    validationErrors = {};

    // Computed properties
    get hasXSellData() {
        return this.opportunityData?.OppXSell?.length > 0;
    }

    get currencyOptions() {
        // Parse currency options from catalog
        const currencyList = this.opportunityData?.catalogOptions?.taxoC264 || [];
        return currencyList.map(curr => ({
            label: curr.label,
            value: curr.value
        }));
    }

    get formattedNotionalAmount() {
        const amount = this.opportunityData?.NotionalAmountValue || 0;
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: this.opportunityData?.DMT_Currency__c || 'USD'
        }).format(amount);
    }

    get rendererFields() {
        return [
            { id: 'Name', apiName: 'Name', label: 'Opportunity Name', type: 'text', value: this.formData.Name, isRequired: true, isReadOnly: false, size: '1-of-2', placeholder: 'Opportunity name' },
            { id: 'StageName', apiName: 'StageName', label: 'Stage', type: 'text', value: this.formData.StageName, isReadOnly: true, size: '1-of-2' },
            { id: 'Entific', apiName: 'Entific', label: 'Entific', type: 'text', value: this.formData.Entific, isReadOnly: true, size: '1-of-2' },
            { id: 'EntityName', apiName: 'EntityName', label: 'Entity', type: 'text', value: this.formData.EntityName, isReadOnly: true, size: '1-of-2' },
            { id: 'DMT_DATE_Initial_Date__c', apiName: 'DMT_DATE_Initial_Date__c', label: 'Initial Date', type: 'date', value: this.formData.DMT_DATE_Initial_Date__c, isRequired: true, isReadOnly: false, size: '1-of-2' },
            { id: 'MaturityDate', apiName: 'MaturityDate', label: 'Maturity Date', type: 'date', value: this.formData.MaturityDate, isRequired: true, isReadOnly: false, size: '1-of-2' },
            { id: 'DMT_Currency__c', apiName: 'DMT_Currency__c', label: 'Currency', type: 'picklist', value: this.formData.DMT_Currency__c, isRequired: true, isReadOnly: false, options: this.currencyOptions, size: '1-of-2' },
            { id: 'NotionalAmountValue', apiName: 'NotionalAmountValue', label: 'Notional Amount', type: 'number', value: this.formData.NotionalAmountValue, isReadOnly: false, size: '1-of-2', step: 0.01, min: 0 },
            { id: 'DMT_Product_Area__c', apiName: 'DMT_Product_Area__c', label: 'Product Area', type: 'text', value: this.formData.DMT_Product_Area__c, isRequired: true, isReadOnly: false, size: '1-of-2' },
            { id: 'DMT_Capital_Action__c', apiName: 'DMT_Capital_Action__c', label: 'Capital Action', type: 'text', value: this.formData.DMT_Capital_Action__c, isReadOnly: false, size: '1-of-2' },
            { id: 'DMT_ContingentCommitments__c', apiName: 'DMT_ContingentCommitments__c', label: 'Contingent Commitments', type: 'textarea', value: this.formData.DMT_ContingentCommitments__c, isReadOnly: false, size: '1-of-1', maxLength: 1000 },
            { id: 'BookingName', apiName: 'BookingName', label: 'Booking Name', type: 'text', value: this.formData.BookingName, isReadOnly: true, size: '1-of-2' },
            { id: 'DMT_Tenor__c', apiName: 'DMT_Tenor__c', label: 'Tenor', type: 'text', value: this.formData.DMT_Tenor__c, isReadOnly: true, size: '1-of-2' }
        ];
    }

    /**
     * Wire method to fetch opportunity record data
     */
    @wire(getRecord, {recordId: '$recordId', fields: ['Opportunity.Id', 'Opportunity.Name', 'Opportunity.StageName']})
    wiredRecord({error, data}) {
        if(data) {
            this.loadOpportunityInfo();
        } else if(error) {
            this.handleError('Failed to load record: ' + error.body?.message);
        }
    }

    /**
     * Load opportunity information from server
     */
    async loadOpportunityInfo() {
        this.isLoading = true;
        this.showError = false;

        try {
            const result = await getOpportunityInfo({recordId: this.recordId});

            if(result.error && result.error !== 'OK') {
                this.handleError(result.error);
                return;
            }

            this.opportunityData = result;
            this.resetFormData();

        } catch(error) {
            this.handleError('Error loading opportunity: ' + error.message);
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Initialize form data from opportunity data
     */
    resetFormData() {
        this.formData = {
            Id: this.opportunityData.Id,
            Name: this.opportunityData.Name,
            Entific: this.opportunityData.Entific,
            EntityName: this.opportunityData.EntityName,
            DMT_DATE_Initial_Date__c: this.formatDateForInput(this.opportunityData.DMT_DATE_Initial_Date__c),
            MaturityDate: this.formatDateForInput(this.opportunityData.MaturityDate),
            DMT_Currency__c: this.opportunityData.DMT_Currency__c,
            NotionalAmountValue: this.opportunityData.NotionalAmountValue,
            DMT_Product_Area__c: this.opportunityData.DMT_Product_Area__c,
            DMT_Capital_Action__c: this.opportunityData.DMT_Capital_Action__c,
            DMT_ContingentCommitments__c: this.opportunityData.DMT_ContingentCommitments__c,
            BookingName: this.opportunityData.BookingName,
            OppXSell: this.opportunityData.OppXSell || [],
            defaultCurrency: this.opportunityData.defaultCurrency
        };
        this.validationErrors = {};
    }

    /**
     * Format date for input element (YYYY-MM-DD)
     */
    formatDateForInput(dateValue) {
        if(!dateValue) return '';
        if(typeof dateValue === 'string') {
            return dateValue.substring(0, 10);
        }
        // Handle Date object
        const date = new Date(dateValue);
        return date.toISOString().substring(0, 10);
    }

    /**
     * Handle field changes in edit mode
     */
    handleFieldChange(event) {
        this.updateFormField(event.target.dataset.field, event.target.value, true);
    }

    updateFormField(field, value, clearValidationError = false) {
        this.formData = {
            ...this.formData,
            [field]: value
        };

        if(clearValidationError && this.validationErrors[field]) {
            this.validationErrors = {
                ...this.validationErrors,
                [field]: ''
            };
        }
    }

    /**
     * Handle date field changes with validation
     */
    handleDateChange(event) {
        this.updateFormField(event.target.dataset.field, event.target.value);
        this.validateDateFields();
    }

    handleRendererFieldChange(event) {
        const { apiName, value } = event.detail || {};
        if(!apiName) {
            return;
        }

        this.formData = {
            ...this.formData,
            [apiName]: value
        };

        if(this.validationErrors[apiName]) {
            this.validationErrors = {
                ...this.validationErrors,
                [apiName]: ''
            };
        }

        if(apiName === 'DMT_DATE_Initial_Date__c' || apiName === 'MaturityDate') {
            this.validateDateFields();
        }
    }

    /**
     * Handle combobox changes
     */
    handleComboboxChange(event) {
        this.handleFieldChange(event);
    }

    /**
     * Validate date fields
     */
    validateDateFields() {
        const errors = {...this.validationErrors};
        const today = new Date().toISOString().substring(0, 10);
        const initialDate = this.formData.DMT_DATE_Initial_Date__c;
        const maturityDate = this.formData.MaturityDate;

        // Initial date validation
        if(initialDate && initialDate < today) {
            errors.initialDate = 'The initial date cannot be less than today';
        } else {
            errors.initialDate = '';
        }

        // Maturity date validation
        if(initialDate && maturityDate && maturityDate <= initialDate) {
            errors.maturityDate = 'The Maturity Date cannot be less than the initial date';
        } else {
            errors.maturityDate = '';
        }

        this.validationErrors = errors;
    }

    /**
     * Validate all required fields
     */
    validateForm() {
        const errors = {};

        // Check required fields
        if(!this.formData.Name) {
            errors.Name = 'Name is required';
        }

        if(!this.formData.DMT_Currency__c) {
            errors.currency = 'Currency is required';
        }

        if(!this.formData.DMT_Product_Area__c) {
            errors.productArea = 'Product Area is required';
        }

        // Validate dates
        this.validateDateFields();

        if(Object.keys(errors).length > 0 || Object.values(this.validationErrors).some(Boolean)) {
            this.validationErrors = {...this.validationErrors, ...errors};
            return false;
        }

        return true;
    }

    /**
     * Handle Edit button click
     */
    handleEditClick() {
        this.isEditingMode = true;
    }

    /**
     * Handle Cancel button click
     */
    handleCancelClick() {
        if(confirm('Are you sure? Any unsaved changes will be lost.')) {
            this.isEditingMode = false;
            this.resetFormData();
        }
    }

    /**
     * Handle Save button click
     */
    async handleSaveClick() {
        // Validate form
        if(!this.validateForm()) {
            this.showToast('Validation Error', 'Please fix the errors before saving', 'error');
            return;
        }

        this.isSaving = true;

        try {
            const result = await saveOpportunityInfo({opportunityData: this.formData});

            if(result.error && result.error !== 'OK') {
                this.handleError(result.error);
                return;
            }

            // Update opportunity data
            this.opportunityData = result;
            this.isEditingMode = false;
            this.resetFormData();

            // Show success message
            this.showToast('Success', 'Opportunity updated successfully', 'success');

            // Dispatch event to notify parent/related components
            this.dispatchEvent(new CustomEvent('opportunityupdated', {
                detail: {recordId: this.recordId},
                bubbles: true,
                composed: true
            }));

        } catch(error) {
            this.handleError('Error saving opportunity: ' + error.message);
        } finally {
            this.isSaving = false;
        }
    }

    /**
     * Handle Retry button click
     */
    handleRetry() {
        this.loadOpportunityInfo();
    }

    /**
     * Show toast notification
     */
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    /**
     * Handle errors
     */
    handleError(message) {
        this.showError = true;
        this.errorMessage = message;
        this.showToast('Error', message, 'error');
        console.error('DMT Opportunity Info Tab Error:', message);
    }
}