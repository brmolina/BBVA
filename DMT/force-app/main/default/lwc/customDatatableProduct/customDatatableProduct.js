import { LightningElement, track, api, wire } from 'lwc';
import buttonClass from "./customDatatableProduct.css";

export default class CustomDatatableProduct extends LightningElement {

    tableData;
    productOptions;
    maxTenorOptions;
    columns;
    addProductRes;
    @api tableType;
    //have this attribute to track data changed
    //with custom picklist or custom lookup
    @track draftValues = [];
    @api
    get  addProduct() {
      return this.addProductRes;
    }
  
    set addProduct(value) {
        console.log("buttonClass buttonClass "+ buttonClass);
        if(value.toLowerCase() === 'true'){
           this.addNewProduct();

        }
      this.addProductRes = 'false';
    }
    @api
    get  tableDataName() {
      return this.tableData;
    }
  
    set tableDataName(value) {
        console.log("tableData ds5555a "+ JSON.stringify(value));
      this.tableData = value;
      this.setColumns();
    }

    @api
    get  productOptionsName() {
      return this.productOptions;
    }
  
    set productOptionsName(value) {
      this.productOptions = value;
      this.setColumns();
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
    this.columns = [
        { label: 'PRODUCT TYPE', fieldName: 'Product_Code__c', type:'picklist',hideDefaultActions:true , typeAttributes: {
            placeholder: 'Select...', options: this.productOptions, fieldName: 'Product_Code__c' // list of all picklist options
            , value: { fieldName: 'Product_Code__c' } // default value for picklist
            , context: { fieldName: 'Id' } // binding account Id with context variable to be returned back
        }},
        { label: 'MAX TENOR WITHOUT CLEARING', fieldName: 'Max_Tenor_WOC__c', type:'picklist',hideDefaultActions:true, typeAttributes: {
            placeholder: 'Select..', options: this.maxTenorOptions, fieldName: 'Max_Tenor_WOC__c' // list of all picklist options
            , value: { fieldName: 'Max_Tenor_WOC__c' } // default value for picklist
            , context: { fieldName: 'Id' } // binding account Id with context variable to be returned back
        }},
        { label: 'MAX TENOR WITH CLEARING', fieldName: 'Max_Tenor_WC__c', type:'picklist',hideDefaultActions:true, typeAttributes: {
            placeholder: 'Select...', options: this.maxTenorOptions, fieldName: 'Max_Tenor_WC__c' // list of all picklist options
            , value: { fieldName: 'Max_Tenor_WC__c' } // default value for picklist
            , context: { fieldName: 'Id' } // binding account Id with context variable to be returned back
        }},
        {
            type:  'button',
            initialWidth: 90,hideDefaultActions:true,
            cellAttributes: { alignment: 'center' },
            typeAttributes: 
            {
              iconName: 'utility:delete',
              iconClass: buttonClass,
              label: ' ', 
              name: 'deleteRecord', 
              title: '', 
              disabled: false,
              iconPosition: 'center', 
              value: 'test'
            }
          }
          ,
        {
            type:  'button',
            initialWidth: 90,hideDefaultActions:true,
            cellAttributes: { alignment: 'center' },
            typeAttributes: 
            {
              iconName: 'utility:add',
              iconClass: buttonClass,
              label: '    ', 
              name: 'addRecord', 
              title: '        ', 
              disabled: false,
              iconPosition: 'center', 
              value: 'test'
            }
          }
    ];
    if (this.tableType === 'interveners'){
      [
        { label: 'INTERVENER', fieldName: 'userName', type:'searchCombobox',hideDefaultActions:true , typeAttributes: {
          pickListOrdered: this.pickListOrdered, selectedSearchResult: this.selectedSearchResult}},
        { label: 'MAX TENOR WITH CLEARING', fieldName: 'Max_Tenor_WC__c', type:'picklist',hideDefaultActions:true, typeAttributes: {
            placeholder: 'Select...', options: this.maxTenorOptions, fieldName: 'Max_Tenor_WC__c' // list of all picklist options
            , value: { fieldName: 'Max_Tenor_WC__c' } // default value for picklist
            , context: { fieldName: 'Id' } // binding account Id with context variable to be returned back
        }},
        {
            type:  'button',
            initialWidth: 90,hideDefaultActions:true,
            cellAttributes: { alignment: 'center' },
            typeAttributes: 
            {
              iconName: 'utility:delete',
              iconClass: buttonClass,
              label: ' ', 
              name: 'deleteRecord', 
              title: '', 
              disabled: false,
              iconPosition: 'center', 
              value: 'test'
            }
          }
          ,
        {
            type:  'button',
            initialWidth: 90,hideDefaultActions:true,
            cellAttributes: { alignment: 'center' },
            typeAttributes: 
            {
              iconName: 'utility:add',
              iconClass: buttonClass,
              label: '    ', 
              name: 'addRecord', 
              title: '        ', 
              disabled: false,
              iconPosition: 'center', 
              value: 'test'
            }
          }
    ];
    }
}
    connectedCallback() {
        

        //sample data
        // this.data = [{ 'Id': '12345', 'productType': 'codeFX', 'maxTenorWC': '1Y', 'maxTenorWOC': '1Y' }, { 'Id': '4321', 'productType': 'codeE', 'maxTenorWC': '5Y', 'maxTenorWOC': '1Y' }]
        //save last saved copy
        //this.lastSavedData = JSON.parse(JSON.stringify(this.tableData));
    }

