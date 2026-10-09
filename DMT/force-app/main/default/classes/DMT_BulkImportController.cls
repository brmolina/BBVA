public with sharing class DMT_BulkImportController {

    @AuraEnabled
    public static String submitLines(String rowsJson, String jobId, String recordTypeName) {
        List<Map<String, Object>> rows = deserializeRows(rowsJson);
        DMT_BulkImportBatch batch = new DMT_BulkImportBatch(rows, jobId, DMT_BulkImportBatch.IMPORT_TYPE_LINES, recordTypeName);
        Database.executeBatch(batch, 50);
        return jobId;
    }

    @AuraEnabled
    public static String submitProducts(String rowsJson, String jobId) {
        List<Map<String, Object>> rows = deserializeRows(rowsJson);
        DMT_BulkImportBatch batch = new DMT_BulkImportBatch(rows, jobId, DMT_BulkImportBatch.IMPORT_TYPE_PRODUCTS, null);
        Database.executeBatch(batch, 50);
        return jobId;
    }

    /**
     * Update Line Status action: moves the Draft lines of the current import to the status
     * informed in the file (g_line_status_type__c), reusing DMT_BatchSanctionAMIWEB in Bulk Import mode.
     * Returns the AsyncApexJob Id.
     */
    @AuraEnabled
    public static String updateLineStatus(List<String> lineIds) {
        if (lineIds == null || lineIds.isEmpty()) {
            throw new AuraHandledException('There are no imported lines to update.');
        }
        Id asyncJobId = Database.executeBatch(new DMT_BatchSanctionAMIWEB(new Set<String>(lineIds)), 50);
        return String.valueOf(asyncJobId);
    }

    @AuraEnabled
    public static List<DMT_Line__c> getExistingLines(List<String> lineIds) {
        return [
            SELECT Id, Name, Line_Id__c, Status__c, CurrencyIsoCode, Booking_Geography__c,
                   Client__r.Name, Client_Code__c,
                   Start_Date__c, End_Date__c, DMT_LastLevelId__c,
                   DMT_Comments__c, DMT_ID_User__c, Breakclause_Frequency__c,
                   g_line_status_type__c, Amount__c
            FROM DMT_Line__c
            WHERE Line_Id__c IN :lineIds
            LIMIT :lineIds.size()
        ];
    }

    @AuraEnabled
    public static List<DMT_Risk_Line_Term__c> getExistingTermsForLines(List<String> lineIds) {
        return [
            SELECT DMT_RiskLineTermId__c, DMT_Line__r.Line_Id__c,
                   DMT_Init_Term__c, DMT_End_Term__c, DMT_Amount__c, CurrencyIsoCode,
                   DMT_LastLevelId__c, DMT_ID_User__c,
                   g_global_product_family_id__c, g_global_product_subfamily_id__c,
                   g_global_product_category_id__c, g_gbl_product_subcategory_id__c,
                   g_global_product_id__c, g_multioperation_ind_type__c,
                   g_expert_criteria_risk_type__c, g_amortization_type__c,
                   gf_payment_frequency__c, gf_group_priority_line_id__c,
                   gf_inscol_months_grace_number__c
            FROM DMT_Risk_Line_Term__c
            WHERE DMT_Line__r.Line_Id__c IN :lineIds
        ];
    }

    @AuraEnabled
    public static List<DMT_Line__c> queryCreatedLines(List<String> lineIds) {
        return [
            SELECT Id, Name, Line_Id__c, Status__c, CurrencyIsoCode, Booking_Geography__c
            FROM DMT_Line__c
            WHERE Line_Id__c IN :lineIds
            LIMIT :lineIds.size()
        ];
    }

    @AuraEnabled
    public static List<DMT_Risk_Line_Term__c> queryCreatedTerms(List<String> termIds) {
        return [
            SELECT Id, Name, DMT_RiskLineTermId__c, DMT_Line__r.Name, DMT_Line__r.Line_Id__c
            FROM DMT_Risk_Line_Term__c
            WHERE DMT_RiskLineTermId__c IN :termIds
            LIMIT 200
        ];
    }

    private static List<Map<String, Object>> deserializeRows(String rowsJson) {
        List<Object> raw = (List<Object>) JSON.deserializeUntyped(rowsJson);
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        for (Object o : raw) {
            rows.add((Map<String, Object>) o);
        }
        return rows;
    }
}