import { LightningElement, api, track, wire } from 'lwc';
import { labels } from './hpg_contract_guarantees_labels.js';
import getContractGuarantees from '@salesforce/apex/HPG_SecondaryTablesController.getContractGuarantees';

export default class Hpg_contract_guarantees extends LightningElement {

    @api contractId;
    @api currentDate;
    @api clientName;
    @api exchangeRate;
    @api currency;

    @track isLoading = true;
    @track csv = [];
    labels = labels;
    data;
    userIsAdmin = false;
    title;
    key = 0;
    foundGuarantees = true;

    columns = [
        {label: 'Initial Date', fieldName: 'beginningGuaranteeDate', initialWidth: '200px', type: 'date', align: 'left'},
        {label: 'End Date', fieldName: 'endGuaranteeDate', initialWidth: '200px', type: 'date', align: 'left'},
        {label: 'Type', fieldName: 'recordTypeName', initialWidth: '200px', type: 'text',align: 'left'},
        {label: 'Amount', fieldName: 'currentAmount', initialWidth: '200px', type: 'currency', currencyCode: 'currencyId', align: 'left'},
        {label: 'Guarantor ID', fieldName: 'guarantorCustomerId', initialWidth: '200px', type: 'text', align: 'left'},
        {label: 'Guarantor Name', fieldName: 'guarantorCustomerNameDesc', initialWidth: '200px', type: 'text', align: 'left'},
        {label: 'Guarantor Mitigation %', fieldName: 'guarantorMitigationPer', initialWidth: '200px', type: 'percent', align: 'left'},
        {label: 'Insurance Coverage %', fieldName: 'insuranceCoverPer', initialWidth: '200px', type: 'percent', align: 'left'},
        {label: 'Guarantee Type', fieldName: 'guaranteeTypeDesc', initialWidth: '200px', type: 'text', align: 'left'},
        {label: 'Guarantee Asset Type', fieldName: 'tradeGuarranteeCollateralTypeDesc', initialWidth: '200px', type: 'text', align: 'left'},
        {label: 'Last Appraisal Date', fieldName: 'lastAppraisalDate', initialWidth: '200px', type: 'date', align: 'left'},
        {label: 'Securities Maturity Date', fieldName: 'expirationSecuritiesDate', initialWidth: '200px', type: 'date', align: 'left'}
    ];

    @wire(getContractGuarantees, {
        contractId: '$contractId',
        searchDate: '$currentDate',
        page : '1',
        pageSize : '1000'
    }) contractGuarantees( { error, data } ) {
        console.log('data ' + JSON.stringify(data));
        if (data) {
            this.title = this.clientName + ' - ' + this.contractId +  ' - Contract Guarantees';
            if (data.data.length < 1) {
                this.foundGuarantees = false;
            }
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
                var rowData = {
                    beginningGuaranteeDate: data.beginningGuaranteeDate,
                    endGuaranteeDate: data.endGuaranteeDate,
                    recordTypeName: data.recordTypeName.toUpperCase(),
                    guaranteeType: data.guaranteeType,
                    currentAmount: (data.recordTypeName.toLowerCase() === 'guarantor') ? data.guarantorAmount : data.currentGuaranteedAmount,
                    currencyId: (data.recordTypeName.toLowerCase() === 'guarantor') ? data.guarantorCurrencyId : data.guaranteeCurrencyId,
                    guarantorCustomerId: data.guarantorCustomerId,
                    guarantorCustomerNameDesc: data.guarantorCustomerNameDesc,
                    guarantorMitigationPer: data.guarantorMitigationPer,
                    insuranceCoverPer: data.insuranceCoverPer,
                    guaranteeTypeDesc: data.guaranteeTypeDesc,
                    tradeGuarranteeCollateralTypeDesc: data.tradeGuarranteeCollateralTypeDesc,
                    lastAppraisalDate: data.lastAppraisalDate,
                    expirationSecuritiesDate: data.expirationSecuritiesDate,
                    contractId: data.contractId,
                    cutoffDate: data.cutoffDate,
                    guaranteeCurrentYearId: data.guaranteeCurrentYearId,
                    guaranteeId: data.guaranteeId,
                    internalContractCodeDesc: data.internalContractCodeDesc,
                    localContractNumberId: data.localContractNumberId,
                    tradeCollateralType: data.tradeCollateralType,
                    assetId: data.assetId
                };
                tableData.push(rowData);
            });
            this.data = tableData;
            this.isLoading = false;
        } else {
            this.error = data.message;
            console.error(data.message);
            this.isLoading = false;
        }
    }

    get userIsAdmin() {
        return this.userAdmin;
    }

    @api
    get iteratorKey() {
        this.key += 1;
        return 'key' + this.key;
    }

    downloadCSV() {
        var fileName = this.contractId + '_contract_guarantees_' + this.currentDate + '.csv';
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