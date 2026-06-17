import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { processAndCreateExternalContact, extractContactIdByType } from 'c/onb_contactUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAllowedContractsForOnboarding from '@salesforce/apex/ONB_MasterAgreementsController.getAllowedContractsForOnboarding';
// ----------------------
// Apex classes
// ----------------------
import getContractItems from '@salesforce/apex/ONB_MasterAgreementsController.getContractItems';
import getInternalNotificationUserIds from '@salesforce/apex/ONB_MasterAgreementsController.getInternalNotificationUserIds';
import addInternalNotificationUser from '@salesforce/apex/ONB_MasterAgreementsController.addInternalNotificationUser';
import removeInternalNotificationUser from '@salesforce/apex/ONB_MasterAgreementsController.removeInternalNotificationUser';
import removeOnboardingContractJunction from '@salesforce/apex/ONB_MasterAgreementsController.removeOnboardingContractJunction';
import getExternalContact from '@salesforce/apex/ONB_RelationshipContactsController.getExternalContactsByOnboarding';

// ----------------------
// LWC
// ----------------------
import onb_selectExistingContract from 'c/onb_selectExistingContract';
import onb_assignFundsToContract from 'c/onb_assignFundsToContract';

// ----------------------
// Card titles (labels)
// ----------------------
import ONB_LEGAL_CLIENT_CONTACT from '@salesforce/label/c.ONB_LEGAL_CLIENT_CONTACT';
import ONB_MASTER_AGREEMENTS_CARD from '@salesforce/label/c.ONB_MASTER_AGREEMENTS_CARD';
import ONB_INTERNAL_NOTIFICATION from '@salesforce/label/c.ONB_INTERNAL_NOTIFICATION';
import ONB_ADDITIONAL_COMMENTS from '@salesforce/label/c.ONB_ADDITIONAL_COMMENTS';

// ----------------------
// Field labels (custom labels)
// ----------------------
// Legal client contact
import ONB_LEGAL_CLIENT_NAME from '@salesforce/label/c.ONB_LEGAL_CLIENT_NAME';
import ONB_LEGAL_CLIENT_EMAIL from '@salesforce/label/c.ONB_LEGAL_CLIENT_EMAIL';
import ONB_LEGAL_CLIENT_ADDRESS from '@salesforce/label/c.ONB_LEGAL_CLIENT_ADDRESS';

// Master agreements
import ONB_EMPTY_STATE_CONTRACT_MSSG from '@salesforce/label/c.ONB_EMPTY_STATE_CONTRACT_MSSG';
import ONB_CONTRACT_STATE from '@salesforce/label/c.ONB_CONTRACT_STATE';
import ONB_CONTRACT_TYPE from '@salesforce/label/c.ONB_CONTRACT_TYPE';
import ONB_GEOGRAPHY from '@salesforce/label/c.ONB_GEOGRAPHY';
import ONB_CONTRACT_DIGITAL_SIGNATURE from '@salesforce/label/c.ONB_CONTRACT_DIGITAL_SIGNATURE';
import ONB_CONTRACT_WHO_PROVIDES from '@salesforce/label/c.ONB_CONTRACT_WHO_PROVIDES';
import ONB_CONTRACT_COLLATERAL_ANNEX from '@salesforce/label/c.ONB_CONTRACT_COLLATERAL_ANNEX';
import ONB_ASSETS from '@salesforce/label/c.ONB_ASSETS';
import ONB_MONITORIZATION_REQUIRED from '@salesforce/label/c.ONB_MONITORIZATION_REQUIRED';
import ONB_CONTRACT_ASSOCIATED from '@salesforce/label/c.ONB_CONTRACT_ASSOCIATED';
import ONB_ADD_NEW_CONTRACT from '@salesforce/label/c.ONB_ADD_NEW_CONTRACT';
import ONB_ADD_EXISTING_CONTRACT from '@salesforce/label/c.ONB_ADD_EXISTING_CONTRACT';
import ONB_CONNECTED_FUNDS from '@salesforce/label/c.ONB_CONNECTED_FUNDS';
import ONB_ENTRY_PHASE from '@salesforce/label/c.ONB_ENTRY_PHASE';
import ONB_COUNTERPARTY_CUSTODIANS from '@salesforce/label/c.ONB_COUNTERPARTY_CUSTODIANS';
import ONB_NAME_CUSTODIANS from '@salesforce/label/c.ONB_NAME_CUSTODIANS';
import ONB_RECONCILIATION_SYSTEM from '@salesforce/label/c.ONB_RECONCILIATION_SYSTEM';
import ONB_NAME_RECONCILIATION_SYTEM from '@salesforce/label/c.ONB_NAME_RECONCILIATION_SYTEM';
import ONB_NAME_COUNTERPARTY_ACAIDA from '@salesforce/label/c.ONB_NAME_COUNTERPARTY_ACAIDA';
import ONB_MARGIN_AUTOMATIZED from '@salesforce/label/c.ONB_MARGIN_AUTOMATIZED';
import ONB_NAME_MARGIN from '@salesforce/label/c.ONB_NAME_MARGIN';
import ONB_BBVA_CUSTODIAN from '@salesforce/label/c.ONB_BBVA_CUSTODIAN';

