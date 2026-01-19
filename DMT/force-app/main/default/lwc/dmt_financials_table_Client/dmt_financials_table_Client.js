import { LightningElement, api, track } from 'lwc';
import { updateRecord } from "lightning/uiRecordApi";
import LightningConfirm from 'lightning/confirm';

import getFinancials from '@salesforce/apex/DMT_BasicFinancialsController_Client.getFinancials';
import getFinancialsOpportunity from '@salesforce/apex/DMT_BasicFinancialsController.getFinancials';
import pubsub from 'omnistudio/pubsub';

const EVENT_SAVE = 'Save';
const EVENT_BUTTON = 'Button';
const EVENT_SET = 'Set';
const CURRENT_YEAR = new Date().getFullYear();
const NA_VALUE = 'N/A';
const ERROR_INVALID_NUMBER = 'Please enter valid numbers in the numeric fields of the table.';
const ERROR_INVALID_UPDATE = 'Error in data saving.';
const ERROR_INVALID_LOADING = 'Error loading data.';

export default class DmtFinancialsTableClient extends LightningElement {

    _recordId;
    _opportunityClientId;
    _groupId;
    _isClient = false;
    _isOpportunity = false;
    _isEditMode = false;
    _isReadOnly = false;
    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        this.loadFinancialData();
    }

    @api
    get groupId() {
        return this._groupId;
    }
    set groupId(value) {
        this._groupId = value;
        this.loadFinancialData();
    }

    @api
    get opportunityClientId() {
        return this._opportunityClientId;
    }
    set opportunityClientId(value) {
        this._opportunityClientId = value;
    }


    @api
    get isOpportunity() {
        return this._isOpportunity;
    }
    set isOpportunity(value) {
        this._isOpportunity = (value == 'true' || value === true);
        this.loadFinancialData();
    }

    @api
    get isClient() {
        return this._isClient;
    }
    set isClient(value) {
        this._isClient = (value == 'true' || value === true);
        this.loadFinancialData();
    }
    @api
    get isReadOnlyUser() {
        return this._isReadOnly;
    }
    set isReadOnlyUser(value) {
        this._isReadOnly = (value == true || value == 'true');
        if (this.processedData) {

            const shouldEdit = this._isEditMode && !this._isReadOnly; 
            console.log('shouldEdit', shouldEdit);
            this.toggleEditMode(shouldEdit); 
        }
    }

    @api
    get isEditMode() {
        return this._isEditMode;
    }
    set isEditMode(value) {

        this._isEditMode = (value == 'true' || value === true);

        if (this.processedData) {
            const shouldEdit = this._isEditMode && !this._isReadOnly;
            console.log('shouldEdit', shouldEdit);
            this.toggleEditMode(shouldEdit);
        }
        
    }

    @track originalData;
    @track processedData;
    isDataProcessed = false;

    columns = [
        { label: '', fieldName: 'category', type: 'text', isEditable: false },
        { label: `${CURRENT_YEAR - 1}`, fieldName: 'lastYear', type: 'text', isEditable: true },
        { label: `${CURRENT_YEAR} (optional)`, fieldName: 'currentYear', type: 'text', isEditable: true },
        { label: `${CURRENT_YEAR + 1} (optional)`, fieldName: 'nextYear', type: 'text', isEditable: true },
        { label: `${CURRENT_YEAR + 2} (optional)`, fieldName: 'nextYear1', type: 'text', isEditable: true },
        { label: `${CURRENT_YEAR + 3} (optional)`, fieldName: 'nextYear2', type: 'text', isEditable: true }
    ];

    categoryFieldMapping = {
        'Revenues': 'Revenues',
        'EBITDA': 'EBITDA',
        'EBIT': 'EBIT',
        'Net Income': 'Net_Income',
        'Free Cash Flow': 'Free_Cash_Flow',
        'Debt / EBITDA': 'Debt_EBITDA',
        'Net Debt / EBITDA': 'Net_Debt_EBITDA'
    };

    @track data = [];

    connectedCallback() {
        this.eventHandlers = {
            DMT_CLIENT_GROUP_V2: this.handleSave.bind(this),
        };
        pubsub.register(EVENT_SAVE, this.eventHandlers);
    }

    disconnectedCallback() {
        pubsub.unregister(EVENT_SAVE, this.eventHandlers);
    }

    /**
     * @description Centraliza la lógica para cargar los datos. Se llama cuando las propiedades @api cambian.
     * Valida que los datos necesarios estén presentes antes de llamar a Apex.
     */
    loadFinancialData() {

        if (this.isClient && this.isValidSalesforceId(this.recordId)) {
            this.fetchFinancialsFromApex();
        }

        if (this.isOpportunity && this.isValidSalesforceId(this.recordId) && this.isValidSalesforceId(this.groupId)) {
            this.fetchFinancialsFromApexOpportunity();
        }
    }

    /**
     * @description Valida si un string tiene el formato de un ID de Salesforce.
     */
    isValidSalesforceId(id) {
        return id && /^[a-zA-Z0-9]{15}(|([a-zA-Z0-9]{3}))$/.test(id);
    }


    async fetchFinancialsFromApexOpportunity() {
        try {

            const [opportunityFinancials, accountData] = await Promise.all([
                getFinancialsOpportunity({ recordId: this.recordId }),
                getFinancials({ recordId: this.groupId })
            ]);

            if (!opportunityFinancials || opportunityFinancials.length === 0 || !accountData || accountData.length === 0) {

                this.data = [];
                return;
            }

            const opportunityRecord = opportunityFinancials[0];
            const accountRecord = accountData[0];

            this.data = Object.keys(this.categoryFieldMapping).map((label, index) => {

                const apiName = this.categoryFieldMapping[label];

                return {
                    Id: index,
                    category: label,
                    isEditable: !label.includes('Total'),
                    rowClass: 'slds-hint-parent',

                    lastYear: opportunityRecord[`${apiName}_Last_Year_number__c`] || NA_VALUE,
                    currentYear: opportunityRecord[`${apiName}_Current_Year_number__c`] || NA_VALUE,
                    nextYear: opportunityRecord[`${apiName}_Next_Year_number__c`] || NA_VALUE,
                    nextYear1: opportunityRecord[`${apiName}_Next_Year_1_number__c`] || NA_VALUE,
                    nextYear2: opportunityRecord[`${apiName}_Next_Year_2_number__c`] || NA_VALUE,

                    lastYearAccount: accountRecord[`${apiName}_Last_Year_number__c`] || NA_VALUE,
                    currentYearAccount: accountRecord[`${apiName}_Current_Year_number__c`] || NA_VALUE,
                    nextYearAccount: accountRecord[`${apiName}_Next_Year_number__c`] || NA_VALUE,
                    nextYear1Account: accountRecord[`${apiName}_Next_Year_1_number__c`] || NA_VALUE,
                    nextYear2Account: accountRecord[`${apiName}_Next_Year_2_number__c`] || NA_VALUE
                };
            });

            this.originalData = JSON.parse(JSON.stringify(this.data));
            this.processDataForView();

            if (this.isEditMode) {
                this.toggleEditMode(true);
            }

        } catch (error) {

            pubsub.fire("Set", "Error", { errorMessage: ERROR_INVALID_LOADING});
            console.error('Error detallado al obtener datos financieros:', JSON.stringify(error));
        }
    }

    /**
     * @description Llama al método Apex para obtener los datos financieros.
     */
    async fetchFinancialsFromApex() {
        try {

            const result = await getFinancials({ recordId: this._recordId });

            if (!result || result.length === 0) {
                this.data = [];
                return;
            }

            const financialsData = result[0];

            this.data = Object.keys(this.categoryFieldMapping).map((label, index) => {
                const apiName = this.categoryFieldMapping[label];
                return {
                    Id: index,
                    category: label,
                    isEditable:true, // Asumimos que todas son editables por defecto
                    lastYear: financialsData[`${apiName}_Last_Year_number__c`] ?? NA_VALUE,
                    currentYear: financialsData[`${apiName}_Current_Year_number__c`] ?? NA_VALUE,
                    nextYear: financialsData[`${apiName}_Next_Year_number__c`] ?? NA_VALUE,
                    nextYear1: financialsData[`${apiName}_Next_Year_1_number__c`] ?? NA_VALUE,
                    nextYear2: financialsData[`${apiName}_Next_Year_2_number__c`] ?? NA_VALUE,
                };
            });

            this.originalData = JSON.parse(JSON.stringify(this.data));
            this.processDataForView();

            if (this.isEditMode) {
                this.toggleEditMode(true);
            }

        } catch (error) {
            pubsub.fire("Set", "Error", { errorMessage: ERROR_INVALID_LOADING});
            console.error('Error detallado al obtener datos financieros:', JSON.stringify(error));
        }
    }

    /**
     * @description Transforma los datos crudos en una estructura adecuada para la vista (template).
     * Este enfoque de separar el modelo de datos (`this.data`) del modelo de vista (`this.processedData`) es robusto.
     */
    processDataForView() {

        this.processedData = this.data.map(row => ({
            ...row,
            values: this.columns.map(column => ({
                field: column.fieldName,
                label: column.label,
                value: row[column.fieldName],
                accountValue: row[column.fieldName + 'Account'],
                isEquals: row[column.fieldName + 'Account'] == row[column.fieldName],
                isEditing: false,
                isEditable: column.isEditable && row.isEditable,
                styleRedo: row[column.fieldName + 'Account'] === row[column.fieldName] ? 'display:none;' : '',
                withoutRedo: row[column.fieldName + 'Account'] === row[column.fieldName] ? 'margin:top: 40% !important;' : '',
                cellClass: "slds-has-button slds-has-flexi-truncate"
            }))
        }));
        this.isDataProcessed = true;
    }

    /**
     * @description Activa el modo de edición para todas las celdas.
     */
    toggleEditMode(isEditing) {

        console.log('isEditing, ', isEditing);
        this._isEditMode = isEditing;
        if(this.processedData) {
            this.processedData = this.processedData.map(row => {
                row.values = row.values.map(cell => {
                    cell.isEditing = isEditing;
                    return cell;
                });
                return row;
            });
        }
    }

    /**
     * @description Dispara un evento para notificar a otros componentes que se ha iniciado la edición.
     */
    handleEdit() {
        pubsub.fire("Button", "Edit", {});
    }
    async handleRedoAllTable() {
        try {
            const result = await LightningConfirm.open({
            message: 'Are you sure you want to make this change?',
            label: 'Confirmation of Change',
            theme: 'alt-inverse' // 'default' | 'success' | 'warning' | 'error'
            });

            if (result) {
                this.redoAllTable();
                console.log('Se realiza el cambio');
            } else {
                console.log('El usuario canceló la acción');
            }
        } catch (e) {
            console.error('Error mostrando LightningConfirm:', e);
            
        }
    }
    redoAllTable(){
        console.log('empieza acción');
        this.processedData = this.processedData.map(row => {
            row.values = row.values.map(cell => {
                cell.isEditing = false;
                cell.value = cell.accountValue === NA_VALUE ? 'N/A' : cell.accountValue;
                this.hasUnsavedChanges = true;
                if(cell.value != null && cell.value != undefined){
                    row[cell.field] = cell.value;
                }                
                row.hasChanged = true;
                return cell;
            });
            return row;
        });
        this.data = JSON.parse(JSON.stringify(this.processedData));
        console.log('this.data' , JSON.stringify(this.data));
        console.log('this.processedData' , JSON.stringify(this.processedData));
        this.handleSave();
    }
    
    handleRedo(event) {

        const { id: rowId, field: fieldName } = event.target.dataset;

        this.processedData = this.processedData.map(row => {
            if (row.Id == rowId) {
                row.values = row.values.map(cell => {
                    if (cell.field == fieldName) {
                        cell.isEditing = false;
                        cell.value = cell.accountValue == NA_VALUE ? null : cell.accountValue;
                        this.hasUnsavedChanges = true;
                        row[fieldName] = cell.value;
                        row.hasChanged = true;
                        this.data[row.Id] = row;

                    }
                    return cell;
                })
            }
            return row;
        });


        this.data = JSON.parse(JSON.stringify(this.processedData));

        this.handleSave();
    }

    /**
     * @description Orquesta el proceso de guardado de datos. Valida los cambios y construye el objeto para la UI API.
     */
    async handleSave() {

        this.isDataProcessed = false;

        const changedRows = this.data.filter(row => row.hasChanged);
        const fieldsToUpdate = this.buildUpdateObject(changedRows);

        try {
            await updateRecord({ fields: fieldsToUpdate });

            this.data = this.data.map(row => ({ ...row, hasChanged: false }));
            this.originalData = JSON.parse(JSON.stringify(this.data));

            pubsub.fire(EVENT_BUTTON, "FinancialsSave", {});
            this.isDataProcessed = true;

        } catch (error) {

            console.log('DmtFinancialsTableClient Error ', JSON.stringify(error, null, 2));
            pubsub.fire(EVENT_SET, "Error", { errorMessage: ERROR_INVALID_UPDATE });
        }

        this.loadFinancialData();
    }

    /**
     * @description Maneja los cambios en los inputs de la tabla.
     * Luego se invoca `processDataForView` para regenerar los datos de la vista, asegurando consistencia.
     */
    handleInputChange(event) {
        const { id, field } = event.target.dataset;
        const newValue = event.target.value;

        const rowIndex = this.data.findIndex(row => row.Id == id);
        if (rowIndex !== -1) {
            this.data[rowIndex] = { ...this.data[rowIndex], [field]: newValue, hasChanged: true };
        }
    }

    buildUpdateObject(changedRows) {

        const actualRecordId = this.isClient == true ? this.recordId : this.opportunityClientId;

        const fieldsToUpdate = { Id: actualRecordId };
        const fieldMap = {
            lastYear: '_Last_Year_number__c',
            currentYear: '_Current_Year_number__c',
            nextYear: '_Next_Year_number__c',
            nextYear1: '_Next_Year_1_number__c',
            nextYear2: '_Next_Year_2_number__c'
        };

        changedRows.forEach(row => {

            const originalRow = this.originalData.find(orig => orig.Id === row.Id);
            const sanitizedColumn = this.categoryFieldMapping[row.category];

            for (const fieldName in fieldMap) {
                const newValue = row[fieldName];
                const originalValue = originalRow[fieldName];

                if (newValue !== originalValue) {
                    const apiFieldName = sanitizedColumn + fieldMap[fieldName];
                    fieldsToUpdate[apiFieldName] = (newValue == NA_VALUE || newValue == '' || newValue == null) ? null : Number(newValue);
                }
            }
        });

        return fieldsToUpdate;
    }
}