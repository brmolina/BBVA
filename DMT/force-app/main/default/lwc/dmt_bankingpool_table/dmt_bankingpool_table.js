import { LightningElement, api, track } from 'lwc';
import { updateRecord, createRecord } from "lightning/uiRecordApi";
import pubsub from 'omnistudio/pubsub';

import ID_FIELD from '@salesforce/schema/DMT_Banking_Pool_Structure__c.Id';
import OPPORTUNITY_FIELD from '@salesforce/schema/DMT_Banking_Pool_Structure__c.DMT_Opportunity__c';
import TICKET_FIELD from '@salesforce/schema/DMT_Banking_Pool_Structure__c.DMT_Ticket__c';
import FEES_FIELD from '@salesforce/schema/DMT_Banking_Pool_Structure__c.DMT_Fees__c';
import MARGIN_FIELD from '@salesforce/schema/DMT_Banking_Pool_Structure__c.DMT_Margin__c';
import BANKS_FIELD from '@salesforce/schema/DMT_Banking_Pool_Structure__c.DMT_N_Banks__c';

const EVENT_SAVE = 'Save';
const EVENT_BUTTON = 'Button';

export default class DmtBankingPoolTable extends LightningElement {
    @api label;
    @api recordId;

    _tableData = [];
    @api
    get tableData() {
        return this._tableData;
    }
    set tableData(value) {
        console.log('tableData recibido:', JSON.parse(JSON.stringify(value)));
        this._tableData = Array.isArray(value) ? value : [];
        this.initializeTable();
    }

    @track originalData = [];
    @track processedData = [];
    @track isDataProcessed = false;

    _internalEditMode = false;
    _isReadOnly = false;
    _stageName;
    eventHandlers = {};

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

    @api
    get isEditMode() {
        return this._internalEditMode;
    }
    set isEditMode(value) {
        const bool = value === true || value === "true";
        this._internalEditMode = bool;
        if (this.processedData && bool) this.setEditModeForView(true);
    }

    connectedCallback() {
        this.eventHandlers = {
            DMT_CLIENT_GROUP_V2: this.handleSave.bind(this)
        };
        pubsub.register(EVENT_SAVE, this.eventHandlers);

        // Initialize once on connect in case tableData was set before connectedCallback
        this.initializeTable();
    }

    disconnectedCallback() {
        pubsub.unregister(EVENT_SAVE, this.eventHandlers);
    }

    initializeTable() {
        // Ensure processed flag reset while building
        this.isDataProcessed = false;

        // Defaults tiers
        const defaults = this.createDefaultRows();

        // If no incoming data -> use defaults
        if (!this._tableData || this._tableData.length === 0) {
            // copy defaults to originalData
            this.originalData = defaults.map(d => ({ ...d }));
        } else {
            // Fill defaults with incoming records matched by Name (or DMT_Tier__c fallback)
            this.originalData = defaults.map(def => {
                // find record where Name matches the tier label OR DMT_Tier__c matches (fallback)
                const rec = this._tableData.find(r => {
                    if (!r) return false;
                    const name = r.Name || r.DMT_Tier__c || '';
                    return name === def.tierLabel;
                });

                if (rec) {
                    return {
                        index: def.index,
                        tierLabel: def.tierLabel,
                        Id: rec.Id || null,
                        DMT_Ticket__c: rec.DMT_Ticket__c ?? "",
                        DMT_Fees__c: rec.DMT_Fees__c ?? "",
                        DMT_Margin__c: rec.DMT_Margin__c ?? "",
                        DMT_N_Banks__c: rec.DMT_N_Banks__c ?? "",
                        hasChanged: false
                    };
                } else {
                    // keep default empty row
                    return { ...def };
                }
            });

            // If incoming has extra records with Name that don't match defaults, we ignore them
            // (This follows your requirement to show the fixed 4 tiers)
        }

        this.processDataForView();
        this.isDataProcessed = true;

        // If edit mode was already requested, apply it
        if (this._internalEditMode) {
            this.setEditModeForView(true);
        }
    }

    createDefaultRows() {
        const tiers = [
            "Tier 1",
            "Tier 2",
            "Tier 3",
            "Tier 4 or above"
        ];

        return tiers.map((tier, index) => ({
            index,
            tierLabel: tier,
            Id: null,
            DMT_Ticket__c: "",
            DMT_Fees__c: "",
            DMT_Margin__c: "",
            DMT_N_Banks__c: "",
            hasChanged: false
        }));
    }

