/**********************************************************************************
* @description  Batch para el borrado de ACCOUNT_PROFITABILITY__c
**********************************************************************************/
public without sharing class DES_Batch_Delete_PROFITABILITY implements Database.Batchable<Sobject>, Database.Stateful {
  
  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  private Integer recordsProcessed = 0;
  private String query = 'SELECT Id FROM ACCOUNT_PROFITABILITY__c';

  //--------------------------------------- CONSTRUCTOR METHODS -----------------------------------
  public DES_Batch_Delete_PROFITABILITY() {
    system.debug('>>>>> Query: ' + query);
  }

  //--------------------------------------- BATCHABLE METHODS -------------------------------------
  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext bc, List<ACCOUNT_PROFITABILITY__c> listACCPROF) {
    /*system.debug('>>>>> BATCH listACCPROF: ' + listACCPROF);
    if(!listACCPROF.isEmpty()) {
            delete listACCPROF;
            Database.emptyRecycleBin(listACCPROF);
        }
    recordsProcessed+=listACCPROF.size();*/
  }

  public void finish(Database.BatchableContext bc) {
    AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];

    System.debug('>>>>> SUMMARY: ');
    System.debug('>>>>>   Records Processed: ' + recordsProcessed);
    System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
    System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
    System.debug('>>>>>   Status: ' + job.Status);
  }
}