// Internal notification
import ONB_INTERNAL_NOTIFICATION_INCLUDE_USERS from '@salesforce/label/c.ONB_INTERNAL_NOTIFICATION_INCLUDE_USERS';

// Additional comments
import ONB_ADDITIONAL_COMMENTS_EXTRA_INFORMATION from '@salesforce/label/c.ONB_ADDITIONAL_COMMENTS_EXTRA_INFORMATION';
import ONB_ADDITIONAL_COMMENTS_ANY_INFORMATION from '@salesforce/label/c.ONB_ADDITIONAL_COMMENTS_ANY_INFORMATION';

const ONBOARDING_OBJECT_API_NAME = 'ONB_Onboarding__c';
const CONTACT_OBJECT_API_NAME = 'ONB_External_Contact__c';
const LEGAL_CLIENT_CONTACT_TYPE = 'LEGAL_CLIENT_CONTACT';
const ONBOARDING_CONTRACT_OBJECT_API_NAME = 'Contrato_Marco__c';
const ONBOARDING_ID_API_NAME = 'OnboardingId__c';
const ANNEX_VALUE_CSA_VM = 'CSA VM';
const ANNEX_VALUE_IM = 'IM';

const FIELD_MON = 'ONB_IM_monitorization_required__c';
const FIELD_ASSOC = 'ONB_Is_the_contract_associated__c';

const FIELD_ENTRY_PHASE = 'ONB_Entry_phase__c';
const FIELD_COUNTERPARTY_CUSTODIANS = 'ONB_Counterpartys_custodians__c';
const FIELD_NAME_CUSTODIAN = 'ONB_Name_custodian__c';
const FIELD_RECONCILIATION_SYSTEM = 'ONB_Reconciliation_system__c';
const FIELD_NAME_RECON_SYSTEM = 'ONB_Name_of_the_Reconciliation_System__c';
const FIELD_NAME_COUNTERPARTY_ACADIA = 'ONB_Name_of_Counterparty_in_Acadia__c';
const FIELD_MARGIN_AUTOMATIZED = 'ONB_Margin_call_automatized__c';
const FIELD_NAME_MARGIN = 'ONB_Name_margin_call__c';
const FIELD_BBVA_CUSTODIAN = 'ONB_BBVAs_Custodian__c';

const CUSTODIAN_OTHER = 'OTHER';
const RECON_ACADIA = 'ACADIA';
const RECON_OTHER = 'OTHER';
const MARGIN_OTHER = 'OTHER';

// ----------------------
// Helpers
// ----------------------
const mapFromPairs = (pairs) => Object.freeze(Object.fromEntries(pairs));
const freezeList = (list) => Object.freeze([...list]);

