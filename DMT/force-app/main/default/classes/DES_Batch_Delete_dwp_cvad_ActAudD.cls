/**********************************************************************************
* @description  Batch para el borrado de dwp_cvad__Action_Audit_Detail__c
**********************************************************************************/
public without sharing class DES_Batch_Delete_dwp_cvad_ActAudD implements Database.Batchable<Sobject>, Database.Stateful {
  
  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  private Integer recordsProcessed = 0;
  private String query = 'SELECT Id FROM dwp_cvad__Action_Audit_Detail__c';

  //--------------------------------------- CONSTRUCTOR METHODS -----------------------------------
  public DES_Batch_Delete_dwp_cvad_ActAudD() {
    system.debug('>>>>> Query: ' + query);
  }

  //--------------------------------------- BATCHABLE METHODS -------------------------------------
  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext bc, List<dwp_cvad__Action_Audit_Detail__c> listACTAUDDET) {
    system.debug('>>>>> BATCH listACTAUDDET: ' + listACTAUDDET);
    if(!listACTAUDDET.isEmpty()) {
            delete listACTAUDDET;
            Database.emptyRecycleBin(listACTAUDDET);
        }
    recordsProcessed+=listACTAUDDET.size();
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