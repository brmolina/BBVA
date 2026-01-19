/**********************************************************************************
* @author  		Global Desktop
* @date         09/09/2019
* @description  Batch que asigna a las account territorios
* @Revision
**********************************************************************************/
public without sharing class AccountTerritoryBatch implements Database.Batchable<Sobject>, Database.Stateful {
    /*
     *  String query variable
    **/
    private final String pQuery = 'SELECT Id, DES_Country_Client__c, DES_Segment__c FROM Account WHERE LastModifiedDate = LAST_N_DAYS:7 AND DES_Structure_Type__c != null' + (Test.isRunningTest()?' LIMIT 1':'');
	/*
     *  List sObject variable
    **/
    private List<sObject> myList; //NOSONAR
    /*
     *  integer maxRecords variable
    **/
	private final Integer maxRecords = 8500; //NOSONAR

    /*
     *  @author     Global Desktop
     *  @description    Constructor
    **/
    public AccountTerritoryBatch() {
        system.debug('>>>>> pQuery : ' + pQuery);
        myList = new List<sObject>();
    }

    /*
     *  @author     Global Desktop
     *  @description    batch START method
    **/
    public Database.QueryLocator start(Database.BatchableContext batchContext) {
        return Database.getQueryLocator(pQuery);
    }

    /*
     *  @author     Global Desktop
     *  @description    batch EXECUTE method
    **/
    public void execute(Database.BatchableContext batchContext, List<Account> listAccounts) {
		myList.addAll(DES_HandlerTerritoryBatch.shareWithTerritoryListBatch(listAccounts));
		DES_HandlerTerritory.insertRecords(myList,maxRecords);

    }//FIN execute

    /*
     *  @author     Global Desktop
     *  @description    batch FINISH method
    **/
    public void finish(Database.BatchableContext batchContext) {
    	System.debug('>>>>>Database.executeBatch');
        if (myList != null && !myList.isEmpty()) {
           Database.executeBatch(new InsertShareTerritoryBatch(myList), 9000);
        }
    }


}