import { LightningElement, api, wire } from 'lwc';
import { refreshApex }    from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// TODO: [DEAD_CODE] pubsub import - no longer used after migration to parent-ref coordination
// import pubsub             from 'omnistudio/pubsub';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import OPP_CLIENT_OBJECT from '@salesforce/schema/DMT_Opportunity_Client__c';
import PRODUCT_AREA_FIELD from '@salesforce/schema/Opportunity.DMT_Product_Area__c';
import getApprovalData    from '@salesforce/apex/DMT_ApprovalDataController.getApprovalData';
import saveApprovalData   from '@salesforce/apex/DMT_ApprovalDataController.saveApprovalData';
import getTaxonomyCatalogValues               from '@salesforce/apex/DMT_ApprovalDataController.getTaxonomyCatalogValues';
import getCurrencyLabel                       from '@salesforce/apex/DMT_Currency_Conversion_Utils.getCurrencyLabel';
import { applyNbcMarks }                      from 'c/dmt_nbc_marks';

// --- Ficheros de campos para cada sección del formulario
import { dealMainFields }             from './dmt_approval_deal_main_fields';
import { dealBankingPoolFields }      from './dmt_approval_deal_banking_pool_fields';
import { bookingPoolFields }          from './dmt_approval_deal_booking_pool';
import { dealOtherAspectsFields }     from './dmt_approval_deal_other_aspects_fields';
import { dealRiskFields }             from './dmt_approval_deal_risk_fields';
import { dealSustainableFields }      from './dmt_approval_deal_sustainable_fields';
import { dealSppiFields }             from './dmt_approval_deal_sppi_fields';
import { clientInfoFields, basicFinancialsFields, basicFinancialsFieldsExtra } from './dmt_approval_client_info_fields';
import { clientProfitabilityFields }  from './dmt_approval_client_profitability_fields';
import { globalStructureFields }  from './dmt_approval_global_structure_fields';
import { dealProfitabilityScenariosFields } from './dmt_approval_deal_profitability_scenarios_fields';
/* const EVENT_SAVE   = 'Save';
const EVENT_BUTTON = 'Button'; */
// TODO: [DEAD_CODE] MASTER_RT_OPP_CLIENT - hardcoded Record Type Id should use objectInfo.defaultRecordTypeId instead
const MASTER_RT_OPP_CLIENT = '012000000000000AAA';

// Stages in which this tab allows editing, independently of the parent's global canEdit.
// For Approval stage, isTeamMemberApprovalEdit permission is still required (checked in _computeEffectiveCanEdit).

const TAB_CONFIG = [
    { id: 'deal',                label: 'Deal' },
    { id: 'clientProfitability', label: 'Client Profitability' },
    { id: 'businessPlanData',    label: 'Business Plan Data' },
    { id: 'clientInformation',   label: 'Client Information' }
];

const DEAL_SECTION_REFS = ['dealMain', 'dealBankingPool', 'dealProfitabilityScenarios', 'dealOtherAspects', 'dealSustainable', 'dealRisk', 'dealSppi', 'globalStructureForm', 'bankingPoolForm'];
const DEAL_TABLE_REFS = ['globalStructureDebt', 'globalStructureUses', 'globalStructureEquity', 'bankingPoolTable'];
const CLIENT_INFO_TABLE_REFS = ['financialsTable'];
const ALL_TABLE_REFS = [...DEAL_TABLE_REFS, ...CLIENT_INFO_TABLE_REFS];
const CLIENT_INFO_SECTION_REFS = ['clientInfo', 'basicFinancials', 'basicFinancialsExtra'];
const CLIENT_PROFITABILITY_SECTION_REFS = ['clientProfitability'];
const BUSINESS_PLAN_SECTION_REFS = ['businessPlan'];
const APPROVERS_SECTION_REFS = ['approversSection'];
const ALL_FORM_SECTION_REFS = [...APPROVERS_SECTION_REFS, ...DEAL_SECTION_REFS, ...CLIENT_INFO_SECTION_REFS, ...CLIENT_PROFITABILITY_SECTION_REFS, ...BUSINESS_PLAN_SECTION_REFS];
// Approver fields belong to Opportunity (not DMT_Opportunity_Client__c);
// SPPI fields are routed via objectType metadata on their field definitions
const OPPORTUNITY_FIELD_NAMES = new Set([
    'DMT_Booking_Unit_Risk_Analyst__c',
    'DMT_Approver__c',
    'DMT_ApproverGlobalBanker__c',
    'DMT_Financial_Sponsors__c'
]);
const NOT_GTB_FIELDS = ['DMT_Applicable_Jurisdiction__c','DMT_Security_Package__c','DMT_Client_RWA__c','DMT_Client_Net_Incomes__c','Geographical_Footprint_desc__c','Industry_Overview_desc__c'];
// Maps each ref name to its parent tab id for error grouping
const REF_TO_TAB = {};
DEAL_SECTION_REFS.forEach(r => { REF_TO_TAB[r] = 'deal'; });
CLIENT_INFO_SECTION_REFS.forEach(r => { REF_TO_TAB[r] = 'clientInformation'; });
CLIENT_PROFITABILITY_SECTION_REFS.forEach(r => { REF_TO_TAB[r] = 'clientProfitability'; });
BUSINESS_PLAN_SECTION_REFS.forEach(r => { REF_TO_TAB[r] = 'businessPlanData'; });
// Note: APPROVERS_SECTION_REFS not in REF_TO_TAB — errors show in global footer, not on a tab

