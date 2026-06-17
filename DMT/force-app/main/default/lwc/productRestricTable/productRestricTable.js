import { LightningElement, track, api, wire } from 'lwc';
//import hiddenCell from "./productRestricTable.css";
import DMT_Styles from "@salesforce/resourceUrl/DMT_Styles";
import { loadStyle } from "lightning/platformResourceLoader";
import TITLE_TABLE from '@salesforce/label/c.dmt_cl_OperationalRestrc_Text';
import dataTableWithoutTruncate from '@salesforce/resourceUrl/DataTableTruncateCss';

export default class ProductRestricTable extends LightningElement {

    tableData;
    bookingGeography;
    productOptions;
    maxTenorOptions;
    @track columns;
    allColumns;
    @api columnstablecopypaste = []
    @api isReadOnlyUser;
    labels = {
        TITLE_TABLE,
    };


    addProductRes;
    visible = ['','','','','','','','slds-hidden','slds-hidden'];
    termoptions = [{label:"", value:""},{label:"0D",value:"0"},{label:"2D",value:"2"},{label:"3D",value:"3"},{label:"4D",value:"4"},{label:"7D",value:"7"},{label:"10D",value:"10"},{label:"15D",value:"15"},{label:"20D",value:"20"},{label:"1M",value:"30"},{label:"45D",value:"45"},{label:"2M",value:"60"},{label:"3M",value:"90"},{label:"4M",value:"120"},{label:"5M",value:"150"},{label:"6M",value:"180"},{label:"9M",value:"270"},{label:"1Y",value:"365"},{label:"18M",value:"548"},{label:"2Y",value:"730"},{label:"3Y",value:"1095"},{label:"4Y",value:"1460"},{label:"5Y",value:"1825"},{label:"6Y",value:"2190"},{label:"7Y",value:"2555"},{label:"8Y",value:"2920"},{label:"9Y",value:"3285"},{label:"10Y",value:"3650"},{label:"11Y",value:"4015"},{label:"12Y",value:"4380"},{label:"13Y",value:"4745"},{label:"14Y",value:"5110"},{label:"15Y",value:"5475"},{label:"16Y",value:"5840"},{label:"17Y",value:"6205"},{label:"18Y",value:"6570"},{label:"19Y",value:"6935"},{label:"20Y",value:"7300"},{label:"21Y",value:"7665"},{label:"22Y",value:"8030"},{label:"25Y",value:"9125"},{label:"27Y",value:"9855"},{label:"30Y",value:"10950"},{label:"32Y",value:"11680"},{label:"35Y",value:"12775"},{label:"37Y",value:"13505"},{label:"40Y",value:"14600"},{label:"42Y",value:"15330"},{label:"45Y",value:"16425"}];
    @api tableType;
    //have this attribute to track data changed
    //with custom picklist or custom lookup
    @track draftValues = [];
    dvpAmountvalue;
    @api
    get  dvpAmount() {
      return this.dvpAmountvalue;
    }
    set dvpAmount(value) {
      this.dvpAmountvalue = value;
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
        //console.log("buttonClass buttonClass "+ buttonClass);
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
        //console.log("tableData ds5555a "+ JSON.stringify(value));
      this.tableData = value;
      if (this.bookingGeography) {
        this.checkProductsByGeography();
        this.setColumns();
      }
    }

    // @api
    // get  productOptionsName() {
    //   return this.productOptions;
    // }
  
