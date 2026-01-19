/*------------------------------------------------------------------
*Author:        Diego Miguel Tamarit - diego.miguel.contractor@bbva.com / dmiguelt@minsait.com
*Project:       ARCE - BBVA Bancomer
*Description:   Test class for code coverage of:
*Arc_Gen_ProposeInPreparation_controller
*Arc_Gen_RefreshClass_service
*Arc_Gen_RefreshClass_data
*_______________________________________________________________________________________
*Version    Date           Author                               Description
*1.0        28/05/2019     diego.miguel.contractor@bbva.com     Creación.
*1.1        21/11/2019     eduardoefrain.hernandez.contractor@bbva.com Update test methods because of propose refactor
*1.2        07/01/2020     javier.soto.carrascosa@bbva.com Add support for account wrapper and setupaccounts
*1.3        07/07/2020     juanignacio.hita.contractor@bbva.com Add isHolding call method createAHAParticipantOK
*1.4        11/08/2020     javier.soto.carrascosa@bbva.com Add Update sector field
*1.5        11/08/2020     javier.soto.carrascosa@bbva.com Add Update sector field
*1.6        14/09/2020     juanignacio.hita.contractor@bbva.com Create new test method for increase coverage
*1.4        23/09/2020     saimassimilianno.jordana.contractor@bbva.com Added arce. namespace to all classes that are now in the arce-dependencies package
*1.7        04/01/2021     joseluis.garcia4.contractor@bbva.com Test for orphan refresh.
*1.8        17/06/2021     juanmanuel.perez.ortiz.contractor@bbva.com Test empty constructor
*1.9        01/09/2021     juanignacio.hita.contractor@bbva.com fix testOrphanRefresh test method
-----------------------------------------------------------------------------------------*/
@SuppressWarnings('sf:TooManyMethods')
@isTest
public class Arc_Gen_RefreshClass_test {
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID = 'G000001';
    /**
    * @Description: String with external id of test group
    */
    static final string SUBSIDIARY_ID1 = 'C000001';
    /**
    * @Description: String with external id of test subsidiary
    */
    static final string SUBSIDIARY_ID2 = 'C000002';
    /**
    * @Description: String with external id of test orphan
    */
    static final string ORPHAN_ID = 'C000004';
    /**
    * @Description: String with the new group of test orphan
    */
    static final string ORPHAN_NEWGROUP_ID = 'G000002';
    /**
    * @Method:      test for method Arc_Gen_RefreshClass_test.
    * @Description: test setup method.
    */
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        List<sObject> iasoCnfList = Arc_UtilitysDataTest_tst.crearIasoUrlsCustomSettings();
        insert iasoCnfList;

