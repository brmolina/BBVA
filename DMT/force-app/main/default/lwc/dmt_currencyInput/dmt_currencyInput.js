import { LightningElement, api } from 'lwc';
import pubsub from 'omnistudio/pubsub';
import userLocale from '@salesforce/i18n/locale';
import ERR_NEGATIVE_VALUE from '@salesforce/label/c.DMT_Negative_Value_Error';
import { parseAbbreviatedNumber } from 'c/dmt_numberUtils';

export default class Dmt_currencyInput extends LightningElement {

    errorLabels = {
        ERR_NEGATIVE_VALUE
    };

    withCurrency = false;

    _currencyIsoCode;
    _initialValue;
    _value;
    _isPubsubEvent;
    _step = 0.01;
    _pattern;
    _objectType;
    _required = false;
    _formatOnBlur = false;
    _isFocused = false;
    _displayValue;

    parseLocalizedNumber(rawValue) {
        if (rawValue === null || rawValue === undefined || rawValue === '') {
            return rawValue;
        }

        const value = String(rawValue).trim();
        if (/[KMBT]$/i.test(value)) {
            return parseAbbreviatedNumber(value, true);
        }

        const hasDot = value.includes('.');
        const hasComma = value.includes(',');

        if (hasDot && hasComma) {
            if (userLocale.startsWith('es')) {
                return parseFloat(value.replace(/\./g, '').replace(',', '.'));
            }

            return parseFloat(value.replace(/,/g, ''));
        }

        if (hasComma) {
            if (userLocale.startsWith('es')) {
                return parseFloat(value.replace(',', '.'));
            }

            return parseFloat(value.replace(/,/g, ''));
        }

        if (hasDot) {
            // Check if dot is decimal separator (followed by 1-3 digits at the end)
            // or thousands separator (followed by exactly 3 digits not at the end)
            const dotIndex = value.lastIndexOf('.');
            const digitsAfterDot = value.length - dotIndex - 1;
            const isDecimalSeparator = digitsAfterDot >= 1 && digitsAfterDot <= 3 && dotIndex === value.indexOf('.');
            
            if (userLocale.startsWith('es')) {
                if (isDecimalSeparator) {
                    // Single dot followed by 1-3 digits: treat as decimal (user typed decimal with dot)
                    return parseFloat(value);
                }
                // Otherwise treat dot as thousands separator
                return parseFloat(value.replace(/\./g, ''));
            }

            return parseFloat(value);
        }

        return parseFloat(value);
    }

    @api label;
    @api eventName;
    @api channelName;
    @api compactLabel = false;
    @api disabled = false;

    @api
    set objectType(value){
        this._objectType = value;
    }

    get objectType() {
        return this._objectType;
    }

    @api
    set pattern(value){
        this._pattern = value;
    }

    get pattern() {
        return this._pattern;
    }

    @api
    set initialValue(value){
        if(this._initialValue === null || this._initialValue === undefined) {
            console.log('----- initialValue ' + value);
            console.log('----- userLocale ' + userLocale);
            console.log('----- this.value ' + this.value);
            this.value = this.parseLocalizedNumber(value);
            this._initialValue = this.value;
        }
    }

    get initialValue() {
        return this._initialValue;
    }
    
    @api
    set value(value){
        console.log('----- value ' + value);

        this._value = value;
        this._displayValue = this._formatOnBlur && !this._isFocused
            ? this.formatValue(value)
            : value;
    }

    get value() {
        return this._value;
    }

    @api
    set formatOnBlur(value) {
        this._formatOnBlur = value === true || value === 'true';
        this._displayValue = this._formatOnBlur && !this._isFocused
            ? this.formatValue(this._value)
            : this._value;
    }

    get formatOnBlur() {
        return this._formatOnBlur;
    }

    get inputType() {
        return this._formatOnBlur ? 'text' : 'number';
    }

    get displayValue() {
        return this._displayValue;
    }

    formatValue(value) {
        if (value === null || value === undefined || value === '') {
            return '';
        }

        const numericValue = Number(value);
        return Number.isFinite(numericValue) ? numericValue.toLocaleString('en-US') : value;
    }

    @api 
    set isPubsubEvent(value){
        this._isPubsubEvent = (value === 'true' || value === true); 
    }

    get isPubsubEvent() {
        return this._isPubsubEvent;
    }

    @api 
    set currencyIsoCode(value){
        this._currencyIsoCode = value;
        this.withCurrency = true;
    }

    get currencyIsoCode() {
        return this._currencyIsoCode;
    }

    @api
    set step(value){
        this._step = value;
    }

    get step() {
        return this._step;
    }

    @api
    set required(value){
        this._required = value;
    }

    get required() {
        return this._required;
    }

    @api helpTextMessage = '';

    _pendingValue;

    @api
    checkValidity() {
        const input = this.template.querySelector('lightning-input');
        const val = parseFloat(input.value);

        if (!isNaN(val) && val < 0) {
            input.setCustomValidity(this.errorLabels.ERR_NEGATIVE_VALUE);
            input.reportValidity();
            return false;
        }

        input.setCustomValidity('');
        input.reportValidity();
        return true;
    }

    handleInputChange(event) {
        this._pendingValue = event.target.value;
        this._displayValue = event.target.value;
    }

    handleInputFocus() {
        this._isFocused = true;
        this._displayValue = this._value ?? '';
    }

    handleInputblur(event) {

        const rawValue = this._pendingValue !== undefined ? this._pendingValue : event.target.value;
        this._pendingValue = undefined;

        const val = this.parseLocalizedNumber(rawValue);
        const input = this.template.querySelector('lightning-input');

        if (!isNaN(val) && val < 0) {
            input.setCustomValidity(this.errorLabels.ERR_NEGATIVE_VALUE);
            input.reportValidity();

            const parsedNegativeValue = this.parseLocalizedNumber(rawValue);
            this._displayValue = this._formatOnBlur ? this.formatValue(parsedNegativeValue) : rawValue;
            if (this.isPubsubEvent) {
              pubsub.fire(this.channelName, this.eventName, {
                value: parsedNegativeValue,
                isFieldValid: input.checkValidity()
              });
            } else {
              this.dispatchEvent(
                new CustomEvent(this.eventName, {
                  detail: { value: parsedNegativeValue, isFieldValid: input.checkValidity() },
                  bubbles: true,
                  composed: true
                })
              );
            }

            return;
        }

        input.setCustomValidity('');
        input.reportValidity();

        if(rawValue == null || rawValue == undefined || rawValue == '' || rawValue === 0) {
            if(this.objectType != 'Line'){
                  this._value = 0;
            }
        }

        // Parse the value to normalize decimal format before sending to backend
        const parsedValue = this.parseLocalizedNumber(rawValue);
        this._value = parsedValue;
        this._displayValue = this._formatOnBlur ? this.formatValue(parsedValue) : parsedValue;
        this._isFocused = false;
        
        if(this.isPubsubEvent) {
            pubsub.fire(this.channelName, this.eventName, { value: parsedValue, isFieldValid: input.checkValidity() });
        }else {
            this.dispatchEvent(new CustomEvent(this.eventName, {detail: { value: parsedValue, isFieldValid: input.checkValidity() }, bubbles: true, composed: true}));  
        }
    }

    handleKeyDown(event) {
        if(userLocale.startsWith('es') && event.key === '.') {
            event.preventDefault();
            event.target.blur();
        }else if(!userLocale.startsWith('es') && event.key === ','){
            event.preventDefault();
            event.target.blur();
        }
    }
}