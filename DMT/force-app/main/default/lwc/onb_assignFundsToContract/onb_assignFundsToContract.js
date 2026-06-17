import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';

// CLASSES
import getFundItemsForContract from '@salesforce/apex/ONB_FundItemController.getFundItemsForContract';
import saveFundsForContract from '@salesforce/apex/ONB_FundItemController.saveFundsForContract';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import emptyFunds from '@salesforce/resourceUrl/emptyFunds';

// LABELS
import ONB_FUND_NAME from '@salesforce/label/c.ONB_FUND_NAME';
import ONB_FUND_TYPE from '@salesforce/label/c.ONB_FUND_TYPE';
import ONB_LEI_CIF_STARCODE from '@salesforce/label/c.ONB_LEI_CIF_STARCODE';
import ONB_EMPTY_LIST from '@salesforce/label/c.ONB_EMPTY_LIST';
import ONB_NO_FUNDS from '@salesforce/label/c.ONB_NO_FUNDS';

const PAGE_SIZE = 8;

export default class Onb_assignFundsToContract extends LightningModal {
    @api header;
    @api recordOnboardingId;
    @api contractId;

    emptyFundsImage = emptyFunds;

    @track isBusy = true;
    @track hasLoadedFunds = false;

    labels = {
        ONB_EMPTY_LIST,
        ONB_NO_FUNDS
    }

    connectedCallback() {
        this.isBusy = true;
        this.loadFundsFresh();
    }

    // ===== FUNDS =====
    @track funds = [];
    @track filteredFunds = [];
    @track displayedFunds = [];
    @track selectedFunds = [];
    @track selectionFilter = 'all';
    @track searchFundTerm = ''; 
    @track searchFundTermRaw = ''; 
    @track currentFundPage = 1;
    totalFundPages = 1;
    selectedFundsIds = new Set();

    columns = [
        { key: 'fundType', label: ONB_FUND_TYPE, fieldName: 'ONB_Fund_Type__c', type: 'clampedText', wrapText: true, hideDefaultActions: true },
        { key: 'name', label: ONB_FUND_NAME, fieldName: 'ONB_FundName__c', type: 'clampedText', wrapText: true, hideDefaultActions: true},
        { key: 'lei', label: ONB_LEI_CIF_STARCODE, fieldName: 'lei_id__c', type: 'clampedText', wrapText: true, hideDefaultActions: true }
    ];

    get selectionFilterOptions() {
        return [
            { label: 'All funds', value: 'all' },
            { label: 'Selected funds', value: 'selected' },
            { label: 'Unselected funds', value: 'unselected' }
        ];
    }

    handleSelectionFilterChange(event) {
        this.selectionFilter = event.detail.value;
        this.currentFundPage = 1;
        this.applyFundFilters();
    }

    async loadFundsFresh() {
        this.isBusy = true;
        try {
            const dto = await getFundItemsForContract({
                onboardingId: this.recordOnboardingId,
                contractId: this.contractId,
                cacheBuster: String(Date.now())
            });

            this.funds = dto?.funds || [];

            this.selectedFundsIds = new Set(dto?.preselectedFundIds || []);
            this.selectedFunds = this.funds.filter(f => this.selectedFundsIds.has(f.Id));

            this.currentFundPage = 1;
            this.applyFundFilters();
            this.hasLoadedFunds = true;

        } catch (e) {
            console.error('loadFundsFresh error', e);
            this.showToast('Error', 'Could not load funds for this contract', 'error');
        } finally {
            this.isBusy = false;
        }
    }

    handleFundSearch(event) {
        this.searchFundTermRaw = event?.target?.value || '';
        this.searchFundTerm = this.searchFundTermRaw.toLowerCase();
        this.currentFundPage = 1;
        this.applyFundFilters();
    }

    applyFundFilters() {
        const term = (this.searchFundTerm || '').trim().toLowerCase();

        const toStr = (v) => {
            if (v === null || v === undefined) return '';
            return String(v).toLowerCase();
        };

        let rows = term
            ? this.funds.filter(c => {
                const haystack = [
                    c.ONB_Fund_Type__c,
                    c.ONB_FundName__c,
                    c.lei_id__c
                ].map(toStr).join(' | ');
                return haystack.includes(term);
            })
            : [...this.funds];

        if (this.selectionFilter === 'selected') {
            rows = rows.filter(r => this.selectedFundsIds.has(r.Id));
        } else if (this.selectionFilter === 'unselected') {
            rows = rows.filter(r => !this.selectedFundsIds.has(r.Id));
        }

        this.filteredFunds = rows;

        this.totalFundPages = Math.ceil(this.filteredFunds.length / PAGE_SIZE) || 1;

        if (this.currentFundPage > this.totalFundPages) {
            this.currentFundPage = this.totalFundPages;
        }
        if (this.currentFundPage < 1) {
            this.currentFundPage = 1;
        }

        this.updateFundPagination();
    }



    updateFundPagination() {
        const start = (this.currentFundPage - 1) * PAGE_SIZE;
        const end = start + PAGE_SIZE;
        this.displayedFunds = this.filteredFunds.slice(start, end);
    }

    handleFundPrevPage() {
        if (this.currentFundPage > 1) {
            this.currentFundPage--;
            this.updateFundPagination();
        }
    }
    handleFundNextPage() {
        if (this.currentFundPage < this.totalFundPages) {
            this.currentFundPage++;
            this.updateFundPagination();
        }
    }

    get selectedFundIdsArray() {
        return Array.from(this.selectedFundsIds || []);
    }

    handleFundsSelection(event) {
        const selectedOnPage = new Set((event.detail.selectedRows || []).map(r => r.Id));
        const currentPageIds = this.displayedFunds.map(r => r.Id);
        currentPageIds.forEach(id => {
            if (selectedOnPage.has(id)) this.selectedFundsIds.add(id);
            else this.selectedFundsIds.delete(id);
        });
        this.selectedFunds = this.funds.filter(g => this.selectedFundsIds.has(g.Id));

        if (this.selectionFilter !== 'all') {
            this.applyFundFilters();
        }
    }

    // ===== HELPERS =====
    getSelectedFunds() {
        if (this.selectedFundsIds && this.selectedFundsIds.size)
            return this.funds.filter(g => this.selectedFundsIds.has(g.Id));
        return this.selectedFunds || [];
    }

    finalizar() {
        this.close({
            action: 'confirm',
            funds: this.getSelectedFunds()
        });
    }

    // ===== CONDICIONALES =====
    get isPreviousDisabledFund(){ return this.currentFundPage === 1; }
    get isNextDisabledFund(){ return this.currentFundPage === this.totalFundPages; }
    get fundsLength(){ return this.funds.length > PAGE_SIZE; }

    // ===== UTILS =====
    showToast(title,message,variant){
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleClose() {
        this.close({ action: 'cancel' });
    }

    async handleConfirmSave() {
        const ids = Array.from(this.selectedFundsIds || []);
        this.isBusy = true;

        try {
            await saveFundsForContract({
                contractId: this.contractId,
                selectedFundIds: ids
            });

            this.showToast('Success', 'Funds saved successfully', 'success');
            this.close({ action: 'added', fundIds: ids });

        } catch (e) {
            console.error(e);
            this.showToast('Error', e?.body?.message || 'Could not save funds', 'error');
        } finally {
            this.isBusy = false;
        }
    }

}