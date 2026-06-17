trigger DES_DenormAccountVisitsTrigger on DES_Denorm_AccountVisits__c (after delete, after insert) {
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            DES_DenormAccountVisitsTriggerHandler.updateTotalVisit(trigger.newMap);
        } else if(Trigger.isDelete) {
            DES_DenormAccountVisitsTriggerHandler.denVisitAfterDelete(trigger.oldMap);
        }
    }
}