import { LightningElement, api, track, wire } from 'lwc';
import { loadStyle } from "lightning/platformResourceLoader";
import { updateRecord } from "lightning/uiRecordApi";
import LightningConfirm from 'lightning/confirm';

import getBussinessPlan from '@salesforce/apex/DMT_BussinessPlanController_Client.getBussinessPlan';
import getBusinessPlanOpportunity from '@salesforce/apex/DMT_BussinessPlanController.getBussinessPlan';
import DMT_Styles from "@salesforce/resourceUrl/DMT_Styles";
import pubsub from 'omnistudio/pubsub';
import { publish, subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import XSELL_SYNC_CHANNEL from '@salesforce/messageChannel/DmtXSellSync__c';

import DMT_modify_financials_table from '@salesforce/label/c.DMT_modify_financials_table';
import DTM_overwrite_confirmation from '@salesforce/label/c.DTM_overwrite_confirmation';

const EVENT_SAVE = 'Save';
const EVENT_BUTTON = 'Button';
const EVENT_SET = 'Set';
const NA_VALUE = 'N/A';
const ERROR_INVALID_NUMBER = 'DmtBusinessPlanTableClient Please enter valid numbers in the numeric fields of the table.';
const ERROR_INVALID_STYLE = 'Error loading static resource styles.';
const ERROR_INVALID_UPDATE = 'Error in data saving.';
const ERROR_INVALID_LOADING = 'Error loading data.';

export default class DmtBusinessPlanTableClient extends LightningElement {

    @wire(MessageContext)
    messageContext;

    subscription = null;

    _recordId;
    _groupId;
    _isOpportunity = false;
    _isClient = false;
    _isEditMode = false;
    _isReadOnly = false;
    _stageName;
    _stylesLoaded = false;
    _isOppView = false;
    _opportunityClientId;

    label = {
        DMT_modify_financials_table,
        DTM_overwrite_confirmation
    }

    @api 
    set isOppView(value){
        this._isOppView = (value == 'true' || value === true);
    }
    get isOppView(){
        return this._isOppView;
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

    @api
    get isReadOnlyUser() {
        return this._isReadOnly;
    }
    set isReadOnlyUser(value) {
        this._isReadOnly = (value == true || value == 'true');
    }

    get isEditPencilEnabled() {
        return this._isReadOnly === false
            && (this._stageName === 'Draft' || this._stageName === 'Proposal');
    }

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

    // Track original base and child sums separately for fidelity 
    baseXSellTotals = { PY: 0, CY: 0, NY: 0, NY1: 0 };
    childXSellTotals = { PY: 0, CY: 0, NY: 0, NY1: 0 };
    _hasReceivedChildTotals = false; // Prevents UI flashing to 0 before LMS connects

    columns = [
        { label: '', fieldName: 'category', type: 'text', isEditable: false },
        { label: 'FY' + `${new Date().getFullYear() - 1}`, fieldName: 'pastYear2', type: 'text', isEditable: true },
        { label: 'FY' + `${new Date().getFullYear()}`, fieldName: 'pastYear', type: 'text', isEditable: true },
        { label: 'FY' + `${new Date().getFullYear() + 1}` + 'E', fieldName: 'currentYear', type: 'text', isEditable: true },
        { label: 'FY' + `${new Date().getFullYear() + 2}` + 'E', fieldName: 'nextYear', type: 'text', isEditable: true }
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
        {label: 'Total X-Sell', value: 'Child_X_Sell'}, // <--- Switched mapping to new API fields
        {label: 'Total Revenues', value: 'Total_Revenues'},
        {label: '% Cross Border Revenues', value: 'gf_kpi_trans_fees'},
        {label: 'Transactional KPI', value: 'gf_xb_cust_ope_revenue'}
    ];

    connectedCallback() {
        console.log('[BP] connectedCallback');
        this.eventHandlers = {
            DMT_CLIENT_GROUP_V2: this.handleSave.bind(this),
        };
        pubsub.register(EVENT_SAVE, this.eventHandlers);

        // Native LMS Subscription
        if (!this.subscription) {
            console.log('[BP] Subscribing to LMS');
            this.subscription = subscribe(
                this.messageContext,
                XSELL_SYNC_CHANNEL,
                (message) => {
                    console.log('[BP] LMS RECEIVED', JSON.stringify(message));
                    this.handleXSellTotals(message);
                }
            );
        }

        publish(this.messageContext, XSELL_SYNC_CHANNEL, {
            action: 'REQUEST_TOTALS'
        });

        this.loadComponentStyles();
    }

    disconnectedCallback() {
        pubsub.unregister(EVENT_SAVE, this.eventHandlers);
        
        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
        }
    }

    /**
     * Catches real-time sum updates from the native LMS channel.
     * Replaces the child totals (handling live edits/deletes) and recalculates.
     */
    handleXSellTotals(message) {
        console.log( '[BP] handleXSellTotals',JSON.stringify(message), 'data exists?', !!this.data, 'processedData exists?', !!this.processedData);


        if (message.action === 'REQUEST_TOTALS') {
            return;
        }

        this._hasReceivedChildTotals = true;

        this.childXSellTotals = {
            PY: Number(message.PY) || 0,
            CY: Number(message.CY) || 0,
            NY: Number(message.NY) || 0,
            NY1: Number(message.NY1) || 0
        };

        console.log('[BP] Stored child totals',JSON.stringify(this.childXSellTotals));

        if (this.data) {
            this.recalculateTotalXSell();
        }
    }

    /**
     * The Master Math Engine: Displayed Total = Current Child Table Sum.
     * ONLY updates the UI DOM (processedData). Prevents DML crashes by leaving hasChanged = false.
     */
    recalculateTotalXSell() {
         console.log('[BP] recalculateTotalXSell', 'data?', !!this.data, 'processed?', !!this.processedData, 'child?', JSON.stringify(this.childXSellTotals));

        if (!this.data) {
            console.log('[BP] EXITING - data not loaded yet');
            return;
        }
        
        // STAGE 1 REFACTOR: Replace totals instead of summing. 
        // Falls back to DB base totals on initial load before the LMS channel connects.
        const totalPY = this._hasReceivedChildTotals ? this.childXSellTotals.PY : this.baseXSellTotals.PY;
        const totalCY = this._hasReceivedChildTotals ? this.childXSellTotals.CY : this.baseXSellTotals.CY;
        const totalNY = this._hasReceivedChildTotals ? this.childXSellTotals.NY : this.baseXSellTotals.NY;
        const totalNY1 = this._hasReceivedChildTotals ? this.childXSellTotals.NY1 : this.baseXSellTotals.NY1;

        // Update underlying data for internal consistency, but DO NOT set hasChanged = true.
        const targetRow = this.data.find(row => row.category === 'Total X-Sell');
        if (targetRow) {
            targetRow.pastYear2 = totalPY;
            targetRow.pastYear = totalCY;
            targetRow.currentYear = totalNY;
            targetRow.nextYear = totalNY1;
        }

        // Ensure processedData exists before mapping
        if (!this.processedData || this.processedData.length === 0) {
            this.processDataForView();
            return; // processDataForView will map from this.data, which we just updated above
        }

        // CRITICAL FIX: Mutate the target row IN PLACE rather than remapping the entire array.
        // This prevents LWC from forcefully re-rendering the whole table and wiping out active user typing.
        const targetProcessedRow = this.processedData.find(row => row.category === 'Total X-Sell');
        if (targetProcessedRow && targetProcessedRow.values) {
            targetProcessedRow.values.forEach(cell => {
                if (cell.field === 'pastYear2') cell.value = totalPY;
                if (cell.field === 'pastYear') cell.value = totalCY;
                if (cell.field === 'currentYear') cell.value = totalNY;
                if (cell.field === 'nextYear') cell.value = totalNY1;
                cell.isEditable = false; 
            });
        }
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
                this.fetchBusinessFromApex();
            }

            // En Opportunity ya no se exige groupId para cargar. Si no viene, igualmente se muestra la tabla con los datos de Opportunity.
            if (this.isOpportunity && this.isValidSalesforceId(this.recordId)) {
                this.fetchBusinessFromApexOpportunity();
            }
        } catch (error) {
            pubsub.fire(EVENT_SET, "Error", { errorMessage: ERROR_INVALID_LOADING });
            console.log('DmtBusinessPlanTableClient loadBusinessPlanData error' + error);
            this.showToast('Error al cargar datos', error.body.message, 'error');
        }
    }

    async fetchBusinessFromApex() {
        try {
            const result = await getBussinessPlan({ recordId: this.recordId });

            if (!result || result.length === 0) {
                this.data = [];
                // Se evita spinner infinito en modo Client.
                this.processDataForView();
                return;
            }

            this.transformApexData(result);

            if (this.isEditMode) {
                this.toggleEditMode(true);
            }
        } catch (error) {
            // Se evita spinner infinito si falla la carga.
            this.data = [];
            this.processDataForView();
            pubsub.fire("Set", "Error", { errorMessage: ERROR_INVALID_LOADING });
            console.error('Error detallado al obtener datos Business Plan:', JSON.stringify(error));
        }
    }

    async fetchBusinessFromApexOpportunity() {
        try {
            // Se carga siempre Opportunity.
            const opportunityData = await getBusinessPlanOpportunity({ recordId: this.recordId });

            // La comparación contra cliente/grupo es opcional.
            let accountData = [];
            if (this.isValidSalesforceId(this.groupId)) {
                try {
                    accountData = await getBussinessPlan({ recordId: this.groupId });
                } catch (accountError) {
                    console.error('Error cargando datos de comparación (group/client):', accountError);
                    accountData = [];
                }
            }

            if (!opportunityData || opportunityData.length === 0) {
                this.data = [];
                this.processDataForView();
                return;
            }

            // Si no hay accountData, se usa el objeto vacío para que visualmente quede N/A.
            this.accountData = accountData && accountData.length > 0 ? accountData[0] : {};

            this.transformApexData(opportunityData);

            if (this.isEditMode) {
                this.toggleEditMode(true);
            }

        } catch (error) {
            // Se evita spinner infinito si falla la carga.
            this.data = [];
            this.processDataForView();
            pubsub.fire("Set", "Error", { errorMessage: ERROR_INVALID_LOADING});
            console.error('Error detallado al obtener datos Business Plan:', JSON.stringify(error));
        }
    }

    transformApexData(apexData) {
        const resultData = apexData[0];
        if (!resultData) {
            this.data = [];
            this.processDataForView();
            return;
        }

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
                // this.accountData puede venir vacío si no hay comparación.
                row.pastYear2Account = this.accountData?.[fieldMap.pastYear2] ?? NA_VALUE;
                row.pastYearAccount = this.accountData?.[fieldMap.pastYear] ?? NA_VALUE;
                row.currentYearAccount = this.accountData?.[fieldMap.currentYear] ?? NA_VALUE;
                row.nextYearAccount = this.accountData?.[fieldMap.nextYear] ?? NA_VALUE;
            }

            return row;
        });

        this.originalData = JSON.parse(JSON.stringify(this.data));
        
        // Capture the native base totals before any child math is applied
        const totalRow = this.data.find(r => r.category === 'Total X-Sell');
        if (totalRow) {
            this.baseXSellTotals = {
                PY: Number(totalRow.pastYear2) || 0,
                CY: Number(totalRow.pastYear) || 0,
                NY: Number(totalRow.currentYear) || 0,
                NY1: Number(totalRow.nextYear) || 0
            };
        }

        // Trigger recalculate instead of just processDataForView. 
        // This ensures if the X-Sell broadcast arrived early, its totals are instantly applied to the UI.
        this.recalculateTotalXSell();
    }
    async handleRedoAllTable() {
        try {
            const result = await LightningConfirm.open({
            message: this.label.DTM_overwrite_confirmation,
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
                        cell.styleRedo = '';
                        this.hasUnsavedChanges = true;
                        row[fieldName] = cell.value;
                        row.hasChanged = true;
                        this.data[row.Id] = row;

                    }
                    return cell;
                });
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
            const values = this.columns.map(column => {
                const accountValueRaw = row[column.fieldName + 'Account'];

                // Solo hay comparación real si existe valor origen
                const hasComparisonValue = accountValueRaw !== undefined && accountValueRaw !== null && accountValueRaw !== '' && accountValueRaw !== NA_VALUE;
                // Visualmente se muestra N/A cuando no hay dato origen
                const accountValue = hasComparisonValue ? accountValueRaw : NA_VALUE;
                const value = row[column.fieldName];

                return {
                    field: column.fieldName,
                    label: column.label,
                    // Valor actual en Opportunity
                    value: value,
                    // Valor origen del Client/Account
                    accountValue: accountValue,
                    // Solo comparar si existe dato real de origen
                    isEquals: hasComparisonValue ? accountValue === value : true,
                    // Esta propiedad sirve para saber si hay comparación real
                    hasComparisonValue: hasComparisonValue,
                    isEditing: false,
                    isEditable: column.isEditable && row.isEditable,
                    // El botón redo aparece solo si hay comparación real y además es distinto
                    styleRedo: hasComparisonValue && accountValue !== value ? '' : 'display:none;',
                    // Ajuste visual cuando no hay redo
                    withoutRedo: hasComparisonValue && accountValue === value ? 'margin-top: 40% !important;' : '',
                    cellClass: "slds-has-button slds-has-flexi-truncate"
                };
            });

            return { ...row, values, id: row.Id};
        } );

        this.isDataProcessed = true;
    }

    handleInputChange(event) {
        const { id, field } = event.target.dataset;
        const newValue = event.target.value;

        // 1. Update the background save data
        const rowIndex = this.data.findIndex(row => row.Id == id);
        if (rowIndex !== -1) {
            this.data[rowIndex] = { ...this.data[rowIndex], [field]: newValue, hasChanged: true };
        }
        
        // 2. CRITICAL FIX: Update the foreground UI data so it survives LMS re-renders
        const pRowIndex = this.processedData.findIndex(row => row.Id == id);
        if (pRowIndex !== -1) {
            const cell = this.processedData[pRowIndex].values.find(c => c.field === field);
            if (cell) {
                cell.value = newValue;
            }
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
        if (!this.isEditPencilEnabled) {
            return;
        }
        pubsub.fire("Button", "Edit", {});
    }
}