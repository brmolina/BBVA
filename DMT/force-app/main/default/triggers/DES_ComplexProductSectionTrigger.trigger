trigger DES_ComplexProductSectionTrigger on fprd__GBL_Complex_product_section__c (before insert, before update, after update, after delete) {
 
    final ComplexProductSectionTriggerHandler handler = ComplexProductSectionTriggerHandler.getInstance();
    final DES_relatedTranchesTriggerHandler handlerTranches = DES_relatedTranchesTriggerHandler.getInstance(Trigger.new,Trigger.old,Trigger.isDelete);
 
    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            handler.onBeforeInsert(Trigger.new);
            handlerTranches.insertWithOlliStage(Trigger.new);
        } else if(Trigger.isUpdate) {
            DES_relatedTranchesTriggerHandler.checkAutoFillFields(Trigger.newMap,Trigger.oldMap);
            handlerTranches.truncateDecimalValues(Trigger.newMap);
        }
    } else if(Trigger.isAfter) {
        if(Trigger.isUpdate || Trigger.isDelete) {
            handlerTranches.recalculateTranches(Trigger.isDelete,Trigger.old);
        }
    }
}