// ----------------------
// Sections (fields + labels)
// ----------------------
const SECTIONS = Object.freeze({
    legalClientContactLeft: {
        fields: freezeList(['Name', 'Email__c']),
        labels: mapFromPairs([
            ['Name', ONB_LEGAL_CLIENT_NAME],
            ['Email__c', ONB_LEGAL_CLIENT_EMAIL]
        ])
    },

    legalClientContactRight: {
        fields: freezeList(['Address__c']),
        labels: mapFromPairs([
            ['Address__c', ONB_LEGAL_CLIENT_ADDRESS]
        ])
    },

    additionalComments: {
        fields: freezeList(['ONB_Additional_Comments__c']),
        labels: mapFromPairs([
            ['ONB_Additional_Comments__c', ONB_ADDITIONAL_COMMENTS_EXTRA_INFORMATION]
        ])
    }
});

// ----------------------
// Rules placeholders per section
// Fill these with your required/disabled/readonly/visibility logic
// ----------------------
const RULES = Object.freeze({
    legalClientContactLeft: Object.freeze({}),
    legalClientContactRight: Object.freeze({}),
    additionalComments: Object.freeze({})
});

const CONTRACT_ASSOCIATED_TYPES = new Set(['ISDA', 'CMOF', 'FBF', 'DRV']);
export default class Onb_contractState extends LightningElement {
    @api recordId;

    rows = [];
    internalNotificationUserIds = [];
    allowedContractOptions = [];
    contractTypeOptionsByRowId = {};
    _boundProductsChangedHandler;

    contactValues = {};
    externalContactId;
    nonce = String(Date.now());

    objContactApiName = CONTACT_OBJECT_API_NAME;
    onboardingObjApiName = ONBOARDING_OBJECT_API_NAME;
    onboardingContractObjApiName = ONBOARDING_CONTRACT_OBJECT_API_NAME;
    parentFieldApiName = ONBOARDING_ID_API_NAME;

    rowReadOnlyWhen = (row) => row?.ONB_Origin__c === 'Existing';

    sections = SECTIONS;
    rules = RULES;

    conditionalRequiredRules = [
        {
            when: (row) => this.hasImAnnex(row),
            requiredFields: [
                FIELD_ENTRY_PHASE,
                FIELD_COUNTERPARTY_CUSTODIANS,
                FIELD_BBVA_CUSTODIAN
            ]
        },
        {
            when: (row) =>
                this.hasImAnnex(row) &&
                row?.[FIELD_COUNTERPARTY_CUSTODIANS] === CUSTODIAN_OTHER,
            requiredFields: [FIELD_NAME_CUSTODIAN]
        },
        {
            when: (row) =>
                this.hasImAnnex(row) &&
                row?.[FIELD_RECONCILIATION_SYSTEM] === RECON_OTHER,
            requiredFields: [FIELD_NAME_RECON_SYSTEM]
        },
        {
            when: (row) =>
                this.hasImAnnex(row) &&
                row?.[FIELD_RECONCILIATION_SYSTEM] === RECON_ACADIA,
            requiredFields: [FIELD_NAME_COUNTERPARTY_ACADIA]
        },
        {
            when: (row) =>
                this.hasImAnnex(row) &&
                row?.[FIELD_MARGIN_AUTOMATIZED] === MARGIN_OTHER,
            requiredFields: [FIELD_NAME_MARGIN]
        }
    ];

