import { LightningElement, api, track, wire } from 'lwc';
import getUnderwritingData from '@salesforce/apex/DMT_UnderwritingFormController.getUnderwritingData';
import saveUnderwritingData from '@salesforce/apex/DMT_UnderwritingFormController.saveUnderwritingData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import HAS_GUMS_FIELD from '@salesforce/schema/Opportunity.DMT_HasGUMSProduct__c';
import STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';
import SYSTEMMODSTAMP_FIELD from '@salesforce/schema/Opportunity.SystemModstamp';
import dataTableStyle from '@salesforce/resourceUrl/DMT_DataTableStyle';
import { loadStyle } from 'lightning/platformResourceLoader';

const FLOAT_FIELDS = [
    'operation_underwriting_per__c',
    'opening_fee_per__c',
    'gf_est_fee_cust_sycr_bp_amount__c',
    'SVA__c'
];

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
    originalDealAmountValue = null;

    _lastModstamp = null;

    get table() {
        return this.tableData;
    }
    
    get columns() {
        const isEdit = this.isEditing;
        
        return [
            {
                fieldName: isEdit ? 'gf_loan_br_ctpty_id__c' : 'counterpartyName',
                label: 'Loan Counterparty',
                type: isEdit ? 'genericrecordpicker' : 'text',
                hideDefaultActions: true,
                cellAttributes: { alignment: 'center' },
                typeAttributes: {
                    placeholder: 'Search Accounts...',
                    fieldName: 'gf_loan_br_ctpty_id__c',
                    value: { fieldName: 'gf_loan_br_ctpty_id__c' },
                    label: { fieldName: 'counterpartyName' }, 
                    options: { fieldName: 'counterpartyOptions' },
                    context: { fieldName: 'Id' },
                    disabled: false
                }
            },
            {
                fieldName:"gf_ctpty_sold_order_amount__c",
                label:"Sold Order (amount in units)",
                type: isEdit ? "custominputRow" : 'currency',
                editable:false,
                hideDefaultActions:true,
                cellAttributes:{ alignment: 'center'},
                typeAttributes:{
                    currencyCode: { fieldName: 'Currency__c' },
                    step: '0.001',
                    inputValue: { fieldName: 'gf_ctpty_sold_order_amount__c' },
                    fieldName: 'gf_ctpty_sold_order_amount__c',
                    context: { fieldName: 'Id' }
                }
            },
            {
                fieldName:"gf_sold_ord_ctpty_setl_amount__c",
                label:"Settled Amount (amount in units)",
                type: isEdit ? "custominputRow" : 'currency',
                editable:false,
                hideDefaultActions:true,
                cellAttributes:{ alignment: 'center'},
                typeAttributes:{
                    currencyCode: { fieldName: 'Currency__c' },
                    step: '0.001',
                    inputValue: { fieldName: 'gf_sold_ord_ctpty_setl_amount__c' },
                    fieldName: 'gf_sold_ord_ctpty_setl_amount__c',
                    context: { fieldName: 'Id' }
                }
            },
            {
                fieldName: "gf_sold_order_settled_ind_type__c",
                label: "Settled Order",
                type: isEdit ? "picklist" : "text",
                editable: false,
                hideDefaultActions: true,
                cellAttributes: { alignment: 'center' },
                typeAttributes: {
                    placeholder: 'Select..',
                    options: { fieldName: 'soldOrderSettledOptions' },
                    fieldName: 'gf_sold_order_settled_ind_type__c',
                    value: { fieldName: 'gf_sold_order_settled_ind_type__c' },
                    context: { fieldName: 'Id' }
                  }
            },            
            {
                fieldName:"Currency__c",
                label:"Currency",
                type: isEdit ? "picklist": "text",
                editable:false,
                initialWidth : 100,
                hideDefaultActions:true,
                cellAttributes:{ alignment: 'center'},
                typeAttributes: {
                    placeholder: 'Select..',
                    options: { fieldName: 'currencyOptions' },
                    fieldName: 'Currency__c',
                    value: { fieldName: 'Currency__c' },
                    context: { fieldName: 'Id' }
                  }
            },
            { 
                label: 'Fees Paid to the Market (BPS)',
                fieldName: 'gf_sold_orders_fees_bps_amount__c',
                type: isEdit ? "custominputRow" : 'number',
                hideDefaultActions:true,
                cellAttributes:{ style: 'text-align: center;'},
                typeAttributes: {
                    aviableItem: {fieldName: 'aviableItem'},
                    inputValue: { fieldName: 'gf_sold_orders_fees_bps_amount__c' },
                    fieldName: 'gf_sold_orders_fees_bps_amount__c',
                    context: { fieldName: 'Id' }
                }
            },
            {
                fieldName:"gf_bbva_assur_prtcp_per__c",
                label:"%Underwriting",
                type: isEdit ? "custominputRow": 'percent-fixed',
                editable:false,
                hideDefaultActions:true,
                cellAttributes:{ alignment: 'center'},
                typeAttributes:{
                    step: '0.001',
                    aviableItem: {fieldName: true},
                    inputValue: { fieldName: 'gf_bbva_assur_prtcp_per__c' },
                    fieldName: 'gf_bbva_assur_prtcp_per__c',
                    context: { fieldName: 'Id' },
                    value: { fieldName: 'gf_bbva_assur_prtcp_per__c' }
                }
            },
            {
                type: 'button',
                hideDefaultActions:true,
                cellAttributes:{ alignment: 'center'},
                initialWidth: 65,
                typeAttributes:{ 
                    iconName: 'utility:delete',
                    label: ' ', 
                    name: 'deleteRecord', 
                    title: '', 
                    disabled: {fieldName: 'deleteDisabled'},
                    iconPosition: 'center', 
                    value: 'test'
                }
            },
            {
                type: 'button',
                hideDefaultActions:true,
                cellAttributes:{ alignment: 'center'},
                initialWidth: 65,
                typeAttributes:{ 
                    iconName: 'utility:edit',
                    label: ' ', 
                    name: 'editRecord', 
                    title: '', 
                    disabled: {fieldName: 'editRecordDisabled'},
                    iconPosition: 'center', 
                    value: 'test'
                }
            },
            {
                type: 'button',
                hideDefaultActions:true,
                cellAttributes:{ alignment: 'center'},
                initialWidth: 65,
                typeAttributes:{ 
                    iconName: 'utility:add',
                    label: '', 
                    name: 'addRecord', 
                    title: '', 
                    disabled: {fieldName: 'buttonDisabled'},
                    iconPosition: 'center', 
                    value: 'test'
                }
            }
        ];
    }     
    
        normalizeValue(field, value) {
            if (value === '' || value === undefined || value === null) return null;
            if (field?.type === 'number' || field?.type === 'text') {
                const normalized = typeof value === 'string' 
                    ? value.replace(',', '.') 
                    : value;
                const n = Number(normalized);
                return isNaN(n) ? value : n;
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
            this.counterpartyOptions = (data.soldOrderCounterpartyOptions || []).sort(
                (a, b) => (a.label || '').localeCompare(b.label || '')
              );
            this.currencyOptions = data.soldOrderCurrencyOptions || [];
            this.soldOrderSettledOptions = data.soldOrderSettledOptions || [];

            if (this.hasGUMSProduct) {
                this.picklistOptions = picklistValues['underwriting_agreement_type__c'];
                this.underwritingValue = opp.underwriting_agreement_type__c || null;
                this.originalUnderwritingValue = this.underwritingValue;

                this.dealAmountValue = opp.deal_total_amount__c ?? null;
                this.originalDealAmountValue = this.dealAmountValue;

                this.showForm = !!(this.underwritingValue && this.underwritingValue !== 'No');

                const fieldList = [
                    { label: 'Amount to be sold (amount in units)', apiName: 'gf_current_be_sold_mk_amount__c', type: 'number', readOnly: true },
                    { label: 'SVA', apiName: 'SVA__c', type: 'text', readOnly: false, step: 'any' },
                    { label: '% Underwriting', apiName: 'bbva_participation_per__c', type: 'number', readOnly: false },
                    { label: 'Underwriting fee (BPS)', apiName: 'operation_underwriting_per__c', type: 'text', readOnly: false, step: 'any' },
                    { label: 'Underwriting fee (amounts in units)', apiName: 'underwriting_fee_amount__c', type: 'number', readOnly: true },
                    { label: 'Upfront Fees Amount to be sold (amount in units)', apiName: 'gf_own_undwr_mk_rsk_fee_amount__c', type: 'number', readOnly: true },
                    { label: 'Available fees to the market to reach target hold', apiName: 'gf_upfront_undwr_fees_amount__c', type: 'number', readOnly: true },
                    { label: 'Total Fees paid to market (amount in units)', apiName: 'gf_tot_sold_order_fees_amount__c', type: 'number', readOnly: true },
                    { label: 'Estimated fees paid to the market (BPS)', apiName: 'gf_est_fee_cust_sycr_bp_amount__c', type: 'text', readOnly: false, step: 'any'  },
                    { label: 'Up front fees (BPS)', apiName: 'opening_fee_per__c', type: 'text', readOnly: false, step: 'any'  },
                    { label: 'Risk Committee Approval', apiName: 'risk_committee_aprvl_ind_type__c', type: 'picklist', readOnly: false },
                    { label: 'Contract Signature Date', apiName: 'signing_date__c', type: 'date', readOnly: false },
                    { label: 'Real time market risk (amount in units)', apiName: 'gf_mk_curr_rsk_synd_amount__c', type: 'number', readOnly: true },
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
                    { label: 'Underwriting Committee Additional comments', apiName: 'gf_oppy_undwr_cmtee_comnt_desc__c', type: 'textarea', readOnly: false }
                ];



            const fullFlatFields = fieldList.map(f => {
                let value = opp[f.apiName];
                if (FLOAT_FIELDS.includes(f.apiName) && value != null) {
                    value = String(value).replace('.', ',');
                }
                return {
                    label: f.label,
                    apiName: f.apiName,
                    value: value,
                    type: f.type,
                    readOnly: f.readOnly,
                    isPicklist: f.type === 'picklist',
                    isTextarea: f.type === 'textarea',
                    options: f.type === 'picklist' ? picklistValues[f.apiName] : undefined
                };
            });

                this.fields = fullFlatFields;
                this.originalValues = JSON.parse(JSON.stringify(fullFlatFields));

                const visible = this.applyUnderwritingFilter(this.fields);
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
        const visible = this.applyUnderwritingFilter(this.fields || []);
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
            const FLOAT_FIELDS = [
                'operation_underwriting_per__c',
                'opening_fee_per__c',
                'gf_est_fee_cust_sycr_bp_amount__c',
                'deal_total_amount__c'
            ];
            const { name, value } = event.target;
            const normalizedInput = FLOAT_FIELDS.includes(name)
                ? value.replace(',', '.')
                : value;

            if (name === 'deal_total_amount__c') {
                this.dealAmountValue = normalizedInput; 
                this.isEditing = true;
                return;
            }
            this.fields = (this.fields || []).map(f => {
                if (f.apiName !== name) return f;
                return { 
                    ...f, 
                    value: FLOAT_FIELDS.includes(f.apiName) ? normalizedInput : value 
                };
            });
            const visible = this.applyUnderwritingFilter(this.fields);
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
            if (currentDeal !== originalDeal) {
                changedFields['deal_total_amount__c'] = currentDeal;
            }

            const cleanedFields = JSON.parse(JSON.stringify(changedFields));
            const soldOrdersPayload = this.buildSoldOrdersPayload();
            const idsToDelete = this.idListToDelete || [];

            let errorMessages = [];

            soldOrdersPayload.forEach((row, index) => {
                let rowMissingFields = [];
                const rowNumber = index + 1;

                if (!row.gf_loan_br_ctpty_id__c) {
                    rowMissingFields.push('Loan Counterparty');
                } else {
                    // Check if the selected ID exists in the allowed options (Subsidiaries)
                    const isValidCounterparty = this.counterpartyOptions.some(opt => opt.value === row.gf_loan_br_ctpty_id__c);
                    if (!isValidCounterparty) {
                         errorMessages.push(`Row ${rowNumber}: The selected Loan Counterparty is not a valid 'Subsidiary'. Please select a new one.`);
                    }
                }
                if (row.gf_ctpty_sold_order_amount__c === null || row.gf_ctpty_sold_order_amount__c === '' || row.gf_ctpty_sold_order_amount__c === undefined) {
                    rowMissingFields.push('Sold Order Amount');
                }
                if (row.gf_sold_ord_ctpty_setl_amount__c === null || row.gf_sold_ord_ctpty_setl_amount__c === '' || row.gf_sold_ord_ctpty_setl_amount__c === undefined) {
                    rowMissingFields.push('Settled Amount');
                }

                if (rowMissingFields.length > 0) {
                    errorMessages.push(`Row ${rowNumber}: Missing ${rowMissingFields.join(', ')}`);
                }
            });

            if (errorMessages.length > 0) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Validation Error',
                    message: errorMessages.join('\n'),
                    variant: 'error',
                    mode: 'sticky'
                }));
                this.isSaving = false; 
                return;
            }

            if (Object.keys(cleanedFields).length === 0 && soldOrdersPayload.length === 0 && idsToDelete.length === 0) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'No Changes', message: 'No fields have been modified.', variant: 'info'
                }));
                this.isSaving = false;
                return;
            }

            await saveUnderwritingData({
                recordId: this.recordId,
                updatedFields: cleanedFields,
                soldOrders: soldOrdersPayload,
                idsToDelete: idsToDelete
            });
            
            this.originalUnderwritingValue = this.underwritingValue;
            this.originalDealAmountValue = this.dealAmountValue;
            this.originalValues = JSON.parse(JSON.stringify(this.rows.flatMap(row => row.fields)));
            this.notifyEditMode(false);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success', message: 'Underwriting data saved successfully.', variant: 'success'
            }));

            this.isEditing = false;
            this.fields = this.fields.map(f => {
                if (FLOAT_FIELDS.includes(f.apiName) && f.value != null) {
                    return { ...f, value: String(f.value).replace('.', ',') };
                }
                return f;
            });
            const visible = this.applyUnderwritingFilter(this.fields);
            this.rows = this.buildRows(visible);
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

    handleRecordPickerChange(event) {
        event.stopPropagation();
        const { context, value, label, fieldname } = event.detail.data;
        
        if (fieldname === 'gf_loan_br_ctpty_id__c') {
          this.updateDataValues({
            Id: context,
            gf_loan_br_ctpty_id__c: value,
            counterpartyName: label || ''
          });
        }
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
    
        if (!action || !row) {
            console.error('Row action event mal formado:', JSON.stringify(event.detail));
            return;
        }
    
        switch (action.name) {
            case 'editRecord':
                this.isEditing = true;
                this.tableData = this.tableData.map(e => ({
                    ...e,
                    opportunity_id__c: this.recordId
                }));
                break;
    
            case 'deleteRecord':
                this.isEditing = true;
                if (!Array.isArray(this.idListToDelete)) {
                    this.idListToDelete = [];
                }

                if (row.Id && row.Id.length >= 15 && !row.Id.startsWith('NEW_') && row.Id !== '0') {
                    this.idListToDelete = [...this.idListToDelete, row.Id];
                }

                this.tableData = this.tableData.filter(item => item.Id !== row.Id);
    
                if (this.tableData.length === 0) {
                    this.tableData = [{
                        Id: this.generateTempId(),
                        gf_loan_br_ctpty_id__c: '',
                        gf_ctpty_sold_order_amount__c: '',
                        gf_sold_ord_ctpty_setl_amount__c: '',
                        Currency__c: '',
                        gf_sold_orders_fees_bps_amount__c: '',
                        gf_bbva_assur_prtcp_per__c: '',
                        deleteDisabled: false,
                        buttonDisabled: false,
                        editRecordDisabled: false,
                        opportunity_id__c: this.recordId
                    }];
                } else {
                    this.tableData = this.tableData.map((r, index, arr) => ({
                        ...r,
                        buttonDisabled: index !== arr.length - 1
                    }));
                }
                break;
    
            case 'addRecord':
                this.isEditing = true;  
                const current = Array.isArray(this.tableData) ? [...this.tableData] : [];
                current.forEach(r => { r.buttonDisabled = true; });
                
                const newRow = {
                    Id: this.generateTempId(),
                    gf_loan_br_ctpty_id__c: '',
                    gf_ctpty_sold_order_amount__c: '',
                    gf_sold_ord_ctpty_setl_amount__c: '',
                    Currency__c: '',
                    gf_sold_orders_fees_bps_amount__c: '',
                    gf_bbva_assur_prtcp_per__c: '',
                    counterpartyOptions: this.counterpartyOptions || [],
                    currencyOptions: this.currencyOptions || [],
                    soldOrderSettledOptions: this.soldOrderSettledOptions || [],
                    deleteDisabled: false,
                    buttonDisabled: false,   
                    editRecordDisabled: false,
                    opportunity_id__c: this.recordId
                };
                
                const index = current.findIndex(r => r.Id === row.Id);
                if (index === -1) {
                    current.push(newRow);
                } else {
                    current.splice(index + 1, 0, newRow);
                }
    
                this.tableData = current;
                break;
        }
    }    

    picklistChanged(event) {
        event.stopPropagation();
        let dataRecieved = event.detail.data;
        let updatedItem;
        if (dataRecieved.fieldname === 'gf_loan_br_ctpty_id__c' && dataRecieved.label) {
            const updatedItem = {
              Id: dataRecieved.context,
              gf_loan_br_ctpty_id__c: dataRecieved.value,
              counterpartyName: dataRecieved.label
            };
            this.updateDataValues(updatedItem);
            return;
        }else if( dataRecieved.fieldname === 'gf_ctpty_sold_order_amount__c'){
            updatedItem = { Id: dataRecieved.context, gf_ctpty_sold_order_amount__c: dataRecieved.value };
        }else if( dataRecieved.fieldname === 'gf_sold_ord_ctpty_setl_amount__c'){
            updatedItem = { Id: dataRecieved.context, gf_sold_ord_ctpty_setl_amount__c: dataRecieved.value };
        } else if (dataRecieved.fieldname === 'gf_sold_order_settled_ind_type__c') {
            updatedItem = { Id: dataRecieved.context, gf_sold_order_settled_ind_type__c: dataRecieved.value };
        }else if( dataRecieved.fieldname === 'Currency__c'){
            updatedItem = { Id: dataRecieved.context, Currency__c: dataRecieved.value };
        }else if( dataRecieved.fieldname === 'gf_sold_orders_fees_bps_amount__c'){
            updatedItem = { Id: dataRecieved.context, gf_sold_orders_fees_bps_amount__c: dataRecieved.value };
        }else{
            updatedItem = { Id: dataRecieved.context, gf_bbva_assur_prtcp_per__c: dataRecieved.value };
        }
        this.updateDataValues(updatedItem);
    }

    textInputChanged(event) {
        event.stopPropagation();
        let dataRecieved = event.detail.data;
        let updatedItem;
        updatedItem = { Id: dataRecieved.context};
        updatedItem[dataRecieved.fieldname]= dataRecieved.value;
        
        this.updateDataValues(updatedItem);
    }

    handleChangeCell(event){
        let dataRecieved = event.detail.draftValues;
        let updatedItem;
        updatedItem = { Id: dataRecieved[0].Id, gf_bbva_assur_prtcp_per__c: dataRecieved[0].gf_bbva_assur_prtcp_per__c };
        this.updateDataValues(updatedItem);
    }

    buildSoldOrdersPayload() {
        if (!Array.isArray(this.tableData)) {
            return [];
        }
    
        return this.tableData
            .filter(row =>
                row.gf_loan_br_ctpty_id__c ||
                row.gf_ctpty_sold_order_amount__c ||
                row.gf_sold_ord_ctpty_setl_amount__c ||
                row.gf_sold_order_settled_ind_type__c ||
                row.Currency__c ||
                row.gf_sold_orders_fees_bps_amount__c ||
                row.gf_bbva_assur_prtcp_per__c
            )
            .map(row => {
                const isRealId = (id) => {
                    // Regex checks for exactly 15 or 18 characters, alphanumeric only
                    const sfIdRegex = /^[a-zA-Z0-9]{15}(?:[a-zA-Z0-9]{3})?$/;
                    return id && sfIdRegex.test(id) && !id.startsWith('NEW_') && id !== '0';
                };
                return {
                    Id: isRealId(row.Id) ? row.Id : null,
                    gf_loan_br_ctpty_id__c: row.gf_loan_br_ctpty_id__c || null,
                    gf_ctpty_sold_order_amount__c: row.gf_ctpty_sold_order_amount__c || null,
                    gf_sold_ord_ctpty_setl_amount__c: row.gf_sold_ord_ctpty_setl_amount__c || null,
                    gf_sold_order_settled_ind_type__c: row.gf_sold_order_settled_ind_type__c || null,
                    Currency__c: row.Currency__c || null,
                    gf_sold_orders_fees_bps_amount__c: row.gf_sold_orders_fees_bps_amount__c || null,
                    gf_bbva_assur_prtcp_per__c: row.gf_bbva_assur_prtcp_per__c || null,
                    opportunity_id__c: this.recordId
                };
            });
    }

    applyUnderwritingFilter(flatFields) {
        if (this.underwritingValue === 'Yes') {
            const stopApi = 'risk_committee_aprvl_ind_type__c';
            const stopIndex = flatFields.findIndex(f => f.apiName === stopApi);
            return stopIndex >= 0 ? flatFields.slice(0, stopIndex) : flatFields;
        }
        return flatFields;
    }
      
    buildRows(flatFields) {
        const newRows = [];
        for (let i = 0; i < flatFields.length; i += 2) {
            newRows.push({ rowKey: `row-${i}`, fields: flatFields.slice(i, i + 2) });
        }
        return newRows;
    }
    
    updateDataValues(updateItem) {
        if (!updateItem || !updateItem.Id) {
            return;
        }
        this.isEditing = true;
        let copyData = JSON.parse(JSON.stringify(this.tableData));
    
        const indexToUpdate = copyData.findIndex(item => item.Id === updateItem.Id);
    
        if (indexToUpdate !== -1) {
            for (let key in updateItem) {
                if (updateItem[key] !== undefined) {
                    copyData[indexToUpdate][key] = updateItem[key];
                }
            }
        }
        if (copyData.length > 0) {
            copyData = copyData.map((row, idx, arr) => ({
                ...row,
                buttonDisabled: idx !== arr.length - 1
            }));
        }
        this.tableData = copyData;
    }

    generateTempId() {
        return `NEW_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }
}