import { api, track, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import getDerivativesData from '@salesforce/apex/HPG_SecondaryTablesController.getDerivativesData';

export default class Hpg_derivativesData extends LightningModal {

  draftValues = [];
  disableSave = true;
  sortOrder = [];
  title = 'Derivatives';

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
  @track heightClass = 'vh65';
  @track showChart = false;
  @track data = [];
  @track csv = [];
  @track columns = [];

  @wire(getDerivativesData, {
    clientId: '$clientId',
    clientType: '$clientType',
    countries: '$countries',
    searchDate : '$searchDate',
    page : 1,
    pageSize : 5000,
    grouped: false
  })
  derivatives( { error, data } ) {
    this.columns = [
      {label: "Risk Type", fieldName: 'productType', type: 'text', initialWidth: 140, cellAttributes: {alignment: 'left'}},
      {label: "Credit Risk Type", fieldName: 'creditRiskTypeName', initialWidth: 140, type: 'text', cellAttributes: {alignment: 'left'}},
      {label: "Risk Exposure ", fieldName: 'riskExpsMetricTypeName', initialWidth: 235, type: 'text', cellAttributes: {alignment: 'left'}},
      {label: "Client GM Id ", fieldName: 'srceSystemCounterpartyId', initialWidth: 130, type: 'text', cellAttributes: {alignment: 'left'}},
      {label: "Currency", fieldName: 'currencyId', initialWidth: 100, type: 'text', cellAttributes: {alignment: 'left'}},
      {label: "Peak", fieldName: 'tenorPeak', type: 'customCurrency', typeAttributes: {currencyCode: this.currency}, cellAttributes: {alignment: 'right'}},
      {label: "<1Y", fieldName: 'tenor1Y', type: 'customCurrency', typeAttributes: {currencyCode: this.currency}, cellAttributes: {alignment: 'right'}},
      {label: "1Y-3Y", fieldName: 'tenor1Y3Y', type: 'customCurrency', typeAttributes: {currencyCode: this.currency}, cellAttributes: {alignment: 'right'}},
      {label: "3Y-5Y", fieldName: 'tenor3Y5Y', type: 'customCurrency', typeAttributes: {currencyCode: this.currency}, cellAttributes: {alignment: 'right'}},
      {label: "5Y-10Y", fieldName: 'tenor5Y10Y', type: 'customCurrency', typeAttributes: {currencyCode: this.currency}, cellAttributes: {alignment: 'right'}},
      {label: ">10Y", fieldName: 'tenor10Y', type: 'customCurrency', typeAttributes: {currencyCode: this.currency}, cellAttributes: {alignment: 'right', fieldName:'lastcolumn'}},
      {label: ' ', fieldName: '', type: 'text', fixedWidth: 16, hideDefaultActions: true}
    ];
    if (data) {
      this.updateDataTable(data);
    } else if (error) {
      this.error = error;
      console.error(data.message);
      this.isLoading = false;
    }
  };

  updateDataTable(data) {
    if (data.success) {
      var tableData = [];
      data.data.forEach( data =>  {
        this.title = data.customerName + ' - Derivatives';
        data.detailDerivatives.forEach( detail => {
          var metricTypeName = detail.riskExpsMetricTypeName;
          if (metricTypeName === 'POTENCIAL EXPOSURE') {
            this.showChart = true;
            this.heightClass = 'vh33';
          }
          if (metricTypeName === 'PEAK EXPOSURE') {
            metricTypeName = 'POTENCIAL EXPOSURE';
          }
          var id = detail.productType + detail.creditRiskTypeName + metricTypeName + detail.srceSystemCounterpartyId;
          var found = tableData.find(i=> i.id === id);
          if (found) {
            switch (detail.tenorId) {
              case 'Peak':
                found.tenorPeak = parseFloat(detail.ctptyRiskExpsrAmount) * this.exchangeRate;
                break;
              case '<1y':
                found.tenor1Y = parseFloat(detail.ctptyRiskExpsrAmount) * this.exchangeRate;
                break;
              case '1y-3y':
                found.tenor1Y3Y = parseFloat(detail.ctptyRiskExpsrAmount) * this.exchangeRate;
                break;
              case '3y-5y':
                found.tenor3Y5Y = parseFloat(detail.ctptyRiskExpsrAmount) * this.exchangeRate;
                break;
              case '5y-10y':
                found.tenor5Y10Y = parseFloat(detail.ctptyRiskExpsrAmount) * this.exchangeRate;
                break;
              case '>10y':
                found.tenor10Y = parseFloat(detail.ctptyRiskExpsrAmount) * this.exchangeRate;
                break;
              default:
                break;
            }
          } else {
            var rowData = {
              id: id,
              groupName: data.groupName,
              subGroupName: data.subGroupName,
              customerName: data.customerName,
              productType : detail.productType,
              creditRiskTypeName: detail.creditRiskTypeName,
              riskExpsMetricTypeName : metricTypeName,
              srceSystemCounterpartyId : detail.srceSystemCounterpartyId,
              currencyId : detail.currencyId,
              tenorId : detail.tenorId,
              ctptyRiskExpsrAmount : parseFloat(detail.ctptyRiskExpsrAmount) * this.exchangeRate,
              maturityTermNumber: detail.maturityTermNumber,
              lastcolumn: 'padding-right:22px;'
            };
            switch (detail.tenorId) {
              case 'Peak':
                rowData.tenorPeak = parseFloat(detail.ctptyRiskExpsrAmount) * this.exchangeRate;
                break;
              case '<1y':
                rowData.tenor1Y = parseFloat(detail.ctptyRiskExpsrAmount) * this.exchangeRate;
                break;
              case '1y-3y':
                rowData.tenor1Y3Y = parseFloat(detail.ctptyRiskExpsrAmount) * this.exchangeRate;
                break;
              case '3y-5y':
                rowData.tenor3Y5Y = parseFloat(detail.ctptyRiskExpsrAmount) * this.exchangeRate;
                break;
              case '5y-10y':
                rowData.tenor5Y10Y = parseFloat(detail.ctptyRiskExpsrAmount) * this.exchangeRate;
                break;
              case '>10y':
                rowData.tenor10Y = parseFloat(detail.ctptyRiskExpsrAmount) * this.exchangeRate;
                break;
              default:
                break;
            }
            tableData.push(rowData);
          }
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
    var fileName = this.clientId + '_deivatives_' + this.searchDate + '.csv';
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