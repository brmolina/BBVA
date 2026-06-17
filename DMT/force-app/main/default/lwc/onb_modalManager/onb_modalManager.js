import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';

import onb_createNewOnboarding from 'c/onb_createNewOnboarding';
import onb_createNonClientLWC from 'c/onb_createNonClientLWC';
import onb_createContactModal from 'c/onb_createContactModal';


import ONB_RT_NEWCLIENT from '@salesforce/label/c.ONB_RT_NEWCLIENT';

const CREATE_NEW_ONBOARDING = 'onb_createNewOnboarding';
const SEARCH_SCREEN_ONB = 'onb_createNonClientLWC';
const CREATE_CONTACT_MODAL = 'onb_createContactModal';

export default class Onb_modalManager extends NavigationMixin(LightningElement) {
    @api recordId;
    @api componentName;
    @api accRecordTypeId;
    @api buttonLabel;
    @api buttonIcon;
    @api className;
    @api disableContinue;
    @api clientName;
    @api clientLei;
    @api existingClientType;

    _hasOpened = false;
    _pageRefRecordId;

    @wire(CurrentPageReference)
    wiredPageRef(pageRef) {
        const rid = pageRef?.attributes?.recordId || pageRef?.state?.recordId;
        if (rid) {
            this._pageRefRecordId = rid;
            this.tryAutoOpen();
        }
    }

    connectedCallback() {
    }

    renderedCallback() {
        this.tryAutoOpen();
    }

    get effectiveRecordId() {
        return this.recordId || this._pageRefRecordId;
    }

    tryAutoOpen() {
        if (this._hasOpened) return;
        if (this.buttonLabel) return;

        const needsRecordId = !this.componentName; 
        if (needsRecordId && !this.effectiveRecordId) return;

        this._hasOpened = true;
        Promise.resolve().then(() => this.handleOpenModal());
    }

    async handleOpenModal() {
        if (!this.componentName) {
            await this.newOnboardingOnExistingClient();
            return;
        }

        switch (this.componentName) {
            case CREATE_NEW_ONBOARDING:
                await this.runOnboardingOnlyFlow();
                break;

            case SEARCH_SCREEN_ONB:
                await this.runFullNonClientOnboardingFlow();
                break;

            case CREATE_CONTACT_MODAL:
                await this.runCreateContactModal();
                break;

            default:
                break;
        }
    }

    async runCreateContactModal() {
       try{
           const contactResult = await onb_createContactModal.open({
               size: 'medium',
               header: this.buttonLabel, 
               footer: true,
               recordId: this.recordId,
           });
           // Cuando el modal se cierra, comprobamos si nos mandó el mensaje de éxito
            if (contactResult && contactResult.action === 'create') {
                // Disparamos un evento hacia arriba (hacia la Tabla)
                this.dispatchEvent(new CustomEvent('registrocreado'));
            }
       } catch(error){
            console.error('runCreateContactModal ERROR (e):', error);
            console.error('runCreateContactModal ERROR message:', error?.body?.message || error?.message);
            console.error('runCreateContactModal ERROR output:', error?.body?.output);
            console.error('runCreateContactModal ERROR fieldErrors:', error?.body?.output?.fieldErrors);

            // errors generales
            console.error('runCreateContactModal ERROR errors:', error?.body?.output?.errors);
            throw error;
       }
    }

    async runOnboardingOnlyFlow() {
        const onboardingResult = await onb_createNewOnboarding.open({
            size: 'medium',
            header: ONB_RT_NEWCLIENT,
            showFooter: true,
            clientName: this.clientName,
            clientLei: this.clientLei,
            accRecordTypeId: this.accRecordTypeId
        });

        if (!onboardingResult || onboardingResult.action === 'cancel') {
            this.navigateToAccountList();
            return;
        }

        if (onboardingResult.action === 'create') {
            const onboardingId = onboardingResult.payload?.onboardingId;
            if (onboardingId) {
                this.navigateToOnboarding(onboardingId);
            }
        }
    }

    async runFullNonClientOnboardingFlow() {
        let keepRunning = true;
        let currentName = this.clientName;
        let currentLei = this.clientLei;

        while (keepRunning) {
            const nonClientResult = await onb_createNonClientLWC.open({
                size: 'small',
                header: ONB_RT_NEWCLIENT,
                showFooter: true
            });

            if (!nonClientResult || nonClientResult.action === 'cancel') {
                this.navigateToAccountList();
                keepRunning = false;
                break;
            }

            if (nonClientResult.action !== 'continue') {
                keepRunning = false;
                break;
            }

            currentName = nonClientResult.payload?.clientName || currentName;
            currentLei = nonClientResult.payload?.clientLei || currentLei;

            const onboardingResult = await onb_createNewOnboarding.open({
                size: 'medium',
                header: ONB_RT_NEWCLIENT,
                showFooter: true,
                clientName: currentName,
                clientLei: currentLei,
                accRecordTypeId: this.accRecordTypeId
            });

            if (!onboardingResult || onboardingResult.action === 'cancel') {
                this.navigateToAccountList();
                keepRunning = false;
                break;
            }

            if (onboardingResult.action === 'create') {
                const onboardingId = onboardingResult.payload?.onboardingId;
                if (onboardingId) {
                    this.navigateToOnboarding(onboardingId);
                }
                keepRunning = false;
                break;
            }

            if (onboardingResult.action === 'back') {
                currentName = onboardingResult.payload?.clientName;
                currentLei = onboardingResult.payload?.clientLei;
                continue;
            }

            keepRunning = false;
        }
    }

    async newOnboardingOnExistingClient() {
        const onboardingResult = await onb_createNewOnboarding.open({
            size: 'medium',
            header: ONB_RT_NEWCLIENT,
            showFooter: true,
            existingClient: true,
            recordId: this.effectiveRecordId,
            existingClientType: this.existingClientType
        });

        if (!onboardingResult || onboardingResult.action === 'cancel') {
            this.dispatchEvent(new CloseActionScreenEvent());
            return;
        }

        if (onboardingResult.action === 'create') {
            const onboardingId = onboardingResult.payload?.onboardingId;
            if (onboardingId) {
                this.navigateToOnboarding(onboardingId);
            }
        }
    }

    navigateToOnboarding(onboardingId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: onboardingId,
                actionName: 'view'
            }
        });
    }

    navigateToAccountList() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Account',
                actionName: 'list'
            }
        });
    }
}