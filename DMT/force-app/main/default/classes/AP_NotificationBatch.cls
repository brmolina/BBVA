/**********************************************************************************
* @author       Global Desktop
* @date         03/07/2019
* @description  Batch para notificar a los miembros de los account planning
* @Revision
**********************************************************************************/
public without sharing class AP_NotificationBatch implements Database.Batchable<Sobject>, Database.Stateful{
    //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  private Integer recordsProcessed = 0;
  //private Integer relationshipsCreated = 0;
  private String query = 'SELECT Id, acpl__gf_ap_edit_start_date__c, acpl__gf_ap_notfn_next_close_date__c, acpl__gf_ap_edit_end_date__c, acpl__gf_ap_start_date_msg_desc__c, acpl__gf_ap_next_date_msg_desc__c, acpl__gf_ap_close_date_msg_desc__c, acpl__gf_ap_priority_edit_type__c FROM acpl__AP_Period__c WHERE acpl__gf_ap_notfn_next_close_date__c = TODAY OR acpl__gf_ap_edit_end_date__c = TODAY OR acpl__gf_ap_edit_start_date__c= TODAY';

  /*
  * @author         Global Desktop
  * @Description    Constructor method
  */
  public AP_NotificationBatch() {
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
  public void execute(Database.BatchableContext bc, List<acpl__AP_Period__c> listAPconfig) {
    system.debug('>>>>> BATCH listAPconfig: ' + listAPconfig);
    AP_NotificationBatchHandler.notifyAPTeam(listAPconfig);
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