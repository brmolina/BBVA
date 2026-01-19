/**********************************************************************************
* @description  Batch para el borrado de ACCOUNT_COMMERCIAL_STRATEGY_RESULTS__c
**********************************************************************************/
public without sharing class DES_Batch_Delete_COMMERCIAL_STRAT_RES implements Database.Batchable<Sobject>, Database.Stateful {
  
  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  private Integer recordsProcessed = 0;
  private String query = 'SELECT Id FROM ACCOUNT_COMMERCIAL_STRATEGY_RESULTS__c';

  //--------------------------------------- CONSTRUCTOR METHODS -----------------------------------
  public DES_Batch_Delete_COMMERCIAL_STRAT_RES() {
    system.debug('>>>>> Query: ' + query);
  }

  //--------------------------------------- BATCHABLE METHODS -------------------------------------
  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext bc, List<ACCOUNT_COMMERCIAL_STRATEGY_RESULTS__c> listCOMMSTRARES) {
    /*system.debug('>>>>> BATCH listCOMMSTRARES: ' + listCOMMSTRARES);
    if(!listCOMMSTRARES.isEmpty()) {
            delete listCOMMSTRARES;
            Database.emptyRecycleBin(listCOMMSTRARES);
        }
    recordsProcessed+=listCOMMSTRARES.size();*/
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