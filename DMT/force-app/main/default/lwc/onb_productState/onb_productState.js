import { LightningElement,api,wire } from 'lwc';
import getProductItems from '@salesforce/apex/ONB_ProductStepController.getProductItemsByOnboarding';
import getProductsByBookingEntityAndCategory from '@salesforce/apex/ONB_ProductStepController.getProductsByBookingEntityAndCategory';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { processAndCreateExternalContact, extractContactIdByType, deleteExternalContact } from 'c/onb_contactUtils';
import { CurrentPageReference } from 'lightning/navigation';
import PAYMENT_THROUGH_CLS_FIELD from '@salesforce/schema/ONB_Onboarding__c.Payment_Through_CLS__c';
import CONFIG_CONTACT_FIELD from '@salesforce/schema/ONB_Onboarding__c.Configuration_contact_CLS_platform__c';
import ANY_MASTER_AGREEMENT_FIELD from '@salesforce/schema/ONB_Onboarding__c.Any_Master_Agreement__c';
import getExternalContact from '@salesforce/apex/ONB_RelationshipContactsController.getExternalContactsByOnboarding';

// ----------------------
// Custom labels
// ----------------------
import ONB_PROD_BOOKING_ENTITY from '@salesforce/label/c.ONB_PROD_BOOKING_ENTITY';
import ONB_PROD_CATEGORY from '@salesforce/label/c.ONB_PROD_CATEGORY';
import ONB_PROD_PRODUCT from '@salesforce/label/c.ONB_PROD_PRODUCT';
import ONB_PROD_SELLING_LOCATION from '@salesforce/label/c.ONB_PROD_SELLING_LOCATION';
import ONB_PROD_BRANCH_CODE from '@salesforce/label/c.ONB_PROD_BRANCH_CODE';
import ONB_PROD_ACCOUNT_OFFICER from '@salesforce/label/c.ONB_PROD_ACCOUNT_OFFICER';
import ONB_PROD_COMMENTS from '@salesforce/label/c.ONB_PROD_COMMENTS';
import ONB_PROD_LIQUIDATION_CLS from '@salesforce/label/c.ONB_PROD_LIQUIDATION_CLS';
import ONB_PROD_CUSTOMER_SETTLE_THROUGH_CLS from '@salesforce/label/c.ONB_PROD_CUSTOMER_SETTLE_THROUGH_CLS';
import ONB_PROD_WHO_IS_CONTACT from '@salesforce/label/c.ONB_PROD_WHO_IS_CONTACT';
import ONB_CLIENT_CONTACT_EMAIL from '@salesforce/label/c.ONB_CLIENT_CONTACT_EMAIL';
import ONB_CLIENT_CONTACT_LAST_NAME from '@salesforce/label/c.ONB_CLIENT_CONTACT_NAME';

// ----------------------
// Helpers
// ----------------------
const mapFromPairs = (pairs) => Object.freeze(Object.fromEntries(pairs));
const freezeList = (list) => Object.freeze([...list]);

const SECTIONS = Object.freeze({
    businessCaseRight: {
        fields: freezeList(['Payment_Through_CLS__c']),
        labels: mapFromPairs([
            ['Payment_Through_CLS__c', ONB_PROD_CUSTOMER_SETTLE_THROUGH_CLS]
        ])
    },
    businessCaseLeft: {
        fields: freezeList(['Configuration_contact_CLS_platform__c']),
        labels: mapFromPairs([
            ['Configuration_contact_CLS_platform__c', ONB_PROD_WHO_IS_CONTACT],
        ])
    },
    clientContactRight: {
        fields: freezeList(['Name']),
        labels: mapFromPairs([
            ['Name', ONB_CLIENT_CONTACT_LAST_NAME]
        ])
    },
    clientContactLeft: {
        fields: freezeList(['Email__c']),
        labels: mapFromPairs([
            ['Email__c', ONB_CLIENT_CONTACT_EMAIL]
        ])
    }

});

const ONBOARDING_OBJECT_LINE_API_NAME = 'ONB_Onboarding_Line__c';
const ONBOARDING_ID_API_NAME = 'OnboardingId__c';
//--- Constantes para formulario de Liquidation Through CLS---
const ONBOARDING_OBJ_API_NAME = 'ONB_Onboarding__c';
const CONTACT_OBJ_API_NAME = 'ONB_External_Contact__c';
const LIQUIDATION_THROUGH_CLS_CONTACT_TYPE = 'LIQUIDATION_THROUGH_CLS';

