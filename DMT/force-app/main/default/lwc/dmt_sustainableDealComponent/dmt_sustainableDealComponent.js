import { LightningElement, api, wire } from 'lwc';
import getPicklistValues from "@salesforce/apex/DMT_SustainableDealController.getPicklistValues";
import getCatalogByAssessment from '@salesforce/apex/DMT_SustainableDealController.getCatalogByAssessment';
import getCatalogBySubtype from '@salesforce/apex/DMT_SustainableDealController.getCatalogBySubtype';
import getDependentPicklistValues from "@salesforce/apex/DMT_SustainableDealController.getDependentPicklistValues";
import pubsub from "omnistudio/pubsub";

// ===== CONSTANTS =====
const EVT_NAME = 'sustainabilityChanges';
const EVT_EDIT_CHANNEL_NAME = 'productOpportunityFields';
const EVT_EDIT_NAME = 'activeEditMode';
const ENABLE_GREEN_FILTER = true;
const SSL_ONLY_VALUES = ['4', '3', '2'];
// Assessments that resolve the catalog directly from assessment value (no subtype needed)
const ASSESSMENT_DIRECT_CATALOG_VALUES = ['2', '3', '4', '5'];
const GREEN_FILTER_OPTIONS = [
        { value: 'delegated', label: 'Delegated Label' },
        { value: 'other', label: 'Other Green Activity' }
    ];
const VALID_STAGES_FOR_EDIT = ['Draft', 'Ready to close'];
const TXT_GREEN = 'Green';
const SUSTAINABLE_USE_OF_PROCEEDS = '6';
const SUBCATEGORY_TRIGGER_VALUES = ['5', '6'];

export default class Dmt_sustainableDealComponent extends LightningElement {
    // Propiedades privadas
    _edit = false;
    _opportunityLineItemId;
    _wrapperOpli = {};
    _isReadOnlyUser = true;
    _stageName = '';
    selectedAssessment = '';
    selectedSubtype = '';
    selectedCatalogValue = '';
    selectedGreenFilter = '';
    previousAssessment = '';
    previousSubtype = '';
    previousCatalogValue = '';
    previousGreenFilter = '';
    catalogOptions = [];
    assessmentOptions = [];
    subtypeOptions = [];
    error = '';
    greenFilterOptions = GREEN_FILTER_OPTIONS;
    selectedSustainabilityPercentage = '';
    _selectedSustainabilityBonus = false;
    labelValueSustainabilityBonus = '';


    @api
    set wrapperOpli(value) {
        this._wrapperOpli = value || {};
        
        if (this._wrapperOpli && this._wrapperOpli!= '{updateRisk}') {
            this.selectedAssessment = this._wrapperOpli.DMT_sustainable_deal_assessment__c || '';
            this.selectedSubtype = this._wrapperOpli.DMT_Sustainable_Deal_Subtype__c || '';
            this.selectedCatalogValue = this._wrapperOpli.DMT_sustainable_deal_value__c || '';
            this.selectedSustainabilityPercentage = this._wrapperOpli.DMT_PER_Sustainability_Percentage__c || '';
            this.selectedSustainabilityBonus = this._wrapperOpli.DMT_Sustainability_bonus_eligible__c || '';
            this.selectedGreenFilter = this._wrapperOpli.DMT_Sustainability_deal_value_criteria__c || '';

            if (this.selectedAssessment) {
                this.loadCatalogIfNeeded();
            }
        }
    }

    get wrapperOpli() {
        return this._wrapperOpli;
    }

    @api
    set edit(value) {
        this._edit = (typeof value === 'boolean') ? value : (String(value).toLowerCase() === 'true');
    }

    get edit() {
        return this._edit;
    }

    @api
    set selectedSustainabilityBonus(value) {
        this._selectedSustainabilityBonus =  (value === true || value === 'Yes' || value === 'true');
        this.labelValueSustainabilityBonus = this._selectedSustainabilityBonus ? 'Yes' : 'No';
    }

    get selectedSustainabilityBonus() {
        return this._selectedSustainabilityBonus;
    }

    @api
    set opportunityLineItemId(value) {
        this._opportunityLineItemId = value;
    }

    get opportunityLineItemId() {
        return this._opportunityLineItemId;
    }

