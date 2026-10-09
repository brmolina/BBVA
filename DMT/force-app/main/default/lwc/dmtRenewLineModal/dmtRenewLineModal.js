import { api } from "lwc";
import LightningModal from "lightning/modal";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getLineForRenewal from "@salesforce/apex/DMT_RenewLineService.getLineForRenewal";
import renewLine from "@salesforce/apex/DMT_RenewLineService.renewLine";

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

  handleToggle(event) {
    // Only one section is expected to be open at a time; we keep the first open section.
    const openSections = event.detail.openSections;
    this.activeSection = openSections.length ? openSections[0] : null;
  }

  // =========================================================
  // Lifecycle
  // =========================================================
  connectedCallback() {
    this.loadInitialData();
  }

  // =========================================================
  // Error handler (centralized)
  // =========================================================
  handleError(error, customTitle = ERROR_TITLE) {
    console.error("Error occurred:", error);

    const msg =
      error?.body?.message ||
      error?.message ||
      (typeof error === "string" ? error : ERROR_FALLBACK_MESSAGE);

    this.toastEvent(customTitle, msg, "error");
    this.isLoading = false;
  }

  // =========================================================
  // Initial load / bootstrap via Apex
  // =========================================================
  async loadInitialData() {
    this.isLoading = true;
    try {
      const result = await getLineForRenewal({ lineId: this.lineId });
      this.applyRefreshPayload(result);
    } catch (error) {
      this.handleError(error, this.labels.DMT_FailedComunicationWithServerText);
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
  // Create Renew line via Apex
  // =========================================================
  async handleSaveAndEdit() {
    if (this.isSaveDisabled) return;

    this.isLoading = true;

    try {
      const newId = await renewLine({
        lineId: this.lineId,
        lineName: this.name
      });

      if (!newId) {
        this.handleError(new Error(this.labels.DMT_IdLineNotReturnedText));
        return;
      }

      window.open(`/${newId}`, "_blank");
      this.toastEvent(this.labels.DMT_SuccessText, this.labels.DMT_LineCreatedSuccessfullyText, "success");
      this.close(newId);
    } catch (error) {
      this.handleError(error, this.labels.DMT_FailedComunicationWithServerText);
      return;
    }

    this.isLoading = false;
  }
}