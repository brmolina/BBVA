import { LightningElement, track, api, wire } from 'lwc';
import buttonClass from "./dmTGetTableCreateView.css";

export default class DMTGetTableCreateView extends LightningElement {

    Options;
    columns;
    addSectionRes;
    @api tableType;
    //have this attribute to track data changed
    //with custom picklist or custom lookup
    @track draftValues = [];
    @api
    get  addSection() {
      return this.addSectionRes;
    }
  
    set addSection(value) {
        console.log("buttonClass buttonClass "+ buttonClass);
        if(value.toLowerCase() === 'true'){
           this.addNewSection();

        }
      this.addSectionRes = 'false';
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
    get  sectionOptionsName() {
      return this.sectionOptions;
    }
  
    set sectionOptionsName(value) {
      this.sectionOptions = value;
      this.setColumns();
    }

    lastSavedData = [];
    setColumns(){
    this.columns = [
        { label: 'Section', fieldName: 'Name', type:'picklist',hideDefaultActions:true , typeAttributes: {
            placeholder: 'Select...', options: this.sectionOptions, fieldName: 'Name' // list of all picklist options
            , value: { fieldName: 'Name' } // default value for picklist
            , context: { fieldName: 'Id' } // binding account Id with context variable to be returned back
        }},,
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
        this.dispatchEvent(new CustomEvent('tableSectionChanges',  { bubbles:true, composed:true,detail:  copyData} ));
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
        if( dataRecieved.fieldname === 'Name'){
            updatedItem = { Id: dataRecieved.context, Section_Code__c: dataRecieved.value };
        }
        console.log('updatedItemdvdv',JSON.stringify(updatedItem));
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
                this.dispatchEvent(new CustomEvent('deleteSection',  { bubbles:true, composed:true,detail:  copyData} ));console.log('deleteRecord',copyData);
                break;
            case 'addRecord':
              const index = this.tableData.findIndex(dataRow => dataRow.Id === row.Id);console.log('index',index);
              let copyDataNew = [
                ...this.tableData.slice(0, index+1),
                {
                  "Max_Tenor_WOC__c": "",
                  "Line__c": "",
                  "Id": index+1,
                  "Name": ""
                },
                ...this.tableData.slice(index+1)
            ];
            this.dispatchEvent(new CustomEvent('tableSectionChanges',  { bubbles:true, composed:true,detail:  copyDataNew} ));console.log('addRecord',copyDataNew);
                break;
        }
    }

    addNewSection(){console.log('adne')
        let copyData = this.copiarLista(this.tableData);
        let nextId = copyData.length + 1;
        copyData.push({
            "Id": nextId.toString() ,
          });console.log('copyData',copyData)
          this.dispatchEvent(new CustomEvent('tableSectionChanges',  { bubbles:true, composed:true,detail:  copyData} ));
    }
}