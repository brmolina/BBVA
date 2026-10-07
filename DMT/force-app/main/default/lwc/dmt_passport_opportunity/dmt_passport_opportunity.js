import { LightningElement, api, track, wire } from 'lwc';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { getRecord, getFieldValue, notifyRecordUpdateAvailable, updateRecord } from "lightning/uiRecordApi";
import { loadStyle } from 'lightning/platformResourceLoader';
import { RefreshEvent, registerRefreshContainer, unregisterRefreshContainer, REFRESH_COMPLETE } from "lightning/refresh";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from '@salesforce/apex';
import updateRiskLinesAndWarranties from '@salesforce/apex/DMT_OppToSanctionUtils.updateRiskLinesAndWarranties';

import overflowyscroll from '@salesforce/resourceUrl/DMT_overflowyscroll';
import pubsub from "omnistudio/pubsub";

import getLastDay from '@salesforce/apex/DMT_Passport_Handler.getLastDay';
import getFeatureRulesLwc from '@salesforce/apex/DMT_Passport_Handler.getFeatureRulesLWC';
import getInformationPassport from '@salesforce/apex/DMT_Passport_Handler.getInformationPassport';
import validateOppBeforePassport from '@salesforce/apex/DMT_Passport_Handler.validateOppBeforePassport';
import fetchData from  '@salesforce/apex/DMT_HPG_MainTableCustomController.fetchClientInitialData';
import buttonCallPassport from '@salesforce/apex/DMT_Passport_Handler.buttonCallPassport';
import getFeatureTypeByApproverType from '@salesforce/apex/DMT_Passport_Handler.getFeatureTypeByApproverType';
import getCurrentStepFromFeaturesOpp from '@salesforce/apex/DMT_Case_Steps_Controller.getCurrentStepFromFeaturesOpp';
import hasLineGodPermission from '@salesforce/customPermission/DMT_Line_God';
import getMainHolderAccountId from '@salesforce/apex/DMT_Passport_Handler.getMainHolderAccountId';

import PASSPORT_OPPORTUNITY_ID_FIELD from "@salesforce/schema/Passport__c.Opportunity__c";
import PASSPORT_OBSOLETED_FIELD from "@salesforce/schema/Passport__c.DMT_Is_Obsoleted_Passport_Save__c";
import PASSPORT_JSON_FIELD from "@salesforce/schema/Passport__c.DMT_Passport_Save__c";

import OPPORTUNITY_ID_EXTERNAL_FIELD from "@salesforce/schema/Opportunity.DMT_Opp_Id__c";
import OPPORTUNITY_RECORDTYPE_FIELD from "@salesforce/schema/Opportunity.RecordType.DeveloperName";
import OPPORTUNITY_STAGE_NAME_FIELD from "@salesforce/schema/Opportunity.StageName";
import OPPORTUNITY_CLIENT_TYPE_FIELD from "@salesforce/schema/Opportunity.DMT_Client_Type__c";
import OPPORTUNITY_CLIENT_ID_FIELD from "@salesforce/schema/Opportunity.AccountId";
import OPPORTUNITY_CURRENCY_FIELD from "@salesforce/schema/Opportunity.DMT_CurrencyText__c";
import OPPORTUNITY_ID_FIELD from '@salesforce/schema/Opportunity.Id';

const LOAD_STYLE_MESSAGE = 'Static Resource Loaded';
const ERROR_MESSAGE = 'error';
const ERROR_PASSPORT_MESSAGE = 'Error processing passport';
const UNSUBCRIBE_MESSAGE = 'Unsubscribed to change events';
const UNKNOWN_MESSAGE = 'Unknown error';
const PASSPORT_ENTITY = 'Passport__c';
const TASK_ENTTITY = 'Task';
const STRING_TYPE = 'string';
const MOTOR_DESC_FIELD = 'motorDesc';
const PASSPORT_SANCTION_FIELD = 'passportSanction';
const SALESFORCE_FEATURE = 'Salesforce';
const LIMIT_ENGINE_FEATURE = 'Limit Engine';
const LINE_ENGINE_FEATURE = 'Line Engine';
const CONSUME_ENGINE_FEATURE = 'Consume Engine';
const PROFITABILITY_ENGINE_FEATURE = 'Profitability Engine';
const APPROVAL_SECTION_FEATURE = 'approval';
const PASSPORT_SECTION_FEATURE = 'passport';
const READYTOCLOSE_SECTION_FEATURE = 'readytoclose';
const UNDEFINED_ENGINE_FEATURE = undefined;
const OPPERATION_CREATE_EVENT = 'CREATE';

const WHITE_STATE = 'WHITE';
const GRAY_STATE = 'GRAY';
const RED_STATE = 'RED';
const GREEN_STATE = 'GREEN';
const YELLOW_STATE = 'YELLOW';
const BLANK_STATE = 'BLANK';

const FEATURE_MANDATORY = 'featureMandatory';
const WORKFLOW_MANDATORY = 'workflowMandatory';
const CAPABILITY_MANDATORY = 'capabilityMandatory';

const APPROVAL_STATE = 'APPROVAL';
const PROPOSAL_STATE = 'PASSPORT';
const READY_TO_CLOSE_STATE = 'READYTOCLOSE';