const FIELD_PAYMENT_THROUGH_CLS = 'Payment_Through_CLS__c';
const FIELD_CONFIG_CONTACT = 'Configuration_contact_CLS_platform__c';

const ONBOARDING_FIELDS = [
    PAYMENT_THROUGH_CLS_FIELD,
    CONFIG_CONTACT_FIELD,
    ANY_MASTER_AGREEMENT_FIELD
];
const FX_CATEGORY_VALUE = 'FX';
const FIXED_INCOME_RATES_CATEGORY_VALUE = 'Fixed Income & Rates';
const FX_SPOT_PRODUCT_NAME = 'FX Spot';
const BONDS_PRODUCT_NAME = 'Bonds';

export default class Onb_productState extends LightningElement {
    @api recordId;
    @api rows = [];
    //Objeto sobre el que se va realizar el CRUD
    @api objectApiName = ONBOARDING_OBJECT_LINE_API_NAME;
    @api parentFieldApiName = ONBOARDING_ID_API_NAME;
    @api objOnboardingApiName = ONBOARDING_OBJ_API_NAME;
    @api objContactApiName = CONTACT_OBJ_API_NAME;
    @api productCategory;
    @api requiredFieldApiNames = ['Booking_Entity__c', 'Product_Category__c', 'Product2Id__c'];
    productCategoryByRow = {};
    productsCacheByKey = {};
    productOptionsByRowId = {};
    bookingEntityByRow = {};

    contactValues = {};
    externalContactId;
    nonce = String(Date.now());

    sections = SECTIONS;
    label = {
        ONB_PROD_LIQUIDATION_CLS,
        ONB_PROD_CUSTOMER_SETTLE_THROUGH_CLS,
        ONB_PROD_WHO_IS_CONTACT
    }

    paymentThroughClsValue;
    configContactValue;
    anyMasterAgreementValue;
    currentPageReference;

    get fundsOnboardingSessionKey() {
        return this.recordId ? `onb_funds_onboarding_${this.recordId}` : null;
    }

    get showWhoIsContactPicklist() {
        return this.paymentThroughClsValue === 'Yes';
    }

    get showClientForm() {
        return this.showWhoIsContactPicklist && this.configContactValue === 'CLS team';
    }

    get showLiquidationThroughCls() {
        return Object.values(this.productCategoryByRow || {}).some(v => String(v || '').trim() === FX_CATEGORY_VALUE);
    }

    get restrictProductCategoryForNoMasterAgreement() {
        return this.anyMasterAgreementValue === 'No' || this.isFromFundsOnboardingFlow;
    }

    get isFromFundsOnboardingFlow() {
        const byState = this.currentPageReference?.state?.c__fundsOnboarding;
        if (byState === '1') {
            return true;
        }

        const key = this.fundsOnboardingSessionKey;
        if (!key) {
            return false;
        }

        try {
            return window.sessionStorage.getItem(key) === '1';
        } catch (e) {
            return false;
        }
    }

    @wire(CurrentPageReference)
    wiredPageReference(value) {
        this.currentPageReference = value;
    }

    @wire(getRecord, { recordId: '$recordId', fields: ONBOARDING_FIELDS })
    wiredOnboarding({ data, error }) {
        if (data) {
            this.paymentThroughClsValue = getFieldValue(data, PAYMENT_THROUGH_CLS_FIELD);
            this.configContactValue = getFieldValue(data, CONFIG_CONTACT_FIELD);
            this.anyMasterAgreementValue = getFieldValue(data, ANY_MASTER_AGREEMENT_FIELD);
            return;
        }
        if (error) {
            console.error('wiredOnboarding error', error);
        }
    }

    filterFundsOnboardingProducts(products, productCategory) {
        const options = (products || []).map(p => ({
            label: p.Name,
            value: p.Id
        }));

        if (!this.isFromFundsOnboardingFlow) {
            return options;
        }

        if (productCategory === FX_CATEGORY_VALUE) {
            return options.filter(opt => opt.label === FX_SPOT_PRODUCT_NAME);
        }

        if (productCategory === FIXED_INCOME_RATES_CATEGORY_VALUE) {
            return options.filter(opt => opt.label === BONDS_PRODUCT_NAME);
        }

        return [];
    }

