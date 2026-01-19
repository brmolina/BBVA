import { LightningElement, api, track, wire } from 'lwc';
import getAllsValidate from '@salesforce/apex/DMT_Rules_Feature.getAllsValidate';
import getStepsFromFeature from '@salesforce/apex/DMT_Case_Steps_Controller.getStepsFromFeature';
import getCurrentStepFromFeatures from '@salesforce/apex/DMT_Case_Steps_Controller.getCurrentStepFromFeatures';
import getCurrentStepFromFeaturesOpp from '@salesforce/apex/DMT_Case_Steps_Controller.getCurrentStepFromFeaturesOpp';
import buttonCallPassport from '@salesforce/apex/DMT_Passport_Handler.buttonCallPassport';
import startCase from '@salesforce/apex/DMT_Passport_Handler.startCase';
import getLastDay from '@salesforce/apex/DMT_Passport_Handler.getLastDay';
import pubsub from "omnistudio/pubsub";
import getFeatureRulesLWC from '@salesforce/apex/DMT_Passport_Handler.getFeatureRulesLWC';
import passportModal from 'c/dmt_passport_modal';
import {loadStyle } from 'lightning/platformResourceLoader';
import overflowyscroll from '@salesforce/resourceUrl/DMT_overflowyscroll';

import getInformationPassport from '@salesforce/apex/DMT_Passport_Handler.getInformationPassport';
import validateOppBeforePassport from '@salesforce/apex/DMT_Passport_Handler.validateOppBeforePassport';
import getFeatureTypeByApproverType from '@salesforce/apex/DMT_Passport_Handler.getFeatureTypeByApproverType';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecord, getFieldValue, getRecordNotifyChange } from "lightning/uiRecordApi";
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent,  registerRefreshContainer, unregisterRefreshContainer, REFRESH_ERROR, REFRESH_COMPLETE, REFRESH_COMPLETE_WITH_ERRORS } from "lightning/refresh";
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import OBSOLETED_FIELD from "@salesforce/schema/Passport__c.DMT_Is_Obsoleted_Passport_Save__c";
import JSON_FIELD from "@salesforce/schema/Passport__c.DMT_Passport_Save__c";
import STATUSLINE_FIELD from "@salesforce/schema/DMT_Line__c.Status__c";
import CLOSEDLINE_FIELD from "@salesforce/schema/DMT_Line__c.Closed__c";
import CLIENTTYPE_FIELD from "@salesforce/schema/DMT_Line__c.Client_Type__c";
import CLIENTID_FIELD from "@salesforce/schema/DMT_Line__c.Client__c";
import AMOUNT_FIELD from "@salesforce/schema/DMT_Line__c.Amount__c";
import LASTLVLID_FIELD from "@salesforce/schema/DMT_Line__c.DMT_LastLevelId__c";
import CURRENCYLINE_FIELD from "@salesforce/schema/DMT_Line__c.CurrencyIsoCode";
import STATUSOPPORTUNITY_FIELD from "@salesforce/schema/Opportunity.StageName";
import CLIENTTYPEOPPORTUNITY_FIELD from "@salesforce/schema/Opportunity.DMT_Client_Type__c";
import CLIENTIDOPPORTUNITY_FIELD from "@salesforce/schema/Opportunity.AccountId";
import LINEVALIDATION_MSG_1 from '@salesforce/label/c.DMT_PassportLineValidationMsg1';
import ClientsVALIDATION_MSG_1 from '@salesforce/label/c.DMT_PassportErrorMsgClientsService';
import Success_MSG from '@salesforce/label/c.Success';
import Required_MSG from '@salesforce/label/c.DMT_PassportMsgRequired';
const CUSTOMER_STRG = 'Customer';
import { CurrentPageReference } from 'lightning/navigation';


export default class Dmt_passport extends LightningElement {

  myPayload = [];
  wrapper = [];
  refreshContainerID;
  responseValidationOpp= [];

  @api isBigVersion;
  @api recordId;

  @api
  get getservice() {
    return this.getservicevalue;
  }
  set getservice(value) {
    this.getservicevalue = value;
    if(value.toLowerCase() == 'true'){
      this.callService();
    }
  }

  limits;
  featureName;
  featureLight;
  validations = [];
  childProps;
  componentConstructor;
  _showSpinner = true;
  @track messageError;
  userPermission = false;
  lastDate;
  recordType;

  //Visualización de Modales
  isTaskModalOpen = false;
  isModalOpen = false;
  graphicModal = false;
  errorModal = false;
  noShowInfo = false;

  //Identificacion del registro y gestion de warnings
  externalId;
  passportId;
  tasksId;
  wiredInformationPassportResult;
  @track showWarning = false;
  rawPayload;
  @track lineStatus;
  @track lineClosed;
  lineId;
  opportunityId;
  showfeaturesTable = false;
  @track clientType;
  handleEventObj;
  featureRules = {};
  @track amountLine;
  @track lastLvlLine;
  @track currencyIsoCode;
  additional_Restrictions;
  previousOpportunityStatus;
  statusRefreshInProgress = false;

  //Change Data Capture
  channelNamePassport = '/data/Passport__ChangeEvent';
  subscriptionPassport = {}; // holds subscription, used for unsubscribe
  channelNameTask = '/event/DMT_Task__e';
  subscriptionTask = {}; // holds subscription, used for unsubscribe

