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
import LINE_RECORDTYPE_FIELD from "@salesforce/schema/DMT_Line__c.RecordType.DeveloperName";
import STATUSOPPORTUNITY_FIELD from "@salesforce/schema/Opportunity.StageName";
import CLIENTTYPEOPPORTUNITY_FIELD from "@salesforce/schema/Opportunity.DMT_Client_Type__c";
import CLIENTIDOPPORTUNITY_FIELD from "@salesforce/schema/Opportunity.AccountId";
import LINEVALIDATION_MSG_1 from '@salesforce/label/c.DMT_PassportLineValidationMsg1';
import ClientsVALIDATION_MSG_1 from '@salesforce/label/c.DMT_PassportErrorMsgClientsService';
import Success_MSG from '@salesforce/label/c.Success';
import Required_MSG from '@salesforce/label/c.DMT_PassportMsgRequired';
const CUSTOMER_STRG = 'Customer';
import { CurrentPageReference } from 'lightning/navigation';
import hasLineGodPermission from '@salesforce/customPermission/DMT_Line_God';

export default class Dmt_passport extends LightningElement {

  myPayload = [];
  wrapper = [];
  refreshContainerID;

  @api isBigVersion;
  @api recordId;

  @api
  get getservice() {
    return this.getservicevalue;
  }

  set getservice(value) {
    this.getservicevalue = value;
    if (value && value.toLowerCase() === 'true') {
        this.executeSafeSync('MANUAL');
    }
  }

