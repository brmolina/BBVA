import { LightningElement, wire, api } from 'lwc';
import getStepsFromParentCase from '@salesforce/apex/DMT_Case_Steps_Controller.getStepsFromParentCase';

export default class Dmt_case_parent_tasks_recordpage extends LightningElement {
    @api recordId;

    columns = [
        {label: "TASK", fieldName: 'step', type: 'url'},
        {label: "APPROVER", fieldName: 'approver', type: 'text'},
        {label: "STATUS", fieldName: 'status', type: 'text'},
        {label: "LINE/OPP STATUS", fieldName: 'lineOppStatus', type: 'text'},
        {label: "TASK DETAILS", fieldName: 'taskDetails', type: 'text'},
        {label: "RESULT", fieldName: 'result', type: 'text'}
    ];

    dataFromApex = [];
    isDataReceived = false;

    @wire(getStepsFromParentCase, { caseId: '$recordId' })
    wiredSteps({ error, data }) {
        if (data) {
            this.dataFromApex = data;
            this.isDataReceived = true;
        } else if (error) {
            this.error = error;
            this.isDataReceived = true;
        }
    }
}