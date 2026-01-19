import { LightningElement, api, track } from 'lwc';
import TITLE_TABLE from '@salesforce/label/c.dmt_cl_OneOffTransaction_Text';

export default class Dmt_singular_treasury extends LightningElement {

    tableData;
    bookingGeography;
    productOptions;
    maxTenorOptions;
    columns;
    labels = {
        TITLE_TABLE,
    };
    addProductRes;
    visible = ['','','','','','','','slds-hidden','slds-hidden'];
    termoptions = [{label:"0D",value:"0"},{label:"2D",value:"2"},{label:"3D",value:"3"},{label:"4D",value:"4"},{label:"7D",value:"7"},{label:"10D",value:"10"},{label:"15D",value:"15"},{label:"20D",value:"20"},{label:"1M",value:"30"},{label:"45D",value:"45"},{label:"2M",value:"60"},{label:"3M",value:"90"},{label:"4M",value:"120"},{label:"5M",value:"150"},{label:"6M",value:"180"},{label:"9M",value:"270"},{label:"1Y",value:"365"},{label:"18M",value:"548"},{label:"2Y",value:"730"},{label:"3Y",value:"1095"},{label:"4Y",value:"1460"},{label:"5Y",value:"1825"},{label:"6Y",value:"2190"},{label:"7Y",value:"2555"},{label:"8Y",value:"2920"},{label:"9Y",value:"3285"},{label:"10Y",value:"3650"},{label:"11Y",value:"4015"},{label:"12Y",value:"4380"},{label:"13Y",value:"4745"},{label:"14Y",value:"5110"},{label:"15Y",value:"5475"},{label:"16Y",value:"5840"},{label:"17Y",value:"6205"},{label:"18Y",value:"6570"},{label:"19Y",value:"6935"},{label:"20Y",value:"7300"},{label:"21Y",value:"7665"},{label:"22Y",value:"8030"},{label:"25Y",value:"9125"},{label:"27Y",value:"9855"},{label:"30Y",value:"10950"},{label:"32Y",value:"11680"},{label:"35Y",value:"12775"},{label:"37Y",value:"13505"},{label:"40Y",value:"14600"},{label:"42Y",value:"15330"},{label:"45Y",value:"16425"}];
    @api tableType;
    //have this attribute to track data changed
    //with custom picklist or custom lookup
    @track draftValues = [];
    dvpAmountvalue;
    @api columnstablecopypaste = [];
    @api isReadOnlyUser;
    @api
    get  singularCon() {
      return this.singularConvalue;
    }
    set singularCon(value) {
      this.singularConvalue = value;
      this.setColumns();
    }
    fdAmountvalue;
    @api
    get  fdAmount() {
      return this.fdAmountvalue;
    }
  
    set fdAmount(value) {
      this.fdAmountvalue = value;
      this.setColumns();
    }
    
    @api
    get  addProduct() {
      return this.addProductRes;
    }
  
    set addProduct(value) {
        if(value.toLowerCase() === 'true'){
           this.addNewProduct();

        }
      this.addProductRes = 'false';
    }

    @api
    get  bookingGeographyLine() {
      return this.bookingGeography;
    }
  
    set bookingGeographyLine(value) {
      this.bookingGeography = value;
      if (this.tableData) {
        this.checkProductsByGeography();
        this.setColumns();
      }
    }