export default class DmtOppApprovalDetails extends LightningElement {

    // ─── State ────────────────────────────────────────────────────────────────

    isEditMode      = false;
    isLoading       = false;
    isLoadingSaving = false;
    hasError        = false;
    errorMessage    = '';
    allData             = {};
    groupData           = {};
    globalStructureData = [];
    bankingPoolData     = [];
    opportunityClientId = null;
    groupId             = null;
    optionsMap          = {};

    // ─── Field definitions (exposed for template) ─────────────────────────────

    dealMainFields            = dealMainFields;
    dealBankingPoolFields     = dealBankingPoolFields;
    bookingPoolFields         = bookingPoolFields; 
    dealOtherAspectsFields    = dealOtherAspectsFields;
    dealRiskFields            = dealRiskFields;
    dealProfitabilityScenariosFields = dealProfitabilityScenariosFields;
    dealSustainableFields     = dealSustainableFields;
    dealSppiFields            = dealSppiFields;
    basicFinancialsFields     = basicFinancialsFields;
    basicFinancialsFieldsExtra      = basicFinancialsFieldsExtra;
    clientInfoFields          = clientInfoFields;
    clientProfitabilityFields = clientProfitabilityFields;
    globalStructureFields     = globalStructureFields;
    _currencyExtraText        = '';
    isGtb                     = false;
    activeTabId     = 'deal';
    _visitedDeal                = true;
    _visitedClientProfitability = false;
    _visitedBusinessPlanData    = false;
    _visitedClientInformation   = false;
    showDiscardChangesModal     = false;

    _wiredResult          = null;
    _canEdit              = true;
    _stageRecord          = '';
    _readOnlyApplied      = false;
    _taxonomyCatalogValues  = {};

    dirtyTabs = {
        deal: false,
        clientProfitability: false,
        businessPlanData: false,
        clientInformation: false
    };

    errorTabs = {
        deal: false,
        clientProfitability: false,
        businessPlanData: false,
        clientInformation: false
    };

    _tableSaveError = false;
    _invalidFieldIds = { deal: new Set(), clientProfitability: new Set(), businessPlanData: new Set(), clientInformation: new Set() };

    // ─── Public API ───────────────────────────────────────────────────────────

    @api currentRecordId;

    @api get recordId() { return this.currentRecordId; }
    set recordId(value) {
        this.currentRecordId = value;
        this.isLoading       = true;
        this._restoreActiveTab();
    }

    @api get canEdit() { return this._canEdit; }
    set canEdit(value) {
        const newValue = !!value;
        if (newValue !== this._canEdit) {
            this._canEdit = newValue;
            this._applyReadOnlyToSections();
            this._applyReadOnlyForTab();
            
        }
        
    }

    @api get stageRecord() { return this._stageRecord; }
    set stageRecord(value) {
        this._stageRecord = value || '';
    }

