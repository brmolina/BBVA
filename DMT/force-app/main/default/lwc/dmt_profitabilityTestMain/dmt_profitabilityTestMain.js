import { LightningElement, api } from 'lwc';
import getOpportunitiesByType from '@salesforce/apex/DMT_Profitability_Helper.getOpportunitiesByType';
import getOpportunityDetails from '@salesforce/apex/DMT_Profitability_Helper.getOpportunityDetails';
import getProfitabilityCatalogValues from '@salesforce/apex/DMT_Profitability_Helper.getProfitabilityCatalogValues';
import getEntificEntityAndBookingRelationships from '@salesforce/apex/DMT_Profitability_Helper.getEntificEntityAndBookingRelationships';
import getPassportByOpp from '@salesforce/apex/DMT_Profitability_Helper.getPassportByOpp';
import calculateProfitabilityMatrix from '@salesforce/apex/DMT_Profitability_Helper.calculateProfitabilityMatrix';

const OPP_TYPE_CURRENT = 'current';
const OPP_TYPE_BASIC = 'basic';
const AMORTIZATION_USER_DEFINED = 'User-defined';
const BPS_MAX_VALUE = 999;

// DMT_Taxonomy_Values__c catalog ids for the axis-selector's rating inputs (see Fase 2 del plan).
const EXTERNAL_RATING_CATALOG_ID = 'C009';
const INTERNAL_RATING_CATALOG_ID = 'C204';
// Axis field API values that represent a rating axis (must match dmt_ProfitabilityAxisSelector's
// RATING_FIELD_VALUES: '2' = internal rating, '9' = external rating).
const INTERNAL_RATING_AXIS_VALUE = '2';
const EXTERNAL_RATING_AXIS_VALUE = '9';

/**
 * OpportunityLineItem.DMT_Line_Oneoffdeal__c value that marks a product as a revolving/committed
 * "Line" (as opposed to a 'One-off deal'). Scenario calculation is not supported for these
 * products, see isLineProduct / showLineProductWarning below.
 */
const LINE_PRODUCT_VALUE = 'Line';
const LINE_PRODUCT_WARNING_MESSAGE =
    'Scenario calculation unavailable for this product. Please choose a one-off-deal product';

/**
 * Field key map shared with c-dmt_profitabilitymatrix (see labelsOppDataFields /
 * labelsOverrideFields in dmt_profitabilitymatrix.js). Every editable field in the
 * 4 tabs is modeled as { original key on oppData/productData -> "...New" override key }.
 * Keys below match DMT_Profitability_Helper.OpportunityDetailsWrapper /
 * DMT_Profitability_Helper.ProductWrapper property names returned by getOpportunityDetails.
 */
const OPPORTUNITY_SELECT_FIELDS = [
    { key: 'entific', apiName: 'entificNew', label: 'Entific' },
    { key: 'entity', apiName: 'entityNew', label: 'Entity' },
    { key: 'internalRating', apiName: 'intClientRatingNew', label: 'Internal Client Rating' },
    { key: 'externalRating', apiName: 'extClientRatingNew', label: 'External Client Rating' },
    { key: 'clientType', apiName: 'clientTypeNew', label: 'Client Type' }
];
const OPPORTUNITY_NUMBER_FIELD = { key: 'scoring', apiName: 'ScoringNew', label: 'Scoring', step: 0.01 };
/**
 * Booking is sourced from OpportunityLineItem (productData) but is displayed on the
 * Opportunity fields tab, right after Entity, since its options cascade from Entity.
 */
const BOOKING_FIELD = { key: 'booking', apiName: 'bookingNew', label: 'Booking geography' };

/**
 * DMT_Taxonomy_Values__c catalog ids backing each opportunity/product select field.
 * 'entity' and 'booking' are omitted here: their options are resolved dynamically from the
 * H287 (Entific->Entity) / H291 (Entity->Booking) relationship maps instead of a flat catalog.
 */
const OPPORTUNITY_FIELD_CATALOGS = {
    entific: 'CD07',
    internalRating: 'C204',
    externalRating: 'C009',
    clientType: 'D971'
};
const ENTITY_CATALOG_ID = 'H006';
const ENTIFIC_ENTITY_RELATIONSHIP_ID = 'H287';
const ENTITY_BOOKING_RELATIONSHIP_ID = 'H291';

