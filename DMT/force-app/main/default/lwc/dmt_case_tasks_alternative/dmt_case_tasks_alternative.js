import { LightningElement, track, wire } from 'lwc';
import getStepsFromUser from '@salesforce/apex/DMT_Case_Steps_Controller.getStepsFromUser';

export default class Dmt_case_tasks_alternative extends LightningElement {

    columns = [
        {label: "TASK", fieldName: 'step', type: 'url'},
        {label: "TASK STATUS", fieldName: 'status', type: 'text'},
        {label: "LINE/OPP STATUS", fieldName: 'lineOppStatus', type: 'text'},
        {label: "RESULT", fieldName: 'result', type: 'text'},
        {label: "START DATE", fieldName: 'startDate', type: 'text'},
        {label: "END DATE", fieldName: 'endDate', type: 'text'},
        {label: "LINE/OPP ID", fieldName: 'lineOppId', type: 'text'},
        {label: "GROUP NAME", fieldName: 'groupClientName', type: 'text'},
        {label: "CLIENT", fieldName: 'client', type: 'text'},
        {label: "APPROVER", fieldName: 'approver', type: 'text' },
        {label: "USER", fieldName: 'user', type: 'text'},
        {label: "LINE/OPP", fieldName: 'lineOrOpportunity', type: 'text'},
        {label: "LINE/OPP NAME", fieldName: 'oppLineName', type: 'url'},
        {label: "LINE DETAILS" , fieldName: 'lineDetails', type: 'text'},
        {label: "ADDITIONAL DETAILS", fieldName: 'taskDetails', type: 'text'}
    ];

    filters = [
        {label: 'Select one or several clients', fieldName: 'client'},
        {label: 'Select one or several tasks status', fieldName: 'status'},
        {label: 'Select if line or opportunity', fieldName: 'lineOrOpportunity'},
    ]

    dataFromApex = [];
    isDataReceived = false;

    @wire(getStepsFromUser)
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