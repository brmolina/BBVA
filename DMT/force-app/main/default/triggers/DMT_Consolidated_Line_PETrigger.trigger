trigger DMT_Consolidated_Line_PETrigger on DMT_Consolidated_Line__c (after insert, after update) {
    if(TriggerBypass.bypassTrigger) return;
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        if (DMT_IntegrationContext.isInbound()) return;// evita re-publicación por rebote
        String op = Trigger.isInsert ? 'Insert' : 'Update';
        DMT_IntegrationEventHandler.publishFromRecords(Trigger.new, op, 'v1');
    }
}