const PRODUCT_SELECT_FIELDS = [
    { key: 'currencyOli', apiName: 'currencyNew', label: 'Currency' },
    { key: 'countryRisk', apiName: 'countryRiskNew', label: 'Country Risk' }
];
const PRODUCT_FIELD_CATALOGS = {
    currencyOli: 'C264',
    countryRisk: 'C245'
};
const BOOKING_CATALOG_ID = 'H007';
const PRODUCT_TERM_FIELD = { key: 'oppTerm', apiName: 'termNew', label: 'Term' };

const AMORTIZATION_SELECT_FIELDS = [
    { key: 'amortizationType', apiName: 'amortizationTypeNew', label: 'Amortization Type' },
    { key: 'paymentFrequency', apiName: 'paymentFrequencyNew', label: 'Payment Frequency' }
];

const TENOR_NUMBER_FIELDS = [
    { key: 'nominalAmount', apiName: 'nominalAmountNew', label: 'Notional Amount Drawn', step: 0.01 },
    { key: 'nominalFb', apiName: 'nominalFbNew', label: 'Notional Amount Undrawn', step: 0.01 },
    { key: 'spreadAmount', apiName: 'spreadAmountNew', label: 'Spread Drawn', step: 0.01, max: BPS_MAX_VALUE },
    { key: 'spreadFb', apiName: 'spreadFbNew', label: 'Spread Undrawn', step: 0.01, max: BPS_MAX_VALUE },
    { key: 'accrualfee', apiName: 'accrualfeeNew', label: 'Accrual Fees', step: 0.01, max: BPS_MAX_VALUE },
    { key: 'nonaccrualfee', apiName: 'nonaccrualfeeNew', label: 'Non Accrual Fees', step: 0.01, max: BPS_MAX_VALUE }
];

export default class Dmt_profitabilityTestMain extends LightningElement {
    // ── Public API ───────────────────────────────────────────────────────
    @api clientId;
    @api groupCode;
    clientType;

    _pendingOppSelected = null;
    _pendingProductSelected = null;
    _isConnected = false;
    _contextVersion = 0;
    _detailsRequestVersion = 0;
    _productRequestVersion = 0;

    /**
     * Single-object entry point used by c-dmt_-d-m-t-deal-management-workspace
     * (bound as `parent-attribute`). Carries { ClientId, groupCode, clientType,
     * oppSelected, productSelected } and is re-set every time any of those values
     * change on the parent (e.g. deep-link via CurrentPageReference, or client switch).
     */
    @api
    get parentAttribute() {
        return this._parentAttribute;
    }
    set parentAttribute(value) {
       
        this._parentAttribute = value || {};
        if(this._parentAttribute){
console.log('**** parentAttribute setter',JSON.stringify( this._parentAttribute));
        }
         
        const { ClientId, groupCode, clientType, oppSelected, productSelected } = this._parentAttribute;

        const clientChanged = ClientId !== undefined && ClientId !== this.clientId;
        const groupChanged = groupCode !== undefined && groupCode !== this.groupCode;

        if (ClientId !== undefined) {
            this.clientId = ClientId;
        }
        if (groupCode !== undefined) {
            this.groupCode = groupCode;
        }
        if (clientType !== undefined) {
            this.clientType = clientType;
        }

        if (clientChanged || groupChanged) {
            this._resetUxState();
        }

        if (oppSelected !== undefined) {
            this.oppSelected = oppSelected;
        }
        if (productSelected !== undefined) {
            this.productSelected = productSelected;
        }

        if ((clientChanged || groupChanged) && this._isConnected) {
            this._loadOpportunities();
        }
    }

    @api
    get oppSelected() {
        return this._oppSelected;
    }
    set oppSelected(value) {
        this._pendingOppSelected = value || null;
        if (this.opportunitiesOptions.length) {
            this._applyPendingOppSelection();
        }
    }

    @api
    get productSelected() {
        return this._productSelected;
    }
    set productSelected(value) {
        this._pendingProductSelected = value || null;
        if (this.productsOptions.length) {
            this._applyPendingProductSelection();
        }
    }

    // ── Reactive state ───────────────────────────────────────────────────
    opportunityType = OPP_TYPE_CURRENT;

    isLoadingOpportunities = false;
    isLoadingDetails = false;
    isCalculating = false;

    opportunitiesOptions = [];
    productsOptions = [];

    _oppSelected = null;
    _productSelected = null;
    _lineItemsById = new Map();
    _opportunityExternalIdsById = new Map();
    _opportunityIdsByExternalId = new Map();

    oppData = {};
    productData = {};

