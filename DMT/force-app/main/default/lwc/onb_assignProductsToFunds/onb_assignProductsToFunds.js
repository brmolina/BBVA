import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';

// CLASSES
import getProductItemsForFunds from '@salesforce/apex/ONB_ProductStepController.getProductItemsForFunds';
import saveProductsForFund from '@salesforce/apex/ONB_ProductStepController.saveProductsForFund';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import emptyFunds from '@salesforce/resourceUrl/emptyFunds';

// LABELS
import ONB_PROD_BOOKING_ENTITY from '@salesforce/label/c.ONB_PROD_BOOKING_ENTITY';
import ONB_PROD_CATEGORY from '@salesforce/label/c.ONB_PROD_CATEGORY';
import ONB_PROD_PRODUCT from '@salesforce/label/c.ONB_PROD_PRODUCT';
import ONB_PROD_SELLING_LOCATION from '@salesforce/label/c.ONB_PROD_SELLING_LOCATION';
import ONB_PROD_BRANCH_CODE from '@salesforce/label/c.ONB_PROD_BRANCH_CODE';
import ONB_PROD_ACCOUNT_OFFICER from '@salesforce/label/c.ONB_PROD_ACCOUNT_OFFICER';
import ONB_PROD_COMMENTS from '@salesforce/label/c.ONB_PROD_COMMENTS';
import ONB_EMPTY_LIST from '@salesforce/label/c.ONB_EMPTY_LIST';
import ONB_NO_PRODUCTS from '@salesforce/label/c.ONB_NO_PRODUCTS';

const PAGE_SIZE = 8;

export default class onb_assignProductsToFunds extends LightningModal {
    @api header;
    @api recordOnboardingId;
    @api fundId;

    emptyProductsImage = emptyFunds;

    @track isBusy = true;
    @track hasLoadedProducts = false;

    labels = {
        ONB_EMPTY_LIST,
        ONB_NO_PRODUCTS
    }

    connectedCallback() {
        this.isBusy = true;
        this.loadProductsFresh();
    }

    // ===== PRODUCTS =====
    @track products = [];
    @track filteredProducts = [];
    @track displayedProducts = [];
    @track selectedProducts = [];
    @track selectionFilter = 'all';
    @track searchProductTerm = ''; 
    @track searchProductTermRaw = ''; 
    @track currentProductPage = 1;
    totalProductPages = 1;
    selectedProductsIds = new Set();
    
    columns = [
        { key: 'bookingEntity', label: ONB_PROD_BOOKING_ENTITY, fieldName: 'Booking_Entity__c', type: 'clampedText', wrapText: true, hideDefaultActions: true },
        { key: 'productCategory', label: ONB_PROD_CATEGORY, fieldName: 'Product_Category__c', type: 'clampedText', wrapText: true, hideDefaultActions: true },
        { key: 'product', label: ONB_PROD_PRODUCT, fieldName: 'productName', type: 'clampedText', wrapText: true, hideDefaultActions: true },
        { key: 'sellingLocation', label: ONB_PROD_SELLING_LOCATION, fieldName: 'Selling_Location__c', type: 'clampedText', wrapText: true, hideDefaultActions: true  },
        { key: 'branchCode', label: ONB_PROD_BRANCH_CODE,  fieldName: 'Branch_Code__c', type: 'clampedText', wrapText: true, hideDefaultActions: true  },
        { key: 'accountOfficer',  label: ONB_PROD_ACCOUNT_OFFICER, fieldName: 'Account_Officer__c',  type: 'clampedText', wrapText: true, hideDefaultActions: true  },
        { key: 'comments', label:ONB_PROD_COMMENTS, fieldName:'Comments__c', type: 'clampedText', wrapText: true, hideDefaultActions: true  }
    ];

    get selectionFilterOptions() {
        return [
            { label: 'All products', value: 'all' },
            { label: 'Selected products', value: 'selected' },
            { label: 'Unselected products', value: 'unselected' }
        ];
    }

    handleSelectionFilterChange(event) {
        this.selectionFilter = event.detail.value;
        this.currentProductPage = 1;
        this.applyProductFilters();
    }

    async loadProductsFresh() {
        
        this.isBusy = true;
        try {
            const dto = await getProductItemsForFunds({
                onboardingId: this.recordOnboardingId,
                fundId: this.fundId,
                cacheBuster: String(Date.now())
            });

            console.log(dto);

            this.products = (dto.products || []).map(p => {
                return {
                    ...p,
                    productName: p.Product2Id__r?.Name
                };
            });

            this.selectedProductsIds = new Set(dto?.preselectedProductIds || []);
            this.selectedProducts = this.products.filter(f => this.selectedProductsIds.has(f.Id));

            this.currentProductPage = 1;
            this.applyProductFilters();
            this.hasLoadedProducts = true;

        } catch (e) {
            console.error('loadProductsFresh error', e);
            this.showToast('Error', 'Could not load products for this fund', 'error');
        } finally {
            this.isBusy = false;
        }
    }

