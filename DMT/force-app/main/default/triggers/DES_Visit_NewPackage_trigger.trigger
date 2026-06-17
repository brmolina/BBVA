/**************************************************************************************************************
Name:            DES_Visit_NewPackage_trigger
Description:     Trigger class for dwp_kitv__Visit__c object
Test Class:

Version        Date            Author            Summary of changes
--------------------------------------------------------------------------------------------------------------
0.1            11/05/2018      Accenture         Class creation
0.2            01/02/2019      Accenture         Se añade llamada el método setVisitGMFields para rellenar los valores de los nuevos campos de GM
0.3            27/05/25        CIB               Se añade llamada al método checkOwnerDelete  para validar que el propietario solo pueda eliminar
**************************************************************************************************************/
trigger DES_Visit_NewPackage_trigger on dwp_kitv__Visit__c (before delete, before update, after insert, after update, before insert) {
  //Trigger handler class for Visit
  dwp_kitv.Visit_Handler visit_handler = new dwp_kitv.Visit_Handler();
  DES_Visit_TriggerHandler DES_visit_handler = new DES_Visit_TriggerHandler();
  private Desktop_Utils utils = Desktop_Utils.getInstance();
  private String profileName = DES_Visit_TriggerHandler.gtProfileName(); //NOSONAR


  if(trigger.isBefore){
    if(trigger.isDelete){
      if(profileName != Label.DES_INTEGRATION_PROFILE && profileName != Label.DES_DATALOADER_PROFILE && profileName != Label.DES_ADMIN_PROFILE) {
        visit_handler.visitBeforeDelete(trigger.old);
        DES_visit_handler.idsRelatedAccounts(trigger.old);
      }
      DES_Visit_TriggerHandler.checkOwnerDelete(trigger.old);
      DES_Visit_TriggerHandler.checkDeletePermission(trigger.old);

    }
    if(trigger.isUpdate){
      //visit_handler.visitBeforeUpdate(trigger.new, trigger.old);
      DES_Visit_TriggerHandler.visitBeforeUpdate(trigger.new, trigger.old);
      DES_Visit_TriggerHandler.confidentialRecordType(trigger.new);
      Map<Id, SObject> newMap = new Map<Id, SObject>();
      for(dwp_kitv__Visit__c opp : trigger.new){
        newMap.put(opp.Id, (SObject)opp);
      }
      Utilities.checkIsMexico(newMap);
      //DES_Visit_TriggerHandler.updateIPVisitCountry(trigger.new);
    }
    if(trigger.isInsert){
      DES_Visit_TriggerHandler.privateVisit(trigger.new);
      DES_Visit_TriggerHandler.fillVisitGMFields(trigger.new);
      DES_Visit_TriggerHandler.fillClientNBCVisit(trigger.new);
      DES_Visit_TriggerHandler.visitBeforeInsert(trigger.new);
      visit_handler.visitBeforeInsert(trigger.new);
      DES_Visit_TriggerHandler.checkVisitInbound(trigger.new);
      DES_Visit_TriggerHandler.confidentialRecordType(trigger.new);
      DES_Visit_TriggerHandler.checkNullError(trigger.new);
      Map<Id, SObject> newMap = new Map<Id, SObject>();
      for(dwp_kitv__Visit__c opp : trigger.new){
        newMap.put(opp.Id, (SObject)opp);
      }
      Utilities.checkIsMexico(newMap);
      //DES_Visit_TriggerHandler.updateIPVisitCountry(trigger.new);
    }
  } else if(trigger.isAfter) {
    if(trigger.isInsert) {
      DES_visit_handler.visitAfterInsert(trigger.new);
      DES_Visit_TriggerHandler.oppsTopicsNBC(trigger.new);
      DES_Visit_TriggerHandler.fillMembers(trigger.new);
      DES_Visit_TriggerHandler.updateStatusNBC(trigger.new);
      DES_Visit_TriggerHandler.checkAccessByClientCountry(trigger.new);
      //visit_handler.visitAfterInsert(trigger.New);
      DES_Visit_TriggerHandler2.onAfterInsert(Trigger.new);
      DES_Visit_TriggerHandler.ownerToTeamMgmt(trigger.new);
      system.debug('::::: insert triggerNew : ' + trigger.new);
      system.debug('::::: insert triggerOld : ' + trigger.old);
      DES_HandlerTerritory.shareWithTerriVisitInsert(trigger.newMap);
    }
    if(trigger.isUpdate){
      DES_visit_handler.visitAfterUpdate(trigger.newMap, trigger.oldMap, trigger.new);
      DES_Visit_TriggerHandler2.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
      system.debug('::::: update triggerNew : ' + trigger.new);
      system.debug('::::: update triggerOld : ' + trigger.old);
      if(!system.isFuture() && !system.isBatch()) {
        DES_HandlerTerritory.shareWithTerritoryListTriggerFuture(JSON.serialize(Trigger.new), JSON.serialize(Trigger.old), utils.getProfileName());
      }
      VisitUtils_cls objVisitUtil=new VisitUtils_cls();
      objVisitUtil.createShareOldOwner(Trigger.new,Trigger.old);//ajusta permisos cambio de owner
    }
  }
}