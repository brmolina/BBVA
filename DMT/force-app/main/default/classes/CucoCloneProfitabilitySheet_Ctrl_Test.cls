/**
* ────────────────────────────────────────────────────────────────────────────────────
* CucoCloneProfitabilitySheet_Ctrl_Test
* Test class for CucoCloneProfitabilitySheet_Ctrl apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-05-03
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@IsTest
public class CucoCloneProfitabilitySheet_Ctrl_Test {
    @TestSetup
    static void createData() {
        final User newUser = getNewUser();
        final Group group1 = new Group(Name = 'group name test');
        insert group1;
        System.runas(newUser) {
            final List<Account> lstGroupAccount = new List<Account>();
            final Account TestAccountParent = UnitTestUtils.GetStandardAccount();
            TestAccountParent.Name = 'Account Test Group 0';
            TestAccountParent.gf_branch_id__c = '3994';
            TestAccountParent.DES_Structure_Type__c = 'Group';
            TestAccountParent.DES_BBVA_Segmentation__c = 'C';
            lstGroupAccount.add(TestAccountParent);
            insert TestAccountParent;
            // insert account
            final List<Account> accounts = new List<Account>();
            final Account testAccount1 = UnitTestUtils.GetStandardAccount();
            testAccount1.ParentId = TestAccountParent.Id;
            testAccount1.Name = 'Account Test 1';
            testAccount1.gf_branch_id__c = '3994';
            testAccount1.DES_Structure_Type__c = 'Subsidiary';
            testAccount1.DES_BBVA_Segmentation__c = 'C';
            testAccount1.OwnerId = newUser.Id;
            accounts.add(testAccount1);
            // insert account
            final Account testAccount2 = UnitTestUtils.GetStandardAccount();
            testAccount2.ParentId = TestAccountParent.Id;
            testAccount2.Name = 'Account Test 2';
            testAccount2.gf_branch_id__c = '3994';
            testAccount2.DES_Structure_Type__c = 'Subsidiary';
            testAccount2.DES_BBVA_Segmentation__c = 'C';
            testAccount2.OwnerId = newUser.Id;
            accounts.add(testAccount2);
 			insert accounts;
            // insert prof sheets
            final List<cuco__profitability_sheet__c> profSheets = cuco.Test_Utils.createProfSheet(1, accounts[0]);
            profSheets[0].gf_branch_id__c = '3994';
            insert profSheets;
        }
    }
    private static User getNewUser() {
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final String profileTest = utilTestClass.createProfile();
        final User newUser = utilTestClass.createUser(profileTest);
        newUser.gf_manage_cuco__c = true;
        newUser.FederationIdentifier = 'XX00000';
        newUser.Username = 'testProfi@example.com';
        newUser.FirstName = 'firstName';
        newUser.LastName = 'profi';
        newUser.Email = 'testProfi@test.com';
        newUser.Alias = 'profi';
        newUser.TimeZoneSidKey='America/Los_Angeles';
        newUser.LocaleSidKey='en_US';
        newUser.EmailEncodingKey = 'UTF-8';
        newUser.LanguageLocaleKey='en_US';
        insert newUser;
        return newUser;
    }
    @IsTest
    static void testCloneFlatRates() {
        final User user = [SELECT Id FROM User WHERE FirstName = 'firstName' LIMIT 1];
        System.runas(user) {
            Test.startTest();
            final cuco__profitability_sheet__c  psInfo = [SELECT Id, cuco__participant_id__c FROM cuco__profitability_sheet__c LIMIT 1];
            Map<String, Object> retMap = CucoCloneProfitabilitySheet_Ctrl.clone('Test name', psInfo.Id, psInfo.cuco__participant_id__c, true, false);
            System.assertEquals(true, Boolean.valueOf(retMap.get('success').toString()), 'testCloneFlatRates - OK');
            Test.stopTest();
        }
    }
    @IsTest
    static void testCloneConditions() {
        final User user = [SELECT Id FROM User WHERE FirstName = 'firstName' LIMIT 1];
        System.runas(user) {
            Test.startTest();
            final cuco__profitability_sheet__c  psInfo = [SELECT Id, cuco__participant_id__c FROM cuco__profitability_sheet__c LIMIT 1];
            Map<String, Object> retMap = CucoCloneProfitabilitySheet_Ctrl.clone('Test name', psInfo.Id, psInfo.cuco__participant_id__c, false, true);
            System.assertEquals(true, Boolean.valueOf(retMap.get('success').toString()), 'testCloneConditions - OK');
            Test.stopTest();
        }
    }
    @IsTest
    static void testCloneErrorName() {
        final User user = [SELECT Id FROM User WHERE FirstName = 'firstName' LIMIT 1];
        System.runas(user) {
            Test.startTest();
            final cuco__profitability_sheet__c  psInfo = [SELECT Id, cuco__participant_id__c FROM cuco__profitability_sheet__c LIMIT 1];
            Map<String, Object> retMap = CucoCloneProfitabilitySheet_Ctrl.clone('', psInfo.Id, null, true, true);
            System.assertEquals(false, Boolean.valueOf(retMap.get('success').toString()), 'testCloneErrorName - OK');
            Test.stopTest();
        }
    }
}