import { LightningElement, wire, api, track } from 'lwc';
import getFinancials from '@salesforce/apex/DMT_BasicFinancialsController.getFinancials';
import getAccountFields from '@salesforce/apex/DMT_BasicFinancialsController.getAccountFields';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from "lightning/uiRecordApi";

export default class Dmt_financials_table extends LightningElement {

    @api recordId;
    dmtOpportunityClientId;
    draftValues;
    originalData;
    
    columns = [
        { label: '', fieldName: 'category', type: 'text', isEditable:false },
        { label: `${new Date().getFullYear() - 1}`, fieldName: 'lastYear', type: 'number', isEditable: true },
        { label: `${new Date().getFullYear()}` + ' (optional)', fieldName: 'currentYear', type: 'number', isEditable: true },
        { label: `${new Date().getFullYear() + 1}` + ' (optional)', fieldName: 'nextYear', type: 'number', isEditable: true },
        { label: `${new Date().getFullYear() + 2}` + ' (optional)', fieldName: 'nextYear1', type: 'number', isEditable: true },
        { label: `${new Date().getFullYear() + 3}` + ' (optional)', fieldName: 'nextYear2', type: 'number', isEditable: true }
    ];

    columnsHorizontal = [
        {label:'Revenues', value: 'Revenues'},
        {label:'EBITDA', value: 'EBITDA'},
        {label:'EBIT', value: 'EBIT'},
        {label:'Net Income', value: 'Net_Income'},
        {label:'Free Cash Flow', value: 'Free_Cash_Flow'},
        {label:'Debt / EBITDA', value: 'Debt_EBITDA'},
        {label:'Net Debt / EBITDA', value: 'Net_Debt_EBITDA'}
    ];

    @track data;

    hasUnsavedChanges = false;
    isDataProcessed = false;
    processedData;
    editingCell;

    connectedCallback() {
        getFinancials({ recordId: this.recordId })
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
                        } else {
                            row.isEditable = true;
                        }
                        row.Id = i;
                        row.rowClass = 'slds-hint-parent';
                        resultOpportunity.forEach(element => {

                            let columnKey = column.value;
                            row.lastYear = element[`${columnKey}_Last_Year_number__c`] || 'N/A';
                            row.currentYear = element[`${columnKey}_Current_Year_number__c`] || 'N/A';
                            row.nextYear = element[`${columnKey}_Next_Year_number__c`] || 'N/A';
                            row.nextYear1 = element[`${columnKey}_Next_Year_1_number__c`] || 'N/A';
                            row.nextYear2 = element[`${columnKey}_Next_Year_2_number__c`] || 'N/A';
                            row.lastYearAccount = resultAccount[0].Account[`${columnKey}_Last_Year_number__c`] || 'N/A';
                            row.currentYearAccount = resultAccount[0].Account[`${columnKey}_Current_Year_number__c`] || 'N/A';
                            row.nextYearAccount = resultAccount[0].Account[`${columnKey}_Next_Year_number__c`] || 'N/A';
                            row.nextYear1Account = resultAccount[0].Account[`${columnKey}_Next_Year_1_number__c`] || 'N/A';
                            row.nextYear2Account = resultAccount[0].Account[`${columnKey}_Next_Year_2_number__c`] || 'N/A';
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
                isEquals: row[column.fieldName + 'Account'] == row[column.fieldName],
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
                    if (cell.field === fieldName) {
                        cell.isEditing = true;
                        this.editingCell = { rowId, fieldName };
                    }
                    return cell;
                });
            }
            return row;
        });
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
                })
            );
            return;
        }

        let fieldsToUpdate = { Id: this.dmtOpportunityClientId };

        modifiedCells.forEach((element) => {
            let sanitizedColumn = this.columnsHorizontal[element.rowId].value.replaceAll(" ", '_').replaceAll("/", '').replaceAll("__", '_');

            if (element.fieldName === 'lastYear') {
                fieldsToUpdate[sanitizedColumn + '_Last_Year_number__c'] = Number(element.newValue);
            }
            if (element.fieldName === 'currentYear') {
                fieldsToUpdate[sanitizedColumn + '_Current_Year_number__c'] = Number(element.newValue);
            }
            if (element.fieldName === 'nextYear') {
                fieldsToUpdate[sanitizedColumn + '_Next_Year_number__c'] = Number(element.newValue);
            }
            if (element.fieldName === 'nextYear1') {
                fieldsToUpdate[sanitizedColumn + '_Next_Year_1_number__c'] = Number(element.newValue);
            }
            if (element.fieldName === 'nextYear2') {
                fieldsToUpdate[sanitizedColumn + '_Next_Year_2_number__c'] = Number(element.newValue);
            }
        });

        const recordInput = { fields: fieldsToUpdate };

        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "Fields updated",
                        variant: "success",
                    })
                );

                this.data = this.data.map(row => {
                    row.hasChanged = false;
                    return row;
                });

                this.originalData = JSON.parse(JSON.stringify(this.data));
                this.hasUnsavedChanges = false;
                this.processData();
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error updating record",
                        message: error.body.message,
                        variant: "error",
                    })
                );
            });
    }

    handleCancel() {
        this.data = JSON.parse(JSON.stringify(this.originalData));
        this.hasUnsavedChanges = false;
        this.processData();
    }
}