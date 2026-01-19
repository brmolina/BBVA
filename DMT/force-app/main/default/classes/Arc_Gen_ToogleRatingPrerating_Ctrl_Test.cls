/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ToogleRatingPrerating_Ctrl_Test
* @Author   BBVA Developers
* @Date     Created: 2022-06-22
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description test class for Arc_Gen_ToogleRatingPrerating_Ctrl
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2023-09-08 BBVA Developers.
*              Test Class creation.
* ------------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class Arc_Gen_ToogleRatingPrerating_Ctrl_Test {
  /**
    * @description testSetup
    * @author ARCE TEAM
  **/
  @TestSetup
  static void testSetup() {

    final Account acc = new Account();
    acc.Name = 'TestAcc';
    acc.AccountNumber = 'ES0182033666666';
    insert acc;

    final arce__Sector__c newSector = new arce__Sector__c();
    newSector.Name = 'Generic';
    newSector.arce__analysis_section_type__c = '100;200';
    newSector.arce__sector_analisis_type__c = '4';
    newSector.arce__analysis_section_list__c = 'sp2-re-gbl-01-100-2012;sp2-raip-01-200-2012';
    newSector.arce__active_type__c = true;
    newSector.arce__unique_id__c = String.valueOf((Math.random()*1000).round()); 
    newSector.arce__rar_rating_tool_id__c = '2021RTC_NFI';
    insert newSector;

    final arce__Analysis__c analisis = new arce__Analysis__c();
    analisis.arce__Group__c = acc.Id;
    analisis.arce__rating_prerating_type__c = 'Rating';
    analisis.arce__Stage__c = '1';
    insert analisis;

    final arce__Account_has_Analysis__c aha = new arce__Account_has_Analysis__c();
    aha.arce__Analysis__c = analisis.Id;
    aha.arce__customer__c = acc.Id;
    aha.arce__RAR_rating_tool_id__c = '2021RTC_NFI';
    insert aha;

    final arce__Modifier__c modifier = new arce__Modifier__c();
    modifier.arce__Account_has_AnalysisId__c = aha.id;
    insert modifier;

  }

  /**
    * @description getInitInfoTest test method
    * @author ARCE TEAM
  **/
  @isTest
  public static void getInitInfoTest() {
    final arce__Account_has_Analysis__c aha =  [SELECT id, arce__RAR_rating_tool_id__c, arce__customer__c FROM arce__Account_has_Analysis__c WHERE arce__RAR_rating_tool_id__c = '2021RTC_NFI' limit 1];
    Test.startTest();
      final String resp = Arc_Gen_ToogleRatingPrerating_Ctrl.getInitInfo(aha.Id);
      System.assert(resp != null, 'Error in getInitInfoTest');
    Test.stopTest();
  }
  /**
    * @description setRatingTypeSelectedTest test method
    * @author ARCE TEAM
  **/
  @isTest
  public static void setRatingTypeSelectedTest() {
    final arce__Account_has_Analysis__c aha =  [SELECT id, arce__RAR_rating_tool_id__c, arce__customer__c FROM arce__Account_has_Analysis__c WHERE arce__RAR_rating_tool_id__c = '2021RTC_NFI' limit 1];
    Test.startTest();
      final String resp = Arc_Gen_ToogleRatingPrerating_Ctrl.setRatingTypeSelected(aha.Id, 'Prerating');
      System.assert(resp != null, 'Error in setRatingTypeSelectedTest');
    Test.stopTest();
  }
  /**
    * @description setRatingTypeSelectedCatch test method
    * @author ARCE TEAM
  **/
  @isTest
  public static void setRatingTypeSelectedCatchTest() {
    Test.startTest();
      final String resp = Arc_Gen_ToogleRatingPrerating_Ctrl.setRatingTypeSelected(null, 'Prerating');
      System.assert(resp != null, 'Error in setRatingTypeSelectedTest');
    Test.stopTest();
  }
}