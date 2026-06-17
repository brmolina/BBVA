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
@SuppressWarnings('sf:TooManyMethods, sf:AvoidSoqlWithNegativeLogic')
@isTest
public with sharing class Arc_Geb_ValidateRatingBy_Test {
  //Rating String
  private static final String RATING_TYPE = 'Rating';
  /** Unexpected actual value! */
  private static final String UNEXPECTED_VAL = 'Unexpected actual value!';
  /** Account number constant for tests */
  private static final String ACC_NUMBER = 'CAONlXcCA_uxyJ402AA_xw';
  /** Test name constant */
  private static final String TEST_NAME = 'testName';
  /** Rating AAA constant */
  private static final String RTG_AAA = 'AAA';
  /** Rating ID constant */
  private static final String RTG_ID = 'RatingId';
  /** Test traceability internal code */
  private static final String TEST_TRACE_CODE = 't-t-002';

  /**
  * --------------------------------------------------------------------------------------
  * @Description Setup method to create test data once for all test methods
  * --------------------------------------------------------------------------------------
  **/
  @TestSetup
  static void setupTestData() {
    arce.Arc_UtilitiesToTest_tst.enableBypass();

    final Account testAcc = arce.Arc_UtilitiesToTest_tst.crearCuenta('ES', null, null, ACC_NUMBER);
    insert testAcc;

    final arce__Analysis__c testAnalysis = arce.Arc_UtilitiesToTest_tst.crearArceAnalysis(TEST_NAME, null, testAcc.Id);
    insert testAnalysis;

    final arce__Analysis__c testAnalysis2 = arce.Arc_UtilitiesToTest_tst.crearArceAnalysis('testName2', null, testAcc.Id);
    testAnalysis2.arce__rating_prerating_type__c = 'Rating';
    testAnalysis2.arce__wf_status_id__c = '13';
    insert testAnalysis2;

    final arce__Account_has_Analysis__c testAha = arce.Arc_UtilitiesToTest_tst.crearAccHasAnalysis(null, testAnalysis.Id, testAcc.Id, null);
    testAha.arce__group_asset_header_type__c = arce.Arc_Gen_Constants.GROUP_ASSET_HEADER_TYPE_HEADER;
    testAha.arce__Customer__c = testAcc.Id;
    testAha.arce__total_rating_score_number__c = 1;
    insert testAha;

    final arce__Account_has_Analysis__c testAha2 = arce.Arc_UtilitiesToTest_tst.crearAccHasAnalysis(null, testAnalysis2.Id, testAcc.Id, null);
    testAha2.arce__Customer__c = testAcc.Id;
    testAha2.arce__total_rating_score_number__c = 4;
    insert testAha2;

    final arce__rating__c testRating = arce.Arc_UtilitiesToTest_tst.createRatingObj(RTG_ID, RTG_AAA, RTG_AAA, '2');
    insert testRating;

    final arce__Financial_Statements__c testFfss = arce.Arc_UtilitiesToTest_tst.crearFinStatement(testAcc.id, testAha.id, testRating.Id, null);
    insert testFfss;

    testAha.arce__ffss_for_rating_id__c = testFfss.id;
    testAha.arce__financial_statement_id__c = testFfss.id;
    update testAha;

    final arce__Traceability_Event__c testTracEvt = new arce__Traceability_Event__c();
    testTracEvt.arce__analysis_id__c = testAnalysis.Id;
    testTracEvt.arce__current_event__c = true;
    testTracEvt.arce__gc_trcblty_internal_code_id__c = TEST_TRACE_CODE;
    insert testTracEvt;

    final arce__AHA_Extension__c testAhaExt = new arce__AHA_Extension__c(
      arce__PS_Successfully_Retrieved__c = true
    );
    insert testAhaExt;

    testAha.arce__AHA_Extension__c = testAhaExt.Id;
    update testAha;

    final arce__Overlay__c testOverlay = new arce__Overlay__c(
      arce__Account_has_AnalysisId__c = testAha.Id,
      arce__Arc_Gen_PS_Relationship_Id__c = '461',
      arce__Arc_Gen_ParentGroups__c = '{"ES0182009687897":["ES0182009687897"]}'
    );
    insert testOverlay;
  }

  /**
  *-------------------------------------------------------------------------------
  * @Description Tests a OK case for Arc_Gen_ValidateRatingBy_Controller.getRatingData method
  *--------------------------------------------------------------------------------
  * @ Author jose.hijar.contactor@bbva.com
  * @ Date 2021-05-21
  *--------------------------------------------------------------------------------
  **/
  @isTest
  public static void getRatingDataTestOK() {

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
  public static void getRatingDataTestKO1() {

    Test.startTest();
    try{
      Arc_Gen_ValidateRatingBy_Controller.getRatingData('xxxx');
    }catch(Exception e){
      System.AssertEquals(e.getTypeName(), 'System.AuraHandledException', 'ko');
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
  public static void getRatingDataTestKO2() {

    Arc_Gen_ValidateRatingBy_Controller.ValidatedByResponse assertTest;
    Test.startTest();
    assertTest = Arc_Gen_ValidateRatingBy_Controller.getRatingData(null);
    System.Assert(!assertTest.success, 'ko');
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
  public static void fetchUsersOK1() {

    Arc_Gen_ValidateRatingBy_Controller.ValidatedByResponse assertTest;
    Test.startTest();
    assertTest = Arc_Gen_ValidateRatingBy_Controller.fetchUsers('ambit1', '001000000000001AAA');
    System.Assert(assertTest.success, 'ok');
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
  public static void fetchUsersKO() {

    Arc_Gen_ValidateRatingBy_Controller.ValidatedByResponse assertTest;
    Test.startTest();
    assertTest = Arc_Gen_ValidateRatingBy_Controller.fetchUsers(null, null);
    System.Assert(!assertTest.success, 'ko');
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
  public static void validateRatingTestOk1() {
    Arc_Gen_ValidateRatingBy_Controller.ValidatedByResponse resp;

    final arce__Account_has_Analysis__c testAha = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = :arce.Arc_Gen_Constants.GROUP_ASSET_HEADER_TYPE_HEADER LIMIT 1];
    final arce__rating__c testRating = [SELECT Id FROM arce__rating__c LIMIT 1];

    Test.startTest();
    resp = Arc_Gen_ValidateRatingBy_Controller.validateRating(testAha.Id, testRating.Id, 'COMITE', 'example description','2');
    System.assert(resp.success, 'Test passed OK');
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
  public static void validateRatingTestKO1() {
    final arce__Account_has_Analysis__c testAha = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = :arce.Arc_Gen_Constants.GROUP_ASSET_HEADER_TYPE_HEADER LIMIT 1];
    final arce__rating__c testRating = [SELECT Id FROM arce__rating__c LIMIT 1];

    Test.startTest();
    try{
      Arc_Gen_ValidateRatingBy_Controller.validateRating(testAha.Id, testRating.Id, 'committee', 'example description','2');
    } catch(Exception e) {
      System.assert(e.getTypeName().equals('System.AuraHandledException'), 'Test passed KO');
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

    final arce__Table_Content_per_Analysis__c tabContent = arce.Arc_UtilitiesToTest_tst.crearTableContentAnalysis(aHa.Id,arceDatColl.Id,'Ratios_Magnitudes','1ยบ 2020-12-31 FISCAL Individual Adjusted (410393)');
    tabContent.arce__original_currency__c = 'EUR';
    tabContent.arce__original_amount__c = Decimal.valueOf('3600000000000');
    insert tabContent;

    arce__Traceability_Event__c te = new arce__Traceability_Event__c();
    te.arce__analysis_id__c = analysis.Id;
    te.arce__current_event__c = true;
    te.arce__gc_trcblty_internal_code_id__c = 't-t-004';
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
    newTrEvt.arce__gc_trcblty_internal_code_id__c = 't-t-003';
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
      System.assert(!resp.success, 'The persistence call has returned with an KO boolean.');
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
  public static void callPersistenceDataEsgTest() {
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
  public static void callPersistenceDataEsgNullTest() {
    Arc_Gen_ValidateRatingBy_Controller.ValidatedByResponse resp;

    Test.startTest();
    resp = Arc_Gen_ValidateRatingBy_Controller.callPersistenceDataEsg('test');
    System.assert(!resp.success, 'Test passed KO');
    Test.stopTest();
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description Test method for Arc_Gen_ValidateRatingBy_Controller.checkScoreAlert()
  * --------------------------------------------------------------------------------------
  * @Author   aleksandar.dinkov.contractor@bbva.com
  * @Date     2025-01-28
  * --------------------------------------------------------------------------------------
  **/
  @isTest
  static void testCheckScoreAlert() {
    // Create account
    final Account acc = arce.Arc_UtilitiesToTest_tst.crearCuenta('ES', null, null, 'CAONlXcCA_uxyJ402AA_xw');
    insert acc;
    // Create analysis and AHA
    arce__Analysis__c analysis = arce.Arc_UtilitiesToTest_tst.crearArceAnalysis('testName', null, acc.Id);
    analysis.arce__rating_prerating_type__c = RATING_TYPE;
    insert analysis;
    arce__Account_has_Analysis__c aHa = arce.Arc_UtilitiesToTest_tst.crearAccHasAnalysis(null, analysis.Id, acc.Id, null);
    aHa.arce__total_rating_score_number__c = 1;
    aHa.arce__Customer__c = acc.Id;
    aHa.arce__RAR_rating_tool_id__c = '2012P1IRP';
    insert aHa;
    // Create second analysis and AHA with different score
    final arce__Analysis__c analysis2 = arce.Arc_UtilitiesToTest_tst.crearArceAnalysis('testName2', null, acc.Id);
    analysis2.arce__rating_prerating_type__c = RATING_TYPE;
    analysis2.arce__wf_status_id__c = '13';
    analysis2.arce__Stage__c = '3';
    insert analysis2;
    final arce__rating__c rating = arce.Arc_UtilitiesToTest_tst.createRatingObj('RatingId', 'AAA', 'AAA', '2');
    insert rating;
    final arce__Account_has_Analysis__c aHa2 = arce.Arc_UtilitiesToTest_tst.crearAccHasAnalysis(null, analysis2.Id, acc.Id, null);
    aHa2.arce__total_rating_score_number__c = 4;
    aHa2.arce__Customer__c = acc.Id;
    aHa2.arce__RAR_rating_tool_id__c = '2012P1IRP';
    insert aHa2;
    final arce__Financial_Statements__c ffss = arce.Arc_UtilitiesToTest_tst.crearFinStatement(acc.id, aHa2.id, rating.Id, null);
    ffss.arce__ffss_submitted_type__c = '1';
    ffss.arce__ffss_valid_type__c = '1';
    insert ffss;
    aHa2.arce__ffss_for_rating_id__c = ffss.id;
    aHa2.arce__financial_statement_id__c = ffss.id;
    update aHa2;

    Test.startTest();
    final String resp = Arc_Gen_ValidateRatingBy_Controller.checkScoreAlert(aha.Id);
    System.assert(!resp.equals(''), 'Unexpected actual value!');
    Test.stopTest();
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description Test method for Arc_Gen_ValidateRatingBy_Controller.getMaxDiffValue()
  * --------------------------------------------------------------------------------------
  * @Author   aleksandar.dinkov.contractor@bbva.com
  * @Date     2025-01-28
  * --------------------------------------------------------------------------------------
  **/
  @isTest
  static void testGetMaxDiffValue() {
    final String arceConfJson = JSON.serialize(new Map<String, String>{'RatingScoreAlert' => '0.5'});
    Test.startTest();
    final Decimal resp = Arc_Gen_ValidateRatingBy_Controller.getMaxDiffValue(arceConfJson, RATING_TYPE);
    System.assert(resp.equals(0.5), 'Unexpected actual value!');
    Test.stopTest();
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description Test method for Arc_Gen_ValidateRatingBy_Controller.getMaxDiffValue()
  * --------------------------------------------------------------------------------------
  * @Author   aleksandar.dinkov.contractor@bbva.com
  * @Date     2025-01-28
  * --------------------------------------------------------------------------------------
  **/
  @isTest
  static void testGetMaxDiffValueError1() {
    final String arceConfJson = JSON.serialize(new Map<String, String>{'confNotFindErrorTest' => '0.5'});
    Test.startTest();
    try {
      final Decimal resp = Arc_Gen_ValidateRatingBy_Controller.getMaxDiffValue(arceConfJson, RATING_TYPE);
    } catch (Exception ex) {
      System.assert(ex.getMessage().contains('Script-thrown exception'), 'Unexpected actual value!');
    }
    Test.stopTest();
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description Test method for Arc_Gen_ValidateRatingBy_Controller.getMaxDiffValue()
  * --------------------------------------------------------------------------------------
  * @Author   aleksandar.dinkov.contractor@bbva.com
  * @Date     2025-01-28
  * --------------------------------------------------------------------------------------
  **/
  @isTest
  static void testGetMaxDiffValueError2() {
    final String arceConfJson = JSON.serialize(new Map<String, String>{'PreRatingScoreAlert' => 'invalidDecimalError'});
    Test.startTest();
    try {
      final Decimal resp = Arc_Gen_ValidateRatingBy_Controller.getMaxDiffValue(arceConfJson, RATING_TYPE);
    } catch (Exception ex) {
      System.assert(ex.getMessage().contains('Script-thrown exception'), 'Unexpected actual value!');
    }
    Test.stopTest();
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description Test method for Arc_Gen_ValidateRatingBy_Controller.getMaxDiffValue()
  * --------------------------------------------------------------------------------------
  * @Author   aleksandar.dinkov.contractor@bbva.com
  * @Date     2025-01-28
  * --------------------------------------------------------------------------------------
  **/
  @isTest
  static void testGetMaxDiffValueError3() {
    final String arceConfJson = 'unhandledError';
    Test.startTest();
    try {
      final Decimal resp = Arc_Gen_ValidateRatingBy_Controller.getMaxDiffValue(arceConfJson, RATING_TYPE);
    } catch (Exception ex) {
      System.assert(ex.getMessage().contains('Script-thrown exception'), 'Unexpected actual value!');
    }
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
    final arce__Account_has_Analysis__c testAha = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__AHA_Extension__c != null LIMIT 1];

    Test.startTest();
    final Map<String, Object> msgResp = Arc_Gen_ValidateRatingBy_Controller.refreshParentSubsidiary(testAha.Id, true);
    System.assertEquals('Success', msgResp.get('status'), UNEXPECTED_VAL);
    Test.stopTest();
  }
}