    // set productOptionsName(value) {
    //   this.productOptions = value;
    //   this.setColumns();
    // }

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
        this.allColumns = [
          { label: 'PRODUCT GROUP', fieldName: 'products',  type: 'url',
            typeAttributes: {
              label: { fieldName: 'products' },
              tooltip: { fieldName: 'title' },
          }, cellAttributes:{
            alignment: "left",
            class: "dmt-datatable-url",
          }
          ,hideDefaultActions:true ,editable: false},
          { label: 'DERIVATIVES LINE', fieldName: 'derivativesLine', type:'customselectRow',hideDefaultActions:true, cellAttributes:{style: 'text-align: center;'},
            typeAttributes: {
              aviableItem: {fieldName: 'derivativesEdit'}, checkedItem: { fieldName: 'derivativesLine' }, fieldName: 'derivativesLine', context: { fieldName: 'Id' }
          }},
          { label: 'MATURITY TERM', fieldName: 'maxTerm', hidden: { fieldName: 'MTDisabled' }, type:'picklist',hideDefaultActions:true, typeAttributes: { isDisabled : { fieldName: 'isDisabled' },
              placeholder: 'Select...', options: this.termoptions, fieldName: 'maxTerm' // list of all picklist options
              , value: { fieldName: 'maxTerm' } // default value for picklist
              , context: { fieldName: 'Id' } // binding account Id with context variable to be returned back
          },cellAttributes:{class: {fieldName:'deriVisible'}}},
          { label: 'FD LINE: ' +this.fdAmount, hidden:{ fieldName: 'FDDisabled' }, fieldName: 'lineFD', type:'customselectRow',hideDefaultActions:true ,cellAttributes:{style: 'text-align: center;'},
            typeAttributes: {
              aviableItem: {fieldName: 'FDEdit'}, checkedItem: { fieldName: 'lineFD' }, fieldName: 'lineFD', context: { fieldName: 'Id' }
            }},
          { label: 'DVP LINE: ' +this.dvpAmount, hidden: { fieldName: 'DVPDisabled' }, fieldName: 'lineDVP', type:'customselectRow',hideDefaultActions:true,cellAttributes:{style: 'text-align: center;'},
            typeAttributes: {
              aviableItem: {fieldName: 'DVPEdit'}, checkedItem: { fieldName: 'lineDVP' }, fieldName: 'lineDVP', context: { fieldName: 'Id' }
          }}
      ];

        if (!this.tableData || this.tableData.length === 0) {
            this.columns = this.allColumns.filter(col => !col.hidden);
            return;
        }

