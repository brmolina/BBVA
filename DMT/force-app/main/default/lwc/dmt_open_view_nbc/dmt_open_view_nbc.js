import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class dmt_open_view_nbc extends LightningElement {
    @api recordId;

    @track isOpen = false;

    @api isOppScreenView = false;
    _initialized = false;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            // Check standard and custom state parameters
            this.recordId = currentPageReference.state?.recordId || currentPageReference.state?.c__recordId || currentPageReference.attributes?.recordId;
        }
    }

    connectedCallback() {
        this.isOppScreenView = true;
        console.log('Record Id in NBC View Modal:', this.recordId);
    }

    renderedCallback() {
        if (this._initialized) return;

        this._initialized = true;
        try {
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (e) {
            console.error('CloseActionScreenEvent failed:', e);
        }
        Promise.resolve().then(() => {this.isOpen = true;});
        const STYLE = document.createElement("style");
        STYLE.innerHTML = `.uiModal--medium .modal-container {
                                                width: 100% !important;
                                                max-width: 70% !important;
                                                min-width: 480px !important;
                            }
                            .slds-modal__header .slds-modal__close {
                                                position: absolute !important;
                                                top: -2.5rem !important;
                                                margin-left: 0 !important;
                                                right: 92px !important;
                                                bottom: 0 !important;
                                                visibility: hidden !important;
                            }
                            .uiModal--recordActionWrapper .modal-body {
                                                display: flex;
                                                flex-direction: column;
                                                padding: var(--lwc-spacingNone, 0);
                                                visibility: hidden !important;
                            }`;
        this.template.querySelector("lightning-card").appendChild(STYLE);

    }

    handleCloseModal() {
        this.isOpen = false;
        try {
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (e) {
            console.warn('CloseActionScreenEvent on close failed:', e);
        }
    }
}