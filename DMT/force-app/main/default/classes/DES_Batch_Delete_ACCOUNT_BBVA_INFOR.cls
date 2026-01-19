/**********************************************************************************
* @description  Batch para el borrado de ACCOUNT_BBVA_INFORMATION__c
**********************************************************************************/
public without sharing class DES_Batch_Delete_ACCOUNT_BBVA_INFOR implements Database.Batchable<Sobject>, Database.Stateful {
  
  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  private Integer recordsProcessed = 0;
  private String query = 'SELECT Id FROM ACCOUNT_BBVA_INFORMATION__c';

  //--------------------------------------- CONSTRUCTOR METHODS -----------------------------------
  public DES_Batch_Delete_ACCOUNT_BBVA_INFOR() {
    system.debug('>>>>> Query: ' + query);
  }

  //--------------------------------------- BATCHABLE METHODS -------------------------------------
  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext bc, List<ACCOUNT_BBVA_INFORMATION__c> listACCBBVAINF) {
    system.debug('>>>>> BATCH listACCBBVAINF: ' + listACCBBVAINF);
    if(!listACCBBVAINF.isEmpty()) {
            delete listACCBBVAINF;
            Database.emptyRecycleBin(listACCBBVAINF);
        }
    recordsProcessed+=listACCBBVAINF.size();
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