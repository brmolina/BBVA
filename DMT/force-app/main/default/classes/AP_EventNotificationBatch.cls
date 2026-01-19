/**********************************************************************************
* @author       Global Desktop
* @date         14/11/2019
* @description  Batch para notificar a los miembros de los account planning
* @Revision
**********************************************************************************/
public without sharing class AP_EventNotificationBatch implements Database.Batchable<Sobject>, Database.Stateful{
    //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  private Integer recordsProcessed = 0;
  //private Integer relationshipsCreated = 0;
  private String query = 'SELECT Id, acpl__gf_ap_edit_days_left_number__c FROM acpl__AP_PeriodConfiguration__c WHERE acpl__gf_ap_edit_days_left_number__c != null ';

  /*
  * @author         Global Desktop
  * @Description    Constructor method
  */
  public AP_EventNotificationBatch() {
    system.debug('>>>>> Query: ' + query);
  }

  /*
  * @author         Global Desktop
  * @Description    Batchable method
  */
  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(query);
  }

  /*
  * @author         Global Desktop
  * @Description    Batchable method
  */
  public void execute(Database.BatchableContext bc, List<acpl__AP_PeriodConfiguration__c> listAPconfig) {
    system.debug('>>>>> BATCH listAPconfig: ' + listAPconfig);
    AP_EventNotificationBatchHandler.notifyAPTeam(listAPconfig);
    system.debug('>>>>> DESPUES listAPconfig');
    recordsProcessed += listAPconfig.size();
  }

  /*
  * @author         Global Desktop
  * @Description    Batchable method
  */
  public void finish(Database.BatchableContext bc) {
    AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];

    System.debug('>>>>> SUMMARY: ');
    System.debug('>>>>>   Records Processed: ' + recordsProcessed);
    //System.debug('>>>>>   Relationships Created: ' + relationshipsCreated);
    System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
    System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
    System.debug('>>>>>   Status: ' + job.Status);
  }
}