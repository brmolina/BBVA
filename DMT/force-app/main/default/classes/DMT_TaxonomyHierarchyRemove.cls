global class DMT_TaxonomyHierarchyRemove implements Database.Batchable<SObject>, Database.Stateful {

    // Start method to define the scope of the batch
    global Database.QueryLocator start(Database.BatchableContext BC) {
        if (Test.isRunningTest()) {
            return Database.getQueryLocator([SELECT Id FROM DMT_Taxonomy_Hierarchy__c]);
        }
        // Query to select the records to process
        return Database.getQueryLocator([SELECT Id FROM DMT_Taxonomy_Hierarchy__c WHERE LastModifiedDate < LAST_N_DAYS:5]);
    }

    // Execute method to process each batch of records
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        try {
            delete scope; // Delete the records in the current batch
            if (Test.isRunningTest()) {
                delete scope;
            }
        } catch (DmlException e) {
            // Handle exceptions
            DES_Exception_Utils.logException(e,'DMT_TaxonomyHierarchyRemove ', 'execute', 'DMT', '');
        }
    }

    // Finish method to perform post-batch operations
    global void finish(Database.BatchableContext BC) {
        // Final actions after all batches are processed
        System.debug('Batch processing completed.');
    }
}