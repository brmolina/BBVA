import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { deleteRecord } from 'lightning/uiRecordApi';
import LightningConfirm from 'lightning/confirm';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import getUnderlyingOptions from '@salesforce/apex/DMT_OpportunityProductsController.getUnderlyingOptions';
import getCurrencyValues from '@salesforce/apex/DMT_MitigantsController.getCurrencyValues';
import getCurrencyLabel from '@salesforce/apex/DMT_Currency_Conversion_Utils.getCurrencyLabel';
import DMT_UNDERLYING_OBJECT from '@salesforce/schema/DMT_Underlying__c';
import DMT_AMORTIZATION_TYPE_FIELD from '@salesforce/schema/DMT_Underlying__c.DMT_Amortization_Type__c';
import DMT_INTEREST_PAYMENT_FREQUENCY_FIELD from '@salesforce/schema/DMT_Underlying__c.DMT_Interest_Payment_Frequency__c';

const TERM_OPTIONS = [
    { value: '7',     label: '1 week'     },
    { value: '15',    label: '2 weeks'    },
    { value: '21',    label: '3 weeks'    },
    { value: '31',    label: '1 month'    },
    { value: '62',    label: '2 months'   },
    { value: '92',    label: '3 months'   },
    { value: '122',   label: '4 months'   },
    { value: '153',   label: '5 months'   },
    { value: '183',   label: '6 months'   },
    { value: '214',   label: '7 months'   },
    { value: '244',   label: '8 months'   },
    { value: '275',   label: '9 months'   },
    { value: '305',   label: '10 months'  },
    { value: '336',   label: '11 months'  },
    { value: '366',   label: '1 year'     },
    { value: '397',   label: '13 months'  },
    { value: '424',   label: '14 months'  },
    { value: '454',   label: '15 months'  },
    { value: '484',   label: '16 months'  },
    { value: '514',   label: '17 months'  },
    { value: '545',   label: '1,5 years'  },
    { value: '575',   label: '19 months'  },
    { value: '605',   label: '20 months'  },
    { value: '635',   label: '21 months'  },
    { value: '666',   label: '22 months'  },
    { value: '696',   label: '23 months'  },
    { value: '726',   label: '2 years'    },
    { value: '756',   label: '25 months'  },
    { value: '787',   label: '26 months'  },
    { value: '817',   label: '27 months'  },
    { value: '847',   label: '28 months'  },
    { value: '877',   label: '29 months'  },
    { value: '908',   label: '2,5 years'  },
    { value: '938',   label: '31 months'  },
    { value: '968',   label: '32 months'  },
    { value: '998',   label: '33 months'  },
    { value: '1029',  label: '34 months'  },
    { value: '1059',  label: '35 months'  },
    { value: '1089',  label: '3 years'    },
    { value: '1119',  label: '37 months'  },
    { value: '1150',  label: '38 months'  },
    { value: '1180',  label: '39 months'  },
    { value: '1210',  label: '40 months'  },
    { value: '1240',  label: '41 months'  },
    { value: '1271',  label: '3,5 years'  },
    { value: '1301',  label: '43 months'  },
    { value: '1331',  label: '44 months'  },
    { value: '1361',  label: '45 months'  },
    { value: '1392',  label: '46 months'  },
    { value: '1422',  label: '47 months'  },
    { value: '1452',  label: '4 years'    },
    { value: '1482',  label: '49 months'  },
    { value: '1513',  label: '50 months'  },
    { value: '1543',  label: '51 months'  },
    { value: '1573',  label: '52 months'  },
    { value: '1603',  label: '53 months'  },
    { value: '1634',  label: '4,5 years'  },
    { value: '1664',  label: '55 months'  },
    { value: '1694',  label: '56 months'  },
    { value: '1724',  label: '57 months'  },
    { value: '1755',  label: '58 months'  },
    { value: '1785',  label: '59 months'  },
    { value: '1815',  label: '5 years'    },
    { value: '1918',  label: '5,25 years' },
    { value: '2009',  label: '5,5 years'  },
    { value: '2100',  label: '5,75 years' },
    { value: '2192',  label: '6 years'    },
    { value: '2283',  label: '6,25 years' },
    { value: '2374',  label: '6,5 years'  },
    { value: '2465',  label: '6,75 years' },
    { value: '2557',  label: '7 years'    },
    { value: '2648',  label: '7,25 years' },
    { value: '2739',  label: '7,5 years'  },
    { value: '2831',  label: '7,75 years' },
    { value: '2922',  label: '8 years'    },
    { value: '3013',  label: '8,25 years' },
    { value: '3105',  label: '8,5 years'  },
    { value: '3196',  label: '8,75 years' },
    { value: '3287',  label: '9 years'    },
    { value: '3379',  label: '9,25 years' },
    { value: '3470',  label: '9,5 years'  },
    { value: '3561',  label: '9,75 years' },
    { value: '3653',  label: '10 years'   },
    { value: '3835',  label: '10,5 years' },
    { value: '4018',  label: '11 years'   },
    { value: '4200',  label: '11,5 years' },
    { value: '4383',  label: '12 years'   },
    { value: '4566',  label: '12,5 years' },
    { value: '4748',  label: '13 years'   },
    { value: '4931',  label: '13,5 years' },
    { value: '5114',  label: '14 years'   },
    { value: '5296',  label: '14,5 years' },
    { value: '5479',  label: '15 years'   },
    { value: '5844',  label: '16 years'   },
    { value: '6209',  label: '17 years'   },
    { value: '6575',  label: '18 years'   },
    { value: '6940',  label: '19 years'   },
    { value: '7305',  label: '20 years'   },
    { value: '7670',  label: '21 years'   },
    { value: '8036',  label: '22 years'   },
    { value: '8401',  label: '23 years'   },
    { value: '8766',  label: '24 years'   },
    { value: '9131',  label: '25 years'   },
    { value: '9497',  label: '26 years'   },
    { value: '9862',  label: '27 years'   },
    { value: '10227', label: '28 years'   },
    { value: '10592', label: '29 years'   },
    { value: '10958', label: '30 years'   },
    { value: '11323', label: '31 years'   },
    { value: '11688', label: '32 years'   },
    { value: '12053', label: '33 years'   },
    { value: '12419', label: '34 years'   },
    { value: '12784', label: '35 years'   }
];