    cellDisabledWhen = (row, col) => {
        const fieldName = col?.fieldName;
        const type = row?.master_agreement_type__c;
        const hasCsaVmInAnnex = this.hasAnnexValue(row, ANNEX_VALUE_CSA_VM);
        const hasImAnnex = this.hasImAnnex(row);

        const custodianValue = row?.[FIELD_COUNTERPARTY_CUSTODIANS];
        const reconciliationValue = row?.[FIELD_RECONCILIATION_SYSTEM];
        const marginValue = row?.[FIELD_MARGIN_AUTOMATIZED];

        if (fieldName === FIELD_MON) {
            return !hasCsaVmInAnnex;
        }

        if (fieldName === FIELD_ASSOC) {
            return !CONTRACT_ASSOCIATED_TYPES.has(type);
        }

        const imFields = new Set([
            FIELD_ENTRY_PHASE,
            FIELD_COUNTERPARTY_CUSTODIANS,
            FIELD_NAME_CUSTODIAN,
            FIELD_RECONCILIATION_SYSTEM,
            FIELD_NAME_RECON_SYSTEM,
            FIELD_NAME_COUNTERPARTY_ACADIA,
            FIELD_MARGIN_AUTOMATIZED,
            FIELD_NAME_MARGIN,
            FIELD_BBVA_CUSTODIAN
        ]);

        if (imFields.has(fieldName) && !hasImAnnex) {
            return true;
        }

        if (fieldName === FIELD_NAME_CUSTODIAN) {
            return !hasImAnnex || custodianValue !== CUSTODIAN_OTHER;
        }

        if (fieldName === FIELD_NAME_RECON_SYSTEM) {
            return !hasImAnnex || reconciliationValue !== RECON_OTHER;
        }

        if (fieldName === FIELD_NAME_COUNTERPARTY_ACADIA) {
            return !hasImAnnex || reconciliationValue !== RECON_ACADIA;
        }

        if (fieldName === FIELD_NAME_MARGIN) {
            return !hasImAnnex || marginValue !== MARGIN_OTHER;
        }

        return false;
    };

    label = {
        ONB_LEGAL_CLIENT_CONTACT,
        ONB_MASTER_AGREEMENTS_CARD,
        ONB_INTERNAL_NOTIFICATION,
        ONB_INTERNAL_NOTIFICATION_INCLUDE_USERS,
        ONB_ADDITIONAL_COMMENTS,
        ONB_EMPTY_STATE_CONTRACT_MSSG,
        ONB_ADD_NEW_CONTRACT,
        ONB_ADD_EXISTING_CONTRACT
    };

    requiredFieldApiNames = ['master_agreement_type__c', 'ONB_Geography__c', 'ONB_Who_provides__c', 'ONB_Annex__c', 'ONB_Assets__c'];

    columns = [
        //{ key: 'contractState', label: ONB_CONTRACT_STATE, fieldName: '', type: 'text' },
        { key: 'contract', label: 'Contract', fieldName: 'ONB_Origin__c', type: 'badge' },
        { key: 'contractType', label: ONB_CONTRACT_TYPE, fieldName: 'master_agreement_type__c', type: 'dependentPicklist', controllerFieldName: 'ONB_Origin__c', optionsKey: 'contractTypeOptions' },
        { key: 'geography', label: ONB_GEOGRAPHY, fieldName: 'ONB_Geography__c', type: 'picklist'},
        { key: 'digitalSignature', label: ONB_CONTRACT_DIGITAL_SIGNATURE, fieldName: 'ONB_Digital_signature__c', type: 'boolean', editable: true},
        { key: 'whoProvides', label: ONB_CONTRACT_WHO_PROVIDES, fieldName: 'ONB_Who_provides__c', type: 'picklist' },
        { key: 'collateralAnnex', label: ONB_CONTRACT_COLLATERAL_ANNEX, fieldName: 'ONB_Annex__c', type: 'multipicklist', controllerFieldName: 'master_agreement_type__c'},
        { key: 'assets', label: ONB_ASSETS, fieldName: 'ONB_Assets__c', type: 'dependentPicklist', controllerFieldName: 'master_agreement_type__c' },
        { key: 'monitorizationRequired', label: ONB_MONITORIZATION_REQUIRED, fieldName: 'ONB_IM_monitorization_required__c', type: 'picklist' },
        { key: 'contractAssociated', label: ONB_CONTRACT_ASSOCIATED, fieldName: 'ONB_Is_the_contract_associated__c', type: 'picklist' },
        { key: 'entryPhase', label: ONB_ENTRY_PHASE, fieldName: 'ONB_Entry_phase__c', type: 'date' },
        { key: 'counterpartiesCustodians', label: ONB_COUNTERPARTY_CUSTODIANS, fieldName: 'ONB_Counterpartys_custodians__c', type: 'picklist' },
        { key: 'nameCustodian', label: ONB_NAME_CUSTODIANS, fieldName: 'ONB_Name_custodian__c', type: 'text' },
        { key: 'reconciliationSystem', label: ONB_RECONCILIATION_SYSTEM, fieldName: 'ONB_Reconciliation_system__c', type: 'picklist' },
        { key: 'nameReconciliationSystem', label: ONB_NAME_RECONCILIATION_SYTEM, fieldName: 'ONB_Name_of_the_Reconciliation_System__c', type: 'text' },
        { key: 'nameCounterpartyAcadia', label: ONB_NAME_COUNTERPARTY_ACAIDA, fieldName: 'ONB_Name_of_Counterparty_in_Acadia__c', type: 'text' },
        { key: 'marginAutomatizated', label: ONB_MARGIN_AUTOMATIZED, fieldName: 'ONB_Margin_call_automatized__c', type: 'picklist' },
        { key: 'nameMargin', label: ONB_NAME_MARGIN, fieldName: 'ONB_Name_margin_call__c', type: 'text' },
        { key: 'bbvaCustodian', label: ONB_BBVA_CUSTODIAN, fieldName: 'ONB_BBVAs_Custodian__c', type: 'text' }
    ];