    @api
    set isReadOnlyUser(value) {
        this._isReadOnlyUser = (typeof value === 'boolean') ? value : (String(value).toLowerCase() === 'true');
    }

    get isReadOnlyUser() {
        return this._isReadOnlyUser;
    }

    @api
    set stageName(value) {
        this._stageName = value || '';
    }

    get stageName() {
        return this._stageName;
    }

    get showEditIcon() {
        return !this._isReadOnlyUser && VALID_STAGES_FOR_EDIT.includes(this._stageName);
    }

    get assessmentLabel() {
        return this.findOptionLabel(this.assessmentOptions, this.selectedAssessment);
    }

    get subtypeLabel() {
        return this.findOptionLabel(this.subtypeOptions, this.selectedSubtype);
    }

    get catalogLabel() {
        return this.findOptionLabel(this.catalogOptions, this.selectedCatalogValue);
    }

    get greenFilterLabel() {
        return this.findOptionLabel(GREEN_FILTER_OPTIONS, this.selectedGreenFilter);
    }
    get isSubtypeDisabled() {
        return !SUBCATEGORY_TRIGGER_VALUES.includes(this.selectedAssessment);
    }

    get isGreenFilterDisabled() {
        return !(this.selectedAssessment === SUSTAINABLE_USE_OF_PROCEEDS && this.selectedSubtype === TXT_GREEN);
    }

    get isCatalogDisabled() {
        const hasSubtypeSelected = SUBCATEGORY_TRIGGER_VALUES.includes(this.selectedAssessment) && this.selectedSubtype !== '';
        const isSSL = SSL_ONLY_VALUES.includes(this.selectedAssessment);
        if (!ENABLE_GREEN_FILTER) {
            return !(hasSubtypeSelected || isSSL);
        }

        const needsGreenFilter = this.selectedAssessment === SUSTAINABLE_USE_OF_PROCEEDS && this.selectedSubtype === TXT_GREEN;
        const greenFilterCondition = !this.isGreenFilterDisabled && this.selectedGreenFilter !== '';

        if(needsGreenFilter){
            return !(hasSubtypeSelected && greenFilterCondition);
        } else {
            return !hasSubtypeSelected && !isSSL;
        }
        
    }

    get subtypePlaceholder() {
        return this.isSubtypeDisabled ? 'Select an Assessment with subcategory' : 'Select an Option';
    }

    get greenFilterPlaceholder() {
        return this.isGreenFilterDisabled ? 'Not available for the selected deal subcategory' : 'Select an Option';
    }

    get catalogPlaceholder() {
        return this.isCatalogDisabled ? 'Complete previous sustainability fields' : 'Select an Option';
    }

    get showGreenFilter() {
        return ENABLE_GREEN_FILTER;
    }

    connectedCallback() {
        this.loadPicklistValues();
    }

    handleAssessmentChange(event) {
        const newValue = event.detail.value;
        this.selectedAssessment = newValue;
        this.resetDependentFields();
        this.loadDependentPicklist();
        this.loadCatalogIfNeeded();
        if(this.selectedAssessment == '1'){
            this.selectedSustainabilityBonus = false;
            this.dispatchSetFundingEvent();
            
        }
        if (this.previousAssessment !== newValue) {
            this.previousAssessment = newValue;
            this.dispatchSetFundingEvent();
        }
        
    }

    handleSustainabilityPercentageChange(event){
        const newValue = event.detail.value;
        
         if (this.selectedSustainabilityPercentage !== newValue) {
            this.selectedSustainabilityPercentage = newValue;
            this.dispatchSetFundingEvent();
        }
    }

    handleSustainabilityBonusChange(event){
        this.selectedSustainabilityBonus = event.target.checked; // boolean
        this.dispatchSetFundingEvent();
    }

    handleSubtypeChange(event) {
        const newValue = event.detail.value;
        this.selectedSubtype = newValue;
        this.selectedCatalogValue = '';
        this.selectedGreenFilter = '';
        this.loadCatalogIfNeeded();

        if (this.previousSubtype !== newValue) {
            this.previousSubtype = newValue;
            if(this.selectedSubtype == 'Green' || this.selectedSubtype == 'Social' || this.selectedSubtype == 'Green and social'){
                this.selectedSustainabilityBonus = true;
            }
            this.dispatchSetFundingEvent();
        }

        
    }

