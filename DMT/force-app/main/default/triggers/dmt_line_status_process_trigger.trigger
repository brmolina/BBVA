/**
* @description  USE DMT_TriggerHandler (kevin ohara framework)
*/
trigger dmt_line_status_process_trigger on DMT_line_status_process__c (after insert, after update) {
    if(TriggerBypass.bypassTrigger) return;
    new DMT_Line_Status_Process_TriggerHandler().run();
}