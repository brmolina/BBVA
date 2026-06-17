trigger DMT_Warranty_PETrigger on DMT_Warranty__c (after insert, after update) {
    if(TriggerBypass.bypassTrigger) return;
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        String op = Trigger.isInsert ? 'Insert' : 'Update';
        DMT_IntegrationEventHandler.publishFromRecords(Trigger.new, op, 'v1');
    }
}