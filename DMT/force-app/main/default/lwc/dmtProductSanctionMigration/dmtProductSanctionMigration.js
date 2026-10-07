import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getData  from '@salesforce/apex/DMT_ProductSanctionMigrationController.getData';
import cloneRisk from '@salesforce/apex/DMT_ProductSanctionMigrationController.cloneRisk';
import deleteRisk from '@salesforce/apex/DMT_ProductSanctionMigrationController.deleteRisk';
import addProducts from '@salesforce/apex/DMT_ProductSanctionMigrationController.addProducts';

const OTHER_PRODUCTS_LINE_TYPE = 'Line (Other Products)';
// Sanction record type's RecordType.Name label is "Approval" (not "Sanction").
const SANCTION_LINE_TYPE = 'Approval';
const CONTEXT_ONE_OFF = 'OP';
const CONTEXT_LINE = 'TO';
const OPERATION_ONE_OFF = 'OPP';
const OPERATION_LINE = 'LIN';

export default class DmtProductSanctionMigration extends LightningElement {

    @api recordId;

    @api
    get lineStatus() {
        return this._lineStatus;
    }

    set lineStatus(value) {
        const nextStatus = value || null;
        const hadParentStatus = this._parentLineStatus !== undefined;
        const statusChanged = hadParentStatus && this._parentLineStatus !== nextStatus;
        this._parentLineStatus = nextStatus;
        if (statusChanged) {
            this._refreshForLineContextChange();
        }
    }

    // ─── State ────────────────────────────────────────────────────────────────
    @track productList = [];
    @track fieldConfigs = [];
    activeRiskId      = null;
    isLoading         = false;
    editMode          = false;
    showCategoryModal = false;
    showAddProductModal = false;
    addProductSearch = '';
    addProductSelectedIds = [];
    addProductSelectedTerms = '';
    addProductSelection = null;
    addProductSaving = false;
    childSaving = false;
    addProductContext = CONTEXT_LINE;
    loadingMessage = '';
    hasLoadedData     = false;

    // Metadata from server
    lineName;
    lineBusinessId;
    _lineStatus;
    _parentLineStatus;
    lineType;
    lineClientType;
    lineClientId;
    lineGroupCode;
    lineGroupAccount;
    entific;
    access       = false;
    hasGodAccess = false;

    // Wire reference for refreshApex
    wiredDataResult;

    // ─── Computed ─────────────────────────────────────────────────────────────

    get hasProducts() {
        return this.productList && this.productList.length > 0;
    }

    get activeRisk() {
        if (!this.activeRiskId) return null;
        return this.productList.find(p => p.Id === this.activeRiskId) || null;
    }

    get selectedRiskId() {
        return this.activeRiskId || this.productList?.[0]?.Id || null;
    }

    get selectedRiskName() {
        return this.activeRisk?.name || this.productList?.[0]?.name || '';
    }

    get selectedRiskPriorityId() {
        return this.activeRisk?.priorityId || this.productList?.[0]?.priorityId || null;
    }

    get selectedRiskOperationType() {
        return this.activeRisk?.operationType || this.productList?.[0]?.operationType || null;
    }

    get hasAccess() {
        return !!this.access;
    }

    get showEmptyState() {
        return this.hasLoadedData && !this.hasProducts;
    }

    get showAddCategory() {
        return this.lineType === OTHER_PRODUCTS_LINE_TYPE && this.hasAccess;
    }

    get showDefaultAddProduct() {
        return this.hasAccess && this.lineType === OTHER_PRODUCTS_LINE_TYPE;
    }

    get showOpportunityAddButtons() {
        return this.hasAccess && this.lineType !== OTHER_PRODUCTS_LINE_TYPE;
    }

    get loadingText() {
        return this.loadingMessage || 'Loading products...';
    }

    get showLoadingState() {
        return this.isLoading || !this.hasLoadedData;
    }

    get addProductModalTitle() {
        return this.addProductContext === CONTEXT_ONE_OFF ? 'Add One-off Deal Product' : 'Add Line Product';
    }

    get buttonDisabled() {
        return this.isLoading || this.childSaving || !this.hasAccess || !this.selectedRiskId;
    }

    get disableTopButtons() {
        return this.isLoading || this.childSaving || !this.hasAccess;
    }

    get tabsConfig() {
        return {
            nameField: 'name',
            amountField: 'amount',
            currencyField: 'currencyIsoCode',
            products: this.productList || []
        };
    }