  wiredLineResult; // holds the line information
  wiredPassportResult;

  //custom labels for text and translations showed in the component
  csLabels = {
    lineValidationMsg1: LINEVALIDATION_MSG_1,
    clientsValidationMsg1: ClientsVALIDATION_MSG_1,
    successMsg: Success_MSG,
    requiredMsg: Required_MSG,
  };

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

  @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {            
            // Check standard and custom state parameters
            this.recordId = currentPageReference.state?.recordId || currentPageReference.state?.c__recordId || currentPageReference.attributes?.recordId;
        }
    }

  @api
  get isBig() {
    return (this.isBigVersion === 'true');
  }

  get columns() {
    return this.isBig == true ? this.bigVersionColumns: this.smallVersionColumns;
  }

  get columnsWithClass(){
    return this.columns.map(col => ({
      ...col,
      class: `slds-is-sortable _slds-is-resizable slds-text-title--caps fixed-header fixed-row-header ${col.isNarrow}`
    }));
  }

  get checkStatusProposal(){
    return this.lineStatus === 'Proposal';
  }

  get checkStatusApproval(){
    return this.lineStatus === 'Approval' || this.lineStatus === 'Ready to close';
  }

  get showAuditDate(){
    return this.myPayload !== undefined ? new Date(this.myPayload?.auditDate) : '';
  }

  get showProfitabilityChart(){
    return this.graphicModal && this.profitability?.results?.length > 0;
  }

  //CALLBACKS
  connectedCallback() {
    loadStyle(this, overflowyscroll);
    this.refreshContainerID = registerRefreshContainer(this, this.refreshContainer);
    this.registerErrorListener();
    this.registerSubscribe();
    if(this.isBigVersion !== 'true'){
      window.onscroll = function (){

        var body = window.document.body; //IE 'quirks'
        var document = window.document.documentElement; //IE with doctype
        document = (document?.clientHeight) ? document : body;console.log('document', document);console.log('body', body);
        let newTop = (330 + document.querySelector(".slds-path")?.clientHeight) - Math.round(document.scrollTop);console.log('newTop', newTop);
        newTop = 215 < newTop ? newTop : 215;
        if(document.scrollTop === 0){
          document.querySelector(".slds-passport").style.removeProperty('top');
        }
        else{
          document.querySelector(".slds-passport").style.setProperty('top', `${newTop}px`);
        }
      };
    }
  }

  disconnectedCallback() {
    unsubscribe(this.subscriptionPassport, () => console.log('Unsubscribed to change events Passport.'));
    unsubscribe(this.subscriptionTask, () => console.log('Unsubscribed to change events Task.'));
    pubsub.unregister('callPassportLWC', this.handleEventObj);
    unregisterRefreshContainer(this.refreshContainerID);
  }

  refreshContainer(refreshPromise) {
    return refreshPromise.then((status) => {
      console.log(status === REFRESH_COMPLETE);
    });
  }

  @wire(getRelatedListRecords, {
    parentRecordId: "$lineId",
    relatedListId: 'Risk_Line_Terms__r',
    fields: ['DMT_Risk_Line_Term__c.Id']
  }) relatedRiksList;

  //WIREDS
  @wire(getRecord, { recordId: "$passportId", fields: [OBSOLETED_FIELD, JSON_FIELD] })
  wiredRecordPassport(result){
    this.wiredPassportResult = result;
    const { error, data } = result;
    if(error){
      this.handleError(error);
    }
    else if(data){
      let tempPayload = getFieldValue(data, JSON_FIELD);
      if (!tempPayload || tempPayload === '') {
        this.showWarning = false;
      }else{
        this.showWarning = getFieldValue(data, OBSOLETED_FIELD);
      }

      if(this.rawPayload !== tempPayload){
        this.proccessPayload(tempPayload);
      }

      refreshApex(this.relatedRiksList);
      refreshApex(this.wiredLineResult);
    }
  }

  //WIREDS
  @wire(getRecord, { recordId: "$lineId", fields: [STATUSLINE_FIELD, CLIENTTYPE_FIELD, CLIENTID_FIELD, AMOUNT_FIELD, LASTLVLID_FIELD, CLOSEDLINE_FIELD, CURRENCYLINE_FIELD] })
  wiredRecordLine(result){
    this.wiredLineResult = result;
    const { error, data } = result;
    if(error){
      this.handleError(error);
    }
    else if(data){
      this.clientType = getFieldValue(data, CLIENTTYPE_FIELD);
      this.clientId = getFieldValue(data, CLIENTID_FIELD);
      this.amountLine = getFieldValue(data, AMOUNT_FIELD);
      this.lastLvlLine = getFieldValue(data, LASTLVLID_FIELD);
      console.log('logg in line','amountLine: ' + this.amountLine + ' lastLvlLine: ' + this.lastLvlLine + ' relatedRiksList:'+ this.relatedRiksList);
      if(this.lineStatus !== undefined && (this.lineStatus !== getFieldValue(data, STATUSLINE_FIELD) || this.lineClosed !== getFieldValue(data, CLOSEDLINE_FIELD)) && this.isBigVersion !== 'true'){
        this.handleStatusChange();
      }

      this.lineStatus = getFieldValue(data, STATUSLINE_FIELD);
      this.lineClosed = getFieldValue(data, CLOSEDLINE_FIELD);
      this.currencyIsoCode = getFieldValue(data, CURRENCYLINE_FIELD);
      //refreshApex(this.relatedRiksList);
      //refreshApex(this.wiredLineResult);
    }
  }

  //WIREDS
  @wire(getRecord, { recordId: "$opportunityId", fields: [STATUSOPPORTUNITY_FIELD, CLIENTTYPEOPPORTUNITY_FIELD, CLIENTIDOPPORTUNITY_FIELD] })
  wiredRecordOpportunity({ error, data }){
    if(error){
      this.handleError(error);
    }
    else if(data){
      const newStatus = getFieldValue(data, STATUSOPPORTUNITY_FIELD);

      this.clientType = getFieldValue(data, CLIENTTYPEOPPORTUNITY_FIELD);
      this.clientId = getFieldValue(data, CLIENTIDOPPORTUNITY_FIELD);

      if (this.previousOpportunityStatus !== undefined && this.previousOpportunityStatus !== newStatus && this.isBigVersion !== 'true'){
        this.handleStatusChange();
      }

      this.previousOpportunityStatus = newStatus;
      this.lineStatus = newStatus;
    }
  }

  @wire(getInformationPassport, { recordId: "$recordId" })
  wiredInformationPassport(result) {
    console.log('recordId in wiredInformationPassport');
    this.wiredInformationPassportResult = result;
    if(result.error){
      this.handleError(result.error);
    }
    else if (result.data) {
      let response = JSON.parse(result.data);
      this.externalId = response.externalId;
      console.log('external Id', this.externalId);
      this.passportId = response.passportId;
      this.lineId = response.lineId;
      console.log('line Id', this.lineId);
      this.opportunityId = response.opportunityId;
      console.log('opp Id', this.opportunityId);
      this.tasksId = JSON.parse(response.tasksId);
      this.userPermission = response.userPermission;
      this.recordType = response.recordType;
      this.groupMembers = response.groupMembers;
      this.additional_Restrictions = response.additional_Restrictions;
    }
  }

  @wire(getLastDay)
  wiredGetLastDay(result) {

    if(result.error){
      this.handleError('HPG service unavailable');
    }
    else if (result.data) {
      this.lastDate = result.data;
    }
  }

  @wire(getFeatureRulesLWC)
  wiredFeatureRules({ data, error }) {
    if (data) {
      data.forEach((d) => {
        this.featureRules[d.DMT_Field__c] = d.dmt_message__c;
      });

    } else if (error) {
      this.handleError(error);
    }
  }

  handleStatusChange() {
    if (this.statusRefreshInProgress){
      return;
    }

    this.statusRefreshInProgress = true;

    this.dispatchEvent(new RefreshEvent());
    this.callService()
    .finally(() => {
      this.statusRefreshInProgress = false;
    });
  }


  proccessPayload(newPayload) {
    const parsedValue = this.parseJson(newPayload);

    if(parsedValue?.data !== undefined){
      this.rawPayload = newPayload;
      this.myPayload = parsedValue.data;
      this.wrapper = [];
      try {
        this.createrWrapper();
        this.sortFeaturesByPassportSanction();

        this._showSpinner = true; // Ensure spinner is on

        Promise.all([
          new Promise((resolve, reject) => {
            this.checkWorkflowStatus()
              .then(result => resolve(result))
              .catch(error => reject(error));
          }),
          new Promise((resolve, reject) => {
            this.initRefreshTasksInProgress()
              .then(result => resolve(result))
              .catch(error => reject(error));
          })
        ])
        .then(() => {
          return this.updateFeatureType();
        })
        .then(() => {
          this.showfeaturesTable = true;
          this._showSpinner = false;
        })
        .catch(error => {
          this.handleError(error);
          this._showSpinner = false;
        });
      }
      catch(error){
        this.handleError(error);
      }
    }
    else{
      this._showSpinner = false;
    }
  }

  createrWrapper(){

    if (!this.myPayload || !this.myPayload.features) {
      return;
    }

    this.myPayload.features.forEach(ftr => {
      if(ftr.motorDesc === 'Salesforce'){
        this.wrapper.push({id: ftr.id, name: ftr.name, passportSanction: ftr.passportSanction, motorDesc: ftr.motorDesc, stateName: ftr.stateName, active: ftr.active, validations: ftr.validations, idProccess: ftr.id});
      }
      /*else if(this.recordType === 'OtherProducts')
      {
        ftr.lastLevels.forEach(lv =>
        {
          this.wrapper.push({id: ftr.id, name: `${ftr.name}/${lv.lastLevelId}`, passportSanction: ftr.passportSanction, motorDesc: ftr.motorDesc, stateName: lv.stateName, active: ftr.active, validations: lv.validations, tasks: lv.tasks, consumptionLimits: lv.consumptionLimits, idProccess: `${ftr.id}-${lv.lastLevelId}`});
        });
      }*/
      else{
        this.wrapper.push({ id: ftr.id, name: ftr.name, passportSanction: ftr.passportSanction, motorDesc: ftr.motorDesc, stateName: ftr.stateName, active: ftr.active, validations: ftr.validations, tasks: ftr.tasks, consumptionLimits: ftr.consumptionLimits, idProccess: ftr.id, profitability: ftr.profitability, orderNumber: ftr.orderNumber });
      }

    });
  }

  sortFeaturesByPassportSanction() {
    let passportSanction;
    let featuresTemp = [];

    this.wrapper.sort((a, b) => {
      const nameA = a.passportSanction?.toUpperCase();
      const nameB = b.passportSanction?.toUpperCase();
      if (nameA === 'APPROVAL' && nameB === 'PASSPORT') {
        return 1;
      }
      if (nameA === 'PASSPORT' && nameB === 'APPROVAL') {
        return -1;
      }
      return 0;
    });

    this.wrapper.forEach((ftr, indexftr) => {
      if (indexftr === 0) {
        ftr.variadito = true;
        passportSanction = ftr.passportSanction?.toUpperCase();
        if (passportSanction !== 'PASSPORT') {
          featuresTemp.push({ changeSanction: true, id: 'changeSanction', name: passportSanction });
        }
      }

      if (passportSanction !== ftr.passportSanction?.toUpperCase()) {
        passportSanction = ftr.passportSanction?.toUpperCase();
        featuresTemp.push({ changeSanction: true, id: 'changeSanction', name: passportSanction === 'APPROVAL' ? 'APPROVAL PROCESS' : passportSanction });
      }
      featuresTemp.push(ftr);
    });

    this.wrapper = featuresTemp;
  }

  setFeatureProperties(ftr) {
    // Defaults to avoid undefined -> falsy in template
    ftr.isValid = ftr.isValid !== undefined ? ftr.isValid : true;
    ftr.capabilityIsValid = ftr.capabilityIsValid !== undefined ? ftr.capabilityIsValid : true;
    ftr.workflowIsValid = ftr.workflowIsValid !== undefined ? ftr.workflowIsValid : true;

    ftr.showTrafficLight = ftr.stateName !== 'WHITE' && ftr.stateName !== 'GRAY' && ftr.stateName !== 'BLANK' && ftr.stateName !== undefined;
    ftr.ShowErrorCapability = ftr.stateName !== 'WHITE';

    ftr.validations?.forEach(v => {
      if (v.state === 'RED') {
        if(v.name.includes('featureMandatory')){
          let featureName = this.featureRules[v.message] === undefined ? v.message : this.featureRules[v.message];
          ftr.isValid = false;
          ftr.errorMessage = ftr.errorMessage === undefined ? featureName : ftr.errorMessage + ' ' + featureName;
        }
        else if(v.name.includes('workflowMandatory')){
          let featureName = this.featureRules[v.message] === undefined ? v.message : this.featureRules[v.message];
          ftr.workflowIsValid = false;
          ftr.workflowErrorMessage = ftr.workflowErrorMessage === undefined ? featureName : ftr.workflowErrorMessage + ' ' + featureName;
        }
        else if(v.name.includes('capabilityMandatory')){
          let featureName = this.featureRules[v.message] === undefined ? v.message : this.featureRules[v.message];
          ftr.capabilityIsValid = false;
          ftr.capabilityErrorMessage = ftr.capabilityErrorMessage === undefined ? featureName : ftr.capabilityErrorMessage + ' ' + featureName;
        }
      }
    });

    ftr.request = ftr.passportSanction?.toUpperCase() !== 'APPROVAL';

    if (ftr.tasks !== undefined) {
      ftr.tasks.forEach((task, index) => {
        if (index === 0) {
          if (task.approvers !== undefined && task.approvers.length !== 0) {
            ftr.taskTemplate = task;
            ftr.taskTemplate.status = 'Not started';
            ftr.taskTemplate.approver = task.approvers[0].name;
          } else {
            ftr.taskTemplate = null;
          }
        }
      });
    }
  }

  //HANDLE METHODS
  handleError(error){
    console.log('error',JSON.stringify(error));
    let message = "Unknown error";
    if (Array.isArray(error.body)) {
      message = error.body.map((e) => e.message).join(", ");
    } else if (typeof error?.body?.message === "string") {
      message = error.body.message;
    } else if (typeof error === "string") {
      message = error;
    }else if(Array.isArray(error) && error.length > 0 && typeof error[0]==="string"){
      message =  this.csLabels.requiredMsg+' '+error.join(", ")+'.';
    }

    this.messageError = message;

    this.dispatchEvent(
      new ShowToastEvent({
        title: "Error processing passport",
        message,
        variant: "error",
      }),
    );

    this._showSpinner = false;

  }

  //TODO: Retornar el campo de color o relizar comprobaciones: si no hay approver ni tarea deberia estar gris. Estemetodo no sera necesario si nos mandan un campo dde color del workflow
  async checkWorkflowStatus(){
    console.log('checkWorkflowStatus');
    let arrayFeatures = [];
    this.wrapper.forEach(feature => {
      arrayFeatures.push(feature.id);
    });
    return this.isValidateFeature(arrayFeatures);
  }

  //TODO : Hablar con carlos lo de la featuretype, de donde tiene que tirar, porque esta mockeado
  isValidateFeature(feature) {
    return getAllsValidate({
      lineId: this.lineId,
      opptyId: this.opportunityId,
      featureType: feature
    }).then(response => {
      let result = JSON.parse(response);

      if(result !== undefined){
        this.wrapper.forEach(f => {
          if(result[f.id] !== undefined){
            this.validFeature(f, result[f.id]);
          }
          this.setFeatureProperties(f);
        });
      }
      this.wrapper = [...this.wrapper]; // Immutable re-assign to force reactivity
      this._showSpinner = false;
    }).catch((error) => {
      this.handleError(error);
    });
  }

  validFeature(feature,response){
    feature.isValid = response.feature?.isValid !== undefined ? response.feature.isValid : true;
    feature.errorMessage = response.feature?.message;
    feature.capabilityIsValid = response.capability?.isValid !== undefined ? response.capability.isValid : true;
    feature.capabilityErrorMessage = response.capability?.message;
    feature.workflowIsValid = response.workflow?.isValid !== undefined ? response.workflow.isValid : true;
    feature.workflowErrorMessage = response.workflow?.message;
  }

  parseJson(value) {
    try {
      return JSON.parse(value);
    } catch (error) {
      this.handleError(error);
      return null;
    }
  }

  data = [];

  getTaskHistory(record, indexRecord) {
    getStepsFromFeature({
      featureId: record.id,
      lineExternalId: this.externalId
    }).then(responseTasks => {
      if(responseTasks){
        if (responseTasks[0].itemKey == 'Closed' || responseTasks[0].itemKey == 'Finished') {
          if (responseTasks[0].subitems[0]) {
            record.featureTasksHistory = responseTasks[0].subitems[0].subitems;
            record.featureTasksHistory.forEach(element =>{
              if(element?.startDate){
                element.startDate = this.formatDate(element.startDate);
              }
              if(element?.endDate){
                element.endDate = this.formatDate(element.endDate);
              }
            });
          } else {
            record.featureTasksHistory = [];
          }

        } else {
          record.featureTasksHistory = responseTasks[0].subitems;
          record.featureTasksHistory.forEach(element =>{
            if(element?.startDate){
              element.startDate = this.formatDate(element.startDate);
            }
            if(element?.endDate) {
              element.endDate = this.formatDate(element.endDate);
            }
          });
        }
        record.expanded = true;
        this.wrapper[indexRecord] = record; // Actualizar el registro en el wrapper
      }
      this._showSpinner = false;

    }).catch((error) => {
      this.handleError(error);
    });
  }
  formatDate(dateToFormat){
    const months = ["Ene","Feb","Mar","Abr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
    var [date, hour] = (dateToFormat).split(" ");
    var [day, mnt, year] = date.split("/");
    return day+'-'+mnt+'-'+year;
  }

  async initRefreshTasksInProgress() {
    console.log('initRefreshTasksInProgress');
    var idsFeaturesWithWorkflow = [];

    this.wrapper.forEach(feature => {
      //If feature doest have approver or task with value workflow dont apply
      if (feature.id != null && feature.tasks?.length > 0 && feature.tasks[0]?.approvers?.length > 0) {
        idsFeaturesWithWorkflow.push(feature.id);
      }
      if(feature.tasks === undefined || feature.tasks.length === 0){
        feature.tasks = undefined;
      }
    });

    if(idsFeaturesWithWorkflow.length > 0){
      let apexPromise;

      if (this.opportunityId) {
          apexPromise = getCurrentStepFromFeaturesOpp({
              featuresIds: idsFeaturesWithWorkflow,
              oppExternalId: this.externalId
          });
      } else if (this.lineId) {
          apexPromise = getCurrentStepFromFeatures({
              featuresIds: idsFeaturesWithWorkflow,
              lineExternalId: this.externalId
          });
      } else {
          return Promise.resolve();
      }

      return apexPromise.then(rspTask => {
        this._showSpinner = true;
        if (rspTask) {
          // Preprocesar rspTask en un Map para acceso rápido por featureId
          const taskMap = new Map();
          rspTask.forEach(currentTask => {
            let currentTaskArray = [];
            if (currentTask.itemKey === 'Closed' || currentTask.itemKey === 'Finished') {
              currentTaskArray = JSON.parse(JSON.stringify(currentTask.subitems));
            } else {
              currentTaskArray.push(currentTask);
            }
            currentTaskArray.forEach(taskItem => {
              // Si hay varias tareas por featureId, nos quedamos con la última (o puedes adaptar la lógica)
              taskMap.set(taskItem.featureId, taskItem);
            });
          });

          this.wrapper.forEach(ftr => {
            ftr.hasSFtask = false;
            if (ftr.tasks !== undefined && ftr.tasks.length > 0) {
              // Solo procesar el primer task para taskTemplate
              const firstTask = ftr.tasks[0];
              if (firstTask.approvers !== undefined && firstTask.approvers.length !== 0) {
                ftr.taskTemplate = firstTask;
                ftr.taskTemplate.status = 'Not started';
                ftr.taskTemplate.approver = firstTask.approvers[0].name;
                ftr.showHistoryButton = false;
              } else {
                ftr.taskTemplate = null;
              }

              // Buscar la tarea actual por featureId
              const currentTaskIteration = taskMap.get(ftr.id);
              if (currentTaskIteration) {
                ftr.sfCurrentTask = currentTaskIteration;
                if(ftr.sfCurrentTask?.startDate){
                  ftr.sfCurrentTask.startDate = this.formatDate(ftr.sfCurrentTask.startDate);
                }
                if(ftr.sfCurrentTask?.endDate){
                  ftr.sfCurrentTask.endDate = this.formatDate(ftr.sfCurrentTask.endDate);
                }
                ftr.isApprover = this.groupMembers.includes(ftr.sfCurrentTask.approver);
                if(ftr.sfCurrentTask.caseStatus != 'Finished'){
                  ftr.isNotFinishedTask = true;
                }else{
                  ftr.isNotFinishedTask = false;
                }
                ftr.sfCurrentTask.openModal = ftr.sfCurrentTask?.step?.urlValue === 'c-modal-container';
                ftr.hasSFtask = true;
                ftr.showHistoryButton = currentTaskIteration.taskSize != null && currentTaskIteration.taskSize > 1;
                if (currentTaskIteration.caseStatus === 'Pending' || currentTaskIteration.caseStatus === 'In Progress') {
                  ftr.workflowColor = 'yellow';
                } else if (currentTaskIteration.caseStatus === 'Finished' && currentTaskIteration.rawresult === 'No') {
                  ftr.workflowColor = 'red';
                } else if (currentTaskIteration.caseStatus === 'Finished' && currentTaskIteration.rawresult === 'Yes') {
                  ftr.workflowColor = 'green';
                } else if (currentTaskIteration.caseStatus === 'Finished' && currentTaskIteration.rawresult === undefined) {
                  ftr.workflowColor = 'grey';
                  ftr.workflowIsNotValid = true;
                  ftr.workflowErrorMessage = 'Task without result and case finised';
                }
              }
            }
          });
        }
        this.wrapper = [...this.wrapper]; // Immutable re-assign to force reactivity
        this._showSpinner = false;
      }).catch((error) => {
        this.handleError(error);
      });
    } else {
      // No features - resolve immediately
      return Promise.resolve();
    }
  }

  openModal(event){
   
    let featureId = event.detail;
    let consumptionLimits = [];
    this.limits = null;
    this.featureName = null;
    this.featureLight = null;
    this.validations = [];
    this.noShowInfo = false;
    this.errorModal = false;
    this.graphicModal = false;
    this.profitability = null;

    this.wrapper.forEach(c => {
      if(featureId === c.idProccess){
        consumptionLimits = c.consumptionLimits;
        this.profitability = c.profitability;
        this.featureName = c.name;
        this.featureLight = c.stateName?.toLowerCase();

        switch (c.motorDesc) {
          case 'Salesforce':
            this.errorModal = true;
            this.validations = c.validations;
            break;

          default:
            this.graphicModal = true;
            break;
        }
      }
    });

    if(this.errorModal){
      this.validations?.forEach(v => {
        if(v.state === 'RED'){
          v.styleColor = 'color: #ea001e;';
        }
        else {
          v.styleColor = '';
        }
      });
    }
    if(this.graphicModal){
      let conditions = [];
      let currencies = [];
      let labels = [];
      let limitLights = [];
      let sections = ["Drawn", "Undrawn committed", "Undrawn uncommitted", "Pending authorized", "New Opportunity"];
      let targets = [];

      let dataDraw = [];
      let dataUndrawnCommitted = [];
      let dataUndrawnUncommitted = [];
      let dataPendingAuthorized = [];
      let dataNewOpportunity = [];

      consumptionLimits?.forEach(l => {
        if(l.stateName !== undefined){
          conditions.push(l.conditionDesc);
          currencies.push(l.currencyId);
          labels.push(l.limitDesc);
          limitLights.push(l.stateName?.toUpperCase());
          targets.push(parseFloat(l.amount?.currentApprovedAmount));
          dataDraw.push(parseFloat(l.amount?.cmtContDisposedAmount) + parseFloat(l.amount?.uncmtContDisposedAmount));
          dataUndrawnCommitted.push(parseFloat(l.amount?.cmtContNonDspsAmount));
          dataUndrawnUncommitted.push(parseFloat(l.amount?.uncmtContNonDspsAmount));
          dataPendingAuthorized.push(parseFloat(l.amount?.authorizedRiskAmount));
          dataNewOpportunity.push(parseFloat(l.amount?.notSignedTrConsumptionAmount));
        }
      });

      if((this.graphicModal && (consumptionLimits === undefined || dataDraw.length === 0)) && !this.profitability || (this.errorModal && (this.validations === undefined || this.validations.length === 0))){
        this.noShowInfo = true;
      }

      let datasets = [
        {"backgroundColor": "rgba(4, 50, 99, 1)", "data": dataDraw, "hoverBackgroundColor": "rgba(4, 50, 99, 1)","label": "Drawn"},
        {"backgroundColor": "rgba(20, 100, 165, 1)", "data": dataUndrawnCommitted, "hoverBackgroundColor": "rgba(20, 100, 165, 1)","label": "Undrawn committed"},
        {"backgroundColor": "rgba(36, 150, 234, 1)", "data": dataUndrawnUncommitted, "hoverBackgroundColor": "rgba(36, 150, 234, 1)","label": "Undrawn uncommitted"},
        {"backgroundColor": "rgba(45, 204, 205, 1)", "data": dataPendingAuthorized, "hoverBackgroundColor": "rgba(45, 204, 205, 1)","label": "Pending authorized"},
        {"backgroundColor": "rgba(189, 189, 189, 1)", "data": dataNewOpportunity, "hoverBackgroundColor": "rgba(189, 189, 189, 1)","label": "New Opportunity"}
      ];

      this.limits = {conditions: conditions, currencies: currencies, datasets: datasets, labels: labels, limitLights: limitLights, originCurrency: this.currencyIsoCode, sections: sections, targetColor: 'red', targets: targets, additional_Restrictions: this.additional_Restrictions};
    }

    passportModal.open({
      // maps to developer-created `@api options`
      noShowInfo: this.noShowInfo,
      graphicModal: this.graphicModal,
      limits: this.limits,
      featureName: this.featureName,
      featureLight: this.featureLight,
      validations: this.validations,
      errorModal: this.errorModal,
      profitability: this.profitability,
      showProfitabilityChart: this.showProfitabilityChart,
      opportunityId: this.opportunityId
    }).then((result) => {
      this.graphicModal = false;
      this.errorModal = false;
      this.errorMessages = [];
    });
  }

  expandedControlEvent(event) {

    this._showSpinner = true;
    const recordId = event.detail;
    let recordFound;
    let indexFound;

    this.wrapper.forEach((record, indexRecord) => {
      if (record.idProccess === recordId && record.workflowColor !== "grey") {
        //Recuperar tareas para la feature solo si estaba colapsada, si no limpiamos
        if(record.expanded === false || record.expanded === undefined){
          recordFound = record;
          indexFound = indexRecord;
        }else{
          record.featureTasksHistory = undefined;
          record.expanded = false;
          this._showSpinner = false;
        }
      }

      if(recordFound !== undefined){
        recordFound = undefined;
        this.getTaskHistory(record, indexFound);
      }

    });
  }

  startCase(event) {
    this._showSpinner = true;
    const {idProccess, comment} = event.detail;
    var externalLineid;
    var approverId;
    var featureName;
    var taskId;
    var taskList;
    var featureid;
    var passportSanction;
    this.wrapper.forEach(record => {
      if (record.idProccess === idProccess) {
        externalLineid = this.myPayload.opportunityId;
        approverId = record.tasks[0].approvers[0].id;
        featureName = record.name;
        taskId = record.tasks[0].id;
        taskList = [...record.tasks];
        featureid = record.id;
        passportSanction = record.passportSanction;
      }

    });

    taskList.shift();

    startCase({
      externalLineid: externalLineid,
      approverId: approverId,
      taskId: taskId,
      taskList: taskList,
      featureId: featureid,
      featureName: featureName,
      comment: comment,
      passportSanction: passportSanction
    }).then(response => {
      const evt = new ShowToastEvent({
        title: this.csLabels.successMsg,
        message: 'The workflow has been successfully requested',
        variant: 'success',
      });
      this.dispatchEvent(evt);
      this.dispatchEvent(new RefreshEvent());

      this.initRefreshTasksInProgress();

    }).catch((error) => {
      this.handleError(error);
    });

  }

  // Called by connectedCallback()
  registerErrorListener() {
    onError(error => {
      console.error('Salesforce error', JSON.stringify(error));
    });
  }

  // Called by connectedCallback()
  registerSubscribe() {
    const changeEventPassportCallback = changeEventPassport => {
      this.processChangePassportEvent(changeEventPassport);
    };

    const changeEventTaskCallback = changeEventTask => {
      this.processChangeTaskEvent(changeEventTask);
    };

    // Sets up subscription and callback for change events
    subscribe(this.channelNamePassport, -1, changeEventPassportCallback).then(subscription => {
      this.subscriptionPassport = subscription;
    });
    subscribe(this.channelNameTask, -1, changeEventTaskCallback).then(subscription => {
      this.subscriptionTask = subscription;
    });

    getRecordNotifyChange([{ recordId: this.passportId }]);
  }

  // Called by registerSubscribe()
  processChangePassportEvent(changeEvent) {
    try {
      const recordIds = changeEvent.data.payload.ChangeEventHeader.recordIds; // avoid deconstruction
      if(recordIds.includes(this.passportId)){
        getRecordNotifyChange([{ recordId: this.passportId }]); // Refresh all components
      }
    } catch (err) {
      this.handleError(error);
    }
  }

  processChangeTaskEvent(changeEvent) {
    try {
      const recordIds = changeEvent.data.payload.records__c.split(',');
      const operation = changeEvent.data.payload.Operation__c;

      if(operation === 'CREATE'){
        refreshApex(this.wiredInformationPassportResult).then(result => {
          this.searchTask(recordIds);
        });
      }
      this.searchTask(recordIds);

    } catch (err) {
      this.handleError(error);
    }
  }

  searchTask(recordIds){
    this.tasksId.forEach(t => {
      if(recordIds.includes(t)){
        this.checkWorkflowStatus();
        this.initRefreshTasksInProgress();
        refreshApex(this.wiredInformationPassportResult);
        return true;
      }

    });
  }

  async validateOppBeforePassportService() {
          this.responseValidationOpp = await validateOppBeforePassport({ oppId : this.opportunityId });
          return this.responseValidationOpp;
    }

  @api
  async callService() {
    this.messageError = '';

    try{
      if(this.opportunityId !== undefined){
        await this.validateOppBeforePassportService();
          if(!this.responseValidationOpp?.success){
              this.handleError(this.responseValidationOpp.message);
              return;
            }
      }else{
          await refreshApex(this.wiredLineResult);
          await refreshApex(this.relatedRiksList);
          if(this.recordType === 'OtherProducts' &&
            (this.amountLine === null || this.lastLvlLine === null || this.relatedRiksList?.data?.records?.length === 0)) {
            this.handleError(this.csLabels.lineValidationMsg1);
            return;
          }
      }

      const params = {
            selectedTab: 'passport',
            clientId: this.clientType === CUSTOMER_STRG ? undefined : this.clientId,
            lCountries: ["ALL"],
            searchDate: this.lastDate,
            clientPositionsType: this.clientType !== CUSTOMER_STRG ? 'Y' : 'N',
            page: 1,
            pageSize: '5000',
            customerId: this.clientType !== CUSTOMER_STRG ? undefined : this.clientId,
          };

          this.template.querySelector("c-dmt_call_passport").fetchData(params);
    }catch (error) {
      this.handleError(error);
    }

    /* refreshApex(this.wiredLineResult)
      .then(() => {
        return refreshApex(this.relatedRiksList);
      })
      .then(response => {
        //console.log('Wired relatedRiksList:', JSON.stringify(this.relatedRiksList));
        //console.log('After refresh: amountLine:', this.amountLine, 'lastLvlLine:', this.lastLvlLine, 'relatedRiksList records:', this.relatedRiksList?.data?.records?.length);
        if(this.recordType === 'OtherProducts' &&
          (this.amountLine === null || this.lastLvlLine === null || this.relatedRiksList?.data?.records?.length === 0)) {
          this.handleError('It is mandatory to add Amount, type of risk and at least one product to the line');
          return;
        }

        const params = {
          selectedTab: 'passport',
          clientId: this.clientType === 'Customer' ? undefined : this.clientId,
          lCountries: ["ALL"],
          searchDate: this.lastDate,
          clientPositionsType: this.clientType !== 'Customer' ? 'Y' : 'N',
          page: 1,
          pageSize: '100',
          customerId: this.clientType !== 'Customer' ? undefined : this.clientId,
        };

        this.template.querySelector("c-dmt_call_passport").fetchData(params);
      })
      .catch((error) => {
        this.handleError(error);
      }); */
  }

  handleCallServiceEvent(event){
    console.log('handleCallServiceEvent');
    event.stopPropagation();
    this._showSpinner = true;

    let message = JSON.parse(event.detail);

    if(message.result){
      buttonCallPassport({
        recordId: this.recordId,
        clientesGroup: message.body
      }).then(response => {
        console.log('buttonCallPassport response', response);
        let result = JSON.parse(response);
        this._showSpinner = false;  // Add this to stop spinner on success
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

  async updateFeatureType(){
    console.log('Calculating feature types');
    let arrayFeaturesApproverId = [];
    let tempFeatureToModifyType = [];
    this.wrapper.forEach(feature => {
      if(feature.passportSanction?.toUpperCase() == 'APPROVAL' && feature?.tasks){
        arrayFeaturesApproverId.push(feature?.tasks?.[0].approvers?.[0].id);
        tempFeatureToModifyType.push(feature);
      } 
    });

    if( arrayFeaturesApproverId.length > 0 ){ 
      return getFeatureTypeByApproverType({featuresApproverIds: arrayFeaturesApproverId}).then(response => {
        if(response !== undefined){
          const featureTypeMap = {};
          response.forEach(item => {
            if(item?.approverId) {
              featureTypeMap[item.approverId] = item.featureType;
            }
          });

          tempFeatureToModifyType.forEach(f => {
            const approverId = f.tasks?.[0].approvers?.[0].id;
            if(approverId){
              f.featureType = featureTypeMap[approverId];
              const idx = this.wrapper.findIndex(w => w.id === f.id);
              if(idx !== -1){
                this.wrapper[idx] = { ...this.wrapper[idx], featureType: f.featureType };
              }
                //console.log( 'Feature Type for feature ' + f.name + ': ' + f.featureType);
                //console.log( 'Approver Id for feature ' + f.name + ': ' + f.tasks[0]?.approvers[0]?.id);
            }
          });
          this.calculateApprovalRequestActive(tempFeatureToModifyType);
        }
        this.wrapper = [...this.wrapper];
      }).catch((error) => {
        this.handleError(error);
      });
    }
  }

  calculateApprovalRequestActive(features){
    if(this.lineStatus != 'Approval'){
      return;
    }
    let requestOn = true;
    let requestOff = false;
    let firstFeatureBusiness = null;
    let firstFeatureRisk = null;

    //First divide features by type
    const withFeatureTypeBusiness = features.filter(item => item.featureType=='Business');
    const withFeatureTypeRisk = features.filter(item => item.featureType=='Risk');

    //If we have business type features, the first one will have request on, ordered by orderNumber
    if(withFeatureTypeBusiness.length > 0){
      withFeatureTypeBusiness.sort((a, b) => a.orderNumber - b.orderNumber);
      console.log('withFeatureTypeBusiness sorted', JSON.stringify(withFeatureTypeBusiness));
      firstFeatureBusiness = withFeatureTypeBusiness[0];
      const idx = this.wrapper.findIndex(w => w.id === firstFeatureBusiness?.id);
              if(idx !== -1){
                this.wrapper[idx] = { ...this.wrapper[idx], request: requestOn  };
              }
    }else{
      //If we dont have business type features, the first risk type feature will have request on, ordered by orderNumber
      withFeatureTypeRisk.sort((a, b) => a.orderNumber - b.orderNumber);
      console.log('withFeatureTypeRisk sorted', JSON.stringify(withFeatureTypeRisk));
      firstFeatureRisk = withFeatureTypeRisk[0];
      const idx = this.wrapper.findIndex(w => w.id === firstFeatureRisk?.id);
              if(idx !== -1){
                this.wrapper[idx] = { ...this.wrapper[idx], request: requestOn  };
              }
    }
  } 
}