import { LightningElement, api } from 'lwc';

export default class customSelectRow extends LightningElement {
    @api aviableItem;
    @api checkedItem;
    @api fieldname;
    @api context;
  
    handleCheckBoxSelected(event) {
    //show the selected value on UI
    this.checkedItem = event.target.checked;
    console.log("2121JSON",JSON.stringify(event.detail));
    console.log("2121Field",JSON.stringify(this.fieldname));
    //fire event to send context and selected value to the data table
    this.dispatchEvent(new CustomEvent('customselectrowchanged', {
        composed: true,
        bubbles: true,
        cancelable: true,
        detail: {
            data: { context: this.context, value: this.checkedItem, fieldname: this.fieldname}
        }
    }));
    }
  }