  limits;
  featureName;
  featureLight;
  validations = [];
  childProps;
  componentConstructor;
  _hasInitialized = false;
  _isStale = false;
  _showSpinner = true;
  _pendingSync = null;     
  @track messageError;
  userPermission = false;
  lastDate;
  recordType;
  hasRendered = false;

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
  }

  renderedCallback() {
      if (!this.hasRendered) {
          this.onScrollPassport();
          this.hasRendered = true;
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

  relatedRiksList;

  @wire(getRelatedListRecords, {
      parentRecordId: "$lineId",
      relatedListId: 'Risk_Line_Terms__r',
      fields: ['DMT_Risk_Line_Term__c.Id']
  })
  wiredRelatedRisks(result) {
      this.relatedRiksList = result;
      const { data, error } = result;
      if (!data && !error) return;

      if (this._pendingSync) {
          const origin = this._pendingSync;
          this._pendingSync = null;
          this.executeSafeSync(origin);
      }
  }

  @wire(getRecord, { recordId: "$passportId", fields: [OBSOLETED_FIELD, JSON_FIELD] })
  wiredRecordPassport(result) {
    this.wiredPassportResult = result;
    const { error, data } = result;
    if (data) {
      let tempPayload = getFieldValue(data, JSON_FIELD);
      console.warn('[WIRE-PASSPORT] Data arrived.');
          this.showWarning = (this._showSpinner) ? false : (tempPayload ? getFieldValue(data, OBSOLETED_FIELD) : false);

        if (this.rawPayload === tempPayload) {
            this._showSpinner = false; // Disable spinner if the record updated but data is the same
            return;
        }

          this.rawPayload = tempPayload;
          this.messageError = '';

          // SHIELD: If we are currently making a callout or haven't finished the first load,
          // do NOT trigger a re-render.
          if (this._isStale) {
              console.log('[ORCHESTRATOR] Passport wire blocked: Data is currently stale.');
              return;
          }

          this.executeSafeSync('PASSPORT_UPDATED');
      }
  }

  // The Gatekeeper
  tryInit(reason) {
    // SILENT CHECK
    // Check here to avoid unnecessary timers and spinner flickers
    if (!this.validateIntegrity(true)) {
        console.warn(`[ORCHESTRATOR] Aborted: Data Integrity check failed.`);
        return;
    }

    if (this.isReady()) {
        console.log(`[ORCHESTRATOR] Ready (${reason}). Scheduling...`);
        this.scheduleOrchestrate(reason);
    } else if (this._retryCount < this.MAX_RETRIES) {
        this._retryCount++;
        this.scheduleOrchestrate('RETRY', 600);
    }
}

  // The Debouncer (The "Chiller")
  scheduleOrchestrate(reason, delayMs = 400) {
      if (this._orchTimer) {
          clearTimeout(this._orchTimer);
      }

      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this._orchTimer = setTimeout(() => {
          this.executeSafeSync(reason);
      }, delayMs);
  }

  //WIREDS
  @wire(getRecord, { recordId: "$lineId", fields: [STATUSLINE_FIELD, CLIENTTYPE_FIELD, CLIENTID_FIELD, AMOUNT_FIELD, LASTLVLID_FIELD, CLOSEDLINE_FIELD, CURRENCYLINE_FIELD, LINE_RECORDTYPE_FIELD] })
  wiredRecordLine(result){
      this.wiredLineResult = result;
      const { error, data } = result;

      if (error) {
          this.handleError(error);
      }
      else if (data) {
        // 1. Assign local variables (Passive sync)
        this.recordType = getFieldValue(result.data, LINE_RECORDTYPE_FIELD);
        this.clientType = getFieldValue(data, CLIENTTYPE_FIELD);
        this.clientId = getFieldValue(data, CLIENTID_FIELD);
        this.amountLine = getFieldValue(data, AMOUNT_FIELD);
        this.lastLvlLine = getFieldValue(data, LASTLVLID_FIELD);
        this.currencyIsoCode = getFieldValue(data, CURRENCYLINE_FIELD);

        // 2. ONLY INITIAL LOAD TRIGGER
        /* if (!this._hasInitialized) {
            console.log('[ORCHESTRATOR] IDs Ready. Performing Initial Load Callout.');
            this._hasInitialized = true;
            this.tryInit('LINE_WIRE');
        } */

        // 3. Detect Status changes to show the spinner while the backend works
        const newLineStatus = getFieldValue(data, STATUSLINE_FIELD);
        if (this.lineStatus !== undefined && this.lineStatus !== newLineStatus) {
            this._showSpinner = true; 
        }

        this.lineStatus = newLineStatus;
        this.lineClosed = getFieldValue(data, CLOSEDLINE_FIELD);
    }
  }

  isReady() {
      // Check for the minimum required data for a callout
      const hasIds = this.passportId && this.lineId;
      const hasClient = this.clientId !== undefined;
      const hasDate = this.lastDate !== undefined;

      return hasIds && hasClient && hasDate;
  }

  // Add a parameter to decide if we show the toast or stay silent
  validateIntegrity(isSilent = true) {
      if (this.recordType === 'OtherProducts') {
          const risksNotResolved = (this.relatedRiksList?.data === undefined && !this.relatedRiksList?.error);
          const lineNotResolved  = (this.amountLine === undefined && this.lastLvlLine === undefined);

          if (risksNotResolved || lineNotResolved) {
              this._pendingSync = this._lastOrigin;
              this._showSpinner = false;
              return false;   // abortamos SIN tocar wrapper ni showfeaturesTable
          }

          const hasNoAmount = (this.amountLine === null || this.amountLine === undefined);
          const hasNoRisk = (this.lastLvlLine === null || this.lastLvlLine === undefined);
          const hasNoProducts = !this.relatedRiksList?.data?.records?.length;

          if (hasNoAmount || hasNoRisk || hasNoProducts) {
              if (!isSilent) {
                  this.handleError(this.csLabels.lineValidationMsg1);
              }
              // CLEANUP: If we aren't valid, we shouldn't have data in memory
              this.showfeaturesTable = false;
              this.wrapper = [];
              this._showSpinner = false;
              this._isStale = false; // Release shield if validation fails
              return false;
          }
      }
      return true;
  }

  async executeSafeSync(origin) {
    this._lastOrigin = origin; // Track the origin every time we enter
      console.warn('[ORCHESTRATOR] Entry:', origin, 'Shield Status (isStale):', this._isStale);

      // If the user triggered this manually, we want to show errors (isSilent = false).
      // Otherwise (Wires/Initial load), we stay silent.
      const isSilent = (origin !== 'MANUAL');

      // RACE CONDITION FIX:
      // Await the absolute latest data from the server for the Line and Related Risks
      // BEFORE we check integrity. This guarantees we don't fail due to stale UI cache.
      try {
          let refreshPromises = [refreshApex(this.wiredLineResult)];
          
          if (this.recordType === 'OtherProducts') {
              refreshPromises.push(refreshApex(this.relatedRiksList));
      }

          await Promise.all(refreshPromises);
      } catch (err) {
          console.error('Failed to sync Line Data before integrity check', err);
      }

      // 1. GUARD: Evaluate integrity using the freshly awaited data
      if (!this.validateIntegrity(isSilent)) {
          console.log('[ORCHESTRATOR] Aborted: Data Integrity check failed..');
          return;
      }
      if (origin === 'PASSPORT_UPDATED' || origin === 'TASK_UPDATED') {
          console.log('[DEBUG-REFRESH] executeSafeSync(' + origin + ') - calling proccessPayload to rebuild feature buffer / traffic lights.');
          await this.proccessPayload(this.rawPayload);
          console.log('[DEBUG-REFRESH] executeSafeSync(' + origin + ') - proccessPayload finished. this.wrapper feature count:', this.wrapper?.length);
          return;
      }

      // Entering integration path
      this._isStale = true;
      this._showSpinner = true;
      this.showfeaturesTable = false;

      try {
          await this.callService(origin);
      } catch (error) {
          this.handleError(error);
          this._showSpinner = false;
          this._isStale = false;
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
        console.error(`[INVESTIGATION] REACTIVE TRIGGER: Opportunity Stage Updated. New Stage: ${newStatus}`);
        this.handleStatusChange();
      }

      this.previousOpportunityStatus = newStatus;
      this.lineStatus = newStatus;
    }
  }

  @wire(getInformationPassport, { recordId: "$recordId" })
  wiredInformationPassport(result) {
    this.wiredInformationPassportResult = result;
    if(result.error){
      this.handleError(result.error);
    }
    else if (result.data) {
      let response = JSON.parse(result.data);
      this.externalId = response.externalId;
      this.passportId = response.passportId;
      this.lineId = response.lineId;
      this.opportunityId = response.opportunityId;
      this.tasksId = JSON.parse(response.tasksId);
      this.userPermission = response.userPermission;
      this.recordType = response.recordType;
      this.groupMembers = response.groupMembers;
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
      if (this.statusRefreshInProgress) return;

      this.statusRefreshInProgress = true;
      this.dispatchEvent(new RefreshEvent());

      // Instead of calling callService directly, call the Orchestrator
      this.executeSafeSync('WIRE').finally(() => {
          this.statusRefreshInProgress = false;
      });
  }


  async proccessPayload(newPayload) {
      const parsedValue = this.parseJson(newPayload);
      console.warn('[PROCESSOR] Building Buffer for Date:', JSON.stringify(parsedValue?.data?.auditDate));
      if (parsedValue?.data !== undefined) {
          // Clear any previous error messages now that we have valid data
        //  this.messageError = '';
          this.rawPayload = newPayload;
          this.myPayload = parsedValue.data;

          let buffer = [];

          try {
              this.buildWrapperList(buffer);
              this.sortBuffer(buffer);

              // WAIT for all async data to populate the buffer
              await Promise.all([
                  this.checkWorkflowStatus(buffer),
                  this.initRefreshTasksInProgress(buffer)
              ]);

              await this.updateFeatureType(buffer);

              // ATOMIC REVEAL
              this.wrapper = [...buffer];
              this.showfeaturesTable = true;
              this._showSpinner = false;

          } catch (error) {
              this.handleError(error);
              this._showSpinner = false;
          }
      } else {
          this._showSpinner = false;
      }
  }

  buildWrapperList(buffer) {
      if (!this.myPayload || !this.myPayload.features) return;

      this.myPayload.features.forEach(ftr => {
          if(ftr.motorDesc === 'Salesforce'){
              buffer.push({id: ftr.id, name: ftr.name, passportSanction: ftr.passportSanction, motorDesc: ftr.motorDesc, stateName: ftr.stateName, active: ftr.active, validations: ftr.validations, idProccess: ftr.id});
          } else {
              buffer.push({ id: ftr.id, name: ftr.name, passportSanction: ftr.passportSanction, motorDesc: ftr.motorDesc, stateName: ftr.stateName, active: ftr.active, validations: ftr.validations, tasks: ftr.tasks, consumptionLimits: ftr.consumptionLimits, idProccess: ftr.id, profitability: ftr.profitability, orderNumber: ftr.orderNumber });
          }
      });
  }

  sortBuffer(buffer) {
      let passportSanction;
      let featuresTemp = [];

      buffer.sort((a, b) => {
          const nameA = a.passportSanction?.toUpperCase();
          const nameB = b.passportSanction?.toUpperCase();
          if (nameA === 'APPROVAL' && nameB === 'PASSPORT') return 1;
          if (nameA === 'PASSPORT' && nameB === 'APPROVAL') return -1;
          return 0;
      });

      buffer.forEach((ftr, indexftr) => {
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

      buffer.length = 0;
      buffer.push(...featuresTemp);
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
            ftr.taskTemplate.approver = task.approvers?.[0]?.name;
          } else {
            ftr.taskTemplate = null;
          }
        }
      });
    }
  }

  //HANDLE METHODS
  handleError(error){
    console.error('error.message',error?.message);
    console.error('error.stack',error?.stack);
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
    this._isStale = false;

    // SOFT LANDING: Force a render of whatever is currently in this.rawPayload
    // so the user sees the last known good Passport instead of a spinner.
    const isProcessingError = (this._lastOrigin === 'PASSPORT_UPDATED');

    if (this.rawPayload && !isProcessingError) {
        console.warn('[ORCHESTRATOR] Attempting Soft Landing...');
        this.executeSafeSync('PASSPORT_UPDATED');
    } else {
        console.error('[ORCHESTRATOR] Loop blocked or No Payload. Killing render.');
        this.showfeaturesTable = false;
        this.wrapper = [];
    }

  }

  async checkWorkflowStatus(buffer) {
      let arrayFeatures = buffer.filter(f => f.id).map(f => f.id);
      return this.isValidateFeature(arrayFeatures, buffer);
  }

  isValidateFeature(featureIds, buffer) {
      return getAllsValidate({
          lineId: this.lineId,
          opptyId: this.opportunityId,
          featureType: featureIds
      }).then(response => {
          let result = JSON.parse(response);
          if (result !== undefined) {
              buffer.forEach(f => {
                  if (result[f.id] !== undefined) {
                      // It updates the object reference 'f' inside the buffer.
                    this.validFeature(f, result[f.id]);
                  }
                  this.setFeatureProperties(f);
              });
          }
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
        console.log('Jimmy history', JSON.stringify(responseTasks));
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

  async initRefreshTasksInProgress(buffer) {
      var idsFeaturesWithWorkflow = [];
      buffer.forEach(feature => {
          if (feature.id != null && feature.tasks?.length > 0 && feature.tasks[0]?.approvers?.length > 0) {
              idsFeaturesWithWorkflow.push(feature.id);
          }
          if (feature.tasks === undefined || feature.tasks.length === 0) {
              feature.tasks = undefined;
          }
      });

      if (idsFeaturesWithWorkflow.length > 0) {
          let apexPromise = this.opportunityId ?
              getCurrentStepFromFeaturesOpp({ featuresIds: idsFeaturesWithWorkflow, oppExternalId: this.externalId }) :
              getCurrentStepFromFeatures({ featuresIds: idsFeaturesWithWorkflow, lineExternalId: this.externalId });

          return apexPromise.then(rspTask => {
              if (rspTask) {
                  const taskMap = new Map();
                  rspTask.forEach(currentTask => {
                      let currentTaskArray = (currentTask.itemKey === 'Closed' || currentTask.itemKey === 'Finished') ?
                          JSON.parse(JSON.stringify(currentTask.subitems)) : [currentTask];
                      currentTaskArray.forEach(taskItem => taskMap.set(taskItem.featureId, taskItem));
                  });

                  var readyToClose = true;
                  buffer.forEach(ftr => {
                      ftr.hasSFtask = false;
                      if (ftr.tasks !== undefined && ftr.tasks.length > 0) {
                        const firstTask = ftr.tasks?.[0];
                          if (firstTask.approvers?.length > 0) {
                              ftr.taskTemplate = firstTask;
                              ftr.taskTemplate.status = 'Not started';
                              ftr.taskTemplate.approver = firstTask.approvers?.[0]?.name;
                              ftr.showHistoryButton = false;
                          }

                          const currentTaskIteration = taskMap.get(ftr.id);
                          if (currentTaskIteration) {
                              ftr.sfCurrentTask = currentTaskIteration;
                              if(ftr.sfCurrentTask?.startDate) ftr.sfCurrentTask.startDate = this.formatDate(ftr.sfCurrentTask.startDate);
                              if(ftr.sfCurrentTask?.endDate) ftr.sfCurrentTask.endDate = this.formatDate(ftr.sfCurrentTask.endDate);

                              ftr.isApprover = this.groupMembers.includes(ftr.sfCurrentTask.approver);
                              ftr.isApproverOrGod = ftr.isApprover || hasLineGodPermission;
                              ftr.isNotFinishedTask = ftr.sfCurrentTask.caseStatus != 'Finished';
                              ftr.sfCurrentTask.openModal = ftr.sfCurrentTask?.step?.urlValue === 'c-modal-container';
                              ftr.hasSFtask = true;
                              ftr.showHistoryButton = currentTaskIteration.taskSize > 1;

                              if (currentTaskIteration.caseStatus === 'Pending' || currentTaskIteration.caseStatus === 'In Progress') {
                                  ftr.workflowColor = 'yellow';
                                  if(ftr.featureType == 'approval') readyToClose = false;
                              } else if (currentTaskIteration.caseStatus === 'Finished' && currentTaskIteration.rawresult === 'No') {
                                  ftr.workflowColor = 'red';
                                  if(ftr.featureType == 'approval') readyToClose = false;
                              } else if (currentTaskIteration.caseStatus === 'Finished' && currentTaskIteration.rawresult === 'Yes') {
                                  ftr.workflowColor = 'green';
                              } else if (currentTaskIteration.caseStatus === 'Finished' && currentTaskIteration.rawresult === undefined) {
                                  ftr.workflowColor = 'grey';
                                  if(ftr.featureType == 'approval') readyToClose = false;
                                  ftr.workflowIsNotValid = true;
                                  ftr.workflowErrorMessage = 'Task without result and case finished';
                              }
                          }
                      }
                  });
              }
          });
      }
      return Promise.resolve();
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

      this.limits = {conditions: conditions, currencies: currencies, datasets: datasets, labels: labels, limitLights: limitLights, originCurrency: this.currencyIsoCode, sections: sections, targetColor: 'red', targets: targets};
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

  async startCase(event) {
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
        approverId = record.tasks?.[0]?.approvers?.[0].id;
        featureName = record.name;
        taskId = record.tasks?.[0].id;
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
    }).then(async response => {
      if (!response.success) {
        this.handleError(response.message);
        this._showSpinner = false;
        return;
      }
      const evt = new ShowToastEvent({
        title: this.csLabels.successMsg,
        message: response.message,
        variant: 'success',
      });
      this.dispatchEvent(evt);
      this.dispatchEvent(new RefreshEvent());

      let buffer = [...this.wrapper];
      await this.initRefreshTasksInProgress(buffer);
      this.wrapper = [...buffer]; // Force reactivity

    }).catch((error) => {
      this.handleError(error);
    })
    .finally(() => {
        // ULTIMATE GUARD: Ensure spinner dies even if logic above is complex
      this._showSpinner = false;
    });;

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
      console.log('[DEBUG-REFRESH] Subscribed to Passport channel:', this.channelNamePassport, subscription);
    });
    subscribe(this.channelNameTask, -1, changeEventTaskCallback).then(subscription => {
      this.subscriptionTask = subscription;
      console.log('[DEBUG-REFRESH] Subscribed to Task channel:', this.channelNameTask, subscription);
    });

    getRecordNotifyChange([{ recordId: this.passportId }]);
  }

  // Called by registerSubscribe()
  processChangePassportEvent(changeEvent) {
    try {
      const recordIds = changeEvent.data.payload.ChangeEventHeader.recordIds; // avoid deconstruction
      console.log('[DEBUG-REFRESH] processChangePassportEvent received. recordIds:', recordIds, 'this.passportId:', this.passportId);
      if(recordIds.includes(this.passportId)){
          console.log('[DEBUG-REFRESH] Passport event MATCHES this.passportId - refreshing.');
          getRecordNotifyChange([{ recordId: this.passportId }]); // Refresh all components
          console.warn('[CDC] Passport changed. Forcing Wire Refresh.');

          // This forces the wire to go back to the server and get the JSON updated by the Trigger
          refreshApex(this.wiredPassportResult);

          if (this.opportunityId) {
            getRecordNotifyChange([{ recordId: this.opportunityId }]);
          } else if (this.lineId) {
            getRecordNotifyChange([{ recordId: this.lineId }]);
          }
      } else {
          console.log('[DEBUG-REFRESH] Passport event did NOT match this.passportId - ignored.');
      }
    } catch (err) {
      this.handleError(error);
    }
  }

  processChangeTaskEvent(changeEvent) {
    try {
      const recordIds = changeEvent.data.payload.records__c.split(',');
      const operation = changeEvent.data.payload.Operation__c;
      console.log('[DEBUG-REFRESH] processChangeTaskEvent received. recordIds:', recordIds, 'operation:', operation, 'current this.tasksId:', this.tasksId);

      // CIBGLOBALD-4117: DMT_ApprovalChangeStep_Helper.restartTasksForRecord publishes this operation with the
      // Line/Opportunity Id itself, not a Task Id - this.lineId/this.opportunityId are already
      // known from load, unlike a brand-new replacement Task's Id (see the isRelatedTask gap
      // below), so this is a reliable way to detect "this passport's approval state changed"
      // regardless of which specific Tasks were cancelled/created underneath it.
      if (operation === 'CASE_UPDATE') {
          const isRelatedRecord = recordIds.includes(this.lineId) || recordIds.includes(this.opportunityId);
          console.log('[DEBUG-REFRESH] CASE_UPDATE event. this.lineId:', this.lineId, 'this.opportunityId:', this.opportunityId, 'isRelatedRecord:', isRelatedRecord);
          if (isRelatedRecord) {
              refreshApex(this.wiredInformationPassportResult).then(() => {
                  if (this.rawPayload) {
                      console.info('[DEBUG-REFRESH] CASE_UPDATE matched - calling executeSafeSync(TASK_UPDATED).');
                      this.executeSafeSync('TASK_UPDATED');
                  } else {
                      console.info('[DEBUG-REFRESH] CASE_UPDATE matched but this.rawPayload is falsy - executeSafeSync NOT called.');
                  }
              });
          }
          return;
      }

   //   if(operation === 'CREATE'){
        refreshApex(this.wiredInformationPassportResult).then(result => {
          console.log('[DEBUG-REFRESH] wiredInformationPassportResult refreshed after task event. New this.tasksId:', this.tasksId);
          this.searchTask(recordIds);
        });
   //   }
      this.searchTask(recordIds);

    } catch (err) {
      this.handleError(error);
    }
  }

  searchTask(recordIds) {
      // 1. Check if any of the updated tasks belong to this passport
      const isRelatedTask = this.tasksId.some(t => recordIds.includes(t));
      console.log('[DEBUG-REFRESH] searchTask called. recordIds:', recordIds, 'this.tasksId:', this.tasksId, 'isRelatedTask:', isRelatedTask);

      if (isRelatedTask) {
          // 2. Refresh the wire to get latest IDs, then run the Orchestrator
          console.log('[DEBUG-REFRESH] isRelatedTask TRUE - refreshing wiredInformationPassportResult and calling executeSafeSync(TASK_UPDATED).');
          refreshApex(this.wiredInformationPassportResult).then(() => {
              if (this.rawPayload) {
                  // This safely rebuilds the buffer, checks the server, and renders the UI
                  this.executeSafeSync('TASK_UPDATED');
              } else {
                  console.log('[DEBUG-REFRESH] isRelatedTask TRUE but this.rawPayload is falsy - executeSafeSync NOT called.');
              }
          });
      } else {
          console.log('[DEBUG-REFRESH] isRelatedTask FALSE - no refresh triggered for this event. This is the gap: a brand-new task Id would not yet be in this.tasksId.');
      }
  }

  @api
  async callService() {
    this.messageError = '';

    try{

      const params = {
            selectedTab: 'passport',
            clientId: this.clientType === CUSTOMER_STRG ? undefined : this.clientId,
            lCountries: ["ALL"],
            searchDate: this.lastDate,
            clientPositionsType: this.clientType === 'Group' ? 'Y' : 'N',
            page: 1,
            pageSize: this.clientType === 'Group' ? '100' : '5000',
            customerId: this.clientType !== CUSTOMER_STRG ? undefined : this.clientId,
          };

          this.template.querySelector("c-dmt_call_passport").fetchData(params);
    }catch (error) {
      this.handleError(error);
    }
  }

  handleCallServiceEvent(event) {
      event.stopPropagation();
      let message = JSON.parse(event.detail);

      if (message.result) {
          buttonCallPassport({
              recordId: this.recordId,
              clientesGroup: message.body
          }).then(async (response) => {
              let result = JSON.parse(response);
              if (result.result && result.payload) {
                  this.messageError = '';
                  refreshApex(this.wiredPassportResult);
                  refreshApex(this.wiredLineResult);

                  this.showWarning = result.isObsolete !== undefined ? result.isObsolete : false;

                  this._isStale = false; // UNLOCK
                  await this.proccessPayload(result.payload);

              } else if (result.result) {
                  this.messageError = '';
                  // Fallback if for some reason payload wasn't returned
                  this._isStale = false;
                  await this.proccessPayload(this.rawPayload);
              } else {
                  this.handleError(result.message);
                  this._isStale = false;
                  this._showSpinner = false;
              }
          }).catch((error) => {
              this.handleError(error);
              this._isStale = false;
              this._showSpinner = false;
          });
      } else {
        this.handleError(this.csLabels.clientsValidationMsg1);
      }
  }

  async updateFeatureType(buffer) {
    let arrayFeaturesApproverId = [];
    let tempFeatureToModifyType = [];
    buffer.forEach(feature => {
        if (feature.passportSanction?.toUpperCase() == 'APPROVAL' && feature?.tasks) {
            arrayFeaturesApproverId.push(feature?.tasks?.[0].approvers?.[0].id);
            tempFeatureToModifyType.push(feature);
        }
    });

    if (arrayFeaturesApproverId.length > 0) {
        return getFeatureTypeByApproverType({ featuresApproverIds: arrayFeaturesApproverId }).then(response => {
            if (response) {
                const featureTypeMap = {};
                response.forEach(item => { if(item?.approverId) featureTypeMap[item.approverId] = item.featureType; });

                tempFeatureToModifyType.forEach(f => {
                    const approverId = f.tasks?.[0].approvers?.[0].id;
                    if (approverId) {
                        f.featureType = featureTypeMap[approverId];
                    }
                });
                this.calculateApprovalRequestActive(tempFeatureToModifyType, buffer);
            }
        });
    }
}

