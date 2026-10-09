import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue, getRecordNotifyChange, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import XSELL_SYNC_CHANNEL from '@salesforce/messageChannel/DmtXSellSync__c';

import STAGE_FIELD       from '@salesforce/schema/Opportunity.StageName';
import ENTIFIC_FIELD     from '@salesforce/schema/Opportunity.Entific__c';
import BOOKING_RISK_ID   from '@salesforce/schema/Opportunity.DMT_Booking_Unit_Risk_Analyst__c';
import BOOKING_RISK_NAME from '@salesforce/schema/Opportunity.DMT_Booking_Unit_Risk_Analyst__r.Name';
import APPROVER_ID       from '@salesforce/schema/Opportunity.DMT_Approver__c';
import APPROVER_NAME     from '@salesforce/schema/Opportunity.DMT_Approver__r.Name';
import APPROVER_GB_ID    from '@salesforce/schema/Opportunity.DMT_ApproverGlobalBanker__c';
import APPROVER_GB_NAME  from '@salesforce/schema/Opportunity.DMT_ApproverGlobalBanker__r.Name';
import FINANCIAL_SPONSORS_FIELD from '@salesforce/schema/Opportunity.DMT_Financial_Sponsors__c';

import pubsub from 'omnistudio/pubsub';
import saveXSellRecords from '@salesforce/apex/DMT_XSell.saveXSellRecords';

const FIELDS = [
    STAGE_FIELD,
    ENTIFIC_FIELD,
    BOOKING_RISK_ID, BOOKING_RISK_NAME,
    APPROVER_ID,     APPROVER_NAME,
    APPROVER_GB_ID,  APPROVER_GB_NAME,
    FINANCIAL_SPONSORS_FIELD
];
const EDITABLE_STAGES = ['Draft', 'Proposal'];

const APPROVER_FIELD_LABELS = {
    'DMT_Booking_Unit_Risk_Analyst__c': 'Booking Unit Risk Approver (Local)',
    'DMT_Approver__c': 'Financial Program Risk Approver (Global)',
    'DMT_ApproverGlobalBanker__c': 'Approver Global Banker'
};

export default class Dmt_OppApproversInfoForm extends LightningElement {

    @api recordId;
    @api opportunityId;
    @api coordinatedMode = false;

    @track isEditMode = false;  // Controls read/edit view mode
    @track isSaving   = false;  // Controls spinner and disabled state of buttons

    // Draft state (pending edits not yet saved)
    @track draftValues      = {};
    @track draftLookupNames = {};

    _isReadOnlyMode = false;

    // Current saved values (populated by @wire)
    @track stageName;
    @track entificValue;
    @track bookingRiskId;
    @track bookingRiskName;
    @track approverId;
    @track approverName;
    @track approverGBId;
    @track approverGBName;
    @track financialSponsors = false;

    // Local Cache populated strictly by the Message Channel
    cachedXsellData = [];
    cachedXsellDelete = [];
    xsellSubscription = null;

