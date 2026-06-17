import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import pubsub from 'omnistudio/pubsub';
import { getRecord } from 'lightning/uiRecordApi';
import getCasesByOpportunity from '@salesforce/apex/DMT_ModalSaveController.getCasesByOpportunity';

export default class Dmt_modal_save extends LightningElement {
    @api tabOppInfo;
    @api tabOppProducts;
    @api tabClient;
    @api objectApiName;
    @api recordId;

    currentPageReference;
    showModal = false;
    isLoading = true;

    connectedCallback() {
        console.log('Connected callback of dmt_modal_save_opp with recordId: ' + this.recordId);
        console.log('Connected callback of dmt_modal_save_opp with tabOppInfo: ' + this.tabOppInfo);
                console.log('Connected callback of dmt_modal_save_opp with tabOppProducts: ' + this.tabOppProducts);
        console.log('Connected callback of dmt_modal_save_opp with tabClient: ' + this.tabClient);

        this.currentPageReference = {
            state: {},
            attributes: {}
        };
        this.checkCases();
    }

    async checkCases() {
        try {
            const cases = await getCasesByOpportunity({ opportunityId: this.recordId });
            
            if (!cases || cases.length === 0) {
                // No hay casos, ejecutar directamente handleYesClick
                this.handleYesClick();
            } else {
                // Hay casos, mostrar el modal
                this.showModal = true;
                this.isLoading = false;
            }
        } catch (error) {
            console.error('Error checking cases:', error);
            // En caso de error, mostrar el modal por seguridad
            this.showModal = true;
            this.isLoading = false;
        }
    }

    handleYesClick() {
        const yesEvent = new CustomEvent('isSaveRtC', {
            detail: {
                isRtCSave: true
            },
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(yesEvent);

        if(this.tabOppInfo === 'tabOppInfo'){
            pubsub.fire(
                this.currentPageReference,
                'DMT_Opportunity_Info_Tab',
                {
                    event: 'reloadAfterSave'
                }
            );
        }
        
        if(this.tabClient === 'tabClient'){
            pubsub.fire(
                this.currentPageReference,
                'Button',
                {
                    event: 'Reload'
                }
            );
        }
        
        if(this.tabOppProducts === 'tabOppProducts'){
            pubsub.fire(
                this.currentPageReference,
                'productOpportunityFields',
                {
                    event: 'reloadParent'
                }
            );
        }

        const closeModalEvent = new CustomEvent('closemodal', {
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(closeModalEvent);
    }

    handleNoClick() {
        const noEvent = new CustomEvent('closemodal', {
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(noEvent);
        
        if(this.tabOppInfo === 'tabOppInfo'){
            pubsub.fire(
                this.currentPageReference,
                'DMT_Opportunity_Info_Tab',
                {
                    event: 'reloadAfterSave'
                }
            );
        }
        
        if(this.tabClient === 'tabClient'){
            pubsub.fire(
                this.currentPageReference,
                'Button',
                {
                    event: 'Reload'
                }
            );
        }
        
        if(this.tabOppProducts === 'tabOppProducts'){
            pubsub.fire(
                this.currentPageReference,
                'productOpportunityFields',
                {
                    event: 'reloadParent'
                }
            );
        }
    }
}