import { api } from "lwc";
import LightningModal from "lightning/modal";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import pubsub from "omnistudio/pubsub";

// Labels (DO NOT TOUCH)
import DMT_Name from "@salesforce/label/c.dmt_cl_NameLine";
import DMT_ClientType from "@salesforce/label/c.dmt_cl_ClientType";
import DMT_ClientCode from "@salesforce/label/c.dmt_cl_Client_Code";
import DMT_GroupCode from "@salesforce/label/c.dmt_cl_Group_Code";
import DMT_Country from "@salesforce/label/c.dmt_cl_Country";
import DMT_TaxPayer from "@salesforce/label/c.dmt_cl_Tax_Payer";
import DMT_permissionErrorMessage from "@salesforce/label/c.dmt_cl_Entific_Error";
import DMT_Entific from "@salesforce/label/c.dmt_cl_Entific_Label";
import DMT_LoadingText from "@salesforce/label/c.GDT_Loading";
import DMT_AccountText from "@salesforce/label/c.Account";
import DMT_SelectLineTypetext from "@salesforce/label/c.dmt_cl_SelectLineType_Text";
import DMT_OpportunityTypeText from "@salesforce/label/c.DMT_OpportunityTypeText";
import DMT_EntityText from "@salesforce/label/c.DMT_EntityText";
import DMT_SeltectWithTreePointText from "@salesforce/label/c.DMT_SeltectWithTreePointText";
import DMT_CancelText from "@salesforce/label/c.Arc_Gen_CancelLA_Lab";
import DMT_SaveAndEditText from "@salesforce/label/c.DMT_SaveAndEditText";
import DMT_UnexpectedErrorText from "@salesforce/label/c.DMT_UnexpectedErrorText";
import DMT_ErrorContactAdministratorText from "@salesforce/label/c.DMT_ErrorContactAdministratorText";
import DMT_FailedRegisterEventListenerText from "@salesforce/label/c.DMT_FailedRegisterEventListenerText";
import DMT_PubSubNotLoadedText from "@salesforce/label/c.DMT_PubSubNotLoadedText";
import DMT_FailedComunicationWithServerText from "@salesforce/label/c.DMT_FailedComunicationWithServerText";
import DMT_Successtext from "@salesforce/label/c.Success";
import DMT_OpportunityCreatedSuccessfullyText from "@salesforce/label/c.DMT_OpportunityCreatedSuccessfullyText";
import DMT_IdOpportunityNotReturnedText from "@salesforce/label/c.DMT_IdOpportunityNotReturnedText";
import DTM_NewOpportunityText from "@salesforce/label/c.DTM_NewOpportunityText";

import DMT_weblink_label from "@salesforce/label/c.DMT_weblink_label";


// =========================================================
// Constants
// =========================================================
const CLIENT_TYPE_CUSTOMER = "Subsidiary";
const CLIENT_TYPE_GROUP = "CIB Group";
const CLIENT_TYPE_SUBGROUP = "Subgroup";
const NAME_MAX_LEN = 50;

const ERROR_TITLE = DMT_UnexpectedErrorText;
const ERROR_FALLBACK_MESSAGE = DMT_ErrorContactAdministratorText

const RESULT_OK = "OK";

// Actions (payload.action)
const ACTION_GET_OPPORTUNITY_INFO = "GET_OPPORTUNITY_INFO";
const ACTION_CREATE_NEW_OPPORTUNITY = "CREATE_NEW_OPPORTUNITY";
const ACTION_REFRESH_ENTITY = "REFRESH_ENTITY";
const ACTION_REFRESH_DATA = "REFRESH_DATA";

// PubSub Configuration
const PUBSUB_CHANNEL = "DMT_MarcoGeneral";
const PUBSUB_EVENT_REQUEST = "OpportunityManagement";
const PUBSUB_EVENT_RESPONSE = "OpportunityResponse";

export default class dmtNewOpportunityModal extends LightningModal {
  // =========================================================
  // Public API
  // =========================================================


