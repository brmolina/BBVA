import { LightningElement, api, wire } from 'lwc';
import getLinesByOnboardingId from '@salesforce/apex/ONB_LinesController.getLinesByOnboardingId';
import hasRepoProduct from '@salesforce/apex/ONB_LinesController.hasRepoProduct';
import getContractLineCategoryStatus from '@salesforce/apex/ONB_MasterAgreementsController.getContractLineCategoryStatus';
import { getRecord } from 'lightning/uiRecordApi';

// ----------------------
// SETTLEMENT LINES
// ----------------------
import ONB_SETTLEMENT_LINE_TYPE from '@salesforce/label/c.ONB_SETT_LINE_TYPE';
import ONB_SETTLEMENT_LINE_LIMIT from '@salesforce/label/c.ONB_SETT_LINE_LIMIT';
import ONB_SETTLEMENT_LINE_CURRENCY from '@salesforce/label/c.ONB_SETT_LINE_CURRENCY';
import ONB_SETTLEMENT_IS_AUTOMATIC from '@salesforce/label/c.ONB_SETT_IS_AUTOMATIC';

// ----------------------
// CREDIT LINES
// ----------------------
import ONB_CREDIT_LINE_LIMIT from '@salesforce/label/c.ONB_CREDIT_LIMIT';
import ONB_CREDIT_LINE_CURRENCY from '@salesforce/label/c.ONB_CREDIT_LINE_CURRENCY';
import ONB_MATURITY_REPO from '@salesforce/label/c.ONB_MATURITY_REPO';
import ONB_MATURITY_DERIVATIVES from '@salesforce/label/c.ONB_MATURITY_DERIVATIVES';
import ONB_MATURITY_SECURITY_LENDING from '@salesforce/label/c.ONB_MATURITY_SECURITY_LENDING';

// ----------------------
// GROSS LIMIT (REPOS)
// ----------------------
import ONB_GROSS_TYPE from '@salesforce/label/c.ONB_GROSS_TYPE';
import ONB_GROSS_LIMIT from '@salesforce/label/c.ONB_GROSS_LIMIT';
import ONB_GROSS_CURRENCY from '@salesforce/label/c.ONB_GROSS_CURRENCY';
import ONB_GROSS_MATURITY from '@salesforce/label/c.ONB_GROSS_MATURITY';

// ----------------------
// BUTTONS
// ----------------------
import ONB_CREDIT_LINES from '@salesforce/label/c.ONB_CREDIT_LINES';
import ONB_SETTLEMENT_LINES from '@salesforce/label/c.ONB_SETTLEMENT_LINES';
import ONB_BTN_ADD_SETTLEMENT_LINE from '@salesforce/label/c.ONB_BTN_ADD_SETTLEMENT_LINE';
import ONB_BTN_ADD_GROSS_LIMIT from '@salesforce/label/c.ONB_BTN_ADD_GROSS_LIMIT';
import ONB_BTN_ADD_CREDIT_LINE from '@salesforce/label/c.ONB_BTN_ADD_CREDIT_LINE';

// ----------------------
// Constants
// ----------------------
const LINES_OBJ_API_NAME = 'ONB_Line__c';
const ONBOARDING_ID_API_NAME = 'OnboardingId__c';
const GROSS_TYPE_TOOLTIP = 'Only one record per Gross Type is allowed: one Flow and one No Flow.';

// Line types
const LINE_TYPE_DVP = 'LC_DVP';
const LINE_TYPE_CRED = 'LC_CRED';
const LINE_TYPE_REPOS = 'LC_REPOS';

export default class Onb_riskLines extends LightningElement {
    @api recordId;
    @api fundId;
    @api forceShowRiskTables = false;
    _pendingCreditMaturityNormalization = false;

    // Data arrays
    settlementsRows = [];
    creditRows = [];
    reposRows = [];

    // Visibility flags
    showRiskTables = true;
    showSettlementLines = true;
    showCreditLines = false;
    showReposLines = false;

    // Add button states
    showSettlementAdd = true;
    disableSettlementAdd = false;
    showCreditAdd = true;
    showReposAdd = true;
    disableReposAdd = false;

