/*
* @author       Alejandro del Rio Martin
* @date         23/01/2020
* @description  Trigger para objeto NBC
*/
trigger NBC on NBC__c (before insert,before update,before delete,after insert,after update,after delete) {
    /*
    *   @AUTHOR Global Desktop
    */
    final NbcTriggerHandler NbcTriggerHandlers= NbcTriggerHandler.getInstance();
    if(Trigger.isBefore) {
        if(Trigger.isDelete) {
            NbcTriggerHandlers.deleteChatter(Trigger.old);
        }
    }
}