import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import astro from '@salesforce/resourceUrl/ONB_Astro';
import ONB_SALESPERSON_TITLE from '@salesforce/label/c.ONB_SALESPERSON_TITLE';
import ONB_NO_SALESPERSON from '@salesforce/label/c.ONB_NO_SALESPERSON';

// Your object + lookup to User
import SALES_PERSON_ID from '@salesforce/schema/ONB_Onboarding__c.Client_Sales_Person__c';
import SALES_PERSON_NAME from '@salesforce/schema/ONB_Onboarding__c.Client_Sales_Person__r.Name';
import SALES_PERSON_EMAIL from '@salesforce/schema/ONB_Onboarding__c.Client_Sales_Person__r.Email';
import SALES_PERSON_PHONE from '@salesforce/schema/ONB_Onboarding__c.Client_Sales_Person__r.Phone';
import SALES_PERSON_PHOTO from '@salesforce/schema/ONB_Onboarding__c.Client_Sales_Person__r.SmallPhotoUrl';

const FIELDS = [
    SALES_PERSON_ID,
    SALES_PERSON_NAME,
    SALES_PERSON_EMAIL,
    SALES_PERSON_PHONE,
    SALES_PERSON_PHOTO
];

export default class Onb_userCard extends LightningElement {
    @api recordId;
    label ={
        ONB_SALESPERSON_TITLE,
        ONB_NO_SALESPERSON
    }
    record;
    error;
    isLoading = true;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ data, error }) {
        console.log('➡️ wiredRecord called');
        console.log('recordId received in LWC:', this.recordId);

        if (data) {
            // Deep clone just for readable logging
            console.log(
                '✅ getRecord data:',
                JSON.parse(JSON.stringify(data))
            );
            this.record = data;
            this.error = undefined;
        } else if (error) {
            console.error(
                '❌ getRecord error:',
                JSON.parse(JSON.stringify(error))
            );
            this.error = error;
            this.record = undefined;
        } else {
            console.log('ℹ️ wiredRecord called with no data and no error');
        }

        this.isLoading = false;
    }

    // Helpers
    get userId() {
        if (!this.record) {
            console.log('userId getter → no record yet');
            return null;
        }
        const id = getFieldValue(this.record, SALES_PERSON_ID);
        console.log('userId getter →', id);
        return id;
    }

    get userName() {
        if (!this.record) {
            console.log('userName getter → no record yet');
            return null;
        }
        const name = getFieldValue(this.record, SALES_PERSON_NAME);
        console.log('userName getter →', name);
        return name;
    }

    get userEmail() {
        if (!this.record) {
            console.log('userEmail getter → no record yet');
            return null;
        }
        const email = getFieldValue(this.record, SALES_PERSON_EMAIL);
        console.log('userEmail getter →', email);
        return email;
    }

    get userPhone() {
        if (!this.record) {
            console.log('userPhone getter → no record yet');
            return null;
        }
        const phone = getFieldValue(this.record, SALES_PERSON_PHONE);
        console.log('userPhone getter →', phone);
        return phone;
    }

    // get userPhotoUrl() {
    //     if (!this.record) {
    //         console.log('userPhotoUrl getter → no record yet');
    //         return null;
    //     }
    //     const photo = getFieldValue(this.record, SALES_PERSON_PHOTO);
    //     console.log('userPhotoUrl getter →', photo);
    //     return photo;
    // }

    get avatarSrc() {
        // return this.userPhotoUrl ? this.userPhotoUrl : astro;
        return astro;
    }

    get hasUser() {
        const has = !!this.userId;
        console.log('hasUser getter →', has);
        return has;
    }

    get noUser() {
        const noUser = !this.isLoading && !this.hasUser;
        console.log('noUser getter →', noUser, 'isLoading:', this.isLoading);
        return noUser;
    }

    get userUrl() {
        const url = this.userId
            ? `/lightning/r/User/${this.userId}/view`
            : '#';
        console.log('userUrl getter →', url);
        return url;
    }
}