/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_FinInfoGpTable_ctr_Test
* @Author   BBVA
* @Date     Created: 2020-04-20
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Controller class for Arc_Gen_FinInfoGroupTable component
* ------------------------------------------------------------------------------------------------
* @Changes
* |2020-04-14 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-06-26 mariohumberto.ramirez.contractor@bbva.com
*             Update test class
* |2020-08-11 javier.soto.carrascosa@bbva.com
*             Update sector field
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* -----------------------------------------------------------------------------------------------
*/
@isTest
public without sharing class Arc_Gen_FinInfoGpTable_ctr_Test {
    /**
    * --------------------------------------------------------------------------------------
    * @Description setup method
    * --------------------------------------------------------------------------------------
    **/
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001','C000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');
        final arce.Arc_Gen_Account_Wrapper clientAccount = groupAccWrapper.get('C000001');

        final arce__Sector__c newSector = Arc_UtilitysDataTest_tst.crearSector('Generic', '100', '1', null);
        insert newSector;

        final arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        insert newArce;

        final arce__Account_has_Analysis__c accHasAnGp = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, groupAccount.accId, '1');
        accHasAnGp.arce__group_asset_header_type__c = '1';
        accHasAnGp.arce__InReview__c = true;
        insert accHasAnGp;
        final arce__Account_has_Analysis__c accHasAnCl = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, clientAccount.accId, '1');
        accHasAnCl.arce__group_asset_header_type__c = '2';
        accHasAnCl.arce__InReview__c = true;
        insert accHasAnCl;
        final arce__Account_has_Analysis__c accHasAnCl2 = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, clientAccount.accId, '1');
        accHasAnCl2.arce__group_asset_header_type__c = '2';
        accHasAnCl2.arce__InReview__c = true;
        insert accHasAnCl2;

        final arce__rating__c rating = Arc_UtilitysDataTest_tst.crearRating(null);
        insert rating;

        final arce__Financial_Statements__c finStatement = Arc_UtilitysDataTest_tst.crearFinStatement(clientAccount.accId, accHasAnCl.id, rating.id, null);
        finStatement.arce__financial_statement_end_date__c = Date.today();
        finStatement.arce__financial_statement_id__c = '70202018129';
        finStatement.arce__ffss_valid_type__c = '1';
        finStatement.CurrencyIsoCode = 'EUR';
        insert finStatement;

        final arce__Financial_Statements__c finStatement2 = Arc_UtilitysDataTest_tst.crearFinStatement(clientAccount.accId, accHasAnCl.id, rating.id, null);
        finStatement2.arce__financial_statement_end_date__c = Date.today();
        finStatement2.arce__financial_statement_id__c = 'dummyFFSS';
        finStatement2.CurrencyIsoCode = 'EUR';
        insert finStatement2;

        final arce__Financial_Statements__c finStatement3 = Arc_UtilitysDataTest_tst.crearFinStatement(clientAccount.accId, accHasAnCl2.id, rating.id, null);
        finStatement3.arce__financial_statement_end_date__c = Date.today();
        finStatement3.arce__financial_statement_id__c = '70202018128';
        finStatement3.arce__ffss_valid_type__c = '1';
        finStatement3.CurrencyIsoCode = 'EUR';
        insert finStatement3;

        final arce__Data_Collections__c dataCollection = Arc_UtilitysDataTest_tst.crearDataCollection('Cash Flow Analysis', 'Cash_Flow_Analysis', '04');
        dataCollection.arce__collection_code_term__c = 'totalLiabilitiesAndEquity';
        insert dataCollection;

        final arce__Table_Content_per_Analysis__c tableCAnalysis = Arc_UtilitysDataTest_tst.crearTableContentAnalysis(accHasAnCl.id, dataCollection.id, 'Cash_Flow_Analysis', '2017');
        tableCAnalysis.arce__previous_valid__c = true;
        tableCAnalysis.arce__valid_fin_statement__c = true;
        insert tableCAnalysis;

        final arce__Table_Content_per_Analysis__c tableCAnalysis2 = Arc_UtilitysDataTest_tst.crearTableContentAnalysis(accHasAnCl2.id, dataCollection.id, 'Cash_Flow_Analysis', '2017');
        tableCAnalysis2.arce__previous_valid__c = true;
        tableCAnalysis2.arce__valid_fin_statement__c = true;
        insert tableCAnalysis2;

    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description test method
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testgetTableData() {
        Arc_Gen_FinInfoGroupTable_Ctrl.FinInfoTableGp wrapper = new Arc_Gen_FinInfoGroupTable_Ctrl.FinInfoTableGp();
        final arce__Account_has_Analysis__c accHasGp = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1'];
        Test.startTest();
        wrapper = Arc_Gen_FinInfoGroupTable_Ctrl.getTableData((String)accHasGp.Id);
        System.assertEquals(false, wrapper.tableFinValid.columns.isEmpty(), 'There is data to build the table');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description test method
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testemptyconstructor() {
        Test.startTest();
        final Arc_Gen_FinInfoGroupTable_Service service = new Arc_Gen_FinInfoGroupTable_Service();
        System.assertEquals(service, service, 'the test to the empty constructor was successfull');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description test method
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testemptyconstructor2() {
        Test.startTest();
        final Arc_Gen_FinInfoGroupTable_Ctrl controller = new Arc_Gen_FinInfoGroupTable_Ctrl();
        System.assertEquals(controller, controller, 'the test to the empty constructor was successfull');
        Test.stopTest();
    }
}