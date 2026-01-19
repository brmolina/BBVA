import { api, track, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import { refreshApex } from '@salesforce/apex';
import { labels } from './hpg_consumption_summary_labels.js';
import getConsumptionSummary from '@salesforce/apex/HPG_SecondaryTablesController.getConsumptionSummary';

const groupMap = [
  {parent: '10000', child: ['10200','10100']},
  {parent: '20000', child: ['20200','20100']},
  {parent: 'under', child: ['130000','140000']},
  {parent: '50000', child: ['10000','20000','30000','40000','under']},
  {parent: '70000', child: ['50000','60000']},
  {parent: '80000', child: ['80200','80100']},
  {parent: '90000', child: ['80000','70000']}
];

const summProperties = [
  'committedContractsDisposedAmount' ,
  'uncommittedContractsDisposedAmount',
  'committedContractsNonDisposedAmount',
  'uncommittedContractsNonDisposedAmount',
  'authorizedRiskAmount',
  'unavailableRiskAmount',
  'cNotSignedTrConsumptionAmount'
];

export default class Hpg_consumption_summary extends LightningModal {

    labels = labels;
    groupMap = groupMap;
    summProperties = summProperties;

    draftValues = [];
    disableSave = true;
    sortOrder = [];
    data = [];
    expandedRows = [];
    csv = '';

    @track showModal = true;
    @track isLoading = true;
    @track title;
    @track columns = [];

    @api clientId;
    @api clientType;
    @api clientName;
    @api searchDate;
    @api countries;
    @api params;
    @api currency;
    @api exchangeRate;
    @api userAdmin = false;

    _serviceResponse;

    @wire(getConsumptionSummary, {
        pageSize: 100,
        page: 1,
        clientId: '$clientId',
        clientType: '$clientType',
        searchDate: '$searchDate',
        countryTotal: 'TODO',
        timestamp: Date.now()
    }) summaryTable (result) {
      this._serviceResponse = result;
      this.columns = [
        {label: this.labels.consumptionLastLevelId, fieldName: 'consumptionLastLevelId', initialWidth: 300, type: 'text', cellAttributes: {alignment: 'left', style:{fieldName:'totalLine'}} },
        {label: this.labels.productTypeDesc, fieldName: 'productTypeDesc', type: 'text', cellAttributes: {alignment: 'left', style:{fieldName:'totalLine'}}},
        {label: this.labels.authorizedRiskAmount, fieldName: 'authorizedRiskAmount', type: 'currency', typeAttributes: { currencyCode: this.currency, currencyDisplayAs: 'code'}, cellAttributes: {alignment: 'right', style:{fieldName:'totalLine'}}},
        {label: this.labels.committedContractsDisposedAmount, fieldName: 'committedContractsDisposedAmount', type: 'currency', typeAttributes: { currencyCode: this.currency, currencyDisplayAs: 'code'}, cellAttributes: {alignment: 'right', style:{fieldName:'totalLine'}}},
        {label: this.labels.committedContractsNonDisposedAmount, fieldName: 'committedContractsNonDisposedAmount', type: 'currency', typeAttributes: { currencyCode: this.currency, currencyDisplayAs: 'code'},  cellAttributes: {alignment: 'right', style:{fieldName:'totalLine'}}},
        {label: this.labels.uncommittedContractsDisposedAmount, fieldName: 'uncommittedContractsDisposedAmount', type: 'currency', typeAttributes: { currencyCode: this.currency, currencyDisplayAs: 'code'}, cellAttributes: {alignment: 'right', style:{fieldName:'totalLine'}}},
        {label: this.labels.uncommittedContractsNonDisposedAmount, fieldName: 'uncommittedContractsNonDisposedAmount', type: 'currency', typeAttributes: { currencyCode: this.currency, currencyDisplayAs: 'code'},  cellAttributes: {alignment: 'right', style:{fieldName:'totalLine'}}},
        {label: this.labels.unavailableRiskAmount, fieldName: 'unavailableRiskAmount', type: 'currency', typeAttributes: { currencyCode: this.currency, currencyDisplayAs: 'code'}, cellAttributes: {alignment: 'right', style:{fieldName:'totalLine'}}},
        {label: this.labels.cNotSignedTrConsumptionAmount, fieldName: 'cNotSignedTrConsumptionAmount', type: 'currency', typeAttributes: { currencyCode: this.currency, currencyDisplayAs: 'code'}, cellAttributes: {alignment: 'right', style:{fieldName:'totalLine'}}},
        {label: this.labels.unauthorizedCount, fieldName: 'unauthorizedCount', type: 'text', cellAttributes: {alignment: 'right', style:{fieldName:'totalLineLast'}}}
      ];
      if (result.data) {
        this.title = this.clientName + ' -  Consumption Summary';
        this.updateDataTable(result.data);
      } else if (result.error) {
        this.error = result.error;
        console.error('ERROR', result.error);
        this.isLoading = false;
      }
    };

     updateDataTable(data) {
        if (data.success) {
          var dataCurrency = [];
          var dataToPass = [];
          var rowstoExpand = [];
          var catalogAmount;
          var consumptionObj;
          var labelConsuption;
          var productTypeArray;
          var catalogIndex;
          var consuptionLastLevelindex;
          data.data.forEach(data =>  {
            catalogAmount = 0;
            labelConsuption = (this.labels[data.consumptionLastLevelId]) ? this.labels[data.consumptionLastLevelId] : data.consumptionLastLevelId;
            // if the consumption variable exist in the data array we assign it to a variable, if not we create a new one to group by consuption level
            consuptionLastLevelindex = dataToPass.findIndex((consElem) => consElem.internalId === labelConsuption + 'total');
            if(consuptionLastLevelindex !== -1) {
              consumptionObj = dataToPass[consuptionLastLevelindex];
              productTypeArray =  consumptionObj._children;
            } else {
              productTypeArray =  [];
              consumptionObj = {
                internalId : labelConsuption + 'total',
                consumptionLastLevelId : 'Total of ' + labelConsuption,
                productTypeDesc: '-',
                committedContractsDisposedAmount : 0.0,
                uncommittedContractsDisposedAmount : 0.0,
                committedContractsNonDisposedAmount : 0.0,
                uncommittedContractsNonDisposedAmount : 0.0,
                authorizedRiskAmount : 0.0,
                unavailableRiskAmount : 0.0,
                unauthorizedCount : 0.0,
                cNotSignedTrConsumptionAmount : 0.0,
                totalLine : 'background-color:#f8f8f8;font-weight:600;',
                totalLineLast: 'background-color:#f8f8f8;font-weight:600;padding-right:22px;',
                _children:[]
              }
              rowstoExpand.push(consumptionObj.internalId);
            }
            data.catalogs.forEach( catalog => {
              // if the catalog variable exist in the data array we assign it to a variable, if not we create a new one group by catalog level
              catalogIndex = productTypeArray.findIndex((prodTypeElem) => prodTypeElem.internalId === labelConsuption + catalog.productTypeDesc);
                if(catalogIndex !== -1) {
                  //summ of ammount of the catalog level group that we found
                  this.summProperties.forEach(prop => {
                    if (catalog[prop]) {
                        productTypeArray[catalogIndex][prop] += parseFloat(catalog[prop].toFixed(2));
                    }
                  });
                  productTypeArray[catalogIndex]['unauthorizedCount'] += parseFloat(catalog['unauthorizedCount']);
                  //initialization of a new product if it no exist already
                } else {
                  productTypeArray.push({
                    internalId : labelConsuption + catalog.productTypeDesc,
                    consumptionLastLevelId: labelConsuption,
                    productTypeDesc : catalog.productTypeDesc,
                    authorizedRiskAmount: parseFloat(catalog.authorizedRiskAmount) * this.exchangeRate,
                    committedContractsDisposedAmount: parseFloat(catalog.committedContractsDisposedAmount) * this.exchangeRate,
                    uncommittedContractsDisposedAmount: parseFloat(catalog.uncommittedContractsDisposedAmount) * this.exchangeRate,
                    committedContractsNonDisposedAmount: parseFloat(catalog.committedContractsNonDisposedAmount) * this.exchangeRate,
                    uncommittedContractsNonDisposedAmount: parseFloat(catalog.uncommittedContractsNonDisposedAmount) * this.exchangeRate,
                    unavailableRiskAmount: parseFloat(catalog.unavailableRiskAmount) * this.exchangeRate,
                    cNotSignedTrConsumptionAmount: parseFloat(catalog.cNotSignedTrConsumptionAmount) * this.exchangeRate,
                    unauthorizedCount: catalog.unauthorizedCount,
                    totalLineLast: 'padding-right:22px;'
                  });
                }
                this.summProperties.forEach(prop => {
                  if (catalog[prop]) {
                    consumptionObj[prop] += parseFloat(catalog[prop].toFixed(2)) * this.exchangeRate;
                  }
                });
                consumptionObj['unauthorizedCount'] += parseFloat(catalog['unauthorizedCount']);
            });
              consumptionObj._children = productTypeArray;
            if(consuptionLastLevelindex !== -1) {
              dataToPass[consuptionLastLevelindex] = consumptionObj;
            } else {
              dataToPass.push(consumptionObj);
            }
          });
          this.groupMap.forEach(group => {
            dataToPass = this.getChildrens(dataToPass,group.child,group.parent);
          });
          this.data = dataToPass;
          this.isLoading = false;
      } else {
        this.error = data.message;
        console.error(data.message);
        this.isLoading = false;
      }
    }

    getChildrens(dataToPass,childCodes,parentCode) {
      let children = [];
      let indexOf;
      childCodes.forEach(code => {
        indexOf = dataToPass.findIndex((comp) => comp.internalId === this.labels[code] + 'total');
        if(indexOf!==-1){
          children.push(...dataToPass.splice(indexOf, 1));
        }
      })
      var consumptionObj = {
        internalId : this.labels[parentCode] + 'total' ,
        consumptionLastLevelId : this.labels[parentCode],
        productTypeDesc: '-',
        committedContractsDisposedAmount: 0.0,
        uncommittedContractsDisposedAmount: 0.0,
        committedContractsNonDisposedAmount: 0.0,
        uncommittedContractsNonDisposedAmount: 0.0,
        authorizedRiskAmount: 0.0,
        unavailableRiskAmount: 0.0,
        unauthorizedCount: 0.0,
        cNotSignedTrConsumptionAmount: 0.0,
        totalLine: 'background-color:#f8f8f8;font-weight:600;',
        totalLineLast: 'background-color:#f8f8f8;font-weight:600;padding-right:22px;'
      }
      children.forEach(child => {
        this.summProperties.forEach( prop => {
          if (child[prop]) {
            consumptionObj[prop] += parseFloat(child[prop].toFixed(2));
          }
        });
        consumptionObj['unauthorizedCount'] += parseFloat(child['unauthorizedCount']);
      });
      if(children.length > 0){
        consumptionObj._children = children;
      }
      dataToPass.push(consumptionObj);
      return dataToPass;
    }

    connectedCallback() {
      refreshApex(this._serviceResponse);
    }

    renderedCallback() {
      if (this.template.querySelector('.slds-table_header-fixed_container')) {
        this.template.querySelector('.slds-table_header-fixed_container').classList.remove('slds-table_header-fixed_container');
      }
      const grid =  this.template.querySelector('lightning-tree-grid');
      grid.expandAll();
    }

    handleActiveTab() {
      console.log('tab');
    }

    get chartData() {
      return this._serviceResponse;
    }

    downloadCSV() {
      var fileName = this.clientId + '_consumption_summary_' + this.searchDate + '.csv';
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