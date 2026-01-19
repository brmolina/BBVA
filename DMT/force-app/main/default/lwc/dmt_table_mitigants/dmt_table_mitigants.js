import { LightningElement,api,wire  } from 'lwc';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import EXTERNAL_RATING from "@salesforce/schema/DMT_Opportunity_Mitigant__c.External_Rating__c";
import CURRENCYISOCODE_FIELD from "@salesforce/schema/DMT_Opportunity_Mitigant__c.CurrencyIsoCode";
import getCurrencyValues from '@salesforce/apex/DMT_MitigantsController.getCurrencyValues';
import TITLETABLE from '@salesforce/label/c.dmt_cl_Collateral_Guarantees_Text';

const DEFAULT_RT = "012000000000000AAA";
const COLUMN_WIDTHS = {
    EndDate: 140,
    CurrencyIsoCode: 85,
    Mitigant_Type__c: 270,
    Country_Guarantor__c: 270,
    Commercial_Percentage__c: 165,
    Political_Percentage__c: 145,
    External_Rating__c: 95,
    Internal_Rating__c: 95,
    Liquidation_Period__c: 115,
    deleteButton: 60,
    editButton: 60,
    addButton: 60
};

const MITIGANS_COLUMN_WIDTHS = {
    EndDate: 140,
    CurrencyIsoCode: 90,
    Mitigant_Type__c: 270,
    Country_Guarantor__c: 270,
    Commercial_Percentage__c: 160,
    Political_Percentage__c: 140,
    External_Rating__c: 100,
    Internal_Rating__c: 100,
    Liquidation_Period__c: 160,
    deleteButton: 60,
    editButton: 60,
    addButton: 60
};

export default class Dmt_table_mitigants extends LightningElement { 
  externalRatingOptions;
  CurrencyIsoCode;
  validValues = ['O2', 'O4', 'O6', 'P2', 'P31' , 'P32'];
  validValuesLabelPersonal = ['Others > Guarantee in favour of Public Administration', 'Others > ECA Guarantor (Exporte Credit agency)', 'Others > Shared maintenance clause', 
    'Personal > Parent guarantee',  'Personal > Corporate', 'Personal > Bank'];
  validValuesLabelReal = ['Real > Mortgage guarantee','Real > Cash','Real > Gold Bullion','Real > Debt securities','Real > Debt securities issued by central governments or central Banks',
    'Real > Receivables','Real > Index equities and Index convertible bonds','Real > Securitisation','Real > Others real']
  labels = {
    TITLETABLE,
};
  @api columnstablecopypaste = [];
  termoptionsData = []
  @api set termoptions(value){
    this.termoptionsData = value;
  }
  get termoptions(){
    console.log('ABS '+ JSON.stringify(this.termoptionsData));
    return this.termoptionsData
  }
  internalRatingsData = [];
  @api
  get internalRatings() {
      return this.internalRatingsData;
  }
  set internalRatings(value) {
      this.internalRatingsData = value;
  }
  get internalRatingOptions() {
      if (!Array.isArray(this.internalRatingsData)) {
          return [];
      }
      return this.internalRatingsData
          .slice().sort((a, b) => a.label.localeCompare(b.label)).map(item => ({label: item.label, value: item.value}));
  }

   countryOptionsData = [];
  @api
  get countryOptions() {
      return this.countryOptionsData;
  }
  set countryOptions(value) {
      this.countryOptionsData = value;
  }
  get countryOptionsVal() {
      if (!Array.isArray(this.countryOptionsData)) {
          return [];
      }
      return this.countryOptionsData
          .slice().sort((a, b) => a.label.localeCompare(b.label)).map(item => ({label: item.label, value: item.value}));
  }




