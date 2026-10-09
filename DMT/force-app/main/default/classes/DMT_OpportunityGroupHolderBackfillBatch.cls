/**
 * @description One-off backfill batch for Opportunity.DMT_Group_Name__c / DMT_Main_Holder_Name__c
 * (Grupo y Main Holder en Opportunity tras migración Multiholder).
 *
 * DMT_OpportunityGroupHolderService.syncGroupAndMainHolderNames() resolves the Group Name by
 * walking the Account hierarchy (DMT_HPG_Utils.buildClientGroupStructure / buildAncestorsHierarchy),
 * which issues SOQL queries per hierarchy level PER Opportunity - not bulkified. Running the sync
 * for many Opportunities within a single synchronous transaction (e.g. Execute Anonymous) can
 * exceed the 100 SOQL queries per transaction governor limit. This batch keeps the scope size
 * small enough per execute() chunk to stay safely under that limit, regardless of how many
 * Opportunities need to be backfilled.
 *
 * Usage (Execute Anonymous):
 *   Database.executeBatch(new DMT_OpportunityGroupHolderBackfillBatch(), 15);
 */
public without sharing class DMT_OpportunityGroupHolderBackfillBatch implements Database.Batchable<SObject> {

    private static final String OPPORTUNITY_RECORD_TYPE_DEV_NAME = 'DMT_Opportunity';

    /**
     * @description Query locator for all DMT Opportunities eligible for the Group Name / Main
     * Holder Name backfill.
     * @param bc Batch context (unused)
     * @return QueryLocator over Opportunity Ids
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Opportunity
            WHERE AccountId != null
            AND RecordType.DeveloperName = :OPPORTUNITY_RECORD_TYPE_DEV_NAME
        ]);
    }

    /**
     * @description Recomputes and persists DMT_Group_Name__c / DMT_Main_Holder_Name__c for each
     * chunk of Opportunities.
     * @param bc Batch context (unused)
     * @param scope Opportunities in the current chunk
     */
    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        Set<Id> opportunityIds = new Set<Id>();
        for (Opportunity opp : scope) {
            opportunityIds.add(opp.Id);
        }
        DMT_OpportunityGroupHolderService.syncGroupAndMainHolderNames(opportunityIds);
    }

    /**
     * @description No follow-up action needed once the batch finishes.
     * @param bc Batch context (unused)
     */
    public void finish(Database.BatchableContext bc) {
        System.debug('DMT_OpportunityGroupHolderBackfillBatch finished.');
    }
}