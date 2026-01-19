/******************************************************************************************************************************************************
*   @author: GlobalDesktop - APC
*   @Method: Batch_Visit_InvolvedProducts
*   @Description: Batch to update previous data related to scope field of contacts - related to ContactScopeManagement.class

*   @Versions:
        v1 - 2019/01/28 - Initial version
******************************************************************************************************************************************************/
public without sharing class Batch_Visit_InvolvedProducts implements Database.Batchable<Sobject>, Database.Stateful {

  /*
  * QUERY
  */
  final private String pQuery = 'SELECT Id, Name, dwp_kitv__visit_id__c, dwp_kitv__user_id__c FROM dwp_kitv__Visit_Management_Team__c WHERE dwp_kitv__user_id__r.gf_user_work_product_desc__c != null'
  + (Test.isRunningTest() ? ' LIMIT 2' : '');

  /*
  * CONSTRUCTOR
  */
  public Batch_Visit_InvolvedProducts() {
    system.debug('Batch_Visit_InvolvedProducts Constructor');
  }

  /*
  * START
  */
  public Database.QueryLocator start(Database.BatchableContext bContext) {
      System.debug('>>>>> Query: ' + pQuery);
      return Database.getQueryLocator(pQuery);
  }

  /*
  * EXECUTE
  */
  public void execute(Database.BatchableContext bContext, List<dwp_kitv__Visit_Management_Team__c> scope) {
    DES_VisitManagementTeam_TriggerHandler.fillInvolvedProducts(scope, false);
  }

  /*
  * FINISH
  */
  public void finish(Database.BatchableContext bContext) {
    system.debug('FINISH');
  }



}