  labels = {
    DMT_permissionErrorMessage, DMT_Entific,
    DMT_Name,
    DMT_ClientType,
    DMT_ClientCode,
    DMT_GroupCode,
    DMT_Country,
    DMT_weblink_label,
    DMT_TaxPayer,
    DMT_LoadingText,
    DMT_AccountText,
    DMT_SelectLineTypetext,
    DMT_OpportunityTypeText,
    DMT_EntityText,
    DMT_SeltectWithTreePointText,
    DMT_CancelText,
    DMT_SaveAndEditText,
    DMT_FailedRegisterEventListenerText,
    DMT_PubSubNotLoadedText,
    DMT_FailedComunicationWithServerText,
    DMT_Successtext,
    DMT_OpportunityCreatedSuccessfullyText,
    DMT_IdOpportunityNotReturnedText,
    DTM_NewOpportunityText
  };

  // =========================================================
  // State (filled by IP refresh)
  // =========================================================
  companyName = "";
  clientId = "";
  clientType = "";
  clientCode = "";
  country = "";
  isProspect = "";
  taxPayer = "";
  groupCode = "";
  clientsByGroup = [];

  /**
   * This flag is returned by the bootstrap IP.
   * If false, the user must not be allowed to create the Opportunity
   * (we show an error and disable Save).
   */
  hasBookingGeography = null;

  opportunityTypeOptions = [];
  opportunityType = "";

  name = "";

  entific = "";
  entificOptions = [];
  entity = "";
  entityOptions = [];
  entificDisabled = true;
  entityDisabled = true;


  /**
   * Controls global UI disabled state + spinner.
   * It must be set to true immediately in connectedCallback to ensure the first paint shows loading.
   */
  isLoading = false;

  /**
   * Single source of truth: we keep the last IP payload to reuse values on Save,
   * instead of re-deriving them from multiple component fields.
   */
  lastIp = null;

  // PubSub internal state
  _pubsubRegistered = false;
  _pubsubHandler = null;

  /**
   * Used to route PubSub responses to the correct handler.
   * (We have multiple actions sharing the same response event.)
   */
  _pendingAction = null;

  // =========================================================
  // Helpers
  // =========================================================
  safeStr(value) {
    return (value ?? "").toString();
  }

  boolOrNull(value) {
    return value === true ? true : value === false ? false : null;
  }

  normalizeName(value) {
    const s = this.safeStr(value);
    return s.length > NAME_MAX_LEN ? s.slice(0, NAME_MAX_LEN) : s;
  }

  /**
   * The backend provides only a raw picklist value (no label/value list).
   * lightning-combobox can only display a selected value if that value exists in `options`,
   * so we inject the received raw value into the options as { label: v, value: v }.
   */
  normalizePicklistValue(rawValue, optionsPropName) {
    const v = this.safeStr(rawValue).trim();
    if (!v) return "";

    const current = this[optionsPropName] || [];
    const exists = current.some((o) => o?.value === v);

    if (!exists) {
      this[optionsPropName] = [...current, { label: v, value: v }];
    }

    return v;
  }

  // =========================================================
  // Permission
  // =========================================================
  get showPermissionError() {
    return this.hasBookingGeography === false && !this.isNonDisclosed;
  }

  get entificWrapperClass() {
    // Used by the template to apply SLDS error styling around the disabled combobox
    return this.showPermissionError ? "slds-has-error" : "";
  }

  // =========================================================
  // UI rules
  // =========================================================
  get isNameDisabled() {
    // Name depends on a selected Opportunity Type and must be locked while loading
    return !this.opportunityType || this.isLoading;
  }

  get isSaveDisabled() {
    // Save is blocked if required fields are missing, loading is active, or permission is denied
    const needsEntificEntity = !this.isSubsidiary || this.isNonDisclosed;
    return (
      !this.opportunityType ||
      !this.name?.trim() ||
      this.isLoading ||
      this.showPermissionError ||
      (
        needsEntificEntity &&
        (!this.entific || !this.entity)
      )
    );
  }

  get showClientType() {
    return true;
  }

  get showClientCode() {
    return this.isSubsidiary;
  }

  get showGroupCode() {
    return !this.isSubsidiary;
  }

  get showCountry() {
    return (
      this.isSubsidiary &&
      Boolean((this.country || "").toString().trim())
    );
  }

  get showTaxPayer() {
    return this.isSubsidiary && !this.isProspect;
  }
  
  get showEntity() {
    return (this.isSubsidiary || this.isGroup) || this.isNonDisclosed;
  }
  
  // =========================================================
  // Global flags
  // =========================================================
  