    @wire(MessageContext)
    messageContext;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredOpportunity(result) {
        this.opportunity = result;
        const { data } = result;
        if (data) {
            this.stageName       = getFieldValue(data, STAGE_FIELD);
            this.entificValue    = getFieldValue(data, ENTIFIC_FIELD);
            this.bookingRiskId   = getFieldValue(data, BOOKING_RISK_ID);
            this.bookingRiskName = getFieldValue(data, BOOKING_RISK_NAME);
            this.approverId      = getFieldValue(data, APPROVER_ID);
            this.approverName    = getFieldValue(data, APPROVER_NAME);
            this.approverGBId    = getFieldValue(data, APPROVER_GB_ID);
            this.approverGBName  = getFieldValue(data, APPROVER_GB_NAME);
            this.financialSponsors = getFieldValue(data, FINANCIAL_SPONSORS_FIELD) === true;
        }
    }

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
        if (this._isReadOnlyMode) return false;
        return EDITABLE_STAGES.includes(this.stageName);
    }

    get isReadOnly() {
        return !this.isEditMode;
    }

    get showOwnFooter() {
        return !this.coordinatedMode && this.isEditMode;
    }

    get entific() {
        return this.entificValue || '';
    }

    get bookingRiskValueId() {
        return this.draftValues.DMT_Booking_Unit_Risk_Analyst__c ?? this.bookingRiskId;
    }
    get bookingRiskValueName() {
        return this.draftLookupNames.DMT_Booking_Unit_Risk_Analyst__c ?? this.bookingRiskName;
    }

    get approverValueId() {
        return this.draftValues.DMT_Approver__c ?? this.approverId;
    }
    get approverValueName() {
        return this.draftLookupNames.DMT_Approver__c ?? this.approverName;
    }

    get approverGBValueId() {
        return this.draftValues.DMT_ApproverGlobalBanker__c ?? this.approverGBId;
    }
    get approverGBValueName() {
        return this.draftLookupNames.DMT_ApproverGlobalBanker__c ?? this.approverGBName;
    }

    get financialSponsorsValue() {
        return this.draftValues.DMT_Financial_Sponsors__c ?? this.financialSponsors;
    }


    // ─── Ref-contract methods (coordinated save pattern) ────────────────────

    @api
    enterEditMode() {
        this.isEditMode = true;
    }

    @api
    restoreSnapshot() {
        this.draftValues      = {};
        this.draftLookupNames = {};
        this.isEditMode       = false;
    }

    @api
    commitEdit() {
        this.draftValues      = {};
        this.draftLookupNames = {};
        this.isEditMode       = false;
    }

    @api
    setReadOnlyMode(readOnly) {
        this._isReadOnlyMode = readOnly;
    }

    @api
    collectChanges() {
        if (Object.keys(this.draftValues).length === 0) return null;
        return { ...this.draftValues };
    }
       

    @api
    validateRequired() {
        return { isValid: true, invalidFields: [], invalidFieldIds: [] };
    }

    @api
    getFieldLabel(apiName) {
        return APPROVER_FIELD_LABELS[apiName] || null;
    }

    // ─── Notifications ────────────────────────────────────────────────────────

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
        if (this.coordinatedMode) {
            this.dispatchEvent(new CustomEvent('editmodechange', { bubbles: true, composed: true }));
            return;
        }
        this.isEditMode = true;
        this.notifyEditMode(true);
    }

    handleCancel() {
        this.isEditMode     = false;
        this.isSaving       = false;
        this.draftValues    = {};
        this.draftLookupNames = {};
        this.notifyEditMode(false);
    }

    handleApproverChange(event) {
        const fieldName = event.target.dataset.field;
        const { id, name } = event.detail;
        this.draftValues      = { ...this.draftValues,      [fieldName]: id   };
        this.draftLookupNames = { ...this.draftLookupNames, [fieldName]: name };
        if (this.coordinatedMode) {
            this._notifyFieldChange(fieldName);
        }
    }

    handleApproverClear(event) {
        const fieldName = event.target.dataset.field;
        this.draftValues      = { ...this.draftValues,      [fieldName]: '' };
        this.draftLookupNames = { ...this.draftLookupNames, [fieldName]: '' };
        if (this.coordinatedMode) {
            this._notifyFieldChange(fieldName);
        }
    }

    handleFinancialSponsorsChange(event) {
        const checked = event.target.checked;
        this.draftValues = { ...this.draftValues, DMT_Financial_Sponsors__c: checked };
        if (this.coordinatedMode) {
            this._notifyFieldChange('DMT_Financial_Sponsors__c');
        }
    }

    _notifyFieldChange(fieldId) {
        this.dispatchEvent(new CustomEvent('fieldchange', {
            detail: { fieldId, isFieldValid: true },
            bubbles: true,
            composed: true
        }));
    }

    async handleSave() {
        this.isSaving = true;

        if (Object.keys(this.draftValues).length === 0) {
            this.isEditMode = false;
            this.isSaving   = false;
            this.notifyEditMode(false);
            return;
        }

        const fields = { Id: this.recordId, ...this.draftValues };

        try {
            const saves = [];
            if (Object.keys(fields).length > 1) saves.push(updateRecord({ fields }));
            await Promise.all(saves);
            this.isSaving         = false;
            this.isEditMode       = false;
            this.draftValues      = {};
            this.draftLookupNames = {};
            this.notifyEditMode(false);
            await getRecordNotifyChange([{ recordId: this.recordId }]);
            this.dispatchEvent(new ShowToastEvent({
                title  : 'Success',
                message: 'Record updated successfully',
                variant: 'success'
            }));
        } catch (error) {
            this.isSaving = false;
            let message = error.body?.message || 'An error occurred while saving.';
            if (error.body?.output?.fieldErrors) {
                message = Object.entries(error.body.output.fieldErrors)
                    .map(([field, errors]) => `${field}: ${errors[0].message}`)
                    .join(' / ');
            }
            this.dispatchEvent(new ShowToastEvent({
                title  : 'Error',
                message: message,
                variant: 'error'
            }));
        }
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