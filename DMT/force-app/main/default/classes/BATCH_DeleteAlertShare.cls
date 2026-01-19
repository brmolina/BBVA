/**********************************************************************************
* @author
* @date
* @description  Batch para borrar la compartición de las alertas
* @Revision
**********************************************************************************/
public without sharing class BATCH_DeleteAlertShare implements Database.Batchable<Sobject>, Database.Stateful {//NOSONAR

  /*
  * Id a robar
  */
  private Set<Id> setRecordIds;//NOSONAR
  /*
  * Query to search
  */
  private String soqlQuery;
  /*
  * Account and user delete
  */
  private Map<Id, List<String>> mapAccUser;
  /*
  * Desktop_Utils
  */
  final Desktop_Utils hndlrDeskUtils = Desktop_Utils.getInstance();


  /*
  * Execute runJobForParticularRecords
  */
  public static void runJobForParticularRecords(Map<Id, List<String>> mapAccUserId) {
    String soqlQueryString = '';

    //Integer batchSize por custom metadata
    final List<Batches_Process_Parameters__mdt> batchParams = new List<Batches_Process_Parameters__mdt>([SELECT DeveloperName, MasterLabel, Batch_Param__c, Batch_Size__c FROM Batches_Process_Parameters__mdt WHERE DeveloperName = 'DES_BatchSize_DelAlertSH' LIMIT 1]);

    final Integer batchSize = (Test.isRunningTest() || batchParams.isEmpty() ? 1 : batchParams.get(0).Batch_Size__c.intValue());//NOSONAR

    final Set<Id> setIds = new Set<Id>(mapAccUserId.keySet());
    if( setIds.size() > 0 ) {//NOSONAR
        soqlQueryString =   'SELECT id, DES_Group_Code__c FROM Account WHERE Id IN :setRecordIds';
    } else if (Test.isRunningTest()) {//NOSONAR
        soqlQueryString =   'SELECT id FROM Account';
    }

    BATCH_DeleteAlertShare cls;
    cls = new BATCH_DeleteAlertShare();
    cls.setRecordIds = setIds;
    cls.soqlQuery = soqlQueryString;
    cls.mapAccUser = mapAccUserId;
    Database.executeBatch(cls, batchSize);
  }

  /*
  * Start
  */
  public Database.QueryLocator start(Database.BatchableContext batchContext) {
      return Database.getQueryLocator(soqlQuery);
  }

  /*
  * Execute batch
  */
  public void execute(Database.BatchableContext batchContext, List<Account> lAcc) {//NOSONAR
    final List<DES_BBVA_Management_Team__c> oldList = new List<DES_BBVA_Management_Team__c>();
    for(Account acc : lAcc) {
      for(String bbvaUser : mapAccUser.get(acc.id)) {
        oldList.add(new DES_BBVA_Management_Team__c(DES_Client__c = acc.id, DES_User__c = bbvaUser));
      }
    }

    if(!oldList.isEmpty()) {
      final List<altm__Commercial_Alert__Share> commAlertShare = DES_BBVAManagementTeamTriggerHandler.deleteCommAlertManualSharing(oldList);

      if(!commAlertShare.isEmpty()) {
        delete commAlertShare;
      }
    }
  }

  /*
  * Execute on finish
  */
  public void finish(Database.BatchableContext databaseContaxt) {
    System.debug('ACCOUNT memberMap--------------->'+mapAccUser);
    BATCH_DeleteAlertTeam.runJobForParticularRecords(mapAccUser);
  }
}