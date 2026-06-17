import { api } from "lwc";
import LightningModal from "lightning/modal";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import pubsub from "omnistudio/pubsub";

// Labels
import DMT_titleRenewLine from "@salesforce/label/c.dmt_cl_Renew_Line";
import DMT_LineType from "@salesforce/label/c.dmt_cl_Line_Type";
import DMT_Name from "@salesforce/label/c.dmt_cl_NameLine";
import DMT_ClientType from "@salesforce/label/c.dmt_cl_ClientType";
import DMT_ClientCode from "@salesforce/label/c.dmt_cl_Client_Code";
import DMT_GroupCode from "@salesforce/label/c.dmt_cl_Group_Code";
import DMT_Country from "@salesforce/label/c.dmt_cl_Country";
import DMT_TaxPayer from "@salesforce/label/c.dmt_cl_Tax_Payer";
import DMT_ProductsRenew from "@salesforce/label/c.dmt_cl_Products_renew";
import DMT_AccountText from "@salesforce/label/c.Account";
import DMT_SelectLineTypText from "@salesforce/label/c.dmt_cl_SelectLineType_Text";
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
import DMT_LineCreatedSuccessfullyText from "@salesforce/label/c.DMT_LineCreatedSuccessfully";
import DMT_IdLineNotReturnedText from "@salesforce/label/c.DMT_IdLineNotReturnedText";

// =========================================================
// Constants
// =========================================================
const CLIENT_TYPE_CUSTOMER = "Customer";
const NAME_MAX_LEN = 50;

const ERROR_TITLE = DMT_UnexpectedErrorText;
const ERROR_FALLBACK_MESSAGE = DMT_ErrorContactAdministratorText;

// Actions (payload.action)
const ACTION_RENEW_LINE = "RENEW_LINE";
const ACTION_CREATE_RENEWLINE = "CREATE_RENEW_LINE";
const ACTION_REFRESH_DATA = "REFRESH_DATA";

// PubSub Configuration
const PUBSUB_CHANNEL = "DMT_MarcoGeneral";
const PUBSUB_EVENT_REQUEST = "LineManagement";
const PUBSUB_EVENT_RESPONSE = "CreateLineResponse";

export default class DmtRenewLineModal extends LightningModal {
  // =========================================================
  // Public API
  // =========================================================
  @api lineId = null;

  labels = {
    DMT_ProductsRenew,
    DMT_titleRenewLine,
    DMT_LineType,
    DMT_Name,
    DMT_ClientType,
    DMT_ClientCode,
    DMT_GroupCode,
    DMT_Country,
    DMT_TaxPayer,
    DMT_AccountText,
    DMT_SelectLineTypText,
    DMT_CancelText,
    DMT_SaveAndEditText,
    DMT_TreasuryText,
    DMT_LineOtherProductsText,
    DMT_FailedRegisterEventListenerText,
    DMT_PubSubNotLoadedText,
    DMT_FailedComunicationWithServerText,
    DMT_SuccessText,
    DMT_LineCreatedSuccessfullyText,
    DMT_IdLineNotReturnedText
  };

  // =========================================================
  // State (filled by IP refresh)
  // =========================================================
  companyName = "";
  clientId = "";
  clientType = "";
  clientCode = "";
  groupCode = "";
  country = "";
  taxPayer = "";

  productsValids = [];

  lineTypeOptions = [
    { label: this.labels.DMT_TreasuryText, value: "TreasurySettlement" },
    { label: this.labels.DMT_LineOtherProductsText, value: "OtherProducts" }
  ];

  lineType = "";
  name = "";

  isLoading = false;

  /**
   * Stores the latest backend payload as the single source of truth.
   * This allows Save to reuse backend fields without re-deriving them from UI state.
   */
  lastIp = null;

  // Accordion state products (null/undefined means collapsed)
  activeSection = null;

  // PubSub internal state
  _pubsubRegistered = false;

  /**
   * Stable handler reference used for register/unregister to prevent listener leaks.
   */
  _pubsubHandler = null;

  /**
   * Used to route the single PubSub response event to the correct handler.
   */
  _pendingAction = null;

  handleToggle(event) {
    // Only one section is expected to be open at a time; we keep the first open section.
    const openSections = event.detail.openSections;
    this.activeSection = openSections.length ? openSections[0] : null;
  }

  // =========================================================
  // Lifecycle
  // =========================================================
  connectedCallback() {
    // Bind once to keep the handler reference stable across the modal lifecycle.
    this._pubsubHandler =
      this._pubsubHandler || this.handlePubSubResponse.bind(this);

    this.registerPubSubListener();
    this.loadInitialData();
  }

  disconnectedCallback() {
    // Always unregister to avoid keeping listeners alive after the modal is destroyed.
    this.unregisterPubSubListener();
  }

  // =========================================================
  // PubSub: Register / Unregister
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
    // Centralized PubSub fire with consistent error handling.
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
  // PubSub: Handle response
  // =========================================================
  handlePubSubResponse(response) {
    // Backend response is expected under response.LineResponse.
    const lineResponse = response?.LineResponse;
    this.taxPayer = response?.taxpayerId;


    if (!lineResponse) {
      const errorMsg =
        response?.error || response?.message || ERROR_FALLBACK_MESSAGE;
      this.handleError(new Error(errorMsg));
      return;
    }

    this.processResponse(lineResponse);
  }