    get approvalFieldOptions() {
        return {
            catalogValues: this._taxonomyCatalogValues,
            picklistSfOptions: {
                ...this.optionsMap,
                DMT_Currency__c: this._taxonomyCatalogValues?.['C264'] || []
            }
        };
    }

    get currencyLabel() {
        return this.allData?.DMT_Currency__c;
    }


    // ─── Data loading ─────────────────────────────────────────────────────────
    @wire(getTaxonomyCatalogValues)
    wiredTaxonomyCatalogValues({ data, error }) {
        if (data)  this._taxonomyCatalogValues = data;
        else if (error) console.error('[dmt_opp_approval_details] getTaxonomyCatalogValues error:', error);
    }

    // Only for Global NBC: several fields across the Deal / Client Profitability / Client Information
    // subtabs apply exclusively when the Opportunity's Product Area is GTB.
    @wire(getRecord, { recordId: '$currentRecordId', fields: [PRODUCT_AREA_FIELD] })
    wiredProductArea({ data }) {
        if (!data) return;
        const productArea = data.fields.DMT_Product_Area__c?.value;
        const isGtb = productArea === 'GTB';
        if (isGtb === this.isGtb) return;
        this.isGtb = isGtb;
        this._applyNbcMarks(isGtb);
        this._applyGtbFieldVisibility(isGtb);
    }
    @wire(getApprovalData, { opportunityId: '$currentRecordId' })
    wiredRecord(result) {
        this._wiredResult = result;
        if (result.data) {
             console.log('📍 getApprovalData result:', JSON.stringify(result.data));

            this.opportunityClientId = result.data.opportunityClientId;
            this.groupData           = result.data.groupComparisonData || {}; // Datos originales/grupo utilizados para el undo y la comparacion
            this.groupId             = result.data.groupId;
            this.globalStructureData = result.data.globalStructure || [];
            this.bankingPoolData     = result.data.bankingPool || [];
            this.allData             = {
                ...(result.data.opportunityClient ?? {}),
                ...(result.data.opportunityData   ?? {})
            };

            console.log('🎯 groupId asignado en padre:', JSON.stringify({
            groupId: this.groupId,
            groupData: this.groupData
        }));
            this._loadCurrencyLabel(this.allData.DMT_CurrencyText__c);

        } else if (result.error) {
            console.error('[dmt_opp_approval_details] getApprovalData error:', result.error);
        }
        this.isLoading = false;
    }

    
    // TODO: [DEAD_CODE] objectInfo wire - not consumed in JS or template, consider using its defaultRecordTypeId for picklist wire instead of MASTER_RT_OPP_CLIENT
    @wire(getObjectInfo, { objectApiName: OPP_CLIENT_OBJECT })
    objectInfo;

    // ─── Picklist values Opp Client ──────────────────────────────────────────────────────    
    @wire(getPicklistValuesByRecordType, {
        objectApiName: OPP_CLIENT_OBJECT,
        recordTypeId: MASTER_RT_OPP_CLIENT
    })
    picklistData({ data, error }) {
        if (data) {
            this.optionsMap = Object.fromEntries(
                Object.entries(data.picklistFieldValues).map(([field, picklist]) => [field, picklist.values])
            );
        } else if (error) {
            console.error('[dmt_opp_approval_details] getPicklistValuesByRecordType error:', error);
        }
    }




    // ─── Lifecycle ────────────────────────────────────────────────────────────

    renderedCallback() {
        if (!this._readOnlyApplied) {
            this._applyReadOnlyToSections();
        }
    }

    // ─── Tab configuration ────────────────────────────────────────────────────

    get tabsConfig() {
        return TAB_CONFIG.map(tab => ({
            ...tab,
            isActive:    tab.id === this.activeTabId,
            isDirty:     this.dirtyTabs[tab.id] || false,
            hasError:    this.errorTabs[tab.id] || false,
            itemClass:   this._computeTabItemClass(tab.id),
            tabIndex:    tab.id === this.activeTabId ? '0' : '-1',
            ariaSelected: String(tab.id === this.activeTabId)
        }));
    }

