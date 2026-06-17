trigger AccountRelationship on dwp_acmh__GBL_Account_Relationship__c (before insert, before update) {

    if ((Trigger.isBefore && Trigger.isInsert) || (Trigger.isBefore && Trigger.isUpdate)) {
        // Get TriggerHandler
        final AccountRelationshipTriggerHandler handler = new AccountRelationshipTriggerHandler();
        handler.applyMappings(Trigger.new);
    }
}