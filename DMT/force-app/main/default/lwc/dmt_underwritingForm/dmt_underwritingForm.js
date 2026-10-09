import { LightningElement, api, track, wire } from 'lwc';
import getUnderwritingData from '@salesforce/apex/DMT_UnderwritingFormController.getUnderwritingData';
import saveUnderwritingData from '@salesforce/apex/DMT_UnderwritingFormController.saveUnderwritingData';
import getFormattedAmountsForCurrency
    from '@salesforce/apex/DMT_OppInfoController.getFormattedAmountsForCurrency';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue, deleteRecord } from 'lightning/uiRecordApi';
import SoldOrderModal from 'c/dmt_underwriting_sold_order_modal';
import HAS_GUMS_FIELD from '@salesforce/schema/Opportunity.DMT_HasGUMSProduct__c';
import STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';
import SYSTEMMODSTAMP_FIELD from '@salesforce/schema/Opportunity.SystemModstamp';
import dataTableStyle from '@salesforce/resourceUrl/DMT_DataTableStyle';
import { loadStyle } from 'lightning/platformResourceLoader';

export default class Dmt_underwritingForm extends LightningElement {
    @api recordId;
    @api idListToDelete;
    @track fields = [];
    @track rows = [];
    @track picklistOptions = [];
    @track hasGUMSProduct = false;
    @track showForm = false;
    @track underwritingValue = null;
    @track isSaving = false;
    @track isEditing = false;
    originalValues = [];
    originalUnderwritingValue = null;
    @track tableData = [];
    @track currencyOptions = [];
    @track counterpartyOptions = [];
    @track soldOrderSettledOptions = [];
    @track showCustomTable = true;
    @track stageName;

    @track dealAmountValue = null;
    @track dealAmountLabel = 'Deal Amount';
    originalDealAmountValue = null;

    _lastModstamp = null;

    get table() {
        return this.tableData;
    }

    get columns() {
        return [
            {
                fieldName: 'counterpartyName',
                label: 'Loan Counterparty',
                type: 'text',
                initialWidth: 180,
                hideDefaultActions: true,
                cellAttributes: { alignment: 'center' }
            },
            {
                fieldName: 'Currency__c',
                label: 'Currency',
                type: 'text',
                initialWidth: 70,
                editable: false,
                hideDefaultActions: true,
                cellAttributes: { alignment: 'center' }
            },
            {
                fieldName: 'gf_ctpty_sold_order_amount__c',
                label: 'Sold Order',
                type: 'currency',
                initialWidth: 85,
                editable: false,
                hideDefaultActions: true,
                cellAttributes: { alignment: 'center' },
                typeAttributes: {
                    currencyCode: { fieldName: 'Currency__c' }
                }
            },
            {
                fieldName: 'gf_sold_order_settled_ind_type__c',
                label: 'Settled Order',
                type: 'text',
                initialWidth: 105,
                editable: false,
                hideDefaultActions: true,
                cellAttributes: { alignment: 'center' }
            },
            {
                fieldName: 'gf_sold_ord_ctpty_setl_amount__c',
                label: 'Settled Amount',
                type: 'currency',
                initialWidth: 110,
                editable: false,
                hideDefaultActions: true,
                cellAttributes: { alignment: 'center' },
                typeAttributes: {
                    currencyCode: { fieldName: 'Currency__c' }
                }
            },
            {
                fieldName: 'gf_bbva_assur_prtcp_per__c',
                label: '% Underwriting',
                type: 'percent-fixed',
                initialWidth: 100,
                editable: false,
                hideDefaultActions: true,
                cellAttributes: { alignment: 'center' },
                typeAttributes: { step: '0.001' }
            },
            {
                fieldName: 'gf_prort_setl_order_amount__c',
                label: 'Pro-Rata Settled',
                type: 'currency',
                initialWidth: 125,
                editable: false,
                hideDefaultActions: true,
                cellAttributes: { alignment: 'center' },
                typeAttributes: {
                    currencyCode: { fieldName: 'Currency__c' }
                }
            },
            {
                fieldName: 'gf_sold_orders_fees_bps_amount__c',
                label: 'Fees (BPS)',
                type: 'number',
                initialWidth: 95,
                editable: false,
                hideDefaultActions: true,
                cellAttributes: { alignment: 'center' }
            },
            {
                fieldName: 'gf_sold_order_fees_paid_amount__c',
                label: 'Fees Amount',
                type: 'currency',
                initialWidth: 110,
                editable: false,
                hideDefaultActions: true,
                cellAttributes: { alignment: 'center' },
                typeAttributes: {
                    currencyCode: { fieldName: 'Currency__c' }
                }
            },
            {
                type: 'button-icon',
                hideDefaultActions: true,
                initialWidth: 30,
                cellAttributes: { alignment: 'center' },
                typeAttributes: {
                    iconName: 'utility:delete',
                    name: 'deleteRecord',
                    title: 'Delete Sold Order',
                    alternativeText: 'Delete Sold Order',
                    variant: 'bare',
                    disabled: { fieldName: 'deleteDisabled' }
                }
            },
            {
                type: 'button-icon',
                hideDefaultActions: true,
                initialWidth: 30,
                cellAttributes: { alignment: 'center' },
                typeAttributes: {
                    iconName: 'utility:edit',
                    name: 'editRecord',
                    title: 'Edit Sold Order',
                    alternativeText: 'Edit Sold Order',
                    variant: 'bare',
                    disabled: { fieldName: 'editRecordDisabled' }
                }
            },
            {
                type: 'button-icon',
                hideDefaultActions: true,
                initialWidth: 40,
                cellAttributes: { alignment: 'center' },
                typeAttributes: {
                    iconName: 'utility:add',
                    name: 'addRecord',
                    title: 'Add Sold Order',
                    alternativeText: 'Add Sold Order',
                    variant: 'bare',
                    disabled: { fieldName: 'buttonDisabled' }
                }
            }
        ];
    }

normalizeValue(field, value) {
    if (value === '' || value === undefined || value === null) {
        return null;
    }

    if (field?.type === 'number') {
        if (typeof value === 'number') {
            return value;
        }

        let normalized = value.trim().replace(/\s/g, '');

        if (normalized.includes(',')) {
            normalized = normalized
                .replace(/\./g, '')
                .replace(',', '.');
        }

        const numericValue = Number(normalized);

        if (!Number.isFinite(numericValue)) {
            throw new Error(`Invalid numeric value: ${value}`);
        }

        return numericValue;
    }

    return value;
}

