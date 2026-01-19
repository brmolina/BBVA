import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import getRecordCode from '@salesforce/apex/DMT_HPG_MainTableCustomController.getRecordCode';
import getSerializedGroupFromRecordCode from '@salesforce/apex/DMT_HPG_Utils.getSerializedGroupFromRecordCode';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LABEL_ERROR_NO_DATA_FROM_SERVICE from '@salesforce/label/hpgr.Error_No_Data_From_Service';
import getRecordAccountId from '@salesforce/apex/DMT_HPG_MainTableCustomController.getAccountIdFromRecordId';


export default class dmt_page_Deal_Manament extends NavigationMixin(LightningElement) {
    @api recordId;
    isLoading = true;

    label = {
        noDataFromService: LABEL_ERROR_NO_DATA_FROM_SERVICE
    };

    hasError = false;
    errorMessage = '';

    @wire(CurrentPageReference)
    currentPageRef;

    @api recordAcc;

    recordCode = '';
    groupCode = null;

    get recordAcc() {
        return this.currentPageRef.state.c__recordAcc;
    }

    connectedCallback() {
        // Check if the style was already added to avoid duplicates
        if (!document.head.querySelector('#custom-modal-style')) {
            const style = document.createElement('style');
            style.id = 'custom-modal-style';
            style.innerHTML = `
                .uiModal--medium .modal-container {
                    width: 43rem !important;
                    max-width: 650px !important;
                    min-width: 480px !important;
                }

                .slds-modal__header .slds-modal__close {
                    display: none !important;
                }

                .slds-card {
                    border: none !important;
                    box-shadow: none !important;
                }
            `;
            document.head.appendChild(style);
        }
        console.log('recordId que tal '+this.recordId);
        this.validateAndNavigate();
    }

    async validateAndNavigate() {
        let clientId;
        if (this.recordAcc) {
            clientId = this.recordAcc;
        } else {
            let recordUrl = window.location.href.split('=')[2];
            clientId = recordUrl.split('&')[0];
        }

        //Check object and get client ID
        try {
          clientId = await getRecordAccountId({ recordId: clientId });
          this.error = undefined;
        } catch (error) {
            this.error = error;
            clientId = undefined;
        }
        

        console.log('Validating record with ID:', clientId);

        // Wait for validateRecordCode to complete before proceeding
        this.hasError = await this.validateRecordCode(clientId) || await this.validateGroupCode();
        console.log('hasError:', this.hasError);

        if (this.hasError) {
            this.errorMessage = this.label.noDataFromService;
            this.showToast('Error', this.errorMessage, 'error');
            this.isLoading = false;
            this.dispatchEvent(new CloseActionScreenEvent());

        } else {
            setTimeout(() => {
                // Proceed with navigation
                let urlMixin = {
                    type: "standard__navItemPage",
                    attributes: { apiName: "DMT_Page" },
                    state: { c__recordId: clientId }
                };

                this[NavigationMixin.GenerateUrl](urlMixin).then(url => window.open(url, '_self'));
                this.isLoading = false;
            }, 1400);
        }
    }

    async validateRecordCode(clientId) {
        try {
            const response = await getRecordCode({ clientId: clientId });
            console.log('getRecordCode response:', response);
            this.recordCode = response;
            if (this.recordCode === '') {
                return true;  // Error occurred
            }
            return false;  // No error
        } catch (error) {
            console.error('Error during validateRecordCode:', error);
            return true;  // Error occurred
        }
    }

    async validateGroupCode() {
        try {
            const response = await getSerializedGroupFromRecordCode({ recordCode: this.recordCode });
            console.log('getSerializedGroupFromRecordCode response:', response);
            let groupCode = JSON.parse(response).groupCode;
            this.groupCode = groupCode;
            if (this.groupCode === null) {
                return true;  // Error occurred
            }
            return false;  // No error
        } catch (error) {
            console.error('Error during validateGroupCode:', error);
            return true;  // Error occurred
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            mode: 'dismissable',
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}