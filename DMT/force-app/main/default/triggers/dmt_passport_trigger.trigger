/**
* @description  USE DMT_TriggerHandler (kevin ohara framework)
*/
trigger dmt_passport_trigger on Passport__c (before insert, before update, after insert, after update) {
    if(TriggerBypass.bypassTrigger) return;
    new DMT_Passport_TriggerHandler().run();
}