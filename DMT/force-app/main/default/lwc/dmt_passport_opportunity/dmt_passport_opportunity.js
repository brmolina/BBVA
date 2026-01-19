import { LightningElement, api, track, wire } from 'lwc';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { getRecord, getFieldValue, getRecordNotifyChange } from "lightning/uiRecordApi";
import { loadStyle } from 'lightning/platformResourceLoader';
import { RefreshEvent,  registerRefreshContainer, unregisterRefreshContainer, REFRESH_ERROR, REFRESH_COMPLETE, REFRESH_COMPLETE_WITH_ERRORS } from "lightning/refresh";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from '@salesforce/apex';

import overflowyscroll from '@salesforce/resourceUrl/DMT_overflowyscroll';
import pubsub from "omnistudio/pubsub";

import getLastDay from '@salesforce/apex/DMT_Passport_Handler.getLastDay';
import getFeatureRulesLwc from '@salesforce/apex/DMT_Passport_Handler.getFeatureRulesLWC';
import getInformationPassport from '@salesforce/apex/DMT_Passport_Handler.getInformationPassport';
import getAllsValidate from '@salesforce/apex/DMT_Rules_Feature.getAllsValidate';
import validateOppBeforePassport from '@salesforce/apex/DMT_Passport_Handler.validateOppBeforePassport';
import fetchData from '@salesforce/apex/DMT_HPG_MainTableCustomController.fetchData';
import buttonCallPassport from '@salesforce/apex/DMT_Passport_Handler.buttonCallPassport';
import getFeatureTypeByApproverType from '@salesforce/apex/DMT_Passport_Handler.getFeatureTypeByApproverType';
import getCurrentStepFromFeaturesOpp from '@salesforce/apex/DMT_Case_Steps_Controller.getCurrentStepFromFeaturesOpp';

import PASSPORT_OPPORTUNITY_ID_FIELD from "@salesforce/schema/Passport__c.Opportunity__c";
import PASSPORT_OBSOLETED_FIELD from "@salesforce/schema/Passport__c.DMT_Is_Obsoleted_Passport_Save__c";
import PASSPORT_JSON_FIELD from "@salesforce/schema/Passport__c.DMT_Passport_Save__c";

import OPPORTUNITY_ID_EXTERNAL_FIELD from "@salesforce/schema/Opportunity.DMT_Opp_Id__c";
import OPPORTUNITY_RECORDTYPE_FIELD from "@salesforce/schema/Opportunity.RecordType.DeveloperName";
import OPPORTUNITY_STAGE_NAME_FIELD from "@salesforce/schema/Opportunity.StageName";
import OPPORTUNITY_CLIENT_TYPE_FIELD from "@salesforce/schema/Opportunity.DMT_Client_Type__c";
import OPPORTUNITY_CLIENT_ID_FIELD from "@salesforce/schema/Opportunity.AccountId";
import OPPORTUNITY_CURRENCY_FIELD from "@salesforce/schema/Opportunity.DMT_Currency__c";

const INITIAL_OFFSET = 330;
const MINIMUM_TOP = 215;
const TOP = 'top';
const SLDS_PATH_CLASS = '.slds-path';
const SLDS_PASSPORT_CLASS = '.slds-passport';

const LOAD_STYLE_MESSAGE = 'Static Resource Loaded';
const ERROR_MESSAGE = 'error';
const ERROR_PASSPORT_MESSAGE = 'Error processing passport';
const UNSUBCRIBE_MESSAGE = 'Unsubscribed to change events';
const UNKNOWN_MESSAGE = 'Unknown error';
const PASSPORT_ENTITY = 'Passport__c';
const TASK_ENTTITY = 'Task';
const STRING_TYPE = 'string';
const EMPTY_STRING = 'string';
const CUSTOMER_STRG = 'Customer';
const MOTOR_DESC_FIELD = 'motorDesc';
const PASSPORT_SANCTION_FIELD = 'passportSanction';
const SALESFORCE_FEATURE = 'Salesforce';
const LIMIT_ENGINE_FEATURE = 'Limit Engine';
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

const APPROVAL_OPPORTUNITY_STATE = 'Approval';
const PROPOSAL_OPPORTUNITY_STATE = 'Proposal';
const READY_TO_CLOSE_OPPORTUNITY_STATE = 'Ready to close';

const CHANNEL_PASSPORT = '/data/Passport__ChangeEvent';
const CHANNEL_TASK = '/event/DMT_Task__e';

const OPPORTUNITY_PREFIX = '006';

export default class Dmt_passport_opportunity extends LightningElement {
    
