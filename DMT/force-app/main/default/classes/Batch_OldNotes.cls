/**********************************************************************************
* @author       Alejandro del Rio
* @date         11/12/2019
* @description  Batch que actualziza las templates antiguas para que muestren las notas que contangan
* @Revision
**********************************************************************************/
public without sharing class Batch_OldNotes implements Database.Batchable<Sobject>, Database.Stateful {
	/*
  * String query
  */
  final private String pQuery;

  /*
  * Constructor
  */
  public Batch_OldNotes() {
    pQuery = 'SELECT Id, NewNbcs__c from DES_Template__c '+ (Test.isRunningTest() ? ' LIMIT 1' : '');
  }
  /*
    * start method
    */
  public Database.QueryLocator start(Database.BatchableContext bch) {
    return Database.getQueryLocator(pQuery);
  }
  /*
    * execute method
    */
  public void execute(Database.BatchableContext bch, List<DES_Template__c> scope) {
    final List <DES_Template__c> TemplatesToUpdate = new List<DES_Template__c>();

    for(DES_Template__c temp : scope) {
      temp.NewNbcs__c = false;
      TemplatesToUpdate.add(temp);
    }

    if(!TemplatesToUpdate.isEmpty()) {
      update TemplatesToUpdate;
    }
  }
  /*
    * finish method
    */
  public void finish(Database.BatchableContext bch) {
    final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bch.getJobId()];
    System.debug('>>>>> SUMMARY: ');
    System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
    System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
    System.debug('>>>>>   Status: ' + job.Status);
  }
}