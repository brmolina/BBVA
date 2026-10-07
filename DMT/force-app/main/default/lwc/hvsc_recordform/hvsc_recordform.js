import { LightningElement, api } from 'lwc';

export default class Hvsc_recordform extends LightningElement {
    @api variant; // The variant of the record form (e.g., 'standard', 'compact')
    @api fields; // The fields to be displayed in the record form

    editingApiNames = new Set(); // apiNames toggled into edit mode via the pencil icon

    get fieldClassVariant() {
        return this.variant === 'standard' ? 'slds-col slds-size_1-of-2 slds-grid_vertical-align-center' : 'slds-col slds-size_1-of-1 slds-grid_vertical-align-center';
    }

    // lwc:if only supports simple property paths, not inline comparisons, so precompute the flag here
    get processedFields() {
        return (this.fields || []).map(field => {
            const currencyCode = field.currencyCode || 'EUR';
            return {
                ...field,
                value: field.value ?? '',
                isCheckbox: field.type === 'checkbox',
                isTextarea: field.type === 'textarea',
                isCurrency: field.type === 'currency',
                currencyCode,
                currencySymbol: field.currencySymbol || this.getCurrencySymbol(currencyCode),
                editing: field.editing || this.editingApiNames.has(field.apiName),
                colClass: this.getFieldColClass(field)
            };
        });
    }

    // Derives the display symbol (€, $, ...) from an ISO currency code so the read-only view matches the edit formatter
    getCurrencySymbol(currencyCode) {
        try {
            return (0).toLocaleString(undefined, { style: 'currency', currency: currencyCode, minimumFractionDigits: 0, maximumFractionDigits: 0 }).replace(/\d/g, '').trim();
        } catch (e) {
            return '€';
        }
    }

    // field.fullWidth lets a specific field bypass the variant and force a 1-of-1 column
    getFieldColClass(field) {
        const size = field.fullWidth ? '1-of-1' : (this.variant === 'standard' ? '1-of-2' : '1-of-1');
        return `slds-col slds-size_${size} slds-grid_vertical-align-center`;
    }

    handleEditClick(event) {
        const apiName = event.currentTarget.dataset.apiName;
        const newSet = new Set(this.editingApiNames);
        newSet.add(apiName);
        this.editingApiNames = newSet;
    }

    handleInputBlur(event) {
        const apiName = event.target.name;
        const newSet = new Set(this.editingApiNames);
        newSet.delete(apiName);
        this.editingApiNames = newSet;
    }

    handleInputChange(event) {
        const apiName = event.target.name;
        const field = this.fields.find(f => f.apiName === apiName);
        if (field) {
            this.dispatchEvent(new CustomEvent('fieldchange', {
                detail: { apiName: field.apiName, value: event.target.type === 'checkbox' ? event.target.checked : event.target.value }
            }));
        }
    }
}