  @wire(getPicklistValues, { recordTypeId: DEFAULT_RT, fieldApiName: EXTERNAL_RATING })
  picklistResults({ error, data }) {
    if (data) {
      this.externalRatingOptions = data.values;
      this.error = null;
    } else if (error) {
      this.error = error;
      this.ratings = null;
    }
  }
  @wire(getCurrencyValues)
  wiredCurrencies({ error, data }) {
      if (data) {
          this.CurrencyIsoCode = data.map(item => ({
              label: item,   
              value: item
          }));
          this.error = null;
      } else if (error) {
          this.error = error;
          this.CurrencyIsoCode = [];
      }
    }

  columns = [
        {
          fieldName: 'End_Date__c',
          label: 'DATE',
          type: this.editModeTableMitigans ? 'customdateRow' : 'date',
          editable:false,
          initialWidth : MITIGANS_COLUMN_WIDTHS.EndDate,
          hideDefaultActions:true,
          cellAttributes:{style: 'text-align: center;'},
          typeAttributes: {            
              aviableItem: {fieldName: 'aviableItem'},
              dateValue: { fieldName: 'End_Date__c' },
              fieldName: 'End_Date__c',
              value: { fieldName: 'End_Date__c' },
              context: { fieldName: 'Id' }
          }
        },
        {
            fieldName:"CurrencyIsoCode",
            label:"CURRENCY",
            type: this.editModeTableMitigans ? "picklist": "text",
            editable:false,
            initialWidth : MITIGANS_COLUMN_WIDTHS.CurrencyIsoCode,
            hideDefaultActions:true,
            cellAttributes: { alignment: 'center' },
            typeAttributes: {
                placeholder: 'Select..',
                options: this.CurrencyIsoCode,
                fieldName: 'CurrencyIsoCode',
                value: { fieldName: 'CurrencyIsoCode' }, 
                context: { fieldName: 'Id' }
            }
        },
        {
            fieldName:"Mitigant_Type__c",
            label:"MITIGANT TYPE",
            type: this.editModeTableMitigans ? "picklist": "text",
            editable:false,
            hideDefaultActions:true,
            initialWidth : MITIGANS_COLUMN_WIDTHS.Mitigant_Type__c,
            cellAttributes: { alignment: 'center' },
            typeAttributes: {
                placeholder: 'Select..',
                options: this.termoptionsData,
                fieldName: 'Mitigant_Type__c',
                value: { fieldName: 'Mitigant_Type__c' }, 
                context: { fieldName: 'Id' }
            }
        },
        {
            fieldName:"DMT_Country_Guarantor__c",
            label:"COUNTRY GUARANTOR",
            type: this.editModeTableMitigans ? "picklist": "text",
            editable:false,
            hideDefaultActions:true,
            initialWidth : MITIGANS_COLUMN_WIDTHS.Country_Guarantor__c,
            cellAttributes: { alignment: 'center' },
            typeAttributes: {
                placeholder: 'Select..',
                options: this.countryOptionsVal,
                fieldName: 'DMT_Country_Guarantor__c',
                value: { fieldName: 'DMT_Country_Guarantor__c' }, 
                context: { fieldName: 'Id' }
            }
        },
        {
            fieldName:"Commercial_Percentage__c",
            label:"COMMERCIAL RISK (%)",
            type: this.editModeTableMitigans ? "custominputRow": 'percent-fixed',
            editable:false,
            initialWidth: MITIGANS_COLUMN_WIDTHS.Commercial_Percentage__c,
            hideDefaultActions:true,
            cellAttributes:{ alignment: 'center' },
            typeAttributes:{
                step: '0.001',
                aviableItem: {fieldName: true},
                inputValue: { fieldName: 'Commercial_Percentage__c' },
                fieldName: 'Commercial_Percentage__c',
                context: { fieldName: 'Id' },
                value: { fieldName: 'Commercial_Percentage__c' }
            }
        },
        {
            fieldName:"Political_Percentage__c",
            label:"POLITICAL RISK (%)",
            type: this.editModeTableMitigans ? "custominputRow": 'percent-fixed',
            initialWidth: MITIGANS_COLUMN_WIDTHS.Political_Percentage__c,
            editable:false,
            hideDefaultActions:true,
            cellAttributes:{ alignment: 'center' },
            typeAttributes:{
                step: '0.001',
                aviableItem: {fieldName: true},
                inputValue: { fieldName: 'Political_Percentage__c' },
                fieldName: 'Political_Percentage__c',
                context: { fieldName: 'Id' },
                value: { fieldName: 'Political_Percentage__c' }
            }
        },
        {
            fieldName: "Internal_Rating__c",
            label: "INTERNAL RATING",
            type: this.editModeTableMitigans ? "picklist" : "text",
            initialWidth: MITIGANS_COLUMN_WIDTHS.Internal_Rating__c,
            editable: false,
            hideDefaultActions: true,
            cellAttributes: {
                alignment: 'center'
            },
            typeAttributes: {
                placeholder: 'Select..',
                options: this.internalRatingOptions,
                value: { fieldName: 'Internal_Rating__c' },
                context: { fieldName: 'Id' },
                fieldName: 'Internal_Rating__c'
            }
        },
        {
            fieldName:"External_Rating__c",
            label:"EXTERNAL RATING",
            initialWidth: MITIGANS_COLUMN_WIDTHS.External_Rating__c,
            type: this.editModeTableMitigans ? "picklist": 'text',
            editable:false,
            hideDefaultActions:true,
            cellAttributes:{ alignment: 'center' },
            typeAttributes:{
                placeholder: 'Select..',
                value: { fieldName: 'External_Rating__c' }, 
                context: { fieldName: 'Id' },
                fieldName: 'External_Rating__c',
                options: this.externalRatingOptions
            }
        },
        {
            fieldName:"Liquidation_Period__c",
            label:"LIQUIDATION PERIOD",
            initialWidth: MITIGANS_COLUMN_WIDTHS.Liquidation_Period__c,
            type:this.editModeTableMitigans ? "picklist": 'text',
            editable:false,
            hideDefaultActions:true,
            cellAttributes:{ alignment: 'center' },
            typeAttributes:{
                placeholder: 'Select..',
                options: this.liquidPeriodOptions,
                value: { fieldName: 'Liquidation_Period__c' }, 
                context: { fieldName: 'Id' },
                aviableItem: {fieldName: true},
                inputValue: { fieldName: 'Liquidation_Period__c' },
                fieldName: 'Liquidation_Period__c',
            }
        },
        {
            type: 'button',
            hideDefaultActions:true,
            cellAttributes:{ alignment: 'center' },
            initialWidth: MITIGANS_COLUMN_WIDTHS.deleteButton,
            typeAttributes:{
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
            cellAttributes:{ alignment: 'center' },
            initialWidth: MITIGANS_COLUMN_WIDTHS.editButton,
            typeAttributes:{
                iconName: 'utility:edit',
                label: ' ', 
                name: 'editRecord', 
                title: '', 
                disabled: {fieldName: 'editDisabled'},
                iconPosition: 'center', 
                value: 'test'
            }
        },
        {
            type: 'button',
            hideDefaultActions:true,
            cellAttributes:{ alignment: 'center' },
            initialWidth: MITIGANS_COLUMN_WIDTHS.addButton,
            typeAttributes:{
                iconName: 'utility:add',
                label: ' ', 
                name: 'addRecord', 
                title: ' ', 
                disabled: {fieldName: 'buttonDisabled'},
                iconPosition: 'center', 
                value: 'test'
            }
        }
    ];

    @api startDate;
    @api tabletype;
    @api totalamount;
    @api conversionLabel;
    currencyvalue;
    defaultLimitvalue;
    bookingGeography;
    tableData;
    @api oppProduct
    @api editModeTableMitigans = false;
    @api idListToDeleteMitigans
    @api oppState;
    @api endDateProduct;
    @api
    get table() {
      return this.tableData;
    }

    set table(value) {
      console.log('this.tableData: 1 ' + JSON.stringify(this.tableData))
      let normalizedData;
      this.termoptionsData = this.termoptionsData.filter(
          option => this.validValuesLabelReal.includes(option.label)
      );
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
      normalizedData = normalizedData.filter(
          option => this.validValuesLabelReal.includes(option.Mitigant_Type__c) || option.Mitigant_Type__c === ''
        );
      if (normalizedData.length > 0) {        
        const newArray = normalizedData.map((item, index) => {
          const newItem = { ...item };
          if (index === normalizedData.length - 1) {
            newItem.buttonDisabled = this.oppState == 'Draft'|| this.oppState == 'Ready to close' ? false : true;
            newItem.editDisabled = this.oppState == 'Draft' || this.oppState == 'Ready to close' ? false : true;
            newItem.pickDisabled = this.oppState == 'Draft' || this.oppState == 'Ready to close' ? false : true;
            newItem.deleteDisabled = (this.oppState == 'Draft' || this.oppState == 'Ready to close') && normalizedData.length > 0 ? false : true;
          }
          return newItem;
        });    
        this.tableData = newArray;
        
      } else {
        this.tableData = [
          {
              "deleteDisabled":  true,
              "pickDisabled":  this.oppState === 'Draft' || this.oppState == 'Ready to close' ? false : true,
              "initRead": "true",
              "buttonDisabled":  this.oppState === 'Draft' || this.oppState == 'Ready to close' ? false : true,
              "tabletype": "Derivatives",
              "Mitigant_Type__c" : "",
              "Political_Percentage__c" : "",
              "Commercial_Percentage__c" :"",
              "Id" : "0",
              "updateKeyId" :""
          }
      ];
      }
      if(this.editModeTableMitigans && this.isValidOmniValue(this.editModeTableMitigans)){
         let isEditBool = (this.editModeTableMitigans == 'true') ? true
                : (this.editModeTableMitigans == 'false') ? false
                : this.editModeTableMitigans;
        this.editModeTableMitigans = (isEditBool === true || isEditBool === false)
                ? !isEditBool
                : true;

        this.setEditColumns()
        
      }
      console.log('this.tableData: ' + JSON.stringify(this.tableData))
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

    @api
    get  bookingGeographyLine() {
      return this.bookingGeography;
    }
    set bookingGeographyLine(value) {
      this.bookingGeography = value;
    }


    liquidPeriodOptions = [{label:"5 días",value:"5"},{label:"10 días",value:"10"},{label:"20 días",value:"20"}];
   
    

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        switch (action.name) {
            case 'editRecord':

                let isEditBool = (this.editModeTableMitigans == 'true') ? true
                : (this.editModeTableMitigans == 'false') ? false
                : this.editModeTableMitigans;
                this.editModeTableMitigans = (isEditBool === true || isEditBool === false)
                ? !isEditBool
                : true;

                this.tableData.map(elemento => {
                  elemento.DMT_Opportunity_Product__c = this.oppProduct;
                });
                this.setEditColumns()
                this.dispatchEvent(new CustomEvent('tableMitigantChange',  { bubbles:true, composed:true,detail:{data:this.tableData,idListToDeleteMitigans:this.idListToDeleteMitigans}} ));

                this.dispatchEvent(new CustomEvent('editModeTableMitigan',  { bubbles:true, composed:true,detail:{ editmodetable:this.editModeTableMitigans}} ));     

                break;
            case 'deleteRecord':
               if(typeof this.idListToDeleteMitigans == 'string'){
                  this.idListToDeleteMitigans = []
                }
                if (!Array.isArray(this.idListToDeleteMitigans)) {
                    this.idListToDeleteMitigans = [];
                }
                
                const newList = [...(this.idListToDeleteMitigans || [])];
                newList.push(row.Id);
                this.idListToDeleteMitigans = newList;
                //const tableType = this.tableData[0]['tabletype'];
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
                
                if(sendcopyData.length == 0){
                  
                  const newItem = new Object();;
                  newItem.buttonDisabled = false;
                  newItem.pickDisabled = false;
                  newItem.Id = "0";
                  newItem.opportunity =  this.opportunityvalue;                                        
                  sendcopyData.push(newItem);
                          }
                
                
                this.dispatchEvent(new CustomEvent('tableMitigantChange',  { bubbles:true, composed:true,detail:{data:sendcopyData,idListToDeleteMitigans:this.idListToDeleteMitigans}} ));
                this.setEditColumns()
                this.isEditMode = true;
                this.dispatchEvent(new CustomEvent('editModeTableMitigan',  { bubbles:true, composed:true,detail:{ editmodetable:this.editModeTableMitigans}} ));     
                

                break;
            case 'addRecord':
              this.tableData.map(elemento => {
                  elemento.DMT_Opportunity_Product__c = this.oppProduct;
                });
              const index = this.tableData.findIndex(dataRow => dataRow.Id === row.Id);
              let copyDataNew;
              let sendcopyDataNew;
              if(row.Id == '0' && this.tableData.length == 1 && row.Mitigant_Type__c == '' && row.Political_Percentage__c == '' && row.Commercial_Percentage__c == ''){
                const tablelenght = this.tableData.length;
                copyDataNew = [
                {
                  'End_Date__c': this.endDateProduct,
                  "Mitigant_Type__c": '',
                  "CurrencyIsoCode": '',
                  "Id": tablelenght.toString(),
                  "Commercial_Percentage__c": '',
                  "Political_Percentage__c":'',
                  "DMT_Country_Guarantor__c":'',
                  "opportunity":this.opportunityvalue,
                  "deleteDisabled": false,
                  'buttonDisabled':true,
                  'editDisabled':false,
                  'CurrencyIsoCode':this.currencyvalue, 
                  "External_Rating__c": '',
                  "Liquidation_Period__c": '',
                  "DMT_Opportunity_Product__c": this.oppProduct,
                  "Internal_Rating__c": '',
                  "updateKeyId" :""
                }
              ];
              }else{
              const tablelenght = this.tableData.length +1;

                copyDataNew = [
                  ...this.tableData.slice(0, index+1),
                {
                  'End_Date__c': this.endDateProduct,
                  "Mitigant_Type__c": '',
                  "DMT_Country_Guarantor__c":'',
                  "CurrencyIsoCode": '',
                  "Id": tablelenght.toString(),
                  "Commercial_Percentage__c": '',
                  "Political_Percentage__c":'',
                  "opportunity":this.opportunityvalue,
                  "deleteDisabled": false,
                  'buttonDisabled':true,
                  'editDisabled':false,
                  'CurrencyIsoCode':this.currencyvalue,
                  "External_Rating__c": '',
                  "Liquidation_Period__c": '',
                  "DMT_Opportunity_Product__c": this.oppProduct,
                  "Internal_Rating__c": '',
                  "updateKeyId" :""
                },
                ...this.tableData.slice(index+1)
              ];
              console.log('copyDataNew -'+ JSON.stringify(copyDataNew))
                sendcopyDataNew = this.copiarLista(copyDataNew);
                //sendcopyDataNew[sendcopyDataNew.length-2]['buttonDisabled'] = true;
                //sendcopyDataNew[sendcopyDataNew.length-1]['buttonDisabled'] = true;
                //sendcopyDataNew[sendcopyDataNew.length-2]['pickDisabled'] = true;
                //sendcopyDataNew[sendcopyDataNew.length-1]['pickDisabled'] = false;
                //sendcopyDataNew[sendcopyDataNew.length-2]['deleteDisabled'] = true;
                //sendcopyDataNew[sendcopyDataNew.length-1]['deleteDisabled'] = false;
                
              }

              this.setEditColumns()
              console.log('ABS DATA -'+ JSON.stringify(this.tableData));
            this.dispatchEvent(new CustomEvent('tableMitigantChange',  { bubbles:true, composed:true,detail:  {data:sendcopyDataNew?sendcopyDataNew:copyDataNew, idListToDeleteMitigans:this.idListToDeleteMitigans}} ));
            this.isEditMode = true;
                this.dispatchEvent(new CustomEvent('editModeTableMitigan',  { bubbles:true, composed:true,detail:{ editmodetable:this.editModeTableMitigans}} ));     

            break;
        }
    }

    picklistChanged(event) {
      event.stopPropagation();
      let dataRecieved = event.detail.data;
      let updatedItem;
      if( dataRecieved.fieldname === 'Mitigant_Type__c'){
          updatedItem = { Id: dataRecieved.context, Mitigant_Type__c: dataRecieved.value };
      }else if( dataRecieved.fieldname === 'Liquidation_Period__c'){
          updatedItem = { Id: dataRecieved.context, Liquidation_Period__c: dataRecieved.value };
      }else if( dataRecieved.fieldname === 'CurrencyIsoCode'){
          updatedItem = { Id: dataRecieved.context, CurrencyIsoCode: dataRecieved.value };
      }else if (dataRecieved.fieldname === 'DMT_Country_Guarantor__c') {
            updatedItem = { Id: dataRecieved.context, DMT_Country_Guarantor__c: dataRecieved.value };
      }else if (dataRecieved.fieldname === 'Internal_Rating__c') {
            updatedItem = { Id: dataRecieved.context, Internal_Rating__c: dataRecieved.value };
      }else{
          updatedItem = { Id: dataRecieved.context, External_Rating__c: dataRecieved.value };
      }
      //this.updateDraftValues(updatedItem);
      this.updateDataValues(updatedItem);

  }
    updateDataValues(updateItem) {
      let copyData = this.copiarLista(this.tableData);

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
      console.log('updateDatA: ' + JSON.stringify(this.tableData))
      this.dispatchEvent(new CustomEvent('tableMitigantChange', {
        bubbles: true,
        composed: true,
        detail: {
          data: copyData
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

  handleChangeCell(event){
    let dataRecieved = event.detail.draftValues;
    let updatedItem;
        updatedItem = { Id: dataRecieved[0].Id, Commercial_Percentage__c: dataRecieved[0].Commercial_Percentage__c };
    //this.updateDraftValues(updatedItem);
    this.updateDataValues(updatedItem);
  }

  handledefaultLimit(){
    var guidanceData;
    if(this.tableData !== undefined)
    {
      if(this.tableData[0]['tabletype'] === 'Derivatives'){
        guidanceData = [    {
          "deleteDisabled": true,
          "Mitigant_Type__c": "2026",
          "Id": "0",
          "pickDisabled": true,
          "initRead": "true",
          "buttonDisabled": true,
          "line": this.tableData[0]['line'],
          "Commercial_Percentage__c": this.totalamount,
          "tabletype": "Derivatives"
        },{
            "deleteDisabled": true,
            "Mitigant_Type__c": "2026",
            "Id": "1",
            "pickDisabled": true,
            "initRead": "true",
            "buttonDisabled": true,
            "line": this.tableData[0]['line'],
            "Commercial_Percentage__c": (this.totalamount*3)/4,
            "tabletype": "Derivatives"
          } ,{
            "deleteDisabled": true,
            "Mitigant_Type__c": "2026",
            "Id": "2",
            "pickDisabled": true,
            "initRead": "true",
            "buttonDisabled": true,
            "line": this.tableData[0]['line'],
            "Commercial_Percentage__c": this.totalamount/2,
            "tabletype": "Derivatives"
          },{
            "deleteDisabled": true,
            "Mitigant_Type__c": "2026",
            "Id": "3",
            "pickDisabled": true,
            "initRead": "true",
            "buttonDisabled": true,
            "line": this.tableData[0]['line'],
            "Commercial_Percentage__c": (this.totalamount*2.5)/10,
            "tabletype": "Derivatives"
          }];
      }
      this.dispatchEvent(new CustomEvent('tableMitigantChange',  { bubbles:true, composed:true,detail:  {data:guidanceData, tabletype:guidanceData[0]['tabletype']}} ));
    }
  }
  setEditColumns() {
    this.columns = [
      {
        fieldName: 'End_Date__c',
        label: 'DATE',
        type: 'customdateRow',
        editable:false,
        initialWidth : COLUMN_WIDTHS.EndDate,
        hideDefaultActions:true,
        cellAttributes:{style: 'text-align: center;'},
        typeAttributes: {
            aviableItem: {fieldName: 'aviableItem'},
            dateValue: { fieldName: 'End_Date__c' },
            fieldName: 'End_Date__c',
            value: { fieldName: 'End_Date__c' },
            context: { fieldName: 'Id' }
        }
      },
        {
            fieldName:"CurrencyIsoCode",
            label:"CURRENCY",
            type: this.editModeTableMitigans ? "picklist": "text",
            editable:this.editModeTableMitigans,
            initialWidth : COLUMN_WIDTHS.CurrencyIsoCode,
            hideDefaultActions:true,
            cellAttributes: { alignment: 'center' },
            typeAttributes: {
                placeholder: 'Select..',
                options: this.CurrencyIsoCode,
                fieldName: 'CurrencyIsoCode',
                value: { fieldName: 'CurrencyIsoCode' }, 
                context: { fieldName: 'Id' }
            }
        },
        {
            fieldName:"Mitigant_Type__c",
            label:"MITIGANT TYPE",
            type:  "picklist",
            editable:false,
            initialWidth : COLUMN_WIDTHS.Mitigant_Type__c,
            hideDefaultActions:true,
            cellAttributes: { alignment: 'center' },
            typeAttributes: {
                placeholder: 'Select..',
                options: this.termoptionsData,
                fieldName: 'Mitigant_Type__c',
                value: { fieldName: 'Mitigant_Type__c' }, 
                context: { fieldName: 'Id' }
            }
        },
        {
            fieldName:"DMT_Country_Guarantor__c",
            label:"COUNTRY GUARANTOR",
            type: this.editModeTableMitigans ? "picklist": "text",
            editable:false,
            hideDefaultActions:true,
            initialWidth : MITIGANS_COLUMN_WIDTHS.Country_Guarantor__c,
            cellAttributes: { alignment: 'center' },
            typeAttributes: {
                placeholder: 'Select..',
                options: this.countryOptionsVal,
                fieldName: 'DMT_Country_Guarantor__c',
                value: { fieldName: 'DMT_Country_Guarantor__c' }, 
                context: { fieldName: 'Id' }
            }
        },
        {
            fieldName:"Commercial_Percentage__c",
            label:"COMMERCIAL RISK (%)",
            type: "custominputRow",
            editable:false,
            initialWidth: COLUMN_WIDTHS.Commercial_Percentage__c,
            hideDefaultActions:true,
            cellAttributes: { alignment: 'center' },
            typeAttributes: {
                step: '0.001',
                aviableItem: {fieldName: true},
                inputValue: { fieldName: 'Commercial_Percentage__c' },
                fieldName: 'Commercial_Percentage__c',
                context: { fieldName: 'Id' },
                value: { fieldName: 'Commercial_Percentage__c' }
            }
        },
        {
            fieldName:"Political_Percentage__c",
            label:"POLITICAL RISK (%)",
            type:  "custominputRow",
            editable:false,
            initialWidth: COLUMN_WIDTHS.Political_Percentage__c,
            hideDefaultActions:true,
            cellAttributes: { alignment: 'center' },
            typeAttributes: {
                step: '0.001',
                aviableItem: {fieldName: true},
                inputValue: { fieldName: 'Political_Percentage__c' },
                fieldName: 'Political_Percentage__c',
                context: { fieldName: 'Id' },
                value: { fieldName: 'Political_Percentage__c' }
            }
        },
        {
            fieldName: "Internal_Rating__c",
            label: "INTERNAL RATING",
            type: "picklist",
            editable: false,
            initialWidth: COLUMN_WIDTHS.Internal_Rating__c,
            hideDefaultActions: true,
            cellAttributes: { alignment: 'center' },
            typeAttributes: {
                placeholder: 'Select..',
                options: this.internalRatingOptions,
                value: { fieldName: 'Internal_Rating__c' },
                context: { fieldName: 'Id' },
                fieldName: 'Internal_Rating__c'
            }
        },
        {
            fieldName:"External_Rating__c",
            label:"EXTERNAL RATING",
            type:  "picklist",
            editable:false,
            initialWidth: COLUMN_WIDTHS.External_Rating__c,
            hideDefaultActions:true,
            cellAttributes: { alignment: 'center' },
            typeAttributes: {
                placeholder: 'Select..',
                value: { fieldName: 'External_Rating__c' }, 
                context: { fieldName: 'Id' },
                fieldName: 'External_Rating__c',
                options: this.externalRatingOptions
            }
        },
        {
            fieldName:"Liquidation_Period__c",
            label:"LIQUIDATION PERIOD",
            type: "picklist",
            editable:false,
            initialWidth: COLUMN_WIDTHS.Liquidation_Period__c,
            hideDefaultActions:true,
            cellAttributes: { alignment: 'center' },
            typeAttributes: {
                placeholder: 'Select..',
                options: this.liquidPeriodOptions,
                value: { fieldName: 'Liquidation_Period__c' }, 
                context: { fieldName: 'Id' },
                aviableItem: {fieldName: true},
                inputValue: { fieldName: 'Liquidation_Period__c' },
                fieldName: 'Liquidation_Period__c',
            }
        },
        {
            type: 'button',
            hideDefaultActions:true,
            cellAttributes: { alignment: 'center' },
            initialWidth: COLUMN_WIDTHS.deleteButton,
            typeAttributes: {
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
            cellAttributes: { alignment: 'center' },
            initialWidth: COLUMN_WIDTHS.editButton,
            typeAttributes: {
                iconName: 'utility:edit',
                label: ' ', 
                name: 'editRecord', 
                title: '', 
                disabled: {fieldName: 'editDisabled'},
                iconPosition: 'center', 
                value: 'test'
            }
        },
        {
            type: 'button',
            hideDefaultActions:true,
            cellAttributes: { alignment: 'center' },
            initialWidth: COLUMN_WIDTHS.addButton,
            typeAttributes: {
                iconName: 'utility:add',
                label: ' ', 
                name: 'addRecord', 
                title: ' ', 
                disabled: {fieldName: 'buttonDisabled'},
                iconPosition: 'center', 
                value: 'test'
            }
        }
    ];
}
  textInputChanged(event) {
      event.stopPropagation();
      let dataRecieved = event.detail.data;
      let updatedItem;
      updatedItem = { Id: dataRecieved.context};
      updatedItem[dataRecieved.fieldname]= dataRecieved.value;
      
      this.updateDataValues(updatedItem);
    }

  isValidOmniValue(value) {
    if (value === null || value === undefined) return false;

    if (typeof value === 'string') {
      const v = value.trim();
      if (v === '' || v.toLowerCase() === 'null') return false;

      // placeholder simple como {overridefields} o {oppData} -> devolver false
      const placeholderRegex = /^\{\s*[A-Za-z0-9_]+(?:\.[A-Za-z0-9_]+)*\s*\}$/;
      if (placeholderRegex.test(v)) return false;

      return true;
    }else if(typeof value === 'object'){
      return true;
    }
    return false;
  }
}