    connectedCallback() {
        loadStyle(this, dataTableStyle);
    }

    @wire(getRecord, { recordId: '$recordId', fields: [SYSTEMMODSTAMP_FIELD, HAS_GUMS_FIELD, STAGE_FIELD] })
    wiredOpp(value) {
        const { data, error } = value || {};
        if (data) {
            const stage = getFieldValue(data, STAGE_FIELD);
            const modstamp = getFieldValue(data, SYSTEMMODSTAMP_FIELD);
            this.stageName = stage;

            this.showCustomTable = stage !== 'Draft' && stage !== 'Proposal';

            this.hasGUMSProduct = true;

            if (this._lastModstamp === null) {
                this._lastModstamp = modstamp;
                this.loadData();
                return;
            }

            if (this._lastModstamp !== modstamp) {
                this._lastModstamp = modstamp;
                if (!this.isEditing && !this.isSaving) {
                    this.loadData();
                }
            }
        } else if (error) {
            console.error('Error in wiredOpp:', error);
        }
    }

    get showSoldOrdersTable() {
        const stageOk = this.showCustomTable;
        const underwritingOk = !!this.underwritingValue && this.underwritingValue !== 'No';
        return stageOk && underwritingOk;
    }

    async loadData() {
        try {
            const data = await getUnderwritingData({ recordId: this.recordId });
            const opp = data.opportunity;
            const picklistValues = data.picklistValues;
            this.currencyOptions = data.soldOrderCurrencyOptions || [];
            this.soldOrderSettledOptions = data.soldOrderSettledOptions || [];

            if (this.hasGUMSProduct) {
                this.picklistOptions = picklistValues['underwriting_agreement_type__c'];
                this.underwritingValue = opp.underwriting_agreement_type__c || null;
                this.originalUnderwritingValue = this.underwritingValue;


                this.showForm = !!(this.underwritingValue && this.underwritingValue !== 'No');

                let displayedDealAmount = opp.DMT_Opportunity_amount__c ?? null;

                if (opp.DMT_CurrencyText__c) {
                    try {
                        const formattedAmounts = await getFormattedAmountsForCurrency({
                            opportunityId: this.recordId,
                            currencyText: opp.DMT_CurrencyText__c
                        });

                        displayedDealAmount =
                            formattedAmounts?.DMT_Opportunity_amount__c ??
                            displayedDealAmount;
                    } catch (error) {
                        console.error(
                            '[dmt_underwritingForm] Error formatting Deal Amount:',
                            error
                        );
                    }
                }

                this.dealAmountValue = displayedDealAmount;
                this.originalDealAmountValue = displayedDealAmount;

                const commitment = opp.bbva_prtcp_tranche_amount__c;
                const dealAmount = opp.DMT_Opportunity_amount__c;

                const amountToBeSold =
                    commitment !== null &&
                    commitment !== undefined &&
                    dealAmount !== null &&
                    dealAmount !== undefined
                        ? Number(commitment) - Number(dealAmount)
                        : null;

                const amountCurrency = opp.DMT_CurrencyText__c || '';

                const amountUnit = data.currencyLabel || 'Units';

                const amountContext = [amountCurrency, amountUnit]
                    .filter(Boolean)
                    .join(' ');

                this.dealAmountLabel = `Deal Amount (${amountContext})`;

                const fieldList = [
                    { label: 'Amount to be sold (amount in units)', apiName: 'gf_current_be_sold_mk_amount__c', type: 'number', readOnly: true },
                    { label: '% Underwriting', apiName: 'bbva_participation_per__c', type: 'number', readOnly: false, isPercentage: true, step: 'any' },
                    { label: 'Underwriting fee (BPS)', apiName: 'operation_underwriting_per__c', type: 'number', readOnly: false, preserveDecimals: true },
                    { label: 'Underwriting fee (amounts in units)', apiName: 'underwriting_fee_amount__c', type: 'number', readOnly: false },
                    { label: 'Upfront Fees Amount to be sold (amount in units)', apiName: 'gf_own_undwr_mk_rsk_fee_amount__c', type: 'number', readOnly: true },
                    { label: 'Available fees to the market to reach target hold', apiName: 'gf_upfront_undwr_fees_amount__c', type: 'number', readOnly: true },
                    { label: 'Total Fees paid to market (amount in units)', apiName: 'gf_tot_sold_order_fees_amount__c', type: 'number', readOnly: true },
                    { label: 'Estimated fees paid to the market (BPS)', apiName: 'gf_est_fee_cust_sycr_bp_amount__c', type: 'number', readOnly: false, preserveDecimals: true },
                    { label: 'Up front fees (BPS)', apiName: 'opening_fee_per__c', type: 'number', readOnly: false, preserveDecimals: true },
                    { label: 'Risk Committee Approval', apiName: 'risk_committee_aprvl_ind_type__c', type: 'picklist', readOnly: false },
                    { label: 'Real time market risk (amount in units)', apiName: 'gf_mk_curr_rsk_synd_amount__c', type: 'number', readOnly: true },
                    { label: 'SVA (Syndication Value Added)', apiName: 'SVA__c', type: 'number', readOnly: false, preserveDecimals: true },
                    { label: 'Amount of sold orders (amount in units)', apiName: 'gf_total_nominal_sold_amount__c', type: 'number', readOnly: true },
                    { label: 'Total settled amount (Amount in units)', apiName: 'gf_total_sold_ord_stl_amount__c', type: 'number', readOnly: true },
                    { label: 'Pending amount to be settled (amount in units)', apiName: 'gf_tl_sold_ord_not_stl_amount__c', type: 'number', readOnly: true },
                    { label: 'Current hold (amount in units)', apiName: 'gf_comt_not_settled_amount__c', type: 'number', readOnly: true },
                    { label: 'Total amount of Pro-rata Sold orders (amount in units)', apiName: 'gf_prort_sale_ord_sum_amount__c', type: 'number', readOnly: true },
                    { label: 'Total Pro-rata Settlement amount (amount in units)', apiName: 'gf_prort_setl_order_tl_amount__c', type: 'number', readOnly: true },
                    { label: 'Risk approved sell date', apiName: 'risk_effective_date__c', type: 'date', readOnly: false },
                    { label: 'Settlement Date', apiName: 'gf_settlement_date__c', type: 'date', readOnly: false },
                    { label: 'Financial Closing Date', apiName: 'gf_oppy_credit_agree_sign_date__c', type: 'date', readOnly: false },
                    { label: 'CLAN Number', apiName: 'clan_syndicated_loan_id__c', type: 'text', readOnly: false },
                    { label: 'Underwriting Year', apiName: 'gf_opportunity_end_year_id__c', type: 'number', readOnly: true },
                    { label: 'Sanction Year', apiName: 'gf_oppy_undwr_approval_year_id__c', type: 'number', readOnly: true },
                    { label: 'Underwriting Committee Approval', apiName: 'oppy_undwr_cmtee_rspse_type__c', type: 'picklist', readOnly: false },
                    { label: 'Underwriting Approval Date', apiName: 'oppy_undwr_cmtee_approval_date__c', type: 'date', readOnly: false },
                    { label: 'Sell Down Commitment Date', apiName: 'oppy_product_ctrct_comt_date__c', type: 'date', readOnly: false },
                    { label: 'Underwriting Committee Additional comments', apiName: 'gf_oppy_undwr_cmtee_comnt_desc__c', type: 'textarea', readOnly: false },
                    { label: 'BBVA Commitment', apiName: 'bbva_prtcp_tranche_amount__c', type: 'number', readOnly: true},
                    { label: 'BBVA Final Take', apiName: 'syndicated_loan_drawn_amount__c', type: 'number', readOnly: true}
                ];


                const amountFieldApiNames = new Set([
                    'gf_current_be_sold_mk_amount__c',
                    'underwriting_fee_amount__c',
                    'gf_own_undwr_mk_rsk_fee_amount__c',
                    'gf_upfront_undwr_fees_amount__c',
                    'gf_tot_sold_order_fees_amount__c',
                    'gf_mk_curr_rsk_synd_amount__c',
                    'SVA__c',
                    'gf_total_nominal_sold_amount__c',
                    'gf_total_sold_ord_stl_amount__c',
                    'gf_tl_sold_ord_not_stl_amount__c',
                    'gf_comt_not_settled_amount__c',
                    'gf_prort_sale_ord_sum_amount__c',
                    'gf_prort_setl_order_tl_amount__c',
                    'bbva_prtcp_tranche_amount__c',
                    'syndicated_loan_drawn_amount__c'
                ]);


                const fullFlatFields = fieldList.map(f => {
                const cleanLabel = f.label
                    .replace(/\s*\(amounts? in units\)/gi, '')
                    .trim();

                return {
                        label: amountFieldApiNames.has(f.apiName)
                            ? `${cleanLabel} (${amountContext})`
                            : f.label,
                        apiName: f.apiName,
                        value: f.apiName === 'gf_current_be_sold_mk_amount__c'
                            ? amountToBeSold
                            : opp[f.apiName],
                        type: f.type,
                        readOnly: f.readOnly,
                        isPercentage: f.isPercentage,
                        preserveDecimals: f.preserveDecimals === true,
                        step: f.step,
                        isPicklist: f.type === 'picklist',
                        isTextarea: f.type === 'textarea',
                        options: f.type === 'picklist'
                            ? picklistValues[f.apiName]
                            : undefined
                    };
                });
                this.fields = fullFlatFields;
                this.originalValues = JSON.parse(JSON.stringify(fullFlatFields));

                const visible = this.fields;
                this.rows = this.buildRows(visible);

                const soldOrders = data.soldOrders || [];

                if (soldOrders.length > 0) {
                    this.tableData = soldOrders.map(so => ({
                        ...so,
                        counterpartyName: so.gf_loan_br_ctpty_id__r?.Name || '',
                        counterpartyOptions: this.counterpartyOptions || [],
                        currencyOptions: this.currencyOptions || [],
                        soldOrderSettledOptions: this.soldOrderSettledOptions || [],
                        deleteDisabled: false,
                        buttonDisabled: true,
                        editRecordDisabled: false
                    }));

                    this.tableData[0].buttonDisabled = true;
                    this.tableData[this.tableData.length - 1].buttonDisabled = false;
                } else {
                    this.tableData = [{
                        Id: this.generateTempId(),
                        gf_loan_br_ctpty_id__c: '',
                        counterpartyName: '',
                        counterpartyOptions: this.counterpartyOptions || [],
                        currencyOptions: this.currencyOptions || [],
                        soldOrderSettledOptions: this.soldOrderSettledOptions || [],
                        gf_ctpty_sold_order_amount__c: '',
                        gf_sold_ord_ctpty_setl_amount__c: '',
                        gf_sold_order_settled_ind_type__c: '',
                        Currency__c: '',
                        gf_sold_orders_fees_bps_amount__c: '',
                        gf_bbva_assur_prtcp_per__c: '',
                        deleteDisabled: false,
                        buttonDisabled: false,
                        editRecordDisabled: false,
                        opportunity_id__c: this.recordId
                    }];
                }
            } else {
                this.underwritingValue = null;
                this.showForm = false;
                this.rows = [];
                this.picklistOptions = [];
                this.dealAmountValue = null;
                this.tableData = [];
            }
        } catch (error) {
            console.error('Error in loadData:', error);
        }
    }

