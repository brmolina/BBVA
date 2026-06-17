import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import updateRiskLinesAndWarranties from '@salesforce/apex/DMT_OppToSanctionUtils.updateRiskLinesAndWarranties';

import DMT_OPPORTUNITY_FIELD from '@salesforce/schema/DMT_Line__c.DMT_Opportunity__c';

export default class DmtUpdateRiskLinesAction extends LightningElement {
    @api recordId;

    @track isLoading = false;

    @wire(getRecord, { recordId: '$recordId', fields: [DMT_OPPORTUNITY_FIELD] })
    line;

    get opportunityId() {
        return getFieldValue(this.line.data, DMT_OPPORTUNITY_FIELD);
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleUpdate() {
        const oppId = this.opportunityId;

        if (!oppId) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'The line has no associated Opportunity (DMT_Opportunity__c is empty).',
                    variant: 'error'
                })
            );
            return;
        }

        this.isLoading = true;

        try {
            await updateRiskLinesAndWarranties({ oppId, approversId: [], typeFeature: 'risk' });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Risk Lines and Warranties were updated successfully.',
                    variant: 'success'
                })
            );
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (error) {
            const msg =
                error?.body?.message ||
                error?.message ||
                'An unexpected error occurred.';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Update Error',
                    message: msg,
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        } finally {
            this.isLoading = false;
        }
    }
}