import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

import getData from '@salesforce/apex/DMT_RiskTablesLineController.getData';
import saveProducts from '@salesforce/apex/DMT_RiskTablesLineController.saveProducts';
import updateRiskLineTermAmount from '@salesforce/apex/DMT_RiskTablesLineController.updateRiskLineTermAmount';
//import refreshInformation from '@salesforce/apex/DMT_Passport_Handler.refreshInformation';

import TOTAL_AMOUNT_LABEL from '@salesforce/label/c.dmt_cl_TotalAmount';
import COUNTERPARTY_RISK_LABEL from '@salesforce/label/c.dmt_cl_CounterpartyRisk_Text';
import DERIVATIVES_MESSAGE_LABEL from '@salesforce/label/c.dmt_cl_DerivativesMessage_Text';
import DEPOS_LABEL from '@salesforce/label/c.dmt_cl_DeposRiskLine_Text';
import EQUITIES_LABEL from '@salesforce/label/c.dmt_cl_EquitiesWrong_Text';

import { formFields as FORM_FIELDS_CONFIG } from './dmtRiskTablesLine-fields';

import STATUS_FIELD from '@salesforce/schema/DMT_Line__c.Status__c';
import CURRENCY_FIELD from '@salesforce/schema/DMT_Line__c.CurrencyIsoCode';

const RECORD_FIELDS = [STATUS_FIELD, CURRENCY_FIELD];

/**
 * Single source of truth for which sections of the card each Booking_Geography__c sees.
 * `hiddenFor` wins over `visibleFor`; an empty/unknown key means "always visible".
 */
const GEOGRAPHY_VISIBILITY = {
    deposTable: { hiddenFor: ['CO', 'AR'] },
    equitiesTable: { hiddenFor: ['CO', 'PE', 'AR', 'MX'] },
    reposTable:  { visibleFor: ['MX'] },
    singularTreasury: { visibleFor: ['CO', 'AR'] },
    derivativesTable: { hiddenFor: [] },
    productRestrictions: { hiddenFor: ['MX'] },
    derivativesRestrictions: { visibleFor: ['MX'] }
};

// Fields that make a not-yet-persisted row worth saving.
const RISK_ROW_FIELDS = ['endTerm', 'amount'];
const SINGULAR_ROW_FIELDS = ['operationName', 'amount', 'dvpAmount', 'fdAmount', 'maxDate', 'endTerm'];

export default class DmtRiskTablesLine extends LightningElement {
    @api recordId;

    // ─── State ────────────────────────────────────────────────────────────────
    isLoading = true;
    editMode = false;
    showPopover = false;
    popoverMessage = '';
    isSaving = false;
    showRiskTables = true;
    tableRefreshCounter = 0;  // Counter to signal tables to refresh/reset

    // Data from server
    bookingGeography;
    currencyIsoCode;
    currency;
    conversionLabel;
    lineStatus;
    isReadOnlyUser = false;
    showSingular = false;

    // Form fields (cfRiskFormLine)
    dvpAmount;
    fdAmount;
    firstBreakclause;
    breakclauseFrequency;
    waiver = false;
    mitigantComments;
    firstBreakOptions = [];
    breakFrequencyOptions = [];
    currencyLabel;

    // Textarea fields (DMT_Additional_Restrictions__c, DMT_Comments__c)
    additionalRestrictions = '';
    comments = '';

    // Tables data (cfRiskTablesLine)
    derivatives;
    depos;
    equities;
    repos;
    derivativesTotalAmount;
    deposTotalAmount;
    equitiesTotalAmount;
    reposTotalAmount;
    defaultLimitDerivatives = 'false';
    defaultLimitDepos = 'false';
    defaultLimitEquities = 'false';
    defaultLimitRepos = 'false';
    tableRestric;
    tableReposProducts;
    tableDerivativesProducts;
    tableDeposProducts;
    mainBorrowerCountry = '';
    maxTenorOptions;
    fdAmountRestric;
    dvpAmountRestric;
    singularCon;
    columnsCopy;
    columnsCopyTransaction;
    restricCopy;
   

