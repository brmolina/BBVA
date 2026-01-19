/**********************************************************************************
* @author
* @date
* @description  Batch para el cálculo de Revenues de Bookings desde Account
* @Revision
**********************************************************************************/
public without sharing class Batch_deleteBBVAMembers implements Database.Batchable<Sobject>, Database.Stateful {

    /*
    * Private Attribute pQuery
    */
    private final String pQuery;

    /*
    * Private Attribute userIntegrator
    */
    private final static String userIntegrator = 'User Integrator'; //NOSONAR

    /*
    * Private Attribute recordsProcessed
    */
    private Integer recordsProcessed = 0;

    /*
    * Public Constructor
    */
    public Batch_deleteBBVAMembers() {
        pQuery = 'SELECT Id FROM DES_BBVA_Management_team__c WHERE CreatedBy.Name = :userIntegrator' + (Test.isRunningTest()?' LIMIT 1':'');
    }

    /*
    * start method
    */
    public Database.QueryLocator start(Database.BatchableContext bch) {
        system.debug('>>>>> query : ' + pQuery);
        return Database.getQueryLocator(pQuery);
    }

    /*
    * Execute method
    */
    public void execute(Database.BatchableContext bch, List<DES_BBVA_Management_team__c> listMembers) {
        system.debug('>>>>> listMembers : ' + listMembers);
        if(!listMembers.isEmpty()) {
            delete listMembers;
            recordsProcessed += listMembers.size();
        }
    }

    /*
    * Finish method
    */
    public void finish(Database.BatchableContext bch) {
        final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bch.getJobId()];

        System.debug('>>>>> SUMMARY: ');
        System.debug('>>>>>   Records Processed: ' + recordsProcessed);
        System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
        System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
        System.debug('>>>>>   Status: ' + job.Status);
    }
}