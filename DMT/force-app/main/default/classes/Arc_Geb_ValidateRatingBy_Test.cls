/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Geb_ValidateRatingBy_Test
* @Author   jose.hijar.contractor@bbva.com
* @Date     Created: 19/05/2021
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Tests methods of Arc_Gen_ValidateRatingBy_Controller class
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |19-05-2021 jose.hijar.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class Arc_Geb_ValidateRatingBy_Test {

  /**
  *-------------------------------------------------------------------------------
  * @Description Tests a OK case for Arc_Gen_ValidateRatingBy_Controller.getRatingData method
  *--------------------------------------------------------------------------------
  * @ Author jose.hijar.contactor@bbva.com
  * @ Date 2021-05-21
  *--------------------------------------------------------------------------------
  **/
  @isTest
  public static void getRatingDataTestOK(){

    arce.Arc_UtilitiesToTest_tst.setupAcccounts();
    Arc_Gen_ValidateRatingBy_Controller.ValidatedByResponse assertTest;

    Account acc = [SELECT Id FROM Account WHERE AccountNumber = 'C000001'][0];
    Account groupAcc = [SELECT Id FROM Account WHERE AccountNumber = 'G000001'][0];

    arce__Analysis__c analysis = arce.Arc_UtilitiesToTest_tst.crearArceAnalysis('testName', null, groupAcc.Id);
    insert analysis;
    arce__Account_has_Analysis__c aHa = arce.Arc_UtilitiesToTest_tst.crearAccHasAnalysis(null, analysis.Id, acc.Id, null);
    insert aHa;

    Test.startTest();
    assertTest = Arc_Gen_ValidateRatingBy_Controller.getRatingData(aHa.Id);
    System.AssertEquals(true, assertTest.success, 'Ok');
    Test.stopTest();
  }

  /**
  *-------------------------------------------------------------------------------
  * @Description Tests a KO case for Arc_Gen_ValidateRatingBy_Controller.getRatingData method
  *--------------------------------------------------------------------------------
  * @ Author jose.hijar.contactor@bbva.com
  * @ Date 2021-05-21
  *--------------------------------------------------------------------------------
  **/
  @isTest
  public static void getRatingDataTestKO1(){

    Test.startTest();
    try{
      Arc_Gen_ValidateRatingBy_Controller.getRatingData('xxxx');
    }catch(Exception e){
      System.AssertEquals(true, e.getTypeName() == 'System.AuraHandledException', 'ko');
    }
    Test.stopTest();
  }

  /**
  *-------------------------------------------------------------------------------
  * @Description Tests a KO case for Arc_Gen_ValidateRatingBy_Controller.getRatingData method
  *--------------------------------------------------------------------------------
  * @ Author jose.hijar.contactor@bbva.com
  * @ Date 2021-05-21
  *--------------------------------------------------------------------------------
  **/
  @isTest
  public static void getRatingDataTestKO2(){

    Arc_Gen_ValidateRatingBy_Controller.ValidatedByResponse assertTest;
    Test.startTest();
    assertTest = Arc_Gen_ValidateRatingBy_Controller.getRatingData(null);
    System.AssertEquals(false, assertTest.success, 'ko');
    Test.stopTest();
  }

  /**
  *-------------------------------------------------------------------------------
  * @Description Tests a OK case for Arc_Gen_ValidateRatingBy_Controller.fetchUsers method
  *--------------------------------------------------------------------------------
  * @ Author jose.hijar.contactor@bbva.com
  * @ Date 2021-05-21
  *--------------------------------------------------------------------------------
  **/
  @isTest
  public static void fetchUsersOK1(){

    Arc_Gen_ValidateRatingBy_Controller.ValidatedByResponse assertTest;
    Test.startTest();
    assertTest = Arc_Gen_ValidateRatingBy_Controller.fetchUsers('ambit1');
    System.AssertEquals(true, assertTest.success, 'ok');
    Test.stopTest();
  }

  /**
  *-------------------------------------------------------------------------------
  * @Description Tests a KO case for Arc_Gen_ValidateRatingBy_Controller.fetchUsers method
  *--------------------------------------------------------------------------------
  * @ Author jose.hijar.contactor@bbva.com
  * @ Date 2021-05-21
  *--------------------------------------------------------------------------------
  **/
  @isTest
  public static void fetchUsersKO(){

    Arc_Gen_ValidateRatingBy_Controller.ValidatedByResponse assertTest;
    Test.startTest();
    assertTest = Arc_Gen_ValidateRatingBy_Controller.fetchUsers(null);
    System.AssertEquals(false, assertTest.success, 'ko');
    Test.stopTest();
  }


  /**
  *-------------------------------------------------------------------------------
  * @Description Tests a OK case for Arc_Gen_ValidateRatingBy_Controller.validateRating method
  *--------------------------------------------------------------------------------
  * @ Author jose.hijar.contactor@bbva.com
  * @ Date 2021-05-21
  *--------------------------------------------------------------------------------
  **/
  @isTest
  public static void validateRatingTestOk1(){
    Arc_Gen_ValidateRatingBy_Controller.ValidatedByResponse resp;

    final Account acc = arce.Arc_UtilitiesToTest_tst.crearCuenta('ES', null, null, 'CAONlXcCA_uxyJ402AA_xw');
    insert acc;
    arce__Analysis__c analysis = arce.Arc_UtilitiesToTest_tst.crearArceAnalysis('testName', null, acc.Id);
    insert analysis;
    arce__Account_has_Analysis__c aHa = arce.Arc_UtilitiesToTest_tst.crearAccHasAnalysis(null, analysis.Id, acc.Id, null);
    aHa.arce__group_asset_header_type__c = arce.Arc_Gen_Constants.GROUP_ASSET_HEADER_TYPE_HEADER;
    insert aHa;
    final arce__rating__c rating = arce.Arc_UtilitiesToTest_tst.createRatingObj('RatingId', 'AAA', 'AAA', '2');
    insert rating;
    final arce__Financial_Statements__c ffss = arce.Arc_UtilitiesToTest_tst.crearFinStatement(acc.id, aha.id, rating.Id, null);
    insert ffss;
    aha.arce__ffss_for_rating_id__c = ffss.id;
    aha.arce__financial_statement_id__c = ffss.id;
    update aha;
    arce__Traceability_Event__c te = new arce__Traceability_Event__c();
    te.arce__analysis_id__c = analysis.Id;
    te.arce__current_event__c = true;
    te.arce__gc_trcblty_internal_code_id__c = 't-t-002';
    insert te;

    Test.startTest();
    resp = Arc_Gen_ValidateRatingBy_Controller.validateRating(aHa.Id, rating.Id, 'COMITE', 'example description','2');
    System.assertEquals(true, resp.success, 'Test passed OK');
    Test.stopTest();

  }


  /**
  *-------------------------------------------------------------------------------
  * @Description Tests a KO case for Arc_Gen_ValidateRatingBy_Controller.validateRating method
  *--------------------------------------------------------------------------------
  * @ Author jose.hijar.contactor@bbva.com
  * @ Date 2021-05-21
  *--------------------------------------------------------------------------------
  **/
  @isTest
  public static void validateRatingTestKO1(){
    Arc_Gen_ValidateRatingBy_Controller.ValidatedByResponse resp;

    final Account acc = arce.Arc_UtilitiesToTest_tst.crearCuenta('ES', null, null, 'CAONlXcCA_uxyJ402AA_xw');
    insert acc;
    arce__Analysis__c analysis = arce.Arc_UtilitiesToTest_tst.crearArceAnalysis('testName', null, acc.Id);
    insert analysis;
    arce__Account_has_Analysis__c aHa = arce.Arc_UtilitiesToTest_tst.crearAccHasAnalysis(null, analysis.Id, acc.Id, null);
    insert aHa;
    final arce__rating__c rating = arce.Arc_UtilitiesToTest_tst.createRatingObj('RatingId', 'AAA', 'AAA', '2');
    insert rating;
    final arce__Financial_Statements__c ffss = arce.Arc_UtilitiesToTest_tst.crearFinStatement(acc.id, aha.id, rating.Id, null);
    insert ffss;
    aha.arce__ffss_for_rating_id__c = ffss.id;
    aha.arce__financial_statement_id__c = ffss.id;
    update aha;
    arce__Traceability_Event__c te = new arce__Traceability_Event__c();
    te.arce__analysis_id__c = analysis.Id;
    te.arce__current_event__c = true;
    te.arce__gc_trcblty_internal_code_id__c = 'xx2';
    insert te;

    Test.startTest();
    try{
      resp = Arc_Gen_ValidateRatingBy_Controller.validateRating(aHa.Id, rating.Id, 'committee', 'example description','2');
    }catch(Exception e){
      System.assertEquals(true, e.getTypeName().equals('System.AuraHandledException'), 'Test passed KO');
    }
    Test.stopTest();
  }

  /**
  *-------------------------------------------------------------------------------
  * @Description Tests a OK case for Arc_Gen_ValidateRatingBy_Controller.validateMillions method with EUR
  *--------------------------------------------------------------------------------
  * @ Author alberto.martinez.carrero.contractor@bbva.com
  * @ Date 2022-05-17
  *--------------------------------------------------------------------------------
  **/
  @isTest
  public static void validateMillionsTestOk(){
    Arc_Gen_ValidateRatingBy_Controller.ValidatedByResponse resp;

    final Account acc = arce.Arc_UtilitiesToTest_tst.crearCuenta('ES', null, null, 'CAONlXcCA_uxyJ402AA_xw');
    insert acc;
    arce__Analysis__c analysis = arce.Arc_UtilitiesToTest_tst.crearArceAnalysis('testName', null, acc.Id);
    insert analysis;
    arce__Account_has_Analysis__c aHa = arce.Arc_UtilitiesToTest_tst.crearAccHasAnalysis(null, analysis.Id, acc.Id, null);
    aHa.arce__group_asset_header_type__c = arce.Arc_Gen_Constants.GROUP_ASSET_HEADER_TYPE_HEADER;
    insert aHa;
    final arce__rating__c rating = arce.Arc_UtilitiesToTest_tst.createRatingObj('RatingId', 'AAA', 'AAA', '2');
    insert rating;
    final arce__Financial_Statements__c ffss = arce.Arc_UtilitiesToTest_tst.crearFinStatement(acc.id, aha.id, rating.Id, null);
    insert ffss;

    aha.arce__ffss_for_rating_id__c = ffss.id;
    aha.arce__financial_statement_id__c = ffss.id;
    update aha;

    final arce__Data_Collections__c arceDatColl = arce.Arc_UtilitiesToTest_tst.crearDataCollection('TOTAL REVENUES','Ratios_Magnitudes','02');
    arceDatColl.arce__collection_code_term__c = '700';
    arceDatColl.arce__collection_order_number__c = 3300;
    insert arceDatColl;

    final arce__Table_Content_per_Analysis__c tabContent = arce.Arc_UtilitiesToTest_tst.crearTableContentAnalysis(aHa.Id,arceDatColl.Id,'Ratios_Magnitudes','1º 2020-12-31 FISCAL Individual Adjusted (410393)');
    tabContent.arce__original_currency__c = 'EUR';
    tabContent.arce__original_amount__c = Decimal.valueOf('3600000000000');
    insert tabContent;

    arce__Traceability_Event__c te = new arce__Traceability_Event__c();
    te.arce__analysis_id__c = analysis.Id;
    te.arce__current_event__c = true;
    te.arce__gc_trcblty_internal_code_id__c = 't-t-002';
    insert te;

    Test.startTest();
    resp = Arc_Gen_ValidateRatingBy_Controller.validateMillions(aHa.Id);
    System.assertEquals(true, resp.success, 'Test passed KO');
    Test.stopTest();

  }

    /**
  *-------------------------------------------------------------------------------
  * @Description Tests a OK case for Arc_Gen_ValidateRatingBy_Controller.callPersistenceEsg method
  *--------------------------------------------------------------------------------
  * @ Author marcos.gimeno.contractor@bbva.com
  * @ Date 2022-10-10
  *--------------------------------------------------------------------------------
  **/
  @isTest
  public static void testCallPersistenceEsgOK() {
    final Account newAcc = arce.Arc_UtilitiesToTest_tst.crearCuenta('ES', null, null, 'CAONlXcCA_uxyJ402AA_xw');
    insert newAcc;
    arce__Analysis__c newAnalysis = arce.Arc_UtilitiesToTest_tst.crearArceAnalysis('analysistest', null, newAcc.Id);
    newAnalysis.arce__anlys_wkfl_sub_process_type__c = '2';
    insert newAnalysis;
    arce__Account_has_Analysis__c newAha = arce.Arc_UtilitiesToTest_tst.crearAccHasAnalysis(null, newAnalysis.Id, newAcc.Id, null);
    newAha.arce__group_asset_header_type__c = arce.Arc_Gen_Constants.GROUP_ASSET_HEADER_TYPE_HEADER;
    insert newAha;
    final arce__rating__c newRating = arce.Arc_UtilitiesToTest_tst.createRatingObj('ratingtest', 'AAA', 'AAA', '2');
    insert newRating;
    final arce__Financial_Statements__c newFfss = arce.Arc_UtilitiesToTest_tst.crearFinStatement(newAcc.id, newAha.id, newRating.Id, null);
    insert newFfss;
    newAha.arce__ffss_for_rating_id__c = newFfss.id;
    newAha.arce__financial_statement_id__c = newFfss.id;
    update newAha;
    arce__Traceability_Event__c newTrEvt = new arce__Traceability_Event__c();
    newTrEvt.arce__analysis_id__c = newAnalysis.Id;
    newTrEvt.arce__current_event__c = true;
    newTrEvt.arce__gc_trcblty_internal_code_id__c = 't-t-002';
    insert newTrEvt;

    arce__esg_toolkitSummary__c newToolkitEsg = new arce__esg_toolkitSummary__c();
    newToolkitEsg.arce__esg_Account_has_Analysis__c = newAha.Id;
    insert newToolkitEsg;
    arce__esg_rating__c newRatingEsg = new arce__esg_rating__c();
    newRatingEsg.arce__esg_toolkit_summary__c = newToolkitEsg.Id;
    insert newRatingEsg;
    arce__esg_emission_target__c newEmissionEsg = new arce__esg_emission_target__c();
    newEmissionEsg.arce__esg_toolkit_summary__c = newToolkitEsg.Id;

    Test.startTest();
      final Arc_Gen_ValidateRatingBy_Controller.ValidatedByResponse resp = Arc_Gen_ValidateRatingBy_Controller.callPersistenceEsg(newAha.Id);
      System.assertEquals(true, resp.success, 'The persistence call has returned with an OK boolean');
      System.assertEquals('Success', resp.message, 'The persistence call has returned with an OK message');
    Test.stopTest();
  }
  /**
  *-------------------------------------------------------------------------------
  * @Description Tests a KO case for Arc_Gen_ValidateRatingBy_Controller.callPersistenceEsg method
  *--------------------------------------------------------------------------------
  * @ Author marcos.gimeno.contractor@bbva.com
  * @ Date 2022-10-10
  *--------------------------------------------------------------------------------
  **/
  @isTest
  public static void testCallPersistenceEsgKO() {
    Test.startTest();
      final Arc_Gen_ValidateRatingBy_Controller.ValidatedByResponse resp = Arc_Gen_ValidateRatingBy_Controller.callPersistenceEsg(null);
      System.assertEquals(false, resp.success, 'The persistence call has returned with an KO boolean.');
      System.assertEquals(System.label.Arc_Esg_Serv_Error1, resp.message, 'The persistence call has returned with an KO message.');
    Test.stopTest();
  }

  /**
  *-------------------------------------------------------------------------------
  * @Description Tests for Arc_Gen_ValidateRatingBy_Controller.callPersistenceDataEsgTest method
  *--------------------------------------------------------------------------------
  * @ Author isabel.ascaso.contractor@bbva.com
  * @ Date 2022-10-10
  *--------------------------------------------------------------------------------
  **/
  @isTest
  public static void callPersistenceDataEsgTest(){
    Arc_Gen_ValidateRatingBy_Controller.ValidatedByResponse resp;

    final Account acc = arce.Arc_UtilitiesToTest_tst.crearCuenta('MX', null, null, 'CAONlXcCA_uxyJ402AA_xw');
    insert acc;
    arce__Analysis__c analysis = arce.Arc_UtilitiesToTest_tst.crearArceAnalysis('testName', null, acc.Id);
    insert analysis;
    arce__Account_has_Analysis__c aHa = arce.Arc_UtilitiesToTest_tst.crearAccHasAnalysis(null, analysis.Id, acc.Id, null);
    aHa.arce__group_asset_header_type__c = arce.Arc_Gen_Constants.GROUP_ASSET_HEADER_TYPE_HEADER;
    insert aHa;
    final arce__rating__c rating = arce.Arc_UtilitiesToTest_tst.createRatingObj('RatingId', 'AAA', 'AAA', '2');
    insert rating;
    final arce__Financial_Statements__c ffss = arce.Arc_UtilitiesToTest_tst.crearFinStatement(acc.id, aha.id, rating.Id, null);
    insert ffss;

    aha.arce__ffss_for_rating_id__c = ffss.id;
    aha.arce__financial_statement_id__c = ffss.id;
    update aha;

    Test.startTest();
    resp = Arc_Gen_ValidateRatingBy_Controller.callPersistenceDataEsg(aHa.Id);
    System.assertEquals(true, resp.success, 'Test passed KO');
    Test.stopTest();
  }

  /**
  *-------------------------------------------------------------------------------
  * @Description Tests for null of Arc_Gen_ValidateRatingBy_Controller.callPersistenceDataEsgTest method
  *--------------------------------------------------------------------------------
  * @ Author isabel.ascaso.contractor@bbva.com
  * @ Date 2022-10-10
  *--------------------------------------------------------------------------------
  **/
  @isTest
  public static void callPersistenceDataEsgNullTest(){
    Arc_Gen_ValidateRatingBy_Controller.ValidatedByResponse resp;

    Test.startTest();
    resp = Arc_Gen_ValidateRatingBy_Controller.callPersistenceDataEsg('test');
    System.assertEquals(false, resp.success, 'Test passed KO');
    Test.stopTest();
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description Test method for Arc_Gen_ValidateRatingBy_Controller.refreshParentSubsidiary()
  * --------------------------------------------------------------------------------------
  * @Author   aleksandar.dinkov.contractor@bbva.com
  * @Date     2024-02-10
  * --------------------------------------------------------------------------------------
  **/
  @isTest
  static void testValidateParentSubsidiary() {
    final Account acc = arce.Arc_UtilitiesToTest_tst.crearCuenta('ES', null, null, 'CAONlXcCA_uxyJ402AA_xw');
    insert acc;
    arce__Analysis__c analysis = arce.Arc_UtilitiesToTest_tst.crearArceAnalysis('testName', null, acc.Id);
    insert analysis;
    final arce__AHA_Extension__c ahaExt = new arce__AHA_Extension__c(
      arce__PS_Successfully_Retrieved__c = true
    );
    insert ahaExt;
    arce__Account_has_Analysis__c aHa = arce.Arc_UtilitiesToTest_tst.crearAccHasAnalysis(null, analysis.Id, acc.Id, null);
    aha.arce__AHA_Extension__c = ahaExt.Id;
    insert aHa;
    final arce__rating__c rating = arce.Arc_UtilitiesToTest_tst.createRatingObj('RatingId', 'AAA', 'AAA', '2');
    insert rating;
    final arce__Financial_Statements__c ffss = arce.Arc_UtilitiesToTest_tst.crearFinStatement(acc.id, aha.id, rating.Id, null);
    insert ffss;
    aha.arce__ffss_for_rating_id__c = ffss.id;
    aha.arce__financial_statement_id__c = ffss.id;
    update aha;
    arce__Traceability_Event__c te = new arce__Traceability_Event__c();
    te.arce__analysis_id__c = analysis.Id;
    te.arce__current_event__c = true;
    te.arce__gc_trcblty_internal_code_id__c = 'xx2';
    insert te;
    final arce__Overlay__c overlay = new arce__Overlay__c(
      arce__Account_has_AnalysisId__c = aha.Id,
      arce__Arc_Gen_PS_Relationship_Id__c = '461',
      arce__Arc_Gen_ParentGroups__c = '{"ES0182009687897":["ES0182009687897"]}'
    );
    insert overlay;

    Test.startTest();
    final Arc_Gen_ValidatePS.MessageResponse msgResp = Arc_Gen_ValidateRatingBy_Controller.validateParentSubsidiary(aha.Id, true);
    System.assertEquals('Success', msgResp.status, 'Unexpected actual value!');
    Test.stopTest();
  }

}