import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';

/**
 * @component   des_funnel_modal
 * @description A highly reusable and generic Lightning Modal to request state/stage-specific
 *              mandatory fields before updating a record. Leverages Salesforce's core
 *              `lightning/modal` and `lightning-record-edit-form` for dynamic standard validation.
 * @author      Borja Lorenzo Adajas
 * @date        2026-06-02
 */
export default class Des_funnel_modal extends LightningModal {
    _flowName;
    _statusTarget;
    _recordId;
    _pendingMergeFlowStart = false;
    _mergeFlowStarted = false;

    @api 
    get flowName() {
        return this._flowName;
    }
    set flowName(value) {
        this._flowName = value;
        if (value === 'MergeFlow') {
            this._pendingMergeFlowStart = true;
        }
    }

    renderedCallback() {
        if (this._pendingMergeFlowStart) {
            this._pendingMergeFlowStart = false;
            const mergeFlow = this.refs.mergeFlow;
            if (mergeFlow) {
                mergeFlow.startFlow('Merge_Prospect_Flow', this.mergeFlowInputVariables);
            }
        }
    }

    @api
    get statusTarget() {
        return this._statusTarget;
    }
    set statusTarget(value) {
        this._statusTarget = value;
    }

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
    }

    _fieldsConfig = {};
    @api 
    get fieldsConfig() {
        return this._fieldsConfig;
    }
    set fieldsConfig(value) {
        // Create a shallow copy of the object and any internal arrays/objects to prevent mutations 
        // that break Locker Service / LWC unidirectional data bindings with parents
        if (value) {
            this._fieldsConfig = {
                ...value,
                currentValues: value.currentValues ? { ...value.currentValues } : {},
                picklistOptions: value.picklistOptions ? { ...value.picklistOptions } : {}
            };
        } else {
            this._fieldsConfig = {};
        }
    }

    get isProspectPath() {
        return this.flowName === 'ProspectPathFlow';
    }

    get showMergeFlow() {
        return this.flowName === 'MergeFlow';
    }

    get mergeFlowLoading() {
        return this.showMergeFlow && !this._mergeFlowStarted;
    }

    get mergeFlowContainerClass() {
        return this._mergeFlowStarted ? '' : 'slds-hide';
    }

    get mergeFlowLoading() {
        return this.showMergeFlow && !this._mergeFlowStarted;
    }

    get mergeFlowContainerClass() {
        return this._mergeFlowStarted ? '' : 'slds-hide';
    }

    get showFooter() {
        // Only show footer for ProspectPathFlow when target status is Discarded, as we need to capture additional info before allowing the save
        return !this.showMergeFlow;
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

    get headerLabel() {
        return 'Discard Prospect';
    }

    get bodyMessage() {
        if (this.isProspectPath) {
            return `Please provide the following information to move the prospect to "${this.statusTarget}" status.`;
        }
        return '';
    }

    get prospectDormancyReasonOptions() {
        return this._fieldsConfig?.picklistOptions?.DES_Dormancy_Reason__c || [];
    }

    get prospectPossibilityReengageOptions() {
        return this._fieldsConfig?.picklistOptions?.DES_possibility_to_reengage_in_the_futur__c || [];
    }

    get selectedDormancyReason() {
        return this._fieldsConfig?.currentValues?.DES_Dormancy_Reason__c || '';
    }

    get selectedPossibilityReengage() {
        return this._fieldsConfig?.currentValues?.DES_possibility_to_reengage_in_the_futur__c || '';
    }

    get disableSave() {
        if (this.isProspectPath && this.statusTarget === 'Discarded') {
            return !this.selectedDormancyReason || !this.selectedPossibilityReengage;
        }
        return false;
    }

    handleDormancyReasonChange(event) {
        // Assign using spread to trigger LWC properties reactivity
        this._fieldsConfig = {
            ...this._fieldsConfig,
            currentValues: {
                ...this._fieldsConfig.currentValues,
                DES_Dormancy_Reason__c: event.detail.value
            }
        };
    }

    handlePossibilityReengageChange(event) {
        // Assign using spread to trigger LWC properties reactivity
        this._fieldsConfig = {
            ...this._fieldsConfig,
            currentValues: {
                ...this._fieldsConfig.currentValues,
                DES_possibility_to_reengage_in_the_futur__c: event.detail.value
            }
        };
    }

    handleCancel() {
        this.close({
            save: false
        });
    }

    handleSave() {
        this.showSpinner = true;
        
        this.close({
            save: true,
            fieldsToUpdate: this.getFieldsToUpdate()
        });
    }

    getFieldsToUpdate() {
        if (this.isProspectPath && this.statusTarget === 'Discarded') {
            return {
                DES_Dormancy_Reason__c: this.selectedDormancyReason,
                DES_possibility_to_reengage_in_the_futur__c: this.selectedPossibilityReengage
            }
        }
        return {};
    }

    handleMergeFlowStatusChange(event) {
        const status = event.detail.status;
        if (status === 'STARTED' || status === 'IN_PROGRESS') {
            this._mergeFlowStarted = true;
        }
        if (status === 'FINISHED') {
           this.close({
                save: false,
                fieldsToUpdate: {} // No additional fields to update, the flow handles everything
            });
        }
    }
}