import { LightningElement, api, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import ID_FIELD from '@salesforce/schema/Opportunity.Id';
import OPPORTUNITY_RECORDTYPEID from '@salesforce/schema/Opportunity.RecordTypeId';
import OPPORTUNITY_CLOSELOSTREASON from '@salesforce/schema/Opportunity.DES_Reasons_Lost__c';
import OPPORTUNITY_CREDENTIALEXCLUSIONREASON from '@salesforce/schema/Opportunity.DES_CredentialExclusionReason__c';
import OPPORTUNITY_FINALBBVATAKE from '@salesforce/schema/Opportunity.syndicated_loan_drawn_amount__c';
import OPPORTUNITY_RELEASEDATE from '@salesforce/schema/Opportunity.DES_ReleaseDate__c';
import OPPORTUNITY_CURRENCYCODE from '@salesforce/schema/Opportunity.CurrencyIsoCode';
import OPPORTUNITY_DESCRIPTION from '@salesforce/schema/Opportunity.Description';
import validateSemaphoreRulesForStageChange from '@salesforce/apex/DMT_FeaturesController.validateSemaphoreRulesForStageChange';

const CLOSING_CREDENTIALS_FLOW = 'Closing Credentials Flow';
const CLOSING_HEADER_DEFAULT = 'Closure Status';
const CLOSING_HEADER_CREDENTIALS = 'Credential Settings';
const CLOSING_HEADER_FINAL_REVIEW = 'Review and confirm';

// Record types that must pass the semaphore (Capability + Workflow) validation before the Opportunity can close
const SEMAPHORE_VALIDATED_RECORD_TYPES = ['DMT_Opportunity'];

// LDS wraps validation rule/trigger messages under body.output.errors/fieldErrors; body.message is just a generic fallback
function getErrorMessage(error) {
    const pageErrors = error?.body?.output?.errors?.map(e => e.message) || [];
    const fieldErrors = Object.values(error?.body?.output?.fieldErrors || {}).flat().map(e => e.message);
    const messages = [...pageErrors, ...fieldErrors];
    return messages.length > 0 ? messages.join(' ') : (error?.body?.message || 'Unknown error');
}

const CLOSING_STEPS = {
    "Closure_Status": {
        header: CLOSING_HEADER_DEFAULT,
        order: 1
    },
    "Credential_Settings": {
        header: CLOSING_HEADER_CREDENTIALS,
        order: 2
    },
    "Final_Review": {
        header: CLOSING_HEADER_FINAL_REVIEW,
        order: 3,
        isFinal: true
    }
}

// Single source of truth for every field touched by the flow, keyed by apiName.
// showWhen lets a descriptor be swapped out for another based on the current form state (e.g. credential vs. its exclusion reason).
const FINAL_REVIEW_FIELD_DEFS = [
    { apiName: 'StageName', label: 'Status', type: 'text', isEditable: false },
    { apiName: 'DMT_Credentials__c', label: 'Elegible As Credential', type: 'checkbox', extraLabel: 'Credential', isEditable: false },
    { apiName: 'DES_ReleaseDate__c', label: 'Release Date', type: 'date', isEditable: true, showWhen: (data) => data.DMT_Credentials__c === true },
    { apiName: 'DES_CredentialExclusionReason__c', label: 'Reason For Exclusion', type: 'text', isEditable: false, showWhen: (data) => data.DMT_Credentials__c === false },
    { apiName: 'syndicated_loan_drawn_amount__c', label: 'Final BBVA Take', type: 'currency', max: 99999999999999.99, isEditable: true },
    { apiName: 'Description', label: 'Description', type: 'textarea', maxLength: 32000, isEditable: true, fullWidth: true }
];

export default class Hvsc_oppClosingFlow extends LightningModal {
    @api recordId;
    @api saveOnWrapper = false;
    actualStep = 'Closure_Status';
    wiredRecord;
    isSaving = false;

    // All input state lives here, keyed by apiName, so the same values feed the wizard steps and the final review summary
    formData = {
        StageName: undefined,
        DES_Reasons_Lost__c: null,
        Description: undefined,
        DMT_Credentials__c: true,
        DES_ReleaseDate__c: undefined,
        DES_CredentialExclusionReason__c: null,
        syndicated_loan_drawn_amount__c: undefined,
        CurrencyIsoCode: undefined
    };

    setFormValue(apiName, value) {
        this.formData = { ...this.formData, [apiName]: value };
    }

    @wire(getRecord, { recordId: '$recordId', fields: [OPPORTUNITY_RECORDTYPEID, OPPORTUNITY_FINALBBVATAKE, OPPORTUNITY_RELEASEDATE, OPPORTUNITY_CURRENCYCODE, 'Opportunity.RecordType.DeveloperName', OPPORTUNITY_DESCRIPTION] })
    wiredRecordFunction({ data, error }) {
        this.wiredRecord = { data, error };
        if (data) {
            this.setFormValue('syndicated_loan_drawn_amount__c', data.fields.syndicated_loan_drawn_amount__c.value);
            this.setFormValue('DES_ReleaseDate__c', data.fields.DES_ReleaseDate__c.value);
            this.setFormValue('CurrencyIsoCode', data.fields.CurrencyIsoCode.value);
            this.setFormValue('Description', data.fields.Description?.value);
        }
    }
    get oppRecordTypeId() {
        return this.wiredRecord?.data?.fields?.RecordTypeId?.value;
    }

    get recordTypeDeveloperName() {
        return this.wiredRecord?.data?.fields?.RecordType?.value?.fields?.DeveloperName?.value;
    }
    

    @wire(getPicklistValues, { recordTypeId: '$oppRecordTypeId', fieldApiName: OPPORTUNITY_CLOSELOSTREASON })
    reasonForClosureOptionsPicklist;

    @wire(getPicklistValues, { recordTypeId: '$oppRecordTypeId', fieldApiName: OPPORTUNITY_CREDENTIALEXCLUSIONREASON })
    wiredFunction({ data, error }) {
        if (data) {
            this.reasonForExclusionOptionsPicklist = { data, error: undefined };
        } else if (error) {
            this.reasonForExclusionOptionsPicklist = { data: undefined, error };
        }
    }

    get hasNextStep() {
        if(this.actualStep == 'Closure_Status') {
            if(this.formData.StageName === 'Closed Won' || !this.formData.StageName) {
                return true;
            }
        }
        if(this.actualStep == 'Credential_Settings') {
            return true;
        }
        return false;
    }

    get hasPreviousStep() {
        const currentOrder = CLOSING_STEPS[this.actualStep]?.order || 0;
        return currentOrder > 1;
    }

    get isFinalStep() {
        return !this.hasNextStep;
    }

    get header() {
        return CLOSING_STEPS[this.actualStep]?.header || CLOSING_HEADER_DEFAULT;
    }

    get isClosingStatus() {
        return this.actualStep === 'Closure_Status';
    }

    get isCredentialSettings() {
        return this.actualStep === 'Credential_Settings';
    }

    get isFinalReview() {
        return this.actualStep === 'Final_Review';
    }

    get closingStatusOptions() {
        return [
            { label: 'Closed Won', value: 'Closed Won' },
            { label: 'Closed Lost', value: 'Closed Lost' }
        ];
    }

    get reasonForClosureOptions() {
        return this.reasonForClosureOptionsPicklist?.data?.values || [];
    }

    get closeStatusSelected() {
        return this.formData.StageName !== undefined && this.formData.StageName !== null && this.formData.StageName !== '';
    }

    get isCloseLost() {
        return this.formData.StageName === 'Closed Lost';
    }

    get nextStepIsDisabled() {
        if (this.isSaving) {
            return true;
        }
        if(this.actualStep == 'Closure_Status') {
            if(!this.closeStatusSelected) {
                return true;
            }
            if(this.isCloseLost && !this.formData.DES_Reasons_Lost__c) {
                return true;
            }
        }
        if(this.actualStep == 'Credential_Settings') {
            if(this.isCredentialNotSelected && !this.formData.DES_CredentialExclusionReason__c) {
                return true;
            }
        }
        return false;
    }

    get isCredentialNotSelected() {
        return this.formData.DMT_Credentials__c === false;
    }

    get reasonForExclusionOptions() {
        return this.reasonForExclusionOptionsPicklist?.data?.values || [];
    }

    get finalReviewComments() {
        return 'test'
    }

    get finalReviewFields() {
        return FINAL_REVIEW_FIELD_DEFS
            .filter(def => !def.showWhen || def.showWhen(this.formData))
            .map(def => ({
                ...def,
                value: this.formData[def.apiName],
                ...(def.type === 'currency' && { currencyCode: this.formData.CurrencyIsoCode })
            }));
    }

    handleClosingStatusChange(event) {
        const stageName = event.detail.value;
        this.setFormValue('StageName', stageName);
        this.setFormValue('DES_Reasons_Lost__c', null);
        // Closed Lost skips the Credential Settings step, so drop any stale exclusion reason from a previous Closed Won pass
        if (stageName === 'Closed Lost') {
            this.setFormValue('DES_CredentialExclusionReason__c', null);
        }
    }

    handleReasonForClosureChange(event) {
        this.setFormValue('DES_Reasons_Lost__c', event.detail.value);
    }

    handleDescriptionChange(event) {
        this.setFormValue('Description', event.detail.value);
    }

    handleCredentialChange(event) {
        this.setFormValue('DMT_Credentials__c', event.detail.checked);
        this.setFormValue('DES_CredentialExclusionReason__c', null);
    }

    handleReasonForExclusionChange(event) {
        this.setFormValue('DES_CredentialExclusionReason__c', event.detail.value);
    }

    async handleNextStep() {
        if (this.actualStep === 'Closure_Status') {
            const isValid = await this.validateSemaphoreForRecordType();
            if (!isValid) {
                return;
            }
        }
        const currentOrder = CLOSING_STEPS[this.actualStep]?.order || 1;
        const nextStep = Object.entries(CLOSING_STEPS).find(([key, value]) => value.order === currentOrder + 1)?.[0];
        if (nextStep) {
            this.actualStep = nextStep;
        }
    }

    handlePreviousStep() {
        this.cleanFieldsStep(this.actualStep);
        const currentOrder = CLOSING_STEPS[this.actualStep]?.order || 1;
        const previousStep = Object.entries(CLOSING_STEPS).find(([key, value]) => value.order === currentOrder - 1)?.[0];
        if (previousStep) {
            this.actualStep = previousStep;
        }
    }

    handleFinish() {
        if (this.isSaving) {
            return;
        }
        this.isSaving = true;

        // CurrencyIsoCode is only used to format the BBVA Take field, not part of the record save
        const { CurrencyIsoCode, ...fieldsToSave } = this.formData;
        const fields = { [ID_FIELD.fieldApiName]: this.recordId, ...fieldsToSave };

        if(this.saveOnWrapper) {
            this.close({
                status: 'success',
                record: fields
            });
            return;
        }
        updateRecord({ fields })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: '',
                    message: 'Opportunity closed successfully.',
                    variant: 'success'
                }));
                this.close({
                    status: 'success',
                    record: fields
                });
            })
            .catch(error => {
                console.error('Error updating record:', error);
                this.isSaving = false;
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error saving Opportunity',
                    message: getErrorMessage(error),
                    variant: 'error',
                    mode: 'dismissable'
                }));
            });
    }

    handleCancel() {
        this.close();
    }

    handleFinalReviewFieldChange(event) {
        const { apiName, value } = event.detail;
        this.setFormValue(apiName, value);
    }

    // Only DMT_Opportunity record types must pass the Capability/Workflow semaphore rules before closing
    async validateSemaphoreForRecordType() {
        if (!SEMAPHORE_VALIDATED_RECORD_TYPES.includes(this.recordTypeDeveloperName)) {
            return true;
        }
        return await this.validateSemaphoreForStage(this.formData.StageName);
    }

    async validateSemaphoreForStage(targetStage) {
        try {
            const result = await validateSemaphoreRulesForStageChange({
                opportunityId: this.recordId,
                targetStatus: targetStage
            });

            if (!result.isValid && result.incompleteFeatures?.length > 0) {
                const featureNames = result.incompleteFeatures.join(', ');
                const featureCount = result.incompleteFeatures.length;
                const messageText = featureCount === 1
                    ? `Opportunity cannot advance to ${targetStage} because the feature ${featureNames} has been rejected.`
                    : `Opportunity cannot advance to ${targetStage} because the features ${featureNames} have been rejected.`;
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: messageText,
                    variant: 'error',
                    mode: 'dismissable'
                }));
                return false;
            }

            return true;
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Validation Error',
                message: error?.body?.message || 'Error validating semaphore rules.',
                variant: 'error',
                mode: 'dismissable'
            }));
            return false;
        }
    }

    cleanFieldsStep(step){
        if(step == 'Closure_Status') {
            this.formData = { ...this.formData, StageName: null, DES_Reasons_Lost__c: null, Description: null };
        } else if(step == 'Credential_Settings') {
            this.formData = { ...this.formData, DMT_Credentials__c: true, DES_CredentialExclusionReason__c: null };
        }
    }
}