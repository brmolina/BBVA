import { api } from "lwc";
import LightningModal from "lightning/modal";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import getRenewOpportunityData from "@salesforce/apex/DMT_OpportunityRenewUtil.getRenewOpportunityData";
import renewOpportunity from '@salesforce/apex/DMT_OpportunityRenewUtil.renewOpportunity';



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
import DMT_ProductsRenew from "@salesforce/label/c.dmt_cl_Products_renew";

// =========================================================
// Constants
// =========================================================
const CLIENT_TYPE_SUBSIDIARY = "Subsidiary";

const NAME_MAX_ALLOWED = 50;
const NAME_MAX_VISIBLE = 51;

const ERROR_TITLE = DMT_UnexpectedErrorText;
const ERROR_FALLBACK_MESSAGE = DMT_ErrorContactAdministratorText;

const NAME_TOO_LONG_MESSAGE = "Only 50 characters are allowed.";

export default class dmtRenewOpportunityModal extends LightningModal {
  // =========================================================
  // Labels
  // =========================================================
  labels = {
    DMT_permissionErrorMessage,
    DMT_Entific,
    DMT_Name,
    DMT_ClientType,
    DMT_ClientCode,
    DMT_GroupCode,
    DMT_Country,
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
    DMT_ProductsRenew
  };

  // =========================================================
  // State
  // =========================================================
  isLoading = false;
  opportunity;

  companyName = "";
  clientId = "";
  clientType = "";
  clientCode = "";
  country = "";

  opportunityTypeOptions = [];
  opportunityType = "";

  name = "";
  nameErrorMessage = "";

  entific = "";
  entificOptions = [];
  entificDisabled = true;

  entity = "";
  entityOptions = [];
  entityDisabled = true;

  showPermissionError = false;

  products = [];
  showProducts = false;
  activeSection = null;

  // =========================================================
  // API: opportunityInfo
  // =========================================================
  @api
  get opportunityInfo() {
    return this.opportunity;
  }
  set opportunityInfo(value) {
    this.opportunity = value;
    this.initializeData();
  }

  // =========================================================
  // Init
  // =========================================================
  async initializeData() {
    const opportunityId = this.opportunity?.Id;
    if (!opportunityId) return;

    this.isLoading = true;

    try {
      const responseData = await getRenewOpportunityData({ opportunityId });
      const opp = responseData?.opportunity || {};
      const account = opp?.Account || {};

      const entificOpt = responseData?.entific || {};
      const entityOpt = responseData?.entity || {};

      // Opportunity Type options (direct, no helper)
      const recordTypeName = (opp?.DMT_RecordTypeName__c || "")
        .toString()
        .trim();
      this.opportunityTypeOptions = recordTypeName
        ? [{ label: recordTypeName, value: recordTypeName }]
        : [];
      this.opportunityType = recordTypeName;

      // Entific / Entity options (helper: "KEY - Label", value = KEY)
      this.entificOptions = this.buildKeyLabelOption(
        entificOpt?.DMT_Key__c,
        entificOpt?.DMT_Name_EN__c
      );

      this.entityOptions = this.buildKeyLabelOption(
        entityOpt?.DMT_Value__c,
        entityOpt?.DMT_Name_EN__c
      );

      // Selected values
      this.entific = opp?.Entific__c || "";
      this.entity = opp?.DMT_Entity__c || "";

      // Name
      this.name = this.trimToMaxAllowed(opp?.Name || "");
      this.validateName(this.name);

      // Account data
      this.clientId = account?.Id || "";
      this.companyName = account?.Name || "";
      this.clientType = account?.DES_Client_Type__c || "";

      this.clientCode =
        this.clientType === CLIENT_TYPE_SUBSIDIARY
          ? account?.g_customer_id__c || ""
          : account?.DES_Group_Code__c || "";

      this.country = account?.DES_Country_Client__c || "";

      // Products
      this.products = this.mapProducts(opp?.OpportunityLineItems);
      this.showProducts = this.products.length > 0;
    } catch (e) {
      this.handleError(e, "Failed to load data");
      this.close();
    } finally {
      this.isLoading = false;
    }
  }

  // =========================================================
  // Handlers
  // =========================================================
  handleNameChange(event) {
    const raw = event?.target?.value ?? "";
    const v = this.trimToMaxVisible(raw);
    event.target.value = v;

    this.name = v;
    this.validateName(v);
  }

  handleOpportunityTypeChange(event) {
    this.opportunityType = event?.detail?.value ?? "";
  }

  handleEntificChange(event) {
    this.entific = event?.detail?.value ?? "";
  }

