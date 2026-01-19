import { LightningElement, api } from 'lwc';

export default class LoansWrapper extends LightningElement {
    @api family;
    @api recordId;

}