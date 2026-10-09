trigger DMT_CustomAssocOppTrigger on Custom_Association_Opportunity__c (after insert, after update, after delete) {
    if (TriggerBypass.bypassTrigger) {
        return;
    }
    new DMT_CustomAssocOppTriggerHandler().run();
}