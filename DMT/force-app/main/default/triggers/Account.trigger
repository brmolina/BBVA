/**
* _________________________________________________________________________________
* @Name      AccountTrigger
* @Author    Accenture
* @Date      2016-03-01
* @Group     [Nombre del Grupo]
* ---------------------------------------------------------------------------------
* @Description  Trigger para objeto Account. No crear más triggers para Account, 
* para ello usar la clase AccountTriggerHandler y ActivitiesUtils.
* ---------------------------------------------------------------------------------
* @History
* Version   Date            Author          Summary of changes
* 1.0       2016-03-01      Accenture       Versión inicial del trigger.
* 1.1       2017-10-26      [Autor]         Se deja de utilizar customActivity (Activity__c).
* 1.2       2018-06-14      [Autor]         Añadida lógica para asignar Recordtype en cargas DESKTOP.
* 1.3       2018-07-20      [Autor]         Añadida lógica para establecer la fecha de Engloba.
* 1.4       2025-09-03     Antonio Lozano   Se añade acceso al método generateIdProsGroup
* _________________________________________________________________________________
**/
trigger Account on Account (after delete, before insert, before update, after update, after insert) {
    if(TriggerBypass.bypassTrigger) return;
    /*
     *
     *  En el Process Builder de Clientes había un rombo con la condición de:
     *      - SI DES_Number_of_Global_Bankers = 0
     *          - INMEDIATE ACTIONS: campo 'GLOBAL BANKER' = null
     *
     *
     *  SE HA QUITADO EL PROCESS BUILDER Y ESTA FUNCIONALIDAD NO SE HA PASADO AL TRIGGER PORQUE YA NO APLICA.
     *  DEJO ESTE COMENTARIO POR SI EN UN FUTURO VUELVE A HACER FALTA.
    **/


    //Get TriggerHandler
    final AccountTriggerHandler handler = AccountTriggerHandler.getInstance();
    private String profileName = handler.getProfileName();
    private CIB_Bypass__c byPassSettings = CIB_Bypass__c.getInstance();

    //ON AFTER DELETE
    if (Trigger.isDelete && Trigger.isAfter){
        //handler.onAfterDelete(Trigger.old);
    }

    //ON BEFORE INSERT
    else if (Trigger.isInsert && Trigger.isBefore) {
        System.debug('jlb - INSERT Trigger.newMap: '+Trigger.new);
        handler.asignarAbacoIdNull(Trigger.new);
        handler.assignRecordType(trigger.new, Trigger.oldMap);
        handler.populateProspectSubsidiaryCountryFromParent(Trigger.new);
        handler.setRevenueInsertEngloba(trigger.new);
        handler.autoPopulateIndustrySectorSubsector(Trigger.new, null);
        handler.generateIdProspectGroup(Trigger.new);

        if(!test.isRunningTest()) {
            NONC_ClientsToConvert.getConvertedAccounts(Trigger.new);
        }
     //   handler.setMatriz(Trigger.new);
    }

    //ON BEFORE UPDATE
    else if (Trigger.isUpdate && Trigger.isBefore) {
        System.debug('jlb - UPDATE newMap: '+Trigger.newMap);
        if(!byPassSettings.CIB_skip_NPS_validationrule__c) {
            if(profileName != Label.DES_INTEGRATION_PROFILE && profileName != Label.DES_DATALOADER_PROFILE && profileName != Label.DES_ADMIN_PROFILE) {
                handler.checkErrorProspect(Trigger.new, Trigger.oldMap);
            }
            handler.updateAbacoIdNull(Trigger.newMap);
            handler.ponerParentIdNull(Trigger.newMap, Trigger.oldMap);
            handler.assignRecordType(trigger.new, Trigger.oldMap);
            handler.setRevenueUpdateEngloba(trigger.new, Trigger.oldMap);
            handler.autoPopulateIndustrySectorSubsector(Trigger.new, Trigger.oldMap);
        }

        handler.applyProspectCountryEntificPrefix(Trigger.new, Trigger.oldMap);
        handler.saveInactiveDate(Trigger.new, Trigger.oldMap);
    } else if(Trigger.isUpdate && Trigger.isAfter) {
        // AccountTriggerHandler.checkNPSGroup(Trigger.newMap, Trigger.oldMap);
        // AccountTriggerHandler.checkNPSSubsidiary(Trigger.newMap, Trigger.oldMap);
        //ProspectHandler.deleteProspectGroup(Trigger.oldMap, Trigger.new);
        handler.assignAccountTeamMember(Trigger.new, Trigger.oldMap);        
        if(!system.isFuture() && !system.isBatch()) {
           //ajuste irene soluciona DGDS-2919
           // DES_HandlerTerritory.shareWithTerritoryListTriggerFuture(JSON.serialize(Trigger.new), JSON.serialize(Trigger.old), profileName );
        }
        handler.callCreateEditProspect(Trigger.new, Trigger.oldMap);

        // should be after all after update methods
        DMT_AsyncOrchestrator.flush();

    } else if (Trigger.isInsert && Trigger.isAfter) {
        handler.applyProspectCountryEntificPrefix(Trigger.new, null);
        handler.createProspectAccountRelationship(Trigger.new);
        handler.generateProspectId(Trigger.newMap);
        handler.assignAccountTeamMember(Trigger.new, null);
        if(!system.isFuture() && !system.isBatch()) {
            //DES_HandlerTerritory.shareWithTerritoryListTriggerFuture(JSON.serialize(Trigger.new), null, profileName);
        }
        handler.callCreateProspect(Trigger.new);

        // should be after all after insert methods
        DMT_AsyncOrchestrator.flush();
    }
}