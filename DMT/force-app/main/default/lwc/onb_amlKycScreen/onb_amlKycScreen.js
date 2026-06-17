import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import ONB_ENTITY_TYPE_FIELD from '@salesforce/schema/ONB_Onboarding__c.Entity_Type__c';
import ONB_LEGAL_ENTITY_TYPE_FIELD from '@salesforce/schema/ONB_Onboarding__c.Legal_Entity_Type__c';

// ----------------------
// Card titles (labels)
// ----------------------
import BUSSINESS_CASE_DETAILS from '@salesforce/label/c.ONB_BUSSINESS_CASE_DETAILS';
import CLIENT_CONTACT from '@salesforce/label/c.ONB_CLIENT_CONTACT';
import ENTITY_DETAILS from '@salesforce/label/c.ONB_ENTITY_DETAILS';
import ONB_HEAD_OFFICE_BRANCH from '@salesforce/label/c.ONB_HEAD_OFFICE_BRANCH';

// Business case
import ONB_FIRST_TRADE_DATE from '@salesforce/label/c.ONB_FIRST_TRADE_DATE';
import ONB_ANNUAL_FRANCHISE from '@salesforce/label/c.ONB_ANNUAL_FRANCHISE';

// Client contact
import ONB_DELEGATE_CONTACT_AML_KYC from '@salesforce/label/c.ONB_DELEGATE_CONTACT_AML_KYC';
import ONB_CLIENT_CONTACT_NAME from '@salesforce/label/c.ONB_CLIENT_CONTACT_NAME';
import ONB_CLIENT_CONTACT_EMAIL from '@salesforce/label/c.ONB_CLIENT_CONTACT_EMAIL';
import ONB_CLIENT_CONTACT_PHONE from '@salesforce/label/c.ONB_CLIENT_CONTACT_PHONE';

// Entity details (left)
import ONB_LEGAL_ENTITY_TYPE from '@salesforce/label/c.ONB_LEGAL_ENTITY_TYPE';
import ONB_ENTITY_TYPE from '@salesforce/label/c.ONB_ENTITY_TYPE';
import ONB_GROUP_NAME from '@salesforce/label/c.ONB_GROUP_NAME';
import ONB_INCORPORATION_COUNTRY from '@salesforce/label/c.ONB_INCORPORATION_COUNTRY';
import ONB_ENTITY_CATEGORY from '@salesforce/label/c.ONB_ENTITY_CATEGORY';
import ONB_SWIFT_BIC from '@salesforce/label/c.ONB_SWIFT_BIC';

// Entity details (right)
import ONB_ENTITY_ROLE from '@salesforce/label/c.ONB_ENTITY_ROLE';
import ONB_RELATIONSHIP_CENTRE from '@salesforce/label/c.ONB_RELATIONSHIP_CENTRE';
import ONB_BUSINESS_PLACE from '@salesforce/label/c.ONB_BUSINESS_PLACE';
import ONB_BUSINESS_REL_NATURE from '@salesforce/label/c.ONB_BUSINESS_REL_NATURE';


//Empty State Message
import ONB_EMPTY_STATE_CONTACT_MSSG from '@salesforce/label/c.ONB_EMPTY_STATE_CONTACT_MSSG';

// ----------------------
// Helpers
// ----------------------
const mapFromPairs = (pairs) => Object.freeze(Object.fromEntries(pairs));
const freezeList = (list) => Object.freeze([...list]);

const ONBOARDING_OBJECT_API_NAME = 'ONB_Onboarding__c';

// ----------------------
// Sections (fields + labels)
// ----------------------
const SECTIONS = Object.freeze({
    businessCase: {
        fields: freezeList(['First_Date_Trade__c', 'Estimated_Annual_Franchise__c']),
        labels: mapFromPairs([
            ['First_Date_Trade__c', ONB_FIRST_TRADE_DATE],
            ['Estimated_Annual_Franchise__c', ONB_ANNUAL_FRANCHISE]
        ])
    },

    clientContact: {
        fields: freezeList(['Delegate_contact__c', 'Contact_Name__c', 'Contact_Email__c', 'Contact_Phone__c']),
        labels: mapFromPairs([
            ['Delegate_contact__c', ONB_DELEGATE_CONTACT_AML_KYC],
            ['Contact_Name__c', ONB_CLIENT_CONTACT_NAME],
            ['Contact_Email__c', ONB_CLIENT_CONTACT_EMAIL],
            ['Contact_Phone__c', ONB_CLIENT_CONTACT_PHONE]
        ])
    },

    entityLeft: {
        fields: freezeList(['Legal_Entity_Type__c', 'Entity_Type__c', 'Group_Name__c', 'Incorporation_Country__c', 'Legal_Entity_Category__c']),
        labels: mapFromPairs([
            ['Legal_Entity_Type__c', ONB_LEGAL_ENTITY_TYPE],
            ['Entity_Type__c', ONB_ENTITY_TYPE],
            ['Group_Name__c', ONB_GROUP_NAME],
            ['Incorporation_Country__c', ONB_INCORPORATION_COUNTRY],
            ['Legal_Entity_Category__c', ONB_ENTITY_CATEGORY],
        ])
    },

    entityRight: {
        fields: freezeList(['Legal_Entity_Type__c', 'Legal_Entity_Role__c', 'Main_Relationship_Centre__c', 'Business_Place__c', 'Business_Rel_Nature__c', 'SWIFT_BIC__c']),
        labels: mapFromPairs([
            ['Legal_Entity_Role__c', ONB_ENTITY_ROLE],
            ['Main_Relationship_Centre__c', ONB_RELATIONSHIP_CENTRE],
            ['Business_Place__c', ONB_BUSINESS_PLACE],
            ['Business_Rel_Nature__c', ONB_BUSINESS_REL_NATURE],
            ['SWIFT_BIC__c', ONB_SWIFT_BIC]
        ])
    },

    branchLeft: {
        fields: freezeList(['Associated_Entity_Name__c']),
        labels: mapFromPairs([])
    },

    branchRight: {
        fields: freezeList(['Legal_Entity_Id__c']),
        labels: mapFromPairs([])
    }

});

