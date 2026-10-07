import { LightningElement, track, api, wire } from 'lwc';
import { FlowNavigationNextEvent} from 'lightning/flowSupport';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { loadStyle } from 'lightning/platformResourceLoader';
import dataTableWithoutTruncate from '@salesforce/resourceUrl/DataTableTruncateCss';
import getCoverageTeamRoles from '@salesforce/apex/DMT_ViewController.getCoverageTeamRoles';

const DUPLICATE_ERROR_TITTLE = 'Duplicate value';
const DUPLICATE_ERROR_MESSAGE = 'The selected user already exists in the list.';


export default class CustomDatatableProduct extends LightningElement {

    tableData;
    isLoading = false;
    accessLevel = [];
    columns;
    addProductRes;
    pickListOrdered;
    isModalOpen = false;
    @api pickListOrder;
    @api recordId;
    @api additionalFields = false;
    nextFlowvalue;
    currentUserInfo = null;
    mapRolesAccess = null;
    _rawTableData  = null;
    _isOpp;
    _addParticipant;
    procesado = false;
    _loadingTimeout = null;
    coverageRolesByUser = null;


    //form values
    user;
    teamRole = [];
    coverageType;
    psProductFamily;
    scope;
    psProduct;
    accessLevelValue = 'Read';

    //have this attribute to track data changed
    //with custom picklist or custom lookup
    @track draftValues = [];

    @api
    get addParticipant(){
      return this._addParticipant;
    }

     set addParticipant(value) {
      this._addParticipant = value;
      if(value == true || value == "true"){
        this.handleSaveData();
      }
    }

    @api
    get  pickListOrdered() {
      return this.pickListOrder;
    }

    set pickListOrdered(value) {
      this.pickListOrder = value;
      this.setColumns();
    }

    @api
    get isOpp() {
      return this._isOpp;
    }

    set isOpp(value) {
      this._isOpp = value;
      this.setColumns();
    }

    @api
    get teamRoleOptions() {
      return this.teamRole;
    }

    set teamRoleOptions(value) {
      this.teamRole = value;
      this.setColumns();
    }

    @api
    get  accessLevelOptions() {
      return this.accessLevel;
    }

    set accessLevelOptions(value) {
      this.accessLevel = value;
      this.setColumns();
    }

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
    get  tableDataName() {
      return this.tableData;
    }

    set tableDataName(value) {
      this.procesado = false;
      this._rawTableData = value;
      this.tryProcess();

    }
    startLoading() {
        if (this._loadingTimeout) clearTimeout(this._loadingTimeout);
        this.isLoading = true;
        this._loadingTimeout = setTimeout(() => {
            this.isLoading = false;
            this._loadingTimeout = null;
        }, 2000);
    }

    closeModal(){
      this.isModalOpen = false;
      this.isLoading = false;
    }

    isDataReady() {
      return this._rawTableData !== null &&
         this.currentUserInfo !== null &&
         this.mapRolesAccess !== null &&
         this.accessLevel !== null
    }



    tryProcess() {
        if (this.isDataReady() && !this.procesado) {
            this.procesado = true;
            this.processTableData(this._rawTableData);

        }

    }

