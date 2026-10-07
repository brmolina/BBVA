import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import pubsub from 'omnistudio/pubsub';
import loadData from '@salesforce/apex/DMT_ApprovalTemplate_Controller.loadData';
import saveStep from '@salesforce/apex/DMT_ApprovalTemplate_Controller.saveStep';
import saveAndCloseStep from '@salesforce/apex/DMT_ApprovalTemplate_Controller.saveAndCloseStep';
import finishCaseCondition from '@salesforce/apex/DMT_ApprovalTemplate_Controller.finishCaseCondition';
import returnToProposal from '@salesforce/apex/DMT_ApprovalTemplate_Controller.returnToProposal';
import extractValidationMessage from '@salesforce/apex/DMT_ApprovalTemplate_Controller.extractValidationMessage';

import LABEL_RESULT from '@salesforce/label/c.dmt_cl_Result';
import LABEL_COMMENTS from '@salesforce/label/c.dmt_cl_Comments';
import LABEL_NO_PENDING_TASK from '@salesforce/label/c.dmt_cl_NoPendingTask_Text';
import LABEL_NOT_ASK from '@salesforce/label/c.dmt_cl_NotAsk_Text';
import LABEL_SEND_NEXT_APPROVER from '@salesforce/label/c.dmt_cl_SendNextApprover_Text';
import LABEL_RETURN_REQUESTER from '@salesforce/label/c.dmt_cl_returnRequester_Text';
import LABEL_CLOSE_TASK from '@salesforce/label/c.dmt_cl_CloseTaskButton_Text';

export default class DmtApprovalTemplate extends NavigationMixin(LightningElement) {

