import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import getClient from '@salesforce/apex/CGMT_page_Local_Portfolio_Controller.getClient';
export default class CGMT_page_Local_Portfolio extends NavigationMixin(LightningElement) {

    @api recordId;
    groupCode;
    error;
    currentPageRef;

    @wire(CurrentPageReference)
    getCurrentPageReference(pageRef) {
        this.currentPageRef = pageRef;
        console.log('CurrentPageReference: ', JSON.stringify(pageRef));
    }
    get recordAcc() {
        return this.currentPageRef?.state?.c__recordAcc || null;
    }

    @wire(getClient, { accountId: '$recordId' })
    wiredClient({ error, data }) {

        console.log('recordId ' +  this.recordId);
        console.log('data ' + JSON.stringify(data) + ' ' + 'error ' + JSON.stringify(error));

        if (data) {
            this.groupCode = data;
            this.error = undefined;
            console.log('Client Code Retrieved:', this.groupCode);
            this.navigateToLocalPortfolio(); // Se ejecuta solo cuando `groupCode` tiene valor
        } else if (error) {
            this.error = error;
            this.groupCode = undefined;
            console.error('Error fetching client code:', error);
        }
    }

    modalContainer;
    isLoading = true;
    isLoaded = false;
    label = "Local Portfolio";
    
    renderedCallback() {
        if (this.isLoaded) return;
        const STYLE = document.createElement("style");
        STYLE.innerHTML = `.uiModal--medium .modal-container {
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
        }`;
        this.template.querySelector("lightning-card").appendChild(STYLE);
        this.isLoaded = true;
    }

   navigateToLocalPortfolio() {
       if (this.groupCode) {

            setTimeout(() => {
                // Proceed with navigation
                let navConfig = {
                    type: 'standard__navItemPage',
                    attributes: {
                        apiName: 'Local_Portfolio'  // Se cambia componentName por apiName
                    },
                    state: { c__recordId: this.groupCode }
                };

                console.log("Navigating with URL Mixin:", JSON.stringify(navConfig));
                this.isLoading = false;
                this[NavigationMixin.GenerateUrl](navConfig).then(url => window.open(url, '_self'));
            }, 1400);

           
       } else {
           console.warn('Client Code is undefined, navigation skipped');
       }
   }
}