/**********************************************************************************
* @author       Global Desktop
* @date         14/01/2020
* @description  Trigger para objeto intt__Pitch_Group__c
**********************************************************************************/
trigger Pitch_Group on intt__Pitch_Group__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  if (Trigger.isInsert && Trigger.isAfter) {
    Pitch_Group_TriggerHandler.onAfterInsert(Trigger.new);
  }
  if (Trigger.isDelete && Trigger.isBefore) {
    Pitch_Group_TriggerHandler.onBeforeDelete(Trigger.old);
    intt.GBL_GroupPitchTriggerHandler.beforeDelete(Trigger.old);
  }
  if(Trigger.isInsert && Trigger.isBefore){
    intt.GBL_GroupPitchTriggerHandler.beforeInsert(Trigger.new);
  }
}