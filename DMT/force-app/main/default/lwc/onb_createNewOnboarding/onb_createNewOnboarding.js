import { api, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import createAccountAndOnboarding from '@salesforce/apex/ONB_createOnboardingController.createAccountAndOnboarding';
import getClientInfo from '@salesforce/apex/ONB_createOnboardingController.getClientInfo';

import ONB_OBJECT from '@salesforce/schema/ONB_Onboarding__c';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';

// Labels
import BACK from '@salesforce/label/c.ONB_BACK';
import RETURN from '@salesforce/label/c.ONB_RETURN';
import CLIENT_INFO from '@salesforce/label/c.ONB_CLIENT_INFO';
import CLIENT_NAME from '@salesforce/label/c.ONB_CLIENT_NAME';
import LEI from '@salesforce/label/c.ONB_LEI';
import ONB_LEI_PENDING_CREATE from '@salesforce/label/c.ONB_LEI_PENDING_CREATE';
import CLIENT_TYPE from '@salesforce/label/c.ONB_CLIENT_TYPE';
import GENERAL_INFORMATION from '@salesforce/label/c.ONB_GENERAL_INFORMATION';
import REQUEST_DETAILS from '@salesforce/label/c.ONB_REQUEST_DETAILS';
import CANCEL from '@salesforce/label/c.ONB_CANCEL';
import CREATE from '@salesforce/label/c.ONB_CREATE';
import ERROR_GENERIC from '@salesforce/label/c.ONB_ERROR_GENERIC';
import ERROR_REQUIRED from '@salesforce/label/c.ONB_ERROR_REQUIRED';
import SUCCESS_TITLE from '@salesforce/label/c.ONB_SUCCESS_TITLE';
import SUCCESS_MESSAGE from '@salesforce/label/c.ONB_SUCCESS_MESSAGE';
import CONTRACT from '@salesforce/label/c.ONB_CONTRACT';

// ----------------------
// Field labels (custom labels)
// ----------------------
// General information
import ONB_PRIORITIZATION from '@salesforce/label/c.ONB_PRIORITIZATION';
import ONB_BRANCH from '@salesforce/label/c.ONB_BRANCH';
import ONB_SEGMENT from '@salesforce/label/c.ONB_SEGMENT';
import ONB_LEGAL_ENTITY_TYPE from '@salesforce/label/c.ONB_LEGAL_ENTITY_TYPE';

// Request details
import ONB_PARENT_ASSET_MANAGER from '@salesforce/label/c.ONB_PARENT_ASSET_MANAGER';
import ONB_IS_SALESPERSON from '@salesforce/label/c.ONB_IS_SALESPERSON';
import ONB_SALESPERSON_TITLE from '@salesforce/label/c.ONB_SALESPERSON_TITLE';
import ONB_OPERATION_IN_PLATFORM from '@salesforce/label/c.ONB_OPERATION_IN_PLATFORM';
import ONB_MASTER_AGREEMENT from '@salesforce/label/c.ONB_MASTER_AGREEMENT';

const ONBOARDING_OBJECT_API_NAME = 'ONB_Onboarding__c';
const ONBOARDING_CONTRACT_FIELD_API_NAME = 'ONB_Contrato__c';
const MASTER_AGREEMENTS_OBJECT_API_NAME = 'ONB_Master_Agreement__c';

const mapFromPairs = (pairs) => Object.freeze(Object.fromEntries(pairs));
const freezeList = (list) => Object.freeze([...list]);

// ----------------------
// Sections (fields + labels)
// ----------------------
const SECTIONS = Object.freeze({
    generalInformation: {
        fields: freezeList(['Prioritization__c', 'Branch__c', 'Segment__c']),
        labels: mapFromPairs([
            ['Prioritization__c', ONB_PRIORITIZATION],
            ['Branch__c', ONB_BRANCH],
            ['Segment__c', ONB_SEGMENT]
        ])
    },

    requestDetails: {
        fields: freezeList(['Legal_Entity_Type__c', 'ONB_Parent_Asset_Manager__c', 'Is_Sales_Person__c', 'Client_Sales_Person__c', 'Operation_in_Platform__c', 'Any_Master_Agreement__c']),
        labels: mapFromPairs([
            ['Legal_Entity_Type__c', ONB_LEGAL_ENTITY_TYPE],
            ['ONB_Parent_Asset_Manager__c', ONB_PARENT_ASSET_MANAGER],
            ['Is_Sales_Person__c', ONB_IS_SALESPERSON],
            ['Client_Sales_Person__c', ONB_SALESPERSON_TITLE],
            ['Operation_in_Platform__c', ONB_OPERATION_IN_PLATFORM],
            ['Any_Master_Agreement__c', ONB_MASTER_AGREEMENT]
        ])
    }
});

// Rule constants
const YES = 'Yes';
const NO = 'No';
const FUND = 'Hedge Fund';

export default class Onb_createNewOnboarding extends NavigationMixin(LightningModal) {
    @api clientName;
    @api clientLei;
    @api clientCif;
    @api existingClientType;
    @api existingClient = false;
    @api header;
    @api showFooter;
    @api accRecordTypeId;

    clientNameAux;
    clientLeiAux;
    clientCifAux;
    leiCheckbox = false;

    onboardingObjApiName = ONBOARDING_OBJECT_API_NAME;
    onboardingContractFldApiName = ONBOARDING_CONTRACT_FIELD_API_NAME;
    masterAgreementsObjApiName = MASTER_AGREEMENTS_OBJECT_API_NAME;
    sections = SECTIONS;

    @api recordId;

    recordTypeId;

    // Draft map
    onboardingDraft = {};

    isSaving = false;

    leiAuxInitialized = false;

    renderedCallback() {
        if (this.leiAuxInitialized) return;

        if (this.clientLei) {
            this.clientLeiAux = this.clientLei.trim();
        }

        this.leiAuxInitialized = true;
    }


    labels = {
        BACK,
        RETURN,
        CLIENT_INFO,
        CLIENT_NAME,
        LEI,
        ONB_LEI_PENDING_CREATE,
        CLIENT_TYPE,
        GENERAL_INFORMATION,
        REQUEST_DETAILS,
        CANCEL,
        CREATE,
        ERROR_GENERIC,
        ERROR_REQUIRED,
        SUCCESS_TITLE,
        SUCCESS_MESSAGE,
        CONTRACT
    };

    get hasClientName() {
        return this.clientName && this.clientName.trim() !== '';
    }

    get leiRequiredLength() {
        return this.leiMaxLength || 20;
    }

    get clientLeiTrimmed() {
        return (this.clientLei || '').trim();
    }

    get hasValidClientLei() {
        return this.clientLei && this.clientLei.trim().length === this.leiMaxLength;
    }

    get showLeiInput() {
        return !this.hasValidClientLei;
    }

    get hasLeiPending() {
        return this.showLeiInput && !this.existingClient;
    }

    get isNewClient() {
        return !this.existingClient;
    }

    get generalFieldRules() {
        // all-required is passed in HTML
        return {};
    }

    get requestFieldRules() {
        return {
            ONB_Parent_Asset_Manager__c: {
                visibleWhen: { field: 'Legal_Entity_Type__c', op: 'eq', value: FUND },
                requiredWhen: { field: 'Legal_Entity_Type__c', op: 'eq', value: FUND }
            },

            Client_Sales_Person__c: {
                visibleWhen: { field: 'Is_Sales_Person__c', op: 'eq', value: NO },
                requiredWhen: { field: 'Is_Sales_Person__c', op: 'eq', value: NO }
            }
        };
    }
    
    get isCreateButtonDisabled() {
        // rely on validate() + contract requirement
        return this.isSaving;
    }

    get leiMaxLength() {
        const field =
            this.objectInfo?.data?.fields?.lei_id__c;

        return field ? field.length : null;
    }

    get cifMaxLength() {
        const field = this.objectInfo?.data?.fields?.CIF_local__c;
        return field ? field.length : null;
    }

    get effectiveLei() {
        return (this.clientLeiAux || this.clientLei || '').trim();
    }

    get effectiveCif() {
        return (this.clientCifAux || this.clientCif || '').trim();
    }

    get hasLeiValue() {
        return this.effectiveLei !== '';
    }

    get hasCifValue() {
        return this.effectiveCif !== '';
    }

    get isLeiRequired() {
        return !this.leiCheckbox && !this.hasCifValue;
    }

    get isCifRequired() {
        return !this.leiCheckbox && !this.hasLeiValue;
    }

    // ------------------------
    // Wire
    // ------------------------

    @wire(getClientInfo, { recordId: '$recordId' })
    wiredClient({ data, error }) {
        if (data) {
            this.clientName = data.clientName;
            this.clientLei = data.clientLei;
        } else if (error) {
            this.showError('Error loading object metadata');
        }
    }

    @wire(getObjectInfo, { objectApiName: ONB_OBJECT })
    objectInfoHandler({ data, error }) {
        if (data) {
            this.recordTypeId = data.defaultRecordTypeId;
        } else if (error) {
            this.showError(this.labels.ERROR_GENERIC);
        }
    }

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    objectInfo;

    // ------------------------
    // Event handlers (capture changes)
    // ------------------------
    handleDynamicChange(event) {
        console.log('onboarding modal record id: ' + this.recordId);
        const { fieldApiName, value } = event.detail;
        this.onboardingDraft = { ...this.onboardingDraft, [fieldApiName]: value };
    }

    handleClientNameChange(event) {
        this.clientNameAux = event.target.value;
    }

    handleClientLeiChange(event) {
        this.clientLeiAux = event.target.value;
    }

    handleClientCifChange(event) {
        this.clientCifAux = event.target.value;
    }

    handleLeiCheckboxChange(event) {
        this.leiCheckbox = event.target.checked;

        if(this.leiCheckbox){
            this.clientLeiAux = '';
        }
    }

    // ------------------------
    // Buttons / close
    // ------------------------
    handleBack() {
        this.close({ action: 'back', payload: { clientName: '', clientLei: '', clientCif: '' } });
    }

    handleCancel() {
        this.close({ action: 'cancel' });
    }

    async handleCreate() {
        const forms = this.template.querySelectorAll('c-onb_onboarding-form');
        for (const f of forms) {
            if (f && !f.validate()) {
                this.showError(this.labels.ERROR_REQUIRED);
                return;
            }
        }

        if (!this.validateLeiOnCreate()) {
            this.showError('The LEI must be exactly 20 characters long.');
            return;
        }

        if (!this.validateLeiOrCifRequired()) {
            this.showError('You must inform either LEI or CIF, or mark LEI Pending Create.');
            return;
        }

        this.isSaving = true;

        console.log(this.accRecordTypeId);

        try {
            const params = {
                clientName: this.clientName || this.clientNameAux,
                clientLei: this.clientLeiAux || this.clientLei,
                clientCif: this.clientCifAux || this.clientCif,
                pendingLei: this.leiCheckbox,

                accRecordTypeId: this.accRecordTypeId,

                prioritization: this.onboardingDraft?.Prioritization__c,
                branch: this.onboardingDraft?.Branch__c,
                segment: this.onboardingDraft?.Segment__c,
                legalEntityType: this.onboardingDraft?.Legal_Entity_Type__c,

                requestType: this.existingClient
                    ? this.onboardingDraft?.Request_Type__c
                    : 'New client onboarding',

                parentAccountId: Array.isArray(this.onboardingDraft?.ONB_Parent_Asset_Manager__c)
                    ? this.onboardingDraft.ONB_Parent_Asset_Manager__c[0]
                    : this.onboardingDraft?.ONB_Parent_Asset_Manager__c,

                isSalesPerson: this.onboardingDraft?.Is_Sales_Person__c,

                clientSalesId: Array.isArray(this.onboardingDraft?.Client_Sales_Person__c)
                    ? this.onboardingDraft.Client_Sales_Person__c[0]
                    : this.onboardingDraft?.Client_Sales_Person__c,

                operationInPlatform: this.onboardingDraft?.Operation_in_Platform__c,
                anyMasterAgreement: this.onboardingDraft?.Any_Master_Agreement__c,

                existingClient: this.existingClient,
                clientId: this.recordId
                };

            const result = await createAccountAndOnboarding(params);

            this.showToast(this.labels.SUCCESS_TITLE, this.labels.SUCCESS_MESSAGE, 'success');

            this.close({
                action: 'create',
                payload: { onboardingId: result.onboardingId }
            });
        } catch (e) {
            const msg = e?.body?.message || this.labels.ERROR_GENERIC;
            this.showError(msg);
        } finally {
            this.isSaving = false;
        }
    }

    validateLeiOnCreate() {
        if (this.leiCheckbox) return true;

        const lei = this.effectiveLei;

        if (!lei) return true;

        const requiredLen = this.leiMaxLength || 20;
        return lei.length === requiredLen;
    }

    validateLeiOrCifRequired() {
        if (this.leiCheckbox) {
            return true;
        }

        return this.hasLeiValue || this.hasCifValue;
    }


    // ------------------------
    // Toast helpers
    // ------------------------
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    showError(message) {
        this.showToast('Error', message, 'error');
    }
}