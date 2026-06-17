/**********************************************************************************
* @author       Global Desktop
* @date         02/07/2019
* @description  Trigger para objeto Inside_information_form__c. 
* @Revision
**********************************************************************************/
trigger Inside_form on Inside_information_form__c (before insert,before update,before delete,after insert,after update,after delete) {

    if(Trigger.isAfter) {
        if(Trigger.isInsert){
            InsideFormTriggerHandler.InsertOwner(Trigger.newMap); 
        }else if(Trigger.isUpdate) {
            InsideFormTriggerHandler.changeContactsRT(Trigger.newMap);         
        }
    } 
    
    
}