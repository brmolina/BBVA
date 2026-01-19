import { LightningElement, api } from 'lwc';

export default class Hpg_contract_guarantees_cell extends LightningElement {

    @api row;
    @api index;
    @api column;

    field;
    label;
    title;
    alignClass;
    fractionDigits;
    currencyCode;
    isEmpty; isDate; isText; isPercent; isNumber; isCurrency; isLink;
    value;
    currencyId

    connectedCallback() {
        this.label = this.column.value.label || '';
        this.type = this.column.value.type || 'text';
        this.field = this.column.value.fieldName;
        this.title = this.label;
        this.fractionDigits = this.column.value.fractionDigits || 2;
        this.alignClass = (this.column.value.align === 'right') ? 'slds-truncate slds-text-align_right' : 'slds-truncate';
        this.value = this.row[this.field];
        this.isText = this.type === 'text';
        this.isDate = this.type === 'date';
        this.isPercent = this.type === 'percent';
        this.isNumber = this.type === 'number';
        this.isCurrency = this.type === 'currency';
        this.isLink = this.onclick !== undefined;
        this.notEmpty = this.value != null && this.value != '' && this.value != undefined;
        if (this.isCurrency) {
            this.currencyCode = this.row['currencyId'];
        }

    }
}