    // Logic flags
    hasRepoProductLine = false;
    hasAssociatedContracts = false;
    hasRepoContracts = false;
    hasDerivativesContracts = false;
    hasSecurityLendingContracts = false;
    isRiskEntityEligible = true;

    // Nonces for cache busting
    nonce = String(Date.now());
    repoNonce = String(Date.now());
    _contractNonce = String(Date.now());

    // API Names
    parentFieldApiName = ONBOARDING_ID_API_NAME;
    objectApiName = LINES_OBJ_API_NAME;

    // Line types
    lineTypeDvp = LINE_TYPE_DVP;
    lineTypeCred = LINE_TYPE_CRED;
    lineTypeRepos = LINE_TYPE_REPOS;

    // Labels
    label = {
        ONB_SETTLEMENT_LINES,
        ONB_CREDIT_LINES,
        ONB_BTN_ADD_SETTLEMENT_LINE,
        ONB_BTN_ADD_GROSS_LIMIT,
        ONB_BTN_ADD_CREDIT_LINE,
        ONB_GROSS_LIMIT
    };

    // Settlement Line Columns
    columnsSettlements = [
        { key: 'SettlementLineType', label: ONB_SETTLEMENT_LINE_TYPE, fieldName: 'ONB_Line_Subtype__c', type: 'dependentPicklist', controllerFieldName: 'Line_Type__c' },
        { key: 'SettlementLineLimit', label: ONB_SETTLEMENT_LINE_LIMIT, fieldName: 'ONB_Settlement_line_limit__c', type: 'input' },
        { key: 'SettlementLineCurrency', label: ONB_SETTLEMENT_LINE_CURRENCY, fieldName: 'CurrencyIsoCode', type: 'picklist' },
        { key: 'Automatic', label: ONB_SETTLEMENT_IS_AUTOMATIC, fieldName: 'IsAutomatic__c', type: 'toggle' }
    ];

    // Credit Line Columns
    columnsCredit = [
        { key: 'CreditLineLimit', label: ONB_CREDIT_LINE_LIMIT, fieldName: 'ONB_Credit_line_limit__c', type: 'input' },
        { key: 'CreditLineCurrency', label: ONB_CREDIT_LINE_CURRENCY, fieldName: 'CurrencyIsoCode', type: 'picklist' },
        { key: 'CreditLineMaturityRepo', label: ONB_MATURITY_REPO, fieldName: 'Maturity_Repo__c', type: 'picklist' },
        { key: 'CreditLineMaturityDerivatives', label: ONB_MATURITY_DERIVATIVES, fieldName: 'Maturity_Derivatives__c', type: 'picklist' },
        { key: 'CreditLineMaturitySecurityLending', label: ONB_MATURITY_SECURITY_LENDING, fieldName: 'Maturity_Security_lending__c', type: 'picklist' }
    ];

    // Repos/Gross Limit Columns
    columnsRepos = [
        { key: 'GrossType', label: ONB_GROSS_TYPE, helpText: GROSS_TYPE_TOOLTIP, fieldName: 'ONB_Line_Subtype__c', type: 'dependentPicklist', controllerFieldName: 'Line_Type__c' },
        { key: 'GrossLimit', label: ONB_GROSS_LIMIT, fieldName: 'ONB_Repos_line_limit__c', type: 'input' },
        { key: 'GrossCurrency', label: ONB_GROSS_CURRENCY, fieldName: 'CurrencyIsoCode', type: 'picklist' },
        { key: 'GrossMaturity', label: ONB_GROSS_MATURITY, fieldName: 'ONB_Maturity__c', type: 'dependentPicklist', controllerFieldName: 'ONB_Line_Subtype__c' }
    ];

    get defaultValuesForTables() {
        if (this.fundId) {
            return { FundItemId__c: this.fundId };
        }
        return {};
    }

    connectedCallback() {
        // Event listener for contract changes
        this._boundContractsChangedHandler = this.handleContractsChanged.bind(this);
        window.addEventListener('onbcontractschange', this._boundContractsChangedHandler);
    }

    disconnectedCallback() {
        if (this._boundContractsChangedHandler) {
            window.removeEventListener('onbcontractschange', this._boundContractsChangedHandler);
        }
    }