    // Wire reference
    wiredDataResult;
    wiredRecordResult;

    // ─── Wire: record change detection ───────────────────────────────────────
    @wire(getRecord, { recordId: '$recordId', fields: RECORD_FIELDS })
    wiredRecord(result) {
        this.wiredRecordResult = result;
        if (result.data) {
            const newStatus = getFieldValue(result.data, STATUS_FIELD);
            const statusChanged = this.lineStatus && this.lineStatus !== newStatus;
            this.lineStatus = newStatus;
            this.currencyIsoCode = getFieldValue(result.data, CURRENCY_FIELD);
            if (statusChanged && this.lineStatus !== 'Closed') {
                this._loadData().catch(error => {
                    console.error('Error reloading data after status change:', error);
                });
            }
        }
    }

    // ─── Lifecycle ────────────────────────────────────────────────────────────
    connectedCallback() {
        this._loadData().catch(error => {
            console.error('Error loading initial data:', error);
        });
    }

    // ─── Computed ─────────────────────────────────────────────────────────────

    /**
     * Generic geography-driven visibility check, exposed so it can be exercised from
     * a parent component or a Jest test with any GEOGRAPHY_VISIBILITY key.
     */
    @api
    isComponentVisible(componentKey) {
        const rule = GEOGRAPHY_VISIBILITY[componentKey];
        if (!rule) {
            return true;
        }
        const geography = (this.bookingGeography || '').trim().toUpperCase();
        if (Array.isArray(rule.visibleFor) && rule.visibleFor.length > 0) {
            return rule.visibleFor.includes(geography);
        }
        return !(rule.hiddenFor || []).includes(geography);
    }

    get showDeposTable() {
        return this.isComponentVisible('deposTable');
    }

    get showEquitiesTable() {
        return this.isComponentVisible('equitiesTable');
    }
    
    get showReposTable() {
        return this.isComponentVisible('reposTable');
    }

    get showProductRestrictions() {
        return this.isComponentVisible('productRestrictions');
    }

    get showDerivativesRestrictions() {
        return this.isComponentVisible('derivativesRestrictions');
    }

    get showSingularTreasury() {
        return this.showSingular && this.isComponentVisible('singularTreasury');
    }

    get totalAmountLabel() {
        return `${TOTAL_AMOUNT_LABEL} ${this.conversionLabel || ''}`;
    }

    get derivativesMessage() {
        return DERIVATIVES_MESSAGE_LABEL;
    }

    get isEditDisabled() {
        return this.isReadOnlyUser || this.lineStatus === 'Closed';
    }

    get isClosed() {
        return this.lineStatus === 'Closed';
    }

    // ─── Form Fields for dmt_form_renderer ────────────────────────────────────
    get formFields() {
        if (!this.currencyIsoCode) {
            return [];
        }

        const optionsMap = {
            'First_Breakclause__c': this.firstBreakOptions,
            'Breakclause_Frequency__c': this.breakFrequencyOptions
        };

        return FORM_FIELDS_CONFIG
            .filter(field => {
                if (field.hiddenGeographies && field.hiddenGeographies.includes(this.bookingGeography)) {
                    return false;
                }
                return true;
            })
            .map(field => {
                const enriched = { ...field };

                // Append currency info to label for currency fields
                if (field.type === 'currency') {
                    enriched.label = `${field.label} (${this.currencyLabel || this.currencyIsoCode})`;
                    enriched.currencyCode = this.currencyIsoCode;
                }

                // Set dynamic value from component state
                enriched.value = this._getFieldValue(field.id);

                // Set dynamic options for picklists
                if (field.type === 'picklist' && optionsMap[field.id]) {
                    enriched.options = optionsMap[field.id];
                }

                // Set read-only based on permissions
                enriched.isReadOnly = this.isEditDisabled;

                return enriched;
            });
    }

