/**
* ────────────────────────────────────────────────────────────────────
* Cuco Picasso Response Dispatcher CIB Test
* Test class of the PicasoResponseDispatcher_itf interface methods for CIB
* ────────────────────────────────────────────────────────────────────
* @author      Torcuato Tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2021-09-04
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
@SuppressWarnings('sf:TooManyMethods')
@IsTest
public class CucoPicassoResponseDispatcherCIB_Test {

    @TestSetup
    static void testSetup() {
        final User newUser = getNewUser();
        final Group group1 = new Group(Name = 'group name test');
        insert group1;

        System.runas(newUser) {

            final List<Account> lstGroupAccount = new List<Account>();
            final Account TestAccountParent = UnitTestUtils.GetStandardAccount();
            TestAccountParent.Name = 'Account Test Group 0';
            TestAccountParent.gf_branch_id__c = '3994';
            lstGroupAccount.add(TestAccountParent);
            insert TestAccountParent;

            // insert account
            final List<Account> accounts = new List<Account>();
            final Account testAccount1 = UnitTestUtils.GetStandardAccount();
            testAccount1.ParentId = TestAccountParent.Id;
            testAccount1.Name = 'Account Test 0';
            testAccount1.gf_branch_id__c = '3994';
            testAccount1.OwnerId = newUser.Id;
            accounts.add(testAccount1);

            // insert account
            final Account testAccount2 = UnitTestUtils.GetStandardAccount();
            testAccount2.ParentId = TestAccountParent.Id;
            testAccount2.Name = 'Account Test 1';
            testAccount2.gf_branch_id__c = '3994';
            testAccount2.OwnerId = newUser.Id;
            accounts.add(testAccount2);

            // insert account
            final Account testAccount3 = UnitTestUtils.GetStandardAccount();
            testAccount3.ParentId = TestAccountParent.Id;
            testAccount3.Name = 'Account Test 2';
            testAccount3.gf_branch_id__c = '3994';
            testAccount3.OwnerId = newUser.Id;
            accounts.add(testAccount3);

            // insert account
            final Account testAccount4 = UnitTestUtils.GetStandardAccount();
            testAccount4.ParentId = TestAccountParent.Id;
            testAccount4.Name = 'Account Test 3';
            testAccount4.gf_branch_id__c = '3994';
            testAccount4.OwnerId = newUser.Id;
            accounts.add(testAccount4);
            insert accounts;

            // insert prof sheets
            final List<cuco__profitability_sheet__c> profSheets = cuco.Test_Utils.createProfSheet(1, accounts[0]);
            profSheets[0].gf_branch_id__c = '3994';
            insert profSheets;

            final List<cuco__profitability_analysis__c> profAnalysis = getProfnalysis(accounts);
            insert profAnalysis;
            
            final List<cuco__profitability_analysis_participant__c> lstPAP = cuco.Test_Utils.createProfAnalysisParticipant(2, profAnalysis[3].Id, new List<Id>{accounts[0].Id,accounts[1].Id});
        	insert lstPAP;
        }
    }

    private static List<cuco__profitability_analysis__c> getProfnalysis(List<Account> accounts) {
        final List<cuco__profitability_analysis__c> profAnalysis = cuco.Test_Utils.createProfAnalysis(4, accounts);
        profAnalysis[0].cuco__gf_pa_management_type_name__c = 'Novation';
        profAnalysis[0].cuco__gf_pa_mgmt_stage_type_name__c = 'Analysis';
        profAnalysis[0].cuco__gf_pa_mgmt_status_type_name__c = 'Analysis';
        profAnalysis[1].cuco__gf_pa_management_type_name__c = 'Novation';
        profAnalysis[1].cuco__gf_pa_mgmt_stage_type_name__c = 'Analysis';
        profAnalysis[2].cuco__gf_pa_management_type_name__c = 'New';
        profAnalysis[2].cuco__gf_pa_mgmt_stage_type_name__c = 'Formalization';
        profAnalysis[3].cuco__gf_pa_management_type_name__c = 'New';
        profAnalysis[3].cuco__gf_pa_mgmt_stage_type_name__c = 'Formalization';
        profAnalysis[3].cuco__gf_pa_mgmt_status_type_name__c = 'Sent for Formalization';
        profAnalysis[3].cuco__gf_manl_formalization_req_id__c = 'ABC01';
        return profAnalysis;
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

    @isTest
    public static void setPicassoResponseTest() {
        test.startTest();

        final Id profAnalysisId = [SELECT Id  FROM cuco__profitability_analysis__c WHERE Name = 'Prof Analysis Test 0' LIMIT 1].Id;
        final cuco.PicassoResponse_Wrapper input = new cuco.PicassoResponse_Wrapper();
        input.externalId = profAnalysisId;
        input.channelId = '06';
        input.operationId = 'ABC01';

        final CucoPicassoResponseDispatcherCIB instance = new CucoPicassoResponseDispatcherCIB();
        final cuco.PicassoResponseError_Wrapper res = instance.setPicassoResponse(input);

        System.assertEquals(409, res.statusCode, 'Error at CucoPicassoResponseDispatcherCIB_Test - setPicassoResponseTest');
        test.stopTest();
    }

    @isTest
    public static void setPicassoResponseTest1() {
        test.startTest();

        final Id profAnalysisId = [SELECT Id  FROM cuco__profitability_analysis__c WHERE Name = 'Prof Analysis Test 0' LIMIT 1].Id;
        final cuco.PicassoResponse_Wrapper input = new cuco.PicassoResponse_Wrapper();
        input.externalId = profAnalysisId;
        input.channelId = '66';
        input.operationId = 'ABC01';

        final CucoPicassoResponseDispatcherCIB instance = new CucoPicassoResponseDispatcherCIB();
        final cuco.PicassoResponseError_Wrapper res = instance.setPicassoResponse(input);

        System.assertEquals(409, res.statusCode, 'Error at CucoPicassoResponseDispatcherCIB_Test - setPicassoResponseTest1');
        test.stopTest();
    }

    @isTest
    public static void setPicassoResponseTest2() {
        test.startTest();

        final Id profSheetId = [SELECT Id  FROM cuco__profitability_sheet__c WHERE Name = 'Prof Sheet Test 0' LIMIT 1].Id;
        final cuco.PicassoResponse_Wrapper input = new cuco.PicassoResponse_Wrapper();
        input.externalId = profSheetId;
        input.channelId = '06';
        input.operationId = 'ABC01';

        final CucoPicassoResponseDispatcherCIB instance = new CucoPicassoResponseDispatcherCIB();
        final cuco.PicassoResponseError_Wrapper res = instance.setPicassoResponse(input);

        System.assertEquals(409, res.statusCode, 'Error at CucoPicassoResponseDispatcherCIB_Test - setPicassoResponseTest2');
        test.stopTest();
    }

    @isTest
    public static void setPicassoResponseTest3() {
        test.startTest();

        final Id profAnalysisId = [SELECT Id  FROM cuco__profitability_analysis__c WHERE Name = 'Prof Analysis Test 3' LIMIT 1].Id;
        final cuco.PicassoResponse_Wrapper.Action action = new cuco.PicassoResponse_Wrapper.Action();
        action.id = '01';
        action.description = 'description here';
        action.source = '123';
        final cuco.PicassoResponse_Wrapper input = new cuco.PicassoResponse_Wrapper();
        input.externalId = profAnalysisId;
        input.channelId = '06';
        input.operationId = 'ABC01';
        input.action = action;

        final CucoPicassoResponseDispatcherCIB instance = new CucoPicassoResponseDispatcherCIB();
        final cuco.PicassoResponseError_Wrapper res = instance.setPicassoResponse(input);

        System.assertEquals(200, res.statusCode, 'Error at CucoPicassoResponseDispatcherCIB_Test - setPicassoResponseTest3');
        test.stopTest();
    }

    @isTest
    public static void setPicassoResponseTest31() {
        test.startTest();

        final Id profAnalysisId = [SELECT Id  FROM cuco__profitability_analysis__c WHERE Name = 'Prof Analysis Test 3' LIMIT 1].Id;
        final cuco.PicassoResponse_Wrapper.Action action = new cuco.PicassoResponse_Wrapper.Action();
        action.id = '01';
        action.description = 'description here';
        action.source = '123';
        final cuco.PicassoResponse_Wrapper input = new cuco.PicassoResponse_Wrapper();
        input.externalId = profAnalysisId;
        input.channelId = '66';
        input.operationId = 'ABC01';
        input.action = action;

        final CucoPicassoResponseDispatcherCIB instance = new CucoPicassoResponseDispatcherCIB();
        final cuco.PicassoResponseError_Wrapper res = instance.setPicassoResponse(input);

        System.assertEquals(409, res.statusCode, 'Error at CucoPicassoResponseDispatcherCIB_Test - setPicassoResponseTest31');
        test.stopTest();
    }

    @isTest
    public static void setPicassoResponseTest4() {
        test.startTest();

        final Id profAnalysisId = [SELECT Id  FROM cuco__profitability_analysis__c WHERE Name = 'Prof Analysis Test 3' LIMIT 1].Id;
        final cuco.PicassoResponse_Wrapper.Action action = new cuco.PicassoResponse_Wrapper.Action();
        action.id = '05';
        action.description = 'description here';
        action.source = '123';
        final cuco.PicassoResponse_Wrapper input = new cuco.PicassoResponse_Wrapper();
        input.externalId = profAnalysisId;
        input.channelId = '06';
        input.operationId = 'ABC01';
        input.action = action;

        final CucoPicassoResponseDispatcherCIB instance = new CucoPicassoResponseDispatcherCIB();
        final cuco.PicassoResponseError_Wrapper res = instance.setPicassoResponse(input);

        System.assertEquals(200, res.statusCode, 'Error at CucoPicassoResponseDispatcherCIB_Test - setPicassoResponseTest4');
        test.stopTest();
    }

    @isTest
    public static void setPicassoResponseTest41() {
        test.startTest();

        final Id profAnalysisId = [SELECT Id  FROM cuco__profitability_analysis__c WHERE Name = 'Prof Analysis Test 3' LIMIT 1].Id;
        final cuco.PicassoResponse_Wrapper.Action action = new cuco.PicassoResponse_Wrapper.Action();
        action.id = '02';
        action.description = 'description here';
        action.source = '123';
        final cuco.PicassoResponse_Wrapper input = new cuco.PicassoResponse_Wrapper();
        input.externalId = profAnalysisId;
        input.channelId = '06';
        input.operationId = 'ABC01';
        input.action = action;

        final CucoPicassoResponseDispatcherCIB instance = new CucoPicassoResponseDispatcherCIB();
        final cuco.PicassoResponseError_Wrapper res = instance.setPicassoResponse(input);

        System.assertEquals(200, res.statusCode, 'Error at CucoPicassoResponseDispatcherCIB_Test - setPicassoResponseTest41');
        test.stopTest();
    }

    @isTest
    public static void setPicassoResponseTest5() {
        test.startTest();

        final Id profAnalysisId = [SELECT Id  FROM cuco__profitability_analysis__c WHERE Name = 'Prof Analysis Test 3' LIMIT 1].Id;
        final cuco.PicassoResponse_Wrapper.Action action = new cuco.PicassoResponse_Wrapper.Action();
        action.id = '03';
        action.description = 'description here';
        action.source = '123';
        final cuco.PicassoResponse_Wrapper input = new cuco.PicassoResponse_Wrapper();
        input.externalId = profAnalysisId;
        input.channelId = '06';
        input.operationId = 'ABC01';
        input.action = action;

        final CucoPicassoResponseDispatcherCIB instance = new CucoPicassoResponseDispatcherCIB();
        final cuco.PicassoResponseError_Wrapper res = instance.setPicassoResponse(input);

        System.assertEquals(200, res.statusCode, 'Error at CucoPicassoResponseDispatcherCIB_Test - setPicassoResponseTest5');
        test.stopTest();
    }

    @isTest
    public static void setPicassoResponseTest6() {
        test.startTest();

        final Id profAnalysisId = [SELECT Id  FROM cuco__profitability_analysis__c WHERE Name = 'Prof Analysis Test 3' LIMIT 1].Id;
        final cuco.PicassoResponse_Wrapper.Action action = new cuco.PicassoResponse_Wrapper.Action();
        action.id = '03';
        action.description = 'description here';
        action.source = '123';
        final cuco.PicassoResponse_Wrapper input = new cuco.PicassoResponse_Wrapper();
        input.externalId = profAnalysisId;
        input.channelId = '06';
        input.operationId = 'ABC01';
        input.action = action;

        final CucoPicassoResponseDispatcherCIB instance = new CucoPicassoResponseDispatcherCIB();
        final cuco.PicassoResponseError_Wrapper res = instance.setPicassoResponse(input);

        System.assertEquals(200, res.statusCode, 'Error at CucoPicassoResponseDispatcherCIB_Test - setPicassoResponseTest6');
        test.stopTest();
    }

    @isTest
    public static void setPicassoResponseTest7() {
        test.startTest();

        final Id profAnalysisId = [SELECT Id  FROM cuco__profitability_analysis__c WHERE Name = 'Prof Analysis Test 3' LIMIT 1].Id;
        final cuco.PicassoResponse_Wrapper.Action action = new cuco.PicassoResponse_Wrapper.Action();
        action.id = '66';
        action.description = 'description here';
        action.source = '123';
        final cuco.PicassoResponse_Wrapper input = new cuco.PicassoResponse_Wrapper();
        input.externalId = profAnalysisId;
        input.channelId = '06';
        input.operationId = 'ABC01';
        input.action = action;

        final CucoPicassoResponseDispatcherCIB instance = new CucoPicassoResponseDispatcherCIB();
        final cuco.PicassoResponseError_Wrapper res = instance.setPicassoResponse(input);
        System.assertEquals(409, res.statusCode, 'Error at CucoPicassoResponseDispatcherCIB_Test - setPicassoResponseTest7');

        test.stopTest();
    }

    @isTest
    public static void setPicassoResponseTest8() {
        test.startTest();

        final Id profAnalysisId = [SELECT Id  FROM cuco__profitability_analysis__c WHERE Name = 'Prof Analysis Test 3' LIMIT 1].Id;
        final cuco.PicassoResponse_Wrapper.Action action = new cuco.PicassoResponse_Wrapper.Action();
        final cuco.PicassoResponse_Wrapper.Document doc1 = new cuco.PicassoResponse_Wrapper.Document();
        final cuco.PicassoResponse_Wrapper.Document doc2 = new cuco.PicassoResponse_Wrapper.Document();

        doc1.id = '123456789';
        doc1.name = 'test.doc';
        doc1.format = 'pdf';

        doc2.id = '123456798';
        doc2.name = 'test2.pdf';
        doc2.format = 'pdf';

        action.id = '06';
        action.description = 'description here';
        action.source = '123';

        final cuco.PicassoResponse_Wrapper input = new cuco.PicassoResponse_Wrapper();
        input.externalId = profAnalysisId;
        input.channelId = '06';
        input.operationId = 'ABC01';
        input.action = action;
        input.documents = new List<cuco.PicassoResponse_Wrapper.Document>{doc1, doc2};

        final CucoPicassoResponseDispatcherCIB instance = new CucoPicassoResponseDispatcherCIB();
        final cuco.PicassoResponseError_Wrapper res = instance.setPicassoResponse(input);

        System.assertEquals(200, res.statusCode, 'Error at CucoPicassoResponseDispatcherCIB_Test - setPicassoResponseTest8');
        test.stopTest();
    }

}