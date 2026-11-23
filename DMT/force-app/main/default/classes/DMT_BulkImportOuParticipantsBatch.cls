/**
 * @description CIBGLOBALD-4851 - Add OU (LWC dmt_bulk_import, button Add OU after Process): adds the users of one
 * Organisational Unit as Read/Write participants (DMT_TeamMember__c) of the lines of a Bulk Import load, plus each line's
 * owner. Separate from DMT_AssignParticipantsByUO (owner's OU on Line create, Opportunities), as agreed with Diego.
 * - OU users (writeUsersOfOu): User.IsActive and User.DES_LevelUO_10__c = OU code, with at least one role in
 *   User.DMT_User_Role__c (';' list) whose DES_User_Roles__mdt record (DES_Role_Developer_Name__c) has
 *   DES_Access_Level__c = 'Read/Write'. Same rule as DMT_Utils.hasWriteAccess; no role name is hardcoded.
 * - Participant: AccessLevel__c Edit, DMT_ApprovalEdit__c true (edit in approval and Closed Won), Team_Role__c User-Defined.
 *   Existing participant of that user on the line (every copy): Read -> Edit, All stays All, Approval Edit set to true.
 *   Other participants are not touched.
 * Batch over the lines (scope LINES_PER_CHUNK): an OU of ~25 users on hundreds of lines exceeds the 10,000 DML rows of
 * one transaction. Row failures are logged (DMT_LogExceptionPayload).
 */
