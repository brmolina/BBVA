import { LightningElement, api } from 'lwc';
import pubsub from 'omnistudio/pubsub';
import userLocale from '@salesforce/i18n/locale';
import ERR_NEGATIVE_VALUE from '@salesforce/label/c.DMT_Negative_Value_Error';

export default class Dmt_currencyInput extends LightningElement {

    label = {
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

    parseLocalizedNumber(rawValue) {
        if (rawValue === null || rawValue === undefined || rawValue === '') {
            return rawValue;
        }

        const value = String(rawValue).trim();
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
            if (userLocale.startsWith('es')) {
                return parseFloat(value.replace(/\./g, ''));
            }

            return parseFloat(value);
        }

        return parseFloat(value);
    }

    @api label;
    @api eventName;
    @api channelName;

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
    }

    get value() {
        return this._value;
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

    @api
    checkValidity() {
        const input = this.template.querySelector('lightning-input');
        const val = parseFloat(input.value);

        if (!isNaN(val) && val < 0) {
            input.setCustomValidity(this.label.ERR_NEGATIVE_VALUE);
            input.reportValidity();
            return false;
        }

        input.setCustomValidity('');
        input.reportValidity();
        return true;
    }

    handleInputblur(event) {

        const val = parseFloat(event.target.value);
        const input = this.template.querySelector('lightning-input');

        if (!isNaN(val) && val < 0) {
            input.setCustomValidity(this.label.ERR_NEGATIVE_VALUE);
            input.reportValidity();
            return;
        }

        input.setCustomValidity('');
        input.reportValidity();

        if(event.target.value == null || event.target.value == undefined || event.target.value == '') {
            if(this.objectType != 'Line'){
                  event.target.value = 0;
            }
        }

        if(this.isPubsubEvent) {
            pubsub.fire(this.channelName, this.eventName, { value: event.target.value});
        }else {
            this.dispatchEvent(new CustomEvent(this.eventName, {detail: { value: event.target.value}, bubbles: true, composed: true}));  
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