public without sharing class DES_MigrateAlertClient implements Database.Batchable<Sobject>, Database.Stateful {
  /* Query attribute */
  private final String pQuery;

  /*
  * constructor method
  */
  public DES_MigrateAlertClient() {
    pQuery = 'SELECT Id, Client_STAR_ID__c, altm__commercial_alert_id__c, altm__commercial_alert_record_type__c, altm__participant_id__c, altm__participant_id__r.SAL_Client_STAR_ID_Solo__c FROM altm__Commercial_Alert__c WHERE altm__participant_id__r.DES_Client_Type__c = \'Counterparty\'' + (Test.isRunningTest()?' LIMIT 10':'');
  }

  /*
  * start method
  */
  public Database.QueryLocator start(Database.BatchableContext bch) {
    return Database.getQueryLocator(pQuery);
  }

  /*
  * Execute method
  */
  public void execute(Database.BatchableContext bch, List<altm__Commercial_Alert__c> scope) {
    final List<String> listStarID = new List<String>();
    for(altm__Commercial_Alert__c iCommercialAlert : scope) {
      final String starID = '%' + iCommercialAlert.altm__participant_id__r.SAL_Client_STAR_ID_Solo__c + '%';
      listStarID.add(starID);
    }

    System.debug('::::::::::');
    final Map<String, Id> mapStarIDClient = new Map<String, Id>();
    for(Counterparty__c iCounterparty : [SELECT Id,
                                          star_counterparty_oper_desc__c,
                                          participant_id__c
                                        FROM Counterparty__c
                                        WHERE star_counterparty_oper_desc__c LIKE :listStarID]) {
      for(String starID : iCounterparty.star_counterparty_oper_desc__c.split(',')) {
        mapStarIdClient.put(starID.replaceAll(' ', ''), iCounterparty.participant_id__c);
      }
    }

    final List<altm__Commercial_Alert__c> toUpdate = new List<altm__Commercial_Alert__c>();
    for(altm__Commercial_Alert__c iCommercialAlert : scope) {
      if(mapStarIdClient.containsKey(iCommercialAlert.altm__participant_id__r.SAL_Client_STAR_ID_Solo__c)) {
        iCommercialAlert.altm__participant_id__c = mapStarIdClient.get(iCommercialAlert.altm__participant_id__r.SAL_Client_STAR_ID_Solo__c);
        toUpdate.add(iCommercialAlert);
      }
    }
    if(!toUpdate.isEmpty()) {
      update toUpdate;
    }
  }

  /*
  * Finish method
  */
  public void finish(Database.BatchableContext bch) {
    final Id batchInstanceId = Database.executeBatch(new DES_AlertMigration(), 70);
    final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bch.getJobId()];
    System.debug('>>>>> SUMMARY: ');
    System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
    System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
    System.debug('>>>>>   Status: ' + job.Status);
    System.debug('>>>>>   batchInstanceId: ' + batchInstanceId);
  }
}