    obsoletePassport = false;
    obsoletePassportMessage = '';
    obsoletePassportLinkMessage = '';

    opportunityFields = [];
    productFields = [];
    amortizationFields = [];
    tenorFields = [];

    // ── Taxonomy catalogs & relationships (loaded once, see _loadCatalogs) ──
    _catalogOptions = {};
    _entificToEntityMap = {};
    _entityToBookingMap = {};
    _catalogsReady = Promise.resolve();

    axisValid = false;
    axisValues = null;

    matrixReceivedData = null;
    matrixOverrideFields = null;
    matrixOppDataOriginal = null;

    popoverHeader = '';
    popoverMessage = '';
    popoverMessageTitle = '';
    popoverVariant = 'error';
    popoverTrigger = null;

    connectedCallback() {
        this._isConnected = true;
        this._catalogsReady = this._loadCatalogs();
        this._loadOpportunities();
        this._catalogsReady.then(() => {
            this._rebuildOpportunityFields();
            this._rebuildProductFields();
            this._rebuildAmortizationFields();
            this._rebuildTenorFields();
        });
    }

    disconnectedCallback() {
        this._isConnected = false;
        this._contextVersion += 1;
    }

    // ── Computed getters ─────────────────────────────────────────────────
    get isCurrentOpportunityType() {
        return this.opportunityType === OPP_TYPE_CURRENT;
    }
    get variantCurrent() {
        return this.isCurrentOpportunityType ? 'brand' : 'neutral';
    }
    get variantBasic() {
        return this.isCurrentOpportunityType ? 'neutral' : 'brand';
    }
    get hasOpportunities() {
        return this.opportunitiesOptions.length > 0;
    }
    get hasProductSelected() {
        return !!this._productSelected;
    }
    get isLineProduct() {
        return this.productData?.lineOneOffDeal === LINE_PRODUCT_VALUE;
    }
    get showLineProductWarning() {
        return this.hasProductSelected && this.isLineProduct;
    }
    get lineProductWarningMessage() {
        return LINE_PRODUCT_WARNING_MESSAGE;
    }
    get showObsoletePassport() {
        return !!this._oppSelected && this.obsoletePassport;
    }
    get selectedOpportunityExternalId() {
        return this._opportunityExternalIdsById.get(this._oppSelected) || '';
    }
    get amortizationTypeValue() {
        return this.productData?.amortizationType || '';
    }
    get isAmortizationUserDefined() {
        return this.amortizationTypeValue === AMORTIZATION_USER_DEFINED;
    }
    get amortizationMessage() {
        return `Amortization fields are not available for Opportunity with Amortization Type : ${this.amortizationTypeValue}`;
    }
    get tenorMessage() {
        return `Tenor fields are not available for Opportunity with Amortization Type : ${this.amortizationTypeValue}`;
    }
    get isCalculateDisabled() {
        return this.isCalculating || !this._oppSelected || !this._productSelected || !this.selectedOpportunityExternalId || this.isLineProduct || !this.axisValid || this.obsoletePassport;
    }
    get isProductSelectorDisabled() {
        return this.isLoadingDetails || this.productsOptions.length <= 1;
    }
    get currentNominalAmountNew() {
        return this._fieldValueByApiName(this.tenorFields, 'nominalAmountNew');
    }
    get currentNominalFbNew() {
        return this._fieldValueByApiName(this.tenorFields, 'nominalFbNew');
    }
    get mergedOppSelectedData() {
        // FlexCard retirado: dmt_ProfitabilityAxisSelector acepta ahora un objeto nativo
        // directamente (ver su setter oppSelectedData), ya no hace falta JSON.stringify.
        return { ...this.oppData, ...this.productData };
    }
    get catalogRatingOptions() {
        return this._catalogOptions[EXTERNAL_RATING_CATALOG_ID] || [];
    }
    get catalogInternalRatingOptions() {
        return this._catalogOptions[INTERNAL_RATING_CATALOG_ID] || [];
    }

    // ── Opportunity type toggle ──────────────────────────────────────────
    handleOpportunityTypeChange(event) {
        const newType = event.currentTarget.dataset.value;
        if (newType === this.opportunityType) {
            return;
        }
        this._resetUxState();
        this.opportunityType = newType;
        this._loadOpportunities();
    }

