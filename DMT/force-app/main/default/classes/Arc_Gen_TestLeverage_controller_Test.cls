/**
* @File Name          : Arc_Gen_TestLeverage_controller_Test.cls
* @Description        : Test class for the test leverage section
* @Author             : eduardoefrain.hernandez.contractor@bbva.com
* @Group              : ARCE - Test Leverage
* @Changes   :
*===================================================================================================
* Ver         Date                     Author                Modification
* =================================================================================================
* 1.0    30/4/2019   17:56:32   eduardoefrain.hernandez.contractor@bbva.com     Initial Version
* 1.1    23/7/2019   17:56:32   luisruben.quinto.munoz@bbva.com                 Refactor Test clases Test Leveraged
* 1.1.1  2/12/2019   13:52:35   german.sanchez.perez.contractor@bbva.com
*                               franciscojavier.bueno@bbva.com                  Api names modified with the correct name on business glossary
* 1.1.2  8/1/2020    18:21:09   javier.soto.carrascosa@bbva.com                 Adapt test classess with account wrapper and setupaccounts
* 1.1.2  8/1/2020    12:11:19   mariohumberto.ramirez.contractor@bbva.com       update test class
* 1.2    21/05/2020  16:30:00   cesaroctavio.villanueva.cebal@bbva.com          Modified error validation method
* 1.3    04/06/2020  18:00:45   cesaroctavio.villanueva.cebal@bbva.com          Modified methods for test leverage
* 1.4    29/06/2020  18:00:45   eduardoefrain.hernandez.contractor@bbva.com     Added methods to test persistance
* 1.5    30/06/2020  09:00:00   joseluis.garcia4.contractor@bbva.com            Change references to PoliciesWrapper
* 1.6    07/07/2020  18:00:45   juanmanuel.perez.ortiz.contractor@bbva.com      Added methods to test persistancetestCalculateLeveraged
* 1.7    12/08/2020  09:00:00   joseluis.garcia4.contractor@bbva.com            Added methods to test currency exchange
* 1.8    18/09/2020  09:00:00   joseluis.garcia4.contractor@bbva.com            Fix leveraged test for groups
* 1.9    23/09/2020     saimassimilianno.jordana.contractor@bbva.com            Added arce. namespace to all classes that are now in the arce-dependencies package
* 1.10    02/02/2021  17:13:00   luisdavid.rivera.ortiz@bbva.com                 Eliminated unused fields
**/
@SuppressWarnings('sf:NullAssignment,sf:TooManyMethods')
@isTest
public class Arc_Gen_TestLeverage_controller_Test {
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID = 'G000001';
    /**
    * @Description: String with external id of test subsidiary
    */
    static final string SUBSIDIARY_ID = 'C000001';
    /**
    * @Description: 'EUR' literal
    */
    static final string EUR_LIT = 'EUR';
    /**
    * @Description: 'AAA' literal
    */
    static final string AAA_LIT = 'AAA';
    /**
    * @Description: LEV_ERROR_LIT
    */
    static final string LEV_ERROR_LIT = 'The leveraged  test cannot be done until the total limit for the group is set-up or the rating is calculated';
    /**
    * @Description: 'false' literal
    */
    static final string FINAL_LIT = 'false';
    /**
    * @Description: 'Status test Leverage' literal
    */
    static final string STATUS_TEST_LIT = 'Status test Leverage';
    /**
    * @Description: 'CCC' literal
    */
    static final string CCC_LIT = 'CCC';
    /**
    * @Description: 'Success' literal
    */
    static final string SUCCESS_LIT = 'Success';
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
@testSetup
    static void insertData() {
        arce.Arc_UtilitiesToTest_tst.enableBypass();
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);
        final arce.Arc_Gen_Account_Wrapper clientAccount = groupAccWrapper.get(SUBSIDIARY_ID);
        final Account accforArceHasAn = new Account(Id=groupAccount.accId);
        accforArceHasAn.CurrencyIsoCode = EUR_LIT;
        accforArceHasAn.Rating = 'Hot';
        accforArceHasAn.controlled_by_sponsor_type__c  =  '1';
        update accforArceHasAn;

        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(SUBSIDIARY_ID);
        final Account kid = new Account(Id=childAccount.accId);
        kid.CurrencyIsoCode = EUR_LIT;
        kid.Rating = 'Hot';
        kid.controlled_by_sponsor_type__c = '1';
        upsert kid;

