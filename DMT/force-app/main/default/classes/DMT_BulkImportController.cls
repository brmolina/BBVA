    /**
 * @description Apex of the Bulk Import screen (LWC dmt_bulk_import). CIBGLOBALD-4851: preview data (existing lines and
 * products, status context, value rules of the save), Process, job state, Update Line Status and Add OU (OU search).
 */
// without sharing, like DMT_BulkImportBatch: the preview must find every line and product the load will
// save or delete (DMT_Line__c and Account are Private); the screen (LWC dmt_bulk_import) requires DMT_Line_God.
public without sharing class DMT_BulkImportController {
    // OU search of the Add OU input (searchOus)
    private static final Integer OU_SEARCH_MIN_CHARS = 2; // guard for direct calls; the screen (dmt_bulk_import) does not call under it
    private static final Integer OU_SEARCH_MAX = 10;

    /**
     * Process button (LWC dmt_bulk_import): saves the lines of the load and replaces their products.
     * unitsJson = one unit per line (keys in DMT_BulkImportBatch.UNIT_*); progress and errors come back through the
     * DMT_BulkImportProgress__e event with this jobId. Returns the AsyncApexJob Id: the screen follows the job with
     * getJobState, so it ends even when an event is lost.
     */
    @AuraEnabled
    public static String processImport(String unitsJson, String jobId, String recordTypeName) {
        List<Map<String, Object>> units = deserializeRows(unitsJson);
        Id asyncJobId = Database.executeBatch(new DMT_BulkImportBatch(units, jobId, recordTypeName), DMT_BulkImportBatch.UNITS_PER_CHUNK);
        return String.valueOf(asyncJobId);
    }

    /**
     * State of a background job of the screen (Process, status move, Add OU), polled by the LWC
     * dmt_bulk_import until it is Completed, Failed or Aborted: status, errors (chunks that failed), extendedStatus (first
     * error), processed / total (chunks).
     */
    @AuraEnabled
    public static Map<String, Object> getJobState(String asyncJobId) {
        AsyncApexJob job = [SELECT Status, NumberOfErrors, ExtendedStatus, JobItemsProcessed, TotalJobItems
                            FROM AsyncApexJob WHERE Id = :asyncJobId];
        return new Map<String, Object>{
            'status'         => job.Status,
            'errors'         => job.NumberOfErrors,
            'extendedStatus' => job.ExtendedStatus,
            'processed'      => job.JobItemsProcessed,
            'total'          => job.TotalJobItems
        };
    }

    /**
     * The status move a load started (DMT_BulkImportBatch.finish launches DMT_BatchSanctionAMIWEB): the
     * first DMT_BatchSanctionAMIWEB job the same user created after the load job, or null while there is none yet.
     */
    @AuraEnabled
    public static String getStatusJobAfterLoad(String loadAsyncJobId) {
        AsyncApexJob load = [SELECT CreatedById, CreatedDate FROM AsyncApexJob WHERE Id = :loadAsyncJobId];
        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob
                                   WHERE ApexClass.Name = 'DMT_BatchSanctionAMIWEB' AND JobType = 'BatchApex'
                                     AND CreatedById = :load.CreatedById AND CreatedDate >= :load.CreatedDate
                                   ORDER BY CreatedDate ASC LIMIT 1];
        return jobs.isEmpty() ? null : String.valueOf(jobs[0].Id);
    }

    /**
     * Update Line Status action: moves the Draft lines of the current import to the status
     * informed in the file (g_line_status_type__c), reusing DMT_BatchSanctionAMIWEB in Bulk Import mode.
     * Returns the AsyncApexJob Id. jobId: the job publishes its progress and result for the screen
     * (DMT_BulkImportProgress__e, Phase STATUS).
     */
    @AuraEnabled
    public static String updateLineStatus(List<String> lineIds, String jobId) {
        if (lineIds == null || lineIds.isEmpty()) {
            throw new AuraHandledException('There are no imported lines to update.');
        }
        Id asyncJobId = Database.executeBatch(new DMT_BatchSanctionAMIWEB(new Set<String>(lineIds), jobId), 50);
        return String.valueOf(asyncJobId);
    }

    /**
     * Add OU button (LWC dmt_bulk_import): adds the active users of the OU with a DMT Read/Write role,
     * and each line's owner, as Read/Write participants with Approval Edit to the lines of the load
     * (DMT_BulkImportOuParticipantsBatch). Returns users = the number of distinct users added (OU users plus line
     * owners) and asyncJobId = the batch job, which the screen follows (getJobState) before checking the result
     * (countMissingOuParticipants).
     * @param ouCode  User.DES_LevelUO_10__c value typed by the user
     * @param lineIds Line_Id__c of the lines processed on the screen
     */
    @AuraEnabled
    public static Map<String, Object> addOuParticipants(String ouCode, List<String> lineIds) {
        if (String.isBlank(ouCode)) {
            throw new AuraHandledException('Enter an OU code.');
        }
        if (lineIds == null || lineIds.isEmpty()) {
            throw new AuraHandledException('There are no imported lines to add participants to.');
        }
        String code = ouCode.trim();
        Set<Id> ouUserIds = DMT_BulkImportOuParticipantsBatch.writeUsersOfOu(code);
        if (ouUserIds.isEmpty()) {
            throw new AuraHandledException('OU ' + code + ' has no active users with a DMT Read/Write role.');
        }
        Set<Id> addedUserIds = new Set<Id>(ouUserIds);
        for (DMT_Line__c line : [SELECT OwnerId FROM DMT_Line__c WHERE Line_Id__c IN :lineIds]) {
            if (line.OwnerId.getSObjectType() == User.SObjectType) {
                addedUserIds.add(line.OwnerId);
            }
        }
        Id asyncJobId = Database.executeBatch(new DMT_BulkImportOuParticipantsBatch(ouUserIds, new Set<String>(lineIds)),
                                              DMT_BulkImportOuParticipantsBatch.LINES_PER_CHUNK);
        return new Map<String, Object>{ 'users' => addedUserIds.size(), 'asyncJobId' => String.valueOf(asyncJobId) };
    }

    /**
     * OU search of the Add OU input (LWC dmt_bulk_import): the first OU_SEARCH_MAX OU codes
     * (User.DES_LevelUO_10__c), in alphabetical order, that contain the typed text and have active users with a DMT
     * Read/Write role, with how many (DMT_BulkImportOuParticipantsBatch.writeUserCountByOu, the users Add OU adds).
     * Nothing under OU_SEARCH_MIN_CHARS characters.
     * @param prefix text typed in the OU code input
     * @return one map per OU: code, users
     */
    @AuraEnabled
    public static List<Map<String, Object>> searchOus(String prefix) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        String text = prefix == null ? '' : prefix.trim();
        if (text.length() < OU_SEARCH_MIN_CHARS) {
            return result;
        }
        // the typed text is literal: LIKE wildcards in it are escaped
        String likePattern = '%' + text.replace('\\', '\\\\').replace('%', '\\%').replace('_', '\\_') + '%';
        Map<String, Integer> countByOu = DMT_BulkImportOuParticipantsBatch.writeUserCountByOu(likePattern, OU_SEARCH_MAX);
        List<String> ouCodes = new List<String>(countByOu.keySet());
        ouCodes.sort();
        for (String ouCode : ouCodes) {
            result.add(new Map<String, Object>{ 'code' => ouCode, 'users' => countByOu.get(ouCode) });
        }
        return result;
    }

    /**
     * Result check of Add OU, read from Salesforce: how many (line, user) pairs of the load are still not a
     * participant with AccessLevel__c Edit or All and DMT_ApprovalEdit__c. Users = the OU's Read/Write users
     * (DMT_BulkImportOuParticipantsBatch.writeUsersOfOu) plus each line's owner. 0 = everything was added.
     */
    @AuraEnabled
    public static Integer countMissingOuParticipants(String ouCode, List<String> lineIds) {
        Set<Id> ouUserIds = DMT_BulkImportOuParticipantsBatch.writeUsersOfOu(ouCode == null ? null : ouCode.trim());
        Map<Id, Set<Id>> expectedByLine = new Map<Id, Set<Id>>();
        Set<Id> allUserIds = new Set<Id>(ouUserIds);
        for (DMT_Line__c line : [SELECT Id, OwnerId FROM DMT_Line__c WHERE Line_Id__c IN :lineIds]) {
            Set<Id> userIds = new Set<Id>(ouUserIds);
            if (line.OwnerId.getSObjectType() == User.SObjectType) {
                userIds.add(line.OwnerId);
                allUserIds.add(line.OwnerId);
            }
            expectedByLine.put(line.Id, userIds);
        }
        Integer missing = 0;
        for (Set<Id> userIds : expectedByLine.values()) {
            missing += userIds.size();
        }
        Set<String> found = new Set<String>();
        for (DMT_TeamMember__c member : [SELECT Line__c, User__c FROM DMT_TeamMember__c
                                         WHERE Line__c IN :expectedByLine.keySet() AND User__c IN :allUserIds
                                           AND AccessLevel__c IN ('Edit', 'All') AND DMT_ApprovalEdit__c = true]) {
            String key = String.valueOf(member.Line__c) + ':' + String.valueOf(member.User__c);
            if (expectedByLine.get(member.Line__c).contains(member.User__c) && found.add(key)) {
                missing--;
            }
        }
        return missing;
    }

    @AuraEnabled
    public static List<DMT_Line__c> getExistingLines(List<String> lineIds) {
        // query adds the Treasury Lines file columns (DMT_Client_Entific__c to DMT_Client_Use__c),
        // compared by the LWC (New / Will Update / No Changes)
        return [
            SELECT Id, Name, Line_Id__c, Status__c, CurrencyIsoCode, Booking_Geography__c,
                   Client__r.Name, Client_Code__c,
                   Start_Date__c, End_Date__c, DMT_LastLevelId__c,
                   DMT_Comments__c, DMT_ID_User__c, Breakclause_Frequency__c,
                   g_line_status_type__c, Amount__c,
                   DMT_Client_Entific__c, Golden_Code__c, FD_Amount__c, DvP_Amount__c, First_Breakclause__c, Waiver__c,
                   DMT_Mitigant_Agreement_comments__c, DMT_Additional_Restrictions__c, DMT_Client_Use__c,
                   Client_Type__c, Custom_Association__c, Client__r.RecordType.DeveloperName, Closed__c,
                   DMT_Allow_Approval_Edit__c
            FROM DMT_Line__c
            WHERE Line_Id__c IN :lineIds
            LIMIT :lineIds.size()
        ];
    }

    /**
     * What the LWC (dmt_bulk_import, _stayDraftReasons) needs to tell which lines will stay in Draft
     * after the load: profileName = the running user's profile (validation rule DMT_Line__c.Go_through_each_step) and
     * clientTypeByCode = the line client type (DMT_Line__c.Client_Type__c formula) of each Client_Code__c in upper case
     * (DMT_BulkImportBatch.clientTypeOf, flow DMT_OTHER_Line_Validations); clientRecordTypeByCode = the client's record type
     * DeveloperName (a Prospect client cannot be closed Won, DMT_Line_Helper.blockReadyToCloseWithProspectInMultiholder);
     * fileValueRules = the typed file columns and term picklist values the save checks (DMT_BulkImportBatch.fileValueRules).
     */
    @AuraEnabled
    public static Map<String, Object> getStatusContext(List<String> clientCodes) {
        Map<String, String> clientTypeByCode = new Map<String, String>();
        Map<String, String> clientRecordTypeByCode = new Map<String, String>();
        Set<String> codes = new Set<String>();
        for (String code : clientCodes == null ? new List<String>() : clientCodes) {
            if (String.isNotBlank(code)) {
                codes.add(code.trim().toUpperCase());
            }
        }
        Map<String, Account> accountByCode = DMT_BulkImportBatch.accountsByClientCode(codes);
        for (String code : accountByCode.keySet()) {
            clientTypeByCode.put(code, DMT_BulkImportBatch.clientTypeOf(accountByCode.get(code)));
            Account client = accountByCode.get(code);
            clientRecordTypeByCode.put(code, client.RecordType == null ? null : client.RecordType.DeveloperName);
        }
        return new Map<String, Object>{
            'profileName'      => [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name,
            'clientTypeByCode' => clientTypeByCode,
            'clientRecordTypeByCode' => clientRecordTypeByCode,
            'fileValueRules'   => DMT_BulkImportBatch.fileValueRules() // value checks of the save, before Process
        };
    }

    /**
     * Custom association clients of the loaded lines (Custom_Association__c.DMT_Line__c), for the LWC
     * dmt_bulk_import to mirror the Custom-line checks of the flow DMT_TRSR_Line_Validations (getCustomAssociation,
     * getCustomAssociationClientsLoop): client count, amounts and term.
     */
    @AuraEnabled
    public static List<Custom_Association_Client__c> getCustomAssociationClients(List<String> lineIds) {
        return [
            SELECT Id, Custom_Association__c, Custom_Association__r.DMT_Line__r.Line_Id__c,
                   DMT_Amount__c, DMT_FDAmount__c, DMT_DVPAmount__c, DMT_Term__c
            FROM Custom_Association_Client__c
            WHERE Custom_Association__r.DMT_Line__r.Line_Id__c IN :lineIds
            ORDER BY Custom_Association__c, CreatedDate
        ];
    }

    @AuraEnabled
    public static List<DMT_Risk_Line_Term__c> getExistingTermsForLines(List<String> lineIds) {
        // query adds Id and DMT_Risk_Type__c: the LWC lists every Risk Line Term of the loaded lines
        // (Treasury Lines files identify a term by its risk type, not by DMT_RiskLineTermId__c)
        return [
            SELECT Id, DMT_Risk_Type__c, DMT_RiskLineTermId__c, DMT_Line__r.Line_Id__c,
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

    /**
     * Line Product Items of the loaded lines (Treasury Lines), listed by the LWC (dmt_bulk_import)
     * next to the rows of the Line Product Items file: they are replaced when the file has rows for their line.
     */
    @AuraEnabled
    public static List<DMT_Line_Product_Item__c> getExistingProductItemsForLines(List<String> lineIds) {
        return [
            SELECT Id, Line__r.Line_Id__c, Product_Code_Value__c, Max_Tenor_WC__c,
                   DMT_DerivativeRestriction__c, DMT_FDRestriction__c, DMT_DVPRestriction__c
            FROM DMT_Line_Product_Item__c
            WHERE Line__r.Line_Id__c IN :lineIds
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