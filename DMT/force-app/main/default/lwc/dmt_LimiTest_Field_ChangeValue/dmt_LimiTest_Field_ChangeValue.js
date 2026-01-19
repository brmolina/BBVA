import { LightningElement, wire, api, track  } from 'lwc';
import pubsub from "omnistudio/pubsub";


export default class Dmt_LimiTest_Field_ChangeValue extends LightningElement{
 
  @api preciounico
  @api producttype;
  @api clienttype;
  @api currencytype;
  @api plazomonthsyears;
  @api itemplazo;

  @track monthsYearValue;
  @track amountValue;
  @track productRiskTypeValue;
  @track clientTypeValue;
  @track currencyTypeValue;
  @track metricTermValue;

  get plazo() {
    return [
        {
          value: '0',
          label: 'Months'
        },
        {
          value: '1',
          label: 'Years'
        }
    ];
  }
  get plazoItem(){ return this.itemplazo == '' ? true : false;}

  renderedCallback() {
    this.clientTypeValue = 'CORP';
    this.currencyTypeValue = 'EUR';
    this.metricTermValue = '1';
    this.productRiskTypeValue = '1000000000';
    this.template.querySelector('select.clienttype').value = 'CORP';
    this.template.querySelector('select.currencytype').value = 'EUR';
    this.template.querySelector('select.plazoMetric').value = '1';

    this.validateRequiredField();
  }

  handleAmountChange(event) {
       
    if(event.target.value != null && this.amountValue != event.target.value) {
      this.amountValue =  event.target.value;
      //pubsub.fire("flexLimitChageValue", "changeValueField", { valueAmount: this.amountValue, fieldType: "amount", chageValue: true }); 
      this.sendAllEvents();
    } 

    this.validateRequiredField();       
  }

  handleMonthsYearsChange(event) {
       
    if(event.target.value != null && this.monthsYearValue != event.target.value) {
      this.monthsYearValue =  event.target.value;
      //pubsub.fire("flexLimitChageValue", "changeValueField", { numberMonthsYears: this.monthsYearValue, fieldType: "numberMonthsYears", chageValue: true });  
      this.sendAllEvents();
    } 

    this.validateRequiredField();
  }

  handleProductTypeChange(event) {

    if(event.target.value != null && this.productRiskTypeValue != event.target.value) {

      this.productRiskTypeValue =  event.target.value;   
      //pubsub.fire("flexLimitChageValue", "changeValueField", { productRiskType: this.productRiskTypeValue, fieldType: "productType", chageValue: true });
      this.sendAllEvents();
    }
    
    this.validateRequiredField();   
  }

  handleClientTypeChange(event){

    if(event.target.value != null && this.clientTypeValue != event.target.value) {

      this.clientTypeValue =  event.target.value; 
      //pubsub.fire("flexLimitChageValue", "changeValueField", { clientType: this.clientTypeValue, fieldType: 'clienttype', chageValue: true });  
      this.sendAllEvents();
    }

    this.validateRequiredField();         
  }

  
  handleCurrencyTypeChange(event){
    
    if(event.target.value != null && this.currencyTypeValue != event.target.value) {

      this.currencyTypeValue =  event.target.value;
      //pubsub.fire("flexLimitChageValue", "changeValueField", { currencyType: this.currencyTypeValue, fieldType: 'currencytype', chageValue: true });  
      this.sendAllEvents();
    }

    this.validateRequiredField();                  
  }

  handlePlazoMetricChange(event){

    if(event.target.value != null && this.metricTermValue != event.target.value) {

      this.metricTermValue =  event.target.value;
      //pubsub.fire("flexLimitChageValue", "changeValueField", { plazoMetric: this.metricTermValue, fieldType: 'plazoMetric', chageValue: true });   
      this.sendAllEvents();
    }

    this.validateRequiredField();          
  }
   
  sendAllEvents() {
    pubsub.fire("flexLimitChageValue", "changeValueField", { numberMonthsYears: this.monthsYearValue, fieldType: "numberMonthsYears", chageValue: true });
    pubsub.fire("flexLimitChageValue", "changeValueField", { valueAmount: this.amountValue, fieldType: "amount", chageValue: true });
    pubsub.fire("flexLimitChageValue", "changeValueField", { productRiskType: this.productRiskTypeValue, fieldType: "productType", chageValue: true });
    pubsub.fire("flexLimitChageValue", "changeValueField", { clientType: this.clientTypeValue, fieldType: 'clienttype', chageValue: true });
    pubsub.fire("flexLimitChageValue", "changeValueField", { currencyType: this.currencyTypeValue, fieldType: 'currencytype', chageValue: true });
    pubsub.fire("flexLimitChageValue", "changeValueField", { plazoMetric: this.metricTermValue, fieldType: 'plazoMetric', chageValue: true });
  }

  validateRequiredField() {
    var isValidate = this.validateFields();
    this.hassError(!isValidate);
  }

  validateFields() {
    return [...this.template.querySelectorAll('lightning-input')].reduce((validSoFar, field) => validSoFar && field.reportValidity(), true);
  }

  hassError(hassError) {
    pubsub.fire("errorFields", "hassError",  { hassError: hassError});
  }
}