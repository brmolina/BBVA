import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOpportunityMoney from '@salesforce/apex/DMT_Opportunity_Utils.getOpportunityMoney';
import upsertOpportunityMoney from '@salesforce/apex/DMT_Opportunity_Utils.upsertOpportunityMoney';
import getOpportunityLineItemDataFresh from '@salesforce/apex/DMT_OpportunityProductsController.getOpportunityLineItemDataFresh';
import getUnderlyingsData from '@salesforce/apex/DMT_OpportunityProductsController.getUnderlyingsData';
import getFeatures from '@salesforce/apex/DMT_ViewController.getFeatures';

const FIELD_DEFINITIONS = [
    { key: '1',  apiName: 'DMT_Up_Front_Fee_Accrual__c',       label: 'Up-Front Fee Accrual',                 sourceKind: 'template',      sourceLabel: 'Template' },
    { key: '2',  apiName: 'DMT_Up_Front_Fee_Non_Accrual__c',   label: 'Up-Front Fee Non Accrual',             sourceKind: 'template',      sourceLabel: 'Template' },
    { key: '3',  apiName: 'DMT_Funding_Cost__c',               label: 'Funding Cost',                         sourceKind: 'profitability', sourceLabel: 'Profitability Engine', profitabilityKey: 'fundingDbPbs' },
    { key: '4',  apiName: 'DMT_Liquidity_Fee__c',              label: 'Liquidity Fee',                        sourceKind: 'profitability', sourceLabel: 'Profitability Engine', profitabilityKey: 'fundingFbPbs' },
    { key: '5',  apiName: 'DMT_Interest_Rate_Period__c',       label: 'Interest Rate Period',                 sourceKind: 'template',      sourceLabel: 'Template' },
    { key: '6',  apiName: 'DMT_Applicable_Margin__c',          label: 'Applicable Margin',                    sourceKind: 'template',      sourceLabel: 'Template' },
    { key: '7',  apiName: 'DMT_Pricing_Grid_or_Step_ups__c',   label: 'Pricing Grid or Step-ups (if applicable)', sourceKind: 'template',   sourceLabel: 'Template' },
    { key: '8',  apiName: 'DMT_Commitment_Fee__c',             label: 'Commitment Fee',                       sourceKind: 'template',      sourceLabel: 'Template' },
    { key: '9',  apiName: 'DMT_Utilisation_Fee__c',            label: 'Utilisation Fee',                      sourceKind: 'template',      sourceLabel: 'Template' },
    { key: '10', apiName: 'DMT_Extension_Duration_Fee__c',     label: 'Extension /duration Fee',              sourceKind: 'template',      sourceLabel: 'Template' },
    { key: '11', apiName: 'DMT_Other_Fees_Accrual__c',         label: 'Other fees (accrual)',                 sourceKind: 'template',      sourceLabel: 'Template' },
    { key: '12', apiName: 'DMT_Other_Fees_Non_Accrual__c',     label: 'Other fees (non accrual)',             sourceKind: 'template',      sourceLabel: 'Template' },
    { key: '13', apiName: 'DMT_Expected_Drawn__c',             label: 'Expected drawn',                       sourceKind: 'template',      sourceLabel: 'Template' },
    { key: '14', apiName: 'DMT_All_in_Drawn__c',               label: 'All-in Drawn',                         sourceKind: 'profitability', sourceLabel: 'Profitability Engine', profitabilityKey: 'allInDb' },
    { key: '15', apiName: 'DMT_All_in_Undrawn__c',             label: 'All-in Undrawn',                       sourceKind: 'profitability', sourceLabel: 'Profitability Engine', profitabilityKey: 'allInFb' }
];

export default class DmtOppMoneyModal extends LightningModal {

    @api oppProductId;

    @track rows      = [];
    @track isLoading = false;
    @track isSaving  = false;
    @track hasError  = false;
    @track errorMessage = '';

