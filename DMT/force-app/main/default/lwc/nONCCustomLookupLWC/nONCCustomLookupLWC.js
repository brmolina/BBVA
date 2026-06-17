/*CAMBIOS MIGRACIÓN A LWC GLOBAL BANKER*/
import { api, LightningElement } from 'lwc';
import fetchLookUpValues from '@salesforce/apex/NONC_CustomLookUpControllerMobile.fetchLookUpValues';

export default class NONCCustomLookupLWC extends LightningElement {
    @api label = '';
    @api iconName = 'standard:account';
    @api fieldAPIName = '';
    @api whereCondition = '';

    searchKeyword = '';
    listOfSearchRecords = [];
    selectedRecord = null;
    isLoading = false;
    isOpen = false;
    message = '';
    blurTimeout;

    handleSearchInput(event) {
        this.searchKeyword = event.target.value;

        if (!this.searchKeyword) {
            this.listOfSearchRecords = [];
            this.message = '';
            this.isOpen = false;
            return;
        }

        this.isLoading = true;
        this.isOpen = true;
        this.message = '';
        this.searchRecords();
    }

    handleSearchFocus() {
        // No lanzamos SOSL con string vacío — SOSL requiere al menos 1 carácter
        // La búsqueda arranca cuando el usuario escribe (handleSearchInput)
        this.isOpen = Boolean(this.searchKeyword);
    }

    handleBlur() {
        this.blurTimeout = window.setTimeout(() => {
            this.isOpen = false;
        }, 200);
    }

    handleRecordSelect(event) {
        if (this.blurTimeout) {
            window.clearTimeout(this.blurTimeout);
        }

        this.selectedRecord = event.detail;
        this.searchKeyword = '';
        this.listOfSearchRecords = [];
        this.message = '';
        this.isOpen = false;

        this.dispatchEvent(
            new CustomEvent('lookupselected', {
                detail: { record: this.selectedRecord }
            })
        );
    }

    handleClearSelection() {
        this.selectedRecord = null;
        this.searchKeyword = '';
        this.listOfSearchRecords = [];
        this.message = '';
        this.isOpen = false;

        this.dispatchEvent(new CustomEvent('lookupcleared'));
    }

    async searchRecords() {
        try {
            const result = await fetchLookUpValues({
                searchKeyWord: this.searchKeyword,
                objectName: 'Account',
                fieldAPIName: this.fieldAPIName,
                queryWhere: this.whereCondition || ''
            });

            this.listOfSearchRecords = result || [];
            this.message = this.listOfSearchRecords.length === 0 ? 'No records found' : '';
        } catch (error) {
            this.listOfSearchRecords = [];
            this.message = 'Error loading records';
            // eslint-disable-next-line no-console
            console.error('NONC custom lookup mobile error', error);
        } finally {
            this.isLoading = false;
        }
    }

    get hasSelectedRecord() {
        return Boolean(this.selectedRecord?.Id);
    }

    get selectedRecordName() {
        return this.selectedRecord?.Name || '';
    }
}