    get showDealTab()                { return this._visitedDeal; }
    get showClientProfitabilityTab() { return this._visitedClientProfitability; }
    get showBusinessPlanDataTab()    { return this._visitedBusinessPlanData; }
    get showClientInformationTab()   { return this._visitedClientInformation; }

    get dealSections()       { return ['dealMain', 'dealBankingPool', 'dealOtherAspects','dealProfitabilityScenarios', 'dealGlobalStructure', 'dealSustainable', 'dealRisk', 'bankingPool', 'dealSppi']; }
    get clientInfoSections() { return ['basicFinancials', 'clientInfo', 'basicFinancialsExtra']; }
    get trueValue()          { return true; }
    get isReadOnlyUser()     { return !this._canEdit; }
    get clientGroupName()    { return this.groupData?.Name ?? ''; }
    get showGlobalStructure() { return !!this.allData?.DMT_SourceAndUses__c && !this.isGtb; }
    get showDealBankingPool() { return !this.isGtb }
    get showDealSustainable() { return !this.isGtb; }
    get showDealRisk() { return !this.isGtb; }
    get showFinancialsTable() { return !this.isGtb; }
    get showBankingPool() { return !this.isGtb; }
    get showBasicFinancial() { return !this.isGtb; }
    get dealPanelClass()                { return this.activeTabId === 'deal' ? 'slds-tabs_default__content slds-show' : 'slds-tabs_default__content slds-hide'; }
    get clientProfitabilityPanelClass() { return this.activeTabId === 'clientProfitability' ? 'slds-tabs_default__content slds-show' : 'slds-tabs_default__content slds-hide'; }
    get businessPlanDataPanelClass()    { return this.activeTabId === 'businessPlanData' ? 'slds-tabs_default__content slds-show' : 'slds-tabs_default__content slds-hide'; }
    get clientInformationPanelClass()   { return this.activeTabId === 'clientInformation' ? 'slds-tabs_default__content slds-show' : 'slds-tabs_default__content slds-hide'; }

    _computeTabItemClass(tabId) {
        const base = 'slds-tabs_default__item';
        return tabId === this.activeTabId ? base + ' slds-is-active' : base;
    }

    // ─── Tab navigation ──────────────────────────────────────────────────────

    handleTabClick(event) {
        event.preventDefault();
        const tabId = event.currentTarget.dataset.tabId;
        if (!tabId || tabId === this.activeTabId) return;

        const isFirstVisit = !this._isTabVisited(tabId);
        this._markTabVisited(tabId);
        this.activeTabId = tabId;
        this._persistActiveTab(tabId);

        // If the tab renders for the first time, defer state application
        // so new child components are in the DOM
        if (isFirstVisit) {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            Promise.resolve().then(() => {
                if (this.isEditMode) {
                    this._enterEditModeForTab(tabId);
                } else if (!this._canEdit) {
                    this._applyReadOnlyForTab(tabId);
                }
            });
        }
    }

    _isTabVisited(tabId) {
        switch (tabId) {
            case 'deal':                return this._visitedDeal;
            case 'clientProfitability': return this._visitedClientProfitability;
            case 'businessPlanData':    return this._visitedBusinessPlanData;
            case 'clientInformation':   return this._visitedClientInformation;
            default: return false;
        }
    }

    _markTabVisited(tabId) {
        switch (tabId) {
            case 'deal':                this._visitedDeal = true; break;
            case 'clientProfitability': this._visitedClientProfitability = true; break;
            case 'businessPlanData':    this._visitedBusinessPlanData = true; break;
            case 'clientInformation':   this._visitedClientInformation = true; break;
            default: break;
        }
    }

    _enterEditModeForTab(tabId) {
        const refNames = this._getRefNamesForTab(tabId);
        for (const name of refNames) {
            const ref = this.refs?.[name];
            if (ref) ref.enterEditMode?.();
        }
    }

    _getRefNamesForTab(tabId) {
        switch (tabId) {
            case 'deal':                return DEAL_SECTION_REFS;
            case 'clientProfitability': return CLIENT_PROFITABILITY_SECTION_REFS;
            case 'businessPlanData':    return BUSINESS_PLAN_SECTION_REFS;
            case 'clientInformation':   return CLIENT_INFO_SECTION_REFS;
            default: return [];
        }
    }

