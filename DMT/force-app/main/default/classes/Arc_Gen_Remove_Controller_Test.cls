/**
  * @File Name          : Arc_Gen_Remove_Controller_Test.cls
  * @Description        : Test class for Remove button controller
  * @Author             : luisarturo.parra.contractor@bbva.com
  * @Group              : ARCE
  * @Last Modified By   : luisruben.quinto.munoz@bbva.com
  * @Last Modified On   : 27/8/2019 17:51:09
  * @Modification Log   :
  *==============================================================================
  * Ver         Date                     Author                 Modification
  *==============================================================================
  * 1.0    5/7/2019 12:50:32   luisarturo.parra.contractor@bbva.com     Initial Version
  * 1.1    6/21/2019 15:56:00   ismaelyovani.obregon.contractor@bbva.com     Add Method testPicklistMethod();
  * 1.2    27/08/2019   luisruben.quinto.munoz@bbva.com            Delete reference to .arce__Id__c.
  * 1.2.1  02/12/2019   german.sanchez.perez.contractor@bbva.com
  *                     franciscojavier.bueno@bbva.com             Api names modified with the correct name on business glossary
  * 1.2.2   07/01/2020    javier.soto.carrascosa@bbva.com Add support for account wrapper and setupaccounts
  * 1.2.3   15/09/2020    juanignacio.hita.contractor@bbva.com     Add new test method for increase coverage
  * 1.2.4   23/09/2020   saimassimilianno.jordana.contractor@bbva.com Added arce. namespace to all classes that are now in the arce-dependencies package
  * 1.3     02/02/2021    luisdavid.rivera.ortiz@bbva.com          Eliminated unused fields
  * 1.4     18/02/2021  joseluis.garcia4.contractor@bbva.com       Fix tests for action persistence service.
  **/
@isTest
public class Arc_Gen_Remove_Controller_Test {
  @testSetup
  static void insertData() {
    Arc_UtilitysDataTest_tst.setupAcccounts();
    final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
    final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');
    arce__Analysis__c arceobj = new arce__Analysis__c();
    arceobj.Name = 'arce__Analysisobj';
    arceobj.arce__analysis_customer_relation_type__c = '01';
    arceobj.CurrencyIsoCode = 'EUR';
    arceobj.arce__Group__c = groupAccount.accId;
    arceobj.arce__Stage__c = '1';
    arceobj.arce__wf_status_id__c = '02';
    insert arceobj;

    arce__Account_has_Analysis__c arceAccounthasAnalysisobj = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, arceobj.Id, groupAccount.accId, null);
    modifyAha(arceAccounthasAnalysisobj);
    insert arceAccounthasAnalysisobj;

    arce__rating__c ratingobj = Arc_UtilitysDataTest_tst.crearRating(null);
    modifyArceRating(ratingobj);
    insert ratingobj;

    arce__Financial_Statements__c arceFinancialStatements = Arc_UtilitysDataTest_tst.crearFinStatement(groupAccount.accId,arceAccounthasAnalysisobj.Id , ratingobj.Id, null);
    modifyArceFinStatement(arceFinancialStatements);
    insert arceFinancialStatements;

    arceAccounthasAnalysisobj.arce__ffss_for_rating_id__c = arceFinancialStatements.Id;
    update arceAccounthasAnalysisobj;

    arce__limits_typology__c lt = new arce__limits_typology__c();
    lt.Name = 'TOTAL GROUP';
    insert lt;

