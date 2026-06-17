import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';

import getExistingContracts from '@salesforce/apex/ONB_MasterAgreementsController.getExistingContracts';
import createOnboardingContractsJunction from '@salesforce/apex/ONB_MasterAgreementsController.createOnboardingContractsJunction';


import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import emptyFunds from '@salesforce/resourceUrl/emptyFunds'; 

// LABELS
import ONB_CONTRACT_TYPE from '@salesforce/label/c.ONB_CONTRACT_TYPE';
import ONB_GEOGRAPHY from '@salesforce/label/c.ONB_GEOGRAPHY';
import ONB_CONTRACT_DIGITAL_SIGNATURE from '@salesforce/label/c.ONB_CONTRACT_DIGITAL_SIGNATURE';
import ONB_CONTRACT_WHO_PROVIDES from '@salesforce/label/c.ONB_CONTRACT_WHO_PROVIDES';
import ONB_CONTRACT_COLLATERAL_ANNEX from '@salesforce/label/c.ONB_CONTRACT_COLLATERAL_ANNEX';
import ONB_ASSETS from '@salesforce/label/c.ONB_ASSETS';
import ONB_MONITORIZATION_REQUIRED from '@salesforce/label/c.ONB_MONITORIZATION_REQUIRED';
import ONB_CONTRACT_ASSOCIATED from '@salesforce/label/c.ONB_CONTRACT_ASSOCIATED';
import ONB_EMPTY_LIST from '@salesforce/label/c.ONB_EMPTY_LIST';
import ONB_NO_EXISTING_CONTRACTS from '@salesforce/label/c.ONB_NO_EXISTING_CONTRACTS';

const PAGE_SIZE = 8;

export default class Onb_selectExistingContract extends LightningModal {
    @api header;
    @api recordOnboardingId;

    emptyFundsImage = emptyFunds;

    @track isBusy = true;              
    @track hasLoadedContracts = false;

    labels = {
        ONB_EMPTY_LIST,
        ONB_NO_EXISTING_CONTRACTS
    }

    connectedCallback() {
        this.isBusy = true;
        this.loadContractsFresh();
    }

    // ===== CONTRACTS =====
    @track contracts = [];
    @track filteredContracts = [];
    @track displayedContracts = [];
    @track selectedContracts = [];
    @track searchContractTerm = '';
    @track currentContractPage = 1;
    totalContractPages = 1;
    selectedContractsIds = new Set();

    columns = [
        { key: 'contractType', label: ONB_CONTRACT_TYPE, fieldName: 'master_agreement_type__c', type: 'clampedText', wrapText: true, hideDefaultActions: true},
        { key: 'geography', label: ONB_GEOGRAPHY, fieldName: 'ONB_Geography__c', type: 'clampedText', wrapText: true, hideDefaultActions: true},
        { key: 'digitalSignature', label: ONB_CONTRACT_DIGITAL_SIGNATURE, fieldName: 'ONB_Digital_signature__c', type: 'checkboxReadOnly', wrapText: true, hideDefaultActions: true, cellAttributes: { alignment: 'center' }},
        { key: 'whoProvides', label: ONB_CONTRACT_WHO_PROVIDES, fieldName: 'ONB_Who_provides__c', type: 'clampedText', wrapText: true, hideDefaultActions: true },
        { key: 'collateralAnnex', label: ONB_CONTRACT_COLLATERAL_ANNEX, fieldName: 'ONB_Annex__c', type: 'clampedText', wrapText: true, hideDefaultActions: true },
        { key: 'assets', label: ONB_ASSETS, fieldName: 'ONB_Assets__c',  type: 'clampedText', wrapText: true, hideDefaultActions: true },
        { key: 'monitorizationRequired', label: ONB_MONITORIZATION_REQUIRED, fieldName: 'ONB_IM_monitorization_required__c', type: 'clampedText', wrapText: true, hideDefaultActions: true },
        { key: 'contractAssociated', label: ONB_CONTRACT_ASSOCIATED, fieldName: 'ONB_Is_the_contract_associated__c', type: 'clampedText', wrapText: true, hideDefaultActions: true }
    ];

