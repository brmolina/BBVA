import { LightningElement, api, track } from 'lwc';
import { loadStyle } from "lightning/platformResourceLoader";
import { updateRecord } from "lightning/uiRecordApi";
import LightningConfirm from 'lightning/confirm';

import getBussinessPlan from '@salesforce/apex/DMT_BussinessPlanController_Client.getBussinessPlan';
import getBusinessPlanOpportunity from '@salesforce/apex/DMT_BussinessPlanController.getBussinessPlan';
import DMT_Styles from "@salesforce/resourceUrl/DMT_Styles";
import pubsub from 'omnistudio/pubsub';

const EVENT_SAVE = 'Save';
const EVENT_BUTTON = 'Button';
const EVENT_SET = 'Set';
const NA_VALUE = 'N/A';
const ERROR_INVALID_NUMBER = 'DmtBusinessPlanTableClient Please enter valid numbers in the numeric fields of the table.';
const ERROR_INVALID_STYLE = 'Error loading static resource styles.';
const ERROR_INVALID_UPDATE = 'Error in data saving.';
const ERROR_INVALID_LOADING = 'Error loading data.';

export default class DmtBusinessPlanTableClient extends LightningElement {

    _recordId;
    _groupId;
    _isOpportunity = false;
    _isClient = false;
    _isEditMode = false;
    _stylesLoaded = false;
    _opportunityClientId;

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        this.loadBusinessPlanData();
    }

    @api
    get groupId() {
        return this._groupId;
    }
    set groupId(value) {
        this._groupId = value;
        this.loadBusinessPlanData();
    }

    @api
    get isOpportunity() {
        return this._isOpportunity;
    }
    set isOpportunity(value) {
        this._isOpportunity = (value == 'true' || value === true);
        this.loadBusinessPlanData();
    }

    @api
    get isClient() {
        return this._isClient;
    }
    set isClient(value) {
        this._isClient = (value == 'true' || value === true);
        this.loadBusinessPlanData();
    }

    @api
    get isEditMode() {
        return this._isEditMode;
    }
    set isEditMode(value) {
        this._isEditMode = (value == 'true' || value === true);
        if (this._isEditMode && this.processedData) {
            this.toggleEditMode(true);
        }
    }

    @api
    get opportunityClientId() {
        return this._opportunityClientId;
    }
    set opportunityClientId(value) {
        this._opportunityClientId = value;
    }

    @track originalData;
    @track data;
    @track processedData;
    isDataProcessed = false;
    accountData;

    columns = [
        { label: '', fieldName: 'category', type: 'text', isEditable: false },
        { label: `FY${new Date().getFullYear() - 2}`, fieldName: 'pastYear2', type: 'text', isEditable: true },
        { label: `FY${new Date().getFullYear() - 1}`, fieldName: 'pastYear', type: 'text', isEditable: true },
        { label: `FY${new Date().getFullYear()}E`, fieldName: 'currentYear', type: 'text', isEditable: true },
        { label: `FY${new Date().getFullYear() + 1}E`, fieldName: 'nextYear', type: 'text', isEditable: true }
    ];

    rowDefinitions = [
        {label: 'Corp. Synd. Lending', value: 'Corp_Synd_Lending'},
        {label: 'Structured Finance', value: 'Structured_Finance'},
        {label: 'Structured Trade Finance', value: 'Str_Trade_Finance'},
        {label: 'Rates', value: 'Rates'},
        {label: 'GTF', value: 'GTF'},
        {label: 'Working Capital', value: 'Working_Capital'},
        {label: 'Total Non X-Sell', value: 'Total_Non_X_Sell'},
        {label: 'ECM/M&A', value: 'ECM_M_A'},
        {label: 'DCM', value: 'DCM'},
        {label: 'Credit/Equity', value: 'Credit_Equity'},
        {label: 'FX/CCS', value: 'FX_CCS'},
        {label: 'Cash Management', value: 'Cash_Management'},
        {label: 'Client Resources', value: 'Client_Resources'},
        {label: 'Securities Services', value: 'Securities_Services'},
        {label: 'Total X-Sell', value: 'Total_X_Sell'},
        {label: 'Total Revenues', value: 'Total_Revenues'},
        {label: '% Cross Border Revenues', value: 'gf_kpi_trans_fees'},
        {label: 'Transactional KPI', value: 'gf_xb_cust_ope_revenue'}
    ];

    connectedCallback() {
        this.eventHandlers = {
            DMT_CLIENT_GROUP_V2: this.handleSave.bind(this),
        };
        pubsub.register(EVENT_SAVE, this.eventHandlers);

        this.loadComponentStyles();
    }

    disconnectedCallback() {
        pubsub.unregister(EVENT_SAVE, this.eventHandlers);
    }

    loadComponentStyles() {
        if (this._stylesLoaded) {
            return;
        }
        loadStyle(this, DMT_Styles)
            .then(() => {
                this._stylesLoaded = true;
            })
            .catch(error => {
                pubsub.fire(EVENT_SET, "Error", { errorMessage: ERROR_INVALID_STYLE });
                console.error('Error loading static resource styles:', error);
            });
    }

    async loadBusinessPlanData() {

        try {

            if (this.isClient && this.isValidSalesforceId(this.recordId)) {
                this.fetchBusinessFromApex()
            }

            if (this.isOpportunity && this.isValidSalesforceId(this.recordId) && this.isValidSalesforceId(this.groupId)) {
                this.fetchBusinessFromApexOpportunity();
            }
        } catch (error) {
            pubsub.fire(EVENT_SET, "Error", { errorMessage: ERROR_INVALID_LOADING });
            console.log('DmtBusinessPlanTableClient loadBusinessPlanData error' + error);
            this.showToast('Error al cargar datos', error.body.message, 'error');
        }
    }

    async fetchBusinessFromApex() {

        const result = await getBussinessPlan({ recordId: this.recordId });

        this.transformApexData(result);

        if (this.isEditMode) {
            this.toggleEditMode(true);
        }
    }

    async fetchBusinessFromApexOpportunity() {
        try {

            const [opportunityData, accountData] = await Promise.all([
                getBusinessPlanOpportunity({ recordId: this.recordId }),
                getBussinessPlan({ recordId: this.groupId })
            ]);


            if (!opportunityData || opportunityData.length === 0 || !accountData || accountData.length === 0) {

                pubsub.fire("Set", "Error", { errorMessage: ERROR_INVALID_LOADING});
                console.error('No hay datos:', JSON.stringify(error));
                return;
            }

            this.accountData = accountData[0];

            this.transformApexData(opportunityData);

            if (this.isEditMode) {
                this.toggleEditMode(true);
            }

        } catch (error) {
            pubsub.fire("Set", "Error", { errorMessage: ERROR_INVALID_LOADING});
            console.error('Error detallado al obtener datos Business Plan:', JSON.stringify(error));
        }
    }

    transformApexData(apexData) {
        const resultData = apexData[0];
        if (!resultData) return;

        this.data = this.rowDefinitions.map((rowDef, index) => {
            const row = {
                Id: index,
                category: rowDef.label,
                isEditable: !rowDef.label.includes('Total'),
                class: rowDef.label.includes('Total') ? 'slds-hint-parent dmt-table-title' : 'slds-hint-parent'
            };

            const fieldMap = this.getFieldMapping(rowDef.value);

            row.pastYear2 = resultData[fieldMap.pastYear2] ?? NA_VALUE;
            row.pastYear = resultData[fieldMap.pastYear] ?? NA_VALUE;
            row.currentYear = resultData[fieldMap.currentYear] ?? NA_VALUE;
            row.nextYear = resultData[fieldMap.nextYear] ?? NA_VALUE;

            if(this.isOpportunity) {
                row.pastYear2Account = this.accountData[fieldMap.pastYear2] ?? NA_VALUE;
                row.pastYearAccount = this.accountData[fieldMap.pastYear] ?? NA_VALUE;
                row.currentYearAccount = this.accountData[fieldMap.currentYear] ?? NA_VALUE;
                row.nextYearAccount = this.accountData[fieldMap.nextYear] ?? NA_VALUE;
            }

            return row;
        });

        this.originalData = JSON.parse(JSON.stringify(this.data));
        this.processDataForView();
    }
    async handleRedoAllTable() {
        try {
            const result = await LightningConfirm.open({
            message: 'Are you sure you want to make this change?',
            variant: 'header',
            label: 'Confirmation of Change',
            theme: 'alt-inverse' // 'default' | 'success' | 'warning' | 'error'
            });

            if (result) {
                this.redoAllTable();
            } else {
                console.log('El usuario canceló la acción');
            }
        } catch (e) {
            console.error('Error mostrando LightningConfirm:', JSON.stringify(e));    
        }
    }
    redoAllTable(){
        try {
            this.processedData = this.processedData.map(row => {
                if (!row.category.includes('Total')){
                    row.values = row.values.map(cell => {
                        cell.isEditing = false;
                        cell.value = cell.accountValue === NA_VALUE ? null : cell.accountValue;
                        cell.isEditable = false;
                        this.hasUnsavedChanges = true;
                        row[cell.field] = cell.value;
                        row.hasChanged = true;   
                        return cell;
                    });
                }
                return row;  
            });

            this.data = this.processedData;
            this.handleSave();   
        } catch (e) {

            console.error('Error mostrando  redoAllTable: ', e);    
        }
    }

    handleRedo(event) {

        const rowId = event.target.dataset.id;
        const fieldName = event.target.dataset.field;

        this.processedData = this.processedData.map(row => {
            if (row.Id == rowId) {
                row.values = row.values.map(cell => {
                    if (cell.field == fieldName) {
                        cell.isEditing = false;
                        cell.value = cell.accountValue == NA_VALUE ? null : cell.accountValue;
                        cell.isEditable = false;
                        cell.styleRedo = '';;
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

        this.data = this.processedData;
        this.handleSave();
    }

    getFieldMapping(columnValue) {
        const suffixes = {
            default: {
                pastYear2: `Past2_FY_${columnValue}_amount__c`,
                pastYear: `Past_FY_${columnValue}_amount__c`,
                currentYear: `Current_FY_${columnValue}_amount__c`,
                nextYear: `Next_FY_${columnValue}_amount__c`
            },
            xb_revenue: {
                pastYear2: `${columnValue}_2ya_per__c`,
                pastYear: `${columnValue}_ly_per__c`,
                currentYear: `${columnValue}_cyr_per__c`,
                nextYear: `${columnValue}_nxy_per__c`
            },
            kpi_fees: {
                pastYear2: `${columnValue}_2ya_amount__c`,
                pastYear: `${columnValue}_ly_amount__c`,
                currentYear: `${columnValue}_cyr_amount__c`,
                nextYear: `${columnValue}_nxy_amount__c`
            },
            ecm_ma: {
                pastYear2: `Past2_FY_${columnValue}_Amount__c`,
                pastYear: `Past_FY_${columnValue}_Amount__c`,
                currentYear: `Current_FY_${columnValue}_Amount__c`,
                nextYear: `Next_FY_${columnValue}_amount__c`
            }
        };

        if (columnValue === 'gf_xb_cust_ope_revenue') return suffixes.xb_revenue;
        if (columnValue === 'gf_kpi_trans_fees') return suffixes.kpi_fees;
        if (columnValue === 'ECM_M_A') return suffixes.ecm_ma;
        return suffixes.default;
    }

    /**
     * Este método prepara los datos para ser renderizados en la tabla personalizada.
     */
    processDataForView() {
        this.processedData = this.data.map(row => {
            let values = this.columns.map(column => ({
                field: column.fieldName,
                label: column.label,
                accountValue: row[column.fieldName + 'Account'],
                isEquals: row[column.fieldName + 'Account'] === row[column.fieldName],
                value: row[column.fieldName],
                isEditing: false,
                isEditable: column.isEditable && row.isEditable,
                styleRedo: row[column.fieldName + 'Account'] === row[column.fieldName] ? 'display:none;' : '',
                withoutRedo: row[column.fieldName + 'Account'] === row[column.fieldName] ? 'margin:top: 40% !important;' : '',
                cellClass: "slds-has-button slds-has-flexi-truncate"
            }));

            return { ...row, values, id: row.Id};
        } );

        this.isDataProcessed = true;
    }

    handleInputChange(event) {
        const { id, field } = event.target.dataset;
        const newValue = event.target.value;

        const rowIndex = this.data.findIndex(row => row.Id == id);
        if (rowIndex !== -1) {
            this.data[rowIndex] = { ...this.data[rowIndex], [field]: newValue, hasChanged: true };
        }
    }

    toggleEditMode(isEditing) {
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
     * Valida si una cadena es un ID de Salesforce válido.
     */
    isValidSalesforceId(id) {
        return id && /^[a-zA-Z0-9]{15}(|([a-zA-Z0-9]{3}))$/.test(id);
    }

    /**
     * Maneja el evento de guardado. Valida los datos y prepara el objeto para enviarlo a la base de datos.
     * El uso de `async/await` mejora la legibilidad.
     */
    async handleSave() {
        this.isDataProcessed = false;

        const changedRows = this.data.filter(row => row.hasChanged);
        const fieldsToUpdate = this.buildUpdateObject(changedRows);

        try {
            await updateRecord({ fields: fieldsToUpdate });

            this.data = this.data.map(row => ({ ...row, hasChanged: false }));
            this.originalData = JSON.parse(JSON.stringify(this.data));

            pubsub.fire(EVENT_BUTTON, "BusinessSave", {});
            this.isDataProcessed = true;
        } catch (error) {

            console.error('DmtBusinessPlanTableClient Error detallado al obtener datos Businees Plan:', JSON.stringify(error));
            pubsub.fire(EVENT_SET, "Error", { errorMessage: ERROR_INVALID_UPDATE });
        }

        this.loadBusinessPlanData();

    }

    buildUpdateObject(changedRows) {
        const fieldsToUpdate = { Id: this.isClient == true ? this.recordId : this.opportunityClientId };

        changedRows.forEach(row => {

            const originalRow = this.originalData.find(orig => orig.Id === row.Id);
            const rowDefinition = this.rowDefinitions.filter(row => row.label == originalRow.category);

            var fieldMap = this.getFieldMapping(rowDefinition[0].value);

            Object.entries(fieldMap).forEach(([fieldName, apiFieldName]) => {

                const newValue = row[fieldName];
                const originalValue = originalRow[fieldName];

                if (newValue != originalValue) {
                    fieldsToUpdate[apiFieldName] = (newValue == NA_VALUE || newValue == '' || newValue == null) ? null : Number(newValue);
                    return;
                }
            });
        });
        return fieldsToUpdate;
    }

    /**
     * @description Dispara un evento para notificar a otros componentes que se ha iniciado la edición.
     */
    handleEdit(event) {
        pubsub.fire("Button", "Edit", {});
    }
}