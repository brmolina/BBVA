/**********************************************************************************
* @description  Batch para el borrado de Commit_Inter_Garant__c
**********************************************************************************/
public without sharing class DES_Batch_Delete_Commit_Inter_Garant implements Database.Batchable<Sobject>, Database.Stateful {
  
  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  private Integer recordsProcessed = 0;
  private String query = 'SELECT Id FROM Commit_Inter_Garant__c';

  //--------------------------------------- CONSTRUCTOR METHODS -----------------------------------
  public DES_Batch_Delete_Commit_Inter_Garant() {
    system.debug('>>>>> Query: ' + query);
  }

  //--------------------------------------- BATCHABLE METHODS -------------------------------------
  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext bc, List<Commit_Inter_Garant__c> listCOMINTGAR) {
    system.debug('>>>>> BATCH listCOMINTGAR: ' + listCOMINTGAR);
    if(!listCOMINTGAR.isEmpty()) {
            delete listCOMINTGAR;
            Database.emptyRecycleBin(listCOMINTGAR);
        }
    recordsProcessed+=listCOMINTGAR.size();
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