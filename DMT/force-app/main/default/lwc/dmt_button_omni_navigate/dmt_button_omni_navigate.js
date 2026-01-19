import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';

export default class Dmt_card_sobject extends OmniscriptBaseMixin(LightningElement) {

    @api buttonText;
    @api stepName;

    goToStep() {
        this.omniNavigateTo(this.stepName);  
    }
}