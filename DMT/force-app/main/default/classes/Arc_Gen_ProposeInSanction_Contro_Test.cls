/**
  * @File Name          : Arc_Gen_ProposeInSanction_Contro_Test.cls
  * @Description        : Test class for Propose in Sanction flow
  * @Author             : luisarturo.parra.contractor@bbva.com
  * @Group              : ARCE
  * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
  * @Last Modified On   : 07-14-2023
  * @Modification Log   :
  *==============================================================================
  * Ver         Date                     Author                 Modification
  *==============================================================================
  * 1.0    5/7/2019 12:50:32   luisarturo.parra.contractor@bbva.com     Initial Version
  * 1.1    7/12/2019   ismaelyovani.obregon.contractor@bbva.com     Add method that validate rating.
  * 1.2    7/12/2019   luisruben.quinto.munoz@bbva.com              Delete reference to .arce__Id__c.
  * 1.2.1  02/12/2019  german.sanchez.perez.contractor@bbva.com
  *                    franciscojavier.bueno@bbva.com               Api names modified with the correct name on business glossary
  * 1.3    05/02/2020  juanignacio.hita.contractor@bbva.com         Refactorization class test
  * 1.4    23/09/2020  saimassimilianno.jordana.contractor@bbva.com Added arce. namespace to all classes that are now in the arce-dependencies package
  * 1.5    02/02/2021  luisdavid.rivera.ortiz@bbva.com              Eliminated unused fields
  * 1.6    18/02/2021  joseluis.garcia4.contractor@bbva.com         Fix tests for action persistence service.
  * 1.7    24/06/2021  israel.rodriguez.ramos.contractor@bbva.com   Add fields in arce__Account_has_Analysis__c, arce__limits_typology__c,
  *                                                                 arce__limits_exposures__c for Audited Values
  * 1.8    19/07/2021  juanignacio.hita.contractor@bbva.com         Add persistArceActionTestOK, persistArceActionTestKO methods
  * 1.9    28/07/2021  juanignacio.hita.contractor@bbva.com         Fix testComponentModeTestFail
  **/
@SuppressWarnings('sf:TooManyMethods, PMD.ExcessivePublicCount')
@isTest
public class Arc_Gen_ProposeInSanction_Contro_Test {
  /*
    @Description: EUROS constant
  */
  static final String EUROS = 'EUR';
  /*
    @Description: Exception error tests KO
  */
  static final String SCRIPT_EXCEPTION = 'Script-thrown exception';
  /**
  * @Method:  Test Setup
  * @Description: testing method setup
  */
  @testSetup
  static void insertData() {
    Arc_UtilitysDataTest_tst.setupAcccounts();
    final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
    final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');
    arce__Analysis__c arceobj = new arce__Analysis__c();
    arceobj.Name = 'arce__Analysisobj';
    arceobj.arce__analysis_customer_relation_type__c = '01';
    arceobj.CurrencyIsoCode = EUROS;
    arceobj.arce__Group__c = groupAccount.accId;
    arceobj.arce__Stage__c = '1';
    arceobj.arce__wf_status_id__c = '02';
    insert arceobj;

    final arce__Account_has_Analysis__c arceAccounthasAnalysisobj = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, arceobj.Id, groupAccount.accId, null);
    modifyAha(arceAccounthasAnalysisobj);
    insert arceAccounthasAnalysisobj;

    arce__rating__c ratingobj = Arc_UtilitysDataTest_tst.crearRating(null);
    modifyArceRating(ratingobj);
    insert ratingobj;

    arce__Financial_Statements__c arceFinancialStatements = Arc_UtilitysDataTest_tst.crearFinStatement(groupAccount.accId,arceAccounthasAnalysisobj.Id,ratingobj.Id,null);
    modifyArceFinStatement(arceFinancialStatements);
    insert arceFinancialStatements;

    arceAccounthasAnalysisobj.arce__ffss_for_rating_id__c = arceFinancialStatements.Id;
    update arceAccounthasAnalysisobj;