    _resetUxState() {
        this._contextVersion += 1;
        this._detailsRequestVersion += 1;
        this._productRequestVersion += 1;

        this.opportunityType = OPP_TYPE_CURRENT;
        this._pendingOppSelected = null;
        this._pendingProductSelected = null;
        this._oppSelected = null;
        this._productSelected = null;
        this.opportunitiesOptions = [];
        this.productsOptions = [];
        this._lineItemsById = new Map();
        this._opportunityExternalIdsById = new Map();
        this._opportunityIdsByExternalId = new Map();
        this.oppData = {};
        this.productData = {};

        this.obsoletePassport = false;
        this.obsoletePassportMessage = '';
        this.obsoletePassportLinkMessage = '';

        this.opportunityFields = [];
        this.productFields = [];
        this.amortizationFields = [];
        this.tenorFields = [];
        this.axisValid = false;
        this.axisValues = null;

        this.matrixReceivedData = null;
        this.matrixOverrideFields = null;
        this.matrixOppDataOriginal = null;

        this.popoverHeader = '';
        this.popoverMessage = '';
        this.popoverMessageTitle = '';
        this.popoverVariant = 'error';
        this.popoverTrigger = null;

        this.isLoadingOpportunities = false;
        this.isLoadingDetails = false;
        this.isCalculating = false;

        this.refs?.axisSelector?.reset?.();
        this.refs?.matrix?.reset?.();
        this.refs?.popover?.reset?.();

        const contextVersion = this._contextVersion;
        this._rebuildOpportunityFields(contextVersion);
        this._rebuildProductFields(contextVersion);
        this._rebuildAmortizationFields(contextVersion);
        this._rebuildTenorFields(contextVersion);
    }

    // ── Opportunity / product selection ──────────────────────────────────
    handleOppChange(event) {
        this._selectOpportunity(event.detail.value);
    }

    handleProductChange(event) {
        this._selectProduct(event.detail.value);
    }

    async _selectOpportunity(oppId) {
        const contextVersion = this._contextVersion;
        const requestVersion = ++this._detailsRequestVersion;
        this._productRequestVersion += 1;
        this._oppSelected = oppId || null;
        this._productSelected = null;
        this.productsOptions = [];
        this.productData = {};
        this._lineItemsById = new Map();

        if (!this._oppSelected) {
            this.oppData = {};
            await this._rebuildOpportunityFields();
            await this._rebuildProductFields();
            await this._rebuildAmortizationFields();
            await this._rebuildTenorFields();
            return;
        }

        this.isLoadingDetails = true;
        try {
            const [details, passport] = await Promise.all([
                getOpportunityDetails({ oppId: this._oppSelected }),
                this._checkObsoletePassport(this._oppSelected)
            ]);
            if (contextVersion !== this._contextVersion || requestVersion !== this._detailsRequestVersion) {
                return;
            }
            const products = details.products || [];
            this._lineItemsById = new Map(products.map((product) => [product.productId, product]));
            this.productsOptions = products.map((product) => ({ label: product.name, value: product.productId }));
            this.oppData = details;
            this.obsoletePassport = passport.obsolete;
            this.obsoletePassportMessage = passport.message;
            this.obsoletePassportLinkMessage = passport.linkMessage;

            await this._rebuildOpportunityFields();
            await this._rebuildProductFields();
            await this._rebuildAmortizationFields();
            await this._rebuildTenorFields();

            if (contextVersion !== this._contextVersion || requestVersion !== this._detailsRequestVersion) {
                return;
            }
            if (products.length === 1) {
                await this._selectProduct(products[0].productId);
            } else {
                this._applyPendingProductSelection();
            }
        } finally {
            if (contextVersion === this._contextVersion && requestVersion === this._detailsRequestVersion) {
                this.isLoadingDetails = false;
            }
        }
    }

    async _selectProduct(productId) {
        const contextVersion = this._contextVersion;
        const requestVersion = ++this._productRequestVersion;
        this._productSelected = productId || null;

        if (!this._productSelected) {
            this.productData = {};
            await this._rebuildOpportunityFields();
            await this._rebuildProductFields();
            await this._rebuildAmortizationFields();
            await this._rebuildTenorFields();
            return;
        }

        this.isLoadingDetails = true;
        try {
            const productData = await this._fetchProductData(this._productSelected);
            if (contextVersion !== this._contextVersion || requestVersion !== this._productRequestVersion) {
                return;
            }
            this.productData = productData;
            await this._rebuildOpportunityFields();
            await this._rebuildProductFields();
            await this._rebuildAmortizationFields();
            await this._rebuildTenorFields();
        } finally {
            if (contextVersion === this._contextVersion && requestVersion === this._productRequestVersion) {
                this.isLoadingDetails = false;
            }
        }
    }

