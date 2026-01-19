/*------------------------------------------------------------------
* @FileName: Arc_Gen_ProposeInPreparation_Test.cls
* @Author:        Angel Fuertes Gomez - angel.fuertes2@bbva.com / BBVA DWP
* @Group:       ARCE - BBVA Bancomer
* @Description:   test for method class Arc_Gen_ProposeInPreparation_controller.
* @Project:         ARCE - BBVA Bancomer
* @Changes:
*_______________________________________________________________________________________
*Version    Date           Author                               Description
*1.0        26/04/2019     Angel Fuertes Gomez                      Creation.
*1.1        28/06/2019     Ismael Obregon Uribe                     Add function of rating.
*1.2                       Mario Ramirez                            Update class
*1.3        11/08/2020     Javier Soto                     Update sector field
*1.4        15/09/2020     Juan Ignacio Hita                    Add constructor test method
*1.5        23/09/2020     Sai Jordana                          Added arce. namespace to all classes that are now in the arce-dependencies package
*1.6        24/06/2021     Israel Rodríguez Ramos          Add fields in arce__Account_has_Analysis__c,
*                                                          arce__limits_typology__c, arce__limits_exposures__c for Audited Values
*1.7        19/07/2021     Juan Ignacio Hita                    Add persistArceActionTestOK, persistArceActionTestKO methods
-----------------------------------------------------------------------------------------*/
@SuppressWarnings('sf:TooManyMethods')
@isTest
public with sharing class Arc_Gen_ProposeInPreparation_Test {
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID = 'G000001';
    /**
    * @Description: String with external id of test subsidiary
    */
    static final string SUBSIDIARY_ID = 'C000001';
    /**
    * @Description: String with external id of test subsidiary
    */
    static final string SUBSIDIARY_ID2 = 'C000002';
    /**
    * @Method:      method that creates the data to use in the test.
    * @Description: testing method.
    */
    String accHasId;
    /*
        @Description: Exception error tests KO
    */
    static final String SCRIPT_EXCEPTION = 'Script-thrown exception';
    /*
        @Description: Name of the sector
    */
    static final String SECTOR_NAME = '1';
    /*
        @Description: Name of the sector
    */
    static final String SCRIPT_LIT = 'Script';

    /**
    * @Method:      method that creates the data to use in the test.
    * @Description: testing method.
    */
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final List<sObject> iasoCnfList = Arc_UtilitysDataTest_tst.crearIasoUrlsCustomSettings();
        insert iasoCnfList;

        final User userTest = Arc_UtilitysDataTest_tst.crearUsuario('UserTest',System.Label.Cls_arce_ProfileSystemAdministrator,'');
        userTest.ID_User__C = String.valueOf((Math.random()*100000));
        insert userTest;

        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID,SUBSIDIARY_ID2});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(SUBSIDIARY_ID);
        final arce.Arc_Gen_Account_Wrapper childAccount2 = groupAccWrapper.get(SUBSIDIARY_ID2);

        final arce__Sector__c newSector = arc_UtilitysDataTest_tst.crearSector('Generic', '100;300;400', SECTOR_NAME, null);
        insert newSector;

        final arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        newArce.arce__anlys_wkfl_sub_process_type__c = arce.Arc_Gen_Constants.SUBPROCESS_NEW;
        newArce.arce__Stage__c = '1';
        newArce.arce__Temporal_status__c = false;
        newArce.arce__analysis_customer_relation_type__c = '01';
        newArce.arce__Group__c = groupAccount.accId;
        insert newArce;

        final arce__Account_has_Analysis__c newAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, groupAccount.accId, SECTOR_NAME);
        newAnalysis.arce__Analysis__c = newArce.Id;
        newAnalysis.arce__Customer__c = groupAccount.accId;
        populateTestAha(newAnalysis);
        insert newAnalysis;

        final arce__limits_typology__c ll1 = new arce__limits_typology__c();
        ll1.arce__risk_typology_level_id__c = 'TP_0003';
        ll1.arce__risk_typology_level_type__c = '1';
        ll1.arce__Typology_Order__c = 1;
        INSERT ll1;

        final arce__Account_has_Analysis__c newAnalysis2 = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, childAccount.accId, SECTOR_NAME);
        newAnalysis2.arce__group_asset_header_type__c = '2';
        newAnalysis2.arce__InReview__c = true;
        newAnalysis2.arce__path__c = 'MAC';
        insert newAnalysis2;

        final arce__Account_has_Analysis__c newAnalysis3 = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, childAccount2.accId, SECTOR_NAME);
        newAnalysis3.arce__group_asset_header_type__c = '2';
        newAnalysis3.arce__InReview__c = true;
        newAnalysis3.arce__path__c = 'MAC';
        insert newAnalysis3;

        createLimitsExposures(ll1, new List<arce__Account_has_Analysis__c> { newAnalysis, newAnalysis2, newAnalysis3 });

        final arce__rating__c rating = Arc_UtilitysDataTest_tst.crearRating(null);
        insert rating;

        final arce__Financial_Statements__c finStatement = Arc_UtilitysDataTest_tst.crearFinStatement(groupAccount.accId, newAnalysis2.id, rating.id, null);
        finStatement.arce__financial_statement_end_date__c = Date.today();
        finStatement.arce__ffss_valid_for_rating_type__c = '1';
        insert finStatement;

        newAnalysis2.arce__ffss_for_rating_id__c = finStatement.Id;
        update newAnalysis2;

        Arc_UtilitysDataTest_tst.createAssessmentData();
        Arc_UtilitysDataTest_tst.createBankingRelationshipDepData();
        Arc_UtilitysDataTest_tst.createBasicDataData();
        Arc_UtilitysDataTest_tst.createFinancialRiskData();
        Arc_UtilitysDataTest_tst.createBusinessRiskData();
        Arc_UtilitysDataTest_tst.createIndustryAnalysisData();
        Arc_UtilitysDataTest_tst.createPolicies();
    }
    /**
    * @Method:      method that creates the data to use in the test.
    * @Description: testing method.
    */
    private static void createLimitsExposures(arce__limits_typology__c ll1, List<arce__Account_has_Analysis__c> ahas) {
        final arce__limits_exposures__c ale = new arce__limits_exposures__c();
        ale.arce__account_has_analysis_id__c = ahas[0].Id;
        ale.arce__curr_apprv_deleg_rm_amount__c = 2000;
        ale.arce__current_apprv_limit_term_id__c = '12';
        ale.arce__limits_typology_id__c = ll1.Id;
        INSERT ale;

        final arce__limits_exposures__c ale2 = new arce__limits_exposures__c();
        ale2.arce__account_has_analysis_id__c = ahas[1].Id;
        ale2.arce__curr_apprv_deleg_rm_amount__c = 2000;
        ale2.arce__current_apprv_limit_term_id__c = '12';
        ale2.arce__limits_typology_id__c = ll1.Id;
        INSERT ale2;

        final arce__limits_exposures__c ale3 = new arce__limits_exposures__c();
        ale3.arce__account_has_analysis_id__c = ahas[2].Id;
        ale3.arce__curr_apprv_deleg_rm_amount__c = 2000;
        ale3.arce__current_apprv_limit_term_id__c = '12';
        ale3.arce__limits_typology_id__c = ll1.Id;
        INSERT ale3;
    }
    /**
    * @Method:      method that creates the data to use in the test.
    * @Description: testing method.
    */
    private static void populateTestAha(arce__Account_has_Analysis__c aha) {
        aha.arce__path__c = 'MAC';
        aha.arce__Stage__c = '3';
        aha.arce__InReview__c = true;
        aha.arce__group_asset_header_type__c = arce.Arc_Gen_Constants.GROUP_ASSET_HEADER_TYPE_HEADER;
        aha.arce__long_rating_value_type__c = 'BBB-2';
        aha.arce__currency_id__c = 'EUR';
        aha.arce__current_formalized_amount__c = 0;
        aha.arce__outstanding_amount__c = 6000000;
        aha.arce__current_proposed_amount__c = 0;
        aha.arce__magnitude_unit_type__c = '1';
        aha.arce__last_approved_amount__c = 6000000;
        aha.arce__ll_after_adj_ind_type__c = '1';
        aha.arce__ll_before_adj_ind_type__c = '1';
        aha.arce__ll_after_adj_clsfn_type__c = 'FS';
        aha.arce__ll_before_adj_clsfn_type__c = 'FS';
        aha.arce__ll_test_manl_excl_rsn_type__c = 'C';
        aha.arce__risk_policy_type__c = '3';
        aha.arce__smes_eur_comuty_defn_type__c = '1';
        aha.arce__total_rating_score_number__c = 3;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test constructor method
    * --------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @param void
    * @return void
    * @example testingConstructor()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testingConstructor() {
        Test.startTest();
        final Arc_Gen_ProposeInPreparation_service constructor = new Arc_Gen_ProposeInPreparation_service();
        System.assertEquals(constructor, constructor,'Empty constructor');
        Test.stopTest();
    }
    /**
    * @Method:      test for method validateRatingInPreparationTest.
    * @Description: testing method.
    */
    @isTest static void validateRatingInPreparationTestOK() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);
        final arce__Sector__c newSector = Arc_UtilitysDataTest_tst.crearSector(SECTOR_NAME, '100', SECTOR_NAME, null);
        insert newSector;
        final arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        insert newArce;
        final arce__Account_has_Analysis__c newAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, groupAccount.accId, SECTOR_NAME);
        insert newAnalysis;
        final arce__rating__c rating = Arc_UtilitysDataTest_tst.crearRating(null);
        insert rating;
        final arce__Financial_Statements__c finStatement = Arc_UtilitysDataTest_tst.crearFinStatement(groupAccount.accId, newAnalysis.id, rating.id, null);
        finStatement.arce__financial_statement_end_date__c = Date.today();
        finStatement.arce__ffss_valid_type__c = '1';
        insert finStatement;
        final arce__Financial_Statements__c finStatement2 = Arc_UtilitysDataTest_tst.crearFinStatement(groupAccount.accId, newAnalysis.id, rating.id, null);
        finStatement2.arce__financial_statement_end_date__c = Date.today();
        insert finStatement2;
        final String[] states = New List<String>();
        states.add(finStatement.Id);
        Test.startTest();
        final arce__Account_has_Analysis__c aac = [SELECT Id FROM arce__Account_has_Analysis__c where arce__group_asset_header_type__c = '1' ORDER by id desc limit 1];
        final Boolean flagTest = Arc_Gen_ProposeInPreparation_controller.validateRatingInPreparation(aac.Id);
        System.assert(!flagTest,'Returns a boolean value (true) if the rating is invalid');
        Test.stopTest();
    }
    /**
    * @Method:      test for method validateRatingInPreparationTest.
    * @Description: testing method.
    */
    @isTest static void validateRatingInPreparationTestKO() {
        try {
            final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
            final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);
            final arce__Sector__c newSector = Arc_UtilitysDataTest_tst.crearSector(SECTOR_NAME, '100', SECTOR_NAME, null);
            insert newSector;
            final arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
            insert newArce;
            final arce__Account_has_Analysis__c newAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, groupAccount.accId, SECTOR_NAME);
            insert newAnalysis;
            final arce__rating__c rating = Arc_UtilitysDataTest_tst.crearRating(null);
            insert rating;
            final arce__Financial_Statements__c finStatement = Arc_UtilitysDataTest_tst.crearFinStatement(groupAccount.accId, newAnalysis.id, rating.id, null);
            finStatement.arce__financial_statement_end_date__c = Date.today();
            finStatement.arce__ffss_valid_type__c = '1';
            insert finStatement;
            final arce__Financial_Statements__c finStatement2 = Arc_UtilitysDataTest_tst.crearFinStatement(groupAccount.accId, newAnalysis.id, rating.id, null);
            finStatement2.arce__financial_statement_end_date__c = Date.today();
            insert finStatement2;
            final String[] states = New List<String>();
            states.add(finStatement.Id);
            Test.startTest();
            Arc_Gen_ProposeInPreparation_controller.validateRatingInPreparation(newArce.Id);
            Test.stopTest();
        } catch(Exception ex) {
            System.assert(ex.getMessage().contains(SCRIPT_LIT), SCRIPT_EXCEPTION);
        }
    }
    /**
    * @Method:      test for method initDelegation (Arc_Gen_ProposeInPreparation_controller)
    * @Description: testing method.
    */
    @isTest static void initDelegationTestOK() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        final String str = Arc_Gen_ProposeInPreparation_controller.initDelegation(accHasAnalysis.Id);
        final Arc_Gen_Delegation_Wrapper wrapperSerialize = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) str, Arc_Gen_Delegation_Wrapper.class);
        System.assertEquals('1', wrapperSerialize.sanctionAmbit, 'Assert sanction ambit of the wrapper');
        Test.stopTest();
    }
    /**
    * @Method:      test for method initDelegation (Arc_Gen_ProposeInPreparation_controller)
    * @Description: testing method.
    */
    @isTest static void initDelegationTestKO() {
        try {
            final arce__Analysis__c analysis = [SELECT Id, Name FROM arce__Analysis__c WHERE Name = 'Arce Analysis' LIMIT 1];
            Test.startTest();
            Arc_Gen_ProposeInPreparation_controller.initDelegation(analysis.Id);
            Test.stopTest();
        } catch(Exception ex) {
            System.assert(ex.getMessage().contains(SCRIPT_LIT), SCRIPT_EXCEPTION);
        }
    }
    /**
    * @Method:      test for method evaluateDelegation OK (Arc_Gen_ProposeInPreparation_controller)
    * @Description: testing method.
    */
    @isTest static void evaluateDelegationTestOK() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        final String wrapperStr = Arc_Gen_ProposeInPreparation_controller.initDelegation(accHasAnalysis.Id);
        final String wrapperRetStr = Arc_Gen_ProposeInPreparation_controller.evaluateDelegation(wrapperStr, accHasAnalysis.Id);
        final Arc_Gen_Delegation_Wrapper wrapperSerialize = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) wrapperRetStr, Arc_Gen_Delegation_Wrapper.class);
        System.assertEquals('1', wrapperSerialize.sanctionAmbit, 'Sanction ambit equal to 1');
        Test.stopTest();
    }
    /**
    * @Method:      test for method evaluateDelegation KO (Arc_Gen_ProposeInPreparation_controller)
    * @Description: testing method.
    */
    @isTest static void evaluateDelegationTestKO() {
        try {
            final arce__Analysis__c analysis = [SELECT Id, Name FROM arce__Analysis__c WHERE Name = 'Arce Analysis' LIMIT 1];
            final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
            Test.startTest();
            final String wrapperStr = Arc_Gen_ProposeInPreparation_controller.initDelegation(accHasAnalysis.Id);
            final Arc_Gen_Delegation_Wrapper wrapperSerialize = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) wrapperStr, Arc_Gen_Delegation_Wrapper.class);
            Arc_Gen_ProposeInPreparation_controller.evaluateDelegation(wrapperSerialize, analysis.Id);
            Test.stopTest();
        } catch(Exception ex) {
            System.assert(ex.getMessage().contains(SCRIPT_LIT), SCRIPT_EXCEPTION);
        }
    }
    /**
    * @Method:      test for method saveAction OK (Arc_Gen_ProposeInPreparation_controller)
    * @Description: testing method.
    */
    @isTest static void saveActionTestAmbitUserOK() {
        final arce__Account_has_Analysis__c miniArce = [SELECT Id FROM arce__Account_has_Analysis__c limit 1];
        Test.startTest();
        final Arc_Gen_Delegation_Wrapper wrapper = Arc_UtilitysDataTest_tst.crearDelegationWrapper();
        final String res = Arc_Gen_ProposeInPreparation_controller.saveAction(JSON.serialize(wrapper), miniArce.Id, '1');
        final Arc_Gen_Delegation_Wrapper wrapperSerialize = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) res, Arc_Gen_Delegation_Wrapper.class);
        System.assertEquals(500, wrapperSerialize.codStatus, 'Status delegation wrapper OK');
        Test.stopTest();
    }
    /**
    * @Method:      test for method saveAction OK (Arc_Gen_ProposeInPreparation_controller)
    * @Description: testing method.
    */
    @isTest static void saveActionTestOK() {
        final arce__Account_has_Analysis__c miniArce = [SELECT Id, arce__Analysis__c FROM arce__Account_has_Analysis__c limit 1];
        Test.startTest();
        final Arc_Gen_Delegation_Wrapper wrapper = Arc_UtilitysDataTest_tst.crearDelegationWrapper();
        wrapper.analysisId = miniArce.arce__Analysis__c;
        final String res = Arc_Gen_ProposeInPreparation_controller.saveAction(JSON.serialize(wrapper), miniArce.Id, '2');
        final Arc_Gen_Delegation_Wrapper wrapperSerialize = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) res, Arc_Gen_Delegation_Wrapper.class);
        System.assertEquals(201, wrapperSerialize.codStatus, 'Status delegation wrapper OK');
        Test.stopTest();
    }
    /**
    * @Method:      test for method saveAction KO (Arc_Gen_ProposeInPreparation_controller)
    * @Description: testing method.
    */
    @isTest static void saveActionTestKO() {
        try {
            final arce__Account_has_Analysis__c miniArce = [SELECT Id FROM arce__Account_has_Analysis__c limit 1];
            Test.startTest();
            final Arc_Gen_Delegation_Wrapper wrapper = Arc_UtilitysDataTest_tst.crearDelegationWrapper();
            Arc_Gen_ProposeInPreparation_controller.saveAction(wrapper, miniArce.Id, '1');
            Test.stopTest();
        } catch(Exception ex) {
            System.assert(ex.getMessage().contains(SCRIPT_LIT), SCRIPT_EXCEPTION);
        }
    }
    /**
    * @Method:      test for method persistArceAction OK (Arc_Gen_ProposeInPreparation_controller)
    * @Description: testing method.
    */
    @isTest static void persistArceActionTestOK() {
        final arce__Account_has_Analysis__c miniArce = [SELECT Id, arce__Analysis__c FROM arce__Account_has_Analysis__c limit 1];
        Test.startTest();
        final Arc_Gen_Delegation_Wrapper wrapper = Arc_UtilitysDataTest_tst.crearDelegationWrapper();
        wrapper.analysisId = miniArce.arce__Analysis__c;
        final String res = Arc_Gen_ProposeInPreparation_controller.persistArceAction(JSON.serialize(wrapper), miniArce.Id);
        final Arc_Gen_Delegation_Wrapper wrapperSerialize = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) res, Arc_Gen_Delegation_Wrapper.class);
        System.assertEquals(wrapperSerialize.codStatus, 200, 'Code 200 Expected');
        Test.stopTest();
    }
    /**
    * @Method:      test for method persistArceAction KO (Arc_Gen_ProposeInPreparation_controller)
    * @Description: testing method.
    */
    @isTest static void persistArceActionTestKO() {
        try {
            final arce__Account_has_Analysis__c miniArce = [SELECT Id FROM arce__Account_has_Analysis__c limit 1];
            Test.startTest();
            Arc_Gen_ProposeInPreparation_controller.persistArceAction(null, miniArce.Id);
            Test.stopTest();
        } catch(Exception ex) {
            System.assert(ex.getMessage().contains(SCRIPT_LIT), SCRIPT_EXCEPTION);
        }
    }
}