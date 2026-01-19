/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Validate_Customer_Ctrl_Test
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-05-22
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Test class for Arc_Gen_Validate_Customer_Controller, Arc_Gen_Validate_Customer_Service
* and Arc_Gen_Validate_Customer_Data.
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-05-23 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2019-06-04 mariohumberto.ramirez.contractor@bbva.com
*             Add new methods
* |2019-09-04 mariohumberto.ramirez.contractor@bbva.com
*             Added new lines of code in order to increment test coverage
* |2019-10-03 mariohumberto.ramirez.contractor@bbva.com
*             Added new lines of code in order to increment test coverage
* |2019-31-19 mariohumberto.ramirez.contractor@bbva.com
*             Added new lines of code in order to increment test coverage
* |2020-01-08 javier.soto.carrascosa@bbva.com
*             Adapt test classess with account wrapper and setupaccounts
* |2020-03-30 javier.soto.carrascosa@bbva.com
*             Add support for product static resource in test classes
* |2020-04-27 joseluis.garcia4.contractor@bbva.com
*             Modify test data to take into account new sector field.
* |2020-05-19 berthaelena.tellez.contractor@bbva.com
*             Modify test data to insert data persistance TL.
* |2020-07-13 joseluis.garcia4.contractor@bbva.com
*             Adapt test testError() to use null instead of invalid ID.
* |2020-08-11 javier.soto.carrascosa@bbva.com
*             Update sector field
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-11-19 joseluis.garcia4.contractor@bbva.com
*             Refers to custom metadata for creating sections and thus removing dependency
*             on user language when deploying.
* |2021-06-07 mariohumberto.ramirez.contractor@@bbva.com
*             Update test class
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:NcssMethodCount, sf:ExcessiveMethodLength')
@isTest
public without sharing class Arc_Gen_Validate_Customer_Ctrl_Test {
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
    static final string SUBSIDIARY_ID2 = 'C000003';
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
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID,SUBSIDIARY_ID2});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(SUBSIDIARY_ID);

        final arce__Analysis__c arceVar = Arc_UtilitysDataTest_tst.crearArceAnalysis('arceAnalysis', null, groupAccount.accId);
        arceVar.arce__analysis_customer_relation_type__c = '01';
        arceVar.arce__Stage__c = '2';
        arceVar.arce__anlys_wkfl_sub_process_type__c = '2';
        insert arceVar;

        arce__Sector__c newSector = arc_UtilitysDataTest_tst.crearSector('Generic', '100;200;300;400;500', '1', null);
        newSector.arce__sector_analisis_type__c = '2';
        newSector.arce__active_type__c = true;
        insert newSector;

        final arce__Account_has_Analysis__c accHasAnGp = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, arceVar.Id, groupAccount.accId, '1');
        accHasAnGp.arce__risk_request_desc__c = 'xxx';
        accHasAnGp.arce__arce_ctmr_flag__c = true;
        accHasAnGp.arce__InReview__c = true;
        accHasAnGp.arce__group_asset_header_type__c = '1';
        accHasAnGp.arce__magnitude_unit_type__c = '2';
        insert accHasAnGp;
        final arce__Account_has_Analysis__c accHasAnCl = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, arceVar.Id, childAccount.accId, '1');
        accHasAnCl.arce__risk_request_desc__c = 'xxx';
        accHasAnCl.arce__arce_ctmr_flag__c = true;
        accHasAnCl.arce__InReview__c = true;
        accHasAnCl.arce__group_asset_header_type__c = '2';
        accHasAnCl.arce__magnitude_unit_type__c = '3';
        accHasAnCl.arce__risk_policy_type__c = '1';
        arce__rating__c rating = Arc_Gen_ValidateRating_test.setRating('AAA', 90.0);
        arce__Financial_Statements__c ffss = Arc_Gen_ValidateRating_test.setFFSS(rating.Id, '1');
        accHasAnCl.arce__ffss_for_rating_id__c = ffss.Id;
        insert accHasAnCl;

        final dyfr__Template__c temp = Arc_UtilitysDataTest_tst.crearTemplate('s-01-500');
        insert temp;

        final dyfr__Tab__c tab = Arc_UtilitysDataTest_tst.crearTab('Policies', temp.Id);
        insert tab;

        final List<String> newSections = Arc_Gen_Validate_Customer_Data.getConfSectionName('s-01-500');
        final dyfr__Field_Config__c fieldConf = Arc_UtilitysDataTest_tst.crearfieldConfigData(null, tab.Id, 'arce__Analysis__r.arce__Stage__c');
        fieldConf.dyfr__DeveloperName__c = 'control';
        insert fieldConf;
        final dyfr__Field_Config__c fieldConf1 = Arc_UtilitysDataTest_tst.crearfieldConfigData(newSections[0], tab.Id, 'arce__risk_policy_type__c');
        fieldConf1.dyfr__DeveloperName__c = 'dev1';
        fieldConf1.dyfr__Important__c = true;
        insert fieldConf1;
        final dyfr__Field_Config__c fieldConf2 = Arc_UtilitysDataTest_tst.crearfieldConfigData(newSections[1], tab.Id, 'arce__risk_request_desc__c');
        fieldConf2.dyfr__DeveloperName__c = 'dev2';
        fieldConf2.dyfr__Visibility_control_field__c = 'dev1';
        fieldConf2.dyfr__Visibility_control_value__c = '1';
        fieldConf2.dyfr__Important__c = true;
        insert fieldConf2;
        final dyfr__Field_Config__c fieldConf3 = Arc_UtilitysDataTest_tst.crearfieldConfigData(newSections[2], tab.Id, 'arce__group_asset_header_type__c');
        fieldConf3.dyfr__DeveloperName__c = 'multiDep';
        fieldConf3.dyfr__Visibility_control_field__c = 'control;dev1';
        fieldConf3.dyfr__Visibility_control_value__c = '2;1';
        fieldConf3.dyfr__Important__c = true;
        insert fieldConf3;

        final arce__limits_typology__c limitTipoTP0005 = Arc_UtilitysDataTest_tst.crearLimitTypology('TOTAL Financial Risk ST & Commercial Risk', null, 'TP_0005');
        insert limitTipoTP0005;
        final arce__limits_typology__c limitTipologyTP0010 = Arc_UtilitysDataTest_tst.crearLimitTypology('Commercial Risk', limitTipoTP0005.Id, 'TP_0010');
        insert limitTipologyTP0010;
        final arce__limits_typology__c limitTipologyTP0012 = Arc_UtilitysDataTest_tst.crearLimitTypology('Financial Risk ST', limitTipoTP0005.Id, 'TP_0012');
        insert limitTipologyTP0012;
        final arce__limits_typology__c limitTipologyTP0003 = Arc_UtilitysDataTest_tst.crearLimitTypology('TOTAL CORPORATE RISK', null, 'TP_0003');
        insert limitTipologyTP0003;
        final arce__limits_typology__c limitTipologyTP0007 = Arc_UtilitysDataTest_tst.crearLimitTypology('TOTAL Financial Risk LT', null, 'TP_0007');
        insert limitTipologyTP0007;
        final arce__limits_typology__c limitTipologyTP0011 = Arc_UtilitysDataTest_tst.crearLimitTypology('Financial Risk LT - Unsecured - No real guarantee', limitTipologyTP0007.Id, 'TP_0011');
        insert limitTipologyTP0011;
        final arce__limits_typology__c limitTipologyTP0014 = Arc_UtilitysDataTest_tst.crearLimitTypology('Financial Risk LT - Secured - Real guarantee', limitTipologyTP0007.Id, 'TP_0014');
        insert limitTipologyTP0014;

        Arc_UtilitysDataTest_tst.setupProducts();
        final Map<Id,Arc_Gen_Product_Wrapper> pWrap = Arc_Gen_Product_Locator.getProductsFromTypology('');
        final Arc_Gen_Product_Wrapper prodWrapper = pWrap.get(new List<Id>(pWrap.keySet())[0]);

        Arc_UtilitysDataTest_tst createExposures = new Arc_UtilitysDataTest_tst();
        final arce__limits_exposures__c exposure1 = createExposures.crearExposures(limitTipoTP0005.Id, accHasAnCl.Id, 0);
        insert exposure1;
        final arce__limits_exposures__c exposure2 = createExposures.crearExposures(limitTipologyTP0010.Id, accHasAnCl.Id, 0);
        insert exposure2;
        final arce__limits_exposures__c exposure3 = createExposures.crearExposures(limitTipologyTP0012.Id, accHasAnCl.Id, 0);
        insert exposure3;
        final arce__limits_exposures__c exposure4 = createExposures.crearExposures(null, accHasAnCl.Id, 0);
        exposure4.arce__Product_id__c =  prodWrapper.productId;
        insert exposure4;
        final arce__limits_exposures__c exposure5 = createExposures.crearExposures(limitTipologyTP0003.Id, accHasAnCl.Id, 0);
        insert exposure5;
        final arce__limits_exposures__c exposure6 = createExposures.crearExposures(limitTipologyTP0007.Id, accHasAnCl.Id, 0);
        insert exposure6;
        final arce__limits_exposures__c exposure7 = createExposures.crearExposures(limitTipologyTP0011.Id, accHasAnCl.Id, 0);
        insert exposure7;
        final arce__limits_exposures__c exposure8 = createExposures.crearExposures(limitTipologyTP0014.Id, accHasAnCl.Id, 0);
        insert exposure8;

    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method that validates if the subsidiary needs fields to fill and if the
    * typologies and products exceed the parents
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @param void
    * @return 0
    * @example Arc_Gen_Validate_Customer_Ctrl_Test.testValidateClient()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testValidateClient() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID,SUBSIDIARY_ID2});
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(SUBSIDIARY_ID);

        final arce__Account_has_Analysis__c acchas = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__Customer__c =: childAccount.accId];

        final arce__limits_typology__c typoParent = [SELECT Id FROM arce__limits_typology__c WHERE arce__risk_typology_level_id__c = 'TP_0005'];
        arce__limits_exposures__c exposuresParent = [SELECT Id FROM arce__limits_exposures__c WHERE arce__account_has_analysis_id__c = :acchas.Id AND arce__limits_typology_id__c = :typoParent.Id];
        exposuresParent.arce__current_proposed_amount__c = 11;
        upsert exposuresParent;

        final arce__limits_typology__c typoChild = [SELECT Id FROM arce__limits_typology__c WHERE arce__risk_typology_level_id__c = 'TP_0010'];
        arce__limits_exposures__c exposuresChild = [SELECT Id FROM arce__limits_exposures__c WHERE arce__account_has_analysis_id__c = :acchas.Id AND arce__limits_typology_id__c = :typoChild.Id];
        exposuresChild.arce__current_proposed_amount__c = 12;
        exposuresChild.arce__limits_exposures_parent_id__c = exposuresParent.Id;
        upsert exposuresChild;
        final arce__limits_typology__c typoChild2 = [SELECT Id FROM arce__limits_typology__c WHERE arce__risk_typology_level_id__c = 'TP_0012'];
        arce__limits_exposures__c exposuresChild2 = [SELECT Id FROM arce__limits_exposures__c WHERE arce__account_has_analysis_id__c = :acchas.Id AND arce__limits_typology_id__c = :typoChild2.Id];
        exposuresChild2.arce__current_proposed_amount__c = -2;
        exposuresChild2.arce__limits_exposures_parent_id__c = exposuresParent.Id;
        upsert exposuresChild2;

        final arce__limits_typology__c typoTOTAL = [SELECT Id FROM arce__limits_typology__c WHERE arce__risk_typology_level_id__c = 'TP_0003'];
        arce__limits_exposures__c exposuresTOTAL = [SELECT Id FROM arce__limits_exposures__c WHERE arce__account_has_analysis_id__c = :acchas.Id AND arce__limits_typology_id__c = :typoTOTAL.Id];
        exposuresTOTAL.arce__current_proposed_amount__c = 10;
        upsert exposuresTOTAL;

        final Map<Id,Arc_Gen_Product_Wrapper> pWrap = Arc_Gen_Product_Locator.getProductsFromTypology('');
        final Arc_Gen_Product_Wrapper prodWrapper = pWrap.get(new List<Id>(pWrap.keySet())[0]);
        arce__limits_exposures__c exposuresProduct = [SELECT Id FROM arce__limits_exposures__c WHERE arce__account_has_analysis_id__c = :acchas.Id AND arce__Product_id__c = :prodWrapper.productId];
        exposuresProduct.arce__current_proposed_amount__c = 13;
        exposuresProduct.arce__limits_exposures_parent_id__c = exposuresChild.Id;
        upsert exposuresProduct;

        Test.startTest();
        final Arc_Gen_Validate_Customer_Controller.responseWrapper wrapper1 = Arc_Gen_Validate_Customer_Controller.validateCustomer(acchas.Id);
        system.assertEquals(wrapper1.gblResponse.isEmpty(), false, 'There are typologies and products that exceed the amount of his parents and missing fields');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Methodo that validates if the validation of the client was successful
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @param void
    * @return 0
    * @example Arc_Gen_Validate_Customer_Ctrl_Test.testValidateClient()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testValidateClientPass() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID,SUBSIDIARY_ID2});
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(SUBSIDIARY_ID);
        arce__Account_has_Analysis__c acchas = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__Customer__c =: childAccount.accId];
        acchas.arce__risk_policy_type__c = '1';
        upsert acchas;

        arce__Analysis__c arceVar = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        arceVar.arce__Stage__c = '1';
        update arceVar;

        Test.startTest();
        final Arc_Gen_Validate_Customer_Controller.responseWrapper wrapper2 = Arc_Gen_Validate_Customer_Controller.validateCustomer(acchas.Id);
        system.assertEquals(wrapper2.gblResponse.isEmpty(), true, 'The client Validation was Successfull');
        Test.stopTest();
    }


    /**
    * --------------------------------------------------------------------------------------
    * @Description Methodo that validates if the validation of the group was successful
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @param void
    * @return 0
    * @example Arc_Gen_Validate_Customer_Ctrl_Test.testGroupControllerValidated()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testGroupValidated() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID,SUBSIDIARY_ID2});
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(SUBSIDIARY_ID);
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);

        arce__Account_has_Analysis__c acchasGp = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__Customer__c =: groupAccount.accId];
        acchasGp.arce__risk_policy_type__c = '1';
        upsert acchasGp;

        arce__Account_has_Analysis__c acchas2Cl = [SELECT Id, arce__Analysis__c, arce__Customer__c FROM arce__Account_has_Analysis__c WHERE arce__Customer__c =: childAccount.accId];
        acchas2Cl.arce__arce_ctmr_flag__c = true;
        acchas2Cl.arce__risk_policy_type__c = '2';
        upsert acchas2Cl;

        arce__Analysis__c arceVar = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        arceVar.arce__Stage__c = '1';
        update arceVar;

        Test.startTest();
        final Arc_Gen_Validate_Customer_Controller.responseWrapper wrapper3 = Arc_Gen_Validate_Customer_Controller.validateCustomer(acchasGp.Id);
        system.assertEquals(wrapper3.gblResponse.isEmpty(), true, 'The group validation was Successfull');
        Test.stopTest();
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Method that validates if the client's flag is active
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @param void
    * @return 0
    * @example Arc_Gen_Validate_Customer_Ctrl_Test.testGroupControllerNoValidated()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testFlagClientFalse() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID,SUBSIDIARY_ID2});
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(SUBSIDIARY_ID);
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);
        final arce__Account_has_Analysis__c acchasGroup = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__Customer__c =: groupAccount.accId];
        arce__Account_has_Analysis__c acchas2Cli = [SELECT Id, arce__Analysis__c, arce__Customer__c FROM arce__Account_has_Analysis__c WHERE arce__Customer__c =: childAccount.accId];
        acchas2Cli.arce__arce_ctmr_flag__c = false;
        upsert acchas2Cli;

        Test.startTest();
        final Arc_Gen_Validate_Customer_Controller.responseWrapper wrapper4 = Arc_Gen_Validate_Customer_Controller.validateCustomer(acchasGroup.Id);
        system.assertEquals(wrapper4.gblResponse.isEmpty(), false, 'A client in the analysys is not validated');
        Test.stopTest();
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Method that validates if there are typologies of the affiliates greater
    * than those of the parents in quantity
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @param void
    * @return 0
    * @example Arc_Gen_Validate_Customer_Ctrl_Test.testGroupControllerSmaller()
    * --------------------------------------------------------------------------------------
    */
    @isTest static void testGroupSmaller() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID,SUBSIDIARY_ID2});
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(SUBSIDIARY_ID);
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);

        final arce__Account_has_Analysis__c acchasGp = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__Customer__c =: groupAccount.accId];
        final arce__Account_has_Analysis__c acchas2Cli = [SELECT Id, arce__Analysis__c, arce__Customer__c FROM arce__Account_has_Analysis__c WHERE arce__Customer__c =: childAccount.accId];

        final arce__limits_typology__c typoChild2 = [SELECT Id FROM arce__limits_typology__c WHERE arce__risk_typology_level_id__c = 'TP_0005'];
        arce__limits_exposures__c exposuresChild = [SELECT Id FROM arce__limits_exposures__c WHERE arce__account_has_analysis_id__c = :acchas2Cli.Id AND arce__limits_typology_id__c = :typoChild2.Id LIMIT 1];
        exposuresChild.arce__current_proposed_amount__c = 10;
        upsert exposuresChild;

        Arc_UtilitysDataTest_tst createExposures = new Arc_UtilitysDataTest_tst();
        final arce__limits_exposures__c exposureGp = createExposures.crearExposures(typoChild2.Id, acchasGp.Id, 0);
        upsert exposureGp;

        Test.startTest();
        final Arc_Gen_Validate_Customer_Controller.responseWrapper wrapper5 = Arc_Gen_Validate_Customer_Controller.validateCustomer(acchasGp.Id);
        system.assertEquals(wrapper5.gblResponse.isEmpty(), false, 'There are typologies that exceed the amount of the typologies group');
        acchasGp.arce__magnitude_unit_type__c = '1';
        acchas2Cli.arce__magnitude_unit_type__c = '4';
        update acchasGp;
        update acchas2Cli;
        final Arc_Gen_Validate_Customer_Controller.responseWrapper wrapper = Arc_Gen_Validate_Customer_Controller.validateCustomer(acchasGp.Id);
        system.assertEquals(wrapper.gblResponse.isEmpty(), false, 'There are typologies that exceed the amount of the typologies group');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method that validates if the group is an orphan
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @param void
    * @return 0
    * @example Arc_Gen_Validate_Customer_Ctrl_Test.testOrfanGroup()
    * --------------------------------------------------------------------------------------
    */
    @isTest static void testOrphanGroup() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID,SUBSIDIARY_ID2});
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(SUBSIDIARY_ID);
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);

        final arce__Account_has_Analysis__c acchasGp = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__Customer__c =: groupAccount.accId];
        final arce__Account_has_Analysis__c acchasClient = [SELECT Id, arce__Analysis__c, arce__Customer__c FROM arce__Account_has_Analysis__c WHERE arce__Customer__c =: childAccount.accId];
        delete acchasClient;

        final arce__Analysis__c arceVar = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        arceVar.arce__analysis_customer_relation_type__c = '02';
        update arceVar;

        Test.startTest();
        final Arc_Gen_Validate_Customer_Controller.responseWrapper wrapper6 = Arc_Gen_Validate_Customer_Controller.validateCustomer(acchasGp.Id);
        system.assertEquals(wrapper6.gblResponse.isEmpty(), false, 'There are fields missing to complete in the analysis');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method that return the exception in the catch
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @param void
    * @return 0
    * @example Arc_Gen_Validate_Customer_Ctrl_Test.testError()
    * --------------------------------------------------------------------------------------
    */
    @isTest static void testError() {
        Arc_Gen_Validate_Customer_Controller.responseWrapper wrapper6 = new Arc_Gen_Validate_Customer_Controller.responseWrapper();
        Test.startTest();
        try {
            wrapper6 = Arc_Gen_Validate_Customer_Controller.validateCustomer(null);
        } catch (QueryException ex) {
            wrapper6.responseError = ex.getMessage();
            system.assertEquals(wrapper6.responseError, 'List has no rows for assignment to SObject', 'There was an error');
        }
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for void contructor
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @param void
    * @return 0
    * @example Arc_Gen_Validate_Customer_Ctrl_Test.testContructor()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testContructor() {
        Test.startTest();
        Arc_Gen_Validate_Customer_Controller controller = new Arc_Gen_Validate_Customer_Controller();
        Arc_Gen_Validate_Customer_Service service = new Arc_Gen_Validate_Customer_Service();
        Arc_Gen_Validate_Customer_Data data = new Arc_Gen_Validate_Customer_Data();
        system.assertEquals(controller, controller, 'The test to void contructor was successfull');
        system.assertEquals(service, service, 'The test to void contructor was successfull');
        system.assertEquals(data, data, 'The test to void contructor was successfull');
        Test.stopTest();
    }
}