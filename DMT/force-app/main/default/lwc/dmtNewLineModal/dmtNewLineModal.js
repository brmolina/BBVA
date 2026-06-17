import { api } from "lwc";
import LightningModal from "lightning/modal";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import pubsub from "omnistudio/pubsub";

// Labels
import DMT_permissionErrorMessage from "@salesforce/label/c.dmt_cl_Entific_Error";
import DMT_titleNewLine from "@salesforce/label/c.dmt_cl_NewLine";
import DMT_LineType from "@salesforce/label/c.dmt_cl_Line_Type";
import DMT_Name from "@salesforce/label/c.dmt_cl_NameLine";
import DMT_Entific from "@salesforce/label/c.dmt_cl_Entific_Label";
import DMT_ClientType from "@salesforce/label/c.dmt_cl_ClientType";
import DMT_ClientCode from "@salesforce/label/c.dmt_cl_Client_Code";
import DMT_GroupCode from "@salesforce/label/c.dmt_cl_Group_Code";
import DMT_Country from "@salesforce/label/c.dmt_cl_Country";
import DMT_TaxPayer from "@salesforce/label/c.dmt_cl_Tax_Payer";
import DMT_AccountText from "@salesforce/label/c.Account";
import DMT_SelectTypeLineText from "@salesforce/label/c.dmt_cl_SelectLineType_Text";
import DMT_SelectWithTreePints from "@salesforce/label/c.DMT_SeltectWithTreePointText";
import DMT_CancelText from "@salesforce/label/c.Arc_Gen_CancelLA_Lab";
import DMT_SaveAndEditText from "@salesforce/label/c.DMT_SaveAndEditText";
import DMT_UnexpectedErrorText from "@salesforce/label/c.DMT_UnexpectedErrorText";
import DMT_ErrorContactAdministratorText from "@salesforce/label/c.DMT_ErrorContactAdministratorText";
import DMT_TreasuryText from "@salesforce/label/c.DMT_TreasuryText";
import DMT_LineOtherProductsText from "@salesforce/label/c.DMT_LineOtherProductsText";
import DMT_FailedRegisterEventListenerText from "@salesforce/label/c.DMT_FailedRegisterEventListenerText";
import DMT_PubSubNotLoadedText from "@salesforce/label/c.DMT_PubSubNotLoadedText";
import DMT_FailedComunicationWithServerText from "@salesforce/label/c.DMT_FailedComunicationWithServerText";
import DMT_SuccessText from "@salesforce/label/c.Success";
import DMT_LineCreatedSuccessfully from "@salesforce/label/c.DMT_LineCreatedSuccessfully";
import DMT_IdLineNotReturnedText from "@salesforce/label/c.DMT_IdLineNotReturnedText";


// =========================================================
// Constants
// =========================================================
const CLIENT_TYPE_SUBSIDIARY = "Subsidiary";
const CLIENT_TYPE_GROUP = "CIB Group";
const CLIENT_TYPE_SUBGROUP = "Subgroup";

const NAME_MAX_LEN = 50;
const RESULT_OK = "OK";

const ERROR_TITLE = DMT_UnexpectedErrorText;
const ERROR_FALLBACK_MESSAGE = DMT_ErrorContactAdministratorText;

// Actions sent to the FlexCard / Integration Procedure via PubSub
const ACTION_CREATE_LINE = "CREATE_LINE_IP";
const ACTION_CREATE_NEWLINE = "CREATE_NEWLINE";
const ACTION_REFRESH_DATA = "REFRESH_DATA";

// PubSub Configuration
const PUBSUB_CHANNEL = "DMT_MarcoGeneral";
const PUBSUB_EVENT_REQUEST = "LineManagement";
const PUBSUB_EVENT_RESPONSE = "CreateLineResponse";

// Static Line Type combobox options
const LINE_TYPE_OPTIONS = [
  { label: DMT_TreasuryText, value: "TreasurySettlement" },
  { label: DMT_LineOtherProductsText, value: "OtherProducts" }
];

export default class NewLineModal extends LightningModal {
  // =========================================================
  // Public API
  // =========================================================

  labels = {
    DMT_permissionErrorMessage,
    DMT_titleNewLine,
    DMT_LineType,
    DMT_Name,
    DMT_Entific,
    DMT_ClientType,
    DMT_ClientCode,
    DMT_GroupCode,
    DMT_Country,
    DMT_TaxPayer,
    DMT_AccountText,
    DMT_SelectTypeLineText,
    DMT_SelectWithTreePints,
    DMT_CancelText,
    DMT_SaveAndEditText,
    DMT_FailedRegisterEventListenerText,
    DMT_PubSubNotLoadedText,
    DMT_FailedComunicationWithServerText,
    DMT_SuccessText,
    DMT_LineCreatedSuccessfully,
    DMT_IdLineNotReturnedText
  };

  // =========================================================
  // State
  // =========================================================
  companyName = "";
  clientId = "";
  clientType = "";
  clientCode = "";
  groupCode = "";
  country = "";
  taxPayer = "";
  isProspect = "";

