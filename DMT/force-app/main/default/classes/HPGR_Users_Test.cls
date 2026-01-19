/*-------------------------------------------------------------------------------------------
* @Name     HPGR_Users_Test
* @Author   torcuato.tejada.tech@bbva.com
*           cosme.alcazar.tech@bbva.com
* @Date     Created: 2024-07-18
* -------------------------------------------------------------------------------------------
* @Description Test class for 'HPGR_Users' apex class
* -------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class HPGR_Users_Test {

    static final String USER_USERNAME = 'testUser@hpgr.com';
    static final String PROFILE_STANDARD_USER = 'Standard User';
    static final String GCE_PERMISSION_SET = 'global_clients_exposure';
    static final String GCE_RISK_PERMISSION_SET = 'global_clients_exposure_risk';
    static final String GCE_ADMIN_PERMISSION_SET = 'global_clients_exposure_admin';
    static final String EXTERNAL_APP_ACCESS_PERMISSION_SET = 'DMT_Access';
    static final String COUNTRY_CODE_ESP = 'ESP';

    @testSetup
    static void setupTestData() {
        Double random = Math.random();
        String username = USER_USERNAME;
        String profilename = PROFILE_STANDARD_USER;
        final Profile prof = [SELECT Id FROM Profile WHERE Name = :profilename];
        final User testUser = new User(
            FederationIdentifier = 'X000000',
            Username = username,
            FirstName = 'HpgrTestName',
            LastName = 'HpgrTestLastName',
            Email = username,
            Alias = 'testuser',
            TimeZoneSidKey='America/Los_Angeles',
            LocaleSidKey='en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = prof.Id,
            LanguageLocaleKey='en_US'
        );
        testUser.ID_User__c = 'Hpgr' + userName.substring(0, 3) + String.valueOf(random).substring(0, 3);
        testUser.DES_Country__c = COUNTRY_CODE_ESP;
        insert testUser;
    }

    @isTest
    static void isHpgrUserTest() {
        User testUser = [SELECT Id FROM User WHERE Username = :USER_USERNAME];
        hpgr.Test_Utils.assignPermissionSet(GCE_PERMISSION_SET, testUser.Id);
        Test.startTest();
            System.runAs(testUser) {
                HPGR_Users hpgrUsers = new HPGR_Users();
                Boolean isHpgrUser = hpgrUsers.isHpgrUser();
                system.assertEquals(true, isHpgrUser, 'isHpgrUserTest - Not passed - isHpgrUser');
            }
        Test.stopTest();
    }

    @isTest
    static void isExternalAppUserTest() {
        User testUser = [SELECT Id FROM User WHERE Username = :USER_USERNAME];
        hpgr.Test_Utils.assignPermissionSet(EXTERNAL_APP_ACCESS_PERMISSION_SET, testUser.Id);
        Test.startTest();
            System.runAs(testUser) {
                HPGR_Users hpgrUsers = new HPGR_Users();
                Boolean isExternalAppUser = hpgrUsers.isExternalAppUser();
                system.assertEquals(true, isExternalAppUser, 'isExternalAppUserTest - Not passed - isExternalAppUser');
            }
        Test.stopTest();
    }

    @isTest
    static void isAdminTest() {
        User testUser = [SELECT Id FROM User WHERE Username = :USER_USERNAME];
        hpgr.Test_Utils.assignPermissionSet(GCE_ADMIN_PERMISSION_SET, testUser.Id);
        Test.startTest();
            System.runAs(testUser) {
                HPGR_Users hpgrUsers = new HPGR_Users();
                Boolean isAdmin = hpgrUsers.isAdmin();
                system.assertEquals(true, isAdmin, 'isAdminTest - Not passed - isAdmin');
            }
        Test.stopTest();
    }

    @isTest
    static void isRiskUserTest() {
        User testUser = [SELECT Id FROM User WHERE Username = :USER_USERNAME];
        hpgr.Test_Utils.assignPermissionSet(GCE_RISK_PERMISSION_SET, testUser.Id);
        Test.startTest();
            System.runAs(testUser) {
                HPGR_Users hpgrUsers = new HPGR_Users();
                Boolean isRiskUser = hpgrUsers.isRiskUser();
                system.assertEquals(true, isRiskUser, 'isRiskUserTest - Not passed - isRiskUser');
            }
        Test.stopTest();
    }

    @isTest
    static void canManageOverridesTest() {
        User testUser = [SELECT Id FROM User WHERE Username = :USER_USERNAME];
        hpgr.Test_Utils.assignPermissionSet(GCE_RISK_PERMISSION_SET, testUser.Id);
        Test.startTest();
            System.runAs(testUser) {
                HPGR_Users hpgrUsers = new HPGR_Users();
                Boolean canManageOverrides = hpgrUsers.canManageOverrides();
                system.assertEquals(true, canManageOverrides, 'canManageOverridesTest - Not passed - canManageOverrides');
            }
        Test.stopTest();
    }

    @isTest
    static void canDownloadCsvTest() {
        User testUser = [SELECT Id FROM User WHERE Username = :USER_USERNAME];
        hpgr.Test_Utils.assignPermissionSet(GCE_RISK_PERMISSION_SET, testUser.Id);
        Test.startTest();
            System.runAs(testUser) {
                HPGR_Users hpgrUsers = new HPGR_Users();
                Boolean canDownloadCsv = hpgrUsers.canDownloadCsv();
                system.assertEquals(true, canDownloadCsv, 'canDownloadCsvTest - Not passed - canDownloadCsv');
            }
        Test.stopTest();
    }

    @isTest
    static void getUserCountryTest() {
        User testUser = [SELECT Id FROM User WHERE Username = :USER_USERNAME];
        Test.startTest();
            System.runAs(testUser) {
                HPGR_Users hpgrUsers = new HPGR_Users();
                String userCountry = hpgrUsers.getUserCountry();
                system.assertEquals(COUNTRY_CODE_ESP, userCountry, 'getUserCountryTest - Not passed - userCountry');
            }
        Test.stopTest();
    }

    @isTest
    static void canReassignContractsTest() {
        User testUser = [SELECT Id FROM User WHERE Username = :USER_USERNAME];
        hpgr.Test_Utils.assignPermissionSet(GCE_RISK_PERMISSION_SET, testUser.Id);
        Test.startTest();
            System.runAs(testUser) {
                HPGR_Users hpgrUsers = new HPGR_Users();
                Boolean canReassignContracts = hpgrUsers.canReassignContracts();
                system.assertEquals(true, canReassignContracts, 'canReassignContractsTest - Not passed - canReassignContracts');
            }
        Test.stopTest();
    }

    @isTest
    static void canShowCapitalAndProvisionTab() {
        User testUser = [SELECT Id FROM User WHERE Username = :USER_USERNAME];
        hpgr.Test_Utils.assignPermissionSet(GCE_RISK_PERMISSION_SET, testUser.Id);
        Test.startTest();
            System.runAs(testUser) {
                HPGR_Users hpgrUsers = new HPGR_Users();
                Boolean canShowCapitalAndProvisionTab = hpgrUsers.canShowCapitalAndProvisionTab();
                system.assertEquals(true, canShowCapitalAndProvisionTab, 'canShowCapitalAndProvisionTabTest - Not passed - canShowCapitalAndProvisionTab');
            }
        Test.stopTest();
    }

    @isTest
    static void canShowConnectedClientsTab() {
        User testUser = [SELECT Id FROM User WHERE Username = :USER_USERNAME];
        hpgr.Test_Utils.assignPermissionSet(GCE_RISK_PERMISSION_SET, testUser.Id);
        Test.startTest();
            System.runAs(testUser) {
                HPGR_Users hpgrUsers = new HPGR_Users();
                Boolean canShowConnectedClientsTab = hpgrUsers.canShowConnectedClientsTab();
                system.assertEquals(true, canShowConnectedClientsTab, 'canShowConnectedClientsTabTest - Not passed - canShowConnectedClientsTab');
            }
        Test.stopTest();
    }

    @isTest
    static void canShowDataReportTab() {
        User testUser = [SELECT Id FROM User WHERE Username = :USER_USERNAME];
        hpgr.Test_Utils.assignPermissionSet(GCE_RISK_PERMISSION_SET, testUser.Id);
        Test.startTest();
            System.runAs(testUser) {
                HPGR_Users hpgrUsers = new HPGR_Users();
                Boolean canShowDataReportTab = hpgrUsers.canShowDataReportTab();
                system.assertEquals(true, canShowDataReportTab, 'canShowDataReportTabTest - Not passed - canShowDataReportTab');
            }
        Test.stopTest();
    }

    @isTest
    static void canShowConsumptionOverrideTab() {
        User testUser = [SELECT Id FROM User WHERE Username = :USER_USERNAME];
        hpgr.Test_Utils.assignPermissionSet(GCE_RISK_PERMISSION_SET, testUser.Id);
        Test.startTest();
            System.runAs(testUser) {
                HPGR_Users hpgrUsers = new HPGR_Users();
                Boolean canShowConsumptionOverrideTab = hpgrUsers.canShowConsumptionOverrideTab();
                system.assertEquals(true, canShowConsumptionOverrideTab, 'canShowConsumptionOverrideTabTest - Not passed - canShowConsumptionOverrideTab');
            }
        Test.stopTest();
    }

    @isTest
    static void canShowApprovalsTabTest() {
        User testUser = [SELECT Id FROM User WHERE Username = :USER_USERNAME];
        hpgr.Test_Utils.assignPermissionSet(GCE_RISK_PERMISSION_SET, testUser.Id);
        Test.startTest();
            System.runAs(testUser) {
                HPGR_Users hpgrUsers = new HPGR_Users();
                Boolean canShowApprovalsTab = hpgrUsers.canShowApprovalsTab();
                system.assertEquals(true, canShowApprovalsTab, 'canShowApprovalsTabTest - Not passed - canShowApprovalsTab');
            }
        Test.stopTest();
    }

    @isTest
    static void canShowCapitalProvisionSummaryTab() {
        User testUser = [SELECT Id FROM User WHERE Username = :USER_USERNAME];
        hpgr.Test_Utils.assignPermissionSet(GCE_RISK_PERMISSION_SET, testUser.Id);
        Test.startTest();
            System.runAs(testUser) {
                HPGR_Users hpgrUsers = new HPGR_Users();
                Boolean canShowCapitalProvisionSummaryTab = hpgrUsers.canShowCapitalProvisionSummaryTab();
                system.assertEquals(true, canShowCapitalProvisionSummaryTab, 'canShowCapitalProvisionSummaryTabTest - Not passed - canShowCapitalProvisionSummaryTab');
            }
        Test.stopTest();
    }

    @isTest
    static void canShowRiskPolicySummaryTabTest() {
        User testUser = [SELECT Id FROM User WHERE Username = :USER_USERNAME];
        hpgr.Test_Utils.assignPermissionSet(GCE_RISK_PERMISSION_SET, testUser.Id);
        Test.startTest();
            System.runAs(testUser) {
                HPGR_Users hpgrUsers = new HPGR_Users();
                Boolean canShowRiskPolicySummaryTab = hpgrUsers.canShowRiskPolicySummaryTab();
                system.assertEquals(true, canShowRiskPolicySummaryTab, 'canShowRiskPolicySummaryTabTest - Not passed - canShowRiskPolicySummaryTab');
            }
        Test.stopTest();
    }

    @isTest
    static void canShowLimitsSummaryTab() {
        User testUser = [SELECT Id FROM User WHERE Username = :USER_USERNAME];
        hpgr.Test_Utils.assignPermissionSet(GCE_RISK_PERMISSION_SET, testUser.Id);
        Test.startTest();
            System.runAs(testUser) {
                HPGR_Users hpgrUsers = new HPGR_Users();
                Boolean canShowLimitsSummaryTab = hpgrUsers.canShowLimitsSummaryTab();
                system.assertEquals(true, canShowLimitsSummaryTab, 'canShowLimitsSummaryTabTest - Not passed - canShowLimitsSummaryTab');
            }
        Test.stopTest();
    }

    @isTest
    static void canRefreshApprovalsTest() {
        User testUser = [SELECT Id FROM User WHERE Username = :USER_USERNAME];
        hpgr.Test_Utils.assignPermissionSet(GCE_RISK_PERMISSION_SET, testUser.Id);
        Test.startTest();
            System.runAs(testUser) {
                HPGR_Users hpgrUsers = new HPGR_Users();
                Boolean canRefreshApprovals = hpgrUsers.canRefreshApprovals();
                system.assertEquals(true, canRefreshApprovals, 'canRefreshApprovalsTest - Not passed - canRefreshApprovals');
            }
        Test.stopTest();
    }
}