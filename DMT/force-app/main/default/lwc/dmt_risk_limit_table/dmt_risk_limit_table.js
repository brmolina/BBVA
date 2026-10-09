import { LightningElement,api } from 'lwc';
import {loadStyle } from 'lightning/platformResourceLoader';
import CustomDataTableResource from '@salesforce/resourceUrl/datatableOverrides';
import getCurrencyLabel from '@salesforce/apex/DMT_Currency_Conversion_Utils.getCurrencyLabel';
import { parseAbbreviatedNumber } from 'c/dmt_numberUtils';
import DERIVATIVES_LABEL from '@salesforce/label/c.dmt_cl_CounterpartyRisk_Text';
import DEPOS_LABEL from '@salesforce/label/c.dmt_cl_DeposRiskLine_Text';
import EQUITIES_LABEL from '@salesforce/label/c.dmt_cl_EquitiesWrong_Text';

import DERIVATIVES_LABEL_MX from '@salesforce/label/c.dmt_cl_CounterpartyRiskMX_Text';
import DEPOS_LABEL_MX from '@salesforce/label/c.dmt_cl_DeposRiskLineMX_Text';
import REPOS_LABEL from '@salesforce/label/c.dmt_cl_ReposRiskLine_Text';

const BR_CO_TERM_OPTIONS = [{ label: 'Select...', value: '' }, { label: '0D', value: '0' }, { label: '1D', value: '1' }, { label: '2D', value: '2' }, { label: '3D', value: '3' }, { label: '7D', value: '7' }, { label: '10D', value: '10' }, { label: '15D', value: '15' }, { label: '1M', value: '30' }, { label: '3M', value: '90' }, { label: '6M', value: '180' }, { label: '1Y', value: '365' }, { label: '2Y', value: '730' }, { label: '3Y', value: '1095' }, { label: '4Y', value: '1460' }, { label: '5Y', value: '1825' }, { label: '7Y', value: '2555' }, { label: '10Y', value: '3650' }, { label: '15Y', value: '5475' }, { label: '20Y', value: '7300' }, { label: '30Y', value: '10950' }];

export default class Dmt_risk_limit_table extends LightningElement {
    @api startDate;
    @api tabletype;
    @api lineId;
    @api totalamount;
    @api conversionLabel;
    @api layoutmx;
    
    _refreshCounter = 0;
    
    @api
    get refreshCounter() {
        return this._refreshCounter;
    }
    
    set refreshCounter(value) {
        const newValue = Number(value);
        if (newValue !== this._refreshCounter) {
            this._refreshCounter = newValue;
            // Reset drafts when parent signals refresh
            this.resetDraftValues();
        }
    }
    
    currencyvalue;
    defaultLimitvalue;
    bookingGeography;
    tableData;
    draftValues = [];
    _currencyLabelCache      = {};
    _pendingCurrencyFetches  = new Set();


    connectedCallback(){
      loadStyle(this, CustomDataTableResource);
    }

    renderedCallback() {
      // Ensure draftValues are synced with the datatable component
      // This prevents the datatable from losing the edited cells styling when focus is lost
      const dataTable = this.template.querySelector('c-dmt-risk-limit-data-table');
      if (dataTable && this.draftValues && this.draftValues.length > 0) {
        // Make sure datatable has the draftValues set
        if (!dataTable.draftValues || dataTable.draftValues.length === 0) {
          dataTable.draftValues = [...this.draftValues];
        }
      }
    }

    @api columnstablecopypaste = [];
    _isReadOnlyUser = false;

    @api
    get isReadOnlyUser() {
      return this._isReadOnlyUser;
    }

    set isReadOnlyUser(value) {
      this._isReadOnlyUser = value === true || value === 'true';
      this._applyReadOnlyState();
    }

    _applyReadOnlyState() {
      if (!this.tableData) {
        return;
      }
      this.tableData = this.tableData.map(row => ({
        ...row,
        isEditableAmount: !this._isReadOnlyUser && !row.isDisabled,
        pickDisabled: this._isReadOnlyUser || row.pickDisabled,
        deleteDisabled: this._isReadOnlyUser || row.deleteDisabled,
        buttonDisabled: this._isReadOnlyUser || row.buttonDisabled
      }));
    }
    //titletable = "TITLE";