    _applyPendingOppSelection() {
        if (this._pendingOppSelected && this._pendingOppSelected !== this._oppSelected) {
            const pendingOppId = this._pendingOppSelected;
            this._pendingOppSelected = null;
            const oppId = this.opportunitiesOptions.some((option) => option.value === pendingOppId)
                ? pendingOppId
                : this._opportunityIdsByExternalId.get(pendingOppId);
            if (oppId) {
                this._selectOpportunity(oppId);
            }
        }
    }

    _applyPendingProductSelection() {
        if (this._pendingProductSelected && this._pendingProductSelected !== this._productSelected) {
            const productId = this._pendingProductSelected;
            this._pendingProductSelected = null;
            if (this.productsOptions.some((option) => option.value === productId)) {
                this._selectProduct(productId);
            }
        }
    }


    async _loadOpportunities() {
        const contextVersion = this._contextVersion;
        this.isLoadingOpportunities = true;
        try {
            const result = await this._fetchOpportunities();
            if (contextVersion !== this._contextVersion) {
                return;
            }
            this.opportunitiesOptions = result.options;
            this._opportunityExternalIdsById = result.externalIdsById;
            this._opportunityIdsByExternalId = result.idsByExternalId;
            this._applyPendingOppSelection();
        } finally {
            if (contextVersion === this._contextVersion) {
                this.isLoadingOpportunities = false;
            }
        }
    }

    // ── Tab field builders ───────────────────────────────────────────────
    async _rebuildOpportunityFields(contextVersion = this._contextVersion) {
        await this._catalogsReady;
        if (contextVersion !== this._contextVersion) {
            return;
        }
        const data = this.oppData || {};
        const productData = this.productData || {};
        const fields = [];
        OPPORTUNITY_SELECT_FIELDS.forEach((def) => {
            if (def.key === 'entity') {
                fields.push(this._buildPicklistField(def, data, this._getEntityOptions(data.entific), '1-of-3'));
                fields.push(this._buildPicklistField(BOOKING_FIELD, productData, this._getBookingOptions(data.entity), '1-of-3'));
                return;
            }
            const options = this._catalogOptions[OPPORTUNITY_FIELD_CATALOGS[def.key]] || [];
            fields.push(this._buildPicklistField(def, data, options, '1-of-3'));
        });
        const numberField = this._buildNumberField(OPPORTUNITY_NUMBER_FIELD, data, '1-of-3');
        this.opportunityFields = [...fields, numberField];
    }

    async _rebuildProductFields(contextVersion = this._contextVersion) {
        await this._catalogsReady;
        if (contextVersion !== this._contextVersion) {
            return;
        }
        const data = this.productData || {};
        const fields = [];

        if (this.isCurrentOpportunityType) {
            fields.push(
                this._buildDateField({ key: 'initialDate', apiName: 'startDateNew', label: 'Initial Date' }, data, '1-of-2'),
                this._buildDateField({ key: 'maturityDate', apiName: 'endDateNew', label: 'Maturity Date' }, data, '1-of-2')
            );
        } else {
            fields.push(this._buildNumberField(PRODUCT_TERM_FIELD, data, '1-of-2'));
        }

        PRODUCT_SELECT_FIELDS.forEach((def) => {
            const options = this._catalogOptions[PRODUCT_FIELD_CATALOGS[def.key]] || [];
            fields.push(this._buildPicklistField(def, data, options, '1-of-2'));
        });
        this.productFields = fields;
    }

    async _rebuildAmortizationFields(contextVersion = this._contextVersion) {
        if (this.isAmortizationUserDefined) {
            this.amortizationFields = [];
            return;
        }
        const options = await this._fetchAmortizationFieldOptions();
        if (contextVersion !== this._contextVersion) {
            return;
        }
        const data = this.productData || {};
        this.amortizationFields = AMORTIZATION_SELECT_FIELDS.map((def) =>
            this._buildPicklistField(def, data, options, '1-of-2')
        );
    }

    async _rebuildTenorFields(contextVersion = this._contextVersion) {
        if (contextVersion !== this._contextVersion) {
            return;
        }
        if (this.isAmortizationUserDefined) {
            this.tenorFields = [];
            return;
        }
        const data = this.productData || {};
        this.tenorFields = TENOR_NUMBER_FIELDS.map((def) => this._buildNumberField(def, data, '1-of-3'));
    }

