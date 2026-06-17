/**********************************************************************************
* @author       Global Desktop
* @date         11/02/2020
* @description  Trigger para objeto altm__Commercial_Alert__c
**********************************************************************************/
trigger Commercial_Alert on altm__Commercial_Alert__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  /**
  * @author Global Desktop
  * @Description bypass
  */
  private static CIB_Bypass__c byPass = CIB_Bypass__c.getInstance();
  if(!byPass.CIB_Skip_Commercial_Alert_trigger__c) {
    if (Trigger.isInsert && Trigger.isBefore) {
      altm.Commercial_Alert_TriggerHandler.onBeforeInsert(Trigger.new);
      Commercial_Alert_TriggerHandler.onBeforeInsert(Trigger.new);
    } else if (Trigger.isUpdate && Trigger.isBefore && !SER_TriggerHelper.get_MethodFired('onBeforeUpdate')) {
      Commercial_Alert_TriggerHandler.onBeforeUpdate(Trigger.new, Trigger.newMap, Trigger.oldMap);
    } else if (Trigger.isInsert && Trigger.isAfter) {
      Commercial_Alert_TriggerHandler.onAfterInsert(Trigger.new);
    } else if (Trigger.isUpdate && Trigger.isAfter && !SER_TriggerHelper.get_MethodFired('onAfterUpdate')) {
      Commercial_Alert_TriggerHandler.onAfterUpdate(Trigger.new, Trigger.newMap, Trigger.oldMap);
    } else if (Trigger.isDelete && Trigger.isBefore) {
      Commercial_Alert_TriggerHandler.onBeforeDelete(Trigger.old, Trigger.oldMap);
    } else if (Trigger.isDelete && Trigger.isAfter) {
      Commercial_Alert_TriggerHandler.onAfterDelete(Trigger.old, Trigger.oldMap);
    }
  }
}