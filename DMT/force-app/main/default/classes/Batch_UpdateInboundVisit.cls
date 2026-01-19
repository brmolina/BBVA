/***********************************************************************************************
Name:            Batch_UpdateInboundVisit
Description:     Batch class to migrate the owner of the visit to team member
Test Class:      -

Version        Date            Author            Summary of changes
------------------------------------------------------------------------------------------------
1.0            12/11/2019                        Class creation

***********************************************************************************************/
public with sharing class Batch_UpdateInboundVisit implements Database.Batchable<Sobject>, Database.Stateful {
    /**
	 * Query used in the batch
	 */
	final private String pQuery = 'SELECT Id, OwnerId, dwp_kitv__account_id__r.DES_Country_Client__c, dwp_kitv__account_id__r.group_management_country_id__c FROM dwp_kitv__Visit__c' + (Test.isRunningTest() ? ' LIMIT 200' : '');

    /**
     * Constructor
     */	
	public Batch_UpdateInboundVisit() {
		System.debug('Batch_UpdateOwnerVisitTeam constructor');
    }

    /**
	 * Implementation of the start method of the Database.Batchable interface
     */
    public Database.QueryLocator start(Database.BatchableContext bContext) {
        System.debug('>>>>> Query: ' + pQuery);
        return Database.getQueryLocator(pQuery);
    }
    
    /**
	 * Implementation of the execute method of the Database.Batchable interface
     */
    public void execute(Database.BatchableContext bContext, List<dwp_kitv__Visit__c> scope) {
        final List<dwp_kitv__Visit__c> listVisit = new List<dwp_kitv__Visit__c>();
        for(dwp_kitv__Visit__c iVisit : scope) {
            if(iVisit.dwp_kitv__account_id__r.DES_Country_Client__c != iVisit.dwp_kitv__account_id__r.group_management_country_id__c) {
                iVisit.visit_type__c = 'Inbound';
                listVisit.add(iVisit);
            }
        }

        if(!listVisit.isEmpty()) {
            update listVisit;
        }
    }

    /**
	 * Implementation of the finish method of the Database.Batchable interface
     */
	public void finish(Database.BatchableContext bContext) {
		system.debug('Finish');
	}
}