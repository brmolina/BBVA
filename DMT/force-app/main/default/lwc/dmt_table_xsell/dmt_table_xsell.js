import { LightningElement,api } from 'lwc';

export default class Dmt_table_xsell extends LightningElement {
  
    @api tabletype;
    @api totalamount;
    @api conversionLabel;
    @api idListToDelete = [];
    @api isEditMode=false;
    @api isEditState=false;
    @api oppState;
    @api columnstablecopypaste = [];
    _isReadOnlyUser = false;
    
    /*get isEditMode() {
      return this.isEditMode;
    }
    set isEditMode(value) {
      let isEditBool = (value === 'true') ? true
                : (value === 'false') ? false
                : value;
      let isEditModeAux = (isEditBool === true || isEditBool === false)
                ? !isEditBool
                : true;
      if(isEditModeAux){
        this.setColumnsEdit()

      }
      
      return isEditModeAux;
    }*/
    @api 
    get isReadOnlyUser(){ 
      return this._isReadOnlyUser; 
    } 
    set isReadOnlyUser(value){
        if (value === 'true') {
              this._isReadOnlyUser = true; 
        }else if (value === 'false') { 
            this._isReadOnlyUser = false;
        }else if (typeof value === 'boolean') {
          this._isReadOnlyUser = value;
        }else {
              this._isReadOnlyUser = Boolean(value); 
        } 
    }
    opportunityvalue;
    currencyvalue;
    defaultLimitvalue;
    bookingGeography;
    tableData;
    
    @api
    get currency() {
      return this.currencyvalue;
    }
    set currency(value) {
      console.log('Set currency value: ' + value)
      console.log('this.currencyvalue before: ' + this.currencyvalue)
      const previusvalue = this.currencyvalue;
      console.log('this.previesvalue: ' + previusvalue)
      this.currencyvalue = value;
      console.log('this.currencyvalue after: ' + this.currencyvalue)
     

      console.log(this.table);
      const updatedColumns = this.columns.map(col => {
        if (col.fieldName === 'g_notional_amount__c') {
          return {
            ...col,
            typeAttributes: {
              ...col.typeAttributes,
              currencyCode: value
            }
          };
        }
        return col;
      });
      
    this.columns = updatedColumns;
    console.log(this.columns)
    this.table = this.tableData;
    if(previusvalue && this.currency != this.previusvalue){
      this.isEditMode = true;
      this.columns = [
                  {
                    fieldName:"Year__c",
                    label:"YEAR",
                    type: this.isEditMode ? "custominputRow": "text",
                    editable:false,
                    hideDefaultActions:true,
                    cellAttributes:
                    {
                      alignment: 'center'
                    },
                    typeAttributes:
                    {
                      value: { fieldName: 'Year__c'},
                      inputValue: { fieldName: 'Year__c'},
                      context: { fieldName: 'Id' }
                    }
                  },
                  {
                    fieldName:"g_notional_amount__c",
                    label:"NOTIONAL AMOUNT",
                    type: this.isEditMode ? "custominputRow" : 'currency',
                    editable:false,
                    hideDefaultActions:true,
                    cellAttributes:
                    {
                      alignment: 'center'
                    },
                    typeAttributes:
                    {
                      currencyCode: this.currency,
                      step: '0.001',
                      value: { fieldName: 'g_notional_amount__c'},
                      inputValue: { fieldName: 'g_notional_amount__c'},
                      context: { fieldName: 'Id' }
                    }
                  },
                  {
                    type: 'button',
                    hideDefaultActions:true,
                    cellAttributes:
                    {
                      alignment: 'center'
                    },
                    initialWidth: 60,
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
                  },
                  {
                    type: 'button',
                    hideDefaultActions:true,
                    cellAttributes:
                    {
                      alignment: 'center'
                    },
                    initialWidth: 60,
                    typeAttributes: 
                    {
                      iconName: 'utility:edit',
                      label: ' ', 
                      name: 'editRecord', 
                      title: '', 
                      disabled: {fieldName: 'editRecordDisabled'},
                      iconPosition: 'center', 
                      value: 'test'
                    }
                  },
                  {
                    type: 'button',
                    hideDefaultActions:true,
                    cellAttributes:
                    {
                      alignment: 'center'
                    },
                    initialWidth: 60,
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
                  }
                ];
    }
    console.log('this.table');
    
     this.setColumnsEdit()
    }

