import { api, track, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import getDataIssuerRisk from '@salesforce/apex/HPG_SecondaryTablesController.getIssuerRisk';

export default class Hpg_issuer_risk extends LightningModal {

  disableSave = true;
  sortOrder = [];
  title = 'Issuer Risk';

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

  @wire(getDataIssuerRisk, {
    clientId: '$clientId',
    clientType: '$clientType',
    countries: '$countries',
    searchDate : '$searchDate',
    page : '$page',
    pageSize : '$pageSize'
  }) issuerrisk( { error, data } ) {
    this.columns = [
      {label: 'Issue Id', fieldName: 'issueId', type: 'text' ,cellAttributes: {alignment: 'left'}},
      {label: 'Instrument Type', fieldName: 'instrumentTypeCodeId', type: 'text' ,cellAttributes: {alignment: 'left'}},
      {label: 'Currency Position', fieldName: 'currencyPositionId', type: 'text' ,cellAttributes: {alignment: 'left'}},
      {label: 'Asset Type', fieldName: 'assetTypeId', type: 'text' ,cellAttributes: {alignment: 'left'}},
      {label: 'IBOND Sector', fieldName: 'ibondSectorDesc', type: 'text' ,cellAttributes: {alignment: 'left'}},
      {label: 'Seniority', fieldName: 'seniorityTextDesc', type: 'text' ,cellAttributes: {alignment: 'left'}},
      {label: 'Maturity Date', fieldName: 'securMaturityDate', type: 'text' ,cellAttributes: {alignment: 'left'}},
      {label: 'Currency', fieldName: 'currencyId', type: 'text' ,cellAttributes: {alignment: 'left'}},
      {label: 'Country', fieldName: 'portfolioCountryId', type: 'text' ,cellAttributes: {alignment: 'left'}},
      {label: 'Business Area', fieldName: 'businessAreaName', type: 'text' ,cellAttributes: {alignment: 'left'}},
      {label: 'Portfolio Type', fieldName: 'pfolioFrmWkInvstPlcyDesc', type: 'text' ,cellAttributes: {alignment: 'left'}},
      {label: 'Portfolio Description', fieldName: 'pfolioFwkInvstPlcyDesc', type: 'text' ,cellAttributes: {alignment: 'left'}},
      {label: 'Local Accounting Id', fieldName: 'glLocalAccountingEx1Id', type: 'text' ,cellAttributes: {alignment: 'left'}},
      {label: 'Nominal', fieldName: 'totalNominalEurAmount', type: 'customCurrency', typeAttributes: { currencyCode: this.currency, currencyDisplayAs: 'code'}, cellAttributes: {alignment: 'right'}},
      {label: '', fieldName: '', type: 'text', fixedWidth: 16, hideDefaultActions: true}
    ];
      if (data) {
        this.title = this.clientName + ' - Issuer Risk';
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
          issueId: data.issueId,
          instrumentTypeCodeId: data.instrumentTypeCodeId,
          currencyPositionId:  data.currencyPositionId,
          assetTypeId: data.assetTypeId,
          ibondSectorDesc : data.ibondSectorDesc,
          seniorityTextDesc : data.seniorityTextDesc,
          securMaturityDate : data.securMaturityDate,
          currencyId : data.currencyId,
          portfolioCountryId : data.portfolioCountryId,
          businessAreaName: data.businessAreaName,
          pfolioFrmWkInvstPlcyDesc : data.pfolioFrmWkInvstPlcyDesc,
          pfolioFwkInvstPlcyDesc : data.pfolioFwkInvstPlcyDesc,
          glLocalAccountingEx1Id : data.glLocalAccountingEx1Id,
          totalNominalEurAmount : parseFloat(data.totalNominalEurAmount) * this.exchangeRate
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

  downloadCSV() {
    var fileName = this.clientId + '_issuer_risk_' + this.searchDate + '.csv';
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