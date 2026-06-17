/**
 * @File Name          : AccountCampaign_tgr.trigger
 * @Description        :
 * @Author             : Global Desktop
 * @Group              :
 * @Last Modified By   : Global Desktop
 * @Last Modified On   : 13/5/2020 11:54:47
 * @Modification Log   :
 * Ver       Date            Author      		    Modification
 * 1.0    8/5/2020   Global Desktop     Initial Version
**/
trigger AccountCampaign_tgr on cond__Account_Campaign__c (before insert, before update, before delete, after insert) {
  final AccountTriggerHandler handler = AccountTriggerHandler.getInstance();
  private String profileName = handler.getProfileName();

  if(trigger.isInsert && trigger.isBefore) {
    Account_Campaign_TriggerHandler.onBeforeInsert(Trigger.new);
    intt.GBL_GroupInitiativeTriggerHandler.beforeInsert(Trigger.new);
    Account_Campaign_TriggerHandler.trunckDescription(Trigger.new);
  }

  if(trigger.isUpdate && trigger.isBefore) {
    intt.GBL_GroupInitiativeTriggerHandler.beforeUpdate(Trigger.new, Trigger.old);
    Account_Campaign_TriggerHandler.onBeforeUpdate(Trigger.newMap, Trigger.oldMap);
  }

  if(trigger.isDelete && trigger.isBefore) {
    intt.GBL_GroupInitiativeTriggerHandler.beforeDelete(Trigger.old);
  }

  if(trigger.isInsert && trigger.isAfter) {
    intt.GBL_GroupInitiativeTriggerHandler.afterInsert(Trigger.new);
    Account_Campaign_TriggerHandler.onAfterInsert(Trigger.new);
    if(!system.isFuture() && !system.isBatch()) {
      DES_HandlerTerritory.shareWithFutureInititiative(JSON.serialize(Trigger.new), null, profileName , false);
    }
  }
}