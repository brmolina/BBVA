import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';
import saveSoldOrderRow from '@salesforce/apex/DMT_UnderwritingFormController.saveSoldOrderRow';
import searchCounterparties from '@salesforce/apex/DMT_UnderwritingFormController.searchCounterparties';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DmtUnderwritingSoldOrderModal extends LightningModal {

    @api record;
    @api opportunityId;
    @track counterpartyOptions = [];
    @api currencyOptions = [];
    @api soldOrderSettledOptions = [];

    @track formData = {};
    @track errorMessage = '';
    @track isLoading = false;

    get modalTitle() {
        const isEdit = this.record?.Id
            && !this.record.Id.startsWith('NEW_')
            && this.record.Id !== '0'
            && this.record.Id.length >= 15;
        return isEdit ? 'Edit Sold Order' : 'New Sold Order';
    }

    connectedCallback() {
        this.formData = {
            gf_loan_br_ctpty_id__c       : this.record?.gf_loan_br_ctpty_id__c        ?? '',
            counterpartyName             : this.record?.counterpartyName               ?? '',
            gf_ctpty_sold_order_amount__c: this.record?.gf_ctpty_sold_order_amount__c ?? null,
            gf_sold_ord_ctpty_setl_amount__c: this.record?.gf_sold_ord_ctpty_setl_amount__c ?? null,
            gf_sold_order_settled_ind_type__c: this.record?.gf_sold_order_settled_ind_type__c ?? '',
            Currency__c                  : this.record?.Currency__c                    ?? '',
            gf_sold_orders_fees_bps_amount__c: this.record?.gf_sold_orders_fees_bps_amount__c ?? null,
            gf_bbva_assur_prtcp_per__c   : this.record?.gf_bbva_assur_prtcp_per__c    ?? null
        };
    }

    handleCounterpartyChange(event) {
        const { value, label } = event.detail.data;
        this.formData = {
            ...this.formData,
            gf_loan_br_ctpty_id__c: value || '',
            counterpartyName: label || ''
        };
        this.errorMessage = '';
    }

    async handleCounterpartySearch(event) {
        const { term } = event.detail;
        if (!term || term.length < 2) {
            this.counterpartyOptions = [];
            return;
        }
        try {
            const results = await searchCounterparties({ searchTerm: term });
            this.counterpartyOptions = results || [];
        } catch (e) {
            console.error('Error searching counterparties:', e);
        }
    }

    get saveButtonLabel() {
        return this.isLoading ? 'Saving...' : 'Save';
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        this.formData = { ...this.formData, [field]: value };
    }

    handleComboboxChange(event) {
        const field = event.target.dataset.field;
        const value = event.detail.value;
        this.formData = { ...this.formData, [field]: value };
    }

    handleCancel() {
        this.close();
    }

    async handleSave() {
        if (!this.formData.gf_loan_br_ctpty_id__c) {
            this.errorMessage = 'Loan Counterparty is required.';
            return;
        }
        if (this.formData.gf_ctpty_sold_order_amount__c === null
            || this.formData.gf_ctpty_sold_order_amount__c === ''
            || this.formData.gf_ctpty_sold_order_amount__c === undefined) {
            this.errorMessage = 'Sold Order Amount is required.';
            return;
        }
        if (this.formData.gf_sold_ord_ctpty_setl_amount__c === null
            || this.formData.gf_sold_ord_ctpty_setl_amount__c === ''
            || this.formData.gf_sold_ord_ctpty_setl_amount__c === undefined) {
            this.errorMessage = 'Settled Amount is required.';
            return;
        }

        this.isLoading = true;
        this.errorMessage = '';

        await Promise.resolve();

        try {
            const isRealId = this.record?.Id
                && !this.record.Id.startsWith('NEW_')
                && this.record.Id !== '0'
                && this.record.Id.length >= 15;

            const toNum = (v) => {
                if (v === null || v === '' || v === undefined) {
                    return null;
                }

                const normalized = typeof v === 'string'
                    ? v.replace(',', '.')
                    : v;

                const n = Number(normalized);

                if (Number.isNaN(n)) {
                    throw new Error(`Invalid number value: ${v}`);
                }

                return n;
            };

            const soldOrder = {
                sobjectType                  : 'Sold_Order__c',
                gf_loan_br_ctpty_id__c       : this.formData.gf_loan_br_ctpty_id__c || null,
                gf_ctpty_sold_order_amount__c: toNum(this.formData.gf_ctpty_sold_order_amount__c),
                gf_sold_ord_ctpty_setl_amount__c: toNum(this.formData.gf_sold_ord_ctpty_setl_amount__c),
                gf_sold_order_settled_ind_type__c: this.formData.gf_sold_order_settled_ind_type__c || null,
                Currency__c                  : this.formData.Currency__c || null,
                gf_sold_orders_fees_bps_amount__c: toNum(this.formData.gf_sold_orders_fees_bps_amount__c),
                gf_bbva_assur_prtcp_per__c   : toNum(this.formData.gf_bbva_assur_prtcp_per__c)
            };

            if (isRealId) {
                soldOrder.Id = this.record.Id;
            }

            const refreshedSoldOrders = await saveSoldOrderRow({
                soldOrder,
                opportunityId: this.opportunityId
            });

            this.close(refreshedSoldOrders);
        }   catch (error) {
                const rawMessage =
                    error?.body?.message ||
                    error?.message ||
                    '';

                console.error('Error saving Sold Order:', rawMessage);

                if (rawMessage.includes('REQUIRED_FIELD_MISSING')) {
                    const match = rawMessage.match(
                        /Required fields are missing:\s*\[([^\]]+)\]/i
                    );

                    const missingFields = match?.[1];

                    this.errorMessage = missingFields
                        ? `Complete the following required fields: ${missingFields}.`
                        : 'Complete all required fields before saving.';
                } else if (rawMessage.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                    this.errorMessage =
                        'The Sold Order does not meet one of the validation rules. Please review the entered data.';
                } else {
                    this.errorMessage =
                        'The Sold Order could not be saved. Please review the entered data or contact support.';
                }
            } finally {
            this.isLoading = false;
        }
    }
}