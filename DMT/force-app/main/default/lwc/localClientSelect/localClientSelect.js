import { LightningElement,track,api,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import gtLocalList from '@salesforce/apex/LocalClientSelectCont.gtLocalClients';
import gtLocalCountry from '@salesforce/apex/LocalClientSelectCont.gtLocalCountries';


export default class LocalClientSelect extends NavigationMixin(LightningElement) {
  @track valueAcc;
  @track valueCountry;
  @track optionsClient;
  @track optionsCountry;
  @track errorClient;
  @track errorCountry;
  @track showDisabled = true;
  @api recordId;
  @api clientVar;


  @wire(gtLocalCountry, {clientCode: '$clientVar'})
  completeCountries({ error, data }) { 
    if(data) {
      this.optionsCountry = [];
      var obj = JSON.parse(data);
      if(obj.length === 1) {
        this.valueCountry = obj[0].localId;
        this.callToGtLocal(obj[0].localId);
      }
      for(let lclient of obj) {
        this.optionsCountry.push({ value: lclient.localId, label: lclient.localName });
      }
      this.errorCountry = null;
    } else if(error) {
      this.errorCountry = error;
      this.optionsCountry = null;
    }
  }

  handleCountryChange(event) {
    this.valueCountry = event.target.value;
    this.callToGtLocal(this.valueCountry);
  }

  handleAccChange(event) {
    this.valueAcc = event.target.value;
    this.showDisabled = false;
  }

  continueFunction() {
    this[NavigationMixin.Navigate] ({
      type: 'standard__recordPage',
      attributes: {
        recordId: this.valueAcc,
        objectApiName: this.valueAcc.startsWith('001')
        ? 'Account'
        : 'Local_Client__c',
        actionName: 'view'
      }
    });
  }

  callToGtLocal(valueCountry) {
    gtLocalList({clientCode: this.clientVar, countryCode : valueCountry})
    .then((result) => {
      this.optionsClient = [];
      var obj = JSON.parse(result);
      if(obj.length === 1) {
        this.valueAcc = obj[0].localId;
        this.showDisabled = false;
      }
      for(let lclient of obj) {
        this.optionsClient.push({ value: lclient.localId, label: lclient.localName });
      }
      this.errorClient = null;
    })
    .catch((error) => {
        this.errorClient = error;
        this.optionsClient = null;
    });
  }
}