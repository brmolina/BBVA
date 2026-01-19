/**
* ____________________________________________________________________________
* Cuco Delete Participants Batch
* Remove participants marked as deleted.
* ____________________________________________________________________________
* @author      Torcuato Tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2021-08-16
* @modified
* @systemLayer Service
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
global class CucoDeleteParticipantsBatch implements Database.Batchable<sObject>, Database.Stateful {

    final private String query = 'SELECT Id, cuco__gf_profitability_sheet_id__c, Valid_Participant__c, cuco__participant_id__r.Name, cuco__participant_id__r.SER_CClient__c FROM cuco__profitability_sheet_participant__c WHERE Valid_Participant__c = false AND cuco__gf_profitability_sheet_id__r.cuco__gf_prftbly_sheet_stt_type_name__c NOT IN (\'10\', \'12\')';
    private Integer recordsDeleted = 0;

    global Database.QueryLocator start(Database.BatchableContext batchContext) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext batchContext, List<cuco__profitability_sheet_participant__c> records) {
        System.debug('Deleting ' + records.size() + ' records...');
        System.debug(records);

        if (records.size() > 0) {
            recordsDeleted += records.size();
            auditRecords(records);
            delete records;
        }
    }

    global void finish(Database.BatchableContext batchContext) {
        final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :batchContext.getJobId()];
        System.debug('Delete Participants summary: ');
        System.debug('Records deleted: ' + recordsDeleted);
        System.debug('Total job items: ' + job.TotalJobItems);
        System.debug('Batches created: ' + job.JobItemsProcessed);
        System.debug('Number of errors: ' + job.NumberOfErrors);
        System.debug('Status: ' + job.Status);
    }

    private void auditRecords(List<cuco__profitability_sheet_participant__c> records) {

        final List<dwp_cvad__Action_Audit__c> audits = new List<dwp_cvad__Action_Audit__c>();

        for (cuco__profitability_sheet_participant__c record : records) {

            final dwp_cvad__Action_Audit__c audit = new dwp_cvad__Action_Audit__c();
            final string name = record.cuco__participant_id__r.SER_CClient__c + ' - ' + record.cuco__participant_id__r.Name + ' was removed from participants.';

            if(name.length() > 255) {
                final string strippedName = name.substring(0,251) + '...';
                audit.dwp_cvad__action_audit_name__c = strippedName.stripHtmlTags();
            } else {
                audit.dwp_cvad__action_audit_name__c = name.stripHtmlTags();
            }

            audit.dwp_cvad__action_audit_object_api_name__c = 'cuco__profitability_sheet__c';
            audit.dwp_cvad__action_audit_record_id__c = record.cuco__gf_profitability_sheet_id__c;
            audit.dwp_cvad__action_audit_style__c = 'delete';
            audit.dwp_cvad__action_audit_date__c = DateTime.now();
            audit.dwp_cvad__action_audit_type__c = 'ProfitabilitySheet';
            audit.dwp_cvad__action_audit_user_id__c = UserInfo.getUserId();
            audits.add(audit);
        }
        if (audits.size() > 0) {
            insert audits;
        }
    }

}