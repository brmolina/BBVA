trigger DMT_OpportunityClientTrigger on DMT_Opportunity_Client__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if (TriggerBypass.bypassTrigger) {
        return;
    }
    new DMT_OpportunityClientTriggerHandler().run();
}