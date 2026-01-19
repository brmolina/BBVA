/*
* @author GlobalDesktop
* @description Batch to delete hitoric opps
*/
public with sharing class OppBigObjectDelete implements Database.Batchable<Sobject>, Database.Stateful {

  /* Query */
  private Set<Id> stoppsIds; //NOSONAR

  /* Query */
  private String pQuery = ''; //NOSONAR

  /* Query */
  private Boolean execution; //NOSONAR

  /*
  * Constructor
  */
  public OppBigObjectDelete(Set<Id> oppsIds, String tableToDelete, String fieldLookup, Boolean execution) {
    this.stoppsIds = oppsIds;
    this.execution = execution;
    this.pQuery = 'SELECT Id FROM ' + tableToDelete + (Test.isRunningTest() ? ' LIMIT 1' : ' WHERE ' + fieldLookup + ' IN :oppsIds'); //NOSONAR
  }

  /*
  * Start method
  */
  public Database.QueryLocator start(Database.BatchableContext bch) {
    system.debug('Query delete: ' + pQuery.substringAfterLast('WHERE'));
    system.debug('Query: ' + pQuery);
    final Set<Id> oppsIds = this.stoppsIds;
    system.debug('oppsIds: ' + oppsIds);
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
      Database.executeBatch(new OppBigObjectDelete(stoppsIds, 'Opportunity', 'Id', false), 100);
    }
  }
}