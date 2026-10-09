import { api } from "lwc";
import LightningModal from "lightning/modal";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getOpportunityCreationParameters from "@salesforce/apex/DMT_CreateOpportunityService.getOpportunityCreationParameters";
import refreshEntityOptions from "@salesforce/apex/DMT_CreateOpportunityService.refreshEntityOptions";
import createOpportunity from "@salesforce/apex/DMT_CreateOpportunityService.createOpportunity";

// Labels (DO NOT TOUCH)
import DMT_Name from "@salesforce/label/c.dmt_cl_NameLine";
import DMT_ClientType from "@salesforce/label/c.dmt_cl_ClientType";
import DMT_ClientCode from "@salesforce/label/c.dmt_cl_Client_Code";
import DMT_GroupCode from "@salesforce/label/c.dmt_cl_Group_Code";
import DMT_Country from "@salesforce/label/c.dmt_cl_Country";
import DMT_TaxPayer from "@salesforce/label/c.dmt_cl_Tax_Payer";
import DMT_permissionErrorMessage from "@salesforce/label/c.dmt_cl_Entific_Error";
import DMT_Entific from "@salesforce/label/c.dmt_cl_Entific_Label";
import DMT_weblink_label from "@salesforce/label/c.DMT_weblink_label";
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



// =========================================================
// Constants
// =========================================================
const CLIENT_TYPE_CUSTOMER = "Subsidiary";
const CLIENT_TYPE_GROUP = "CIB Group";
const CLIENT_TYPE_SUBGROUP = "Subgroup";
const CLIENT_TYPE_SINGLE_CLIENT_LABEL = "Single client";
const CLIENT_TYPE_MULTI_CLIENT_LABEL = "Multi-client";
const NAME_MAX_LEN = 50;
const RECORD_TYPE_NAME = "DMT_Opportunity";

const ERROR_TITLE = DMT_UnexpectedErrorText;
const ERROR_FALLBACK_MESSAGE = DMT_ErrorContactAdministratorText

export default class dmtNewOpportunityModal extends LightningModal {
  // =========================================================
  // Public API
  // =========================================================
  @api clientId;
  @api groupId;
  @api taxPayer = "";

