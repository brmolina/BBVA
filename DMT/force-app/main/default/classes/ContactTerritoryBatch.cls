/**********************************************************************************
* @author  		Global Desktop
* @date         09/09/2019
* @description  Batch que asigna a las account territorios
* @Revision
**********************************************************************************/
public without sharing class ContactTerritoryBatch implements Database.Batchable<Sobject>, Database.Stateful {
    /*
     *  @author     Global Desktop
    **/
    private final String pQuery = 'SELECT Id, DES_Scope__c FROM Contact where LastModifiedDate = LAST_N_DAYS:7' + (Test.isRunningTest()?' LIMIT 1':'');
	/*
     *  @author     Global Desktop
    **/
    private List<sObject> myList;//NOSONAR
	/*
     *  @author     Global Desktop
    **/
    private final Integer maxRecords = 8500;//NOSONAR

    /*
     *  @author Global Desktop
     *  CONSTRUCTOR
     *
    **/
    public ContactTerritoryBatch() {
        system.debug('>>>>> pQuery : ' + pQuery);
        myList = new List<sObject>();
    }


    /*
     *  @author Global Desktop
     *  START METHOD
     *
    **/
    public Database.QueryLocator start(Database.BatchableContext batchContext) {
        return Database.getQueryLocator(pQuery);
    }


    /*
     *  @author Global Desktop
     *  EXECUTE METHOD
     *
    **/
    public void execute(Database.BatchableContext batchContext,List<Contact> listContact) {
		myList.addAll(DES_HandlerTerritoryBatch.shareWithTerritoryListBatch(listContact));
		DES_HandlerTerritory.insertRecords(myList,maxRecords);
    }//FIN execute

    /*
     *  @author Global Desktop
     *  FINISH METHOD
     *
    **/
    public void finish(Database.BatchableContext batchContext) {
    	System.debug('>>>>>Database.executeBatch');
        if (myList != null && !myList.isEmpty()) {
           Database.executeBatch(new InsertShareTerritoryBatch(myList), 9000);
        }
    }


}