    handleOnboardingFieldChange(event) {
        const { fieldApiName, value } = event.detail || {};
        if (!fieldApiName) return;

        if (fieldApiName === FIELD_PAYMENT_THROUGH_CLS) {
            this.paymentThroughClsValue = value;

            if (value !== 'Yes') {
                this.configContactValue = null;
            }
            return;
        }

        if (fieldApiName === FIELD_CONFIG_CONTACT) {
            this.configContactValue = value;
        }
    }

    columns = [
        { key: 'bookingEntity', label: ONB_PROD_BOOKING_ENTITY, fieldName: 'Booking_Entity__c', type: 'picklist' },
        { key: 'productCategory', label: ONB_PROD_CATEGORY, fieldName: 'Product_Category__c', type: 'dependentPicklist', controllerFieldName: 'Booking_Entity__c'},
        { key: 'product', label: ONB_PROD_PRODUCT, fieldName: 'Product2Id__c', type: 'dependentPicklist', controllerFieldName: 'Product_Category__c', optionsKey: 'productOptions'},
        { key: 'sellingLocation', label: ONB_PROD_SELLING_LOCATION, fieldName: 'Selling_Location__c', type: 'picklist' },
        { key: 'branchCode', label: ONB_PROD_BRANCH_CODE,  fieldName: 'Branch_Code__c',  type: 'input' },
        { key: 'accountOfficer',  label: ONB_PROD_ACCOUNT_OFFICER, fieldName: 'Account_Officer__c',  type: 'text' },
        { key: 'comments', label:ONB_PROD_COMMENTS, fieldName:'Comments__c', type:'textarea' }
    ];

    conditionalRequiredRules = [
        {
            when: (row) => String(row?.Booking_Entity__c || '').trim() !== 'BBVA_SA_Spain',
            requiredFields: ['Branch_Code__c', 'Account_Officer__c']
        }
    ];

    async loadProductItems() {
        try {
            this.rows = await getProductItems({ onboardingId: this.recordId });
        } catch (e) {
            console.error(JSON.stringify(e));
            this.rows = [];
        }
    }

    async loadProductsByBookingEntityAndCategory(rowKey, bookingEntity, productCategory, onboardingId) {
        try {
            if (!rowKey || !bookingEntity || !productCategory || !onboardingId) {
                console.log('Missing data, aborting');
                return;
            }

            const cacheKey = `${bookingEntity}::${productCategory}`;
            let options = this.productsCacheByKey?.[cacheKey];

            if (!options) {
                const products = await getProductsByBookingEntityAndCategory({
                    bookingEntity,
                    productCategory,
                    onboardingId
                });

                options = this.filterFundsOnboardingProducts(products, productCategory);

                this.productsCacheByKey = {
                    ...this.productsCacheByKey,
                    [cacheKey]: options
                };
            }

            this.productOptionsByRowId = {
                ...this.productOptionsByRowId,
                [rowKey]: options
            };

        } catch (e) {
            console.error(
                'loadProductsByBookingEntityAndCategory ERROR',
                e,
                e?.body?.message,
                e?.message
            );
        }
    }

    async handleProductCategoryChange(event) {
        const { rowIndex, rowId, rowKey, productCategory } = event.detail || {};
        const key = rowKey || rowId || `idx-${rowIndex}`;
        const onboardingId = this.recordId;

        this.productCategoryByRow = {
            ...this.productCategoryByRow,
            [key]: productCategory
        };

        const table = this.template.querySelector('c-onb_onboarding-table');
        if (table) {
            await table.setCellValue(rowIndex, 'Product2Id__c', null);
        }

        this.productOptionsByRowId = {
            ...this.productOptionsByRowId,
            [key]: []
        };

        const bookingEntity = this.bookingEntityByRow?.[key];
        await this.loadProductsByBookingEntityAndCategory(key, bookingEntity, productCategory, onboardingId);
        this.notifyProductsChanged();
    }

    async handleBookingEntityChange(event) {
        const { rowIndex, rowId, rowKey, bookingEntity } = event.detail || {};
        const key = rowKey || rowId || `idx-${rowIndex}`;

        this.bookingEntityByRow = {
            ...this.bookingEntityByRow,
            [key]: bookingEntity
        };

        // Limpia estado dependiente
        this.productCategoryByRow = {
            ...this.productCategoryByRow,
            [key]: null
        };

        this.productOptionsByRowId = {
            ...this.productOptionsByRowId,
            [key]: []
        };

        const table = this.template.querySelector('c-onb_onboarding-table');
        if (table) {
            await table.setCellValue(rowIndex, 'Product_Category__c', null);
            await table.setCellValue(rowIndex, 'Product2Id__c', null);
        }
        this.notifyProductsChanged();
    }

