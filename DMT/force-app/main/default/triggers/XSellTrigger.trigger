trigger XSellTrigger on DMT_X_Sell__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if (TriggerBypass.bypassTrigger) {
        return;
    }
    new XSellTriggerHandler().run();
}