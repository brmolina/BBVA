/**
 * _________________________________________________________________________________
 * @Name      DES_AccountTeamMemberSelectorTest
 * @Author    Borja Lorenzo Adajas
 * @Date      2026-05-18
 * ---------------------------------------------------------------------------------
 * @Description  Test class for DES_AccountTeamMemberSelector.
 *               Covers all three query methods with positive and negative paths.
 * ---------------------------------------------------------------------------------
 * @History
 * Version   Date            Author          Summary of changes
 * 1.0       2026-05-18      Borja Lorenzo   Initial version
 * _________________________________________________________________________________
 **/
@IsTest(testFor='ApexClass:DES_AccountTeamMemberSelector')
private class DES_AccountTeamMemberSelectorTest {

    // ──────────────────────────────────────────────────────────────────────────
    // Test data setup
    // ──────────────────────────────────────────────────────────────────────────

    @TestSetup
    static void makeData() {
        final DES_UtilTestClass util = new DES_UtilTestClass();
        final String profileId = util.createProfile();

        // Two users: one will be team member, the other will not
        final User banker = util.createUser(profileId, 'bankeruser@atm.test');
        final User otherUser = util.createUser(profileId, 'otheruser@atm.test');
        insert new List<User>{ banker, otherUser };

        final Account acc = util.createClient();
        insert acc;

        // Insert one team member with the Global Banker role
        insert new AccountTeamMember(
            AccountId    = acc.Id,
            UserId       = banker.Id,
            TeamMemberRole = Label.DES_ROLE_GLOBAL_BANKER
        );
    }

    // ──────────────────────────────────────────────────────────────────────────
    // getByAccountIdsAndRole
    // ──────────────────────────────────────────────────────────────────────────

    @IsTest
    static void getByAccountIdsAndRole_returnsFilteredResults() {
        // getByAccountIdsAndRole
        final Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        final List<AccountTeamMember> matchingRole = DES_AccountTeamMemberSelector.getByAccountIdsAndRole(
            new Set<Id>{ acc.Id },
            Label.DES_ROLE_GLOBAL_BANKER
        );
        final List<AccountTeamMember> differentRole = DES_AccountTeamMemberSelector.getByAccountIdsAndRole(
            new Set<Id>{ acc.Id },
            'Account Manager'
        );
        final List<AccountTeamMember> emptyIds = DES_AccountTeamMemberSelector.getByAccountIdsAndRole(
            new Set<Id>(),
            Label.DES_ROLE_GLOBAL_BANKER
        );
        Test.stopTest();

        System.assertEquals(1, matchingRole.size(),  'Debe retornar 1 miembro con rol Global Banker');
        System.assertEquals(0, differentRole.size(), 'No debe retornar registros para un rol diferente');
        System.assertEquals(0, emptyIds.size(),      'Conjunto vacío de IDs debe retornar lista vacía');
    }

    // ──────────────────────────────────────────────────────────────────────────
    // getByAccountIds
    // ──────────────────────────────────────────────────────────────────────────

    @IsTest
    static void getByAccountIds_returnsAccountMembers() {
        // getByAccountIds
        final Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        final List<AccountTeamMember> withMembers = DES_AccountTeamMemberSelector.getByAccountIds(
            new Set<Id>{ acc.Id }
        );
        final List<AccountTeamMember> emptyIds = DES_AccountTeamMemberSelector.getByAccountIds(
            new Set<Id>()
        );
        Test.stopTest();

        System.assertEquals(1, withMembers.size(),      'Debe retornar 1 miembro para la cuenta');
        System.assertNotEquals(null, withMembers[0].UserId,    'UserId debe estar informado');
        System.assertNotEquals(null, withMembers[0].AccountId, 'AccountId debe estar informado');
        System.assertEquals(0, emptyIds.size(),         'Conjunto vacío de IDs debe retornar lista vacía');
    }

    // ──────────────────────────────────────────────────────────────────────────
    // getByAccountIdsAndUserIds
    // ──────────────────────────────────────────────────────────────────────────

    @IsTest
    static void getByAccountIdsAndUserIds_returnsFilteredResults() {
        // getByAccountIdsAndUserIds
        final AccountTeamMember member = [SELECT AccountId, UserId FROM AccountTeamMember LIMIT 1];
        // Use a user that is NOT the team member
        final User otherUser = [SELECT Id FROM User WHERE Username LIKE '%otheruser@atm.test%' LIMIT 1];

        Test.startTest();
        final List<AccountTeamMember> matchingPair = DES_AccountTeamMemberSelector.getByAccountIdsAndUserIds(
            new Set<Id>{ member.AccountId },
            new Set<Id>{ member.UserId }
        );
        final List<AccountTeamMember> nonMemberUser = DES_AccountTeamMemberSelector.getByAccountIdsAndUserIds(
            new Set<Id>{ member.AccountId },
            new Set<Id>{ otherUser.Id }
        );
        final List<AccountTeamMember> emptyIds = DES_AccountTeamMemberSelector.getByAccountIdsAndUserIds(
            new Set<Id>(),
            new Set<Id>()
        );
        Test.stopTest();

        System.assertEquals(1, matchingPair.size(),   'Debe retornar 1 registro para el par (accountId, userId) correcto');
        System.assertEquals(0, nonMemberUser.size(),  'No debe retornar registros cuando el usuario no es miembro de esa cuenta');
        System.assertEquals(0, emptyIds.size(),       'Conjuntos vacíos deben retornar lista vacía');
    }
}