    handleGreenFilterChange(event) {
        const newValue = event.detail.value;
        this.selectedGreenFilter = newValue;
        this.selectedCatalogValue = '';
        this.loadCatalogIfNeeded();

        if (this.previousGreenFilter !== newValue) {
            this.previousGreenFilter = newValue;
        }

        this.dispatchSetFundingEvent();
    }

    handleCatalogChange(event) {
        const newValue = event.detail.value;
        this.selectedCatalogValue = newValue;

        if (this.previousCatalogValue !== newValue) {
            this.previousCatalogValue = newValue;
            this.dispatchSetFundingEvent();
        }
    }

    handleEditClick() {
        const payload = {isEditMode: true };
        pubsub.fire(EVT_EDIT_CHANNEL_NAME, EVT_EDIT_NAME, payload);
    }
    loadPicklistValues() {
            this.error = "";

        Promise.all([
            getPicklistValues({ fieldName: "DMT_sustainable_deal_assessment__c" }),
            getPicklistValues({ fieldName: "DMT_Sustainable_Deal_Subtype__c" })
        ])
        .then(([assessmentResult, subtypeResult]) => {
            this.assessmentOptions = this.mapToOptions(assessmentResult);
            this.subtypeOptions = this.mapToOptions(subtypeResult);
            this.loadDependentPicklist();
        })
        .catch(error => {
            this.handleError("Error loading picklist values", error);
        });
    }
    loadDependentPicklist() {
        if (!SUBCATEGORY_TRIGGER_VALUES.includes(this.selectedAssessment)) {
            return;
        }

            getDependentPicklistValues({ controllingFieldValue: this.selectedAssessment })
                .then((result) => {
                this.subtypeOptions = this.mapToOptions(result);
                })
            .catch(error => {
                this.handleError("Error loading dependent picklist values", error);
                });
    }

    loadCatalogIfNeeded() {
        const shouldLoadCatalog = this.isCatalogDisabled === false;

        if (!shouldLoadCatalog) {
            this.catalogOptions = [];
            return;
        }

        if (ASSESSMENT_DIRECT_CATALOG_VALUES.includes(this.selectedAssessment)) {
            // Assessments '2','3','4','5': catalog is fixed to RBES regardless of subtype
            getCatalogByAssessment({ assessmentValue: this.selectedAssessment })
                .then((result) => {
                    this.catalogOptions = this.mapToOptions(result);
                })
                .catch(error => {
                    this.handleError('Error loading catalog', error);
                });
        } else {
            // Assessment '6' (Use of Proceeds): catalog depends on selected subtype
            getCatalogBySubtype({
                subtypeValue: this.selectedSubtype,
                greenFilter: this.selectedGreenFilter,
                enableGreenFilter: ENABLE_GREEN_FILTER
            })
                .then((result) => {
                    this.catalogOptions = this.mapToOptions(result);
                })
                .catch(error => {
                    this.handleError('Error loading catalog', error);
                });
        }
    }

    resetDependentFields() {
        this.selectedSubtype = '';
        this.selectedCatalogValue = '';
        this.selectedGreenFilter = '';
        this.catalogOptions = [];
    }

    mapToOptions(data) {
        return data.map(entry => ({
            value: entry.value,
            label: entry.label
        }));
    }

    findOptionLabel(options, value) {
        const option = options.find(opt => opt.value === value);
        return option ? option.label : '';
    }
    dispatchSetFundingEvent() {
        const payload = {
                DMT_sustainable_deal_assessment__c: this.selectedAssessment,
                DMT_Sustainable_Deal_Subtype__c: this.selectedSubtype,
                DMT_sustainable_deal_value__c: this.selectedCatalogValue,
                DMT_PER_Sustainability_Percentage__c: this.selectedSustainabilityPercentage,
                DMT_Sustainability_bonus_eligible__c: this.selectedSustainabilityBonus,
                DMT_Sustainability_deal_value_criteria__c: this.selectedGreenFilter,
        };

        this.dispatchEvent(new CustomEvent(EVT_NAME, {
                          bubbles: true,
                          composed: true,
                          detail: { data: payload }
                      }));
    }
    handleError(message, error) {
        this.error = `${message}: ${error.body?.message || error.message}`;
        console.error(this.error, error);
    }
}