    _getFieldValue(fieldId) {
        const valueMap = {
            'DvP_Amount__c': this.dvpAmount,
            'FD_Amount__c': this.fdAmount,
            'First_Breakclause__c': this.firstBreakclause || '',
            'Breakclause_Frequency__c': this.breakclauseFrequency || '',
            'Waiver__c': this.waiver || false,
            'DMT_Mitigant_Agreement_comments__c': this.mitigantComments || ''
        };
        return valueMap[fieldId] !== undefined ? valueMap[fieldId] : '';
    }

    // ─── Data Loading ─────────────────────────────────────────────────────────
    async _loadData() {
        this.isLoading = true;
        try {
            const result = await getData({ recordId: this.recordId });
            this._mapServerData(result);
        } catch (error) {
            this._showToast('Error', error?.body?.message || 'Error loading data', 'error');
            throw error;  // Re-throw so caller knows it failed
        } finally {
            this.isLoading = false;
            // Signal child tables to reset their draft values
            this.tableRefreshCounter++;
            console.log('📊 Incremented tableRefreshCounter to:', this.tableRefreshCounter);
        }
    }

    _mapServerData(data) {
        // Form fields
        this.bookingGeography = data.bookingGeography;
        this.currencyIsoCode = data.currencyIsoCode;
        this.currency = data.currency_x;
        this.conversionLabel = data.conversionLabel;
        this.currencyLabel = data.currencyLabel;
        this.isReadOnlyUser = data.isReadOnlyUser === true || data.isReadOnlyUser === 'true';
        this.lineStatus = data.lineStatus;
        this.showSingular = data.showSingular === true || data.showSingular === 'true';
        // Form data
        this.dvpAmount = data.dvpAmount;
        this.fdAmount = data.fdAmount;
        this.firstBreakclause = data.firstBreakclause;
        this.breakclauseFrequency = data.breakclauseFrequency;
        this.waiver = data.waiver;
        this.mitigantComments = data.mitigantComments;
        this.additionalRestrictions = data.additionalRestrictions || '';
        this.comments = data.comments || '';
        this.firstBreakOptions = data.firstBreakOptions || [];
        this.breakFrequencyOptions = data.breakFrequencyOptions || [];

        // Tables data - rename currency_x → currency for child component compatibility
        this.derivatives = this._mapCurrencyInRows(data.derivatives, 'Derivatives');
        this.repos = this._mapCurrencyInRows(data.repos, 'Repos');
        this.depos = this._mapCurrencyInRows(data.depos, 'Depos');
        this.equities = this._mapCurrencyInRows(data.equities, 'Equities');
        this.derivativesTotalAmount = data.derivativesTotalAmount;
        this.reposTotalAmount = data.reposTotalAmount;
        this.deposTotalAmount = data.deposTotalAmount;
        this.equitiesTotalAmount = data.equitiesTotalAmount;
        this.tableRestric = data.tableRestric;
        this.tableReposProducts = data.tableReposProducts;
        this.tableDerivativesProducts = data.tableDerivativesProducts;
        this.tableDeposProducts = data.tableDeposProducts;
        this.mainBorrowerCountry = data.mainBorrowerCountryIfoId || '';
        this.maxTenorOptions = data.maxTenorOptions;
        this.fdAmountRestric = data.fdAmountRestric;
        this.dvpAmountRestric = data.dvpAmountRestric;
        this.singularCon = this._mapSingularRows(data.singularCon);
        this.columnsCopy = data.columnsCopy;
        this.columnsCopyTransaction = data.columnsCopyTransaction;
        this.restricCopy = data.restricCopy;
    }