    _oldMoneyId = null;
    _newMoneyId = null;

    async connectedCallback() {
        this.isLoading = true;
        try {
            const [moneyResult, lineResult, underlyingsResult] = await Promise.allSettled([
                getOpportunityMoney({ oppLineItemId: this.oppProductId }),
                getOpportunityLineItemDataFresh({ opportunityLineItemId: this.oppProductId }),
                getUnderlyingsData({ opportunityLineItemId: this.oppProductId })
            ]);

            const pair = moneyResult.status === 'fulfilled' ? moneyResult.value : null;
            const lineItem = lineResult.status === 'fulfilled' ? lineResult.value : null;
            const underlyings = underlyingsResult.status === 'fulfilled' ? underlyingsResult.value : [];


            let features = [];
            const opportunityId = lineItem?.OpportunityId ?? null;
            if (opportunityId) {
                try {
                    features = await getFeatures({ id: opportunityId });
                } catch (error) {
                    console.error('[dmt_opp_money_modal] Error loading profitability features:', error);
                }
            }

            this._oldMoneyId = pair?.oldMoney?.Id ?? null;
            this._newMoneyId = pair?.newMoney?.Id ?? null;
            this.rows = this._buildRows(pair, lineItem, underlyings, features);
        } catch (error) {
            console.error('[dmt_opp_money_modal] Error loading records:', error);
            this.rows = this._buildFallbackRows();
        } finally {
            this.isLoading = false;
        }
    }

    _buildRows(pair, lineItem, underlyings, features) {
        const profitabilityResult = this._extractProfitabilityResult(features, lineItem);
        const lineContext = this._isLineContext(lineItem);
        const allTenors = Array.isArray(lineItem?.Opportunity_Tenors__r)
            ? lineItem.Opportunity_Tenors__r
            : [];
        const tenors = allTenors.filter(tenor => this._hasNotionalValue(tenor));    

        // Keys de campos que NUNCA deben mostrar botón de fetch (Line o One-off)
        const noFetchButtonKeys = ['7', '9', '10', '11', '12']; // Pricing Grid, Utilisation Fee, Extension/Duration Fee, Other Fees Accrual, Other Fees Non-Accrual
        // Keys que solo tienen herencia en One-off: en Line no se muestra el botón
        const lineOnlyNoFetchKeys = ['1', '5']; // Up-Front Fee Accrual, Interest Rate Period


        return FIELD_DEFINITIONS.map(definition => {
            const rawSourceValue = this._resolveSourceValue(definition, lineItem, underlyings, tenors, profitabilityResult, lineContext);
            const sourceValue = this._roundNumericDisplayValue(rawSourceValue);
            const oldPersistedValue = this._normalizeDisplayValue(pair?.oldMoney?.[definition.apiName]);
            const newPersistedValue = this._normalizeDisplayValue(pair?.newMoney?.[definition.apiName]);

            return {
                key: definition.key,
                label: definition.label,
                helpText: this._getHelpText(definition.apiName, lineContext),
                apiName: definition.apiName,
                sourceLabel: definition.sourceLabel,
                sourceValue,
                canFetchSource: !noFetchButtonKeys.includes(definition.key)
                && !(lineContext && lineOnlyNoFetchKeys.includes(definition.key)),
                isTextArea: definition.apiName === 'DMT_Pricing_Grid_or_Step_ups__c',
                defaultOnBlank: !!definition.defaultOnBlank,
                defaultOnLoad: !!definition.defaultOnLoad,
                defaultValue: definition.defaultValue ?? '',
                oldValue: oldPersistedValue,
                newValue: newPersistedValue
            };
        });
    }