    @api
    get opportunity() {
      return this.opportunityvalue;
    }
    set opportunity(value) {
      console.log('this.opportunityvalue before: ' + this.opportunityvalue)
      console.log('Set opp value: ' + value)
      this.opportunityvalue = value;
      console.log('this.opportunityvalue after: ' + this.opportunityvalue)
    }
    
    @api
    get table() {
      return this.tableData;
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
          console.log('normalizedData1: ' + normalizedData)
                    console.log('value: ' + normalizedData)

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
            console.log('AML0');
      let isEditBool = (this.isEditMode == 'true') ? true
                : (this.isEditMode == 'false') ? false
                : this.isEditMode;
        this.isEditMode = (isEditBool === true)
                ? true :  (isEditBool === false) ? false :  this.isEditMode

      console.log('isEditBool: ' + isEditBool);
      console.log('this.isEditMode: ' + this.isEditMode);
      console.log('normalizedData:', JSON.stringify(normalizedData, null, 2));
      console.log('AML1');
      console.log('currencyJuan: ', this.currencyvalue);
      console.log('opportunityJuan: ', this.opportunityvalue);
      if (normalizedData.length > 0) {
        const newArray = normalizedData.map((item, index) => {
          const newItem = { ...item };
          if (index === normalizedData.length - 1) {
            console.log('this.isReadOnlyUser ' +this.isReadOnlyUser);
            newItem.buttonDisabled = this.isReadOnlyUser == this.oppState == 'Draft' || this.oppState == 'Ready to close' ? false : true
            newItem.editRecordDisabled = this.isReadOnlyUser == this.oppState == 'Draft' || this.oppState == 'Ready to close' ? false : true
            newItem.deleteDisabled = this.isReadOnlyUser == this.oppState == 'Draft' || this.oppState == 'Ready to close' ? false : true
            //newItem.deleteDisabled = newItem.g_currency__c == null;
            if (!newItem.Id) {
              newItem.Id = "0";
              newItem.g_currency__c = this.currencyvalue;
              newItem.opportunity =  this.opportunityvalue;
              if(newItem.Id == '0' &&  newItem.g_notional_amount__c == null && newItem.Year__c == null && this.isEditMode){
                console.log('····Row.id 0')
                const currentYear = new Date().getFullYear();
                newItem.Year__c = currentYear.toString();
              }
            }
            newItem.deleteDisabled = newItem.g_currency__c = null;

          }
           newItem.buttonDisabled = this.oppState == 'Draft' || this.oppState == 'Ready to close' ? false : true
            newItem.editRecordDisabled = this.oppState == 'Draft'|| this.oppState == 'Ready to close' ? false : true
            newItem.deleteDisabled = this.oppState == 'Draft' || this.oppState == 'Ready to close'? false : true
          newItem.g_currency__c = this.currencyvalue;
          console.log(item)
          console.log('editRecordDisabled get Table--> ' + newItem.editRecordDisabled);
          return newItem;
        });
        const tempNewArray = this.tableData;
        this.tableData = newArray;
        if(tempNewArray != newArray){
          /*this.dispatchEvent(new CustomEvent('tableRiskchange', {
            bubbles: true,
            composed: true,
            detail: {
              data: this.tableData,
              tabletype: this.tableData[0]?.tabletype || ''
            }
          }));*/
        }
        
      } else {
        this.tableData = [];
      }
      
         

        this.setColumnsEdit()

      
    }
    
