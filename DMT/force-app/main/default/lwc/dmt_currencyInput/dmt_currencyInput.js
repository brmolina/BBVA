import { LightningElement, api } from 'lwc';
import pubsub from 'omnistudio/pubsub';

export default class Dmt_currencyInput extends LightningElement {

    withCurrency = false;

    _currencyIsoCode;
    _initialValue;
    _value;
    _isPubsubEvent;
    _step = 0.01;;
    _pattern;
    _objectType;
    _required = false;

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
            let formatValue = parseFloat(String(value).replace(/[.,]/g, match => (match === ',' ? '.' : '')));
            this.value = formatValue;
            this._initialValue = formatValue;
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

    handleInputblur(event) {

        console.log('----- event.target.value ' + event.target.value);

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
}