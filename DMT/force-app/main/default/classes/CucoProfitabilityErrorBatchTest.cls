/**
* ────────────────────────────────────────────────────────────────────
* CucoProfitabilityErrorBatchTest
* Test class for CucoSchedulableBatchError,
                CucoFormalizationErrorsController,
                CucoSendEmail,
                CucoSendEmailHelper,
                ProfitabilityAnalysisTriggerHandler
* ────────────────────────────────────────────────────────────────────
* @author      CuCo CIB <globalhub_components.group@bbva.com>
* @modifiedBy
* @version     1.0
* @created     July 2021
* @modified
* @systemLayer
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
@isTest
private class CucoProfitabilityErrorBatchTest {
    @testSetup
    static void setup() {
        final List<Account> lstAcc = cuco.Test_Utils.createAccounts(1);
        insert lstAcc;

        final List<cuco__profitability_sheet__c> lstPS = cuco.Test_Utils.createProfSheet(1, lstAcc[0]);
        insert lstPS;

        final List<cuco__profitability_sheet_participant__c> lstPSP = cuco.Test_Utils.createProfSheetParticipant(1, lstPS[0].Id, new List<Id>{lstAcc[0].Id});
        insert lstPSP;

        final List<cuco__profitability_sheet_error__c> errorList = new List<cuco__profitability_sheet_error__c> ();
        final cuco__profitability_sheet_error__c profError = new cuco__profitability_sheet_error__c (
            cuco__participant_id__c	= lstAcc[0].Id,
            cuco__gf_profitability_sheet_id__c = lstPS[0].Id,
            cuco__gf_error_code_id__c = '1',
            cuco__gf_error_desc__c = 'ErrorTest',
            cuco__gf_product_family_desc__c	= '01');
        errorList.add(profError);
        insert errorList;

        final User usr = cuco.Test_Utils.createUser();
        usr.ID_User__c = 'UserTest';
        insert usr;

        final User usr2 = cuco.Test_Utils.createUser();
        usr2.ID_User__c = 'TestNuevo';
        usr2.Username = 'testProfi2@example.com';
        usr2.FederationIdentifier = '5678';
        insert usr2;

        final List<cuco__profitability_analysis__c> lstPA = cuco.Test_Utils.createProfAnalysis(1, lstAcc[0]);
        lstPA[0].cuco__gf_pa_management_type_name__c = 'Novation';
        lstPA[0].cuco__gf_pa_mgmt_stage_type_name__c = 'Formalized';
        lstPA[0].cuco__gf_pa_comments_desc__c = 'CommentTest';
        lstPA[0].cuco__gf_profitability_sheet_id__c = lstPS[0].Id;
        lstPA[0].OwnerId = usr.Id;
        insert lstPA;

        final List<cuco__profitability_analysis_participant__c> lstPAP = cuco.Test_Utils.createProfAnalysisParticipant(1, lstPA[0].Id, new List<Id>{lstAcc[0].Id});
        insert lstPAP;

        final dwp_cvad__Action_Audit__c audit = new dwp_cvad__Action_Audit__c();
        audit.dwp_cvad__action_audit_name__c = 'Formalized';
        audit.dwp_cvad__action_audit_object_api_name__c = 'cuco__profitability_analysis__c';
        audit.dwp_cvad__action_audit_record_id__c = lstPA[0].id;
        audit.dwp_cvad__action_audit_style__c = 'elevate';
        audit.dwp_cvad__action_audit_date__c = DateTime.now();
        audit.dwp_cvad__action_audit_type__c = 'ProfitabilityAnalysis';
        audit.dwp_cvad__action_audit_user_id__c = usr.Id;
        insert audit;

    }

    @isTest static void testBatch() {
        final CucoSendEmail instance = CucoSendEmail.gtInstance();
        final CucoSendEmailHelper instanceHelper = CucoSendEmailHelper.gtInstance();
        final CucoConstructor instanceCons = CucoConstructor.gtInstance();
        System.debug(instance);
        System.debug(instanceHelper);
        System.debug(instanceCons);
        Test.startTest();
        final CucoProfitabilityErrorBatch cucoPEB = new CucoProfitabilityErrorBatch();
        Database.executeBatch(cucoPEB);
        Test.stopTest();
        System.assertEquals(1, [SELECT count() FROM cuco__profitability_sheet__c WHERE Notified__c = true], 1);
    }

    @IsTest
    static void checkDeleteErrors() {
        final CucoFormalizationErrorsController instance = CucoFormalizationErrorsController.gtInstance();
        system.debug(instance);
        final Set<String> psNames = new Set<String>{'Prof Sheet Test 0'};
        final Set<String> psErrors = new Set<String>{'ErrorTest'};
        final List<cuco__profitability_sheet__c> profSheets = [SELECT Id,Name,cuco__gf_profitability_sheet_id__c FROM cuco__profitability_sheet__c WHERE Name =: psNames];
        final List<cuco__profitability_sheet_error__c> profSheetsErrors = [SELECT Id,cuco__gf_error_code_id__c,cuco__gf_error_desc__c,cuco__gf_product_family_desc__c,Family_Code__c FROM cuco__profitability_sheet_error__c WHERE cuco__gf_error_desc__c =: psErrors];
        final cuco.ProfitabilityAnalysis_Selector profAnSelector = new cuco.ProfitabilityAnalysis_Selector(false);
        final Set<String> setNamesPA = new Set<String>{'Prof Analysis Test 0'};
        final List<cuco__profitability_analysis__c> lstPA = profAnSelector.selectByName(setNamesPA);
        Test.startTest();
        CucoFormalizationErrorsController.deleteErrors(profSheetsErrors[0], profSheets[0].Id);
        CucoFormalizationErrorsController.getErrors(lstPA[0].Id);
        Test.stopTest();
        System.assertEquals(1, [SELECT count() FROM cuco__profitability_sheet_error__c WHERE Fixed__c = true], 1);
    }

    @IsTest
    static void scheduledTest() {
        test.startTest();
        final CucoSchedulableBatchError myClass = new CucoSchedulableBatchError ();
        final String chron = '0 0 23 * * ?';
        system.schedule('Test Sched', chron, myClass);
        test.stopTest();
        System.assertEquals(1, [SELECT count() FROM cuco__profitability_sheet_error__c WHERE Fixed__c = false], 1);
    }

    @IsTest
    static void checkHandler() {
        final User usr2 = [SELECT Id FROM User WHERE ID_User__c = 'TestNuevo' LIMIT 1];
        system.runAs(usr2) {
        final cuco.ProfitabilityAnalysis_Selector profAnSelector = new cuco.ProfitabilityAnalysis_Selector(false);
        final Set<String> setNamesPA = new Set<String>{'Prof Analysis Test 0'};
        final List<cuco__profitability_analysis__c> lstPA = profAnSelector.selectByName(setNamesPA);
        Test.startTest();
        lstPA[0].cuco__gf_pa_comments_desc__c = 'TestNuevo';
        update lstPA[0];
        Test.stopTest();
        }
        final User editUser = [SELECT Id FROM User WHERE ID_User__c = 'TestNuevo' LIMIT 1];
        System.assertEquals(1, [SELECT count() FROM cuco__profitability_analysis__c WHERE LastModifiedById =: editUser.Id], 1);
    }

    @isTest
    static void testCall(){

        test.startTest();
        final RestRequest request = new RestRequest();
        final RestResponse response = new RestResponse();

        request.requestURI = '/services/apexrest/cucoProfitabilityErrorWS';
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response = response;

        Id batchId = CucoProfitabilityErrorWS.runBatch();
        Boolean result = batchId == null ? false : true;
        System.assert(result, 'Ok');
        test.stopTest();
    }
}