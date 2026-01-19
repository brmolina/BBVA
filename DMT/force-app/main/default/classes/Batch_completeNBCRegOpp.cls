/**********************************************************************************
* @author
* @date
* @description  Batch para el cálculo de Revenues de Bookings desde Account
* @Revision
**********************************************************************************/
public without sharing class Batch_completeNBCRegOpp implements Database.Batchable<Sobject>, Database.Stateful {

    /*
    * Private Attribute pQuery
    */
    private final String pQuery;

    /*
    * Private Attribute recordsProcessed
    */
    private Integer recordsProcessed = 0;

    /*
    * Public Constructor
    */
    public Batch_completeNBCRegOpp() {
        pQuery = 'SELECT Id, DES_Booking_Geography__c, gf_opportunity_nbc_name__c, DES_NBC_Region__c FROM Opportunity WHERE isClosed = false AND Committee_id__c = null' + (Test.isRunningTest()?' LIMIT 1':'');
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
    public void execute(Database.BatchableContext bch, List<Opportunity> listOpps) {
        final List<String> emeaCountries = new List<String>{'PT', 'ID', 'ES', 'IN', 'GB', 'TW', 'JP', 'BE', 'SG', 'FR', 'IT', 'DE','HK'};
        final List<String> latamCountries = new List<String>{'UY', 'AR', 'PE', 'MX', 'VE', 'CO', 'CL'}; //NOSONAR
        final List<Opportunity> oppsToUpd = new List <Opportunity>();
        for(Opportunity opp : listOpps) {
            if(emeaCountries.contains(opp.DES_Booking_Geography__c)) {
                opp.DES_NBC_Region__c = 'EMEA';
            } else if(latamCountries.contains(opp.DES_Booking_Geography__c) || (opp.DES_Booking_Geography__c == 'NY' && opp.gf_opportunity_nbc_name__c == 'LATAM')) {
                opp.DES_NBC_Region__c = 'LATAM';
            } else if (checkUsa(opp)) {
                opp.DES_NBC_Region__c = 'USA';
            }
            oppsToUpd.add(opp);
        }
        if(!oppsToUpd.isEmpty()) {
            update oppsToUpd;
        }
        recordsProcessed += listOpps.size();
    }
    /*
    * Aux Method
    */
    private static Boolean checkUsa(Opportunity opp) {
        boolean usa;
        usa = false;
        if (opp.DES_Booking_Geography__c == 'Compass' || (opp.DES_Booking_Geography__c == 'NY' && (opp.gf_opportunity_nbc_name__c == 'USA' || opp.gf_opportunity_nbc_name__c == null))) {
            usa = true;
        }
        return usa;
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