    // =====================================================
    // WIRE METHODS
    // =====================================================

    @wire(getRecord, { recordId: '$recordId', fields: ['ONB_Onboarding__c.Client__c', 'ONB_Onboarding__c.Legal_Entity_Type__c'] })
    wiredOnboarding({ data, error }) {
        if (data) {
            const legalEntityType = data.fields.Legal_Entity_Type__c?.value;

            // Default behavior hides risk tables for these entity types, but modal can force visibility.
            this.isRiskEntityEligible = this.forceShowRiskTables || (legalEntityType !== 'Investment Manager' && legalEntityType !== 'Hedge Fund');
            this.updateRiskTablesVisibility();
        } else if (error) {
            console.error('Error loading onboarding:', error);
        }
    }

    @wire(getContractLineCategoryStatus, { onboardingId: '$recordId', cacheBuster: '$_contractNonce' })
    wiredContractCategoryStatus({ data, error }) {
        if (data) {
            this.hasAssociatedContracts = !!data.hasAssociatedContracts;
            this.hasRepoContracts = !!data.hasReposContracts;
            this.hasDerivativesContracts = !!data.hasDerivativesContracts;
            this.hasSecurityLendingContracts = !!data.hasSecurityLendingContracts;
            this.updateCreditLinesVisibility();
            this.updateReposLineVisibility();
            this.updateAddButtonState();
            this.normalizeDisabledCreditMaturityValues();
        } else if (error) {
            console.error('Error loading contract line category status:', error);
        }
    }

    @wire(hasRepoProduct, { onboardingId: '$recordId', nonce: '$repoNonce' })
    wiredRepoProduct({ data, error }) {
        if (data !== undefined) {
            this.hasRepoProductLine = data;
            this.updateReposLineVisibility();
        } else if (error) {
            console.error('Error checking repo product:', error);
        }
    }

    @wire(getLinesByOnboardingId, { onboardingId: '$recordId', fundId: '$fundId', nonce: '$nonce' })
    wiredLines({ data, error }) {
        if (data) {
            // Filtrar y asignar filas por Line_Type__c
            console.log('Lines data:', data);

            this.settlementsRows = data.filter(line => line.Line_Type__c === LINE_TYPE_DVP);
            this.creditRows = data.filter(line => line.Line_Type__c === LINE_TYPE_CRED);
            this.reposRows = data.filter(line => line.Line_Type__c === LINE_TYPE_REPOS);
            this.updateAddButtonState();
            this.normalizeDisabledCreditMaturityValues();

            console.log('Settlements Rows:', JSON.stringify(this.settlementsRows));
            console.log('Credit Rows:', JSON.stringify(this.creditRows));
            console.log('Repos Rows:', JSON.stringify(this.reposRows));
        } else if (error) {
            console.error('Error loading lines:', error);
        }
    }

    renderedCallback() {
        if (this._pendingCreditMaturityNormalization) {
            this.normalizeDisabledCreditMaturityValues();
        }
    }

    // =====================================================
    // EVENT HANDLERS
    // =====================================================

    handleRowDeleted(event) {
        console.log('Row deleted:', event.detail);
        this.nonce = String(Date.now());
        this.repoNonce = String(Date.now());
        this.updateAddButtonState();

        // DispatchEvent to notify parent components
        this.dispatchEvent(new CustomEvent('rowdeleted', { detail: event.detail, bubbles: true, composed: true }));
    }

    handleRowCreated(event) {
        console.log('Row created:', event.detail);
        this.nonce = String(Date.now());
        this.repoNonce = String(Date.now());
        this.updateAddButtonState();

        // DispatchEvent to notify parent components
        this.dispatchEvent(new CustomEvent('rowcreated', { detail: event.detail, bubbles: true, composed: true }));
    }

    handleContractsChanged(event) {
        const changedRecordId = event?.detail?.recordId;

        if (!changedRecordId || changedRecordId !== this.recordId) {
            return;
        }

        // Force re-evaluation of cacheable wire tied to contracts.
        this._contractNonce = String(Date.now());
    }

    // =====================================================
    // COMPUTED PROPERTIES & CELL DISABLERS
    // =====================================================

