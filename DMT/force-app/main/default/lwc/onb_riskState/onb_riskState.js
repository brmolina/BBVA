import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { processAndCreateExternalContact, extractContactIdByType, deleteExternalContact } from 'c/onb_contactUtils';
import getExternalContact from '@salesforce/apex/ONB_RelationshipContactsController.getExternalContactsByOnboarding';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getFundItems from '@salesforce/apex/ONB_FundItemController.getFundItems';
import onb_assignRiskLinesModal from 'c/onb_assignRiskLinesModal';

// ----------------------
// Card titles (labels)
// ----------------------
import ONB_RISK_CLIENT_CONTACT from '@salesforce/label/c.ONB_RISK_CLIENT_CONTACT';
import ONB_RISK_TOOLBAR_MSG from '@salesforce/label/c.ONB_RISK_TOOLBAR_MSG';
import ONB_RISK_WARNING_MSG from '@salesforce/label/c.ONB_RISK_WARNING_MSG';

// ----------------------
// Field labels (custom labels)
// ----------------------
// Legal client contact
import ONB_LEGAL_CLIENT_NAME from '@salesforce/label/c.ONB_LEGAL_CLIENT_NAME';
import ONB_LEGAL_CLIENT_EMAIL from '@salesforce/label/c.ONB_LEGAL_CLIENT_EMAIL';
import ONB_LEGAL_CLIENT_ADDRESS from '@salesforce/label/c.ONB_LEGAL_CLIENT_ADDRESS';

// ----------------------
const mapFromPairs = (pairs) => Object.freeze(Object.fromEntries(pairs));
const freezeList = (list) => Object.freeze([...list]);

// ----------------------
// Sections (fields + labels)
// ----------------------
const SECTIONS = Object.freeze({
    riskClientContactLeft: {
        fields: freezeList(['Name', 'Email__c']),
        labels: mapFromPairs([
            ['Name', ONB_LEGAL_CLIENT_NAME],
            ['Email__c', ONB_LEGAL_CLIENT_EMAIL]
        ])
    },

    riskClientContactRight: {
        fields: freezeList(['Address__c']),
        labels: mapFromPairs([
            ['Address__c', ONB_LEGAL_CLIENT_ADDRESS]
        ])
    }
});

// ----------------------
// Rules placeholders per section
// Fill these with your required/disabled/readonly/visibility logic
// ----------------------
const RULES = Object.freeze({
    riskClientContactLeft: Object.freeze({}),
    riskClientContactRight: Object.freeze({}),
});

const CONTACT_OBJ_API_NAME = 'ONB_External_Contact__c';
const RISK_CLIENT_CONTACT_TYPE = 'RISK_CLIENT_CONTACT';
const FUND_ITEM_OBJECT_API_NAME = 'ONB_Fund_Item__c';

export default class Onb_riskState extends LightningElement {
    _loadingForOnboardingId;
    externalContactId;
    _recordId;
    clientId;
    isInvestmentManagerOrHedgeFund = false;
    fundsRowsForTable = [];
    wiredFundsResult;
    fundsTableObjectApiName = FUND_ITEM_OBJECT_API_NAME;

