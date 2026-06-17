// TXNM_ScheduleBatchProcess.cls
// Batches over TXNM_Taxonomy_mapping__mdt (one row per chunk).
// For each row, calls:
//   TXNM_DynamicPicklistService.createDynamicPicklistValues(taxonomyCode, metadataConfig)
//
// Notes:
// - Scope size is always 1 (enforced in execute()) so each row is handled independently.
// - We do NOT query TXNM_Taxonomy__b here (that happens later in your flow).
// - Assumes TXNM_Taxonomy_mapping__mdt has TaxonomyCode__c; falls back to DeveloperName if missing/blank.
// - WITH SECURITY_ENFORCED included in the metadata query.
// - Adjust sharing as needed.

global without sharing class TXNM_ScheduleSingleProcess implements Schedulable, Database.AllowsCallouts {
    public String taxonomyCode {get; set;}
    public TXNM_Taxonomy_mapping__mdt mdta {get; set;}
    // ---- Schedulable ----
    global void execute(SchedulableContext sc) {
        // Always run with scope size = 1
        try {
            TXNM_DynamicPicklistService.createDynamicPicklistValues(taxonomyCode, JSON.serialize(mdta));
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'TXNM_ScheduleBatchProcess error for code ' + taxonomyCode +
                ' (mapping=' + mdta.DeveloperName + '): ' + e.getMessage());
        }
    }
}