    // CIBGLOBALD-3779: mirrors DMT_ProductSanctionMigrationController.resolveTemplateType()
    // bucketing, so field config lookups here match what the server returned in fieldConfigs.
    get _lineTypeCode() {
        if (this.lineType === OTHER_PRODUCTS_LINE_TYPE) {
            return 'OL';
        }
        if (this.lineType === SANCTION_LINE_TYPE) {
            return 'SANCTION';
        }
        return 'OP';
    }

    // CIBGLOBALD-3779: Sanction ('SANCTION') was split out of the shared 'OP' bucket only for
    // its own label overrides (Product -> Global Product Description, Commercial Product
    // Description) - it was never meant to lose the rest of 'OP's ~170 fields (Amount, Currency,
    // Risk Type, Typology of financial program risks, etc.), which Settlement/TreasurySettlement
    // still get under 'OP' unchanged. 'OP' stays an acceptable fallback bucket for Sanction so
    // those fields keep showing; _fieldConfigScore already ranks an exact lineTypeCode match
    // (SANCTION) above an 'OP' fallback for the same field, so the 2 SANCTION-specific overrides
    // still win over their 'OP' equivalents.
    _isAcceptableConfigLineType(configLineType, lineTypeCode) {
        if (!configLineType || configLineType === lineTypeCode) {
            return true;
        }
        return lineTypeCode === 'SANCTION' && configLineType === 'OP';
    }

    get selectedFieldConfigs() {
        const configs = this.fieldConfigs || [];
        const lineTypeCode = this._lineTypeCode;
        const operationType = this._normalizeOperationValue(this.selectedRiskOperationType);
        const bestByField = new Map();

        configs.forEach((cfg, index) => {
            const fieldApiName = cfg?.fieldApiName;
            if (!fieldApiName) {
                return;
            }

            const configLineType = this._normalizeLineTypeValue(cfg.lineType);
            const configSubtype = this._normalizeOperationValue(cfg.templateSubtype);
            if (!this._isAcceptableConfigLineType(configLineType, lineTypeCode)) {
                return;
            }

            if (operationType === OPERATION_ONE_OFF && configSubtype && configSubtype !== OPERATION_ONE_OFF) {
                return;
            }

            if (operationType === OPERATION_LINE && configSubtype && configSubtype !== OPERATION_LINE) {
                return;
            }

            if (!operationType && configSubtype === OPERATION_ONE_OFF) {
                return;
            }

            const score = this._fieldConfigScore(configLineType, configSubtype, lineTypeCode, operationType, index);
            const existing = bestByField.get(fieldApiName);
            if (!existing || score > existing.score) {
                bestByField.set(fieldApiName, { cfg, score });
            }
        });

        return Array.from(bestByField.values()).map((entry) => entry.cfg);
    }

    // ─── Wire: getData ────────────────────────────────────────────────────────

    @wire(getData, { lineId: '$recordId' })
    wiredData(result) {
        this.wiredDataResult = result;
        const { data, error } = result;

        if (data) {
            this.hasLoadedData = true;
            this.lineName     = data.lineName;
            this.lineBusinessId = data.lineBusinessId;
            this._lineStatus   = data.lineStatus;
            this.lineType     = data.lineType;
            this.lineClientType = data.lineClientType;
            this.lineClientId = data.lineClientId;
            this.lineGroupCode = data.lineGroupCode;
            this.lineGroupAccount = data.lineGroupAccount;
            this.entific      = data.entific;
            this.access       = data.access       || false;
            this.hasGodAccess = data.hasGodAccess || false;
            this.fieldConfigs = data.fieldConfigs || [];

            const risks = data.risks || [];

            // Keep active tab if it still exists; fall back to first
            const stillExists = this.activeRiskId && risks.some(r => r.id === this.activeRiskId);
            if (!stillExists) {
                this.activeRiskId = risks.length > 0 ? risks[0].id : null;
            }

            this.productList = risks.map(r => ({
                Id           : r.id,
                name         : r.name,
                amount       : r.amount,
                currencyIsoCode: r.currencyIsoCode,
                currencyLabel: r.currencyIsoCode || '',
                priorityId   : r.priority,
                operationType: r.operationType,
                isSelected   : r.id === this.activeRiskId
            }));

        } else if (error) {
            this.hasLoadedData = true;
            this._toast('Error loading products', error?.body?.message || error?.message || 'Unknown error', 'error');
        }
    }

    // ─── Event handlers ───────────────────────────────────────────────────────

    handleRiskSelected(event) {
        const newId = event.detail.Id;

        // Exit edit mode if child is currently editing
        const fieldsComponent = this.refs?.sanctionFields;
        if (fieldsComponent?.getEditMode()) {
            this.editMode = false;
        }

        this.activeRiskId = newId;
        // Sync isSelected flags so the tile template re-renders correctly
        this.productList = this.productList.map(p => ({
            ...p,
            isSelected: p.Id === newId
        }));
    }