  lineTypeOptions = LINE_TYPE_OPTIONS;
  entificOptions = [];

  lineType = "";
  name = "";
  entific = "";




  isLoading = false;
  hasBookingGeography = null;

  /**
   * Keeps the latest backend payload as the single source of truth for "Save & Edit".
   */
  lastIp = null;

  // PubSub internal state
  _pubsubRegistered = false;
  /**
   * Used to route a single PubSub response event into the correct handler.
   */
  _pendingAction = null;
  /**
   * Stable handler reference used for register/unregister.
   */
  _pubsubHandler = null;

  // =========================================================
  // Lifecycle
  // =========================================================
  connectedCallback() {
    this._pubsubHandler =
      this._pubsubHandler || this.handlePubSubResponse.bind(this);
    console.log('connect');
    this.registerPubSubListener();console.log('connect1');
    this.loadInitialData();console.log('connect2');
  }

  disconnectedCallback() {
    this.unregisterPubSubListener();
  }

  // =========================================================
  // PubSub: Register listener
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

  // =========================================================
  // PubSub: Unregister listener
  // =========================================================
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

  // =========================================================
  // PubSub: Fire event to FlexCard
  // =========================================================
  firePubSubEvent(payload) {
    // Centralized PubSub fire to keep error handling consistent.
    if (!pubsub) {
      console.error("PubSub not available");
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

  // =========================================================
  // PubSub: Handle response from FlexCard/IP
  // =========================================================
  handlePubSubResponse(response) {
    // Backend response is expected under response.LineResponse.
    const lineResponse = response?.LineResponse;
    this.taxPayer = response?.taxpayerId;
        console.log(response?.taxpayerId, 'taxPayer: ', JSON.stringify(this.taxPayer))
    this.companyName = this.safeStr(response?.selectedClientName);
        console.log(response?.selectedClientName, 'selectedClientName: ', JSON.stringify(this.selectedClientName))

    this.lastIp = lineResponse?.lastIp;

    if (!lineResponse) {
      const errorMsg =
        response?.error || response?.message || ERROR_FALLBACK_MESSAGE;
      this.handleError(new Error(errorMsg));
      return;
    }

    this.processResponse(lineResponse);
  }

  // =========================================================
  // Process response based on pending action
  // =========================================================
  processResponse(data) {
    try {
      switch (this._pendingAction) {
        case ACTION_CREATE_LINE:
          this.handleBootstrapDataResponse(data);console.log('thi.pendingaction',this._pendingAction)
          break;

        case ACTION_CREATE_NEWLINE:
          this.handleCreateNewLineResponse(data);
          break;

        default:
          this.isLoading = false;
      }
    } finally {
      this._pendingAction = null;
    }
  }

  // =========================================================
  // Bootstrap / hydrate modal data from IP response
  // =========================================================
  handleBootstrapDataResponse(data) {
    // Bootstrap fills the fields needed to render the modal (left panel + picklists).
    this.applyRefreshPayload(data);
    this.isLoading = false;
  }

  // =========================================================
  // Handle CREATE_NEWLINE response
  // =========================================================
  handleCreateNewLineResponse(data) {
    const resultError = data?.error;
    if (resultError && resultError !== RESULT_OK) {
      this.handleError(new Error(resultError || ERROR_FALLBACK_MESSAGE));
      return;
    }

    /**
     * The created Id may come in different shapes depending on the IP mapping.
     * We try multiple known paths to keep the client resilient.
     */
    const newId =
      data?.DMT_Line__c_1?.Id ||
      data?.IPResult?.createdId ||
      data?.IPResult?.DMT_Line__c_1?.Id ||
      data?.createdId;

    if (newId) {
      window.open(`/${newId}`, "_blank");

      // Notify host context to refresh after creation.
      this._pendingAction = ACTION_REFRESH_DATA;
      this.firePubSubEvent({ action: ACTION_REFRESH_DATA });

      this.toastEvent(this.labels.DMT_SuccessText, this.labels.DMT_LineCreatedSuccessfully, "success");
      this.close();
    } else {
      this.handleError(new Error(this.labels.DMT_IdLineNotReturnedText));
      return;
    }

    this.isLoading = false;
  }

  // =========================================================
  // Error handler (centralized)
  // =========================================================
  handleError(error, customTitle = ERROR_TITLE) {
    console.error("Error occurred:", error);

    let errorMessage = ERROR_FALLBACK_MESSAGE;
    if (error?.message) errorMessage = error.message;
    else if (error?.body?.message) errorMessage = error.body.message;
    else if (typeof error === "string") errorMessage = error;

    this.toastEvent(customTitle, errorMessage, "error");
    this.isLoading = false;
    this._pendingAction = null;
  }

  // =========================================================
  // Load initial data using PubSub
  // =========================================================
  loadInitialData() {
    // Initial bootstrap call to obtain client data and entific options.
    this.isLoading = true;
    this._pendingAction = ACTION_CREATE_LINE;
    this.firePubSubEvent({ action: ACTION_CREATE_LINE });
  }

  // =========================================================
  // Left panel visibility
  // =========================================================
  get showClientType() {
    return true;
  }

  get showClientCode() {
    return this.isSubsidiary;
  }

  get showGroupCode() {
    return (
      this.isGroup ||
      this.isSubGroup
    );
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

  // =========================================================
  // Global flags
  // =========================================================
  
  //Returns if the Account is a Susbsidiary, including Clients and Prospects
  get isSubsidiary() {
    return this.clientType === CLIENT_TYPE_SUBSIDIARY;
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
  // UI rules
  // =========================================================
  get isNameDisabled() {
    return !this.lineType || this.isLoading || this.hasBookingGeography === false;
  }

  get isEntificDisabled() {
    return !this.lineType || this.isLoading || this.hasBookingGeography === false;
  }

  get showPermissionError() {
    // Show permission error only after the user selected a line type.
    return Boolean(this.lineType && this.hasBookingGeography === false);
  }

  get entificWrapperClass() {
    return this.showPermissionError
      ? "slds-form-element slds-has-error"
      : "slds-form-element";
  }

  get isSaveDisabled() {
    return (
      !this.lineType ||
      !this.name?.trim() ||
      !this.entific ||
      this.isLoading ||
      this.hasBookingGeography === false
    );
  }

  get companyHref() {
    const id = (this.clientId || "").toString().trim();
    return id ? `/${id}` : "#";
  }

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
    const s = (value ?? "").toString();
    return s.length > NAME_MAX_LEN ? s.slice(0, NAME_MAX_LEN) : s;
  }

  /**
   * Formats entific labels as "value - label" while keeping the original `value`.
   */
  normalizeEntificOptions(options) {
    if (!Array.isArray(options)) return [];

    return options.map((opt) => {
      const value = (opt?.value ?? "").toString().trim();
      const label = (opt?.label ?? "").toString().trim();

      if (!value) return opt;

      return {
        ...opt,
        value,
        label: label ? `${value} - ${label}` : value
      };
    });
  }

  applyRefreshPayload(refresh) {console.log('refres',refresh);
    if (!refresh) return;

    console.log('jimmy data: ', JSON.stringify(refresh));

    // Persist backend payload to reuse required fields during Save.
    this.lastIp = refresh;

    this.hasBookingGeography = this.boolOrNull(refresh.hasBookingGeography);

    // Entific options may require label formatting for the combobox.
    this.entificOptions = this.normalizeEntificOptions(refresh.count);

    this.entific = refresh.BookingGeography || "";
    this.isProspect = refresh.isProspect === true;
    //this.companyName = this.safeStr(refresh.ClientName);
    this.clientId = this.safeStr(refresh.clientId);
    this.clientType = this.safeStr(refresh.DES_Client_Type__c);
    this.clientCode = this.safeStr(refresh.clientCode);
    this.groupCode = this.safeStr(refresh.groupCode);
    this.country = this.safeStr(refresh.countryIfoId);

    const ipName = refresh.lineName ?? refresh.LineName ?? "";
    this.name = this.normalizeName(ipName);
  }

  toastEvent(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  // =========================================================
  // Handle line type change using PubSub
  // =========================================================
  handleLineTypeChange(event) {
    /**
     * Changing line type triggers a backend refresh to recalculate:
     * - permissions (hasBookingGeography)
     * - entific options
     * - any dependent default values
     */
    this.lineType = event.detail.value;
    this.entific = "";
    this.hasBookingGeography = null;

    this.isLoading = true;
    this._pendingAction = ACTION_CREATE_LINE;

    this.firePubSubEvent({
      action: ACTION_CREATE_LINE,
      RecordTypeName: this.lineType
    });
  }

  handleNameChange(event) {
    this.name = this.normalizeName(event.detail.value || "");
  }

  handleEntificChange(event) {
    this.entific = event.detail.value;
  }

  handleCancel() {
    this.close();
  }

  // =========================================================
  // Create new line using PubSub
  // =========================================================
  handleSaveAndEdit() {
    if (this.isSaveDisabled) return;

    /**
     * Payload mixes editable fields (name/entific) with backend-provided fields from `lastIp`.
     * This ensures the server receives the full context required for creation.
     */
    const ip = this.lastIp || {};

    this.isLoading = true;
    this._pendingAction = ACTION_CREATE_NEWLINE;

    this.firePubSubEvent({
      action: ACTION_CREATE_NEWLINE,
      RecordTypeName: ip.RecordTypeName || this.lineType,
      lineName: this.name,
      StartDate: ip.StartDate,
      EndDate: ip.EndDate,
      ClientId: ip.clientId ?? ip.ClientId,
      BookingGeography: this.entific,
      generalClientCode: ip.generalClientCode,
      countryIfoId: this.entific
    });
  }
}