    formatTermForDisplay(value) {
      if (value === null || value === undefined || value === '') {
        return '';
      }

      const numericValue = Number(value);
      if (!Number.isFinite(numericValue)) {
        return String(value);
      }

      if (numericValue === 0) {
        return '0D';
      }

      const exactOption = this.activeTermOptions.find(option => Number(option.value) === numericValue);
      if (exactOption) {
        return exactOption.label;
      }

      const years = numericValue / 365;
      if (Number.isInteger(years)) {
        return `${years}Y`;
      }

      return `${Number(years.toFixed(2))}Y`;
    }

    normalizeDisplayTerms(rows) {
      return rows.map(item => {
        const normalizedItem = { ...item };
        normalizedItem.displayInitTerm = this.formatTermForDisplay(normalizedItem.initTerm);
        normalizedItem.displayEndTerm = this.formatTermForDisplay(normalizedItem.endTerm);
        normalizedItem.amount_display = this._formatAmountDisplay(normalizedItem.amount, normalizedItem.currency || this.currencyvalue);
        normalizedItem.currencyLabel = this._getCurrencyLabel(normalizedItem.currency || this.currencyvalue);
        return normalizedItem;
      });
    }

    // ─── Currency label (metadata: DMT_Currency_Conversion__mdt) ─────────────

    _getCurrencyLabel(currencyCode) {
      const code = currencyCode || 'EUR';
      if (this._currencyLabelCache[code]) return this._currencyLabelCache[code];

      if (!this._pendingCurrencyFetches.has(code)) {
        this._pendingCurrencyFetches.add(code);
        getCurrencyLabel({ currencyIsoCode: code })
          .then(result => {
            this._currencyLabelCache[code] = result || code;
          })
          .catch(() => {
            this._currencyLabelCache[code] = code;
          })
          .finally(() => {
            this._pendingCurrencyFetches.delete(code);
            this._refreshAmountDisplay();
          });
      }

      return code;
    }

    _formatAmountDisplay(value, currencyCode) {
      if (value === null || value === undefined || value === '') return '';
      const numeric = Number(value);
      const formatted = Number.isNaN(numeric) ? value : numeric.toLocaleString('en-US');
      const label = this._getCurrencyLabel(currencyCode);
      return `${formatted} ${label}`.trim();
    }

    _refreshAmountDisplay() {
      if (!this.tableData || this.tableData.length === 0) return;
      this.tableData = this.tableData.map(row => ({
        ...row,
        amount_display: this._formatAmountDisplay(row.amount, row.currency || this.currencyvalue),
        currencyLabel: this._getCurrencyLabel(row.currency || this.currencyvalue)
      }));
    }

    // Parses a display string like "1,234.50 Units EUR" or shorthand like "1M", "1K" back into a plain number.
    _parseAmountFromDisplay(value) {
      return parseAbbreviatedNumber(value, true);
    }

    @api
    get table() {
      return this.tableData;
    }
    
   

    get context() {
      if (this.tableData && this.tableData[0]) {
        const tableType = this.tableData[0]['tabletype'];
        if (tableType === 'Equities') return 'equities';
        if (tableType === 'Depos') return 'depos';
        if (tableType === 'Repos') return 'repos';
      }
      return 'derivatives';
    }

    // Rows pasted or built in the UI may miss `tabletype`; fall back to the @api value.
    get resolvedTabletype() {
      return (this.tableData && this.tableData[0] && this.tableData[0]['tabletype']) || this.tabletype;
    }

    get activeTermOptions() {
      return ['BR', 'CO'].includes((this.bookingGeography || '').trim().toUpperCase())
        ? BR_CO_TERM_OPTIONS
        : this.termoptions;
    }

