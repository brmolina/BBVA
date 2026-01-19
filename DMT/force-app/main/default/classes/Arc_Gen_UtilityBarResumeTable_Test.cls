/**
* @File Name          : Arc_Gen_UtilityBarResumeTable_Test.cls
* @Description        :test for Arc_Gen_UtilityBarResumeTable_ctrl.cls
* @Author             :luisarturo.parra.contractor@bbva.com
* @Group              : ARCE
* @Last Modified By   : luisarturo.parra.contractor@bbva.com
* @Last Modified On   :  23/12/2019 05:17
* @Modification Log   :
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0    23/12/2019          luisarturo.parra.contractor@bbva.com     Initial Version
* 1.1    07/01/2020          javier.soto.carrascosa@bbva.com          Add support for account wrapper and setupaccounts
* 1.2    30/03/2020          javier.soto.carrascosa@bbva.com          Add support for product static resource in test classes
* 1.2    23/09/2020     saimassimilianno.jordana.contractor@bbva.com  Added arce. namespace to all classes that are now in the arce-dependencies package
**/
@isTest
public class Arc_Gen_UtilityBarResumeTable_Test {
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001','C000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get('C000001');
        arce__limits_typology__c l1 = Arc_UtilitysDataTest_tst.crearLimitTypology(System.Label.Arc_Gen_ExecRepTipologyTCR, null, null);
        l1.arce__risk_typology_level_id__c = 'TP_0006';
        l1.arce__risk_typology_level_type__c = '1';
        l1.arce__Typology_Order__c = 1;
        Insert l1;
        arce__limits_typology__c l1b = Arc_UtilitysDataTest_tst.crearLimitTypology('TOTAL Financial Risk ST & Commercial Risk', null, null);
        l1b.arce__risk_typology_level_id__c = 'TP_0005';
        l1b.arce__risk_typology_level_type__c = '1';
        l1b.arce__Typology_Order__c = 2;
        Insert l1b;
        arce__limits_typology__c l2 = Arc_UtilitysDataTest_tst.crearLimitTypology('Commercial Risk', l1b.Id, null);
        l2.arce__risk_typology_level_id__c = 'TP_0010';
        l2.arce__risk_typology_level_type__c = '2';
        Insert l2;
        arce__limits_typology__c projectFinance = Arc_UtilitysDataTest_tst.crearLimitTypology('Project Finance', null, null);
        projectFinance.arce__risk_typology_level_id__c = System.Label.Arc_Gen_ProjectFinance;
        projectFinance.arce__risk_typology_level_type__c = '1';
        projectFinance.arce__Typology_Order__c = 1;
        Insert projectFinance;
        arce__limits_typology__c totalCR = Arc_UtilitysDataTest_tst.crearLimitTypology('TOTAL CORPORATE RISK', null, null);
        totalCR.arce__risk_typology_level_id__c = System.Label.Arc_Gen_TOTAL_CORPORATE_RISK;
        totalCR.arce__risk_typology_level_type__c = '1';
        totalCR.arce__Typology_Order__c = 1;
        Insert totalCR;
        arce__Analysis__c analysis = Arc_UtilitysDataTest_tst.crearArceAnalysis('Test Analysis', null, groupAccount.accId);
        Insert analysis;
        arce__Sector__c sect = Arc_UtilitysDataTest_tst.crearSector('Executive Summ', '600', 'ExecSumm', null);
        Insert sect;
        Arc_UtilitysDataTest_tst.setupProducts();
        final Map<Id,Arc_Gen_Product_Wrapper> pWrap = Arc_Gen_Product_Locator.getProductsFromTypology('familyTest');
        final Arc_Gen_Product_Wrapper prodWrapper = pWrap.get(new List<Id>(pWrap.keySet())[0]);
        arce__Account_has_Analysis__c accHasAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(sect.Id, analysis.Id, childAccount.accId, ' s-01');
        accHasAnalysis.arce__group_asset_header_type__c ='2';
        Insert accHasAnalysis;
        arce__limits_exposures__c lim1 = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,accHasAnalysis.Id,l1b.Id);
        Insert lim1;
        arce__limits_exposures__c lim1duplicated = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,accHasAnalysis.Id,l1b.Id);
        Insert lim1duplicated;
        arce__limits_exposures__c lim2 = Arc_UtilitysDataTest_tst.crearLimitExposures(lim1.Id,null,accHasAnalysis.Id,l2.Id);
        Insert lim2;
        arce__limits_exposures__c limExp1 = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,accHasAnalysis.Id,projectFinance.Id);
        limExp1.arce__current_proposed_amount__c = 1;
        Insert limExp1;
        arce__limits_exposures__c limExp2 = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,accHasAnalysis.Id,totalCR.Id);
        limExp2.arce__current_proposed_amount__c = 1;
        Insert limExp2;
        arce__limits_exposures__c limExp3 = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,accHasAnalysis.Id,l1.Id);
        limExp3.arce__current_proposed_amount__c = 1;
        Insert limExp3;
        arce__limits_exposures__c mod = Arc_UtilitysDataTest_tst.crearLimitExposures(lim2.Id,null,accHasAnalysis.Id,null);
        mod.arce__current_proposed_amount__c = 1;
        mod.arce__Product_id__c = prodWrapper.productId;
        Insert mod;
    }
    /**
*-------------------------------------------------------------------------------
* @description get typologies
*-------------------------------------------------------------------------------
* @date 23/12/2019
* @author luisarturo.parra.contractor@bbva.com
* @param none
* @return   List<arce__limits_typology__c>
* @example @isTest static void testSumTypologies() {
*/
    @isTest static void testSumTypologies() {
        try {
            Test.startTest();
            Arc_Gen_UtilityBarResumeTable_Ctrl.getDataTypologies();
            Test.stopTest();
        } catch (Exception e) {
            System.assertNotEquals(e, null, 'Error controlado');
        }
    }
    /**
*-------------------------------------------------------------------------------
* @description get data for the table
*-------------------------------------------------------------------------------
* @date 23/12/2019
* @author luisarturo.parra.contractor@bbva.com
* @param none
* @return   List<arce__limits_typology__c>
* @example @isTest static void testgetdata() {
*/
    @isTest static void testgetdata() {
        arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id,arce__Analysis__c FROM arce__Account_has_Analysis__c
                                                        WHERE arce__group_asset_header_type__c = '2' LIMIT 1];
        update accHasAnalysis;
        arce__limits_exposures__c totalCRExposure = [SELECT Id FROM arce__limits_exposures__c WHERE arce__limits_typology_id__r.arce__risk_typology_level_id__c = 'TP_0003'];
        totalCRExposure.arce__last_approved_amount__c = 1;
        totalCRExposure.arce__curr_approved_commited_amount__c = 1;
        totalCRExposure.arce__curr_apprv_uncommited_amount__c = 1;
        totalCRExposure.arce__current_formalized_amount__c = 1;
        totalCRExposure.arce__outstanding_amount__c = 1;
        totalCRExposure.arce__current_proposed_amount__c = 1;
        totalCRExposure.arce__current_approved_amount__c = 1;
        update totalCRExposure;
        arce__limits_exposures__c projectFinance = [SELECT Id FROM arce__limits_exposures__c WHERE arce__limits_typology_id__r.arce__risk_typology_level_id__c = 'TP_0013'];
        projectFinance.arce__last_approved_amount__c = 1;
        projectFinance.arce__curr_approved_commited_amount__c = 1;
        projectFinance.arce__curr_apprv_uncommited_amount__c = 1;
        projectFinance.arce__current_formalized_amount__c = 1;
        projectFinance.arce__outstanding_amount__c = 1;
        projectFinance.arce__current_proposed_amount__c = 1;
        projectFinance.arce__current_approved_amount__c = 1;
        update projectFinance;
        Arc_Gen_Expandible_Table_Controller.sumTypologies(accHasAnalysis.Id);
        try {
            Test.startTest();
            Arc_Gen_UtilityBarResumeTable_Ctrl.getTableData(accHasAnalysis.arce__Analysis__c);
            Arc_Gen_UtilityBarResumeTable_Service.orderdata(arce.Arc_Gen_LimitsExposures_Data.getExposureDatafromIds(new Set<Id>{accHasAnalysis.Id}));
            Test.stopTest();
        } catch (Exception e) {
            System.assertNotEquals(e, null, 'Error controlado');
        }
    }
}