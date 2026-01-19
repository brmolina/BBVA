/**
* ────────────────────────────────────────────────────────────────────────────────────
* CucoParticipantMove_Ctrl_Test
* Test class for CucoParticipantMove_Ctrl apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-06-13
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@IsTest
public class CucoParticipantMove_Ctrl_Test {
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
            // insert accounts
            final List<Account> accounts = new List<Account>();
            final Account testAccount1 = UnitTestUtils.GetStandardAccount();
            testAccount1.ParentId = TestAccountParent.Id;
            testAccount1.Name = 'Account Test 1';
            testAccount1.gf_branch_id__c = '3994';
            testAccount1.DES_Structure_Type__c = 'Subsidiary';
            testAccount1.DES_BBVA_Segmentation__c = 'C';
            testAccount1.OwnerId = newUser.Id;
            accounts.add(testAccount1);
            final Account testAccount2 = UnitTestUtils.GetStandardAccount();
            testAccount2.ParentId = TestAccountParent.Id;
            testAccount2.Name = 'Account Test 2';
            testAccount2.gf_branch_id__c = '3994';
            testAccount2.DES_Structure_Type__c = 'Subsidiary';
            testAccount2.DES_BBVA_Segmentation__c = 'C';
            testAccount2.OwnerId = newUser.Id;
            accounts.add(testAccount2);
            final Account testAccount3 = UnitTestUtils.GetStandardAccount();
            testAccount3.ParentId = TestAccountParent.Id;
            testAccount3.Name = 'Account Test 3';
            testAccount3.gf_branch_id__c = '3994';
            testAccount3.DES_Structure_Type__c = 'Subsidiary';
            testAccount3.DES_BBVA_Segmentation__c = 'C';
            testAccount3.OwnerId = newUser.Id;
            accounts.add(testAccount3);
 			insert accounts;
            // insert prof sheets
            final List<cuco__profitability_sheet__c> profSheets = cuco.Test_Utils.createProfSheet(1, accounts[0]);
            profSheets[0].gf_branch_id__c = '3994';
            profSheets[0].cuco__gf_prftbly_sheet_stt_type_name__c = '01';
            insert profSheets;
            //
            final cuco__profitability_sheet__c  profitabilitySheet = [SELECT Id FROM cuco__profitability_sheet__c LIMIT 1];
            final Map<String,Object> mapDetails = cuco.ProfitabilitySheet_Service.getProfSheetFullDetails(profitabilitySheet.Id);
            final cuco.ProfitabilitySheet_Wrapper wrapperInfo = (cuco.ProfitabilitySheet_Wrapper) mapDetails.get('profSheetDetails');
            final Map<String,Object> mapAnalysisFinal = cuco.Request_Helper.createProfAnalysis(wrapperInfo, 'Novation');
            final cuco__profitability_analysis__c  profitabilityAnalysis = [SELECT Id FROM cuco__profitability_analysis__c LIMIT 1];
            List<Id> lstAccs1 = new List<Id>();
			lstAccs1.add(testAccount1.Id);
            lstAccs1.add(testAccount2.Id);
            final Map<String,Object> retMap = cuco.Participants_Service.manageAddNewParticipants(profitabilityAnalysis.Id, lstAccs1);
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
    static void testPreviousChecksError() {
        final cuco__profitability_analysis_participant__c pAParticipant1 = [SELECT Id FROM cuco__profitability_analysis_participant__c LIMIT 1];
        Map<String, Object> retMap1 = CucoParticipantMove_Ctrl.removeParticipant(pAParticipant1.Id,'temporarily');
        final cuco__profitability_analysis_participant__c pAParticipant2 = [SELECT Id FROM cuco__profitability_analysis_participant__c LIMIT 1];
        Test.startTest();
        Map<String, Object> retMap2 = CucoParticipantMove_Ctrl.previousChecks(pAParticipant2.Id);
        System.assertEquals(true, Boolean.valueOf(retMap2.get('errorParticipants').toString()), 'testPreviousChecksError - OK');
        Test.stopTest();
    }
    @IsTest
    static void testPreviousChecks() {
        final cuco__profitability_sheet__c  profitabilitySheet = [SELECT Id FROM cuco__profitability_sheet__c LIMIT 1];
        final cuco__profitability_analysis__c  profitabilityAnalysis = [SELECT Id FROM cuco__profitability_analysis__c LIMIT 1];
        final cuco__profitability_analysis_participant__c pAParticipant = [SELECT Id, cuco__participant_id__c FROM cuco__profitability_analysis_participant__c LIMIT 1];
        final User user = [SELECT Id FROM User WHERE FirstName = 'firstName' LIMIT 1];
        System.runas(user) {
            Test.startTest();
            Map<String, Object> retMap = CucoParticipantMove_Ctrl.previousChecks(pAParticipant.Id);
            System.assertEquals(false, Boolean.valueOf(retMap.get('hasExtPkg').toString()), 'testPreviousChecks - OK');
            Test.stopTest();
        }
    }
    @IsTest
    static void testGetProfitabilitySheets() {
        final cuco__profitability_analysis_participant__c pAParticipant = [SELECT Id FROM cuco__profitability_analysis_participant__c LIMIT 1];
        Test.startTest();
        List<CucoParticipantMove_Ctrl.Move_Wrapper> profitabilitySheetList = CucoParticipantMove_Ctrl.getProfitabilitySheets(pAParticipant.Id);
        System.assertEquals(0, profitabilitySheetList.size(), 'testGetProfitabilitySheets - OK');
        Test.stopTest();
    }
    @IsTest
    static void testMoveParticipantCreate() {
        final cuco__profitability_sheet__c  profitabilitySheet = [SELECT Id FROM cuco__profitability_sheet__c LIMIT 1];
        final cuco__profitability_analysis__c  profitabilityAnalysis = [SELECT Id FROM cuco__profitability_analysis__c LIMIT 1];
        final cuco__profitability_analysis_participant__c pAParticipant = [SELECT Id, cuco__participant_id__c FROM cuco__profitability_analysis_participant__c LIMIT 1];
        final User user = [SELECT Id FROM User WHERE FirstName = 'firstName' LIMIT 1];
        System.runas(user) {
            Test.startTest();
            Map<String,Object> retMap = CucoParticipantMove_Ctrl.moveParticipant(true, false, 'Test Name', null, pAParticipant.Id, profitabilityAnalysis.Id, false, false, pAParticipant.cuco__participant_id__c);
            System.assertEquals(true, Boolean.valueOf(retMap.get('success').toString()), 'testMoveParticipantCreate - OK');
            Test.stopTest();
        }
    }
    @IsTest
    static void testAddParticipant() {
        final cuco__profitability_sheet__c  profitabilitySheet = [SELECT Id FROM cuco__profitability_sheet__c LIMIT 1];
        final cuco__profitability_analysis__c  profitabilityAnalysis = [SELECT Id FROM cuco__profitability_analysis__c LIMIT 1];
        final Account account = [SELECT Id FROM Account WHERE Name = 'Account Test 3' LIMIT 1];
        final User user = [SELECT Id FROM User WHERE FirstName = 'firstName' LIMIT 1];
        System.runas(user) {
            Test.startTest();
            Map<String,Object> retMap = CucoParticipantMove_Ctrl.addParticipant(profitabilitySheet.Id, account.Id, profitabilityAnalysis.Id);
            System.assertEquals(true, Boolean.valueOf(retMap.get('success').toString()), 'testAddParticipant - OK');
            Test.stopTest();
        }
    }
    @IsTest
    static void testFormalizationAnalysis() {
        final cuco__profitability_sheet__c  profitabilitySheet = [SELECT Id FROM cuco__profitability_sheet__c LIMIT 1];
        final cuco__profitability_analysis__c  profitabilityAnalysis = [SELECT Id FROM cuco__profitability_analysis__c LIMIT 1];
        final cuco__profitability_analysis_participant__c pAParticipant = [SELECT Id, cuco__participant_id__c FROM cuco__profitability_analysis_participant__c LIMIT 1];
        final User user = [SELECT Id FROM User WHERE FirstName = 'firstName' LIMIT 1];
        System.runas(user) {
            Test.startTest();
            Map<String, Object> retMap1 = CucoParticipantMove_Ctrl.removeParticipant(pAParticipant.Id,'temporarily');
            Map<String,Object> retMap2 = CucoParticipantMove_Ctrl.moveParticipant(true, false, 'Test Name', null, pAParticipant.Id, profitabilityAnalysis.Id, false, false, pAParticipant.cuco__participant_id__c);
            final cuco__profitability_analysis_participant__c pAParticipantNew = [SELECT Id FROM cuco__profitability_analysis_participant__c WHERE cuco__participant_id__c = :pAParticipant.cuco__participant_id__c];
            cuco.ProfitabilityAnalysis_Wrapper paWrapper = new cuco.ProfitabilityAnalysis_Wrapper();
            List<cuco.ProfitabilityAnalysis_Wrapper.Participants> participantsList = new List<cuco.ProfitabilityAnalysis_Wrapper.Participants>();
            cuco.ProfitabilityAnalysis_Wrapper.Participants participant = new cuco.ProfitabilityAnalysis_Wrapper.Participants();
            participant.Id = pAParticipantNew.Id;
            participantsList.add(participant);
            paWrapper.participantsList = participantsList;
            List<String> response = CucoValidationsCIB.checkParticipantMoved(paWrapper);
            System.assertEquals('null was moved from Novation - MOCK CC pricing conditions book request. Formalize it first.', response[0], 'testFormalizationAnalysis - OK');
            Test.stopTest();
        }
    }
    @IsTest
    static void testFormalizationDismissed() {
        final cuco__profitability_sheet__c  profitabilitySheet = [SELECT Id FROM cuco__profitability_sheet__c LIMIT 1];
        final cuco__profitability_analysis__c  profitabilityAnalysis = [SELECT Id, cuco__gf_pa_mgmt_stage_type_name__c FROM cuco__profitability_analysis__c LIMIT 1];
        final cuco__profitability_analysis_participant__c pAParticipant = [SELECT Id, cuco__participant_id__c FROM cuco__profitability_analysis_participant__c LIMIT 1];
        final User user = [SELECT Id FROM User WHERE FirstName = 'firstName' LIMIT 1];
        System.runas(user) {
            Test.startTest();
            Map<String, Object> retMap1 = CucoParticipantMove_Ctrl.removeParticipant(pAParticipant.Id,'temporarily');
            Map<String,Object> retMap2 = CucoParticipantMove_Ctrl.moveParticipant(true, false, 'Test Name', null, pAParticipant.Id, profitabilityAnalysis.Id, false, false, pAParticipant.cuco__participant_id__c);
            final cuco__profitability_analysis__c  profitabilityAnalysisUpdate = [SELECT Id, cuco__gf_pa_mgmt_stage_type_name__c FROM cuco__profitability_analysis__c WHERE Id = :profitabilityAnalysis.Id];
            profitabilityAnalysis.cuco__gf_pa_mgmt_stage_type_name__c = 'Dismissed';
            profitabilityAnalysis.cuco__gf_pa_mgmt_status_type_name__c = 'Dismissed';
            update profitabilityAnalysis;
            final cuco__profitability_analysis_participant__c pAParticipantNew = [SELECT Id FROM cuco__profitability_analysis_participant__c WHERE cuco__participant_id__c = :pAParticipant.cuco__participant_id__c];
            cuco.ProfitabilityAnalysis_Wrapper paWrapper = new cuco.ProfitabilityAnalysis_Wrapper();
            List<cuco.ProfitabilityAnalysis_Wrapper.Participants> participantsList = new List<cuco.ProfitabilityAnalysis_Wrapper.Participants>();
            cuco.ProfitabilityAnalysis_Wrapper.Participants participant = new cuco.ProfitabilityAnalysis_Wrapper.Participants();
            participant.Id = pAParticipantNew.Id;
            participantsList.add(participant);
            paWrapper.participantsList = participantsList;
            List<String> response = CucoValidationsCIB.checkParticipantMoved(paWrapper);
            System.assertEquals('null was moved from Novation - MOCK CC pricing conditions book that has been dismissed. Remove it before formalize.', response[0], 'testFormalizationDismissed - OK');
            Test.stopTest();
        }
    }
}