  //Returns if the Account is a Susbsidiary, including Clients and Prospects
  get isSubsidiary() {
    return this.clientType === CLIENT_TYPE_CUSTOMER;
  }

  get isNonDisclosed() {
    return this.groupCode === "GXXXXXXXXXXXXXX";
  }

  //Returns if the Account is a Group, including Clients and Prospects
  get isGroup() {
    return this.clientType === CLIENT_TYPE_GROUP;
  }

  //Returns if the Account is a SubGroup, including Clients and Prospects
  get isSubGroup() {
    return this.clientType === CLIENT_TYPE_SUBGROUP;
  }

  get isProspectSubsidiary() {
    return this.isProspect && this.isSubsidiary;
  }

  get isProspectGroup() {
    return this.isProspect && !this.isSubsidiary;
  }

  // =========================================================
  // Lifecycle
  // =========================================================
  connectedCallback() {
    /**
     * Force initial loading state before firing any PubSub request.
     * Without this, the first render may happen before `isLoading` becomes true.
     */
    this.isLoading = true;

    // Bind once to avoid creating multiple handler references across reconnects
    this._pubsubHandler =
      this._pubsubHandler || this.handlePubSubResponse.bind(this);

    this.registerPubSubListener();
    this.loadInitialData();
  }

  disconnectedCallback() {
    // Clean up PubSub to avoid leaking listeners when the modal is destroyed
    this.unregisterPubSubListener();
  }

  // =========================================================
  // PubSub
  // =========================================================
  registerPubSubListener() {
    if (this._pubsubRegistered || !pubsub) return;

    try {
      pubsub.register(PUBSUB_CHANNEL, {
        [PUBSUB_EVENT_RESPONSE]: this._pubsubHandler
      });
      this._pubsubRegistered = true;
    } catch (error) {
      console.error("Error registering PubSub listener:", error);
      this.handleError(error, this.labels.DMT_FailedRegisterEventListenerText);
    }
  }

  unregisterPubSubListener() {
    if (!this._pubsubRegistered || !pubsub) return;

    try {
      pubsub.unregister(PUBSUB_CHANNEL, {
        [PUBSUB_EVENT_RESPONSE]: this._pubsubHandler
      });
      this._pubsubRegistered = false;
    } catch (error) {
      console.error("Error unregistering PubSub listener:", error);
    }
  }

  firePubSubEvent(payload) {
    // Centralized PubSub fire with consistent error handling
    if (!pubsub) {
      console.error("PubSub module not available");
      this.handleError(new Error(this.labels.DMT_PubSubNotLoadedText));
      return;
    }

    try {
      pubsub.fire(PUBSUB_CHANNEL, PUBSUB_EVENT_REQUEST, payload);
    } catch (error) {
      console.error("Error firing PubSub event:", error);
      this.handleError(error, this.labels.DMT_FailedComunicationWithServerText);
    }
  }

  handlePubSubResponse(response) {
    /**
     * The backend responds through a single PubSub event, so we extract the specific
     * payload node and then route it using `_pendingAction`.
     */
    const opportunityResponse = response?.OpportunityResponse;
    this.taxPayer = response?.taxpayerId;
    this.clientsByGroup = response?.clientsByGroup;
    this.companyName = this.safeStr(response?.selectedClientName);
    opportunityResponse.clientsByGroup = response?.clientsByGroup || [];

    if (!opportunityResponse) {
      const errorMsg =
        response?.error || response?.message || ERROR_FALLBACK_MESSAGE;
      this.handleError(new Error(errorMsg));
      return;
    }

    this.processResponse(opportunityResponse);

    if (opportunityResponse.refreshBoolean ) {
      this.handlerRefreshEntity(opportunityResponse);
      return; 
    }
  }

  processResponse(data) {
    /**
     * Response router: `_pendingAction` tells us which request is currently waiting.
     * We always clear `_pendingAction` in finally to prevent stale routing.
     */
    try {
      switch (this._pendingAction) {
        case ACTION_GET_OPPORTUNITY_INFO:
          this.handleBootstrapDataResponse(data);
          break;

        case ACTION_CREATE_NEW_OPPORTUNITY:
          this.handleCreateNewOpportunityResponse(data);
          break;

        case ACTION_REFRESH_ENTITY:
          this.handlerRefreshEntity(data);
          break;

        default:
          this.isLoading = false;
      }
    } finally {
      this._pendingAction = null;
    }
  }

