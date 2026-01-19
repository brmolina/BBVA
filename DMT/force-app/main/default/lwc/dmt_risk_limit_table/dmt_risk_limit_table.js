import { LightningElement,api } from 'lwc';
import {loadStyle } from 'lightning/platformResourceLoader';
import CustomDataTableResource from '@salesforce/resourceUrl/datatableOverrides';

export default class Dmt_risk_limit_table extends LightningElement {
    @api startDate;
    @api tabletype;
    @api totalamount;
    @api conversionLabel;
    currencyvalue;
    defaultLimitvalue;
    bookingGeography;
    tableData;


    connectedCallback(){
      loadStyle(this, CustomDataTableResource);
    }
    @api columnstablecopypaste = [];
    @api isReadOnlyUser;
    @api titletable;

    @api
    get table() {
      return this.tableData;
    }

    set table(value) {
      console.log('Original:', value); 
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
    
      console.log('Normalizado:', normalizedData);
    
      if (normalizedData.length > 0) {
        const newArray = normalizedData.map((item, index) => {
          const newItem = { ...item };
          newItem.isEditableAmount = !newItem.isDisabled;
          if (index === normalizedData.length - 1 && newItem.isDisabled != true) {
            newItem.buttonDisabled = false;
            newItem.pickDisabled = false;
            newItem.deleteDisabled = false;
          }
          return newItem;
        });
    
        this.tableData = newArray;
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
      if(value.toLowerCase() === 'true'){
        this.handledefaultLimit();
      }
    }

    @api
    get  bookingGeographyLine() {
      return this.bookingGeography;
    }
    set bookingGeographyLine(value) {
      this.bookingGeography = value;
    }

    @api
    get  currency() {
      return this.currencyvalue;
    }
    set currency(value) {
      this.columns = [{fieldName:"initTerm",label:"INIT TERM",type:"picklist",editable:true, hideDefaultActions:true,
        cellAttributes: { alignment: 'center' }, typeAttributes: {
          placeholder: 'Select...', options: this.termoptions, fieldName: 'initTerm' // list of all picklist options
          , value: { fieldName: 'initTerm' } // default value for picklist
          , context: { fieldName: 'Id' }, readonlyAttr : { fieldName: 'initRead' }, isDisabled : { fieldName: 'isDisabled' } 
      }},{fieldName:"endTerm",label:"END TERM",type:"picklist",editable:true, hideDefaultActions:true,
            cellAttributes: { alignment: 'center' }, typeAttributes: {
              placeholder: 'Select...', options: this.termoptions, fieldName: 'endTerm' // list of all picklist options
              , value: { fieldName: 'endTerm' } // default value for picklist
              , context: { fieldName: 'Id' } ,optionslimit: { fieldName: 'initTerm' }, readonlyAttr : { fieldName: 'pickDisabled' }, isDisabled : { fieldName: 'isDisabled' }  
          }},
        {fieldName:"amount",label:"AMOUNT", type: 'currency',editable: { fieldName: 'isEditableAmount' } , hideDefaultActions:true,
            cellAttributes: { alignment: 'center' } , typeAttributes: { currencyCode: value, step: '0.001' }},
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

    }
    
    termoptions = [{ label: 'Select...', value: '' },{label:"0D",value:"0"},{label:"2D",value:"2"},{label:"3D",value:"3"},{label:"4D",value:"4"},{label:"7D",value:"7"},{label:"10D",value:"10"},{label:"15D",value:"15"},{label:"20D",value:"20"},{label:"1M",value:"30"},{label:"45D",value:"45"},{label:"2M",value:"60"},{label:"3M",value:"90"},{label:"4M",value:"120"},{label:"5M",value:"150"},{label:"6M",value:"180"},{label:"9M",value:"270"},{label:"1Y",value:"365"},{label:"18M",value:"548"},{label:"2Y",value:"730"},{label:"3Y",value:"1095"},{label:"4Y",value:"1460"},{label:"5Y",value:"1825"},{label:"6Y",value:"2190"},{label:"7Y",value:"2555"},{label:"8Y",value:"2920"},{label:"9Y",value:"3285"},{label:"10Y",value:"3650"},{label:"11Y",value:"4015"},{label:"12Y",value:"4380"},{label:"13Y",value:"4745"},{label:"14Y",value:"5110"},{label:"15Y",value:"5475"},{label:"16Y",value:"5840"},{label:"17Y",value:"6205"},{label:"18Y",value:"6570"},{label:"19Y",value:"6935"},{label:"20Y",value:"7300"},{label:"21Y",value:"7665"},{label:"22Y",value:"8030"},{label:"25Y",value:"9125"},{label:"27Y",value:"9855"},{label:"30Y",value:"10950"},{label:"32Y",value:"11680"},{label:"35Y",value:"12775"},{label:"37Y",value:"13505"},{label:"40Y",value:"14600"},{label:"42Y",value:"15330"},{label:"45Y",value:"16425"}];
    columns = [{fieldName:"initTerm",label:"INIT TERM",type:"picklist",editable:true, hideDefaultActions:true,
        cellAttributes: { alignment: 'center' }, typeAttributes: {
          placeholder: 'Select..', options: this.termoptions, fieldName: 'initTerm' // list of all picklist options
          , value: { fieldName: 'initTerm' } // default value for picklist
          , context: { fieldName: 'Id' }, readonlyAttr : { fieldName: 'initRead' } 
      }},{fieldName:"endTerm",label:"END TERM",type:"picklist",editable:true, hideDefaultActions:true,
            cellAttributes: { alignment: 'center' }, typeAttributes: {
              placeholder: 'Select...', options: this.termoptions, fieldName: 'endTerm' // list of all picklist options
              , value: { fieldName: 'endTerm' } // default value for picklist
              , context: { fieldName: 'Id' } ,optionslimit: { fieldName: 'initTerm' }, readonlyAttr : { fieldName: 'pickDisabled' } 
          }},
        {fieldName:"amount",label:"AMOUNT", type: 'currency',editable:true, hideDefaultActions:true,
            cellAttributes: { alignment: 'center' } , typeAttributes: { currencyCode: this.currency, step: '0.001' }},
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

    /*renderedCallback(){
      if(this.table && this.table[0] && this.table[this.table.length -1]['buttonDisabled'] && this.table[this.table.length -1]['endTerm'] !== "" && this.table[0]){
        let copyData = this.copiarLista(this.table);
        copyData[copyData.length - 1]['buttonDisabled'] = false;
        copyData[copyData.length - 1]['pickDisabled'] = false;
        if(copyData.length > 1){
          copyData[copyData.length - 1]['deleteDisabled'] = false;
        } else {
          copyData[copyData.length - 1]['deleteDisabled'] = true;
        }
        this.dispatchEvent(new CustomEvent('tableRiskinit',  { bubbles:true, composed:true,detail:{data:copyData, tabletype:copyData[0]['tabletype']}} ));
      } /*else if (this.table && this.table[0]) {
        let copyData = this.copiarLista(this.table);
        copyData[0]['deleteDisabled'] = true;
        this.table = JSON.parse(JSON.stringify(copyData));
        //this.dispatchEvent(new CustomEvent('tableRiskinit',  { bubbles:true, composed:true,detail:{data:copyData, tabletype:copyData[0]['tabletype']}} ));
      }
    }*/

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        switch (action.name) {
            case 'deleteRecord':
                const tableType = this.tableData[0]['tabletype'];
                
                if (this.tableData.length === 1) {
                  this.totalamount = '';

                  const resetRow = {
                    ...this.tableData[0],
                    totalamount: '',
                    initTerm: "0",
                    endTerm: "2",
                    amount: null,
                    deleteDisabled: false,
                    buttonDisabled: false
                  };

                  const newTable = [resetRow];

                  this.dispatchEvent(new CustomEvent('tableRiskchange', {
                    bubbles: true,
                    composed: true,
                    detail: {
                      data: newTable,
                      tabletype: tableType
                    }
                }));
                } else {
                let copyData = this.tableData.filter(function(item) {
                    return item.Id !== row.Id
                })
                let sendcopyData = this.copiarLista(copyData);
                if(sendcopyData[0]){
                  sendcopyData[sendcopyData.length-1]['buttonDisabled'] = false;
                  sendcopyData[sendcopyData.length-1]['pickDisabled'] = false;
                  sendcopyData[sendcopyData.length-1]['deleteDisabled'] = false;
                }

                  this.dispatchEvent(new CustomEvent('tableRiskchange',  { 
                    bubbles:true, 
                    composed:true,
                    detail:{
                      data:sendcopyData, 
                      tabletype:tableType
                    }
                  }));
                }
                break;
            case 'addRecord':
              const index = this.tableData.findIndex(dataRow => dataRow.Id === row.Id);
              let copyDataNew = [
                ...this.tableData.slice(0, index+1),
                {
                  "initTerm": this.tableData[index]["endTerm"],
                  "endTerm": "",
                  "Id": this.tableData.length,
                  "amount": null,
                  "initRead":true,
                  "tabletype":this.tableData[index]["tabletype"],
                  "line":this.tableData[0]["line"],
                  "currency":this.tableData[0]["currency"],
                  "deleteDisabled": false,
                  'buttonDisabled':true
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
            this.dispatchEvent(new CustomEvent('tableRiskchange',  { bubbles:true, composed:true,detail:  {data:sendcopyDataNew, tabletype:sendcopyDataNew[0]['tabletype']}} ));
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
      this.dispatchEvent(new CustomEvent('tableRiskchange',  { bubbles:true, composed:true,detail:  {data:copyData, tabletype:copyData[0]['tabletype']}} ));
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

  handleChangeCell(event){
    let dataRecieved = event.detail.draftValues;
    let updatedItem;
        updatedItem = { Id: dataRecieved[0].Id, amount: dataRecieved[0].amount };
    //this.updateDraftValues(updatedItem);
    this.updateDataValues(updatedItem);
  }

  handledefaultLimit(){
    var guidanceData;
    if(this.tableData !== undefined)
    {
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

      this.dispatchEvent(new CustomEvent('tableRiskchange',  { bubbles:true, composed:true,detail:  {data:guidanceData, tabletype:guidanceData[0]['tabletype']}} ));
    }
  }

}