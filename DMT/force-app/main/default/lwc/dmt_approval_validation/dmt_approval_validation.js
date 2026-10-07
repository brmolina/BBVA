import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getApproversForStep from '@salesforce/apex/DMT_ApprovalValidation_Service.getApproversForStep';
import updateApprovalStep from '@salesforce/apex/DMT_ApprovalValidation_Service.updateApprovalStep';
import getTaskContext from '@salesforce/apex/DMT_ApprovalValidation_Service.getTaskContext';

const DEFAULT_ERROR_MESSAGE = 'An unexpected error occurred. Please contact an administrator.';
const APPROVAL_STEP_OPTIONS = ['Yes', 'No', 'NA'];

export default class DmtApprovalValidation extends LightningElement {
    // ─── Public API ───────────────────────────────────────────────────────────
    _recordId;
    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        if (value) {
            this._loadTaskContext();
        }
    }

    _caseId;
    @api
    get caseId() {
        return this._caseId;
    }
    set caseId(value) {
        this._caseId = value;
    }

    @api statusLine;         // 'Proposal' or other (determines which validations to show)

    // ─── State ────────────────────────────────────────────────────────────────
    @track stepSelected = '';
    @track nextApprover = '';
    @track showApproverSelect = true;
    @track isLoading = false;
    @track hasError = false;
    @track errorMessage = '';
    @track isButtonDisabled = false;

    @track validations = [];           // Steps for non-Proposal status
    @track proposalValidations = [];   // Steps for Proposal status
    @track nextApprovers = [];         // Approver options (depends on step)

    @track taskContext = {};           // Task + Case context data

    // ─── Load context ─────────────────────────────────────────────────────────
    async _loadTaskContext() {
        if (!this._recordId) {
            return;
        }

        this.isLoading = true;
        try {
            this.taskContext = await getTaskContext({ recordId: this._recordId });
            this.statusLine = this.taskContext.statusLine || this.statusLine || '';

            // Load appropriate validations
            if (this.statusLine === 'Proposal') {
                this.proposalValidations = this.taskContext.proposalValidations || [];
            } else {
                this.validations = this.taskContext.validations || [];
            }
        } catch (error) {
            this._handleError('load', error);
        } finally {
            this.isLoading = false;
        }
    }

    // ─── Step selection handler ───────────────────────────────────────────────
    async handleStepChange(event) {
        this.stepSelected = event.detail.value;
        this.nextApprover = ''; // Reset approver when step changes
        await this._loadApprovers();
    }

    // ─── Load approvers for selected step ──────────────────────────────────────
    async _loadApprovers() {
        try {
            this.nextApprovers = await getApproversForStep({ 
                stepSelected: this.stepSelected,
                recordId: this._recordId
            });
        } catch (error) {
            this._handleError('load', error);
        }
    }

    // ─── Approver selection handler ────────────────────────────────────────────
    handleApproverChange(event) {
        this.nextApprover = event.detail.value;
    }

    // ─── Save handler ──────────────────────────────────────────────────────────
    async handleSave() {
        this.isLoading = true;
        this.hasError = false;
        this.errorMessage = '';
        this.isButtonDisabled = true;

        try {
            // Validate required fields
            if (!this.stepSelected) {
                throw new Error('Please select a valid step.');
            }
            if (this.showApproverSelect && !this.nextApprover) {
                throw new Error('Please select an approver.');
            }

            // Call backend to update approval step
            const result = await updateApprovalStep({
                taskId: this._recordId,
                caseId: this._caseId || this.taskContext.caseId,
                recordId: this.taskContext.caseId || this._caseId || this._recordId,
                stepSelected: this.stepSelected,
                nextApprover: this.nextApprover
            });

            if (result.error) {
                this.hasError = true;
                this.errorMessage = result.message || 'An error occurred during approval.';
                this.isButtonDisabled = false;
            } else {
                // Success: close modal and notify parent
                this.dispatchEvent(new CustomEvent('close', { 
                    detail: { success: true, message: 'Approval updated successfully.' },
                    bubbles: true,
                    composed: true
                }));
                this._showToast('Success', 'Approval step updated successfully.', 'success');
            }
        } catch (error) {
            this._handleError('save', error);
            this.isButtonDisabled = false;
        } finally {
            this.isLoading = false;
        }
    }

    // ─── Cancel handler ───────────────────────────────────────────────────────
    handleCancel() {
        this.dispatchEvent(new CustomEvent('close', { 
            detail: { success: false },
            bubbles: true,
            composed: true
        }));
    }

    // ─── Getters ──────────────────────────────────────────────────────────────
    get getValidations() {
        return this.statusLine === 'Proposal' ? this.proposalValidations : this.validations;
    }

    get isSaveDisabled() {
        return this.isLoading || this.isButtonDisabled || 
               !this.stepSelected || 
               (this.showApproverSelect && !this.nextApprover);
    }

    get showError() {
        return this.hasError && !!this.errorMessage;
    }

    // ─── Error handling ───────────────────────────────────────────────────────
    _requiresApprover(stepValue) {
        return !!stepValue && APPROVAL_STEP_OPTIONS.includes(stepValue) && stepValue !== 'No';
    }

    _handleError(context, error) {
        const message = error?.body?.message || error?.message || DEFAULT_ERROR_MESSAGE;
        console.error(`[dmt_approval_validation][${context}]`, message, error);
        this.hasError = true;
        this.errorMessage = message;
        this._showToast('Error', message, 'error');
    }

    _showToast(title, message, variant = 'info') {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
                mode: 'dismissable'
            })
        );
    }
}