public without sharing class DMT_BulkImportOuParticipantsBatch implements Database.Batchable<SObject> {

    public static final Integer LINES_PER_CHUNK = 20;
    private static final String ACCESS_EDIT     = 'Edit';
    private static final String ACCESS_READ     = 'Read';
    private static final String ROLE_USER_DEFINED = 'User-Defined';
    private static final String ROLE_ACCESS_READ_WRITE = 'Read/Write';

    private Set<Id> ouUserIds;
    private Set<String> lineIds;

    /**
     * @param ouUserIds users of the OU with a DMT Read/Write role (writeUsersOfOu)
     * @param lineIds   Line_Id__c of the lines of the load
     */
    public DMT_BulkImportOuParticipantsBatch(Set<Id> ouUserIds, Set<String> lineIds) {
        this.ouUserIds = ouUserIds;
        this.lineIds   = lineIds;
    }

    /**
     * @description CIBGLOBALD-4851 - Active users of the OU (User.DES_LevelUO_10__c) with at least one DMT role whose
     * DES_User_Roles__mdt access level is Read/Write.
     */
    public static Set<Id> writeUsersOfOu(String ouCode) {
        Set<String> writeRoles = writeRoleNames(); // CIBGLOBALD-4851
        Set<Id> userIds = new Set<Id>();
        for (User ouUser : [SELECT Id, DMT_User_Role__c FROM User WHERE IsActive = true AND DES_LevelUO_10__c = :ouCode]) {
            if (hasWriteRole(ouUser, writeRoles)) { // CIBGLOBALD-4851
                userIds.add(ouUser.Id);
            }
        }
        return userIds;
    }

    /**
     * @description CIBGLOBALD-4851 - OU search of the Add OU input (DMT_BulkImportController.searchOus): Read/Write users
     * (same rule as writeUsersOfOu) per OU, for the first maxOus OU codes in alphabetical order that match likePattern
     * and have at least one. Users are read sorted by OU, so the scan stops at the next OU and each count is complete.
     * @param likePattern SOQL LIKE pattern, the typed text already escaped, between '%' (contains)
     * @param maxOus      how many OUs to return
     */
    public static Map<String, Integer> writeUserCountByOu(String likePattern, Integer maxOus) {
        Set<String> writeRoles = writeRoleNames();
        Map<String, Integer> countByOu = new Map<String, Integer>();
        for (User ouUser : [SELECT DES_LevelUO_10__c, DMT_User_Role__c FROM User
                            WHERE IsActive = true AND DES_LevelUO_10__c LIKE :likePattern ORDER BY DES_LevelUO_10__c]) {
            if (!hasWriteRole(ouUser, writeRoles)) {
                continue;
            }
            String ouCode = ouUser.DES_LevelUO_10__c;
            if (!countByOu.containsKey(ouCode)) {
                if (countByOu.size() == maxOus) {
                    break;
                }
                countByOu.put(ouCode, 0);
            }
            countByOu.put(ouCode, countByOu.get(ouCode) + 1);
        }
        return countByOu;
    }

    // CIBGLOBALD-4851 - DMT roles whose DES_User_Roles__mdt access level is Read/Write
    private static Set<String> writeRoleNames() {
        Set<String> writeRoles = new Set<String>();
        for (DES_User_Roles__mdt role : [SELECT DES_Role_Developer_Name__c FROM DES_User_Roles__mdt
                                         WHERE DES_Access_Level__c = :ROLE_ACCESS_READ_WRITE]) {
            writeRoles.add(role.DES_Role_Developer_Name__c);
        }
        return writeRoles;
    }

    // CIBGLOBALD-4851 - the user has at least one of those roles (User.DMT_User_Role__c, ';' separated)
    private static Boolean hasWriteRole(User ouUser, Set<String> writeRoles) {
        if (String.isBlank(ouUser.DMT_User_Role__c)) {
            return false;
        }
        for (String role : DMT_Utils.splitString(ouUser.DMT_User_Role__c, ';')) {
            if (writeRoles.contains(role.trim())) {
                return true;
            }
        }
        return false;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Set<String> loadLineIds = lineIds;
        return Database.getQueryLocator([SELECT Id, OwnerId FROM DMT_Line__c WHERE Line_Id__c IN :loadLineIds]);
    }

    public void execute(Database.BatchableContext bc, List<DMT_Line__c> lines) {
        // Users per line: the OU users plus the line owner (a queue owner is not a user and is skipped)
        Map<Id, Set<Id>> userIdsByLineId = new Map<Id, Set<Id>>();
        Set<Id> allUserIds = new Set<Id>(ouUserIds);
        for (DMT_Line__c line : lines) {
            Set<Id> userIds = new Set<Id>(ouUserIds);
            if (line.OwnerId != null && line.OwnerId.getSObjectType() == User.SObjectType) {
                userIds.add(line.OwnerId);
                allUserIds.add(line.OwnerId);
            }
            userIdsByLineId.put(line.Id, userIds);
        }

        // Existing participants of those users on those lines, every copy (one line + user can have several rows)
        Map<String, List<DMT_TeamMember__c>> existingByKey = new Map<String, List<DMT_TeamMember__c>>();
        for (DMT_TeamMember__c member : [SELECT Id, Line__c, User__c, AccessLevel__c, DMT_ApprovalEdit__c FROM DMT_TeamMember__c
                                         WHERE Line__c IN :userIdsByLineId.keySet() AND User__c IN :allUserIds]) {
            String key = memberKey(member.Line__c, member.User__c);
            if (!existingByKey.containsKey(key)) {
                existingByKey.put(key, new List<DMT_TeamMember__c>());
            }
            existingByKey.get(key).add(member);
        }

        List<DMT_TeamMember__c> toInsert = new List<DMT_TeamMember__c>();
        List<DMT_TeamMember__c> toUpdate = new List<DMT_TeamMember__c>();
        for (Id lineId : userIdsByLineId.keySet()) {
            for (Id userId : userIdsByLineId.get(lineId)) {
                List<DMT_TeamMember__c> existing = existingByKey.get(memberKey(lineId, userId));
                if (existing == null) {
                    toInsert.add(new DMT_TeamMember__c(
                        Line__c = lineId, User__c = userId, AccessLevel__c = ACCESS_EDIT,
                        DMT_ApprovalEdit__c = true, Team_Role__c = ROLE_USER_DEFINED
                    ));
                    continue;
                }
                for (DMT_TeamMember__c member : existing) {
                    Boolean readOnly = member.AccessLevel__c == ACCESS_READ || String.isBlank(member.AccessLevel__c);
                    if (readOnly || member.DMT_ApprovalEdit__c != true) {
                        toUpdate.add(new DMT_TeamMember__c(
                            Id = member.Id, AccessLevel__c = readOnly ? ACCESS_EDIT : member.AccessLevel__c, DMT_ApprovalEdit__c = true
                        ));
                    }
                }
            }
        }
        logFailures(Database.insert(toInsert, false), 'insert');
        logFailures(Database.update(toUpdate, false), 'update');
        DMT_AsyncOrchestrator.flush();
    }

    public void finish(Database.BatchableContext bc) {
        return;
    }

    private static String memberKey(Id lineId, Id userId) {
        return String.valueOf(lineId) + ':' + String.valueOf(userId);
    }

    private static void logFailures(List<Database.SaveResult> results, String operation) {
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(
                    result.getErrors()[0].getMessage(), null, null, 'DmlException',
                    'DMT_BulkImportOuParticipantsBatch', 'execute ' + operation, 'DMT', 'DMT_TeamMember__c'
                ));
            }
        }
    }
}
