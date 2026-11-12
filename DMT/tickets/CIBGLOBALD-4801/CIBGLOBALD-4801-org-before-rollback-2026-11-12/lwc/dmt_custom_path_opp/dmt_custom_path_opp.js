import { LightningElement, wire, api } from 'lwc'
import { CurrentPageReference } from 'lightning/navigation'
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { getPicklistValues } from 'lightning/uiObjectInfoApi'
import { getRecord, updateRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi'
import validateSemaphoreRulesForStageChange from '@salesforce/apex/DMT_FeaturesController.validateSemaphoreRulesForStageChange';
import STAGENAME_FIELD from '@salesforce/schema/Opportunity.StageName'
import ID_FIELD from '@salesforce/schema/Opportunity.Id'
import RECORDTYPEID_FIELD from '@salesforce/schema/Opportunity.RecordTypeId'
import REASONLOST_FIELD from '@salesforce/schema/Opportunity.DES_Reasons_Lost__c'
import DATETOPROPOSAL_FIELD from '@salesforce/schema/Opportunity.DMT_DateToProposal__c' // CIBGLOBALD-4811
import RECORD_TYPE_DEVELOPER_NAME_FIELD from '@salesforce/schema/Opportunity.RecordType.DeveloperName' // CIBGLOBALD-4811
const ERROR_TITLE = 'You encountered some errors when trying to save this record'
const ERROR_PERMISSION =
    'Unable to create/update fields: StageName. Please check the security settings of this field and verify that it is read/write for your profile or permission set.'
const SUCCESS_UPDATING = 'Status changed successfully.'
import getOppLockUser from '@salesforce/apex/DMT_Opportunity_Utils.getOppLockUser';
import previewCompareTasksFromCase from '@salesforce/apex/DMT_ApprovalChangeStep_Handler.previewCompareTasksFromCase'; // CIBGLOBALD-4811
import USER_ID from '@salesforce/user/Id';
import ClosingFlowModal from 'c/hvsc_oppClosingFlow';

import DMT_LABEL_MODAL_UNSAVED_CHANGES_TITLE from '@salesforce/label/c.DMT_Label_Modal_Unsaved_Changes_Title';
import DMT_LABEL_MODAL_UNSAVED_CHANGES_BODY  from '@salesforce/label/c.DMT_Label_Modal_Unsaved_Changes_Body';
import DMT_LABEL_BTN_EXIT_WITHOUT_SAVING     from '@salesforce/label/c.DMT_Label_Btn_Exit_Without_Saving';
import DMT_LABEL_BTN_KEEP_EDITING            from '@salesforce/label/c.DMT_Label_Btn_Keep_Editing';



/** Normalizes any Closed Won/Lost stage to "Closed" */
const normalize = (stage) => stage?.includes('Closed') ? 'Closed' : stage

export default class Dmt_custom_path_opp extends LightningElement {

    @api recordId

    labels = {
    modalUnsavedChangesTitle : DMT_LABEL_MODAL_UNSAVED_CHANGES_TITLE,
    modalUnsavedChangesBody  : DMT_LABEL_MODAL_UNSAVED_CHANGES_BODY,
    btnExitWithoutSaving     : DMT_LABEL_BTN_EXIT_WITHOUT_SAVING,
    btnKeepEditing           : DMT_LABEL_BTN_KEEP_EDITING
};

    /* ── Internal state ─────────────────────────────────────────────────────── */ 

    _currentStage       // Real stage saved in Salesforce (e.g. "Closed Won") 
    _selectedStage      // Visually selected stage (can be "Closed") 
    _recordTypeId       // RecordTypeId to load the picklists 
    _dateToProposal     // CIBGLOBALD-4811
    _recordTypeDeveloperName // CIBGLOBALD-4811
    _rawStages = []     // Original picklist values [{value, label}] 
    reasonsLostOptions = []    // Lost reasons picklist values [{value, label}] 
    _isEditing = false; // Tracks the current editing state of the Opportunity record
    _showPendingChangesModal = false; // Controls visibility of the pending changes modal
    closedStageSelected = '' // Value chosen in the modal select 
    reasonsLostSelected = '' // Value chosen in the lost reasons select (if any) 
    isLoading = false   // Spinner during the update 
    isClosedLost = false // True for Closed Lost, to show the reasons 
   
    @api
    set isEditing(value) {
        this._isEditing = value;
    }

    get isEditing() {
        return this._isEditing;
    }

    get showPendingChangesModal() {
        return this._showPendingChangesModal;
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference && !this.recordId) {
            this.recordId =
                currentPageReference.state?.recordId ||
                currentPageReference.state?.c__recordId ||
                currentPageReference.attributes?.recordId
        }
    }

    /* ── Wire: record data ───────────────────────────────────────────────────── */

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [STAGENAME_FIELD, RECORDTYPEID_FIELD, DATETOPROPOSAL_FIELD, RECORD_TYPE_DEVELOPER_NAME_FIELD] // CIBGLOBALD-4811
    })
    record({ data }) {
        if (data) {
            this._currentStage = data.fields.StageName.value
            this._selectedStage = normalize(this._currentStage)
            this._recordTypeId = data.fields.RecordTypeId.value
            this._dateToProposal = data.fields.DMT_DateToProposal__c.value // CIBGLOBALD-4811
            this._recordTypeDeveloperName = data.fields.RecordType?.value?.fields?.DeveloperName?.value // CIBGLOBALD-4811
        }
    }

    /* ── Wire: picklist values by RecordType ─────────────────────────────────── */ 

    @wire(getPicklistValues, {
        recordTypeId: '$_recordTypeId',
        fieldApiName: STAGENAME_FIELD
    })
    picklistValues({ data }) {
        if (data) {
            this._rawStages = data.values.map(o => ({ value: o.value, label: o.label }))
        }
    }

    /* ── Wire: picklist values by RecordType ─────────────────────────────────── */ 

    @wire(getPicklistValues, {
        recordTypeId: '$_recordTypeId',
        fieldApiName: REASONLOST_FIELD
    })
    picklistValuesReasonLost({ data }) {
        if (data) {
            this.reasonsLostOptions = data.values.map(o => o.value);
            console.log('Reasons Lost Options: ', JSON.stringify(this.reasonsLostOptions));
        }
    }


    /* ── Visible stages: Closed Won/Lost become one "Closed" ───────────────── */ 

    get _displayStages() {
        if (!this._rawStages.length) return []
        const seen = new Set()
        return this._rawStages.reduce((acc, s) => {
            const key = normalize(s.value)
            if (!seen.has(key)) {
                seen.add(key)
                acc.push({ value: key, label: key })
            }
            return acc
        }, [])
    }

    /* ── Items for the template (SLDS classes by state) ──────────────────── */ 

    get stageItems() {
        const stages = this._displayStages
        if (!stages.length || !this._currentStage) return []

        const current = normalize(this._currentStage)
        const selected = this._selectedStage
        const isWon = this._currentStage === 'Closed Won'
        const isLost = this._currentStage === 'Closed Lost'
        const isClosed = isWon || isLost
        const currentIdx = stages.findIndex(s => s.value === current)

        return stages.map((stage, idx) => {
            let cssClass = 'slds-path__item'

            // Base state per SLDS
            if (stage.value === 'Closed' && isClosed) {
                cssClass += isWon ? ' slds-is-won slds-is-current' : ' slds-is-lost slds-is-current'
            } else if (stage.value === 'Closed') {
                cssClass += ' slds-is-incomplete'
            } else if (isClosed) {
                cssClass += isWon ? ' slds-is-complete' : ' slds-is-incomplete'
            } else if (stage.value === current) {
                cssClass += ' slds-is-current'
            } else if (currentIdx !== -1 && idx < currentIdx) {
                cssClass += ' slds-is-complete'
            } else {
                cssClass += ' slds-is-incomplete'
            }

            // Visually selected stage
            if (stage.value === selected) {
                cssClass += ' slds-is-active'
            }

            return {
                ...stage,
                cssClass,
                isSelected: stage.value === selected ? 'true' : 'false',
                tabindex: stage.value === selected ? '0' : '-1',
            }
        })
    }

    /* ── Template getters ─────────────────────────────────────────────────── */ 

    get isCurrentSelected() {
        return this._selectedStage === normalize(this._currentStage)
    }

    get isClosed() {
        return this._currentStage?.includes('Closed') ?? false
    }

    /** Button text per SLDS */ 
    get actionButtonLabel() {
        if (this.isLoading) return 'Saving...'
        if (this._selectedStage === 'Closed') return 'Change Closed State'
        if (this.isClosed && this._selectedStage !== 'Closed') return 'Mark as Current Stage'
        if (this.isCurrentSelected) return 'Mark Status as Complete'
        return 'Mark as Current Stage'
    }

    /** Options of the modal select (real values: Closed Won, Closed Lost) */ 
    get closedStageOptions() {
        return this._rawStages.filter(s => s.value.includes('Closed')).map(s => s.value)
    }

    
    get isSaveDisabled() {
        return !this.closedStageSelected
    }

    /** Next linear stage (excluding Closed) */ 
    get nextStage() {
        const linear = this._displayStages.filter(s => s.value !== 'Closed')
        const idx = linear.findIndex(s => s.value === this._currentStage)
        return (idx !== -1 && idx < linear.length - 1) ? linear[idx + 1].value : null
    }

    /* ── Handlers ─────────────────────────────────────────────────────────── */

    handleStageClick(event) {
        event.preventDefault()
        this._selectedStage = event.currentTarget.dataset.value
    }

