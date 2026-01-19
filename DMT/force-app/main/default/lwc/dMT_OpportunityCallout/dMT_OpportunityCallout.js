import { LightningElement, wire } from 'lwc';
import getMockResponse from '@salesforce/apex/DMT_CalloutLine_Opp.getMockResponse';

export default class DMT_OpportunityCallout extends LightningElement {
    columns;
    lines;
    error;

    columns = [
        { label: 'Line ID', fieldName: 'lineId' },
        { label: 'Line Name', fieldName: 'lineName' }
    ];

    @wire(getMockResponse)
    wiredLines({ error, data }) {
        if (data) {
            this.lines = data;
        } else if (error) {
            this.error = error;
        }
    }
}