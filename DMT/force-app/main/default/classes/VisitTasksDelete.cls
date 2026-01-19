/*
* @author GlobalDesktop
* @description Batch to delete hitoric tasks
*/
public with sharing class VisitTasksDelete implements Database.Batchable<Sobject>, Database.Stateful {
  /* Query */
  private Set<Id> stvisitsIds; //NOSONAR

  /* Query */
  private Set<Id> stTasksDeleted; //NOSONAR

  /* Query */
  private String pQuery = ''; //NOSONAR

  /* Query */
  private String nextTable = ''; //NOSONAR

  /*
  * Constructor
  */
  public VisitTasksDelete(Set<Id> visitsIds, String fieldLookup, String futureTable) {
    this.stvisitsIds = visitsIds;
    this.nextTable = futureTable;
    this.pQuery = 'SELECT Id FROM Task ' + (Test.isRunningTest() ? ' LIMIT 1' : ' WHERE isArchived = true and isDeleted = false AND ' + fieldLookup + ' IN :visitsIds ALL ROWS'); //NOSONAR
  }

  /*
  * Start method
  */
  public Database.QueryLocator start(Database.BatchableContext bch) {
    system.debug('Query delete: ' + pQuery.substringAfterLast('WHERE'));
    system.debug('Query: ' + pQuery);
    stTasksDeleted = new Set<Id>();
    final Set<Id> visitsIds = this.stvisitsIds;
    system.debug('visitsIds: ' + visitsIds);
    return Database.getQueryLocator(pQuery);
  }

  /*
  * Execute method
  */
  public void execute(Database.BatchableContext bch,List<Task> scope) { //NOSONAR
    system.debug('delete scope' + JSON.serialize(scope));
    final List<Task> tasksToDelete = new List<Task>();
    for(Task tsk : scope) {
      if(!stTasksDeleted.contains(tsk.Id)) {
        stTasksDeleted.add(tsk.Id);
        tasksToDelete.add(tsk);
      }
    }
    if(!tasksToDelete.isEmpty()) {
      delete tasksToDelete;
    }
  }

  /*
  * Finish method
  */
  public void finish(Database.BatchableContext bch) {
    if(this.nextTable == 'Visit') {
      Database.executeBatch(new VisitBigObjectDelete(stvisitsIds, 'dwp_kitv__Visit__c', 'Id', false), 100);
    } else if (this.nextTable == 'Opportunity') {
      Database.executeBatch(new OppBigObjectDelete(stvisitsIds, 'OpportunityTeamMember', 'OpportunityId', true), 100);
    } else {
      Database.executeBatch(new AlertBigObjectDelete(stvisitsIds, 'ctcp__Custom_Team__c', 'commercial_alert_id__c', true), 1);
    }
  }
}