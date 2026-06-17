import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = ['User.DMT_User_Role__c'];

export default class Dmt_record_picker extends LightningElement {
    @api value;
    @api fieldname;
    @api placeholder;
    @api objectapiname;
    @api variant;
    @api displayinfo;
    @api matchinginfo;
    @api filter;
    @api disabled;

    @track selectedRecordId;
    dmtRole;
    contextval;

    // Flag to ensure we only fire the event once per component load
    //_hasRendered = false;

    @api
    get context() {
        return this.contextval;
    }

    set context(value) {
        this.contextval = value;
    }

    @wire(getRecord, { recordId: '$selectedRecordId', fields: FIELDS })
    wiredUserRecord({ error, data }) {
        if (data) {
            this.dmtRole = data.fields.DMT_User_Role__c.value;
            this.fireRecordPickerChangeEvent();
        } else if (error) {
            console.error('Error fetching user data: ', error);
            this.dmtRole = null;
        }
    }

    handleChangerecord(event) {
        const selectedId = event.detail.recordId;

        // If no ID is selected, clear it and fire event
        if (!selectedId) {
            this.selectedRecordId = null;
            this.dmtRole = null;
            this.fireRecordPickerChangeEvent();
            return;
        }

        // Only update if the ID actually changed
        if (selectedId !== this.selectedRecordId) {
            this.selectedRecordId = selectedId;
        }
    }

    // Centralized method to fire the event back to the datatable
    fireRecordPickerChangeEvent() {
        this.dispatchEvent(new CustomEvent('recordpickerchange', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                data: {
                    context: this.context,
                    value: this.selectedRecordId,
                    fieldname: this.fieldname,
                    dmtUserRole: this.dmtRole
                }
            }
        }));
    }
}