import { LightningElement, api } from 'lwc';

export default class Dmt_numberInputWithAddButtons extends LightningElement {

    //Variables 
    numberValue;
    eventName;
    _subtractDisabled;
    @api label;
    @api finalValue;
    
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
        this.eventName = 'subtractNumber';
        this.dispatchEvent(new CustomEvent(this.eventName, {bubbles: true, composed: true}));  
    }

    addNumber(){
        if(this.numberValue != null){
            this.numberValue = this.numberValue + 1;
        }
        this.eventName = 'addNumber';
        this.dispatchEvent(new CustomEvent(this.eventName, {bubbles: true, composed: true}));  
    }

}