    _mapCurrencyInRows(rows, tabletype) {
        if (rows && !Array.isArray(rows)) return rows;
        const sourceRows = (rows && rows.length > 0) ? rows : [this._buildEmptyRiskRow(tabletype)];
        return sourceRows.map((row, index) => {
            const mapped = { ...row };
            // Rename currency_x → currency (Apex reserved word workaround)
            if (row.currency_x !== undefined) {
                mapped.currency = row.currency_x;
                delete mapped.currency_x;
            }
            // Add control properties required by dmt_risk_limit_table custom datatable
            const isLast = index === sourceRows.length - 1;
            mapped.initRead = row.isDisabled ? 'true' : 'true'; // initTerm always readonly after initial set
            mapped.pickDisabled = isLast ? false : true;
            mapped.deleteDisabled = isLast ? false : true;
            mapped.buttonDisabled = isLast ? false : true;
            return mapped;
        });
    }

    // Placeholder row so Depos/Equities always render one editable, deletable line.
    _buildEmptyRiskRow(tabletype) {
        return {
            Id: '1',
            initTerm: '0',
            endTerm: '2',
            amount: null,
            tabletype,
            isDisabled: false,
            line: this.recordId,
            currency_x: this.currencyIsoCode
        };
    }

    _mapSingularRows(rows) {
        if (rows && !Array.isArray(rows)) return rows;
        const sourceRows = (rows && rows.length > 0) ? rows : [this._buildEmptySingularRow()];
        return sourceRows.map((row, index) => {
            const mapped = { ...row };
            if (row.currency_x !== undefined) {
                mapped.currency = row.currency_x;
                delete mapped.currency_x;
            }
            const isLast = index === sourceRows.length - 1;
            mapped.isEditableField = !row.isDisabled;
            mapped.pickDisabled = !isLast;
            mapped.buttonDisabled = !isLast;
            mapped.deleteDisabled = !isLast;
            return mapped;
        });
    }

    _buildEmptySingularRow() {
        return {
            Id: '1',
            operationName: '',
            amount: null,
            dvpAmount: null,
            fdAmount: null,
            initTerm: '0',
            endTerm: '',
            maxDate: null,
            active: false,
            tabletype: 'Singular',
            isDisabled: false,
            line: this.recordId,
            currency_x: this.currencyIsoCode
        };
    }

    // A placeholder the user never filled in must not create a DMT_Risk_Line_Term__c.
    _serializeRows(rows, meaningfulFields) {
        if (!Array.isArray(rows)) {
            return rows ? JSON.stringify(rows) : null;
        }
        const persistable = rows.filter(row => {
            if (meaningfulFields === RISK_ROW_FIELDS && (row.amount === null || row.amount === undefined || row.amount === '')) {
                return false;
            }
            if (row.Id && String(row.Id).length === 18) {
                return true;
            }
            return meaningfulFields.some(field => {
                const value = row[field];
                return value !== null && value !== undefined && value !== '';
            });
        });
        return JSON.stringify(persistable);
    }

    // ─── Event Handlers ───────────────────────────────────────────────────────

    handleFormFieldChange(event) {
        const { fieldId, value } = event.detail;
        switch (fieldId) {
            case 'DvP_Amount__c':
                this.dvpAmount = value;
                break;
            case 'FD_Amount__c':
                this.fdAmount = value;
                break;
            case 'First_Breakclause__c':
                this.firstBreakclause = value;
                break;
            case 'Breakclause_Frequency__c':
                this.breakclauseFrequency = value;
                break;
            case 'Waiver__c':
                this.waiver = value;
                break;
            case 'DMT_Mitigant_Agreement_comments__c':
                this.mitigantComments = value;
                break;
            default:
                break;
        }
        this._enterEditMode();
    }

    handleFormEditModeChange() {
        this._enterEditMode();
    }

    handleDerivativesAmountChange(event) {
        if (this.isEditDisabled) {
            return;
        }
        console.log('📥 handleDerivativesAmountChange event:', event.detail);
        this.derivativesTotalAmount = event.detail.value;
        this.defaultLimitDerivatives = 'true';
        console.log('✅ Updated derivativesTotalAmount:', this.derivativesTotalAmount, 'defaultLimitDerivatives:', this.defaultLimitDerivatives);
        this._enterEditMode();
    }

