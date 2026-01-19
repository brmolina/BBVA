/*
* @author GlobalDesktop
* @description Batch to delete hitoric events
*/
public with sharing class VisitsEventDelete implements Database.Batchable<Sobject>, Database.Stateful {
  /* Query */
  private Set<Id> stvisitsIds; //NOSONAR

  /* Query */
  private Set<Id> setEventsDeleted; //NOSONAR

  /* Query */
  private String pQuery = ''; //NOSONAR

  /* Query */
  private String nextField = ''; //NOSONAR

  /* Query */
  private String nextTable = ''; //NOSONAR

  /*
  * Constructor
  */
  public VisitsEventDelete(Set<Id> visitsIds, String fieldLookup, String futureTable) {
    this.stvisitsIds = visitsIds;
    this.nextTable = futureTable;
    if(fieldLookup == 'WhatId') {
      this.nextField = 'WhatId';
    } else {
      this.nextField = 'dwp_kitv__visit_id__c';
    }
    this.pQuery = 'SELECT Id FROM Event ' + (Test.isRunningTest() ? ' LIMIT 1' : ' WHERE isArchived = true and isDeleted = false AND ' + fieldLookup + ' IN :visitsIds ALL ROWS'); //NOSONAR
  }

  /*
  * Start method
  */
  public Database.QueryLocator start(Database.BatchableContext bch) {
    system.debug('Query delete: ' + pQuery.substringAfterLast('WHERE'));
    system.debug('Query: ' + pQuery);
    setEventsDeleted = new Set<Id>();
    final Set<Id> visitsIds = this.stvisitsIds;
    system.debug('visitsIds: ' + visitsIds);
    return Database.getQueryLocator(pQuery);
  }

  /*
  * Execute method
  */
  public void execute(Database.BatchableContext bch,List<Event> scope) { //NOSONAR
    system.debug('delete scope' + JSON.serialize(scope));
    final List<Event> eventsToDelete = new List<Event>();
    for(Event evt : scope) {
      if(!setEventsDeleted.contains(evt.Id)) {
        setEventsDeleted.add(evt.Id);
        eventsToDelete.add(evt);
      }
    }
    if(!eventsToDelete.isEmpty()) {
      delete eventsToDelete;
    }
  }

  /*
  * Finish method
  */
  public void finish(Database.BatchableContext bch) {
    Database.executeBatch(new VisitTasksDelete(stvisitsIds, this.nextField, this.nextTable), 100);
  }
}