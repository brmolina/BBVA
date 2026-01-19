import { api, track, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import getDataDetailCapitalProvision from '@salesforce/apex/HPG_SecondaryTablesController.getDetailCapitalProvision';

// Labels
import grid_field_10200 from '@salesforce/label/c.grid_field_10200';
import grid_field_10100 from '@salesforce/label/c.grid_field_10100';
import grid_field_20200 from '@salesforce/label/c.grid_field_20200';
import grid_field_20100 from '@salesforce/label/c.grid_field_20100';
import grid_field_30000 from '@salesforce/label/c.grid_field_30000';
import grid_field_40000 from '@salesforce/label/c.grid_field_40000';
import grid_field_130000 from '@salesforce/label/c.grid_field_130000';
import grid_field_140000 from '@salesforce/label/c.grid_field_140000';
import grid_field_60000 from '@salesforce/label/c.grid_field_60000';
import grid_field_80100 from '@salesforce/label/c.grid_field_80100';
import grid_field_80200 from '@salesforce/label/c.grid_field_80200';
import grid_field_50000 from '@salesforce/label/c.grid_field_50000';
import grid_field_10000 from '@salesforce/label/c.grid_field_10000';
import grid_field_20000 from '@salesforce/label/c.grid_field_20000';
import grid_field_888888 from '@salesforce/label/c.grid_field_888888';
import grid_field_999999 from '@salesforce/label/c.grid_field_999999';

const labels = {
    '10200': grid_field_10200,
    '10100': grid_field_10100,
    '20200': grid_field_20200,
    '20100': grid_field_20100,
    '30000': grid_field_30000,
    '40000': grid_field_40000,
    '130000': grid_field_130000,
    '140000': grid_field_140000,
    '60000': grid_field_60000,
    '80100': grid_field_80100,
    '80200': grid_field_80200,
    '50000': grid_field_50000,
    '10000': grid_field_10000,
    '20000': grid_field_20000,
    '888888': grid_field_888888,
    '999999': grid_field_999999,
    '200000': grid_field_888888,
    'XXXXXX': grid_field_999999
}

export default class Hpg_capitalprovision_detail extends LightningModal {

    labels = labels;
    draftValues = [];
    disableSave = true;
    sortOrder = [];
    title = 'Capital & Provisions Detail';

    @api clientId;
    @api clientType;
    @api clientName;
    @api searchDate;
    @api countries;
    @api params;
    @api currency;
    @api exchangeRate;

    @track showModal = true;
    @track isLoading = true;
    @track data = [];
    @track csv = [];
    @track page = 1;
    @track pageSize = 300;
    @track columns = [];

    @wire(getDataDetailCapitalProvision, {
        clientId: '$clientId',
        clientType: '$clientType',
        countries: '$countries',
        searchDate : '$searchDate',
        page : '$page',
        pageSize : '$pageSize'
    })
    consumptiondetails({ error, data }) {
        this.columns = [
            {label: 'Initial Date', fieldName: 'contractRegisterDate', initialWidth: 110, type: 'date', cellAttributes: {alignment: 'left'}},
            {label: 'Maturity Date', fieldName: 'currentExpirationDate', initialWidth: 130, type: 'date', cellAttributes: {alignment: 'left'}},
            {label: 'Currency', fieldName: 'currencyId', initialWidth: 98, type: 'text', cellAttributes: {alignment: 'left'}},
            {label: 'Branch', fieldName: 'branchId', initialWidth: 85, type: 'text', cellAttributes: {alignment: 'right'}},
            {label: 'Refinanced Ind', fieldName: 'activityRefinancedType', initialWidth: 135, type: 'text', cellAttributes: {alignment: 'right'}},
            {label: 'Authorization Id', fieldName: 'opportunityId', initialWidth: 225, type: 'text', cellAttributes: {alignment: 'left'}},
            {label: 'Contract Id', fieldName: 'internalContractCodeDesc', initialWidth: 225, type: 'text', cellAttributes: {alignment: 'left'}},
            {label: 'Entity', fieldName: 'entityId', initialWidth: 85, type: 'text', cellAttributes: {alignment: 'right'}},
            {label: 'Product Type', fieldName: 'productTypeDesc', initialWidth: 260, type: 'text', cellAttributes: {alignment: 'left'}},
            {label: 'Maturity', fieldName: 'maturityTermNumber', initialWidth: 95, type: 'number', cellAttributes: {minimumFractionDigits : '1',alignment: 'right'}},
            {label: 'Consumption Last Level', fieldName: 'consumptionLastLevelId', initialWidth: 240, type: 'text', cellAttributes: {alignment: 'left'}},
            {label: 'Current Guaranteed Amount', fieldName: 'currentGuaranteedAmount', initialWidth: 220, type: 'customCurrency', typeAttributes: {currencyCode: this.currency}, cellAttributes: {alignment: 'right'}},
            {label: 'IFRS9 Final Stage', fieldName: 'finalStageType', initialWidth: 150, type: 'text', cellAttributes: {alignment: 'left'}},
            {label: 'IFRS9 Ind Customer Ind', fieldName: 'individualizedCustType', initialWidth: 190, type: 'text', cellAttributes: {alignment: 'left'}},
            {label: 'IFRS9 Indi Contract Ind', fieldName: 'individualizedContType', initialWidth: 190, type: 'text', cellAttributes: {alignment: 'left'}},
            {label: 'IFRS9 EAD', fieldName: 'eadAmount', initialWidth: 145, type: 'customCurrency', typeAttributes: {currencyCode: this.currency}, cellAttributes: {alignment: 'right'}},
            {label: 'IFRS9 Provision', fieldName: 'finalProvisionAmount', initialWidth: 145, type: 'customCurrency', typeAttributes: {currencyCode: this.currency}, cellAttributes: {alignment: 'right'}},
            {label: 'Reg C Method', fieldName: 'capitalCalculationMtType', initialWidth: 130, type: 'text', cellAttributes: {alignment: 'left'}},
            {label: 'Reg C EAD', fieldName: 'regyCapitalEadAmount', initialWidth: 140, type: 'customCurrency', typeAttributes: {currencyCode: this.currency}, cellAttributes: {alignment: 'right'}},
            {label: 'Reg C Capital', fieldName: 'capitalRegyAmount', initialWidth: 140, type: 'customCurrency', typeAttributes: {currencyCode: this.currency}, cellAttributes: {alignment: 'right'}},
            {label: 'Reg C RWA', fieldName: 'regyCapitalAprAmount', initialWidth: 140, type: 'customCurrency', typeAttributes: {currencyCode: this.currency}, cellAttributes: {alignment: 'right'}},
            {label: 'Reg C RWA (%)', fieldName: 'regyCapitalRWA', initialWidth: 135, type: 'number', cellAttributes: {alignment: 'right'}},
            {label: 'Eco C EAD', fieldName: 'economicCapitalEad1Amount', initialWidth: 140, type: 'customCurrency', typeAttributes: {currencyCode: this.currency}, cellAttributes: {alignment: 'right'}},
            {label: 'Eco C Capital', fieldName: 'economicCapitalAmount', initialWidth: 140, type: 'customCurrency', typeAttributes: {currencyCode: this.currency}, cellAttributes: {alignment: 'right'}},
            {label: 'Details', fieldName: 'catalogFieldValueEsDes', initialWidth: 260, type: 'text', cellAttributes: {alignment: 'left'}},
            {label: ' ', fieldName: '', type: 'text', fixedWidth: 16, hideDefaultActions: true}
        ];
        if (data) {
            this.title = this.clientName + ' -  Capital & Provisions Detail';
            this.updateDataTable(data);
        } else if (error) {
            this.error = error;
            console.error(error);
            this.isLoading = false;
        }
    };
    updateDataTable(data) {
        if (data.success) {
            var tableData = [];
            data.data.forEach( data =>  {
                data.detailConsumptions.forEach(detailConsumption => {
                    var rowData = {
                        groupName: data.groupName,
                        subGroupName: data.subGroupName,
                        customerName: data.customerName,
                        contractRegisterDate: detailConsumption.contractRegisterDate,
                        currentExpirationDate: detailConsumption.currentExpirationDate,
                        currencyId: detailConsumption.currencyId,
                        branchId: detailConsumption.branchId,
                        activityRefinancedType: detailConsumption.activityRefinancedType,
                        internalContractCodeDesc: detailConsumption.internalContractCodeDesc,
                        entityId: detailConsumption.entityId,
                        productTypeDesc: detailConsumption.productTypeDesc,
                        maturityTermNumber : detailConsumption.maturityTermNumber,
                        consumptionLastLevelId: this.labels[detailConsumption.consumptionLastLevelId] ? this.labels[detailConsumption.consumptionLastLevelId] : detailConsumption.consumptionLastLevelId,
                        currentGuaranteedAmount: parseFloat(detailConsumption.currentGuaranteedAmount) * this.exchangeRate,
                        finalStageType: detailConsumption.finalStageType,
                        individualizedCustType: detailConsumption.individualizedCustType,
                        individualizedContType: detailConsumption.individualizedContType,
                        eadAmount: parseFloat(detailConsumption.eadAmount) * this.exchangeRate,
                        finalProvisionAmount: parseFloat(detailConsumption.finalProvisionAmount) * this.exchangeRate,
                        capitalCalculationMtType: detailConsumption.capitalCalculationMtType,
                        regyCapitalEadAmount: parseFloat(detailConsumption.regyCapitalEadAmount) * this.exchangeRate,
                        capitalRegyAmount: parseFloat(detailConsumption.capitalRegyAmount) * this.exchangeRate,
                        regyCapitalAprAmount: parseFloat(detailConsumption.regyCapitalAprAmount) * this.exchangeRate,
                        regyCapitalRWA: parseFloat(detailConsumption.capitalRegyAmount) / parseFloat(detailConsumption.regyCapitalAprAmount),
                        economicCapitalEad1Amount: parseFloat(detailConsumption.economicCapitalEad1Amount) * this.exchangeRate,
                        economicCapitalAmount: parseFloat(detailConsumption.economicCapitalAmount) * this.exchangeRate,
                        catalogFieldValueEsDes: detailConsumption.catalogFieldValueEsDes,
                        opportunityId: detailConsumption.opportunityId
                    };
                    tableData.push(rowData);
                });
            });
            this.data = tableData;
            this.isLoading = false;
        } else {
            this.error = data.message;
            console.error(data.message);
            this.isLoading = false;
        }
    }

    downloadCSV() {
        var fileName = this.clientId + '_capital_provision_detail_' + this.searchDate + '.csv';
        var uri = `data:text/csv;charset=utf-8,${encodeURIComponent(this.data2CSV(this.data))}`;
        var link = document.createElement("a");
        link.setAttribute("download", fileName);
        link.href = uri;
        link.style = "visibility:hidden";
        link.click();
    }

    data2CSV() {
        let headers = '';
        this.columns.forEach(column => {
            headers += `"${column.label}",`;
        })
        headers = headers.replace(/,$/, '\n');
        this.csv += headers;
        this.data.forEach(row => {
            this.addRow2CSV(row);
        });
        return this.csv;
    }

    addRow2CSV(row) {
        let rowdata = '';
        this.columns.forEach(column => {
            rowdata += (row[column.fieldName]) ? `"${row[column.fieldName]}",` : `"",`;
        });
        rowdata = rowdata.replace(/,$/, '\n');
        this.csv += rowdata;
        if (row._children) {
            row._children.forEach(child => {
            this.addRow2CSV(child);
            });
        }
    }
}