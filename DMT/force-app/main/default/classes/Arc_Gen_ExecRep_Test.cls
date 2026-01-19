/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ExecRep_Test
* @Author   Ricardo Almanza ricardo.almanza.contractor@bbva.com
* @Date     Created: 2019-06-28
* @Group    ARCE
* @Last Modified By   : eduardoefrain.hernandez.contractor@bbva.com
* @Last Modified On   : 26/8/2019 12:01:53
* @Description Clase de prueba de Executive Summary
* @Changes :
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0    30/04/2019           ricardo.almanza.contractor@bbva.com     Initial Version
* 1.1    26/8/2019           ricardo.almanza.contractor@bbva.com     Add try catch functions
* 1.2    30/8/2019           ricardo.almanza.contractor@bbva.com     deleted methods not used and added field for validation rule
* 1.3    02/12/2019          ricardo.almanza.contractor@bbva.com     modified to match tipology level id
* 1.4    30/03/2020          mariohumberto.ramirez.contractor@bbva.com update test class
* 1.5    27/07/2020          mariohumberto.ramirez.contractor@bbva.com update test class
* 1.6    04/08/2020          mariohumberto.ramirez.contractor@bbva.com update test class
* 1.6    23/09/2020     saimassimilianno.jordana.contractor@bbva.com Added arce. namespace to all classes that are now in the arce-dependencies package
* 1.7    12/03/2021          juanpedro.benito.contractor@bbva.com Change arce__third_participant_per__c for arce__third_prtcpt_intervention_per__c
* 1.8    17/06/2021          juanignacio.hita.contractor@bbva.com    rollback 12/03/2021 commit  (PR: 1231)
*/
@SuppressWarnings('sf:NcssMethodCount, sf:ExcessiveMethodLength, PMD.NcssMethodCount')
@isTest

