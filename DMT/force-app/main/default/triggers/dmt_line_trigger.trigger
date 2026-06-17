/**
* @description  USE DMT_TriggerHandler (kevin ohara framework)
*/
trigger dmt_line_trigger on DMT_Line__c (before insert, before update, after insert, after update) {
    if(TriggerBypass.bypassTrigger) return;
    new DMT_Line_TriggerHandler().run();
}