    @api objContactApiName = CONTACT_OBJ_API_NAME;
    contactValues = {};
    nonce = String(Date.now());
    fundsCacheBuster = String(Date.now());
    fundsTableColumns = [
        { key: 'warning', label: '', fieldName: 'warningIcon', type: 'icon', hideDefaultActions: true, tooltipFieldName: 'warningTooltip' },
        { key: 'fundType', label: 'Type of fund', fieldName: 'ONB_Fund_Type__c', type: 'text' },
        { key: 'fundName', label: 'Fund name', fieldName: 'ONB_FundName__c', type: 'text' },
        { key: 'leiOrStarCode', label: 'LEI / STARCODE', fieldName: 'lei_id__c', type: 'text' },
        { key: 'cif', label: 'CIF', fieldName: 'ONB_CIF__c', type: 'text' }
    ];

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        this._recordId = value;
    }

    sections = SECTIONS;
    rules = RULES;

    label = {
        ONB_RISK_CLIENT_CONTACT,
        ONB_RISK_TOOLBAR_MSG,
        ONB_RISK_WARNING_MSG
    };

    @wire(getExternalContact, { onboardingId: '$recordId', nonce: '$nonce' })
    wiredRelationships({ data }) {
        this.externalContactId = extractContactIdByType(data, RISK_CLIENT_CONTACT_TYPE) || this.externalContactId;
    }

    @wire(getRecord, { recordId: '$recordId', fields: ['ONB_Onboarding__c.Legal_Entity_Type__c'] })
    wiredOnboarding({ data, error }) {
        if (data) {
            const legalEntityType = data.fields.Legal_Entity_Type__c?.value;
            this.isInvestmentManagerOrHedgeFund = legalEntityType === 'Investment Manager' || legalEntityType === 'Hedge Fund';
        } else if (error) {
            this.isInvestmentManagerOrHedgeFund = false;
            console.error('Error loading onboarding legal entity type:', error);
        }
    }

    @wire(getFundItems, { onboardingId: '$recordId', cacheBuster: '$fundsCacheBuster' })
    wiredFundItems(result) {
        this.wiredFundsResult = result;

        if (result.data) {
            this.fundsRowsForTable = (result.data || []).map((row) => ({
                Id: row.fundId,
                ONB_Fund_Type__c: row.fundType,
                ONB_FundName__c: row.fundName,
                lei_id__c: row.leiId,
                ONB_CIF__c: row.cif,
                hasLinkedContract: row.hasLinkedContract,
                hasLinkedProduct: row.hasLinkedProduct,
                warningIcon: (!row.hasLinkedProduct && !row.hasLinkedContract) ? 'utility:warning' : '',
                warningTooltip: (!row.hasLinkedProduct && !row.hasLinkedContract) ? ONB_RISK_WARNING_MSG : '',
                connectLabel: this.getLinesButtonLabel(row.linesCount)
            }));
        } else if (result.error) {
            this.fundsRowsForTable = [];
            console.error('Error loading funds for risk table:', result.error);
        }
    }

    get showRiskLinesComponent() {
        return !this.isInvestmentManagerOrHedgeFund;
    }

    get showFundsRiskTable() {
        return this.isInvestmentManagerOrHedgeFund;
    }

    get noFundsMessage() {
        return 'No funds added in FUNDS step.';
    }

    get showFundsRiskToolbarWarning() {
        return this.showFundsRiskTable && (this.fundsRowsForTable || []).some(
            (row) => row.hasLinkedContract === false && row.hasLinkedProduct === false
        );
    }

    getLinesButtonLabel(linesCount) {
        const count = Number(linesCount) || 0;
        return count > 0 ? `Lines (${count})` : 'Lines';
    }

    rowReadOnlyWhen = () => true;

    async handleFundLinesRow(event) {
        const fundId = event.detail?.row?.Id;

        if (!fundId) {
            return;
        }

        await onb_assignRiskLinesModal.open({
            size: 'medium',
            header: 'Assigned lines',
            fundId: fundId,
            recordOnboardingId: this.recordId
        });

        // Refresh funds data with new cache buster
        this.fundsCacheBuster = String(Date.now());
        if (this.wiredFundsResult) {
            await refreshApex(this.wiredFundsResult);
        }
    }

    handleContactFieldChange(event) {
        const { fieldApiName, value } = event.detail || {};
        if (fieldApiName) {
            this.contactValues[fieldApiName] = value;
        }
    }

    @api
    async validate() {
        const isUpdate = !!this.externalContactId;

        let datosEnPantalla = {};
        this.template.querySelectorAll('c-onb_onboarding-form').forEach(form => {
            if (typeof form.getValues === 'function') {
                datosEnPantalla = { ...datosEnPantalla, ...form.getValues() };
            }
        });

        const todosVacios = Object.values(datosEnPantalla).every(val => val === null || val === undefined || String(val).trim() === '');
        const nameVacio = !datosEnPantalla.Name || String(datosEnPantalla.Name).trim() === '';

        // Si el contacto existe en BD y ahora en pantalla TODO está vacío: lo borramos
        if (isUpdate && todosVacios) {
            await deleteExternalContact(this, this.externalContactId);
            this.externalContactId = null;
            this.contactValues = {};
            return true;
        }

        if (!todosVacios && nameVacio) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Name Required',
                    message: 'You must provide a Name to save the contact information.',
                    variant: 'error'
                })
            );
            return false;
        }

        // Si hay nombre y hay cambios pendientes (ya sea creación o edición), los procesamos
        if (!nameVacio && Object.keys(this.contactValues).length > 0) {
            this.contactValues.OnboardingId__c = this.recordId; // Asociamos el contacto al onboarding
            this.contactValues.Type__c = RISK_CLIENT_CONTACT_TYPE;

            const result = await processAndCreateExternalContact(this, this.contactValues, this.externalContactId);
            if (result.success) {
                this.externalContactId = result.contactId; // Guardamos el ID por si se queda en la pantalla
                this.contactValues = {}; // Vaciamos los cambios
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Contact created successfully',
                        variant: 'success'
                    })
                );
            }
            return result.success;
        }
        return true;
    }
}