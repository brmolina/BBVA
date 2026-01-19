/**
* ────────────────────────────────────────────────────────────────────
* CucoProfitabilityErrorBatch
* Batch Class to send email information and notifications in Salesforce.
* ────────────────────────────────────────────────────────────────────
* @author      CuCo CIB <globalhub_components.group@bbva.com>
* @modifiedBy
* @version     1.0
* @created     July 2021
* @modified
* @systemLayer
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
public with sharing class CucoProfitabilityErrorBatch implements Database.Batchable<sObject>, Database.Stateful {
    //Number of records Processed
    private Integer recordsProcessed = 0;

    /*
    * @author         CIB
    * @Description    Batchable method
    */
    public Database.QueryLocator start(Database.BatchableContext batchc) {
        return Database.getQueryLocator(
            'SELECT Id, Name, cuco__gf_profitability_sheet_id__c, Number_of_errors__c ' +
            'FROM cuco__profitability_sheet__c ' +
            'WHERE Number_of_errors__c > 0 AND Notified__c = false'
        );
    }

    /*
    * @author         CIB
    * @Description    Batchable method
    */
    public void execute(Database.BatchableContext batchc, List<cuco__profitability_sheet__c> scope) {
        // process each batch of records
        final List<cuco__profitability_sheet__c> books = new List<cuco__profitability_sheet__c>();
        final Set<Id> idProfSheetSet = new Set<Id>();
        final Set<String> setProfSheetCode = new Set<String>();
        for (cuco__profitability_sheet__c book : scope) {
            book.Notified__c = true;
            books.add(book);
            idProfSheetSet.add(book.Id);
            setProfSheetCode.add(book.cuco__gf_profitability_sheet_id__c);
            recordsProcessed = recordsProcessed + 1;
        }
        if (!books.isEmpty()) {
            update books;
            CucoSendEmail.notifications (books, idProfSheetSet, setProfSheetCode);
        }
    }

    /*
    * @author         CIB
    * @Description    Batchable method
    */
    public void finish(Database.BatchableContext batchc) {
        // execute any post-processing operations
        final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed FROM AsyncApexJob WHERE Id = :batchc.getJobId()];
        System.debug(recordsProcessed + ' records processed!');
        System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
        System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
        System.debug('>>>>>   Status: ' + job.Status);
    }
}