    processTableData(value) {
      if (this._loadingTimeout) {
          clearTimeout(this._loadingTimeout);
          this._loadingTimeout = null;
      }

      let valueCopy = JSON.parse(JSON.stringify(value));
      valueCopy.forEach((element) => {

        element.userDisabled = element.AccessLevel === "All" || element.editAccess === true;
        element.showReadOnlyWarning = !this.hasFullAccess(element?.dmtUserRole);

    });

      const seenUserIds = new Set();
      const filteredValueCopy = valueCopy.filter(item => {
          if (item.userId && seenUserIds.has(item.userId)) {
              return false;
          }
          seenUserIds.add(item.userId);
          return true;
    });
      this.tableData = this.applyCoverageRoles(filteredValueCopy);

      this.setColumns();

      setTimeout(() => {
        this.isLoading = false;
      },500);
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

    get participantUserFilter() {
      return {
        criteria: [{
          fieldPath: 'IsActive',
          operator: 'eq',
          value: true
        }]
      };
    }

    setColumns(){
    let readOnlyAccessCurrentUser = !(this.hasFullAccess(this.currentUserInfo?.DMT_User_Role__c) && this.currentUserInfo?.userHasEditAccess) && !this.currentUserInfo?.hasGodAccess;
        if(this.isOpp != true){
          this.columns = [
            { label: 'PARTICIPANT', fieldName: 'userName', type:'recordpicker',hideDefaultActions:true , typeAttributes: { fieldName: 'userName',
            disabled: readOnlyAccessCurrentUser || {fieldName: 'userDisabled'},
              matchingInfo : {
                primaryField: { fieldPath: 'Name' },
                additionalFields: [{ fieldPath: 'ID_User__c' }]
            },displayInfo : {
                primaryField: 'Name'
            },
            filter: this.participantUserFilter,
            value: { fieldName: 'userId' }, context: { fieldName: 'Id' }, readonlyAttr : { fieldName: 'AccessLevel' }}},
            { label: 'ACCESS LEVEL', fieldName: 'AccessLevel', type:'picklist',hideDefaultActions:true, typeAttributes: {
                placeholder: 'Select...', options: this.accessLevel,isDisabled : readOnlyAccessCurrentUser, fieldName: 'AccessLevel' // list of all picklist options
                , value: { fieldName: 'AccessLevel' } // default value for picklist
                , context: { fieldName: 'Id' } // binding account Id with context variable to be returned back
                , readonlyAttr : { fieldName: 'userDisabled' }// make readonly access level if Access Level is all
                , showReadOnlyWarning: { fieldName: 'showReadOnlyWarning' }
            }},
            { label: 'COVERAGE TEAM ROLE', fieldName: 'coverageRole', type: 'text', hideDefaultActions: true, wrapText: true },
            {
                type:  'button-icon',
                initialWidth: 90,hideDefaultActions:true,
                cellAttributes: { alignment: 'center' },
                typeAttributes:
                {
                  iconName: 'utility:delete',
                  variant: "bare",
                  label: ' ',
                  name: 'deleteRecord',
                  title: '',
                  disabled: readOnlyAccessCurrentUser  || { fieldName: 'userDisabled' },
                  iconPosition: 'center',
                  value: 'test'
                }
              }
              ,
          ];
        }else{
       this.columns = [
        { label: 'PARTICIPANT', fieldName: 'userName', type:'recordpicker',hideDefaultActions:true , typeAttributes: { fieldName: 'userName',
        disabled: readOnlyAccessCurrentUser || {fieldName: 'userDisabled'},
           matchingInfo : {
             primaryField: { fieldPath: 'Name' },
             additionalFields: [{ fieldPath: 'ID_User__c' }]
         },displayInfo : {
            primaryField: 'Name'
         },
        filter: this.participantUserFilter,
        value: { fieldName: 'userId' }, context: { fieldName: 'Id' }, readonlyAttr : { fieldName: 'AccessLevel' }}},

        { label: 'ACCESS LEVEL', fieldName: 'AccessLevel', type:'picklist',hideDefaultActions:true, typeAttributes: {
            placeholder: 'Select...', options: this.accessLevel,isDisabled : readOnlyAccessCurrentUser, fieldName: 'AccessLevel' // list of all picklist options
            , value: { fieldName: 'AccessLevel' } // default value for picklist
            , context: { fieldName: 'Id' } // binding account Id with context variable to be returned back
            , readonlyAttr : { fieldName: 'userDisabled' }// make readonly access level if Access Level is all
            , showReadOnlyWarning: { fieldName: 'showReadOnlyWarning' }
        }},

        { label: 'COVERAGE TEAM ROLE', fieldName: 'coverageRole', type: 'text', hideDefaultActions: true, wrapText: true },
        {
            type:  'button-icon',
            initialWidth: 70,hideDefaultActions:true,
            cellAttributes: { alignment: 'center' },
            typeAttributes:
            {
              variant: "bare",
              iconName: 'utility:delete',
              label: ' ',
              name: 'deleteRecord',
              title: '',
              disabled: readOnlyAccessCurrentUser  || { fieldName: 'userDisabled' },
              iconPosition: 'center',
              value: 'test'
            }
          }
    ];
    }


}
    connectedCallback(){
      loadStyle(this, dataTableWithoutTruncate);
      this.loadCoverageRoles();
    }

    handleSaveData(){

      let copyTable = JSON.parse(JSON.stringify(this.tableData));
      //empty placeholder rows (no participant selected) must never be sent
      //to the backend, only rows with an actual participant are kept
      let filledRows = copyTable.filter((element) => !!element.userName);
      let i = 0;
      let copyDataNew = [];
      filledRows.forEach((element) => {
        element.Id = i;
        copyDataNew.push(element);
        i++;
      });
      copyDataNew.push( {
        "AccessLevel": "Read",
        "teamRoleValue": "",
        "userName": "",
        "showReadOnlyWarning": false,
        "Id": i,
        "recordId": this.recordId,
        "field1": "",
        "field2": "",
        "fieldHistory" : '{"field1" : "", "field2": ""}'
      });

      this.tableData = undefined;

      //this.dispatchEvent(new CustomEvent('tableProductChanges',  { bubbles:true, composed:true,detail:  copyDataNew} ));
      this.emitTableChanges(copyDataNew);

    }


    handleRecordPicker(event){
      let dataRecieved = event.detail.data;
      let updatedItem;
      updatedItem = { Id: dataRecieved.context};
      updatedItem[dataRecieved.fieldname] = dataRecieved.value;
      updatedItem["userId"] = dataRecieved.value;
      if (!updatedItem.userId) updatedItem.AccessLevel = 'Read';
      updatedItem["dmtUserRole"] = dataRecieved.dmtUserRole;
      updatedItem["showReadOnlyWarning"] = dataRecieved.dmtUserRole == null;
      // Auto-assign 'User-Defined' teamRole for manually added participants
      // (rows with no existing teamRoleValue are new rows added manually from the UI)
      const existingRow = this.tableData ? this.tableData.find(item => item.Id === dataRecieved.context) : null;
      if (!existingRow || !existingRow.teamRoleValue) {
        updatedItem.teamRoleValue = 'User-Defined';
      }
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
        this.startLoading();
        //this.dispatchEvent(new CustomEvent('tableProductChanges',  { bubbles:true, composed:true,detail:  copyData} ));
        this.emitTableChanges(copyData);

        this.dispatchEvent(new ShowToastEvent({
          title: DUPLICATE_ERROR_TITTLE,
          message: DUPLICATE_ERROR_MESSAGE,
          variant: "error"
        }));
      }
      else
      {
        this.updateDataValues(updatedItem);
      }
    }

