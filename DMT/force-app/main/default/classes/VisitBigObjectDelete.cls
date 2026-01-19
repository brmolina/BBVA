/*
* @author GlobalDesktop
* @description Batch to delete hitoric visits
*/
public with sharing class VisitBigObjectDelete implements Database.Batchable<Sobject>, Database.Stateful {
  /* Query */
  private Set<Id> stvisitsIds; //NOSONAR

  /* Query */
  private String pQuery = ''; //NOSONAR

  /* Query */
  private Boolean execution; //NOSONAR

  /*
  * Constructor
  */
  public VisitBigObjectDelete(Set<Id> visitsIds, String tableToDelete, String fieldLookup, Boolean execution) {
    this.stvisitsIds = visitsIds;
    this.execution = execution;
    this.pQuery = 'SELECT Id FROM ' + tableToDelete + (Test.isRunningTest() ? ' LIMIT 1' : ' WHERE ' + fieldLookup + ' IN :visitsIds'); //NOSONAR
  }

  /*
  * Start method
  */
  public Database.QueryLocator start(Database.BatchableContext bch) {
    system.debug('Query delete: ' + pQuery.substringAfterLast('WHERE'));
    system.debug('Query: ' + pQuery);
    final Set<Id> visitsIds = this.stvisitsIds;
    system.debug('visitsIds: ' + visitsIds);
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

  }
}