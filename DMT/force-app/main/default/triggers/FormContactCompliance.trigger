/**********************************************************************************
* @author       Global Desktop
* @date         02/07/2019
* @description  Trigger para objeto Compliance_form_contact__c .
* @Revision
**********************************************************************************/
trigger FormContactCompliance on Compliance_form_contact__c (before delete) {
     if(Trigger.isBefore) {
         if(trigger.IsDelete){
            CompformContTriggerHandler.logicBeforeDelete(trigger.oldMap);
         }
    }
}