    _buildFallbackRows() {
        return FIELD_DEFINITIONS.map(definition => ({
            key: definition.key,
            label: definition.label,
            helpText: this._getHelpText(definition.apiName, false),
            apiName: definition.apiName,
            sourceLabel: definition.sourceLabel,
            sourceValue: definition.defaultValue ?? '',
            canFetchSource: false,
            isTextArea: definition.apiName === 'DMT_Pricing_Grid_or_Step_ups__c',
            defaultOnBlank: !!definition.defaultOnBlank,
            defaultOnLoad: !!definition.defaultOnLoad,
            defaultValue: definition.defaultValue ?? '',
            oldValue: '',
            newValue: ''
        }));
    }

    _extractProfitabilityResult(features, lineItem) {
        if (!Array.isArray(features) || features.length === 0) {
            return {};
        }

        const targetProductId = lineItem?.gf_group_priority_opportunity_id__c ?? null;

        for (const feature of features) {
            const results = feature?.profitability?.results;
            if (!Array.isArray(results) || results.length === 0) {
                continue;
            }

            if (!targetProductId) {
                return results[0] || {};
            }

            const matchedResult = results.find(result => String(result?.productId) === String(targetProductId));
            if (matchedResult) {
                return matchedResult;
            }
        }

        return features[0]?.profitability?.results?.[0] || {};
    }

    _resolveSourceValue(definition, lineItem, underlyings, tenors, profitabilityResult, lineContext) {
        console.log('ABS underlyings ' + JSON.stringify(underlyings));
        console.log('ABS tenors ' + JSON.stringify(tenors));
        console.log('ABS profitabilityResult ' + JSON.stringify(profitabilityResult));
        switch (definition.apiName) {
            case 'DMT_Up_Front_Fee_Accrual__c':
                return lineContext ? '' : this._normalizeDisplayValue(lineItem?.gf_accrual_fees_bp__c);
            case 'DMT_Up_Front_Fee_Non_Accrual__c':
                return lineContext
                    ? this._sumUnderlyingsUpfrontFees(underlyings)
                    : this._sumTwoTenorFields(tenors, 'gf_accrual_fees_bp__c', 'gf_non_accrual_fees_bp__c');
            case 'DMT_Funding_Cost__c':
                return this._normalizeDisplayValue(this._resolveProfitabilityValueByKey('fundingDbPbs', profitabilityResult));
            case 'DMT_Liquidity_Fee__c':
                return this._normalizeDisplayValue(this._resolveProfitabilityValueByKey('fundingFbPbs', profitabilityResult));
            case 'DMT_Interest_Rate_Period__c':
                return lineContext ? '' : this._normalizeDisplayValue(lineItem?.DMT_RateType__c);
            case 'DMT_Applicable_Margin__c':
                return lineContext
                    ? this._sumUnderlyingsNumeric(underlyings, 'DMT_Drawn_Speed__c')
                    : this._resolveFirstTenorValue(tenors, 'gf_spread_db__c');
            case 'DMT_Pricing_Grid_or_Step_ups__c':
                return lineContext ? '' : this._normalizeDisplayValue(lineItem?.DMT_PricingGrid_OR_StepUps__c);
            case 'DMT_Commitment_Fee__c':
                return lineContext
                    ? this._sumUnderlyingsNumeric(underlyings, 'DMT_Undrawn_Spread__c')
                    : this._resolveFirstTenorValue(tenors, 'gf_spread_fb__c');
            case 'DMT_Utilisation_Fee__c':
                return lineContext ? '' : this._normalizeDisplayValue(lineItem?.DMT_Utilisation_Fee__c);
            case 'DMT_Extension_Duration_Fee__c':
                return lineContext ? '' : this._normalizeDisplayValue(lineItem?.DMT_TXT_Extension_Duration_Fees__c);
            case 'DMT_Other_Fees_Accrual__c':
                return lineContext ? '' : this._normalizeDisplayValue(lineItem?.DMT_TXT_Other_Fees_Accrual__c);
            case 'DMT_Other_Fees_Non_Accrual__c':
                return lineContext ? '' : this._normalizeDisplayValue(lineItem?.DMT_TXT_Other_Fees_NonAccrual__c);
            case 'DMT_Expected_Drawn__c':
                return this._normalizeDisplayValue(lineItem?.DMT_Expected_Drawn__c);
            case 'DMT_All_in_Drawn__c':
                return this._normalizeDisplayValue(this._resolveProfitabilityValueByKey('allInDb', profitabilityResult));
            case 'DMT_All_in_Undrawn__c':
                return this._normalizeDisplayValue(this._resolveProfitabilityValueByKey('allInFb', profitabilityResult));
            default:
                return '';
        }
    }