        this.columns = this.allColumns.filter(col => {
            if (!col.hidden) {
                return true; 
            }

            const fieldToCheck = col.hidden.fieldName;

          
            const shouldBeHidden = this.tableData.every(row => {
                
                return !!row[fieldToCheck]; 
            });


            return !shouldBeHidden;
        });
      this.columns = [...this.columns];
    
}
    renderedCallback() {

      Promise.all([loadStyle(this, DMT_Styles)])
      .then(() => {
          console.log("Static Resource Loaded");
      })
      .catch(error => {
          console.log("error-", error);
      });
    }
    connectedCallback() {
        
      loadStyle(this, dataTableWithoutTruncate);

        //sample data
        // this.data = [{ 'Id': '12345', 'productType': 'codeFX', 'maxTenorWC': '1Y', 'maxTenorWOC': '1Y' }, { 'Id': '4321', 'productType': 'codeE', 'maxTenorWC': '5Y', 'maxTenorWOC': '1Y' }]
        //save last saved copy
        //this.lastSavedData = JSON.parse(JSON.stringify(this.tableData));
    }

    updateDataValues(updateItem) {//console.log('updateitem',updateItem)
        let copyData = this.copiarLista(this.tableData);
        copyData.forEach(item => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];//console.log('updateItem[field]',updateItem[field])
                    let productsValue = this.tableData.filter(dataRow => dataRow["Id"] == updateItem['Id'])[0]['productsValue'];
                    if(field == 'derivativesLine' && updateItem[field]){
                      if(item['FDEdit'] && item['FDdependentDerivatives']){
                        item['lineFD'] = true;
                      }
                      if(item['DVPEdit'] && item['DVPdependentDerivatives']){
                        item['lineDVP'] = true;
                      }

                     }
                    
                    if(field == 'derivativesLine' && this.bookingGeography == 'ES' && (productsValue == 'REPA' || productsValue == 'REAC')){
                      item['lineFD'] = updateItem[field];
                      item['lineDVP'] = updateItem[field];
                    }
                    if(productsValue == 'FOEX' && this.bookingGeography == 'MX' && field == 'derivativesLine'){
                       //item['lineFD'] = updateItem[field];
                       item['lineDVP'] = updateItem[field];
                     }
                      //if(item['lineFD'] && this.fdAmountvalue.replace(/\D/g, "") == 0){//console.log('fdAmountvalue',this.fdAmountvalue.replace(/\D/g, ""))
                      if(item['lineFD'] && this.fdAmountvalue == 0){
                        item['setAttentionFD'] = 'slds-theme_error';
                      }
                      if(item['lineDVP'] && this.dvpAmountvalue == 0){
                        item['setAttentionDVP'] = 'slds-theme_error';
                      }
                }
            }
        });
        //console.log('copyData',JSON.stringify(copyData))
        //write changes back to original data
        this.dispatchEvent(new CustomEvent('tableProductChanges',  { bubbles:true, composed:true,detail:  copyData} ));
    }

    updateDraftValues(updateItem) {
        let draftValueChanged = false;
        let copyDraftValues = [...this.draftValues];//console.log('updateItemJSONONO',JSON.stringify(updateItem))
        //store changed value to do operations
        //on save. This will enable inline editing &
        //show standard cancel & save button
        copyDraftValues.forEach(item => {
            if (item.Id === updateItem.Id) {//console.log('dentrooooooo',JSON.stringify(updateItem))
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
        updatedItem = { Id: dataRecieved.context, maxTerm: dataRecieved.value };
        //console.log('updatedItemdvdv',JSON.stringify(updatedItem));
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
    handleCellChange(event) {
        this.updateDataValues(event.detail.draftValues[0]);
        this.updateDraftValues(event.detail.draftValues[0]);
    }

    handleSave(event) {
        //console.log('Updated items', this.draftValues);
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

    //   handleRowAction(event) {
    //     const action = event.detail.action;
    //     const row = event.detail.row;console.log('event',JSON.stringify(event.detail));console.log('row',row)
    //     switch (action.name) {
    //         case 'deleteRecord':
    //             let copyData = this.tableData.filter(function(item) {
    //                 return item.Id !== row.Id
    //             })
    //             this.dispatchEvent(new CustomEvent('deleteProduct',  { bubbles:true, composed:true,detail:  copyData} ));console.log('deleteRecord',copyData);
    //             break;
    //         case 'addRecord':
    //           const index = this.tableData.findIndex(dataRow => dataRow.Id === row.Id);console.log('index',index);
    //           let copyDataNew = [
    //             ...this.tableData.slice(0, index+1),
    //             {
    //               "Max_Tenor_WOC__c": "",
    //               "Line__c": "",
    //               "Id": index+1,
    //               "Max_Tenor_WC__c": "",
    //               "Product_Code__c": ""
    //             },
    //             ...this.tableData.slice(index+1)
    //         ];
    //         this.dispatchEvent(new CustomEvent('tableProductChanges',  { bubbles:true, composed:true,detail:  copyDataNew} ));console.log('addRecord',copyDataNew);
    //             break;
    //     }
    // }

    addNewProduct(){//console.log('adne')
        let copyData = this.copiarLista(this.tableData);
        let nextId = copyData.length + 1;
        copyData.push({
            "Max_Tenor_WOC__c": "",
            "Line__c": "",
            "Id": nextId.toString() ,
            "Max_Tenor_WC__c": "",
            "Product_Code__c": ""
          });//console.log('copyData',copyData)
          this.dispatchEvent(new CustomEvent('tableProductChanges',  { bubbles:true, composed:true,detail:  copyData} ));
    }

    checkProductsByGeography() {

      
      this.tableData = this.tableData.map((item) => ({
          ...item,
          derivativesEdit: item.isDisabled ? false : item.derivativesEdit,
          DVPEdit: item.isDisabled ? false : item.DVPEdit,
          FDEdit: item.isDisabled ? false : item.FDEdit
      }));


    }

    removeProductsFromTableData() {
      let tableDataAux = JSON.parse(JSON.stringify(this.tableData));
      
      for (let i = 0; i < arguments.length; i++) {
        let productCode = arguments[i];
        const index = tableDataAux.findIndex((item) => item.productsValue == productCode);
        if (index != -1) {
            tableDataAux.splice(index, 1);
        }
      }
      this.tableData = JSON.parse(JSON.stringify(tableDataAux));
    }
}