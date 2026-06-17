/**
* @description  USE DMT_TriggerHandler (kevin ohara framework)
*/
trigger DMT_Product2_Trigger on Product2 (before insert, before update, after insert, after update) {
    new DMT_Product_TriggerHandler().run();
}