public class Arc_Gen_ExecRep_Test {
  /**
  * --------------------------------------------------------------------------------------
  * @Description Prueba metodo que valida Pagina metodos y clases para Executive Summary
  *
  * @example executiveSummaryTest()
  **/
  @isTest
  static void executiveSummaryTest() {
    Arc_UtilitysDataTest_tst.setupAcccounts();
    final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001','C000001'});
    final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');
    final arce.Arc_Gen_Account_Wrapper clientAccount = groupAccWrapper.get('C000001');
    arce__limits_typology__c l1 = Arc_UtilitysDataTest_tst.crearLimitTypology(System.Label.Arc_Gen_ExecRepTipologyTCR, null, null);
    l1.arce__risk_typology_level_id__c = 'TP_0006';
    l1.arce__risk_typology_level_type__c = '1';
    l1.arce__Typology_Order__c = 1;
    Insert l1;
    final arce__limits_typology__c ll1 = Arc_UtilitysDataTest_tst.crearLimitTypology(System.Label.Arc_Gen_ExecRepTipologyTCR+'1', null, null);
    ll1.arce__risk_typology_level_id__c = 'TP_0003';
    ll1.arce__risk_typology_level_type__c = '1';
    ll1.arce__Typology_Order__c = 1;
    Insert ll1;
    final arce__limits_typology__c ll2 = Arc_UtilitysDataTest_tst.crearLimitTypology('Ll2', ll1.Id, null);
    Insert ll2;
    final arce__limits_typology__c lll1 = Arc_UtilitysDataTest_tst.crearLimitTypology(System.Label.Arc_Gen_ExecRepTipologyTCR+'2', null, null);
    lll1.arce__risk_typology_level_id__c = 'TP_0013';
    lll1.arce__risk_typology_level_type__c = '1';
    lll1.arce__Typology_Order__c = 1;
    Insert lll1;
    final arce__limits_typology__c lll2 = Arc_UtilitysDataTest_tst.crearLimitTypology('Ll2', lll1.Id, null);
    Insert lll2;
    arce__limits_typology__c l2 = Arc_UtilitysDataTest_tst.crearLimitTypology('L2', l1.Id, null);
    Insert l2;
    arce__Analysis__c analysis = Arc_UtilitysDataTest_tst.crearArceAnalysis('Test Analysis', null, groupAccount.accId);
    analysis.arce__analysis_customer_relation_type__c = '01';
    Insert analysis;
    arce__Sector__c sect = Arc_UtilitysDataTest_tst.crearSector('Executive Summ', '500', 'ExecSumm', null);
    Insert sect;
    arce__Account_has_Analysis__c accHasAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(sect.Id, analysis.Id, groupAccount.accId, ' s-01');
    accHasAnalysis.arce__group_asset_header_type__c = '1';
    accHasAnalysis.arce__InReview__c = true;
    Insert accHasAnalysis;
    arce__Account_has_Analysis__c accHasAnalysisClient = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(sect.Id, analysis.Id, clientAccount.accId, ' s-01');
    accHasAnalysisClient.arce__group_asset_header_type__c = '2';
    accHasAnalysisClient.arce__InReview__c = true;
    accHasAnalysisClient.arce__ll_after_adj_ind_type__c = '1';
    Insert accHasAnalysisClient;
    insertShareHoldTbData(clientAccount.accId, analysis.Id);
    final arce__limits_exposures__c lim1 = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,accHasAnalysis.Id,l1.Id);
    Insert lim1;
    final arce__limits_exposures__c lim2 = Arc_UtilitysDataTest_tst.crearLimitExposures(lim1.Id,null,accHasAnalysis.Id,l2.Id);
    Insert lim2;
    final arce__limits_exposures__c lim3 = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,accHasAnalysis.Id,ll1.Id);
    Insert lim3;
    final arce__limits_exposures__c lim4 = Arc_UtilitysDataTest_tst.crearLimitExposures(lim3.Id,null,accHasAnalysis.Id,ll2.Id);
    Insert lim4;
    final arce__limits_exposures__c lim5 = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,accHasAnalysis.Id,lll1.Id);
    Insert lim5;
    final arce__limits_exposures__c lim6 = Arc_UtilitysDataTest_tst.crearLimitExposures(lim5.Id,null,accHasAnalysis.Id,lll2.Id);
    Insert lim6;
    final arce__limits_exposures__c mod = Arc_UtilitysDataTest_tst.crearLimitExposures(lim2.Id,null,accHasAnalysis.Id,null);
    mod.arce__curr_apprv_deleg_dchan_amount__c = 1;
    mod.arce__currency_id__c = 'MXN';
    Insert mod;
    arce__Data_Collections__c colls = Arc_UtilitysDataTest_tst.crearDataCollection('E.B.I.T.D.A.', 'Income_Statement','03');
    Insert colls;
    arce__Data_Collections__c country1 = Arc_UtilitysDataTest_tst.crearDataCollection('Mexico', 'Geographies', '05');
    Insert country1;
    arce__Table_Content_per_Analysis__c tblCont = Arc_UtilitysDataTest_tst.crearTableContentAnalysis(accHasAnalysis.Id, colls.Id, 'Income_Statement','2019');
    tblCont.arce__collection_order_type__c='3200';
    Insert tblCont;
    arce__Table_Content_per_Analysis__c countryData1 = Arc_UtilitysDataTest_tst.crearTableContentAnalysis(accHasAnalysis.Id, country1.Id, 'Geographies', '2019');
    Insert countryData1;
    //arce__Table_Content_per_Analysis__c where arce__account_has_analysis_id__c = :rid AND arce__collection_order_type__c in :tblscpa
    Arc_Gen_ExecRep_Service_Helper execRep = new Arc_Gen_ExecRep_Service_Helper();
    execRep.getPDFinBase64(accHasAnalysis.Id);
    PageReference templateVF = Page.Arc_Gen_ExecRepVF;
    Test.setCurrentPage(templateVF);
    templateVF.getParameters().put('Id', accHasAnalysis.Id);
    ApexPages.StandardController sc = new ApexPages.StandardController(accHasAnalysis);

    Arc_Gen_ExecRepCtrl execRepCtrl = new Arc_Gen_ExecRepCtrl(sc);
    System.assertNotEquals(null, execRepCtrl.wrapIns, 'Executive Summary con datos');
    arce__Third_Participant_Details__c thrd = new arce__Third_Participant_Details__c();
    arce__Third_Participant_Details__c[] thrdLst = new List<arce__Third_Participant_Details__c> ();
    Arc_Gen_ThirdParticipantDetails_Data.insertTableContent(thrdLst);
    Arc_Gen_ThirdParticipantDetails_Data.updateTableContent(thrdLst);
    Arc_Gen_ThirdParticipantDetails_Data.deleteTableContent(thrdLst);
    thrdLst.add(thrd);
    Arc_Gen_ThirdParticipantDetails_Data.insertTableContent(thrdLst);
    Arc_Gen_ThirdParticipantDetails_Data.updateTableContent(thrdLst);
    arce__Third_Participant__c thrdMain = Arc_UtilitysDataTest_tst.crearThirdParticipant(null);
    thrdMain.arce__third_participant_role_type__c = '03';
    Insert thrdMain;
    arce__Third_Participant_Details__c thrd2 = Arc_UtilitysDataTest_tst.crearThirdParticipantDetails(accHasAnalysis.Id, thrdMain.Id, null);
    thrdLst = new List<arce__Third_Participant_Details__c> ();
    thrdLst.add(thrd2);
    Arc_Gen_ThirdParticipantDetails_Data.insertTableContent(thrdLst);
    arce__main_banks__c mnBnks = new arce__main_banks__c();
    arce__main_banks__c[] mnBnksLst = new List<arce__main_banks__c> ();
    Arc_Gen_MainBanks_Data.insertTableContent(mnBnksLst);
    Arc_Gen_MainBanks_Data.updateTableContent(mnBnksLst);
    mnBnksLst.add(mnBnks);
    Arc_Gen_MainBanks_Data.insertTableContent(mnBnksLst);
    Arc_Gen_MainBanks_Data.updateTableContent(mnBnksLst);
    arce__main_banks__c mnBnks2 = Arc_UtilitysDataTest_tst.crearMainBanks(accHasAnalysis.Id, null);
    mnBnksLst = new List<arce__main_banks__c> ();
    mnBnksLst.add(mnBnks2);
    Arc_Gen_MainBanks_Data.insertTableContent(mnBnksLst);
    Arc_Gen_MainBanks_Data.updateTableContent(mnBnksLst);
    arce__Table_Content_per_Analysis__c tblCnt = new arce__Table_Content_per_Analysis__c();
    arce__Table_Content_per_Analysis__c[] tblCntLst = new List<arce__Table_Content_per_Analysis__c> ();
    Arc_Gen_TableContentPerAnalysis_Data.insertTableContent(tblCntLst);
    Arc_Gen_TableContentPerAnalysis_Data.updateTableContent(tblCntLst);
    Arc_Gen_TableContentPerAnalysis_Data.deleteTableContent(tblCntLst);
    tblCntLst.add(tblCnt);
    Arc_Gen_TableContentPerAnalysis_Data.insertTableContent(tblCntLst);
    Arc_Gen_TableContentPerAnalysis_Data.updateTableContent(tblCntLst);
    arce__Table_Content_per_Analysis__c tblCnt2 = Arc_UtilitysDataTest_tst.crearTableContentAnalysis(accHasAnalysis.Id, colls.Id, 'Income_Statement','2019');
    tblCont.arce__collection_order_type__c='3200';
    tblCntLst = new List<arce__Table_Content_per_Analysis__c> ();
    tblCntLst.add(tblCnt2);
    Arc_Gen_TableContentPerAnalysis_Data.insertTableContent(tblCntLst);
    Arc_Gen_TableContentPerAnalysis_Data.deleteTableContent(tblCntLst);
    final Arc_Gen_ExecRep_Service exeServ = new Arc_Gen_ExecRep_Service();
    System.assertNotEquals(null, exeServ, 'Service created');
  }
  /*
  * @Description  Test Method
  */
  @isTest
  static void maturityFitTest() {
    List<List<String>> maturity = new List<List<String>>();
    List<List<String>> ratios = new List<List<String>>();
    List<List<String>> newMat = new List<List<String>>();
    List<String> auxMat = new List<String>{'1'};
    maturity.add(auxMat);
    List<String> auxRat1 = new List<String>{'1'};
    ratios.add(auxRat1);
    ratios.add(auxRat1);
    newMat = Arc_Gen_ExecRep_Service_Helper.fitMaturityData(ratios, maturity);
    system.assertEquals(ratios.size(),newMat.size(), 'The size of the rows have the same size');
  }
  /*
  * @Description  Test Method
  */
  static void insertShareHoldTbData(Id accId, Id analysisId) {
    final List<arce__Account_has_Analysis__c> accHasAnLts = new List<arce__Account_has_Analysis__c>();
    for (integer i = 0; i <= 10; i++) {
        arce__Account_has_Analysis__c accHasAnAux = new arce__Account_has_Analysis__c();
        accHasAnAux = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, analysisId, accId, ' s-01');
        accHasAnAux.arce__group_asset_header_type__c = '2';
        accHasAnAux.arce__InReview__c = true;
        accHasAnAux.arce__ll_after_adj_ind_type__c = '1';
        accHasAnAux.arce__participant_name__c = 'participant' + i;
        accHasAnLts.add(accHasAnAux);
    }
    insert accHasAnLts;
    final List<arce__Third_Participant__c> thirdPartLts = new List<arce__Third_Participant__c>();
    for (integer i = 0; i <= 10; i++) {
        arce__Third_Participant__c thirdpart = new arce__Third_Participant__c();
        thirdpart = Arc_UtilitysDataTest_tst.crearThirdParticipant(null);
        thirdpart.Name = 'Jaime';
        thirdPartLts.add(thirdpart);
    }
    insert thirdPartLts;
    final List<arce__third_participant_details__c> thirdPartDetailsLts = new List<arce__third_participant_details__c>();
    for (integer i = 0; i < accHasAnLts.size(); i++) {
        arce__third_participant_details__c thirdPartDetails = new arce__third_participant_details__c();
        thirdPartDetails = Arc_UtilitysDataTest_tst.crearThirdParticipantDetails(accHasAnLts[i].Id, thirdPartLts[i].Id, 'Shareholders');
        thirdPartDetails.arce__third_participant_per__c = 100;
        thirdPartDetails.arce__third_participant_role_type__c = '03';
        thirdPartDetailsLts.add(thirdPartDetails);
    }
    insert thirdPartDetailsLts;
  }
  /*
  * @Description  Test Method
  */
  @isTest
  static void serviceTest() {
      final Arc_Gen_ExecRep_Group_Service service = new Arc_Gen_ExecRep_Group_Service();
      System.assertEquals(service, service, 'Service OK');
  }
  /*
  * @Description  Test Method
  */
  @isTest
  static void helperTest() {
      final Arc_Gen_ExecRep_Group_Helper helper = new Arc_Gen_ExecRep_Group_Helper();
      System.assertEquals(helper, helper, 'helper OK');
  }
}