    _buildPicklistField(def, data, options, size) {
        const originalValue = data[def.key] ?? '';
        return {
            id: def.apiName,
            apiName: def.apiName,
            label: def.label,
            type: 'picklist',
            value: originalValue,
            originalValue,
            overridable: true,
            options,
            size
        };
    }

    _buildNumberField(def, data, size) {
        const originalValue = data[def.key] ?? null;
        return {
            id: def.apiName,
            apiName: def.apiName,
            label: def.label,
            type: 'number',
            value: originalValue,
            originalValue,
            overridable: true,
            step: def.step,
            max: def.max,
            size
        };
    }

    _buildDateField(def, data, size) {
        const originalValue = data[def.key] ?? null;
        return {
            id: def.apiName,
            apiName: def.apiName,
            label: def.label,
            type: 'date',
            value: originalValue,
            originalValue,
            overridable: true,
            size
        };
    }

    _fieldValueByApiName(fields, apiName) {
        const field = (fields || []).find((f) => f.apiName === apiName);
        return field ? field.value : null;
    }

    // ── Taxonomy catalogs & cascading relationships ───────────────────────
    async _loadCatalogs() {
        const [catalogOptions, relationships] = await Promise.all([
            getProfitabilityCatalogValues(),
            getEntificEntityAndBookingRelationships()
        ]);
        this._catalogOptions = catalogOptions || {};
        this._entificToEntityMap = (relationships && relationships[ENTIFIC_ENTITY_RELATIONSHIP_ID]) || {};
        this._entityToBookingMap = (relationships && relationships[ENTITY_BOOKING_RELATIONSHIP_ID]) || {};
    }

    _getEntityOptions(entificValue) {
        if (entificValue && this._entificToEntityMap[entificValue]) {
            return this._entificToEntityMap[entificValue];
        }
        return this._catalogOptions[ENTITY_CATALOG_ID] || [];
    }

    _getBookingOptions(entityValue) {
        if (entityValue && this._entityToBookingMap[entityValue]) {
            return this._entityToBookingMap[entityValue];
        }
        return this._catalogOptions[BOOKING_CATALOG_ID] || [];
    }

    _refreshEntityOptions(entificValue) {
        const arr = this.opportunityFields || [];
        const idx = arr.findIndex((f) => f.apiName === 'entityNew');
        if (idx === -1) {
            return;
        }
        const entityOptions = this._getEntityOptions(entificValue);
        const validValues = new Set(entityOptions.map((opt) => opt.value));
        const current = arr[idx];
        const nextValue = validValues.has(current.value) ? current.value : '';
        const updated = arr.slice();
        updated[idx] = { ...current, options: entityOptions, value: nextValue };
        this.opportunityFields = updated;

        // Entity may have just changed (or been cleared) as a side effect: cascade to Booking too.
        this._refreshBookingOptions(nextValue);
    }

    _refreshBookingOptions(entityValue) {
        const arr = this.opportunityFields || [];
        const idx = arr.findIndex((f) => f.apiName === 'bookingNew');
        if (idx === -1) {
            return;
        }
        const bookingOptions = this._getBookingOptions(entityValue);
        const validValues = new Set(bookingOptions.map((opt) => opt.value));
        const current = arr[idx];
        const nextValue = validValues.has(current.value) ? current.value : '';
        const updated = arr.slice();
        updated[idx] = { ...current, options: bookingOptions, value: nextValue };
        this.opportunityFields = updated;
    }

    // ── Field change handlers (from c-dmt_form_renderer instances) ───────
    handleOpportunityFieldChange(event) {
        const detail = event.detail;
        this._updateFieldArray('opportunityFields', detail);

        if (detail.fieldId === 'entificNew') {
            this._refreshEntityOptions(detail.value);
        } else if (detail.fieldId === 'entityNew') {
            this._refreshBookingOptions(detail.value);
        }
    }
    handleProductFieldChange(event) {
        this._updateFieldArray('productFields', event.detail);
    }
    handleAmortizationFieldChange(event) {
        this._updateFieldArray('amortizationFields', event.detail);
    }
    handleTenorFieldChange(event) {
        this._updateFieldArray('tenorFields', event.detail);
    }

    _updateFieldArray(propName, detail) {
        const arr = this[propName];
        const idx = arr.findIndex((f) => f.id === detail.fieldId);
        if (idx === -1) {
            return;
        }
        const updated = arr.slice();
        updated[idx] = { ...updated[idx], value: detail.value };
        this[propName] = updated;
    }

