import { api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import LightningModal from 'lightning/modal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ANY_MASTER_AGREEMENT_FIELD from '@salesforce/schema/ONB_Onboarding__c.Any_Master_Agreement__c';

import getLineItems from '@salesforce/apex/ONB_FundItemController.getLineItems';
import getProductItemsForFunds from '@salesforce/apex/ONB_ProductStepController.getProductItemsForFunds';
import getContractLineCategoryStatus from '@salesforce/apex/ONB_MasterAgreementsController.getContractLineCategoryStatus';

import ONB_LINE_TYPE from '@salesforce/label/c.ONB_LINE_TYPE';
import ONB_LINE_SUBTYPE from '@salesforce/label/c.ONB_LINE_SUBTYPE';
import ONB_LINE_AMOUNT from '@salesforce/label/c.ONB_LINE_AMOUNT';
import ONB_LINE_CURRENCY from '@salesforce/label/c.ONB_LINE_CURRENCY';
import ONB_LINE_MATURITY from '@salesforce/label/c.ONB_LINE_MATURITY';

import ONB_REQUIRED_FIELDS from '@salesforce/label/c.ONB_REQUIRED_FIELDS';

const ONBOARDING_LINE_OBJECT_API_NAME = 'ONB_Line__c';
const FUND_ID_API_NAME = 'FundItemId__c';

const LINE_TYPE_FIELD = 'Line_Type__c';
const LINE_TYPES_SETTLEMENT_ONLY = ['LC_DVP'];
const LINE_TYPES_STANDARD = ['LC_DVP', 'LC_CRED'];
const LINE_TYPES_WITH_REPO = ['LC_DVP', 'LC_CRED', 'LC_REPOS'];

export default class Onb_assignLinesToFunds extends LightningModal {
    @api fundId;
    @api header;
    @api recordOnboardingId;

    rows = [];
    wiredResult;

    onboardingLineObjApiName = ONBOARDING_LINE_OBJECT_API_NAME;
    parentFieldApiName = FUND_ID_API_NAME;

    hasRepoContracts = false;
    picklistAllowedValuesByField = {};
    hasSettlementOnlyProduct = false;
    contractStatusNonce = String(Date.now());

    toast(message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: variant === 'error' ? 'Error' : 'Info',
                message,
                variant
            })
        );
    }

    lineTypeSubtypeMaxRules = [
        { typeValue: 'LC_DVP', subtypeValue: 'DVP', max: 1 },
        { typeValue: 'LC_DVP', subtypeValue: 'Free Delivery', max: 1 },
        { typeValue: 'LC_REPOS', subtypeValue: 'Flow', max: 1 },
        { typeValue: 'LC_REPOS', subtypeValue: 'No Flow', max: 1 }
    ];

    requiredFieldApiNames = ['Line_Type__c', 'Amount__c', 'ONB_Currency__c', 'ONB_Maturity__c'];

    conditionalRequiredRules = [
        {
        when: (row) => row?.ONB_Line_Subtype__c,
        requiredFields: ['ONB_Line_Subtype__c']
        }
    ];

    columns = [
        { key: 'lineType', label: ONB_LINE_TYPE, fieldName: 'Line_Type__c', type: 'picklist' },
        { key: 'lineSubtype', label: ONB_LINE_SUBTYPE, fieldName: 'ONB_Line_Subtype__c', type: 'dependentPicklist', controllerFieldName: 'Line_Type__c' },
        { key: 'amount', label: ONB_LINE_AMOUNT, fieldName: 'Amount__c', type: 'number' },
        { key: 'currency', label: ONB_LINE_CURRENCY, fieldName: 'ONB_Currency__c', type: 'picklist' },
        { key: 'maturity', label: ONB_LINE_MATURITY, fieldName: 'ONB_Maturity__c', type: 'picklist' }
    ];

    isNoMasterAgreement = false;

    get isSettlementOnlyBecauseNoMasterAgreement() {
        return this.isNoMasterAgreement;
    }

    get currentLinesCount() {
        return Array.isArray(this.rows) ? this.rows.length : 0;
    }

    get disableAddLineButton() {
        return this.isSettlementOnlyBecauseNoMasterAgreement && this.currentLinesCount >= 2;
    }

    get defaultLineValues() {
        if (this.isSettlementOnlyBecauseNoMasterAgreement) {
            return {
                Line_Type__c: 'LC_DVP'
            };
        }
        return {};
    }

    @wire(getRecord, {
        recordId: '$recordOnboardingId',
        fields: [ANY_MASTER_AGREEMENT_FIELD]
    })
    wiredOnboarding({ data, error }) {
        if (data) {
            this.isNoMasterAgreement =
                getFieldValue(data, ANY_MASTER_AGREEMENT_FIELD) === 'No';

            this.applyLineTypeFilter();
        } else if (error) {
            console.error('Error loading onboarding master agreement flag', error);
            this.isNoMasterAgreement = false;
            this.applyLineTypeFilter();
        }
    }

    connectedCallback() {
        this.loadRepoContext();
    }

    @wire(getContractLineCategoryStatus, { onboardingId: '$recordOnboardingId', cacheBuster: '$contractStatusNonce' })
    wiredContractCategoryStatus({ data, error }) {
        if (data) {
            this.hasRepoContracts = !!data.hasReposContracts;
        } else if (error) {
            console.error('Error loading contract line category status', error);
            this.hasRepoContracts = false;
        }

        this.applyLineTypeFilter();
    }

    @wire(getLineItems, { fundId: '$fundId', cacheBuster: String(Date.now()) })
    wiredLineItems(result) {
        this.wiredResult = result;

        if (result.data) {
            this.rows = result.data;
        } else if (result.error) {
            console.error(JSON.stringify(result.error));
            this.rows = [];
        }
    }

    async loadRepoContext() {
        this.hasSettlementOnlyProduct = false;
        this.applyLineTypeFilter();

        if (!this.recordOnboardingId || !this.fundId) {
            return;
        }

        try {
            const dto = await getProductItemsForFunds({
                onboardingId: this.recordOnboardingId,
                fundId: this.fundId,
                cacheBuster: String(Date.now())
            });

            const preselectedIds = new Set(dto?.preselectedProductIds || []);
            const associatedProducts = (dto?.products || []).filter(p => preselectedIds.has(p.Id));

            console.log('dto', JSON.stringify(dto));
            console.log('preselectedProductIds', JSON.stringify(dto?.preselectedProductIds));
            console.log('products', JSON.stringify(dto?.products));
            console.log('associatedProducts', JSON.stringify(associatedProducts));

            this.hasSettlementOnlyProduct = associatedProducts.some(p => {
                const category = ((p?.Product2Id__r?.Name) || '').trim();
                return category === 'FX Spot' || category === 'Bonds';
            });

            console.log('hasSettlementOnlyProduct', this.hasSettlementOnlyProduct);

        } catch (e) {
            console.error('loadRepoContext error', e);
            this.hasSettlementOnlyProduct = false;
        }

        this.applyLineTypeFilter();
    }

    applyLineTypeFilter() {
        let allowedValues = LINE_TYPES_STANDARD;

        if (this.isNoMasterAgreement) {
            allowedValues = LINE_TYPES_SETTLEMENT_ONLY;
        } else if (this.hasSettlementOnlyProduct) {
            allowedValues = LINE_TYPES_SETTLEMENT_ONLY;
        } else if (this.hasRepoContracts) {
            allowedValues = LINE_TYPES_WITH_REPO;
        }

        this.picklistAllowedValuesByField = {
            [LINE_TYPE_FIELD]: allowedValues
        };
    }

    async handleRowChange() {
        await refreshApex(this.wiredResult);
        await this.loadRepoContext();
    }

    async validateAndSaveCurrentStep() {
        if (typeof this.validate !== 'function') {
            return true;
        }

        try {
            const ok = await this.validate();
            console.log('validate2 ok: '+ok);

            if (!ok) this.toast(ONB_REQUIRED_FIELDS, 'error');
            return ok;
        } catch (e) {
            console.error(e);
            this.toast('Error validando las lineas. Revisa consola.', 'error');
            return false;
        }
    }

    async handleClose() {
        const ok = await this.validateAndSaveCurrentStep();
        if (!ok) return;

        this.close({ saved: true });
    }

    @api
    validate() {
        let ok = true;

        this.template.querySelectorAll('c-onb_onboarding-table').forEach((cmp) => {
            if (cmp?.validate && !cmp.validate()) ok = false;
        });

        console.log('validate ok: '+ok);
        return ok;
    }
}