const MODE_UNDRAWN = 'UNDRAWN';
const TEMP_ID_PREFIX = 'NEW_';
const UNDERLYING_TYPE_RESTRICTION = 'Restriction';
const UNDERLYING_TYPE_PROFITABILITY = 'Profitability';
const LOOKUP_INITIAL_VISIBLE_OPTIONS = 5;
const ALLOWED_PRODUCT_CODES = ['1010100000', '1010101100', '1012100000'];
const AUTO_MANUAL_CURRENCIES = new Set(['EUR', 'USD', 'GBP']);
const UPFRONT_FEES_FIELD = '_upfrontFeesValue';
const UPFRONT_FEES_UNIT_FIELD = '_upfrontFeesUnitDisplay';
const UPFRONT_UNIT_AMOUNT = 'Amount';
const UPFRONT_UNIT_BPS = 'BPS';
const UPFRONT_UNIT_OPTIONS = [
    { label: UPFRONT_UNIT_AMOUNT, value: UPFRONT_UNIT_AMOUNT },
    { label: UPFRONT_UNIT_BPS, value: UPFRONT_UNIT_BPS }
];
const SUPPORTED_UNDERLYING_TYPES = new Set([
    UNDERLYING_TYPE_RESTRICTION,
    UNDERLYING_TYPE_PROFITABILITY
]);

const BUSINESS_FIELDS = [
    'Name',
    'DMT_Underlying_Type__c',
    'DMT_Max_Amount__c',
    'DMT_Max_Term__c',
    'DMT_Other_restrictions__c',
    'DMT_Drawn_Reference_Amount__c',
    'DMT_Undrawn_Reference_Amount__c',
    'DMT_Term__c',
    'DMT_Drawn_Speed__c',
    'DMT_Undrawn_Spread__c',
    'DMT_Upfront_Fees__c',
    'DMT_Upfront_Fees_amount__c',
    'DMT_Amortization_Type__c',
    'DMT_Interest_Payment_Frequency__c',
    'DMT_Currency__c',
    'DMT_Opportunity_Product__c'
];

const NON_NEGATIVE_FIELDS = new Set([
    'DMT_Max_Amount__c',
    'DMT_Drawn_Reference_Amount__c',
    'DMT_Undrawn_Reference_Amount__c',
    'DMT_Drawn_Speed__c',
    'DMT_Undrawn_Spread__c',
    UPFRONT_FEES_FIELD,
    'DMT_Upfront_Fees__c',
    'DMT_Upfront_Fees_amount__c'
]);

const COLUMN_WIDTHS = {
    Name                    : 200,
    DMT_Max_Amount__c       : 200,
    DMT_Max_Term__c         : 160,
    DMT_Other_restrictions__c: 250,
    DMT_Drawn_Reference_Amount__c: 240,
    DMT_Undrawn_Reference_Amount__c: 240,
    DMT_Term__c             : 140,
    DMT_Drawn_Speed__c      : 160,
    DMT_Undrawn_Spread__c   : 175,
    [UPFRONT_FEES_FIELD]    : 200,
    [UPFRONT_FEES_UNIT_FIELD]: 140,
    DMT_Amortization_Type__c: 180,
    DMT_Interest_Payment_Frequency__c: 220,
    DMT_Currency__c         : 120,
    button                  : 60
};


export default class DmtOppProductDetailsLineUnderlyings extends LightningElement {

    @api oppProduct;
    @api referenceUpfrontFees;
    @api productCode;

    _isEditMode = false;
    _canEdit    = true;
    _data       = [];
    _opportunityCurrency = '';
    _currencyLabels     = {};

    get isReadOnly() { return !this._canEdit; }

    @api get opportunityCurrency() { return this._opportunityCurrency; }
    set opportunityCurrency(value) {
        const normalized = value || '';
        const changed = normalized !== this._opportunityCurrency;
        this._opportunityCurrency = normalized;
        this._ensureCurrencyLabel(this._opportunityCurrency);
    }

    get opportunityCurrencyLabel() {
        return this._currencyLabels[this._opportunityCurrency] || this._opportunityCurrency;
    }

    @api get data() { return this._data; }
    set data(value) {
        this._data = Array.isArray(value) ? value : [];
        if (this._snapshot) return;
        this._loadFromData();
    }

    @track rows                    = [];
    @track displayRestrictionRows  = [];
    @track displayProfitabilityRows = [];
    @track restrictionColumns      = [];
    @track profitabilityColumns    = [];
    @track isLoading               = false;
    @track renderRestrictionTable  = true;
    @track renderProfitabilityTable = true;

    _snapshot      = null;
    _tempIdCounter = 0;
    _maxTermOptions = TERM_OPTIONS;
    _currencyOptions = [];
    _termOptions = TERM_OPTIONS;
    _amortizationTypeOptions = [];
    _interestPaymentFrequencyOptions = [];
    _defaultRecordTypeId;

    @track _dropdownOpen    = false;
    @track _dropdownOptions = [];
    _dropdownAllOptions     = [];
    _dropdownSearchTerm     = '';
    _dropdownVisibleCount   = LOOKUP_INITIAL_VISIBLE_OPTIONS;
    _dropdownLeft           = 0;
    _dropdownBottom         = 0;
    _dropdownWidth          = 0;
    _dropdownCtx            = null;
    _underlyingOptions      = [];
    _modeByLabel            = new Map();
    _underlyingOptionsLoadedFor = null;
    _isUnderlyingLookup = false;
    _onDocClick             = (event) => {
        if (this.template?.contains(event?.target)) {
            return;
        }
        const path = event?.composedPath?.() || [];
        if (path.includes(this.template?.host)) {
            return;
        }
        this._dropdownOpen = false;
    };
    _onWinScroll            = () => { this._dropdownOpen = false; };

