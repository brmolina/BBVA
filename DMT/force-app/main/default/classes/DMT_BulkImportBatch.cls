/**
 * @description Bulk Import load (LWC dmt_bulk_import, Process). Reworked in CIBGLOBALD-4851: one unit per line with its
 * products; the Lines file creates / updates the line, a loaded products table replaces all Risk Line Terms / Line Product
 * Items of that line; client from Client_Code__c (customer or group code); a line outside Draft whose blocked fields change
 * is saved through Draft and moved back to its status (or to the status of its g_line_status_type__c code) by
 * DMT_BatchSanctionAMIWEB; row errors and progress go to the screen through DMT_BulkImportProgress__e.
 */
// without sharing: the import is a system load run by the Bulk Import users (DMT_Line_God); clients
// (Account, Private sharing) and existing lines must be found whether or not the running user can see them.
public without sharing class DMT_BulkImportBatch implements Database.Batchable<Object>, Database.Stateful {

    // Process: one unit per line, built by the LWC (dmt_bulk_import.processImport). Keys:
    //   line       = the Lines file row (Map, Line_Id__c required)
    //   rowNumber  = the row of the line in the Lines file (error list)
    //   updateLine = false when the line has no change (only its products are replaced)
    //   rlt / lpi  = Risk Line Terms / Line Product Items file rows of the line (List of Map); present = every record of
    //                that object on the line is deleted and these rows are inserted; absent = that object is not touched
    public static final String IMPORT_TYPE_PROCESS = 'PROCESS';
    public static final String UNIT_LINE        = 'line';
    public static final String UNIT_ROW_NUMBER  = 'rowNumber';
    public static final String UNIT_UPDATE_LINE = 'updateLine';
    public static final String UNIT_RLT         = 'rlt';
    public static final String UNIT_LPI         = 'lpi';
    // stayDraft = true when the LWC found that the move after the load would be rejected by the org
    // rules (dmt_bulk_import._stayDraftReasons): the line is saved as planned but not moved; Update Line Status retries it
    public static final String UNIT_STAY_DRAFT  = 'stayDraft';
    // rltDelete / lpiDelete = Ids of single Salesforce records of the line the user removed on the screen
    // (that table not loaded): only those are deleted, and only when they belong to the line
    public static final String UNIT_RLT_DELETE  = 'rltDelete';
    public static final String UNIT_LPI_DELETE  = 'lpiDelete';
    // lines per batch chunk (each with its products): the chunk runs delete + insert + update once
    public static final Integer UNITS_PER_CHUNK = 10;

    private static final Integer MAX_ERROR_ENTRIES = 500;
    // line statuses by g_line_status_type__c code (same map as DMT_BatchSanctionAMIWEB)
    public static final Map<String, String> STATUS_BY_CODE = new Map<String, String>{
        'DR' => 'Draft', 'PR' => 'Proposal', 'AP' => 'Approval', 'RC' => 'Ready to close', 'CL' => 'Closed', 'CW' => 'Closed'
    };
    private static final String STATUS_DRAFT          = 'Draft';
    private static final String STATUS_READY_TO_CLOSE = 'Ready to close';
    private static final String STATUS_CLOSED         = 'Closed';
    // fields the validation rule DMT_Line__c.AvoidEditNotDraft blocks outside Draft: a change to one of
    // them sends a non-Draft line to Draft (status rules approved by Diego, 2026-11-16).
    private static final List<String> BLOCKED_OUTSIDE_DRAFT = new List<String>{
        'Name', 'Booking_Geography__c', 'CurrencyIsoCode', 'Start_Date__c', 'DvP_Amount__c', 'FD_Amount__c', 'Repos_Limit__c',
        'Repos_Limit_6M__c', 'First_Breakclause__c', 'Breakclause_Frequency__c', 'Waiver__c', 'Client__c', 'Amount__c',
        'DMT_LastLevelId__c'
    };
    // fields the validation rule DMT_Line__c.ApprovalProcessDataEdit blocks in Approval, Ready to close and
    // Closed; the rule reads the new status, so a change to one of them also sends the line to Draft (approvalDataLocked)
    private static final List<String> APPROVAL_DATA_FIELDS = new List<String>{
        'DMT_Operation__c', 'DMT_Nominal__c', 'DMT_RAROEC_RORC_Proposal__c', 'DMT_Franchise_L12M__c', 'DMT_Comments__c',
        'DMT_Additional_Restrictions__c', 'DMT_Client_Use__c', 'DMT_ApproverGlobalBanker__c', 'DMT_Booking_Unit_Risk_Analyst__c',
        'DMT_Approver__c'
    };
    private static final Set<String> APPROVAL_DATA_STATUSES = new Set<String>{ 'Approval', 'Ready to close', 'Closed' };
    // child fields a file column can write (columns with other names are ignored, e.g. the line
    // columns of an old Other Products file); the LWC sends 'DMT_Risk_Line_Term__c <field>' columns as <field>.
    private static final List<String> RLT_FILE_FIELDS = new List<String>{
        'DMT_Risk_Type__c', 'DMT_Amount__c', 'DMT_Init_Term__c', 'DMT_End_Term__c', 'DMT_RiskLineTermId__c', 'DMT_LastLevelId__c',
        'g_global_product_family_id__c', 'g_global_product_subfamily_id__c', 'g_global_product_category_id__c',
        'g_gbl_product_subcategory_id__c', 'g_global_product_id__c', 'g_multioperation_ind_type__c',
        'g_expert_criteria_risk_type__c', 'g_amortization_type__c', 'gf_payment_frequency__c', 'gf_group_priority_line_id__c',
        'gf_inscol_months_grace_number__c'
    };
    // term fields that must hold a value of their picklist of days (checkTermDays)
    private static final List<Schema.SObjectField> TERM_DAY_FIELDS = new List<Schema.SObjectField>{
        DMT_Risk_Line_Term__c.DMT_Init_Term__c, DMT_Risk_Line_Term__c.DMT_End_Term__c
    };
    private static final Map<String, Set<String>> TERM_DAY_VALUES = new Map<String, Set<String>>();
    private static final List<String> LPI_FILE_FIELDS = new List<String>{
        'Product_Code_Value__c', 'Max_Tenor_WC__c', 'Max_Tenor_WOC__c', 'DMT_DerivativeRestriction__c', 'DMT_FDRestriction__c',
        'DMT_DVPRestriction__c', 'g_global_product_family_id__c', 'g_global_product_subfamily_id__c',
        'g_global_product_category_id__c', 'g_gbl_product_subcategory_id__c', 'g_global_product_id__c'
    };

    // DMT_Line__c fields a Lines file column can write, typed from the field describe. A column that is
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
    // columns whose blank cell keeps the value in Salesforce (business request: later loads of the
    // same lines may come without the break clause values).
    private static final Set<String> KEEP_WHEN_BLANK_FIELDS = new Set<String>{ 'First_Breakclause__c', 'Breakclause_Frequency__c' };
    // owner column: TL files use DMT_ID_User__c, the earlier Other Products files 'owner User id_user__c'.
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
    // Line_Id__c -> status the line moves to after the load (planStatus), sent in finish to
    // DMT_BatchSanctionAMIWEB (Bulk Import load mode)
    private Map<String, String> statusTargets = new Map<String, String>();
    // the targets of the last finished load, read by the tests
    @TestVisible private static Map<String, String> lastStatusTargets;
    // Phase__c of the background jobs that report to the screen (publishEvent)
    public static final String PHASE_STATUS = 'STATUS';
    public static final String EVENT_IN_PROGRESS = 'IN_PROGRESS';
    public static final String EVENT_COMPLETED   = 'COMPLETED';
    public static final String EVENT_FAILED      = 'FAILED';
    // the events published in this transaction, read by the tests
    @TestVisible private static List<DMT_BulkImportProgress__e> publishedEvents = new List<DMT_BulkImportProgress__e>();
    private List<Map<String, Object>> collectedErrors = new List<Map<String, Object>>();

    /**
     * @description Process of a Bulk Import load: units = one per line (see UNIT_* keys), recordTypeName
     * = DeveloperName of the DMT_Line__c record type picked in the LWC. Run with UNITS_PER_CHUNK.
     */
    public DMT_BulkImportBatch(List<Map<String, Object>> units, String jobId, String recordTypeName) {
        this.rows = new List<Object>();
        for (Map<String, Object> unit : units) {
            this.rows.add(unit);
        }
        this.jobId           = jobId;
        this.importType      = IMPORT_TYPE_PROCESS;
        this.recordTypeName  = recordTypeName;
        this.totalRows       = units.size();
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
processUnits(chunk);
        processedCount += chunk.size();
        publishProgress('IN_PROGRESS');
    }

    public void finish(Database.BatchableContext bc) {
        publishProgress('COMPLETED');
        // automatic status change (Update Line Status logic), one line per transaction: a status
        // change that restarts approval tasks costs about 76 SOQL (measured in DMT_TCM_DEV, 2026-11-16). A test can run
        // only one batch: the load mode has its own test (DMT_BatchSanctionAMIWEB_Test).
        lastStatusTargets = statusTargets;
        // the screen always gets a STATUS result: COMPLETED at once when no line moves, FAILED when
        // the job cannot start; otherwise DMT_BatchSanctionAMIWEB reports progress and the end with this jobId
        if (statusTargets.isEmpty()) {
            publishEvent(jobId, PHASE_STATUS, EVENT_COMPLETED, 0, 0, 0, 0, null);
            return;
        }
        try {
            if (!Test.isRunningTest()) {
                Database.executeBatch(new DMT_BatchSanctionAMIWEB(statusTargets, jobId), 1);
            }
            publishEvent(jobId, PHASE_STATUS, EVENT_IN_PROGRESS, statusTargets.size(), 0, 0, 0, null);
        } catch (Exception e) {
            publishEvent(jobId, PHASE_STATUS, EVENT_FAILED, statusTargets.size(), 0, 0, statusTargets.size(),
                         new List<Map<String, Object>>{ new Map<String, Object>{ 'message' => e.getMessage() } });
        }
    }

    // ─── Process: lines and their products, per line all or nothing ───

    /**
     * @description Builds every unit of the chunk (line, Risk Line Terms, Line Product Items); a unit
     * that cannot be built is reported and not saved. The rest is saved with one delete (old products of the replaced
     * objects), one insert (new lines, then the products, each pointing to its line by Line_Id__c) and one update
     * (existing lines). If that fails, the chunk is rolled back and saved again line by line.
     */
    private void processUnits(List<Map<String, Object>> chunk) {
        List<Map<String, Object>> fileRows = new List<Map<String, Object>>();
        Set<String> chunkLineIds = new Set<String>();
        for (Map<String, Object> unit : chunk) {
            Map<String, Object> lineRow = lineRow(unit);
            fileRows.add(lineRow);
            fileRows.addAll(childRows(unit, UNIT_RLT));
            String lineId = str(lineRow, 'Line_Id__c');
            if (lineId != null) {
                chunkLineIds.add(lineId);
            }
        }

        Map<String, Id> userIdMap = new Map<String, Id>();
        Set<String> userExtIds = new Set<String>();
        for (Map<String, Object> row : fileRows) {
            String uid = ownerExtId(row);
            if (uid != null) userExtIds.add(uid);
        }
        if (!userExtIds.isEmpty()) {
            for (User u : [SELECT Id, ID_User__c FROM User WHERE ID_User__c IN :userExtIds AND IsActive = true]) {
                userIdMap.put(u.ID_User__c, u.Id);
            }
        }

        // Existing lines: status kept on update, Id for the update
        // query adds g_line_status_type__c, the fields blocked outside Draft (BLOCKED_OUTSIDE_DRAFT) and
        // the fields of the rule ApprovalProcessDataEdit with Closed__c and DMT_Allow_Approval_Edit__c (approvalDataLocked),
        // compared by planStatus
        Map<String, String> existingStatusMap = new Map<String, String>();
        Map<String, DMT_Line__c> existingLines = new Map<String, DMT_Line__c>();
        for (DMT_Line__c existing : [SELECT Id, Line_Id__c, Status__c, g_line_status_type__c, Name, Booking_Geography__c,
                                            CurrencyIsoCode, Start_Date__c, DvP_Amount__c, FD_Amount__c, Repos_Limit__c,
                                            Repos_Limit_6M__c, First_Breakclause__c, Breakclause_Frequency__c, Waiver__c,
                                            Client__c, Amount__c, DMT_LastLevelId__c,
                                            Closed__c, DMT_Allow_Approval_Edit__c, DMT_Operation__c, DMT_Nominal__c,
                                            DMT_RAROEC_RORC_Proposal__c, DMT_Franchise_L12M__c, DMT_Comments__c,
                                            DMT_Additional_Restrictions__c, DMT_Client_Use__c, DMT_ApproverGlobalBanker__c,
                                            DMT_Booking_Unit_Risk_Analyst__c, DMT_Approver__c
                                     FROM DMT_Line__c WHERE Line_Id__c IN :chunkLineIds]) {
            existingStatusMap.put(existing.Line_Id__c, existing.Status__c);
            existingLines.put(existing.Line_Id__c, existing);
        }

        List<Map<String, Object>> updatedLineRows = new List<Map<String, Object>>();
        for (Map<String, Object> unit : chunk) {
            if (unit.get(UNIT_UPDATE_LINE) != false) {
                updatedLineRows.add(lineRow(unit));
            }
        }
        Map<String, Id> accountIdByClientCode = resolveClientCodes(updatedLineRows);
        Id lineRecordTypeId = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();

        List<UnitWork> works = new List<UnitWork>();
        for (Map<String, Object> unit : chunk) {
            UnitWork work = new UnitWork(unit);
            String error = buildUnit(work, unit, userIdMap, lineRecordTypeId, existingStatusMap, existingLines, accountIdByClientCode);
            if (error != null) {
                addRowError(work.rowNumber, work.lineRow, 'Line_Id__c', 'Name', error);
            } else {
                works.add(work);
            }
        }
        if (works.isEmpty()) {
            return;
        }
        loadOldChildren(works);
        saveWorks(works);
    }

    /**
     * @description Fills the unit's line and products from the file rows; returns the reason the unit is
     * rejected, or null.
     */
    private String buildUnit(UnitWork work, Map<String, Object> unit, Map<String, Id> userIdMap, Id lineRecordTypeId,
                             Map<String, String> existingStatusMap, Map<String, DMT_Line__c> existingLines,
                             Map<String, Id> accountIdByClientCode) {
        if (work.lineId == null) {
            return 'Line_Id__c is required.';
        }
        DMT_Line__c existing = existingLines.get(work.lineId);
        work.existingLineId = existing == null ? null : existing.Id;
        if (unit.get(UNIT_UPDATE_LINE) != false) {
            DMT_Line__c line = new DMT_Line__c();
            String error = buildLine(line, work.lineRow, userIdMap, lineRecordTypeId, existingStatusMap, accountIdByClientCode);
            if (error != null) {
                return error;
            }
            line.Id = work.existingLineId;
            work.line = line;
planStatus(work, existing, recordTypeName);
        } else if (work.existingLineId == null) {
            return 'The line does not exist in Salesforce and has no line data to create it.';
        }

        Map<String, Schema.SObjectField> rltFields = Schema.SObjectType.DMT_Risk_Line_Term__c.fields.getMap();
        Map<String, Schema.SObjectField> lpiFields = Schema.SObjectType.DMT_Line_Product_Item__c.fields.getMap();
        work.replaceRlt = unit.get(UNIT_RLT) != null;
        work.replaceLpi = unit.get(UNIT_LPI) != null;
        for (Map<String, Object> row : childRows(unit, UNIT_RLT)) {
            DMT_Risk_Line_Term__c term = new DMT_Risk_Line_Term__c(DMT_Line__r = new DMT_Line__c(Line_Id__c = work.lineId));
            String error = putFileFields(term, row, RLT_FILE_FIELDS, rltFields);
            if (error == null) {
error = checkTermDays(term);
            }
            if (error != null) {
                return 'Risk Line Term: ' + error;
            }
            String userExtId = ownerExtId(row);
            if (userExtId != null && userIdMap.containsKey(userExtId)) {
                term.DMT_ID_User__c = userExtId;
            }
            work.terms.add(term);
        }
        for (Map<String, Object> row : childRows(unit, UNIT_LPI)) {
            DMT_Line_Product_Item__c item = new DMT_Line_Product_Item__c(Line__r = new DMT_Line__c(Line_Id__c = work.lineId));
            String error = putFileFields(item, row, LPI_FILE_FIELDS, lpiFields);
            if (error != null) {
                return 'Line Product Item: ' + error;
            }
            work.items.add(item);
        }
        // products only on a Ready to close line: the line is not updated, so runDml adds a no-change
        // update that runs the Ready to close checkpoint (as DMT_ApprovalChangeStep_Helper.recheckReadyToCloseLine)
        work.recheckReadyToClose = work.line == null && existing != null && existing.Status__c == STATUS_READY_TO_CLOSE
                                   && (work.replaceRlt || work.replaceLpi || !work.deleteRltIds.isEmpty()
|| !work.deleteLpiIds.isEmpty());
        return null;
    }

    /**
     * @description Status rules of the load (approved by Diego, 2026-11-16). New line: created in Draft;
     * a code other than DR in g_line_status_type__c moves it to that status after the load. Existing line not in Draft:
     * when the file changes a field blocked outside Draft (BLOCKED_OUTSIDE_DRAFT), a field the rule ApprovalProcessDataEdit
     * blocks in its status (approvalDataLocked), or its code points to another status,
     * it is saved in Draft and moved back to the status of g_line_status_type__c after the load (file value, or the
     * stored one when the column is absent), or to its previous status when there is no code. A Closed line without a
     * code stays in Draft. Existing Draft lines keep the Update Line Status button (ticket requirement 3). The move is
     * one update straight to the target (DMT_BatchSanctionAMIWEB, Bulk Import load mode).
     */
    private static void planStatus(UnitWork work, DMT_Line__c existing, String recordTypeName) {
        DMT_Line__c line = work.line;
        Map<String, Object> populated = line.getPopulatedFieldsAsMap();
        String code = populated.containsKey('g_line_status_type__c') ? line.g_line_status_type__c
                    : (existing == null ? null : existing.g_line_status_type__c);
        code = code == null ? null : code.toUpperCase();
        String codeStatus = code == null ? null : STATUS_BY_CODE.get(code);
        if (existing == null) {
            if (codeStatus != null && codeStatus != STATUS_DRAFT) {
                work.walkToStatus = codeStatus;
            }
            return;
        }
        if (existing.Status__c == STATUS_DRAFT) {
            return;
        }
        Boolean blockedChange = false;
        for (String fieldName : BLOCKED_OUTSIDE_DRAFT) {
            if (populated.containsKey(fieldName) && populated.get(fieldName) != existing.get(fieldName)) {
                blockedChange = true;
                break;
            }
        }
        // a change the rule ApprovalProcessDataEdit rejects in the current status also goes through Draft
        if (!blockedChange && approvalDataLocked(populated, existing, recordTypeName)) {
            blockedChange = true;
        }
        Boolean codeMoves = codeStatus != null && codeStatus != existing.Status__c;
        if (!blockedChange && !codeMoves) {
            return;
        }
        line.Status__c = STATUS_DRAFT;
        String target = codeStatus != null ? codeStatus : existing.Status__c;
        if (codeStatus == null && existing.Status__c == STATUS_CLOSED) {
            target = null;
        }
        if (target != null && target != STATUS_DRAFT) {
            work.walkToStatus = target;
        }
    }

    /**
     * @description Copy of the validation rule DMT_Line__c.ApprovalProcessDataEdit for the line as it is
     * now: the file changes one of its fields and the save would be rejected in the current status. Treasury lines: in
     * Approval, Ready to close or Closed unless DMT_Allow_Approval_Edit__c. Sanction / Other Products lines: in those
     * statuses when Closed Lost, or without DMT_Line_God and DMT_Allow_Approval_Edit__c.
     */
    private static Boolean approvalDataLocked(Map<String, Object> populated, DMT_Line__c existing, String recordTypeName) {
        if (!APPROVAL_DATA_STATUSES.contains(existing.Status__c)) {
            return false;
        }
        Boolean changed = false;
        for (String fieldName : APPROVAL_DATA_FIELDS) {
            if (populated.containsKey(fieldName) && populated.get(fieldName) != existing.get(fieldName)) {
                changed = true;
                break;
            }
        }
        if (!changed) {
            return false;
        }
        if (recordTypeName == 'Sanction' || recordTypeName == 'OtherProducts') {
            return (existing.Status__c == STATUS_CLOSED && existing.Closed__c == 'Lost')
                || (!FeatureManagement.checkPermission('DMT_Line_God') && !existing.DMT_Allow_Approval_Edit__c);
        }
        return !existing.DMT_Allow_Approval_Edit__c;
    }

    /**
     * @description For the LWC preview (dmt_bulk_import, bulkImportRules.rowSaveError): the file columns
     * that putValue types, by table (line, rlt, lpi) and field, as 'date', 'number' or 'boolean' (other columns are saved
     * as text), and the active values of the term picklists (checkTermDays), so the screen can show before Process the
     * errors buildUnit returns.
     */
    public static Map<String, Object> fileValueRules() {
        Map<String, Object> fieldTypes = new Map<String, Object>{
            UNIT_LINE => typedFields(LINE_FILE_FIELDS, Schema.SObjectType.DMT_Line__c.fields.getMap()),
            UNIT_RLT  => typedFields(RLT_FILE_FIELDS, Schema.SObjectType.DMT_Risk_Line_Term__c.fields.getMap()),
            UNIT_LPI  => typedFields(LPI_FILE_FIELDS, Schema.SObjectType.DMT_Line_Product_Item__c.fields.getMap())
        };
        Map<String, List<String>> termDayValuesByField = new Map<String, List<String>>();
        for (Schema.SObjectField field : TERM_DAY_FIELDS) {
            termDayValuesByField.put(field.getDescribe().getName(), new List<String>(termDayValues(field)));
        }
        return new Map<String, Object>{ 'fieldTypes' => fieldTypes, 'termDays' => termDayValuesByField };
    }

    // the type putValue checks for each listed field: date, number or boolean (text fields left out)
    private static Map<String, String> typedFields(List<String> fieldNames, Map<String, Schema.SObjectField> fields) {
        Map<String, String> typeByField = new Map<String, String>();
        for (String fieldName : fieldNames) {
            Schema.SObjectField field = fields.get(fieldName);
            if (field == null) {
                continue;
            }
            Schema.DisplayType fieldType = field.getDescribe().getType();
            if (fieldType == Schema.DisplayType.DATE) {
                typeByField.put(fieldName, 'date');
            } else if (fieldType == Schema.DisplayType.CURRENCY || fieldType == Schema.DisplayType.DOUBLE
                       || fieldType == Schema.DisplayType.PERCENT || fieldType == Schema.DisplayType.INTEGER) {
                typeByField.put(fieldName, 'number');
            } else if (fieldType == Schema.DisplayType.BOOLEAN) {
                typeByField.put(fieldName, 'boolean');
            }
        }
        return typeByField;
    }

    /**
     * @description DMT_Init_Term__c / DMT_End_Term__c are picklists of days (0, 30, 365...) that do not
     * restrict their values: a date or any other text saves, and the line fails later when it reaches Approval
     * (DMT_Line_Helper.createConsolidatedLine reads them as numbers). A whole number written as 365.0 or 365,0 is saved
     * as 365; any value that is not one of the picklist values rejects the line. Returns the error or null.
     */
    private static String checkTermDays(DMT_Risk_Line_Term__c term) {
        for (Schema.SObjectField field : TERM_DAY_FIELDS) {
            String value = (String) term.get(field);
            if (String.isBlank(value)) {
                continue;
            }
            String days = value.trim();
            try {
                Decimal numericDays = Decimal.valueOf(days.replace(',', '.'));
                if (numericDays == numericDays.round(System.RoundingMode.DOWN)) {
                    days = String.valueOf(numericDays.intValue());
                }
            } catch (TypeException e) {
                days = value.trim();
            }
            if (!termDayValues(field).contains(days)) {
                return field.getDescribe().getName() + ': invalid value ' + value
                       + ' (expected a number of days of the picklist, for example 0, 30, 365).';
            }
            term.put(field, days);
        }
        return null;
    }

    // active picklist values of a term field (describe, cached per transaction)
    private static Set<String> termDayValues(Schema.SObjectField field) {
        String name = field.getDescribe().getName();
        if (!TERM_DAY_VALUES.containsKey(name)) {
            Set<String> values = new Set<String>();
            for (Schema.PicklistEntry entry : field.getDescribe().getPicklistValues()) {
                if (entry.isActive()) {
                    values.add(entry.getValue());
                }
            }
            TERM_DAY_VALUES.put(name, values);
        }
        return TERM_DAY_VALUES.get(name);
    }

    // writes the listed fields present in the row (typed by putValue); returns the first invalid value
    private static String putFileFields(SObject record, Map<String, Object> row, List<String> fieldNames,
                                        Map<String, Schema.SObjectField> fields) {
        for (String fieldName : fieldNames) {
            if (!row.containsKey(fieldName)) {
                continue;
            }
            String error = putValue(record, fields.get(fieldName), str(row, fieldName));
            if (error != null) {
                return fieldName + ': ' + error;
            }
        }
        return null;
    }

    // Ids of the products that each unit replaces (only existing lines can have them), two queries per chunk
    private static void loadOldChildren(List<UnitWork> works) {
        Map<String, UnitWork> rltWorks = new Map<String, UnitWork>();
        Map<String, UnitWork> lpiWorks = new Map<String, UnitWork>();
        for (UnitWork work : works) {
            if (work.existingLineId == null) continue;
            if (work.replaceRlt) rltWorks.put(work.lineId, work);
            if (work.replaceLpi) lpiWorks.put(work.lineId, work);
        }
        if (!rltWorks.isEmpty()) {
            for (DMT_Risk_Line_Term__c term : [SELECT Id, DMT_Line__r.Line_Id__c FROM DMT_Risk_Line_Term__c
                                               WHERE DMT_Line__r.Line_Id__c IN :rltWorks.keySet()]) {
                rltWorks.get(term.DMT_Line__r.Line_Id__c).oldChildIds.add(term.Id);
            }
        }
        if (!lpiWorks.isEmpty()) {
            for (DMT_Line_Product_Item__c item : [SELECT Id, Line__r.Line_Id__c FROM DMT_Line_Product_Item__c
                                                  WHERE Line__r.Line_Id__c IN :lpiWorks.keySet()]) {
                lpiWorks.get(item.Line__r.Line_Id__c).oldChildIds.add(item.Id);
            }
        }
loadSingleDeletes(works);
    }

    /**
     * @description Single records the user removed on the screen (UNIT_RLT_DELETE / UNIT_LPI_DELETE, that
     * table not loaded): added to the records to delete only when they belong to the unit's line. One query per object,
     * only when there are such records.
     */
    private static void loadSingleDeletes(List<UnitWork> works) {
        Map<Id, UnitWork> rltOwner = new Map<Id, UnitWork>();
        Map<Id, UnitWork> lpiOwner = new Map<Id, UnitWork>();
        for (UnitWork work : works) {
            if (work.existingLineId == null) continue;
            if (!work.replaceRlt) for (Id recordId : work.deleteRltIds) rltOwner.put(recordId, work);
            if (!work.replaceLpi) for (Id recordId : work.deleteLpiIds) lpiOwner.put(recordId, work);
        }
        if (!rltOwner.isEmpty()) {
            for (DMT_Risk_Line_Term__c term : [SELECT Id, DMT_Line__c FROM DMT_Risk_Line_Term__c WHERE Id IN :rltOwner.keySet()]) {
                UnitWork work = rltOwner.get(term.Id);
                if (term.DMT_Line__c == work.existingLineId) work.oldChildIds.add(term.Id);
            }
        }
        if (!lpiOwner.isEmpty()) {
            for (DMT_Line_Product_Item__c item : [SELECT Id, Line__c FROM DMT_Line_Product_Item__c WHERE Id IN :lpiOwner.keySet()]) {
                UnitWork work = lpiOwner.get(item.Id);
                if (item.Line__c == work.existingLineId) work.oldChildIds.add(item.Id);
            }
        }
    }

    /**
     * @description Saves the units together; on failure rolls back and saves them one by one, so a line
     * and its products are saved together or not at all (the old products stay when a line fails).
     */
    private void saveWorks(List<UnitWork> works) {
        Savepoint chunkSavepoint = Database.setSavepoint();
        try {
            runDml(works);
            successCount += works.size();
            for (UnitWork work : works) {
addStatusFollowUp(work);
            }
            return;
        } catch (Exception e) {
            Database.rollback(chunkSavepoint);
            if (works.size() == 1) {
                addRowError(works[0].rowNumber, works[0].lineRow, 'Line_Id__c', 'Name', dmlMessage(e));
                return;
            }
        }
        for (UnitWork work : works) {
            Savepoint lineSavepoint = Database.setSavepoint();
            try {
                runDml(new List<UnitWork>{ work });
                successCount++;
addStatusFollowUp(work);
            } catch (Exception e) {
                Database.rollback(lineSavepoint);
                addRowError(work.rowNumber, work.lineRow, 'Line_Id__c', 'Name', dmlMessage(e));
            }
        }
    }

    // delete old products, insert new lines + products (grouped by object, lines first), update existing
    // lines. Records are cloned so a retry after a rollback starts from records without Id.
    private static void runDml(List<UnitWork> works) {
        List<Id> toDelete = new List<Id>();
        List<SObject> newLines = new List<SObject>();
        List<SObject> newTerms = new List<SObject>();
        List<SObject> newItems = new List<SObject>();
        List<DMT_Line__c> toUpdate = new List<DMT_Line__c>();
        for (UnitWork work : works) {
            toDelete.addAll(work.oldChildIds);
            if (work.line != null && work.existingLineId == null) {
                newLines.add(work.line.clone(false, true));
            } else if (work.line != null) {
                toUpdate.add(work.line.clone(true, true));
            } else if (work.recheckReadyToClose) {
toUpdate.add(new DMT_Line__c(Id = work.existingLineId)); // Ready to close checkpoint
            }
            for (DMT_Risk_Line_Term__c term : work.terms) {
                newTerms.add(term.clone(false, true));
            }
            for (DMT_Line_Product_Item__c item : work.items) {
                newItems.add(item.clone(false, true));
            }
        }
        List<SObject> toInsert = new List<SObject>();
        toInsert.addAll(newLines);
        toInsert.addAll(newTerms);
        toInsert.addAll(newItems);
        if (!toDelete.isEmpty()) {
            Database.delete(toDelete, true);
        }
        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    // a saved line that moves to a status after the load (planStatus)
    private void addStatusFollowUp(UnitWork work) {
if (work.walkToStatus != null && !work.stayDraft) {
            statusTargets.put(work.lineId, work.walkToStatus);
        }
    }

    private static String dmlMessage(Exception e) {
        return e instanceof DmlException ? ((DmlException) e).getDmlMessage(0) : e.getMessage();
    }

    private static Map<String, Object> lineRow(Map<String, Object> unit) {
        Object line = unit.get(UNIT_LINE);
        return line == null ? new Map<String, Object>() : (Map<String, Object>) line;
    }

    // a list of record Ids sent by the LWC (invalid values are skipped)
    private static List<Id> idList(Object value) {
        List<Id> ids = new List<Id>();
        if (value == null) {
            return ids;
        }
        for (Object item : (List<Object>) value) {
            try {
                ids.add(Id.valueOf(String.valueOf(item)));
            } catch (Exception e) {
                continue;
            }
        }
        return ids;
    }

    private static List<Map<String, Object>> childRows(Map<String, Object> unit, String key) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        Object value = unit.get(key);
        if (value != null) {
            for (Object row : (List<Object>) value) {
                result.add((Map<String, Object>) row);
            }
        }
        return result;
    }

    // one line of the load and what Process saves for it
    private class UnitWork {
        Map<String, Object> lineRow;
        String lineId;
        Integer rowNumber;
        Id existingLineId;
        DMT_Line__c line;
        Boolean replaceRlt = false;
        Boolean replaceLpi = false;
        List<DMT_Risk_Line_Term__c> terms = new List<DMT_Risk_Line_Term__c>();
        List<DMT_Line_Product_Item__c> items = new List<DMT_Line_Product_Item__c>();
        List<Id> oldChildIds = new List<Id>();
String walkToStatus; // status the line moves to after the load (planStatus)
Boolean recheckReadyToClose = false; // products only on a Ready to close line
Boolean stayDraft = false; // UNIT_STAY_DRAFT: no move after the load
List<Id> deleteRltIds = new List<Id>(); // UNIT_RLT_DELETE
List<Id> deleteLpiIds = new List<Id>(); // UNIT_LPI_DELETE

        UnitWork(Map<String, Object> unit) {
stayDraft = unit.get(UNIT_STAY_DRAFT) == true;
deleteRltIds = DMT_BulkImportBatch.idList(unit.get(UNIT_RLT_DELETE));
deleteLpiIds = DMT_BulkImportBatch.idList(unit.get(UNIT_LPI_DELETE));
            lineRow   = DMT_BulkImportBatch.lineRow(unit);
            lineId    = DMT_BulkImportBatch.str(lineRow, 'Line_Id__c');
            Object rowNumberValue = unit.get(UNIT_ROW_NUMBER);
            rowNumber = rowNumberValue == null ? null : Integer.valueOf(rowNumberValue);
        }
    }

    /**
     * @description Fills the Line from the row and returns the reason the row is rejected, or null.
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
if (KEEP_WHEN_BLANK_FIELDS.contains(fieldName) && String.isBlank(str(row, fieldName))) {
                continue;
            }
            String error = putValue(line, lineFields.get(fieldName), str(row, fieldName));
            if (error != null) {
                return fieldName + ': ' + error;
            }
        }

        // the code in upper case: DMT_BatchSanctionAMIWEB sets Closed__c Won / Lost only for 'CW' / 'CL', and
        // a Closed line without Closed__c is rejected (validation rule Set_Closed_Won_Lost)
        if (line.g_line_status_type__c != null) {
            line.g_line_status_type__c = line.g_line_status_type__c.toUpperCase();
        }

        // Status__c from the file is ignored: new lines start in Draft, existing ones keep their status.
        line.Status__c     = isNewLine ? 'Draft' : existingStatusMap.get(line.Line_Id__c);
        line.DMT_Origin__c = 'BulkImport';

        // Amount from embedded term column in the lines file → line total amount
        String amtStr = str(row, 'DMT_Risk_Line_Term__c DMT_Amount__c');
        if (String.isNotBlank(amtStr)) {
            line.Amount__c = parseDecimal(amtStr);
        }

        // client: customer or group code, found before the upsert (resolveClientCodes).
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
String userExtId = ownerExtId(row);
        if (String.isNotBlank(userExtId) && userIdMap.containsKey(userExtId)) {
            line.OwnerId       = userIdMap.get(userExtId);
            line.DMT_ID_User__c = userExtId;
        }

        return null;
    }

    /**
     * @description Accounts of the chunk's Client_Code__c values, by code in upper case. A code is a
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
        // the query is shared with the LWC preview (DMT_BulkImportController.getStatusContext)
        Map<String, Id> accountIdByCode = new Map<String, Id>();
        Map<String, Account> accountByCode = accountsByClientCode(codes);
        for (String code : accountByCode.keySet()) {
            accountIdByCode.put(code, accountByCode.get(code).Id);
        }
        return accountIdByCode;
    }

    /**
     * @description Accounts by client code in upper case (codes already in upper case): customer code
     * (g_customer_id__c) or group code (DES_Group_Code__c), the customer match wins. One query; none when codes is empty.
     */
    public static Map<String, Account> accountsByClientCode(Set<String> codes) {
        Map<String, Account> accountByCode = new Map<String, Account>();
        if (codes == null || codes.isEmpty()) {
            return accountByCode;
        }
        for (Account account : [SELECT Id, g_customer_id__c, DES_Group_Code__c, DES_Client_Type__c, RecordType.Name,
                                       RecordType.DeveloperName
                                FROM Account WHERE g_customer_id__c IN :codes OR DES_Group_Code__c IN :codes]) {
            if (account.DES_Group_Code__c != null && codes.contains(account.DES_Group_Code__c.toUpperCase())
                && !accountByCode.containsKey(account.DES_Group_Code__c.toUpperCase())) {
                accountByCode.put(account.DES_Group_Code__c.toUpperCase(), account);
            }
            if (account.g_customer_id__c != null && codes.contains(account.g_customer_id__c.toUpperCase())) {
                accountByCode.put(account.g_customer_id__c.toUpperCase(), account);
            }
        }
        return accountByCode;
    }

    /**
     * @description The DMT_Line__c.Client_Type__c a line gets with this client and without Golden_Code__c
     * or Custom_Association__c (same order as the formula): Country Customer, Customer (DES_Client_Type__c Subsidiary)
     * or Group.
     */
    public static String clientTypeOf(Account account) {
        if (account.RecordType != null && account.RecordType.Name == 'Country') {
            return 'Country Customer';
        }
        return account.DES_Client_Type__c == 'Subsidiary' ? 'Customer' : 'Group';
    }

    /**
     * @description Writes a file value to a field, typed from its describe. Blank clears the field
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

    // the owner's user id from whichever owner column the file uses.
    private static String ownerExtId(Map<String, Object> row) {
        for (String column : OWNER_COLUMNS) {
            String value = str(row, column);
            if (value != null) {
                return value;
            }
        }
        return null;
    }

    // ─── Shared helpers ───────────────────────────────────────────────────────

    // one failed row in the progress event's error list (shared by DML failures and rows rejected before the DML).
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
publishEvent(jobId, importType, status, totalRows, processedCount, successCount, errorCount, collectedErrors);
    }

    /**
     * @description One DMT_BulkImportProgress__e for the LWC dmt_bulk_import (filtered by Job_Id__c and
     * Phase__c): PROCESS (this batch) and PHASE_STATUS (status move after the load or Update Line Status,
     * DMT_BatchSanctionAMIWEB): progress and the row messages. The end of each job is also read by polling its
     * AsyncApexJob (DMT_BulkImportController.getJobState), so a lost event does not leave the screen waiting. errorList
     * entries: row, id, label, message.
     */
    public static void publishEvent(String jobId, String phase, String status, Integer total, Integer processed,
                                    Integer success, Integer errors, List<Map<String, Object>> errorList) {
        DMT_BulkImportProgress__e evt = new DMT_BulkImportProgress__e();
        evt.Job_Id__c       = jobId;
evt.Phase__c        = phase;
        evt.Status__c       = status;
evt.Total__c        = total;
evt.Processed__c    = processed;
evt.Success_Count__c = success;
evt.Error_Count__c  = errors;

String errJson = JSON.serialize(errorList == null ? new List<Map<String, Object>>() : errorList);
        evt.Errors_JSON__c = errJson.length() > 131000
            ? errJson.substring(0, 131000) + '...truncated]'
            : errJson;

publishedEvents.add(evt);
        EventBus.publish(evt);
    }

    private static String str(Map<String, Object> row, String key) {
        Object val = row.get(key);
        if (val == null) return null;
        String s = String.valueOf(val).trim();
        return String.isEmpty(s) ? null : s;
    }

    // a file date: yyyy-mm-dd (CSV and XLSX cells as read by the LWC) or dd/mm/yyyy; null when invalid.
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