const DRAFT_OPPORTUNITY_STATE = 'Draft';
const APPROVAL_OPPORTUNITY_STATE = 'Approval';
const PROPOSAL_OPPORTUNITY_STATE = 'Proposal';
const READY_TO_CLOSE_OPPORTUNITY_STATE = 'Ready to close';
const CLOSED_WON_OPPORTUNITY_STATE = 'Closed Won';

const CHANNEL_PASSPORT = '/data/Passport__ChangeEvent';
const CHANNEL_TASK = '/event/DMT_Task__e';


export default class Dmt_passport_opportunity extends LightningElement {

    @api isBigVersion;
    @api objectApiName;

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;

        if (this.objectApiName === 'Opportunity') {
            this.opportunityId = value;
        } else if (this.objectApiName === 'Passport__c') {
            this.passportId = value;
        }

        this.refreshAllWires();
    }

    @api
    get getservice() {
        return this._getservice;
    }

    set getservice(value) {

        this._getservice = value;
        if (value.toLowerCase() == 'true') {
            this.callService();
        }
    }

    @api
    get isBig() {
        return (this.isBigVersion === 'true');
    }

    get columns() {
        return this.isBig == true ? this.bigVersionColumns : this.smallVersionColumns;
    }

    get showAuditDate() {
        return this.myPayload !== undefined ? new Date(this.myPayload?.auditDate) : '';
    }

    get columnsWithClass() {
        return this.columns.map(col => ({
            ...col,
            class: `slds-is-sortable _slds-is-resizable slds-text-title--caps fixed-header fixed-row-header ${col.isNarrow}`
        }));

    }

    get checkStatusProposal() {
        return getFieldValue(this.opportunity, OPPORTUNITY_STAGE_NAME_FIELD) == PROPOSAL_OPPORTUNITY_STATE;
    }
    get checkStatusDraft() {
        return getFieldValue(this.opportunity, OPPORTUNITY_STAGE_NAME_FIELD) == DRAFT_OPPORTUNITY_STATE;
    }

    get checkStatusApproval() {

        console.log('checkStatusApproval getFieldValue(this.opportunity, OPPORTUNITY_STAGE_NAME_FIELD) ' + getFieldValue(this.opportunity, OPPORTUNITY_STAGE_NAME_FIELD));
        console.log('checkStatusApproval APPROVAL_OPPORTUNITY_STATE ' + APPROVAL_OPPORTUNITY_STATE);

        return getFieldValue(this.opportunity, OPPORTUNITY_STAGE_NAME_FIELD) == APPROVAL_OPPORTUNITY_STATE;
    }
    get checkStatusReadyToClose() {
        return getFieldValue(this.opportunity, OPPORTUNITY_STAGE_NAME_FIELD) == READY_TO_CLOSE_OPPORTUNITY_STATE;
    }
    get checkStatusClosedWon() {
        return getFieldValue(this.opportunity, OPPORTUNITY_STAGE_NAME_FIELD) == CLOSED_WON_OPPORTUNITY_STATE;
    }

    get isReadyToClose() {
        return true;
    }

    wiredPassportResultId;
    wiredPassportResult;
    wiredOpportunityResult;
    wiredGetLastDayResult;
    wiredFeaturesRules;

    passport;
    opportunity;
    opportunityId;
    passportId;
    refreshContainerId;
    lastDate;
    showWarning;
    rawPayload;
    myPayload;
    features = [];
    showfeaturesTable = false;
    featuresId;
    subscriptionPassport;
    subscriptionTask;
    recordType;
    groupedData = [];
    featuresIds = [];
    externalId;
    groupMembers;
    haveApprovalProcess;
    haveReadyToClose;
    hasRendered = false;

    @track approvalFeatures;
    @track readytocloseFeatures;
    @track limitTestFeatures;
    @track lineEngineFeatures;
    @track globalValidationsFeatures;
    @track profitabilityFeatures;
    @track undefinedFeatures;
    @track pawifFeatures;
    @track clientType;

    _recordId;
    _getservice;

    showSpinner = false;
    messageError = '';
    featureRules = [];
    responseValidationOpp;
    userPermission = false;
    previousOpportunityStage;
    approvalTransitionPending = false;
    statusRefreshInProgress = false;
    readytoclosePassportTriggered = new Set();

    bigVersionColumns = [
        { label: "FEATURE", fieldName: 'approvers', type: 'text', isNarrow: "slds-size_3-of-12" },
        { label: "CAPABILITY", fieldName: 'capabilityStatus', type: 'text', isNarrow: "slds-size_1-of-12 slds-p-right_small" },
        { label: "WORKFLOW", fieldName: 'worflowStatus', type: 'text', isNarrow: "slds-size_1-of-12 slds-p-right_small" },
        { label: "", fieldName: '', type: 'text', isNarrow: "" },
        { label: "Approver", fieldName: 'approverName', type: 'text', isNarrow: "" },
        { label: "TASK", fieldName: 'taskName', type: 'url', isNarrow: "" },
        { label: "TASK STATUS", fieldName: 'taskStatus', type: 'text', isNarrow: "" },
        { label: "START DATE", fieldName: 'taskStart', type: 'text', isNarrow: "" },
        { label: "END DATE", fieldName: 'taskEnd', type: 'text', isNarrow: "" },
        { label: "RESULT", fieldName: 'taskResult', type: 'text', isNarrow: "" }
    ];

    smallVersionColumns = [
        { label: "FEATURE", fieldName: 'approvers', type: 'text', isNarrow: "slds-size_3-of-12" },
        { label: "CAPABILITY", fieldName: 'capabilityStatus', type: 'text', isNarrow: "slds-size_1-of-12 slds-p-right_small" },
        { label: "WORKFLOW", fieldName: 'worflowStatus', type: 'text', isNarrow: "slds-size_1-of-12 slds-p-right_small" }
    ];

    //INFORMACION DEL PASSPORT
    @wire(getInformationPassport, { recordId: "$recordId" })
    wiredInformationPassportId(result) {
        try {
            this.wiredPassportResultId = result;
            const { error, data } = result;

            if (data) {

                let dataParse = this.parseJson(data);
                this.passportId = dataParse.passportId;
                this.recordType = dataParse.recordType;
                this.userPermission = dataParse.userPermission;
                this.externalId = dataParse.externalId;
                this.groupMembers = dataParse.groupMembers;

                this.refreshAllWires();
            } else if (error) {
                this.handleError(error.body.message);
            }
        } catch (error) {
            this.handleError(error.body.message);
        }
    }

    //INFORMACION DEL PASSPORT
    @wire(getRecord, {
        recordId: "$passportId", fields: [
            PASSPORT_OPPORTUNITY_ID_FIELD,
            PASSPORT_OBSOLETED_FIELD,
            PASSPORT_JSON_FIELD
        ]
    })
    wiredInformationPassport(result) {
        try {
            this.wiredPassportResult = result;
            const { error, data } = this.wiredPassportResult;

            if (data) {

                this.passport = data;
                var warningValue = getFieldValue(data, PASSPORT_OBSOLETED_FIELD);
                var jsonData = getFieldValue(data, PASSPORT_JSON_FIELD);
                this.showWarning = jsonData ? warningValue : false;

                this.opportunityId = getFieldValue(this.passport, PASSPORT_OPPORTUNITY_ID_FIELD);
                this.proccessPassport(getFieldValue(data, PASSPORT_JSON_FIELD));
                this.showfeaturesTable = getFieldValue(data, PASSPORT_JSON_FIELD) ? true : false;
                this.updateFeatureType();
                //this.features.map(feature => this.setFeatureProperties(feature)); // WIP: ALVARO refactor --> Se hace dos veces, en la linea this.proccessPassport(getFieldValue(data, PASSPORT_JSON_FIELD));
                this.getCurrentStepFromFeaturesOpp();

            } else if (error) {
                this.handleError(error.body.message);
            }
        } catch (error) {
            this.handleError(error.body.message);
        }
    }

    //INFORMACION DE LA OPPORTUNIDAD
    @wire(getRecord, {
        recordId: "$opportunityId", fields: [
            OPPORTUNITY_ID_EXTERNAL_FIELD,
            OPPORTUNITY_RECORDTYPE_FIELD,
            OPPORTUNITY_STAGE_NAME_FIELD,
            OPPORTUNITY_CLIENT_TYPE_FIELD,
            OPPORTUNITY_CLIENT_ID_FIELD,
            OPPORTUNITY_CURRENCY_FIELD
        ]
    })
    wiredRecordOpportunity(result) {
        try {
            this.wiredOpportunityResult = result;
            const { error, data } = result;

            if (data) {

                this.opportunity = data;

                const newStage = getFieldValue(data, OPPORTUNITY_STAGE_NAME_FIELD);

                if (this.previousOpportunityStage != undefined && this.previousOpportunityStage != newStage) {
                    const isEnteringApproval = newStage === APPROVAL_OPPORTUNITY_STATE;
                    this.approvalTransitionPending = isEnteringApproval && this.hasResolvableApprovalApprover();
                    if (this.approvalTransitionPending) {
                        this.showSpinner = true;
                    }
                    if (newStage !== APPROVAL_OPPORTUNITY_STATE && this.isBigVersion !== 'true') {
                        this.handleStatusChange();
                    }
                }

                this.previousOpportunityStage = newStage;
                this.proccessPassport(getFieldValue(this.passport, PASSPORT_JSON_FIELD));
                this.features.map(feature => this.setFeatureProperties(feature));
                
                 if (this.limitTestFeatures?.length > 0) {
                    this.limitTestFeatures = this.limitTestFeatures.map(f => ({ ...f }));
                } 

            } else if (error) {
                this.handleError(error.body.message);
            }

        } catch (error) {
            this.handleError(error.body.message);
        }
    }

    @wire(getLastDay)
    wiredGetLastDay(result) {
        try {
            this.wiredGetLastDayResult = result;
            const { error, data } = result;

            if (data) {
                this.lastDate = data;
            } else if (error) {
                this.handleError(error.body.message);
            }
        } catch (error) {
            this.handleError(error.body.message);
        }
    }

    @wire(getFeatureRulesLwc)
    wiredFeatureRules(result) {
        try {
            this.wiredFeaturesRules = result;
            const { error, data } = result;

            if (data) {
                this.processFeaturesRules(data);
            } else if (error) {
                this.handleError(error.body.message);
            }

        } catch (error) {
            this.handleError(error.body.message);
        }
    }

    connectedCallback() {

        this.loadStylePromise();

        this.refreshContainerId = registerRefreshContainer(this, this.refreshContainer);
        this.registerErrorListener();
        this.registerSubscribe();
    }

    renderedCallback() {
        if (!this.hasRendered) {
            this.onScrollPassport();
            this.hasRendered = true;
        }
    }

    disconnectedCallback() {
        unsubscribe(this.subscriptionPassport, () => console.info(UNSUBCRIBE_MESSAGE + PASSPORT_ENTITY));
        unsubscribe(this.subscriptionTask, () => console.info(UNSUBCRIBE_MESSAGE + TASK_ENTTITY));
        pubsub.unregister('callPassportLWC', this.handleEventObj);
        unregisterRefreshContainer(this.refreshContainerID);
    }

    loadStylePromise() {

        Promise.all([loadStyle(this, overflowyscroll)])
            .then(() => {
                console.info(LOAD_STYLE_MESSAGE);
            })
            .catch(error => {
                this.handleError(error.message);
            });
    }

    onScrollPassport() {
        if (this.isBigVersion !== 'true') {

            let dynamicInitialOffset = 325;

            window.onscroll = () => {
                let body = window?.document?.body;
                let documentNode = window?.document?.documentElement;
                documentNode = (documentNode?.clientHeight) ? documentNode : body;

                // 1. Securely find the anchor
                let stickyAnchor = this.template.querySelector('.stickyAnchor');
                if (!stickyAnchor) return;

                // 2. Traverse UP to the specific parent wrapper
                let passportElement = stickyAnchor.closest('.slds-passport');
                if (!passportElement) return;

                // 4. Pure math using the dynamic offset
                let newTop = dynamicInitialOffset - Math.round(documentNode.scrollTop);
                newTop = 165 < newTop ? newTop : 165;

                // 5. Apply the style
                if (documentNode.scrollTop === 0) {
                    // When hitting the top, we remove the inline style.
                    // This allows Step 3 to recalculate the perfect height on the next scroll!
                    passportElement.style.removeProperty('top');
                } else {
                    // The moment this applies, Step 3 stops calculating, locking the math in place.
                    passportElement.style.setProperty('top', `${newTop}px`);
                }
            };
        }
    }
        refreshContainer(refreshPromise) {
        return refreshPromise.then((status) => {
            console.info(status === REFRESH_COMPLETE);
        });
    }

    registerErrorListener() {
        onError(error => {
            console.error("EMP API Error: ", JSON.stringify(error));
        });
    }

    registerSubscribe() {

        const changeEventPassportCallback = changeEventPassport => {
            this.processChangePassportEvent(changeEventPassport);
        };

        const changeEventTaskCallback = changeEventTask => {
            this.processChangeTaskEvent(changeEventTask);
        };

        subscribe(CHANNEL_PASSPORT, -1, changeEventPassportCallback).then(subscription => {
            this.subscriptionPassport = subscription;
        });
        subscribe(CHANNEL_TASK, -1, changeEventTaskCallback).then(subscription => {
            this.subscriptionTask = subscription;
        });

        notifyRecordUpdateAvailable([{ recordId: this.passportId }]);
    }

    processChangePassportEvent(changeEvent) {
        try {
            const recordIds = changeEvent.data.payload.ChangeEventHeader.recordIds;
            if(recordIds.includes(this.passportId)){
                notifyRecordUpdateAvailable([{ recordId: this.passportId }]);
            }
        } catch (error) {
            this.handleError(error.message);
        }
    }

    processChangeTaskEvent(changeEvent) {
        try {
            const operation = changeEvent.data.payload.Operation__c;
            const recordsInEvent = changeEvent.data.payload.records__c;            

            if (operation === 'CREATE' && this.checkStatusApproval && this.approvalTransitionPending) {
                this.approvalTransitionPending = false;
                this.showSpinner = false;
            }

            this.refreshAllWires();
            this.getCurrentStepFromFeaturesOpp(); 

            // Detect "Close Task" (step 11): MODIFY event with multiple task IDs
            // means all tasks in the case were set to Finished simultaneously.
            // This is the moment to refresh the passport (callService).
            if (operation === 'MODIFY' && recordsInEvent && recordsInEvent.includes(',') && this.checkStatusReadyToClose) {
                if (!this.readytoclosePassportTriggered.has('_closetask_')) {
                    this.readytoclosePassportTriggered.add('_closetask_');
                    // Wait for Salesforce transaction to fully commit
                    setTimeout(() => {
                        this.triggerReadytoclosePassportRefresh();
                    }, 5000);
                }
            }
        } catch (error) {
            this.handleError(error.message);
        }
    }

    triggerReadytoclosePassportRefresh() {
        let arrayFeaturesApproverId = [];
        if (this.readytocloseFeatures) {
            this.readytocloseFeatures.forEach(feature => {
                const approverId = feature?.tasks?.[0]?.approvers?.[0]?.id;
                if (approverId) {
                    arrayFeaturesApproverId.push(approverId);
                }
            });
        }

        if (this.opportunityId != null && arrayFeaturesApproverId.length > 0) {
            updateRiskLinesAndWarranties({ oppId: this.opportunityId, approversId: arrayFeaturesApproverId, typeFeature: 'business' })
                .then(() => {
                    if (!this.statusRefreshInProgress) {
                        this.statusRefreshInProgress = true;
                        this.callService().finally(() => {
                            this.statusRefreshInProgress = false;
                            // After passport is refreshed, fetch the settled state → GREEN
                            this.getCurrentStepFromFeaturesOpp();
                            this.readytoclosePassportTriggered.delete('_closetask_');
                        });
                    } else {
                        this.readytoclosePassportTriggered.delete('_closetask_');
                    }
                })
                .catch(error => {
                    console.error('Error in triggerReadytoclosePassportRefresh:', error);
                    this.readytoclosePassportTriggered.delete('_closetask_');
                });
        } else {
            this.readytoclosePassportTriggered.delete('_closetask_');
        }
    }

    proccessPassport(newPayload) {

        if (this.rawPayload === newPayload) {
            return;
        }

        const parsedValue = this.parseJson(newPayload);

        if (parsedValue?.data !== undefined) {
            this.rawPayload = newPayload;

            this.myPayload = parsedValue.data;

            this.features = this.myPayload.features;
            this.features.map(feature => this.setFeatureProperties(feature));

            this.limitTestFeatures = this.filterListByField(this.features, MOTOR_DESC_FIELD, LIMIT_ENGINE_FEATURE);
            this.limitTestFeatures = this.limitTestFeatures.concat(this.filterListByField(this.features, MOTOR_DESC_FIELD, CONSUME_ENGINE_FEATURE));
            this.lineEngineFeatures = this.filterListByField(this.filterListByField(this.features, MOTOR_DESC_FIELD, LINE_ENGINE_FEATURE), PASSPORT_SANCTION_FIELD, PASSPORT_SECTION_FEATURE);
            this.globalValidationsFeatures = this.filterListByField(this.features, MOTOR_DESC_FIELD, SALESFORCE_FEATURE);
            this.profitabilityFeatures = this.filterListByField(this.features, MOTOR_DESC_FIELD, PROFITABILITY_ENGINE_FEATURE);
            let preFilterFeatures = this.filterListByField(this.features, MOTOR_DESC_FIELD, UNDEFINED_ENGINE_FEATURE);
            this.undefinedFeatures = this.filterListByField(preFilterFeatures, PASSPORT_SANCTION_FIELD, PASSPORT_SECTION_FEATURE);
            this.approvalFeatures = this.filterListByField(this.features, PASSPORT_SANCTION_FIELD, APPROVAL_SECTION_FEATURE);
            
            

            this.haveApprovalProcess = this.approvalFeatures.length > 0;

            this.readytocloseFeatures = this.filterListByField(this.features, PASSPORT_SANCTION_FIELD, READYTOCLOSE_SECTION_FEATURE);
            this.haveReadyToClose = this.readytocloseFeatures.length > 0;

            this.showSpinner = false;
        }
        else {
            this.showSpinner = false;
        }
    }


    setFeatureProperties(feature) {

        this.featuresIds.push(feature.id);
        feature.isValid = feature.isValid !== undefined ? feature.isValid : true;
        feature.capabilityIsValid = feature.capabilityIsValid !== undefined ? feature.capabilityIsValid : true;
        feature.workflowIsValid = feature.workflowIsValid !== undefined ? feature.workflowIsValid : true;
        feature.checkStatusProposal = this.checkStatusProposal;
        feature.checkStatusDraft = this.checkStatusDraft;
        feature.checkStatusApproval = this.checkStatusApproval;
        feature.checkStatusReadyToClose = this.checkStatusReadyToClose;
        feature.userPermission = this.userPermission;
        feature.featureIsValid = true;
        feature.opportunityId = this.externalId;
        feature.fieldsRequired = feature.fieldsRequired || {};

        feature.showTrafficLight = feature.stateName != WHITE_STATE && feature.stateName != BLANK_STATE && feature.stateName != undefined;
        feature.showErrorCapability = feature.validations?.length > 0;
        feature.showErrorWorkflow = feature.validations?.length > 0;

        feature = this.formatValidation(feature);
        
        const currentOppStage = (getFieldValue(this.opportunity, OPPORTUNITY_STAGE_NAME_FIELD) || '').toUpperCase();
        const targetStatus = feature.requiredAtStatus ? feature.requiredAtStatus.toUpperCase() : 'READY TO CLOSE';

        const isProposal = feature.passportSanction?.toUpperCase() === PROPOSAL_STATE && feature.userPermission;
        
        // Dynamically allow rendering if the current stage equals the target stage where it's required
        const isStageMatchForApproval = feature.checkStatusApproval || currentOppStage === targetStatus;
        const isStageMatchForReadyToClose = feature.checkStatusReadyToClose || currentOppStage === targetStatus;

        const isApproval = feature.passportSanction?.toUpperCase() === APPROVAL_STATE && isStageMatchForApproval && feature.userPermission;
        const isReadyToClose = feature.passportSanction?.toUpperCase() === READY_TO_CLOSE_STATE && isStageMatchForReadyToClose && feature.userPermission;
        const isWithoutApprovalAndReadyToClose = feature.passportSanction?.toUpperCase() !== APPROVAL_STATE && feature.passportSanction?.toUpperCase() !== READY_TO_CLOSE_STATE;
        const isApprovers = feature?.tasks?.[0]?.approvers?.[0]?.id != undefined;

        const requiredType = (feature?.requiredType || '').trim().toUpperCase();
        // Only requiredType = 'Y' is considered mandatory. 'N' and null/undefined are treated as non-mandatory.
        const isMandatoryFeature = requiredType === 'Y';

        // For proposal/passport features:
        // - In Proposal: keep current behavior
        // - In Target Stage (Dynamic): only allow Request if mandatory
        const allowProposalRequest = feature.checkStatusProposal || ((isStageMatchForApproval || isStageMatchForReadyToClose) && isMandatoryFeature);

        feature.dmtCurrency = getFieldValue(this.opportunity, OPPORTUNITY_CURRENCY_FIELD);

        // Reset flags before setting them based on conditions
        feature.request = false;
        feature.showRequestButtonInProposal = false;
        feature.showRequestButtonInApproval = false;
        feature.showRequestButtonInReadyToClose = false;

        // Show request button logic:
        feature.showRequestButtonInProposal = (isProposal && allowProposalRequest && isWithoutApprovalAndReadyToClose && isApprovers);
        feature.showRequestButtonInApproval = (!isProposal && isApproval && !isReadyToClose && isApprovers);
        feature.showRequestButtonInReadyToClose = (!isProposal && !isApproval && isReadyToClose && isApprovers);

        // Request flag
        if (isReadyToClose && isApprovers) feature.request = true;
        if (isProposal && isApprovers && allowProposalRequest) feature.request = true;
        if (!isProposal && isApproval && !isReadyToClose && isApprovers) feature.request = true;
        if(feature.name == 'Portfolio Alignment Simulation') feature.pawif = true;

        const freezedFeature = (feature?.indicatorId || '').trim().toUpperCase();
        feature.isFaded = freezedFeature=== 'Y' && (this.checkStatusReadyToClose || this.checkStatusClosedWon); //&& !isReadyToCloseFeature && !isMandatoryFeature;
    }

    formatValidation(feature) {
        feature.featureErrorMessage = undefined;
        feature.workflowErrorMessage = undefined;
        feature.capabilityErrorMessage = undefined;

        feature.validations?.forEach(validation => {
            if (validation.state == RED_STATE) {

                let featureName = this.featureRules[validation.message] === undefined ? validation.message : this.featureRules[validation.message];

                if (validation.name.includes(FEATURE_MANDATORY)) {

                    feature.showErrorFeature = true;
                    feature.featureIsValid = false;
                    feature.featureErrorMessage = feature.errorMessage === undefined ? featureName : feature.errorMessage + ' ' + featureName;
                }
                else if (validation.name.includes(WORKFLOW_MANDATORY)) {
                    feature.workflowIsValid = false;
                    feature.workflowErrorMessage = feature.workflowErrorMessage === undefined ? featureName : feature.workflowErrorMessage + ' ' + featureName;
                }
                else if (validation.name.includes(CAPABILITY_MANDATORY)) {
                    feature.capabilityIsValid = false;
                    feature.capabilityErrorMessage = feature.capabilityErrorMessage === undefined ? featureName : feature.capabilityErrorMessage + ' ' + featureName;
                }
            }
        });

        return feature;
    }

    getCurrentStepFromFeaturesOpp() {

        getCurrentStepFromFeaturesOpp({
            featuresIds: this.featuresIds,
            oppExternalId: this.externalId
        }).then(response => {
            if (response !== undefined) {

                let currentTaks = JSON.parse(JSON.stringify(response));
                const taskMap = new Map();

                const allTasks = currentTaks.flatMap(currentTask => {
                    const isClosedOrFinished = ['Closed', 'Finished'].includes(currentTask.itemKey);
                    return isClosedOrFinished ? [...currentTask.subitems] : [currentTask];
                });

                allTasks.forEach(taskItem => {
                    taskMap.set(taskItem.featureId, taskItem);
                });

                if (this.readytocloseFeatures != undefined) {
                    this.readytocloseFeatures = this.formatCurrentCase(this.readytocloseFeatures, taskMap);
                }
                if (this.profitabilityFeatures != undefined) {
                    this.profitabilityFeatures = this.formatCurrentCase(this.profitabilityFeatures, taskMap);
                }
                if (this.approvalFeatures != undefined) {
                    this.approvalFeatures = this.formatCurrentCase(this.approvalFeatures, taskMap);
                    this.calculateApprovalRequestActive();
                }
                if (this.undefinedFeatures != undefined) {
                    this.undefinedFeatures = this.formatCurrentCase(this.undefinedFeatures, taskMap);
                    this.calculateApprovalRequestActive();
                }
            }

        }).catch((error) => {
            this.handleError(error.message);
        });
    }

    calculateApprovalRequestActive() {

        if (this.approvalFeatures.length == 0) return;

        this.approvalFeatures = this.approvalFeatures.map(feature => {
            return { ...feature, request: false };
        });

        const withFeatureTypeBusiness = this.approvalFeatures.filter(item => item.featureType == 'Business').sort((a, b) => a.orderNumber - b.orderNumber);
        const withFeatureTypeRisk = this.approvalFeatures.filter(item => item.featureType == 'Risk').sort((a, b) => a.orderNumber - b.orderNumber);

        /*const hasBusinessRejectedOrNA = withFeatureTypeBusiness.some(item => item.workflowColor === RED_STATE || item.workflowColor === GRAY_STATE);
        
        if (hasBusinessRejectedOrNA) {
            this.approvalFeatures = [...this.approvalFeatures];
            return;
        }*/

        const allBusinessGreen = withFeatureTypeBusiness.every(item =>
            item.workflowColor === GREEN_STATE
        );
        const firstUnfinishedBusiness = withFeatureTypeBusiness.find(item =>
            item.isNotFinishedTask == undefined || item.isNotFinishedTask
        );
        if (firstUnfinishedBusiness) {
            const featInBuffer = this.approvalFeatures.find(w => w.id === firstUnfinishedBusiness.id);
            if (featInBuffer) {
                featInBuffer.request = true;
            }
        } else if (withFeatureTypeRisk.length > 0 && allBusinessGreen) {
            withFeatureTypeRisk.forEach(riskFeature => {
                const featInBuffer = this.approvalFeatures.find(w => w.id === riskFeature.id);
                if (featInBuffer){
                    featInBuffer.request = true;
                }
            });
        }

        // FORCE REACTIVITY: Reassign the array to trigger the UI re-render
        this.approvalFeatures = [...this.approvalFeatures];
    }

    formatCurrentCase(features, taskMap) {

        const featuresAux = [];

        features.forEach(feature => {

            feature = { ...feature, hasSftask: false };
            const tasks = feature?.tasks;

            if (tasks?.length > 0) {
                const firstTask = tasks?.[0];
                const hasApprovers = firstTask.approvers?.length > 0;

                if (hasApprovers) {
                    feature.currentTask = {
                        ...firstTask,
                        status: 'Not started',
                        approver: firstTask.approvers?.[0].name
                    };
                    feature.showHistoryButton = false;
                } else {
                    feature.currentTask = null;
                }

                const currentTask = taskMap.get(feature.id);

                if (currentTask) {

                    if (currentTask.startDate) currentTask.startDate = this.formatDate(currentTask.startDate);
                    if (currentTask.endDate) currentTask.endDate = this.formatDate(currentTask.endDate);

                    currentTask.openModal = currentTask.step?.urlValue === 'c-modal-container';

                    feature.hasSftask = true;
                    feature.currentTask = currentTask;
                    feature.hascurrentTask = true;
                    feature.isApprover = this.groupMembers.includes(currentTask.approver);
                    feature.isApproverOrGod = feature.isApprover || hasLineGodPermission;
                    feature.isNotFinishedTask = currentTask.caseStatus != 'Finished';

                    feature.showHistoryButton = currentTask.taskSize > 1;

                    feature.workflowColor = this.getWorkflowColor(currentTask, feature);
                }
            }
            featuresAux.push(feature);
        });

        return featuresAux;
    }

    showSpinnerEvent(event) {
        this.showSpinner = event.detail.message;
    }

    getWorkflowColor(task, feature) {

        if (task.caseStatus === 'Pending' || task.caseStatus === 'In Progress') return YELLOW_STATE;

        if (task.caseStatus === 'Finished') {
            if (task.rawresult === 'No') return RED_STATE;
            if (task.rawresult === 'Yes') return GREEN_STATE;
            if (task.rawresult === undefined) {
                feature.workflowIsNotValid = true;
                feature.workflowErrorMessage = 'Task without result and case finished';
                return GRAY_STATE;
            }
        }
        return feature.workflowColor;
    }

    formatDate(dateToFormat) {
        var [date, hour] = (dateToFormat).split(" ");
        var [day, mnt, year] = date.split("/");
        return day + '-' + mnt + '-' + year;
    }

    filterListByField(list, field, value) {
        return list?.filter(item => item[field] == value) || [];
    }

    hasResolvableApprovalApprover() {
        return (this.features || []).some(feature =>
            feature.passportSanction === APPROVAL_SECTION_FEATURE &&
            feature.tasks?.[0]?.approvers?.[0]?.id != undefined
        );
    }

    processFeaturesRules(featuresRulesList) {
        featuresRulesList.forEach((featureRule) => {
            this.featureRules[featureRule.DMT_Field__c] = featureRule.dmt_message__c;
        });
    }

    handleErrorEvent(event) {
        this.handleError(event.detail.message);
    }

    handleError(error) {

        console.error(ERROR_MESSAGE, JSON.stringify(error));

        let message = UNKNOWN_MESSAGE;

        if (Array.isArray(error?.body)) {
            message = error?.body.map((e) => e.message).join(", ");
        } else if (typeof error?.body?.message === STRING_TYPE) {
            message = error?.body?.message;
        } else if (typeof error === STRING_TYPE) {
            message = error;
        } else if (Array.isArray(error) && error.length > 0 && typeof error[0] === STRING_TYPE) {
            message = this.csLabels.requiredMsg + ' ' + error.join(", ") + '.';
        }

        this.messageError = message;
        this.setToast(ERROR_PASSPORT_MESSAGE, message, ERROR_MESSAGE);
        this.showSpinner = false;
    }


    handleStatusChange() {
        if (this.statusRefreshInProgress) {
            return;
        }

        this.statusRefreshInProgress = true;
        this.dispatchEvent(new RefreshEvent());
        this.refreshAllWires();

        this.callService().finally(() => {
            this.statusRefreshInProgress = false;
        });
    }

    setToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message,
                variant: variant,
            }),
        );
    }

    parseJson(value) {
        try {
            return JSON.parse(value);
        } catch (error) {
            this.handleError(error.message);
            return null;
        }
    }

    async callService() {

        this.messageError = '';
        this.showSpinner = true;

        await this.validateOppBeforePassportService();
        if (!this.responseValidationOpp?.success) {
            this.handleError(this.responseValidationOpp?.message?.[0]);
            return;
        }

        this.refreshAllWires();

        
        getMainHolderAccountId({ oppId: this.opportunityId }).then(result => {
            this.clientId = result.AccountId;
            this.clientType = result.ClientType;

        const params = {
            selectedTab: 'passport',
            clientId: null,
            lCountries: ["ALL"],
            searchDate: this.lastDate,
            clientPositionsType: 'N',
            page: 1,
            pageSize: '100',
            customerId: this.clientId,
        };


        fetchData(params).then(data => {
            if (data.success) {
                    this.buttonCallPassport(data.data);
                
            } else {
                this.handleError(data.errorMessage);
            }
        }).catch((error) => {
            this.handleError(error.message);
        });

        }).catch((error) => {
            this.handleError(error.message);
        });
    }

    async buttonCallPassport(data) {
        if (data) {
            buttonCallPassport({
                recordId: this.recordId,
                clientesGroup: JSON.stringify(data)
            }).then(response => {
                let result = JSON.parse(response);
                if (!result.result) {
                    this.handleError(result.message);
                } else {
                    this.messageError = '';
                    if (this.passportId) {
                        notifyRecordUpdateAvailable([{ recordId: this.passportId }]);
                    }
                }
            }).catch((error) => {
                this.handleError(error.message);
            })
        }
        else {
            this.handleError(this.csLabels.clientsValidationMsg1);
        }
    }

    async validateOppBeforePassportService() {

        this.responseValidationOpp = await validateOppBeforePassport({ oppId: this.opportunityId });
        return this.responseValidationOpp;
    }

    updateFeatureType() {

        let arrayFeaturesApproverId = [];

        this.features.forEach(feature => {

            if (feature?.passportSanction == APPROVAL_SECTION_FEATURE && feature?.tasks?.[0]?.approvers?.[0]) {
                arrayFeaturesApproverId.push(feature?.tasks?.[0]?.approvers?.[0]?.id);
            }
        });

        if (arrayFeaturesApproverId.length > 0) {
            return getFeatureTypeByApproverType({ featuresApproverIds: arrayFeaturesApproverId }).then(response => {
                if (response !== undefined) {
                    response = JSON.parse(JSON.stringify(response));

                    const approverMap = response.reduce((acc, item) => {
                        acc[item.approverId] = item.featureType;
                        return acc;
                    }, {});

                    this.features.forEach(feature => {
                        if (feature.passportSanction == APPROVAL_SECTION_FEATURE && feature.tasks?.[0]?.approvers?.[0]?.id) {
                            feature.featureType = approverMap[feature.tasks?.[0]?.approvers?.[0]?.id];
                        }
                    });
                }
                this.features = [...this.features];
            }).catch((error) => {
                this.handleError(error.message);
            });
        }
    }

    async initRefreshTasksInProgress() {

        this.featuresIds = [];

        this.features.forEach(feature => {
            if (feature.id != null && feature.tasks?.length > 0 && feature.tasks[0]?.approvers?.length > 0) {
                this.featuresIds.push(feature.id);
            }
            if (feature.tasks === undefined || feature.tasks.length === 0) {
                feature.tasks = undefined;
            }
        });

        this.getCurrentStepFromFeaturesOpp();
    }

    forceRefreshAllWires() {

        this.showSpinner = true;

        this.callService().finally(() => {
            this.statusRefreshInProgress = false;
        });
    }

    refreshWithoutService() {
        const temp = this.passportId;
        this.passportId = null;

        setTimeout(() => {
            this.passportId = temp;
        }, 0);
    }
    refreshAllWires() {

        refreshApex(this.wiredPassportResultId);
        refreshApex(this.wiredGetLastDayResult);
        refreshApex(this.wiredFeaturesRules);

        // 2. COMMENT OUT Invalid LDS refreshApex calls
        // refreshApex(this.wiredOpportunityResult);
        // refreshApex(this.wiredPassportResult);

        // 3. IMPLEMENT notifyRecordUpdateAvailable for SObjects
        const recordsToRefresh = [];
        
        if (this.opportunityId) {
            recordsToRefresh.push({ recordId: this.opportunityId });
        }
        if (this.passportId) {
            recordsToRefresh.push({ recordId: this.passportId });
        }

        if (recordsToRefresh.length > 0) {
            // This purges the LDS cache and triggers wiredRecordOpportunity 
            // and wiredInformationPassport to fetch fresh data
            notifyRecordUpdateAvailable(recordsToRefresh);
        }
    }

    // updateReadyToClose removed in favor of dynamic Apex validation
}