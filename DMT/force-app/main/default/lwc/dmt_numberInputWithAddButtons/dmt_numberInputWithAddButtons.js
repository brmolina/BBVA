import { LightningElement, api, track } from 'lwc';

export default class Dmt_numberInputWithAddButtons extends LightningElement {

    //Variables 
    numberValue;
    eventName;
    _subtractDisabled;
    @track _finalValue;
    @api label;
    @api field;
    @api
    set finalValue(value){
        if (value != null && !String(value).includes('month(s)')) {
            this._finalValue = value + ' month(s)';
        } else {
            this._finalValue = value;
        }

        console.log('final value: ' + this._finalValue);
    }

    get finalValue() {
        return this._finalValue;
    }
    _required;
    @api
    set required(value){
        this._required = value;
    }

    get required() {
        return this._required;
    }
    @api 
    set subtractDisabled(value){
        this._subtractDisabled = (value === 'true' || value === true); 
    }

    get subtractDisabled() {
        return this._subtractDisabled;
    }

    //functions
    subtractNumber(){
        if(this.numberValue > 0){
            this.numberValue = this.numberValue - 1;
        }
        console.log('field: ' + this.field);
        if(this.field == 'DMT_Business_Approval_Term__c'){
                                console.log('1');

            this.eventName = 'substractNumberBusiness';
        }else{
                                console.log('2');

            this.eventName = 'subtractNumber';
        }
        this.dispatchEvent(new CustomEvent(this.eventName, {bubbles: true, composed: true}));  

        
    }

    addNumber(){
        if(this.numberValue != null){
            this.numberValue = this.numberValue + 1;
        }
        console.log('field: ' + this.field);

        if(this.field == 'DMT_Business_Approval_Term__c'){
                    console.log('1');

            this.eventName = 'addNumberBusiness';
        }else{
                                console.log('2');

            this.eventName = 'addNumber';
        }
        this.dispatchEvent(new CustomEvent(this.eventName, {bubbles: true, composed: true}));  

    }

}