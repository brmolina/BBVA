trigger AMH_AccountRelationship on AMH_GBL_Account_Relationship__c (before insert, before update) {

    if ((Trigger.isBefore && Trigger.isInsert) || (Trigger.isBefore && Trigger.isUpdate)) {
        // Get TriggerHandler
        final AMH_AccountRelationshipTriggerHandler handler = new AMH_AccountRelationshipTriggerHandler();
        handler.applyMappings(Trigger.new);
    }
}