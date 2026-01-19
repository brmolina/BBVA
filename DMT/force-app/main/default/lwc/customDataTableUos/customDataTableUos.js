import { LightningElement,track, api } from 'lwc';
import searchUOs from '@salesforce/apex/DES_UOS_Utils.getUsersByUos';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CustomDataTableUos extends LightningElement {
    isSearchModalOpen=false;
    isUOModalOpen=false;
    mapRolesAccess = null;
    isButtonDisabled;
    currentUserInfo  = null; 
    UOsUsers;
    searchValue;
    noResults = false;
    @track tableData=[]; //Info que se pinta en la tabla: uos, acces level
    tableDataApproversUsers  = null; //Approvers member recibidos de la flexcard, o que se añaden
    @track uosUsersAdded = new Map(); //Mapa de usuarios agrupados por uos
    showUosTable = false;
    @track buttonAddDisabled = true;
    selectedUOUsers;
    UOSModalHeader;
    accessLevel  = null;
    columns;
    pickListFields = [{label: 'Line Name', value: 'DMT_Line__r.Name'}, {label: 'Line Term', value: 'DMT_Line__r.Line_Term__c'}, {label: 'Line Type', value: 'DMT_Line__r.Product__c'}, {label: 'Opportunity Name', value: 'opportunity_id__r.Name'}, {label: 'Opportunity Status of Action', value: 'opportunity_id__r.StageName'}, {label: 'Opportunity Type', value: 'opportunity_id__r.Type'}];
    picklistField1 = JSON.parse(JSON.stringify(this.pickListFields));
    picklistField2 = JSON.parse(JSON.stringify(this.pickListFields));
    @api recordId;
    procesado = false;
    _tableDataApproversUsers = null;
    columnsReadOnly = [
      { label: 'Name', fieldName: 'Name' },
      { label: 'User Name', fieldName: 'userName', type: 'text' }
  ];

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
  return this.tableDataApproversUsers;
}

