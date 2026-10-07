public with sharing class DMT_BulkImportBatch implements Database.Batchable<Object>, Database.Stateful {

    public static final String IMPORT_TYPE_LINES    = 'LINES';
    public static final String IMPORT_TYPE_PRODUCTS = 'PRODUCTS';

    private static final Integer MAX_ERROR_ENTRIES = 500;

    private List<Object> rows;
    private String jobId;
    private String importType;
    private String recordTypeName;
    private Integer totalRows;
    private Integer processedCount  = 0;
    private Integer successCount    = 0;
    private Integer errorCount      = 0;
    private List<Map<String, Object>> collectedErrors = new List<Map<String, Object>>();

    public DMT_BulkImportBatch(List<Map<String, Object>> rows, String jobId, String importType, String recordTypeName) {
        this.rows = new List<Object>();
        for (Map<String, Object> row : rows) {
            this.rows.add(row);
        }
        this.jobId           = jobId;
        this.importType      = importType;
        this.recordTypeName  = recordTypeName;
        this.totalRows       = rows.size();
    }

    public Iterable<Object> start(Database.BatchableContext bc) {
        publishProgress('IN_PROGRESS');
        return rows;
    }

    public void execute(Database.BatchableContext bc, List<Object> scope) {
        List<Map<String, Object>> chunk = new List<Map<String, Object>>();
        for (Object o : scope) {
            chunk.add((Map<String, Object>) o);
        }
        if (importType == IMPORT_TYPE_LINES) {
            processLines(chunk);
        } else {
            processProducts(chunk);
        }
        processedCount += chunk.size();
        publishProgress('IN_PROGRESS');
    }

    public void finish(Database.BatchableContext bc) {
        publishProgress('COMPLETED');
    }

    // ─── Lines import → DMT_Line__c ──────────────────────────────────────────

    private void processLines(List<Map<String, Object>> chunk) {
        Set<String> userExtIds = new Set<String>();
        for (Map<String, Object> row : chunk) {
            String uid = str(row, 'owner User id_user__c');
            if (String.isNotBlank(uid)) userExtIds.add(uid);
        }

        Map<String, Id> userIdMap = new Map<String, Id>();
        for (User u : [SELECT Id, ID_User__c FROM User WHERE ID_User__c IN :userExtIds AND IsActive = true]) {
            userIdMap.put(u.ID_User__c, u.Id);
        }

        Id lineRecordTypeId = Schema.SObjectType.DMT_Line__c
            .getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();

        // Pre-query Status__c for existing records so upsert preserves it on update
        Set<String> chunkLineIds = new Set<String>();
        for (Map<String, Object> row : chunk) {
            String lid = str(row, 'Line_Id__c');
            if (String.isNotBlank(lid)) chunkLineIds.add(lid);
        }
        Map<String, String> existingStatusMap = new Map<String, String>();
        for (DMT_Line__c existing : [SELECT Line_Id__c, Status__c FROM DMT_Line__c WHERE Line_Id__c IN :chunkLineIds]) {
            existingStatusMap.put(existing.Line_Id__c, existing.Status__c);
        }

        List<DMT_Line__c> toUpsert = new List<DMT_Line__c>();
        for (Map<String, Object> row : chunk) {
            toUpsert.add(buildLine(row, userIdMap, lineRecordTypeId, existingStatusMap));
        }

        Database.UpsertResult[] results = Database.upsert(toUpsert, DMT_Line__c.Line_Id__c, false);
        collectResults(results, chunk, 'Line_Id__c', 'Name');
    }

    private DMT_Line__c buildLine(Map<String, Object> row, Map<String, Id> userIdMap, Id recordTypeId, Map<String, String> existingStatusMap) {
        DMT_Line__c line = new DMT_Line__c();
        line.RecordTypeId                     = recordTypeId;
        line.Line_Id__c                       = str(row, 'Line_Id__c');
        line.Name                             = str(row, 'Name');
        line.Booking_Geography__c             = str(row, 'Booking_Geography__c');
        line.Client_Code__c                   = str(row, 'Client_Code__c');
        line.End_Date__c                      = parseDate(row, 'End_Date__c');
        line.Start_Date__c                    = parseDate(row, 'Start_Date__c');
        line.DMT_LastLevelId__c       = str(row, 'DMT_LastLevelId__c');
        line.CurrencyIsoCode          = str(row, 'CurrencyIsoCode');
        line.DMT_Comments__c          = str(row, 'DMT_Comments__c');
        line.Breakclause_Frequency__c = str(row, 'Breakclause_Frequency__c');
        line.g_line_status_type__c    = str(row, 'g_line_status_type__c');
        // Existing records → preserve current Status__c (upsert would null it otherwise)
        // New records → use CSV value if provided, default to 'Draft'
        String csvStatus = str(row, 'Status__c');
        line.Status__c = existingStatusMap.containsKey(line.Line_Id__c)
            ? existingStatusMap.get(line.Line_Id__c)
            : (String.isNotBlank(csvStatus) ? csvStatus : 'Draft');
        line.DMT_Origin__c                    = 'BulkImport';

        // Amount from embedded term column in the lines file → line total amount
        String amtStr = str(row, 'DMT_Risk_Line_Term__c DMT_Amount__c');
        if (String.isNotBlank(amtStr)) {
            line.Amount__c = parseDecimal(amtStr);
        }

        // Account Lookup resolved via external ID cross-reference at DML time
        String clientCode = str(row, 'Client_Code__c');
        if (String.isNotBlank(clientCode)) {
            line.Client__r = new Account(g_customer_id__c = clientCode.toUpperCase());
        }

        // Owner resolved via pre-fetched user map
        String userExtId = str(row, 'owner User id_user__c');
        if (String.isNotBlank(userExtId) && userIdMap.containsKey(userExtId)) {
            line.OwnerId       = userIdMap.get(userExtId);
            line.DMT_ID_User__c = userExtId;
        }

        return line;
    }

    // ─── Products import → DMT_Risk_Line_Term__c ─────────────────────────────

    private void processProducts(List<Map<String, Object>> chunk) {
        Set<String> userExtIds = new Set<String>();
        for (Map<String, Object> row : chunk) {
            String uid = str(row, 'owner User id_user__c');
            if (String.isNotBlank(uid)) userExtIds.add(uid);
        }

        Map<String, String> userExtIdMap = new Map<String, String>();
        for (User u : [SELECT Id, ID_User__c FROM User WHERE ID_User__c IN :userExtIds AND IsActive = true]) {
            userExtIdMap.put(u.ID_User__c, u.ID_User__c);
        }

        List<DMT_Risk_Line_Term__c> toUpsert = new List<DMT_Risk_Line_Term__c>();
        for (Map<String, Object> row : chunk) {
            toUpsert.add(buildTerm(row, userExtIdMap));
        }

        Database.UpsertResult[] results = Database.upsert(toUpsert, DMT_Risk_Line_Term__c.DMT_RiskLineTermId__c, false);
        collectResults(results, chunk, 'DMT_RiskLineTermId__c', 'Line_Id__c');
    }

    private DMT_Risk_Line_Term__c buildTerm(Map<String, Object> row, Map<String, String> userExtIdMap) {
        DMT_Risk_Line_Term__c term = new DMT_Risk_Line_Term__c();
        term.DMT_RiskLineTermId__c            = str(row, 'DMT_RiskLineTermId__c');
        term.DMT_Line__r                      = new DMT_Line__c(Line_Id__c = str(row, 'Line_Id__c'));
        term.DMT_Init_Term__c                 = str(row, 'DMT_Risk_Line_Term__c DMT_Init_Term__c');
        term.DMT_End_Term__c                  = str(row, 'DMT_Risk_Line_Term__c DMT_End_Term__c');
        term.DMT_LastLevelId__c               = str(row, 'DMT_LastLevelId__c');
        term.g_global_product_family_id__c    = str(row, 'g_global_product_family_id__c');
        term.g_global_product_subfamily_id__c = str(row, 'g_global_product_subfamily_id__c');
        term.g_global_product_category_id__c  = str(row, 'g_global_product_category_id__c');
        term.g_gbl_product_subcategory_id__c  = str(row, 'g_gbl_product_subcategory_id__c');
        term.g_global_product_id__c           = str(row, 'g_global_product_id__c');
        term.g_multioperation_ind_type__c     = '1'.equals(str(row, 'g_multioperation_ind_type__c'));
        term.g_expert_criteria_risk_type__c   = str(row, 'g_expert_criteria_risk_type__c');
        term.g_amortization_type__c           = str(row, 'g_amortization_type__c');
        term.gf_payment_frequency__c          = str(row, 'gf_payment_frequency__c');
        term.gf_group_priority_line_id__c     = str(row, 'gf_group_priority_line_id__c');

        String amtStr = str(row, 'DMT_Risk_Line_Term__c DMT_Amount__c');
        if (String.isNotBlank(amtStr)) {
            term.DMT_Amount__c = parseDecimal(amtStr);
        }

        String graceStr = str(row, 'gf_inscol_months_grace_number__c');
        if (String.isNotBlank(graceStr)) {
            try { term.gf_inscol_months_grace_number__c = Integer.valueOf(graceStr); } catch (Exception e) {}
        }

        String userExtId = str(row, 'owner User id_user__c');
        if (String.isNotBlank(userExtId) && userExtIdMap.containsKey(userExtId)) {
            term.DMT_ID_User__c = userExtId;
        }

        return term;
    }

    // ─── Shared helpers ───────────────────────────────────────────────────────

    private void collectResults(Database.UpsertResult[] results, List<Map<String, Object>> chunk,
                                String idField, String labelField) {
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                successCount++;
            } else {
                errorCount++;
                if (collectedErrors.size() < MAX_ERROR_ENTRIES) {
                    Map<String, Object> row = chunk[i];
                    collectedErrors.add(new Map<String, Object>{
                        'row'     => processedCount + i + 1,
                        'id'      => str(row, idField),
                        'label'   => str(row, labelField),
                        'message' => results[i].getErrors()[0].getMessage()
                    });
                }
            }
        }
    }

    private void publishProgress(String status) {
        DMT_BulkImportProgress__e evt = new DMT_BulkImportProgress__e();
        evt.Job_Id__c       = jobId;
        evt.Phase__c        = importType;
        evt.Status__c       = status;
        evt.Total__c        = totalRows;
        evt.Processed__c    = processedCount;
        evt.Success_Count__c = successCount;
        evt.Error_Count__c  = errorCount;

        String errJson = JSON.serialize(collectedErrors);
        evt.Errors_JSON__c = errJson.length() > 131000
            ? errJson.substring(0, 131000) + '...truncated]'
            : errJson;

        EventBus.publish(evt);
    }

    private static String str(Map<String, Object> row, String key) {
        Object val = row.get(key);
        if (val == null) return null;
        String s = String.valueOf(val).trim();
        return String.isEmpty(s) ? null : s;
    }

    private static Date parseDate(Map<String, Object> row, String key) {
        String s = str(row, key);
        if (String.isBlank(s)) return null;
        try {
            return Date.valueOf(s);
        } catch (Exception e) {
            return null;
        }
    }

    private static Decimal parseDecimal(String s) {
        if (String.isBlank(s)) return null;
        try {
            return Decimal.valueOf(s.replace(',', '.'));
        } catch (Exception e) {
            return null;
        }
    }
}