    @wire(getObjectInfo, { objectApiName: DMT_UNDERLYING_OBJECT })
    wiredObjectInfo({ data }) {
        if (data) {
            this._defaultRecordTypeId = data.defaultRecordTypeId;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$_defaultRecordTypeId', fieldApiName: DMT_AMORTIZATION_TYPE_FIELD })
    wiredAmortizationTypeOptions({ data }) {
        if (!data) return;
        this._amortizationTypeOptions = data.values.map(v => ({ label: v.label, value: v.value }));
        this._rebuildColumns();
    }

    @wire(getPicklistValues, { recordTypeId: '$_defaultRecordTypeId', fieldApiName: DMT_INTEREST_PAYMENT_FREQUENCY_FIELD })
    wiredInterestPaymentFrequencyOptions({ data }) {
        if (!data) return;
        this._interestPaymentFrequencyOptions = data.values.map(v => ({ label: v.label, value: v.value }));
        this._rebuildColumns();
    }

    @wire(getCurrencyValues)
    wiredCurrencies({ data }) {
        if (!Array.isArray(data)) {
        this._currencyOptions = [];
    } else {
        // Deduplicate using Set to fix dropdown key conflicts
        const uniqueCurrencies = [...new Set(data)];
        this._currencyOptions = uniqueCurrencies.map(item => ({ label: item, value: item }));
    }
    this._rebuildColumns();
    }

    connectedCallback() {
        this._rebuildColumns();
        document.addEventListener('click', this._onDocClick);
        window.addEventListener('scroll', this._onWinScroll, true);
        this._ensureUnderlyingOptionsLoaded();
    }

    disconnectedCallback() {
        document.removeEventListener('click', this._onDocClick);
        window.removeEventListener('scroll', this._onWinScroll, true);
    }

    renderedCallback() {
        if (!this._dropdownOpen) return;
        const el = this.template.querySelector('.underlying-dropdown-list');
        if (!el) return;
        el.style.left   = `${this._dropdownLeft}px`;
        el.style.bottom = `${this._dropdownBottom}px`;
        el.style.width  = `${this._dropdownWidth}px`;
    }

    @api enterEditMode() {
        if (this._isEditMode) return;
        if (!this._snapshot) {
            this._snapshot = this.rows.map(r => ({ ...r }));
        }
        this._isEditMode = true;
        this._rebuildColumns();
        this._remountTables();
        this._refreshDerivedState();
        this._ensureUnderlyingOptionsLoaded();
    }

    @api restoreSnapshot() {
        if (!this._snapshot) return;
        this.rows        = this._snapshot.map(r => ({ ...r }));
        this._snapshot   = null;
        this._isEditMode = false;
        this._rebuildColumns();
        this._remountTables();
        this._refreshDerivedState();
    }

    @api commitEdit() {
        this.rows        = this.rows.filter(r => !r._deleted);
        this._snapshot   = null;
        this._isEditMode = false;
        this._rebuildColumns();
        this._remountTables();
        this._loadFromData();
    }

    @api collectChanges() {
        return {};
    }

    @api collectUnderlyingsChanges() {
        return {
            underlyingsToUpsert: this.rows
                .filter(r => !r._deleted)
                .map(r => this._cleanRow(r)),
            underlyingsToDelete: this.rows
                .filter(r => r._deleted && r.Id && !r.Id.startsWith(TEMP_ID_PREFIX))
                .map(r => r.Id)
        };
    }

    @api collectBpsFieldsValidation() {
        const FIELDS_TO_VALIDATE = [
            { field: 'DMT_Drawn_Reference_Amount__c',   label: 'Drawn Reference Amount'   },
            { field: 'DMT_Undrawn_Reference_Amount__c', label: 'Undrawn Reference Amount' },
            { field: 'DMT_Drawn_Speed__c',              label: 'Drawn Spread (BPS)'       },
            { field: 'DMT_Undrawn_Spread__c',           label: 'Undrawn Spread (BPS)'     },
            { field: 'DMT_Upfront_Fees__c',             label: 'Upfront Fees'             },
            { field: 'DMT_Upfront_Fees_amount__c',      label: 'Upfront Fees'             },
            { field: 'DMT_Max_Amount__c',               label: 'Max Amount'               }
        ];
        const invalidFields = [];
        for (const row of this.rows) {
            if (row._deleted) continue;
            for (const { field, label } of FIELDS_TO_VALIDATE) {
                const value = row[field];
                if (value === null || value === undefined || value === '') continue;
                if (this._hasMoreThanTwoDecimals(value) && !invalidFields.includes(label)) {
                    invalidFields.push(label);
                }
            }
        }
        return { isValid: invalidFields.length === 0, invalidFields };
    }

    @api validate() {
        if (!this._isEditMode || !this._canEdit) {
            return true;
        }
        const hasRestrictionRow = this.rows.some(row => {
            if (row._deleted) return false;
            return row.DMT_Underlying_Type__c === UNDERLYING_TYPE_RESTRICTION;
        });

        if (!hasRestrictionRow) {
            this._toast('Missing required records', 'At least one Underlying Restriction record is required before saving.', 'error');
            return false;
        }

        const invalidRestrictionRow = this.rows.find(row => {
            if (row._deleted) return false;
            if (row.DMT_Underlying_Type__c !== UNDERLYING_TYPE_RESTRICTION) return false;
            return String(row.DMT_Max_Term__c || '').trim() === '';
        });

        if (invalidRestrictionRow) {
            this._toast('Missing required fields', 'Max Term is required for Underlying Restriction rows.', 'error');
            return false;
        }

        const hasProfitabilityRow = this.rows.some(row => {
            if (row._deleted) return false;
            return row.DMT_Underlying_Type__c === UNDERLYING_TYPE_PROFITABILITY;
        });

        if (!hasProfitabilityRow) {
            this._toast('Missing required records', 'At least one Underlying Profitability record is required before saving.', 'error');
            return false;
        }

        return true;
    }

    @api setReadOnlyMode(readOnly) {
        const newCanEdit = !readOnly;
        if (this._canEdit === newCanEdit) return;
        this._canEdit = newCanEdit;
        this._rebuildColumns();
        this._remountTables();
        this._refreshDerivedState();
    }

    get restrictionReadOnly() {
        return !this._canEdit || !this._isEditMode;
    }

    get profitabilityReadOnly() {
        return !this._canEdit || !this._isEditMode;
    }

    get isRestrictedProduct() {
        return !ALLOWED_PRODUCT_CODES.includes(this.productCode);
    }

    get profitabilityFieldsReadOnly() {
        return this.profitabilityReadOnly || this.isRestrictedProduct;
    }

    get rowActionsDisabled() {
        return !this._canEdit;
    }

    get rowEditActionDisabled() {
        return !this._canEdit || this._isEditMode;
    }

    _loadFromData() {
        this.rows = this._data
            .filter(r => SUPPORTED_UNDERLYING_TYPES.has(r?.DMT_Underlying_Type__c))
            .map(r => this._decorateNewRow(r));
        this._refreshDerivedState();
    }

    _decorateNewRow(row) {
        const isNew = !row.Id || row.Id.startsWith(TEMP_ID_PREFIX);
        const rowType = SUPPORTED_UNDERLYING_TYPES.has(row.DMT_Underlying_Type__c)
            ? row.DMT_Underlying_Type__c
            : UNDERLYING_TYPE_RESTRICTION;
        const normalizedRow = this._normalizeUpfrontFeeFields(row);
        return {
            ...normalizedRow,
            Id                        : isNew ? this._newTempId() : row.Id,
            DMT_Underlying_Type__c    : rowType,
            DMT_Opportunity_Product__c: normalizedRow.DMT_Opportunity_Product__c || this.oppProduct || null,
            _deleted                  : false,
            _isNew                    : isNew
        };
    }

    _newTempId() {
        this._tempIdCounter += 1;
        return `${TEMP_ID_PREFIX}${Date.now()}_${this._tempIdCounter}`;
    }

    handleRowAction(event) {
        const { action, row } = event.detail;
        switch (action.name) {
            case 'editRecord'  : this._handleEditClick();     break;
            case 'addRecord'   : this._handleAddRow(row.Id, row.DMT_Underlying_Type__c);  break;
            case 'deleteRecord': this._requestDelete(row.Id); break;
            default: break;
        }
    }

    handleAddRestrictionGlobal() {
        this._handleAddRow(null, UNDERLYING_TYPE_RESTRICTION);
    }

    handleAddProfitabilityGlobal() {
        this._handleAddRow(null, UNDERLYING_TYPE_PROFITABILITY);
    }

    _handleEditClick() {
        this.dispatchEvent(new CustomEvent('editmodechange', {
            bubbles : true,
            composed: true,
            detail  : { isEditMode: true }
        }));
    }

    _handleAddRow(afterId, requestedType) {
        if (!this._canEdit) return;
        if (!this._snapshot) {
            this._snapshot = this.rows.map(r => ({ ...r }));
        }
        let rowType = requestedType;
        if (!SUPPORTED_UNDERLYING_TYPES.has(rowType) && afterId != null) {
            const sourceRow = this.rows.find(r => r.Id === afterId);
            rowType = sourceRow?.DMT_Underlying_Type__c;
        }
        if (!SUPPORTED_UNDERLYING_TYPES.has(rowType)) {
            rowType = UNDERLYING_TYPE_RESTRICTION;
        }
        const newRow = this._decorateNewRow(this._buildDefaultRowByType(rowType));
        if (afterId == null) {
            this.rows = [...this.rows, newRow];
        } else {
            const idx    = this.rows.findIndex(r => r.Id === afterId);
            const newArr = [...this.rows];
            newArr.splice(idx === -1 ? newArr.length : idx + 1, 0, newRow);
            this.rows = newArr;
        }
        this._refreshDerivedState();
        if (!this._isEditMode) {
            this.dispatchEvent(new CustomEvent('editmodechange', {
                bubbles : true,
                composed: true,
                detail  : { isEditMode: true }
            }));
        }
    }

    _buildDefaultRowByType(type) {
        if (type === UNDERLYING_TYPE_PROFITABILITY) {
            const defaultUpfrontFees = this._getDefaultUpfrontFeesBps();
            const useRestrictedDefaults = this.isRestrictedProduct;
            return {
                Id                               : null,
                Name                             : '',
                DMT_Underlying_Type__c           : UNDERLYING_TYPE_PROFITABILITY,
                DMT_Drawn_Reference_Amount__c    : null,
                DMT_Undrawn_Reference_Amount__c  : null,
                DMT_Term__c                      : null,
                DMT_Drawn_Speed__c               : null,
                DMT_Undrawn_Spread__c            : null,
                DMT_Upfront_Fees__c              : defaultUpfrontFees,
                DMT_Upfront_Fees_amount__c       : null,
                DMT_Amortization_Type__c         : useRestrictedDefaults ? 'Bullet' : null,
                DMT_Interest_Payment_Frequency__c: useRestrictedDefaults ? 'Monthly' : null,
                DMT_Currency__c                  : useRestrictedDefaults ? (this.opportunityCurrency || '') : '',
                DMT_Opportunity_Product__c       : this.oppProduct || null
            };
        }

        return {
            Id                        : null,
            Name                      : '',
            DMT_Underlying_Type__c    : UNDERLYING_TYPE_RESTRICTION,
            DMT_Max_Amount__c         : null,
            DMT_Max_Term__c           : null,
            DMT_Other_restrictions__c : '',
            DMT_Opportunity_Product__c: this.oppProduct || null
        };
    }

    _getDefaultUpfrontFeesBps() {
        const value = this.referenceUpfrontFees;
        if (value === '' || value === undefined || value === null) return null;
        if (typeof value === 'number') return Number.isFinite(value) ? value : null;

        const raw = String(value).trim();
        if (!raw) return null;

        const hasComma = raw.includes(',');
        const hasDot = raw.includes('.');

        let normalized = raw;
        if (hasComma && hasDot) {
            const lastComma = raw.lastIndexOf(',');
            const lastDot = raw.lastIndexOf('.');
            const decimalSeparator = lastComma > lastDot ? ',' : '.';
            if (decimalSeparator === ',') {
                normalized = raw.replace(/\./g, '').replace(',', '.');
            } else {
                normalized = raw.replace(/,/g, '');
            }
        } else if (hasComma) {
            normalized = raw.replace(/\./g, '').replace(',', '.');
        }

        const parsed = Number(normalized);
        return Number.isFinite(parsed) ? parsed : null;
    }

    async _requestDelete(id) {
        const row = this.rows.find(r => r.Id === id);
        if (!row) return;
        if (row._isNew || this._isEditMode) {
            this._performDelete(id);
            return;
        }
        const confirmed = await LightningConfirm.open({
            message: 'Are you sure you want to delete this Underlying? This action cannot be undone.',
            variant: 'header',
            label  : 'Confirm deletion',
            theme  : 'warning'
        });
        if (confirmed) this._performDelete(id);
    }

    _performDelete(id) {
        const row = this.rows.find(r => r.Id === id);
        if (!row) return;
        if (row._isNew) {
            this.rows = this.rows.filter(r => r.Id !== id);
            this._refreshDerivedState();
            this._toast('Record deleted', 'The Underlying was successfully deleted.', 'success');
            return;
        }
        if (this._isEditMode) {
            this.rows = this.rows.map(r => r.Id === id ? { ...r, _deleted: true } : r);
            this._refreshDerivedState();
            return;
        }
        this.isLoading = true;
        deleteRecord(id)
            .then(() => {
                this._toast('Record deleted', 'The Underlying was successfully deleted.', 'success');
                this.rows = this.rows.filter(r => r.Id !== id);
                this._refreshDerivedState();
            })
            .catch(error => {
                this._toast('Error deleting', error?.body?.message || error?.message || 'Could not delete the record.', 'error');
            })
            .finally(() => { this.isLoading = false; });
    }

    _handleCellChange(event) {
        event.stopPropagation();
        const detailData = event.detail?.data || {};
        const id = detailData.context || event.currentTarget?.dataset?.id;
        const field = detailData.fieldname || event.currentTarget?.dataset?.field;
        const value = detailData.value !== undefined ? detailData.value : event.currentTarget?.value;
        this._updateRowField(id, field, value);
    }

    handleCellInput(event)  { this._handleCellChange(event); }
    handleCellNumber(event) {
        const field = event.currentTarget?.dataset?.field;
        if (NON_NEGATIVE_FIELDS.has(field)) {
            const rawValue    = event.detail?.value ?? event.currentTarget?.value;
            const numericValue = typeof rawValue === 'number' ? rawValue : parseFloat(rawValue);
            if (Number.isFinite(numericValue) && numericValue < 0) {
                const id = event.currentTarget?.dataset?.id;
                this._updateRowField(id, field, 0);
                return;
            }
        }
        this._handleCellChange(event);
    }

    async handleUnderlyingFocus(event) {
        event.stopPropagation();
        await this._openUnderlyingLookup(event.currentTarget, '');
    }

    async handleUnderlyingClick(event) {
        event.stopPropagation();
        await this._openUnderlyingLookup(event.currentTarget, '');
    }

    async handleUnderlyingInput(event) {
        event.stopPropagation();
        const id = event.currentTarget?.dataset?.id;
        const value = event.target?.value || '';
        this._updateRowField(id, 'Name', value);
        await this._openUnderlyingLookup(event.currentTarget, value);
    }

    async handleUnderlyingArrowClick(event) {
        event.stopPropagation();
        const container = event.currentTarget?.closest('.underlying-picklist');
        const input = container?.querySelector('input');
        if (!input) return;
        await this._openUnderlyingLookup(input, '');
        input.focus();
    }

    handleCurrencyFocus(event) {
        event.stopPropagation();
        this._openCurrencyLookup(event.currentTarget, '');
    }

    handleCurrencyClick(event) {
        event.stopPropagation();
        this._openCurrencyLookup(event.currentTarget, '');
    }

    handleCurrencyInput(event) {
        event.stopPropagation();
        const id = event.currentTarget?.dataset?.id;
        const value = event.target?.value || '';
        this._updateRowField(id, 'DMT_Currency__c', value);
        this._openCurrencyLookup(event.currentTarget, value);
    }

    handleCurrencyArrowClick(event) {
        event.stopPropagation();
        const container = event.currentTarget?.closest('.underlying-picklist');
        const input = container?.querySelector('input');
        if (!input) return;
        this._openCurrencyLookup(input, '');
        input.focus();
    }

    async _openUnderlyingLookup(inputEl, searchTerm) {
        await this._ensureUnderlyingOptionsLoaded();

        const id = inputEl?.dataset?.id;
        if (!id) return;

        const term = (searchTerm || '').trim();
        const filtered = this._filterUnderlyingOptions(term);

        this._dropdownCtx = { id, field: 'Name' };
        this._isUnderlyingLookup = true;
        this._dropdownSearchTerm = term;
        this._dropdownAllOptions = filtered;
        this._dropdownVisibleCount = LOOKUP_INITIAL_VISIBLE_OPTIONS;
        this._dropdownOptions = term
            ? filtered
            : filtered.slice(0, this._dropdownVisibleCount);

        const anchorEl = inputEl.closest('.underlying-picklist') || inputEl;
        const rect = anchorEl.getBoundingClientRect();
        this._dropdownLeft = rect.left;
        this._dropdownBottom = window.innerHeight - rect.top + 4;
        this._dropdownWidth = rect.width;
        this._dropdownOpen = true;
    }

    _openCurrencyLookup(inputEl, searchTerm) {
        const id = inputEl?.dataset?.id;
        if (!id) return;

        this._dropdownCtx = { id, field: 'DMT_Currency__c' };
        this._isUnderlyingLookup = false;
        this._dropdownSearchTerm = '';
        this._dropdownAllOptions = [];
        const filtered = this._filterOptions(this._currencyOptions, searchTerm);
        this._dropdownOptions = filtered;

        const anchorEl = inputEl.closest('.underlying-picklist') || inputEl;
        const rect = anchorEl.getBoundingClientRect();
        this._dropdownLeft = rect.left;
        this._dropdownBottom = window.innerHeight - rect.top + 4;
        this._dropdownWidth = rect.width;
        this._dropdownOpen = true;
    }

    _filterOptions(options, searchTerm) {
        const source = Array.isArray(options) ? options : [];
        const term = (searchTerm || '').trim().toLowerCase();
        if (!term) {
            return [...source];
        }
        return source.filter(opt => {
            const label = (opt?.label || '').toLowerCase();
            const value = (opt?.value || '').toLowerCase();
            return label.includes(term) || value.includes(term);
        });
    }

    _filterUnderlyingOptions(searchTerm) {
        return this._filterOptions(this._underlyingOptions, searchTerm);
    }

    _getUnderlyingLookupOptions(searchTerm) {
        const filtered = this._filterUnderlyingOptions(searchTerm);
        const term = (searchTerm || '').trim();
        return term ? filtered : filtered.slice(0, LOOKUP_INITIAL_VISIBLE_OPTIONS);
    }

    _getDrawnUndrawnMode(underlyingName) {
        if (!underlyingName) return '';
        return this._modeByLabel.get(underlyingName) || '';
    }

    handleDropdownScroll(event) {
        if (!this._dropdownOpen || !this._isUnderlyingLookup) return;
        if (this._dropdownSearchTerm) return;

        const list = event.target;
        const isNearBottom = list.scrollTop + list.clientHeight >= list.scrollHeight - 8;
        if (!isNearBottom) return;
        if (this._dropdownOptions.length >= this._dropdownAllOptions.length) return;

        this._dropdownVisibleCount += LOOKUP_INITIAL_VISIBLE_OPTIONS;
        this._dropdownOptions = this._dropdownAllOptions.slice(0, this._dropdownVisibleCount);
    }

    async _ensureUnderlyingOptionsLoaded() {
        if (!this.oppProduct) return;
        if (this._underlyingOptionsLoadedFor === this.oppProduct && this._underlyingOptions.length > 0) return;

        try {
            const records = await getUnderlyingOptions({ opportunityLineItemId: this.oppProduct });
            this._underlyingOptions = Array.isArray(records)
                ? records.map(r => ({ label: r.label, value: r.value, mode: r.drawnUndrawnMode || '' }))
                : [];
            this._modeByLabel = new Map(this._underlyingOptions.map(o => [o.label, o.mode]));
            this._underlyingOptionsLoadedFor = this.oppProduct;
            this._refreshDerivedState();
        } catch (error) {
            this._underlyingOptions = [];
            this._modeByLabel = new Map();
            this._underlyingOptionsLoadedFor = this.oppProduct;
            this._toast('Error loading Underlying options', error?.body?.message || error?.message || 'Could not load Underlying options.', 'error');
        }
    }

    handlePicklistChange(event) {
        event.stopPropagation();
        const detailData = event.detail?.data || {};
        const id = event.currentTarget?.dataset?.id || detailData.context;
        const field = event.currentTarget?.dataset?.field || detailData.fieldname;
        const value = event.detail?.value !== undefined
            ? event.detail.value
            : (event.currentTarget?.value !== undefined ? event.currentTarget.value : detailData.value);
        this._updateRowField(id, field, value);
    }

    handlePicklistOpen(event) {
        event.stopPropagation();
        const el    = event.currentTarget;
        const id    = el.dataset.id;
        const field = el.dataset.field;
        if (this._dropdownOpen && this._dropdownCtx?.id === id && this._dropdownCtx?.field === field) {
            this._dropdownOpen = false;
            return;
        }
        const optMap = {
            DMT_Max_Term__c                  : this._maxTermOptions,
            DMT_Term__c                      : this._termOptions,
            DMT_Amortization_Type__c         : this._amortizationTypeOptions,
            DMT_Interest_Payment_Frequency__c: this._interestPaymentFrequencyOptions,
            DMT_Currency__c                  : this._currencyOptions,
            [UPFRONT_FEES_UNIT_FIELD]        : UPFRONT_UNIT_OPTIONS
        };
        this._dropdownCtx      = { id, field };
        this._isUnderlyingLookup = false;
        this._dropdownSearchTerm = '';
        this._dropdownAllOptions = [];
        this._dropdownOptions  = optMap[field] || [];
        const rect             = el.getBoundingClientRect();
        this._dropdownLeft     = rect.left;
        this._dropdownBottom   = window.innerHeight - rect.top + 4;
        this._dropdownWidth    = rect.width;
        this._dropdownOpen     = true;
    }

    handleDropdownSelect(event) {
        event.stopPropagation();
        const rawValue      = event.currentTarget.dataset.value;
        const label         = event.currentTarget.dataset.label;
        const value         = this._isUnderlyingLookup ? (label || rawValue) : rawValue;
        const { id, field } = this._dropdownCtx;
        this._dropdownOpen  = false;
        this._isUnderlyingLookup = false;
        this._updateRowField(id, field, value);
    }

    handleDropdownMousedown(event) {
        event.stopPropagation();
    }

    _updateRowField(id, field, value) {
        if (!id || !field) return;
        const idx = this.rows.findIndex(r => r.Id === id);
        if (idx === -1) return;
        const newArr = [...this.rows];
        const row = this.rows[idx];
        let updated;
        if (field === UPFRONT_FEES_FIELD) {
            updated = this._applyUpfrontFeeValueSelection(row, this._getUpfrontFeeUnit(row), value);
        } else if (field === UPFRONT_FEES_UNIT_FIELD) {
            updated = this._applyUpfrontFeeUnitSelection(row, value);
        } else {
            updated = { ...row, [field]: value };
        }
        if (field === 'DMT_Amortization_Type__c' && value === 'Bullet') {
            updated.DMT_Interest_Payment_Frequency__c = null;
        }

        if (field === 'Name' && updated.DMT_Underlying_Type__c === UNDERLYING_TYPE_PROFITABILITY) {
            if (this._getDrawnUndrawnMode(value) === MODE_UNDRAWN) {
                updated.DMT_Drawn_Reference_Amount__c = null;
                updated.DMT_Drawn_Speed__c = null;
            }
        }
        newArr[idx] = updated;
        this.rows = newArr;
        this._refreshDerivedState();
    }

    handleInlineAction(event) {
        event.stopPropagation();
        const { action, id, rowtype } = event.currentTarget.dataset;
        switch (action) {
            case 'edit':
                this._handleEditClick();
                break;
            case 'delete':
                this._requestDelete(id);
                break;
            case 'add':
                this._handleAddRow(id, rowtype);
                break;
            default:
                break;
        }
    }

    _getOptionLabel(options, value) {
        if (value === null || value === undefined || value === '') return '';
        const opt = options.find(o => o.value === String(value));
        return opt ? opt.label : String(value);
    }

    _refreshDerivedState() {
        const visibleRows = this.rows
            .filter(r => !r._deleted)
            .map(r => {
                if (r.DMT_Underlying_Type__c === UNDERLYING_TYPE_PROFITABILITY) {
                    const upfrontUnit = this._getUpfrontFeeUnit(r);
                    const drawnUndrawnMode = this._getDrawnUndrawnMode(r.Name);
                    this._ensureCurrencyLabel(r.DMT_Currency__c);
                    return {
                        ...r,
                        deleteDisabled        : !this._canEdit,
                        editDisabled          : !this._canEdit,
                        buttonDisabled        : !this._canEdit,
                        DMT_Term__c_label     : this._getOptionLabel(TERM_OPTIONS, r.DMT_Term__c),
                        DMT_Max_Term__c_label : this._getOptionLabel(TERM_OPTIONS, r.DMT_Max_Term__c),
                        DMT_Currency__c_label : this._currencyLabels[r.DMT_Currency__c] || r.DMT_Currency__c,
                        [UPFRONT_FEES_FIELD]  : this._getUpfrontFeeValueForRow(r, upfrontUnit),
                        [UPFRONT_FEES_UNIT_FIELD]: upfrontUnit,
                        _showUpfrontCurrency  : upfrontUnit === UPFRONT_UNIT_AMOUNT,
                        _upfrontFeesCellClass : upfrontUnit === UPFRONT_UNIT_AMOUNT ? 'col-amount-currency col-upfront-amount' : '',
                        _upfrontFeesReadOnlyClass: upfrontUnit === UPFRONT_UNIT_AMOUNT
                            ? 'cell-text amount-with-currency amount-with-currency-wide'
                            : 'cell-text amount-with-currency',
                        _upfrontFeesEditClass: upfrontUnit === UPFRONT_UNIT_AMOUNT
                            ? 'amount-with-currency amount-with-currency-wide'
                            : 'amount-with-currency',
                        _drawnDisabled  : this.profitabilityReadOnly || drawnUndrawnMode === MODE_UNDRAWN
                    };
                }
                return {
                    ...r,
                    deleteDisabled        : !this._canEdit,
                    editDisabled          : !this._canEdit,
                    buttonDisabled        : !this._canEdit,
                    DMT_Term__c_label     : this._getOptionLabel(TERM_OPTIONS, r.DMT_Term__c),
                    DMT_Max_Term__c_label : this._getOptionLabel(TERM_OPTIONS, r.DMT_Max_Term__c),
                    DMT_Currency__c_label : this._currencyLabels[r.DMT_Currency__c] || r.DMT_Currency__c
                };
            });
        this.displayRestrictionRows = visibleRows
            .filter(r => r.DMT_Underlying_Type__c === UNDERLYING_TYPE_RESTRICTION);
        this.displayProfitabilityRows = visibleRows
            .filter(r => r.DMT_Underlying_Type__c === UNDERLYING_TYPE_PROFITABILITY);

        this.displayRestrictionRows = [...this.displayRestrictionRows];
        this.displayProfitabilityRows = [...this.displayProfitabilityRows];

        this.dispatchEvent(new CustomEvent('underlyingschange', {
            bubbles : true,
            composed: true,
            detail  : {
                rows: this.rows.map(r => ({ ...r })),
                hasNonStandardCurrency: this._hasNonStandardCurrency()
            }
        }));
    }

    get hasRestrictionRows() { return this.displayRestrictionRows.length > 0; }
    get hasProfitabilityRows() { return this.displayProfitabilityRows.length > 0; }
    get globalAddDisabled() { return !this._canEdit; }
    // show column only when at least one profitability row is non-Bullet
    get showInterestPaymentFrequency() {
        return this.displayProfitabilityRows.some(r => r.DMT_Amortization_Type__c !== 'Bullet');
    }

    _hasNonStandardCurrency() {
        return this.rows.some(row => {
            if (row._deleted) return false;
            const currency = String(row.DMT_Currency__c || '').trim();
            return currency !== '' && !AUTO_MANUAL_CURRENCIES.has(currency);
        });
    }

    _rebuildColumns() {
        this.restrictionColumns = this._buildRestrictionColumns();
        this.profitabilityColumns = this._buildProfitabilityColumns();
    }

    _remountTables() {
        this.renderRestrictionTable = false;
        this.renderProfitabilityTable = false;
        requestAnimationFrame(() => {
            this.renderRestrictionTable = true;
            this.renderProfitabilityTable = true;
        });
    }

    _buildRestrictionColumns() {
        const e = this._isEditMode;
        return [
            this._textColumn   ('Underlying',         'Name',                       COLUMN_WIDTHS.Name,                       e),
            this._numericColumn('Max Amount',          'DMT_Max_Amount__c',          COLUMN_WIDTHS.DMT_Max_Amount__c,          e),
            this._picklistColumn('Max Term',           'DMT_Max_Term__c',            this._maxTermOptions,                     e),
            this._textColumn   ('Other restrictions',  'DMT_Other_restrictions__c',  null,                                     e),
            this._buttonColumn('utility:delete', 'deleteRecord', 'deleteDisabled'),
            this._buttonColumn('utility:edit',   'editRecord',   'editDisabled'),
            this._buttonColumn('utility:add',    'addRecord',    'buttonDisabled')
        ];
    }

    _buildProfitabilityColumns() {
        const e = this._isEditMode;
        return [
            this._textColumn   ('Underlying',                    'Name',                                COLUMN_WIDTHS.Name, e),
            this._numericColumn('Drawn Reference Amount',        'DMT_Drawn_Reference_Amount__c',       COLUMN_WIDTHS.DMT_Drawn_Reference_Amount__c, e),
            this._numericColumn('Undrawn Reference Amount',      'DMT_Undrawn_Reference_Amount__c',     COLUMN_WIDTHS.DMT_Undrawn_Reference_Amount__c, e),
            this._picklistColumn('Term',                         'DMT_Term__c',                         this._termOptions, e),
            this._numericColumn('Drawn Spread (BPS)',            'DMT_Drawn_Speed__c',                  COLUMN_WIDTHS.DMT_Drawn_Speed__c, e),
            this._numericColumn('Undrawn Spread (BPS)',          'DMT_Undrawn_Spread__c',               COLUMN_WIDTHS.DMT_Undrawn_Spread__c, e),
            this._numericColumn('Upfront Fees',                  UPFRONT_FEES_FIELD,                    COLUMN_WIDTHS[UPFRONT_FEES_FIELD], e),
            this._picklistColumn('Amount / BPS',                 UPFRONT_FEES_UNIT_FIELD,               UPFRONT_UNIT_OPTIONS, e),
            this._picklistColumn('Amortization Type',            'DMT_Amortization_Type__c',            this._amortizationTypeOptions, e),
            this._picklistColumn('Interest Payment Frequency',   'DMT_Interest_Payment_Frequency__c',   this._interestPaymentFrequencyOptions, e),
            this._picklistColumn('Currency',                     'DMT_Currency__c',                     this._currencyOptions, e),
            this._buttonColumn('utility:delete', 'deleteRecord', 'deleteDisabled'),
            this._buttonColumn('utility:edit',   'editRecord',   'editDisabled'),
            this._buttonColumn('utility:add',    'addRecord',    'buttonDisabled')
        ];
    }

    _textColumn(label, field, width, isEdit) {
        const col = {
            label,
            fieldName         : field,
            type              : isEdit ? 'custominputRow' : 'text',
            editable          : false,
            hideDefaultActions: true,
            cellAttributes    : { alignment: 'left' },
            typeAttributes    : {
                aviableItem: { fieldName: true },
                inputValue : { fieldName: field },
                fieldName  : field,
                context    : { fieldName: 'Id' }
            }
        };
        if (width) col.initialWidth = width;
        return col;
    }

    _numericColumn(label, field, width, isEdit) {
        return {
            label,
            fieldName         : field,
            type              : isEdit ? 'customnumberRow' : 'number',
            editable          : false,
            hideDefaultActions: true,
            initialWidth      : width,
            cellAttributes    : { alignment: 'center' },
            typeAttributes    : {
                step       : 'any',
                aviableItem: { fieldName: true },
                numberValue: { fieldName: field },
                fieldName  : field,
                context    : { fieldName: 'Id' }
            }
        };
    }

    _picklistColumn(label, field, options, isEdit) {
        const picklistOptions = Array.isArray(options)
            ? options.map(opt => ({ ...opt }))
            : [];
        return {
            label,
            fieldName         : field,
            type              : 'picklist',
            editable          : false,
            hideDefaultActions: true,
            initialWidth      : COLUMN_WIDTHS[field] || COLUMN_WIDTHS.DMT_Max_Term__c,
            cellAttributes    : { alignment: 'center' },
            typeAttributes    : {
                placeholder : 'Select..',
                options     : picklistOptions,
                value       : { fieldName: field },
                context     : { fieldName: 'Id' },
                fieldName   : field,
                readonlyAttr: !isEdit || !this._canEdit,
                isDisabled  : !isEdit || !this._canEdit
            }
        };
    }

    _buttonColumn(iconName, actionName, disabledField) {
        return {
            type              : 'button-icon',
            hideDefaultActions: true,
            initialWidth      : COLUMN_WIDTHS.button,
            cellAttributes    : { alignment: 'center' },
            typeAttributes    : {
                iconName,
                label   : ' ',
                variant : 'bare',
                name    : actionName,
                disabled: { fieldName: disabledField }
            }
        };
    }

    _normalizeUpfrontFeeFields(row) {
        if (row?.DMT_Underlying_Type__c !== UNDERLYING_TYPE_PROFITABILITY) {
            return row;
        }
        const normalizedUnit = this._getUpfrontFeeUnit(row);
        const normalizedValue = row?.[UPFRONT_FEES_FIELD] === undefined
            ? this._getUpfrontFeeValueForRow(row, normalizedUnit)
            : this._parseNumeric(row?.[UPFRONT_FEES_FIELD]);

        return this._applyUpfrontFeeUnitSelection({
            ...row,
            [UPFRONT_FEES_FIELD]: normalizedValue
        }, normalizedUnit);
    }

    _getUpfrontFeeUnit(row) {
        const amountValue = this._parseNumeric(row?.DMT_Upfront_Fees_amount__c);
        const bpsValue = this._parseNumeric(row?.DMT_Upfront_Fees__c);
        if (bpsValue !== 0 && amountValue === 0) return UPFRONT_UNIT_BPS;
        if (amountValue !== 0 && bpsValue === 0) return UPFRONT_UNIT_AMOUNT;
        return UPFRONT_UNIT_AMOUNT;
    }

    _applyUpfrontFeeUnitSelection(row, selectedUnit) {
        const unit = selectedUnit === UPFRONT_UNIT_BPS ? UPFRONT_UNIT_BPS : UPFRONT_UNIT_AMOUNT;
        const currentUnit = this._getUpfrontFeeUnit(row);
        const currentValue = this._getUpfrontFeeValueForRow(row, currentUnit);

        return {
            ...row,
            DMT_Upfront_Fees_amount__c: unit === UPFRONT_UNIT_AMOUNT ? currentValue : 0,
            DMT_Upfront_Fees__c: unit === UPFRONT_UNIT_BPS ? currentValue : 0,
            [UPFRONT_FEES_FIELD]: currentValue,
            [UPFRONT_FEES_UNIT_FIELD]: unit
        };
    }

    _applyUpfrontFeeValueSelection(row, selectedUnit, inputValue) {
        const unit = selectedUnit === UPFRONT_UNIT_BPS ? UPFRONT_UNIT_BPS : UPFRONT_UNIT_AMOUNT;
        const normalizedValue = this._parseNumeric(inputValue);
        return {
            ...row,
            DMT_Upfront_Fees_amount__c: unit === UPFRONT_UNIT_AMOUNT ? normalizedValue : 0,
            DMT_Upfront_Fees__c: unit === UPFRONT_UNIT_BPS ? normalizedValue : 0,
            [UPFRONT_FEES_FIELD]: normalizedValue,
            [UPFRONT_FEES_UNIT_FIELD]: unit
        };
    }

    _getUpfrontFeeValueForRow(row, unit) {
        return unit === UPFRONT_UNIT_BPS
            ? this._parseNumeric(row?.DMT_Upfront_Fees__c)
            : this._parseNumeric(row?.DMT_Upfront_Fees_amount__c);
    }

    _parseNumeric(value) {
        if (value === null || value === undefined || value === '') return 0;
        const parsed = typeof value === 'number' ? value : parseFloat(value);
        return Number.isFinite(parsed) ? parsed : 0;
    }

    _cleanRow(row) {
        const cleaned = { Id: row.Id?.startsWith(TEMP_ID_PREFIX) ? null : row.Id };
        for (const f of BUSINESS_FIELDS) {
            cleaned[f] = row[f] !== undefined ? row[f] : null;
        }
        return cleaned;
    }

    _toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    _hasMoreThanTwoDecimals(value) {
        const decimalPart = String(value).split('.')[1];
        return !!decimalPart && decimalPart.length > 2;
    }

    _ensureCurrencyLabel(currencyIsoCode) {
        if (!currencyIsoCode || this._currencyLabels[currencyIsoCode]) return;
        getCurrencyLabel({ currencyIsoCode })
            .then(result => {
                this._currencyLabels = { ...this._currencyLabels, [currencyIsoCode]: result || currencyIsoCode };
                this._refreshDerivedState();
            })
            .catch(() => {
                this._currencyLabels = { ...this._currencyLabels, [currencyIsoCode]: currencyIsoCode };
                this._refreshDerivedState();
            });
    }

}