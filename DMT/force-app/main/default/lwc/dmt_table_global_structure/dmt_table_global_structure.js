import { LightningElement, api } from 'lwc';
import { updateRecord, createRecord } from "lightning/uiRecordApi";
import pubsub from 'omnistudio/pubsub';
import NAME_FIELD from "@salesforce/schema/DMT_Global_Structure__c.Name";
import FUNDS_FIELD from "@salesforce/schema/DMT_Global_Structure__c.DMT_Funds__c";
import TYPE_FIELD from "@salesforce/schema/DMT_Global_Structure__c.DMT_Type__c";
import OPPORTUNITY_FIELD from "@salesforce/schema/DMT_Global_Structure__c.DMT_Opportunity__c";
import ID_FIELD from "@salesforce/schema/DMT_Global_Structure__c.Id";

const EVENT_BUTTON = 'Button';
const EVENT_SET = 'Set';

export default class DmtStructureTable extends LightningElement {
    @api label;
    @api recordId;
    @api showcopypaste = false;

    originalData = [];
    processedData = [];
    isDataProcessed = false;

    _internalEditMode = false;
    _isReadOnly = false;
    _stageName;
    _tableData = [];
    _dataSnapshot = [];

    typeMapping = {
        "Debt Funds (Mn)": "Funding Debt",
        "Equity Funds (Mn)": "Funding Equity",
        "Uses": "Uses"
    };

    @api
    get tableData() {
        return this._tableData;
    }
    set tableData(value) {
        this._tableData = Array.isArray(value) ? value : [];
        this.initializeTable();
    }

    @api
    get isEditMode() {
        return this._internalEditMode;
    }
    set isEditMode(value) {
        const isTrue = (value === true || value === 'true');
        this._internalEditMode = isTrue;
        this.setEditModeForView(isTrue);
    }

    @api
    get isReadOnlyUser() {
        return this._isReadOnly;
    }
    set isReadOnlyUser(value) {
        this._isReadOnly = (value === true || value === 'true');
    }

    @api
    get stageName() {
        return this._stageName;
    }
    set stageName(value) {
        this._stageName = value;
    }

    // TODO: [DEAD_CODE] StageName (PascalCase) - duplicate of stageName (camelCase), kept for FlexCard backward compat
    @api
    get StageName() {
        return this._stageName;
    }
    set StageName(value) {
        this._stageName = value;
    }

    get isEditPencilEnabled() {
        return this._isReadOnly === false
            && (this._stageName === 'Draft' || this._stageName === 'Proposal');
    }

    connectedCallback() {
        // Save is triggered by parent via ref.handleSave()
    }

    initializeTable() {
        const defaultRows = this.createDefaultRows();
        const convertedType = this.typeMapping[this.label] || this.label;

        let filteredData = [];
        if (this._tableData.length > 0) {
            filteredData = this._tableData.filter(r => r.DMT_Type__c === convertedType);

            this.originalData = filteredData.map((r, index) => ({
                index,
                Id: r.Id,
                Name: this.getDisplayName(r.Name, r.Id),
                DMT_Funds__c: r.DMT_Funds__c ?? "",
                DMT_Type__c: convertedType,
                isTotal: false,
                hasChanged: false
            }));

            // Rellenar filas faltantes hasta llegar al default
            const nonTotalDefaultRows = defaultRows.filter(r => !r.isTotal);
            const currentNonTotalRows = this.originalData;
            if (currentNonTotalRows.length < nonTotalDefaultRows.length) {
                const missingRows = nonTotalDefaultRows.slice(currentNonTotalRows.length);
                this.originalData = this.originalData.concat(missingRows);
            }

        } else {
            this.originalData = defaultRows.filter(r => !r.isTotal);
        }

        // Asegurar fila TOTAL
        const totalRow = defaultRows.find(r => r.isTotal);
        this.originalData.push({
            ...totalRow,
            DMT_Funds__c: this.calculateTotal()
        });

        // Store snapshot for cancel/restore
        this._dataSnapshot = JSON.parse(JSON.stringify(this.originalData));

        this.processDataForView();

        if (this._internalEditMode) {
            this.setEditModeForView(true);
        }
    }

    @api
    restoreSnapshot() {
        this.originalData = JSON.parse(JSON.stringify(this._dataSnapshot));
        this._internalEditMode = false;
        this.processDataForView();
    }

    @api
    commitEdit() {
        this._dataSnapshot = JSON.parse(JSON.stringify(this.originalData));
        this._internalEditMode = false;
        this.processDataForView();
    }

    createDefaultRows() {
        let count = 0;
        if (this.label === "Debt Funds (Mn)") count = 5;
        else if (this.label === "Equity Funds (Mn)") count = 4;
        else if (this.label === "Uses") count = 10;

        const rows = [];
        for (let i = 0; i < count; i++) {
            rows.push({
                index: i,
                Id: null,
                Name: "",
                DMT_Funds__c: "",
                DMT_Type__c: this.label,
                isTotal: false,
                hasChanged: false
            });
        }

        rows.push({
            index: count,
            Id: null,
            Name: "Total",
            DMT_Funds__c: "",
            DMT_Type__c: this.label,
            isTotal: true,
            hasChanged: false
        });

        return rows;
    }

