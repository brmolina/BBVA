import { LightningElement, track, api, wire } from 'lwc';
import { FlowNavigationNextEvent} from 'lightning/flowSupport';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { loadStyle } from 'lightning/platformResourceLoader';
import dataTableWithoutTruncate from '@salesforce/resourceUrl/DataTableTruncateCss';
import getApproverMemberFields from '@salesforce/apex/DMT_DataTableIntervenersController.getApproverMemberFields';

export default class CustomDatatableProduct extends LightningElement {
    currentUserInfo = null;
    mapRolesAccess = null;
    tableData = null;
    accessLevel = null;
    columns;
    readonly = [];
    pickListOrdered;
    @api pickListOrder;
    @track pickListFields = null;
    @track picklistField1 = [];
    @track picklistField2 = [];
    veceesEjecucion = 0;

    procesado = false;

    @wire(getApproverMemberFields)
    wiredPicklistFields({ error, data }) {
        if (data) {
            this.pickListFields = data;
            this.picklistField1 = [...data];
            this.picklistField2 = [...data];
            this.tryProcess();
        } else if (error) {
            this.dispatchEvent(
              new ShowToastEvent({
                  title: 'Error',
                  message: 'The options for FIELD1 and FIELD2 could not be loaded.',
                  variant: 'error'
              })
            );
        }
    }
    
    @api recordId;
    @api additionalFields = false;
    nextFlowvalue;
    //have this attribute to track data changed
    //with custom picklist or custom lookup
    @track draftValues = [];

    @api
    get desUserRoles(){
      return this.mapRolesAccess;
    }
    set desUserRoles (value){

       this.mapRolesAccess =  new Map(
        value.map(role => [role.DES_Role_Developer_Name__c, role.DES_Access_Level__c]));
        this.tryProcess();

    }

 
    @api
    get  currentUser() {
      return this.currentUserInfo;
    }


   set currentUser(value) {
    this.currentUserInfo = value;
    this.tryProcess();
   
 

  }

    @api
    get  accessLevelOptions() {
      return this.accessLevel;
    }
  
    set accessLevelOptions(value) {
      this.accessLevel = value;
      this.tryProcess();

    }
    @api
    get  tableDataName() {
      return this.tableData;
    }
  
    set tableDataName(value) {
      this.procesado = false;
      this.tableData = value;
      this.tryProcess();

    }
    isDataReady() {
      return this.tableData !== null &&
         this.currentUserInfo !== null &&
         this.mapRolesAccess !== null &&
         this.accessLevel !== null &&
         this.pickListFields !== null;
    }



    tryProcess() {      
        if (this.isDataReady() && !this.procesado) {
            this.processTableData(this.tableData);
            this.procesado = true;
        }

    }

    processTableData(value) {
      let valueCopy = JSON.parse(JSON.stringify(value));
      this.readonly = [];

      valueCopy.forEach((element) => {
        if(element.AccessLevel === "All"){
          this.readonly.push(true);
        }else{
          this.readonly.push(false);
        }
        if (element.hasOwnProperty('fieldHistory') && element.fieldHistory) {
          try {
            const fieldHistory = JSON.parse(element.fieldHistory);
            element['field1'] = fieldHistory.field1 || '';
            element['field2'] = fieldHistory.field2 || '';
        
            // Add the labels
            if (this.pickListFields.length > 0) {
              element['field1Label'] = this.pickListFields.find((el) => el.value === element['field1'])?.label || '';
              element['field2Label'] = this.pickListFields.find((el) => el.value === element['field2'])?.label || '';
            }
          } catch (e) {
            console.warn('Error parsing fieldHistory', e);
          }
        }
        //return element;
        
      });

      //Quitamos los approver añadidos por uos ( tienen el campo uos)
      valueCopy = valueCopy.filter((element) => !(element.hasOwnProperty('Uos') && element.Uos != null));
      if(valueCopy.length === 0 ){
        valueCopy.push(
          {
            "AccessLevel": "Read",
            "recordId":this.recordId
          }
        );
      }

      this.tableData = valueCopy.map((acc) => ({ ...acc, buttonDisabled: acc.AccessLevel == 'All', showReadOnlyWarning: !this.hasFullAccess(acc.dmtUserRole)}));



      this.dispatchEvent(new CustomEvent('tableProductChanges',  { bubbles:true, composed:true,detail:  this.tableData} ));
      this.setColumns();
    }

    @api
    get  nextFlow() {
      return this.nextFlowvalue;
    }
  
    set nextFlow(value) {
      if(value.toLowerCase() === 'true'){
        this.passFlow();
      }
      this.nextFlowvalue = value;
    }

