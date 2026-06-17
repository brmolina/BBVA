trigger ONB_ProductTrigger on ONB_Onboarding_Line__c (
    after insert,
    after update,
    after delete,
    after undelete
) {
    ONB_ProductTriggerHandler.handleAfter(
        Trigger.new,
        Trigger.oldMap,
        Trigger.isInsert,
        Trigger.isUpdate,
        Trigger.isDelete,
        Trigger.isUndelete
    );
}