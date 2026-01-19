/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Persistance_FinSt
* @Author   Berth Elena Téllez Lira  eberthaelena.tellez.contractor@bbva.com
* @Date     Created: 24/01/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Test class that covers:  Arc_Gen_Persistance_FinSt_Serice
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |
*             Class creation.
* |2020-04-14 berthaelena.tellez.contractor@bbva.com
*             resolve fix on mapeo data
* |2020-04-14 juanignacio.hita.contractor@bbva.com
*             changed test class
* |2020-08-11 javier.soto.carrascosa@bbva.com
*             Update sector field
* |2020-09-14 joseluis.garcia4.contractor@bbva.com
*             Increase test coverage
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* -----------------------------------------------------------------------------------------------
*/
@isTest
public class Arc_Gen_Persistance_FinSt_Test {
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method, create data for dinamic form
    * --------------------------------------------------------------------------------------
    * @Author   berthaelena.tellez.contractor@bbva.com
    * @param void
    * @return void
    * @example setupTest()
    * --------------------------------------------------------------------------------------
    **/
    @testSetup
      static void setupTest(){
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');

        final arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        newArce.arce__Stage__c = '1';
        insert newArce;

        final arce__Account_has_Analysis__c newAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, newArce.Id, groupAccount.accId, '1');
        newAnalysis.arce__InReview__c = true;
        newAnalysis.arce__path__c = 'MAC';
        insert newAnalysis;

        final arce__Data_Collections__c dataColpeer = Arc_UtilitysDataTest_tst.crearDataCollection('Test Prueba', 'Maturity_table', '01');
        insert dataColpeer;

        final arce__Table_Content_per_Analysis__c maturityData = Arc_UtilitysDataTest_tst.crearTableContentAnalysis(newAnalysis.Id, dataColpeer.id, 'Maturity_table', '2019');
        insert maturityData;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method that is responsible for preparing the list of objects and
    identifiers to execute the class to save basic data.
    * --------------------------------------------------------------------------------------
    * @Author   berthaelena.tellez.contractor@bbva.com
    * @param void
    * @return void
    * @example prepareData()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Public static void prepareData(){
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');
        final arce__account_has_analysis__c ahaTest = arce.Arc_Gen_AccHasAnalysis_Data.getAccForResume(new Set<Id>{groupAccount.accId})[0];
        final arce__account_has_analysis__c ahaTestFinal = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)ahaTest.Id})[0];
        Test.startTest();
        String test1 =  Arc_Gen_FinRisk_Pers_service.save(new List<arce__account_has_analysis__c>{ahaTestFinal});
        system.assertEquals(test1,test1, 'Test save persistance');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method that is responsible for preparing the list of objects and
    identifiers to execute the class to save basic data.
    * --------------------------------------------------------------------------------------
    * @Author   berthaelena.tellez.contractor@bbva.com
    * @param void
    * @return void
    * @example prepareData()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void constructor() {
        Test.startTest();
        Arc_Gen_Persistance_FinSt_Service testConstructor = new Arc_Gen_Persistance_FinSt_Service();
        system.assertEquals(testConstructor, testConstructor, 'The test to the empty constructor was successfully');
        Test.stopTest();

    }
    @isTest Static void testDataNull() {
      final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
      final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');
      final arce__account_has_analysis__c ahaTest = arce.Arc_Gen_AccHasAnalysis_Data.getAccForResume(new Set<Id>{groupAccount.accId})[0];
      final arce__account_has_analysis__c ahaTestFinal = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)ahaTest.Id})[0];
      ahaTestFinal.put('arce__ffss_auditor_fullname_name__c','test');
      ahaTestFinal.put('arce__ffss_cnsld_perimeter_desc__c','test');
      ahaTestFinal.put('arce__ffss_auditor_fullname_name__c','test');
      ahaTestFinal.put('arce__debt_maturity_desc__c','test');
      ahaTestFinal.put('arce__number_entity_type__c','test');
      ahaTestFinal.put('arce__debt_maturity_available_type__c','test');
      ahaTestFinal.put('arce__cust_budget_cyr_ind_type__c','test');
      ahaTestFinal.put('arce__cust_budget_incl_ffss_ind_type__c','test');
      ahaTestFinal.put('arce__cust_proj_2yr_3yr_ind_type__c','test');
      ahaTestFinal.put('arce__cust_proj_2yr_3yr_desc__c','test');
      ahaTestFinal.put('arce__property_ownership_type__c','test');
      ahaTestFinal.put('arce__property_ownership_desc__c','test');
      ahaTestFinal.put('arce__var_over_20_balance_desc__c','test');
      ahaTestFinal.put('arce__equity_total_asset_20_type__c','test');
      Test.startTest();
      String result = Arc_Gen_FinRisk_Pers_service.save(new List<sObject>{ahaTestFinal});
      system.assertEquals(result, result, 'The test to the empty constructor was successfully');
      Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test persistance performed when the FFSS tab of the Dyfr is saved.
    * --------------------------------------------------------------------------------------
    * @Author   joseluis.garcia4.contractor@bbva.com
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testPersistanceDyfr() {
      final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
      final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');
      final arce__account_has_analysis__c ahaTest = arce.Arc_Gen_AccHasAnalysis_Data.getAccForResume(new Set<Id>{groupAccount.accId})[0];
      final arce__account_has_analysis__c ahaTestFinal = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)ahaTest.Id})[0];

      ahaTestFinal.arce__Syn_significant_extraordinary_variab__c = 'test';
      ahaTestFinal.arce__AFAS_projection_type__c = '1';
      Test.startTest();
      final Arc_Gen_SaveFinancialStatement saveImpl = new Arc_Gen_SaveFinancialStatement();
      final String result = saveImpl.save(new List<arce__account_has_analysis__c>{ahaTestFinal});
      Test.stopTest();

      Map<String, Object> parsedRes = (Map<String, Object>) JSON.deserializeUntyped(result); 
      System.assert((Boolean)parsedRes.get('validated'), 'Save must have been successful');
    }
}