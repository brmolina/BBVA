import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { publish, MessageContext, subscribe, unsubscribe } from 'lightning/messageService';
import XSELL_SYNC_CHANNEL from '@salesforce/messageChannel/DmtXSellSync__c';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecordUi } from 'lightning/uiRecordApi';
import getXSellRecords from '@salesforce/apex/DMT_XSell.getXSellRecords';
import getGeographyOptions from '@salesforce/apex/DMT_XSell.getGeographyOptions';
import pubsub from 'omnistudio/pubsub';
import saveXSellRecords from '@salesforce/apex/DMT_XSell.saveXSellRecords';
  
  export default class Dmt_table_xsell extends LightningElement {
  
    @wire(MessageContext)
    messageContext;

    subscription = null;

    @api tabletype;
    @api idListToDelete = [];
    @api oppState;
    @api columnstablecopypaste = [];
    
    _isEditMode = false;
    
    @api
    get isEditMode() { 
      return this._isEditMode; 
    }
    set isEditMode(value) {
      const newEditMode = (typeof value === 'boolean') ? value : (String(value).toLowerCase() === 'true');
      
      if (this._isEditMode !== newEditMode) {
          this._isEditMode = newEditMode;
          this.refreshButtonStates();
      }
    }

    /**
     * Dynamically updates row-level button disabled states whenever isEditMode changes.
     * Ensures Delete/Add buttons lock/unlock instantly without needing an Apex refresh.
     */
    refreshButtonStates() {
        if (!this.tableData || this.tableData.length === 0) return;
        
        const isDraft = this._parentType === 'Account' ? true : (this.oppState == 'Draft');
        
        let updatedData = this.deepCloneArray(this.tableData);
        
        updatedData.forEach((item, index) => {
            // Delete is strictly locked to Edit Mode
            item.deleteDisabled = !this._isEditMode;
            item.editRecordDisabled = !isDraft;
            
            // The Add (+) button is only active on the last row AND only in Edit Mode
            if (index === updatedData.length - 1) {
                item.buttonDisabled = !this._isEditMode || !isDraft;
            } else {
                item.buttonDisabled = true;
            }
        });
        
        // Re-assign to force the Lightning Datatable to re-render the rows
        this.tableData = updatedData;
    }
    
    _isReadOnlyUser = false;
    currentYear = new Date().getFullYear();
    _recordId;
    _parentType;
    currentRecordId; // Reactive variable to trigger the LDS wire

    /**
     * Hack to add empty space below the table on Account pages so the 
     * OmniStudio sticky footer doesn't overlap the component.
     */
    get bottomSpacerStyle() {
        return this._parentType === 'Account' ? 'height: 100px; display: block; width: 100%;' : 'display: none;';
    }

    connectedCallback() {
        pubsub.register('Save', { DMT_CLIENT_GROUP_V2: this.handleFlexCardSave.bind(this) });
        pubsub.register('Button', { Reload: this.handleGetXsellRecords.bind(this) });
        pubsub.register('Button', { Edit: this.toggleEditMode.bind(this) });
        if (!this.subscription) {
          this.subscription = subscribe(
              this.messageContext,
              XSELL_SYNC_CHANNEL,
              (message) => this.handleLmsMessage(message)
          );
      }
    }

    disconnectedCallback() {
        pubsub.unregister('Save', { DMT_CLIENT_GROUP_V2: this.handleFlexCardSave.bind(this) });
        pubsub.unregister('Button', { Reload: this.handleGetXsellRecords.bind(this) });
        pubsub.unregister('Button', { Edit: this.toggleEditMode.bind(this) });
        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
        }
    }

    toggleEditMode(isEditing) {
        this._isEditMode = isEditing;
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            const urlId = currentPageReference.state?.recordId || currentPageReference.state?.c__recordId || currentPageReference.attributes?.recordId;
            if (urlId && this.currentRecordId !== urlId) {
                this.currentRecordId = urlId;
                this._recordId = urlId; // Preserve existing reference
            }
        }
    }

    _entityCode; // Stores the DMT_Entity__c for the Apex query
    _isOptionsLoaded = false; // BUFFER FLAG
    _pendingXSellData = null; // BUFFER DATA

    // Step 1: Detect object type and extract Entity Code using LDS
    @wire(getRecordUi, { recordIds: '$currentRecordId', layoutTypes: ['Full'], modes: ['View'] })
    async wiredRecordUi({ error, data }) {
        if (data) {
            const record = data.records[this.currentRecordId];
            this._parentType = record.apiName;
            this._entityCode = record.fields.DMT_Entity__c ? record.fields.DMT_Entity__c.value : null;
                        
            try {
                this.geographyOptions = await getGeographyOptions({ entityCode: this._entityCode });
                this._isOptionsLoaded = true;
                this.processTableData(); // UNBLOCK THE BUFFER NOW THAT WE HAVE LABELS
            } catch (err) {
                console.error('Error fetching Geography Options:', err);
                this._isOptionsLoaded = true; // Unblock to prevent infinite freeze
                this.processTableData();
            }

            this.handleGetXsellRecords(); // Native fetch for BOTH Account and Opportunity
            
        } else if (error) {
            console.error('Error retrieving object info via LDS:', error);
        }
    }

    _requestTotalsPending = false;

    handleLmsMessage(message) {
        if (message.action === 'REQUEST_TOTALS') {

            if (!this.tableData || this.tableData.length === 0) {
                this._requestTotalsPending = true;
                return;
            }

            this.broadcastToSibling(
                this._cleanForParent(this.tableData)
            );
        }
    }

    async handleGetXsellRecords() {
        
        this.idListToDelete = [];
        this._pendingXSellData = null; 

        try {
            const dataResult = await getXSellRecords({ parentId: this._recordId });
            
            // DIRECT HANDOFF: Feed the buffer and force processing
            this._pendingXSellData = dataResult;
            this.processTableData();
            
        } catch (error) {
            console.error('[XSELL-LWC] ERROR fetching Native Data:', error);
        }
    }

    @api 
    get isReadOnlyUser(){ 
      return this._isReadOnlyUser; 
    } 
    set isReadOnlyUser(value){
        if (value === 'true') {
              this._isReadOnlyUser = true; 
        } else if (value === 'false') { 
            this._isReadOnlyUser = false;
        } else if (typeof value === 'boolean') {
          this._isReadOnlyUser = value;
        } else {
              this._isReadOnlyUser = Boolean(value); 
        } 
    }
    
    bookingGeography;
    geographyOptions = [];
    @track tableData = [];

    /**
     * Injects the parsed geography taxonomy options and resolves the display 
     * labels for the current table rows. Required for the genericrecordpicker 
     * and read-only text displays.
     */
    injectGeographyData() {
      if (!this.tableData || this.tableData.length === 0) return;
      
      this.tableData = this.tableData.map(row => {
        let label = row.Booking_Geography__c || '';
        if (this.geographyOptions && this.geographyOptions.length > 0) {
          let matchedOpt = this.geographyOptions.find(opt => opt.value === row.Booking_Geography__c);
          if (matchedOpt) {
            label = matchedOpt.label;
          } else {
             console.warn(`[MAPPER-DEBUG] WARNING: No label match found in options for code: ${row.Booking_Geography__c}`);
          }
        }

        return {
          ...row,
          GeographyLabel__c: label,
          geographyOptions: this.geographyOptions
        };
      });
    }
    
    @api
    get xSellList() {
      return this.tableData;
    }

    // Centralized processor that only runs when BOTH the data and the options are ready
    processTableData() {
        
      if (!this._isOptionsLoaded || !this._pendingXSellData) {
          console.info('[XSELL-LWC] 3a. BUFFER ACTIVE: Waiting for either options or data to finish loading.');
          return;
      }

      let value = this._pendingXSellData;
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
          normalizedData = [];
        }
      } catch (e) {
        console.error('Error al procesar table:', e);
        normalizedData = [];
      }
      
      if (normalizedData.length > 0) {
        const newArray = normalizedData.map((item, index) => {
          const newItem = { ...item };
          const isDraft = this._parentType === 'Account' ? true : (this.oppState == 'Draft');
          
          // Explicitly tie the disabled state to the component's _isEditMode flag
          newItem.deleteDisabled = !this._isEditMode;
          newItem.editRecordDisabled = !isDraft;
          
          // CRITICAL FIX: Lock the Add button if in View Mode OR if not a Draft
          if (index === normalizedData.length - 1) {
            newItem.buttonDisabled = !this._isEditMode || !isDraft;
          } else {
            newItem.buttonDisabled = true;
          }
          
          // CRITICAL: Restore unique temporary IDs so datatable rows don't corrupt
          if (!newItem.Id || newItem.Id === "0") {
            newItem.Id = "NEW_" + Date.now() + Math.floor(Math.random() * 10000) + index;
            if (this._parentType === 'Account') {
                newItem.account = this._recordId;
            } else {
                newItem.opportunity = this._recordId;
            }
          }

          newItem.aviableItem = false; 
          return newItem;
        });
        this.tableData = newArray;
        this.injectGeographyData();
      } else {
        const isDraft = this._parentType === 'Account' ? true : (this.oppState == 'Draft');
        
        this.tableData = [{
            Id: "NEW_" + Date.now() + Math.floor(Math.random() * 10000), // Restore unique ID
            Booking_Geography__c: "",
            GeographyLabel__c: "",
            XSELL_Value_PY__c: null,
            XSELL_Value_CY__c: null,
            XSELL_Value_NY__c: null,
            XSELL_Value_NY1__c: null,
            initRead: true,
            tabletype: 'Derivatives',
            buttonDisabled: !this._isEditMode || !isDraft,
            deleteDisabled: true, // Ghost row: Delete is ALWAYS disabled
            editRecordDisabled: !isDraft,
            aviableItem: false,
            geographyOptions: this.geographyOptions || [],
            opportunity: this._parentType === 'Account' ? null : this._recordId,
            account: this._parentType === 'Account' ? this._recordId : null
        }];
      }

      if (this._requestTotalsPending) {
            this._requestTotalsPending = false;

            this.broadcastToSibling(
                this._cleanForParent(this.tableData)
            );
      }
    }
    
    /**
     * Dispatches a unique event to notify the parent framework/FlexCard 
     * to swap between the View and Edit mode components without conflicting with other tables.
     */
    notifyEditMode(value) {
        if (this._parentType === 'Account') {
            pubsub.fire('DMT_CLIENT_GROUP_V2', 'xsellEditMode', { editMode: value });
        } else {
            this.dispatchEvent(new CustomEvent('xsellEditModeTab', {
                detail   : { editMode: value },
                bubbles  : true,
                composed : true
            }));
        }
    }
    
    broadcastToSibling(cleanData) {

      // Remove completely empty placeholder rows before sending to LMS
      const filteredData = (cleanData || []).filter(row => {
          const hasGeo =
              row.Booking_Geography__c &&
              String(row.Booking_Geography__c).trim() !== '';

          const hasNumbers =
              row.XSELL_Value_PY__c != null ||
              row.XSELL_Value_CY__c != null ||
              row.XSELL_Value_NY__c != null ||
              row.XSELL_Value_NY1__c != null;

          return hasGeo || hasNumbers;
      });

     // const filteredData = cleanData || [];

      let totals = { PY: 0, CY: 0, NY: 0, NY1: 0 };

      filteredData.forEach(row => {
          totals.PY += (Number(row.XSELL_Value_PY__c) || 0);
          totals.CY += (Number(row.XSELL_Value_CY__c) || 0);
          totals.NY += (Number(row.XSELL_Value_NY__c) || 0);
          totals.NY1 += (Number(row.XSELL_Value_NY1__c) || 0);
      });

      publish(this.messageContext, XSELL_SYNC_CHANNEL, {
          PY: totals.PY,
          CY: totals.CY,
          NY: totals.NY,
          NY1: totals.NY1,
          xsellData: filteredData,
          xsellDelete: this.idListToDelete
      });
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        switch (action.name) {
            case 'editRecord':
                this.isEditMode = true;
                this.notifyEditMode(true);
                break;
                
            case 'deleteRecord':
                if (typeof this.idListToDelete === 'string') {
                  this.idListToDelete = [];
                }
                
                // Prevent temporary 'NEW_' IDs from sneaking into the Apex delete list
                if (row.Id && String(row.Id).length >= 15 && row.Id !== '0' && !String(row.Id).startsWith('NEW_')) {
                    this.idListToDelete = [...this.idListToDelete, row.Id];
                }

                const tableType = this.tableData[0] ? this.tableData[0]['tabletype'] : 'Derivatives';
                let copyData = this.tableData.filter(function(item) {
                    return item.Id !== row.Id;
                });
                
                let sendcopyData = this.deepCloneArray(copyData);
                if (sendcopyData.length > 0) {
                  sendcopyData.forEach(item => item.buttonDisabled = true);
                  
                  sendcopyData[sendcopyData.length - 1].buttonDisabled = false;
                  sendcopyData[sendcopyData.length - 1].pickDisabled = false;
                  sendcopyData[sendcopyData.length - 1].deleteDisabled = false;
                }
                
                if(sendcopyData.length == 0){
                  const newItem = new Object();
                  newItem.buttonDisabled = false;
                  newItem.pickDisabled = false;
                  newItem.Id = "NEW_" + Date.now() + Math.floor(Math.random() * 10000); // Restore unique ID
                  if (this._parentType === 'Account') {
                      newItem.account = this._recordId;
                  } else {
                      newItem.opportunity = this._recordId;
                  }                    
                  newItem.deleteDisabled = true; // Ghost row: Delete is ALWAYS disabled
                  sendcopyData.push(newItem);
                }
                
                // UPDATE LOCAL STATE IMMEDIATELY so the row disappears from the screen
                this.tableData = sendcopyData;
                this.injectGeographyData();
                
                const cleanDeleteData = this._cleanForParent(sendcopyData);
                this.broadcastToSibling(cleanDeleteData);
                if(this._parentType === 'Account'){
                    this.notifyEditMode(true);
                }
                break;
                
            case 'addRecord':
              const newTempId = 'NEW_' + Date.now() + Math.floor(Math.random() * 1000); 
              let sendcopyDataNew = this.deepCloneArray(this.tableData);
              
              // ALWAYS push to the end to prevent DOM recycling glitches
              sendcopyDataNew.push({
                  "Id": newTempId,
                  "Booking_Geography__c": "",
                  "GeographyLabel__c": "",
                  "XSELL_Value_PY__c": null,
                  "XSELL_Value_CY__c": null,
                  "XSELL_Value_NY__c": null,
                  "XSELL_Value_NY1__c": null,
                  "initRead": true,
                  "tabletype": sendcopyDataNew.length > 0 ? sendcopyDataNew[sendcopyDataNew.length - 1]["tabletype"] : 'Derivatives',
                  "opportunity": this._parentType === 'Account' ? null : this._recordId,
                  "account": this._parentType === 'Account' ? this._recordId : null,
                  "deleteDisabled": false,
                  "buttonDisabled": false,
                  "pickDisabled": false,
                  "editRecordDisabled": false,
                  "aviableItem": false,
                  "geographyOptions": this.geographyOptions
              });
              
              // Only the last row gets the add button
              for (let i = 0; i < sendcopyDataNew.length; i++) {
                  sendcopyDataNew[i].buttonDisabled = (i !== sendcopyDataNew.length - 1);
                  sendcopyDataNew[i].pickDisabled = (i !== sendcopyDataNew.length - 1);
              }
              
              this.tableData = sendcopyDataNew;
              this.injectGeographyData();

              this.isEditMode = true;
             // this.notifyEditMode(true);

              const cleanAddData = this._cleanForParent(sendcopyDataNew);
              this.broadcastToSibling(cleanAddData);
              break;
        }
    }
    /**
     * Dynamically builds the datatable columns array based on current component state.
     * Toggles the Geography column between standard text (View Mode) and genericrecordpicker (Edit Mode).
     */
    get columns() {
      const isEdit = this._isEditMode;

      return [
        {
          fieldName: "GeographyLabel__c", // 1. Force label at the datatable root cell level
          label: "Geography",
          type: isEdit ? "genericrecordpicker" : "text",
          editable: false,
          hideDefaultActions: true,
          cellAttributes: { alignment: 'center' },
          typeAttributes: {
            placeholder: 'Select Geography...',
            options: { fieldName: 'geographyOptions' },
            value: { fieldName: 'GeographyLabel__c' }, // 2. THE FIX: Force label into the picker's internal text binding
            label: { fieldName: 'GeographyLabel__c' },
            inputValue: { fieldName: 'GeographyLabel__c' },
            fieldName: 'Booking_Geography__c', // 3. Keep this as the code! The event handler needs this to trigger the update.
            context: { fieldName: 'Id' },
            disabled: false
          }
        },
        {
          fieldName: "XSELL_Value_PY__c",
          label: `FY${this.currentYear - 1}`,
          type: isEdit ? "custominputRow" : 'number',
          editable: false,
          hideDefaultActions: true,
          cellAttributes: { alignment: 'center' },
          typeAttributes: {
            step: '0.01',
            value: { fieldName: 'XSELL_Value_PY__c' },
            inputValue: { fieldName: 'XSELL_Value_PY__c' },
            fieldName: 'XSELL_Value_PY__c',
            context: { fieldName: 'Id' },
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
          }
        },
        {
          fieldName: "XSELL_Value_CY__c",
          label: `FY${this.currentYear}`,
          type: isEdit ? "custominputRow" : 'number',
          editable: false,
          hideDefaultActions: true,
          cellAttributes: { alignment: 'center' },
          typeAttributes: {
            step: '0.01',
            value: { fieldName: 'XSELL_Value_CY__c' },
            inputValue: { fieldName: 'XSELL_Value_CY__c' },
            fieldName: 'XSELL_Value_CY__c',
            context: { fieldName: 'Id' },
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
          }
        },
        {
          fieldName: "XSELL_Value_NY__c",
          label: `FY${this.currentYear + 1}`,
          type: isEdit ? "custominputRow" : 'number',
          editable: false,
          hideDefaultActions: true,
          cellAttributes: { alignment: 'center' },
          typeAttributes: {
            step: '0.01',
            value: { fieldName: 'XSELL_Value_NY__c' },
            inputValue: { fieldName: 'XSELL_Value_NY__c' },
            fieldName: 'XSELL_Value_NY__c',
            context: { fieldName: 'Id' },
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
          }
        },
        {
          fieldName: "XSELL_Value_NY1__c",
          label: `FY${this.currentYear + 2}`,
          type: isEdit ? "custominputRow" : 'number',
          editable: false,
          hideDefaultActions: true,
          cellAttributes: { alignment: 'center' },
          typeAttributes: {
            step: '0.01',
            value: { fieldName: 'XSELL_Value_NY1__c' },
            inputValue: { fieldName: 'XSELL_Value_NY1__c' },
            fieldName: 'XSELL_Value_NY1__c',
            context: { fieldName: 'Id' },
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
          }
        },
        {
          type: 'button',
          hideDefaultActions: true,
          initialWidth: 60,
          cellAttributes: { alignment: 'center' },
          typeAttributes: { iconName: 'utility:delete', label: ' ', name: 'deleteRecord', title: '', disabled: {fieldName: 'deleteDisabled'}, iconPosition: 'center', value: 'test', variant: 'base' }
        },
        {
          type: 'button',
          hideDefaultActions: true,
          initialWidth: 60,
          cellAttributes: { alignment: 'center' },
          typeAttributes: { iconName: 'utility:edit', label: ' ', name: 'editRecord', title: '', disabled: {fieldName: 'editRecordDisabled'}, iconPosition: 'center', value: 'test', variant: 'base' }
        },
        {
          type: 'button',
          hideDefaultActions: true,
          initialWidth: 60,
          cellAttributes: { alignment: 'center' },
          typeAttributes: { iconName: 'utility:add', label: ' ', name: 'addRecord', title: ' ', disabled: {fieldName: 'buttonDisabled'}, iconPosition: 'center', value: 'test', variant: 'base' }
        }
      ];
    }

    /**
     * Catches the specific event fired by genericrecordpicker.
     * Updates the taxonomy code and label so it successfully attaches to the outbound payload.
     */
    handleRecordPickerChange(event) {
      event.stopPropagation();
      const { context, value, label, fieldname } = event.detail.data;
      
      if (fieldname === 'Booking_Geography__c') {
        this.updateDataValues({
          Id: context,
          Booking_Geography__c: value,
          GeographyLabel__c: label || ''
        });
      }
    }

    /**
     * Merges draft edits (text inputs, picklists) into the main tableData state.
     * Intercepts letters/special characters, showing a toast and forcing a UI re-render.
     */
    updateDataValues(updateItem) {
      
      const numFields = ['XSELL_Value_PY__c', 'XSELL_Value_CY__c', 'XSELL_Value_NY__c', 'XSELL_Value_NY1__c'];
      let hasInvalidChars = false;
      let invalidFields = [];

      // Validate numeric fields against letters and invalid special characters
      for (let field of numFields) {
        if (updateItem[field] !== undefined && updateItem[field] !== null && updateItem[field] !== '') {
          // If string contains anything other than digits, dots, commas, or minus signs
          if (/[^\d.,-]/.test(String(updateItem[field]))) {
            hasInvalidChars = true;
            invalidFields.push(field);
            delete updateItem[field]; // Strip the bad data
          }
        }
      }

      if (hasInvalidChars) {
        this.dispatchEvent(new ShowToastEvent({
          title: 'Invalid Input',
          message: 'Please enter a valid number. Letters are not allowed.',
          variant: 'warning'
        }));
        
        // Force LWC to clear the user's typed letters by breaking the old reference
        // and temporarily setting a dummy value, then reverting to the known valid value.
        let tempCopy = this.deepCloneArray(this.tableData);
        const idx = tempCopy.findIndex(item => item.Id === updateItem.Id);
        
        if (idx !== -1) {
            let originalVals = {};
            invalidFields.forEach(f => {
                originalVals[f] = tempCopy[idx][f];
                tempCopy[idx][f] = ' '; // Dummy delta to trigger reactivity
            });
            this.tableData = tempCopy;

            // Revert back to original valid values on the next event loop tick
            setTimeout(() => {
                let revertCopy = this.deepCloneArray(this.tableData);
                invalidFields.forEach(f => {
                    revertCopy[idx][f] = originalVals[f] || null;
                });
                this.tableData = revertCopy;
            }, 50); // 50ms delay ensures the DOM cycle processes the dummy delta
        }

        // If stripping the bad data left us with just the { Id }, abort the update entirely
        if (Object.keys(updateItem).length === 1) return;
      }
      
      let copyData = this.deepCloneArray(this.tableData);
      const indexToUpdate = copyData.findIndex(item => item.Id === updateItem.Id);

      if (indexToUpdate !== -1) {
        for (let key in updateItem) {
          if (updateItem[key] !== undefined) {
            copyData[indexToUpdate][key] = updateItem[key];
          }
        }
      }

      if (copyData.length > 0) {
        copyData[copyData.length - 1]['buttonDisabled'] = false;
      }
      
      // UNLOCK DELETE BUTTON: If user typed data into an empty row, enable the delete button
      copyData.forEach(row => {
          const hasData = row.Booking_Geography__c || row.XSELL_Value_PY__c != null || row.XSELL_Value_CY__c != null || row.XSELL_Value_NY__c != null || row.XSELL_Value_NY1__c != null;
          if (hasData && this._isEditMode) {
              row.deleteDisabled = false;
          }
      });

      this.tableData = copyData;

      // MANDATORY GEOGRAPHY REMINDER
      const isMissingGeo = copyData.some(row => {
          const hasNumbers = row.XSELL_Value_PY__c != null || row.XSELL_Value_CY__c != null || row.XSELL_Value_NY__c != null || row.XSELL_Value_NY1__c != null;
          const noGeo = !row.Booking_Geography__c || String(row.Booking_Geography__c).trim() === '';
          return hasNumbers && noGeo;
      });

      if (isMissingGeo) {
          this.dispatchEvent(new ShowToastEvent({
              title: 'Geography Required',
              message: 'Please remember to select a Geography for your Cross Sell entries.',
              variant: 'warning'
          }));
      }

      // NO redundant publish here. Just send data to the unified broadcast.
      const cleanData = this._cleanForParent(copyData);
      this.broadcastToSibling(cleanData);
    }

    /**
     * Sanitizes the data array before dispatching it to the FlexCard.
     * Strips UI-only state (like geographyOptions) to prevent payload bloat, 
     * nullifies temporary IDs, maps the Opportunity ID, and formats numeric fields.
     */
    _cleanForParent(rows) {
      const isRealId = (v) => !!v && v !== '0' && !String(v).startsWith('NEW_') && String(v).length >= 15;
      
      return (rows || []).map(row => {
        // Destructure to remove UI-specific properties from the outbound payload
        const {
          geographyOptions, buttonDisabled, deleteDisabled, editRecordDisabled, 
          pickDisabled, initRead, tabletype, aviableItem, GeographyLabel__c, 
          opportunity, account, ...cleanRow 
        } = row;

        // Force string values into floats for Apex mapping
        const numFields = ['XSELL_Value_PY__c', 'XSELL_Value_CY__c', 'XSELL_Value_NY__c', 'XSELL_Value_NY1__c'];
        numFields.forEach(f => {
          if (cleanRow[f] === '' || cleanRow[f] === null || cleanRow[f] === undefined) {
             cleanRow[f] = null;
          } else if (typeof cleanRow[f] === 'string' || typeof cleanRow[f] === 'number') {
             let valStr = String(cleanRow[f]).trim();
             
             if (valStr.includes(',') && valStr.includes('.')) {
                 // Has both: the last one is the decimal
                 const lastComma = valStr.lastIndexOf(',');
                 const lastDot = valStr.lastIndexOf('.');
                 if (lastComma > lastDot) {
                     valStr = valStr.replace(/\./g, '').replace(',', '.');
                 } else {
                     valStr = valStr.replace(/,/g, '');
                 }
             } else if (valStr.includes(',')) {
                 // Only commas
                 const commaCount = (valStr.match(/,/g) || []).length;
                 if (commaCount > 1) {
                     valStr = valStr.replace(/,/g, ''); // Multiple commas = thousands separator
                 } else {
                     valStr = valStr.replace(',', '.'); // Single comma = decimal
                 }
             } else if (valStr.includes('.')) {
                 // Only dots
                 const dotCount = (valStr.match(/\./g) || []).length;
                 if (dotCount > 1) {
                     valStr = valStr.replace(/\./g, ''); // Multiple dots = thousands separator
                 }
                 // Single dot is natively parsed as a decimal by parseFloat, so do nothing.
             }
             
             cleanRow[f] = parseFloat(valStr) || null; 
          }
        });

        // Attach the required Salesforce fields based on context
        if (this._parentType === 'Account') {
            cleanRow.Account__c = this._recordId;
        } else {
            cleanRow.Opportunity__c = this._recordId;
        }
        cleanRow.sobjectType = 'DMT_X_Sell__c';

        return cleanRow;
      });
    }

    /**
     * Utility method to create a deep clone of the array of objects.
     * Prevents direct mutation of tracked reactive properties.
     */
    deepCloneArray(originalArray) {
      return originalArray.map(element => {
        if (typeof element === 'object' && element !== null) {
          return JSON.parse(JSON.stringify(element));
        } else {
          return element; 
        }
      });
    }

    /**
     * Standard handler for native datatable cell changes.
     * Captures draft values directly from the datatable payload and merges them.
     */
    handleChangeCell(event) {
      let dataRecieved = event.detail.draftValues[0];
      const updatedItem = { Id: dataRecieved.Id };

      if ('Booking_Geography__c' in dataRecieved) { updatedItem.Booking_Geography__c = dataRecieved.Booking_Geography__c; }
      if ('XSELL_Value_PY__c' in dataRecieved) { updatedItem.XSELL_Value_PY__c = dataRecieved.XSELL_Value_PY__c; }
      if ('XSELL_Value_CY__c' in dataRecieved) { updatedItem.XSELL_Value_CY__c = dataRecieved.XSELL_Value_CY__c; }
      if ('XSELL_Value_NY__c' in dataRecieved) { updatedItem.XSELL_Value_NY__c = dataRecieved.XSELL_Value_NY__c; }
      if ('XSELL_Value_NY1__c' in dataRecieved) { updatedItem.XSELL_Value_NY1__c = dataRecieved.XSELL_Value_NY1__c; }

      this.updateDataValues(updatedItem);
    }

    textInputChanged(event) {
      let dataRecieved = event.detail.data;
      let updatedItem = { Id: dataRecieved.context};
      updatedItem[dataRecieved.fieldname]= dataRecieved.value;
      this.updateDataValues(updatedItem);
    }

    /**
     * Intercepts the PubSub payload dispatched by the Account FlexCard Save button.
     * Sanitizes arrays, ensures Account relationship, and executes the Apex DML.
     */
    _isSaving = false;
    async handleFlexCardSave(payload) {
        // Cross-talk protection & Double-click prevention
        if (this._parentType !== 'Account' || this._isSaving) {
            return; 
        }

        this._isSaving = true;

        // Clean the local datatable state for Apex
        let rawData = this._cleanForParent(this.tableData);
        let dataToUpsert = [];
        let missingGeo = false;

        rawData.forEach(row => {
            const hasGeo = row.Booking_Geography__c && String(row.Booking_Geography__c).trim() !== '';
            const hasNumbers = row.XSELL_Value_PY__c != null || row.XSELL_Value_CY__c != null || row.XSELL_Value_NY__c != null || row.XSELL_Value_NY1__c != null;

            if (hasGeo || hasNumbers) {
                if (!hasGeo && hasNumbers) {
                    missingGeo = true;
                }
                dataToUpsert.push(row);
            }
        });

        // MANDATORY FIELD VALIDATION: Booking Geography
        if (missingGeo) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Missing Required Field',
                message: 'Cross SELL update ABORTED. Please select a Geography for all Cross Sell rows before saving.',
                variant: 'error',
                mode: 'sticky'
            }));
            this._isSaving = false;
            return;
        }

        // Passed validation, safe to exit edit mode
        this.isEditMode = false;

        // Only fire Apex if there is actual data to process
        if (dataToUpsert.length > 0 || this.idListToDelete.length > 0) {
            try {
                
                await saveXSellRecords({ 
                    recordsToUpsert: dataToUpsert, 
                    recordsToDelete: this.idListToDelete 
                });
                
                // Clear the local delete list after successful save
                this.idListToDelete = [];

                // Reload fresh data from database to reset the baseline UI state
                this.handleGetXsellRecords();
                
            } catch (error) {
                console.error('[DEBUG] Apex Save Error:', error);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error saving Cross Sell Data',
                    message: error.body ? error.body.message : error.message,
                    variant: 'error'
                }));
                this.isEditMode = true; // Revert to edit mode if save fails
            }
        }
        
        this._isSaving = false;
    }
}