  // =========================================================
  // Initial load
  // =========================================================
  loadInitialData() {
    // Bootstrap request: fetch everything needed to hydrate the modal UI
    this.isLoading = true;
    this._pendingAction = ACTION_GET_OPPORTUNITY_INFO;

    this.firePubSubEvent({
      action: ACTION_GET_OPPORTUNITY_INFO,
    });
  }

  handleBootstrapDataResponse(data) {
    // Hydrate component state from the IP payload and release the spinner
    this.applyRefreshPayload(data);
    this.isLoading = false;
  }

  applyRefreshPayload(refresh) {
    if (!refresh) return;

    /**
     * We keep the full IP response because Save must send fields that are not editable in the UI.
     * This avoids subtle mismatches if UI state diverges from backend state.
     */
    this.lastIp = refresh;
    const ip = refresh;
    this.entificDisabled = ip.entificDisabled !== false;
    this.entityDisabled = ip.entityDisabled !== false;  
    this.hasBookingGeography = this.boolOrNull(ip.hasBookingGeography);

    this.isProspect = ip.isProspect === true;
    //this.companyName = this.safeStr(ip.ClientName);
    this.clientId = this.safeStr(ip.clientId);
    this.clientType = this.safeStr(ip.DES_Client_Type__c);
    this.clientCode = this.safeStr(ip.clientCode);
    this.country = this.safeStr(ip.BookingGeography);
    this.groupCode = this.safeStr(ip.groupCode);
    const ipName = this.safeStr(ip.oppName);

    this.opportunityType = this.normalizePicklistValue(
      ip.RecordTypeName,
      "opportunityTypeOptions"
    );
    this.name = this.normalizeName(ipName);

    if (this.isSubsidiary) {
      if (this.isNonDisclosed) {
        this.entificOptions = Array.isArray(ip.entificOptions)
          ? ip.entificOptions.map(o => ({ value: o.value, label: `${o.value} - ${o.label}` }))
          : [];
        this.entific = this.normalizePicklistValue(ip.entificOpp, "entificOptions");
        this.entity = this.normalizePicklistValue(ip.entityOpp, "entityOptions");
        this.entificDisabled = false;
        this.entityDisabled = false;

        this._initialEntific = this.entific;
        this._initialEntity = this.entity;
      } else {
        this.entific = this.normalizePicklistValue(ip.entificOpp, "entificOptions");
        this.entity = this.normalizePicklistValue(ip.entityOpp, "entityOptions");
      }

    } else {

      this.clientsByGroup = Array.isArray(ip.clientsByGroup) ? ip.clientsByGroup : [];
      const uniqueCountries = [...new Set(this.clientsByGroup.map(c => c.country))];

      this.entificOptions = Array.isArray(ip.entificOptions)
        ? ip.entificOptions
          .filter(o => uniqueCountries.includes(o.value))
          .map(o => ({
            value: o.value,
            label: `${o.value} - ${o.label}`
          }))
        : [];

      let finalEntific = "";

      if (this.entificOptions.some(o => o.value === ip.entificOpp)) {
        finalEntific = ip.entificOpp;
      } else {
        finalEntific = this.entificOptions.length > 0
          ? this.entificOptions[0].value
          : "";
      }

      this.entific = finalEntific;

      if (!this.entificOptions.length) {
        this.entific = null;
        this.entity = null;
        this.entificDisabled = true;
        this.entityOptions = [];
        this.entityDisabled = true;
        return;
      }

      const entificChanged = finalEntific !== ip.entificOpp;

      if (!entificChanged) {
        this.entityOptions = Array.isArray(ip.entityOptions)
          ? ip.entityOptions.map(o => ({
            value: o.value,
            label: `${o.value} - ${o.label}`
          }))
          : [];

        this.entity = this.normalizePicklistValue(ip.entityOpp, "entityOptions");

      } else {
        this.entity = "";
        this.entityOptions = [];
        this.entityDisabled = true;

        if (finalEntific) {
          this.isLoading = true;
          this._pendingAction = ACTION_REFRESH_ENTITY;

          this.firePubSubEvent({
            action: ACTION_REFRESH_ENTITY,
            entific: finalEntific
          });
        }
      }

      
    }
  }