    _resolveProfitabilityValue(definition, profitabilityResult) {
        if (!profitabilityResult) {
            return '';
        }

        if (definition.profitabilityKey === 'spreadTotalPbs') {
            const spreadDb = this._parseNumeric(profitabilityResult.spreadDbPbs);
            const spreadFb = this._parseNumeric(profitabilityResult.spreadFbPbs);

            if (spreadDb === null && spreadFb === null) {
                return '';
            }

            return this._normalizeDisplayValue((spreadDb ?? 0) + (spreadFb ?? 0));
        }

        return this._normalizeDisplayValue(profitabilityResult[definition.profitabilityKey]);
    }

    _resolveProfitabilityValueByKey(key, profitabilityResult) {
        if (!profitabilityResult || !key) {
            return '';
        }

        const rawValue = profitabilityResult[key];
        const numericValue = this._parseNumeric(rawValue);

        return numericValue !== null
            ? numericValue.toFixed(2)
            : (rawValue ?? '');
    }

        _getHelpText(apiName, lineContext) {
        switch (apiName) {
            case 'DMT_Up_Front_Fee_Accrual__c':
                return lineContext
                    ? ''
                    : 'Template: Accrual Fees';
            case 'DMT_Up_Front_Fee_Non_Accrual__c':
                return lineContext
                    ? 'Template: Sum of underlyings'
                    : 'Template: Sum of Non Accrual Fees';
            case 'DMT_Funding_Cost__c':
                return 'Profitability: FC Drawn';
            case 'DMT_Liquidity_Fee__c':
                return 'Profitability: FC Undrawn';
            case 'DMT_Interest_Rate_Period__c':
                return lineContext
                    ? ''
                    : 'Template: Margin Rate Type';
            case 'DMT_Applicable_Margin__c':
                return lineContext
                    ? 'Template: Sum of underlyings.'
                    : 'Template: Drawn Spread (BPS), first payment';
            case 'DMT_Pricing_Grid_or_Step_ups__c':
                return '';
            case 'DMT_Commitment_Fee__c':
                return lineContext
                    ? 'Template: Sum of underlyings.'
                    : 'Template: Undrawn Spread, first payment';
            case 'DMT_Utilisation_Fee__c':
                return lineContext
                    ? ''
                    : 'Template: Utilisation Fee';
            case 'DMT_Extension_Duration_Fee__c':
                return lineContext
                    ? ''
                    : 'Template: Extension/Duration Fee';
            case 'DMT_Other_Fees_Accrual__c':
                return lineContext
                    ? ''
                    : 'Template: Other Fees (accrual)';
            case 'DMT_Other_Fees_Non_Accrual__c':
                return lineContext
                    ? ''
                    : 'Template: Other Fees (non accrual)';
            case 'DMT_Expected_Drawn__c':
                return 'Template: Expected Drawn (%)';
            case 'DMT_All_in_Drawn__c':
                return 'Profitability: All-in Drawn';
            case 'DMT_All_in_Undrawn__c':
                return 'Profitability: All-in Undrawn';
            default:
                return '';
        }
    }

    _isLineContext(lineItem) {
        return String(lineItem?.DMT_Line_Oneoffdeal__c || '').trim().toLowerCase() === 'line';
    }

