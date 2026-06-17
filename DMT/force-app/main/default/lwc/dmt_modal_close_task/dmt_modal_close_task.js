import { LightningElement, track, api } from 'lwc';
import CHECK_TEXT_1 from '@salesforce/label/c.dmt_cl_closeTask_returnClose_Text';
import CHECK_TEXT_2 from '@salesforce/label/c.dmt_cl_closeTask_returnReview_Text';
import CHECK_TEXT_3 from '@salesforce/label/c.dmt_cl_closeTask_AdvanceApproval_Text';
export default class dmt_modal_close_task extends LightningElement {

    //Check variables
    @track isActive1 = false;
    @track isActive2 = false;
    @track isActive3 = false;   
    @track disabledNextButton = true;
    showModal = true;
    _finishStep;
    _buttonDisabled;
    _returnToProposalDisabled;
    _errorMessage = '';
    showSpinner = false;

    //Labels
    label = {
        CHECK_TEXT_1,
        CHECK_TEXT_2,
        CHECK_TEXT_3
    };

    //getters and setters
    @api
    get finishStep() {
        return this._finishStep;
    };
    set finishStep(value) {
        this._finishStep = value == true ? true : false;
    };

    @api
    get buttonDisabled() {
        return this._buttonDisabled;
    };
    set buttonDisabled(value) {
        this._buttonDisabled = value == true ? true : false;
    };

    @api
    get returnToProposalDisabled() {
        return this._returnToProposalDisabled;
    };
    set returnToProposalDisabled(value) {
        this._returnToProposalDisabled = value == true ? true : false;
    };

    @api
    get errorMessage() {
        return this._errorMessage;
    };
    set errorMessage(value) {
        const normalizedValue = (value || '').toString().trim();
        this._errorMessage = normalizedValue !== '' && normalizedValue !== '{errorMessage}' ? normalizedValue : '';
    };

    get showErrorMessage() {
        return this._errorMessage !== '';
    }


    //methods

    handleToggle1(event) {
        this.isActive1 = event.detail.checked;
        this.isActive2 = false;
        this.isActive3 = false;
        this.disabledNextButton = !this.isActive1;
    }
     handleToggle2(event) {
        this.isActive2 = event.detail.checked;
        this.isActive1 = false;
        this.isActive3 = false;
        this.disabledNextButton = !this.isActive2;
    }
     handleToggle3(event) {
        this.isActive3 = event.detail.checked;
        this.isActive1 = false;
        this.isActive2 = false;
        this.disabledNextButton = !this.isActive3;
    }

    handleNext(){  
        this.disabledNextButton = true;
        if(this.isActive1){
            this.showSpinner = false;
            this.dispatchEvent(new CustomEvent('finishCaseConditionCard',{ bubbles:true, composed:true}));
        }else if(this.isActive2){
            this.showSpinner = true;
            this.dispatchEvent(new CustomEvent('returnToProposalCard',{ bubbles:true, composed:true}));
        }else if(this.isActive3){
            this.showSpinner = true;
            this.dispatchEvent(new CustomEvent('approvalValidationCard',{ bubbles:true, composed:true}));
        }
    }
    handleClose(event){
        if (event) {
            event.preventDefault();
            event.stopPropagation();
        }

        // OmniStudio modals usually close through this custom event.
        this.dispatchEvent(new CustomEvent('closemodal', { bubbles: true, composed: true }));

        // Fallback events for containers listening to standard dialog semantics.
        this.dispatchEvent(new CustomEvent('close', { bubbles: true, composed: true }));
        this.dispatchEvent(new CustomEvent('cancel', { bubbles: true, composed: true }));

        // Keep a local fallback to avoid a stuck UI if parent close handling fails.
        this.showModal = false;
    }

}