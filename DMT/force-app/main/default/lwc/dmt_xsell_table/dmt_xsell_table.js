import { LightningElement,api,wire,track } from 'lwc';

import getXsell from "@salesforce/apex/DMT_XSell.getXSellRecords";
import DMT_Styles from "@salesforce/resourceUrl/DMT_Styles";
import { loadStyle } from "lightning/platformResourceLoader";


export default class Dmt_xsell_table extends LightningElement {

@api recordId;
@track xSell;
@track activeSections =['xSell'];
@track isExpanded = true;
@track icon = 'utility:chevrondown';

  columns = [
    {
      label: 'YEAR',
      fieldName: 'g_year__c',
      type: 'number',
      cellAttributes: { alignment: 'center' }
    },
    {
      label: 'NOTIONAL AMOUNT',
      fieldName: 'g_notional_amount__c',
      type: 'number',
      cellAttributes: { alignment: 'center' }
    },
    {
      label: 'CURRENCY',
      fieldName: 'g_currency__c',
      type: 'text',
      cellAttributes: { alignment: 'center' }
    }
  ];

  @wire(getXsell,{opportunityId: '$recordId'})
  wiredXsell({ error, data }) {

    var dataFormat = [];

    if (data != undefined) {

      data.forEach(element => {
        var elementFormat = Object.assign({}, element);
        elementFormat.g_year__c = new Date(element.g_year__c).getFullYear();
        dataFormat.push(elementFormat);
      });

      this.xSell = dataFormat;
      this.error = undefined;

    } else if (error) {
      this.error = error;
      this.xSell = undefined;
    }
  }

  renderedCallback() {

    Promise.all([loadStyle(this, DMT_Styles)])
    .then(() => {
        console.log("Static Resource Loaded");
    })
    .catch(error => {
        console.log("error-", error);
    });
  }

  recordToggle(event) {

    this.isExpanded = !this.isExpanded;

    if(this.isExpanded) {
      this.icon = 'utility:chevrondown';
    }else {
      this.icon = 'utility:chevronright';
    }

  }
}