    _recordId;
    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        if (this._connected && value) {
            this.fetchData();
        }
    }

    @track data = {};
    @track dataLoaded = false;
    @track editState = false;
    @track stepResult = '';
    @track comments = '';
    @track committeeLabel = '';
    @track doNotAskCheck = false;
    @track buttonDisabled = true;
    @track showPopover = false;
    @track errorMessage = '';
    @track showSpinner = true;
    @track showModal = false;
    @track taskResult = {};
    @track showApprovalValidation = false;
    @track showCloseTaskChild = false;
    _connected = false;

    labels = {
        result: LABEL_RESULT,
        comments: LABEL_COMMENTS,
        noPendingTask: LABEL_NO_PENDING_TASK,
        notAsk: LABEL_NOT_ASK,
        sendNextApprover: LABEL_SEND_NEXT_APPROVER,
        returnRequester: LABEL_RETURN_REQUESTER,
        closeTask: LABEL_CLOSE_TASK
    };

    get isViewState() {
        return !this.showSpinner && this.dataLoaded && !this.editState && this.data.taskId && this.data.taskId !== 'norecord';
    }

    get isNoPendingTask() {
        return !this.showSpinner && this.dataLoaded && (!this.data.taskId || this.data.taskId === 'norecord');
    }

    get isEditState() {
        return !this.showSpinner && this.dataLoaded && this.editState && this.data.taskId && this.data.taskId !== 'norecord';
    }

    get canEdit() {
        const hasEditRole = this.data.hasEditCaseRole === true || this.data.hasEditCaseRole === 'true';
        const hasGodAccess = this.data.hasLineGodAccess === true || this.data.hasLineGodAccess === 'true';
        return (hasEditRole && this.data.accessLevel === 'Edit') || hasGodAccess;
    }

    get isFinishStepDisabled() {
        return this.data.finishStep === true || this.data.finishStep === 'true';
    }

    get isButtonDisabled() {
        return this.buttonDisabled;
    }

    get isReturnToProposalDisabled() {
        return this.data.returnToProposalDisabled === true || this.data.returnToProposalDisabled === 'true';
    }

    get taskName() {
        return this.currentTaskType.Name || '';
    }

    get yesFlag() {
        return this.currentTaskType.DMT_Yes_Flag__c || 'Yes';
    }

    get noFlag() {
        return this.currentTaskType.DMT_No_Flag__c || 'No';
    }

    get naFlag() {
        return this.currentTaskType.DMT_NA_Flag__c || 'NA';
    }

    get currentTaskType() {
        return this.data.currentTaskType || {};
    }

    get finishCaseConfig() {
        return this.currentTaskType.DMT_Finish_Case__c || '';
    }

    get normalizedFinishCaseConfig() {
        return this.normalizeCloseTaskConfig(this.finishCaseConfig);
    }

    get reviewOperationConfig() {
        return this.currentTaskType.DMT_Review_Operation__c || '';
    }

    get normalizedReviewOperationConfig() {
        return this.normalizeCloseTaskConfig(this.reviewOperationConfig);
    }

    get sendToApproverConfig() {
        return this.currentTaskType.DMT_Send_To_Approver__c || '';
    }

    get normalizedSendToApproverConfig() {
        return this.normalizeCloseTaskConfig(this.sendToApproverConfig);
    }

    normalizeCloseTaskConfig(configValue) {
        if (!configValue || typeof configValue !== 'string') {
            return configValue;
        }

        const parts = configValue.split(';');
        if (parts.length !== 3) {
            return configValue;
        }

        return [parts[0], parts[2], parts[1]].join(';');
    }

    get showResultEmpty() {
        return !this.stepResult || this.stepResult === '';
    }

    get showResultYes() {
        return this.stepResult === 'Yes';
    }

    get showResultNo() {
        return this.stepResult === 'No';
    }

    get showResultNA() {
        return this.stepResult === 'NA';
    }

    get yesBtnWrapperClass() {
        return 'slds-size_4-of-12 slds-text-align_center ' + (this.stepResult === 'Yes' ? 'buttonYES' : 'buttonYEShover');
    }

    get noBtnWrapperClass() {
        return 'slds-size_4-of-12 slds-text-align_center ' + (this.stepResult === 'No' ? 'buttonNO' : 'buttonRound');
    }

    get naBtnWrapperClass() {
        return 'slds-size_4-of-12 slds-text-align_center ' + (this.stepResult === 'NA' ? 'buttonNA' : 'buttonRound');
    }

    get records() {
        return {
            taskId: this.data.taskId,
            caseId: this.data.caseId || this.recordId,
            stepResult: this.stepResult,
            comments: this.comments,
            Committee_Label: this.committeeLabel,
            doNotAskCheck: this.doNotAskCheck,
            caseStatus: 'In Progress'
        };
    }

    get contextData() {
        return {
            relatedTasks: this.data.relatedTasks,
            'line.endDate': this.data['line.endDate'],
            'line.plazoMaximoLine': this.data['line.plazoMaximoLine'],
            EndTermMax: this.data.EndTermMax,
            setProduct: this.data.setProduct,
            setClient: this.data.setClient,
            client: this.data.client,
            lineProductInfo: this.data.lineProductInfo,
            'line.dvpAmount': this.data['line.dvpAmount'],
            'line.fdAmount': this.data['line.fdAmount'],
            'line.derivativesAmount': this.data['line.derivativesAmount'],
            OpportunityId: this.data.OpportunityId,
            LineId: this.data.LineId,
            DMT_LineOpportunity__c: this.data.DMT_LineOpportunity__c
        };
    }

    get closeTaskModalParams() {
        return {
            finishStep: this.taskResult.finishStep ?? this.data.finishStep,
            buttonDisabled: this.taskResult.buttonDisabled ?? this.buttonDisabled,
            returnToProposalDisabled: this.taskResult.returnToProposalDisabled ?? this.data.returnToProposalDisabled,
            errorMessage: this.errorMessage
        };
    }

    get showSendNextApprover() {
        return false;
    }

    get showReturnToRequester() {
        return false;
    }

    connectedCallback() {
        this._connected = true;
        this._boundFinish = this.handleFinishCaseConditionCard.bind(this);
        this._boundReturn = this.handleReturnToProposalCard.bind(this);
        this._boundApproval = this.handleApprovalValidationCard.bind(this);
        this.addEventListener('finishCaseConditionCard', this._boundFinish);
        this.addEventListener('returnToProposalCard', this._boundReturn);
        this.addEventListener('approvalValidationCard', this._boundApproval);
        this.fetchData();
    }

    disconnectedCallback() {
        this._connected = false;
        this.removeEventListener('finishCaseConditionCard', this._boundFinish);
        this.removeEventListener('returnToProposalCard', this._boundReturn);
        this.removeEventListener('approvalValidationCard', this._boundApproval);
    }

    async fetchData() {
        this.showSpinner = true;
        console.log('Fetching data for recordId:', this.recordId);
        try {
            const result = await loadData({ recordId: this.recordId });
            console.log('Fetched data:', JSON.stringify(result));
            if (Array.isArray(result)) {
                this.data = result[0] || {};
            } else {
                this.data = result || {};
            }
            this.stepResult = this.data.stepResult || '';
            this.comments = this.data.comments || '';
            this.committeeLabel = this.data.Committee_Label || '';
            this.doNotAskCheck = this.data.doNotAskCheck === true || this.data.doNotAskCheck === 'true';
            this.buttonDisabled = this.data.buttonDisabled === true || this.data.buttonDisabled === 'true';
            this.editState = false;
            this.showPopover = false;
        } catch (error) {
            this.data = {};
            this.errorMessage = error.body ? error.body.message : error.message;
            this.showPopover = true;
        } finally {
            this.dataLoaded = true;
            this.showSpinner = false;
        }
    }

    handleEdit() {
        this.editState = true;
    }

    handleCancel() {
        this.fetchData();
    }

    handleYes() {
        this.stepResult = 'Yes';
        this.buttonDisabled = false;
    }

    handleNo() {
        this.stepResult = 'No';
        this.buttonDisabled = false;
    }

    handleNA() {
        this.stepResult = 'NA';
        this.buttonDisabled = false;
    }

    handleTextfieldChange(event) {
        this.comments = event.detail.value;
    }

    handleCommitteeLabelChange(event) {
        this.committeeLabel = event.target.value;
    }

    handleDoNotAskChange(event) {
        this.doNotAskCheck = event.target.checked;
    }

    focusChildModal() {
        setTimeout(() => {
            const childModal = this.template.querySelector('c-dmt_modal_close_task');
            if (childModal && typeof childModal.focusModal === 'function') {
                childModal.focusModal();
            }
        }, 100);
    }

    async handleSave() {
        this.showSpinner = true;
        this.showPopover = false;
        try {
            const result = await saveStep({ recordsJson: JSON.stringify(this.records) });
            if (result && result.error === 'true') {
                this.errorMessage = result.IPResult ? result.IPResult.message : 'Error saving';
                this.showPopover = true;
            } else {
                this.editState = false;
                this.fetchData();
            }
        } catch (error) {
            this.errorMessage = error.body ? error.body.message : error.message;
            this.showPopover = true;
        } finally {
            this.showSpinner = false;
        }
    }

    async handleSaveAndClose() {
        this.showSpinner = true;
        this.showPopover = false;
        try {
            const result = await saveAndCloseStep({ recordsJson: JSON.stringify(this.records) });
            if (result && result.error === 'true') {
                this.errorMessage = result.IPResult ? result.IPResult.message : 'Error saving';
                this.showPopover = true;
            } else {
                this.editState = false;
                this.buttonDisabled = result.buttonDisabled === true || result.buttonDisabled === 'true';
                this.data = {
                    ...this.data,
                    finishStep: result.finishStep,
                    returnToProposalDisabled: result.returnToProposalDisabled
                };
                this.taskResult = {
                    finishStep: result.finishStep,
                    buttonDisabled: result.buttonDisabled,
                    returnToProposalDisabled: result.returnToProposalDisabled
                };
                this.showModal = true;
                this.focusChildModal();
            }
        } catch (error) {
            this.errorMessage = error.body ? error.body.message : error.message;
            this.showPopover = true;
        } finally {
            this.showSpinner = false;
        }
    }

    handleCloseTask() {
        this.showModal = true;
        this.taskResult = {
            finishStep: this.data.finishStep,
            buttonDisabled: this.buttonDisabled,
            returnToProposalDisabled: this.data.returnToProposalDisabled
        };
        this.focusChildModal(); 
    }

    handleSendNextApprover() {
        this.showModal = true;
        this.focusChildModal(); 
    }

    async handleFinishCaseConditionCard() {
        this.showModal = false;
        this.showSpinner = true;
        try {
            const result = await finishCaseCondition({
                recordId: this.recordId,
                taskId: this.data.taskId,
                recordsJson: JSON.stringify(this.records),
                contextJson: JSON.stringify(this.contextData)
            });
            if (result && result.error && result.error !== 'OK') {
                this.errorMessage = result.IPResult ? result.IPResult.message : 'Error';
                this.showPopover = true;
            } else {
                pubsub.fire('DmtTaskChannel', 'taskClosed', {
                    taskId: this.data.taskId,
                    caseId: this.recordId
                });
                this.navigateToCaseTasks();
            }
        } catch (error) {
            this.errorMessage = error.body ? error.body.message : error.message;
            this.showPopover = true;
        } finally {
            this.showSpinner = false;
        }
    }

    async handleReturnToProposalCard(event) {
        this.showModal = false;
        this.showSpinner = true;
        const statusValue = event && event.detail ? event.detail.status : '';
        try {
            const result = await returnToProposal({
                recordId: this.recordId,
                taskId: this.data.taskId,
                recordsJson: JSON.stringify(this.records),
                contextJson: JSON.stringify(this.contextData),
                statusValue: statusValue
            });
            if (result && result.error === 'true') {
                this.showPopover = true;
            } else {
                this.fetchData();
                this.navigateToCaseTasks();
            }
        } catch (error) {
            this.errorMessage = error.body ? error.body.message : error.message;
            this.showPopover = true;
        } finally {
            this.showSpinner = false;
        }
    }

    handleApprovalValidationCard() {
        this.showModal = false;
        this.showCloseTaskChild = true;
    }

    // NOTE: stepOptions and showApproverCombobox getters removed.
    // Toggle 3 (approval validation) now delegated to child dmt_close_task component.

    // NOTE: Approval validation handlers removed.
    // Toggle 3 (close task + send to approver) now completely delegated to child dmt_close_task component.
    // Related methods eliminated:
    // - handleApprovalStepChange()
    // - handleApprovalApproverChange()
    // - handleCloseTaskApproval()
    // - handleCancelApprovalValidation()
    //
    // New handlers for child component:

    handleCloseTaskSuccess(event) {
        this.showCloseTaskChild = false;
        this.fetchData();
        // Optionally navigate to case tasks if needed
        // this.navigateToCaseTasks();
    }

    handleCloseTaskCancel(event) {
        this.showCloseTaskChild = false;
    }

    handleCloseModal() {
        this.showModal = false;
    }

    navigateToCaseTasks() {
        if (this.data.Case_Tasks) {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: { url: this.data.Case_Tasks }
            });
        }
    }

    handleReloadCard() {
        this.navigateToCaseTasks();
        this.fetchData();
    }
}