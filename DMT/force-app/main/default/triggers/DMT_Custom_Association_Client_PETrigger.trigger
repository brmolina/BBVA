trigger DMT_Custom_Association_Client_PETrigger on Custom_Association_Client__c (after insert, after update) {
    if(TriggerBypass.bypassTrigger) return;
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        String op = Trigger.isInsert ? 'Insert' : 'Update';
        DMT_IntegrationEventHandler.publishFromRecords(Trigger.new, op, 'v1');
    }
}