    handleUnderwritingChange(event) {
        this.underwritingValue = event.detail.value || null;
        this.showForm = !!(this.underwritingValue && this.underwritingValue !== 'No');
        this.isEditing = true;
        const visible = this.fields || [];
        this.rows = this.buildRows(visible);
    }

    notifyEditMode(value) {
        this.dispatchEvent(new CustomEvent('editmodetab', {
            detail   : { editMode: value },
            bubbles  : true,
            composed : true
        }));
    }

    handleChange(event) {
        const { name, value } = event.target;
        if (name === 'DMT_Opportunity_amount__c') {
            this.dealAmountValue = this.normalizeValue({ type: 'number' }, value);
            this.isEditing = true;
            return;
        }
        this.fields = (this.fields || []).map(f =>
            f.apiName === name ? { ...f, value } : f
        );
        const visible = this.fields;
        this.rows = this.buildRows(visible);
        this.isEditing = true;
    }

    async handleSave() {
        this.isSaving = true;
        try {
            const changedFields = {};
            this.rows.forEach(row => {
                row.fields.forEach(field => {
                    const original = this.originalValues.find(f => f.apiName === field.apiName);
                    const currentNorm = this.normalizeValue(field, field.value);
                    const originalNorm = this.normalizeValue(field, original?.value);
                    if (currentNorm !== originalNorm) {
                        changedFields[field.apiName] = currentNorm;
                    }
                });
            });

            if (this.underwritingValue !== this.originalUnderwritingValue) {
                changedFields['underwriting_agreement_type__c'] = this.underwritingValue ?? null;
            }
            const currentDeal = this.normalizeValue({ type: 'number' }, this.dealAmountValue);
            const originalDeal = this.normalizeValue({ type: 'number' }, this.originalDealAmountValue);
            /*if (currentDeal !== originalDeal) {
                changedFields['deal_total_amount__c'] = currentDeal;
            }*/

            const cleanedFields = JSON.parse(JSON.stringify(changedFields));

            if (Object.keys(cleanedFields).length === 0) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'No Changes', message: 'No fields have been modified.', variant: 'info'
                }));
                this.isSaving = false;
                return;
            }

            await saveUnderwritingData({
                recordId: this.recordId,
                updatedFields: cleanedFields,
                soldOrders: [],
                idsToDelete: []
            });

            this.originalUnderwritingValue = this.underwritingValue;
            this.originalDealAmountValue = this.dealAmountValue;
            this.originalValues = JSON.parse(JSON.stringify(this.rows.flatMap(row => row.fields)));
            this.notifyEditMode(false);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success', message: 'Underwriting data saved successfully.', variant: 'success'
            }));

            this.isEditing = false;
            await this.loadData();

        } catch (error) {
            console.error('***Error saving data:', error);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error', message: error?.body?.message || 'An error occurred while saving.', variant: 'error'
            }));
        } finally {
            this.isSaving = false;
        }
    }

    async handleCancel() {
        this.notifyEditMode(false);
        this.isEditing = false;
        this.idListToDelete = [];
        try {
            await this.loadData();
        } catch (e) {
            console.error('Error reloading data on cancel', e);
        }
    }

    enterEditMode() {
        this.notifyEditMode(true);
        this.isEditing = true;
    }


    async handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        if (!action || !row) {
            console.error('Row action event mal formado:', JSON.stringify(event.detail));
            return;
        }

        switch (action.name) {
            case 'editRecord':
                await this._openSoldOrderModal(row);
                break;

            case 'addRecord':
                await this._openSoldOrderModal(null);
                break;

            case 'deleteRecord': {
                const isRealId = row.Id
                    && !row.Id.startsWith('NEW_')
                    && row.Id !== '0'
                    && row.Id.length >= 15;

                if (isRealId) {
                    try {
                        await deleteRecord(row.Id);
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Deleted',
                            message: 'Sold Order deleted successfully.',
                            variant: 'success'
                        }));
                    } catch (error) {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error deleting',
                            message: error?.body?.message || 'Could not delete the Sold Order.',
                            variant: 'error'
                        }));
                        return;
                    }
                }

                this.tableData = this.tableData.filter(item => item.Id !== row.Id);

                if (this.tableData.length === 0) {
                    this.tableData = [{
                        Id: this.generateTempId(),
                        gf_loan_br_ctpty_id__c: '',
                        counterpartyName: '',
                        counterpartyOptions: this.counterpartyOptions || [],
                        currencyOptions: this.currencyOptions || [],
                        soldOrderSettledOptions: this.soldOrderSettledOptions || [],
                        gf_ctpty_sold_order_amount__c: '',
                        gf_sold_ord_ctpty_setl_amount__c: '',
                        gf_sold_order_settled_ind_type__c: '',
                        Currency__c: '',
                        gf_sold_orders_fees_bps_amount__c: '',
                        gf_bbva_assur_prtcp_per__c: '',
                        deleteDisabled: false,
                        buttonDisabled: false,
                        editRecordDisabled: false,
                        opportunity_id__c: this.recordId
                    }];
                } else {
                    this.tableData = this.tableData.map((r, idx, arr) => ({
                        ...r,
                        buttonDisabled: idx !== arr.length - 1
                    }));
                }
                if (isRealId) {
                    await this.loadData();
                }
                break;
            }
        }
    }

    async _openSoldOrderModal(row) {
        try {
            const result = await SoldOrderModal.open({
                size: 'medium',
                record: row,
                opportunityId: this.recordId,
                currencyOptions: this.currencyOptions,
                soldOrderSettledOptions: this.soldOrderSettledOptions
            });

            if (!result) {
                return;
            }

            this._updateTableFromSoldOrders(result);
            // Refresca los campos resumen de la Opportunity
            await this.loadData();

            this.dispatchEvent(new ShowToastEvent({
                title: row ? 'Updated' : 'Created',
                message: row
                    ? 'Sold Order updated successfully.'
                    : 'Sold Order created successfully.',
                variant: 'success'
            }));

        } catch (error) {
            console.error('Error opening Sold Order modal:', error);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: error?.body?.message || error?.message || 'An error occurred.',
                variant: 'error'
            }));
        }
    }

    _updateTableFromSoldOrders(soldOrders) {
        if (soldOrders && soldOrders.length > 0) {
            this.tableData = soldOrders.map(so => ({
                ...so,
                counterpartyName        : so.gf_loan_br_ctpty_id__r?.Name || '',
                counterpartyOptions     : this.counterpartyOptions || [],
                currencyOptions         : this.currencyOptions || [],
                soldOrderSettledOptions : this.soldOrderSettledOptions || [],
                deleteDisabled          : false,
                buttonDisabled          : true,
                editRecordDisabled      : false
            }));
            this.tableData[this.tableData.length - 1].buttonDisabled = false;
        } else {
            this.tableData = [{
                Id: this.generateTempId(),
                gf_loan_br_ctpty_id__c: '',
                counterpartyName: '',
                counterpartyOptions     : this.counterpartyOptions || [],
                currencyOptions         : this.currencyOptions || [],
                soldOrderSettledOptions : this.soldOrderSettledOptions || [],
                gf_ctpty_sold_order_amount__c: '',
                gf_sold_ord_ctpty_setl_amount__c: '',
                gf_sold_order_settled_ind_type__c: '',
                Currency__c: '',
                gf_sold_orders_fees_bps_amount__c: '',
                gf_bbva_assur_prtcp_per__c: '',
                deleteDisabled: false,
                buttonDisabled: false,
                editRecordDisabled: false,
                opportunity_id__c: this.recordId
            }];
        }
    }



    buildRows(flatFields) {
        const newRows = [];
        for (let i = 0; i < flatFields.length; i += 2) {
            newRows.push({ rowKey: `row-${i}`, fields: flatFields.slice(i, i + 2) });
        }
        return newRows;
    }


    generateTempId() {
        return `NEW_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }

    handlePercentageKeyDown(event) {
        if (
            event.key.length === 1 && !/[0-9.,]/.test(event.key)
        ) {
            event.preventDefault();
        }
    }

}