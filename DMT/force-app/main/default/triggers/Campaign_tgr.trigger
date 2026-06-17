/**
 * @File Name          : Campaign_tgr.trigger
 * @Description        :
 * @Author             : Global Desktop
 * @Group              :
 * @Last Modified By   : Global Desktop
 * @Last Modified On   : 13/5/2020 12:16:00
 * @Modification Log   :
 * Ver       Date            Author      		    Modification
 * 1.0    8/5/2020   Global Desktop     Initial Version
**/
trigger Campaign_tgr on Campaign (after insert, before update, before insert, after update) {
  final AccountTriggerHandler handler = AccountTriggerHandler.getInstance();
  private String profileName = handler.getProfileName();

  if(trigger.isInsert&&trigger.isAfter) {
	GBL_InitiativeTriggerHandlerLocal.afterInsert(Trigger.new);
    if(!system.isFuture() && !system.isBatch()) {
      DES_HandlerTerritory.shareWithTerritoryListTriggerFuture(JSON.serialize(Trigger.new),null, profileName );
    }
  }

  if(trigger.isUpdate&&trigger.isBefore) {
    intt.GBL_InitiativeTriggerHandler.BeforeUpdate(Trigger.new,Trigger.old);
  }

  if(trigger.isInsert&&trigger.isBefore) {
    intt.GBL_InitiativeTriggerHandler.BeforeInsert(Trigger.new);
  }

  if(trigger.isUpdate&&trigger.isAfter) {
    intt.GBL_InitiativeTriggerHandler.AfterUpdate(Trigger.new,Trigger.old);
    GBL_InitiativeTriggerEmailHandler.AfterUpdate(Trigger.new,Trigger.old);
    if(!system.isFuture() && !system.isBatch()) {
      DES_HandlerTerritory.shareWithTerritoryListTriggerFuture(JSON.serialize(Trigger.new), JSON.serialize(Trigger.old), profileName );
      DES_HandlerTerritory.shareWithFutureInititiative(JSON.serialize(Trigger.newMap), JSON.serialize(Trigger.oldMap), profileName,true );
    }
  }
}