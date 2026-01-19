/*------------------------------------------------------------------
*Author:        Mauricio luisarturo.parra.contractor@bbva.com / BBVA DWP
*Project:       ARCE - BBVA Bancomer
*Description:   test for method class Arc_Gen_groupTable_controller.
*_______________________________________________________________________________________
*Version    Date           Author                               Description
*1.0        17/06/2019     Esquivel Cázares Mauricio                    Creation.
*1.2        07/01/2020     javier.soto.carrascosa@bbva.com Add support for account wrapper and setupaccounts
*1.3        11/08/2020  javier.soto.carrascosa@bbva.com Update sector field
*1.3        23/09/2020     saimassimilianno.jordana.contractor@bbva.com Added arce. namespace to all classes that are now in the arce-dependencies package
-----------------------------------------------------------------------------------------*/
@isTest
public with sharing class Arc_Gen_groupTable_test {
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID = 'G000001';
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID2 = 'G000002';
    /**
    * @Description: String with external id of test subsidiary
    */
    static final string SUBSIDIARY_ID = 'C000001';
    /**
    * @Description: String with external id of test subsidiary
    */
    static final string SUBSIDIARY_ID2 = 'C000004';
    /**
    * @Method:      method that creates the data to use in the test.
    * @Description: testing method.
    */
    @testSetup
    static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,GROUP_ID2,SUBSIDIARY_ID,SUBSIDIARY_ID2});
        final arce.Arc_Gen_Account_Wrapper miniArceAcc1 = groupAccWrapper.get(SUBSIDIARY_ID);
        arce__Sector__c newSector1 = arc_UtilitysDataTest_tst.crearSector('Generic', '100;300;400', '1', null);
        insert newSector1;
        arce__Analysis__c newArce1 = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, miniArceAcc1.accId);
        newArce1.arce__Stage__c = '1';
        newArce1.arce__analysis_customer_relation_type__c = '01';
        insert newArce1;
        arce__Account_has_Analysis__c newAnalysis1 = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector1.id, newArce1.Id, miniArceAcc1.accId, '1');
        newAnalysis1.arce__group_asset_header_type__c = '2';
        newAnalysis1.arce__InReview__c = true;
        newAnalysis1.arce__path__c = 'MAC';
        insert newAnalysis1;
        final arce.Arc_Gen_Account_Wrapper noMiniArceAcc = groupAccWrapper.get(GROUP_ID2);
        arce__Sector__c newSector = arc_UtilitysDataTest_tst.crearSector('Generic', '100;300;400', '1', null);
        insert newSector;
        arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, noMiniArceAcc.accId);
        newArce.arce__Stage__c = '1';
        newArce.arce__analysis_customer_relation_type__c = '01';
        insert newArce;
        arce__Account_has_Analysis__c newAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, noMiniArceAcc.accId, '1');
        newAnalysis.arce__group_asset_header_type__c = '1';
        newAnalysis.arce__InReview__c = true;
        newAnalysis.arce__path__c = 'MAC';
        insert newAnalysis;

    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void testGroupAcc() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,GROUP_ID2,SUBSIDIARY_ID,SUBSIDIARY_ID2});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);

        Test.startTest();
        final List<arce.Arc_Gen_Account_Wrapper> wrapperLts = Arc_Gen_groupTable_controller.retrieveData(JSON.serialize(new List<arce.Arc_Gen_Account_Wrapper>{groupAccount}));
        system.assertEquals(wrapperLts.isEmpty(), false, 'There call was successfull');
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void testEmptyConstructor() {
        Test.startTest();
        Arc_Gen_groupTable_controller controller = new Arc_Gen_groupTable_controller();
        system.assertEquals(controller, controller, 'The test to the empty constructor was successfull');
        Test.stopTest();
    }
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @isTest static void testEmptyConstructor2() {
        Test.startTest();
        Arc_Gen_groupTable_service service = new Arc_Gen_groupTable_service();
        system.assertEquals(service, service, 'The test to the empty constructor was successfull');
        Test.stopTest();
    }
}