    @wire(getContractItems, { onboardingId: '$recordId', cacheBuster: String(Date.now()) })
    wiredFundItems(result) {
        this.wiredResult = result;
        if (result.data) {
        this.rows = result.data;
        this.buildOptionsMap();
        } else if (result.error) {
        console.error(JSON.stringify(result.error));
        this.rows = [];
        }
    }

    @wire(getInternalNotificationUserIds, { onboardingId: '$recordId' })
    wiredInternalNotif(result) {
        this.wiredInternalNotifResult = result;
        if (result.data) {
            this.internalNotificationUserIds = Array.isArray(result.data) ? result.data : [];
        } else if (result.error) {
            console.error(JSON.stringify(result.error));
            this.internalNotificationUserIds = [];
        }
    }

    connectedCallback() {
        this._boundProductsChangedHandler = this.handleProductsChanged.bind(this);
        window.addEventListener('onbproductschanged', this._boundProductsChangedHandler);
        this.loadAllowedContracts();
    }

    disconnectedCallback() {
        if (this._boundProductsChangedHandler) {
            window.removeEventListener('onbproductschanged', this._boundProductsChangedHandler);
        }
    }

    async handleProductsChanged(event) {
        const changedRecordId = event?.detail?.recordId;
        if (!changedRecordId || changedRecordId !== this.recordId) return;
        await this.loadAllowedContracts();
    }

    async loadAllowedContracts() {
        if (!this.recordId) return;
        try {
            const data = await getAllowedContractsForOnboarding({ onboardingId: this.recordId });
            this.allowedContractOptions = (data || []).map(contract => ({ label: contract, value: contract }));
            this.buildOptionsMap();
            this.updateContractTypeColumn();
        } catch (e) {
            console.error('Error fetching allowed contracts', e);
        }
    }

    async handleAddExistingContract() {
        const res = await onb_selectExistingContract.open({
            size: 'medium',
            header: ONB_ADD_EXISTING_CONTRACT,
            recordOnboardingId: this.recordId
        });

        if (res?.action === 'added') {
            await refreshApex(this.wiredResult);
            await this.loadAllowedContracts();
            this.notifyContractsChanged();
        }
    }

