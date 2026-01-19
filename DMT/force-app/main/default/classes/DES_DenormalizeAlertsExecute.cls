/******************************************************************************************************************************************************************
Name:            DES_DenormalizeAlertsExecute
Description:     Clase batch para que se invoque semanalmente desde una clase Scheduled y se vuelva a generar la tabla de Denorm_AccountAlert
Test Class:      -

Version        Date            Author            Summary of changes
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
0.1            31/10/2018      Accenture         Class creation
*******************************************************************************************************************************************************************/
public without sharing class DES_DenormalizeAlertsExecute implements Database.Batchable<Sobject>, Database.Stateful{

  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  private Integer recordsProcessed = 0;
  private Integer relationshipsCreated = 0;
  private String query = 'SELECT Id, altm__participant_id__c, Name FROM altm__Commercial_Alert__c'+(Test.isRunningTest()?' LIMIT 1':'');

  //--------------------------------------- CONSTRUCTOR METHODS -----------------------------------
  public DES_DenormalizeAlertsExecute() {
    system.debug('Query: ' + query);
  }

  //--------------------------------------- BATCHABLE METHODS -------------------------------------
  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext bc, List<altm__Commercial_Alert__c> scope) {
    DES_DenormalizeAlertsUtils doUtil = new DES_DenormalizeAlertsUtils();

    for (altm__Commercial_Alert__c alert : scope) {
      relationshipsCreated = relationshipsCreated + doUtil.denormalize(alert);
      recordsProcessed++;
    }
  }

  public void finish(Database.BatchableContext bch) {
    final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bch.getJobId()];
    System.debug('>>>>> SUMMARY: ');
    System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
    System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
    System.debug('>>>>>   Status: ' + job.Status);
    System.debug('>>>>>   recordsProcessed: ' + recordsProcessed);
  }
}