    // Función para deshabilitar el toggle Automatic si ONB_Line_Subtype__c no es "Free Delivery"
    settlementCellDisabledWhen = (row, col) => {
        if (col.fieldName === 'IsAutomatic__c') {
            const isNotFreeDelivery = row.ONB_Line_Subtype__c !== 'Free Delivery';
            if (isNotFreeDelivery) {
                row.IsAutomatic__c = false;
            }
            return isNotFreeDelivery;
        }
        return false;
    };

    creditCellDisabledWhen = (_row, col) => {
        if (col.fieldName === 'Maturity_Repo__c') {
            return !this.hasRepoContracts;
        }

        if (col.fieldName === 'Maturity_Derivatives__c') {
            return !this.hasDerivativesContracts;
        }

        if (col.fieldName === 'Maturity_Security_lending__c') {
            return !this.hasSecurityLendingContracts;
        }

        return false;
    };

    get conditionalRequiredRulesCredit() {
        return [
            {
                when: () => this.hasRepoContracts,
                requiredFields: ['Maturity_Repo__c']
            },
            {
                when: () => this.hasDerivativesContracts,
                requiredFields: ['Maturity_Derivatives__c']
            },
            {
                when: () => this.hasSecurityLendingContracts,
                requiredFields: ['Maturity_Security_lending__c']
            }
        ];
    }

    async normalizeDisabledCreditMaturityValues() {
        const rows = this.creditRows || [];
        if (!rows.length) {
            this._pendingCreditMaturityNormalization = false;
            return;
        }

        const fieldsToClearByIndex = [];
        rows.forEach((row, rowIndex) => {
            if (!this.hasRepoContracts && row?.Maturity_Repo__c) {
                fieldsToClearByIndex.push({ rowIndex, fieldName: 'Maturity_Repo__c' });
            }
            if (!this.hasDerivativesContracts && row?.Maturity_Derivatives__c) {
                fieldsToClearByIndex.push({ rowIndex, fieldName: 'Maturity_Derivatives__c' });
            }
            if (!this.hasSecurityLendingContracts && row?.Maturity_Security_lending__c) {
                fieldsToClearByIndex.push({ rowIndex, fieldName: 'Maturity_Security_lending__c' });
            }
        });

        if (!fieldsToClearByIndex.length) {
            this._pendingCreditMaturityNormalization = false;
            return;
        }

        const creditTable = this.template.querySelector('c-onb_onboarding-table[line-type="LC_CRED"]');
        if (!creditTable) {
            this._pendingCreditMaturityNormalization = true;
            return;
        }

        for (const item of fieldsToClearByIndex) {
            await creditTable.setCellValue(item.rowIndex, item.fieldName, null);
        }

        this._pendingCreditMaturityNormalization = false;
        this.nonce = String(Date.now());
    }

    // =====================================================
    // VISIBILITY UPDATE METHODS
    // =====================================================

    updateRiskTablesVisibility() {
        this.showRiskTables = this.isRiskEntityEligible;
        this.showSettlementLines = this.showRiskTables;
        this.updateCreditLinesVisibility();
        this.updateReposLineVisibility();
        this.updateAddButtonState();
    }

    updateCreditLinesVisibility() {
        this.showCreditLines = this.showRiskTables && this.hasAssociatedContracts;
    }

    updateReposLineVisibility() {
        // Repos only shows when risk is enabled and there is a REPOS contract category.
        if (this.showRiskTables) {
            this.showReposLines = this.hasRepoContracts;
        } else {
            this.showReposLines = false;
        }
    }

    updateAddButtonState() {
        this.showSettlementAdd = true;
        this.disableSettlementAdd = (this.settlementsRows || []).length >= 2;
        this.showCreditAdd = this.showCreditLines && (this.creditRows || []).length < 1;
        this.showReposAdd = this.showReposLines && this.hasRepoContracts;
        this.disableReposAdd = (this.reposRows || []).length >= 2;
    }

    // =====================================================
    // PUBLIC METHODS (for parent components)
    // =====================================================

    @api
    async validateLines() {
        // Placeholder para validación de líneas si es necesario
        return true;
    }
}