    processDataForView() {
        this.processedData = this.originalData.map(row => ({
            index: row.index,
            Id: row.Id ?? row.index,
            tierLabel: row.tierLabel,
            values: [
                {
                    field: 'DMT_Ticket__c',
                    label: 'Ticket (Mn)',
                    value: row.DMT_Ticket__c,
                    isEditing: this._internalEditMode && !row.isTotal,
                    isEditable: true,
                    type: 'number',
                    cellClass: ''
                },
                {
                    field: 'DMT_Fees__c',
                    label: 'Fees',
                    value: row.DMT_Fees__c,
                    isEditing: this._internalEditMode && !row.isTotal,
                    isEditable: true,
                    type: 'number',
                    cellClass: ''
                },
                {
                    field: 'DMT_Margin__c',
                    label: 'Margin',
                    value: row.DMT_Margin__c,
                    isEditing: this._internalEditMode && !row.isTotal,
                    isEditable: true,
                    type: 'number',
                    cellClass: ''
                },
                {
                    field: 'DMT_N_Banks__c',
                    label: 'Nº Banks',
                    value: row.DMT_N_Banks__c,
                    isEditing: this._internalEditMode && !row.isTotal,
                    isEditable: true,
                    type: 'number',
                    cellClass: ''
                }
            ]
        }));
    }

    setEditModeForView(isEditing) {
        this._internalEditMode = isEditing;

        if (this.processedData) {
            this.processedData = this.processedData.map(row => {
                row.values = row.values.map(c => {
                    c.isEditing = isEditing;
                    return c;
                });
                return row;
            });
        }

        if (isEditing) pubsub.fire(EVENT_BUTTON, "Edit", {});
    }

    handleEditCell() {
        if (!this.isEditPencilEnabled) {
            return;
        }
        this.setEditModeForView(true);
    }

    handleInputChange(event) {
        const idx = event.target.dataset.index;
        const field = event.target.dataset.field;
        const value = event.target.value;

        // defensive: ensure index exists
        const i = Number(idx);
        if (Number.isNaN(i) || !this.originalData[i]) return;

        this.originalData[i][field] = value;
        this.originalData[i].hasChanged = true;

        // reflect changes
        this.processDataForView();
    }

    @api
    async handleSave() {
        console.log("handleSave ejecutado - Banking Pool");

        // collect changed rows
        const changed = this.originalData.filter(r => r.hasChanged);

        if (changed.length === 0) {
            this._internalEditMode = false;
            this.processDataForView();
            return;
        }

        for (let row of changed) {
            // build fields object
            const fields = {
                // ensure Name is set to tierLabel so we can identify rows later
                Name: row.tierLabel,
                [TICKET_FIELD.fieldApiName]: row.DMT_Ticket__c !== "" ? row.DMT_Ticket__c : null,
                [FEES_FIELD.fieldApiName]: row.DMT_Fees__c !== "" ? row.DMT_Fees__c : null,
                [MARGIN_FIELD.fieldApiName]: row.DMT_Margin__c !== "" ? row.DMT_Margin__c : null,
                [BANKS_FIELD.fieldApiName]: row.DMT_N_Banks__c !== "" ? row.DMT_N_Banks__c : null,
                [OPPORTUNITY_FIELD.fieldApiName]: this.recordId
            };

            if (row.Id) {
                fields[ID_FIELD.fieldApiName] = row.Id;
                try {
                    console.log('Updating record:', JSON.stringify(fields));
                    await updateRecord({ fields });
                } catch (err) {
                    console.error('Error updating banking pool record', err);
                    // you can fire error pubsub if you want
                }
            } else {
                try {
                    console.log('Creating record:', JSON.stringify(fields));
                    await createRecord({
                        apiName: "DMT_Banking_Pool_Structure__c",
                        fields
                    });
                } catch (err) {
                    console.error('Error creating banking pool record', err);
                }
            }
        }

        // reset flags & view
        this.originalData.forEach(r => (r.hasChanged = false));
        this._internalEditMode = false;

        // after saving, re-initialize to pick up IDs / persisted values
        // (if apex or parent refreshed tableData later, that is also fine)
        await this.initializeTable();

        // notify
        pubsub.fire(EVENT_BUTTON, "FinancialsSave", {});
    }
}