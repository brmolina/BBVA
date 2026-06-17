/**
 * @description Service class encapsulating business logic for prospect Account operations,
 *              including Account Team Member management for Global Banker assignments.
 * @author      Borja Lorenzo Adajas
 * @date        2026-05-14
 */
public with sharing class DES_ProspectService {

    /** Cache mapping prospect RT developer names to their Ids, populated once per transaction. */
    private static Map<String, Id> prospectRtByDevNameCache;
    @TestVisible private static Map<String, String> countryToEntificMapTestOverride;

    // ──────────────────────────────────────────────────────────────────────────
    // Public methods
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * @description Sets gf_customer_prospect_id__c on newly inserted Prospect accounts
     *              and enqueues a DES_ProspectCreateQueueable job to call the remote
     *              prospect-creation service asynchronously. The Queueable processes
     *              records in batches of 50 and chains itself for any remaining records.
     * @param newAccounts Trigger.newMap from the after-insert Account trigger context.
     */
    public static void generateProspectId(Map<Id, Account> newAccounts) {
        final List<Id> allProspectIds = new List<Id>();
        final Set<Id> subsidiaryIds = new Set<Id>();

        for (Id idAccount : newAccounts.keySet()) {
            final Account acc = newAccounts.get(idAccount);
            if (isProspectRecord(acc, DES_Constants.ACCOUNT_RT_PROSPECT_SUBSIDIARY)) {
                allProspectIds.add(idAccount);
                subsidiaryIds.add(idAccount);
            } else if (isProspectRecord(acc, DES_Constants.ACCOUNT_RT_PROSPECT_GROUP)) {
                allProspectIds.add(idAccount);
            }
        }

        if (allProspectIds.isEmpty()) {
            return;
        }

        final List<Account> accList = DES_AccountSelector.getByIds(allProspectIds);

        final List<DES_Arc_ProspectController.WrapperService> wraps =
            new List<DES_Arc_ProspectController.WrapperService>();

        for (Account acc : accList) {
            // Prospect id = Salesforce Id without the 3-character object key prefix.
            acc.gf_customer_prospect_id__c = String.valueOf(acc.Id).substring(3);
            if (subsidiaryIds.contains(acc.Id)) {
                wraps.add(new DES_Arc_ProspectController.WrapperService(acc, '', true));
            }
        }

        update accList;

        if (!wraps.isEmpty()) {
            System.enqueueJob(new DES_ProspectCreateQueueable(wraps));
        }
    }

    /**
     * @description Manages AccountTeamMember records with the Global Banker role
     *              when the DES_Global_banker__c field is set or changes on prospect Accounts.
     *
     *              Handles four scenarios in a single bulkified operation:
     *              - Insert with banker set (null record → User): inserts a new AccountTeamMember.
     *              - Banker assigned on update (null → User): inserts a new AccountTeamMember.
     *              - Banker removed on update (User → null): deletes the existing AccountTeamMember.
     *              - Banker changed on update (User A → User B): deletes the old entry and inserts the new one.
     *
     *              Runs at most one SOQL query and two DML operations regardless of
     *              the number of accounts processed, complying with Salesforce governor limits.
     *
     * @param triggerNew   List of Account records in their new state (from Trigger.new).
     * @param oldAccounts  Map of Account records in their previous state (from Trigger.oldMap).
     *                     Pass null on insert context.
     */
    public static void assignAccountTeamMember(List<Account> triggerNew, Map<Id, Account> oldAccounts) {

        // Accounts whose existing Global Banker team member must be removed (update only)
        Set<Id> accountsToCleanBanker = new Set<Id>();

        // New DES_BBVA_Management_team__c records to insert after cleanup
        List<DES_BBVA_Management_team__c> membersToInsert = new List<DES_BBVA_Management_team__c>();

        for (Account eachAcc : triggerNew) {
            if (!isProspectRecord(eachAcc)) {
                continue;
            }

            Account oldAccount = oldAccounts != null ? oldAccounts.get(eachAcc.Id) : null;
            Boolean isUpdate = oldAccount != null;

            // On update: skip if the field has not changed
            if (isUpdate && eachAcc.DES_Global_banker__c == oldAccount.DES_Global_banker__c) {
                continue;
            }

            // On update: flag existing team member for deletion (covers A→null and A→B)
            if (isUpdate) {
                accountsToCleanBanker.add(eachAcc.Id);
            }

            // Both insert and update: create new management team record if a banker is assigned
            if (eachAcc.DES_Global_banker__c != null) {
                membersToInsert.add(new DES_BBVA_Management_team__c(
                    DES_Client__c              = eachAcc.Id,
                    DES_User__c               = eachAcc.DES_Global_banker__c,
                    DES_Member_Role__c        = DES_Constants.ROLE_GLOBAL_BANKER,
                    DES_Local_Banker_Country__c = DES_Constants.MANAGEMENT_TEAM_GLOBAL_COUNTRY
                ));
            }
        }

        deleteExistingGlobalBankerMembers(accountsToCleanBanker);

        if (!membersToInsert.isEmpty()) {
            insert membersToInsert;
        }
    }

    /**
     * @description Creates AMH_GBL_Account_Relationship__c records for newly inserted
     *              Prospect Subsidiary Accounts when a Prospect Group is selected as parent.
     *
     *              Business rule:
     *              - Child account: the newly created Prospect Subsidiary (its Id is used in AMH_Child_Account__c).
     *              - Parent account: the selected Group in participant_id__c, only if it is Prospect_Group
     *                (its Id is used in AMH_Parent_Account__c).
     *
     *              The relation fields AMH_Child_Account__r.g_customer_id__c and
     *              AMH_Parent_Account__r.DES_Group_Code__c are resolved from those lookup links.
     *
     *              Bulkified: performs one parent query and one insert DML for all valid rows.
     *
     * @param triggerNew List of Account records in insert context (Trigger.new).
     */
    public static void createProspectAccountRelationship(List<Account> triggerNew) {
        Map<String, Schema.RecordTypeInfo> accountRTs =
            Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();

        Schema.RecordTypeInfo subsidiaryRtInfo = accountRTs.get(DES_Constants.ACCOUNT_RT_PROSPECT_SUBSIDIARY);
        Schema.RecordTypeInfo groupRtInfo = accountRTs.get(DES_Constants.ACCOUNT_RT_PROSPECT_GROUP);

        if (subsidiaryRtInfo == null || groupRtInfo == null) {
            return;
        }

        Id subsidiaryRtId = subsidiaryRtInfo.getRecordTypeId();
        Id groupRtId = groupRtInfo.getRecordTypeId();

        Set<Id> parentCandidateIds = new Set<Id>();
        List<Account> subsidiaryCandidates = new List<Account>();

        for (Account eachAcc : triggerNew) {
            if (eachAcc.Id != null && eachAcc.RecordTypeId == subsidiaryRtId && eachAcc.participant_id__c != null) {
                subsidiaryCandidates.add(eachAcc);
                parentCandidateIds.add(eachAcc.participant_id__c);
            }
        }

        if (subsidiaryCandidates.isEmpty() || parentCandidateIds.isEmpty()) {
            return;
        }

        Map<Id, Account> parentGroupsById = new Map<Id, Account>([
            SELECT Id, RecordTypeId
            FROM Account
            WHERE Id IN :parentCandidateIds
        ]);

        List<AMH_GBL_Account_Relationship__c> relationshipsToInsert = new List<AMH_GBL_Account_Relationship__c>();

        for (Account subsidiaryAcc : subsidiaryCandidates) {
            Account selectedParent = parentGroupsById.get(subsidiaryAcc.participant_id__c);
            if (selectedParent != null && selectedParent.RecordTypeId == groupRtId) {
                relationshipsToInsert.add(new AMH_GBL_Account_Relationship__c(
                    AMH_Child_Account__c = subsidiaryAcc.Id,
                    AMH_Parent_Account__c = selectedParent.Id,
                    AMH_Vision__c = 'Negocio',
                    DES_Participacion__c = 100, 
                    AMH_Type__c = '03 - Filial', 
                    DES_Main_Parent__c = 'N'
                ));
                relationshipsToInsert.add(new AMH_GBL_Account_Relationship__c(
                    AMH_Child_Account__c = subsidiaryAcc.Id,
                    AMH_Parent_Account__c = selectedParent.Id,
                    AMH_Vision__c = 'Riesgos',
                    DES_Participacion__c = 100, 
                    AMH_Type__c = '03 - Filial', 
                    DES_Main_Parent__c = 'S'
                ));
            }
        }

        if (!relationshipsToInsert.isEmpty()) {
            insert relationshipsToInsert;
        }
    }

    /**
     * @description Returns whether the given Account has a prospect Record Type
     *              (Prospect_Group or Prospect_Subsidiary).
     *              Safe to call inside loops: Record Type Ids are resolved once
     *              per transaction and cached for subsequent calls.
     *
     * @param acc  Account record to evaluate.
     * @return     True if the Account's RecordTypeId is a prospect type, false otherwise.
     */
    public static Boolean isProspectRecord(Account acc) {
        return acc.RecordTypeId != null && getProspectRecordTypeIds().contains(acc.RecordTypeId);
    }

    /**
     * @description Returns whether the given Account has the prospect Record Type
     *              identified by the supplied developer name.
     *              Safe to call inside loops: Record Type Ids are resolved once
     *              per transaction and cached for subsequent calls.
     *
     * @param acc      Account record to evaluate.
     * @param devName  Developer name of the prospect Record Type to match
     *                 (e.g. DES_Constants.ACCOUNT_RT_PROSPECT_GROUP).
     * @return         True if the Account's RecordTypeId matches the given developer name, false otherwise.
     */
    public static Boolean isProspectRecord(Account acc, String devName) {
        if (acc.RecordTypeId == null) {
            return false;
        }
        getProspectRecordTypeIds();
        Id rtId = prospectRtByDevNameCache.get(devName);
        return rtId != null && acc.RecordTypeId == rtId;
    }

    /**
     * @description Resolves and returns the Set of Record Type Ids for prospect Account types
     *              (Prospect_Group and Prospect_Subsidiary).
     *              Result is cached after the first call within a transaction.
     *              Skips any developer name not found in the org's schema to avoid null-pointer errors.
     *
     * @return Set<Id> containing the Record Type Ids for Prospect_Group and Prospect_Subsidiary.
     */
    public static Set<Id> getProspectRecordTypeIds() {
        if (prospectRtByDevNameCache != null) {
            return new Set<Id>(prospectRtByDevNameCache.values());
        }

        Map<String, Schema.RecordTypeInfo> accountRTs =
            Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();

        prospectRtByDevNameCache = new Map<String, Id>();

        for (String devName : new Set<String>{
            DES_Constants.ACCOUNT_RT_PROSPECT_GROUP,
            DES_Constants.ACCOUNT_RT_PROSPECT_SUBSIDIARY
        }) {
            Schema.RecordTypeInfo rtInfo = accountRTs.get(devName);
            if (rtInfo != null) {
                prospectRtByDevNameCache.put(devName, rtInfo.getRecordTypeId());
            }
        }

        return new Set<Id>(prospectRtByDevNameCache.values());
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Private helpers
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * @description Queries and deletes all AccountTeamMember records with the
     *              Global Banker role for the given set of Account Ids.
     *              No-op when the input set is empty.
     *
     * @param accountIds  Set of Account Ids whose Global Banker team members should be removed.
     */
    private static void deleteExistingGlobalBankerMembers(Set<Id> accountIds) {
        if (accountIds.isEmpty()) {
            return;
        }

        List<DES_BBVA_Management_team__c> membersToDelete =
            DES_BBVAManagementTeamSelector.getByClientIdsAndRole(accountIds, DES_Constants.ROLE_GLOBAL_BANKER);

        if (!membersToDelete.isEmpty()) {
            DES_SystemDMLService.deleteRecords(membersToDelete);
        }
    }

    public static void populateProspectSubsidiaryCountryFromParent(List<Account> triggerNew) {
        Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId();
        Set<Id> parentIds = new Set<Id>();

        for (Account acc : triggerNew) {
            if (acc.RecordTypeId == subsidiaryRtId && acc.participant_id__c != null) {
                parentIds.add(acc.participant_id__c);
            }
        }

        if (parentIds.isEmpty()) {
            return;
        }

        Map<Id, Account> parentAccountsById = new Map<Id, Account>([
            SELECT Id, DES_Country_of_Management_OLD__c
            FROM Account
            WHERE Id IN :parentIds
        ]);

        for (Account acc : triggerNew) {
            if (acc.RecordTypeId == subsidiaryRtId && acc.participant_id__c != null) {
                Account parentAcc = parentAccountsById.get(acc.participant_id__c);
                // El país de gestión se hereda solo si viene vacío en la subsidiaria.
                if (String.isBlank(acc.DES_Country_of_Management_OLD__c) && parentAcc != null && String.isNotBlank(parentAcc.DES_Country_of_Management_OLD__c)) {
                    acc.DES_Country_of_Management_OLD__c = parentAcc.DES_Country_of_Management_OLD__c;
                }
            }
        }
    }

    public static void applyProspectCountryEntificPrefix(List<Account> triggerNew, Map<Id, Account> oldAccounts) {
        Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId();
        Map<String, String> countryToEntificMap = getCountryToEntificMap();
        System.debug(LoggingLevel.DEBUG, 'Country to Entific Map: ' + countryToEntificMap);
        if (!countryToEntificMap.isEmpty()) {
            System.debug(LoggingLevel.DEBUG, 'Processing accounts for country to entific mapping.');
            List<Account> recordsToUpdate = new List<Account>();

            for (Account acc : triggerNew) {
                if (acc.RecordTypeId != subsidiaryRtId ||
                    String.isBlank(acc.DES_Country_of_Management_OLD__c) || String.isBlank(acc.DES_Sequence__c) ||
                    (oldAccounts != null && oldAccounts.containsKey(acc.Id) &&
                    acc.DES_Country_of_Management_OLD__c == oldAccounts.get(acc.Id).DES_Country_of_Management_OLD__c)) {
                    continue;
                }
                String countryCode = acc.DES_Country_of_Management_OLD__c.trim().toUpperCase();
                String prefix = extractAlphabeticPrefix(countryToEntificMap.get(countryCode));
                System.debug(LoggingLevel.DEBUG, 'Processing account: ' + acc.Id + ', Country Code: ' + countryCode + ', Prefix: ' + prefix);
                if (String.isNotBlank(prefix)) {
                    if (Trigger.isAfter) {
                        // After insert: Trigger.new es read-only, se necesita DML explícito.
                        recordsToUpdate.add(new Account(Id = acc.Id, g_customer_id__c = prefix + 'P' + acc.DES_Sequence__c));
                    } else {
                        // Before update: modificación directa en memoria.
                        acc.g_customer_id__c = prefix + 'P' + acc.DES_Sequence__c;
                        System.debug(LoggingLevel.DEBUG, 'Updated account in before update context: ' + acc.Id + ', New g_customer_id__c: ' + acc.g_customer_id__c);
                    }
                }
            }

            if (!recordsToUpdate.isEmpty()) {
                update recordsToUpdate;
            }
        }
    }

    private static Map<String, String> getCountryToEntificMap() {
        if (Test.isRunningTest() && countryToEntificMapTestOverride != null) {
            return new Map<String, String>(countryToEntificMapTestOverride);
        }

        Map<String, String> countryToEntificMap = new Map<String, String>();

        for (DES_Country_Entific_Mapping__mdt row : [
            SELECT Country_Code__c, Entific__c
            FROM DES_Country_Entific_Mapping__mdt
        ]) {
            if (String.isNotBlank(row.Country_Code__c) && String.isNotBlank(row.Entific__c)) {
                countryToEntificMap.put(row.Country_Code__c.trim().toUpperCase(), row.Entific__c.trim());
            }
        }

        return countryToEntificMap;
    }

    private static String extractAlphabeticPrefix(String value) {
        if (String.isBlank(value)) {
            return '';
        }

        String trimmed = value.trim();
        String prefix = '';
        for (Integer i = 0; i < trimmed.length(); i++) {
            String character = trimmed.substring(i, i + 1);
            if ((character >= 'A' && character <= 'Z') || (character >= 'a' && character <= 'z')) {
                prefix += character.toUpperCase();
            } else {
                break;
            }
        }

        return prefix;
    }

}