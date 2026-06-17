import { LightningElement, api } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import createAccountAndOnboarding from "@salesforce/apex/ONB_createOnboardingController.createAccountAndOnboarding";
import ONB_RT_NEWFUND from "@salesforce/label/c.ONB_RT_NEWFUND";
import ONB_ADDFUND_NEWFUND from "@salesforce/label/c.ONB_ADDFUND_NEWFUND";
import ONB_ADDFUNDDES_NEWFUND from "@salesforce/label/c.ONB_ADDFUNDDES_NEWFUND";
import ONB_FUND_NEWFUND from "@salesforce/label/c.ONB_FUND_NEWFUND";
import ONB_FUNDDES_NEWFUND from "@salesforce/label/c.ONB_FUNDDES_NEWFUND";
import ONB_NEWPRODUCT_NEWFUND from "@salesforce/label/c.ONB_NEWPRODUCT_NEWFUND";
import ONB_NEWPRODUCTDES_NEWFUND from "@salesforce/label/c.ONB_NEWPRODUCTDES_NEWFUND";
import ONB_NEWCONTRACT_NEWFUND from "@salesforce/label/c.ONB_NEWCONTRACT_NEWFUND";
import ONB_NEWCONTRACTDES_NEWFUND from "@salesforce/label/c.ONB_NEWCONTRACTDES_NEWFUND";

export default class OnboardingRequestModal extends NavigationMixin(LightningElement) {
  @api recordId;
  @api accRecordTypeId;
  @api anyMasterAgreement;
  selectedOption = "";
  isLoading = false;
  labels = {
    title: ONB_RT_NEWFUND,
    addFundTitle: ONB_ADDFUND_NEWFUND,
    addFundDesc: ONB_ADDFUNDDES_NEWFUND,
    fundTitle: ONB_FUND_NEWFUND,
    fundDesc: ONB_FUNDDES_NEWFUND,
    newProdTitle: ONB_NEWPRODUCT_NEWFUND,
    newProdDesc: ONB_NEWPRODUCTDES_NEWFUND,
    newContTitle: ONB_NEWCONTRACT_NEWFUND,
    newContDesc: ONB_NEWCONTRACTDES_NEWFUND
  };

  get isNextDisabled() {
    return this.selectedOption === "";
  }

  get addFundsClass() {
    return `custom-card ${this.selectedOption === "addFunds" ? "custom-card-active" : ""}`;
  }
  get fundsOnboardingClass() {
    return `custom-card ${this.selectedOption === "fundsOnboarding" ? "custom-card-active" : ""}`;
  }
  get newProductClass() {
    return "custom-card custom-card-disabled";
  }
  get newContractClass() {
    return "custom-card custom-card-disabled";
  }

  handleSelectAddFunds() {
    this.selectedOption = "addFunds";
  }
  handleSelectFundsOnboarding() {
    this.selectedOption = "fundsOnboarding";
  }

  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  async handleNext() {
    this.isLoading = true;

    try {
      if (this.selectedOption === "addFunds") {
        this.anyMasterAgreement = "Yes";
      }

      const params = {
        pendingLei: false,
        requestType: 'Add funds (without derivations)',
        accRecordTypeId: this.accRecordTypeId,
        legalEntityType: "Hedge Fund",
        anyMasterAgreement: this.anyMasterAgreement,
        existingClient: true,
        clientId: this.recordId
      };

      const result = await createAccountAndOnboarding(params);

      this.dispatchEvent(
        new ShowToastEvent({
          title: "Success",
          message: "Onboarding request created successfully!",
          variant: "success"
        })
      );

      this.dispatchEvent(new CloseActionScreenEvent());

      if (result && result.onboardingId) {
        const isFundsOnboardingFlow = this.selectedOption === "fundsOnboarding";

        if (isFundsOnboardingFlow) {
          try {
            window.sessionStorage.setItem(
              `onb_funds_onboarding_${result.onboardingId}`,
              "1"
            );
          } catch (e) {
            console.warn("Unable to persist funds onboarding flag", e);
          }
        }

        this[NavigationMixin.Navigate]({
          type: "standard__recordPage",
          attributes: {
            recordId: result.onboardingId,
            objectApiName: "ONB_Onboarding__c",
            actionName: "view"
          },
          state: isFundsOnboardingFlow
            ? { c__fundsOnboarding: "1" }
            : undefined
        });
      }
    } catch (error) {
      console.error("Error creating onboarding:", error);
      const errorMsg =
        error?.body?.message || "Error creating Onboarding request";
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: errorMsg,
          variant: "error"
        })
      );
    } finally {
      this.isLoading = false;
    }
  }
}