    set table(value) {
      let normalizedData;

      try {
          if (typeof value === 'string') {
              const parsed = JSON.parse(value);
              if (Array.isArray(parsed)) {
                  normalizedData = parsed;
              } else if (typeof parsed === 'object' && parsed !== null) {
                  normalizedData = [parsed];
              } else {
                  normalizedData = [];
              }
          } else if (Array.isArray(value)) {
              normalizedData = value.filter(item => typeof item === 'object' && item !== null);
          } else if (typeof value === 'object' && value !== null) {
              normalizedData = [value];
          } else {
              console.warn('Formato inesperado para table:', value);
              normalizedData = [];
          }
      } catch (e) {
          console.error('Error al procesar table:', e);
          normalizedData = [];
      }

      console.log('Normalizado:', JSON.stringify(normalizedData));

        if (normalizedData.length > 0) {
          const activeTermOptions = this.activeTermOptions;
          const maxTermValue = activeTermOptions[activeTermOptions.length - 1].value;
          console.log('Max Term Value:', maxTermValue);
          const newArray = normalizedData.map((item, index) => {
            const newItem = { ...item };
            newItem.isEditableAmount = !this._isReadOnlyUser && !newItem.isDisabled;
            if (index === normalizedData.length - 1 && newItem.isDisabled != true) {
              newItem.buttonDisabled = this._isReadOnlyUser || newItem.endTerm === maxTermValue || newItem.endTerm === "";
              newItem.pickDisabled = this._isReadOnlyUser;
              newItem.deleteDisabled = this._isReadOnlyUser;
            }
            return newItem;
          });

          this.tableData = this.normalizeDisplayTerms(newArray);
      } else {
          this.tableData = [];
      }

  }
    /*
    set table(value) {
      console.log('Original:'+value);
      let copyData = JSON.parse(JSON.stringify(value));
      console.log('copyData:'+copyData);
      // Validar que sea array
    if (Array.isArray(copyData) && copyData.length > 0 && typeof copyData[copyData.length - 1] === 'object') {
        console.log('Es un Objeto');
        copyData[copyData.length - 1]['buttonDisabled'] = false;
        copyData[copyData.length - 1]['pickDisabled'] = false;
        if(copyData.length > 1){
          copyData[copyData.length - 1]['deleteDisabled'] = false;
        } else {
          copyData[copyData.length - 1]['deleteDisabled'] = true;
        }
        this.tableData = JSON.parse(JSON.stringify(copyData));
      } else {
        console.warn('copyData no es un array de objetos válido:', copyData);
      }
    }*/

    @api
    get  defaultLimit() {
      //this.handledefaultLimit();
      return this.defaultLimitvalue;
    }
    set defaultLimit(value) {
      this.defaultLimitvalue = value;
      if(String(value).toLowerCase() === 'true'){
        Promise.resolve().then(() => {
          if (String(this.defaultLimitvalue).toLowerCase() === 'true') {
            this.handledefaultLimit();
          }
        });
      }
    }

    @api
    get  bookingGeographyLine() {
      return this.bookingGeography;
    }
    set bookingGeographyLine(value) {
      this.bookingGeography = value;
      this.currency = this.currencyvalue;
    }

     get titletable() {
      if( this.tableData && this.tableData[0]) {
        if (this.bookingGeography == 'MX') {
          return this.tableData[0]['tabletype'] == "Depos" ? DEPOS_LABEL_MX : (this.tableData[0]['tabletype'] == "Derivatives" ? DERIVATIVES_LABEL_MX : DERIVATIVES_LABEL);
        }else{
           return this.tableData[0]['tabletype'] == "Equities" ? EQUITIES_LABEL: (this.tableData[0]['tabletype'] == "Depos" ? DEPOS_LABEL: (this.tableData[0]['tabletype'] == "Repos" ? REPOS_LABEL : DERIVATIVES_LABEL))
        }
      } else {
        return this.bookingGeography == 'MX' ? DERIVATIVES_LABEL_MX : DERIVATIVES_LABEL;
      }
    }