    handleTabChange(event) {
        const newTabId = event.detail.tabId;
        const fieldsComponent = this.refs?.sanctionFields;
        if (fieldsComponent?.getEditMode()) {
            this.editMode = false;
        }
        this.activeRiskId = newTabId;
        this.productList = this.productList.map(p => ({
            ...p,
            isSelected: p.Id === newTabId
        }));
    }

    async handleClone() {
        this._startLoading('Cloning product...');
        try {
            const result = await cloneRisk({
                riskId: this.selectedRiskId,
                lineId: this.recordId
            });
            if (result?.clonedRiskId) {
                this.activeRiskId = result.clonedRiskId;
                await this._refresh();
                this._toast('Cloned', 'Product was cloned successfully.', 'success');
            } else {
                this._toast('Error', result?.errorMessage || 'Error cloning product.', 'error');
            }
        } catch (error) {
            this._toast('Error cloning product', error?.body?.message || error?.message || 'Unknown error', 'error');
        } finally {
            this._stopLoading();
        }
    }

    async handleDelete() {
        this._startLoading('Deleting product...');
        try {
            const deletedId  = this.selectedRiskId;
            const sorted     = [...this.productList];
            const idx        = sorted.findIndex(p => p.Id === deletedId);
            const nextActive = sorted[idx + 1]?.Id || sorted[idx - 1]?.Id || null;

            await deleteRisk({ riskId: deletedId, lineId: this.recordId });
            this.activeRiskId = nextActive;
            await this._refresh();
            this._toast('Deleted', 'Product was deleted successfully.', 'success');
        } catch (error) {
            this._toast('Error deleting product', error?.body?.message || error?.message || 'Unknown error', 'error');
        } finally {
            this._stopLoading();
        }
    }

    handleAddCategory() {
        this.showCategoryModal = true;
    }

    handleAddProduct() {
        this.openAddProductModal(CONTEXT_LINE);
    }

    handleAddOneOffProduct() {
        this.openAddProductModal(CONTEXT_ONE_OFF);
    }

    handleAddLineProduct() {
        this.openAddProductModal(CONTEXT_LINE);
    }

    openAddProductModal(contextCode) {
        this.addProductContext = contextCode || CONTEXT_LINE;
        this.addProductSearch = '';
        this.addProductSelectedIds = [];
        this.addProductSelectedTerms = '';
        this.addProductSelection = null;
        this.showAddProductModal = true;
    }

    async handleCloseAddProductModal() {
        this.showAddProductModal = false;
        this.addProductSaving = false;
        await this._refresh();
    }

    handleAddProductSearchChange(event) {
        this.addProductSearch = event.target.value || '';
    }

    handleAddProductsToSend(event) {
        const detail = event.detail || {};
        this.addProductSelection = detail?.data || null;
        this.addProductSelectedIds = detail.selectedCodesId || [];
        this.addProductSelectedTerms = this.addProductSelection?.selectedTerms || '';
    }

    get disableAddProductSave() {
        const hasIds = Array.isArray(this.addProductSelectedIds) && this.addProductSelectedIds.length > 0;
        const hasCodes = !!this.addProductSelection?.selectedCodes;
        return this.addProductSaving || (!hasIds && !hasCodes);
    }

    get addProductContextCode() {
        if (this.lineType === OTHER_PRODUCTS_LINE_TYPE) {
            return '';
        }
        return this.addProductContext === CONTEXT_ONE_OFF ? 'OPP' : 'L';
    }

    get addProductOperationType() {
        return this.addProductContext === CONTEXT_ONE_OFF ? OPERATION_ONE_OFF : OPERATION_LINE;
    }

    async handleSaveAddProduct() {
        if (this.disableAddProductSave) {
            return;
        }

        this.addProductSaving = true;
        try {
            await addProducts({
                lineId: this.recordId,
                productIds: this.addProductSelectedIds,
                selectedTerms: this.addProductSelectedTerms,
                selectedCodes: this.addProductSelection?.selectedCodes,
                selectedName: this.addProductSelection?.Name,
                parentProductName: this.addProductSelection?.parentProductName,
                operationType: this.addProductOperationType
            });
            this._toast('Success', 'Product(s) added successfully.', 'success');
            await this.handleCloseAddProductModal();
        } catch (error) {
            this._toast(
                'Error adding products',
                error?.body?.message || error?.message || 'Unknown error',
                'error'
            );
            this.addProductSaving = false;
        }
    }

