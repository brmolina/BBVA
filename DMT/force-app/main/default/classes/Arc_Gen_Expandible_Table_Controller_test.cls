/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Expandible_Table_Controller_test
* @Author   Ricardo Almanza ricardo.almanza.contractor@bbva.com
* @Date     Created: 2019-06-28
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Test class for Expandible Table
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-06-28 ricardo.almanza.contractor@bbva.com
*             Class creation.
* |2019-08-09 mariohumberto.ramirez.contractor@bbva.com
*             Add new methods testContructor, testProduct2Contructor and testGenericContructor
*             in order to increment test coverage
* |2019-10-04 mariohumberto.ramirez.contractor@bbva.com
*             Add new lines of code in order to increment test coverage
* |2019-10-10 mariohumberto.ramirez.contractor@bbva.com
*             Added new method testSumTypologies
* |2019-10-10 mariohumberto.ramirez.contractor@bbva.com
*             Added new method testGetHeaderDate()
* |2020-01-09 javier.soto.carrascosa@bbva.com
*             Adapt test classess with account wrapper and setupaccounts
* |2020-02-07 mariohumberto.ramirez.contractor@bbva.com
*             Update test class
* |2020-03-30 javier.soto.carrascosa@bbva.com
*             Add support for product static resource in test classes
* |2020-03-30 eduardoefrain.hernandez.contractor@bbva.com
*             Add methods to test group risk table
* |2020-04-30 joseluis.garcia4.contractor@bbva.com
*             Adds new parameters to insertProducts.
* |2020-05-29 cesaroctavio.villanueva.cebal@bbva.com
*             Added validation for group info to set proposed amount
* |2020-08-11 javier.soto.carrascosa@bbva.com
*             Update sector field
* |2020-08-17 mariohumberto.ramirez.contractor@bbva.com
*             Update test class for hu renovation
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-10-14 juanignacio.hita.contractor@bbva.com
*             Add delLimitPersServiceTest, addLimitPersServiceTest, testLimitsContructor methods
* |2020-10-29 juanignacio.hita.contractor@bbva.com
*             Add limitsPersistenceTest methods
* |2020-11-17 joseluis.garcia4.contractor@bbva.com
*             Use approved field arce__limit_exposure_ext_ind_type__c for extended policies indicator.
* |2021-03-05 juanignacio.hita.contractor@bbva.com
*             Change getTypeOfAnalysisTest method
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:TooManyMethods, sf:ExcessiveMethodLength')
@isTest
public with sharing class Arc_Gen_Expandible_Table_Controller_test {
    /**
    * --------------------------------------------------------------------------------------
    * @Description Setup method for Arc_Gen_Validate_Customer_Controller_tst
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @param void
    * @return void
    * @example Arc_Gen_Validate_Customer_Controller_tst.setup()
    * --------------------------------------------------------------------------------------
    **/
    @SuppressWarnings('sf:NcssMethodCount')
    @testSetup static void setup() {
        arce.Arc_UtilitiesToTest_tst.enableBypass();
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001','C000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get('C000001');

        arce__limits_typology__c l1 = Arc_UtilitysDataTest_tst.crearLimitTypology(System.Label.Arc_Gen_ExecRepTipologyTCR, null, null);
        l1.arce__risk_typology_level_id__c = 'TP_0006';
        l1.arce__risk_typology_level_type__c = '1';
        l1.arce__Typology_Order__c = 1;
        l1.arce__risk_typology_active__c = true;
        l1.arce__risk_typo_ext_id__c = '999999999999';
        Insert l1;
        arce__limits_typology__c l1b = Arc_UtilitysDataTest_tst.crearLimitTypology('TOTAL Financial Risk ST & Commercial Risk', null, null);
        l1b.arce__risk_typology_level_id__c = 'TP_0005';
        l1b.arce__risk_typology_level_type__c = '1';
        l1b.arce__Typology_Order__c = 2;
        l1b.arce__risk_typo_ext_id__c = '000299999999';
        Insert l1b;
        arce__limits_typology__c l2 = Arc_UtilitysDataTest_tst.crearLimitTypology('Commercial Risk', l1b.Id, null);
        l2.arce__risk_typology_level_id__c = 'TP_0010';
        l2.arce__risk_typo_ext_id__c = '000200019999';
        l2.arce__risk_typology_active__c = true;
        l2.arce__risk_typology_level_type__c = '2';
        l2.arce__risk_typology_parent_id__c = l1.Id;
        Insert l2;
        arce__limits_typology__c projectFinance = Arc_UtilitysDataTest_tst.crearLimitTypology('Project Finance', null, null);
        projectFinance.arce__risk_typology_level_id__c = System.Label.Arc_Gen_ProjectFinance;
        projectFinance.arce__risk_typology_level_type__c = '1';
        projectFinance.arce__Typology_Order__c = 1;
        Insert projectFinance;
        arce__limits_typology__c totalCR = Arc_UtilitysDataTest_tst.crearLimitTypology('TOTAL CORPORATE RISK', null, null);
        totalCR.arce__risk_typology_level_id__c = System.Label.Arc_Gen_TOTAL_CORPORATE_RISK;
        totalCR.arce__risk_typology_level_type__c = '1';
        totalCR.arce__Typology_Order__c = 1;
        Insert totalCR;

        arce__Analysis__c analysis = Arc_UtilitysDataTest_tst.crearArceAnalysis('Test Analysis', null, groupAccount.accId);
        Insert analysis;

        arce__Sector__c sect = Arc_UtilitysDataTest_tst.crearSector('Executive Summ', '600', 'ExecSumm', null);
        Insert sect;

        Arc_UtilitysDataTest_tst.setupProducts();
        final Map<Id,Arc_Gen_Product_Wrapper> pWrap = Arc_Gen_Product_Locator.getProductsFromTypology('familyTest');
        final Arc_Gen_Product_Wrapper prodWrapper = pWrap.get(new List<Id>(pWrap.keySet())[0]);

        final arce__AHA_Extension__c ahaExt = new arce__AHA_Extension__c(
            arce__group_corporative__c = true
        );
        insert ahaExt;
        arce__Account_has_Analysis__c accHasAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(sect.Id, analysis.Id, childAccount.accId, '	s-01');
        accHasAnalysis.arce__group_asset_header_type__c = '2';
        accHasAnalysis.arce__AHA_Extension__c = ahaExt.Id;
        Insert accHasAnalysis;

        arce__Account_has_Analysis__c accHasAnalysis2 = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(sect.Id, analysis.Id, childAccount.accId, '	s-01');
        accHasAnalysis2.arce__group_asset_header_type__c = '2';
        accHasAnalysis2.arce__AHA_Extension__c = ahaExt.Id;
        Insert accHasAnalysis2;

        arce__Account_has_Analysis__c accHasAnalysisGr = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(sect.Id, analysis.Id, groupAccount.accId, '1');
        accHasAnalysisGr.arce__group_asset_header_type__c = '1';
        Insert accHasAnalysisGr;

        arce__limits_exposures__c lim1 = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,accHasAnalysis.Id,l1b.Id);
        Insert lim1;
        arce__limits_exposures__c lim1duplicated = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,accHasAnalysis.Id,l1b.Id);
        Insert lim1duplicated;
        arce__limits_exposures__c lim2 = Arc_UtilitysDataTest_tst.crearLimitExposures(lim1.Id,null,accHasAnalysis.Id,l2.Id);
        Insert lim2;
        arce__limits_exposures__c limExp1 = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,accHasAnalysis.Id,projectFinance.Id);
        limExp1.arce__last_approved_amount__c = 1;
        limExp1.arce__outstanding_amount__c = 1;
        limExp1.arce__current_formalized_amount__c = 1;
        limExp1.arce__current_proposed_amount__c = 0;

        Insert limExp1;
        arce__limits_exposures__c limExp2 = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,accHasAnalysis.Id,totalCR.Id);
        limExp2.arce__last_approved_amount__c = 1;
        limExp2.arce__outstanding_amount__c = 1;
        limExp2.arce__current_formalized_amount__c = 1;
        limExp2.arce__current_proposed_amount__c = 1;

        Insert limExp2;
        arce__limits_exposures__c limExp3 = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,accHasAnalysis.Id,l1.Id);
        limExp3.arce__last_approved_amount__c = 1;

        Insert limExp3;
        final arce__limits_exposures__c mod = Arc_UtilitysDataTest_tst.crearLimitExposures(lim2.Id,null,accHasAnalysis.Id,l1.Id);
        mod.arce__curr_apprv_deleg_dchan_amount__c = 1;
        mod.arce__Product_id__c = prodWrapper.productId;
        Insert mod;

        final arce__limits_exposures__c lim1GR = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,accHasAnalysisGr.Id,l1b.Id);
        Insert lim1GR;
        final arce__limits_exposures__c lim1duplicatedGR = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,accHasAnalysisGr.Id,l1b.Id);
        Insert lim1duplicatedGR;
        final arce__limits_exposures__c lim2GR = Arc_UtilitysDataTest_tst.crearLimitExposures(lim1.Id,null,accHasAnalysisGr.Id,l2.Id);
        Insert lim2GR;
        final arce__limits_exposures__c limExp1GR = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,accHasAnalysisGr.Id,projectFinance.Id);
        limExp1GR.arce__last_approved_amount__c = 1;
        limExp1GR.arce__outstanding_amount__c = 1;
        limExp1GR.arce__current_formalized_amount__c = 1;
        limExp1GR.arce__current_proposed_amount__c = 0;

        Insert limExp1GR;
        final arce__limits_exposures__c limExp2GR = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,accHasAnalysisGr.Id,totalCR.Id);
        limExp2GR.arce__last_approved_amount__c = 1;
        limExp2GR.arce__outstanding_amount__c = 1;
        limExp2GR.arce__current_formalized_amount__c = 1;
        limExp2GR.arce__current_proposed_amount__c = 1;

        Insert limExp2GR;
        final arce__limits_exposures__c limExp3GR = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,accHasAnalysisGr.Id,l1.Id);
        limExp3GR.arce__last_approved_amount__c = 1;

        Insert limExp3GR;
        final arce__limits_exposures__c modGR = Arc_UtilitysDataTest_tst.crearLimitExposures(lim2.Id,null,accHasAnalysisGr.Id,null);
        modGR.arce__curr_apprv_deleg_dchan_amount__c = 1;
        modGR.arce__Product_id__c = prodWrapper.productId;
        Insert modGR;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for policies table
    * --------------------------------------------------------------------------------------
    * @Author   Ricardo Almanza ricardo.almanza.contractor@bbva.com
    * @Date     Created: 2019-06-28
    * @param void
    * @return void
    * @example Arc_Gen_Expandible_Table_Controller_test.expandibleTable2()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void expandibleTable2() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final arce__Analysis__c arceVar = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        arceVar.arce__anlys_wkfl_sanction_rslt_type__c = '1';
        update arceVar;
        final Arc_Gen_Expandible_Table_Controller.ResponseWrapper respWrapp;
        try {
            respWrapp = Arc_Gen_Expandible_Table_Controller.dataResponse(accHasAnalysis.Id,'default');
            System.assert(respWrapp != null, 'Error expandibleTable2 method');
        } catch(Exception ex) {
            System.assertNotEquals(ex, null, 'Error controlado');
        }
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for getProducts method
    * --------------------------------------------------------------------------------------
    * @Author   alberto.martinez.carrero.contractor@bbva.com
    * @Date     Created: 2022-03-08
    * @param void
    * @return void
    * @example getProductsTest method
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void getProductsTest() {
        final Arc_Gen_Expandible_Table_Controller.ResponseWrapper respWrapp;
        try {
            respWrapp = Arc_Gen_Expandible_Table_Controller.getProducts('familyTest');
            System.assert(respWrapp != null, 'Error getProductsTest method');
        } catch(Exception ex) {
            System.assertNotEquals(ex, null, 'Error controlado');
        }
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for getRecordId method
    * --------------------------------------------------------------------------------------
    * @Author   alberto.martinez.carrero.contractor@bbva.com
    * @Date     Created: 2022-03-08
    * @param void
    * @return void
    * @example getRecordIdTest method
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void getRecordIdTest() {
        try {
            final String recId = Arc_Gen_Expandible_Table_Controller.getRecordId('TP_0006');
            System.assertNotEquals(recId, null, 'The recId exist');
        } catch(Exception ex) {
            System.assertNotEquals(ex, null, 'Error controlado');
        }
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for desactivateValidFlag method
    * --------------------------------------------------------------------------------------
    * @Author   alberto.martinez.carrero.contractor@bbva.com
    * @Date     Created: 2022-03-08
    * @param void
    * @return void
    * @example desactivateValidFlagTest method
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void desactivateValidFlagTest() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Arc_Gen_Expandible_Table_Controller.ResponseWrapper respWrapp;
        try {
            respWrapp = Arc_Gen_Expandible_Table_Controller.desactivateValidFlag(null, '');
            respWrapp = Arc_Gen_Expandible_Table_Controller.desactivateValidFlag(accHasAnalysis.Id, '');
            respWrapp = Arc_Gen_Expandible_Table_Controller.desactivateValidFlag(accHasAnalysis.Id, 'Active');
            System.assert(respWrapp != null, 'Error desactivateValidFlagTest method');
        } catch(Exception ex) {
            System.assertNotEquals(ex, null, 'Error controlado');
        }
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for deleteRecords method
    * --------------------------------------------------------------------------------------
    * @Author   alberto.martinez.carrero.contractor@bbva.com
    * @Date     Created: 2022-03-08
    * @param void
    * @return void
    * @example deleteRecordsTest method
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void deleteRecordsTest() {
        final arce__limits_exposures__c mod = [SELECT Id FROM arce__limits_exposures__c WHERE arce__limits_typology_id__r.name = 'Commercial Risk' LIMIT 1];
        try {
            System.debug('mod.Id es: ' + mod.Id);
            Map<String,String> delExpMap = Arc_Gen_Expandible_Table_Controller.deleteRecords(mod.Id);
            System.assertNotEquals(delExpMap, null, 'Borrado de modality completo');
        } catch(Exception ex) {
            System.assertNotEquals(ex, null, 'Error controlado');
        }
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-10-10
    * @param void
    * @return void
    * @example testSumTypologies()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testSumTypologies() {
        arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        accHasAnalysis.arce__limit_exposure_ext_ind_type__c = '1';
        update accHasAnalysis;
        arce__limits_typology__c totalCR = [SELECT Id FROM arce__limits_typology__c WHERE arce__risk_typology_level_id__c = 'TP_0003'];
        final arce__limits_exposures__c totalCRExposure = [SELECT Id FROM arce__limits_exposures__c WHERE arce__limits_typology_id__r.arce__risk_typology_level_id__c = 'TP_0003' LIMIT 1];
        totalCRExposure.arce__last_approved_amount__c = 1;
        totalCRExposure.arce__curr_approved_commited_amount__c = 1;
        totalCRExposure.arce__curr_apprv_uncommited_amount__c = 1;
        totalCRExposure.arce__current_formalized_amount__c = 1;
        totalCRExposure.arce__outstanding_amount__c = 1;
        totalCRExposure.arce__current_proposed_amount__c = 1;
        totalCRExposure.arce__current_approved_amount__c = 1;
        update totalCRExposure;
        final arce__limits_exposures__c projectFinance = [SELECT Id FROM arce__limits_exposures__c WHERE arce__limits_typology_id__r.arce__risk_typology_level_id__c = 'TP_0013' LIMIT 1];
        projectFinance.arce__last_approved_amount__c = 1;
        projectFinance.arce__curr_approved_commited_amount__c = 1;
        projectFinance.arce__curr_apprv_uncommited_amount__c = 1;
        projectFinance.arce__current_formalized_amount__c = 1;
        projectFinance.arce__outstanding_amount__c = 1;
        projectFinance.arce__current_proposed_amount__c = 1;
        projectFinance.arce__current_approved_amount__c = 1;
        update projectFinance;
        Arc_Gen_Expandible_Table_Controller.sumTypologies(accHasAnalysis.Id);
        try {
            delete totalCRExposure;
            arce__limits_exposures__c limExpErr = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,accHasAnalysis.Id,totalCR.Id);
            Insert limExpErr;
            Arc_Gen_Expandible_Table_Controller.sumTypologies(accHasAnalysis.Id);
        } catch (Exception e) {
            System.assertNotEquals(e, null, 'Error controlado');
        }
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-10-10
    * @param void
    * @return void
    * @example Arc_Gen_Expandible_Table_Controller_test.testGetHeaderDate()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testGetHeaderDate() {
        final arce__Analysis__c arceVar = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        arceVar.arce__analysis_risk_sanction_date__c = Date.today();
        update arceVar;
        arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        final String response = Arc_Gen_Expandible_Table_Controller.getHeaderDate(accHasAnalysis.Id);
        system.assertNotEquals('11-11-11', response, 'the date is not the same');
        Arc_Gen_ExpTable_Service_Helper.insertTypologies(accHasAnalysis.Id);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for void contructor
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-08-09
    * @param void
    * @return void
    * @example Arc_Gen_Expandible_Table_Controller_test.testContructor()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testContructor() {
        Test.startTest();
        final Arc_Gen_LimitsTypologies_Data data = new Arc_Gen_LimitsTypologies_Data();
        system.assertEquals(data, data, 'The test to the void contructor was successfull');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for void contructor
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-08-09
    * @param void
    * @return void
    * @example Arc_Gen_Expandible_Table_Controller_test.testContructor()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void groupRiskContructor() {
        Test.startTest();
        final Arc_Gen_GroupRiskDetailTable_service data = new Arc_Gen_GroupRiskDetailTable_service();
        system.assertEquals(data, data, 'The test to the void contructor was successfull');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for void contructor
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-08-09
    * @param void
    * @return void
    * @example Arc_Gen_Expandible_Table_Controller_test.testGenericContructor()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testGenericContructor() {
        Test.startTest();
        final arce.Arc_Gen_GenericUtilities data = new arce.Arc_Gen_GenericUtilities();
        system.assertEquals(data, data, 'The test to the void contructor was successfull');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for void contructor
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-08-09
    * @param void
    * @return void
    * @example Arc_Gen_Expandible_Table_Controller_test.Arc_Gen_LimitsExposures_Data()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testLimitExposureConst() {
        Test.startTest();
        final arce.Arc_Gen_LimitsExposures_Data data = new arce.Arc_Gen_LimitsExposures_Data();
        system.assertEquals(data, data, 'The test to the void contructor was successfull');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for policies table
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-02-06
    * @param void
    * @return void
    * @example Arc_Gen_Expandible_Table_Controller_test.testAutoExpTable()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testAutoExpTable() {
        arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        Arc_Gen_Expandible_Table_Controller.ResponseWrapper respWrapp = Arc_Gen_Expandible_Table_Controller.dataResponse(accHasAnalysis.Id,'Arc_Gen_Auto_ExpTable_Service');
        System.assertEquals(respWrapp.successResponse, true, 'Operation success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for policies table
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-02-06
    * @param void
    * @return void
    * @example Arc_Gen_Expandible_Table_Controller_test.testChangeServiceFlagSuccess()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testChangeServiceFlagSuccess() {
        arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        Arc_Gen_Expandible_Table_Controller.ResponseWrapper respWrapp = Arc_Gen_Expandible_Table_Controller.changeServiceFlag(accHasAnalysis.Id);
        System.assertEquals(respWrapp.successResponse, true, 'Operation success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for policies table
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-02-06
    * @param void
    * @return void
    * @example Arc_Gen_Expandible_Table_Controller_test.testChangeServiceFlagSuccess()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testChangeServiceFlagError() {
        Test.startTest();
        Arc_Gen_Expandible_Table_Controller.ResponseWrapper respWrapp = Arc_Gen_Expandible_Table_Controller.changeServiceFlag(null);
        System.assertEquals(respWrapp.successResponse, false, 'Operation Fail');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for policies table
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-02-06
    * @param void
    * @return void
    * @example Arc_Gen_Expandible_Table_Controller_test.testChangeServiceFlagSuccess()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testGetProductsSuccess() {
        Test.startTest();
        Arc_Gen_Expandible_Table_Controller.ResponseWrapper respWrapp = Arc_Gen_Expandible_Table_Controller.getProducts('TP_0010');
        System.assertEquals(respWrapp.successResponse, true, 'Operation Success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for policies table
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-02-06
    * @param void
    * @return void
    * @example Arc_Gen_Expandible_Table_Controller_test.testChangeServiceFlagSuccess()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testGetProductsFail() {
        Test.startTest();
        Arc_Gen_Expandible_Table_Controller.ResponseWrapper respWrapp = Arc_Gen_Expandible_Table_Controller.getProducts('nofamily');
        System.assertEquals(respWrapp.successResponse, false, 'Operation Fail');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for policies table
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-02-06
    * @param void
    * @return void
    * @example Arc_Gen_Expandible_Table_Controller_test.testInsertProductsOk()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testInsertProductsOk() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final Map<Id,Arc_Gen_Product_Wrapper> pWrap = Arc_Gen_Product_Locator.getProductsFromTypology('TP_0010');
        final Arc_Gen_Product_Wrapper prodWrapper = pWrap.get(new List<Id>(pWrap.keySet())[0]);
        final arce__limits_exposures__c limits = [SELECT Id FROM arce__limits_exposures__c LIMIT 1];
        Test.startTest();
        final Arc_Gen_Expandible_Table_Controller.ResponseWrapper respWrapp = Arc_Gen_Expandible_Table_Controller.insertProducts(accHasAnalysis.Id, 'TP_0010', prodWrapper.productId, limits.Id);
        System.assertEquals(respWrapp.successResponse, true, 'Operation Ok');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for policies table
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-02-06
    * @param void
    * @return void
    * @example Arc_Gen_Expandible_Table_Controller_test.testInsertProductsOk()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testInsertProductsFail() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final arce__limits_exposures__c limits = [SELECT Id FROM arce__limits_exposures__c LIMIT 1];
        Test.startTest();
        final Arc_Gen_Expandible_Table_Controller.ResponseWrapper respWrapp = Arc_Gen_Expandible_Table_Controller.insertProducts(accHasAnalysis.Id, 'TP_0010', null, limits.Id);
        System.assertEquals(respWrapp.successResponse, false, 'Operation Fail');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for policies table
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2020-03-27
    * @param void
    * @return void
    * @example Arc_Gen_Expandible_Table_Controller_test.updGroupRiskDetailTable()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void updGroupRiskDetailTable() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        final String res = Arc_Gen_Expandible_Table_Controller.setLimitsToAha(accHasAnalysis.Id);
        final Map<String, Object> resp = (Map<String, Object>)JSON.deserializeUntyped(res);
        System.assertEquals((String)resp.get('status'), 'true', 'Operation success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for policies table
    * --------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-08-11
    * @param void
    * @return void
    * @example getTypeOfAnalysisTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void getTypeOfAnalysisTest() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        final List<Object> obj = (List<Object>) JSON.deserializeUntyped(Arc_Gen_Expandible_Table_Controller.getTypeOfAnalysis(accHasAnalysis.Id));
        System.assertEquals(obj[0], null, 'Operation success');
        Test.stopTest();
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for persistenceLimitsConstructor
    * --------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     Created: 2020-10-14
    * @param    void
    * @return   void
    * @example  Arc_Gen_Expandible_Table_Controller_test.testLimitsContructor()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testLimitsServiceContructor() {
        Test.startTest();
        final Arc_Gen_PersistenceLimits_service data = new Arc_Gen_PersistenceLimits_service();
        system.assertEquals(data, data, 'The test to the void contructor was successfull');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for persistenceLimitsConstructor
    * --------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     Created: 2020-10-14
    * @param    void
    * @return   void
    * @example  Arc_Gen_Expandible_Table_Controller_test.testLimitsContructor()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testLimitsHelperContructor() {
        Test.startTest();
        final Arc_Gen_PersistenceLimits_helper limitHelper = new Arc_Gen_PersistenceLimits_helper();
        system.assertEquals(limitHelper, limitHelper, 'The test to the void contructor was successfull');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for addLimitPersService method
    * --------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     Created: 2020-10-14
    * @param    void
    * @return   void
    * @example  addLimitPersServiceTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void addLimitPersServiceTest() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id, arce__limit_exposure_ext_ind_type__c FROM arce__Account_has_Analysis__c LIMIT 1];
        final arce__limits_exposures__c limits = [SELECT Id FROM arce__limits_exposures__c LIMIT 1];
        Test.startTest();
        Boolean retStatus = Arc_Gen_Expandible_Table_Controller.addLimitPersService(accHasAnalysis.Id, limits.Id);
        System.assertEquals(retStatus, true, 'Assert addLimitPersService method');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for delLimitPersServiceTest method
    * --------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     Created: 2020-10-14
    * @param    void
    * @return   void
    * @example  delLimitPersServiceTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void delLimitPersServiceTest() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final arce__limits_exposures__c limits = [SELECT Id FROM arce__limits_exposures__c LIMIT 1];
        Test.startTest();
        Boolean retStatus = Arc_Gen_Expandible_Table_Controller.delLimitPersService(accHasAnalysis.Id, limits.Id);
        System.assertEquals(retStatus, true, 'Assert delLimitPersService method');
        Test.stopTest();
    }
}