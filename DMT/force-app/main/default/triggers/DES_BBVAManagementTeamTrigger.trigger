/**************************************************************************************************************
Name:            DES_BBVAManagementTeamTrigger
Description:     trigger on object DES_BBVA_Management_team__c
Test Class:

Version        Date            Author            Summary of changes
--------------------------------------------------------------------------------------------------------------
0.1            01/04/2018      DSL          Creación de la clase
0.2            13/07/2018      JSS          Update -> Añadido en isBeforeInsert llamada al método del handler setCountry_GB_IH para actualizar el country a 'Global' cuando se trata de los 'Industry Head' y 'Global Banker'
**************************************************************************************************************/
trigger DES_BBVAManagementTeamTrigger on DES_BBVA_Management_team__c (before insert, before update, before delete, after insert, after update, after delete) {
  final static String profileName {
    get {
      if(profileName == null) {
        profileName = [SELECT Name
                      FROM Profile
                      WHERE Id = :userInfo.getProfileId()
                      LIMIT 1].Name;
      }
      return profileName;
    } set;
  }

  /**
  * @author Global Desktop
  * @Description bypass
  */
  private static CIB_Bypass__c byPass = CIB_Bypass__c.getInstance();

  final DES_BBVAManagementTeamTriggerHandler handler = DES_BBVAManagementTeamTriggerHandler.getInstance();
  //List <DES_BBVA_Management_team__c> listaDeDuplicados = new List <DES_BBVA_Management_team__c>();
  system.debug('>>>>> ENTRO EN TRIGGER DES_BBVA_Management_team__c ');
  system.debug('>>>>> trigger.new : ' + trigger.new);
  system.debug('>>>>> trigger.oldMap : ' + trigger.oldMap);

  if(trigger.isBefore && !byPass.CIB_Skip_BBVATeam_trigger__c) {
    if(trigger.isInsert) {
      //DES_BBVAManagementTeam_Helper.replaceTransaction(Trigger.new);
      system.debug('>>>>> ENTRO EN TRIGGER.AFTER INSERT ');
      DES_BBVAManagementTeamTriggerHandler.deleteTeamMembersBeforeInsert( trigger.new );
      handler.setUserFields(trigger.new, null);
      DES_BBVAManagementTeamTriggerHandler.fillCountryGBIH(trigger.new);
      //llamo a la funcion que inserta en las cuentas hijas elGlobal banker y/o el industry head
      //handler.insertBBVAMTChildAccount(trigger.new);
      // llamo a la funcion para controlar duplicados
      Desktop_Utils.listaDeDuplicados = DES_BBVAManagementTeamTriggerHandler.checkDuplicates(trigger.new);
    }
    if(Trigger.IsDelete) {
      //Borro los BBVA_Management_Teams relacionados con el registro borrado
      //handler.deleteBBVAMTChildAccount(trigger.old);
    }
    if(trigger.isUpdate) {
      //DES_BBVAManagementTeam_Helper.replaceTransaction(Trigger.new);
      //handler.updateBBVAMTChildAccount(trigger.newMap, trigger.oldMap);
      handler.setUserFields(trigger.new, trigger.oldMap);
    }
    if(Trigger.isInsert || Trigger.isUpdate) {
      DES_BBVAManagementTeamTriggerHandler.checkInactiveUsers(trigger.new);
    }
    system.debug('>>>>> Desktop_Utils.listaDeDuplicados : ' + Desktop_Utils.listaDeDuplicados);
  }

  if(trigger.isAfter && !byPass.CIB_Skip_BBVATeam_trigger__c) {
    system.debug('>>>>> ENTRO EN TRIGGER.ISAFTER ');
    if(trigger.isInsert) {
      system.debug('>>>>> Desktop_Utils.listaDeDuplicados : ' + Desktop_Utils.listaDeDuplicados);
      if(Desktop_Utils.listaDeDuplicados != null && !Desktop_Utils.listaDeDuplicados.isEmpty()) {
        //delete Desktop_Utils.listaDeDuplicados;
            Database.DeleteResult[] drList = Database.delete(Desktop_Utils.listaDeDuplicados, false);
            // Iterate through each returned result
            for(Database.DeleteResult dr : drList) {
                if (!dr.isSuccess()) {
                    // Operation failed, so get all errors                
                    for(Database.Error err : dr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }

      }
      system.debug('>>>>> ENTRO EN TRIGGER.AFTER INSERT ');
      //llamo a la funcion que inserta en las cuentas hijas elGlobal banker y/o el industry head
      //handler.insertBBVAMTChildAccount(trigger.new);
      DES_BBVAManagementTeamTriggerHandler.insertAccountTeam(trigger.new, null);
      DES_BBVAManagementTeamTriggerHandler.insertFilialCoverTeamMember(trigger.new);
      // handler.updateBankerAccount(trigger.new);
      if(Trigger.new.size() == 1
        && ((profileName != Label.DES_ADMIN_PROFILE
            && profileName != Label.DES_INTEGRATION_PROFILE)
          || (Test.isRunningTest() && System.IsBatch() == false && System.isFuture() == false))) {
        DES_BBVAManagementTeamTriggerHandler.insertCommAlertManualSharingFuture(JSON.serialize(Trigger.new));
        DES_BBVAManagementTeam_Helper.insAlertMemberFut(JSON.serialize(Trigger.new), '');
      }
      handler.createManualSharing(trigger.new, false);
      DES_BBVAManagementTeamTriggerHandler.fillAccountField(trigger.newMap);
    }
    if(Trigger.IsDelete) {
      //Borra los AccountTeamMembers equivalentes del objeto BBVA_Management_team
      DES_BBVAManagementTeamTriggerHandler.deleteAccountTeamMember(Trigger.old);
      DES_BBVAManagementTeamTriggerHandler.deleteFilialCoverTeamMember(Trigger.old);
      if(Trigger.old.size() == 1
        && ((profileName != Label.DES_ADMIN_PROFILE
            && profileName != Label.DES_INTEGRATION_PROFILE)
          || (Test.isRunningTest() && System.IsBatch() == false && System.isFuture() == false))) {
        DES_BBVAManagementTeamTriggerHandler.deleteCommAlertManualSharingFuture(JSON.serialize(Trigger.old));
        DES_BBVAManagementTeam_Helper.delAlertMemberFut(JSON.serialize(Trigger.old));
      }

      if(!Test.isRunningTest() && System.IsBatch() == false && System.isFuture() == false) {
        //DES_BBVAManagementTeamTriggerHandler.deleteAlertsManualSharingFuture(JSON.serialize(Trigger.old)); /*Descomentar en la subida de alertas */
      }
      //handler.deleteComAlertManualSharing(Trigger.old); probar quitando deleteAlertsManualSharing
      handler.deleteVisitManualSharing(Trigger.old);
      handler.deleteOppsManualSharing(Trigger.old);
      //Borro los BBVA_Management_Teams relacionados con el registro borrado
      //handler.deleteBBVAMTChildAccount(trigger.old);
    }
    if(trigger.isUpdate) {
      DES_BBVAManagementTeamTriggerHandler.insertAccountTeam(Trigger.new, Trigger.oldMap);
      DES_BBVAManagementTeamTriggerHandler.updateCommAlertManualSharing(Trigger.newMap, Trigger.oldMap);
      handler.createManualSharing(Trigger.new, false);
      DES_BBVAManagementTeam_Helper.insAlertMemberFut(JSON.serialize(Trigger.new), JSON.serialize(Trigger.oldMap));
      //handler.updateBBVAMTChildAccount(trigger.newMap, trigger.oldMap);
    }
  }

  system.debug('>>>>> FIN DE TRIGGER DES_BBVA_Management_team__c ');
}