    arce__limits_exposures__c le = new arce__limits_exposures__c();
    le.arce__account_has_analysis_id__c = arceAccounthasAnalysisobj.Id;
    le.arce__limits_typology_id__c = lt.Id;
    le.arce__current_proposed_amount__c = 1622;
    insert le;
  }
  /**
    * @Method:      test for method updateRemoveInfo.
    * @Description: test updateRemoveInfo
  */
  @isTest
  public static void testmethod1() {
    List < arce__Account_has_Analysis__c > element = [SELECT arce__Analysis__c FROM arce__Account_has_Analysis__c WHERE currencyIsoCode = 'EUR' limit 1];
    Id tocheck=element[0].id;
    system.assertEquals(tocheck,element[0].Id, 'check that the Id matchs');
    Test.startTest();
    Arc_Gen_Remove_Controller.updateRemoveInfo(element[0].Id,'1','razon','1');
    Test.stopTest();
  }
  /**
    * @Method:      test for method getDiscardList.
    * @Description: test for method getDiscardList.
  */
  @isTest
  public static void testPicklistMethodCorrect() {
    Test.startTest();
    List<map<String,String>> listAssert = new List<map<String,String>>();
    listAssert = Arc_Gen_Remove_Controller.getDiscardList('arce__Analysis__c','arce__anlys_wkfl_discard_reason_id__c');
    system.assertEquals(Arc_Gen_Remove_service.getDiscardReasons(),listAssert,'the values are correct');
    Test.stopTest();
  }
  /**
    * @Method:      test exception of updateRemoveInfo method
    * @Description: test exception of updateRemoveInfo method
  */
  @isTest
  public static void testUpdateRemoveInfoKO() {
      List <arce__Account_has_Analysis__c> element = [SELECT id FROM arce__Account_has_Analysis__c WHERE currencyIsoCode = 'EUR' limit 1];
      try {
        Test.startTest();
        final String testDesc = 'LoremIpsumLoremIpsumLoremIpsumLoremIpsumLoremIpsumLoremIpsumLoremIpsumLoremIpsum' +
        'LoremIpsumLoremIpsumLoremIpsumLoremIpsumLoremIpsumLoremIpsumLoremIpsumLoremIpsumLoremIpsumLoremIpsum' +
        'LoremIpsumLoremIpsumLoremIpsumLoremIpsumLoremIpsumLoremIpsumLoremIpsumLoremIpsumLoremIpsumLoremIpsum';
        Arc_Gen_Remove_Controller.updateRemoveInfo(element[0].Id, 'aa', testDesc, '1');
        Test.stopTest();
      } catch (Exception e) {
        System.assertEquals('Script-thrown exception',e.getMessage(),'Exception returned');
      }
  }
  /**
  * --------------------------------------------------------------------------------------
  * @Description private Test Method to modify arce__Account_has_Analysis__c fields
  * --------------------------------------------------------------------------------------
  **/
  private static void modifyAha (arce__Account_has_Analysis__c aha){
    aha.currencyIsoCode = 'EUR';
    aha.arce__main_subsidiary_ind_type__c = true;
    aha.arce__InReview__c = true;
    aha.arce__smes_eur_comuty_defn_type__c = '1';
    aha.arce__ll_before_adj_ind_type__c = '1';
    aha.arce__ll_before_adj_clsfn_type__c = 'NI';
    aha.arce__ll_after_adj_ind_type__c = '1';
    aha.arce__ll_after_adj_clsfn_type__c = 'NI';
    aha.arce__group_asset_header_type__c = arce.Arc_Gen_Constants.GROUP_ASSET_HEADER_TYPE_HEADER;
  }
  /**
  * --------------------------------------------------------------------------------------
  * @Description private Test Method to modify arce__rating__c fields
  * --------------------------------------------------------------------------------------
  **/
  private static void modifyArceRating (arce__rating__c ratingobj){
    ratingobj.arce__adj_long_rating_value_type__c = 'AAA';
    ratingobj.arce__adj_short_rating_value_type__c = 'AAA';
    ratingobj.arce__adj_total_rating_score_number__c = 1;
    ratingobj.CurrencyIsoCode = 'EUR';
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
  private static void modifyArceFinStatement (arce__Financial_Statements__c arceFinancialStatements){
    arceFinancialStatements.arce__ffss_adjusted_type__c = '1';
    arceFinancialStatements.arce__ffss_auditor_qlfn_type__c = '1';
    arceFinancialStatements.arce__ffss_auditor_opinion_type__c = 'S';
    arceFinancialStatements.arce__ffss_auditor_opinion_desc__c = '1';
    arceFinancialStatements.arce__ffss_certification_type__c = 'AUDITED';
    arceFinancialStatements.CurrencyIsoCode = 'EUR';
    arceFinancialStatements.arce__financial_statement_end_date__c = SYSTEM.TODAY() + 30;
    arceFinancialStatements.arce__financial_statement_id__c = 'id test';
    arceFinancialStatements.Name = '1';
    arceFinancialStatements.arce__status_type__c = '1';
    arceFinancialStatements.arce__ffss_submitted_type__c = '1';
    arceFinancialStatements.arce__ffss_valid_type__c = '1';
    arceFinancialStatements.arce__economic_month_info_number__c = '544';
    arceFinancialStatements.arce__financial_statement_start_date__c = SYSTEM.TODAY() + 26;
    arceFinancialStatements.arce__financial_statement_start_date__c = SYSTEM.TODAY() + 27;
  }
}