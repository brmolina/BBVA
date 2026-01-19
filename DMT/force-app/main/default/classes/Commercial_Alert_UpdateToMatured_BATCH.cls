/**
* Author: BBVA
* Description:  .
* History:
*   <Date>       <Author>          <Description>
* 22/01/2021   Javier Touchard   V 1.0 Initial version
*/
global without sharing class Commercial_Alert_UpdateToMatured_BATCH implements Database.Batchable<sObject> { //NOSONAR Avoid Global Clases: Tiene que ser Global por si en algún momento fuese necesario llamar desde APX.

  /*Query que va a determinar el scope de el Batch*/
  final String query;

  /**
  * Constructor 1.
  * @Params String query: scope.
  */
  global Commercial_Alert_UpdateToMatured_BATCH(String query) {
    this.query = query;
  }

  /**
  * Constructor 2.
  */
  global Commercial_Alert_UpdateToMatured_BATCH() {
    this.query = 'SELECT Id, altm__alert_stage_type__c, altm__owner_access_alert_id__c FROM altm__Commercial_Alert__c WHERE altm__alert_stage_type__c = \'Pending\' and altm__commercial_alert_end_date__c <= TODAY AND owner.isactive = true AND altm__participant_id__c != null';
  }

  /**
  * Method que determina el scope del job.
  * @Params Database.BatchableContext bcctx: contexto.
  * @Return Database.QueryLocator: Scope.
  */
  global Database.QueryLocator start(Database.BatchableContext bcctx) { //NOSONAR Avoid Global Clases: Tiene que ser Global por si en algún momento fuese necesario llamar desde APX.
    return Database.getQueryLocator(this.query);
  }

  /**
  * Method principal donde se encuentra toda la logica del Batch.
  * @Params: Database.BatchableContext bcctx: contexto.
  * @Params: List<sObject> scope: Registros que van a ser tratados.
  * @Return: Void
  */
  global void execute(Database.BatchableContext bcctx, List<sObject> scope) {

    List<altm__Commercial_Alert__c> commAlertList;
    commAlertList = new List<altm__Commercial_Alert__c>();
    Set<String> userIdSet;
    userIdSet = new Set<String>();
    for(Object obj : scope) {
      altm__Commercial_Alert__c commAlert;
      commAlert = (altm__Commercial_Alert__c)obj;
      userIdSet.add(commAlert.altm__owner_access_alert_id__c);
    }

    Map<String, Id> userIdMap;
    userIdMap = new Map<String, Id>();
    for(User usuario : [SELECT Id, FederationIdentifier from User where FederationIdentifier IN : userIdSet AND IsActive = true]) {
      userIdMap.put(usuario.FederationIdentifier, usuario.Id);
    }

    for(Object obj : scope) {
      altm__Commercial_Alert__c commAlert2;
      commAlert2 = (altm__Commercial_Alert__c)obj;
      if(userIdMap.get(commAlert2.altm__owner_access_alert_id__c) != null) {
        commAlert2.altm__alert_stage_type__c = Label.COMMERCIAL_ALERT_STATUS_MATURED;
        commAlertList.add(commAlert2);
      }
    }
    update commAlertList;
  }

  /**
  * Method que se ejecuta al finalizar el Batch.
  * @Params: Database.BatchableContext bcctx: contexto.
  * @Return: Void
  */
  global void finish(Database.BatchableContext bcctx) {
    System.debug('Finish Commercial_Alert_UpdateToMatured_BATCH');

    final AsyncApexJob job = [SELECT NumberOfErrors,ExtendedStatus
                              FROM AsyncApexJob WHERE Id =: bcctx.getJobId()];

    //Insertamos un CIB_Log con la excepcion
    if(String.isNotBlank(JOB.ExtendedStatus)) {
      CIB_Log__c logToInsertF;
      logToInsertF = new CIB_Log__c();
      logToInsertF.CIB_Subject__c = 'ERROR: Commercial_Alert_UpdateToMatured_BATCH';
      logToInsertF.CIB_ErrorMessage__c = 'Nº errores: ' + JOB.NumberOfErrors + '\n ExtendedStatus' + JOB.ExtendedStatus;
      insert logToInsertF;
    }
  }
}