    @api
    get  defaultLimit() {
      return this.defaultLimitvalue;
    }
    set defaultLimit(value) {
      this.defaultLimitvalue = value;
      if(value.toLowerCase() === 'true'){
        this.handledefaultLimit();
      }
    }
    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        switch (action.name) {
            case 'editRecord':
                console.log('typeof this.isEditMode -->' +typeof this.isEditMode);
                if(typeof this.isEditMode == 'string'){      
                    let isEditBool = (this.isEditMode == 'true') ? true
                    : (this.isEditMode == 'false') ? false
                    : this.isEditMode;
                    this.isEditMode = (isEditBool === true || isEditBool === false)
                    ? !isEditBool
                    : true;
                    console.log('Edit 1');
                    console.log('editModeTable: ' + this.isEditMode);
                    this.dispatchEvent(new CustomEvent('editModeTable',  { bubbles:true, composed:true,detail:{ editmodetable:this.isEditMode}} ));
                    console.log('Edit 2')
                    this.setColumnsEdit()
              }
                break;
            case 'deleteRecord':
                console.log('Delete 0')
                if(typeof this.idListToDelete == 'string'){
                  this.idListToDelete = []
                }
                console.log(this.idListToDelete)

                this.idListToDelete = [...this.idListToDelete, row.Id];

                const tableType = this.tableData[0]['tabletype'];
                let copyData = this.tableData.filter(function(item) {
                    return item.Id !== row.Id
                })
                console.log('Delete  2')
                let sendcopyData = this.copiarLista(copyData);
                if(sendcopyData[0]){
                  sendcopyData[sendcopyData.length-1]['buttonDisabled'] = false;
                  sendcopyData[sendcopyData.length-1]['pickDisabled'] = false;
                  sendcopyData[sendcopyData.length-1]['deleteDisabled'] = false;
                  sendcopyData[0]['buttonDisabled'] = true;
                  
                }
                console.log('this.sendcopyData: ' + JSON.stringify(sendcopyData))
                console.log('Delete  3')
                if(sendcopyData.length == 0){
                  
                  const newItem = new Object();;
                  newItem.buttonDisabled = false;
                  newItem.pickDisabled = false;
                  newItem.Id = "0";
                  newItem.g_currency__c = this.currencyvalue;
                  newItem.opportunity =  this.opportunityvalue;                      
                  newItem.deleteDisabled = newItem.g_currency__c = null;
                  newItem.g_currency__c = this.currencyvalue;
                  
                  sendcopyData.push(newItem);
                  console.log('this.sendcopyData996: '+ sendcopyData)
                          }
                this.dispatchEvent(new CustomEvent('tableRiskchange',  { bubbles:true, composed:true,detail:{data:sendcopyData, tabletype:tableType, idlistdelete:this.idListToDelete}} ));
                this.isEditMode = true;
                              this.setColumnsEdit()

            this.dispatchEvent(new CustomEvent('editModeTable',  { bubbles:true, composed:true,detail:{ editmodetable:this.isEditMode}} ));

                break;
            case 'addRecord':
              const index = this.tableData.findIndex(dataRow => dataRow.Id === row.Id);
              let copyDataNew;
              let sendcopyDataNew;
              if(row.Id == '0' &&  row.g_notional_amount__c == null && row.Year__c == null){
                console.log('····Row.id 0')
                const currentYear = new Date().getFullYear();
                const tablelenght = this.tableData.length;
                copyDataNew = [
                {
                  "Year__c": currentYear.toString(),
                  "Id": tablelenght.toString(),
                  "g_notional_amount__c": 0,
                  "g_currency__c":this.currencyvalue,
                  "initRead":true,
                  "tabletype":'Derivatives',
                  "opportunity":this.opportunityvalue,
                  "deleteDisabled": this.oppState == 'Draft' || this.oppState == 'Ready to close'? false : true,
                  'buttonDisabled': this.oppState == 'Draft' || this.oppState == 'Ready to close'? false : true 
                }
              ];
              }else{
                let yearString = this.tableData[index]["Year__c"];
                let yearAsInteger = parseInt(yearString);
                let nextYear = yearAsInteger + 1;
                let nextYearString = nextYear.toString();
              const tablelenght = this.tableData.length +1;

                copyDataNew = [
                  ...this.tableData.slice(0, index+1),
                  {
                    "Year__c": nextYearString,
                    "Id": tablelenght.toString(),
                    "g_notional_amount__c": 0,
                    "g_currency__c":this.tableData[0]["g_currency__c"],
                    "initRead":true,
                    "tabletype":this.tableData[index]["tabletype"],
                    "opportunity":this.tableData[0]["opportunity"],
                    "deleteDisabled": false,
                    'buttonDisabled':true
                  },
                  ...this.tableData.slice(index+1)
                ];
                sendcopyDataNew = this.copiarLista(copyDataNew);
                sendcopyDataNew[sendcopyDataNew.length-2]['buttonDisabled'] = true;
                sendcopyDataNew[sendcopyDataNew.length-1]['buttonDisabled'] = true;
                sendcopyDataNew[sendcopyDataNew.length-2]['pickDisabled'] = true;
                sendcopyDataNew[sendcopyDataNew.length-1]['pickDisabled'] = false;
                sendcopyDataNew[sendcopyDataNew.length-2]['deleteDisabled'] = true;
                sendcopyDataNew[sendcopyDataNew.length-1]['deleteDisabled'] = false;
              }
              this.setColumnsEdit()
              this.isEditMode = true;
            this.dispatchEvent(new CustomEvent('editModeTable',  { bubbles:true, composed:true,detail:{ editmodetable:this.isEditMode}} ));
            this.dispatchEvent(new CustomEvent('tableRiskchange',  { bubbles:true, composed:true,detail:  {data:sendcopyDataNew?sendcopyDataNew:copyDataNew, tabletype:sendcopyDataNew?sendcopyDataNew[0]['tabletype']:copyDataNew[0]['tabletype'], idlistdelete:this.idListToDelete}} ));
            

            break;
        }
    }
    setColumnsEdit(){
      this.columns = [
                  {
                    fieldName:"Year__c",
                    label:"YEAR",
                    type: this.isEditMode ? "custominputRow": "text",
                    editable:false,
                    hideDefaultActions:true,
                    cellAttributes:
                    {
                      alignment: 'center'
                    },
                    typeAttributes:
                    {
                      value: { fieldName: 'Year__c'},
                      inputValue: { fieldName: 'Year__c'},
                      fieldName: 'Year__c',

                      context: { fieldName: 'Id' }
                    }
                  },
                  {
                    fieldName:"g_notional_amount__c",
                    label:"NOTIONAL AMOUNT",
                    type: this.isEditMode ? "custominputRow" : 'currency',
                    editable:false,
                    hideDefaultActions:true,
                    cellAttributes:
                    {
                      alignment: 'center'
                    },
                    typeAttributes:
                    {
                      currencyCode: this.currency,
                      step: '0.001',
                      value: { fieldName: 'g_notional_amount__c'},
                      inputValue: { fieldName: 'g_notional_amount__c'},
                      context: { fieldName: 'Id' },
                      fieldName: 'g_notional_amount__c',

                    }
                  },
                  {
                    type: 'button',
                    hideDefaultActions:true,
                    cellAttributes:
                    {
                      alignment: 'center'
                    },
                    initialWidth: 60,
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
                  },
                  {
                    type: 'button',
                    hideDefaultActions:true,
                    cellAttributes:
                    {
                      alignment: 'center'
                    },
                    initialWidth: 60,
                    typeAttributes: 
                    {
                      iconName: 'utility:edit',
                      label: ' ', 
                      name: 'editRecord', 
                      title: '', 
                      disabled: {fieldName: 'editRecordDisabled'},
                      iconPosition: 'center', 
                      value: 'test'
                    }
                  },
                  {
                    type: 'button',
                    hideDefaultActions:true,
                    cellAttributes:
                    {
                      alignment: 'center'
                    },
                    initialWidth: 60,
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
                  }
                ];
    }
    picklistChanged(event) {
      console.log('PicklistChanged');
      event.stopPropagation();
      let dataRecieved = event.detail.data;
      let updatedItem;
      // Comentado por error SONAR
      /*if( dataRecieved.fieldname === 'Year__c'){
          updatedItem = { Id: dataRecieved.context, Year__c: dataRecieved.value ? dataRecieved.value : dataRecieved.inputValue};
      }else{
          updatedItem = { Id: dataRecieved.context, Year__c: dataRecieved.value ? dataRecieved.value : dataRecieved.inputValue};
      }*/
      updatedItem = { Id: dataRecieved.context, Year__c: dataRecieved.value ? dataRecieved.value : dataRecieved.inputValue};
      //this.updateDraftValues(updatedItem);
      this.updateDataValues(updatedItem);

  }

    /*updateDataValues(updateItem) {
      let copyData = this.copiarLista(this.tableData);
      console.log('copyData:', JSON.stringify(copyData, null, 2));
      console.log('updateItem:', JSON.stringify(updateItem, null, 2));
      copyData.forEach(item => {
            if (item.Id.toString() === updateItem.Id.toString()) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
            }
      });
      copyData[copyData.length-1]['buttonDisabled'] = false;
      this.dispatchEvent(new CustomEvent('tableRiskchange',  { bubbles:true, composed:true,detail:  {data:copyData, tabletype:copyData[0]['tabletype']}} ));
  }

  updateDataValues(updateItem) {
      let copyData = this.copiarLista(this.tableData);
      console.log('copyData:', JSON.stringify(copyData, null, 2));
      console.log('updateItem:', JSON.stringify(updateItem, null, 2));
      const indexToUpdate = copyData.findIndex(item => item.Id === updateItem.Id);
      if (indexToUpdate !== -1) {
        copyData[indexToUpdate] = {
          ...copyData[indexToUpdate],
          ...updateItem 
        };
      }
      
      copyData[copyData.length-1]['buttonDisabled'] = false;
      this.tableData = copyData;
      this.dispatchEvent(new CustomEvent('tableRiskchange',  { bubbles:true, composed:true,detail:  {data:copyData, tabletype:copyData[0]['tabletype']}} ));
  }*/

  updateDataValues(updateItem) {
    let copyData = this.copiarLista(this.tableData);
    console.log('copyData2:', JSON.stringify(copyData, null, 2));
    console.log('updateItem2:', JSON.stringify(updateItem, null, 2));

    const indexToUpdate = copyData.findIndex(item => item.Id === updateItem.Id);

    if (indexToUpdate !== -1) {
      // Merge fields while preserving existing data
      for (let key in updateItem) {
        if (updateItem[key] !== undefined) {
          copyData[indexToUpdate][key] = updateItem[key];
        }
      }
    }

    // Ensure the last row allows adding
    if (copyData.length > 0) {
      copyData[copyData.length - 1]['buttonDisabled'] = false;
    }

    this.tableData = copyData;

    this.dispatchEvent(new CustomEvent('tableRiskchange', {
      bubbles: true,
      composed: true,
      detail: {
        data: copyData,
        tabletype: copyData[0]?.tabletype || '',
         idlistdelete:this.idListToDelete
      }
      
    }));
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

  /*
  handleChangeCell(event){
    let dataRecieved = event.detail.draftValues;
    console.log('dataRecieved:', JSON.stringify(dataRecieved, null, 2));
    let updatedItem;
        updatedItem = { Id: dataRecieved[0].Id, Year__c: dataRecieved[0].Year__c, g_notional_amount__c: dataRecieved[0].g_notional_amount__c };
    this.updateDataValues(updatedItem);
  }*/

  handleChangeCell(event) {
    let dataRecieved = event.detail.draftValues[0];
    console.log('dataRecieved:', JSON.stringify(dataRecieved, null, 2));

    const updatedItem = { Id: dataRecieved.Id };

    if ('Year__c' in dataRecieved) {
      updatedItem.Year__c = dataRecieved.Year__c;
    }

    if ('g_notional_amount__c' in dataRecieved) {
      updatedItem.g_notional_amount__c = dataRecieved.g_notional_amount__c;
    }

    this.updateDataValues(updatedItem);
  }
  textInputChanged(event) {
      let dataRecieved = event.detail.data;
      console.log('dataRecieved: ' + JSON.stringify(dataRecieved))
      let updatedItem;
      updatedItem = { Id: dataRecieved.context};
      updatedItem[dataRecieved.fieldname]= dataRecieved.value;
      this.updateDataValues(updatedItem);
    }
  handledefaultLimit(){
    var guidanceData;
    if(this.tableData !== undefined)
    {
      if(this.tableData[0]['tabletype'] === 'Derivatives'){
        guidanceData = [    {
          "deleteDisabled": true,
          "Year__c": "2026",
          "Id": "0",
          "pickDisabled": true,
          "initRead": "true",
          "buttonDisabled": true,
          "line": this.tableData[0]['line'],
          "g_notional_amount__c": this.totalamount,
          "tabletype": "Derivatives"
        },{
            "deleteDisabled": true,
            "Year__c": "2026",
            "Id": "1",
            "pickDisabled": true,
            "initRead": "true",
            "buttonDisabled": true,
            "line": this.tableData[0]['line'],
            "g_notional_amount__c": (this.totalamount*3)/4,
            "tabletype": "Derivatives"
          } ,{
            "deleteDisabled": true,
            "Year__c": "2026",
            "Id": "2",
            "pickDisabled": true,
            "initRead": "true",
            "buttonDisabled": true,
            "line": this.tableData[0]['line'],
            "g_notional_amount__c": this.totalamount/2,
            "tabletype": "Derivatives"
          },{
            "deleteDisabled": true,
            "Year__c": "2026",
            "Id": "3",
            "pickDisabled": true,
            "initRead": "true",
            "buttonDisabled": true,
            "line": this.tableData[0]['line'],
            "g_notional_amount__c": (this.totalamount*2.5)/10,
            "tabletype": "Derivatives"
          }];
      }
      this.dispatchEvent(new CustomEvent('tableRiskchange',  { bubbles:true, composed:true,detail:  {data:guidanceData, tabletype:guidanceData[0]['tabletype'], idlistdelete:this.idListToDelete}} ));
    }
  }
  columns = [
      {
        fieldName:"Year__c",
        label:"YEAR",
        type: this.isEditMode ? "custominputRow": "text",
        editable:false,
        hideDefaultActions:true,
        cellAttributes:
        {
          alignment: 'center'
        },
        typeAttributes:
        {
          value: { fieldName: 'Year__c'},
          context: { fieldName: 'Id' }
        }
      },
      {
        fieldName:"g_notional_amount__c",
        label:"NOTIONAL AMOUNT",
        type: this.isEditMode ? "custominputRow" : 'currency',
        editable:false,
        hideDefaultActions:true,
        cellAttributes:
        {
          alignment: 'center'
        },
        typeAttributes:
        {
          currencyCode: this.currency,
          step: '0.001'
        }
      },
      {
        type: 'button',
        hideDefaultActions:true,
        cellAttributes:
        {
          alignment: 'center'
        },
        initialWidth: 60,
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
      },
      {
        type: 'button',
        hideDefaultActions:true,
        cellAttributes:
        {
          alignment: 'center'
        },
        initialWidth: 60,
        typeAttributes: 
        {
          iconName: 'utility:edit',
          label: ' ', 
          name: 'editRecord', 
          title: '', 
          disabled: {fieldName: 'editRecordDisabled'},
          iconPosition: 'center', 
          value: 'test'
        }
      },
      {
        type: 'button',
        hideDefaultActions:true,
        cellAttributes:
        {
          alignment: 'center'
        },
        initialWidth: 60,
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
      }
    ];
}