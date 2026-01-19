import { LightningElement, api, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import launchCuco from '@salesforce/messageChannel/Launch_Cuco__c';

export default class LaunchCucoQA extends LightningElement {

  @api recordId;

  @wire(MessageContext)
  messageContext;

  @api invoke() {
      const payload = { contextId: this.recordId  };
      publish(this.messageContext, launchCuco, payload);
  }
}