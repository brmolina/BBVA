/**
* @File Name          : Arc_Gen_UtilityBarFire_Test.cls
* @Description        : test for method class Arc_Gen_UtilityBarFire_Controller.
* @Author             : juanmanuel.perez.ortiz.contractor@bbva.com
* @Group              : ARCE
* @Last Modified By   : juanmanuel.perez.ortiz.contractor@bbva.com
* @Last Modified On   : 24/12/2019 12:35
* @Modification Log   :
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0    24/12/2019          juanmanuel.perez.ortiz.contractor@bbva.com     Initial Version
* 1.1    07/01/2020          javier.soto.carrascosa@bbva.com                Add support for account wrapper and setupaccounts
* 1.2    11/08/2020          javier.soto.carrascosa@bbva.com                Update sector field
* 1.2    23/09/2020     saimassimilianno.jordana.contractor@bbva.com        Added arce. namespace to all classes that are now in the arce-dependencies package
**/
@isTest
public class Arc_Gen_UtilityBarFire_Test {
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID2 = 'G000002';
    /**
    * @Description: String with external id of test group
    */
    static final string SUBSIDIARY_ID1 = 'C000001';
    /**
    * @Method:      method that creates the data to use in the test.
    * @Description: testing method.
    */
    @testSetup
    static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID2,SUBSIDIARY_ID1});
        final arce.Arc_Gen_Account_Wrapper groupAccount2 = groupAccWrapper.get(GROUP_ID2);
        final arce.Arc_Gen_Account_Wrapper childAccount1 = groupAccWrapper.get(SUBSIDIARY_ID1);
        final arce__Sector__c newSector1 = arc_UtilitysDataTest_tst.crearSector('Generic', '100;300;400', '1', null);
        insert newSector1;
        final arce__Analysis__c newArce1 = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, childAccount1.accId);
        newArce1.arce__Stage__c = '1';
        newArce1.arce__analysis_customer_relation_type__c = '01';
        insert newArce1;
        final arce__Account_has_Analysis__c newAnalysis1 = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector1.id, newArce1.Id, childAccount1.accId, '1');
        newAnalysis1.arce__group_asset_header_type__c = '2';
        newAnalysis1.arce__InReview__c = true;
        newAnalysis1.arce__path__c = 'MAC';
        insert newAnalysis1;
        final arce__Sector__c newSector = arc_UtilitysDataTest_tst.crearSector('Generic', '100;300;400', '1', null);
        insert newSector;
        final arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount2.accId);
        newArce.arce__Stage__c = '1';
        newArce.arce__analysis_customer_relation_type__c = '01';
        insert newArce;
        final arce__Account_has_Analysis__c newAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, groupAccount2.accId, '1');
        newAnalysis.arce__group_asset_header_type__c = '1';
        newAnalysis.arce__InReview__c = true;
        newAnalysis.arce__path__c = 'MAC';
        insert newAnalysis;
    }
    @isTest static void getAnalysisTest() {
        Test.startTest();
        final arce__Account_has_Analysis__c accHas = [SELECT Id,arce__Analysis__c FROM arce__Account_has_Analysis__c LIMIT 1];
        final String returnData = Arc_Gen_UtilityBarFire_Controller.getAnalysis(accHas.Id);
        System.assertEquals(accHas.arce__Analysis__c, returnData, 'The return match succesfully');
        Test.stopTest();
    }
}