    calculateTotal() {
        return this.originalData
            .filter(r => !r.isTotal)
            .reduce((sum, r) => sum + (Number(r.DMT_Funds__c) || 0), 0);
    }

    processDataForView() {
        this.processedData = this.originalData.map(row => ({
            index: row.index,
            Id: row.Id ?? row.index,
            isTotal: row.isTotal,
            values: [
                {
                    field: 'Name',
                    label: 'Name',
                    value: row.Name,
                    isEditing: this._internalEditMode && !row.isTotal,
                    isEditable: !row.isTotal,
                    type: 'text'
                },
                {
                    field: 'DMT_Funds__c',
                    label: 'Funds',
                    value: row.DMT_Funds__c,
                    isEditing: this._internalEditMode && !row.isTotal,
                    isEditable: !row.isTotal,
                    type: 'number'
                }
            ]
        }));
        this.isDataProcessed = true;
    }

    setEditModeForView(isEditing) {
        if (!this.processedData) return;
        this._internalEditMode = isEditing;
        this.processedData = this.processedData.map(row => {
            row.values = row.values.map(cell => {
                cell.isEditing = isEditing && !row.isTotal;
                return cell;
            });
            return row;
        });

    }

    handleEditCell() {
        if (!this.isEditPencilEnabled) {
            return;
        }
        this.dispatchEvent(new CustomEvent('editmodechange', { bubbles: true, composed: true }));
    }

    handleInputChange(event) {
        const idx = event.target.dataset.index;
        const field = event.target.dataset.field;
        const value = event.target.value;

        this.originalData[idx][field] = value;
        this.originalData[idx].hasChanged = true;

        const totalRow = this.originalData.find(r => r.isTotal);
        if (totalRow) {
            totalRow.DMT_Funds__c = this.calculateTotal();
        }

        this.processDataForView();
        this.dispatchEvent(new CustomEvent('fieldchange', { bubbles: true, composed: true }));
    }

    @api
    collectChanges() {
        const changed = this.originalData.filter(r => r.hasChanged && !r.isTotal);
        return changed.length > 0 ? { _tableHasChanges: true } : {};
    }

    @api
    async handleSave() {
        this.isDataProcessed = false;

        const changedRows = this.originalData.filter(r => r.hasChanged && !r.isTotal);

        if (!changedRows.length) {
            this._internalEditMode = false;
            this.processDataForView();
            return;
        }

        const convertedType = this.typeMapping[this.label] || this.label;

        for (let row of changedRows) {
            if (row.Id) {
                const fields = this.buildUpdateObject(row, convertedType);
                try {
                    await updateRecord({ fields });
                } catch (error) {
                    pubsub.fire(EVENT_SET, "Error", { errorMessage: 'Error updating record' });
                    this.dispatchEvent(new CustomEvent('saveerror', { bubbles: true, composed: true, detail: { message: 'Error updating record' } }));
                    this.isDataProcessed = true;
                    return;
                }
            } else {
                const fields = {
                    [NAME_FIELD.fieldApiName]: row.Name || '',
                    [FUNDS_FIELD.fieldApiName]: row.DMT_Funds__c !== "" ? Number(row.DMT_Funds__c) : null,
                    [TYPE_FIELD.fieldApiName]: convertedType,
                    [OPPORTUNITY_FIELD.fieldApiName]: this.recordId
                };
                try {
                    await createRecord({ apiName: 'DMT_Global_Structure__c', fields });
                } catch (error) {
                    pubsub.fire(EVENT_SET, "Error", { errorMessage: 'Error creating record' });
                    this.dispatchEvent(new CustomEvent('saveerror', { bubbles: true, composed: true, detail: { message: 'Error creating record' } }));
                    this.isDataProcessed = true;
                    return;
                }
            }
        }

        this._internalEditMode = false;
        this.originalData.forEach(r => r.hasChanged = false);
        const totalRow = this.originalData.find(r => r.isTotal);
        if (totalRow) totalRow.DMT_Funds__c = this.calculateTotal();

        this.processDataForView();
        this.dispatchEvent(new CustomEvent('savesuccess', { bubbles: true, composed: true }));
        pubsub.fire(EVENT_BUTTON, "FinancialsSave", {});
    }

    isTechnicalName(value, recordId) {
        if (!value) return false;

        const trimmedValue = String(value).trim();

        if (recordId && trimmedValue === recordId) {
            return true;
        }

        return /^[a-zA-Z0-9]{15,18}$/.test(trimmedValue);
    }

    getDisplayName(value, recordId) {
        return this.isTechnicalName(value, recordId) ? '' : (value ?? '');
    }

   buildUpdateObject(row, convertedType) {
        const fields = {
            [ID_FIELD.fieldApiName]: row.Id,
            [FUNDS_FIELD.fieldApiName]: row.DMT_Funds__c !== "" ? Number(row.DMT_Funds__c) : null,
            [TYPE_FIELD.fieldApiName]: convertedType,
            [OPPORTUNITY_FIELD.fieldApiName]: this.recordId
        };

        if (row.Name && row.Name.trim() !== '') {
            fields[NAME_FIELD.fieldApiName] = row.Name.trim();
        }

        return fields;
    }
}