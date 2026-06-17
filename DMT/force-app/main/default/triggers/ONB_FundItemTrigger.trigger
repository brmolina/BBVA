trigger ONB_FundItemTrigger on ONB_Fund_Item__c (after insert, before delete) {
    if (Trigger.isAfter && Trigger.isInsert) {
        FundItemTriggerHandler.afterInsert(Trigger.new);
    }
    
    if (Trigger.isBefore && Trigger.isDelete) {
        FundItemTriggerHandler.beforeDelete(Trigger.old);
    }
}