import { LightningElement,track,api } from 'lwc';
import fetchAccounts from '@salesforce/apex/MergeSelectAccountCnt.fetchLookUpValues';

export default class MergeSelectAccount extends LightningElement {
  @api recordId;
  @api iconName;
  @api objectAPIName
  @api label
  @api message
  @api fieldsToGet
  @api filter
  @api fieldToOrder
  @api selectedRecordId
  @track selectedValue
  @track searchKeyWord
  @track iconNametoShow = 'standard:account'
  @track listOfSearchRecords
  @track fieldsSplit = []
  @track fieldsSplit1 = []
  @track errorClient
  @track areVisible

  connectedCallback() {
    this.iconNametoShow = 'standard:'+ this.iconName;
    let varSplit = this.fieldsToGet.split(',');
    const index = varSplit.indexOf('Id');
    if (index > -1) {
      varSplit.splice(index, 1);
    }
    for(var i = 0; i <= varSplit.length-1; i++) {
      if(i == 0 || i % 2 == 0) {
        this.fieldsSplit.push(varSplit[i].trim());
      } else {
        this.fieldsSplit1.push(varSplit[i].trim());
      }
    }
    if(this.selectedValue !== undefined && this.selectedValue !== null && this.selectedValue !== '') {
      var forclose =  this.template.querySelector('[data-id="lookup-pill"]')
      forclose.classList.add('slds-show');
      forclose.classList.remove('slds-hide');

      var forclose1 =  this.template.querySelector('[data-id="searchRes"]')
      forclose1.classList.add('slds-is-close');
      forclose1.classList.remove('slds-is-open');

      var lookUpTarget =  this.template.querySelector('[data-id="lookupField"]')
      lookUpTarget.classList.add('slds-hide');
      lookUpTarget.classList.remove('slds-show');
    }
  }

  onfocus(event) {
    this.template.querySelector('[data-id="mySpinner"]').classList.add('slds-show');
    var forOpen =  this.template.querySelector('[data-id="searchRes"]')
    forOpen.classList.add('slds-is-open');
    forOpen.classList.remove('slds-is-close');

    // Get Default 5 Records order by createdDate DESC
    var getInputkeyWord = '';
    this.callFetchAccount(getInputkeyWord);
  }

  onChangeController(event) {
    var getInputkeyWord = event.target.value;
    if (getInputkeyWord.length > 0) {
      var forOpen = this.template.querySelector('[data-id="searchRes"]')
      forOpen.classList.add('slds-is-open');
      forOpen.classList.remove('slds-is-close');
      this.callFetchAccount(getInputkeyWord);
    } else {
      this.listOfSearchRecords = null;
      var forclose1 =  this.template.querySelector('[data-id="searchRes"]')
      forclose1.classList.add('slds-is-close');
      forclose1.classList.remove('slds-is-open');
    }
  }

  handleRemove(event) {
    var pillTarget =  this.template.querySelector('[data-id="lookup-pill"]');
    pillTarget.classList.add('slds-hide');
    pillTarget.classList.remove('slds-show');

    var lookUpTarget =  this.template.querySelector('[data-id="lookupField"]');
    lookUpTarget.classList.add('slds-show');
    lookUpTarget.classList.remove('slds-hide');

    var lupa = this.template.querySelector('[data-id="lupa"]');
    lupa.classList.add('slds-show');
    lupa.classList.remove('slds-hide')

    var box = this.template.querySelector('[data-id="box"]');
    box.classList.add('slds-hide');
    box.classList.remove('slds-show');

    this.template.querySelector('lightning-input[data-name="inputText"]').value = null;
    this.SearchKeyWord = null;
    this.listOfSearchRecords = null;
    this.selectedRecordId = null;
    this.areVisible = false;
  }

  onSelect(event) {
    this.selectedRecordId = event.currentTarget.dataset.id;
    this.selectedValue = event.currentTarget.dataset.name;
    this.areVisible = true;

    var forclose =  this.template.querySelector('[data-id="lookup-pill"]');
    forclose.classList.add('slds-show');
    forclose.classList.remove('slds-hide');

    var forclose1 =  this.template.querySelector('[data-id="searchRes"]');
    forclose1.classList.add('slds-is-close');
    forclose1.classList.remove('slds-is-open');

    var lookUpTarget =  this.template.querySelector('[data-id="lookupField"]');
    lookUpTarget.classList.add('slds-hide');
    lookUpTarget.classList.remove('slds-show');

    var lupa = this.template.querySelector('[data-id="lupa"]');
    lupa.classList.add('slds-hide');
    lupa.classList.remove('slds-show');

    var box = this.template.querySelector('[data-id="box"]');
    box.classList.add('slds-show');
    box.classList.remove('slds-hide');
  }

  callFetchAccount(getInputkeyWord) {
    fetchAccounts({searchKeyWord: getInputkeyWord, objectName : this.objectAPIName, fieldsToGet: this.fieldsToGet, filter: this.filter, fieldToOrder: this.fieldToOrder})
    .then((result) => {
      this.listOfSearchRecords = null;
      if(result.length === 0) {
        this.message = 'No Result Found...';
      } else {
        this.message = '';
      }
      this.listOfSearchRecords = result;
      this.errorClient = null;
    })
    .catch((error) => {
      console.log('Entra catch');
      this.errorClient = error;
      this.listOfSearchRecords = null;
      this.message = 'No Result Found...';
    });
  }
}