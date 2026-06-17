import { LightningElement, api } from 'lwc';

export default class dmtCustomSpinner extends LightningElement {
  @api variant; 
  @api size;    

  get computedVariant() {
    return this.variant?.trim() ? this.variant : 'brand';
  }

  get computedSize() {
    return this.size?.trim() ? this.size : 'large';
  }
}