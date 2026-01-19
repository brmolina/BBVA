import { api, track, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import { refreshApex } from '@salesforce/apex';
import getDataConsumptionDetail from '@salesforce/apex/HPG_SecondaryTablesController.getConsumptionDetail';
import validateDataOverrideConsumption from '@salesforce/apex/HPG_SecondaryTablesController.validateOverrideConsumption';

//Labels
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

export default class Hpg_consumption_detail extends LightningModal {

  labels = labels;
  draftValues = [];
  disableSave = true;
  sortOrder = [];
  title = 'Risk Consumption Detail';

  @api groupName;
  @api groupCode;
  @api clientId;
  @api clientType;
  @api clientName;
  @api searchDate;
  @api countries;
  @api params;
  @api currency;
  @api exchangeRate;
  @api userAdmin = false;

  @track showModal = true;
  @track isLoading = true;
  @track data = [];
  @track csv = [];
  @track page = 1;
  @track pageSize = 300;
  @track columns = [];

  @track gContractId;
  @track gCurrentDate;
  @track gClientName = this.clientName;
  @track gShow = false;

  adminColumns = [{label: ' ', fieldName: 'overrideIcon', type: 'button-icon', initialWidth: 15, typeAttributes: {iconName: {fieldName: 'overrideIcon'}, name: {fieldName: 'overrideAction'}, title: {fieldName: 'overrideTitle'}, variant: 'bare'}, cellAttributes: {class: {fieldName: 'expiredIconClass'}, alignment: 'center'}}];
  _serviceResponse;

  @wire(getDataConsumptionDetail, {
    clientId: '$clientId',
    clientType: '$clientType',
    countries: '$countries',
    searchDate : '$searchDate',
    page : '$page',
    pageSize : '$pageSize',
    filter: '$params.field',
    timestamp: Date.now()
  }) consumptiondetails(result) {
    this._serviceResponse = result;
    this.columns = (this.userAdmin ?  this.adminColumns : []).concat([
      {label: 'Initial Date', fieldName: 'contractRegisterDate', type: 'date', initialWidth: 110, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'left'}},
      {label: 'Maturity Date', fieldName: 'currentExpirationDate', type: 'date', initialWidth: 130, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'left'}},
      {label: 'Currency', fieldName: 'currencyId', type: 'text', initialWidth: 98, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'left'}},
      {label: 'Branch', fieldName: 'branchId', type: 'text', initialWidth: 85, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'right'}},
      {label: 'Refinanced Ind', fieldName: 'activityRefinancedType', type: 'text', initialWidth: 135, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'right'}},
      {label: 'Authorization Id', fieldName: 'opportunityId', type: 'text', initialWidth: 225, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'left'}},
      {label: 'Contract Id', fieldName: 'internalContractCodeDesc', type: 'linkToGuarantees', typeAttributes: {date: this.searchDate}, initialWidth: 225, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'left'}},
      {label: 'Entity', fieldName: 'entityId', type: 'text', initialWidth: 80, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'right'}},
      {label: 'Max Deadline Date', fieldName: 'maximumDeadlineDate', type: 'date', initialWidth: 160, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'left'}},
      {label: 'Product Type', fieldName: 'productTypeDesc', type: 'text', initialWidth: 260, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'left'}},
      {label: 'Maturity', fieldName: 'maturityTermNumber', type: 'number', initialWidth: 100, cellAttributes: {class: {fieldName: 'expiredClass'}, minimumFractionDigits : '1', alignment: 'right'}},
      {label: 'Consumption Last Level', fieldName: 'consumptionLastLevelName', type: 'text', initialWidth: 200, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'left'}},
      {label: 'Current Guaranteed Amount', fieldName: 'currentGuaranteedAmount', initialWidth: 220, type: 'customCurrency', typeAttributes: {currencyCode: this.currency}, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'right'}},
      {label: 'Committed Contracts Drawn Amount', fieldName: 'committedContractsDisposedAmount', initialWidth: 275, type: 'customCurrency', typeAttributes: {currencyCode: this.currency}, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'right'}},
      {label: 'Uncommitted Contracts Drawn Amount', fieldName: 'uncommittedContractsDisposedAmount', initialWidth: 285, type: 'customCurrency', typeAttributes: {currencyCode: this.currency}, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'right'}},
      {label: 'Committed Contracts Undrawn Amount', fieldName: 'committedContractsNonDisposedAmount', initialWidth: 285, type: 'customCurrency', typeAttributes: {currencyCode: this.currency}, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'right'}},
      {label: 'Uncommitted Contracts Undrawn Amount', fieldName: 'uncommittedContractsNonDisposedAmount', initialWidth: 300, type: 'customCurrency', typeAttributes: {currencyCode: this.currency}, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'right'}},
      {label: 'Pending Authorized', fieldName: 'authorizedRiskAmount', type: 'customCurrency', initialWidth: 170, typeAttributes: {currencyCode: this.currency}, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'right'}},
      {label: 'Total Exposure', fieldName: 'unavailableRiskAmount', type: 'customCurrency', initialWidth: 170, typeAttributes: {currencyCode: this.currency}, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'right'}},
      {label: 'Draft', fieldName: 'cNotSignedTrConsumptionAmount', type: 'customCurrency', initialWidth: 170, typeAttributes: {currencyCode: this.currency}, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'right'}},
      {label: 'Details', fieldName: 'catalogFieldValueEsDes', type: 'text', initialWidth: 260, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'right'}},
      {label: 'Consumption Exclusion Ind', fieldName: 'lineConsumptionExclusionIndType', type: 'text', initialWidth: 210, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'right'}},
      {label: 'Sustainability Mark', fieldName: 'sustainabilityMarkId', type: 'text', initialWidth: 170, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'right'}},
      {label: 'Sustainability Category', fieldName: 'sustCategoryTradePerDesc', type: 'text', initialWidth: 200, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'right'}},
      {label: 'Trade Data Origin', fieldName: 'originatesDataGeographyId', type: 'text', initialWidth: 150, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'right'}},
      {label: 'Trade Data Update Frequency', fieldName: 'frequencyType', type: 'text', initialWidth: 225, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'right'}},
      {label: 'Booking Segment', fieldName: 'cibSegmentType', type: 'text', initialWidth: 150, cellAttributes: {class: {fieldName: 'expiredClass'}, alignment: 'right'}},
      {label: ' ', fieldName: '', type: 'text', fixedWidth: 16, hideDefaultActions: true}
    ]);
    if (result.data) {
      this.title = this.clientName + ' -  Risk Consumption Detail';
      this.updateDataTable(result.data);
    } else if (result.error) {
      this.error = result.error;
      console.error(result.error);
      this.isLoading = false;
    }
  };

  updateDataTable(data) {
    if (data.success) {
      validateDataOverrideConsumption({ data: data, clientId: this.groupCode})
        .then(result => {
          var tableData = [];
          result.data.forEach( data =>  {
            data.detailConsumptions.forEach(detailConsumption => {
              if (detailConsumption.consumptionLastLevelId ===  this.params.field) {
                var rowData = {
                  groupName: data.groupName,
                  subGroupName: data.subGroupName,
                  customerName: data.customerName,
                  expiredClass: (detailConsumption.consumptionExpired ? 'slds-text-color_error' : ''),
                  expiredIconClass: (detailConsumption.overrideAction == 'EXPIRED' ? 'slds-icon slds-icon-text-error' : ''),
                  overrideAction: detailConsumption.overrideAction,
                  overrideComments: detailConsumption.overrideComments,
                  overrideIcon: (detailConsumption.overrideAction != 'EXPIRED' ? detailConsumption.overrideIcon : ''),
                  overrideTitle: detailConsumption.overrideTitle,
                  contractRegisterDate: detailConsumption.contractRegisterDate,
                  currentExpirationDate: detailConsumption.currentExpirationDate,
                  currencyId: detailConsumption.currencyId,
                  branchId: detailConsumption.branchId,
                  activityRefinancedType: detailConsumption.activityRefinancedType,
                  internalContractCodeDesc: detailConsumption.internalContractCodeDesc,
                  entityId: detailConsumption.entityId,
                  maximumDeadlineDate: detailConsumption.maximumDeadlineDate,
                  productTypeDesc: detailConsumption.productTypeDesc,
                  maturityTermNumber : detailConsumption.maturityTermNumber,
                  consumptionLastLevelName: this.labels[detailConsumption.consumptionLastLevelId] ? this.labels[detailConsumption.consumptionLastLevelId] : detailConsumption.consumptionLastLevelId,
                  consumptionLastLevelId: detailConsumption.consumptionLastLevelId,
                  currentGuaranteedAmount: parseFloat(detailConsumption.currentGuaranteedAmount) * this.exchangeRate,
                  committedContractsDisposedAmount: parseFloat(detailConsumption.committedContractsDisposedAmount) * this.exchangeRate,
                  uncommittedContractsDisposedAmount: parseFloat(detailConsumption.uncommittedContractsDisposedAmount) * this.exchangeRate,
                  committedContractsNonDisposedAmount: parseFloat(detailConsumption.committedContractsNonDisposedAmount) * this.exchangeRate,
                  uncommittedContractsNonDisposedAmount: parseFloat(detailConsumption.uncommittedContractsNonDisposedAmount) * this.exchangeRate,
                  authorizedRiskAmount: parseFloat(detailConsumption.authorizedRiskAmount) * this.exchangeRate,
                  unavailableRiskAmount: parseFloat(detailConsumption.unavailableRiskAmount) * this.exchangeRate,
                  cNotSignedTrConsumptionAmount: parseFloat(detailConsumption.cNotSignedTrConsumptionAmount) * this.exchangeRate,
                  catalogFieldValueEsDes: detailConsumption.catalogFieldValueEsDes,
                  lineConsumptionExclusionIndType: detailConsumption.lineConsumptionExclusionIndType,
                  sustainabilityMarkId: detailConsumption.sustainabilityMarkId,
                  sustCategoryTradePerDesc: detailConsumption.sustCategoryTradePerDesc,
                  originatesDataGeographyId: detailConsumption.originatesDataGeographyId,
                  frequencyType: detailConsumption.frequencyType,
                  cibSegmentType: detailConsumption.cibSegmentType,
                  opportunityId: detailConsumption.opportunityId
                };
                tableData.push(rowData);
              }
            });
          });
          this.data = tableData.sort( function( b, a ) {
              return a.unavailableRiskAmount < b.unavailableRiskAmount ? -1 : a.unavailableRiskAmount > b.unavailableRiskAmount ? 1 : 0;
          });
          this.isLoading = false;
        })
        .catch(error => {
          this.error = 'Error validating data: ' + error.body.message;
          console.error(this.error);
          this.isLoading = false;
        });
    } else {
      this.error = data.message;
      console.error(data.message);
      this.isLoading = false;
    }
  }

  connectedCallback() {
    console.log('refreshApex');
    refreshApex(this._serviceResponse);
  }

  get eventPayload() {
    return {
      action: 'CLIENT',
      groupId: this.groupCode,
      groupName: this.groupName,
      customerId: this.clientId,
      customerName: this.clientName,
      consumptionLastLevelId: this.params.field,
      overrideStartDate: this.getPreviousBusinessDay(),
      overrideUploadDate: Intl.DateTimeFormat('sv-SE').format(new Date())
    }
  }

  get userIsAdmin() {
    return this.userAdmin;
  }

  handleRowAction(event) {
    if (event.detail.row.overrideAction != 'EXPIRED') {
      const launcher = this.template.querySelector('c-hpg_event_launcher');
      launcher.launchEvent(new CustomEvent( 'addoverride', {
        bubbles: true,
        composed: true,
        detail: {
          label: 'editoverride',
          value: {
            action: event.detail.row.overrideAction,
            overrideComments: event.detail.row.overrideComments,
            customerId: this.clientId,
            customerName: event.detail.row.customerName,
            groupId: this._serviceResponse.data.data[0].groupId,
            groupName: this._serviceResponse.data.data[0].groupName,
            internalContractCodeDesc: event.detail.row.internalContractCodeDesc,
            overrideStartDate: event.detail.row.contractRegisterDate,
            overrideEndDate: event.detail.row.currentExpirationDate,
            consumptionLastLevelId: event.detail.row.consumptionLastLevelId,
            consumptionLastLevelName: event.detail.row.consumptionLastLevelName,
            committedContractsDisposedAmount: (event.detail.row.committedContractsDisposedAmount ? event.detail.row.committedContractsDisposedAmount : ''),
            uncommittedContractsDisposedAmount: (event.detail.row.uncommittedContractsDisposedAmount ? event.detail.row.uncommittedContractsDisposedAmount : ''),
            committedContractsNonDisposedAmount: (event.detail.row.committedContractsNonDisposedAmount ? event.detail.row.committedContractsNonDisposedAmount : ''),
            uncommittedContractsNonDisposedAmount: (event.detail.row.uncommittedContractsNonDisposedAmount ? event.detail.row.uncommittedContractsNonDisposedAmount : ''),
            authorizedRiskAmount: (event.detail.row.authorizedRiskAmount ? event.detail.row.authorizedRiskAmount : ''),
            overrideUploadDate: Intl.DateTimeFormat('sv-SE').format(new Date())
          }
        }
      }));
    }
  }

  downloadCSV() {
    var fileName = this.clientId + '_consumption_detail_' + this.searchDate + '.csv';
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

  getPreviousBusinessDay() {
    var date = new Date();
    date.setDate(date.getDate() - 1);
    while (date.getDay() === 0 || date.getDay() === 6 ) {
      date.setDate(date.getDate() - 1);
    }
    return Intl.DateTimeFormat('sv-SE').format(date); // YYYY-MM-DD
  }

  openContractGuarantees(e) {
      e.preventDefault();
      const { contractId, currentDate } = e.detail;
      console.log('open contract guarantees from consumption detail: ', contractId, currentDate);
      this.gContractId = contractId;
      this.gCurrentDate = currentDate;
      this.gShow = true
  }

  closeContractGuarantees(e) {
    this.gContractId = null;
    this.gCurrentDate = null;
    this.gShow = false
  }

  get showContractGuarantees() {
    return this.gShow;
  }

}