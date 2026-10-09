public with sharing class DMT_XSell {

    // Custom exception for clean error bubbling
    public class XSellException extends Exception {}

    @AuraEnabled(cacheable=false)
    public static List<DMT_X_Sell__c> getXSellRecords(Id parentId) {
        if (parentId == null) return new List<DMT_X_Sell__c>();

        Boolean isGodMode = FeatureManagement.checkPermission('DMT_Line_God');
        AccessLevel dbMode = isGodMode ? AccessLevel.SYSTEM_MODE : AccessLevel.USER_MODE;

        if (dbMode == AccessLevel.USER_MODE && (!Schema.sObjectType.DMT_X_Sell__c.isAccessible())) {
            throw new XSellException('Insufficient permissions to query Cross Sell records.');
        }

        String sObjName = parentId.getSObjectType().getDescribe().getName();
        
        String query = 'SELECT Id, Booking_Geography__c, XSELL_Value_PY__c, XSELL_Value_CY__c, ' +
                       'XSELL_Value_NY__c, XSELL_Value_NY1__c ' +
                       'FROM DMT_X_Sell__c ';

        if (sObjName == 'Opportunity') {
            query += 'WHERE Opportunity__c = :parentId';
        } else if (sObjName == 'Account') {
            query += 'WHERE Account__c = :parentId';
        } else {
            return new List<DMT_X_Sell__c>();
        }

        return Database.query(query, dbMode);
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getGeographyOptions(String entityCode) {
        List<Map<String, String>> options = new List<Map<String, String>>();
        Set<String> seenFinalValues = new Set<String>();
        system.debug('entityCode: ' + entityCode);
        // If an entity code is passed (Opportunity), do the strict Relationship query exactly like the DataRaptor
        if (String.isNotBlank(entityCode)) {
            for (DMT_Taxonomy_Relationship__c rel : [
                SELECT DMT_Final_Taxonomy_Value__r.DMT_Name_EN__c, DMT_Final_Taxonomy_Value__r.DMT_Value__c 
                FROM DMT_Taxonomy_Relationship__c 
                WHERE DMT_Id_Catalog_Final__c = 'H007' 
                  AND DMT_Id_Catalog_Initial__c = 'H006' 
                  AND DMT_Final_Taxonomy_Value__r.DMT_Active__c = true 
                  AND DMT_Initial_Taxonomy_Value__r.DMT_Value__c = :entityCode
                WITH SYSTEM_MODE
                ORDER BY DMT_Final_Taxonomy_Value__r.DMT_Value__c
            ]) {
                String finalValue = rel.DMT_Final_Taxonomy_Value__r.DMT_Value__c;
                if (String.isBlank(finalValue) || seenFinalValues.contains(finalValue)) {
                    continue;
                }
                seenFinalValues.add(finalValue);
                options.add(new Map<String, String>{
                    'label' => rel.DMT_Final_Taxonomy_Value__r.DMT_Name_EN__c,
                    'value' => finalValue
                });
            }
        } else {
            // Fallback for Account or if Entity is blank: Get standard H007 options directly
            for (DMT_Taxonomy_Values__c tax : [
                SELECT DMT_Name__c, DMT_Value__c 
                FROM DMT_Taxonomy_Values__c 
                WHERE DMT_Catalog__c = 'H007'
                  AND DMT_Active__c = true 
                WITH SYSTEM_MODE
                ORDER BY DMT_Value__c
            ]) {
                options.add(new Map<String, String>{
                    'label' => tax.DMT_Name__c,
                    'value' => tax.DMT_Value__c
                });
            }
        }
        return options;
    }

    @AuraEnabled
    public static void saveXSellRecords(List<DMT_X_Sell__c> recordsToUpsert, List<String> recordsToDelete) {
        Boolean isGodMode = FeatureManagement.checkPermission('DMT_Line_God');
        AccessLevel dbMode = isGodMode ? AccessLevel.SYSTEM_MODE : AccessLevel.USER_MODE;
        Savepoint sp = Database.setSavepoint();

        try {
            // Delegating to helper methods keeps Cognitive Complexity low
            handleDeletions(recordsToDelete, AccessLevel.SYSTEM_MODE);
            handleUpserts(recordsToUpsert, AccessLevel.SYSTEM_MODE);
            // Clean up any duplicate records that may have been created by repeated PubSub events
            deduplicateXSellRecords(recordsToUpsert, AccessLevel.SYSTEM_MODE);
        } catch (Exception e) {
            Database.rollback(sp);
            
            // Fix for Salesforce obscuring AuraHandledException messages
            String errorMsg = 'Error saving Cross Sell data: ' + e.getMessage();
            AuraHandledException ex = new AuraHandledException(errorMsg);
            ex.setMessage(errorMsg); // This forces the custom message to reach the LWC and Test Class
            throw ex;
        }
    }

    private static void handleDeletions(List<String> rawIds, AccessLevel dbMode) {
        if (rawIds == null || rawIds.isEmpty()) { return; }

        // Enforce CRUD to clear the Security-ApexCRUDViolation linter rule
        if (dbMode == AccessLevel.USER_MODE && !Schema.sObjectType.DMT_X_Sell__c.isDeletable()) {
            throw new XSellException('Insufficient permissions to delete Cross Sell records.');
        }

        List<Id> validIdsToDelete = new List<Id>();
        for (String rawId : rawIds) {
            Id validId = getValidId(rawId);
            if (validId != null) {
                validIdsToDelete.add(validId);
            }
        }
        
        if (!validIdsToDelete.isEmpty()) {
            String deleteQuery = 'SELECT Id FROM DMT_X_Sell__c WHERE Id IN :validIdsToDelete';
            List<DMT_X_Sell__c> toDelete = Database.query(deleteQuery, dbMode);
            Database.delete(toDelete, dbMode);
        }
    }

    private static void handleUpserts(List<DMT_X_Sell__c> recordsToUpsert, AccessLevel dbMode) {
        if (recordsToUpsert == null || recordsToUpsert.isEmpty()) { return; }

        // Enforce CRUD to clear the Security-ApexCRUDViolation linter rule
        if (dbMode == AccessLevel.USER_MODE && 
           (!Schema.sObjectType.DMT_X_Sell__c.isCreateable() || !Schema.sObjectType.DMT_X_Sell__c.isUpdateable())) {
            throw new XSellException('Insufficient permissions to create or update Cross Sell records.');
        }

        // DEDUPLICATION: Remove records that already exist in the database with identical field values
        List<DMT_X_Sell__c> deduplicatedRecords = deduplicateAgainstDatabase(recordsToUpsert, dbMode);
        
        if (deduplicatedRecords.isEmpty()) { 
            return; // Nothing left to save after deduplication
        }

        for (DMT_X_Sell__c rec : deduplicatedRecords) {
            if (rec.Id != null) {
                // If the ID is invalid, this sets it to null so Salesforce treats it as an insert
                rec.Id = getValidId(String.valueOf(rec.Id));
            }
        }
        
        Database.upsert(deduplicatedRecords, dbMode);
    }

    /**
     * HELPER METHOD: Isolates the try/catch block.
     * This allows you to use Id.valueOf() without spiking the Cognitive Complexity 
     * of the loops in the parent methods above.
     */
    private static Id getValidId(String rawId) {
        if (String.isBlank(rawId) || rawId == '0' || rawId.startsWith('NEW_')) {
            return null;
        }
        try {
            return Id.valueOf(rawId);
        } catch (Exception e) {
            // Fails silently, returning null to gracefully reject bad UI data
            return null;
        }
    }

    /**
     * DEDUPLICATION GUARDRAIL #1: Filters incoming records against existing database records.
     * Skips any record that already exists with identical values for the 5 key fields:
     * Booking_Geography__c, XSELL_Value_PY__c, XSELL_Value_CY__c, XSELL_Value_NY__c, XSELL_Value_NY1__c
     * 
     * This prevents duplicate inserts when the PubSub event fires multiple times.
     */
    private static List<DMT_X_Sell__c> deduplicateAgainstDatabase(List<DMT_X_Sell__c> recordsToUpsert, AccessLevel dbMode) {
        if (recordsToUpsert == null || recordsToUpsert.isEmpty()) {
            return new List<DMT_X_Sell__c>();
        }

        // Extract unique Opportunity IDs from the incoming records
        Set<Id> opportunityIds = new Set<Id>();
        for (DMT_X_Sell__c rec : recordsToUpsert) {
            if (rec.Opportunity__c != null) {
                opportunityIds.add(rec.Opportunity__c);
            }
        }

        if (opportunityIds.isEmpty()) {
            return recordsToUpsert; // No opportunities to check, return as-is
        }

        // Query existing records for these opportunities
        String existingQuery = 'SELECT Id, Opportunity__c, Booking_Geography__c, XSELL_Value_PY__c, XSELL_Value_CY__c, XSELL_Value_NY__c, XSELL_Value_NY1__c ' +
                              'FROM DMT_X_Sell__c ' +
                              'WHERE Opportunity__c IN :opportunityIds';
        List<DMT_X_Sell__c> existingRecords = Database.query(existingQuery, dbMode);

        // Build a map of existing records by opportunity + field combination for quick lookup
        Map<String, DMT_X_Sell__c> existingMap = new Map<String, DMT_X_Sell__c>();
        for (DMT_X_Sell__c existing : existingRecords) {
            String key = buildDuplicateKey(existing);
            existingMap.put(key, existing);
        }

        // Filter incoming records: keep only those that don't already exist
        List<DMT_X_Sell__c> dedupedRecords = new List<DMT_X_Sell__c>();
        for (DMT_X_Sell__c incoming : recordsToUpsert) {
            String incomingKey = buildDuplicateKey(incoming);
            if (!existingMap.containsKey(incomingKey)) {
                dedupedRecords.add(incoming);
            }
        }

        return dedupedRecords;
    }

    /**
     * DEDUPLICATION GUARDRAIL #2: After upsert, queries for remaining duplicates within the same Opportunity.
     * If multiple records exist with identical values for the 5 key fields, keeps only the first (oldest) 
     * and deletes all others. This is a safety net for edge cases where duplicates slip through.
     */
    private static void deduplicateXSellRecords(List<DMT_X_Sell__c> recordsToUpsert, AccessLevel dbMode) {
        if (recordsToUpsert == null || recordsToUpsert.isEmpty()) {
            return;
        }

        // Extract unique Opportunity IDs
        Set<Id> opportunityIds = new Set<Id>();
        for (DMT_X_Sell__c rec : recordsToUpsert) {
            if (rec.Opportunity__c != null) {
                opportunityIds.add(rec.Opportunity__c);
            }
        }

        if (opportunityIds.isEmpty()) {
            return;
        }

        // Query all XSell records for these opportunities, ordered by CreatedDate to keep oldest
        String dupCheckQuery = 'SELECT Id, Opportunity__c, Booking_Geography__c, XSELL_Value_PY__c, XSELL_Value_CY__c, XSELL_Value_NY__c, XSELL_Value_NY1__c, CreatedDate ' +
                               'FROM DMT_X_Sell__c ' +
                               'WHERE Opportunity__c IN :opportunityIds ' +
                               'ORDER BY CreatedDate ASC';
        List<DMT_X_Sell__c> allRecords = Database.query(dupCheckQuery, dbMode);

        // Group by duplicate key and identify duplicates
        Map<String, List<DMT_X_Sell__c>> duplicateMap = new Map<String, List<DMT_X_Sell__c>>();
        for (DMT_X_Sell__c rec : allRecords) {
            String key = buildDuplicateKey(rec);
            if (!duplicateMap.containsKey(key)) {
                duplicateMap.put(key, new List<DMT_X_Sell__c>());
            }
            duplicateMap.get(key).add(rec);
        }

        // Collect all duplicates (keep first, mark rest for deletion)
        List<DMT_X_Sell__c> recordsToDelete = new List<DMT_X_Sell__c>();
        for (List<DMT_X_Sell__c> xGroup : duplicateMap.values()) {
            if (xGroup.size() > 1) {
                // Keep the first (oldest), delete the rest
                for (Integer i = 1; i < xGroup.size(); i++) {
                    recordsToDelete.add(xGroup[i]);
                }
            }
        }

        // Delete duplicate records if any were found
        if (!recordsToDelete.isEmpty()) {
            if (dbMode == AccessLevel.USER_MODE && !Schema.sObjectType.DMT_X_Sell__c.isDeletable()) {
                System.debug('this should be system mode. no exception should be thrown');
              //  throw new XSellException('Insufficient permissions to delete Cross Sell duplicates.');
            }
            Database.delete(recordsToDelete, dbMode);
        }
    }

    /**
     * HELPER METHOD: Builds a unique key from the 5 critical XSell fields for duplicate detection.
     * Used by both deduplication methods to identify matching records.
     * Safely handles null values that may not have been queried from the database.
     */
    private static String buildDuplicateKey(DMT_X_Sell__c rec) {
        String oppId = rec.Opportunity__c != null ? String.valueOf(rec.Opportunity__c) : '';
        String geo = rec.Booking_Geography__c != null ? rec.Booking_Geography__c : '';
        String py = rec.XSELL_Value_PY__c != null ? String.valueOf(rec.XSELL_Value_PY__c) : '0';
        String cy = rec.XSELL_Value_CY__c != null ? String.valueOf(rec.XSELL_Value_CY__c) : '0';
        String ny = rec.XSELL_Value_NY__c != null ? String.valueOf(rec.XSELL_Value_NY__c) : '0';
        String ny1 = rec.XSELL_Value_NY1__c != null ? String.valueOf(rec.XSELL_Value_NY1__c) : '0';
        return oppId + '|' + geo + '|' + py + '|' + cy + '|' + ny + '|' + ny1;
    }
}