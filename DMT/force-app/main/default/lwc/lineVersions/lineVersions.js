import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import STATUS_FIELD from '@salesforce/schema/DMT_Line__c.Status__c';
import LINE_ID_FIELD from '@salesforce/schema/DMT_Line__c.Line_Id__c';
import checkEditPermission from '@salesforce/apex/DMT_LineController.checkEditPermission';
import hasLineGodPermission from '@salesforce/customPermission/DMT_Line_God';

export default class LineVersions extends LightningElement {
    recordId;
    status;
    lineid;

    isButtonDisabled = false;

    columns = [
        { label: 'Select', type: 'customselectRow', hideDefaultActions: true, cellAttributes: { style: 'text-align: center;' },
            typeAttributes: {
                aviableItem: true,
                checkedItem: { fieldName: 'isSelected' },
                fieldName: 'id',
                context: { fieldName: 'versionNumber' }
            }
        },
        { label: 'Name', fieldName: 'name', type: 'text', hideDefaultActions: true},
        { label: 'User', fieldName: 'user', type: 'text', hideDefaultActions: true },
        { label: 'Created Date', fieldName: 'createdDate', type: 'date', hideDefaultActions: true,
            type: 'date-local',
            typeAttributes:{
            month: "2-digit",
            day: "2-digit",
            year: "numeric"
            }
        },
        { label: 'Version Number', fieldName: 'versionNumber', type: 'text', hideDefaultActions: true },
        { label: 'Category', fieldName: 'category', type: 'text', hideDefaultActions: true },
        { label: 'Version', fieldName: 'version', type: 'text', hideDefaultActions: true }
    ];

    data = [
        {
            id: '1',
            name: 'Version 1',
            user: 'John Doe',
            createdDate: '2025-04-01',
            versionNumber: 101,
            category: 'Category A',
            version: 1,
            isSelected: false
        },
        {
            id: '2',
            name: 'Version 2',
            user: 'Jane Smith',
            createdDate: '2025-04-15',
            versionNumber: 102,
            category: 'Category B',
            version: 2,
            isSelected: false
        },
        {
            id: '3',
            name: 'Version 3',
            user: 'Alice Johnson',
            createdDate: '2025-04-20',
            versionNumber: 103,
            category: 'Category C',
            version: 3,
            isSelected: false
        }
    ];

    selectedRows = [];

    connectedCallback() {
        console.log('Connected callback executed');
        console.log('Status:', this.status);
        console.log('Record ID:', this.recordId);
        console.log('isbuttonDisabled:', this.isButtonDisabled);
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            console.log('CurrentPageReference:', JSON.stringify(currentPageReference));
            
            // Check standard and custom state parameters
            this.recordId = currentPageReference.state?.recordId || currentPageReference.state?.c__recordId || currentPageReference.attributes?.recordId;

            console.log('RecordId from page ref:', this.recordId);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [STATUS_FIELD, LINE_ID_FIELD] })
    wiredRecord({ error, data }) {
        console.log('Wired record executed');
        if (data) {
            console.log('Record data:', JSON.stringify(data));
            this.status = data.fields.Status__c.value;
            this.lineid = data.fields.Line_Id__c.value;
            console.log('Status:', this.status);
            console.log('Line ID:', this.lineid);

            if(this.status != 'Approval'){
                this.isButtonDisabled = true;
            } else {
                this.handleCheckEditPermission();
            }
        } else if (error) {
            console.error('Error retrieving record:', error);
        }
    }

    handleCheckEditPermission() {
        console.log('Checking edit permission hasLineGodPermission:', hasLineGodPermission);
        if (hasLineGodPermission) {
            this.isButtonDisabled = false;
        } else {
            checkEditPermission({ recordId: this.recordId })
                .then((result) => {
                    console.log('Check Edit permission result:', result);
                    const { isAdmin, DMT_ApprovalEdit__c } = result;
                    this.isButtonDisabled = !(isAdmin || DMT_ApprovalEdit__c);
                    console.log('isButtonDisabled:', this.isButtonDisabled);
                })
                .catch((error) => {
                    console.error('Error determining button state:', error);
                });
        }
    }

    renderedCallback() {
        console.log('Rendered callback executed');
        console.log('Status:', this.status);
        console.log('Record ID:', this.recordId);
        console.log('isbuttonDisabled:', this.isButtonDisabled);
    }

    handleCreateNewVersion() {
        console.log('Create New Version button clicked');
    }

    getSelectedRows(event) {
        console.log('Get selected rows event fired');
        // Display that fieldName of the selected rows
        /* for (let i = 0; i < selectedRows.length; i++) {
            console.log('You selected: ' + selectedRows[i].versionNumber);
        } */
    }

    selectedRowChanged(event) {
        event.stopPropagation();
        console.log('Selected row changed:', JSON.stringify(event.detail));
        let dataRecieved = event.detail.data;
        console.log('Selected row changed:', JSON.stringify(dataRecieved));
        const selectedVersionNumber = event.detail.data.context; // This is the versionNumber

        // Update the data array to ensure only one row is selected at a time
        this.data = this.data.map(row => {
            return {
                ...row,
                isSelected: row.versionNumber === selectedVersionNumber
            };
        });

        console.log('Updated data with selected row:', JSON.stringify(this.data));
    }
}