    _sumTenorValues(tenors, fieldName) {
        if (!Array.isArray(tenors) || tenors.length === 0 || !fieldName) {
            return '';
        }

        let total = 0;
        let hasValue = false;

        tenors.forEach(tenor => {
            const numericValue = this._parseNumeric(tenor?.[fieldName]);
            if (numericValue !== null) {
                total += numericValue;
                hasValue = true;
            }
        });

        return hasValue ? this._normalizeDisplayValue(total) : '';
    }

    _sumTwoTenorFields(tenors, fieldNameA, fieldNameB) {
        const totalA = this._parseNumeric(this._sumTenorValues(tenors, fieldNameA));
        const totalB = this._parseNumeric(this._sumTenorValues(tenors, fieldNameB));

        if (totalA === null && totalB === null) {
            return '';
        }

        return this._normalizeDisplayValue((totalA ?? 0) + (totalB ?? 0));
    }

    _sumUnderlyingsNumeric(underlyings, fieldName) {
        if (!Array.isArray(underlyings) || underlyings.length === 0 || !fieldName) {
            return '';
        }

        let total = 0;
        let hasValue = false;

        underlyings.forEach(row => {
            const numericValue = this._parseNumeric(row?.[fieldName]);
            if (numericValue !== null) {
                total += numericValue;
                hasValue = true;
            }
        });

        return hasValue ? this._normalizeDisplayValue(total) : '';
    }

    _sumUnderlyingsUpfrontFees(underlyings) {
        if (!Array.isArray(underlyings) || underlyings.length === 0) {
            return '';
        }

        let total = 0;
        let hasValue = false;

        underlyings.forEach(row => {
            const unit = this._getUpfrontFeeUnit(row);
            const numericValue = unit === 'BPS'
                ? this._parseNumeric(row?.DMT_Upfront_Fees__c)
                : this._parseNumeric(row?.DMT_Upfront_Fees_amount__c);

            if (numericValue !== null) {
                total += numericValue;
                hasValue = true;
            }
        });

        return hasValue ? this._normalizeDisplayValue(total) : '';
    }

    _getUpfrontFeeUnit(row) {
        const amountValue = this._parseNumeric(row?.DMT_Upfront_Fees_amount__c);
        const bpsValue = this._parseNumeric(row?.DMT_Upfront_Fees__c);

        if (bpsValue !== null && bpsValue !== 0 && (amountValue === null || amountValue === 0)) {
            return 'BPS';
        }

        return 'AMOUNT';
    }

    _resolveFirstTenorValue(tenors, fieldName) {
        if (!Array.isArray(tenors) || tenors.length === 0 || !fieldName) {
            return '';
        }

        for (const tenor of tenors) {
            const value = this._normalizeDisplayValue(tenor?.[fieldName]);
            if (value !== '') {
                return value;
            }
        }

        return '';
    }

    _normalizeDisplayValue(value) {
        if (value === null || value === undefined) {
            return '';
        }

        return String(value);
    }

    _roundNumericDisplayValue(value) {
        const numericValue = this._parseNumeric(value);
        if (numericValue === null) {
            return value;
        }
        const rounded = Math.round(numericValue * 100) / 100;
        return String(rounded);
    }

    _parseNumeric(value) {
        if (value === null || value === undefined || value === '') {
            return null;
        }

        const parsed = Number(value);
        return Number.isFinite(parsed) ? parsed : null;
    }

    _hasNotionalValue(tenor) {
        const drawn = this._parseNumeric(tenor?.gj_nominal_amount_db__c);
        const undrawn = this._parseNumeric(tenor?.gf_nominal_amount_fb__c);

        return (drawn !== null && drawn > 0) || (undrawn !== null && undrawn > 0);
    }   

    handleInputChange(event) {
        const rowKey = event.target.dataset.rowKey;
        const moneyType = event.target.dataset.moneyType;
        const nextValue = this._normalizeDisplayValue(event.target.value);

        this.rows = this.rows.map(row => {
            if (row.key !== rowKey) {
                return row;
            }

            return {
                ...row,
                oldValue: moneyType === 'old' ? nextValue : row.oldValue,
                newValue: moneyType === 'new' ? nextValue : row.newValue
            };
        });
    }

