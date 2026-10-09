import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import PROSPECT_RECORDTYPEID_FIELD from '@salesforce/schema/Account.RecordTypeId';
import PROSPECT_STATUS_FIELD from '@salesforce/schema/Account.DES_Prospect_Status_Funnel__c';
import PROSPECT_DOMANCYREASON_FIELD from '@salesforce/schema/Account.DES_Dormancy_Reason__c';
import PROSPECT_REENGAGE_FIELD from '@salesforce/schema/Account.DES_possibility_to_reengage_in_the_futur__c';
import DesFunnelModal from 'c/des_funnel_modal';
import { normalizeError } from 'c/des_utils';
import { logError } from 'c/des_exception_utils';

export default class Des_prospect_path extends NavigationMixin(LightningElement) {
    @api recordId;

    account;
    selectedStep;
    recordTypeId;
    showSpinner = false;
    useCustomPath = false; // Set to false to render standard Salesforce Chevron path
    hasGuidance = true;
    showMergeFlow = false;
    shouldStartMergeFlow = false;
    mergeFlowApiName = 'Merge_Prospect_Flow';
    mergeCompleted = false;
    showCloseDecisionModal = false;
    closeDecisionOption = null;
    _currentStep;
    defaultStep = "Identified";

    @wire(getRecord, { recordId: '$recordId', fields: [PROSPECT_RECORDTYPEID_FIELD, PROSPECT_STATUS_FIELD, PROSPECT_DOMANCYREASON_FIELD, PROSPECT_REENGAGE_FIELD] })
    wiredFunction({ error, data }) {
        if (data) {
            this.account = data;
            this.recordTypeId = getFieldValue(data, PROSPECT_RECORDTYPEID_FIELD);
            this.selectedDormancyReason = getFieldValue(data, PROSPECT_DOMANCYREASON_FIELD);
            this.selectedPossibilityReengage = getFieldValue(data, PROSPECT_REENGAGE_FIELD);

            const currentStatus = getFieldValue(data, PROSPECT_STATUS_FIELD);
            
            if (currentStatus) {
                this._currentStep = currentStatus;
                this.selectedStep = currentStatus;
                // Dormant value was the old value for Discarded step
                // If we find a record with Dormant as status, we will treat it as Discarded in the path going forward
                if (currentStatus === 'Dormant') {
                    this._currentStep = 'Discarded';
                    this.selectedStep = 'Discarded';
                }
            } else if (this.defaultStep) {
                this._currentStep = this.defaultStep;
                this.selectedStep = this.defaultStep;
            }
        } else if (error) {
            logError({ componentName: 'des_prospect_path', methodName: 'wiredFunction', error, projectCode: 'HVSC', objectName: 'Account', recordId: this.recordId });
            this.account = undefined;
            this.selectedStep = undefined;
            this.recordTypeId = undefined;
            this._currentStep = undefined;
        }
    }

