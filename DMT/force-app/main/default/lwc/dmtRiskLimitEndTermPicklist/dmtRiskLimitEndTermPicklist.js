import { LightningElement, api } from 'lwc';
export default class DmtRiskLimitEndTermPicklist extends LightningElement {
    @api value;
    @api options = [];
    @api optionslimit;
    _isDisabled = false;
    @api context;

    @api
    get isdisabled() {
        return this._isDisabled;
    }

    set isdisabled(value) {
        this._isDisabled = value === true || String(value).toLowerCase() === 'true';
    }

    get filteredOptions() {
        const options = Array.isArray(this.options) ? [...this.options] : [];
        let filteredOptions = options;

        if (this.optionslimit) {
            const startIndex = options.findIndex(option => String(option.value) === String(this.optionslimit));
            if (startIndex !== -1) {
                filteredOptions = options.slice(startIndex + 1);
            }
        }

        if (this.value && !filteredOptions.some(option => String(option.value) === String(this.value))) {
            filteredOptions = [
                ...filteredOptions,
                { label: this.value, value: this.value }
            ];
        }

        return filteredOptions;
    }

    handleChange(event) {
        console.log('Selected value:', event.detail.value);
        this.dispatchEvent(new CustomEvent('endtermchange', {
            bubbles: true,
            composed: true,
            detail: {
                context: this.context,
                value: event.detail.value
            }
        }));
    }
}