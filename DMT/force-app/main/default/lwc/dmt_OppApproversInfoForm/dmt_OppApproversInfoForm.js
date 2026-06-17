import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import XSELL_SYNC_CHANNEL from '@salesforce/messageChannel/DmtXSellSync__c';

import STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';

import pubsub from 'omnistudio/pubsub';
import saveXSellRecords from '@salesforce/apex/DMT_XSell.saveXSellRecords';

const FIELDS          = [STAGE_FIELD];
const EDITABLE_STAGES = ['Draft', 'Proposal'];

export default class Dmt_OppApproversInfoForm extends LightningElement {

    @api recordId;

    @track isEditMode = false;  // Controls read/edit view mode
    @track isSaving   = false;  // Controls spinner and disabled state of buttons

    // Local Cache populated strictly by the Message Channel
    cachedXsellData = [];
    cachedXsellDelete = [];
    xsellSubscription = null;

    @wire(MessageContext)
    messageContext;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    opportunity;

    connectedCallback() {
        pubsub.register('Save', {
            DMT_CLIENT_GROUP_V2: this.handleFlexCardSave.bind(this)
        });

        this.xsellSubscription = subscribe(
            this.messageContext,
            XSELL_SYNC_CHANNEL,
            (message) => {
                console.log('[XSELL_SYNC_CHANNEL] Message received:', JSON.stringify(message));
                if (message.xsellData) {
                    this.cachedXsellData = message.xsellData;
                    console.log('[XSELL_SYNC_CHANNEL] Cached rows:', this.cachedXsellData.length);
                }
                if (message.xsellDelete) {
                    this.cachedXsellDelete = message.xsellDelete;
                    console.log('[XSELL_SYNC_CHANNEL] Cached delete IDs:', this.cachedXsellDelete.length);
                }
            }
        );
    }

    disconnectedCallback() {
        pubsub.unregister('Save', {
            DMT_CLIENT_GROUP_V2: this.handleFlexCardSave.bind(this)
        });

        if (this.xsellSubscription) {
            unsubscribe(this.xsellSubscription);
            this.xsellSubscription = null;
        }
    }

    // ─── Getters ──────────────────────────────────────────────────────────────

    get canEdit() {
        const stage = getFieldValue(this.opportunity?.data, STAGE_FIELD);
        return EDITABLE_STAGES.includes(stage);
    }

    get isReadOnly() {
        return !this.isEditMode;
    }


    notifyEditMode(value) {
        this.dispatchEvent(new CustomEvent('editmodetab', {
            detail   : { editMode: value },
            bubbles  : true,
            composed : true
        }));
    }

    // ─── Handlers ─────────────────────────────────────────────────────────────

    handleEdit() {
        if (!this.canEdit) return;
        this.isEditMode = true;
        this.notifyEditMode(true);
    }

    handleCancel() {
        this.isEditMode = false;
        this.isSaving   = false;
        this.notifyEditMode(false);

        this.refs['DMT_Booking_Unit_Risk_Analyst__c']?.reset();
        this.refs['DMT_Approver__c']?.reset();
        this.refs['DMT_ApproverGlobalBanker__c']?.reset();
    }

    handleChange(event) {
        //console.log(`Field changed → ${event.target.fieldName}:`, event.detail.value);
    }

    handleSave() {
        this.isSaving = true;
        this.refs.submitBtn?.click();
    }

    handleSuccess() {
        this.isSaving   = false;
        this.isEditMode = false;
        this.notifyEditMode(false);

        this.dispatchEvent(new ShowToastEvent({
            title  : 'Success',
            message: 'Record updated successfully',
            variant: 'success'
        }));
    }

    handleError(event) {
        this.isSaving = false;

        this.dispatchEvent(new ShowToastEvent({
            title  : 'Error',
            message: event.detail.detail,
            variant: 'error'
        }));
    }

    /**
     * Triggered by the FlexCard Save event.
     * Bypasses the FlexCard payload entirely and uses the LMS cached data to execute the Apex DML.
     */
    async handleFlexCardSave() {
        this.isSaving = true;

        console.log('[DEBUG] Sibling executing Save from LMS cache.');
        
        let xsellDataToSave = this.cachedXsellData || [];
        let xsellIdsToDelete = this.cachedXsellDelete || [];

        let validDataToSave = [];

        console.log('[DEBUG] Before validation', JSON.stringify(xsellDataToSave, null, 2));

        xsellDataToSave.forEach(row => {
            const hasGeo = row.Booking_Geography__c && String(row.Booking_Geography__c).trim() !== '';
            const hasNumbers = row.XSELL_Value_PY__c != null || row.XSELL_Value_CY__c != null || row.XSELL_Value_NY__c != null || row.XSELL_Value_NY1__c != null;
            const hasRealId = row.Id && row.Id !== '0' && String(row.Id).length >= 15 && !String(row.Id).includes('{');

            if (!hasGeo && !hasNumbers) {
                // Row is completely empty. If it has a real Salesforce ID, queue it for deletion.
                if (hasRealId && !xsellIdsToDelete.includes(row.Id)) {
                    xsellIdsToDelete.push(row.Id);
                }
            } else {
                // Row has data (Geo or Numbers). Keep it for the update list and validation.
                validDataToSave.push(row);
            }
        });

        xsellDataToSave = validDataToSave;

        // MANDATORY FIELD VALIDATION: Booking Geography
        // If a row survived the ghost filter, it means it has data. It MUST have a geography.
        const hasMissingGeography = xsellDataToSave.some(row => !row.Booking_Geography__c || String(row.Booking_Geography__c).trim() === '');

        console.log('[DEBUG] hasMissingGeography',hasMissingGeography);
        
        if (hasMissingGeography) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Missing Required Field',
                message: 'Cross SELL update ABORTED. Please select a Geography for all Cross Sell rows before saving.',
                variant: 'error',
                mode: 'sticky'
            }));
            
            // Abort the save, turn off the spinner, and force them to fix it
            this.isSaving = false;
            return;
        }

        // Inject parent relationship ID and sobjectType into the pre-cleaned rows
        if (xsellDataToSave.length > 0) {
            xsellDataToSave = xsellDataToSave.map(row => ({
                ...row,
                sobjectType: 'DMT_X_Sell__c',
                Opportunity__c: this.recordId
            }));
        }

        // Only fire Apex if there is actual XSell data to process
        if (xsellDataToSave.length > 0 || xsellIdsToDelete.length > 0) {
            try {
                this.isSaving = true;
                console.log('[DEBUG] Sibling sending payload to Apex xsellDataToSave:', JSON.stringify(xsellDataToSave));
                console.log('[DEBUG] Sibling sending payload to Apex xsellIdsToDelete:', JSON.stringify(xsellIdsToDelete));
                
                await saveXSellRecords({ 
                    recordsToUpsert: xsellDataToSave, 
                    recordsToDelete: xsellIdsToDelete 
                });
                
                /* this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Cross Sell records saved successfully.',
                    variant: 'success'
                })); */
                
            } catch (error) {
                console.error('[DEBUG] Apex Save Error:', error);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error saving Cross Sell Data',
                    message: error.body ? error.body.message : error.message,
                    variant: 'error'
                }));
            } finally {
                this.isSaving = false;
            }
        }
    }
}