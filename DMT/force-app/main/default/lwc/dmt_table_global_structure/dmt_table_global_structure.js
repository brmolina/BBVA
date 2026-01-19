import { LightningElement, api, track } from 'lwc';
import { updateRecord, createRecord } from "lightning/uiRecordApi";
import pubsub from 'omnistudio/pubsub';
import NAME_FIELD from "@salesforce/schema/DMT_Global_Structure__c.Name";
import FUNDS_FIELD from "@salesforce/schema/DMT_Global_Structure__c.DMT_Funds__c";
import TYPE_FIELD from "@salesforce/schema/DMT_Global_Structure__c.DMT_Type__c";
import OPPORTUNITY_FIELD from "@salesforce/schema/DMT_Global_Structure__c.DMT_Opportunity__c";
import ID_FIELD from "@salesforce/schema/DMT_Global_Structure__c.Id";

const EVENT_SAVE = 'Save';
const EVENT_BUTTON = 'Button';
const EVENT_SET = 'Set';

export default class DmtStructureTable extends LightningElement {
    @api label;
    @api recordId;
    @api showcopypaste = false;

    @track originalData = [];
    @track processedData = [];
    @track isDataProcessed = false;

    _internalEditMode = false;
    eventHandlers = {};
    _tableData = [];

    typeMapping = {
        "DEBT FUNDS (Mn)": "Funding Debt",
        "EQUITY FUNDS (Mn)": "Funding Equity",
        "USES": "Uses"
    };

    @api
    get tableData() {
        return this._tableData;
    }
    set tableData(value) {
        console.log('tableData setter called:', JSON.stringify(value));
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
        if (this.processedData && isTrue) {
            this.setEditModeForView(true);
        }
    }

    connectedCallback() {
        this.eventHandlers = {
            DMT_CLIENT_GROUP_V2: this.handleSave.bind(this),
        };
        pubsub.register(EVENT_SAVE, this.eventHandlers);
    }

    disconnectedCallback() {
        pubsub.unregister(EVENT_SAVE, this.eventHandlers);
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
                Name: r.Name ?? "",
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

        this.processDataForView();

        if (this._internalEditMode) {
            this.setEditModeForView(true);
        }
    }

    createDefaultRows() {
        let count = 0;
        if (this.label === "DEBT FUNDS (Mn)") count = 5;
        else if (this.label === "EQUITY FUNDS (Mn)") count = 4;
        else if (this.label === "USES") count = 10;

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
            Name: "TOTAL",
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

        if (isEditing) {
            pubsub.fire(EVENT_BUTTON, "Edit", {});
        }
    }

    handleEditCell() {
        this.setEditModeForView(true);
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
    }

    @api
    async handleSave() {
        console.log('handleSave called');
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
                    console.log('update record:', JSON.stringify(fields));
                    await updateRecord({ fields });
                } catch (error) {
                    pubsub.fire(EVENT_SET, "Error", { errorMessage: 'Error updating record' });
                }
            } else {
                const fields = {
                    [NAME_FIELD.fieldApiName]: row.Name || '',
                    [FUNDS_FIELD.fieldApiName]: row.DMT_Funds__c !== "" ? Number(row.DMT_Funds__c) : null,
                    [TYPE_FIELD.fieldApiName]: convertedType,
                    [OPPORTUNITY_FIELD.fieldApiName]: this.recordId
                };
                try {
                    console.log('create record:', JSON.stringify(fields));
                    await createRecord({ apiName: 'DMT_Global_Structure__c', fields });
                } catch (error) {
                    console.log('error createRecord:', JSON.stringify(error));
                    pubsub.fire(EVENT_SET, "Error", { errorMessage: 'Error creating record' });
                }
            }
        }

        this._internalEditMode = false;
        this.originalData.forEach(r => r.hasChanged = false);
        const totalRow = this.originalData.find(r => r.isTotal);
        if (totalRow) totalRow.DMT_Funds__c = this.calculateTotal();

        this.processDataForView();
        pubsub.fire(EVENT_BUTTON, "FinancialsSave", {});
    }

    buildUpdateObject(row, convertedType) {
        return {
            [ID_FIELD.fieldApiName]: row.Id,
            [NAME_FIELD.fieldApiName]: row.Name,
            [FUNDS_FIELD.fieldApiName]: row.DMT_Funds__c !== "" ? Number(row.DMT_Funds__c) : null,
            [TYPE_FIELD.fieldApiName]: convertedType,
            [OPPORTUNITY_FIELD.fieldApiName]: this.recordId
        };
    }
}