    // ─── Cross-section coordination ──────────────────────────────────────────

    handleSectionChange(event) {
        const { apiName, value } = event.detail;
        if (apiName) {
            this.allData = { ...this.allData, [apiName]: value };
            console.log('📍 handleSectionChange: updated allData:', JSON.stringify(this.allData));
        }
        this._updateDirtyState();
    }

    handleFieldChange(event) {
        const { fieldId, isFieldValid, apiName, value, isRevert } = event.detail || {};

        // Read mode + undo button: save the reverted value immediately
        if (!this.isEditMode && isRevert && apiName) {
            this._saveRevertedField(apiName, value);
            return;
        }

        const refName = ALL_FORM_SECTION_REFS.find(name => this.refs?.[name] === event.target);
        const tabId = refName ? REF_TO_TAB[refName] : null;
        if (tabId && fieldId !== undefined) {
            if (isFieldValid === false) {
                this._invalidFieldIds[tabId].add(fieldId);
                this.errorTabs = { ...this.errorTabs, [tabId]: true };
            } else {
                this._invalidFieldIds[tabId].delete(fieldId);
                if (this.errorTabs[tabId] && this._invalidFieldIds[tabId].size === 0) {
                    this.errorTabs = { ...this.errorTabs, [tabId]: false };
                }
            }
        }
        this._updateDirtyState();
    }

    async _saveRevertedField(apiName, value) {
        this.isLoadingSaving = true;
        this.hasError        = false;
        this.errorMessage    = '';
        try {
            // Resolve target object: check field metadata first (dmt_section_simple_form sections),
            // fall back to OPPORTUNITY_FIELD_NAMES for approver fields (approversSection)
            let fieldObjectType = null;
            for (const name of ALL_FORM_SECTION_REFS) {
                const ref = this.refs?.[name];
                if (typeof ref?.getFieldObjectType === 'function') {
                    const t = ref.getFieldObjectType(apiName);
                    if (t !== null) { fieldObjectType = t; break; }
                }
            }
            const isOppField        = fieldObjectType === 'Opportunity' ||
                                      (fieldObjectType === null && OPPORTUNITY_FIELD_NAMES.has(apiName));
            const recordFields      = isOppField ? {} : { [apiName]: value };
            const opportunityFields = isOppField ? { [apiName]: value } : null;

            const result = await saveApprovalData({
                recordFields,
                opportunityClientId : this.opportunityClientId,
                bpChangesJson       : null,
                opportunityId       : isOppField ? this.currentRecordId : null,
                opportunityFields
            });

            if (result?.success === false) {
                this.hasError     = true;
                this.errorMessage = result.errorMessage || 'Validation error. Please contact your administrator.';
                return;
            }

            await refreshApex(this._wiredResult);
            this._notifySuccess('Record updated successfully.');
        } catch (error) {
            this._notifyError(error);
        } finally {
            this.isLoadingSaving = false;
        }
    }

    handleTableSaveError(event) {
        this._tableSaveError = true;
        this._notifyError({ message: event.detail?.message || 'Error saving table data' });
    }

    _updateDirtyState() {
        const dealDirty = DEAL_SECTION_REFS.some(name => {
            const ref = this.refs?.[name];
            return ref && this._isSectionDirty(ref);
        });
        const tableDirty = DEAL_TABLE_REFS.some(name => {
            const ref = this.refs?.[name];
            return ref && this._isSectionDirty(ref);
        });
        const clientInfoDirty = CLIENT_INFO_SECTION_REFS.some(name => {
            const ref = this.refs?.[name];
            return ref && this._isSectionDirty(ref);
        });
        const clientInfoTableDirty = CLIENT_INFO_TABLE_REFS.some(name => {
            const ref = this.refs?.[name];
            return ref && this._isSectionDirty(ref);
        });
        const profitabilityDirty = CLIENT_PROFITABILITY_SECTION_REFS.some(name => {
            const ref = this.refs?.[name];
            return ref && this._isSectionDirty(ref);
        });

        const bpDirty = BUSINESS_PLAN_SECTION_REFS.some(name => {
            const ref = this.refs?.[name];
            return ref?.hasPendingChanges;
        });

        this.dirtyTabs = {
            deal: dealDirty || tableDirty,
            clientProfitability: profitabilityDirty,
            businessPlanData: bpDirty,
            clientInformation: clientInfoDirty || clientInfoTableDirty
        };
    }

