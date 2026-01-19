import { LightningElement, api } from 'lwc';

export default class Dmt_multi_select_combobox_item extends LightningElement {
    @api item;

    get itemClass() {
        return `slds-listbox__item ${this.item.selected ? 'slds-is-selected' : ''}`;
    }
  
    handleClick() {
        this.dispatchEvent(
            new CustomEvent('change', {
            detail: { item: this.item, selected: !this.item.selected }
        })
      );
    }
}