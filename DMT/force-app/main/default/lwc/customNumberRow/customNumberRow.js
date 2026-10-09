import { LightningElement, api } from 'lwc';
import ERR_NEGATIVE_VALUE from '@salesforce/label/c.DMT_Negative_Value_Error';

export default class CustomNumberRow extends LightningElement {
    @api aviableItem;
    @api numberValue;
    @api fieldname;
    @api context;
    @api min;
    @api max;
    @api step;
    @api placeholder;
    @api formatter;
    @api disabledAttr;
    @api readonlyAttr;
    @api validateNegative = false;
    @api fieldlabel;

    _initialValue;
    _debounceTimer;

    label = {
        ERR_NEGATIVE_VALUE
    };

    get isDisabled() {
        return !!this.aviableItem || !!this.disabledAttr;
    }

    connectedCallback() {
        this._initialValue = this.numberValue;
    }

    renderedCallback() {
        if (this.validateNegative) {
            this.applyValidation(this.numberValue);
        }
    }

    handleFocus(event) {
        this._initialValue = event.target.value;
    }

    handleChange(event) {
        const newValue = event.target.value;

        if (this._debounceTimer) {
            clearTimeout(this._debounceTimer);
        }

        this._debounceTimer = setTimeout(() => {
            this.commitValue(newValue);
        }, 700);
    }

    handleBlur(event) {
        const newValue = event.target.value;

        if (this._debounceTimer) {
            clearTimeout(this._debounceTimer);
        }

        this.commitValue(newValue);
    }

    commitValue(newValue) {
        const parsed = newValue !== '' && newValue !== null ? Number(newValue) : null;

        if (this.validateNegative) {
            this.applyValidation(parsed);
        }

        const input = this.template.querySelector('lightning-input');
        const isFieldValid = input ? input.checkValidity() : true;

        if (String(parsed) !== String(this._initialValue)) {
            this.numberValue = parsed;
            this._initialValue = parsed;

            this.dispatchEvent(new CustomEvent('customnumberinputchanged', {
                composed: true,
                bubbles: true,
                cancelable: true,
                detail: {
                    data: { 
                        context: this.context, 
                        value: parsed, 
                        fieldname: this.fieldname,
                        fieldlabel: this.fieldlabel, 
                        isFieldValid 
                    }
                }
            }));
        }
    }

    applyValidation(value) {
        const input = this.template.querySelector('lightning-input');
        if (input) {
            const isNegative = value !== null && value < 0;
            input.setCustomValidity(isNegative ? this.label.ERR_NEGATIVE_VALUE : '');
            input.reportValidity();
        }
    }
}