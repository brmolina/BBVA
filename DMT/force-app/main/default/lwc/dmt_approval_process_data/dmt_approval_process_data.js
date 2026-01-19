import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, getRecordNotifyChange } from "lightning/uiRecordApi";
import LINE_TYPE from "@salesforce/schema/DMT_Line__c.Product__c";

export default class Dmt_approval_process_data extends LightningElement {
    @api recordId; // Asumimos que este viene de la página de registro
    lineType;
      @wire(getRecord, { recordId: "$recordId", fields: [LINE_TYPE] })
      wiredRecordLine(result){
        const { error, data } = result;
        if(error){
          this.showToast('Error getting line info', error.body.message, 'error');
        }
        else if(data){
          this.lineType = getFieldValue(data, LINE_TYPE);

        }
      }

    get approvalProcessDataColumns() {
        if( this.lineType == 'Treasury Line') {
            return [
            [{fieldName: 'DMT_Booking_Unit_Risk_Analyst__c', isReadOnly: false},
                {fieldName: 'DMT_Approver__c', isReadOnly: false}], // Columna 1
            [{fieldName:'DMT_GlobalBanker__c', isReadOnly: true},
             {fieldName:'DMT_ApproverGlobalBanker__c', isReadOnly: false}]  // Columna 2
        ];
        } else {
            return [
            [{fieldName: 'DMT_Booking_Unit_Risk_Analyst__c', isReadOnly: false},
                {fieldName: 'DMT_Approver__c', isReadOnly: false}], // Columna 1
            [{fieldName:'DMT_GlobalBanker__c', isReadOnly: true},
             {fieldName:'DMT_ApproverGlobalBanker__c', isReadOnly: false}]  // Columna 2
        ];
        }
        
    }

    get commentsColumns() {
        if( this.lineType == 'Treasury Line') {
            return [
            [{fieldName: 'DMT_Client_Use__c', isReadOnly: false}]
        ];
        }
        else{
                    return [
            [{fieldName: 'DMT_Comments__c', isReadOnly: false},
                {fieldName: 'DMT_Additional_Restrictions__c', isReadOnly: false}
            ]
        ];
        }

    }
}