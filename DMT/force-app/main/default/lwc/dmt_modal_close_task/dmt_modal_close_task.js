import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import PASSPORT_SANCTION_FIELD from '@salesforce/schema/Case.DMT_Passport_Sanction__c';
import CHECK_TEXT_1 from '@salesforce/label/c.dmt_cl_closeTask_returnClose_Text';
import CHECK_TEXT_2 from '@salesforce/label/c.dmt_cl_closeTask_returnReview_Text';
import CHECK_TEXT_2_APPROVAL from '@salesforce/label/c.dmt_cl_closeTask_returnProposal_Text';
import CHECK_TEXT_3 from '@salesforce/label/c.dmt_cl_closeTask_AdvanceApproval_Text';
import getWebLinkUrl from '@salesforce/apex/DMT_Opportunity_Handler.getWebLinkUrl';

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
    _recordId;
    showSpinner = false;

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
    }

    @api defaultStepSelected;
    
    // CIBGLOBALD-3808 - Config values received from FlexCard/DataTransform
    @api stepResult;               
    @api dmtFinishCaseConfig;      
    @api dmtReviewOperationConfig; 
    @api dmtSendToApproverConfig;  

    // Case link URL
    caseLinkUrl = '';

    @wire(getWebLinkUrl, { recordDeveloperName: 'Case_Link' })
    wiredCaseLink({ error, data }) {
        if (data) {
            this.caseLinkUrl = data;
        } else if (error) {
            console.error('Error loading Case_Link web link:', error);
        }
    }

    get hasCaseLink() {
        return this.caseLinkUrl && this.caseLinkUrl.trim() !== '';
    }

    @wire(CurrentPageReference)
    wiredPageRef(pageRef) {
        if (this._recordId) {
            return;
        }
        const state = pageRef?.state || {};
        const attributes = pageRef?.attributes || {};
        this._recordId =
            attributes.recordId ||
            state.c__recordId ||
            state.recordId ||
            null;
    }

    @wire(getRecord, { recordId: '$_recordId', fields: [PASSPORT_SANCTION_FIELD] })
    caseRecord;

    //Labels
    label = {
        CHECK_TEXT_1,
        CHECK_TEXT_2,
        CHECK_TEXT_2_APPROVAL,
        CHECK_TEXT_3
    };

    // NUEVO MÉTODO: El padre llamará a este método para asegurar el enfoque
    @api
    focusModal() {
        setTimeout(() => {
            const modal = this.template.querySelector('section[role="dialog"]');
            if (modal) {
                modal.scrollIntoView({ behavior: 'smooth', block: 'start' });
                modal.focus();
            }
        }, 150); // Damos 150ms para que la app de Salesforce dibuje completamente la pantalla
    }

    getToggleAvailability(configString) {
        if (!configString || typeof configString !== 'string' || configString.trim() === '') {
            return null;
        }
        const parts = configString.split(';').map(value => value.trim());
        while (parts.length > 0 && parts[parts.length - 1] === '') {
            parts.pop();
        }
        if (parts.length !== 3) {
            return null;
        }
        const resultIndexMap = {
            'yes': 0,
            'na': 1,
            'no': 2
        };
        const normalizedResult = (this.stepResult || '').toString().trim().toLowerCase();
        const index = resultIndexMap[normalizedResult];
        if (index === undefined) {
            return null;
        }
        const value = parts[index].toLowerCase();
        if (value === '') {
            return null;
        }
        if (value === 'yes') {
            return true;
        } else if (value === 'no') {
            return false;
        }
        return null;
    }

    //getters and setters
    @api
    get finishStep() {
        const isAvailable = this.getToggleAvailability(this.dmtFinishCaseConfig);
        if (isAvailable !== null) {
            return !isAvailable;
        }
        return this._finishStep;
    };
    set finishStep(value) {
        this._finishStep = (value === true || value === 'true') ? true : false;
    };

    @api
    get buttonDisabled() {
        const isAvailable = this.getToggleAvailability(this.dmtSendToApproverConfig);
        if (isAvailable !== null) {
            return !isAvailable;
        }
        return this._buttonDisabled;
    };
    set buttonDisabled(value) {
        this._buttonDisabled = (value === true || value === 'true') ? true : false;
    };

    @api
    get returnToProposalDisabled() {
        const isAvailable = this.getToggleAvailability(this.dmtReviewOperationConfig);
        if (isAvailable !== null) {
            return !isAvailable;
        }
        return this._returnToProposalDisabled;
    };
    set returnToProposalDisabled(value) {
        this._returnToProposalDisabled = (value === true || value === 'true') ? true : false;
    };

    get passportSanction() {
        if (this.caseRecord && this.caseRecord.data) {
            const fieldValue = getFieldValue(this.caseRecord.data, PASSPORT_SANCTION_FIELD);
            return fieldValue || 'passport';
        }
        return 'passport';
    }

    get isApprovalType() {
        return (this.passportSanction || '').toLowerCase() === 'approval';
    }

    get checkText2Label() {
        return this.isApprovalType ? this.label.CHECK_TEXT_2_APPROVAL : this.label.CHECK_TEXT_2;
    }

    get returnStatus() {
        return this.isApprovalType ? 'Proposal' : 'Draft';
    }

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
            this.dispatchEvent(new CustomEvent('returnToProposalCard',{ 
                bubbles:true, 
                composed:true,
                detail: { status: this.returnStatus }
            }));
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
        this.dispatchEvent(new CustomEvent('closemodal', { bubbles: true, composed: true }));
        this.dispatchEvent(new CustomEvent('close', { bubbles: true, composed: true }));
        this.dispatchEvent(new CustomEvent('cancel', { bubbles: true, composed: true }));
        this.showModal = false;
    }
}