    handleProductChange() {
        this.notifyProductsChanged();
    }

    handleRowCreated() {
        this.notifyProductsChanged();
    }

    handleRowDeleted(event) {
        const { id, rowIndex } = event.detail || {};
        const key = id || `idx-${rowIndex}`;
        this.cleanupRowCaches(key);
        this.notifyProductsChanged();
    }

    handleRowUnlink(event) {
        const { id, rowIndex } = event.detail || {};
        const key = id || `idx-${rowIndex}`;
        this.cleanupRowCaches(key);
        this.notifyProductsChanged();
    }

    notifyProductsChanged() {
        window.dispatchEvent(new CustomEvent('onbproductschanged', {
            detail: { recordId: this.recordId }
        }));
    }

    cleanupRowCaches(key) {
        const cat = { ...(this.productCategoryByRow || {}) };
        delete cat[key];
        this.productCategoryByRow = cat;

        const booking = { ...(this.bookingEntityByRow || {}) };
        delete booking[key];
        this.bookingEntityByRow = booking;

        const opts = { ...(this.productOptionsByRowId || {}) };
        delete opts[key];
        this.productOptionsByRowId = opts;
    }

    async rebuildProductOptionsForAllRows() {
        const byId = {};
        const rows = this.rows || [];
        const onboardingId = this.recordId;

        for (let idx = 0; idx < rows.length; idx++) {
            const row = rows[idx];
            const rowKey = row?._key || row?.Id || `idx-${idx}`;
            const category = row?.Product_Category__c;
            const bookingEntity = row?.Booking_Entity__c;

            if (!rowKey || !category || !bookingEntity) continue;

            const cacheKey = `${bookingEntity}::${category}`;
            let options = this.productsCacheByKey?.[cacheKey];

            if (!options) {
                const products = await getProductsByBookingEntityAndCategory({
                    bookingEntity,
                    productCategory: category,
                    onboardingId
                });

                options = this.filterFundsOnboardingProducts(products, category);

                this.productsCacheByKey = {
                    ...this.productsCacheByKey,
                    [cacheKey]: options
                };
            }

            byId[rowKey] = options;
        }

        this.productOptionsByRowId = byId;
    }

    async loadLines() {
        this.rows = await getProductItems({ onboardingId: this.recordId });
        await this.rebuildProductOptionsForAllRows();

        const categoryMap = {};
        const bookingMap = {};

        (this.rows || []).forEach((r, idx) => {
            const key = r?.Id || `idx-${idx}`;
            categoryMap[key] = r?.Product_Category__c;
            bookingMap[key] = r?.Booking_Entity__c;
        });

        this.productCategoryByRow = categoryMap;
        this.bookingEntityByRow = bookingMap;
    }

    @wire(getExternalContact, { onboardingId: '$recordId', nonce: '$nonce' })
    wiredRelationships({ data }) {
            this.externalContactId = extractContactIdByType(data, LIQUIDATION_THROUGH_CLS_CONTACT_TYPE) || this.externalContactId;
    }

    //Validacion
    @api
    async validate() {
        let ok = true;

        this.template.querySelectorAll('c-onb_onboarding-form').forEach(cmp => {
            if (typeof cmp.validate === 'function' && !cmp.validate()) ok = false;
        });

        this.template.querySelectorAll('c-onb_onboarding-table').forEach(cmp => {
            if (typeof cmp.validate === 'function' && !cmp.validate()) ok = false;
        });

        if (!this.showClientForm && this.externalContactId) {
            await deleteExternalContact(this, this.externalContactId);
            this.externalContactId = null;
            this.contactValues = {};
        }

        if(ok && this.showClientForm){
            if (Object.keys(this.contactValues).length === 0) return ok;
            this.contactValues.OnboardingId__c = this.recordId; // Asociamos el contacto al onboarding
            this.contactValues.Type__c = LIQUIDATION_THROUGH_CLS_CONTACT_TYPE;

            const result = await processAndCreateExternalContact(this, this.contactValues, this.externalContactId);
            if (result.success) {
                this.externalContactId = result.contactId; // Guardamos el ID
                this.contactValues = {}; // Vaciamos los cambios
            }
            ok = result.success;
        }

        return ok;
    }

    connectedCallback() {
        this.loadLines();
    }

    handleContactFieldChange(event) {
        const { fieldApiName, value } = event.detail || {};
        if (fieldApiName) {
            this.contactValues[fieldApiName] = value;
        }
    }
}