  // =========================================================
  // Create Opportunity response
  // =========================================================
  handleCreateNewOpportunityResponse(data) {
    /**
     * This integration returns `error` as a status string.
     * We treat anything different from OK as a blocking error.
     */
    const resultError = data?.error;
    if (resultError && resultError !== RESULT_OK) {
      this.handleError(new Error(resultError || ERROR_FALLBACK_MESSAGE));
      return;
    }

    const newId = data?.IPResult?.createdId;
    if (newId) {
      window.open(`/${newId}`, "_blank");

      // Optional refresh hook for the host console after creation
      this._pendingAction = ACTION_REFRESH_DATA;
      this.firePubSubEvent({ action: ACTION_REFRESH_DATA });

      this.toastEvent(this.labels.DMT_Successtext, this.labels.DMT_OpportunityCreatedSuccessfullyText, "success");
      this.close();
      return;
    }

    this.handleError(new Error(this.labels.DMT_IdOpportunityNotReturnedText));    
  }

  handlerRefreshEntity(data) {
    this.entity = "";

    const options = Array.isArray(data?.entityOptions)
      ? data.entityOptions.map(o => ({
        value: o.value,
        label: `${o.value} - ${o.label}`
      }))
      : [];

    this.entityOptions = [...options];

    if (this.entityOptions.length > 0) {
      this.entity = this.entityOptions[0].value;
    }
    this.entityDisabled = this.entityOptions.length === 0;

    this.isLoading = false;
  }

  // =========================================================
  // Handlers
  // =========================================================
  handleNameChange(event) {
    this.name = this.normalizeName(event.detail.value || "");
  }

  handleCancel() {
    this.close();
  }

  handleOpportunityTypeChange(event) {
    this.opportunityType = event.detail.value;
  }

  handleEntificChange(event) {
    this.entific = event.detail.value;

    if (!this.isSubsidiary || this.isNonDisclosed) {

      if (this.isNonDisclosed && this.entific === this._initialEntific) {
        this.entity = this._initialEntity;
        return;
      }
      
      this.entity = "";
      this.entityOptions = [];
      this.entityDisabled = true;
      const payload = {
        action: ACTION_REFRESH_ENTITY,
        entific: this.entific
      };

      this.isLoading = true;
      this._pendingAction = ACTION_REFRESH_ENTITY;

      this.firePubSubEvent(payload);
    }

  }

  handleEntityChange(event) {
    this.entity = event.detail.value;
  }

  // =========================================================
  // Save & Edit: Create New Opportunity (PubSub)
  // =========================================================
  handleSaveAndEdit() {
    if (this.isSaveDisabled) return;

    /**
     * Build payload using both UI selections and immutable fields from the bootstrap IP.
     * This ensures the server receives the full context needed to create the record.
     */
    const ip = this.lastIp || {};
    let entityToSend = "";

    if (this.clientType !== CLIENT_TYPE_CUSTOMER) {
      entityToSend = this.entity;
    } else {
      entityToSend = this.entity ? this.entity.trim().substring(0, 6) : "";
    }

    const payload = {
      action: ACTION_CREATE_NEW_OPPORTUNITY,
      RecordTypeName: "DMT_Opportunity",
      Name: this.name,
      StartDate: ip.StartDate,
      EndDate: ip.EndDate,
      ClientId: this.clientId,
      BookingGeography: this.isNonDisclosed ? this.entific : ip.BookingGeography,
      generalClientCode: ip.generalClientCode,
      groupCode: ip.groupCode,
      oppEntity: entityToSend,
      Segment: ip.Segment,
      ClientName: this.companyName,
      entific: this.entific,
      clientType: this.clientType,
      clientsByGroup: this.clientsByGroup
    };

    this.isLoading = true;
    this._pendingAction = ACTION_CREATE_NEW_OPPORTUNITY;

    this.firePubSubEvent(payload);
  }

  // =========================================================
  // Toast / Error
  // =========================================================
  toastEvent(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  handleError(error, customTitle = ERROR_TITLE) {
    // Centralized error handler: always releases loading state and clears pending action
    console.error("Modal error:", JSON.stringify(error));
    const msg =
      error?.message ||
      error?.body?.message ||
      (typeof error === "string" ? error : ERROR_FALLBACK_MESSAGE);

    this.toastEvent(customTitle, msg, "error");
    this.isLoading = false;
    this._pendingAction = null;
  }
}