import { LightningElement, api } from 'lwc';
import DMT_HELPTEXT_WARNING from '@salesforce/label/c.DMT_ReadOnly_Warningtooltip';

export default class DatatablePicklist extends LightningElement {
    @api label;
    @api placeholder;
    @api options;
    @api value;
    @api context;
    @api fieldname;
    @api isdisabled;
    @api requieresvaluerecopick;
    @api showreadonlywarning;
    readChange;

    labels = {
        DMT_HELPTEXT_WARNING
    }
    //@api readonlyAttr;
    @api
    get  readonlywarning() {     
      
      return (this.value == "Edit" || this.value == "All") && this.showreadonlywarning
    }
    @api
    get  readonlyAttr() {
      return this.readChange;
    }
    set readonlyAttr(value) {
        if (this.value === "All") {
            this.readonly = true;
        }
        else if(value && !this.options.find((option) => option.value === this.value) && this.value != ''){console.log('in get debe',this.value);
            this.optionsValue.push({label:this.label??this.value ,value:this.value});
            this.readonly = true;
        }
        else{console.log('in get attr',value);console.log('in get debe',this.value);
            this.readonly = value;
        }
    }
    @api optionslimit;
    optionsValue;
    readonly = false;



    @api
    get readOnlyField() {
        return this.readonly || (this.isdisabled || this.requieresvaluerecopick);
}

    connectedCallback(){
       
        console.log('value options',this.options.find((option) => option.value === this.value));
        this.optionsValue = JSON.parse(JSON.stringify(this.options));
        if(this.optionslimit){console.log('optionsValue',JSON.stringify(this.optionsValue));
            const index = this.optionsValue.findIndex(option => option.value === this.optionslimit);
            this.optionsValue = this.optionsValue.slice(index+1);
        }
        if(!this.options.find((option) => option.value === this.value) && this.value != '' ){console.log('in no debe',this.value);
            this.optionsValue.push({label:this.label??this.value ,value:this.value});
                }
        console.log('value opt',JSON.stringify(this.optionsValue));
    }

    renderedCallback(){
        if(this.fieldname === 'initTerm'){
            this.readonly = true;console.log('iiiin readonly',this.fieldname);
        }
    }

    handleChange(event) {
        //show the selected value on UI
        this.value = event.detail.value;
        console.log("2121JSON",JSON.stringify(event.detail));
        //fire event to send context and selected value to the data table
        this.dispatchEvent(new CustomEvent('picklistchanged', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                data: { context: this.context, value: this.value, fieldname: this.fieldname}
            }
        }));
    }
    handleClick(event){

    }

    /**
     * containerStyleWarining- CIBGLOBALD-1439 
     * Returns the set of CSS classes for the combobox container.
     * Adds the help text/warning class if 'readonlywarning' is true,
     * otherwise applies the standard combobox class.
     * @returns {string} The CSS class list for the combobox container.
     */
    get containerStyleWarining() {

        return this.readonlywarning
            ? 'slds-truncate combobox-container-with-helptext'
            : 'slds-truncate combobox-container';
    }

}