/**
* ────────────────────────────────────────────────────────────────────
* Cuco Profitability Anlaysis CIB Test
* Test class of the ProfitabilityAnalysis_Itf interface methods for CIB
* ────────────────────────────────────────────────────────────────────
* @author      Torcuato Tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2021-08-26
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
@SuppressWarnings('sf:TooManyMethods')
@IsTest
public class CucoProfitabilityAnalysisCIB_Test {

    /** @description branchCode */
    static final String BRANCHCODE = '';
    /** @description usercode */
    static final String USERCODE = '';
    /** @description screenShot */
    static final String SCREENSHOT_NEW = '<div class="slds-modal__content slds-p-around_xx-large"></div>';

    @TestSetup
    static void makeDataOfCucoProfitabilityAnalysisCIB() {

        final User newUser = getNewUser();

        final Group group1 = new Group(Name = 'group name test');
        insert group1;

        System.runas(newUser) {

            final List<Account> lstGroupAccount = new List<Account>();
            final Account TestAccountParent = UnitTestUtils.GetStandardAccount();
            TestAccountParent.Client_STAR_ID__c = '1';
            TestAccountParent.Name = 'Account Test Group 0';
            TestAccountParent.gf_branch_id__c = '3994';
            TestAccountParent.DES_Structure_Type__c = 'Group';
            TestAccountParent.DES_BBVA_Segmentation__c = 'C';
            lstGroupAccount.add(TestAccountParent);
            insert TestAccountParent;

            // insert account
            final List<Account> accounts = new List<Account>();
            final Account testAccount1 = UnitTestUtils.GetStandardAccount();
            testAccount1.Client_STAR_ID__c = '2';
            testAccount1.ParentId = TestAccountParent.Id;
            testAccount1.Name = 'Account Test 0';
            testAccount1.gf_branch_id__c = '3994';
            testAccount1.DES_Structure_Type__c = 'Subsidiary';
            testAccount1.DES_BBVA_Segmentation__c = 'C';
            testAccount1.OwnerId = newUser.Id;
            accounts.add(testAccount1);

            // insert account
            final Account testAccount2 = UnitTestUtils.GetStandardAccount();
            testAccount2.Client_STAR_ID__c = '3';
            testAccount2.ParentId = TestAccountParent.Id;
            testAccount2.Name = 'Account Test 1';
            testAccount2.gf_branch_id__c = '3994';
            testAccount2.DES_Structure_Type__c = 'Subsidiary';
            testAccount2.DES_BBVA_Segmentation__c = 'C';
            testAccount2.OwnerId = newUser.Id;
            accounts.add(testAccount2);

            // insert account
            final Account testAccount3 = UnitTestUtils.GetStandardAccount();
            testAccount3.Client_STAR_ID__c = '4';
            testAccount3.ParentId = TestAccountParent.Id;
            testAccount3.Name = 'Account Test 2';
            testAccount3.gf_branch_id__c = '3994';
            testAccount3.DES_Structure_Type__c = 'Subsidiary';
            testAccount3.DES_BBVA_Segmentation__c = 'C';
            testAccount3.OwnerId = newUser.Id;
            accounts.add(testAccount3);

            // insert account
            final Account testAccount4 = UnitTestUtils.GetStandardAccount();
            testAccount4.ParentId = TestAccountParent.Id;
            testAccount4.Client_STAR_ID__c = '5';
            testAccount4.Name = 'Account Test 3';
            testAccount4.gf_branch_id__c = '3994';
            testAccount4.DES_Structure_Type__c = 'Subsidiary';
            testAccount4.DES_BBVA_Segmentation__c = 'C';
            testAccount4.OwnerId = newUser.Id;
            accounts.add(testAccount4);

            // insert account
            final Account testAccount5 = UnitTestUtils.GetStandardAccount();
            testAccount5.Name = 'Account Orphan 1';
            testAccount5.Client_STAR_ID__c = '6';
            testAccount5.gf_branch_id__c = '3994';
            testAccount5.Sic = '3994';
            testAccount5.DES_Structure_Type__c = 'Subsidiary';
            testAccount5.DES_BBVA_Segmentation__c = 'B';
            testAccount5.OwnerId = newUser.Id;
            accounts.add(testAccount5);
 			insert accounts;

            // insert prof sheets
            final List<cuco__profitability_sheet__c> profSheets = cuco.Test_Utils.createProfSheet(1, accounts[0]);
            profSheets[0].gf_branch_id__c = '3994';
            insert profSheets;

            final List<cuco__profitability_analysis__c> profAnalysis = getProfnalysis(accounts);
            insert profAnalysis;
        }
    }

    private static List<cuco__profitability_analysis__c> getProfnalysis(List<Account> accounts) {
        final List<cuco__profitability_analysis__c> profAnalysis = cuco.Test_Utils.createProfAnalysis(5, accounts);
        profAnalysis[0].cuco__gf_pa_management_type_name__c = 'Novation';
        profAnalysis[0].cuco__gf_pa_mgmt_stage_type_name__c = 'Analysis';
        profAnalysis[0].cuco__gf_pa_mgmt_status_type_name__c = 'Analysis';
        profAnalysis[1].cuco__gf_pa_management_type_name__c = 'Novation';
        profAnalysis[1].cuco__gf_pa_mgmt_stage_type_name__c = 'Analysis';
        profAnalysis[2].cuco__gf_pa_management_type_name__c = 'New';
        profAnalysis[2].cuco__gf_pa_mgmt_stage_type_name__c = 'Formalization';
        profAnalysis[3].cuco__gf_pa_management_type_name__c = 'Novation';
        profAnalysis[3].cuco__gf_pa_mgmt_stage_type_name__c = 'Formalization';
        profAnalysis[3].cuco__gf_pa_mgmt_status_type_name__c = 'Sent for Formalization';
        profAnalysis[3].cuco__gf_manl_formalization_req_id__c = 'Manual Req Id';
        profAnalysis[4].cuco__gf_pa_management_type_name__c = 'Novation';
        profAnalysis[4].cuco__gf_pa_mgmt_stage_type_name__c = 'Analysis';
        profAnalysis[4].cuco__gf_pa_mgmt_status_type_name__c = 'Analysis';
        profAnalysis[4].gf_branch_id__c = '3994';
        profAnalysis[4].cuco__segment_type__c = 'BEC';

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

    @IsTest
    static void getUserCode1() {
        Test.startTest();
            final User federation = [SELECT id, FederationIdentifier FROM User WHERE LastName =: 'profi' LIMIT 1];
            final CucoProfitabilityAnalysisCIB profitaSample = new CucoProfitabilityAnalysisCIB();
            final String actualValue = profitaSample.getUserCode(federation.id);
            System.assertEquals(federation.FederationIdentifier, actualValue, 'Error at CucoProfitabilityAnalysisCIB_Test getUserCode1');
        Test.stopTest();
    }

    @IsTest
    static void setPADefaultCreationData() {
        Test.startTest();

        final List<Account> lstAcc = [SELECT Id, Name FROM Account WHERE Name = 'Account Test Group 0' LIMIT 1];
        final cuco__profitability_analysis__c paNew = new cuco__profitability_analysis__c();
        paNew.name = 'test1';
        paNew.cuco__participant_id__c = lstAcc[0].Id;
        paNew.cuco__gf_pa_management_type_name__c ='New';
        paNew.cuco__gf_pa_mgmt_stage_type_name__c ='Analysis';
        paNew.cuco__gf_pa_mgmt_status_type_name__c ='Analysis';

        insert paNew;
        final CucoProfitabilityAnalysisCIB profitaSample = new CucoProfitabilityAnalysisCIB();
        final cuco__profitability_analysis__c actualValue = profitaSample.setPADefaultCreationData(paNew);
        System.assertEquals(actualValue, actualValue, 'Error at CucoProfitabilityAnalysisCIB_Test setPADefaultCreationData');
        Test.stopTest();
    }

    @IsTest
    static void getUserId1() {
        Test.startTest();
            final User userInfo = [SELECT Id, FederationIdentifier FROM User WHERE LastName =: 'profi' LIMIT 1];
            final CucoProfitabilityAnalysisCIB instance = new CucoProfitabilityAnalysisCIB();
            final Id userId = instance.getUserId(userInfo.FederationIdentifier);
            System.assertEquals(userInfo.Id, userId, 'Error at CucoProfitabilityAnalysisCIB_Test getUserId1. Expected: ' + userInfo.Id + ' got: ' + userId);
        Test.stopTest();
    }

    @IsTest
    static void getBranchCode1() {
        Test.startTest();
            final cuco__profitability_analysis__c paInfo = [SELECT Id, cuco__participant_id__r.gf_branch_id__c FROM cuco__profitability_analysis__c WHERE Name = 'Prof Analysis Test 0' LIMIT 1];
            final CucoProfitabilityAnalysisCIB instance = new CucoProfitabilityAnalysisCIB();
            final String branchCode = instance.getBranchCode(paInfo.Id, 'cuco__profitability_analysis__c');
            System.assertEquals(paInfo.cuco__participant_id__r.gf_branch_id__c, branchCode, 'Error at CucoProfitabilityAnalysisCIB_Test getBranchCode1. Expected: ' + paInfo.cuco__participant_id__r.gf_branch_id__c + ' got: ' + branchCode);
        Test.stopTest();
    }

    @IsTest
    static void getBranchCode2() {
        Test.startTest();
            final cuco__profitability_sheet__c  psInfo = [SELECT Id, cuco__participant_id__r.gf_branch_id__c FROM cuco__profitability_sheet__c WHERE Name = 'Prof Sheet Test 0' LIMIT 1];
            final CucoProfitabilityAnalysisCIB instance = new CucoProfitabilityAnalysisCIB();
            final String branchCode = instance.getBranchCode(psInfo.Id, 'cuco__profitability_sheet__c');
            System.assertEquals(psInfo.cuco__participant_id__r.gf_branch_id__c, branchCode, 'Error at CucoProfitabilityAnalysisCIB_Test getBranchCode2. Expected: ' + psInfo.cuco__participant_id__r.gf_branch_id__c + ' got: ' + branchCode);
        Test.stopTest();
    }

    @IsTest
    static void setPADefaultRequestDataTest() {
        final cuco.ProfitabilityAnalysis_Selector paSelector = new cuco.ProfitabilityAnalysis_Selector(true);
        final Set<String> paSetName = new Set<String>{'Prof Analysis Test 0'};
        final List<cuco__profitability_analysis__c> profAnalysis = paSelector.selectByName(paSetName);

        Test.startTest();
            final CucoProfitabilityAnalysisCIB paSample = new CucoProfitabilityAnalysisCIB();
            final cuco__profitability_analysis__c paRes1 = paSample.setPADefaultRequestData(profAnalysis[0],BRANCHCODE,USERCODE);
            System.assertEquals(paRes1.Name,'Novation - Prof Analysis Test 0','Error in setPADefaultRequestData1');

            profAnalysis[0].cuco__gf_pa_management_type_name__c = 'Novation';
            profAnalysis[0].Name = 'Prof Analysis Test 0';
            update profAnalysis;
            final cuco__profitability_analysis__c paRes2 = paSample.setPADefaultRequestData(profAnalysis[0],branchCode,userCode);
            System.assertEquals(paRes2.Name,'Novation - Prof Analysis Test 0','Error in setPADefaultRequestData2');

            profAnalysis[0].cuco__gf_pa_management_type_name__c = 'Cancellation';
            profAnalysis[0].Name = 'Prof Analysis Test 0';
            update profAnalysis;
            final cuco__profitability_analysis__c paRes3 = paSample.setPADefaultRequestData(profAnalysis[0],branchCode,userCode);
            System.assertEquals(paRes3.Name,'Cancellation - Prof Analysis Test 0','Error in setPADefaultRequestData3');

            profAnalysis[0].cuco__gf_pa_management_type_name__c = 'Renewal';
            profAnalysis[0].Name = 'Prof Analysis Test 0';
            update profAnalysis;
            final cuco__profitability_analysis__c paRes4 = paSample.setPADefaultRequestData(profAnalysis[0],branchCode,userCode);
            System.assertEquals(paRes4.Name,'Renewal - Prof Analysis Test 0','Error in setPADefaultRequestData4');

        Test.stopTest();
    }

    @IsTest
    static void setPriceDecisionTest() {
        final cuco.ProfitabilityAnalysis_Wrapper paWrapper = new cuco.ProfitabilityAnalysis_Wrapper();
        Test.startTest();
            final CucoProfitabilityAnalysisCIB paSample = new CucoProfitabilityAnalysisCIB();
            final Map<String, Object> paRes1 = paSample.setPriceDecision(paWrapper, 'A', 'String decisionComments', 'String screenShot');
            System.assertEquals(paRes1.get('success'), true, 'Error in setPriceDecisionTest');
        Test.stopTest();
    }

    @IsTest
    static void setPAApprovePriceTest() {
        final cuco.ProfitabilityAnalysis_Selector paSelectorPrice = new cuco.ProfitabilityAnalysis_Selector(true);
        final Set<String> paSetNamePrice = new Set<String>{'Prof Analysis Test 0'};
        final List<cuco__profitability_analysis__c> lstPA = paSelectorPrice.selectByName(paSetNamePrice);

        Test.startTest();
            final cuco.ProfitabilityAnalysis_Wrapper profAnalysis = cuco.ProfitabilityAnalysis_Helper.getProfAnalysis(lstPA[0].Id);
            final CucoProfitabilityAnalysisCIB paSamplePrice = new CucoProfitabilityAnalysisCIB();
            final Map<String,Object> mapRet = paSamplePrice.setPAApprovePrice(profAnalysis,'');
            System.assertEquals(mapRet.get('success'), false, 'Error at CucoProfitabilityAnalysisCIB_Test setPAApprovePriceTest');
        Test.stopTest();
    }

    @IsTest
    static void setPADismissalTest() {
        final cuco.ProfitabilityAnalysis_Selector paSelector2 = new cuco.ProfitabilityAnalysis_Selector(true);
        final Set<String> paSetName2 = new Set<String>{'Prof Analysis Test 0'};
        final List<cuco__profitability_analysis__c> lstPA2 = paSelector2.selectByName(paSetName2);

        final cuco.ProfitabilityAnalysis_Wrapper paWrapper = cuco.ProfitabilityAnalysis_Helper.getProfAnalysis(lstPA2[0].Id);
        final String dismissalComments = 'test comments';
        final String screenShot = 'test screenshot';

        Test.startTest();
            final CucoProfitabilityAnalysisCIB paSample = new CucoProfitabilityAnalysisCIB();
            final Map<String, Object> retMap = paSample.setPADismissal(paWrapper, dismissalComments, screenShot);
            final List<cuco__profitability_analysis__c> lstPAPost = paSelector2.selectByName(paSetName2);
            final List<dwp_cvad__Action_Audit__c> lstActionAudit = [SELECT Id FROM dwp_cvad__Action_Audit__c LIMIT 1];
            final List<dwp_cvad__Action_Audit_Detail__c> lstActionAuditDetail = [SELECT Id FROM dwp_cvad__Action_Audit_Detail__c LIMIT 1];

            final Map<String, Object> expectedMap = new Map<String, Object>();
            expectedMap.put('success', true);
            expectedMap.put('stage', 'Dismissed');
            expectedMap.put('status', 'Dismissed');
            expectedMap.put('actionAudit', 1);
            expectedMap.put('actionAuditDetail', 1);

            final Map<String, Object> actualMap = new Map<String, Object>();
            actualMap.put('success', (Boolean) retMap.get('success'));
            actualMap.put('stage', lstPAPost[0].cuco__gf_pa_mgmt_stage_type_name__c);
            actualMap.put('status', lstPAPost[0].cuco__gf_pa_mgmt_status_type_name__c);
            actualMap.put('actionAudit', lstActionAudit.size());
            actualMap.put('actionAuditDetail', lstActionAuditDetail.size());

            System.assertEquals(expectedMap, actualMap, 'Error at CucoProfitabilityAnalysisCIB_Test - setPADismissalTest');
        Test.stopTest();
    }

    @IsTest
    static void setPAFormalizationValidationTest() {
        final User testUser = [SELECT Id FROM User WHERE Username = 'testProfi@example.com' LIMIT 1];
		System.runAs(testUser) {
        	Test.startTest();

            final cuco.ProfitabilityAnalysis_Selector paSelectorForm = new cuco.ProfitabilityAnalysis_Selector(true);
            final Set<String> paSetNameForm = new Set<String>{'Prof Analysis Test 4'};
            final List<cuco__profitability_analysis__c> lstPA = paSelectorForm.selectByName(paSetNameForm);

            final cuco.ProfitabilityAnalysis_Wrapper paWrapper = cuco.ProfitabilityAnalysis_Helper.getProfAnalysis(lstPA[0].Id);
            //List<String> errors = CucoValidationsCIB.checkPAFormalization(cuco.ProfitabilityAnalysis_Wrapper paWrapper, cuco__pa_general_configuration__mdt genConfig) {

            System.debug(lstPA[0]);
            System.debug(paWrapper);

            final CucoValidationsCIB cucoValidations = new CucoValidationsCIB();
            List<String> errorList = cucoValidations.getErrorMessagesList(lstPA[0].Id, 'cuco__profitability_analysis__c', 'PA_Formalization_Sample');

            for (String str : errorList) {
                System.debug(str);
            }

            System.assertEquals(0, errorList.size(), 'Error at CucoProfitabilityAnalysisCIB_Test setPAFormalizationValidationTest');
        	Test.stopTest();
        }
    }

    @IsTest
    static void setPAFormalizationTest() {
        final cuco.ProfitabilityAnalysis_Selector paSelectorForm = new cuco.ProfitabilityAnalysis_Selector(true);
        final Set<String> paSetNameForm = new Set<String>{'Prof Analysis Test 0'};
        final List<cuco__profitability_analysis__c> lstPA = paSelectorForm.selectByName(paSetNameForm);

        Test.startTest();
            final cuco.ProfitabilityAnalysis_Wrapper profAnalysis = cuco.ProfitabilityAnalysis_Helper.getProfAnalysis(lstPA[0].Id);
            final CucoProfitabilityAnalysisCIB paSampleForm = new CucoProfitabilityAnalysisCIB();
            final Map<String,Object> mapRet1 = paSampleForm.setPAFormalization(profAnalysis,'Combined','',SCREENSHOT_NEW);
            final Map<String,Object> mapRet2 = paSampleForm.setPAFormalization(profAnalysis,'Automatic','',SCREENSHOT_NEW);
            System.assertEquals(mapRet1.get('success'), true, 'Err 1 at CucoProfitabilityAnalysisCIB_Test setPAFormalizationTest (combined)');
            System.assertEquals(mapRet2.get('success'), true, 'Err 2 at CucoProfitabilityAnalysisCIB_Test setPAFormalizationTest (automatic)');
        Test.stopTest();
    }

    @IsTest
    static void setPARestudyTest1() {
        final cuco.ProfitabilityAnalysis_Selector paSelector3 = new cuco.ProfitabilityAnalysis_Selector(true);
        final Set<String> paSetName3 = new Set<String>{'Prof Analysis Test 1'};
        final List<cuco__profitability_analysis__c> lstPA3 = paSelector3.selectByName(paSetName3);

        final cuco.ProfitabilityAnalysis_Wrapper paWrapper3 = cuco.ProfitabilityAnalysis_Helper.getProfAnalysis(lstPA3[0].Id);
        final String restudyComments3 = 'test comments';
        final String screenShot3 = 'test screenshot';

        Test.startTest();
            final CucoProfitabilityAnalysisCIB paSample3 = new CucoProfitabilityAnalysisCIB();
            final Map<String, Object> retMap3 = paSample3.setPARestudy(paWrapper3, restudyComments3, screenShot3);
            final List<cuco__profitability_analysis__c> lstPAPost3 = paSelector3.selectByName(paSetName3);
            final List<dwp_cvad__Action_Audit__c> lstActionAudit3 = [SELECT Id FROM dwp_cvad__Action_Audit__c LIMIT 1];
            final List<dwp_cvad__Action_Audit_Detail__c> lstActionAuditDetail3 = [SELECT Id FROM dwp_cvad__Action_Audit_Detail__c LIMIT 1];

            final Map<String, Object> expectedMap3 = new Map<String, Object>();
            expectedMap3.put('success', true);
            expectedMap3.put('stage', 'Analysis');
            expectedMap3.put('status', 'Restudy');
            expectedMap3.put('actionAudit', 1);
            expectedMap3.put('actionAuditDetail', 1);
            expectedMap3.put('emptyFieldOne', null);
            expectedMap3.put('emptyFieldTwo', null);

            final Map<String, Object> actualMap3 = new Map<String, Object>();
            actualMap3.put('success', (Boolean) retMap3.get('success'));
            actualMap3.put('stage', lstPAPost3[0].cuco__gf_pa_mgmt_stage_type_name__c);
            actualMap3.put('status', lstPAPost3[0].cuco__gf_pa_mgmt_status_type_name__c);
            actualMap3.put('actionAudit', lstActionAudit3.size());
            actualMap3.put('actionAuditDetail', lstActionAuditDetail3.size());
            actualMap3.put('emptyFieldOne', lstPAPost3[0].cuco__gf_pa_price_negotiated_date__c);
            actualMap3.put('emptyFieldTwo', lstPAPost3[0].cuco__gf_pa_aprvl_proc_deleg_br_id__c);

            System.assertEquals(expectedMap3, actualMap3, 'Error at CucoProfitabilityAnalysisCIB_Test - setPARestudyTest1');
        Test.stopTest();
    }

    @IsTest
    static void setPARestudyTest2() {
        final cuco.ProfitabilityAnalysis_Selector paSelector4 = new cuco.ProfitabilityAnalysis_Selector(true);
        final Set<String> paSetName4 = new Set<String>{'Prof Analysis Test 2'};
        final List<cuco__profitability_analysis__c> lstPA4 = paSelector4.selectByName(paSetName4);

        final cuco.ProfitabilityAnalysis_Wrapper paWrapper4 = cuco.ProfitabilityAnalysis_Helper.getProfAnalysis(lstPA4[0].Id);
        final String restudyComments4 = 'test comments';
        final String screenShot4 = 'test screenshot';

        Test.startTest();
            final CucoProfitabilityAnalysisCIB paSample4 = new CucoProfitabilityAnalysisCIB();
            final Map<String, Object> retMap4 = paSample4.setPARestudy(paWrapper4, restudyComments4, screenShot4);
            final List<cuco__profitability_analysis__c> lstPAPost4 = paSelector4.selectByName(paSetName4);
            final List<dwp_cvad__Action_Audit__c> lstActionAudit4 = [SELECT Id FROM dwp_cvad__Action_Audit__c LIMIT 1];
            final List<dwp_cvad__Action_Audit_Detail__c> lstActionAuditDetail4 = [SELECT Id FROM dwp_cvad__Action_Audit_Detail__c LIMIT 1];

            final Map<String, Object> expectedMap4 = new Map<String, Object>();
            expectedMap4.put('success', true);
            expectedMap4.put('stage', 'Analysis');
            expectedMap4.put('status', 'Restudy');
            expectedMap4.put('actionAudit', 1);
            expectedMap4.put('actionAuditDetail', 1);
            expectedMap4.put('emptyFieldOne', null);
            expectedMap4.put('emptyFieldTwo', null);
            expectedMap4.put('emptyFieldThree', null);

            final Map<String, Object> actualMap4 = new Map<String, Object>();
            actualMap4.put('success', (Boolean) retMap4.get('success'));
            actualMap4.put('stage', lstPAPost4[0].cuco__gf_pa_mgmt_stage_type_name__c);
            actualMap4.put('status', lstPAPost4[0].cuco__gf_pa_mgmt_status_type_name__c);
            actualMap4.put('actionAudit', lstActionAudit4.size());
            actualMap4.put('actionAuditDetail', lstActionAuditDetail4.size());
            actualMap4.put('emptyFieldOne', lstPAPost4[0].cuco__gf_price_aprvl_process_req_id__c);
            actualMap4.put('emptyFieldTwo', lstPAPost4[0].cuco__gf_pa_price_negotiated_date__c);
            actualMap4.put('emptyFieldThree', lstPAPost4[0].cuco__gf_pa_aprvl_proc_deleg_br_id__c);

            System.assertEquals(expectedMap4, actualMap4, 'Error at CucoProfitabilityAnalysisCIB_Test - setPARestudyTest2');
        Test.stopTest();
    }

    @IsTest
    static void getFirstAndLastName1() {
        Test.startTest();
            final User userInfo = [SELECT Id, FirstName, LastName FROM User WHERE LastName =: 'profi' LIMIT 1];
            final CucoProfitabilityAnalysisCIB instance = new CucoProfitabilityAnalysisCIB();
            final String userName = instance.getFirstAndLastName(userInfo.Id);
            System.assertEquals(userInfo.FirstName + ' ' + userInfo.LastName, userName, 'Error at CucoProfitabilityAnalysisCIB_Test getFirstAndLastName1. Expected: ' + userInfo.FirstName + ' ' + userInfo.LastName + ' got: ' + userName);
        Test.stopTest();
    }

    @IsTest
    static void getFirstAndLastName2() {
        Test.startTest();
            final Group group1 = [SELECT Id FROM Group WHERE Name = 'group name test' LIMIT 1];
            final CucoProfitabilityAnalysisCIB instance = new CucoProfitabilityAnalysisCIB();
            final String userName = instance.getFirstAndLastName(group1.Id);
            System.assertEquals('', userName, 'Error at CucoProfitabilityAnalysisCIB_Test getFirstAndLastName2. Expected: empty got: ' + userName);
        Test.stopTest();
    }

    @IsTest
    static void setPANotificationTest1() {
        final cuco.ProfitabilityAnalysis_Selector paSelector5 = new cuco.ProfitabilityAnalysis_Selector(true);
        final Set<String> paSetName5 = new Set<String>{'Prof Analysis Test 3'};
        final List<cuco__profitability_analysis__c> lstPA5 = paSelector5.selectByName(paSetName5);

        final cuco.ProfitabilityAnalysis_Wrapper paWrapper5 = cuco.ProfitabilityAnalysis_Helper.getProfAnalysis(lstPA5[0].Id);
        final String notificationComments5 = 'test comments notification';
        final String screenShot5 = 'test screenshot notification';

        Test.startTest();
            final CucoProfitabilityAnalysisCIB paSample5 = new CucoProfitabilityAnalysisCIB();
            final Map<String, Object> retMap5 = paSample5.setPANotification(paWrapper5, notificationComments5, screenShot5);
            final List<cuco__profitability_analysis__c> lstPAPost5 = paSelector5.selectByName(paSetName5);
            final List<dwp_cvad__Action_Audit__c> lstActionAudit5 = [SELECT Id FROM dwp_cvad__Action_Audit__c LIMIT 1];
            final List<dwp_cvad__Action_Audit_Detail__c> lstActionAuditDetail5 = [SELECT Id FROM dwp_cvad__Action_Audit_Detail__c LIMIT 1];

            final Map<String, Object> expectedMap5 = new Map<String, Object>();
            expectedMap5.put('success', true);
            expectedMap5.put('stage', 'Formalization');
            expectedMap5.put('status', 'Sent for Formalization');
            expectedMap5.put('actionAudit', 1);
            expectedMap5.put('actionAuditDetail', 1);
            expectedMap5.put('fieldOne', 'Manual Req Id');

            final Map<String, Object> actualMap5 = new Map<String, Object>();
            actualMap5.put('success', (Boolean) retMap5.get('success'));
            actualMap5.put('stage', lstPAPost5[0].cuco__gf_pa_mgmt_stage_type_name__c);
            actualMap5.put('status', lstPAPost5[0].cuco__gf_pa_mgmt_status_type_name__c);
            actualMap5.put('actionAudit', lstActionAudit5.size());
            actualMap5.put('actionAuditDetail', lstActionAuditDetail5.size());
            actualMap5.put('fieldOne', lstPAPost5[0].cuco__gf_manl_formalization_req_id__c);

            System.assertEquals(expectedMap5, actualMap5, 'Error at CucoProfitabilityAnalysisCIB_Test - setPANotificationTest1');
        Test.stopTest();
    }

    // Test without the correct configuration for method filter
    @IsTest
    static void getExtraParticipantActionsTest1() {
        final cuco.ProfitabilityAnalysis_Selector paSelector6 = new cuco.ProfitabilityAnalysis_Selector(true);
        final Set<String> paSetName6 = new Set<String>{'Prof Analysis Test 0'};
        final List<cuco__profitability_analysis__c> lstPA6 = paSelector6.selectByName(paSetName6);

        Test.startTest();
            final CucoProfitabilityAnalysisCIB paSample6 = new CucoProfitabilityAnalysisCIB();
            List<cuco.AdditionalActions_Wrapper> lstAAW6 = paSample6.getExtraParticipantActions(lstPA6[0].Id, UserInfo.getUserId());
            System.assertEquals(1, lstAAW6.size(), 'Err at ProfitabilityAnalysisSample_Test - getExtraParticipantActionsTest1');
        Test.stopTest();
    }

    // Test for update profitability analisis with participant data
    @IsTest
    static void setPADefaultCloneDataTest1() {

        final Account acc = [SELECT Id, OwnerId FROM Account WHERE name = 'Account Test 0' LIMIT 1];
        final cuco__profitability_analysis__c paInfo = [SELECT Id FROM cuco__profitability_analysis__c WHERE Name = 'Prof Analysis Test 0' LIMIT 1];
        final User testUser = [SELECT Id FROM User WHERE id = :acc.OwnerId];

        System.runAs(testUser) {
            Test.startTest();
                final CucoProfitabilityAnalysisCIB paSample = new CucoProfitabilityAnalysisCIB();
                cuco__profitability_analysis__c paInf = paSample.setPADefaultCloneData(paInfo);
                System.assertEquals(paInf.OwnerId, acc.OwnerId, 'Err at ProfitabilityAnalysisSample_Test - setPADefaultCloneDataTest1');
            Test.stopTest();
        }
    }

    @IsTest
    static void setPAResetRenewalTest() {
        final cuco.ProfitabilityAnalysis_Selector paSelectorForm = new cuco.ProfitabilityAnalysis_Selector(true);
        final Set<String> paSetNameForm = new Set<String>{'Prof Analysis Test 0'};
        final List<cuco__profitability_analysis__c> lstPA = paSelectorForm.selectByName(paSetNameForm);

        Test.startTest();
            final cuco.ProfitabilityAnalysis_Wrapper profAnalysis = cuco.ProfitabilityAnalysis_Helper.getProfAnalysis(lstPA[0].Id);
            final CucoProfitabilityAnalysisCIB paSampleForm = new CucoProfitabilityAnalysisCIB();
            final Map<String,Object> mapRet = paSampleForm.setPAResetRenewal(profAnalysis,'',SCREENSHOT_NEW);
            System.assertEquals(mapRet.get('success'), true, 'Err 1 at CucoProfitabilityAnalysisCIB_Test setPAResetRenewalTest');
        Test.stopTest();
    }
}