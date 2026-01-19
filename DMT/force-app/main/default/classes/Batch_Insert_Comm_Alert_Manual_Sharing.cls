/**********************************************************************************
* @author       Global Desktop
* @date         03/03/2020
* @description  Batch para insertar manual sharings de los miembros de los
*               clientes en sus alertas relacionadas
**********************************************************************************/
public with sharing class Batch_Insert_Comm_Alert_Manual_Sharing implements Database.Batchable<Sobject>, Database.Stateful {
  /**
  * @author Global Desktop
  * @Description query String
  */
  private final String iQuery;

  /**
  * @author Global Desktop
  * @Description constructor
  */
  public Batch_Insert_Comm_Alert_Manual_Sharing() {
    iQuery = 'SELECT Id, DES_Client__c, DES_User__c, DES_Member_Role__c, copy_record_approval_type__c FROM DES_BBVA_Management_team__c WHERE copy_record_approval_type__c = false AND DES_User__r.IsActive = true';
  }

  /**
  * @author Global Desktop
  * @Description start
  */
  public Database.QueryLocator start(Database.BatchableContext iBatchableContext) {
    return Database.getQueryLocator(iQuery);
  }

  /**
  * @author Global Desktop
  * @Description execute
  */
  public void execute(Database.BatchableContext iBatchableContext, List<DES_BBVA_Management_team__c> listBBVAMT) {
    final List<altm__Commercial_Alert__Share> commAlertShare = DES_BBVAManagementTeamTriggerHandler.insertCommAlertManualSharing(listBBVAMT);
    if(!commAlertShare.isEmpty()) {
      insert commAlertShare;
    }
    DES_BBVAManagementTeam_Helper.insAlertMember(listBBVAMT);
  }

  /**
  * @author Global Desktop
  * @Description finish
  */
  public void finish(Database.BatchableContext iBatchableContext) {
    final AsyncApexJob iJob = [SELECT Id,
                          Status,
                          NumberOfErrors,
                          JobItemsProcessed
                        FROM AsyncApexJob
                        WHERE Id = :iBatchableContext.getJobId()];
    System.debug('>>>>> SUMMARY: ');
    System.debug('>>>>>   Batches Created: ' + iJob.JobItemsProcessed);
    System.debug('>>>>>   Number of Errors: ' + iJob.NumberOfErrors);
    System.debug('>>>>>   Status: ' + iJob.Status);
  }
}