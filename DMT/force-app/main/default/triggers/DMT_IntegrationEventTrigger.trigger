trigger DMT_IntegrationEventTrigger on DMT_Integration_Event__e (after insert) {
    if(TriggerBypass.bypassTrigger) return;
    for (DMT_Integration_Event__e e : Trigger.New) {
        DMT_IntegrationEventProcessor.enqueueFromEvent(e);
    }
}