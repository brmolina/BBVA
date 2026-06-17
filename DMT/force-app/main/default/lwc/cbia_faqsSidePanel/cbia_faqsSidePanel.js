import { LightningElement, api, track } from 'lwc';

import question from '@salesforce/label/c.CBIA_question';
import answer from '@salesforce/label/c.CBIA_answer';

export default class Cbia_faqsSidePanel extends LightningElement {
    label = {
        question,
         answer
    }
    @track isExpanded = false;

    @api listafaqs = [];

    toggleSection(event) {
        event.currentTarget.closest('.slds-accordion__section').classList.toggle('slds-is-open');
        event.currentTarget.children[0].classList.toggle('cib-rotate');
    }
}