// ----------------------
// Rules placeholders per section
// Fill these with your required/disabled/readonly/visibility logic
// ----------------------
const RULES = Object.freeze({
    businessCase: Object.freeze({}),
    clientContact: Object.freeze({
    Contact_Name__c: {
        disabledWhen: {
        field: 'Delegate_contact__c',
        op: 'eq',
        value: 'No'
        }
    },
    Contact_Email__c: {
        disabledWhen: {
        field: 'Delegate_contact__c',
        op: 'eq',
        value: 'No'
        }
    },
    Contact_Phone__c: {
        disabledWhen: {
        field: 'Delegate_contact__c',
        op: 'eq',
        value: 'No'
        }
    }
    }),
    entityLeft: Object.freeze({}),
    entityRight: Object.freeze({
        Legal_Entity_Type__c: {
            visibleWhen: {
                field: 'Id',
                op: 'eq',
                value: 'OCULTO_SIEMPRE'
            }
        },
        SWIFT_BIC__c: {
        visibleWhen: {
        field: 'Legal_Entity_Type__c',
        op: 'in',
        value: ['Bank', 'Central Bank']
        },
        disabledWhen: {
            field: 'Legal_Entity_Type__c',
            op: 'notIn',
            value: ['Bank', 'Central Bank']
        }
    },
    }),
    branchLeft: Object.freeze({}),
    branchRight: Object.freeze({}),
    relationshipContacts: Object.freeze({})
});

const LEGAL_ENTITY_TYPES_ALLOWED = new Set([
    'Bank',
    'Insurance Company',
    'Investment manager',
    'Regulated Financial Institution',
    'Subsidiary of Public Company'
]);


export default class Onb_AmlKycScreen extends LightningElement {
    @api recordId;
    headOfficeResult;
    entityTypeValue;
    legalEntityTypeValue;
    onboardingObjApiName = ONBOARDING_OBJECT_API_NAME;
    sections = SECTIONS;
    rules = RULES;
    isBranchOpen = false;

    label = {
        BUSSINESS_CASE_DETAILS,
        CLIENT_CONTACT,
        ENTITY_DETAILS,
        ONB_HEAD_OFFICE_BRANCH,
        ONB_EMPTY_STATE_CONTACT_MSSG
    };

    @wire(getRecord, { recordId: '$recordId', fields: [ONB_ENTITY_TYPE_FIELD, ONB_LEGAL_ENTITY_TYPE_FIELD] })
    wiredRecord({ error, data }) {
        if (data) {
            this.entityTypeValue = getFieldValue(data, ONB_ENTITY_TYPE_FIELD);
            this.legalEntityTypeValue = getFieldValue(data, ONB_LEGAL_ENTITY_TYPE_FIELD);
            this.fieldValidation(this.entityTypeValue, this.legalEntityTypeValue);
        } else if (error) {
            console.error('Error fetching record', error);
        }
    }


    handleEntityTypeChange({ detail: { fieldApiName, value } }) {
        if (fieldApiName === 'Entity_Type__c') {
            this.entityTypeValue = value;
        } else if (fieldApiName === 'Legal_Entity_Type__c') {
            this.legalEntityTypeValue = value;
            if (value !== 'Bank' && value !== 'Central Bank') {
                this.clearSwiftBic();
            }
        } else {
            return;
        }

        this.fieldValidation(this.entityTypeValue, this.legalEntityTypeValue);
    }

    fieldValidation(entityTypeValue, legalEntityTypeValue) {
        const shouldOpen = entityTypeValue === 'Branch' && LEGAL_ENTITY_TYPES_ALLOWED.has(legalEntityTypeValue);
        this.setBranchOpen(shouldOpen);
    }

    async clearSwiftBic() {
        if (!this.recordId) return;

        const fields = {
            Id: this.recordId,
            SWIFT_BIC__c: null
        };

        try {
            await updateRecord({ fields });
        } catch (e) {
            console.error('Error clearing SWIFT BIC', JSON.stringify(e));
        }
    }

    // Expand/collapse with a frame boundary (helps transitions trigger reliably)
    setBranchOpen(shouldOpen) {
        if (shouldOpen) {
            this.isBranchOpen = false;
            requestAnimationFrame(() => {
                this.isBranchOpen = true;
            });
        } else {
            this.isBranchOpen = false;
            this.clearBranchFields();
        }
    }

    async clearBranchFields() {
        if (!this.recordId) return;

        const fields = {
            Id: this.recordId,
            Associated_Entity_Name__c: null,
            Legal_Entity_Id__c: null
        };

        try {
            await updateRecord({ fields });
            console.log('Branch fields cleared');
        } catch (e) {
            console.error('Error clearing branch fields', JSON.stringify(e));
        }
    }

    get branchAnimClass() {
        return this.isBranchOpen
            ? 'onb-collapseGrid onb-collapseGrid--open'
            : 'onb-collapseGrid';
    }

     @api
    validate() {
        let ok = true;

        this.template.querySelectorAll('c-onb_onboarding-form').forEach((cmp) => {
            if (cmp?.validate && !cmp.validate()) ok = false;
        });

        this.template.querySelectorAll('c-onb_onboarding-table').forEach((cmp) => {
            if (cmp?.validate && !cmp.validate()) ok = false;
        });
        return ok;/** */
    }
}