    _isSectionDirty(ref) {
        const changes = ref.collectChanges?.();
        return changes && Object.keys(changes).length > 0;
    }

    _hasAnyDirtyFormSection() {
        if (Object.values(this.dirtyTabs).some(v => v)) return true;
        // Approvers section is outside tabs — check separately
        return APPROVERS_SECTION_REFS.some(name => {
            const ref = this.refs?.[name];
            return ref && this._isSectionDirty(ref);
        });
    }

    // ─── Edit mode ───────────────────────────────────────────────────────────

    handleEditModeChange() {
        if (this.isEditMode || !this._canEdit) return;
        for (const ref of this._allFormSectionRefs()) ref.enterEditMode?.();
        this.isEditMode = true;
        this._notifyEditMode(true);
    }

    @api getEditMode() {
        return this.isEditMode;
    }

    // ─── Save / Cancel ───────────────────────────────────────────────────────

    async handleSave() {
        const preservedTabId = this.activeTabId;
        this.isLoadingSaving = true;
        this.hasError  = false;
        this.errorTabs = { deal: false, clientProfitability: false, businessPlanData: false, clientInformation: false };
        this._invalidFieldIds = { deal: new Set(), clientProfitability: new Set(), businessPlanData: new Set(), clientInformation: new Set() };
        this._tableSaveError = false;

        try {
            // Save tables first — abort if any fails
            for (const name of ALL_TABLE_REFS) {
                const ref = this.refs?.[name];
                if (ref?.handleSave) {
                    await ref.handleSave();
                }
                if (this._tableSaveError) {
                    this.isLoadingSaving = false;
                    return;
                }
            }

            const recordFields = {};
            const opportunityFields = {};
            let allRequiredValid = true;
            const errorsByTab = {};

            for (const name of ALL_FORM_SECTION_REFS) {
                const ref = this.refs?.[name];
                if (!ref) continue;

                // dmt_section_simple_form: use field-level objectType metadata
                if (typeof ref.collectChangesByObject === 'function') {
                    const byObject = ref.collectChangesByObject();
                    Object.assign(recordFields,      byObject['DMT_Opportunity_Client__c'] ?? {});
                    Object.assign(opportunityFields,  byObject['Opportunity']               ?? {});
                } else {
                    // Other refs (e.g. approversSection): fall back to OPPORTUNITY_FIELD_NAMES
                    const changes = ref.collectChanges?.();
                    if (changes) {
                        for (const [key, val] of Object.entries(changes)) {
                            if (OPPORTUNITY_FIELD_NAMES.has(key)) {
                                opportunityFields[key] = val;
                            } else {
                                recordFields[key] = val;
                            }
                        }
                    }
                }

                if (typeof ref.validateRequired === 'function') {
                    const result = ref.validateRequired();
                    if (result && typeof result === 'object') {
                        if (!result.isValid) {
                            allRequiredValid = false;
                            const tabId = REF_TO_TAB[name] || 'deal';
                            if (!errorsByTab[tabId]) errorsByTab[tabId] = [];
                            if (result.invalidFields?.length) {
                                errorsByTab[tabId].push(...result.invalidFields);
                            }
                            if (result.invalidFieldIds?.length) {
                                for (const fid of result.invalidFieldIds) {
                                    this._invalidFieldIds[tabId]?.add(fid);
                                }
                            }
                        }
                    } else if (!result) {
                        allRequiredValid = false;
                    }
                }
            }
            const hasFieldChanges = Object.keys(recordFields).length > 0;
            const hasOppChanges   = Object.keys(opportunityFields).length > 0;

            // Collect BP table changes (array of { Id, Field__c: value } update objects)
            const bpChanges    = this.refs?.businessPlan?.collectBpChanges?.() ?? [];
            const hasBpChanges = bpChanges.length > 0;

            if (!hasFieldChanges && !hasBpChanges && !hasOppChanges && allRequiredValid) {
                // Nothing to save — exit edit mode silently
                this._persistActiveTab(preservedTabId);
                this.activeTabId = preservedTabId;
                this._exitEditMode();
                return;
            }

            if (!allRequiredValid) {
                this.errorTabs = {
                    deal: !!errorsByTab.deal,
                    clientProfitability: !!errorsByTab.clientProfitability,
                    businessPlanData: !!errorsByTab.businessPlanData,
                    clientInformation: !!errorsByTab.clientInformation
                };
                this.hasError = true;
                this.errorMessage = this._buildValidationErrorMessage(errorsByTab);
                return;
            }

            const result = await saveApprovalData({
                recordFields         : hasFieldChanges ? recordFields : {},
                opportunityClientId  : this.opportunityClientId,
                bpChangesJson        : hasBpChanges ? JSON.stringify(bpChanges) : null,
                opportunityId        : hasOppChanges ? this.currentRecordId : null,
                opportunityFields    : hasOppChanges ? opportunityFields : null
            });

            if (result?.success === false) {
                this.hasError     = true;
                this.errorMessage = result.errorMessage || 'Validation error. Please contact your administrator.';
                return;
            }

            // Refresh BP table state and reload fresh records from org
            await this.refs?.businessPlan?.refreshAfterSave?.();
            this._exitEditMode();
            await refreshApex(this._wiredResult);
            this._notifySuccess('Record updated successfully.');
            this._persistActiveTab(preservedTabId);
            this.activeTabId = preservedTabId;
            

        } catch (error) {
            this._notifyError(error);
        } finally {
            this.isLoadingSaving = false;
        }
    }