    async loadContractsFresh({ preserveSelection = false } = {}) {
        try {
            const data = await getExistingContracts({ onboardingId: this.recordOnboardingId });
            this.contracts = data; 

            this.currentContractPage = 1;
            this.applyContractFilters();

            if (!preserveSelection) {
                this.selectedContractsIds?.clear?.();
                this.selectedContracts = [];
            } else {
                this.selectedContracts = this.contracts.filter(g => this.selectedContractsIds.has(g.Id));
            }

            this.hasLoadedContracts = true;
        } catch (e) {
            console.error('loadContractsFresh error', e);
            this.showToast('Error', 'Could not load existing contracts', 'error');
        } finally {
            this.isBusy = false;
        }
    }

    handleContractSearch(event) {
        this.searchContractTerm = (event?.target?.value || '').toLowerCase();
        this.currentContractPage = 1;
        this.applyContractFilters();
    }

    applyContractFilters() {
        const term = (this.searchContractTerm || '').trim().toLowerCase();

        const toStr = (v) => {
            if (v === null || v === undefined) return '';
            return String(v).toLowerCase();
        };

        this.filteredContracts = term
            ? this.contracts.filter(c => {
                const haystack = [
                    c.master_agreement_type__c,
                    c.ONB_Geography__c,
                    c.ONB_Who_provides__c,
                    c.ONB_Collateral_Annex__c
                ]
                .map(toStr)
                .join(' | ');

                return haystack.includes(term);
            })
            : [...this.contracts];

        this.totalContractPages = Math.ceil(this.filteredContracts.length / PAGE_SIZE) || 1;
        this.updateContractPagination();
    }


    updateContractPagination() {
        const start = (this.currentContractPage - 1) * PAGE_SIZE;
        const end = start + PAGE_SIZE;
        this.displayedContracts = this.filteredContracts.slice(start, end);
    }

    handleContractPrevPage() {
        if (this.currentContractPage > 1) {
            this.currentContractPage--;
            this.updateContractPagination();
        }
    }
    handleContractNextPage() {
        if (this.currentContractPage < this.totalContractPages) {
            this.currentContractPage++;
            this.updateContractPagination();
        }
    }

    get selectedContractsIdsArray() { return Array.from(this.selectedContractsIds); }

    handleContractsSelection(event) {
        const selectedOnPage = new Set((event.detail.selectedRows || []).map(r => r.Id));
        const currentPageIds = this.displayedContracts.map(r => r.Id);
        currentPageIds.forEach(id => {
            if (selectedOnPage.has(id)) this.selectedContractsIds.add(id);
            else this.selectedContractsIds.delete(id);
        });
        this.selectedContracts = this.contracts.filter(g => this.selectedContractsIds.has(g.Id));
    }

    // ===== HELPERS =====
    getSelectedContracts() {
        if (this.selectedContractsIds && this.selectedContractsIds.size)
            return this.contracts.filter(g => this.selectedContractsIds.has(g.Id));
        return this.selectedContracts || [];
    }
    get isSingleContractSelected() {
        return this.getSelectedContracts().length === 1;
    }
    get singleSelectedContractName() {
        const arr = this.getSelectedContracts();
        return arr.length ? arr[0].Name+' - '+(arr[0].lei_id__c === '' || arr[0].lei_id__c == undefined ? 'NO LEI': arr[0].lei_id__c) : '';
    }
    get selectedContractOptions() {
        return this.getSelectedContracts().map(g => ({ label: g.Name+' - '+(g.lei_id__c === '' || g.lei_id__c == undefined ? 'NO LEI': g.lei_id__c), value: g.Id }));
    }

    finalizar() {
        this.close({
            action: 'confirm',
            contracts: this.getSelectedContracts()
        });
    }


    // ===== CONDICIONALES =====
    get isPreviousDisabledContract(){ return this.currentContractPage === 1; }
    get isNextDisabledContract(){ return this.currentContractPage === this.totalContractPages; }
    get contractsLength(){ return this.contracts.length > PAGE_SIZE; }

    // ===== UTILS =====
    showToast(title,message,variant){
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleClose() {
        this.close({ action: 'cancel' });
    }

    async handleConfirmAdd() {
        const ids = Array.from(this.selectedContractsIds || []);
        if (!ids.length) {
            this.showToast('Error', 'Select at least one contract', 'error');
            return;
        }

        this.isBusy = true;
        try {
            await createOnboardingContractsJunction({
            onboardingId: this.recordOnboardingId,
            contractIds: ids
            });

            this.showToast('Success', 'Contracts added successfully', 'success');

            this.close({ action: 'added', contractIds: ids });
        } catch (e) {
            console.error(e);
            this.showToast('Error', 'Could not add contracts', 'error');
        } finally {
            this.isBusy = false;
        }
        }

}