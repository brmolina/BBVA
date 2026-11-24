/**
 * @description CIBGLOBALD-4851 - Tests of Add OU: DMT_BulkImportOuParticipantsBatch and
 * DMT_BulkImportController.addOuParticipants. Data through DMT_UtilTestClass (DMT test architecture); the DMT roles are
 * read from DES_User_Roles__mdt, never hardcoded.
 */
@isTest
private class DMT_BulkImportOuParticipantsBatch_Test {

    private static final DMT_UtilTestClass DMT_UTIL = new DMT_UtilTestClass();
    private static final String OU_CODE    = 'T4851OU01';
    private static final String OTHER_OU   = 'T4851OU02';
    private static final String LINE_ONE   = 'TESTOU001';
    private static final String LINE_TWO   = 'TESTOU002';

    @TestSetup
    static void makeData() {
        String writeRole = [SELECT DES_Role_Developer_Name__c FROM DES_User_Roles__mdt WHERE DES_Access_Level__c = 'Read/Write' LIMIT 1].DES_Role_Developer_Name__c;
        String readRole  = [SELECT DES_Role_Developer_Name__c FROM DES_User_Roles__mdt WHERE DES_Access_Level__c = 'ReadOnly' LIMIT 1].DES_Role_Developer_Name__c;
        Id profileId = UserInfo.getProfileId();
        // Setup objects (User) and data in one test: inserted inside runAs to avoid mixed DML
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(runningUser) {
            insert new List<User>{
                buildOuUser(profileId, 'ouwriter', OU_CODE, 'Other Role;' + writeRole, true),
                buildOuUser(profileId, 'oureader', OU_CODE, readRole, true),
                buildOuUser(profileId, 'ouinact', OU_CODE, writeRole, false),
                buildOuUser(profileId, 'otherou', OTHER_OU, writeRole, true)
            };
        }
        DMT_Line__c lineOne = DMT_UTIL.createLineRecord(null, new Map<Schema.SObjectField, Object>{
            DMT_Line__c.Name => 'OU Line One', DMT_Line__c.Line_Id__c => LINE_ONE, DMT_Line__c.DMT_Origin__c => 'BulkImport'
        });
        DMT_Line__c lineTwo = DMT_UTIL.createLineRecord(null, new Map<Schema.SObjectField, Object>{
            DMT_Line__c.Name => 'OU Line Two', DMT_Line__c.Line_Id__c => LINE_TWO, DMT_Line__c.DMT_Origin__c => 'BulkImport'
        });
        // The OU writer is already a participant: Read on line one, Edit on line two, both without Approval Edit ('All'
        // cannot be created here: the share flow on DMT_TeamMember__c only accepts Read / Edit).
        // Built through DMT_UtilTestClass.buildTeamMemberRecord, one insert.
        Id writerId = [SELECT Id FROM User WHERE Alias = 'ouwriter' LIMIT 1].Id;
        insert new List<DMT_TeamMember__c>{
            DMT_UTIL.buildTeamMemberRecord(new Map<Schema.SObjectField, Object>{
                DMT_TeamMember__c.Line__c => lineOne.Id, DMT_TeamMember__c.User__c => writerId,
                DMT_TeamMember__c.AccessLevel__c => 'Read', DMT_TeamMember__c.DMT_ApprovalEdit__c => false
            }),
            DMT_UTIL.buildTeamMemberRecord(new Map<Schema.SObjectField, Object>{
                DMT_TeamMember__c.Line__c => lineTwo.Id, DMT_TeamMember__c.User__c => writerId,
                DMT_TeamMember__c.AccessLevel__c => 'Edit', DMT_TeamMember__c.DMT_ApprovalEdit__c => false
            })
        };
    }

    private static User buildOuUser(Id profileId, String alias, String ouCode, String roles, Boolean active) {
        return DMT_UTIL.buildUser(profileId, new Map<Schema.SObjectField, Object>{
            User.Alias              => alias,
            User.Username           => alias + '.cibglobald4851@test.bbva.com',
            User.Email              => alias + '@test.bbva.com',
            User.DES_LevelUO_10__c  => ouCode,
            User.DMT_User_Role__c   => roles,
            User.IsActive           => active
        });
    }

    private static Map<String, DMT_TeamMember__c> membersByLineAndAlias() {
        Map<String, DMT_TeamMember__c> result = new Map<String, DMT_TeamMember__c>();
        for (DMT_TeamMember__c member : [SELECT Line__r.Line_Id__c, User__r.Alias, User__c, AccessLevel__c, DMT_ApprovalEdit__c, Team_Role__c
                                         FROM DMT_TeamMember__c WHERE Line__r.Line_Id__c IN (:LINE_ONE, :LINE_TWO)]) {
            result.put(member.Line__r.Line_Id__c + ':' + (member.User__c == UserInfo.getUserId() ? 'owner' : member.User__r.Alias), member);
        }
        return result;
    }