    prospectStatusPicklistValues;
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: PROSPECT_STATUS_FIELD })
    wiredPicklistValues({ error, data }) {
        if (data) {
            this.prospectStatusPicklistValues = data;
            if (data.values && data.values.length > 0) {
                this.defaultStep = data.values[0].value;
                // If there's no current status on the record, fallback to the dynamic default step
                if (!this._currentStep || this._currentStep === "Identified") {
                    this._currentStep = this.defaultStep;
                    this.selectedStep = this.defaultStep;
                }
            }
        } else if (error) {
            logError({ componentName: 'des_prospect_path', methodName: 'wiredPicklistValues', error, projectCode: 'HVSC', objectName: 'Account', recordId: this.recordId });
            this.prospectStatusPicklistValues = undefined;
        }
    }

    prospectPossibilityReengageValues;
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: PROSPECT_REENGAGE_FIELD })
    wiredProspectPossibilityReengageValues({ error, data }) {
        if (data) {
            this.prospectPossibilityReengageValues = data;
        } else if (error) {
            logError({ componentName: 'des_prospect_path', methodName: 'wiredProspectPossibilityReengageValues', error, projectCode: 'HVSC', objectName: 'Account', recordId: this.recordId });
            this.prospectPossibilityReengageValues = undefined;
        }
    }

    prospectDormancyReasonValues;
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: PROSPECT_DOMANCYREASON_FIELD })
    wiredProspectDormancyReasonValues({ error, data }) {
        if (data) {
            this.prospectDormancyReasonValues = data;
        } else if (error) {
            logError({ componentName: 'des_prospect_path', methodName: 'wiredProspectDormancyReasonValues', error, projectCode: 'HVSC', objectName: 'Account', recordId: this.recordId });
            this.prospectDormancyReasonValues = undefined;
        }
    }

    get prospectStatusOptions() {
        const options = this.prospectStatusPicklistValues && this.prospectStatusPicklistValues.values
            ? this.prospectStatusPicklistValues.values
            : [];
        // Hide Merged/Discarded in the visible path; next-step and disable logic also use this filtered list.
        return options.filter(opt => opt.value !== 'Merged' && opt.value !== 'Discarded');
    }

    get prospectStatusValue() {
        if (this._currentStep === 'Discarded' || this._currentStep === 'Merged') {
            return 'Closed';
        }
        return this._currentStep || '';
    }

    get selectedStepForPath() {
        if (this.selectedStep === 'Discarded' || this.selectedStep === 'Merged') {
            return 'Closed';
        }
        return this.selectedStep;
    }

    get prospectPossibilityReengageOptions() {
        return this.prospectPossibilityReengageValues ? this.prospectPossibilityReengageValues.values : [];
    }

    get prospectDormancyReasonOptions() {
        return this.prospectDormancyReasonValues ? this.prospectDormancyReasonValues.values : [];
    }

    get buttonLabel() {
        if (this.selectedStep === this._currentStep) {
            return 'Mark Prospect status as Complete';
        }
        return 'Mark as Current Prospect status';
    }

    get isDiscardedSelected() {
        return this.selectedStep === 'Discarded' && this.selectedStep !== this._currentStep;
    }

    get isCurrentDiscarded() {
        return this._currentStep === 'Discarded';
    }

    get isMergedSelected() {
        return this.selectedStep === 'Merged' && this.selectedStep !== this._currentStep;
    }

    get isClosedSelected() {
        return this.selectedStep === 'Closed' && this.selectedStep !== this._currentStep;
    }

    get disableMarkComplete() {
        // If selected is current, and it's the final/last step, there is no next step to advance to
        if (this.selectedStep === this._currentStep) {
            const options = this.prospectStatusOptions;
            const currentIdx = options.findIndex(opt => opt.value === this._currentStep);
            return currentIdx === -1 || currentIdx === options.length - 1;
        }
        // Otherwise, if they selected a different step, we can click "Mark as Current Status"
        return false;
    }

    handleStepSelect(event) {
        this.selectedStep = event.detail.stepKey;

        // If user moves away from Merged, hide the embedded flow and reset merge completion state.
        if (this.selectedStep !== 'Merged') {
            this.showMergeFlow = false;
            this.mergeCompleted = false;
        }
        if (this.selectedStep  !== 'Closed') {
            this.showCloseDecisionModal = false;
            this.closeDecisionOption = null;
        }
    }

    get mergeFlowInputVariables() {
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
        ];
    }

    async handleMergeClick() {
        //this.showMergeFlow = true;
        //this.shouldStartMergeFlow = true;
        await DesFunnelModal.open({
            flowName: 'MergeFlow',
            recordId: this.recordId,
            size: 'small'
        });

    }

    handleCloseMergeModal() {
        this.shouldStartMergeFlow = false;
        this.showMergeFlow = false;
    }

    handleCloseDecisionModal() {
    this.showCloseDecisionModal = false;
    }

    handleChooseMerge() {
        this.handleCloseDecisionChoice('merge');
    }

    handleChooseDiscard() {
        this.handleCloseDecisionChoice('discard');
    }

    renderedCallback() {
        if (!this.showMergeFlow || !this.shouldStartMergeFlow) {
            return;
        }

        const mergeFlow = this.template.querySelector('lightning-flow[data-id="mergeFlow"]');
        if (mergeFlow) {
            mergeFlow.startFlow(this.mergeFlowApiName, this.mergeFlowInputVariables);
            this.shouldStartMergeFlow = false;
        }
    }

    handleMergeFlowStatusChange(event) {
        const status = event.detail.status;

        if (status === 'FINISHED' || status === 'FINISHED_SCREEN') {
            this.shouldStartMergeFlow = false;
            this.showMergeFlow = false;
            this.mergeCompleted = true;
            this.navigateToAccountListView();
        }
    }

    navigateToAccountListView() {
        this[NavigationMixin.Navigate](
            {
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'Account',
                    actionName: 'list'
                },
                state: {
                    filterName: 'Recent'
                }
            },
            true
        );
    }

    async handleMarkComplete() {
        // For Merged, Mark button now launches the merge flow.
        if (this.selectedStep === 'Merged' && this.selectedStep !== this._currentStep) {
            this.showMergeFlow = true;
            this.shouldStartMergeFlow = true;
            return;
        }else if(this.selectedStep === 'Closed' && this.selectedStep !== this._currentStep){
                // For Closed, Mark button now launches the close decision modal.
                this.showCloseDecisionModal = true;
                return;  // stop further execution until user makes a decision in the modal
        }

        

        let targetStatus = this.selectedStep;

        // If clicking "Mark Status as Complete" on current step, find the next step to advance to
        if (this.selectedStep === this._currentStep) {
            const options = this.prospectStatusOptions;
            const currentIdx = options.findIndex(opt => opt.value === this._currentStep);
            if (currentIdx !== -1 && currentIdx < options.length - 1) {
                targetStatus = options[currentIdx + 1].value;
            } else {
                return; // Nothing to advance to
            }
        }

        // If next automatic step is Closed, route through decision modal instead of direct update.
        if (targetStatus === 'Closed') {
            this.showCloseDecisionModal = true;
            return;
        }

        let dependantFields = await this.validateMandatoryFields(targetStatus);

        if (!dependantFields || !dependantFields.save) {
            return; // User cancelled out of modal or validation failed, do not proceed with update
        }

        const fields = {};
        fields['Id'] = this.recordId;
        fields[PROSPECT_STATUS_FIELD.fieldApiName] = targetStatus;

        if (dependantFields.fieldsToUpdate) {
            Object.assign(fields, dependantFields.fieldsToUpdate);
        }

        const recordInput = { fields };

        this.showSpinner = true;
        updateRecord(recordInput)
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Prospect status updated successfully.',
                    variant: 'success'
                })
            );
        })
        .catch(error => {
            logError({ componentName: 'des_prospect_path', methodName: 'handleMarkComplete', error, projectCode: 'HVSC', objectName: 'Account', recordId: this.recordId });
            const errorMessage = normalizeError(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error updating prospect status',
                    message: errorMessage,
                    variant: 'error'
                })
            );
        })
        .finally(() => {
            this.showSpinner = false;
        });
    }

    async handleCloseDecisionChoice(option) {
      this.closeDecisionOption = option;
      this.showCloseDecisionModal = false;

      if (option === "merge") {
                this.showMergeFlow = true;
                this.shouldStartMergeFlow = true;
      } else if (option === "discard") {
        const dependantFields = await this.validateMandatoryFields('Discarded');

        if (!dependantFields || !dependantFields.save) {
            return;
        }

        const fields = {};
        fields.Id = this.recordId;
        fields[PROSPECT_STATUS_FIELD.fieldApiName] = 'Discarded';

        if (dependantFields.fieldsToUpdate) {
            Object.assign(fields, dependantFields.fieldsToUpdate);
        }

        const recordInput = { fields };

        this.showSpinner = true;
        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Prospect status updated successfully.',
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                logError({ componentName: 'des_prospect_path', methodName: 'handleCloseDecisionChoice', error, projectCode: 'HVSC', objectName: 'Account', recordId: this.recordId });
                const errorMessage = normalizeError(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating prospect status',
                        message: errorMessage,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.showSpinner = false;
            });
      }
    }
    
    selectedDormancyReason;
    handleDormancyReasonChange(event) {
        this.selectedDormancyReason = event.detail.value;
        if (this.isCurrentDiscarded) {
            this.saveDiscardedField(PROSPECT_DOMANCYREASON_FIELD.fieldApiName, this.selectedDormancyReason);
        }
    }

    selectedPossibilityReengage;
    handlePossibilityReengageChange(event) {
        this.selectedPossibilityReengage = event.detail.value;
        if (this.isCurrentDiscarded) {
            this.saveDiscardedField(PROSPECT_REENGAGE_FIELD.fieldApiName, this.selectedPossibilityReengage);
        }
    }

    saveDiscardedField(fieldApiName, value) {
        const fields = {};
        fields.Id = this.recordId;
        fields[fieldApiName] = value;

        this.showSpinner = true;
        updateRecord({ fields })
            .catch(error => {
                logError({ componentName: 'des_prospect_path', methodName: 'saveDiscardedField', error, projectCode: 'HVSC', objectName: 'Account', recordId: this.recordId });
                const errorMessage = normalizeError(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating prospect information',
                        message: errorMessage,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    async validateMandatoryFields(targetStatus) {
        // Discarded mandatory fields validation
        if (targetStatus === 'Discarded') {
            if (!this.selectedDormancyReason || !this.selectedPossibilityReengage || this.selectedStep === this._currentStep) {
                // Open modal to request mandatory fields
                let fieldsUpdates = await DesFunnelModal.open({
                    flowName: 'ProspectPathFlow',
                    statusTarget: targetStatus,
                    fieldsConfig: this.getFieldsConfig(),
                    size: 'small'
                });
                if (!fieldsUpdates) {
                    // User cancelled out of the modal, do not proceed with status update
                    return {
                        save: false
                    };
                }
                return {
                    save: fieldsUpdates.save,
                    fieldsToUpdate: fieldsUpdates.fieldsToUpdate
                }
            }else {
                return {
                    save: true,
                    fieldsToUpdate: {
                        DES_Dormancy_Reason__c: this.selectedDormancyReason,
                        DES_possibility_to_reengage_in_the_futur__c: this.selectedPossibilityReengage
                    }
                }
            }
        }
        return {
            save: true
        };
    }

    getFieldsConfig() {
        return {
            picklistOptions: {
                DES_Dormancy_Reason__c: this.prospectDormancyReasonOptions,
                DES_possibility_to_reengage_in_the_futur__c: this.prospectPossibilityReengageOptions
            },
            currentValues: {
                DES_Dormancy_Reason__c: this.selectedDormancyReason,
                DES_possibility_to_reengage_in_the_futur__c: this.selectedPossibilityReengage
            }
        }
    }

}