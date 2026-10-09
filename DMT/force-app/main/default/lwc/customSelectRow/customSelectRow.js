import { LightningElement, api } from 'lwc';

export default class customSelectRow extends LightningElement {
    _aviableItem = false;
    _checkedItem = false;

    @api
    get aviableItem() {
        return this._aviableItem;
    }
    set aviableItem(val) {
        this._aviableItem = val === true || val === 'true';
    }

    @api
    get checkedItem() {
        return this._checkedItem;
    }
    set checkedItem(val) {
        this._checkedItem = val === true || val === 'true';
    }

    @api fieldname;
    @api context;
  
    handleCheckBoxSelected(event) {
        //show the selected value on UI
        this._checkedItem = event.target.checked;
        console.log("2121JSON",JSON.stringify(event.detail));
        console.log("2121Field",JSON.stringify(this.fieldname));
        //fire event to send context and selected value to the data table
        this.dispatchEvent(new CustomEvent('customselectrowchanged', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                data: { context: this.context, value: this._checkedItem, fieldname: this.fieldname}
            }
        }));
    }
}