import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import pubsub from 'omnistudio/pubsub';
import getInitialData from '@salesforce/apex/DMT_CloseTask_Controller.getInitialData';
import getTaskSelectionData from '@salesforce/apex/DMT_CloseTask_Controller.getTaskSelectionData';
import closeTask from '@salesforce/apex/DMT_CloseTask_Controller.closeTask';

const DEFAULT_ERROR_MESSAGE = 'An unexpected error occurred. Please contact an administrator.';

export default class DmtCloseTask extends LightningElement {
    _recordId;

    @api
    get caseId() {
        return this._recordId;
    }

    set caseId(value) {
        this._recordId = value;
        if (value) {
            this.loadInitialData();
        }
    }

    @track isLoading = false;
    @track hasError = false;
    @track errorMessage = '';
    @track stepSelected = '';
    @track approverSelected = '';
    @track taskOptions = [];
    @track approverOptions = [];
    @track showApprovers = true;

    taskId = '';
    taskName = '';
    currentTaskTypeId = '';
    currentTaskExternalId = '';
    defaultTaskTypeId = '';
    defaultRelationshipId = '';
    lineOpportunityType = '';
    username = '';
    buttonDisabled = false;
    hasRelatedApprovalTask = false;
    approverField = '';
    approvalEdit = false;
    defaultApproverCode = '';
    taskTypeName = '';

    async loadInitialData() {
        if (!this._recordId) {
            return;
        }

        this.isLoading = true;
        this.hasError = false;
        this.errorMessage = '';

        try {
            const result = await getInitialData({ recordId: this._recordId });

            this.taskId = result.taskId || '';
            this.taskName = result.taskName || '';
            this.currentTaskTypeId = result.currentTaskTypeId || '';
            this.currentTaskExternalId = result.currentTaskExternalId || '';
            this.defaultTaskTypeId = result.defaultTaskTypeId || '';
            this.defaultRelationshipId = result.defaultRelationshipId || '';
            this.lineOpportunityType = result.lineOpportunityType || '';
            this.username = result.username || '';
            this.buttonDisabled = !!result.buttonDisabled;
            this.hasRelatedApprovalTask = !!result.hasRelatedApprovalTask;

            this.taskOptions = (result.validations || []).map(item => ({
                label: item.label,
                value: String(item.value)
            }));

            this.stepSelected = result.defaultStepSelected != null
                ? String(result.defaultStepSelected)
                : '';

            if (this.stepSelected) {
                await this.loadTaskSelectionData(false);
            } else {
                this.showApprovers = false;
                this.approverOptions = [];
                this.approverSelected = '';
                this.defaultApproverCode = '';
            }
        } catch (error) {
            this._setError(this.getErrorMessage(error));
        } finally {
            this.isLoading = false;
        }
    }

    async loadTaskSelectionData(showSpinner = true) {
        if (!this._recordId || !this.stepSelected) {
            this.approverOptions = [];
            this.approverSelected = '';
            this.showApprovers = false;
            return;
        }

        if (showSpinner) {
            this.isLoading = true;
        }

        try {
            const result = await getTaskSelectionData({
                recordId: this._recordId,
                stepSelected: this.stepSelected
            });

            this.taskTypeName = result.taskTypeName || '';
            this.approverField = result.approverField || '';
            this.approvalEdit = !!result.approvalEdit;
            this.showApprovers = !!result.showApprovers;
            this.defaultApproverCode = result.defaultApproverCode != null
                ? String(result.defaultApproverCode)
                : '';

            this.approverOptions = (result.approvers || []).map(item => ({
                label: item.label,
                value: String(item.approverCode || item.value || item.id)
            }));

            this.approverSelected = this.defaultApproverCode;

            if (!this.showApprovers) {
                this.approverSelected = '';
            }
        } catch (error) {
            this._setError(this.getErrorMessage(error));
            this.showApprovers = false;
            this.approverOptions = [];
            this.approverSelected = '';
        } finally {
            if (showSpinner) {
                this.isLoading = false;
            }
        }
    }

    async handleTaskChange(event) {
        this.stepSelected = event.detail.value;
        this.approverSelected = '';
        this.approverOptions = [];
        this.showApprovers = true;
        this.hasError = false;
        this.errorMessage = '';

        await this.loadTaskSelectionData();
    }

    handleApproverChange(event) {
        this.approverSelected = event.detail.value;
    }

    handleCancel(event) {
       if (event) {
            event.preventDefault();
            event.stopPropagation();
        }
        // OmniStudio modals usually close through this custom event.
        this.dispatchEvent(new CustomEvent('closemodal', { bubbles: true, composed: true }));
        this.dispatchEvent(new CustomEvent('close', {detail: { success: false },bubbles: true,composed: true}));

    }

    async handleCloseTask() {
        this.hasError = false;
        this.errorMessage = '';

        if (!this.stepSelected) {
            this._setError('Please select a Task.');
            return;
        }

        if (this.showApprovers && !this.approverSelected) {
            this._setError('Please select an Approver.');
            return;
        }

        this.isLoading = true;

        try {
            const result = await closeTask({ caseId: this._recordId, currentTaskId: this.taskId, stepSelected: this.stepSelected, approverSelected: this.approverSelected});

            if (result?.success) {

                this._showToast( 'Success', result.message || 'Close Task ejecutado correctamente.', 'success');

                // (Event/PubSub -> DmtTaskChannel/taskClosed)so dmt_CreateHTMLAndJSONForTask keeps generating the HTML/JSON/PDF snapshot on task close.
                pubsub.fire('DmtTaskChannel', 'taskClosed', {taskId: this.taskId, caseId: this._recordId});
                this.dispatchEvent( new CustomEvent('closetasksuccess', { detail: { newTaskId: result.newTaskId }, bubbles: true, composed: true}));
            }

        } catch (error) {
            this._setError(this.getErrorMessage(error));
        } finally {
            this.isLoading = false;
        }
    }

    get showError() {
        return this.hasError && !!this.errorMessage;
    }

    get isCloseDisabled() {
        return this.isLoading || !this.stepSelected || (this.showApprovers && !this.approverSelected);
    }

    get approverSectionClass() {
        return this.showApprovers
            ? 'slds-col slds-size_1-of-1 slds-medium-size_1-of-2 slds-p-bottom_medium dmt-close-task-approver-wrapper'
            : 'slds-col slds-size_1-of-1 slds-medium-size_1-of-2 slds-p-bottom_medium slds-hide dmt-close-task-approver-wrapper';
    }

    getErrorMessage(error) {
        if (error?.body?.message) {
            return error.body.message;
        }

        if (error?.message) {
            return error.message;
        }

        return DEFAULT_ERROR_MESSAGE;
    }

    _setError(message) {
        this.hasError = true;
        this.errorMessage = message || DEFAULT_ERROR_MESSAGE;
        this._showToast('Error', this.errorMessage, 'error');
    }

    _showToast(title, message, variant = 'info') {
        
        this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode: 'dismissable'}));
    }
}