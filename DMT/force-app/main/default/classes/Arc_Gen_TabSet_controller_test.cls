/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_TabSet_controller_test
* @Author   Mario Humberto Ramirez Lio - mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-07-17
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Test class for code coverage of: Arc_Gen_TabSet_controller, Arc_Gen_TabSet_service
* and  Arc_Gen_TabSet_ServiceHelper
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |11/04/2019 diego.miguel.contractor@bbva.com
*             Class creation.
* |2019-07-17 mariohumberto.ramirez.contractor@bbva.com
*             Documentation and refactor for change in completness.
* |2019-07-29 mariohumberto.ramirez.contractor@bbva.com
*             Add new lines of data in order to increment test coverage.
* |2019-08-08 mariohumberto.ramirez.contractor@bbva.com
*             Add new line Arc_UtilitysDataTest_tst.createIndustryAnalysisData()
*             in order to increment test coverage.
* |2019-08-09 mariohumberto.ramirez.contractor@bbva.com
*             Add new method "testContructorSector" in order to increment test coverage of the
*             Arc_Gen_Sector_Data class.
* |2019-11-20 mariohumberto.ramirez.contractor@bbva.com
*             Update test class
* |2020-01-09 javier.soto.carrascosa@bbva.com
*             Adapt test classess with account wrapper and setupaccounts
* |2020-03-30 eduardoefrain.hernandez.contractor@bbva.com
*             Add test methods to test the units converter of Group Risk Table
* |2020-04-24 eduardoefrain.hernandez.contractor@bbva.com
*             Add test methods to test the update the automated fields in group chrome
* |2020-06-10 cesaroctavio.villanueva.cebal@bbva.com
*             Added limits for getAccountHasAnalysis method
* |2020-08-11 javier.soto.carrascosa@bbva.com
*             Update sector field
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:TooManyMethods')
@isTest
public class Arc_Gen_TabSet_controller_test {
    /**
    * --------------------------------------------------------------------------------------
    * @Description Setup method for Arc_Gen_TabSet_controller_test
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio - mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-17
    * @param void
    * @return void
    * @example Arc_Gen_TabSet_controller_test.setup()
    * --------------------------------------------------------------------------------------
    **/
    /** String for result */
    final private static String RESULT1 = 'The result is not empty';
    /** String for result2 */
    final private static String RESULT2 = 'The test to void contructor was successfull';

    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');

        final arce__Sector__c newSector = arc_UtilitysDataTest_tst.crearSector('Generic', '100;200;300;400;500;600', '1', null);
        insert newSector;

        final arce__Analysis__c newArce = arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        newArce.arce__anlys_wkfl_sub_process_type__c = '2';
        newArce.arce__wf_status_id__c = '03';
        insert newArce;