  labels = {
    DMT_permissionErrorMessage, DMT_Entific,
    DMT_Name,
    DMT_ClientType,
    DMT_ClientCode,
    DMT_GroupCode,
    DMT_Country,
    DMT_TaxPayer,
    DMT_weblink_label,
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
  clientType = "";
  clientCode = "";
  country = "";
  isProspect = "";
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
   * so we inject the received raw value into the options as { label, value: v }.
   * `label` defaults to the raw value but callers can pass a friendlier display label
   * (e.g. the RecordType DeveloperName 'DMT_Opportunity' displayed as 'DMT Opportunity').
   */
  normalizePicklistValue(rawValue, optionsPropName, label) {
    const v = this.safeStr(rawValue).trim();
    if (!v) return "";

    const current = this[optionsPropName] || [];
    const exists = current.some((o) => o?.value === v);

    if (!exists) {
      this[optionsPropName] = [...current, { label: label || v, value: v }];
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
    return this.clientType === CLIENT_TYPE_CUSTOMER;
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

  get isNonDisclosed() {
    return this.groupCode === "GXXXXXXXXXXXXXX";
  }

  // =========================================================
  // Lifecycle
  // =========================================================
  connectedCallback() {
    /**
     * Force initial loading state before the first Apex call.
     * Without this, the first render may happen before `isLoading` becomes true.
     */
    this.isLoading = true;
    this.loadInitialData();
  }

  // =========================================================
  // Initial load
  // =========================================================
  async loadInitialData() {
    // Bootstrap request: fetch everything needed to hydrate the modal UI
    this.isLoading = true;
    try {
      const result = await getOpportunityCreationParameters({
        clientId: this.clientId,
        groupId: this.groupId,
        recordTypeName: RECORD_TYPE_NAME
      });
      await this.applyRefreshPayload(result);
    } catch (error) {
      this.handleError(error);
    } finally {
      this.isLoading = false;
    }
  }

  async applyRefreshPayload(refresh) {
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
    this.companyName = this.safeStr(ip.ClientName);
    this.clientId = this.safeStr(ip.clientId) || this.clientId;
    this.clientType = this.safeStr(ip.DES_Client_Type__c);
    this.clientCode = this.safeStr(ip.clientCode);
    this.country = this.safeStr(ip.BookingGeography);
    this.taxPayer = this.safeStr(ip.taxpayerId) || this.taxPayer;
    this.groupCode = this.safeStr(ip.groupCode);
    const ipName = this.safeStr(ip.oppName);

    this.opportunityType = this.normalizePicklistValue(
      ip.RecordTypeName,
      "opportunityTypeOptions",
      this.safeStr(ip.RecordTypeName).replace(/_/g, " ")
    );
    this.name = this.normalizeName(ipName);

    // The bootstrap payload exposes the booking-geography options as `count` (array of
    // {value,label} taxonomy rows) and the selected value as `BookingGeography` — NOT
    // `entificOptions`/`entificOpp` (those keys don't exist on the Apex response). The
    // selected entity comes back as `oppEntity`, not `entityOpp`.
    const bookingGeographyOptions = Array.isArray(ip.count)
      ? ip.count.map(o => ({ value: o.value, label: `${o.value} - ${o.label}` }))
      : [];

    if (this.isSubsidiary) {
      if (this.isNonDisclosed) {
        this.entificOptions = bookingGeographyOptions;
        this.entific = this.normalizePicklistValue(ip.BookingGeography, "entificOptions");
        this.entity = this.normalizePicklistValue(ip.oppEntity, "entityOptions");
        this.entificDisabled = false;
        this.entityDisabled = false;

        this._initialEntific = this.entific;
        this._initialEntity = this.entity;
      } else {
      this.entific = this.normalizePicklistValue(ip.BookingGeography, "entificOptions");
      this.entity = this.normalizePicklistValue(ip.oppEntity, "entityOptions");
      }

    } else {

      this.clientsByGroup = Array.isArray(ip.clientsByGroup) ? ip.clientsByGroup : [];
      const uniqueCountries = [...new Set(this.clientsByGroup.map(c => c.country))];

      this.entificOptions = bookingGeographyOptions.filter(o => uniqueCountries.includes(o.value));

     

      let finalEntific = "";

      if (this.entificOptions.some(o => o.value === ip.BookingGeography)) {
        finalEntific = ip.BookingGeography;
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

      const entificChanged = finalEntific !== ip.BookingGeography;

      if (!entificChanged) {
        this.entityOptions = Array.isArray(ip.entityOptions)
          ? ip.entityOptions.map(o => ({
            value: o.value,
            label: `${o.value} - ${o.label}`
          }))
          : [];

        this.entity = this.normalizePicklistValue(ip.oppEntity, "entityOptions");

      } else {
        this.entity = "";
        this.entityOptions = [];
        this.entityDisabled = true;

        if (finalEntific) {
          this.isLoading = true;
          try {
            const options = await refreshEntityOptions({ entific: finalEntific });
            this.applyEntityOptions(options);
          } catch (error) {
            this.handleError(error);
          } finally {
            this.isLoading = false;
          }
        }
      }


    }
  }

  applyEntityOptions(rawOptions) {
    this.entity = "";

    const options = Array.isArray(rawOptions)
      ? rawOptions.map(o => ({
        value: o.value,
        label: `${o.value} - ${o.label}`
      }))
      : [];

    this.entityOptions = [...options];

    if (this.entityOptions.length > 0) {
      this.entity = this.entityOptions[0].value;
    }
    this.entityDisabled = this.entityOptions.length === 0;
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

  async handleEntificChange(event) {
    this.entific = event.detail.value;

    if (!this.isSubsidiary || this.isNonDisclosed) {

      if (this.isNonDisclosed && this.entific === this._initialEntific) {
        this.entity = this._initialEntity;
        return;
      }

      this.entity = "";
      this.entityOptions = [];
      this.entityDisabled = true;

      this.isLoading = true;
      try {
        const options = await refreshEntityOptions({ entific: this.entific });
        this.applyEntityOptions(options);
      } catch (error) {
        this.handleError(error);
      } finally {
        this.isLoading = false;
      }
    }

  }

  handleEntityChange(event) {
    this.entity = event.detail.value;
  }

  // =========================================================
  // Save & Edit: Create New Opportunity (Apex)
  // =========================================================
  async handleSaveAndEdit() {
    if (this.isSaveDisabled) return;

    /**
     * Build the Apex call using both UI selections and immutable fields from the bootstrap IP.
     * This ensures the server receives the full context needed to create the record.
     */
    const ip = this.lastIp || {};
    let entityToSend = "";

    if (this.clientType !== CLIENT_TYPE_CUSTOMER) {
      entityToSend = this.entity;
    } else {
      entityToSend = this.entity ? this.entity.trim().substring(0, 6) : "";
    }

    this.isLoading = true;

    try {
      const payload = {
        recordTypeName: "DMT_Opportunity",
        name: this.name,
        startDate: ip.StartDate,
        endDate: ip.EndDate,
        clientId: this.clientId,
        clientType: this.clientType,
        bookingGeography: this.entific || ip.BookingGeography,
        oppEntity: entityToSend,
        segment: ip.Segment,
        groupCode: ip.groupCode,
        clientsByGroup: this.clientsByGroup,
        isDummyOpp: false
      };

      const result = await createOpportunity(payload);

      const newId = result?.createdId;
      if (!newId) {
        this.handleError(new Error(this.labels.DMT_IdOpportunityNotReturnedText));
        return;
      }

      window.open(`/${newId}`, "_blank");
      this.toastEvent(this.labels.DMT_Successtext, this.labels.DMT_OpportunityCreatedSuccessfullyText, "success");
      this.close(newId);
    } catch (error) {
      this.handleError(error);
    } finally {
      this.isLoading = false;
    }
  }

  // =========================================================
  // Toast / Error
  // =========================================================
  toastEvent(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  handleError(error, customTitle = ERROR_TITLE) {
    // Centralized error handler: always releases loading state and clears pending action

    const msg =
      error?.message ||
      error?.body?.message ||
      (typeof error === "string" ? error : ERROR_FALLBACK_MESSAGE);

    this.toastEvent(customTitle, msg, "error");
    this.isLoading = false;
    this._pendingAction = null;
  }
}