    lastSavedData = [];
    setColumns(){
      let readOnlyAccessCurrentUser = !this.hasFullAccess(this.currentUserInfo?.DMT_User_Role__c);

     this.columns = [
      { label: 'PARTICIPANT', fieldName: 'userName', type:'recordpicker',hideDefaultActions:true , typeAttributes: { fieldName: 'userName', disabled : readOnlyAccessCurrentUser,
         matchingInfo : {
           primaryField: { fieldPath: 'Name' },
           additionalFields: [{ fieldPath: 'ID_User__c' }]
       },displayInfo : {
           primaryField: 'Name'
       },
      value: { fieldName: 'userId' }, context: { fieldName: 'Id' }, readonlyAttr : { fieldName: 'AccessLevel' }}},
        { label: 'ACCESS LEVEL', fieldName: 'AccessLevel', type:'picklist',hideDefaultActions:true, typeAttributes: {
            placeholder: 'Select...', options: this.accessLevel, isDisabled : readOnlyAccessCurrentUser, requieresValueRecoPick : { fieldName: 'requieresValueRecoPick' }, showReadOnlyWarning: { fieldName: 'showReadOnlyWarning' }, fieldName: 'AccessLevel' // list of all picklist options
            , value: { fieldName: 'AccessLevel' } // default value for picklist
            , context: { fieldName: 'Id' } // binding account Id with context variable to be returned back
        }},
        {
            type:  'button-icon',
            initialWidth: 90,hideDefaultActions:true,
            cellAttributes: { alignment: 'center' },
            typeAttributes: 
            {
              iconName: 'utility:delete',
              label: ' ', 
              name: 'deleteRecord', 
              title: '', 
              disabled: readOnlyAccessCurrentUser,
              iconPosition: 'center', 
              value: 'test'
            }
          }
          ,
        {
            type:  'button-icon',
            initialWidth: 90,hideDefaultActions:true,
            cellAttributes: { alignment: 'center' },
            typeAttributes: 
            {
              iconName: 'utility:add',
              label: '    ', 
              name: 'addRecord', 
              title: '        ', 
              disabled: readOnlyAccessCurrentUser,
              iconPosition: 'center', 
              value: 'test'
            }
          }
    ];
    if (this.additionalFields) {
      this.columns.splice(2, 0,  { label: 'FIELD 1', fieldName: 'field1', type:'searchcombobox',hideDefaultActions:true , typeAttributes: {
        fieldName: 'field1', pickListOrdered: this.picklistField1,requieresValueRecoPick : { fieldName: 'requieresValueRecoPick' }, isDisabled : readOnlyAccessCurrentUser, selectedSearchvalue:  { fieldName: 'field1' }, selectedSearchlabel:  { fieldName: 'field1Label' }, context: { fieldName: 'Id' }}},  { label: 'FIELD 2', fieldName: 'field2', type:'searchcombobox',hideDefaultActions:true , typeAttributes: {
          fieldName: 'field2', pickListOrdered: this.picklistField2, requieresValueRecoPick : { fieldName: 'requieresValueRecoPick' }, isDisabled : readOnlyAccessCurrentUser, selectedSearchvalue:  { fieldName: 'field2' }, selectedSearchlabel:  { fieldName: 'field2Label' }, context: { fieldName: 'Id' }}})
    }
    
}
    connectedCallback(){
      loadStyle(this, dataTableWithoutTruncate);
    }

    handleRecordPicker(event){
      let dataRecieved = event.detail.data;
      let updatedItem;
      updatedItem = { Id: dataRecieved.context};
      updatedItem[dataRecieved.fieldname] = dataRecieved.value;
      updatedItem["userId"] = dataRecieved.value;
      updatedItem["requieresValueRecoPick"] = updatedItem.userId == null;

      if (!updatedItem.userId) updatedItem.AccessLevel = 'Read';
      updatedItem["dmtUserRole"] = dataRecieved.dmtUserRole;
      updatedItem["showReadOnlyWarning"] = dataRecieved.dmtUserRole == null;

      
      /*if (dataRecieved.fieldname == 'userName') {
        let name = this.pickListOrder.find(({value}) => value === dataRecieved.value)?.label;
        updatedItem.Name = name;
      }*/
      let duplicatedElement = false;
      this.tableData.forEach(item => {
        if (item.userId && updatedItem.userId && item.userId === updatedItem.userId) {
          duplicatedElement = true;
          return;
        }
      });

      if (duplicatedElement) {
        let copyData = this.tableData.filter(function(item) {
          return item.Id !== updatedItem.Id
        })
        this.isLoading = true;
        this.dispatchEvent(new CustomEvent('tableProductChanges',  { bubbles:true, composed:true,detail:  copyData} ));

        this.dispatchEvent(new ShowToastEvent({
          title: "Valor duplicado",
          message: 'El usuario seleccionado ya existe en la lista',
          variant: "error"
        }));
      }
      else
      {
        this.updateDataValues(updatedItem);
      }
    }