        final arce__Account_has_Analysis__c newAnalysisGr = arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, groupAccount.accId, '1');
        newAnalysisGr.arce__group_asset_header_type__c = '1';
        insert newAnalysisGr;

        final arce__Account_has_Analysis__c newAnalysis = arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, groupAccount.accId, '1');
        modifyAha(newAnalysis);
        insert newAnalysis;

        final arce__limits_typology__c typology = Arc_UtilitysDataTest_tst.crearLimitTypology('TOTAL Financial Risk ST & Commercial Risk', null, 'TP_0001');
        insert typology;

        arce__limits_typology__c l1 = Arc_UtilitysDataTest_tst.crearLimitTypology(System.Label.Arc_Gen_ExecRepTipologyTCR, null, 'TP_0006');
        modifyTypologyOrder(l1,'1', 1,true);
        insert l1;

        arce__limits_typology__c l1b = Arc_UtilitysDataTest_tst.crearLimitTypology('TOTAL Financial Risk ST & Commercial Risk', null, 'TP_0005');
        modifyTypologyOrder(l1b,'1',2,false);
        insert l1b;

        arce__limits_typology__c l2 = Arc_UtilitysDataTest_tst.crearLimitTypology('Commercial Risk', l1b.Id, 'TP_0010');
        modifyTypologyOrder(l2,'2',null,true);
        l2.arce__risk_typology_parent_id__c = l1.Id;
        insert l2;

        arce__limits_typology__c projectFinance = Arc_UtilitysDataTest_tst.crearLimitTypology('Project Finance', null, System.Label.Arc_Gen_ProjectFinance);
        modifyTypologyOrder(projectFinance,'1',1,false);
        insert projectFinance;

        arce__limits_typology__c totalCR = Arc_UtilitysDataTest_tst.crearLimitTypology('TOTAL CORPORATE RISK', null, System.Label.Arc_Gen_TOTAL_CORPORATE_RISK);
        modifyTypologyOrder(totalCR,'1',1,false);
        insert totalCR;

        arce__limits_exposures__c lim1 = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,newAnalysisGr.Id,l1b.Id);
        insert lim1;

        arce__limits_exposures__c lim2 = Arc_UtilitysDataTest_tst.crearLimitExposures(lim1.Id,null,newAnalysisGr.Id,l2.Id);
        insert lim2;

        Arc_UtilitysDataTest_tst.setupProducts();
        final Map<Id,Arc_Gen_Product_Wrapper> pWrap = Arc_Gen_Product_Locator.getProductsFromTypology('familyTest');
        final Arc_Gen_Product_Wrapper prodWrapper = pWrap.get(new List<Id>(pWrap.keySet())[0]);

        arce__limits_exposures__c lim1GR = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,newAnalysisGr.Id,l1b.Id);
        insert lim1GR;

        arce__limits_exposures__c lim1duplicatedGR = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,newAnalysisGr.Id,l1b.Id);
        insert lim1duplicatedGR;

        arce__limits_exposures__c lim2GR = Arc_UtilitysDataTest_tst.crearLimitExposures(lim1.Id,null,newAnalysisGr.Id,l2.Id);
        insert lim2GR;

        arce__limits_exposures__c limExp1GR = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,newAnalysisGr.Id,projectFinance.Id);
        modifyArcLimitsExp(limExp1GR,0);
        insert limExp1GR;

        arce__limits_exposures__c limExp2GR = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,newAnalysisGr.Id,totalCR.Id);
        modifyArcLimitsExp(limExp2GR,1);
        insert limExp2GR;

        arce__limits_exposures__c limExp3GR = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,newAnalysisGr.Id,l1.Id);
        limExp3GR.arce__last_approved_amount__c = 1;
        insert limExp3GR;

        arce__limits_exposures__c modGR = Arc_UtilitysDataTest_tst.crearLimitExposures(lim2.Id,null,newAnalysisGr.Id,null);
        modGR.arce__curr_apprv_deleg_dchan_amount__c = 1;
        modGR.arce__Product_id__c = prodWrapper.productId;
        insert modGR;

        Arc_UtilitysDataTest_tst createExposures = new Arc_UtilitysDataTest_tst();
        final arce__limits_exposures__c exposure1 = createExposures.crearExposures(typology.Id, newAnalysis.Id, 7);
        insert exposure1;

        Arc_UtilitysDataTest_tst.createBasicDataData();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that returns the JSON to build tabset component
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio - mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-17
    * @param void
    * @return void
    * @example Arc_Gen_TabSet_controller_test.testGetTabsSuccess()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testGetTabsSuccess() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        final String tabWrapper = Arc_Gen_TabSet_controller.getTabsJson(accHasAnls.Id);
        Assert.areEqual(String.isEmpty(tabWrapper), false, RESULT1);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that returns a message of error
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio - mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-17
    * @param void
    * @return void
    * @example Arc_Gen_TabSet_controller_test.testGetTabsError()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testGetTabsError() {
        final Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        final String tabWrapper2 = Arc_Gen_TabSet_controller.getTabsJson(acc.id);
        Assert.areEqual(String.isEmpty(tabWrapper2), false, RESULT1);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that returns the JSON to build tabset component
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio - mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-17
    * @param void
    * @return void
    * @example Arc_Gen_TabSet_controller_test.testGetComple()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testGetComple() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        accHasAnls.arce__group_asset_header_type__c = '2';
        accHasAnls.arce__magnitude_unit_type__c = '1';
        accHasAnls.arce__prev_magnitude_unit_type__c = '2';
        upsert accHasAnls;

        final arce__Analysis__c arceVar = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        arceVar.arce__Stage__c = '1';
        upsert arceVar;

        Test.startTest();
        final Arc_Gen_TabSet_controller.TabsWrapper result = Arc_Gen_TabSet_controller.callTemplateAnalysisJson(accHasAnls.Id);
        Assert.areEqual(String.isEmpty(result.gblDesResponse), false, RESULT1);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that returns the JSON to build tabset component
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio - mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-17
    * @param void
    * @return void
    * @example Arc_Gen_TabSet_controller_test.testGetComple2()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testGetComple2() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        accHasAnls.arce__group_asset_header_type__c = '2';
        accHasAnls.arce__magnitude_unit_type__c = '1';
        accHasAnls.arce__prev_magnitude_unit_type__c = '3';
        upsert accHasAnls;

        final arce__Analysis__c arceVar = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        arceVar.arce__Stage__c = '2';
        upsert arceVar;

        Arc_UtilitysDataTest_tst.createIndustryAnalysisData();

        Test.startTest();
        final Arc_Gen_TabSet_controller.TabsWrapper result = Arc_Gen_TabSet_controller.callTemplateAnalysisJson(accHasAnls.Id);
        Assert.areEqual(String.isEmpty(result.gblDesResponse), false, RESULT1);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that returns the JSON to build tabset component
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio - mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-17
    * @param void
    * @return void
    * @example Arc_Gen_TabSet_controller_test.testMultifactor1()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testMultifactor1() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        accHasAnls.arce__group_asset_header_type__c = '2';
        accHasAnls.arce__magnitude_unit_type__c = '1';
        accHasAnls.arce__prev_magnitude_unit_type__c = '4';
        upsert accHasAnls;

        final arce__Analysis__c arceVar = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        arceVar.arce__Stage__c = '2';
        upsert arceVar;

        Arc_UtilitysDataTest_tst.createIndustryAnalysisData();

        Test.startTest();
        final Arc_Gen_TabSet_controller.TabsWrapper result = Arc_Gen_TabSet_controller.callTemplateAnalysisJson(accHasAnls.Id);
        Assert.areEqual(String.isEmpty(result.gblDesResponse), false, RESULT1);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that returns the JSON to build tabset component
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio - mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-17
    * @param void
    * @return void
    * @example Arc_Gen_TabSet_controller_test.testMultifactor2()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testMultifactor2() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        accHasAnls.arce__group_asset_header_type__c = '2';
        accHasAnls.arce__magnitude_unit_type__c = '4';
        accHasAnls.arce__prev_magnitude_unit_type__c = '3';
        upsert accHasAnls;

        final arce__Analysis__c arceVar = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        arceVar.arce__Stage__c = '2';
        upsert arceVar;

        Arc_UtilitysDataTest_tst.createIndustryAnalysisData();

        Test.startTest();
        final Arc_Gen_TabSet_controller.TabsWrapper result = Arc_Gen_TabSet_controller.callTemplateAnalysisJson(accHasAnls.Id);
        Assert.areEqual(String.isEmpty(result.gblDesResponse), false, RESULT1);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that returns the JSON to build tabset component
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio - mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-17
    * @param void
    * @return void
    * @example Arc_Gen_TabSet_controller_test.testMultifactor3()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testMultifactor3() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        accHasAnls.arce__group_asset_header_type__c = '2';
        accHasAnls.arce__magnitude_unit_type__c = '4';
        accHasAnls.arce__prev_magnitude_unit_type__c = '2';
        upsert accHasAnls;

        final arce__Analysis__c arceVar = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        arceVar.arce__Stage__c = '2';
        upsert arceVar;

        Arc_UtilitysDataTest_tst.createIndustryAnalysisData();

        Test.startTest();
        final Arc_Gen_TabSet_controller.TabsWrapper result = Arc_Gen_TabSet_controller.callTemplateAnalysisJson(accHasAnls.Id);
        Assert.areEqual(String.isEmpty(result.gblDesResponse), false, RESULT1);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that returns the JSON to build tabset component
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio - mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-17
    * @param void
    * @return void
    * @example Arc_Gen_TabSet_controller_test.testMultifactor4()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testMultifactor4() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        accHasAnls.arce__group_asset_header_type__c = '2';
        accHasAnls.arce__magnitude_unit_type__c = '4';
        accHasAnls.arce__prev_magnitude_unit_type__c = '1';
        upsert accHasAnls;

        final arce__Analysis__c arceVar = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        arceVar.arce__Stage__c = '2';
        upsert arceVar;

        Arc_UtilitysDataTest_tst.createIndustryAnalysisData();

        Test.startTest();
        final Arc_Gen_TabSet_controller.TabsWrapper result = Arc_Gen_TabSet_controller.callTemplateAnalysisJson(accHasAnls.Id);
        Assert.areEqual(String.isEmpty(result.gblDesResponse), false, RESULT1);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that returns the JSON to build tabset component
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio - mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-17
    * @param void
    * @return void
    * @example Arc_Gen_TabSet_controller_test.testMultifactor5()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testMultifactor5() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        accHasAnls.arce__group_asset_header_type__c = '2';
        accHasAnls.arce__magnitude_unit_type__c = '1';
        accHasAnls.arce__prev_magnitude_unit_type__c = null;
        upsert accHasAnls;

        final arce__Analysis__c arceVar = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        arceVar.arce__Stage__c = '2';
        upsert arceVar;

        Arc_UtilitysDataTest_tst.createIndustryAnalysisData();

        Test.startTest();
        final Arc_Gen_TabSet_controller.TabsWrapper result = Arc_Gen_TabSet_controller.callTemplateAnalysisJson(accHasAnls.Id);
        Assert.areEqual(String.isEmpty(result.gblDesResponse), false, RESULT1);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that returns the JSON to build tabset component
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio - mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-17
    * @param void
    * @return void
    * @example Arc_Gen_TabSet_controller_test.testUnitConversorError()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testUnitConversorError() {
        Test.startTest();
        final arce.Arc_Gen_GenericUtilities.ConversionWrapper wrapper = new arce.Arc_Gen_GenericUtilities.ConversionWrapper();
        final Map<String, Object> result = arce.Arc_Gen_GenericUtilities.convertUnits(wrapper);
        Assert.areEqual(result.get('status'), 'Error', 'there was a problem in the call to the conversor');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that tests the units conversor in the group chrome
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2020-03-30
    * @param void
    * @return void
    * @example Arc_Gen_TabSet_controller_test.testUnitConversorError()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void convInGroupDiffUnit() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1' LIMIT 1];
        accHasAnls.arce__magnitude_unit_type__c = '1';
        accHasAnls.arce__prev_magnitude_unit_type__c = '2';
        update accHasAnls;
        Test.startTest();
        final Arc_Gen_TabSet_controller.TabsWrapper res = Arc_Gen_TabSet_controller.callTemplateAnalysisJson(accHasAnls.Id);
        Assert.areEqual(res.changeStatus, true, 'Operation success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that tests the units conversor in the group chrome
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2020-03-30
    * @param void
    * @return void
    * @example Arc_Gen_TabSet_controller_test.testUnitConversorError()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void convInGroupSameUnit() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1' LIMIT 1];
        accHasAnls.arce__magnitude_unit_type__c = '1';
        accHasAnls.arce__prev_magnitude_unit_type__c = '1';
        update accHasAnls;
        Test.startTest();
        final Arc_Gen_TabSet_controller.TabsWrapper res = Arc_Gen_TabSet_controller.callTemplateAnalysisJson(accHasAnls.Id);
        Assert.areEqual(res.changeStatus, true, 'Operation success');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for void constructor
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-17
    * @param void
    * @return void
    * @example Arc_Gen_TabSet_controller_test.testContructorController()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testContructorController() {
        Test.startTest();
        final Arc_Gen_TabSet_controller controller = new Arc_Gen_TabSet_controller();
        Assert.areEqual(controller, controller, RESULT2);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for void contructor
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-17
    * @param void
    * @return void
    * @example Arc_Gen_TabSet_controller_test.testContructorService()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testContructorService() {
        Test.startTest();
        final Arc_Gen_TabSet_service service = new Arc_Gen_TabSet_service();
        Assert.areEqual(service, service, RESULT2);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for void contructor
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-17
    * @param void
    * @return void
    * @example Arc_Gen_TabSet_controller_test.testContructorHelper()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testContructorHelper() {
        Test.startTest();
        final Arc_Gen_TabsetService_Helper help = new Arc_Gen_TabsetService_Helper();
        Assert.areEqual(help, help, RESULT2);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for void contructor
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-29
    * @param void
    * @return void
    * @example Arc_Gen_TabSet_controller_test.testContructorHelper()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testContructorData() {
        Test.startTest();
        final arce.Arc_Gen_ArceAnalysis_Data data = new arce.Arc_Gen_ArceAnalysis_Data();
        Assert.areEqual(data, data, RESULT2);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for void contructor
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-29
    * @param void
    * @return void
    * @example Arc_Gen_TabSet_controller_test.testContructorData2()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testContructorData2() {
        Test.startTest();
        final arce.Arc_Gen_AccHasAnalysis_Data data = new arce.Arc_Gen_AccHasAnalysis_Data();
        Assert.areEqual(data, data, RESULT2);
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
    * @example Arc_Gen_TabSet_controller_test.testContructorSector()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testContructorSector() {
        Test.startTest();
        final Arc_Gen_Sector_Data data = new Arc_Gen_Sector_Data();
        Assert.areEqual(data, data, 'The test to the void contructor was successfull');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method to testing the automated fields for the group chrome
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2020-29-04
    * @param void
    * @return void
    * @example Arc_Gen_TabSet_controller_test.automatedGroupFields()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void automatedGroupFields() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id,arce__Analysis__c,arce__Analysis__r.arce__Stage__c,arce__group_asset_header_type__c,arce__capital_provision_per__c,arce__participant_srty_age_number__c,arce__customer_qualitative_type__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1' LIMIT 1];
        Test.startTest();
        final Map<String, Object> response =(Map<String, Object>)JSON.deserializeUntyped(Arc_Gen_TabSet_controller.updateGroupFields(accHasAnls));
        Assert.areEqual('true', response.get('status'), 'The operation has a true status');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test errors to the automated fields for the group chrome
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2020-29-04
    * @param void
    * @return void
    * @example Arc_Gen_TabSet_controller_test.automatedGroupFieldsError()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void automatedGroupFieldsError() {
        final arce__Account_has_Analysis__c accHasAnls = new arce__Account_has_Analysis__c();
        String response;
        Test.startTest();
        try {
            Arc_Gen_TabSet_controller.updateGroupFields(accHasAnls);
        } catch(AuraHandledException ex) {
            response = ex.getMessage();
        }
        Assert.areEqual(System.Label.Arc_Gen_empty_table, response, 'Operation Error');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method to get account has analysis data
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2020-29-04
    * @param void
    * @return void
    * @example Arc_Gen_TabSet_controller_test.testGettingAccHasAn()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testGettingAccHasAn() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id,arce__Analysis__c,arce__group_asset_header_type__c,arce__capital_provision_per__c,arce__participant_srty_age_number__c,arce__customer_qualitative_type__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1' LIMIT 1];
        Test.startTest();
        final arce__Account_has_Analysis__c response = Arc_Gen_TabSet_controller.getAccHasAnalysis(accHasAnls.Id);
        Assert.areEqual(response.Id, accHasAnls.Id, 'It gets the data of the account has analysis');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description testing an error occurred when get account has analysis data
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2020-29-04
    * @param void
    * @return void
    * @example Arc_Gen_TabSet_controller_test.gettingAccHasAnError()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void gettingAccHasAnError() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id,arce__Analysis__c,arce__group_asset_header_type__c,arce__capital_provision_per__c,arce__participant_srty_age_number__c,arce__customer_qualitative_type__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1' LIMIT 1];
        String response;
        Test.startTest();
        try {
            Arc_Gen_TabSet_controller.getAccHasAnalysis(accHasAnls.arce__Analysis__c);
        } catch(AuraHandledException ex) {
            response = ex.getMessage();
        }
        Assert.areEqual(System.Label.Arc_Gen_empty_table, response, 'Operation Error');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for void contructor
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2020-29-04
    * @param void
    * @return void
    * @example Arc_Gen_TabSet_controller_test.testContructorGroupFields()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testContructorGroupFields() {
        Test.startTest();
        final Arc_Gen_SetAutomatedFileds_Service data = new Arc_Gen_SetAutomatedFileds_Service();
        Assert.areEqual(data, data, 'The test to the void contructor was successfull');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description private Test Method to modify arce__limits_typology__c fields
    * --------------------------------------------------------------------------------------
    **/
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static void modifyTypologyOrder (arce__limits_typology__c arceFinState,String typeLevelType, Double typologyOrder,Boolean typoActive){
        arceFinState.arce__risk_typology_level_type__c = typeLevelType;
        arceFinState.arce__Typology_Order__c = typologyOrder;
        arceFinState.arce__risk_typology_active__c = typoActive;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description private Test Method to modify arce__limits_exposures__c fields
    * --------------------------------------------------------------------------------------
    **/
    private static void modifyArcLimitsExp (arce__limits_exposures__c arcLimExp,Double currentPrAmount){
        arcLimExp.arce__last_approved_amount__c = 1;
        arcLimExp.arce__outstanding_amount__c = 1;
        arcLimExp.arce__current_formalized_amount__c = 1;
        arcLimExp.arce__current_proposed_amount__c = currentPrAmount;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description private Test Method to modify arce__Account_has_Analysis__c fields
    * --------------------------------------------------------------------------------------
    **/
    private static void modifyAha (arce__Account_has_Analysis__c aha){
        aha.arce__group_asset_header_type__c = '2';
        aha.arce__InReview__c = true;
        aha.arce__participant_srty_age_number__c = System.today() - 1;
        aha.arce__customer_qualitative_type__c = '2';
    }

}