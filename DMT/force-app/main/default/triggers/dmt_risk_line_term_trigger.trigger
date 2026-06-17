/**
* @description  Trigger for DMT_Risk_Line_Term__c. 
*/
trigger dmt_risk_line_term_trigger on DMT_Risk_Line_Term__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    if(TriggerBypass.bypassTrigger) return;
    new DMT_Risk_Line_Term_TriggerHandler().run();
}