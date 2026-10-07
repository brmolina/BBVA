import { LightningElement, api } from 'lwc';
import ERR_NEGATIVE_VALUE from '@salesforce/label/c.DMT_Negative_Value_Error';

export default class CustomInputRow extends LightningElement {
    @api aviableItem;
    @api inputValue;
    @api fieldname;
    @api fieldlabel;
    @api context;
    @api maxDecimals;
    @api suffix;
    @api validateNegative = false;

    _initialValue;
    _debounceTimer;

    label = {
        ERR_NEGATIVE_VALUE
    };

    connectedCallback() {
        // Store the initial value when the component is connected to the DOM
        this._initialValue = this.inputValue;
    }

    handleFocus(event) {
        // When the input gains focus, capture its current value
        this._initialValue = event.target.value;
    }

    handleInput(event) {
        if (this.maxDecimals === undefined || this.maxDecimals === null) return;
        const value = event.target.value;
        // Find decimal separator (dot or comma)
        const dotIdx = value.indexOf('.');
        const commaIdx = value.indexOf(',');
        const decIdx = Math.max(dotIdx, commaIdx);
        if (decIdx !== -1) {
            const afterDecimal = value.substring(decIdx + 1);
            if (afterDecimal.length > parseInt(this.maxDecimals, 10)) {
                event.target.value = value.substring(0, decIdx + 1 + parseInt(this.maxDecimals, 10));
            }
        }
    }

    handleKeyUp(event) {
        const newValue = event.target.value;
        
        // Clear the existing timer if the user is still typing
        if (this._debounceTimer) {
            clearTimeout(this._debounceTimer);
        }
        
        // Set a new timer. If the user stops typing for 700ms (0.7 second), commit the value.
        this._debounceTimer = setTimeout(() => {
            this.commitValue(newValue);
        }, 700);
    }

    handleBlur(event) {
        const newValue = event.target.value;
        
        // If the user clicks Save immediately after typing, kill the pending keyup timer
        if (this._debounceTimer) {
            clearTimeout(this._debounceTimer);
        }
        
        // Force the commit instantly
        this.commitValue(newValue);
    }

    commitValue(newValue) {
        const input = this.template.querySelector('lightning-input');

        if (this.validateNegative && input) {
            const isNegative = newValue !== '' && newValue !== null && Number(newValue) < 0;
            input.setCustomValidity(isNegative ? this.label.ERR_NEGATIVE_VALUE : '');
            input.reportValidity();
        }

        const isFieldValid = input ? input.checkValidity() : true;

        // Check if the new value is different from the initial value
        if (newValue !== this._initialValue) {
            this.inputValue = newValue; // Update the inputValue property
            this._initialValue = newValue; // Reset initial value to prevent duplicate dispatches

            this.dispatchEvent(new CustomEvent('customtextinputchanged', {
                composed: true,
                bubbles: true,
                cancelable: true,
                detail: {
                    data: {
                        context: this.context,
                        value: this.inputValue,
                        fieldname: this.fieldname,
                        fieldlabel: this.fieldlabel,
                        isFieldValid
                    }
                }
            }));
        }
    }
}