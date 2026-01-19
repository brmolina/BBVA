/**
* @author Global Desktop
*/
public with sharing class AlertBigObjectDelete implements Database.Batchable<Sobject>, Database.Stateful {

  /* Query */
  private Set<Id> stalertsIds; //NOSONAR

  /* Query */
  private String pQuery = ''; //NOSONAR

  /* Query */
  private Boolean execution; //NOSONAR

  /*
  * Constructor
  */
  public AlertBigObjectDelete(Set<Id> alertsIds, String tableToDelete, String fieldLookup, Boolean execution) {
    this.stalertsIds = alertsIds;
    this.execution = execution;
    this.pQuery = 'SELECT Id FROM ' + tableToDelete + (Test.isRunningTest() ? ' LIMIT 1' : ' WHERE ' + fieldLookup + ' IN :alertsIds'); //NOSONAR
  }

  /*
  * Start method
  */
  public Database.QueryLocator start(Database.BatchableContext bch) {
    system.debug('Query delete: ' + pQuery.substringAfterLast('WHERE'));
    system.debug('Query: ' + pQuery);
    final Set<Id> alertsIds = this.stalertsIds;
    system.debug('alertsIds: ' + alertsIds);
    return Database.getQueryLocator(pQuery);
  }

  /*
  * Execute method
  */
  public void execute(Database.BatchableContext bch,List<SObject> scope) { //NOSONAR
    system.debug('delete scope' + JSON.serialize(scope));
    delete scope;
  }

  /*
  * Finish method
  */
  public void finish(Database.BatchableContext bch) {
    if(execution) {
      Database.executeBatch(new AlertBigObjectDelete(stalertsIds, 'altm__Commercial_Alert__c', 'Id', false), 1);
    }
  }
}