/**
 * @description Test class for DES_BBVAManagementTeamSelector.
 *              Each test inserts a DES_BBVA_Management_team__c record directly;
 *              the associated trigger fires normally as part of the test execution.
 * @author      Borja Lorenzo Adajas
 * @date        2026-05-22
 */
@IsTest(testFor='ApexClass:DES_BBVAManagementTeamSelector')
private class DES_BBVAManagementTeamSelectorTest {

    // ──────────────────────────────────────────────────────────────────────────
    // Test data setup
    // ──────────────────────────────────────────────────────────────────────────

    @TestSetup
    static void makeData() {
        final DES_UtilTestClass util = new DES_UtilTestClass();
        final String profileId = util.createProfile();

        final User banker = util.createUser(profileId, 'selector.banker@bbvamt.test');
        insert banker;

        final Account acc = util.createClient();
        insert acc;

        insert new DES_BBVA_Management_team__c(
            DES_Client__c               = acc.Id,
            DES_User__c                 = banker.Id,
            DES_Member_Role__c          = DES_Constants.ROLE_GLOBAL_BANKER,
            DES_Local_Banker_Country__c = DES_Constants.MANAGEMENT_TEAM_GLOBAL_COUNTRY
        );
    }

    // ──────────────────────────────────────────────────────────────────────────
    // getByClientIdsAndRole
    // ──────────────────────────────────────────────────────────────────────────

    @IsTest
    static void getByClientIdsAndRole_matchingClientAndRole_returnsRecord() {
        // getByClientIdsAndRole — client and role both match → record is returned
        // Arrange
        final Account acc = [SELECT Id FROM Account LIMIT 1];

        // Act
        Test.startTest();
        final List<DES_BBVA_Management_team__c> result =
            DES_BBVAManagementTeamSelector.getByClientIdsAndRole(
                new Set<Id>{ acc.Id },
                DES_Constants.ROLE_GLOBAL_BANKER
            );
        Test.stopTest();

        // Assert
        System.assertEquals(1, result.size(), 'One record should be returned when client and role both match');
    }

    @IsTest
    static void getByClientIdsAndRole_differentRole_returnsEmpty() {
        // getByClientIdsAndRole — client matches but role does not → no record returned
        // Arrange
        final Account acc = [SELECT Id FROM Account LIMIT 1];

        // Act
        Test.startTest();
        final List<DES_BBVA_Management_team__c> result =
            DES_BBVAManagementTeamSelector.getByClientIdsAndRole(
                new Set<Id>{ acc.Id },
                'Non_Matching_Role'
            );
        Test.stopTest();

        // Assert
        System.assertEquals(0, result.size(), 'No records should be returned when the role does not match');
    }

    @IsTest
    static void getByClientIdsAndRole_differentClientId_returnsEmpty() {
        // getByClientIdsAndRole — role matches but client does not → no record returned
        // Act
        Test.startTest();
        final List<DES_BBVA_Management_team__c> result =
            DES_BBVAManagementTeamSelector.getByClientIdsAndRole(
                new Set<Id>{ '001000000000000AAA' },
                DES_Constants.ROLE_GLOBAL_BANKER
            );
        Test.stopTest();

        // Assert
        System.assertEquals(0, result.size(), 'No records should be returned when the client Id does not match');
    }

    @IsTest
    static void getByClientIdsAndRole_emptyClientIds_returnsEmpty() {
        // getByClientIdsAndRole — empty client set → no records returned
        // Act
        Test.startTest();
        final List<DES_BBVA_Management_team__c> result =
            DES_BBVAManagementTeamSelector.getByClientIdsAndRole(
                new Set<Id>(),
                DES_Constants.ROLE_GLOBAL_BANKER
            );
        Test.stopTest();

        // Assert
        System.assertEquals(0, result.size(), 'No records should be returned when the client set is empty');
    }
}