    _sourceValueForRow(row) {
        if (!row) {
            return '';
        }

        const currentSource = this._normalizeDisplayValue(row.sourceValue).trim();
        if (currentSource !== '') {
            return currentSource;
        }

        if (row.defaultOnBlank) {
            return this._normalizeDisplayValue(row.defaultValue).trim();
        }

        return '';
    }

    handleFetchRowSource(event) {
        const rowKey = event.currentTarget.dataset.rowKey;
        const targetRow = this.rows.find(row => row.key === rowKey);
        const sourceValue = this._sourceValueForRow(targetRow);

        if (!targetRow || sourceValue === '') {
            return;
        }

        this.rows = this.rows.map(row => {
            if (row.key !== rowKey) {
                return row;
            }

            return {
                ...row,
                newValue: sourceValue
            };
        });
    }

    handleFetchAll() {
        // Keys de campos que NO deben ser cargados con "Obtener todos"
        const excludedKeys = ['9', '10', '11', '12']; // Utilisation Fee, Extension/Duration Fee, Other Fees Accrual, Other Fees Non-Accrual

        this.rows = this.rows.map(row => {
            // Si el campo está excluido, no cargar
            if (excludedKeys.includes(row.key)) {
                return row;
            }

            const sourceValue = this._sourceValueForRow(row);
            if (sourceValue === '') {
                return row;
            }

            return {
                ...row,
                newValue: sourceValue
            };
        });
    }

    handleCancel() {
        this.close();
    }

    async handleSave() {
        this.isSaving     = true;
        this.hasError     = false;
        this.errorMessage = '';

        try {
            const oldRecord = { DMT_Opportunity_Product__c: this.oppProductId };
            const newRecord = { DMT_Opportunity_Product__c: this.oppProductId };

            if (this._oldMoneyId) { oldRecord.Id = this._oldMoneyId; }
            if (this._newMoneyId) { newRecord.Id = this._newMoneyId; }

            this.rows.forEach(row => {
                oldRecord[row.apiName] = this._normalizeOldValueForSave(row);
                newRecord[row.apiName] = this._normalizeValueForSave(row.newValue, row);
            });

            const saved = await upsertOpportunityMoney({
                oldMoneyJson: JSON.stringify(oldRecord),
                newMoneyJson: JSON.stringify(newRecord)
            });

            this._oldMoneyId = saved?.oldMoney?.Id ?? this._oldMoneyId;
            this._newMoneyId = saved?.newMoney?.Id ?? this._newMoneyId;

            this.dispatchEvent(new ShowToastEvent({
                title:   'Success',
                message: 'Money record saved successfully.',
                variant: 'success'
            }));

            this.close(saved);
        } catch (error) {
            this.hasError     = true;
            this.errorMessage = error?.body?.message
                || 'An unexpected error occurred while saving. Please try again.';
        } finally {
            this.isSaving = false;
        }
    }

    _normalizeValueForSave(value, row) {
        const normalizedValue = this._normalizeDisplayValue(value).trim();
        if (normalizedValue !== '') {
            return normalizedValue;
        }

        if (row?.defaultOnBlank) {
            const defaultValue = this._normalizeDisplayValue(row.defaultValue).trim();
            return defaultValue !== '' ? defaultValue : null;
        }

        return null;
    }

    _normalizeOldValueForSave(row) {
        const editedValue = this._normalizeDisplayValue(row?.oldValue).trim();
        if (editedValue !== '') {
            return editedValue;
        }

        if (row?.defaultOnBlank) {
            const defaultValue = this._normalizeDisplayValue(row.defaultValue).trim();
            return defaultValue !== '' ? defaultValue : null;
        }

        return null;
    }
}