    // ── Axis selector ─────────────────────────────────────────────────────
    handleAxisChange(event) {
        const detail = event.detail || {};
        this.axisValues = detail;
        // disabledCalculate is the single source of truth dispatched by
        // dmt_ProfitabilityAxisSelector._dispatchChangeEvent() — there is no separate `isValid`
        // flag on this event.
        this.axisValid = !detail.disabledCalculate;
    }

    // ── Calculate flow ────────────────────────────────────────────────────
    handleCalculate() {
        const { isValid, invalidFields } = this._validateAllSections();

        if (!isValid) {
            this._showPopover(
                'error',
                'Validation error',
                invalidFields.length
                    ? `Please review: ${invalidFields.join(', ')}`
                    : 'Please complete the required fields and axis selection before calculating.'
            );
            return;
        }

        const contextVersion = this._contextVersion;
        this.isCalculating = true;
        this._calculate(this._buildCalculateRequest())
            .then((result) => {
                if (contextVersion !== this._contextVersion) {
                    return;
                }
                this.matrixReceivedData = result.receivedData;
                this.matrixOverrideFields = result.overrideFields;
                this.matrixOppDataOriginal = result.oppDataOriginal;
            })
            .catch((error) => {
                if (contextVersion !== this._contextVersion) {
                    return;
                }
                this._showPopover(
                    'error',
                    'Calculation error',
                    error?.body?.message || error?.message || 'The profitability calculation failed.'
                );
            })
            .finally(() => {
                if (contextVersion === this._contextVersion) {
                    this.isCalculating = false;
                }
            });
    }

    _validateAllSections() {
        const renderers = [
            this.refs.oppFieldsRenderer,
            this.refs.productFieldsRenderer,
            !this.isAmortizationUserDefined ? this.refs.amortFieldsRenderer : null,
            !this.isAmortizationUserDefined ? this.refs.tenorFieldsRenderer : null
        ].filter(Boolean);

        const results = renderers.map((r) => r.validate());
        const invalidFields = results.flatMap((r) => r.invalidFields || []);
        const isValid = results.every((r) => r.isValid !== false) && this.axisValid;

        return { isValid, invalidFields };
    }

    _buildCalculateRequest() {
        const axis = this.axisValues || {};
        return {
            // The profitability service expects Opportunity.DMT_Opp_Id__c, not the Salesforce record Id.
            oppId: this.selectedOpportunityExternalId,
            // The selector is keyed by the Salesforce OpportunityLineItem Id, while the
            // profitability service requires its business group-priority identifier.
            prodId: this._getSelectedProductGroupPriorityId(),
            // TODO(apex): opportunityVersion isn't tracked anywhere in this flow yet (the FlexCard
            // used an OmniScript state variable, `action.oppDataVersion`, with no direct equivalent
            // here). Defaulting to '1' until a real optimistic-concurrency source is defined.
            version: '1',
            axisX: axis.xSelectedLabel || '',
            axisY: axis.ySelectedLabel || '',
            axisCentral: axis.centralSelectedLabel || '',
            axisX_Id: axis.xSelected || '',
            axisY_Id: axis.ySelected || '',
            minX: axis.xMin || '',
            maxX: axis.xRange || '',
            minY: axis.yMin || '',
            maxY: axis.yRange || '',
            catalogRating: this._resolveRequestRatingCatalog(axis),
            overrideFields: {
                ...this._fieldsArrayToMap(this.opportunityFields),
                ...this._fieldsArrayToMap(this.productFields),
                ...this._fieldsArrayToMap(this.amortizationFields),
                ...this._fieldsArrayToMap(this.tenorFields)
            }
        };
    }

    _getSelectedProductGroupPriorityId() {
        return this._lineItemsById.get(this._productSelected)?.groupPriorityOpportunityId || '';
    }

    // Resolves the rating catalog (internal C204 / external C009) matching whichever axis (X or Y)
    // was selected as a rating field, per DMT_ProfitabilityMatrix_Wrapper.validateInputsRequest.
    _resolveRequestRatingCatalog(axis) {
        if (axis.xSelected === INTERNAL_RATING_AXIS_VALUE || axis.ySelected === INTERNAL_RATING_AXIS_VALUE) {
            return this.catalogInternalRatingOptions;
        }
        if (axis.xSelected === EXTERNAL_RATING_AXIS_VALUE || axis.ySelected === EXTERNAL_RATING_AXIS_VALUE) {
            return this.catalogRatingOptions;
        }
        return [];
    }