    isUntouchedPlaceholderRow(item) {
        return !item.userName && !item.userId && !item.teamRoleValue;
    }

    applyCoverageRoles(rows) {
    const roles = this.coverageRolesByUser || {};
    return rows.map(row => ({
      ...row,
      coverageRole: (row.userId && roles[row.userId]) || ''
    }));
  }

    async loadCoverageRoles() {
      if (!this.recordId) {
        this.coverageRolesByUser = {};
        return;
      }
      try {
        this.coverageRolesByUser = (await getCoverageTeamRoles({ recordId: this.recordId })) || {};
      } catch (error) {
        console.error('Error loading Coverage Team roles', error);
        this.coverageRolesByUser = {};
      }
      if (this.tableData) {
        this.tableData = this.applyCoverageRoles(this.tableData);
      }
    }

    emitTableChanges(rows) {
      const clean = rows.map(({ coverageRole, ...rest }) => rest);
      this.dispatchEvent(new CustomEvent('tableProductChanges', { bubbles: true, composed: true, detail: clean }));
    }

    updateDataValues(updateItem) {
        let copyData = this.copiarLista(this.tableData);
        this.startLoading();
        let thereIsEmptyElement = false;
        copyData.forEach(item => {
          if (updateItem.Id !== item.Id && !this.isUntouchedPlaceholderRow(item) && (!item.AccessLevel || !item.userName)) {
            thereIsEmptyElement = true;
          }
            else if (item.Id === updateItem.Id) {
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
                //CIBGLOBALD-1265 the condition is updated
                if (!item.userName) {
                //if (!item.AccessLevel || !item.userName) {
                  thereIsEmptyElement = true;
                }
            }
        });
        //write changes back to original data
        //this.dispatchEvent(new CustomEvent('tableProductChanges',  { bubbles:true, composed:true,detail:  copyData} ));
        this.emitTableChanges(copyData);
        if (!thereIsEmptyElement) {
          //this.dispatchEvent(new CustomEvent('editModeOff',  { bubbles:true, composed:true} ));
        //} else {
          this.dispatchEvent(new CustomEvent('editModeOn',  { bubbles:true, composed:true} ));
        }
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
      this.startLoading();
      let dataRecieved = event.detail.data;
      let updatedItem;
      updatedItem = { Id: dataRecieved.context};
      updatedItem[dataRecieved.fieldname] = dataRecieved.value;
      if (dataRecieved.fieldname == 'userName') {
        let name = this.pickListOrder.find(({value}) => value === dataRecieved.value)?.label;
        updatedItem.Name = name;
      }


      let duplicatedElement = false;
      this.tableData.forEach(item => {
        if (item.userName && updatedItem.userName && item.userName === updatedItem.userName) {
          duplicatedElement = true;
          return;
        }
      });

      if (duplicatedElement) {
        let copyData = this.tableData.filter(function(item) {
          return item.Id !== updatedItem.Id
        })
        this.startLoading();
        //this.dispatchEvent(new CustomEvent('tableProductChanges',  { bubbles:true, composed:true,detail:  copyData} ));
        this.emitTableChanges(copyData);

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

    picklistChanged(event) {
        event.stopPropagation();
        let dataRecieved = event.detail.data;
        let updatedItem;
        if(dataRecieved.fieldname == 'AccessLevel') {
        updatedItem = { Id: dataRecieved.context, AccessLevel: dataRecieved.value };
           this.updateDataValues(updatedItem);
        }else if(dataRecieved.fieldname == 'teamRoleValue'){
           updatedItem = { Id: dataRecieved.context, teamRoleValue: dataRecieved.value };
           this.updateDataValues(updatedItem);
        }
        //this.updateDraftValues(updatedItem);
    }

    //handler to handle cell changes & update values in draft values
    handleCellChange(event) {
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
        this.startLoading();
        switch (action.name) {
            case 'deleteRecord':
                let copyData = this.tableData.filter(function(item) {
                    return item.Id !== row.Id
                })
                let thereIsEmptyElement = false;
                let j = 0;
                copyData.forEach((element) => {
                  element.Id = j;
                  j++;
                  //CIBGLOBALD-1265 the condition is updated
                  if ( !element.userName) {
                  //if (!element.AccessLevel || !element.userName) {
                    thereIsEmptyElement = true;
                  }
                });
                this.tableData = undefined;
                //this.dispatchEvent(new CustomEvent('tableProductChanges',  { bubbles:true, composed:true,detail:  copyData} ));
                this.emitTableChanges(copyData);
                if (!thereIsEmptyElement) {
                  //this.dispatchEvent(new CustomEvent('editModeOff',  { bubbles:true, composed:true} ));
                //} else {
                  this.dispatchEvent(new CustomEvent('editModeOn',  { bubbles:true, composed:true} ));
                }
                break;
            case 'addRecord':
                const index = this.tableData.findIndex(dataRow => dataRow.Id === row.Id);
                let copyTable = JSON.parse(JSON.stringify(this.tableData));
                let i = 0;
                let copyDataNew = [];
                copyTable.forEach((element) => {
                  element.Id = i;
                  copyDataNew.push(element);
                  if (i == index) {
                    i++;
                    copyDataNew.push( {
                      "AccessLevel": "Read",
                      "userName": "",
                      "showReadOnlyWarning": false,
                      "Id": i,
                      "recordId":this.recordId,
                      "field1": "",
                      "field2": "",
                      "fieldHistory" : '{"field1" : "", "field2": ""}'
                    });
                  }
                  i++;
                });
                this.tableData = undefined;
                /*let copyDataNew = [
                  ...this.tableData.slice(0, index+1),
                  {
                    "AccessLevel": "",
                    "userName": "",
                    "Id": index + 1,
                    "recordId":this.recordId,
                    "field1": "",
                    "field2": "",
                    "fieldHistory" : '{"field1" : "", "field2": ""}'
                  },
                  ...this.tableData.slice(index+1)
              ];
              let i = 0;
                copyDataNew.forEach((element) => {
                  element.Id = i;
                  i++;
                });*/
              //this.dispatchEvent(new CustomEvent('tableProductChanges',  { bubbles:true, composed:true,detail:  copyDataNew} ));
              this.emitTableChanges(copyDataNew);
              //this.dispatchEvent(new CustomEvent('editModeOff',  { bubbles:true, composed:true} ));
            break;
            case 'addOppTeamMember':
              this.isModalOpen = true;
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
}