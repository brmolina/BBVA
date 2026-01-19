import { LightningElement, api,wire,track } from 'lwc';
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import titleDealManagement from '@salesforce/label/c.titleDealManagement';
import pubsub from "omnistudio/pubsub";
import getRecordCode from '@salesforce/apex/DMT_HPG_MainTableCustomController.getRecordCode';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPassportByOpp from '@salesforce/apex/DMT_Profitability_Helper.getPassportByOpp';
import toastObsoletePassportTitle from "@salesforce/label/c.DMT_ProfitabilityRedirectionObsoletePassportTitle";
import toastObsoletePassportContent from "@salesforce/label/c.DMT_ProfitabilityRedirectionObsoletePassportContent";

const EVT_CLOSE_LWC='close_lwc';
const EVENT_STRG='event';
const ADVERTENCIA_STRG='Advertencia';
const WARNING_STRG='warning';
const DISMISSABLE_MODE_STRG='dismissable';
const ERROR_TITLE='Error'; 
const ERROR_VARIANT='error';  
const MSG_ERROR_NOCLIENT ='Cannot obtain group/client record code';  
const MSG_ERROR_ONVALIDATION='An unexpected error occurred during validation.';  

export default class Dmt_profitability_Deal_Management extends NavigationMixin(LightningElement) {

 //Variables declaration
  isLoaded = false;
  url;
  label={titleDealManagement};
  @wire(CurrentPageReference)
  currentPageRef;
  withErrorPassport  = false; //evita la redireccion y muestra la card de error
  isLoading = true; //Muestra el modal de carga bien para la redireccion, bien miestras llama a apex para comprobar pasaport

  label = {
    toastObsoletePassportTitle,
    toastObsoletePassportContent,
  };

  
  //getters and setters from the values of the dataSource
  @api accountId;
  get  accountId() {
    return this.valueAccount;
  }

  set accountId(value) {
    this.valueAccount = value;
    if(this.valueOpp != null &&  this.valueProduct != null){
     this.tryNavigateOrShowError();
    }
  } 

  @api oppId;
  get  oppId() { 
    return this.valueOpp;
  }

  set oppId(value) {
    this.valueOpp = value;
    this.tryNavigateOrShowError();
  }

  @api productSelected;
  get  productSelected() { 
    return this.valueProduct;
  }

  set productSelected(value) {
    this.valueProduct = value;
    if(this.valueOpp != null &&  this.valueAccount != null){
     this.tryNavigateOrShowError();
    }
  }


  
  NavigateMixer() {
    var clientId = this.valueAccount;
    var oppId = this.valueOpp;
    var prof = 'Profitability';
    var productSelected = this.valueProduct;
                
    getRecordCode({ clientId: clientId })
        .then(response => {
            if (response == '') {

                // Display SLDS alert for error or exception
                const alertEvent = new ShowToastEvent({
                    title: ERROR_TITLE,
                    message: MSG_ERROR_NOCLIENT,
                    variant: ERROR_VARIANT,
                });
                this.dispatchEvent(alertEvent);

            }  else {
              // Display modal before navigation
              const STYLE = document.createElement("style");
              STYLE.innerHTML = `.uiModal--medium .modal-container{
                  width: 43rem !important;
                  max-width: 650px !important;
                  min-width: 480px !important;
              }
              .slds-modal__header .slds-modal__close {
                  position: absolute;
                  top: -2.5rem;
                  right: 0;
                  margin-left: 0;
                  bottom: 0;
                  visibility: hidden;
              }
              .slds-card {
                  border: none !important;
                  box-shadow: none !important;
                  border-style: none; 
                  box-shadow:none
              }`;
              this.template.querySelector("lightning-card").appendChild(STYLE);
                setTimeout(() => {
                    // Proceed with navigation to the deal manahement card
                    let urlMixin = {
                        type: "standard__navItemPage",
                        attributes: { apiName: "DMT_Page" },
                        state: { c__recordId: clientId, c__viewTab: prof , c__oppSelected:oppId, c__productSelected:productSelected }
                    };
                    this[NavigationMixin.GenerateUrl](urlMixin).then(url => window.open(url, '_blank'));
                    this.isLoading = false;
                    pubsub.fire(EVT_CLOSE_LWC, EVENT_STRG);
                }, 1300);
            } 
        })
        .catch(error => {

            console.error('Error during validation:', error);
            const alertEvent = new ShowToastEvent({
                title: ERROR_TITLE,
                message: MSG_ERROR_ONVALIDATION,
                variant: ERROR_VARIANT,
            });
            this.dispatchEvent(alertEvent);
        });  
  }

  tryNavigateOrShowError() {
    if (this.valueAccount && this.valueOpp && this.valueProduct) {
        this.isLoading = true;
        this.withErrorPassport  = false;
        getPassportByOpp({ oppId: this.valueOpp })
            .then(data => {
               this.withErrorPassport  = data ? data.DMT_Is_Obsoleted_Passport_Save__c : false;
                    if (this.withErrorPassport ) {
                      setTimeout(() => {
                        pubsub.fire(EVT_CLOSE_LWC, EVENT_STRG);
                        this.showWarningToast(this.label.toastObsoletePassportContent, this.label.toastObsoletePassportTitle);
                        this.isLoading = false;
                      }, 1600);
                    }else{
                      this.NavigateMixer();
                    }    
            })
            .catch(error => {
                    console.error('Error fetching Passport record:', error);
                    this.isLoading = false;
                    this.withErrorPassport  = true;
            });
    }
  }
  showWarningToast(message, title = ADVERTENCIA_STRG) {
      this.dispatchEvent(
          new ShowToastEvent({
              title: title,
              message: message,
              variant: WARNING_STRG,
              mode: DISMISSABLE_MODE_STRG
          })
      );
  }
}