    _fieldsArrayToMap(fields) {
        return (fields || []).reduce((map, f) => {
            if (this._isFieldOverridden(f)) {
                map[f.apiName] = f.value;
            }
            return map;
        }, {});
    }

    _isFieldOverridden(field) {
        const originalValue = field.originalValue;
        const isStructuredOriginal = originalValue !== null
            && originalValue !== undefined
            && typeof originalValue === 'object'
            && !Array.isArray(originalValue)
            && 'value' in originalValue;

        let currentComparable = field.value;
        let originalComparable = isStructuredOriginal ? originalValue.value : originalValue;

        if (isStructuredOriginal && 'compareValue' in originalValue && Array.isArray(field.options)) {
            const currentOption = field.options.find((option) => String(option.value) === String(field.value));
            currentComparable = currentOption?.name ?? field.value;
            originalComparable = originalValue.compareValue;
        }

        // Treat null/undefined/blank as the same empty value and number/string equivalents alike.
        return String(currentComparable ?? '') !== String(originalComparable ?? '');
    }

    _showPopover(variant, header, message) {
        this.popoverVariant = variant;
        this.popoverHeader = header;
        this.popoverMessage = message;
        this.popoverMessageTitle = header;
        this.popoverTrigger = Date.now();
    }

    // ── Data layer ────────────────────────────────────────────────────
    async _fetchOpportunities() {
        const isDraft = this.opportunityType === OPP_TYPE_BASIC;
        const opps = await getOpportunitiesByType({
            clientId: this.clientId,
            groupCode: this.groupCode,
            isDraft
        });
        return {
            externalIdsById: new Map((opps || []).map((opp) => [opp.Id, opp.DMT_Opp_Id__c || ''])),
            idsByExternalId: new Map(
                (opps || [])
                    .filter((opp) => opp.DMT_Opp_Id__c)
                    .map((opp) => [opp.DMT_Opp_Id__c, opp.Id])
            ),
            options: (opps || []).map((opp) => ({ label: opp.Name, value: opp.Id }))
        };
    }

    _fetchProductData(productId) {
        const lineItem = this._lineItemsById.get(productId) || {};
        return Promise.resolve({ ...lineItem, oppTerm: this.oppData?.oppTerm ?? null });
    }

    // TODO(apex): wire to DMT_Profitability_Helper.getTaxonomyValues() or a dedicated
    // catalog per field once the real picklist source is confirmed.
    _fetchAmortizationFieldOptions() {
        return Promise.resolve([
            { label: 'Linear', value: 'Linear' },
            { label: 'Bullet', value: 'Bullet' },
            { label: AMORTIZATION_USER_DEFINED, value: AMORTIZATION_USER_DEFINED }
        ]);
    }

    // Wired to DMT_Profitability_Helper.getPassportByOpp(oppId) (already @AuraEnabled), checking
    // DMT_Is_Obsoleted_Passport_Save__c on the returned Passport__c record.
    async _checkObsoletePassport(oppId) {
        try {
            const passport = await getPassportByOpp({ oppId });
            const obsolete = !!passport?.DMT_Is_Obsoleted_Passport_Save__c;
            return {
                obsolete,
                message: obsolete ? 'The Passport used for this Opportunity is obsolete.' : '',
                linkMessage: obsolete ? passport?.Id : ''
            };
        } catch (error) {
            console.error('Error checking obsolete passport', error);
            return { obsolete: false, message: '', linkMessage: '' };
        }
    }

    // Wired to DMT_Profitability_Helper.calculateProfitabilityMatrix (new @AuraEnabled wrapper
    // around the OmniStudio "callProfitabilityMatrix" Apex Remote action, DMT_Profitability_Handler),
    // reusing the same backend logic FlexCards used before their retirement.
    async _calculate(request) {
        const outMap = await calculateProfitabilityMatrix({ inputMap: request });
        if (outMap?.result === false) {
            const error = new Error(outMap.message || 'The profitability calculation failed.');
            error.messageTitle = outMap.messageTitle || 'Calculation error';
            throw error;
        }
        const body = typeof outMap.bodyResponse === 'string' ? JSON.parse(outMap.bodyResponse) : outMap.bodyResponse;
        return {
            receivedData: body,
            overrideFields: request.overrideFields,
            oppDataOriginal: { ...this.oppData, ...this.productData }
        };
    }
}