    @api
    get  currency() {
      return this.currencyvalue;
    }
    set currency(value) {
      this.currencyvalue = value;
      const activeTermOptions = this.activeTermOptions;
      this.columns = [{fieldName:"initTerm",label:"INIT TERM",type:"endTermPicklist",editable:false, hideDefaultActions:true,
        cellAttributes: { alignment: 'center' }, typeAttributes: { value: { fieldName: 'initTerm' }, options: activeTermOptions, isDisabled: true, context: { fieldName: 'Id' } }},{fieldName:"endTerm",label:"END TERM",type:"endTermPicklist",editable:false, hideDefaultActions:true,
            cellAttributes: { alignment: 'center' }, typeAttributes: { value: { fieldName: 'endTerm' }, options: activeTermOptions, optionslimit: { fieldName: 'initTerm' }, isDisabled: { fieldName: 'pickDisabled' }, context: { fieldName: 'Id' } }},
        {fieldName:"amount_display",label:"AMOUNT", type: 'amountColumn',editable: { fieldName: 'isEditableAmount' } , hideDefaultActions:false,
            cellAttributes: { alignment: 'center' },
            initialWidth: 240,
            typeAttributes: { displayValue: { fieldName: 'amount_display' }, editValue: { fieldName: 'amount' }, currencyLabel: { fieldName: 'currencyLabel' } }},
            {
                type:  'button-icon',hideDefaultActions:true,
                cellAttributes: { alignment: 'center' },
                initialWidth: 90,
                typeAttributes:
                {
                  iconName: 'utility:delete',
                  label: ' ',
                  name: 'deleteRecord',
                  title: '',
                  variant: "brand-outlined",
                  disabled: {fieldName: 'deleteDisabled'},
                  iconPosition: 'center',
                  value: 'test'
                }
              }
              ,
            {
                type:  'button-icon',hideDefaultActions:true,
                cellAttributes: { alignment: 'center' },
                initialWidth: 90,
                typeAttributes:
                {
                  iconName: 'utility:add',
                  label: '    ',
                  name: 'addRecord',
                  title: '        ',
                  variant: "brand-outlined",
                  disabled: {fieldName: 'buttonDisabled'},
                  iconPosition: 'center',
                  value: 'test'
                }
              }];

    }

    termoptions = [{ label: 'Select...', value: '' },{label:"0D",value:"0"},{label:"2D",value:"2"},{label:"3D",value:"3"},{label:"4D",value:"4"},{label:"7D",value:"7"},{label:"10D",value:"10"},{label:"15D",value:"15"},{label:"20D",value:"20"},{label:"1M",value:"30"},{label:"45D",value:"45"},{label:"2M",value:"60"},{label:"3M",value:"90"},{label:"4M",value:"120"},{label:"5M",value:"150"},{label:"6M",value:"180"},{label:"9M",value:"270"},{label:"1Y",value:"365"},{label:"18M",value:"548"},{label:"2Y",value:"730"},{label:"3Y",value:"1095"},{label:"4Y",value:"1460"},{label:"5Y",value:"1825"},{label:"6Y",value:"2190"},{label:"7Y",value:"2555"},{label:"8Y",value:"2920"},{label:"9Y",value:"3285"},{label:"10Y",value:"3650"},{label:"11Y",value:"4015"},{label:"12Y",value:"4380"},{label:"13Y",value:"4745"},{label:"14Y",value:"5110"},{label:"15Y",value:"5475"},{label:"16Y",value:"5840"},{label:"17Y",value:"6205"},{label:"18Y",value:"6570"},{label:"19Y",value:"6935"},{label:"20Y",value:"7300"},{label:"22Y",value:"8030"},{label:"25Y",value:"9125"},{label:"27Y",value:"9855"},{label:"30Y",value:"10950"},{label:"32Y",value:"11680"},{label:"35Y",value:"12775"},{label:"37Y",value:"13505"},{label:"40Y",value:"14600"},{label:"42Y",value:"15330"},{label:"45Y",value:"16425"}];
    columns = [{fieldName:"initTerm",label:"INIT TERM",type:"endTermPicklist",editable:false, hideDefaultActions:true,
      cellAttributes: { alignment: 'center' }, typeAttributes: { value: { fieldName: 'initTerm' }, options: this.activeTermOptions, isDisabled: true, context: { fieldName: 'Id' } }},{fieldName:"endTerm",label:"END TERM",type:"endTermPicklist",editable:false, hideDefaultActions:true,
        cellAttributes: { alignment: 'center' }, typeAttributes: { value: { fieldName: 'endTerm' }, options: this.activeTermOptions, optionslimit: { fieldName: 'initTerm' }, isDisabled: { fieldName: 'pickDisabled' }, context: { fieldName: 'Id' } }},
        {fieldName:"amount_display",label:"AMOUNT", type: 'amountColumn',editable:true, hideDefaultActions:true,
            cellAttributes: { alignment: 'center' },
            typeAttributes: { displayValue: { fieldName: 'amount_display' }, editValue: { fieldName: 'amount' }, currencyLabel: { fieldName: 'currencyLabel' } }},
            {
                type:  'button',hideDefaultActions:true,
                cellAttributes: { alignment: 'center' },
                initialWidth: 90,
                typeAttributes:
                {
                  iconName: 'utility:delete',
                  label: ' ',
                  name: 'deleteRecord',
                  title: '',
                  disabled: {fieldName: 'deleteDisabled'},
                  iconPosition: 'center',
                  value: 'test'
                }
              }
              ,
            {
                type:  'button',hideDefaultActions:true,
                cellAttributes: { alignment: 'center' },
                initialWidth: 90,
                typeAttributes:
                {
                  iconName: 'utility:add',
                  label: '    ',
                  name: 'addRecord',
                  title: '        ',
                  disabled: {fieldName: 'buttonDisabled'},
                  iconPosition: 'center',
                  value: 'test'
                }
              }];


    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        const activeTermOptions = this.activeTermOptions;
        const maxTermValue = activeTermOptions[activeTermOptions.length - 1].value;