    handleCancel() {
        if (this._hasAnyDirtyFormSection()) {
            this.showDiscardChangesModal = true;
            return;
        }
        this._performCancel();
    }

    handleConfirmDiscard() {
        this.showDiscardChangesModal = false;
        this._performCancel();
    }

    handleCloseDiscardModal() {
        this.showDiscardChangesModal = false;
    }

    _performCancel() {
        const preservedTabId = this.activeTabId;
        for (const ref of this._allFormSectionRefs()) ref.restoreSnapshot?.();
        for (const name of ALL_TABLE_REFS) {
            this.refs?.[name]?.restoreSnapshot?.();
        }
        // Reset allData to original wire values so _recompute() won't use dirty data
        if (this._wiredResult?.data) {
            this.allData = {
                ...(this._wiredResult.data.opportunityClient ?? {}),
                ...(this._wiredResult.data.opportunityData   ?? {})
            };
        }
        this._persistActiveTab(preservedTabId);
        this.activeTabId = preservedTabId;
        this._exitEditMode();
    }

    _exitEditMode() {
        this.isEditMode   = false;
        for (const ref of this._allFormSectionRefs()) ref.commitEdit?.();
        for (const name of ALL_TABLE_REFS) {
            this.refs?.[name]?.commitEdit?.();
        }
        this.hasError     = false;
        this.errorMessage = '';
        this.dirtyTabs = { deal: false, clientProfitability: false, businessPlanData: false, clientInformation: false };
        this.errorTabs = { deal: false, clientProfitability: false, businessPlanData: false, clientInformation: false };
        this._invalidFieldIds = { deal: new Set(), clientProfitability: new Set(), businessPlanData: new Set(), clientInformation: new Set() };
        this._notifyEditMode(false);
    }

    // ─── Read-only mode ──────────────────────────────────────────────────────

    _applyReadOnlyToSections() {
        const refs = this._allFormSectionRefs();
        if (refs.length === 0) return;
        for (const ref of refs) ref.setReadOnlyMode?.(!this._canEdit);
        this._readOnlyApplied = true;
    }

    _applyReadOnlyForTab(tabId) {
        const refNames = this._getRefNamesForTab(tabId);
        for (const name of refNames) {
            this.refs?.[name]?.setReadOnlyMode?.(!this._canEdit);
        }
    }


    // ─── Helpers ─────────────────────────────────────────────────────────────

    _allFormSectionRefs() {
        const refs = [];
        for (const name of ALL_FORM_SECTION_REFS) {
            const ref = this.refs?.[name];
            if (ref) refs.push(ref);
        }
        return refs;
    }

