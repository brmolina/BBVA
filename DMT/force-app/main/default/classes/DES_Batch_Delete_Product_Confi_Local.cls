/**********************************************************************************
* @description  Batch para el borrado de Product_Configuration_Local__c
**********************************************************************************/
public without sharing class DES_Batch_Delete_Product_Confi_Local implements Database.Batchable<Sobject>, Database.Stateful {
  
  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  private Integer recordsProcessed = 0;
  private String query = 'SELECT Id FROM Product_Configuration_Local__c';

  //--------------------------------------- CONSTRUCTOR METHODS -----------------------------------
  public DES_Batch_Delete_Product_Confi_Local() {
    system.debug('>>>>> Query: ' + query);
  }

  //--------------------------------------- BATCHABLE METHODS -------------------------------------
  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext bc, List<Product_Configuration_Local__c> listPROCONLOC) {
    system.debug('>>>>> BATCH listPROCONLOC: ' + listPROCONLOC);
    if(!listPROCONLOC.isEmpty()) {
            delete listPROCONLOC;
            Database.emptyRecycleBin(listPROCONLOC);
        }
    recordsProcessed+=listPROCONLOC.size();
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