        switch (action.name) {
            case 'deleteRecord':
                const tableType = this.resolvedTabletype;

                if (this.tableData.length === 1) {
                    this.totalamount = '';
                    const resetRow = {
                        ...this.tableData[0],
                        // Drop the record Id so the row is deleted server-side on Save.
                        Id: '1',
                        totalamount: '',
                        initTerm: "0",
                        endTerm: "2",
                        amount: null,
                        deleteDisabled: false,
                        pickDisabled: false,
                        buttonDisabled: true
                    };
                    const newTable = [resetRow];
                    this.dispatchEvent(new CustomEvent('tableriskchange', {
                        bubbles: true,
                        composed: true,
                        detail: { data: newTable, tabletype: tableType }
                    }));
                } else {
                    let copyData = this.tableData.filter(function(item) {
                        return item.Id !== row.Id;
                    });
                    let sendcopyData = this.copiarLista(copyData);
                    if (sendcopyData[0]) {
                      sendcopyData[sendcopyData.length-1]['buttonDisabled'] = false;
                      sendcopyData[sendcopyData.length-1]['pickDisabled'] = false;
                      sendcopyData[sendcopyData.length-1]['deleteDisabled'] = false;
                    }
                    this.dispatchEvent(new CustomEvent('tableriskchange', {
                        bubbles: true,
                        composed: true,
                        detail: { data: sendcopyData, tabletype: tableType }
                    }));
                }
                break;
            case 'addRecord':
                const index = this.tableData.findIndex(dataRow => dataRow.Id === row.Id);
                const currentEndTerm = this.tableData[index]["endTerm"];

                if (currentEndTerm === maxTermValue || currentEndTerm === "") return;
                console.log('this.tableData.length', this.tableData.length);
                let copyDataNew = [
                    ...this.tableData.slice(0, index+1),
                    {
                        "initTerm": this.tableData[index]["endTerm"],
                        "endTerm": "",
                        "Id": this.tableData.length + 1,
                        "amount": null,
                        "initRead": true,
                        "tabletype": this.tableData[index]["tabletype"],
                        "line": this.tableData[0]["line"],
                        "currency": this.tableData[0]["currency"],
                        "deleteDisabled": false,
                        'buttonDisabled': true
                    },
                    ...this.tableData.slice(index+1)
                ];
                let sendcopyDataNew = this.copiarLista(copyDataNew);
                sendcopyDataNew[sendcopyDataNew.length-2]['buttonDisabled'] = true;
                sendcopyDataNew[sendcopyDataNew.length-1]['buttonDisabled'] = true;
                sendcopyDataNew[sendcopyDataNew.length-2]['pickDisabled'] = true;
                sendcopyDataNew[sendcopyDataNew.length-1]['pickDisabled'] = false;
                sendcopyDataNew[sendcopyDataNew.length-2]['deleteDisabled'] = false;
                sendcopyDataNew[sendcopyDataNew.length-1]['deleteDisabled'] = false;
                this.dispatchEvent(new CustomEvent('tableriskchange', {
                    bubbles: true,
                    composed: true,
                    detail: { data: sendcopyDataNew, tabletype: this.resolvedTabletype }
                }));
                break;
        }
    }

    picklistChanged(event) {
      event.stopPropagation();
      let dataRecieved = event.detail.data;
      let updatedItem;
      if( dataRecieved.fieldname === 'iniTerm'){
          updatedItem = { Id: dataRecieved.context, initTerm: dataRecieved.value };
      }else{
          updatedItem = { Id: dataRecieved.context, endTerm: dataRecieved.value };
      }
      //this.updateDraftValues(updatedItem);
      this.updateDataValues(updatedItem);

  }

    handleEndTermChange(event) {
      event.stopPropagation();
      this.updateDataValues({
        Id: event.detail.context,
        endTerm: event.detail.value
      });
    }

    updateDataValues(updateItem) {
      let copyData = this.copiarLista(this.tableData);
      copyData.forEach(item => {
          if (item.Id.toString() === updateItem.Id.toString()) {
              for (let field in updateItem) {
                  item[field] = updateItem[field];
              }
          }
      });
      copyData[copyData.length-1]['buttonDisabled'] = false;
      //write changes back to original data
      this.dispatchEvent(new CustomEvent('tableriskchange',  { bubbles:true, composed:true,detail:  {data:copyData, tabletype:this.resolvedTabletype}} ));
  }

  copiarLista(listaOriginal) {
    return listaOriginal.map(elemento => {
      if (typeof elemento === 'object' && elemento !== null) {
        return JSON.parse(JSON.stringify(elemento));
      } else {
        return elemento; // Devolver una copia directa para valores primitivos
      }
    });
  }

  handledefaultLimit(){
    var guidanceData;
    if (this.tableData !== undefined)
    {
      if (this.tableData.length === 0) {
        if (!this.tabletype) {
          return;
        }
        this.tableData = [{
          tabletype: this.tabletype,
          line: this.lineId,
          currency: this.currencyvalue
        }];
      }

      if(this.tableData[0]['tabletype'] === 'Depos'){
        guidanceData = [    {
          "deleteDisabled": true,
          "initTerm": "0",
          "Id": "0",
          "pickDisabled": true,
          "initRead": "true",
          "buttonDisabled": true,
          "line": this.tableData[0]['line'],
          "currency": this.tableData[0]['currency'],
          "endTerm": "365",
          "amount": this.totalamount,
          "tabletype": "Depos"
        },{
          "deleteDisabled": false,
          "initTerm": "365",
          "Id": "1",
          "pickDisabled": false,
          "initRead": "true",
          "buttonDisabled": true,
          "line": this.tableData[0]['line'],
          "currency": this.tableData[0]['currency'],
          "endTerm": "16425",
          "amount": this.totalamount*0,
          "tabletype": "Depos"
        }];
      }
       else if(this.tableData[0]['tabletype'] === 'Repos'){
        guidanceData = [    {
          "deleteDisabled": true,
          "initTerm": "0",
          "Id": "0",
          "pickDisabled": true,
          "initRead": "true",
          "buttonDisabled": true,
          "line": this.tableData[0]['line'],
          "currency": this.tableData[0]['currency'],
          "endTerm": "1825",
          "amount": this.totalamount,
          "tabletype": "Repos"
        },{
          "deleteDisabled": false,
          "initTerm": "1825",
          "Id": "1",
          "pickDisabled": false,
          "initRead": "true",
          "buttonDisabled": true,
          "line": this.tableData[0]['line'],
          "currency": this.tableData[0]['currency'],
          "endTerm": "16425",
          "amount": this.totalamount*0,
          "tabletype": "Repos"
        }];
      }
      else if(this.tableData[0]['tabletype'] === 'Equities'){
        guidanceData = [    {
          "deleteDisabled": true,
          "initTerm": "0",
          "Id": "0",
          "pickDisabled": true,
          "initRead": "true",
          "buttonDisabled": true,
          "line": this.tableData[0]['line'],
          "currency": this.tableData[0]['currency'],
          "endTerm": "1825",
          "amount": this.totalamount,
          "tabletype": "Equities"
        },{
          "deleteDisabled": false,
          "initTerm": "1825",
          "Id": "1",
          "pickDisabled": false,
          "initRead": "true",
          "buttonDisabled": true,
          "line": this.tableData[0]['line'],
          "currency": this.tableData[0]['currency'],
          "endTerm": "16425",
          "amount": this.totalamount*0,
          "tabletype": "Equities"
        }];
      }else{
        if (this.bookingGeography == 'CO' || this.bookingGeography == 'AR') {
          const intermediateTerm = this.bookingGeography == 'CO' ? '2555' : '2920';
          guidanceData = [    {
            "deleteDisabled": true,
            "initTerm": "0",
            "Id": "0",
            "pickDisabled": true,
            "initRead": "true",
            "buttonDisabled": true,
            "line": this.tableData[0]['line'],
            "currency": this.tableData[0]['currency'],
            "endTerm": "1095",
            "amount": this.totalamount,
            "tabletype": "Derivatives"
          },{
            "deleteDisabled": true,
            "initTerm": "1095",
            "Id": "1",
            "pickDisabled": true,
            "initRead": "true",
            "buttonDisabled": true,
            "line": this.tableData[0]['line'],
            "currency": this.tableData[0]['currency'],
            "endTerm": "1825",
            "amount": (this.totalamount*3)/4,
            "tabletype": "Derivatives"
          } ,{
            "deleteDisabled": true,
            "initTerm": "1825",
            "Id": "2",
            "pickDisabled": true,
            "initRead": "true",
            "buttonDisabled": true,
            "line": this.tableData[0]['line'],
            "currency": this.tableData[0]['currency'],
            "endTerm": intermediateTerm,
            "amount": this.totalamount/2,
            "tabletype": "Derivatives"
          },{
            "deleteDisabled": true,
            "initTerm": intermediateTerm,
            "Id": "3",
            "pickDisabled": true,
            "initRead": "true",
            "buttonDisabled": true,
            "line": this.tableData[0]['line'],
            "currency": this.tableData[0]['currency'],
            "endTerm": "3650",
            "amount": (this.totalamount*2.5)/10,
            "tabletype": "Derivatives"
          }]
        } else {
          guidanceData = [    {
            "deleteDisabled": true,
            "initTerm": "0",
            "Id": "0",
            "pickDisabled": true,
            "initRead": "true",
            "buttonDisabled": true,
            "line": this.tableData[0]['line'],
            "currency": this.tableData[0]['currency'],
            "endTerm": "1095",
            "amount": this.totalamount,
            "tabletype": "Derivatives"
          },{
            "deleteDisabled": true,
            "initTerm": "1095",
            "Id": "1",
            "pickDisabled": true,
            "initRead": "true",
            "buttonDisabled": true,
            "line": this.tableData[0]['line'],
            "currency": this.tableData[0]['currency'],
            "endTerm": "1825",
            "amount": (this.totalamount*3)/4,
            "tabletype": "Derivatives"
          },{
            "deleteDisabled": true,
            "initTerm": "1825",
            "Id": "2",
            "pickDisabled": true,
            "initRead": "true",
            "buttonDisabled": true,
            "line": this.tableData[0]['line'],
            "currency": this.tableData[0]['currency'],
            "endTerm": "2920",
            "amount": this.totalamount/2,
            "tabletype": "Derivatives"
          },{
            "deleteDisabled": true,
            "initTerm": "2920",
            "Id": "3",
            "pickDisabled": true,
            "initRead": "true",
            "buttonDisabled": true,
            "line": this.tableData[0]['line'],
            "currency": this.tableData[0]['currency'],
            "endTerm": "3650",
            "amount": (this.totalamount*3)/10,
            "tabletype": "Derivatives"
          },{
            "deleteDisabled": false,
            "initTerm": "3650",
            "Id": "4",
            "pickDisabled": false,
            "initRead": "true",
            "buttonDisabled": true,
            "line": this.tableData[0]['line'],
            "currency": this.tableData[0]['currency'],
            "endTerm": "16425",
            "amount": this.totalamount/5,
            "tabletype": "Derivatives"
          }];
        }
      }

      this.dispatchEvent(new CustomEvent('tableriskchange',  { bubbles:true, composed:true,detail:  {data:guidanceData, tabletype:guidanceData[0]['tabletype']}} ));
    }
  }

  // ─── Cell Change Handler ──────────────────────────────────────────────────
  handleTableClick(event) {
    const isEditButton = event.composedPath().some(element =>
      element?.tagName === 'BUTTON' && element.title?.toLowerCase().startsWith('edit')
    );

    if (isEditButton) {
      this.dispatchEvent(new CustomEvent('editstart'));
    }
  }

  handleChangeCell(event) {
    const draftValues = event.detail.draftValues || [];
    console.log('Draft Values:', JSON.stringify(draftValues));
    // Translate the edited display text back into the real numeric `amount` field.
    const normalizedDrafts = draftValues.map(draft => {
      if (Object.prototype.hasOwnProperty.call(draft, 'amount_display')) {
        const parsedAmount = this._parseAmountFromDisplay(draft.amount_display);
        const { amount_display, ...rest } = draft;
        return parsedAmount !== null ? { ...rest, amount: parsedAmount } : rest;
      }
      return draft;
    });

    console.log('Normalized Drafts:', JSON.stringify(normalizedDrafts));
    console.log('Current Draft Values Map:', JSON.stringify(this.draftValues));
    const draftsById = new Map(this.draftValues.map(draft => [String(draft.Id), { ...draft }]));
    normalizedDrafts.forEach(draft => {
      const key = String(draft.Id);
      draftsById.set(key, { ...draftsById.get(key), ...draft });
    });
    this.draftValues = Array.from(draftsById.values());

    if (normalizedDrafts.length > 0) {
      console.log('Updating table data with normalized drafts.');
      const updatedData = this.tableData.map(row => {
        const draft = draftsById.get(String(row.Id));
        return draft ? { ...row, ...draft } : row;
      });
      this.tableData = this.normalizeDisplayTerms(updatedData);
      console.log('Updated Table Data:', JSON.stringify(this.tableData));

      this.dispatchEvent(new CustomEvent('tableriskchange', {
        bubbles: true,
        composed: true,
        detail: { data: this.tableData, tabletype: this.resolvedTabletype }
      }));

      normalizedDrafts.forEach(draft => {
        if (draft.amount !== undefined && draft.amount !== null) {
          this.dispatchEvent(new CustomEvent('riskamountchange', {
            bubbles: true,
            composed: true,
            detail: {
              Id: draft.Id,
              amount: draft.amount
            }
          }));
        }
      });
    }
  }

  // ─── Save Handler ─────────────────────────────────────────────────────────
  handleSaveCell(event) {
    // Clear draft values after save (datatable will handle the UI update)
    this.draftValues = [];
  }

  // ─── Reset Draft Values (called by parent after data reload) ──────────────
  @api
  resetDraftValues() {
    this.draftValues = [];
    // Also try to clear the datatable's internal draft values
    const dataTable = this.template.querySelector('c-dmt-risk-limit-data-table');
    if (dataTable) {
      try {
        dataTable.draftValues = [];
      } catch (e) {
        console.warn('Could not directly clear datatable draftValues:', e);
      }
    }
  }

}