    _persistActiveTab(tabId) {
        try {
            if (this.currentRecordId) {
                sessionStorage.setItem(`dmt_inner_tab_${this.currentRecordId}`, tabId);
            }
        } catch (_) { /* sessionStorage not available */ }
    }

    _restoreActiveTab() {
        try {
            if (!this.currentRecordId) return;
            const stored = sessionStorage.getItem(`dmt_inner_tab_${this.currentRecordId}`);
            if (stored && TAB_CONFIG.some(t => t.id === stored)) {
                this.activeTabId = stored;
                this._markTabVisited(stored);
            }
        } catch (_) { /* sessionStorage not available */ }
    }

    getFieldLabel(apiName) {
        for (const ref of this._allFormSectionRefs()) {
            const label = ref.getFieldLabel?.(apiName);
            if (label) return label;
        }
        return null;
    }

    // ─── Notifications ───────────────────────────────────────────────────────

    _buildValidationErrorMessage(errorsByTab) {
        const tabEntries = Object.entries(errorsByTab).filter(([, fields]) => fields.length > 0);
        if (tabEntries.length === 0) return 'Please fix the errors on this page before saving.';

        const tabLabel = (tabId) => TAB_CONFIG.find(t => t.id === tabId)?.label || tabId;
        const tabNames = tabEntries.slice(0, 3).map(([tabId]) => tabLabel(tabId));

        if (tabNames.length === 1) return `Please fix the errors in the ${tabNames[0]} tab before saving.`;
        const last = tabNames.pop();
        return `Please fix the errors in the ${tabNames.join(', ')} and ${last} tabs before saving.`;
    }

    _notifyEditMode(value) {
        this.dispatchEvent(new CustomEvent('editmodetab', {
            detail   : { editMode: value },
            bubbles  : true,
            composed : true
        }));
    }

    _notifySuccess(message) {
        this.dispatchEvent(new CustomEvent('recordsaved', { bubbles: true, composed: true }));
        this.dispatchEvent(new ShowToastEvent({ title: 'Success', message, variant: 'success' }));
    }

    _notifyError(error) {
        const errorMsg = error.body ? error.body.message : error.message;
        this.hasError     = true;
        this.errorMessage = errorMsg;
    }

    _loadCurrencyLabel(currencyIsoCode) {
        if (!currencyIsoCode) return;
        getCurrencyLabel({ currencyIsoCode })
            .then(result => {
                this._currencyExtraText = result || currencyIsoCode;
                this._applyCurrencyToFields();
            })
            .catch(() => {
                this._currencyExtraText = currencyIsoCode;
                this._applyCurrencyToFields();
            });
    }

    _applyCurrencyToFields() {
        // DMT_Client_Net_Incomes__c and DMT_Client_RWA__c always use EUR (hardcoded in field definition)
        // No dynamic currency override needed for these fields
    }

    _applyGtbFieldVisibility(isGtb) {
        const hideFields = (fields) => fields.map(f =>
            NOT_GTB_FIELDS.includes(f.id) ? { ...f, isHidden: isGtb } : f
        );
        this.dealMainFields = hideFields(this.dealMainFields);
        this.dealOtherAspectsFields = hideFields(this.dealOtherAspectsFields);
        this.dealRiskFields = hideFields(this.dealRiskFields);
        this.clientInfoFields = hideFields(this.clientInfoFields);
        this.clientProfitabilityFields = hideFields(this.clientProfitabilityFields);
        this.basicFinancialsFields = hideFields(this.basicFinancialsFields);
        this.basicFinancialsFieldsExtra = hideFields(this.basicFinancialsFieldsExtra);
    }

    // NBC Local/Global marks: driven by each field's own `nbcScope` property, set directly
    // in its *_fields.js descriptor (dmt_approval_deal_main_fields.js, etc.) — no id list here.
    _applyNbcMarks(isGtb) {
        this.dealMainFields = applyNbcMarks(this.dealMainFields, isGtb);
        this.dealOtherAspectsFields = applyNbcMarks(this.dealOtherAspectsFields, isGtb);
        this.clientInfoFields = applyNbcMarks(this.clientInfoFields, isGtb);
        this.clientProfitabilityFields = applyNbcMarks(this.clientProfitabilityFields, isGtb);
    }
}