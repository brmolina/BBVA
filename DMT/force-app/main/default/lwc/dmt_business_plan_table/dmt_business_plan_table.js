import { LightningElement, api, track } from 'lwc';
import getBussinessPlan from '@salesforce/apex/DMT_BussinessPlanController.getBussinessPlan';
import getAccountFields from '@salesforce/apex/DMT_BussinessPlanController.getAccountFields';
import DMT_Styles from "@salesforce/resourceUrl/DMT_Styles";
import { loadStyle } from "lightning/platformResourceLoader";
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Dmt_business_plan_table extends LightningElement {
    @api recordId;
    dmtOpportunityClientId;
    draftValues;
    originalData;

    columns = [
        { label: '', fieldName: 'category', type: 'text', isEditable: false},
        { label: 'FY' + `${new Date().getFullYear() - 2}`, fieldName: 'pastYear2', type: 'text', isEditable: true},
        { label: 'FY' + `${new Date().getFullYear() - 1}`, fieldName: 'pastYear', type: 'text', isEditable: true},
        { label: 'FY' + `${new Date().getFullYear()}` + 'E', fieldName: 'currentYear', type: 'text', isEditable: true},
        { label: 'FY' + `${new Date().getFullYear() + 1}` + 'E', fieldName: 'nextYear', type: 'text', isEditable: true}
    ];

    columnsHorizontal = [
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

    @track data;

    hasUnsavedChanges = false;
    isDataProcessed = false;
    processedData;
    editingCell;

    renderedCallback() {

        Promise.all([loadStyle(this, DMT_Styles)])
        .then(() => {
            console.log("Static Resource Loaded");
        })
        .catch(error => {
            console.log("error-", error);
        });
    }

    /**
     * This is called when page is opened.
     */
    connectedCallback() {
        getBussinessPlan({ recordId: this.recordId })
            .then(resultOpportunity => {
                getAccountFields({ recordId: this.recordId}).then(resultAccount => {
                    var rows = [];
                    this.dmtOpportunityClientId = resultOpportunity[0].Id;
                    let i = 0;

                    this.columnsHorizontal.forEach(column => {

                        var row = {};
                        row.category = column.label;
                        if (column.label.includes('Total')) {
                            row.isEditable = false;
                            row.class = 'slds-hint-parent dmt-table-title';
                        } else {
                            row.isEditable = true;
                            row.class = 'slds-hint-parent';
                        }
                        row.Id = i;
                        resultOpportunity.forEach(element => {
                            
                            const sanitizedColumn = column.value;
                            if (sanitizedColumn === 'gf_xb_cust_ope_revenue') {
                                row.pastYear2 = element[sanitizedColumn + '_2ya_per__c'] || 'N/A';
                                row.pastYear = element[sanitizedColumn + '_ly_per__c'] || 'N/A';
                                row.currentYear = element[sanitizedColumn + '_cyr_per__c'] || 'N/A';
                                row.nextYear = element[sanitizedColumn + '_nxy_per__c'] || 'N/A';
                                row.pastYear2Account = resultAccount[0].Account[sanitizedColumn + '_2ya_per__c'] || 'N/A';
                                row.pastYearAccount = resultAccount[0].Account[sanitizedColumn + '_ly_per__c'] || 'N/A';
                                row.currentYearAccount = resultAccount[0].Account[sanitizedColumn + '_cyr_per__c'] || 'N/A';
                                row.nextYearAccount = resultAccount[0].Account[sanitizedColumn + '_nxy_per__c'] || 'N/A';
                            } 
                            else if (sanitizedColumn === 'gf_kpi_trans_fees') {
                                row.pastYear2 = element[sanitizedColumn + '_2ya_amount__c'] || 'N/A';
                                row.pastYear = element[sanitizedColumn + '_ly_amount__c'] || 'N/A';
                                row.currentYear = element[sanitizedColumn + '_cyr_amount__c'] || 'N/A';
                                row.nextYear = element[sanitizedColumn + '_nxy_amount__c'] || 'N/A';
                                row.pastYear2Account = resultAccount[0].Account[sanitizedColumn + '_2ya_amount__c'] || 'N/A';
                                row.pastYearAccount = resultAccount[0].Account[sanitizedColumn + '_ly_amount__c'] || 'N/A';
                                row.currentYearAccount = resultAccount[0].Account[sanitizedColumn + '_cyr_amount__c'] || 'N/A';
                                row.nextYearAccount = resultAccount[0].Account[sanitizedColumn + '_nxy_amount__c'] || 'N/A';
                            }
                            else {
                                row.pastYear2 = element[Object.keys(element).find((key) => key.toLowerCase() === `${'Past2_FY_' + sanitizedColumn + '_amount__c'}`.toLowerCase())] || 'N/A';
                                row.pastYear = element[Object.keys(element).find((key) => key.toLowerCase() === `${'Past_FY_' + sanitizedColumn + '_amount__c'}`.toLowerCase())] || 'N/A';
                                row.currentYear = element[Object.keys(element).find((key) => key.toLowerCase() === `${'Current_FY_' + sanitizedColumn + '_amount__c'}`.toLowerCase())] || 'N/A';
                                row.nextYear = element[Object.keys(element).find((key) => key.toLowerCase() === `${'Next_FY_' + sanitizedColumn + '_amount__c'}`.toLowerCase())] || 'N/A';
                                row.pastYear2Account = resultAccount[0].Account[Object.keys(element).find((key) => key.toLowerCase() === `${'Past2_FY_' + sanitizedColumn + '_amount__c'}`.toLowerCase())] || 'N/A';
                                row.pastYearAccount = resultAccount[0].Account[Object.keys(element).find((key) => key.toLowerCase() === `${'Past_FY_' + sanitizedColumn + '_amount__c'}`.toLowerCase())] || 'N/A';
                                row.currentYearAccount = resultAccount[0].Account[Object.keys(element).find((key) => key.toLowerCase() === `${'Current_FY_' + sanitizedColumn + '_amount__c'}`.toLowerCase())] || 'N/A';
                                row.nextYearAccount = resultAccount[0].Account[Object.keys(element).find((key) => key.toLowerCase() === `${'Next_FY_' + sanitizedColumn + '_amount__c'}`.toLowerCase())] || 'N/A';
                            }
                            //row.pastYear2 = element.Past2_FY_GTF_amount__c;
                            
                    });
                        rows.push(row);
                        i++;
                    });
                    this.data = rows;
                    this.originalData = JSON.parse(JSON.stringify(this.data));
                    this.processData();
                }).catch(error => {
                    console.error('Error fetching account fields:', JSON.stringify(error));
                })
                }).catch(error => {
                    console.error('Error fetching financials:', error);
                });
            
            
    }

    getRowValue(row, fieldName) {
        return row[fieldName];
    }

    processData() {
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
        const rowId = event.target.dataset.id;
        const fieldName = event.target.dataset.field;
        const newValue = event.target.value;

        this.data = this.data.map(row => {
            if (row.Id == rowId) {
                row[fieldName] = newValue;
                row.hasChanged = true;
            }
            return row;
        });

        this.processedData = this.processedData.map(row => {
            if (row.Id == rowId) {
                row.values = row.values.map(cell => {
                    if (cell.field == fieldName) {
                        cell.value = newValue;
                        cell.isEquals = newValue === cell.accountValue;
                    }
                    return cell;
                });
            }
            return row;
        });
        this.hasUnsavedChanges = this.data.some(row => row.hasChanged);
    }

    handleEdit(event) {
        const rowId = event.target.dataset.id;
        const fieldName = event.target.dataset.field;

        this.processedData = this.processedData.map(row => {
            if (row.Id == rowId) {
                row.values = row.values.map(cell => {
                    if (cell.field == fieldName) {
                        cell.isEditing = true;
                        this.editingCell = {rowId, fieldName};
                    }
                    return cell;
                })
            }
            return row;
        });
    }
    async handleRedoAllTable() {
        try {
            const result = await LightningConfirm.open({
            message: 'Are you sure you want to make this change?',
            label: 'Confirmation of Change',
            theme: 'warning' // 'default' | 'success' | 'warning' | 'error'
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
/*         this.data = JSON.parse(JSON.stringify(this.processedData));
        this.handleSave(); */
    }
    handleRedo(event) {
        const rowId = event.target.dataset.id;
        const fieldName = event.target.dataset.field;

        this.processedData = this.processedData.map(row => {
            if (row.Id == rowId) {
                row.values = row.values.map(cell => {
                    if (cell.field == fieldName) {
                        cell.isEditing = true;
                        cell.value = cell.accountValue;
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
    }

    handleFocusOut(event) {
        const rowId = event.target.dataset.id;
        const fieldName = event.target.dataset.field;

        this.processedData = this.processedData.map(row => {
            if (row.Id == rowId) {
                row.values = row.values.map(cell => {
                    if (cell.field == fieldName) {
                        cell.cellClass = 'slds-has-button slds-has-flexi-truncate slds-is-edited'
                        cell.isEditing = false;
                    }
                    return cell;
                })
            }
            return row;
        });
    }

    /**
     * Handles save data event
     * @param {*} event 
     */
    handleSave() {
        let modifiedCells = [];
        let hasInvalidNumber = false;
        this.data.forEach(row => {
            if (row.hasChanged) {
                this.columns.forEach(column => {
                    const fieldName = column.fieldName;
                    const fieldType = column.type;
                    const newValue = row[fieldName];
                    const originalValue = this.originalData.find(origRow => origRow.Id === row.Id)[fieldName];
                    if (newValue !== originalValue) {
                        if (isNaN(newValue)) {
                            hasInvalidNumber = true;
                        } else {
                            modifiedCells.push({
                                rowId: row.Id,
                                fieldName: fieldName,
                                newValue: row[fieldName]
                            });
                        }
                    }
                });
            }
        });

        if (hasInvalidNumber) {
            this.dispatchEvent(
                new ShowToastEvent({
                title: "Error",
                message: 'Please enter valid numbers in the numeric fields',
                variant: "error",
            }));
            return;
        }

        let fieldsToUpdate = {};
        fieldsToUpdate['Id'] = this.dmtOpportunityClientId;

        modifiedCells.forEach((element) => {
            let sanitizedColumn = this.columnsHorizontal[element.rowId].value;
            if (element.fieldName == 'pastYear2') {
                if (sanitizedColumn === 'gf_xb_cust_ope_revenue') {
                    fieldsToUpdate[sanitizedColumn + '_2ya_per__c'] = Number(element.newValue);
                } 
                else if (sanitizedColumn === 'gf_kpi_trans_fees') {
                    fieldsToUpdate[sanitizedColumn + '_2ya_amount__c'] = Number(element.newValue);
                }
                else if (sanitizedColumn === 'ECM_M_A') {
                    fieldsToUpdate['Past2_FY_' + sanitizedColumn + '_Amount__c'] = Number(element.newValue);
                }
                else {
                    fieldsToUpdate['Past2_FY_' + sanitizedColumn + '_amount__c'] = Number(element.newValue);
                }
                //rowsUpdated[columnNumber[1]].pastYear2 = element.newValue;
            }
            if (element.fieldName === 'pastYear') {
                if (sanitizedColumn === 'gf_xb_cust_ope_revenue') {
                    fieldsToUpdate[sanitizedColumn + '_ly_per__c'] = Number(element.newValue);
                } 
                else if (sanitizedColumn === 'gf_kpi_trans_fees') {
                    fieldsToUpdate[sanitizedColumn + '_ly_amount__c'] = Number(element.newValue);
                }
                else if (sanitizedColumn === 'ECM_M_A') {
                    fieldsToUpdate['Past_FY_' + sanitizedColumn + '_Amount__c'] = Number(element.newValue);
                }
                else {
                    fieldsToUpdate['Past_FY_' + sanitizedColumn + '_amount__c'] = Number(element.newValue);
                }
                //rowsUpdated[columnNumber[1]].pastYear = element.pastYear;
            }
            if (element.fieldName === 'currentYear') {
                if (sanitizedColumn === 'gf_xb_cust_ope_revenue') {
                    fieldsToUpdate[sanitizedColumn + '_cyr_per__c'] = Number(element.newValue);
                } 
                else if (sanitizedColumn === 'gf_kpi_trans_fees') {
                    fieldsToUpdate[sanitizedColumn + '_cyr_amount__c'] = Number(element.newValue);
                }
                else if (sanitizedColumn === 'ECM_M_A') {
                    fieldsToUpdate['Current_FY_' + sanitizedColumn + '_Amount__c'] = Number(element.newValue);
                }
                else {
                    fieldsToUpdate['Current_FY_' + sanitizedColumn + '_amount__c'] = Number(element.newValue);
                }    
                //rowsUpdated[columnNumber[1]].currentYear = element.value;
            }
            if (element.fieldName == 'nextYear') {
                if (sanitizedColumn === 'gf_xb_cust_ope_revenue') {
                    fieldsToUpdate[sanitizedColumn + '_nxy_per__c'] = Number(element.newValue);
                } 
                else if (sanitizedColumn === 'gf_kpi_trans_fees') {
                    fieldsToUpdate[sanitizedColumn + '_nxy_amount__c'] = Number(element.newValue);
                }
                //Here we don't make difference with ECM_M_A cause the field has amount in lowercase
                else {
                    fieldsToUpdate['Next_FY_' + sanitizedColumn + '_amount__c'] = Number(element.newValue);
                }
                //rowsUpdated[columnNumber[1]].nextYear = element.newValue;
            }
        });

            const recordInput = { fields : fieldsToUpdate };
            updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                    title: "Success",
                    message: "Fields updated",
                    variant: "success",
                    }),
                );
                this.data = this.data.map(row => {
                    row.hasChanged = false;
                    return row;
                });

                this.originalData = JSON.parse(JSON.stringify(this.data));
                this.hasUnsavedChanges = false;
                this.processData();
            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                    title: "Error updating record",
                    message: error.body.message,
                    variant: "error",
                }));
            });
    }

    handleCancel() {
        this.data = JSON.parse(JSON.stringify(this.originalData));
        this.hasUnsavedChanges = false;
        this.processData();
    }
}