set tableDataName(value) {
  this.procesado = false;
  this._tableDataApproversUsers = value;
  this.tryProcess();
}

  isDataReady() {
    return this._tableDataApproversUsers !== null &&
      this.currentUserInfo !== null &&
      this.mapRolesAccess !== null &&
      this.accessLevel !== null
  }



    tryProcess() {      
        if (this.isDataReady() && !this.procesado) {
            this.processTableData(this._tableDataApproversUsers );
            this.procesado = true;
        }

    }

  processTableData(value) {
  
  let valueCopy = JSON.parse(JSON.stringify(value));
  valueCopy= valueCopy.filter((element) => element.hasOwnProperty('Uos') && element.Uos != null);
  this.uosUsersAdded=new Map();
  // Agrupar usuarios en el mapa
  valueCopy.forEach(teamMember => {
    const key = teamMember.Uos; // Usar el campo `uos` como clave
    if (!this.uosUsersAdded.has(key)) {
        this.uosUsersAdded.set(key, []); // Inicializar un array si no existe
    }
    if (teamMember.hasOwnProperty('fieldHistory') && teamMember.fieldHistory) {
      const fieldHistory = JSON.parse(teamMember.fieldHistory);
      teamMember['field1'] = fieldHistory.field1 + '';
      teamMember['field2'] = fieldHistory.field2 + '';
      teamMember['field1Label'] = this.pickListFields.find((el) => el.value == teamMember['field1'])?.label;
      teamMember['field2Label'] = this.pickListFields.find((el) => el.value == teamMember['field2'])?.label;
    }
    this.uosUsersAdded.get(key).push(teamMember); // Añadir el usuario al array correspondiente
  });

  let tableDataCopy = [];

  for (const [uos, teamMembers] of this.uosUsersAdded.entries()) {

    tableDataCopy.push({
      Id:tableDataCopy.length+1,
      UosCode: uos,
      AccessLevel: teamMembers[0].AccessLevel,
      field1Label: teamMembers[0].field1Label,
      field1: teamMembers[0].field1,
      field2: teamMembers[0].field2,
      field2Label: teamMembers[0].field2Label
      });

  }


  if( tableDataCopy != null && tableDataCopy.length > 0 ){
    this.showUosTable=true;
  }else{
    this.showUosTable=false;
  }
  
  this.tableDataApproversUsers = valueCopy;
  this.tableData = [...tableDataCopy];

  //Se añade la propiedad buttondisabled a los approver member
  this.tableDataApproversUsers = this.tableDataApproversUsers.map((acc) => ({ ...acc, buttonDisabled: acc.AccessLevel == 'All' }));
  this.dispatchEvent(new CustomEvent('uosMembersEvent',  { bubbles:true, composed:true,detail: this.tableDataApproversUsers} ));

  this.setColumns();
}

    @api
    get  accessLevelOptions() {
      return this.accessLevel;
    }
  
    set accessLevelOptions(value) {
      this.accessLevel = value;
      this.setColumns();
      this.tryProcess();

    }

    openSearchModal(){
      this.isSearchModalOpen=true;
    }

    handleUoSave() {
      this.addOperativeUnit();
      this.isSearchModalOpen = false;
    }

    handleSearchModalClose() {
      this.isSearchModalOpen = false;
      this.UOsUsers = undefined;
    }

    searchKeyword(event) {
      this.searchValue = event.target.value;
      this.buttonAddDisabled = true;
  }

  setColumns(){ 
    let readOnlyAccessCurrentUser = !this.hasFullAccess(this.currentUserInfo?.DMT_User_Role__c);
    this.isButtonDisabled = readOnlyAccessCurrentUser;
    this.columns= [
      { label: 'Operative Unit', fieldName: 'UosCode', type:'button', hideDefaultActions:true, typeAttributes: {
        label: { fieldName: 'UosCode' },
        name: 'view_users',
        variant: 'base'
    } 
    },
    { label: 'ACCESS LEVEL', fieldName: 'AccessLevel', type:'picklist',hideDefaultActions:true, typeAttributes: { isDisabled : readOnlyAccessCurrentUser,
      placeholder: 'Select...', options: this.accessLevel, fieldName: 'AccessLevel' // list of all picklist options
      , value: { fieldName: 'AccessLevel' } // default value for picklist
      , context: { fieldName: 'Id' } // binding account Id with context variable to be returned back
    }},
    { label: 'FIELD 1', fieldName: 'field1', type:'searchcombobox',hideDefaultActions:true , typeAttributes: { isDisabled : readOnlyAccessCurrentUser,fieldName: 'field1', pickListOrdered: this.picklistField1, selectedSearchvalue:  { fieldName: 'field1' }, selectedSearchlabel:  { fieldName: 'field1Label' }, context: { fieldName: 'Id' }}},  
      { label: 'FIELD 2', fieldName: 'field2', type:'searchcombobox',hideDefaultActions:true ,  typeAttributes: {isDisabled : readOnlyAccessCurrentUser,fieldName: 'field2', pickListOrdered: this.picklistField2, selectedSearchvalue:  { fieldName: 'field2' }, selectedSearchlabel:  { fieldName: 'field2Label' }, context: { fieldName: 'Id' }}},
      {
        type:  'button',
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
    ];
  }

    handleSearch(event){
      const searchTerm = this.searchValue;

      if (searchTerm) {
        searchUOs({ searchedUosId: searchTerm })
            .then(result => {
                this.UOsUsers = result.length === 0 ? undefined: result;
                this.noResults = result.length === 0;
                this.buttonAddDisabled = result.length === 0 ? true:false;

                const modal = this.template.querySelector('c-dmt-uos-search-modal');
                if (modal) {
                  modal.updateButtonState(this.buttonAddDisabled);
                }
            })
            .catch(error => {
                console.error('Error searching users: ', error);
                this.UOsUsers = undefined;
                this.noResults = true;

                const modal = this.template.querySelector('c-dmt-uos-search-modal');
                if (modal) {
                  modal.updateButtonState(true);
                }
            });
      } else {
          this.UOsUsers = undefined;
          this.noResults = true;
          const modal = this.template.querySelector('c-dmt-uos-search-modal');
          if (modal) {
            modal.updateButtonState(true);
          }
      }

    }

    addOperativeUnit(){
      let copyDataApprovers = this.copiarLista(this.tableDataApproversUsers);

      //Si no hay usuarios encontrados no añado
      if(this.UOsUsers!== undefined && this.UOsUsers.length!== 0){
        this.uosUsersAdded.set(this.searchValue,this.UOsUsers);
        //Comprobamos que el uso no existe ya en nuestra tabla
        let result = this.tableData.filter(u => u.UosCode === this.searchValue);
        if (result == '' || result == undefined || result == null || result.length == 0) {
         
          this.tableData.push({
            Id:this.tableData.length+1,
            UosCode: this.searchValue
          });

          this.tableData= [... this.tableData];

          this.dispatchEvent(
            new ShowToastEvent({
            title: "Success",
            message: 'The UO has been added to the list',
            variant: "success",
          }));

          //Itero el mapa uos-users para añadir approberMembers al array con la estructura correcta de campos
            this.UOsUsers.forEach(user => {

              copyDataApprovers.push(
                {
                  "AccessLevel": "Read",
                  "Name": user.Name,
                  "userName": user.userName,
                  "Id": copyDataApprovers.length + 1,
                  "recordId":this.recordId,
                  "field1": "",
                  "field2": "",
                  "fieldHistory" : '{"field1" : "", "field2": ""}',
                  "Uos" : this.searchValue
                }
              );

            });

          //la tabla recibida de la flexcard, mas los nuevos approvers members del uos añadidos
          this.dispatchEvent(new CustomEvent('uosMembersEvent',  { bubbles:true, composed:true,detail:  copyDataApprovers} ));
          

        } else {
          this.dispatchEvent(
            new ShowToastEvent({
            title: "Error",
            message: 'The UO is already on the list',
            variant: "error",
          }));
        }
        this.showUosTable=true;
        this.buttonAddDisabled = true;
      }

    }

    handleRowAction(event) {
      const action = event.detail.action;
        const row = event.detail.row;
        switch (action.name) {
            case 'deleteRecord':
                this.removeUOSFromTable(row.Id);
              break;
            case 'view_users':
              this.UOSModalHeader = 'UO ' + event.detail.row.UosCode;
              this.selectedUOUsers = this.uosUsersAdded.get(event.detail.row.UosCode);
              this.isUOModalOpen = true;
              break;
        }
    }


    viewRecord(event) {
      this.UOSModalHeader = 'UO ' + event.detail.row.UosCode;
      this.selectedUOUsers = this.uosUsersAdded.get(event.detail.row.UosCode);
      this.isUOModalOpen = true;
    }

    handleUOModalClose() {
      this.selectedUOUsers = null;
      this.isUOModalOpen = false;
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

    picklistChanged(event) {
      event.stopPropagation();
      let dataRecieved = event.detail.data;
      let updatedItem;
      updatedItem = { Id: dataRecieved.context, AccessLevel: dataRecieved.value };
      //this.updateDraftValues(updatedItem);
      this.updateDataValues(updatedItem);
  }

  updateDataValues(updateItem) {
    let copyData = this.copiarLista(this.tableData);
    copyData.forEach(item => {
        if (item.Id === updateItem.Id) {
            let approversFromUOS = this.tableDataApproversUsers.filter((approver) => approver.Uos == item.UosCode);
              for (let field in updateItem) {
                if (field != 'Id') {
                approversFromUOS.forEach((approver) => {
                  approver[field] = updateItem[field];
                  if (field.includes("field")) {
                    if (!approver["fieldHistory"]) {
                      approver["fieldHistory"] = '{"field1" : "", "field2": ""}';
                    }
                    let copyFieldHistory = JSON.parse(approver["fieldHistory"]);
                    copyFieldHistory[field] = updateItem[field];
                    approver["fieldHistory"] = JSON.stringify(copyFieldHistory);
                  }
                });
              }
            }
            let result;
            let copyTableDataApprovers = this.copiarLista(this.tableDataApproversUsers);
            approversFromUOS.forEach((approver) => {
              result = copyTableDataApprovers.map((item) => item.Id === approver.Id ? approver : item);
              copyTableDataApprovers = this.copiarLista(result);
            });

            this.tableDataApproversUsers = this.copiarLista(copyTableDataApprovers);
        }
    });

    //write changes back to original data
    this.dispatchEvent(new CustomEvent('uosMembersEvent',  { bubbles:true, composed:true,detail: this.tableDataApproversUsers} ));
}

  removeUOSFromTable(rowId) {

    let uosRemoved = this.tableData.find((item) => item.Id == rowId);

    let approversFromUOS = this.tableDataApproversUsers.filter((approver) => approver.Uos != uosRemoved.UosCode);

    this.tableDataApproversUsers = this.copiarLista(approversFromUOS);

    this.dispatchEvent(new CustomEvent('uosMembersEvent',  { bubbles:true, composed:true,detail: this.tableDataApproversUsers} ));

    let copyData = this.tableData.filter(function(item) {
      return item.Id !== rowId
    })
    this.tableData = [...copyData];


  }

  comboboxChange(event) {
    event.stopPropagation();
    let dataRecieved = event.detail.data;
    let updatedItem;
    updatedItem = { Id: dataRecieved.context};
    updatedItem[dataRecieved.fieldname] = dataRecieved.value;

    
    let duplicatedElement = false;
    this.tableData.forEach(item => {
      if (item.userName === updatedItem.userName) {
        duplicatedElement = true;
        return;
      }
    });

    this.updateDataValues(updatedItem);
    
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