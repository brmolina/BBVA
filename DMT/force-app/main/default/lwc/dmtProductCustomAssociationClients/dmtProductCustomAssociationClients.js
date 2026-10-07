import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import loadProductDatasource from '@salesforce/apex/DMT_SelectClientsInLineService.loadProductDatasource';
import saveProductSelection from '@salesforce/apex/DMT_SelectClientsInLineService.saveProductSelection';

const CLIENT_POSITION_ALL = 'Y/N';

export default class DmtProductCustomAssociationClients extends LightningElement {
    _lineId;
    _priorityId;

    @api riskId;
    @api lineStatus;

    @track availableClients = [];
    @track selectedRows = [];
    @track priorselectedRows = [];
    @track showLoading = false;
    @track isSaving = false;
    @track errorMessage = '';
    @track isDirty = false;

    currency;
    groupId;
    groupSfId;
    mainHolder = '';
    canEditByBusinessRule = true;
    baselineState = '';
    availableClientById = new Map();

    @api
    get lineId() {
        return this._lineId;
    }

    set lineId(value) {
        const nextValue = value || null;
        const changed = this._lineId !== nextValue;
        this._lineId = nextValue;
        if (changed) {
            this.loadDatasource();
        }
    }

    @api
    get priorityId() {
        return this._priorityId;
    }

    set priorityId(value) {
        const nextValue = value || '';
        const changed = this._priorityId !== nextValue;
        this._priorityId = nextValue;
        if (changed) {
            this.loadDatasource();
        }
    }

    connectedCallback() {
        this.loadDatasource();
    }

    get loadingMessage() {
        if (this.isSaving) {
            return 'Saving selected records, please wait...';
        }
        if (this.showLoading) {
            return 'Loading client information, please wait...';
        }
        return '';
    }

    get showOverlay() {
        return this.showLoading || this.isSaving;
    }

    get hasError() {
        return this.errorMessage !== '';
    }

    get selectedCount() {
        return this.selectedRows.length;
    }

    get showFooter() {
        return this.isDirty && this.canEditByBusinessRule;
    }

    get isSaveDisabled() {
        return this.isSaving || !this.isDirty || !this.canEditByBusinessRule;
    }

    get hasVisibleClients() {
        return this.availableClients.length > 0;
    }

    get totalColumns() {
        return 4;
    }

    get visibleClients() {
        const selectedById = new Map();
        for (const row of this.selectedRows) {
            selectedById.set(row.customerId, row);
        }

        return this.availableClients
            .map((row) => {
                const selected = selectedById.get(row.customerId);
                const merged = selected ? { ...row, ...selected } : { ...row };
                merged.isSelected = Boolean(selected);
                merged.rowClass = merged.isSelected ? 'selected-row' : '';
                return merged;
            });
    }

    async loadDatasource() {
        if (!this.lineId || !this.priorityId || this.showLoading || this.isSaving) {
            return;
        }

        try {
            this.showLoading = true;
            this.errorMessage = '';
            const response = await loadProductDatasource({
                lineId: this.lineId,
                priorityId: this.priorityId,
                clientPosition: CLIENT_POSITION_ALL
            });

            this.currency = response.currency || this.currency;
            this.groupId = response.groupId || this.groupId;
            this.groupSfId = response.groupSfId || this.groupSfId;
            this.canEditByBusinessRule = response.canEditSelection !== false;
            this.availableClients = this.normalizeRows(response.availableClients || []);
            this.availableClientById = new Map(this.availableClients.map((row) => [row.customerId, row]));
            this.priorselectedRows = this.normalizeRows(response.priorselectedRows || []);
            this.selectedRows = this.normalizeSelectedRows(this.normalizeRows(response.selectedRows || []));
            this.mainHolder = this.selectedRows[0]?.mainHolder || this.priorselectedRows[0]?.mainHolder || '';
            this.snapshotBaseline();
        } catch (error) {
            this.errorMessage = this.resolveErrorMessage(error, 'Error loading product clients.');
        } finally {
            this.showLoading = false;
        }
    }

    normalizeRows(rows) {
        return (rows || [])
            .filter((row) => row && row.customerId)
            .map((row) => ({
                ...row,
                customerName: row.customerName || row.name || row.customerId,
                countryIfoId: row.countryIfoId || '',
                updSmsclInternalRatgType: row.updSmsclInternalRatgType || '',
                currentRatingToolDate: row.currentRatingToolDate || '',
                customerCounterpartiesCodesDesc: row.customerCounterpartiesCodesDesc || '',
                operationMitigantDesc: row.operationMitigantDesc || ''
            }));
    }

    normalizeSelectedRows(rows) {
        return rows
            .filter((row) => row.customerId)
            .map((row) => ({ ...(this.availableClientById.get(row.customerId) || {}), ...row }));
    }

    handleClientToggle(event) {
        if (!this.canEditByBusinessRule) {
            return;
        }

        const customerId = event.currentTarget.dataset.id;
        if (!customerId) {
            return;
        }

        const selectedIndex = this.selectedRows.findIndex((row) => row.customerId === customerId);
        if (selectedIndex >= 0) {
            this.selectedRows = this.selectedRows.filter((row) => row.customerId !== customerId);
            if (this.mainHolder === customerId) {
                this.mainHolder = this.selectedRows[0]?.customerId || '';
            }
        } else {
            const sourceRow = this.availableClientById.get(customerId);
            if (sourceRow) {
                const nextRow = { ...sourceRow, mainHolder: this.mainHolder || customerId };
                this.selectedRows = [...this.selectedRows, nextRow];
                if (!this.mainHolder) {
                    this.mainHolder = customerId;
                }
            }
        }

        this.refreshDirtyState();
    }

    handleCancel() {
        this.selectedRows = this.priorselectedRows.map((row) => ({ ...row }));
        this.mainHolder = this.selectedRows[0]?.mainHolder || this.priorselectedRows[0]?.mainHolder || '';
        this.snapshotBaseline();
    }

    async handleSave() {
        if (this.isSaveDisabled) {
            return;
        }

        try {
            this.isSaving = true;
            this.errorMessage = '';
            const result = await saveProductSelection({
                lineId: this.lineId,
                priorityId: this.priorityId,
                mainHolderAlphaCode: this.mainHolder,
                currencyLine: this.currency,
                groupId: this.groupId,
                groupSfId: this.groupSfId,
                selectedRows: this.selectedRows
            });

            if (result?.success === false) {
                this.errorMessage = result.error || 'Error saving selected clients.';
                return;
            }

            this.priorselectedRows = this.selectedRows.map((row) => ({ ...row }));
            this.snapshotBaseline();
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Clients saved successfully.',
                    variant: 'success'
                })
            );
        } catch (error) {
            this.errorMessage = this.resolveErrorMessage(error, 'Error saving selected clients.');
        } finally {
            this.isSaving = false;
        }
    }

    serializeState(rows) {
        return JSON.stringify(
            (rows || [])
                .map((row) => row.customerId || '')
                .filter(Boolean)
                .sort()
        );
    }

    snapshotBaseline() {
        this.baselineState = this.serializeState(this.selectedRows);
        this.isDirty = false;
    }

    refreshDirtyState() {
        this.isDirty = this.serializeState(this.selectedRows) !== this.baselineState;
    }

    resolveErrorMessage(error, fallback) {
        return error?.body?.message || error?.message || fallback;
    }
}