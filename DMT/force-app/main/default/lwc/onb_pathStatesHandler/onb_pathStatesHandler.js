import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import PATH_STEP_FIELD from '@salesforce/schema/ONB_Onboarding__c.Step__c';
import REQUEST_TYPE_FIELD from '@salesforce/schema/ONB_Onboarding__c.Request_Type__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getPathModel from '@salesforce/apex/ONB_PathConfigService.getPathModel';

const FIELDS = [PATH_STEP_FIELD, REQUEST_TYPE_FIELD];

export default class Onb_pathStatesHandler extends LightningElement {
    @api recordId;
    @api contextKey; // ahora se define dinámicamente según el tipo de solicitud (request type) del onboarding, para soportar múltiples paths en el futuro

    currentStep;
    selectedStep;
    model; // Apex PathModelDTO

    _didAutoFixStep = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ data, error }) {
        if (data) {
            this.currentStep = getFieldValue(data, PATH_STEP_FIELD);
            const requestTypeValue = getFieldValue(data, REQUEST_TYPE_FIELD);

            if (requestTypeValue === 'New client onboarding') {
                this.contextKey = 'NEW_CLIENT_ONBOARDING';
                console.log('Context key set to NEW_CLIENT_ONBOARDING based on request type:', requestTypeValue);
            } else if (requestTypeValue === 'Add funds (without derivations)' || requestTypeValue === 'Add funds to an existing contract (with derivatives/repos)') {
                this.contextKey = 'NEW_FUND_ONBOARDING';
                console.log('Context key set to NEW_FUND_ONBOARDING based on request type:', requestTypeValue);
            }

            // si selected no está inicializado, lo igualamos al current
            if (!this.selectedStep) {
                this.selectedStep = this.currentStep;
            }

        } else if (error) {
            console.error('getRecord error:', error);
        }
    }

    @wire(getPathModel, { onboardingId: '$recordId', contextKey: '$contextKey' })
    wiredModel({ data, error }) {
        if (data) {

            console.log('PATH MODEL:', JSON.stringify(data));
            console.log('STEPS:', data.steps?.map(s => s.key).join(', '));
            console.log('CURRENT STEP (model):', data.currentStep);

            this.model = data;

            if (!this._didAutoFixStep &&
                data.currentStep &&
                data.currentStep !== this.currentStep) {
                    this._didAutoFixStep = true;
                    this.currentStep = data.currentStep;
                    this.selectedStep = data.currentStep;
                    this.persistStep(data.currentStep);
            }

            // Si selected ya no existe, vuelve al current
            if (this.selectedStep && !this.steps.some(s => s.key === this.selectedStep)) {
                this.selectedStep = this.currentStep;
            }

        } else if (error) {
            console.error('PATH MODEL ERROR:', JSON.parse(JSON.stringify(error)));
        }
    }

    get steps() {
        return this.model?.steps || [];
    }

    get disableMarkComplete() {
        if (!this.model) return true;
        if (!this.currentStep) return true;

        const current = this.steps.find(s => s.key === this.currentStep);
        if (!current) return true;

        // Si quieres deshabilitar solo cuando intentan saltar a un step NO permitido:
        const targetKey = this.selectedStep || this.currentStep;
        const target = this.steps.find(s => s.key === targetKey);
        if (!target) return true;

        // Solo bloquea si target es futuro y no clickable (regla de avance)
        const currentIdx = this.steps.findIndex(s => s.key === this.currentStep);
        const targetIdx = this.steps.findIndex(s => s.key === targetKey);

        const isForward = targetIdx > currentIdx;
        return isForward && target.clickable === false;
    }

    async handleMarkComplete() {
        try {
            let target = this.selectedStep || this.currentStep;
            if (!target) return;

            const currentIdx = this.steps.findIndex(s => s.key === this.currentStep);
            const targetIdxInitial = this.steps.findIndex(s => s.key === target);

            // Si el usuario no seleccionó otro step (o seleccionó el mismo),
            // al marcar como completo avanzamos al siguiente si existe (comportamiento estándar)
            if (
                target === this.currentStep &&
                currentIdx >= 0 &&
                currentIdx < this.steps.length - 1
            ) {
                target = this.steps[currentIdx + 1].key;
            }

            const targetIdx = this.steps.findIndex(s => s.key === target);

            // BACK (siempre permitido, no valida)
            if (targetIdx >= 0 && currentIdx >= 0 && targetIdx < currentIdx) {
                await this.persistStep(target);
                this.currentStep = target;
                this.selectedStep = target;
                return;
            }

            // FORWARD / NEXT (requiere validar el step actual)
            const ok = await this.validateAndSaveCurrentStep();
            if (!ok) return;

            await this.persistStep(target);
            this.currentStep = target;
            this.selectedStep = target;
        } catch (e) {
            console.error('MARK COMPLETE ERROR:', e);

            const msg =
                e?.body?.message ||
                e?.body?.output?.errors?.[0]?.message ||
                e?.message ||
                'Error moving step';
            this.toast(msg, 'error');
        }
    }

    async validateAndSaveCurrentStep() {
        const cmp = this.getCurrentStepComponent();
        if (!cmp || typeof cmp.validate !== 'function') {
            return true;
        }

        try {
            const ok = await cmp.validate();
            if (!ok) this.toast('Debes completar los campos obligatorios antes de avanzar.', 'error');
            return ok;
        } catch (e) {
            console.error(e);
            this.toast('Error validando el step. Revisa consola.', 'error');
            return false;
        }
    }

    getCurrentStepComponent() {
        switch (this.currentStep) {
            case 'AML_KYC':
                return this.template.querySelector('c-onb_aml-kyc-state');
            case 'FUNDS':
                return this.template.querySelector('c-onb-funds-state');
            case 'PRODUCTS':
                return this.template.querySelector('c-onb_product-state');
            case 'CONTRACT':
                return this.template.querySelector('c-onb_contract-state');
            case 'RISK_INFO':
                return this.template.querySelector('c-onb_risk-state');
            default:
                return null;
        }
    }

    async persistStep(stepKey) {
        try {
             const fields = {
                Id: this.recordId,
                [PATH_STEP_FIELD.fieldApiName]: stepKey
            };
            await updateRecord({ fields });
        } catch (e) {
            console.error('PERSIST STEP ERROR (e):', e);
            console.error('PERSIST STEP ERROR message:', e?.body?.message || e?.message);
            console.error('PERSIST STEP ERROR output:', e?.body?.output);
            console.error('PERSIST STEP ERROR fieldErrors:', e?.body?.output?.fieldErrors);

            // errors generales
            console.error('PERSIST STEP ERROR errors:', e?.body?.output?.errors);
            throw e;
        }
    }

    toast(message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: variant === 'error' ? 'Error' : 'Info',
                message,
                variant
            })
        );
    }

    get isAmlKyc() {
        return this.currentStep === 'AML_KYC';
    }
    get isFunds() {
        return this.currentStep === 'FUNDS';
    }
    get isProducts() {
        return this.currentStep === 'PRODUCTS';
    }
    get isContract() {
        return this.currentStep === 'CONTRACT';
    }
    get isRiskInfo() {
        return this.currentStep === 'RISK_INFO';
    }

    //Validaciones
    handlePathStepSelect(event) {
        const nextStep = event.detail?.stepKey;
        if (!nextStep) return;
        this.selectedStep = nextStep;
    }
}