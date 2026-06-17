import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import PATH_STEP_FIELD from '@salesforce/schema/ONB_Onboarding__c.Step__c';
// Title label (you can swap to a Custom Label later if you want)
const REQUEST_DETAILS_TITLE = 'Request Details';

// Field custom labels
import ONB_IS_SALESPERSON from '@salesforce/label/c.ONB_IS_SALESPERSON';
import ONB_IN_PLATFORM from '@salesforce/label/c.ONB_IN_PLATFORM';
import ONB_MASTER_AGREEMENT from '@salesforce/label/c.ONB_MASTER_AGREEMENT';

// Helpers
const mapFromPairs = (pairs) => Object.freeze(Object.fromEntries(pairs));
const freezeList = (list) => Object.freeze([...list]);

const OBJECT_API_NAME = 'ONB_Onboarding__c';

// Sections (fields + labels)
const STEP_CONFIG = Object.freeze({
    'FUNDS': {
        fields: freezeList([
            'Request_Type__c',
            'Any_Master_Agreement__c'
        ]),
        labels: mapFromPairs([
            ['Is_Sales_Person__c', ONB_IS_SALESPERSON],
            ['Operation_in_Platform__c', ONB_IN_PLATFORM],
            ['Any_Master_Agreement__c', ONB_MASTER_AGREEMENT]
        ]),
        rules: Object.freeze({
            Request_Type__c: { readOnly: true },
            Any_Master_Agreement__c: { readOnly: true }
        })
    },
    'CONTRACT': {
        fields: freezeList([
            'Request_Type__c',
            'Is_Sales_Person__c',
            'Operation_in_Platform__c',
            'Any_Master_Agreement__c'
        ]),
        labels: mapFromPairs([
            ['Is_Sales_Person__c', ONB_IS_SALESPERSON],
            ['Operation_in_Platform__c', ONB_IN_PLATFORM],
            ['Any_Master_Agreement__c', ONB_MASTER_AGREEMENT]
        ]),
        rules: Object.freeze({
            Request_Type__c: { readOnly: true },
            Is_Sales_Person__c: { readOnly: true },
            Operation_in_Platform__c: { readOnly: true },
            Any_Master_Agreement__c: { readOnly: true }
        })
    }
});

export default class Onb_summaryContainer extends LightningElement {
    @api recordId;

    objectApiName = OBJECT_API_NAME;

    label = {
        REQUEST_DETAILS: REQUEST_DETAILS_TITLE
    };

    @wire(getRecord, { recordId: '$recordId', fields: [PATH_STEP_FIELD] })
    onboardingRecord;

    connectedCallback() {
        console.log('this summary record id?: ' + this.recordId);
    }

    renderedCallback() {
        console.log('this rendered?:' + this.recordId);
    }

    get currentStep() {
        return getFieldValue(this.onboardingRecord.data, PATH_STEP_FIELD) || 'CONTRACT';
    }

    get activeConfig() {
        return STEP_CONFIG[this.currentStep] || STEP_CONFIG['CONTRACT'];
    }

    get activeFields() {
        return this.activeConfig.fields;
    }

    get activeLabels() {
        return this.activeConfig.labels;
    }

    get activeRules() {
        return this.activeConfig.rules;
    }
}