    @api
    get  tableDataName() {
      return this.tableData;
    }

    
  set tableDataName(value) {

    // 🔍 Normalización segura
    let normalizedData;

    try {
      // Si viene como string, intentar parsear
      if (typeof value === 'string') {
        const parsed = JSON.parse(value);
        if (Array.isArray(parsed)) {
          normalizedData = parsed;
        } else if (typeof parsed === 'object' && parsed !== null) {
          normalizedData = [parsed];
        } else {
          normalizedData = [];
        }
     }
      // Si ya es array, filtrar que sean objetos válidos
      else if (Array.isArray(value)) {
        normalizedData = value.filter(item => typeof item === 'object' && item !== null);
      }
      // Si es un solo objeto
      else if (typeof value === 'object' && value !== null) {
        normalizedData = [value];
      } else {
        console.warn('Formato inesperado para tableData:', value);
        normalizedData = [];
      }
    } catch (e) {
      console.error('Error al procesar tableData:', e);
      normalizedData = [];
    }

    if (normalizedData.length > 0) {
      const newArray = normalizedData.map((item, index) => {
        const newItem = { ...item };
        newItem.isEditableField = !newItem.isDisabled;
        newItem.buttonDisabled = true;
        newItem.pickDisabled = true;
        newItem.deleteDisabled = true;
        if (index === normalizedData.length - 1 && newItem.isDisabled != true) {
          newItem.buttonDisabled = false;
          newItem.pickDisabled = false;
          newItem.deleteDisabled = normalizedData.length === 1;
        }
        return newItem;
      });
      this.tableData = newArray;
    } else {
      this.tableData = [];
    }

    // Asignación segura
    //this.tableData = normalizedData;

    if (this.bookingGeography) {
      this.checkProductsByGeography();
      this.setColumns();
    }
}

    @api
    get  maxTenorOptionsName() {
      return this.maxTenorOptions;
    }
    set maxTenorOptionsName(value) {
      this.maxTenorOptions = value;
      this.setColumns();
    }

