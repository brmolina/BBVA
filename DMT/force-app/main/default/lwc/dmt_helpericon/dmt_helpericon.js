import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import ccsicon from '@salesforce/resourceUrl/DMT_Styles';

export default class Dmt_helpericon extends LightningElement 
{
    @api iconName;
    @api iconSize;
    @api text;
    @api iconVariant;

    renderedCallback() {
        Promise.all([
            loadStyle(this, ccsicon)
        ]);
      } 

    handleOnClick () 
    {
        this.template.querySelector('[data-id="divHelp"]').classList.toggle('slds-hide');
    }

    handleMouseLeave () 
    {
        this.template.querySelector('[data-id="divHelp"]').classList.add('slds-hide');
    }

    handleMouseEnter ()
    {
        this.template.querySelector('[data-id="divHelp"]').classList.remove('slds-hide');
    }
}