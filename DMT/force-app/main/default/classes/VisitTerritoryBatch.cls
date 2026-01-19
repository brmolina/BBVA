/*
 *	@author	Global Desktop
 *	@description	Batch que se encarga de compartir las visitas con los territorios.
 *
 *
**/
public without sharing class VisitTerritoryBatch implements Database.Batchable<Sobject> {

	/*
	 * Query
	**/
	private String pQuery = 'SELECT Id, dwp_kitv__country_name__c, disclosure_info_type__c, gf_visit_users_products_desc__c FROM dwp_kitv__Visit__c WHERE disclosure_info_type__c != \'Inside information\' ' + (Test.isRunningTest()?' LIMIT 1':'');//NOSONAR
	/*
	 * myList
	**/
	private List<sObject> myList; //NOSONAR
	/*
	 * maxRecords
	**/
	private final Integer maxRecords = 8500; //NOSONAR


	/*
	 * CONSTRUCTOR
	**/
	public VisitTerritoryBatch() {
		system.debug('>>>>> pQuery : ' + pQuery);
		myList = new List<sObject>();
	}

	/*
	 * start method
	**/
	public Database.QueryLocator start(Database.BatchableContext batchCont) {
		return Database.getQueryLocator(pQuery);
	}

	/*
	 * execute batch method
	**/
	public void execute(Database.BatchableContext batchCont, List<dwp_kitv__Visit__c> listVisits) {
		myList.addAll(DES_HandlerTerritoryBatch.shareWithTerritoryListBatch(listVisits));
		DES_HandlerTerritory.insertRecords(myList,maxRecords);
	}//FIN execute

	/*
	 * finish method
	**/
	public void finish(Database.BatchableContext batchCont) {
		System.debug('>>>>>Database.executeBatch');
		if (myList != null && !myList.isEmpty()) {
			Database.executeBatch(new InsertShareTerritoryBatch(myList), 9000);
		}
	}



}