    updateDataValues(updateItem) {
        let copyData = this.copiarLista(this.tableData);
        copyData.forEach(item => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                    if (field.includes("field")) {
                      if (!item["fieldHistory"]) {
                        item["fieldHistory"] = '{"field1" : "", "field2": ""}';
                      }
                      let copyFieldHistory = JSON.parse(item["fieldHistory"]);
                      copyFieldHistory[field] = updateItem[field];
                      item["fieldHistory"] = JSON.stringify(copyFieldHistory);
                    }
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
                    if (field.includes("field")) {
                      if (!item["fieldHistory"]) {
                        item["fieldHistory"] = '{"field1" : "", "field2": ""}';
                      }
                      let copyFieldHistory = JSON.parse(item["fieldHistory"]);
                      copyFieldHistory[field] = updateItem[field];
                      item["fieldHistory"] = JSON.stringify(copyFieldHistory);
                    }
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
    comboboxChange(event) {
        event.stopPropagation();
        let dataRecieved = event.detail.data;console.log('dataRecievedjson',JSON.stringify(dataRecieved));
        let updatedItem;
        updatedItem = { Id: dataRecieved.context};
        updatedItem[dataRecieved.fieldname] = dataRecieved.value;
        console.log('updatedItemdvdv',JSON.stringify(updatedItem));
        //this.updateDraftValues(updatedItem);
        this.updateDataValues(updatedItem);
    }

    picklistChanged(event) {
        event.stopPropagation();
        let dataRecieved = event.detail.data;console.log('dataRecievedjson',JSON.stringify(dataRecieved));
        let updatedItem;
        updatedItem = { Id: dataRecieved.context, AccessLevel: dataRecieved.value };
        console.log('updatedItemdvdv',JSON.stringify(updatedItem));
        //this.updateDraftValues(updatedItem);
        this.updateDataValues(updatedItem);
    }

    //handler to handle cell changes & update values in draft values
    handleCellChange(event) {console.log('cell change')
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
                this.dispatchEvent(new CustomEvent('tableProductChanges',  { bubbles:true, composed:true,detail:  copyData} ));console.log('deleteRecord',copyData);
                break;
            case 'addRecord':
              const index = this.tableData.length - 1;
              let copyDataNew = [
                ...this.tableData.slice(0, index+1),
                {
                  "AccessLevel": "Read",
                  "userName": "",
                  "Id": index + 1,
                  "recordId":this.recordId,
                  "field1": "",
                  "field2": "",
                  "fieldHistory" : '{"field1" : "", "field2": ""}',
                  "requieresValueRecoPick": true,
                  "showReadOnlyWarning": false,
                },
                ...this.tableData.slice(index+1)
            ];
            this.dispatchEvent(new CustomEvent('tableProductChanges',  { bubbles:true, composed:true,detail:  copyDataNew} ));console.log('addRecord',JSON.stringify(copyDataNew));
                break;
        }
    }


    passFlow(){
      const navigateNextEvent = new FlowNavigationNextEvent();
      this.dispatchEvent(navigateNextEvent);
    }

    hasFullAccess(userRolesStr) {
        if (!userRolesStr || !this.mapRolesAccess) return false;


        const userRoles = userRolesStr
            .split(/[;,|]/)
            .map(r => r.trim())
            .filter(Boolean);

        return userRoles.some(role => {
          // in case there is no accessLevel, we set it by default to ReadOnly
          const accessLevel = this.mapRolesAccess.get(role) || 'ReadOnly';
          return accessLevel !== 'ReadOnly';

        });
    }

    /*async resetTable() {
      await this.setColumns();
      let copyData = JSON.parse(JSON.stringify(this.tableData));
      this.tableData = false;
      this.tableData = JSON.parse(JSON.stringify(copyData));
    }*/

    /*notifyCombobox(dataRecieved) {
      const parentComponent = this.template.querySelector('c-custom-data-table');
      const customEvent = new CustomEvent('changepicklistfromcombobox', {
        detail: { data: this.pickListFields.filter(function(el) { return el.value !== dataRecieved.value}), fieldname: dataRecieved.fieldname, context: dataRecieved.context}
      });
      parentComponent.dispatchEvent(customEvent);
      //console.log(parentComponent);
      /*const grandChildren = this.template.querySelectorAll('c-searchable-combobox');
      console.log('JACG');
      console.log(grandChildren);
      const targetGrandChild = [...grandChildren].find(grandchild => grandchild.getAttribute('context') === dataRecieved.context && grandchild.getAttribute('fieldname') != dataRecieved.fieldname);
      if (targetGrandChild) {
        const customEvent = new CustomEvent('changepicklist', {
          detail: this.pickListFields.filter(function(el) { return el.value !== dataRecieved.value})
        });
        targetGrandChild.dispatchEvent(customEvent);
      }
    }*/
}