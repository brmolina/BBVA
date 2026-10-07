import { api } from "lwc";
import LightningModal from "lightning/modal";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getLineCreationParameters from "@salesforce/apex/DMT_CreateLineService.getLineCreationParameters";
import createLine from "@salesforce/apex/DMT_CreateLineService.createLine";

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
const CLIENT_TYPE_SINGLE_CLIENT_LABEL = "Single client";
const CLIENT_TYPE_MULTI_CLIENT_LABEL = "Multi-client";

const NAME_MAX_LEN = 50;

const ERROR_TITLE = DMT_UnexpectedErrorText;
const ERROR_FALLBACK_MESSAGE = DMT_ErrorContactAdministratorText;

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
    DMT_FailedComunicationWithServerText,
    DMT_SuccessText,
    DMT_LineCreatedSuccessfully,
    DMT_IdLineNotReturnedText
  };

  // =========================================================
  // Public API (provided by the opener component)
  // =========================================================
  @api clientId;
  @api groupId;
  @api taxPayer;
  // =========================================================
  // State
  // =========================================================
  companyName = "";
  clientType = "";
  clientCode = "";
  groupCode = "";
  country = "";
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

    let errorMessage = ERROR_FALLBACK_MESSAGE;
    if (error?.body?.message) errorMessage = error.body.message;
    else if (error?.message) errorMessage = error.message;
    else if (typeof error === "string") errorMessage = error;

    this.toastEvent(customTitle, errorMessage, "error");
    this.isLoading = false;
  }

  // =========================================================
  // Load initial data / refresh creation parameters via Apex
  // =========================================================
  async loadInitialData(recordTypeName) {
    this.isLoading = true;
    try {
      const result = await getLineCreationParameters({
        clientId: this.clientId,
        groupId: this.groupId,
        recordTypeName: recordTypeName || null
      });
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
    get clientTypeLabel() {
    if (this.isSubsidiary) {
      return CLIENT_TYPE_SINGLE_CLIENT_LABEL;
    }

    if (this.isGroup) {
      return CLIENT_TYPE_MULTI_CLIENT_LABEL;
    }

    return this.clientType;
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

  applyRefreshPayload(refresh) {
    if (!refresh) return;
    // Persist backend payload to reuse required fields during Save.
    this.lastIp = refresh;

    this.hasBookingGeography = this.boolOrNull(refresh.hasBookingGeography);

    // Entific options may require label formatting for the combobox.
    this.entificOptions = this.normalizeEntificOptions(refresh.count);

    this.entific = refresh.BookingGeography || "";
    this.isProspect = refresh.isProspect === true;
    //this.companyName = this.safeStr(refresh.ClientName);
    if (refresh.clientId) {
      this.clientId = this.safeStr(refresh.clientId);
    }
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
  // Handle line type change (reload creation parameters via Apex)
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

    this.loadInitialData(this.lineType);
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
  // Create new line via Apex
  // =========================================================
  async handleSaveAndEdit() {
    if (this.isSaveDisabled) return;

    /**
     * Payload mixes editable fields (name/entific) with backend-provided fields from `lastIp`.
     * This ensures the server receives the full context required for creation.
     */
    const ip = this.lastIp || {};

    this.isLoading = true;

    try {
      const newId = await createLine({
        recordTypeName: ip.RecordTypeName || this.lineType,
        lineName: this.name,
        startDate: ip.StartDate,
        endDate: ip.EndDate,
        clientId: ip.clientId || this.clientId,
        bookingGeography: this.entific,
        generalClientCode: ip.generalClientCode,
        countryIfoId: this.entific
      });

      if (!newId) {
        this.handleError(new Error(this.labels.DMT_IdLineNotReturnedText));
        return;
      }

      window.open(`/${newId}`, "_blank");
      this.toastEvent(this.labels.DMT_SuccessText, this.labels.DMT_LineCreatedSuccessfully, "success");
      this.close(newId);
    } catch (error) {
      this.handleError(error, this.labels.DMT_FailedComunicationWithServerText);
      return;
    }

    this.isLoading = false;
  }
}