    handleDerivativesTableEditStart() {
        this._enterEditMode();
    }

    handleDeposAmountChange(event) {
        this.deposTotalAmount = event.detail.value;
        this.defaultLimitDepos = 'true';
        this._enterEditMode();
    }

    handleEquitiesAmountChange(event) {
        this.equitiesTotalAmount = event.detail.value;
        this.defaultLimitEquities = 'true';
        this._enterEditMode();
    }

    handleReposAmountChange(event) {
        this.reposTotalAmount = event.detail.value;
        this.defaultLimitRepos = 'true';
        this._enterEditMode();
    }

    handleTableRiskChange(event) {
        const { tabletype, data } = event.detail;
        if (tabletype === 'Derivatives') {
            this.derivatives = data;
            this.defaultLimitDerivatives = 'false';
        } else if (tabletype === 'Depos') {
            this.depos = data;
            this.defaultLimitDepos = 'false';
        } else if (tabletype === 'Equities') {
            this.equities = data;
            this.defaultLimitEquities = 'false';
        } else if (tabletype === 'Repos') {
            this.repos = data;
            this.defaultLimitRepos = 'false';
        }
        this._enterEditMode();
    }

    async handleRiskAmountChange(event) {
        const { Id, amount } = event.detail;
        this._enterEditMode();
        if (Id && String(Id).length === 18) {
            try {
                await updateRiskLineTermAmount({
                    riskLineTermId: Id,
                    amount: amount === '' ? null : amount
                });
            } catch (error) {
                this._showToast('Error', error?.body?.message || 'Error updating risk amount', 'error');
            }
        }
    }

    handleTableProductChanges(event) {
        this.tableRestric = event.detail;
        this._enterEditMode();
    }

    handleTableDerivativesChanges(event) {
        this.tableDerivativesProducts = event.detail;
        this._enterEditMode();
    }

    handleTableDeposChanges(event) {
        this.tableDeposProducts = event.detail;
        this._enterEditMode();
    }

    handleTableReposChanges(event) {
        this.tableReposProducts = event.detail;
        this._enterEditMode();
    }

    handleSingularChange(event) {
        this.singularCon = event.detail;
        this._enterEditMode();
    }

    handleTextfieldChange(event) {
        if (this.isEditDisabled) {
            return;
        }
        const { fieldName, value } = event.detail;
        console.log('📝 Textarea changed:', fieldName, value);
        
        // Capture textarea values
        if (fieldName === 'DMT_Additional_Restrictions__c') {
            this.additionalRestrictions = value;
        } else if (fieldName === 'DMT_Comments__c') {
            this.comments = value;
        }
        
        this._enterEditMode();
    }

    handleSendRowsEvent(event) {
        const { context, data } = event.detail;
        if (context === 'derivatives') {
            this.derivatives = data;
        } else if (context === 'depos') {
            this.depos = data;
        } else if (context === 'repos') {
            this.repos = data;
        } else if (context === 'equities') {
            this.equities = data;
        } else if (context === 'singular') {
            this.singularCon = data;
        } else if (context === 'oprestric') {
            this.tableRestric = data;
        } else if (context === 'tableDerivativesProducts') {
            this.tableDerivativesProducts = data;
        } else if (context === 'tableDeposProducts') {
            this.tableDeposProducts = data;
        } else if (context === 'tableReposProducts') {
            this.tableReposProducts = data;
        }
        this._enterEditMode();
    }

    // ─── Save / Cancel ────────────────────────────────────────────────────────

