/**********************************************************************************
* @description  Batch para el borrado de ACCOUNT_BANKING_SYSTEM_CLASSIFICATION__c
**********************************************************************************/
public without sharing class DES_Batch_Delete_SBS_CLASSIF implements Database.Batchable<Sobject>, Database.Stateful {
  
  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  private Integer recordsProcessed = 0;
  private String query = 'SELECT Id FROM ACCOUNT_BANKING_SYSTEM_CLASSIFICATION__c';

  //--------------------------------------- CONSTRUCTOR METHODS -----------------------------------
  public DES_Batch_Delete_SBS_CLASSIF() {
    system.debug('>>>>> Query: ' + query);
  }

  //--------------------------------------- BATCHABLE METHODS -------------------------------------
  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext bc, List<ACCOUNT_BANKING_SYSTEM_CLASSIFICATION__c> listSBSCLAS) {
      /*
    system.debug('>>>>> BATCH listSBSCLAS: ' + listSBSCLAS);
    if(!listSBSCLAS.isEmpty()) {
            delete listSBSCLAS;
            Database.emptyRecycleBin(listSBSCLAS);
        }
    recordsProcessed+=listSBSCLAS.size();
*/
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