        final arce__Sector__c sect = Arc_UtilitysDataTest_tst.crearSector('Executive Summ', '500', 'ExecSumm', null);
        Insert sect;

        final arce__Analysis__c arceobj  =  Arc_UtilitysDataTest_tst.crearArceAnalysis('arce__Analysisobj', null, groupAccount.accId);
        arceobj.arce__analysis_customer_relation_type__c = '01';
        arceobj.arce__controlled_by_sponsor_type__c = '1';
        arceobj.CurrencyIsoCode = EUR_LIT;
        insert arceobj;

        final arce__Account_has_Analysis__c arceAccHasAnObj  =  Arc_UtilitysDataTest_tst.crearAccHasAnalysis(sect.Id, arceobj.Id, groupAccount.accId, '  s-01');
        modifyAha(arceAccHasAnObj);
        arceAccHasAnObj.arce__group_asset_header_type__c = '1';
        insert arceAccHasAnObj;

        final arce__Account_has_Analysis__c accHasAnCl = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(sect.Id, arceobj.Id, clientAccount.accId, '  s-01');
        modifyAha(accHasAnCl);
        accHasAnCl.arce__group_asset_header_type__c = '2';
        insert accHasAnCl;

        final arce__rating__c ratingobj  =  Arc_UtilitysDataTest_tst.crearRating(null);
        modifyArceRating(ratingobj);
        insert ratingobj;

        arce__Financial_Statements__c arceFinState  =  Arc_UtilitysDataTest_tst.crearFinStatement(accforArceHasAn.id,accHasAnCl.Id , ratingobj.Id, null);
        modifyArceFinStatement(arceFinState);
        insert arceFinState;

        accHasAnCl.arce__ffss_for_rating_id__c = arceFinState.Id;
        update accHasAnCl;

        arceAccHasAnObj.arce__ffss_for_rating_id__c = arceFinState.Id;
        update arceAccHasAnObj;

        final arce__limits_typology__c projectFinance = Arc_UtilitysDataTest_tst.crearLimitTypology('Project Finance', null, null);
        projectFinance.arce__risk_typology_level_id__c = 'TP_0013';
        projectFinance.arce__risk_typology_level_type__c = '1';
        projectFinance.arce__Typology_Order__c = 1;
        insert projectFinance;
        final arce__limits_typology__c totalCR = Arc_UtilitysDataTest_tst.crearLimitTypology('TOTAL CORPORATE RISK', null, null);
        totalCR.arce__risk_typology_level_id__c = 'TP_0003';
        totalCR.arce__risk_typology_level_type__c = '1';
        totalCR.arce__Typology_Order__c = 1;
        insert totalCR;

