/**
* --------------------------------------------------------------------
* Batch class to update SER_Process_date__c on exchange rate records
* to the current date. Used in sandbox/dev orgs where exchange rates
* are not loaded daily, to keep records within the 7-day filter window.
* Implements Schedulable so it can be scheduled every 6 days.
* --------------------------------------------------------------------
* @version     1.0
* @created     2025-07-15
* @systemLayer Business Logic
* --------------------------------------------------------------------
*/
public with sharing class DMT_Currency_ExchangeRate_Batch implements Database.Batchable<SObject>, Schedulable {

    /**
    * @description Schedulable execute - launches the batch
    * @param sc SchedulableContext
    */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new DMT_Currency_ExchangeRate_Batch(), 200);
    }

    /**
    * @description Batch start - queries exchange rate records with outdated process date
    * @param bc Database.BatchableContext
    * @return Database.QueryLocator
    */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date today = Date.today();
        return Database.getQueryLocator([
            SELECT Id, SER_Process_date__c
            FROM SER_EUR_Currency_exchange_rate__c
            WHERE SER_Base_currency__c = 'EUR'
            AND SER_Process_date__c < :today
        ]);
    }

    /**
    * @description Batch execute - updates SER_Process_date__c to today
    * @param bc Database.BatchableContext
    * @param scope List of records to update
    */
    public void execute(Database.BatchableContext bc, List<SER_EUR_Currency_exchange_rate__c> scope) {
        Date today = Date.today();
        for (SER_EUR_Currency_exchange_rate__c record : scope) {
            record.SER_Process_date__c = today;
        }
        update scope;
    }

    /**
    * @description Batch finish
    * @param bc Database.BatchableContext
    */
    public void finish(Database.BatchableContext bc) {
        System.debug('DMT_Currency_ExchangeRate_Batch completed. Records updated to current date.');
    }

    /**
    * @description Schedule the batch to run every 6 days.
    *              Execute in Anonymous Apex:
    *              DMT_Currency_ExchangeRate_Batch.scheduleEvery6Days();
    */
    public static void scheduleEvery6Days() {
        // Schedule 5 jobs covering a 30-day cycle (every 6 days)
        // Runs at 1:00 AM
        String jobPrefix = 'DMT_ExchangeRate_Update_';
        Date startDate = Date.today().addDays(1);
        for (Integer i = 0; i < 5; i++) {
            Date runDate = startDate.addDays(i * 6);
            String cronExp = '0 0 1 ' + runDate.day() + ' ' + runDate.month() + ' ? ' + runDate.year();
            System.schedule(jobPrefix + runDate.format(), cronExp, new DMT_Currency_ExchangeRate_Batch());
        }
    }

    /**
    * @description Run the batch immediately (for one-time manual execution).
    *              Execute in Anonymous Apex:
    *              DMT_Currency_ExchangeRate_Batch.runNow();
    */
    public static void runNow() {
        Database.executeBatch(new DMT_Currency_ExchangeRate_Batch(), 200);
    }
}