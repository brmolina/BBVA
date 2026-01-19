import { LightningElement, wire, api } from 'lwc';
import { getRecord, getFieldValue, updateRecord  } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from 'lightning/actions';
import DELETED_FIELD from "@salesforce/schema/DMT_Line__c.DMT_Deleted__c";
import CLIENT_FIELD from "@salesforce/schema/DMT_Line__c.Client__c";
import ID_FIELD from "@salesforce/schema/DMT_Line__c.Id";
import calculatePermission from '@salesforce/apex/DMT_Passport_Handler.calculatePermissionLWC';

const ERROR_DELETE_LINE = 'You do not have permission or the role to delete the Line Object. Please contact your administrator.'; 

export default class Dmt_close_line extends LightningElement 
{
    @api recordId;
    isDeleted;
    clientRecord;

    @wire(getRecord, { recordId: "$recordId", fields: [DELETED_FIELD, CLIENT_FIELD] })
    wiredRecordLine({ error, data }) {
        if (error) 
        {
            this.dispatchEvent(
                new ShowToastEvent({
                  title: "Error",
                  message: error?.body?.message,
                  variant: "error",
                }),
              );
        } 
        else if (data) 
            {
            this.isDeleted = getFieldValue(data, DELETED_FIELD);
            this.clientRecord = getFieldValue(data, CLIENT_FIELD);

            if(this.isDeleted)
            {
                window.location.href = `/lightning/n/DMT_Page?c__recordId=${this.clientRecord}`;
            }
        }
    }

    @wire(calculatePermission, { recordId: "$recordId"})
    wiredCalculatePermissions({ error, data }) {
        if (error) 
        {
            this.dispatchEvent(
                new ShowToastEvent({
                  title: "Error",
                  message: error?.body?.message,
                  variant: "error",
                }),
              );
        } 
        else if (data !== undefined) 
        {
            if(!data)
            {
                this.dispatchEvent(
                    new ShowToastEvent({
                      title: "Warning",
                      message: ERROR_DELETE_LINE,
                      variant: "warning",
                    }),
                  );
                this.dispatchEvent(new CloseActionScreenEvent());
            }
        }
    }

    handleDelete() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[DELETED_FIELD.fieldApiName] =true;

        const recordInput = { fields };
    
        updateRecord(recordInput)
        .then( response => {
    
            this.dispatchEvent(
                new ShowToastEvent({
                  title: "Success",
                  message: "Line deleted",
                  variant: "success",
                }),
              );
          
        }).catch((error) => {
          
            this.dispatchEvent(
                new ShowToastEvent({
                  title: "Error deleting record",
                  message: error.body.message,
                  variant: "error",
                }),
            );
        }); 
    }

    handleClose()
    {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}