    lastSavedData = [];
    setColumns(){
      //Due to sonar issue, the if estructure has been commented because doing the same logic in both cases
      if (this.bookingGeography == 'AR') {
      this.columns = [
          { label: 'TRANSACTION', fieldName: 'DMT_Singular_Operation__c', type:'text',hideDefaultActions:true ,editable: {fieldName:'isEditableField'}},
          { label: 'DERIVATIVES AMOUNT', fieldName: 'amount', type:'currency',hideDefaultActions:true,editable: {fieldName:'isEditableField'}, cellAttributes:{style: 'text-align: center;'},
            typeAttributes: { currencyCode: {fieldName:'currency'} }},
            { label: 'DVP AMOUNT', fieldName: 'DMT_Singular_DvP__c', type:'currency',hideDefaultActions:true,editable: {fieldName:'isEditableField'}, cellAttributes:{style: 'text-align: center;'},
            typeAttributes: { currencyCode: {fieldName:'currency'} }},
          { label: 'TERM', fieldName: 'endTerm', type:'picklist',hideDefaultActions:true, typeAttributes: {isDisabled : true,
              placeholder: 'Select...', options: this.termoptions, fieldName: 'endTerm', wrapText:true, editable: false // list of all picklist options
              , value: { fieldName: 'endTerm' } // default value for picklist
              , context: { fieldName: 'Id' } // binding account Id with context variable to be returned back
          },cellAttributes:{class: {fieldName:'deriVisible'}}},
          { label: 'MAX DATE', fieldName: 'maxDate', type:'date-local',hideDefaultActions:true ,editable:  {fieldName:'isEditableField'}, cellAttributes:{style: 'text-align: center;'},
           typeAttributes: {
             day: "2-digit",
             month: "2-digit",
             year: "2-digit"
         }
            },
          { label: 'ACTIVE', fieldName: 'active', type:'boolean',hideDefaultActions:true,cellAttributes:{style: 'text-align: center;'},editable:false
            },
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
            }
      ];
    }else {
        this.columns = [
          { label: 'TRANSACTION', fieldName: 'DMT_Singular_Operation__c', type:'text',hideDefaultActions:true ,editable: {fieldName:'isEditableField'}},
          { label: 'DERIVATIVES AMOUNT', fieldName: 'amount', type:'currency',hideDefaultActions:true,editable: {fieldName:'isEditableField'}, cellAttributes:{style: 'text-align: center;'},
            typeAttributes: { currencyCode: {fieldName:'currency'} }},
            { label: 'DVP AMOUNT', fieldName: 'DMT_Singular_DvP__c', type:'currency',hideDefaultActions:true,editable: {fieldName:'isEditableField'}, cellAttributes:{style: 'text-align: center;'},
            typeAttributes: { currencyCode: {fieldName:'currency'} }},
            { label: 'FD AMOUNT', fieldName: 'DMT_Singular_FD__c', type:'currency',hideDefaultActions:true,editable: {fieldName:'isEditableField'}, cellAttributes:{style: 'text-align: center;'},
            typeAttributes: { currencyCode: {fieldName:'currency'} }},
          { label: 'TERM', fieldName: 'endTerm', type:'picklist',hideDefaultActions:true, typeAttributes: {isDisabled : true,
              placeholder: 'Select...', options: this.termoptions, fieldName: 'endTerm', wrapText:true, editable: false // list of all picklist options
              , value: { fieldName: 'endTerm' } // default value for picklist
              , context: { fieldName: 'Id' } // binding account Id with context variable to be returned back
          },cellAttributes:{class: {fieldName:'deriVisible'}}},
          { label: 'MAX DATE', fieldName: 'maxDate', type:'date-local',hideDefaultActions:true ,editable:  {fieldName:'isEditableField'}, cellAttributes:{style: 'text-align: center;'},
           typeAttributes: {
             day: "2-digit",
             month: "2-digit",
             year: "2-digit"
         }
            },
          { label: 'ACTIVE', fieldName: 'active', type:'boolean',hideDefaultActions:true,cellAttributes:{style: 'text-align: center;'},editable:false
            },
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
            }
      ];
      } 
    }
    renderedCallback() {
        
      if(this.tableData && this.tableData[0] && this.tableData[this.tableData.length -1]['buttonDisabled'] && this.tableData[this.tableData.length -1]['endTerm'] !== ""){
        let copyData = this.copiarLista(this.tableData);
        copyData[copyData.length - 1]['buttonDisabled'] = false;
        copyData[copyData.length - 1]['pickDisabled'] = false;
        
        //if(this.tableData.length > 1){
          copyData[copyData.length - 1]['deleteDisabled'] = false;
          copyData[0]['deleteDisabled'] = true;
        //}
        this.dispatchEvent(new CustomEvent('tableSingularConInit',  { bubbles:true, composed:true,detail:copyData} ));
      }
    }

    updateDataValues(updateItem) {
        let copyData = this.copiarLista(this.tableData);console.log('todayprev')
         copyData.forEach(item => {
             if (item.Id.toString() === updateItem.Id.toString()) {
                 for (let field in updateItem) {
                    item[field] = updateItem[field];
                    if (field === 'maxDate') {
                        const today = new Date();console.log('today', today);console.log('updateItem[field] term', updateItem[field])
                        var dateSelected = new Date(updateItem[field]);console.log('endt[field] term', dateSelected - today)
                        item['endTerm'] = this.getNextGridValue(Math.ceil((dateSelected - today) / (3600*1000*24)).toString(),this.termoptions);console.log('endt term', item['endTerm'])
                    }

                 }
             }
         });
        this.dispatchEvent(new CustomEvent('tableSingularCon',  { bubbles:true, composed:true,detail:  copyData} ));
    }

    getNextGridValue(inputValue, options) {
    const inputNumber = Number(inputValue);

    // Ordenamos por value numérico
    const sortedOptions = [...options].sort(
        (a, b) => Number(a.value) - Number(b.value)
    );

    // Buscamos el siguiente value válido
    const nextOption = sortedOptions.find(
        opt => Number(opt.value) > inputNumber
    );

    // Devuelve string o el último valor permitido
    return nextOption ? nextOption.value : sortedOptions[sortedOptions.length - 1].value;
}


    updateDraftValues(updateItem) {
        let draftValueChanged = false;
        let copyDraftValues = [...this.draftValues];
        //store changed value to do operations
        //on save. This will enable inline editing &
        //show standard cancel & save button
        copyDraftValues.forEach(item => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
                draftValueChanged = true;
            }
        });

        if (draftValueChanged) {
            this.draftValues = [...copyDraftValues];
        } else {
            this.draftValues = [...copyDraftValues, updateItem];
        }
    }

    //listener handler to get the context and data
    //updates datatable
    picklistChanged(event) {
        event.stopPropagation();
        let dataRecieved = event.detail.data;
        let updatedItem;
        updatedItem = { Id: dataRecieved.context, endTerm: dataRecieved.value };
        //this.updateDraftValues(updatedItem);
        this.updateDataValues(updatedItem);
    }

    selectedRowChanged(event) {
      event.stopPropagation();
      let dataRecieved = event.detail.data;
      let updatedItem;
      updatedItem = { Id: dataRecieved.context};
      updatedItem[dataRecieved.fieldname]= dataRecieved.value;
      //this.updateDraftValues(updatedItem);
      this.updateDataValues(updatedItem);
  }

    //handler to handle cell changes & update values in draft values
    handleCellChange(event) {console.log('handle cell change')
        this.updateDataValues(event.detail.draftValues[0]);
        this.updateDraftValues(event.detail.draftValues[0]);
    }

    handleSave(event) {
        //save last saved copy
        this.lastSavedData = JSON.parse(JSON.stringify(this.tableData));
    }

    handleCancel(event) {
        //remove draftValues & revert tableData changes
        this.tableData = JSON.parse(JSON.stringify(this.lastSavedtableData));
        this.draftValues = [];
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

      handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        switch (action.name) {
            case 'deleteRecord':
                const tableType = this.tableData[0]['tabletype'];
                let copyData = this.tableData.filter(function(item) {
                    return item.Id !== row.Id
                })
                let sendcopyData = this.copiarLista(copyData);
                if(sendcopyData[0]){
                  sendcopyData[sendcopyData.length-1]['buttonDisabled'] = false;
                  sendcopyData[sendcopyData.length-1]['pickDisabled'] = false;
                  sendcopyData[sendcopyData.length-1]['deleteDisabled'] = false;
                  sendcopyData[0]['buttonDisabled'] = true;
                  
                }
                //if(sendcopyData.length == 1){
                  sendcopyData[0]['deleteDisabled']= true;
                //}
                this.dispatchEvent(new CustomEvent('tableSingularCon',  { bubbles:true, composed:true,detail:sendcopyData} ));
                break;
            case 'addRecord':
              const index = this.tableData.findIndex(dataRow => dataRow.Id === row.Id);
              let copyDataNew = [
                ...this.tableData.slice(0, index+1),
                {
                  "initTerm": 0,
                  "endTerm": "",
                  "DMT_Singular__c":true,
                  "DMT_Singular_Operation__c": "",
                  "maxDate": "",
                  "Id": this.tableData.length,
                  "amount": 0,
                  "initRead":true,
                  "tabletype":this.tableData[index]["tabletype"],
                  "line": this.tableData[0]["line"],
                  "currency": this.tableData[0]["currency"],
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
              sendcopyDataNew[sendcopyDataNew.length-2]['deleteDisabled'] = true;
              sendcopyDataNew[sendcopyDataNew.length-1]['deleteDisabled'] = false;
            this.dispatchEvent(new CustomEvent('tableSingularCon',  { bubbles:true, composed:true,detail: sendcopyDataNew} ));
                break;
        }
    }

    addNewProduct(){
        let copyData = this.copiarLista(this.tableData);
        let nextId = copyData.length + 1;
        copyData.push({
            "Max_Tenor_WOC__c": "",
            "Line__c": "",
            "Id": nextId.toString() ,
            "Max_Tenor_WC__c": "",
            "Product_Code__c": ""
          });
          this.dispatchEvent(new CustomEvent('tableProductChanges',  { bubbles:true, composed:true,detail:  copyData} ));
    }

    checkProductsByGeography() {
      if (this.bookingGeography == 'CO') {
        this.removeProductsFromTableData('DBIC','REAC', 'REPA', 'EQSP');
      } else if (this.bookingGeography == 'PE') {
        this.removeProductsFromTableData('DBIC');
      }
    }

    removeProductsFromTableData() {
      if (!Array.isArray(this.tableData)) {
        console.error('this.tableData no es un array en removeProductsFromTableData:', this.tableData);
        return;
      }
    
      let tableDataAux = JSON.parse(JSON.stringify(this.tableData));
    
      for (let i = 0; i < arguments.length; i++) {
        let productCode = arguments[i];
        const index = tableDataAux.findIndex((item) => item.productsValue == productCode);
        if (index !== -1) {
            tableDataAux.splice(index, 1);
        }
      }
    
      this.tableData = JSON.parse(JSON.stringify(tableDataAux));
    }

}