    @api isBigVersion;
    
    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        console.log('Dmt_passport_opportunity set recordId ' + value);
        this._recordId = value;
        this.opportunityId = value;
        this.refreshAllWires();
    }
    
    @api
    get getservice() {
        return this._getservice;
    }
    
    set getservice(value) {
        
        console.log('Dmt_passport_opportunity set getservice value ' + value);
        
        this._getservice = value;
        if(value.toLowerCase() == 'true'){
            this.callService();
        }
    }
    
    @api
    get isBig() {
        return (this.isBigVersion === 'true');
    }
    
    get columns() {
        return this.isBig == true ? this.bigVersionColumns: this.smallVersionColumns;
    }
    
    get showAuditDate(){
        return this.myPayload !== undefined ? new Date(this.myPayload?.auditDate) : '';
    }
    
    get columnsWithClass()
    {
        return this.columns.map(col => ({
            ...col,
            class: `slds-is-sortable _slds-is-resizable slds-text-title--caps fixed-header fixed-row-header ${col.isNarrow}`
        }));
        
    }
    
    get checkStatusProposal(){
        return getFieldValue(this.opportunity, OPPORTUNITY_STAGE_NAME_FIELD) == PROPOSAL_OPPORTUNITY_STATE;
    }
    
    get checkStatusApproval(){
        return getFieldValue(this.opportunity, OPPORTUNITY_STAGE_NAME_FIELD) == APPROVAL_OPPORTUNITY_STATE || getFieldValue(this.opportunity, OPPORTUNITY_STAGE_NAME_FIELD) == READY_TO_CLOSE_OPPORTUNITY_STATE;
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
    
    @track approvalFeatures;
    @track readytocloseFeatures;
    @track limitTestFeatures;
    @track globalValidationsFeatures;
    @track profitabilityFeatures;
    @track undefinedFeatures;
    @track clientType;
    
    _recordId;
    _getservice;
    
    showSpinner = false;
    messageError = '';
    featureRules = [];
    responseValidationOpp;
    userPermission = false;
    
    bigVersionColumns = [
        {label: "FEATURE", fieldName: 'approvers', type: 'text', isNarrow: "slds-size_3-of-12"},
        {label: "CAPABILITY", fieldName: 'capabilityStatus', type: 'text', isNarrow: "slds-size_1-of-12 slds-p-right_small"},
        {label: "WORKFLOW", fieldName: 'worflowStatus', type: 'text', isNarrow: "slds-size_1-of-12 slds-p-right_small"},
        {label: "", fieldName: '', type: 'text', isNarrow: ""},
        {label: "Approver", fieldName: 'approverName', type: 'text', isNarrow: ""},
        {label: "TASK", fieldName: 'taskName', type: 'url', isNarrow: ""},
        {label: "TASK STATUS", fieldName: 'taskStatus', type: 'text', isNarrow: ""},
        {label: "START DATE", fieldName: 'taskStart', type: 'text', isNarrow: ""},
        {label: "END DATE", fieldName: 'taskEnd', type: 'text', isNarrow: ""},
        {label: "RESULT", fieldName: 'taskResult', type: 'text', isNarrow: ""}
    ];
    
    smallVersionColumns = [
        {label: "FEATURE", fieldName: 'approvers', type: 'text', isNarrow: "slds-size_3-of-12"},
        {label: "CAPABILITY", fieldName: 'capabilityStatus', type: 'text', isNarrow: "slds-size_1-of-12 slds-p-right_small"},
        {label: "WORKFLOW", fieldName: 'worflowStatus', type: 'text', isNarrow: "slds-size_1-of-12 slds-p-right_small"}
    ];
    
    //INFORMACION DEL PASSPORT
    @wire(getInformationPassport, { recordId: "$recordId" })
    wiredInformationPassportId(result) { 
        
        console.log('Dmt_passport_opportunity wiredInformationPassportId result ' +  JSON.stringify(result),2);
        
        this.wiredPassportResultId = result;
        const { error, data } = result;
        
        console.log('Dmt_passport_opportunity wiredInformationPassportId recordId ' +  JSON.stringify(this.recordId),2);
        
        console.log('Dmt_passport_opportunity wiredInformationPassportId data ' +  JSON.stringify(data),2);
        console.log('Dmt_passport_opportunity wiredInformationPassportId error ' +  JSON.stringify(error),2);
        
        if(data) {
            
            let dataParse = this.parseJson(data);
            this.passportId = dataParse.passportId;
            this.recordType = dataParse.recordType;
            this.userPermission = dataParse.userPermission;
            this.externalId = dataParse.externalId;
            this.groupMembers = dataParse.groupMembers;
            
            console.log('Dmt_passport_opportunity wiredInformationPassportId dataParse.passportId ' +  JSON.stringify(dataParse.passportId),2);
            
            this.refreshAllWires();      
        }else if(error) {
            this.handleError(error);
        }
    }
    
    //INFORMACION DEL PASSPORT
    @wire(getRecord, { recordId: "$passportId", fields: [
        PASSPORT_OPPORTUNITY_ID_FIELD, 
        PASSPORT_OBSOLETED_FIELD,
        PASSPORT_JSON_FIELD
    ] })
    wiredInformationPassport(result) { 
        
        console.log('Dmt_passport_opportunity wiredInformationPassport result ' +  JSON.stringify(result),2);
        
        this.wiredPassportResult = result;
        const { error, data } = result;
        
        console.log('Dmt_passport_opportunity wiredInformationPassport recordId ' +  JSON.stringify(this.recordId),2);
        
        console.log('Dmt_passport_opportunity wiredInformationPassport data ' +  JSON.stringify(data),2);
        console.log('Dmt_passport_opportunity wiredInformationPassport error ' +  JSON.stringify(error),2);
        
        if(data) {
            this.passport = data;
            this.showWarning = getFieldValue(data, PASSPORT_OBSOLETED_FIELD);
            this.opportunityId = getFieldValue(this.passport, PASSPORT_OPPORTUNITY_ID_FIELD);
            this.proccessPassport(getFieldValue(data, PASSPORT_JSON_FIELD));
            this.showfeaturesTable = getFieldValue(data, PASSPORT_JSON_FIELD) ? true : false; 
            this.updateFeatureType();
            this.features.map(feature => this.setFeatureProperties(feature));
            this.getCurrentStepFromFeaturesOpp();
        }else if(error) {
            this.handleError(error);
        }
    }
    
    //INFORMACION DE LA OPPORTUNIDAD 
    @wire(getRecord, { recordId: "$opportunityId", fields: [
        OPPORTUNITY_ID_EXTERNAL_FIELD, 
        OPPORTUNITY_RECORDTYPE_FIELD,
        OPPORTUNITY_STAGE_NAME_FIELD,
        OPPORTUNITY_CLIENT_TYPE_FIELD,
        OPPORTUNITY_CLIENT_ID_FIELD,
        OPPORTUNITY_CURRENCY_FIELD
    ] })
    wiredRecordOpportunity(result){
        
        console.log('Dmt_passport_opportunity wiredRecordOpportunity result ' +  JSON.stringify(result),2);
        
        this.wiredOpportunityResult = result;
        const { error, data } = result;
        
        console.log('Dmt_passport_opportunity wiredRecordOpportunity data ' +  JSON.stringify(data),2);
        console.log('Dmt_passport_opportunity wiredRecordOpportunity error ' +  JSON.stringify(error),2);
        
        if(data) {
            this.opportunity = data;
            this.refreshAllWires();
            this.features.map(feature => this.setFeatureProperties(feature));
        }else if(error) {
            this.handleError(error);
        }
    }
    
    @wire(getLastDay)
    wiredGetLastDay(result) {
        
        console.log('Dmt_passport_opportunity wiredGetLastDay result ' +  JSON.stringify(result),2);
        
        this.wiredGetLastDayResult = result;
        const { error, data } = result;
        
        console.log('Dmt_passport_opportunity wiredGetLastDay data ' +  JSON.stringify(data,2));
        console.log('Dmt_passport_opportunity wiredGetLastDay error ' +  JSON.stringify(error,2));
        
        if(data) {
            this.lastDate = data;
        }else if(error) {
            this.handleError(error);
        }
    }
    
    @wire(getFeatureRulesLwc)
    wiredFeatureRules(result) {
        
        console.log('Dmt_passport_opportunity wiredFeatureRules result ' +  JSON.stringify(result),2);
        
        this.wiredFeaturesRules = result;
        const { error, data } = result;
        
        console.log('Dmt_passport_opportunity wiredFeatureRules data ' +  JSON.stringify(data,2));
        console.log('Dmt_passport_opportunity wiredFeatureRules error ' +  JSON.stringify(error),2);
        
        if (data) {
            this.processFeaturesRules(data);
        } else if (error) {
            this.handleError(error);
        }
    }
    
    connectedCallback() {
        
        this.loadStylePromise();
        
        this.refreshContainerId = registerRefreshContainer(this, this.refreshContainer);
        this.registerErrorListener();
        this.registerSubscribe();
        this.onScrollPassport();
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
            this.handleError(error);
        });
    }
    
    onScrollPassport() {
        if(!this.isBigVersion) {
            window.onscroll = function () {
                var body = window.document.body; 
                var document = window.document.documentElement;
                document = (document?.clientHeight) ? document : body;
                let newTop = (INITIAL_OFFSET + document.querySelector(SLDS_PATH_CLASS)?.clientHeight) - Math.round(document.scrollTop);
                newTop = MINIMUM_TOP < newTop ? newTop : MINIMUM_TOP;
                if(document.scrollTop === 0){
                    document.querySelector(SLDS_PASSPORT_CLASS).style.removeProperty(TOP);
                }
                else{
                    document.querySelector(SLDS_PASSPORT_CLASS).style.setProperty(TOP, `${newTop}px`);
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
            this.handleError(error);
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
        
        getRecordNotifyChange([{ recordId: this.passportId }]);
    }
    
    processChangePassportEvent(changeEvent) {
        try {
            const recordIds = changeEvent.data.payload.ChangeEventHeader.recordIds; 
            if(recordIds.includes(this.passportId)){
                getRecordNotifyChange([{ recordId: this.passportId }]); 
            }
        } catch (error) {
            this.handleError(error);
        }
    }
    
    processChangeTaskEvent(changeEvent) {
        try {
            const operation = changeEvent.data.payload.Operation__c;
            
            if(operation === OPPERATION_CREATE_EVENT){
                this.refreshAllWires();
            }    
        } catch (error) {
            this.handleError(error);
        }
    }
    
    proccessPassport(newPayload) {
        
        console.log('Dmt_passport_opportunity proccessPassport newPayload ' +  JSON.stringify(newPayload,2));
        console.log('Dmt_passport_opportunity proccessPassport this.rawPayload ' +  JSON.stringify(this.rawPayload,2));
        
        if(this.rawPayload === newPayload) {
            return;
        }
        
        const parsedValue = this.parseJson(newPayload);
        
        if(parsedValue?.data !== undefined) {
            this.rawPayload = newPayload;
            
            console.log('Dmt_passport_opportunity proccessPassport parsedValue.data ' +  JSON.stringify(parsedValue.data,2));
            
            this.myPayload = parsedValue.data;
            
            console.log('Dmt_passport_opportunity proccessPassport this.myPayload.features ' +  JSON.stringify(this.myPayload.features,2));
            
            this.features = this.myPayload.features;
            this.features.map(feature => this.setFeatureProperties(feature));
            this.limitTestFeatures = this.filterListByField(this.features,MOTOR_DESC_FIELD,LIMIT_ENGINE_FEATURE);
            
            console.log('Dmt_passport_opportunity proccessPassport this.limitTestFeatures ' +  JSON.stringify(this.limitTestFeatures,2));
            
            this.globalValidationsFeatures = this.filterListByField(this.features,MOTOR_DESC_FIELD,SALESFORCE_FEATURE);
            
            console.log('Dmt_passport_opportunity proccessPassport this.globalValidationsFeatures ' +  JSON.stringify(this.globalValidationsFeatures,2));
            
            this.profitabilityFeatures = this.filterListByField(this.features,MOTOR_DESC_FIELD,PROFITABILITY_ENGINE_FEATURE);
            
            console.log('Dmt_passport_opportunity proccessPassport this.profitabilityFeatures ' +  JSON.stringify(this.profitabilityFeatures,2));
            
            let preFilterFeatures = this.filterListByField(this.features,MOTOR_DESC_FIELD,UNDEFINED_ENGINE_FEATURE);
            this.undefinedFeatures = this.filterListByField(preFilterFeatures,PASSPORT_SANCTION_FIELD,PASSPORT_SECTION_FEATURE);
            
            console.log('Dmt_passport_opportunity proccessPassport this.undefinedFeatures ' +  JSON.stringify(this.undefinedFeatures,2));
            
            this.approvalFeatures = this.filterListByField(this.features,PASSPORT_SANCTION_FIELD,APPROVAL_SECTION_FEATURE);
            
            this.readytocloseFeatures = this.filterListByField(this.features,PASSPORT_SANCTION_FIELD,READYTOCLOSE_SECTION_FEATURE);
            
            console.log('Dmt_passport_opportunity proccessPassport this.approvalFeatures ' +  JSON.stringify(this.approvalFeatures,2));
        }
        else{
            this.showSpinner = false;
        }
    }
    
    
    setFeatureProperties(feature) {
        
        console.log('Dmt_passport_opportunity setFeatureProperties feature ' +  JSON.stringify(feature,2));
        
        this.featuresIds.push(feature.id);
        feature.isValid = feature.isValid !== undefined ? feature.isValid : true;
        feature.capabilityIsValid = feature.capabilityIsValid !== undefined ? feature.capabilityIsValid : true;
        feature.workflowIsValid = feature.workflowIsValid !== undefined ? feature.workflowIsValid : true;
        feature.checkStatusProposal = this.checkStatusProposal;
        feature.checkStatusApproval = this.checkStatusApproval;
        feature.userPermission = this.userPermission;
        feature.featureIsValid = true;
        feature.opportunityId = this.externalId;
        
        console.log('Dmt_passport_opportunity setFeatureProperties feature.isValid ' +  feature.isValid);
        console.log('Dmt_passport_opportunity setFeatureProperties feature.capabilityIsValid ' +  feature.capabilityIsValid);
        console.log('Dmt_passport_opportunity setFeatureProperties feature.workflowIsValid ' +  feature.workflowIsValid);
        
        feature.showTrafficLight = feature.stateName != WHITE_STATE && feature.stateName != GRAY_STATE && feature.stateName != BLANK_STATE && feature.stateName != undefined;
        feature.showErrorCapability = feature.stateName != WHITE_STATE && feature.validations?.length > 0;
        
        console.log('Dmt_passport_opportunity setFeatureProperties feature.showTrafficLight ' +  feature.showTrafficLight);
        console.log('Dmt_passport_opportunity setFeatureProperties feature.showErrorCapability ' +  feature.showErrorCapability);
        
        feature = this.formatValidation(feature);    
        
        feature.request = feature.passportSanction?.toUpperCase() !== APPROVAL_STATE;
        
        console.log('Dmt_passport_opportunity setFeatureProperties this.opportunity ' +  JSON.stringify(this.opportunity));
        
        feature.dmtCurrency = getFieldValue(this.opportunity, OPPORTUNITY_CURRENCY_FIELD);
        
        console.log('Dmt_passport_opportunity setFeatureProperties getFieldValue(this.opportunity, OPPORTUNITY_CURRENCY_FIELD) ' +  JSON.stringify(getFieldValue(this.opportunity, OPPORTUNITY_CURRENCY_FIELD)));
        console.log('Dmt_passport_opportunity setFeatureProperties feature.dmtCurrency ' +  feature.dmtCurrency);
        
        feature.showRequestButton = (feature.request && feature.checkStatusProposal && feature.userPermission) || feature.checkStatusApproval;
        
        console.log('Dmt_passport_opportunity setFeatureProperties feature.showRequestButton ' +  feature.showRequestButton);
        console.log('Dmt_passport_opportunity setFeatureProperties feature.tasks? ' +  feature?.tasks);
        
        console.log('Dmt_passport_opportunity setFeatureProperties final feature ' +  JSON.stringify(feature,2));  
    }
    
    formatValidation(feature) {
        
        console.log('Dmt_passport_opportunity formatValidation feature ' +  JSON.stringify(feature,2));
        
        feature.validations?.forEach(validation => {
            
            console.log('Dmt_passport_opportunity formatValidation validation ' +  JSON.stringify(validation,2));
            
            if (validation.state == RED_STATE) {
                
                let featureName = this.featureRules[validation.message] === undefined ? validation.message : this.featureRules[validation.message];
                
                if(validation.name.includes(FEATURE_MANDATORY)){
                    
                    feature.showErrorFeature = true;
                    feature.featureIsValid = false;
                    feature.featureErrorMessage = feature.errorMessage === undefined ? featureName : feature.errorMessage + ' ' + featureName;
                }
                else if(validation.name.includes(WORKFLOW_MANDATORY)){
                    feature.workflowIsvalidationalid = false;
                    feature.workflowErrorMessage = feature.workflowErrorMessage === undefined ? featureName : feature.workflowErrorMessage + ' ' + featureName;
                }
                else if(validation.name.includes(CAPABILITY_MANDATORY)){
                    feature.capabilityIsValid = false;
                    feature.capabilityErrorMessage = feature.capabilityErrorMessage === undefined ? featureName : feature.capabilityErrorMessage + ' ' + featureName;
                }
            }  
        });
        
        
        console.log('Dmt_passport_opportunity formatValidation final feature ' +  JSON.stringify(feature,2));
        
        return feature;
    }
    
    getCurrentStepFromFeaturesOpp() {
        
        console.log('Dmt_passport_opportunity getCurrentStepFromFeaturesOpp this.featuresIds ' + this.featuresIds);
        console.log('Dmt_passport_opportunity getCurrentStepFromFeaturesOpp this.externalId ' + this.externalId);
        
        getCurrentStepFromFeaturesOpp({
            featuresIds: this.featuresIds,
            oppExternalId: this.externalId
        }).then(response => {
            
            console.log('Dmt_passport_opportunity getCurrentStepFromFeaturesOpp response ' + JSON.stringify(response));
            
            if(response !== undefined){
                
                let currentTaks = JSON.parse(JSON.stringify(response));
                const taskMap = new Map();
                
                const allTasks = currentTaks.flatMap(currentTask => {
                    const isClosedOrFinished = ['Closed', 'Finished'].includes(currentTask.itemKey);
                    return isClosedOrFinished ? [...currentTask.subitems] : [currentTask];
                });
                
                console.log('Dmt_passport_opportunity getCurrentStepFromFeaturesOpp allTasks ' + JSON.stringify(allTasks));
                
                allTasks.forEach(taskItem => {
                    
                    console.log('Dmt_passport_opportunity getCurrentStepFromFeaturesOpp taskItem.featureId ' + JSON.stringify(taskItem.featureId));
                    console.log('Dmt_passport_opportunity getCurrentStepFromFeaturesOpp taskItem ' + JSON.stringify(taskItem));
                    taskMap.set(taskItem.featureId, taskItem);
                });
                
                console.log('Dmt_passport_opportunity getCurrentStepFromFeaturesOpp taskMap.size ' + JSON.stringify(taskMap.size));
                console.log('Dmt_passport_opportunity getCurrentStepFromFeaturesOpp Array.from(taskMap.entries()) ' + JSON.stringify(Array.from(taskMap.entries())));


                this.readytocloseFeatures = this.formatCurrentCase(this.readytocloseFeatures,taskMap);
                this.approvalFeatures = this.formatCurrentCase(this.approvalFeatures,taskMap);
            }
            
        }).catch((error) => {
            this.handleError(error);
        });
    }
    
    formatCurrentCase(features,taskMap) {

        const featuresAux = [];
        
        features.forEach(feature => {
            
            feature = { ...feature, hasSftask: false };
            const tasks = feature?.tasks;
            
            console.log('Dmt_passport_opportunity formatCurrentCase feature?.tasks ' + JSON.stringify(feature?.tasks));
            
            
            if (tasks?.length > 0) {
                const firstTask = tasks[0];
                const hasApprovers = firstTask.approvers?.length > 0;
                
                if (hasApprovers) {
                    feature.currentTask = {
                        ...firstTask,
                        status: 'Not started',
                        approver: firstTask.approvers[0].name
                    };
                    feature.showHistoryButton = false;
                } else {
                    feature.currentTask = null;
                }
                
                console.log('Dmt_passport_opportunity formatCurrentCase feature.id ' + JSON.stringify(feature.id));
                
                const currentTask = taskMap.get(feature.id);
                
                console.log('Dmt_passport_opportunity formatCurrentCase currentTask ' + JSON.stringify(currentTask));
                
                if (currentTask) {
                    
                    if (currentTask.startDate) currentTask.startDate = this.formatDate(currentTask.startDate);
                    if (currentTask.endDate) currentTask.endDate = this.formatDate(currentTask.endDate);
                    
                    currentTask.openModal = currentTask.step?.urlValue === 'c-modal-container';
                    
                    feature.hasSftask = true;
                    feature.currentTask = currentTask;
                    feature.hascurrentTask = true;
                    feature.isApprover = this.groupMembers.includes(currentTask.approver);
                    feature.isNotFinishedTask = currentTask.caseStatus != 'Finished';

                    console.log('Dmt_passport_opportunity formatCurrentCase feature.isNotFinishedTask ' + JSON.stringify(feature.isNotFinishedTask));

                    feature.showHistoryButton = currentTask.taskSize > 1;
                    
                    feature.workflowColor = this.getWorkflowColor(currentTask, feature);

                    console.log('Dmt_passport_opportunity formatCurrentCase feature.workflowColor ' + JSON.stringify(feature.workflowColor));
                }
            }
            
            console.log('Dmt_passport_opportunity formatCurrentCase return feature ' + JSON.stringify(feature));  
            featuresAux.push(feature);
        });

        return featuresAux;
    }
    
    getWorkflowColor(task, feature) {
        
        console.log('Dmt_passport_opportunity getWorkflowColor task ' + JSON.stringify(task));
        console.log('Dmt_passport_opportunity getWorkflowColor feature ' + JSON.stringify(feature));

        console.log('Dmt_passport_opportunity getWorkflowColor task.caseStatus ' + JSON.stringify(task.caseStatus));
        console.log('Dmt_passport_opportunity getWorkflowColor task.rawresult ' + JSON.stringify(task.rawresult));
    
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

    formatDate(dateToFormat){
        var [date, hour] = (dateToFormat).split(" ");
        var [day, mnt, year] = date.split("/");
        return day+'-'+mnt+'-'+year;
    }
    
    filterListByField(list,field,value) {
        
        console.log('Dmt_passport_opportunity filterListByField field ' +  JSON.stringify(field,2));
        console.log('Dmt_passport_opportunity filterListByField value ' +  JSON.stringify(value,2));
        
        return list?.filter(item => item[field] == value) || [];
    }
    
    processFeaturesRules(featuresRulesList) {
        featuresRulesList.forEach((featureRule) => {
            this.featureRules[featureRule.DMT_Field__c] = featureRule.dmt_message__c;
        });
    }
    
    handleError(error){
        
        console.error(ERROR_MESSAGE,JSON.stringify(error));
        
        let message = UNKNOWN_MESSAGE;
        
        if (Array.isArray(error.body)) {
            message = error.body.map((e) => e.message).join(", ");
        } else if (typeof error?.body?.message === STRING_TYPE) {
            message = error.body.message;
        } else if (typeof error === STRING_TYPE) {
            message = error;
        }else if(Array.isArray(error) && error.length > 0 && typeof error[0] === STRING_TYPE){
            message =  this.csLabels.requiredMsg+' '+error.join(", ")+'.';
        }
        
        this.messageError = message;
        this.setToast(ERROR_PASSPORT_MESSAGE,message,ERROR_MESSAGE);
        this.showSpinner = false;
    }
    
    handleFetchClients(data) {
        const params = {
            selectedTab: data.selectedTab,
            clientId: data.clientId,
            lCountries: data.countries,
            searchDate: data.searchDate,
            clientPositionsType: data.clientPositionsType,
            page: data.page + 1,
            pageSize: data.pageSize,
            customerId: data.customerId
        }
        this.fetchData(params);
    }
    
    setToast(title,message,variant) {
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
            this.handleError(error);
            return null;
        }
    }
    
    async callService() {
        
        console.log('Dmt_passport_opportunity callService ');
        console.log('Dmt_passport_opportunity callService this.opportunityId ' + this.opportunityId);
        
        await this.validateOppBeforePassportService();
        
        if(!this.responseValidationOpp?.success){
            this.handleError(this.responseValidationOpp?.message?.[0]);
            return;
        }
        
        this.refreshAllWires();
        
        this.clientType = getFieldValue(this.opportunity, OPPORTUNITY_CLIENT_TYPE_FIELD);
        
        console.log('Dmt_passport_opportunity callService this.clientType ' + this.clientType);
        
        this.clientId = getFieldValue(this.opportunity, OPPORTUNITY_CLIENT_ID_FIELD);
        
        console.log('Dmt_passport_opportunity callService clientId ' + this.clientId);
        
        const params = {
            selectedTab: 'passport',
            clientId: this.clientType === CUSTOMER_STRG ? undefined : this.clientId,
            lCountries: ["ALL"],
            searchDate: this.lastDate,
            clientPositionsType: this.clientType !== CUSTOMER_STRG ? 'Y' : 'N',
            page: 1,
            pageSize: '100',
            customerId: this.clientType !== CUSTOMER_STRG ? undefined : this.clientId,
        };
        
        console.log('Dmt_passport_opportunity callService params ' + JSON.stringify(params));
        
        this.showSpinner = true;
        this.groupedData = params.page === 1 ? [] : this.groupedData;
        
        fetchData(params).then( data => {
            if (data.success) {
                
                console.log('Dmt_passport_opportunity callService data ' + JSON.stringify(data));
                
                this.groupedData = this.groupedData.concat(data.data);
                if (data.pagination.totalPages > data.pagination.page) {
                    this.handleFetchClients(params);
                } else {
                    this.buttonCallPassport(this.groupedData);  
                }
            } else {   
                this.handleError( data.errorMessage);
            }
        }).catch((error) => {
            this.handleError(error);
        });   
    }
    
    async buttonCallPassport(data){
        
        console.log('Dmt_passport_opportunity buttonCallPassport data' + JSON.stringify(data));
        
        if(data){
            buttonCallPassport({
                recordId: this.recordId,
                clientesGroup: JSON.stringify(data)
            }).then(response => {
                
                console.log('Dmt_passport_opportunity buttonCallPassport response' + JSON.stringify(response));
                
                let result = JSON.parse(response);
                this.showSpinner = false;  
                if(!result.result){
                    this.handleError(result.message);
                }
            }).catch((error) => {
                this.handleError(error);
            })
        }
        else {
            this.handleError(this.csLabels.clientsValidationMsg1);
        }
    }
    
    async validateOppBeforePassportService() {
        
        console.log('Dmt_passport_opportunity validateOppBeforePassportService');
        
        this.responseValidationOpp = await validateOppBeforePassport({ oppId : this.opportunityId });
        
        console.log('Dmt_passport_opportunity validateOppBeforePassportService this.responseValidationOpp ' + JSON.stringify(this.responseValidationOpp));
        return this.responseValidationOpp;
    }
    
    updateFeatureType() {
        
        console.log('Dmt_passport_opportunity updateFeatureType');
        
        let arrayFeaturesApproverId = [];
        
        console.log('Dmt_passport_opportunity updateFeatureType this.features ' + JSON.stringify(this.features));
        
        this.features.forEach(feature => {
            
            console.log('Dmt_passport_opportunity updateFeatureType feature ' + JSON.stringify(feature));
            console.log('Dmt_passport_opportunity updateFeatureType feature.passportSanction?.toUpperCase() ' + JSON.stringify(feature.passportSanction?.toUpperCase()));
            console.log('Dmt_passport_opportunity updateFeatureType feature?.tasks ' + JSON.stringify(feature?.tasks));       
            console.log('Dmt_passport_opportunity updateFeatureType feature?.tasks?.[0]?.approvers?.[0]?.id ' + JSON.stringify(feature?.tasks?.[0]?.approvers?.[0]?.id));     
            
            if(feature?.passportSanction == APPROVAL_SECTION_FEATURE && feature?.tasks?.[0]?.approvers?.[0]) {
                
                console.log('Dmt_passport_opportunity updateFeatureType feature?.tasks?.[0]?.approvers?.[0]?.id ' + JSON.stringify(feature?.tasks?.[0]?.approvers?.[0]?.id));
                arrayFeaturesApproverId.push(feature?.tasks?.[0]?.approvers?.[0]?.id);
            } 
        });
        
        console.log('Dmt_passport_opportunity updateFeatureType arrayFeaturesApproverId ' + JSON.stringify(arrayFeaturesApproverId));
        
        if(arrayFeaturesApproverId.length > 0 ){ 
            return getFeatureTypeByApproverType({featuresApproverIds: arrayFeaturesApproverId}).then(response => {
                if(response !== undefined){
                    response =JSON.parse(JSON.stringify(response));
                    this.features.forEach(feature => {
                        
                        if(feature.passportSanction == APPROVAL_SECTION_FEATURE && feature.tasks[0]?.approvers[0]?.id){
                            feature.featureType = response[feature.tasks[0]?.approvers[0]?.id];
                            console.log('Dmt_passport_opportunity updateFeatureType Feature Type for feature ' + feature.name + ': ' + feature.featureType);
                            console.log('Dmt_passport_opportunity updateFeatureType Approver Id for feature ' + feature.name + ': ' + feature.tasks[0]?.approvers[0]?.id);
                        }
                    });
                }
                this.features = [...this.features];
            }).catch((error) => {
                this.handleError(error);
            });
        }
    }
    
    async initRefreshTasksInProgress() {
        
        console.log('Dmt_passport_opportunity initRefreshTasksInProgress');
        
        this.featuresIds = [];
        
        this.features.forEach(feature => {
            //If feature doest have approver or task with value workflow dont apply
            if (feature.id != null && feature.tasks?.length > 0 && feature.tasks[0]?.approvers?.length > 0) {
                this.featuresIds.push(feature.id);
            }
            if(feature.tasks === undefined || feature.tasks.length === 0){
                feature.tasks = undefined;
            }
        });
        
        console.log('Dmt_passport_opportunity this.featuresIds ' + this.featuresIds);
        console.log('Dmt_passport_opportunity this.opportunityId ' + this.opportunityId);
        console.log('Dmt_passport_opportunity this.externalId ' + this.externalId);
        
        this.getCurrentStepFromFeaturesOpp();
    }        
    
    refreshAllWires() {
        
        console.log('Dmt_passport_opportunity refreshAllWires INITIAL');
        
        console.log('Dmt_passport_opportunity refreshAllWires recordId ' + this.recordId );
        console.log('Dmt_passport_opportunity refreshAllWires opportunityId ' + this.opportunityId );
        console.log('Dmt_passport_opportunity refreshAllWires passportId ' + this.passportId );
        
        refreshApex(this.wiredOpportunityResult);
        refreshApex(this.wiredPassportResult);
        refreshApex(this.wiredGetLastDayResult);
        refreshApex(this.wiredFeaturesRules);
        console.log('Dmt_passport_opportunity refreshAllWires FINISH');
    }
}