    async handleInternalNotifAdd(event) {
        const userId = event?.detail?.userId;
        if (!this.recordId || !userId) return;

        if (this.internalNotificationUserIds.includes(userId)) return;

        try {
            await addInternalNotificationUser({
                onboardingId: this.recordId,
                userId
            });

            await refreshApex(this.wiredInternalNotifResult);

        } catch (e) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error adding user',
                    message: e?.body?.message || e?.message || 'Unknown error',
                    variant: 'error'
                })
            );
        }
    }

    async handleInternalNotifRemove(event) {
        const userId = event?.detail?.userId;
        if (!this.recordId || !userId) return;

        try {
            await removeInternalNotificationUser({
                onboardingId: this.recordId,
                userId
            });

            await refreshApex(this.wiredInternalNotifResult);

        } catch (e) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error removing user',
                    message: e?.body?.message || e?.message || 'Unknown error',
                    variant: 'error'
                })
            );
        }
    }

    async handleRowUnlink(event) {
        const contractId = event.detail?.id || event.detail?.row?.Id;
        if (!contractId) return;

        try {
            await removeOnboardingContractJunction({
                onboardingId: this.recordId,
                contractId
            });
            await refreshApex(this.wiredResult);
            this.notifyContractsChanged();
        } catch (e) {
            console.error('Error deleting junction', e);
        }
    }

    async handleConnectRow(event){
        const { row } = event.detail;
        const contractId = row?.Id;

        if (!contractId) {return;}

        const result = await onb_assignFundsToContract.open({
            size: 'medium',
            header: ONB_CONNECTED_FUNDS,
            recordOnboardingId: this.recordId,
            contractId: contractId
        });

        if (result?.action === 'added') {
            await this.handleRowChange();
        }
    }

    async handleRowChange() {
        await refreshApex(this.wiredResult);
        this.notifyContractsChanged();
    }

    notifyContractsChanged() {
        window.dispatchEvent(new CustomEvent('onbcontractschange', {
            detail: { recordId: this.recordId }
        }));
    }

    @wire(getExternalContact, { onboardingId: '$recordId', nonce: '$nonce' })
    wiredRelationships({ data }) {
            this.externalContactId = extractContactIdByType(data, LEGAL_CLIENT_CONTACT_TYPE) || this.externalContactId;
    }

    handleContactFieldChange(event) {
        const { fieldApiName, value } = event.detail || {};
        if (fieldApiName) {
            this.contactValues[fieldApiName] = value;
        }
    }

    @api
    async validate() {
        let ok = true;

        this.template.querySelectorAll('c-onb_onboarding-form').forEach((cmp) => {
            if (cmp?.validate && !cmp.validate()) ok = false;
        });

        this.template.querySelectorAll('c-onb_onboarding-table').forEach((cmp) => {
            if (cmp?.validate && !cmp.validate()) ok = false;
        });

        if(ok){
            if (Object.keys(this.contactValues).length === 0) return true; // Si no hay cambios, no hace falta actualizar
            this.contactValues.OnboardingId__c = this.recordId; // Asociamos el contacto al onboarding
            this.contactValues.Type__c = LEGAL_CLIENT_CONTACT_TYPE;

            const result = await processAndCreateExternalContact(this, this.contactValues, this.externalContactId);
            if (result.success) {
                this.externalContactId = result.contactId;
                this.contactValues = {}; // Vaciamos los cambios
            }
            ok = result.success;
        }

        return ok;
    }

    getAnnexValues(row) {
        return (row?.ONB_Annex__c || '')
            .split(';')
            .map(v => v.trim())
            .filter(Boolean);
    }

    hasAnnexValue(row, annexValue) {
        return this.getAnnexValues(row).includes(annexValue);
    }

    hasImAnnex(row) {
        return this.hasAnnexValue(row, ANNEX_VALUE_IM);
    }

    get shouldAllowAddNewContract() {
        return this.allowedContractOptions && this.allowedContractOptions.length > 0;
    }

    updateContractTypeColumn() {
        this.columns = this.columns.map(col => {
            if (col.key === 'contractType') {
                return { ...col, options: this.allowedContractOptions };
            }
            return col;
        });
    }

    buildOptionsMap() {
        if (!this.rows || this.rows.length === 0 || !this.allowedContractOptions) return;

        const optionsMap = {};
        this.rows.forEach((row, index) => {
            const key = row.Id || row._key || `idx-${index}`;
            if (this.allowedContractOptions.length > 0) {
                optionsMap[key] = this.allowedContractOptions;
            } else {
                const currentValue = row.master_agreement_type__c;
                optionsMap[key] = currentValue
                    ? [{ label: currentValue, value: currentValue }]
                    : [];
            }
        });

        this.contractTypeOptionsByRowId = { ...optionsMap };
    }
}