  handleEntityChange(event) {
    this.entity = event?.detail?.value ?? "";
  }

  handleToggle(event) {
    // Only one section is expected to be open at a time; we keep the first open section.
    const openSections = event.detail.openSections;
    this.activeSection = openSections.length ? openSections[0] : null;
  }

  handleCancel() {
    this.close();
  }

async handleSaveAndEdit() {
  // Evitar doble click / re-entradas
  if (this.isLoading) return;

  // Validación básica
  this.validateName(this.name);
  if (this.isNameInvalid) {
    this.toastEvent(ERROR_TITLE, this.nameErrorMessage, "error");
    return;
  }

  this.isLoading = true;

  try {
    const result = await renewOpportunity({
      opportunityId: this.opportunity?.Id,
      input: { newName: this.name }
    });

    if (result?.success === false) {
      const msg = result?.errorMessage || ERROR_FALLBACK_MESSAGE;
      this.toastEvent(ERROR_TITLE, msg, "error");
      return;
    }

    if (!result?.newOppId) {
      this.toastEvent(
        ERROR_TITLE,
        this.labels.DMT_IdOpportunityNotReturnedText || ERROR_FALLBACK_MESSAGE,
        "error"
      );
      return;
    }


    this.toastEvent(
      this.labels.DMT_Successtext,
      this.labels.DMT_OpportunityCreatedSuccessfullyText,
      "success"
    );

    this.close({ success: true, newOppId: result.newOppId });
  } catch (e) {
    console.error("renewOpportunity error:", e);

    this.toastEvent(ERROR_TITLE, ERROR_FALLBACK_MESSAGE, "error");
  } finally {
    this.isLoading = false;
  }
}

  // =========================================================
  // Validation
  // =========================================================
  validateName(value) {
    const len = (value || "").toString().length;
    this.nameErrorMessage = len > NAME_MAX_ALLOWED ? NAME_TOO_LONG_MESSAGE : "";
  }

  // =========================================================
  // Helpers
  // =========================================================
  buildKeyLabelOption(keyValue, labelValue) {
    const key = (keyValue || "").toString().trim();
    if (!key) return [];

    const labelPart = (labelValue || "").toString().trim();
    const label = labelPart ? `${key} - ${labelPart}` : key;

    return [{ label, value: key }];
  }

  trimToMaxAllowed(value) {
    const s = (value || "").toString();
    return s.length > NAME_MAX_ALLOWED ? s.slice(0, NAME_MAX_ALLOWED) : s;
  }

  trimToMaxVisible(value) {
    const s = (value || "").toString();
    return s.length > NAME_MAX_VISIBLE ? s.slice(0, NAME_MAX_VISIBLE) : s;
  }

  mapProducts(items) {
    const list = Array.isArray(items) ? items : [];
    return list.map((x) => ({
      ...x,
      isDisabled: true
    }));
  }

  // =========================================================
  // Getters (UI)
  // =========================================================
  get companyHref() {
    const id = (this.clientId || "").toString().trim();
    return id ? `/${id}` : "#";
  }

  get showCountry() {
    return (
      this.clientType === CLIENT_TYPE_SUBSIDIARY &&
      Boolean((this.country || "").toString().trim())
    );
  }

  get labelsClient() {
    return this.clientType === CLIENT_TYPE_SUBSIDIARY
      ? this.labels.DMT_ClientCode
      : this.labels.DMT_GroupCode;
  }

  get isNameInvalid() {
    return Boolean(this.nameErrorMessage);
  }

  get isSaveDisabled() {
    return this.isLoading || this.isNameInvalid;
  }

  get isNameDisabled() {
    return this.isLoading;
  }

  get nameMaxlength() {
    return NAME_MAX_VISIBLE;
  }

  get nameWrapperClass() {
    return `slds-form-element ${this.isNameInvalid ? "slds-has-error" : ""}`;
  }

  get entificWrapperClass() {
    return `slds-m-top_small slds-form-element ${this.showPermissionError ? "slds-has-error" : ""
      }`;
  }

  // =========================================================
  // Toast / Error
  // =========================================================
  toastEvent(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  handleError(error, customTitle = ERROR_TITLE) {
    // eslint-disable-next-line no-console
    console.error("Modal error:", error);

    const msg =
      error?.message ||
      error?.body?.message ||
      (typeof error === "string" ? error : ERROR_FALLBACK_MESSAGE);

    this.toastEvent(customTitle, msg, "error");
    this.isLoading = false;
    this._pendingAction = null;
  }
}