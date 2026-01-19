import { LightningElement, track, wire, api } from 'lwc';
import getStepsFromCase from '@salesforce/apex/DMT_Case_Steps_Controller.getStepsFromCase';

export default class Dmt_case_tasks_recordpage extends LightningElement {

    @api recordId;

    columns = [
        {label: "TASK", fieldName: 'step', type: 'url'},
        {label: "APPROVER", fieldName: 'approver', type: 'text' },
        {label: "STATUS", fieldName: 'status', type: 'text'},
        {label: "LINE/OPP STATUS", fieldName: 'lineOppStatus', type: 'text'},
        {label: "TASK DETAILS", fieldName: 'taskDetails', type: 'text'},
        {label: "RESULT", fieldName: 'result', type: 'text'}
    ];

    dataFromApex = [];
    isDataReceived = false;

    @wire(getStepsFromCase, {caseId:'$recordId'})
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