    handleRecordSaved(event) {
        const detail = event.detail || {};
        if (detail.recordId && detail.fields) {
            this._applySavedRiskFields(detail.recordId, detail.fields);
        }
        this.editMode = false;
        this._notifyEditingTab(false);
    }

    handleEditModeChange(event) {
        this.editMode = !!event.detail?.isEditMode;
        this._notifyEditingTab(this.editMode);
    }

    async handleSaveEdit() {
        const fieldsComponent = this.refs?.sanctionFields;
        if (fieldsComponent?.saveFromParent) {
            await fieldsComponent.saveFromParent();
        }
    }

    handleCancelEditFromFooter() {
        const fieldsComponent = this.refs?.sanctionFields;
        if (fieldsComponent?.cancelFromParent) {
            fieldsComponent.cancelFromParent();
        } else {
            this.editMode = false;
        }
    }

    handleChildSavingChange(event) {
        this.childSaving = !!event.detail?.isSaving;
    }

    handleCancelEdit() {
        this.editMode = false;
        this._notifyEditingTab(false);
    }

    _notifyEditingTab(isEditing) {
        this.dispatchEvent(new CustomEvent('editingtab', {
            detail: {
                tab: isEditing ? 'products' : null
            },
            bubbles: true,
            composed: true
        }));
    }

    handleCloseCategoryModal() {
        this.showCategoryModal = false;
    }

    async handleCategoryReload() {
        this.showCategoryModal = false;
        await this._refresh();
        this._toast('Success', 'Category added successfully.', 'success');
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    async _refresh() {
        const alreadyLoading = this.isLoading;
        if (!alreadyLoading) {
            this._startLoading('Refreshing products...');
        }
        try {
            await refreshApex(this.wiredDataResult);
        } finally {
            if (!alreadyLoading) {
                this._stopLoading();
            }
        }
    }

    async _refreshForLineContextChange() {
        if (!this.wiredDataResult) {
            return;
        }

        try {
            await this._refresh();
            if (!this.hasAccess && this.editMode) {
                const fieldsComponent = this.refs?.sanctionFields;
                if (fieldsComponent?.cancelFromParent) {
                    fieldsComponent.cancelFromParent();
                } else {
                    this.editMode = false;
                    this._notifyEditingTab(false);
                }
            }
        } catch (error) {
            this._toast('Error refreshing products', error?.body?.message || error?.message || 'Unknown error', 'error');
        }
    }

    _startLoading(message) {
        this.loadingMessage = message || 'Loading...';
        this.isLoading = true;
    }

    _stopLoading() {
        this.isLoading = false;
        this.loadingMessage = '';
    }

    _applySavedRiskFields(riskId, fields) {
        const hasHeaderField = Object.prototype.hasOwnProperty.call(fields, 'DMT_Amount__c')
            || Object.prototype.hasOwnProperty.call(fields, 'CurrencyIsoCode')
            || Object.prototype.hasOwnProperty.call(fields, 'Name');
        if (!hasHeaderField) {
            return;
        }

        this.productList = this.productList.map((product) => {
            if (product.Id !== riskId) {
                return product;
            }
            const nextProduct = { ...product };
            if (Object.prototype.hasOwnProperty.call(fields, 'DMT_Amount__c')) {
                nextProduct.amount = fields.DMT_Amount__c;
            }
            if (Object.prototype.hasOwnProperty.call(fields, 'CurrencyIsoCode')) {
                nextProduct.currencyIsoCode = fields.CurrencyIsoCode;
                nextProduct.currencyLabel = fields.CurrencyIsoCode || '';
            }
            if (Object.prototype.hasOwnProperty.call(fields, 'Name')) {
                nextProduct.name = fields.Name;
            }
            return nextProduct;
        });
    }

    _normalizeLineTypeValue(value) {
        return String(value || '').trim().toUpperCase();
    }

    _normalizeOperationValue(value) {
        const normalized = String(value || '').trim().toUpperCase();
        if (normalized === 'OPP') {
            return OPERATION_ONE_OFF;
        }
        if (normalized === 'TO' || normalized === 'LIN' || normalized === 'LINE') {
            return OPERATION_LINE;
        }
        return normalized;
    }

    _fieldConfigScore(configLineType, configSubtype, lineTypeCode, operationType, index) {
        let score = 100000 - index;
        if (configLineType === lineTypeCode) {
            score += 10000;
        }
        if (operationType && configSubtype === operationType) {
            score += 1000;
        } else if (!configSubtype) {
            score += 100;
        }
        return score;
    }

    _toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}