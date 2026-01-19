import { LightningElement, api } from 'lwc';

export default class CustomInputRow extends LightningElement {
    @api aviableItem;
    @api inputValue;
    @api fieldname;
    @api context;

    _initialValue;

    connectedCallback() {
        // Store the initial value when the component is connected to the DOM
        this._initialValue = this.inputValue;
    }
    
    handleFocus(event) {
        // When the input gains focus, capture its current value
        this._initialValue = event.target.value;
    }

    handleBlur(event) {
        const newValue = event.target.value;
        // Check if the new value is different from the initial value
        if (newValue !== this._initialValue) {
            this.inputValue = newValue; // Update the inputValue property

            this.dispatchEvent(new CustomEvent('customtextinputchanged', {
                composed: true,
                bubbles: true,
                cancelable: true,
                detail: {
                    data: { context: this.context, value: this.inputValue, fieldname: this.fieldname }
                }
            }));
        }
    }

    /*handleInputChange(event) {
        console.log('juanevent:', JSON.stringify(event, null, 2));
        console.log("juanField",JSON.stringify(this.fieldname));
        this.inputValue = event.target.value;
        console.log("Input Value:", this.inputValue);
        console.log("juanJSON",JSON.stringify(event.detail));
        this.dispatchEvent(new CustomEvent('customtextinputchanged', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                data: { context: this.context, value: this.inputValue, fieldname: this.fieldname }
            }
        }));
    }*/
}