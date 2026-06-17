import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import pubsub from 'omnistudio/pubsub';
import getCasesByOpportunity from '@salesforce/apex/DMT_ModalSaveController.getCasesByOpportunity';

// LMS Imports
import { subscribe, unsubscribe, publish, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import DMT_WARNING_MODAL_CHANNEL from '@salesforce/messageChannel/DmtWarningModalChannel__c';

const FIELDS = ['Opportunity.StageName'];

export default class Dmt_confirmationModal extends LightningElement {
    objectApiName;
    recordId;
    currentPageReference;
    
    showModal = false;
    stageName;

    // Configurable UI Properties for Reusability
    @api modalBodyText = 'Please confirm your action.';
    @api modalQuestionText = 'Are you sure you want to proceed?';
    @api confirmButtonLabel = 'Yes';
    @api cancelButtonLabel = 'No';

    tabOppInfo;
    tabOppProducts;
    tabClient;

    // LMS Context and Subscription
    @wire(MessageContext)
    messageContext;
    subscription = null;
    actionIdentifier = null; // To track which action triggered the modal

    // --- 1. Robust Record ID Extraction ---
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.currentPageReference = currentPageReference;
            this.recordId = currentPageReference.state?.recordId || 
                            currentPageReference.attributes?.recordId || 
                            currentPageReference.state?.c__recordId;
            console.log('Record ID populated: ', this.recordId);
        }
    }

    // --- 2. Reactive StageName tracking ---
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            // Natively grab the API name directly from the getRecord payload
            this.objectApiName = data.apiName;
            this.stageName = data.fields.StageName.value;
            console.log('StageName loaded/changed: ', this.stageName);
        } else if (error) {
            console.error('Error fetching Opportunity data:', error);
        }
    }

    // --- 3. OmniStudio PubSub & LMS Listener Setup ---
    pubsubPayload = {
        checkWarningModal: this.handleCheckWarningModal.bind(this)
    };

    connectedCallback() {
        // Must use pubsub.register to hear FlexCard events across Shadow DOM
        pubsub.register('checkWarningModal', this.pubsubPayload); 

        // Setup LMS Subscription for agnostic/LWC triggers
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                DMT_WARNING_MODAL_CHANNEL,
                (message) => this.handleCheckWarningModal(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    disconnectedCallback() {
        pubsub.unregister('checkWarningModal', this.pubsubPayload);

        // Teardown LMS Subscription
        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
        }
    }

    // --- 4. Event Handler & Gatekeeper Logic ---
    async handleCheckWarningModal(payload) {
        console.log('Event just received (PubSub or LMS). Payload: ', JSON.stringify(payload));

        // ARCHITECTURAL GUARD: Ignore events that are responses to prevent infinite loops
        if (payload && payload.proceed !== undefined) {
            return;
        }

        this.actionIdentifier = payload?.actionIdentifier;
        
        // OmniStudio PubSub puts data directly in the payload, not event.detail
        this.tabOppInfo = payload?.tabOppInfo;
        this.tabOppProducts = payload?.tabOppProducts;
        this.tabClient = payload?.tabClient;

        // Force LDS to refresh cache so stageName is 100% accurate before checking
        if (this.recordId) {
            await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
        }

        // Condition: Is this an Opportunity AND is it in "Ready to close"?
        if (this.objectApiName === 'Opportunity' && this.stageName === 'Ready to close') {
            this.modalBodyText = 'The Opportunity will be modified and the associated cases and task will be reopened.';
            this.modalQuestionText = 'Do you want to modify the Opportunity?';
            this.checkCases();
        } else {
            // Bypass the modal entirely and proceed with save
            this.handleConfirmClick();
        }
    }

    async checkCases() {
        try {
            const cases = await getCasesByOpportunity({ opportunityId: this.recordId });
            
            if (!cases || cases.length === 0) {
                // No open cases found -> Bypass modal
                this.handleConfirmClick();
            } else {
                // Open cases found -> Trigger SLDS Modal
                this.showModal = true;
            }
        } catch (error) {
            console.error('Error checking cases:', error);
            this.showModal = true; // Safe fallback
        }
    }

    // --- 5. User Actions ---
    handleConfirmClick() {
        this.showModal = false;

        console.log('Event just about to be fired: isSaveRtC (PubSub) and proceed: true (LMS)');

        // Fire PubSub so the FlexCard can hear it across Shadow DOM
        pubsub.fire(this.currentPageReference, 'isSaveRtC', {
            event: 'isSaveRtC',
            isRtCSave: true
        });

        // Publish via LMS for decoupled LWC siblings
        publish(this.messageContext, DMT_WARNING_MODAL_CHANNEL, {
            actionIdentifier: this.actionIdentifier,
            proceed: true
        });
        
        this.firePubSubEvents();
    }

    handleCancelClick() {
        this.showModal = false;

        console.log('Event just about to be fired: closemodal (PubSub) and proceed: false (LMS)');

        pubsub.fire(this.currentPageReference, 'closemodal', {
            event: 'closemodal'
        });

        // Publish via LMS for decoupled LWC siblings
        publish(this.messageContext, DMT_WARNING_MODAL_CHANNEL, {
            actionIdentifier: this.actionIdentifier,
            proceed: false
        });
        
        this.firePubSubEvents();
    }

    firePubSubEvents() {
        if (this.tabOppInfo === 'tabOppInfo') {
            pubsub.fire(this.currentPageReference, 'DMT_Opportunity_Info_Tab', { event: 'reloadAfterSave' });
        }
        if (this.tabClient === 'tabClient') {
            pubsub.fire(this.currentPageReference, 'Button', { event: 'Reload' });
        }
        if (this.tabOppProducts === 'tabOppProducts') {
            pubsub.fire(this.currentPageReference, 'productOpportunityFields', { event: 'reloadParent' });
        }
    }
}