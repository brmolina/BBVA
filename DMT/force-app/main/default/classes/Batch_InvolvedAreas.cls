/******************************************************************************************************************************************************
*   @author: GlobalDesktop - APC
*   @Method: Batch_InvolvedAreas
*   @Description: Batch to update previous data related to scope field of contacts - related to ContactScopeManagement.class

*   @Versions:
        v1 - 2019/01/28 - Initial version
******************************************************************************************************************************************************/
public without sharing class Batch_InvolvedAreas implements Database.Batchable<Sobject>, Database.Stateful {


  final private String pQuery = 'SELECT Id, Name, dwp_kitv__visit_id__c, dwp_kitv__visit_id__r.dwp_kitv__solution_name_path_desc__c, ' +
      'dwp_kitv__user_id__c, dwp_kitv__user_id__r.ProfileId, dwp_kitv__user_id__r.Profile.Name, dwp_kitv__user_id__r.dwp_kitv__EMPLOYEE_DEPARTMENT_DESC__c FROM dwp_kitv__Visit_Management_Team__c'
  + (Test.isRunningTest() ? ' LIMIT 200' : '');

    public Batch_InvolvedAreas() {

    }

    public Database.QueryLocator start(Database.BatchableContext bContext) {
        System.debug('>>>>> Query: ' + pQuery);
        return Database.getQueryLocator(pQuery);
    }

    public void execute(Database.BatchableContext bContext, List<dwp_kitv__Visit_Management_Team__c> scope) {
      final Batch_InvolvedAreas_Handler handler = Batch_InvolvedAreas_Handler.getInstance();
      handler.logicSetInvolvedAreas(scope);
    }

    public void finish(Database.BatchableContext bContext) {
      system.debug('FINISH');
    }



}