  processResponse(data) {
    /**
     * PubSub responses come through a single event.
     * `_pendingAction` routes the payload to the correct handler.
     * `_pendingAction` is cleared in finally to avoid stale routing on later responses.
     */
    try {
      switch (this._pendingAction) {
        case ACTION_RENEW_LINE:
          this.handleBootstrapDataResponse(data);
          break;

        case ACTION_CREATE_RENEWLINE:
          this.handleCreateRenewLineResponse(data);
          break;

        default:
          this.isLoading = false;
      }
    } finally {
      this._pendingAction = null;
    }
  }

  // =========================================================
  // Initial load / bootstrap
  // =========================================================
  loadInitialData() {
    // Bootstrap request: fetch everything needed to hydrate the modal.
    this.isLoading = true;
    this._pendingAction = ACTION_RENEW_LINE;

    this.firePubSubEvent({
      action: ACTION_RENEW_LINE,
      lineId: this.lineId
    });
  }

  handleBootstrapDataResponse(data) {
    // The integration returns an array and the first element contains the payload for the modal.
    this.applyRefreshPayload(data[0]);
    this.isLoading = false;
  }

  // =========================================================
  // Create Renew line response
  // =========================================================
  handleCreateRenewLineResponse(data) {
    // Creation errors may come either from IPResult or from the root response.
    const resultError = data?.IPResult?.error || data?.error;

    if (resultError) {
      const msg =
        data?.IPResult?.message || data?.message || ERROR_FALLBACK_MESSAGE;
      this.toastEvent(ERROR_TITLE, msg, "error");
      this.isLoading = false;
      return;
    }

    const newId = data?.IPResult?.createdId;
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
  // Left panel visibility
  // =========================================================
  get showClientType() {
    return true;
  }

  get showClientCode() {
    return this.clientType === CLIENT_TYPE_CUSTOMER;
  }

  get showGroupCode() {
    return this.clientType !== CLIENT_TYPE_CUSTOMER;
  }

  get showCountry() {
    return (
      this.clientType === CLIENT_TYPE_CUSTOMER &&
      Boolean((this.country || "").toString().trim())
    );
  }

  get showTaxPayer() {
    return this.clientType === CLIENT_TYPE_CUSTOMER;
  }

  // =========================================================
  // UI rules
  // =========================================================
  get isNameDisabled() {
    // Name is enabled only after Line Type is present and while not loading.
    return !this.lineType || this.isLoading;
  }

  get isSaveDisabled() {
    // Save requires Line Type + a non-empty Name and must be locked while loading.
    return !this.lineType || !this.name?.trim() || this.isLoading;
  }

  get companyHref() {
    const id = (this.clientId || "").toString().trim();
    return id ? `/${id}` : "#";
  }

  get validItems() {
    /**
     * Product list comes as string flags ("true"/"false").
     * We filter only the valid ones and normalize the disabled flag for template usage.
     */
    return (this.productsValids || [])
      .filter((x) => x?.value === "true")
      .map((x) => ({
        ...x,
        isDisabled: x?.disabled === "true"
      }));
  }

  get hasValidItems() {
    return this.validItems.length > 0;
  }

  // =========================================================
  // Helpers
  // =========================================================
  normalizeName(value) {
    const s = (value ?? "").toString();
    return s.length > NAME_MAX_LEN ? s.slice(0, NAME_MAX_LEN) : s;
  }

  applyRefreshPayload(refresh) {
    if (!refresh) return;

    /**
     * The modal uses the full backend payload as the single source of truth.
     * This keeps UI fields aligned with the server state, and allows Save to reuse fields safely.
     */
    this.lastIp = refresh;
    const ip = refresh;

    this.productsValids = Array.isArray(ip.productList) ? ip.productList : [];
    this.companyName = (ip.ClientName ?? "").toString();
    this.clientId = (ip.clientId ?? "").toString();
    this.clientType = (ip.DES_Client_Type__c ?? "").toString();
    this.clientCode = (ip.clientCode ?? "").toString();
    this.groupCode = (ip.groupCode ?? "").toString();
    this.country = (ip.Booking_Geography__c ?? "").toString();

    const ipName = ip.lineName ?? "";
    this.lineType = ip.RecordTypeName;
    this.name = this.normalizeName(ipName);
  }

  toastEvent(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  handleError(error, customTitle = ERROR_TITLE) {
    // Centralized error handler: releases loading state and clears pending routing.
    console.error("Error occurred:", error);

    const msg =
      error?.message ||
      error?.body?.message ||
      (typeof error === "string" ? error : ERROR_FALLBACK_MESSAGE);

    this.toastEvent(customTitle, msg, "error");
    this.isLoading = false;
    this._pendingAction = null;
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

  // =========================================================
  // Create Renew line (PubSub)
  // =========================================================
  handleSaveAndEdit() {
    if (this.isSaveDisabled) return;

    /**
     * Create payload is built from the last backend response plus the edited name.
     * This ensures all required fields are present without duplicating mapping logic.
     */
    const ip = { ...(this.lastIp || {}), lineName: this.name };

    this.isLoading = true;
    this._pendingAction = ACTION_CREATE_RENEWLINE;

    this.firePubSubEvent({
      action: ACTION_CREATE_RENEWLINE,
      records: ip,
      approvalData: ip.approvalData
    });
  }
}