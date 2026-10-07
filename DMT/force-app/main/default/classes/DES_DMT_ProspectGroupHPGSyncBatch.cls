/**
 * @description Batch to sync unsynced Prospects Groups to HPG.
 *              Processes Prospect Groups that have not yet been
 *              synced (DMT_Prospect_HPG_Sync__c = false).
 * 
 * Execute: Database.executeBatch(new DES_DMT_ProspectGroupHPGSyncBatch(), 1);
 */
public without sharing class DES_DMT_ProspectGroupHPGSyncBatch implements Database.Batchable<SObject> {

    private static final Id GROUP_RT_ID = Schema.SObjectType.Account
        .getRecordTypeInfosByDeveloperName()
        .get(DES_Constants.ACCOUNT_RT_PROSPECT_GROUP)
        .getRecordTypeId();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, RecordTypeId, DES_Group_Code__c, g_customer_id__c,
                   DES_Country_Client__c, g_golden_customer_id__c, participant_id__c,
                   DES_Prospect_Status_Funnel__c, DMT_Prospect_HPG_Sync__c
            FROM Account
            WHERE RecordTypeId = :GROUP_RT_ID AND DES_Group_Code__c != null AND DMT_Prospect_HPG_Sync__c = false
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        System.debug(LoggingLevel.INFO, 'log::Processing ' + scope.size() + ' accounts');
        for (Account acc : scope) {
            DMT_AsyncOrchestrator.enqueue(new DES_ProspectStructurePayload(acc, 'DES_PostCreateProspect'));
        }
        DMT_AsyncOrchestrator.flush();
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO, 'log::DES_DMT_ProspectHPGSyncBatch finished');
    }
}