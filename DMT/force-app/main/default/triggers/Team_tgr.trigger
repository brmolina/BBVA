/**********************************************************************************
* @author       Global Desktop
* @date         14/01/2020
* @description  Trigger para objeto intt__Team_initiative__c
**********************************************************************************/
trigger Team_tgr on intt__Team_initiative__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  if(Trigger.isInsert && Trigger.isBefore) {
    intt.GBL_TeamTriggerHandler.beforeInsert(Trigger.new);
  }

  if(Trigger.isInsert && Trigger.isAfter) {
    Team_Initiative_TriggerHandler.onAfterInsert(Trigger.new);
  }

  if(Trigger.isDelete && Trigger.isBefore) {
    intt.GBL_TeamTriggerHandler.beforeDelete(Trigger.old);
  }

  if(Trigger.isDelete && Trigger.isAfter) {
    Team_Initiative_TriggerHandler.onAfterDelete(Trigger.old);
  }
}