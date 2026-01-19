/*
 *  @author         Global Desktop
 *  @description    batch para la comparticion de los comites NBC
 *
 *
**/
public without sharing class NbcCommitteTerritoryBatch implements Database.Batchable<Sobject> {

    /*
     * variable
    **/
	private String pQuery = 'SELECT Id,Committee_id__c FROM Opportunity WHERE Committee_id__c != null ' + (Test.isRunningTest()?' LIMIT 1':'');//NOSONAR
	/*
     * variable
    **/
    private List<sObject> myList;//NOSONAR
	/*
     * variable
    **/
    private final Integer maxRecords = 8500;//NOSONAR

    /*
     * CONSTRUCTOR
    **/
    public NbcCommitteTerritoryBatch() {
        system.debug('>>>>> pQuery : ' + pQuery);
        myList = new List<sObject>();
    }

    /*
     * START
    **/
    public Database.QueryLocator start(Database.BatchableContext batchContx) {
        return Database.getQueryLocator(pQuery);
    }

    /*
     * EXECUTE
    **/
    public void execute(Database.BatchableContext batchContx,List<Opportunity> listOLI) {
		myList.addAll(DES_HandlerTerritoryBatch.shareNBCBatch(listOLI));
		DES_HandlerTerritory.insertRecords(myList,maxRecords);

    }//FIN execute

    /*
     * FINISH
    **/
    public void finish(Database.BatchableContext batchContx) {
    	System.debug('>>>>>Database.executeBatch');
        if (myList != null && !myList.isEmpty()) {
           Database.executeBatch(new InsertShareTerritoryBatch(myList), 9000);
        }
    }



}