async handleMarkAsCurrent() {
    // Unsaved changes: show the modal and stop 
    if (this._isEditing) {
        this._showPendingChangesModal = true;
        return;
    }
    // Checks the lock before going on 
    const isBlocked = await this.isEditingRecord();
    if (isBlocked) {
        // The toast is shown inside 
        return;
    }
    await this.executeMarkAsCurrent();
}

async isEditingRecord() {
    try {
        const opp = await getOppLockUser({ oppId: this.recordId });
        const lockedById = opp?.DMT_Opp_User_Lock__c;
        const lockedBy   = opp?.DMT_Opp_User_Lock__r?.Name;

        if (lockedById && lockedById !== USER_ID) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Record Locked',
                message: `This record is currently being edited by ${lockedBy}. You cannot make any changes at this time.`,
                variant: 'warning',
                mode: 'dismissable'
            }));
            return true; // Locked by someone else 
        }
        return false; // Not locked, or locked by the current user 
    } catch (error) {
        // Apex error 
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: error?.body?.message || 'Error checking the record lock.', 
            variant: 'error',
            mode: 'dismissable'
        }));
        return true; // Assumes locked on error, for safety 
    }
}


    async executeMarkAsCurrent() {
       // "Closed" selected: always the modal 
        if (this._selectedStage === 'Closed') {
            this.closedStageSelected = ''
            ClosingFlowModal.open({
                size: 'small',
                recordId: this.recordId
            });
            return
        }

        // Closed Opportunity with a non-closed stage selected: back to that stage 
        if (this.isClosed) {
            const isValid = await this.validateTrafficLightForStage(this._selectedStage) // CIBGLOBALD-4811
            if (!isValid) return
            this.updateStatus(this._selectedStage)
            return
        }

        // Current selected: move to the next // CIBGLOBALD-4811
        if (this.isCurrentSelected) {
            const next = this.nextStage
            if (!next) {
                // Last linear stage: open the Closed modal // CIBGLOBALD-4811
                this.closedStageSelected = ''
                ClosingFlowModal.open({
                    size: 'small',
                    recordId: this.recordId
                });
                return
            }
            const isValid = await this.validateTrafficLightForStage(next) // CIBGLOBALD-4811
            if (!isValid) return
            this.updateStatus(next)
            return
        }

        const isValid = await this.validateTrafficLightForStage(this._selectedStage) // CIBGLOBALD-4811
        if (!isValid) return
        this.updateStatus(this._selectedStage)
    }

    handleClosedStageChange(event) {
        this.closedStageSelected = event.target.value
        this.isClosedLost = this.closedStageSelected === 'Closed Lost'
    }
     handleReasonsLostChange(event) {
        this.reasonsLostSelected = event.target.value
    }

    /**
     * Validates the traffic light rules (Capability + Workflow, AND/OR) for the target stage. 
     */
    async validateTrafficLightForStage(targetStage) { // CIBGLOBALD-4811
        try {
            const result = await validateSemaphoreRulesForStageChange({
                opportunityId: this.recordId,
                targetStatus: targetStage
            })

            if (!result.isValid && result.incompleteFeatures?.length > 0) {
                const featureNames = result.incompleteFeatures.join(', ')
                const featureCount = result.incompleteFeatures.length
                const messageText = featureCount === 1 
                    ? `Opportunity cannot advance to ${targetStage} because the required feature ${featureNames} does not meet its traffic light rule.` // CIBGLOBALD-4801
                    : `Opportunity cannot advance to ${targetStage} because the required features ${featureNames} do not meet their traffic light rule.` // CIBGLOBALD-4801
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: messageText,
                    variant: 'error',
                    mode: 'dismissable'
                }))
                return false
            }

            const stageRequirements = await validateStageAdvanceRequirements({
                opportunityId: this.recordId,
                currentStatus: this._currentStage,
                targetStatus: targetStage
            })

            if (!stageRequirements.isValid) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: stageRequirements.errorMessage || `Opportunity cannot advance to ${targetStage}.`,
                    variant: 'error',
                    mode: 'dismissable'
                }))
                return false
            }

            return true
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Validation Error',
                message: error?.body?.message || 'Error validating traffic light rules.', 
                variant: 'error',
                mode: 'dismissable'
            }))
            return false
        }
    }
     /*async validateClosedWonRequirements() {
        try {
            const result = await validateFeaturesForClosedWon({ opportunityId: this.recordId })

            if (!result.isValid && result.incompleteFeatures && result.incompleteFeatures.length > 0) {
                const featureNames = result.incompleteFeatures.map(feature => feature.name).join(', ')
                const featureCount = result.incompleteFeatures.length
                const messageText = featureCount === 1 
                    ? `Opportunity cannot be closed because feature ${featureNames} has been rejected.`
                    : `Opportunity cannot be closed because features ${featureNames} have been rejected.`
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: messageText,
                    variant: 'error',
                    mode: 'dismissable'
                }))
                return { isValid: false }
            }

            return { isValid: true }
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Validation Error',
                message: error?.body?.message || 'Error validating features.',
                variant: 'error',
                mode: 'dismissable'
            }))
            return { isValid: false }
        }
    }*/

        /* ── "Pending Changes" modal handlers ───────────────────────────────── */ // CIBGLOBALD-4811


    handleCloseModal() {
        this._showPendingChangesModal = false
    }

    async handleExitWithoutSaving() {
        // Tells the parent that the user accepted leaving without saving 
        await this.dispatchEvent(new CustomEvent('reloadeditmode', {
            bubbles: true,
            composed: true
        }))
        this._showPendingChangesModal = false
        await this.executeMarkAsCurrent();

    }

    /* ── Salesforce update ───────────────────────────────────────────────── */ 

    // CIBGLOBALD-4811 - the Case type the Opportunity trigger checks at this stage change
    // (DMT_OpportunityTriggerHandler.restartApprovalTasksOnOpportunityResubmission), or null when
    // nothing can reopen.
    caseTypeToCheck(newStatus) {
        if (this._recordTypeDeveloperName !== 'DMT_Opportunity') {
            return null
        }
        if (this._currentStage === 'Draft' && newStatus === 'Proposal' && this._dateToProposal) {
            return 'passport'
        }
        if (this._currentStage === 'Proposal' && newStatus === 'Approval') {
            return 'approval'
        }
        return null
    }

    // CIBGLOBALD-4811 - runs before the stage update, while the snapshot comparison still finds the
    // stale tasks. A failing check never stops the stage change.
    async showReopenWarning(newStatus) {
        const caseTypeToCheck = this.caseTypeToCheck(newStatus)
        if (!caseTypeToCheck) {
            return
        }
        try {
            const features = await previewCompareTasksFromCase({ recordId: this.recordId, caseTypeToCheck })
            if (features && features.length > 0) {
                // CIBGLOBALD-4811 - Cases with the same feature, owner and fields give the same line: shown once.
                const message = [...new Set(features
                    .map(feature => 'The feature  ' + feature.featureName + ' should be reopened with Owner: <b>' + (feature.taskToRecreate?.Owner?.Name || 'N/A') +
                        '</b> due to changes in the following fields: <ul class="slds-list_dotted">' +
                        Object.keys(feature.changedFields || {}).sort().map(field => '<li>' + field + '</li>').join('') + '</ul><br/>'))]
                    .join('')
                this.template.querySelector('c-dmt_customtoast')?.showToast('Features to Be Reopened', message, 'info', false)
            }
        } catch (error) {
            console.error('Error previewing the features to reopen', error)
        }
    }

    async updateStatus(newStatus) { // CIBGLOBALD-4811
        this.isLoading = true
        await this.showReopenWarning(newStatus) // CIBGLOBALD-4811
        const fields = {
            [ID_FIELD.fieldApiName]: this.recordId,
            [STAGENAME_FIELD.fieldApiName]: newStatus,
            [REASONLOST_FIELD.fieldApiName]: this.reasonsLostSelected,
        }

        updateRecord({ fields })
            .then(() => {
                this._currentStage = newStatus
                this._selectedStage = normalize(newStatus)
                notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
                this.isLoading = false
                this.dispatchEvent(new ShowToastEvent({
                    title: '', message: SUCCESS_UPDATING, variant: 'success'
                }))
            })
            .catch(error => {
                this.isLoading = false
                let msg
                if (error.status === 403) {
                    msg = ERROR_PERMISSION
                } else {
                    // Validation Rules → body.output.errors[0].message
                    const outputError = error?.body?.output?.errors?.[0]?.message
                    // Field-level errors (e.g. StageName) → body.output.fieldErrors.*[0].message
                    const fieldErrors = error?.body?.output?.fieldErrors
                    const fieldError = fieldErrors
                        ? Object.values(fieldErrors).flat()?.[0]?.message
                        : undefined
                    // Generic body message
                    const bodyMessage = error?.body?.message
                    msg = outputError || fieldError || bodyMessage || JSON.stringify(error?.body) || 'Unknown error'
                }
                console.error('updateRecord error', JSON.stringify(error))
                this.dispatchEvent(new ShowToastEvent({
                    title: ERROR_TITLE, message: msg, variant: 'error'
                }))
            })
    }
}