/*
 *  @AUTHOR         Global Desktop
 *  @DESCRIPTION    clase batchable para la comparticion de las oportunidades con sus correspondientes territorios
 *
 *
 *
**/
public without sharing class OpportunityTerritoryBatch implements Database.Batchable<Sobject>, Database.Stateful {
    /*
     *  VARIABLE
    **/
    private String pQuery = 'SELECT Id, ProductCode, OpportunityId, Opportunity.DES_Booking_Geography__c, Opportunity.Account.DES_Segment__c, Opportunity.disclosure_info_type__c FROM OpportunityLineItem WHERE OpportunityId in (select id from Opportunity where AccountId != null AND disclosure_info_type__c != \'Inside information\')' + (Test.isRunningTest()?' LIMIT 1':'');//NOSONAR
	/*
     *  VARIABLE
    **/
    private List<sObject> myList;//NOSONAR
	/*
     *  VARIABLE
    **/
    private final Integer maxRecords = 8500;//NOSONAR

    /*
     *  CONSTRUCTOR
    **/
    public OpportunityTerritoryBatch() {
        system.debug('>>>>> pQuery : ' + pQuery);
        myList = new List<sObject>();
    }

    /*
     *  START
    **/
    public Database.QueryLocator start(Database.BatchableContext batchCtx) {
        return Database.getQueryLocator(pQuery);
    }

    /*
     *  EXECUTE
    **/
    public void execute(Database.BatchableContext batchCtx,List<OpportunityLineItem> listOLI) {
		myList.addAll(DES_HandlerTerritoryBatch.shareOpportunityBatch(listOLI));
        system.debug('::::: myList: ' + myList);
		DES_HandlerTerritory.insertRecords(myList,maxRecords);

    }//FIN execute

    /*
     *  FINISH
    **/
    public void finish(Database.BatchableContext batchCtx) {
        System.debug('>>>>> finish myList : ' + myList);
        system.debug('>>>>> pQuery : ' + pQuery);
        if (myList != null && !myList.isEmpty()) {
           Database.executeBatch(new InsertShareTerritoryBatch(myList), 9000);
        }
    }


}