        final arce__limits_exposures__c proyectFinExp  = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,arceAccHasAnObj.Id,projectFinance.Id);
        proyectFinExp.arce__current_proposed_amount__c  =  0;
        insert proyectFinExp;
        final arce__limits_exposures__c totalCRExp  = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,arceAccHasAnObj.Id,totalCR.Id);
        totalCRExp.arce__current_proposed_amount__c  =  10;
        insert totalCRExp;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testMethod1() {
        Test.startTest();
            final List<arce__Account_has_Analysis__c> acc = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2'];
            Arc_Gen_TestLeverage_controller.setupLeverage(acc[0].Id);
            final Arc_Gen_TestLeverage_service.leverageTestResponse leverage  =  new Arc_Gen_TestLeverage_service.leverageTestResponse();
            leverage.leveragedVariables = null;
            leverage.message = LEV_ERROR_LIT;
            leverage.status = FINAL_LIT;
            system.assertEquals( FINAL_LIT,leverage.status,STATUS_TEST_LIT);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testMethod2() {
        final List<arce__Account_has_Analysis__c> acc = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2'];
        final List<arce__rating__c> rating = [select Id from arce__rating__c where currencyIsoCode = :EUR_LIT];
        rating[0].arce__rating_short_value_type__c = CCC_LIT;
        update rating;
        Test.startTest();
        Arc_Gen_TestLeverage_controller.setupLeverage(acc[0].Id);
        final Arc_Gen_TestLeverage_service.leverageTestResponse leverage  =  new Arc_Gen_TestLeverage_service.leverageTestResponse();
        leverage.leveragedVariables = null;
        leverage.message = LEV_ERROR_LIT;
        leverage.status = FINAL_LIT;
        system.assertEquals( FINAL_LIT,leverage.status,STATUS_TEST_LIT);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testMethod3() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper clientAccount = groupAccWrapper.get(SUBSIDIARY_ID);
        final Account accC = new Account(Id=clientAccount.accId);
        accC.controlled_by_sponsor_type__c  =  '2';
        update accC;
        final List<arce__Account_has_Analysis__c> acc = [SELECT Id,arce__Analysis__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2'];
        final arce__Analysis__c analysisToUpd = [SELECT Id, arce__controlled_by_sponsor_type__c FROM arce__Analysis__c WHERE Id =: acc[0].arce__Analysis__c];
        analysisToUpd.arce__controlled_by_sponsor_type__c = '2';
        update analysisToUpd;
        final List<arce__rating__c> rating = [SELECT Id FROM arce__rating__c WHERE currencyIsoCode = :EUR_LIT];
        rating[0].arce__rating_short_value_type__c = 'BBB';
        update rating;
        Test.startTest();
        Arc_Gen_TestLeverage_controller.setupLeverage(acc[0].Id);
        final Arc_Gen_TestLeverage_service.leverageTestResponse leverage  =  new Arc_Gen_TestLeverage_service.leverageTestResponse();
        leverage.leveragedVariables = null;
        leverage.message = LEV_ERROR_LIT;
        leverage.status = FINAL_LIT;
        system.assertEquals( FINAL_LIT,leverage.status,STATUS_TEST_LIT);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testMethod4() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper clientAccount = groupAccWrapper.get(SUBSIDIARY_ID);
        final Account accC = new Account(Id=clientAccount.accId);
        accC.controlled_by_sponsor_type__c  =  '2';
        update accC;
        final List<arce__Account_has_Analysis__c> acc = [SELECT Id,arce__Analysis__c  FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2'];
        final arce__Analysis__c analysisToUpd = [SELECT Id, arce__controlled_by_sponsor_type__c FROM arce__Analysis__c WHERE Id =: acc[0].arce__Analysis__c];
        analysisToUpd.arce__controlled_by_sponsor_type__c = '2';
        update analysisToUpd;
        final List<arce__rating__c> rating = [select Id from arce__rating__c where currencyIsoCode = :EUR_LIT];
        rating[0].arce__rating_short_value_type__c = CCC_LIT;
        update rating;
        Test.startTest();
        Arc_Gen_TestLeverage_controller.setupLeverage(acc[0].Id);
        final Arc_Gen_TestLeverage_service.leverageTestResponse leverage  =  new Arc_Gen_TestLeverage_service.leverageTestResponse();
        leverage.leveragedVariables = null;
        leverage.message = LEV_ERROR_LIT;
        leverage.status = FINAL_LIT;
        SYSTEM.assertEquals( FINAL_LIT,leverage.status,STATUS_TEST_LIT);
        Test.stopTest();
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testMethod5() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper clientAccount = groupAccWrapper.get(SUBSIDIARY_ID);
        final Account accC = new Account(Id=clientAccount.accId);
        accC.controlled_by_sponsor_type__c  =  '2';
        update accC;
        final List<arce__Account_has_Analysis__c> acc = [SELECT Id,arce__Analysis__c,arce__smes_eur_comuty_defn_type__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2'];
        final arce__Analysis__c analysisToUpd = [SELECT Id, arce__controlled_by_sponsor_type__c FROM arce__Analysis__c WHERE Id =: acc[0].arce__Analysis__c];
        analysisToUpd.arce__controlled_by_sponsor_type__c = '2';
        update analysisToUpd;
        acc[0].arce__smes_eur_comuty_defn_type__c  =  '2';
        update acc[0];
        final List<arce__rating__c> rating = [select Id from arce__rating__c where currencyIsoCode = :EUR_LIT];
        rating[0].arce__rating_short_value_type__c = CCC_LIT;
        update rating;
        Test.startTest();
        Arc_Gen_TestLeverage_controller.setupLeverage(acc[0].Id);
        final Arc_Gen_TestLeverage_service.leverageTestResponse leverage  =  new Arc_Gen_TestLeverage_service.leverageTestResponse();
        leverage.leveragedVariables = null;
        leverage.message = LEV_ERROR_LIT;
        leverage.status = FINAL_LIT;
        system.assertEquals( FINAL_LIT,leverage.status,STATUS_TEST_LIT);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testMethod6() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper clientAccount = groupAccWrapper.get(SUBSIDIARY_ID);
        final Account accC = new Account(Id=clientAccount.accId);
        accC.controlled_by_sponsor_type__c  =  '2';
        update accC;
        final List<arce__Account_has_Analysis__c> acc = [SELECT Id,arce__Analysis__c,arce__smes_eur_comuty_defn_type__c,arce__gross_financial_debt_local_amount__c,arce__ebitda_interest_local_number__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2'];
        final arce__Analysis__c analysisToUpd = [SELECT Id, arce__controlled_by_sponsor_type__c FROM arce__Analysis__c WHERE Id =: acc[0].arce__Analysis__c];
        analysisToUpd.arce__controlled_by_sponsor_type__c = '2';
        update analysisToUpd;
        acc[0].arce__smes_eur_comuty_defn_type__c  =  '2';
        acc[0].arce__gross_financial_debt_local_amount__c = 5000000;
        acc[0].arce__ebitda_interest_local_number__c = 1000000;
        update acc[0];
        final List<arce__rating__c> rating = [select Id from arce__rating__c where currencyIsoCode = :EUR_LIT];
        rating[0].arce__rating_short_value_type__c = CCC_LIT;
        update rating;
        Test.startTest();
        Arc_Gen_TestLeverage_controller.setupLeverage(acc[0].Id);
        final Arc_Gen_TestLeverage_service.leverageTestResponse leverage  =  new Arc_Gen_TestLeverage_service.leverageTestResponse();
        leverage.leveragedVariables = null;
        leverage.message = LEV_ERROR_LIT;
        leverage.status = FINAL_LIT;
        system.assertEquals( FINAL_LIT,leverage.status,STATUS_TEST_LIT);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testMethod7() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper clientAccount = groupAccWrapper.get(SUBSIDIARY_ID);
        final Account accC = new Account(Id=clientAccount.accId);
        accC.controlled_by_sponsor_type__c  =  '2';
        update accC;
        final List<arce__Account_has_Analysis__c> acc = [SELECT Id,arce__Analysis__c,arce__smes_eur_comuty_defn_type__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2'];
        final arce__Analysis__c analysisToUpd = [SELECT Id, arce__controlled_by_sponsor_type__c FROM arce__Analysis__c WHERE Id =: acc[0].arce__Analysis__c];
        analysisToUpd.arce__controlled_by_sponsor_type__c = '2';
        update analysisToUpd;
        acc[0].arce__smes_eur_comuty_defn_type__c  =  '2';
        acc[0].arce__debt_comt_not_disb_local_amount__c = 10000004.0;
        acc[0].arce__ebitda_interest_local_number__c = 10000004.0;
        acc[0].arce__ll_adj_deb_excl_amount__c = 10000004.0;
        acc[0].arce__ll_adj_debt_auditor_amount__c = 10000004.0;
        acc[0].arce__ll_adj_ebitda_auditor_amount__c = 10000004.0;
        acc[0].arce__ll_adj_ebitda_excl_amount__c = 10000004.0;
        acc[0].arce__gross_financial_debt_local_amount__c = 168678787778.0;
        acc[0].arce__ll_other_adj_debt_amount__c = 10000004.0;
        acc[0].arce__ll_other_adj_ebitda_amount__c = 10000004.0;
        acc[0].arce__total_asset_local_amount__c = 9999998.0;
        acc[0].arce__current_proposed_local_amount__c = 9999999999999999.0;
        update acc[0];
        final List<arce__rating__c> rating = [select Id from arce__rating__c where currencyIsoCode = :EUR_LIT];
        rating[0].arce__rating_short_value_type__c = CCC_LIT;
        update rating;
        Test.startTest();
        Arc_Gen_TestLeverage_controller.setupLeverage(acc[0].Id);
        final Arc_Gen_TestLeverage_service.leverageTestResponse leverage  =  new Arc_Gen_TestLeverage_service.leverageTestResponse();
        leverage.leveragedVariables = null;
        leverage.message = LEV_ERROR_LIT;
        leverage.status = FINAL_LIT;
        system.assertEquals( FINAL_LIT,leverage.status,STATUS_TEST_LIT);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testLeveragedLower5Million() {
        Test.startTest();
        final List<arce__Account_has_Analysis__c> accSub = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2'];
        accSub[0].arce__current_proposed_amount__c = 6;   // MXN (millions)
        accSub[0].arce__currency_id__c = 'MXN';
        final List<arce__Account_has_Analysis__c> accGrp = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1'];
        accGrp[0].arce__currency_id__c = 'MXN';
        update accSub;
        update accGrp;
        final Arc_Gen_TestLeverage_service.leverageTestResponse leverage = Arc_Gen_TestLeverage_controller.setupLeverage(accSub[0].Id);
        system.assertEquals('NO', leverage.leveragedVariables[0], 'Leveraged indicator must be set to false');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testLeveragedGreater5Million() {
        Test.startTest();
        final List<arce__Account_has_Analysis__c> accSub = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2'];
        accSub[0].arce__current_proposed_amount__c = 200;   // MXN (millions)
        final List<arce__Account_has_Analysis__c> accGrp = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1'];
        accGrp[0].arce__currency_id__c = 'MXN';
        update accSub;
        update accGrp;
        final Arc_Gen_TestLeverage_service.leverageTestResponse leverage = Arc_Gen_TestLeverage_controller.setupLeverage(accSub[0].Id);
        system.assertEquals('YES', leverage.leveragedVariables[0], 'Leveraged indicator must be set to true');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testLeverageEmptyConst() {
        Test.startTest();
        final List<arce__Account_has_Analysis__c> acc = [SELECT Id,arce__current_proposed_local_amount__c,arce__Analysis__c,arce__smes_eur_comuty_defn_type__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2'];
        acc[0].arce__current_proposed_local_amount__c = 0;
        update acc[0];
        final Arc_Gen_TestLeverage_controller controller = new Arc_Gen_TestLeverage_controller();
        Arc_Gen_TestLeverage_controller.setupLeverage(acc[0].Id);
        system.assertEquals(controller,controller,'The test to the empty constructor was successfully');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testLeverageError1() {
        final List<arce__Account_has_Analysis__c> acc = [SELECT Id,arce__current_proposed_local_amount__c,arce__Analysis__c,arce__smes_eur_comuty_defn_type__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2'];
        acc[0].arce__current_proposed_local_amount__c = null;
        update acc[0];

        Test.startTest();
        final Arc_Gen_TestLeverage_service.leverageTestResponse leverage = Arc_Gen_TestLeverage_controller.setupLeverage(acc[0].Id);
        system.assertEquals(FINAL_LIT,leverage.status,LEV_ERROR_LIT);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testLeverageError2() {
        final List<arce__Account_has_Analysis__c> acc = [SELECT Id,arce__current_proposed_local_amount__c,arce__Analysis__c,arce__smes_eur_comuty_defn_type__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2'];
        final List<arce__rating__c> rating = [select Id from arce__rating__c where currencyIsoCode = :EUR_LIT];
        rating[0].arce__rating_short_value_type__c = '';
        update rating;
        Test.startTest();
        final Arc_Gen_TestLeverage_service.leverageTestResponse leverage = Arc_Gen_TestLeverage_controller.setupLeverage(acc[0].Id);
        system.assertEquals(FINAL_LIT,leverage.status,LEV_ERROR_LIT);
        Test.stopTest();
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testLeverageError3() {
        final List<arce__Account_has_Analysis__c> acc = [SELECT Id,arce__Analysis__c,arce__smes_eur_comuty_defn_type__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2'];
        final arce__limits_exposures__c totalCredExp = [SELECT Id FROM arce__limits_exposures__c WHERE arce__limits_typology_id__r.arce__risk_typology_level_id__c = 'TP_0003'];
        totalCredExp.arce__current_proposed_amount__c = -1;
        update totalCredExp;

        final arce__Analysis__c analysis = [SELECT Id, arce__controlled_by_sponsor_type__c FROM arce__Analysis__c WHERE Id =: acc[0].arce__Analysis__c ];
        analysis.arce__controlled_by_sponsor_type__c = '';
        update analysis;

        Test.startTest();
        final Arc_Gen_TestLeverage_service.leverageTestResponse leverage = Arc_Gen_TestLeverage_controller.setupLeverage(acc[0].Id);
        system.assertEquals(FINAL_LIT,leverage.status,LEV_ERROR_LIT);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testLeverageError4() {
        final List<arce__Account_has_Analysis__c> acc = [SELECT Id,arce__current_proposed_local_amount__c,arce__Analysis__c,arce__smes_eur_comuty_defn_type__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2'];
        acc[0].arce__smes_eur_comuty_defn_type__c = null;
        update acc[0];

        Test.startTest();
        final Arc_Gen_TestLeverage_service.leverageTestResponse leverage = Arc_Gen_TestLeverage_controller.setupLeverage(acc[0].Id);
        system.assertEquals(FINAL_LIT,leverage.status,LEV_ERROR_LIT);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testLeverageError5() {
        final List<arce__Account_has_Analysis__c> acc = [SELECT Id,arce__current_proposed_local_amount__c,arce__Analysis__c,arce__smes_eur_comuty_defn_type__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2'];
        acc[0].arce__employees_number__c = null;
        update acc[0];

        Test.startTest();
        final Arc_Gen_TestLeverage_service.leverageTestResponse leverage = Arc_Gen_TestLeverage_controller.setupLeverage(acc[0].Id);
        system.assertEquals(FINAL_LIT,leverage.status,LEV_ERROR_LIT);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testLeveragePersistence() {
        final List<arce__Account_has_Analysis__c> acc = [SELECT Id,arce__smes_eur_comuty_defn_type__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2'];

        Test.startTest();
        final Arc_Gen_Persistence_Leverage_Service.PoliciesWrapper leverage = Arc_Gen_Validate_Customer_Controller.leveragePersistence(acc[0].Id);
        system.assertEquals(true,leverage.success,SUCCESS_LIT);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testLeveragePersistenceError() {
        Test.startTest();
        final Arc_Gen_Persistence_Leverage_Service.PoliciesWrapper leverage = Arc_Gen_Validate_Customer_Controller.leveragePersistence(null);
        system.assertEquals(Label.Arc_Gen_EmptyList,leverage.messageError,'There was an error calling the persistence service');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void persistLeverageEmptyConst() {
        Test.startTest();
        Arc_Gen_Persistence_Leverage_Service controller = new Arc_Gen_Persistence_Leverage_Service();
        system.assertEquals(controller,controller,'The test to the empty constructor was successfully');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void persistHelperEmptyConst() {
        Test.startTest();
        Arc_Gen_Persistence_Leverage_Helper controller = new Arc_Gen_Persistence_Leverage_Helper();
        system.assertEquals(controller,controller,'The test to the empty constructor was successfully');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void leveragePersistenceGroup() {
        List<arce__Account_has_Analysis__c> acc = [SELECT Id,arce__group_asset_header_type__c,arce__smes_eur_comuty_defn_type__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1'];

        Test.startTest();
        final Arc_Gen_Persistence_Leverage_Service.PoliciesWrapper leverage = Arc_Gen_Persistence_Leverage_Service.callPersistence(acc);
        system.assertEquals(true,leverage.success,SUCCESS_LIT);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testCovenantType() {
        final String apiFieldName = 'arce__entity_covenants_type__c';
        Test.startTest();
        List<arce__Account_has_Analysis__c> acc = [SELECT Id,arce__entity_covenants_type__c,arce__smes_eur_comuty_defn_type__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2'];
        acc[0].arce__entity_covenants_type__c = '1';
        update acc;
        String response = Arc_Gen_Persistence_Leverage_Helper.getCovenantType(new List<sObject>{acc[0]}, apiFieldName);
        acc[0].arce__entity_covenants_type__c = '2';
        update acc;
        response = Arc_Gen_Persistence_Leverage_Helper.getCovenantType(new List<sObject>{acc[0]}, apiFieldName);
        acc[0].arce__entity_covenants_type__c = '3';
        update acc;
        response = Arc_Gen_Persistence_Leverage_Helper.getCovenantType(new List<sObject>{acc[0]}, apiFieldName);
        acc[0].arce__entity_covenants_type__c = '4';
        update acc;
        response = Arc_Gen_Persistence_Leverage_Helper.getCovenantType(new List<sObject>{acc[0]}, apiFieldName);
        system.assertNotEquals(null,response,SUCCESS_LIT);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testClasificationAdj() {
        final String apiFieldName = 'arce__ll_before_adj_clsfn_type__c';
        Test.startTest();
        List<arce__Account_has_Analysis__c> acc = [SELECT Id,arce__ll_before_adj_clsfn_type__c,arce__smes_eur_comuty_defn_type__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2'];
        acc[0].arce__ll_before_adj_clsfn_type__c = 'NI';
        update acc;
        String response = Arc_Gen_Persistence_Leverage_Helper.getClasificationsAdj(new List<sObject>{acc[0]}, apiFieldName);
        acc[0].arce__ll_before_adj_clsfn_type__c = 'FS';
        update acc;
        response = Arc_Gen_Persistence_Leverage_Helper.getClasificationsAdj(new List<sObject>{acc[0]}, apiFieldName);
        acc[0].arce__ll_before_adj_clsfn_type__c = 'R4';
        update acc;
        response = Arc_Gen_Persistence_Leverage_Helper.getClasificationsAdj(new List<sObject>{acc[0]}, apiFieldName);
        acc[0].arce__ll_before_adj_clsfn_type__c = 'R6';
        update acc;
        response = Arc_Gen_Persistence_Leverage_Helper.getClasificationsAdj(new List<sObject>{acc[0]}, apiFieldName);
        system.assertNotEquals(null,response,SUCCESS_LIT);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void persistenceAnalysisType() {
        final String apiFieldName = 'arce__ffss_for_rating_id__r.arce__ffss_submitted_type__c';
        List<arce__Account_has_Analysis__c> acc = [SELECT Id,arce__ffss_for_rating_id__r.arce__ffss_submitted_type__c,arce__ffss_for_rating_id__c,arce__smes_eur_comuty_defn_type__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2'];
        List<arce__Financial_Statements__c> ffss = [SELECT Id, arce__ffss_submitted_type__c FROM arce__Financial_Statements__c WHERE Id =: acc[0].arce__ffss_for_rating_id__c];
        ffss[0].arce__ffss_submitted_type__c = '2';
        update acc;
        Test.startTest();
        String response = Arc_Gen_Persistence_Leverage_Helper.getTypeOfAnalysis(new List<sObject>{acc[0]}, apiFieldName);
        system.assertNotEquals(null,response,SUCCESS_LIT);
        Test.stopTest();
    }
    @isTest
    static void testCalculateLeveraged() {
        Test.startTest();
            List<arce__Account_has_Analysis__c> acc=[select Id,arce__smes_eur_comuty_defn_type__c,arce__Analysis__r.id,arce__employees_number__c,arce__Analysis__r.arce__controlled_by_sponsor_type__c,
                                                      arce__ffss_for_rating_id__c,arce__ffss_for_rating_id__r.arce__rating_final__c,
                                                      arce__Customer__r.controlled_by_sponsor_type__c,arce__ll_adj_debt_amount__c,
                                                      arce__debt_comt_not_disb_local_amount__c,arce__ebitda_interest_number__c,
                                                      arce__ebitda_interest_local_number__c,
                                                      arce__ll_adj_deb_excl_amount__c,
                                                      arce__ll_adj_debt_auditor_amount__c,
                                                      arce__ll_adj_ebitda_auditor_amount__c,
                                                      arce__ll_adj_ebitda_excl_amount__c,
                                                      arce__gross_financial_debt_local_amount__c,arce__gross_financial_debt_amount__c,
                                                      arce__ll_other_adj_debt_amount__c,
                                                      arce__ll_other_adj_ebitda_amount__c,
                                                      arce__total_asset_local_amount__c,
                                                      arce__current_proposed_amount__c
                                                      FROM arce__Account_has_Analysis__c
                                                      LIMIT 1
                                                    ];
        System.assertEquals( Arc_Gen_TestLeverage_service.calculateLeverage(Arc_Gen_TestLeverage_service.setupLeverageVariables(acc[0],'before', 1.0), acc[0]), acc[0], 'Account to validate');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description private Test Method to modify arce__Account_has_Analysis__c fields
    * --------------------------------------------------------------------------------------
    **/
    private static void modifyAha(arce__Account_has_Analysis__c aha) {
        aha.currencyIsoCode = EUR_LIT;
        aha.arce__smes_eur_comuty_defn_type__c = '1';
        aha.arce__ll_before_adj_ind_type__c = '1';
        aha.arce__ll_before_adj_clsfn_type__c = 'NI';
        aha.arce__ll_after_adj_ind_type__c = '1';
        aha.arce__ll_after_adj_clsfn_type__c = 'NI';
        aha.arce__current_proposed_local_amount__c = 99999999999.0;
        aha.arce__employees_number__c = 300;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description private Test Method to modify arce__rating__c fields
    * --------------------------------------------------------------------------------------
    **/
    private static void modifyArceRating(arce__rating__c ratingobj) {
        ratingobj.arce__adj_long_rating_value_type__c = 'AAA';
        ratingobj.arce__adj_short_rating_value_type__c = 'AAA';
        ratingobj.arce__adj_total_rating_score_number__c = 1;
        ratingobj.CurrencyIsoCode = EUR_LIT;
        ratingobj.arce__rating_long_value_type__c = 'AAA';
        ratingobj.arce__rating_short_value_type__c = 'AAA';
        ratingobj.arce__manual_rating_value_type__c = 'AAA';
        ratingobj.arce__pd_per__c = 50;
        ratingobj.arce__long_rating_value_type__c = 'AAA';
        ratingobj.arce__short_rating_value_type__c = 'AAA';
        ratingobj.arce__total_rating_score_number__c = 1;
        ratingobj.arce__status_type__c = '1';
        ratingobj.arce__rating_user_id__c = '938098';
        ratingobj.arce__data_adjusted_score_number__c = 3.0;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description private Test Method to modify arce__Financial_Statements__c fields
    * --------------------------------------------------------------------------------------
    **/
    private static void modifyArceFinStatement(arce__Financial_Statements__c arceFinState) {
        arceFinState.arce__ffss_adjusted_type__c = '1';
        arceFinState.arce__ffss_auditor_qlfn_type__c = '1';
        arceFinState.arce__ffss_auditor_opinion_type__c = 'S';
        arceFinState.arce__ffss_auditor_opinion_desc__c = '1';
        arceFinState.arce__ffss_certification_type__c = 'AUDITED';
        arceFinState.CurrencyIsoCode = EUR_LIT;
        arceFinState.arce__financial_statement_end_date__c = SYSTEM.TODAY()+30;
        arceFinState.arce__financial_statement_id__c = 'id test';
        arceFinState.Name = '1';
        arceFinState.arce__status_type__c = '1';
        arceFinState.arce__ffss_submitted_type__c = '1';
        arceFinState.arce__ffss_valid_type__c = '1';
        arceFinState.arce__economic_month_info_number__c = '544';
        arceFinState.arce__financial_statement_start_date__c = SYSTEM.TODAY()+26;
        arceFinState.arce__financial_statement_start_date__c = SYSTEM.TODAY()+27;
    }
}