    updateDataValues(updateItem) {
        let copyData = this.copiarLista(this.tableData);
        copyData.forEach(item => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
            }
        });

        //write changes back to original data
        this.dispatchEvent(new CustomEvent('tableProductChanges',  { bubbles:true, composed:true,detail:  copyData} ));
    }

    updateDraftValues(updateItem) {
        let draftValueChanged = false;
        let copyDraftValues = [...this.draftValues];console.log('updateItemJSONONO',JSON.stringify(updateItem))
        //store changed value to do operations
        //on save. This will enable inline editing &
        //show standard cancel & save button
        copyDraftValues.forEach(item => {
            if (item.Id === updateItem.Id) {console.log('dentrooooooo',JSON.stringify(updateItem))
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
        let dataRecieved = event.detail.data;console.log('dataRecievedjson',JSON.stringify(dataRecieved));
        let updatedItem;
        if( dataRecieved.fieldname === 'Product_Code__c'){
            updatedItem = { Id: dataRecieved.context, Product_Code__c: dataRecieved.value };
        }else if(dataRecieved.fieldname === 'Max_Tenor_WC__c'){
            updatedItem = { Id: dataRecieved.context, Max_Tenor_WC__c: dataRecieved.value };
        }
        else{
            updatedItem = { Id: dataRecieved.context, Max_Tenor_WOC__c: dataRecieved.value };
        }console.log('updatedItemdvdv',JSON.stringify(updatedItem));
        //this.updateDraftValues(updatedItem);
        this.updateDataValues(updatedItem);
    }

    //handler to handle cell changes & update values in draft values
    handleCellChange(event) {
        this.updateDraftValues(event.detail.draftValues[0]);
    }

    handleSave(event) {
        console.log('Updated items', this.draftValues);
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
        const row = event.detail.row;console.log('event',JSON.stringify(event.detail));console.log('row',row)
        switch (action.name) {
            case 'deleteRecord':
                let copyData = this.tableData.filter(function(item) {
                    return item.Id !== row.Id
                })
                this.dispatchEvent(new CustomEvent('deleteProduct',  { bubbles:true, composed:true,detail:  copyData} ));console.log('deleteRecord',copyData);
                break;
            case 'addRecord':
              const index = this.tableData.findIndex(dataRow => dataRow.Id === row.Id);console.log('index',index);
              let copyDataNew = [
                ...this.tableData.slice(0, index+1),
                {
                  "Max_Tenor_WOC__c": "",
                  "Line__c": "",
                  "Id": index+1,
                  "Max_Tenor_WC__c": "",
                  "Product_Code__c": ""
                },
                ...this.tableData.slice(index+1)
            ];
            this.dispatchEvent(new CustomEvent('tableProductChanges',  { bubbles:true, composed:true,detail:  copyDataNew} ));console.log('addRecord',copyDataNew);
                break;
        }
    }

    addNewProduct(){console.log('adne')
        let copyData = this.copiarLista(this.tableData);
        let nextId = copyData.length + 1;
        copyData.push({
            "Max_Tenor_WOC__c": "",
            "Line__c": "",
            "Id": nextId.toString() ,
            "Max_Tenor_WC__c": "",
            "Product_Code__c": ""
          });console.log('copyData',copyData)
          this.dispatchEvent(new CustomEvent('tableProductChanges',  { bubbles:true, composed:true,detail:  copyData} ));
    }
}