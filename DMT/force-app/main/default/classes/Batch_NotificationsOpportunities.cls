/**
* @author       Accenture
* @date         2019/09/15 
* @description  Batch para enviar notificaciones de las oportunidades proximas a vencer.
*               Se ha rehecho completamente este batch.
*
* Version   Date            Author          Summary of changes
* 0.1       2019/09/23      JSS             Se modifica la query para que el batch se lance diariamente y se notifique exactamente en los días definidos (no retroactivo).
* ----------------------------------------------------------------------------------
*/
public without sharing class Batch_NotificationsOpportunities implements Database.Batchable<sObject>, Database.Stateful {

  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  private Integer recordsUpdated = 0;
  private Date closingDate_Notification1;
  private Date closingDate_Notification2;
  private string oppInsideValue = Label.DES_OP_Inside;    
  private String bQuery = 'SELECT Id, trigger_action_type__c, CloseDate, disclosure_info_type__c, IsClosed, opportunity_expiration_ind_type__c ' + 
                          'FROM Opportunity ' + 
                          'WHERE (CloseDate = :closingDate_Notification1 OR CloseDate = :closingDate_Notification2) AND IsClosed = false AND disclosure_info_type__c != :oppInsideValue AND owner.isActive = true';


  //--------------------------------------- CONSTRUCTOR METHODS -----------------------------------
  public Batch_NotificationsOpportunities() {
    this.closingDate_Notification1 = Date.today().addDays(-20);
    this.closingDate_Notification2 = Date.today().addDays(-27);
  }

  public Batch_NotificationsOpportunities(Integer numDays_N1,Integer numDays_N2) {
    this.closingDate_Notification1 = Date.today().addDays(-numDays_N1);
    this.closingDate_Notification2 = Date.today().addDays(-numDays_N2);
  }

  //--------------------------------------- BATCHABLE METHODS -------------------------------------

  public Database.QueryLocator start(Database.BatchableContext bc) {   
     return Database.getQueryLocator(bQuery);
  }

  public  void execute(Database.BatchableContext bc,List<Opportunity> scope) {
    recordsUpdated = recordsUpdated + scope.size();
    for (Opportunity opp : scope) {
        opp.opportunity_expiration_ind_type__c = true;
        if (opp.CloseDate == this.closingDate_Notification2) { // Primera Notificación
           opp.trigger_action_type__c = 'Send Notify D-10';
        } else { // = closingDate_Notification1, Segunda Notificación
           opp.trigger_action_type__c = 'Send Notify D-3'; 
        }        
    }
    update scope;
  }

  public void finish(Database.BatchableContext bc) {
    AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];

    System.debug('>>>>>>> SUMMARY: ');
    System.debug('>>>>>>>   Records Updated: ' + recordsUpdated);
    System.debug('>>>>>>>   Batches Created: ' + job.JobItemsProcessed);
    System.debug('>>>>>>>   Number of Errors: ' + job.NumberOfErrors);
    System.debug('>>>>>>>   Status: ' + job.Status);
  }

}