calculateApprovalRequestActive(features, buffer) {
    if (this.lineStatus != 'Approval') return;

    const withFeatureTypeBusiness = features.filter(item => item.featureType == 'Business').sort((a, b) => a.orderNumber - b.orderNumber);
    const withFeatureTypeRisk = features.filter(item => item.featureType == 'Risk').sort((a, b) => a.orderNumber - b.orderNumber);

    // 1. Check for the first unfinished Business Feature
    const firstUnfinishedBusiness = withFeatureTypeBusiness.find(item => 
        item.isNotFinishedTask == undefined || item.isNotFinishedTask
    );

    if (firstUnfinishedBusiness) {
        const featInBuffer = buffer.find(w => w.id === firstUnfinishedBusiness.id);
        if (featInBuffer) {
            featInBuffer.request = true;
        }
    } else {
        // 2. If Business features are done, find ONLY the FIRST unfinished Risk Feature
        const firstUnfinishedRisk = withFeatureTypeRisk.find(item => 
            item.isNotFinishedTask == undefined || item.isNotFinishedTask
        );
        
        if (firstUnfinishedRisk) {
            const featInBuffer = buffer.find(w => w.id === firstUnfinishedRisk.id);
            if (featInBuffer) {
                featInBuffer.request = true;
            }
        }
    }
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

}