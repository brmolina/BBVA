// CIBGLOBALD-4851 - without sharing: the import is a system load run by the Bulk Import users (DMT_Line_God); clients
// (Account, Private sharing) and existing lines must be found whether or not the running user can see them.
public without sharing class DMT_BulkImportBatch implements Database.Batchable<Object>, Database.Stateful { // CIBGLOBALD-4851

    public static final String IMPORT_TYPE_LINES    = 'LINES';
    public static final String IMPORT_TYPE_PRODUCTS = 'PRODUCTS';

    private static final Integer MAX_ERROR_ENTRIES = 500;

    // CIBGLOBALD-4851 - DMT_Line__c fields a Lines file column can write, typed from the field describe. A column that is
    // in the file is written (a blank cell clears the field); a column that is not in the file leaves the field as it is.
    // Not listed on purpose: Status__c (new lines are created in Draft, existing lines keep theirs), DMT_Origin__c (always
    // BulkImport: the Update Line Status logic in DMT_BatchSanctionAMIWEB only takes BulkImport lines), RecordTypeId
    // (from the record type picked in the LWC), Client__c (resolved from Client_Code__c), OwnerId (from DMT_ID_User__c).
    private static final List<String> LINE_FILE_FIELDS = new List<String>{
        'Name', 'Booking_Geography__c', 'DMT_Client_Entific__c', 'CurrencyIsoCode', 'Start_Date__c', 'End_Date__c',
        'Client_Code__c', 'Golden_Code__c', 'FD_Amount__c', 'DvP_Amount__c', 'Breakclause_Frequency__c',
        'First_Breakclause__c', 'Waiver__c', 'DMT_Mitigant_Agreement_comments__c', 'DMT_Comments__c',
        'DMT_Additional_Restrictions__c', 'DMT_Client_Use__c', 'DMT_LastLevelId__c', 'g_line_status_type__c'
    };
    // CIBGLOBALD-4851 - columns whose blank cell keeps the value in Salesforce (business request: later loads of the
    // same lines may come without the break clause values).
    private static final Set<String> KEEP_WHEN_BLANK_FIELDS = new Set<String>{ 'First_Breakclause__c', 'Breakclause_Frequency__c' };
    // CIBGLOBALD-4851 - owner column: TL files use DMT_ID_User__c, the earlier Other Products files 'owner User id_user__c'.
    private static final List<String> OWNER_COLUMNS = new List<String>{ 'DMT_ID_User__c', 'owner User id_user__c' };
    private static final String CLIENT_CODE_COLUMN = 'Client_Code__c';

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
            String uid = ownerExtId(row); // CIBGLOBALD-4851
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

        Map<String, Id> accountIdByClientCode = resolveClientCodes(chunk); // CIBGLOBALD-4851

        // CIBGLOBALD-4851 - a row that cannot be built (client not found, invalid value) is reported and not saved;
        // the rows sent to the upsert keep their position in rowsToUpsert for collectResults.
        List<DMT_Line__c> toUpsert = new List<DMT_Line__c>();
        List<Map<String, Object>> rowsToUpsert = new List<Map<String, Object>>();
        for (Integer i = 0; i < chunk.size(); i++) {
            Map<String, Object> row = chunk[i];
            DMT_Line__c line = new DMT_Line__c();
            String error = buildLine(line, row, userIdMap, lineRecordTypeId, existingStatusMap, accountIdByClientCode);
            if (error != null) {
                addRowError(processedCount + i + 1, row, 'Line_Id__c', 'Name', error);
            } else {
                toUpsert.add(line);
                rowsToUpsert.add(row);
            }
        }

        Database.UpsertResult[] results = Database.upsert(toUpsert, DMT_Line__c.Line_Id__c, false);
        collectResults(results, rowsToUpsert, 'Line_Id__c', 'Name'); // CIBGLOBALD-4851
    }

    /**
     * @description CIBGLOBALD-4851 - Fills the Line from the row and returns the reason the row is rejected, or null.
     * Only the columns present in the row are written (LINE_FILE_FIELDS); a blank cell clears the field, except in
     * KEEP_WHEN_BLANK_FIELDS (the break clause fields keep their value). The client
     * comes from Client_Code__c (customer or group code, resolveClientCodes); a new line needs it, and a code that is
     * not found rejects the row. New lines are created in Draft; existing lines keep their Status__c.
     */
    private String buildLine(DMT_Line__c line, Map<String, Object> row, Map<String, Id> userIdMap, Id recordTypeId,
                             Map<String, String> existingStatusMap, Map<String, Id> accountIdByClientCode) {
        line.RecordTypeId = recordTypeId;
        line.Line_Id__c   = str(row, 'Line_Id__c');
        if (line.Line_Id__c == null) {
            return 'Line_Id__c is required.';
        }
        Boolean isNewLine = !existingStatusMap.containsKey(line.Line_Id__c);

        Map<String, Schema.SObjectField> lineFields = Schema.SObjectType.DMT_Line__c.fields.getMap();
        for (String fieldName : LINE_FILE_FIELDS) {
            if (!row.containsKey(fieldName)) {
                continue;
            }
            if (KEEP_WHEN_BLANK_FIELDS.contains(fieldName) && String.isBlank(str(row, fieldName))) { // CIBGLOBALD-4851
                continue;
            }
            String error = putValue(line, lineFields.get(fieldName), str(row, fieldName));
            if (error != null) {
                return fieldName + ': ' + error;
            }
        }

        // Status__c from the file is ignored: new lines start in Draft, existing ones keep their status.
        line.Status__c     = isNewLine ? 'Draft' : existingStatusMap.get(line.Line_Id__c);
        line.DMT_Origin__c = 'BulkImport';

        // Amount from embedded term column in the lines file → line total amount
        String amtStr = str(row, 'DMT_Risk_Line_Term__c DMT_Amount__c');
        if (String.isNotBlank(amtStr)) {
            line.Amount__c = parseDecimal(amtStr);
        }

        // CIBGLOBALD-4851 - client: customer or group code, found before the upsert (resolveClientCodes).
        String clientCode = str(row, CLIENT_CODE_COLUMN);
        if (row.containsKey(CLIENT_CODE_COLUMN) || isNewLine) {
            if (clientCode == null) {
                return 'Client_Code__c is required: the line must be related to its client.';
            }
            Id accountId = accountIdByClientCode.get(clientCode.toUpperCase());
            if (accountId == null) {
                return 'Client_Code__c ' + clientCode + ' was not found as a customer code or a group code.';
            }
            line.Client__c = accountId;
        }

        // Owner resolved via pre-fetched user map
        String userExtId = ownerExtId(row); // CIBGLOBALD-4851
        if (String.isNotBlank(userExtId) && userIdMap.containsKey(userExtId)) {
            line.OwnerId       = userIdMap.get(userExtId);
            line.DMT_ID_User__c = userExtId;
        }

        return null;
    }

    /**
     * @description CIBGLOBALD-4851 - Accounts of the chunk's Client_Code__c values, by code in upper case. A code is a
     * customer code (Account.g_customer_id__c, subsidiaries) or a group code (Account.DES_Group_Code__c, groups); no value
     * is both in the org, so the customer match wins only as a safeguard. One query per chunk.
     */
    private static Map<String, Id> resolveClientCodes(List<Map<String, Object>> chunk) {
        Set<String> codes = new Set<String>();
        for (Map<String, Object> row : chunk) {
            String code = str(row, CLIENT_CODE_COLUMN);
            if (code != null) {
                codes.add(code.toUpperCase());
            }
        }
        Map<String, Id> accountIdByCode = new Map<String, Id>();
        if (codes.isEmpty()) {
            return accountIdByCode;
        }
        for (Account account : [SELECT Id, g_customer_id__c, DES_Group_Code__c FROM Account
                                WHERE g_customer_id__c IN :codes OR DES_Group_Code__c IN :codes]) {
            if (account.DES_Group_Code__c != null && codes.contains(account.DES_Group_Code__c.toUpperCase())
                && !accountIdByCode.containsKey(account.DES_Group_Code__c.toUpperCase())) {
                accountIdByCode.put(account.DES_Group_Code__c.toUpperCase(), account.Id);
            }
            if (account.g_customer_id__c != null && codes.contains(account.g_customer_id__c.toUpperCase())) {
                accountIdByCode.put(account.g_customer_id__c.toUpperCase(), account.Id);
            }
        }
        return accountIdByCode;
    }

    /**
     * @description CIBGLOBALD-4851 - Writes a file value to a field, typed from its describe. Blank clears the field
     * (false for a checkbox). Returns the reason the value is invalid, or null.
     */
    private static String putValue(SObject record, Schema.SObjectField field, String value) {
        Schema.DisplayType fieldType = field.getDescribe().getType();
        if (value == null) {
            record.put(field, fieldType == Schema.DisplayType.BOOLEAN ? (Object) false : null);
            return null;
        }
        if (fieldType == Schema.DisplayType.DATE) {
            Date dateValue = parseDateValue(value);
            if (dateValue == null) {
                return 'invalid date ' + value + ' (expected yyyy-mm-dd or dd/mm/yyyy).';
            }
            record.put(field, dateValue);
        } else if (fieldType == Schema.DisplayType.CURRENCY || fieldType == Schema.DisplayType.DOUBLE
                   || fieldType == Schema.DisplayType.PERCENT || fieldType == Schema.DisplayType.INTEGER) {
            Decimal numberValue = parseDecimal(value);
            if (numberValue == null) {
                return 'invalid number ' + value + '.';
            }
            record.put(field, fieldType == Schema.DisplayType.INTEGER ? (Object) numberValue.intValue() : numberValue);
        } else if (fieldType == Schema.DisplayType.BOOLEAN) {
            String flag = value.toLowerCase();
            if (flag == 'true' || flag == '1' || flag == 'yes') {
                record.put(field, true);
            } else if (flag == 'false' || flag == '0' || flag == 'no') {
                record.put(field, false);
            } else {
                return 'invalid checkbox value ' + value + ' (expected TRUE or FALSE).';
            }
        } else {
            record.put(field, value);
        }
        return null;
    }

    // CIBGLOBALD-4851 - the owner's user id from whichever owner column the file uses.
    private static String ownerExtId(Map<String, Object> row) {
        for (String column : OWNER_COLUMNS) {
            String value = str(row, column);
            if (value != null) {
                return value;
            }
        }
        return null;
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
                addRowError(processedCount + i + 1, chunk[i], idField, labelField, results[i].getErrors()[0].getMessage()); // CIBGLOBALD-4851
            }
        }
    }

    // CIBGLOBALD-4851 - one failed row in the progress event's error list (shared by DML failures and rows rejected before the DML).
    private void addRowError(Integer rowNumber, Map<String, Object> row, String idField, String labelField, String message) {
        errorCount++;
        if (collectedErrors.size() < MAX_ERROR_ENTRIES) {
            collectedErrors.add(new Map<String, Object>{
                'row'     => rowNumber,
                'id'      => str(row, idField),
                'label'   => str(row, labelField),
                'message' => message
            });
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

    // CIBGLOBALD-4851 - a file date: yyyy-mm-dd (CSV and XLSX cells as read by the LWC) or dd/mm/yyyy; null when invalid.
    private static Date parseDateValue(String s) {
        try {
            if (s.contains('/')) {
                List<String> parts = s.split('/');
                return parts.size() == 3 ? Date.newInstance(Integer.valueOf(parts[2]), Integer.valueOf(parts[1]), Integer.valueOf(parts[0])) : null;
            }
            return Date.valueOf(s.left(10));
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