    async handleSave() {
        // Validate form FIRST (without changing state)
        const formRenderer = this.template.querySelector('c-dmt_form_renderer');
        console.log('tableRestric:', JSON.stringify(this.tableRestric));
        if (formRenderer) {
            const validation = formRenderer.validate();
            if (!validation.isValid) {
                this.showPopover = true;
                this.popoverMessage = `Invalid fields: ${validation.invalidFields.join(', ')}`;
                return;
            }
        }

        // Only after validation passes, enter save flow
        this.isSaving = true;
        this.showRiskTables = false;  // Unmount tables for reload
        this.editMode = false;
        this.showPopover = false;
        let saveSuccessful = false;

        try {
            const payload = {
                recordId: this.recordId,
                derivatives: this._serializeRows(this.derivatives, RISK_ROW_FIELDS),
                depos: this._serializeRows(this.depos, RISK_ROW_FIELDS),
                repos: this._serializeRows(this.repos, RISK_ROW_FIELDS),
                equities: this._serializeRows(this.equities, RISK_ROW_FIELDS),
                tableRestric: this.tableRestric ? JSON.stringify(this.tableRestric) : null,
                tableDerivativesProducts: this.tableDerivativesProducts ? JSON.stringify(this.tableDerivativesProducts) : null,
                tableDeposProducts: this.tableDeposProducts ? JSON.stringify(this.tableDeposProducts) : null,
                tableReposProducts: this.tableReposProducts ? JSON.stringify(this.tableReposProducts) : null,
                singularCon: this._serializeRows(this.singularCon, SINGULAR_ROW_FIELDS),
                derivativesTotalAmount: this.derivativesTotalAmount,
                dvpAmount: this.dvpAmount,
                fdAmount: this.fdAmount,
                firstBreakclause: this.firstBreakclause,
                breakclauseFrequency: this.breakclauseFrequency,
                waiver: this.waiver,
                mitigantComments: this.mitigantComments,
                additionalRestrictions: this.additionalRestrictions || '',
                comments: this.comments || ''
            };

            console.log('payload: '+JSON.stringify(payload));

            const result = await saveProducts(payload);

            if (result.error && result.error !== 'OK') {
                this.showPopover = true;
                this.popoverMessage = result.message || 'An error occurred while saving.';
                this.showRiskTables = true;  // Remount on error
                return;
            }

            // Success - data saved
            saveSuccessful = true;
            this.editMode = false;
            this.showPopover = false;
            this._dispatchEditingTab(null);

            // Reload data from server
            if (this.lineStatus !== 'Closed') {
                try {
                    await this._loadData();
                    this._showToast('Success', 'Products saved successfully', 'success');
                } catch (loadError) {
                    // If reload fails, show error but still remount with last known data
                    console.error('Error reloading data after save:', loadError);
                    this._showToast('Warning', 'Data saved but reload had issues. Please refresh the page.', 'warning');
                }
            } else {
                this._showToast('Success', 'Products saved successfully', 'success');
            }
        } catch (error) {
            console.error('Save error:', error);
            this.showPopover = true;
            this.popoverMessage = error?.body?.message || 'An error occurred while saving.';
        } finally {
            this.isSaving = false;
            this.editMode = false;
            this.showPopover = false;
            // Always remount tables to ensure UI refreshes with fresh data
            // Note: Child tables will auto-clear draftValues when new data arrives via setter
            this.showRiskTables = true;
        }
    }

    handleCancel() {
        this.isSaving = false;
        this.editMode = false;
        this.showPopover = false;
        this.showRiskTables = false;
        this._dispatchEditingTab(null);
        
        // Reload data and then remount tables
        this._loadData()
            .then(() => {
                // Data loaded successfully, remount tables
                this.showRiskTables = true;
            })
            .catch(error => {
                // Error already shown by _loadData(), but still remount tables with last known data
                console.warn('Cancel: Error reloading data, remounting with existing data', error);
                this.showRiskTables = true;
            });
    }

    // ─── Private ──────────────────────────────────────────────────────────────

    _enterEditMode() {
        if (this.isSaving || this.isEditDisabled) {
            return;
        }
        if (!this.editMode) {
            this.editMode = true;
            this._dispatchEditingTab();
        }
    }

    _dispatchEditingTab(tab = 'products') {
        this.dispatchEvent(new CustomEvent('editingtab', {
            detail: { tab },
            bubbles: true,
            composed: true
        }));
    }

    _showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}