/*
* batch upadate contact active
*/
public without sharing class DES_Batch_Update_ActiveContact implements Database.Batchable<Sobject>, Database.Stateful {
    private final String pQuery;
    private final String inactiveRT = 'Desktop_Inactive_Contact'; //NOSONAR

    /*
    * constructor method
    */
    public DES_Batch_Update_ActiveContact() {
        pQuery = 'Select Id, role_status_contact_prtcpt_type__c from Contact where recordtype.DeveloperName != :inactiveRT' + (Test.isRunningTest()?' LIMIT 1':'');
    }
    /*
    * start method
    */
    public Database.QueryLocator start(Database.BatchableContext bch) {
        return Database.getQueryLocator(pQuery);
    }
    /*
    * Execute method
    */
    public void execute(Database.BatchableContext bch,List<Contact> scope) {
        final List<Contact> contactUpdate = new List<Contact>();
        for(Contact con : scope) {
            con.role_status_contact_prtcpt_type__c = true;
            contactUpdate.add(con);
        }
        update contactUpdate;
    }
    /*
    * Finish method
    */
    public void finish(Database.BatchableContext bch) {
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bch.getJobId()];
        System.debug('>>>>> SUMMARY: ');
        System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
        System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
        System.debug('>>>>>   Status: ' + job.Status);
    }


}