    handleProductSearch(event) {
        this.searchProductTermRaw = event?.target?.value || '';
        this.searchProductTerm = this.searchProductTermRaw.toLowerCase();
        this.currentProductPage = 1;
        this.applyProductFilters();
    }

    applyProductFilters() {
        const term = (this.searchProductTerm || '').trim().toLowerCase();

        const toStr = (v) => {
            if (v === null || v === undefined) return '';
            return String(v).toLowerCase();
        };

        let rows = term
            ? this.products.filter(c => {
                const haystack = [
                    c.Booking_Entity__c,
                    c.Product_Category__c,
                    c.Product2Id__c,
                    c.Selling_Location__c,
                    c.Branch_Code__c,
                    c.Account_Officer__c,
                    c.Comments__c
                ].map(toStr).join(' | ');
                return haystack.includes(term);
            })
            : [...this.products];

        if (this.selectionFilter === 'selected') {
            rows = rows.filter(r => this.selectedProductsIds.has(r.Id));
        } else if (this.selectionFilter === 'unselected') {
            rows = rows.filter(r => !this.selectedProductsIds.has(r.Id));
        }

        this.filteredProducts = rows;

        this.totalProductPages = Math.ceil(this.filteredProducts.length / PAGE_SIZE) || 1;

        if (this.currentProductPage > this.totalProductPages) {
            this.currentProductPage = this.totalProductPages;
        }
        if (this.currentProductPage < 1) {
            this.currentProductPage = 1;
        }

        this.updateProductPagination();
    }



    updateProductPagination() {
        const start = (this.currentProductPage - 1) * PAGE_SIZE;
        const end = start + PAGE_SIZE;
        this.displayedProducts = this.filteredProducts.slice(start, end);
    }

    handleProductPrevPage() {
        if (this.currentProductPage > 1) {
            this.currentProductPage--;
            this.updateProductPagination();
        }
    }
    handleProductNextPage() {
        if (this.currentProductPage < this.totalProductPages) {
            this.currentProductPage++;
            this.updateProductPagination();
        }
    }

    get selectedProductIdsArray() {
        return Array.from(this.selectedProductsIds || []);
    }

    handleProductsSelection(event) {
        console.log('detail keys:', Object.keys(event.detail || {}));
        console.log('selectedRows:', event.detail?.selectedRows);
        console.log('selectedRows length:', event.detail?.selectedRows?.length);
        const selectedOnPage = new Set((event.detail.selectedRows || []).map(r => r.Id));
        const currentPageIds = this.displayedProducts.map(r => r.Id);
        currentPageIds.forEach(id => {
            if (selectedOnPage.has(id)) this.selectedProductsIds.add(id);
            else this.selectedProductsIds.delete(id);
        });
        this.selectedProducts = this.products.filter(g => this.selectedProductsIds.has(g.Id));

        if (this.selectionFilter !== 'all') {
            this.applyProductFilters();
        }
    }

    // ===== HELPERS =====
    getSelectedProducts() {
        if (this.selectedProductsIds && this.selectedProductsIds.size)
            return this.products.filter(g => this.selectedProductsIds.has(g.Id));
        return this.selectedProducts || [];
    }

    finalizar() {
        this.close({
            action: 'confirm',
            products: this.getSelectedProducts()
        });
    }

    // ===== CONDICIONALES =====
    get isPreviousDisabledProduct(){ return this.currentProductPage === 1; }
    get isNextDisabledProduct(){ return this.currentProductPage === this.totalProductPages; }
    get productsLength(){ return this.products.length > PAGE_SIZE; }

    // ===== UTILS =====
    showToast(title,message,variant){
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleClose() {
        this.close({ action: 'cancel' });
    }

    async handleConfirmSave() {
        const ids = Array.from(this.selectedProductsIds || []);
        this.isBusy = true;

        try {
            await saveProductsForFund({
                fundId: this.fundId,
                selectedProductsIds: ids
            });

            this.showToast('Success', 'Products saved successfully', 'success');
            this.close({ action: 'added', productIds: ids });

        } catch (e) {
            console.error(e);
            this.showToast('Error', e?.body?.message || 'Could not save products', 'error');
        } finally {
            this.isBusy = false;
        }
    }

}