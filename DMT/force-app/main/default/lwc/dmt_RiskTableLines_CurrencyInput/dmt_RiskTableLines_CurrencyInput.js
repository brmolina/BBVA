import { LightningElement, api, track } from 'lwc';
import totalAmountLabel from '@salesforce/label/c.dmt_cl_TotalAmount';
import AmountLabel from '@salesforce/label/c.dmt_cl_Amount';


export default class Dmt_RiskTableLines_CurrencyInput extends LightningElement {

    //Variables
    @track currencyTrack;
    @track conversionLabelTrack;
    @track totalAmountTypeTrack;
    @track totalAmountTrack;
    @track showLabelCurrencyTrack;
    @track combLabel;
    @track showTRSRtrack;
    @track showOTHRtrack;

    //variable set to show or hide the currency label
    @api  showTRSR;
    set showTRSR(value){
        this.showTRSRtrack = value;
    }
    get showTRSR() {
        return this.showTRSRtrack === "true";
    }

    @api
    set showOTHR(value){
        this.showOTHRtrack = value;
    }
    get showOTHR() {
        return this.showOTHRtrack === "true";
    }
    
    @api 
    set currency(value){
        this.currencyTrack = value;
    }
    get currency() {
        return this.currencyTrack;
    }
    
    @api 
    set conversionLabel(value){
        this.conversionLabelTrack = value;
    }
    get conversionLabel() {
        return this.conversionLabelTrack;
    }

    @api 
    set totalAmountType(value){
        this.totalAmountTypeTrack = value;
    }
    get totalAmountType() {
        return this.totalAmountTypeTrack;
    }

    @api 
    set totalAmount(value){
        this.totalAmountTrack = value;
    }
    get totalAmount() {
        return this.totalAmountTrack;
    }
   //store the labels
    label = {totalAmountLabel, AmountLabel};
   

     //renderedCallback function
    renderedCallback() {
       //Label when is the amount for a line of TRSR
        if(this.showTRSRtrack == true || this.showTRSRtrack == 'true' ){
             this.combLabel = this.label.totalAmountLabel + ' ' + this.conversionLabel;
        }
         //Label when is the amount for a line of OTHR
        else{
             this.combLabel = this.label.AmountLabel + ' {' + this.conversionLabel + ' ' + this.currency + '}';
        }
        this.currencyTrack = this.currencyTrack;
        this.totalAmountTrack = this.totalAmountTrack;
        console.log('totalAmountType: ' + this.totalAmountType);
        console.log('conversionLabel: ' + this.conversionLabel);
    }
    
    //handleInputblur function dispatch the event to the card
    handleInputblur(event) {
        const  totalAmountTypeEvent = this.totalAmountType;
        const  amountTracked = event.target.value;

        if(amountTracked != '' && this.totalAmountType != ''){
            this.dispatchEvent( new CustomEvent('updatetedTotalAmount', {detail: {totalAmountType: totalAmountTypeEvent, amountTracked: amountTracked }, bubbles: true, composed: true}));
        }
    }
}