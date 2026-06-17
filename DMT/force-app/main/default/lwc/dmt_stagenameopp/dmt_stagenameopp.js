// opportunityStageListener.js
import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';

const FIELDS = [STAGE_FIELD];

export default class Dmt_stagenameopp extends LightningElement {
    @api recordId;

    previousStage;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ data, error }) {
        if (data) {
            const newStage = getFieldValue(data, STAGE_FIELD);
            if (this.previousStage && this.previousStage !== newStage) {
                this.handleStageChange(this.previousStage, newStage);
            }
            this.previousStage = newStage;
        }
        if (error) {
            console.error('Error obteniendo StageName:', error);
        }
    }

    handleStageChange(oldStage, newStage) {
        console.log(`StageName cambió de "${oldStage}" a "${newStage}"`);
        this.dispatchEvent(new CustomEvent('reloadParent', {
                            bubbles: true,
                            composed: true,
                            detail: {  }
                        }));
        }
}