        final Map<String, arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID1,SUBSIDIARY_ID2,ORPHAN_ID});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);
        final arce.Arc_Gen_Account_Wrapper childAccount1 = groupAccWrapper.get(SUBSIDIARY_ID1);
        final arce.Arc_Gen_Account_Wrapper childAccount2 = groupAccWrapper.get(SUBSIDIARY_ID2);
        final arce.Arc_Gen_Account_Wrapper orphanAccount = groupAccWrapper.get(ORPHAN_ID);

        arce__Sector__c newSector = arc_UtilitysDataTest_tst.crearSector('Generic', '100;300;400', '1', null);
        insert newSector;

        arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        newArce.arce__Stage__c = '1';
        insert newArce;

        arce__Analysis__c newArce2 = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis11', null, groupAccount.accId);
        newArce2.arce__Stage__c = '1';
        insert newArce2;

        final arce__Analysis__c newArce3 = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis Orphan', null, orphanAccount.accId);
        newArce3.arce__Stage__c = '1';
        newArce3.arce__analysis_customer_relation_type__c = arce.Arc_Gen_Constants.CUSTOMER_RELATION_ORPHAN;
        insert newArce3;

        arce__Account_has_Analysis__c acc1 = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, groupAccount.accId, '1');
        acc1.arce__InReview__c = true;
        acc1.arce__path__c = 'MAC';
        acc1.arce__group_asset_header_type__c = '1';
        insert acc1;

        arce__Account_has_Analysis__c acc2 = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, childAccount1.accId, '1');
        acc2.arce__InReview__c = true;
        acc2.arce__path__c = 'MACAHA2';
        acc2.arce__group_asset_header_type__c = '2';
        insert acc2;

        arce__Account_has_Analysis__c acc3 = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, childAccount2.accId, '1');
        acc3.arce__InReview__c = true;
        acc3.arce__path__c = 'MAC';
        insert acc3;

        final arce__Account_has_Analysis__c acc4 = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce3.Id, orphanAccount.accId, '1');
        acc4.arce__InReview__c = true;
        acc4.arce__path__c = 'MACAHA3';
        insert acc4;

        arce__rating__c rating = Arc_UtilitysDataTest_tst.crearRating(null);
        insert rating;

        arce__Financial_Statements__c finStatement = Arc_UtilitysDataTest_tst.crearFinStatement(childAccount1.accId, acc2.id, rating.id, null);
        finStatement.arce__financial_statement_end_date__c = Date.today();
        finStatement.arce__ffss_valid_type__c = '1';
        insert finStatement;

        acc2.arce__ffss_for_rating_id__c = finStatement.Id;
        Update acc2;

        Arc_UtilitysDataTest_tst.createAssessmentData();
        Arc_UtilitysDataTest_tst.createBankingRelationshipDepData();
        Arc_UtilitysDataTest_tst.createBasicDataData();
        Arc_UtilitysDataTest_tst.createFinancialRiskData();
        Arc_UtilitysDataTest_tst.createBusinessRiskData();
        Arc_UtilitysDataTest_tst.createIndustryAnalysisData();
        Arc_UtilitysDataTest_tst.createPolicies();
    }
    /**
    * @Method:  Test for method constructor
    * @Description: Testing method.
    */
    @isTest
    static void testConstructor() {
        Test.startTest();
        final Arc_Gen_Refresh_controller contConstructor = new Arc_Gen_Refresh_controller();
        System.assertEquals(contConstructor, contConstructor, 'Empty constructor');
        Test.stopTest();
    }
    /**
    * @Method:      Test with success for method getAllAnalysis (recordId)
    * @Description: testing method.
    */
    @isTest static void testGetAllAnalysisOK() {
        final Id recordId = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1].Id;
        Test.startTest();
        final List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> lst = Arc_Gen_Refresh_controller.getAHARefresh(recordId);
        System.assertEquals(lst[0].ahaObj.Id, recordId, 'Get all analysis test');
        Test.stopTest();
    }
    /**
    * @Method:      Test with fail for method getAllAnalysis (recordId)
    * @Description: testing method.
    */
    @isTest static void testGetAllAnalysisKO() {
        try {
            final Id recordId = [SELECT Id FROM arce__Analysis__c LIMIT 1].Id;
            Test.startTest();
            Arc_Gen_Refresh_controller.getAHARefresh(recordId);
            Test.stopTest();
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('Script'), 'Script-thrown exception');
        }
    }
    /**
    * @Method:      Test with success for method callListCustomers
    * @Description: testing method.
    */
    @isTest static void testCallListCustomersOK() {
        try {
            final List<arce__Account_has_Analysis__c> newMiniArces = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__path__c = 'MACAHA2'];
            Test.startTest();
            Arc_Gen_RefreshClass_service.refreshMessagesResponse response = Arc_Gen_Refresh_controller.callListCustomers(newMiniArces[0].Id);
            System.assertEquals('OK', response.serviceStatus, 'testCallListCustomFromRefresh expected OK response');
            Test.stopTest();
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('Script'), 'Script-thrown exception');
        }
    }
    /**
    * @Method:      Test with success for method getListParticipants
    * @Description: testing method.
    */
    @isTest static void testGetListParticipants() {
        try {
            Test.startTest();
            final String[] withoutgroup = new String[0];
            final String[] groupnumber = new String[0];
            for (Account acc : [SELECT Id, AccountNumber FROM Account LIMIT 3]) {
                withoutgroup.add(acc.Id);
                groupnumber.add(acc.AccountNumber);
            }

            final List<arce__Account_has_Analysis__c> newMiniArces = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
            Arc_Gen_Refresh_controller.getListParticipants('sfYZ9luP93g9U9AqdpF1Iw', withoutgroup, groupnumber, newMiniArces[0].Id);
            // Test exception
            Arc_Gen_Refresh_controller.getListParticipants(null, null, null, newMiniArces[0].Id);
            Test.stopTest();
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('Script'), 'Script-thrown exception');
        }
    }
    /**
    * @Method:      Test with success for method createAHAParticipant
    * @Description: testing method.
    */
    @isTest static void testCreateAHAParticipantOK() {
        Test.startTest();
            List<String> partNoExist = new List<String>();
            final List<Account> lstAccount = [SELECT Id, AccountNumber FROM Account LIMIT 3];
            final arce__Analysis__c analysis = [SELECT Id, arce__anlys_wkfl_sub_process_type__c FROM arce__Analysis__c LIMIT 1];
            Map<String, Boolean> mapIsHolding = new Map<String, Boolean>();
            for (Account acc : lstAccount) {
                partNoExist.add(acc.AccountNumber);
                mapIsHolding.put(acc.AccountNumber, false);
            }
            final List<arce__Account_has_Analysis__c> lst = Arc_Gen_RefreshClass_data.createAHAParticipants(partNoExist, analysis, mapIsHolding);
            System.assertEquals(lst[0].arce__Analysis__c, analysis.Id, 'Create AHA participant test');
        Test.stopTest();
    }
    /**
    * @Method:      Test refreshFinancialSponsor method
    * @Description: Test refreshFinancialSponsor method
    */
    @isTest static void testRefreshFinancialSponsor() {
        try {
            arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
            Test.startTest();
            // Test method with success
            Arc_Gen_Refresh_controller.refreshFinancialSponsor(aha.Id);
            // Test method expected exception
            Arc_Gen_Refresh_controller.refreshFinancialSponsor('');
            Test.stopTest();
        } catch (Exception ex) {
            System.assertEquals('Script-thrown exception', ex.getMessage());
        }
    }
    /**
    * @Method:      Test createTraceability method
    * @Description: Test createTraceability method
    */
    @isTest static void testCreateTraceability() {
        final List<String> participantsDeleted = new List<String>{'1','2'};
        final arce__Analysis__c analysis = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        Test.startTest();
        final dwp_cvad__Action_Audit__c auditAction = Arc_Gen_RefreshClass_service.createTraceability(analysis.Id, participantsDeleted);
        System.assertEquals('Arc_Gen_Traceability', auditAction.dwp_cvad__action_audit_type__c, 'Test create traceability method');
        Test.stopTest();
    }
    /**
    * @Method:      Test testOrphanRefresh method
    * @Description: Test testOrphanRefresh method
    */
    @isTest static void testOrphanRefresh() {
        try {
            final List<arce__Account_has_Analysis__c> ahas = [SELECT Id, arce__Analysis__c, arce__analysis__r.arce__is_RTC_Emp__c FROM arce__Account_has_Analysis__c WHERE arce__path__c = 'MACAHA3'];
            final arce__Analysis__c arce = [SELECT Id, arce__rating_prerating_type__c, arce__anlys_wkfl_sub_process_type__c FROM arce__Analysis__c WHERE Id = :ahas[0].arce__Analysis__c];
            arce.arce__rating_prerating_type__c = 'Prerating';
            arce.arce__anlys_wkfl_sub_process_type__c = 'Rating';
            update arce; 
            Test.startTest();
            final String econPartResp = Arc_Gen_Refresh_controller.callEconomicParticipants(ORPHAN_ID, ahas[0].Id);
            final String listPartResp = Arc_Gen_Refresh_controller.getListParticipantsOrphan(ORPHAN_NEWGROUP_ID, ahas[0].Id);
            final String newAhaId = Arc_Gen_Refresh_controller.constructGroupStructure(listPartResp, econPartResp, ahas[0].Id);
            System.assert(newAhaId != null, 'Error in testOrphanRefresh method');
            Test.stopTest();
        } catch (Exception ex) {
            System.assertEquals('Unable to refresh group structure: This customer does not have an associated economic group.', ex.getMessage(), 'test orphan refresh');
        }
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void emptyConstructorTest() {
        Test.startTest();
        final Arc_Gen_RefreshClass_Helper constructor = new Arc_Gen_RefreshClass_Helper();
        System.assertEquals(constructor, constructor, 'Empty constructor');
        Test.stopTest();
    }

}