    // Only active OU users with a Read/Write role are added; existing participants keep their row and get Approval Edit
    @isTest
    static void testAddsWriteUsersAndOwner() {
        Set<Id> ouUserIds = DMT_BulkImportOuParticipantsBatch.writeUsersOfOu(OU_CODE);
        Assert.areEqual(1, ouUserIds.size(), 'Only the active OU user with a Read/Write role');
        // Before the batch: the OU writer and the owner on both lines are missing (writer rows lack Edit / Approval Edit)
        Assert.areEqual(4, DMT_BulkImportController.countMissingOuParticipants(OU_CODE, new List<String>{ LINE_ONE, LINE_TWO }),
                        '2 users on 2 lines missing before the batch');

        Test.startTest();
            Database.executeBatch(new DMT_BulkImportOuParticipantsBatch(ouUserIds, new Set<String>{ LINE_ONE, LINE_TWO }), 200);
        Test.stopTest();

        Map<String, DMT_TeamMember__c> members = membersByLineAndAlias();
        Assert.areEqual('Edit', members.get(LINE_ONE + ':ouwriter').AccessLevel__c, 'Read becomes Edit');
        Assert.isTrue(members.get(LINE_ONE + ':ouwriter').DMT_ApprovalEdit__c, 'Approval Edit set on the existing row');
        Assert.areEqual('Edit', members.get(LINE_TWO + ':ouwriter').AccessLevel__c, 'Edit stays Edit');
        Assert.isTrue(members.get(LINE_TWO + ':ouwriter').DMT_ApprovalEdit__c, 'Approval Edit set on the existing Edit row');
        for (String lineId : new List<String>{ LINE_ONE, LINE_TWO }) {
            DMT_TeamMember__c owner = members.get(lineId + ':owner');
            Assert.isNotNull(owner, 'The line owner is always added');
            Assert.areEqual('Edit', owner.AccessLevel__c, 'New participant with Edit');
            Assert.isTrue(owner.DMT_ApprovalEdit__c, 'New participant with Approval Edit');
            Assert.areEqual('User-Defined', owner.Team_Role__c, 'New participant with Team Role User-Defined');
            Assert.isFalse(members.containsKey(lineId + ':oureader'), 'A read-only role is not added');
            Assert.isFalse(members.containsKey(lineId + ':ouinact'), 'An inactive user is not added');
            Assert.isFalse(members.containsKey(lineId + ':otherou'), 'A user of another OU is not added');
        }
        Assert.areEqual(4, [SELECT COUNT() FROM DMT_TeamMember__c WHERE Line__r.Line_Id__c IN (:LINE_ONE, :LINE_TWO)],
                        'No duplicate rows: 2 existing updated, 2 owners inserted');
        // The screen's final check (DMT_BulkImportController.countMissingOuParticipants): nothing missing
        Assert.areEqual(0, DMT_BulkImportController.countMissingOuParticipants(OU_CODE, new List<String>{ LINE_ONE, LINE_TWO }),
                        'Every OU user and owner is an Edit participant with Approval Edit');
    }

    // The button returns the distinct users added (OU users plus line owners) and launches the batch
    @isTest
    static void testControllerReturnsUserCount() {
        Test.startTest();
            Map<String, Object> added = DMT_BulkImportController.addOuParticipants(' ' + OU_CODE + ' ', new List<String>{ LINE_ONE, LINE_TWO });
        Test.stopTest();

        Assert.areEqual(2, added.get('users'), 'The OU writer and the owner of both lines');
        Assert.isNotNull(added.get('asyncJobId'), 'The batch job Id for the screen to follow');
        Assert.areEqual(4, [SELECT COUNT() FROM DMT_TeamMember__c WHERE Line__r.Line_Id__c IN (:LINE_ONE, :LINE_TWO)],
                        'The batch ran for the lines of the load');
    }

    // A blank OU or an OU without write users adds nothing and says why
    @isTest
    static void testControllerRejectsBlankAndEmptyOu() {
        List<String> messages = new List<String>();
        for (String ou : new List<String>{ '', 'NOUSERS99' }) {
            try {
                DMT_BulkImportController.addOuParticipants(ou, new List<String>{ LINE_ONE });
            } catch (AuraHandledException e) {
                messages.add(e.getMessage());
            }
        }
        Assert.areEqual(2, messages.size(), 'Both calls are rejected');
        Assert.areEqual(2, [SELECT COUNT() FROM DMT_TeamMember__c WHERE Line__r.Line_Id__c IN (:LINE_ONE, :LINE_TWO)],
                        'No participant added');
    }

    // OU search of the Add OU input: OUs containing the typed text that have Read/Write users, with how
    // many; nothing under 2 characters; LIKE wildcards typed are literal; the scan stops at the requested number of OUs
    @isTest
    static void testSearchOus() {
        Test.startTest();
            List<Map<String, Object>> found = DMT_BulkImportController.searchOus(' T4851OU ');
            List<Map<String, Object>> middle = DMT_BulkImportController.searchOus('851OU02');
            List<Map<String, Object>> tooShort = DMT_BulkImportController.searchOus('T');
            List<Map<String, Object>> wildcard = DMT_BulkImportController.searchOus('T4851%');
            Map<String, Integer> firstOnly = DMT_BulkImportOuParticipantsBatch.writeUserCountByOu('T4851OU%', 1);
        Test.stopTest();

        Assert.areEqual(2, found.size(), 'Both test OUs have a Read/Write user');
        Assert.areEqual(OU_CODE, found[0].get('code'), 'Sorted by OU code');
        Assert.areEqual(1, found[0].get('users'), 'Only the active writer: the reader and the inactive user are not added by Add OU');
        Assert.areEqual(OTHER_OU, found[1].get('code'), 'The second OU');
        Assert.areEqual(1, found[1].get('users'), 'Its writer');
        Assert.areEqual(1, middle.size(), 'Text in the middle of the code is found');
        Assert.areEqual(OTHER_OU, middle[0].get('code'), 'The OU that contains it');
        Assert.isTrue(tooShort.isEmpty(), 'No search under 2 characters');
        Assert.isTrue(wildcard.isEmpty(), 'A typed % is not a wildcard');
        Assert.areEqual(new Set<String>{ OU_CODE }, firstOnly.keySet(), 'Only the first OU when one is requested');
        Assert.areEqual(1, firstOnly.get(OU_CODE), 'Its count is complete');
    }
}
