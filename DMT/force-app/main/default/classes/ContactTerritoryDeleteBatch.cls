/**********************************************************************************
* @author  		Global Desktop
* @date         09/09/2019
* @description  Batch que asigna a las account territorios
* @Revision
**********************************************************************************/
public without sharing class ContactTerritoryDeleteBatch implements Database.Batchable<Sobject>, Database.Stateful {
	/*
     *  Variable
    **/
    private List<sObject> myList;//NOSONAR
	/*
     *  Variable
    **/
    private final Integer maxRecords = 8500;//NOSONAR
    /*
     *  Variable
    **/
    private Boolean last7Days = false;//NOSONAR

    /*
     *  Global Desktop
     *  CONSTRUCTOR
     *
    */
    public ContactTerritoryDeleteBatch(Boolean last7DaysParam) {
        last7Days = last7DaysParam;
        myList = new List<sObject>();
    }

    /*
     *  Global Desktop
     *
     *
    */
    public Database.QueryLocator start(Database.BatchableContext batchContext) {
        String pQuery;
        if(last7Days) {
            pQuery = 'SELECT Id FROM ContactShare where rowCause = \'Manual\' and LastModifiedDate = LAST_N_DAYS:7' + (Test.isRunningTest()?' LIMIT 1':''); //NOSONAR
        } else {
            pQuery = 'SELECT Id FROM ContactShare where rowCause = \'Manual\'' + (Test.isRunningTest()?' LIMIT 1':'');//NOSONAR
        }
        system.debug('>>>>> pQuery : ' + pQuery);
        return Database.getQueryLocator(pQuery);
    }

    /*
     *  Global Desktop
     *  CONSTRUCTOR
     *
    */
    public void execute(Database.BatchableContext batchContext, List<Contact> listContact) {
		DES_HandlerTerritory.deleteSharing(listContact);
    }//FIN execute

    /*
     *  Global Desktop
     *  CONSTRUCTOR
     *
    */
    public void finish(Database.BatchableContext batchContext) {}



}