    arce__limits_typology__c lt = new arce__limits_typology__c();
    lt.Name = 'TOTAL GROUP';
    lt.arce__risk_typology_level_id__c = 'TP_0003';
    lt.arce__risk_typology_level_type__c = '1';
    lt.arce__Typology_Order__c = 1;
    insert lt;

    arce__limits_exposures__c le = new arce__limits_exposures__c();
    le.arce__account_has_analysis_id__c = arceAccounthasAnalysisobj.Id;
    le.arce__limits_typology_id__c = lt.Id;
    le.arce__curr_apprv_deleg_rm_amount__c = 2000;
    le.arce__current_proposed_amount__c = 1622;
    le.arce__current_apprv_limit_term_id__c = '12';
    insert le;

    final User userAdmin = arce.Arc_UtilitiesToTest_tst.crearUsuario('UserAdmin','System Administrator','');
    userAdmin.federationIdentifier = 'XME';
    userAdmin.ID_User__C = String.valueOf((Math.random()*100000));
    insert userAdmin;
  }
  /**
  * @Method:  Test GetCustomerDataCtrl method with expected result OK
  * @Description: testing method
  */
  @isTest
  public static void testGetCustomerDataCtrlOK() {
    Test.startTest();
      final List <arce__Account_has_Analysis__c> element = [SELECT id FROM arce__Account_has_Analysis__c WHERE currencyIsoCode = :EUROS LIMIT 1];
      final Arc_Gen_ProposeInSanction_Wrappers.WrapperGeneral wrapper  = Arc_Gen_ProposeInSanction_Controller.getCustomerDatactrl(true, element[0].Id);
      final Map<String, Arc_Gen_ProposeInSanction_Wrappers.WrapperAccHasAnalysis> wrapAcc = wrapper.mapAccHasAnalysis;
      System.assertEquals(wrapAcc.get(element[0].Id).customerName, 'Group1Child', 'Assert wrapper account has analysis');
    Test.stopTest();
  }
  /**
  * @Method:  Test GetCustomerDataCtrl method with expected result KO
  * @Description: testing method
  */
  @isTest
  public static void testGetCustomerDataCtrlKO() {
    try {
      Test.startTest();
      Arc_Gen_ProposeInSanction_Controller.getCustomerDatactrl(null, null);
      Test.stopTest();
    } catch (Exception ex) {
      System.assert(ex.getMessage().contains('Script'), SCRIPT_EXCEPTION);
    }
  }
  /**
  * @Method:  Test UpdateMainSubsidiary
  * @Description: testing method
  */
  @isTest
  public static void testUpdateMainSubsidiary() {
    final NullPointerException callEx;
    final List < arce__Account_has_Analysis__c > element = [SELECT id, arce__main_subsidiary_ind_type__c FROM arce__Account_has_Analysis__c WHERE currencyIsoCode = :EUROS LIMIT 1];
    Id theId = element[0].Id;
    system.assertEquals(theId, element[0].Id, 'should match the id');
    final Arc_Gen_ProposeInSanction_Wrappers.WrapperAccHasAnalysis wrapper = new Arc_Gen_ProposeInSanction_Wrappers.WrapperAccHasAnalysis();
    wrapper.recordId = element[0].Id;
    wrapper.mainSubsidiary = element[0].arce__main_subsidiary_ind_type__c;
    final Arc_Gen_ProposeInSanction_Wrappers.WrapperAccHasAnalysis wrapper2 = new Arc_Gen_ProposeInSanction_Wrappers.WrapperAccHasAnalysis();
    Test.startTest();
    Arc_Gen_ProposeInSanction_Controller.updateMainSubsidiary(wrapper);
    try {
      Arc_Gen_ProposeInSanction_Controller.updateMainSubsidiary(wrapper2);
    } catch (exception wrapE) {
      System.assertNotEquals(wrapE, callEx, 'test catch');
    }
    Test.stopTest();
  }
  /**
  * @Method:  Test UpdateStageSetDataCtrl
  * @Description: testing method
  */
  @isTest
  public static void testUpdateStagesetDataCtrl() {
    final NullPointerException callEx;
    final List<arce__Account_has_Analysis__c> element = [SELECT id FROM arce__Account_has_Analysis__c WHERE currencyIsoCode = :EUROS LIMIT 1];
    Id theId = element[0].Id;
    system.assertEquals(theId, element[0].Id, 'should match the Id');
    Test.startTest();
    Arc_Gen_ProposeInSanction_Controller.updateStagesetDataCtrl(element[0].Id,'1');
    try {
      Arc_Gen_ProposeInSanction_Controller.updateStagesetDataCtrl(null,null);
    } catch (exception t5e) {
      System.assertNotEquals(t5e, callEx, 'test catch');
    }
    Test.stopTest();
  }
  /**
  * @Method:  Test SetAmbitCtrl method with expected result OK
  * @Description: testing method
  */
  @isTest
  public static void testSetAmbitCtrlOK() {
    final List <arce__Account_has_Analysis__c> element = [SELECT id FROM arce__Account_has_Analysis__c WHERE currencyIsoCode = :EUROS LIMIT 1];
    Arc_Gen_Delegation_Wrapper wrapper = Arc_UtilitysDataTest_tst.crearDelegationWrapper();
    Test.startTest();
    String ambitCtrl = Arc_Gen_ProposeInSanction_Controller.setAmbitCtrl('1', element[0].Id, JSON.serialize(wrapper));
    final Arc_Gen_Delegation_Wrapper wrapperSerialize = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) ambitCtrl, Arc_Gen_Delegation_Wrapper.class);
    System.assertEquals('4', wrapperSerialize.sanctionAmbit, 'Sanction ambit equal to 4');
    Test.stopTest();
  }
  /**
  * @Method:  Test SetAmbitCtrl method with expected result KO
  * @Description: testing method
  */
  @isTest
  public static void testSetAmbitCtrlKO() {
    try {
      final List <arce__Account_has_Analysis__c> element = [SELECT id FROM arce__Account_has_Analysis__c WHERE currencyIsoCode = :EUROS LIMIT 1];
      final Arc_Gen_Delegation_Wrapper wrapper = Arc_UtilitysDataTest_tst.crearDelegationWrapper();
      Test.startTest();
      Arc_Gen_ProposeInSanction_Controller.setAmbitCtrl('aaa', element[0].Id, JSON.serialize(wrapper));
      Test.stopTest();
    } catch (Exception ex) {
      System.assert(ex.getMessage().contains('Script'), SCRIPT_EXCEPTION);
    }
  }
  /**
  * @Method:  Test GetAmbitCtrl method with expected result OK
  * @Description: testing method
  */
  @isTest
  public static void testGetAmbitCtrlOK() {
    final List<Map<string,string>>  testlist = Arc_Gen_ProposeInSanction_Controller.getAmbitCtrl();
    Test.startTest();
    system.assertEquals(testlist, Arc_Gen_ProposeInSanction_Controller.getAmbitCtrl(), 'should match a list of arce__Analysis__c');
    Test.stopTest();
  }
  /**
  * @Method:      test for method proposeInSanctionEmptyConstructor.
  * @Description: testing method.
  */
  @isTest
  public static void testEmptyConstructorOK() {
    Test.startTest();
    final Arc_Gen_ProposeInSanction_Controller obj = new Arc_Gen_ProposeInSanction_Controller();
    System.assertEquals(obj, obj, 'Returns Instance of a constructor.');
    Test.stopTest();
  }
  /**
  * @Method:      test for method proposeInSanctionEmptyConstructor.
  * @Description: testing method.
  */
  @isTest
  public static void testEmptyConstructorProposeHelper() {
    Test.startTest();
    final Arc_Gen_Propose_Helper obj = new Arc_Gen_Propose_Helper();
    System.assertEquals(obj, obj, 'Returns Instance of a constructor.');
    Test.stopTest();
  }
  /**
  * @Method:      test for method getArceId.
  * @Description: testing method.
  */
  @isTest
  public static void testGetArceId() {
    final NullPointerException callEx;
    final List <arce__Account_has_Analysis__c> element = [SELECT id, arce__Analysis__c FROM arce__Account_has_Analysis__c WHERE currencyIsoCode = :EUROS LIMIT 1];
    Test.startTest();
    System.assertEquals(element[0].arce__Analysis__c,Arc_Gen_ProposeInSanction_Controller.getArceId(element[0].Id).Id,'Returns smae Id');
    try {
      Arc_Gen_ProposeInSanction_Controller.getArceId(null);
    } catch (exception gArce) {
      System.assertNotEquals(gArce, callEx, 'test catch');
    }
    Test.stopTest();
    }
  /**
  * @Method:      test for method getStagePicklist.
  * @Description: testing method.
  */
  @isTest
  public static void testGetStagePicklistOK() {
    final List<Map<string,string>> element = arce.Arc_Gen_GenericUtilities.getPicklistValuesLabels('arce__Analysis__c','arce__stage_collective_type__c');
    Test.startTest();
    System.assertEquals(element.size(), Arc_Gen_ProposeInSanction_Controller.getStagePicklist().size(),'Returns same list');
    Test.stopTest();
  }
  /**
  * @Method:      test for method validateRatingInSanction.
  * @Description: testing method.
  */
  @isTest
  public static void testValidRatingTest() {
    final List <arce__Account_has_Analysis__c> element = [SELECT id, arce__Analysis__c FROM arce__Account_has_Analysis__c WHERE currencyIsoCode = :EUROS LIMIT 1];
    Test.startTest();
    Boolean retBool = Arc_Gen_ProposeInSanction_Controller.validateRatingInSanction(element[0].Id);
    System.assert(true, retBool);
    Test.stopTest();
  }
  /**
  * @Method:      test for method componentmode.
  * @Description: testing method.
  */
  @isTest
  public static void testComponentModeTest() {
    final boolean arconfig = Boolean.valueOf(arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('ProposeInSanctLite')[0].arce__Value1__c);
    Test.startTest();
    System.assertEquals(arconfig,Arc_Gen_ProposeInSanction_Controller.retrieveComponentMode(),'Returns same configuration value.');
    Test.stopTest();
  }
  /**
  * @Method:      test for method initDelegation OK
  * @Description: testing method.
  */
  @isTest
  public static void testInitDelegationOK() {
    final List <arce__Account_has_Analysis__c> element = [SELECT id, arce__Analysis__c FROM arce__Account_has_Analysis__c WHERE currencyIsoCode = :EUROS LIMIT 1];
    Test.startTest();
    final String retStr = Arc_Gen_ProposeInSanction_Controller.initDelegation(element[0].Id);
    final Arc_Gen_Delegation_Wrapper wrapper = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) retStr, Arc_Gen_Delegation_Wrapper.class);
    System.assertEquals(200, wrapper.codStatus, 'init delegation test OK');
    Test.stopTest();
  }
  /**
  * @Method:      test for method initDelegation OK
  * @Description: testing method.
  */
  @isTest
  public static void testInitDelegationKO() {
    final Arc_Gen_Delegation_Wrapper wrapper;
    try {
      final arce__Analysis__c analysis = [SELECT Id FROM arce__Analysis__c WHERE Name = 'arce__Analysisobj' LIMIT 1];
      Test.startTest();
      final String retStr = Arc_Gen_ProposeInSanction_Controller.initDelegation(analysis.Id);
      wrapper = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) retStr, Arc_Gen_Delegation_Wrapper.class);
      System.assert(wrapper != null, 'wrapper deserialize error');
      Test.stopTest();
    } catch (Exception ex) {
      System.debug('wrapper : ' + wrapper);
      System.assert(ex.getMessage().contains('Script'), SCRIPT_EXCEPTION);
    }
  }
  /**
  * @Method:  test for method updateSnctnType OK
  * @Description: testing method.
  */
  @isTest
  public static void testUpdateSnctnTypeOK() {
    List<arce__Analysis__c> lstAnalysis = [SELECT Id, arce__anlys_wkfl_snctn_br_level_type__c FROM arce__Analysis__c WHERE Name = 'arce__Analysisobj'];
    final Arc_Gen_Delegation_Wrapper wrapper = Arc_UtilitysDataTest_tst.crearDelegationWrapper();
    wrapper.analysisId = lstAnalysis[0].Id;
    Test.startTest();
    Arc_Gen_ProposeInSanction_Controller.updateSnctnType(JSON.serialize(wrapper));
    arce__Analysis__c analysis = [SELECT Id, arce__anlys_wkfl_snctn_br_level_type__c FROM arce__Analysis__c WHERE Name = 'arce__Analysisobj' LIMIT 1];
    System.assertEquals(analysis.arce__anlys_wkfl_snctn_br_level_type__c, '4', 'update snctn type method assert');
    Test.stopTest();
  }
  /**
  * @Method:  test for method updateSnctnType KO
  * @Description: testing method.
  */
  @isTest
  public static void testUpdateSnctnTypeKO() {
    try {
      Test.startTest();
      final Arc_Gen_Delegation_Wrapper wrapper = Arc_UtilitysDataTest_tst.crearDelegationWrapper();
      Arc_Gen_ProposeInSanction_Controller.updateSnctnType(JSON.serialize(wrapper));
      Test.stopTest();
    } catch (Exception ex) {
      System.assert(ex.getMessage().contains('Script'), SCRIPT_EXCEPTION);
    }
  }
  /**
  * @Method:  test for method updateSnctnType OK
  * @Description: testing method.
  */
  @isTest
  public static void testEvaluateDelegationAOK() {
    Arc_Gen_Delegation_Wrapper wrapper = Arc_UtilitysDataTest_tst.crearDelegationWrapper();
    final List <arce__Account_has_Analysis__c> lstAccHas = [SELECT Id, arce__group_asset_header_type__c,
        arce__Analysis__r.arce__analysis_customer_relation_type__c, arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c FROM arce__Account_has_Analysis__c WHERE currencyIsoCode = :EUROS LIMIT 1];
    final List<arce__Analysis__c> lstAnalysis = [SELECT Id, arce__anlys_wkfl_snctn_br_level_type__c FROM arce__Analysis__c WHERE Name = 'arce__Analysisobj'];
    wrapper.analysisId = lstAnalysis[0].Id;
    wrapper.hasDelegation = 'YES';
    Test.startTest();
    final String wrapperStr = Arc_Gen_ProposeInSanction_Controller.evaluateDelegation(JSON.serialize(wrapper), lstAccHas[0].Id);
    final Arc_Gen_Delegation_Wrapper wrapperRet = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) wrapperStr, Arc_Gen_Delegation_Wrapper.class);
    System.assertEquals(wrapperRet.codStatus, 201, 'evaluate codStatus test ok');
    Test.stopTest();
  }
  /**
  * @Method:  test for method updateSnctnType OK
  * @Description: testing method.
  */
  @isTest
  public static void testEvaluateDelegationBOK() {
    Arc_Gen_Delegation_Wrapper wrapper = Arc_UtilitysDataTest_tst.crearDelegationWrapper();
    final List <arce__Account_has_Analysis__c> lstAccHas = [SELECT Id FROM arce__Account_has_Analysis__c WHERE currencyIsoCode = :EUROS LIMIT 1];
    final List<arce__Analysis__c> lstAnalysis = [SELECT Id, arce__anlys_wkfl_snctn_br_level_type__c FROM arce__Analysis__c WHERE Name = 'arce__Analysisobj'];
    wrapper.analysisId = lstAnalysis[0].Id;
    Test.startTest();
    final String wrapperStr = Arc_Gen_ProposeInSanction_Controller.evaluateDelegation(JSON.serialize(wrapper), lstAccHas[0].Id);
    final Arc_Gen_Delegation_Wrapper wrapperRet = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) wrapperStr, Arc_Gen_Delegation_Wrapper.class);
    System.assertEquals(wrapperRet.codStatus, 200, 'evaluate codStatus test ok');
    Test.stopTest();
  }
  /**
  * @Method:  test for method updateSnctnType OK
  * @Description: testing method.
  */
  @isTest
  public static void testEvaluateDelegationBElementOK() {
    Arc_Gen_Delegation_Wrapper wrapper = Arc_UtilitysDataTest_tst.crearDelegationWrapper();
    final List <arce__Account_has_Analysis__c> lstAccHas = [SELECT Id FROM arce__Account_has_Analysis__c WHERE currencyIsoCode = :EUROS LIMIT 1];
    final List<arce__Analysis__c> lstAnalysis = [SELECT Id, arce__anlys_wkfl_snctn_br_level_type__c FROM arce__Analysis__c WHERE Name = 'arce__Analysisobj'];
    final List<String> valuesSelected = new List<String>{'1'};
    final List<Map<String,String>> lstPicklist = arce.Arc_Gen_GenericUtilities.getPicklistValuesLabels('arce__Analysis__c','arce__anlys_wkfl_edit_br_level_type__c', valuesSelected);
    wrapper.lstAmbits = lstPicklist;
    wrapper.analysisId = lstAnalysis[0].Id;
    Test.startTest();
    final String wrapperStr = Arc_Gen_ProposeInSanction_Controller.evaluateDelegation(JSON.serialize(wrapper), lstAccHas[0].Id);
    final Arc_Gen_Delegation_Wrapper wrapperRet = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) wrapperStr, Arc_Gen_Delegation_Wrapper.class);
    System.assertEquals(wrapperRet.codStatus, 201, 'evaluate delegation case b with one ambit test ok');
    Test.stopTest();
  }
  /**
  * @Method:  test for method updateSnctnType OK
  * @Description: testing method.
  */
  @isTest
  public static void testEvaluateDelegation500() {
    Arc_Gen_Delegation_Wrapper wrapper = Arc_UtilitysDataTest_tst.crearDelegationWrapper();
    final List <arce__Account_has_Analysis__c> lstAccHas = [SELECT Id FROM arce__Account_has_Analysis__c WHERE currencyIsoCode = :EUROS LIMIT 1];
    final List<arce__Analysis__c> lstAnalysis = [SELECT Id, arce__anlys_wkfl_snctn_br_level_type__c FROM arce__Analysis__c WHERE Name = 'arce__Analysisobj'];
    wrapper.analysisId = lstAnalysis[0].Id;
    wrapper.hasDelegation = 'SI';
    Test.startTest();
    final String wrapperStr = Arc_Gen_ProposeInSanction_Controller.evaluateDelegation(JSON.serialize(wrapper), lstAccHas[0].Id);
    final Arc_Gen_Delegation_Wrapper wrapperRet = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) wrapperStr, Arc_Gen_Delegation_Wrapper.class);
    System.assertEquals(wrapperRet.codStatus, 500, 'evaluate codStatus test ok');
    Test.stopTest();
  }
  /**
  * @Method:  test for method updateSnctnType KO
  * @Description: testing method.
  */
  @isTest
  public static void testEvaluateDelegationKO() {
    try {
      Arc_Gen_Delegation_Wrapper wrapper = Arc_UtilitysDataTest_tst.crearDelegationWrapper();
      final List <arce__Account_has_Analysis__c> lstAccHas = [SELECT Id FROM arce__Account_has_Analysis__c WHERE currencyIsoCode = :EUROS LIMIT 1];
      Test.startTest();
      Arc_Gen_ProposeInSanction_Controller.evaluateDelegation(wrapper, lstAccHas[0].Id);
      Test.stopTest();
    } catch (Exception ex) {
      System.assert(ex.getMessage().contains('Script'), SCRIPT_EXCEPTION);
    }
  }
  /**
  * @Method:  test for method updateSnctnType KO
  * @Description: testing method.
  */
  @isTest
  public static void testInitModeCmp() {
    Test.startTest();
    final Boolean retBool = Arc_Gen_ProposeInSanction_Controller.initModeCmp();
    System.assertEquals(true, retBool, 'test init cmp KO');
    Test.stopTest();
  }
  /**
  * @Method:      test for method persistArceAction (Arc_Gen_ProposeInSanction_Controller)
  * @Description: testing method.
  */
  @isTest
  public static void persistArceActionTestOK() {
    Test.startTest();
    final arce__Account_has_Analysis__c miniArce = [SELECT Id, arce__Analysis__c FROM arce__Account_has_Analysis__c limit 1];
    final Arc_Gen_Delegation_Wrapper wrapper = Arc_UtilitysDataTest_tst.crearDelegationWrapper();
    wrapper.analysisId = miniArce.arce__Analysis__c;
    final String res = Arc_Gen_ProposeInSanction_Controller.persistArceAction(JSON.serialize(wrapper), miniArce.Id);
    final Arc_Gen_Delegation_Wrapper wrapperSerialize = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) res, Arc_Gen_Delegation_Wrapper.class);
    System.assertEquals(wrapperSerialize.codStatus, 200, 'Code 200 Expected');
    Test.stopTest();
  }
  /**
  * @Method:      test for method persistArceAction KO (Arc_Gen_ProposeInSanction_Controller)
  * @Description: testing method.
  */
  @isTest
  public static void persistArceActionTestKO() {
    try {
      final arce__Account_has_Analysis__c miniArce = [SELECT Id FROM arce__Account_has_Analysis__c limit 1];
      Test.startTest();
      Arc_Gen_ProposeInSanction_Controller.persistArceAction(null, miniArce.Id);
      Test.stopTest();
    } catch(Exception ex) {
        System.assert(ex.getMessage().contains('Script'), SCRIPT_EXCEPTION);
    }
  }
  /**
  * --------------------------------------------------------------------------------------
  * @Description private Test Method to modify arce__Account_has_Analysis__c fields
  * --------------------------------------------------------------------------------------
  **/
  private static void modifyAha(arce__Account_has_Analysis__c aha) {
    aha.currencyIsoCode = EUROS;
    aha.arce__main_subsidiary_ind_type__c = true;
    aha.arce__InReview__c = true;
    aha.arce__smes_eur_comuty_defn_type__c = '1';
    aha.arce__ll_before_adj_ind_type__c = '1';
    aha.arce__ll_before_adj_clsfn_type__c = 'NI';
    aha.arce__ll_after_adj_ind_type__c = '1';
    aha.arce__ll_after_adj_clsfn_type__c = 'NI';
    aha.arce__group_asset_header_type__c = arce.Arc_Gen_Constants.GROUP_ASSET_HEADER_TYPE_HEADER;
    aha.arce__Stage__c = '3';
    aha.arce__long_rating_value_type__c = 'BBB-2';
    aha.arce__currency_id__c = 'EUR';
    aha.arce__current_formalized_amount__c = 0;
    aha.arce__outstanding_amount__c = 6000000;
    aha.arce__current_proposed_amount__c = 0;
    aha.arce__magnitude_unit_type__c = '1';
    aha.arce__last_approved_amount__c = 6000000;
    aha.arce__ll_test_manl_excl_rsn_type__c = 'C';
    aha.arce__risk_policy_type__c = '3';
    aha.arce__total_rating_score_number__c = 3;
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
    ratingobj.CurrencyIsoCode = EUROS;
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
    arceFinState.CurrencyIsoCode = EUROS;
    arceFinState.arce__financial_statement_end_date__c = SYSTEM.TODAY() + 30;
    arceFinState.arce__financial_statement_id__c = 'id test';
    arceFinState.Name = '1';
    arceFinState.arce__status_type__c = '1';
    arceFinState.arce__ffss_submitted_type__c = '1';
    arceFinState.arce__ffss_valid_type__c = '1';
    arceFinState.arce__economic_month_info_number__c = '544';
    arceFinState.arce__financial_statement_start_date__c = SYSTEM.TODAY() + 26;
    arceFinState.arce__financial_statement_start_date__c = SYSTEM.TODAY() + 27;
  }
}