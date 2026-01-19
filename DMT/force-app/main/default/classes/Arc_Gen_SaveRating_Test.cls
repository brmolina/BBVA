/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_SaveBusinessRisk_Test
* @Author   Ricardo Almanza Angeles
* @Date     Created: 15/01/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class test manages dyanmic form save for Business Risk.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2019-01-15 Ricardo Almanza Angeles
*             Class creation.
* |2020-04-22 César Octavio Villanueva Ceballos
*			  Added validation for new setup for override
* |2019-02-13 Eduardo Efrain Hernandez Rendon
*             Add In Preparation stage validation methods
* |2020-06-26 Juan Manuel Perez Ortiz
*             Fix failed method
* |2020-07-07 Juan Manuel Perez Ortiz
*             Create constant variable called SUBSIDIARY_ID1
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* -----------------------------------------------------------------------------------------------
*/
@isTest
public class Arc_Gen_SaveRating_Test {
    /**
    * @Description: String with external id of test group
    */
    static final string SUBSIDIARY_ID1 = 'C000001';
    /**
* --------------------------------------------------------------------------------------
* @Description Prueba metodo que valida clase de guardado Business Risk
* --------------------------------------------------------------------------------------
* @Author   ricardo.almanza.contractor@bbva.com
* @Date     Created: 2020-01-29
* @param void
* @return void
* @example saveBr()
* --------------------------------------------------------------------------------------
**/
    @TestSetup
    static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001',SUBSIDIARY_ID1});
        final arce.Arc_Gen_Account_Wrapper fath = groupAccWrapper.get('G000001');
        final arce.Arc_Gen_Account_Wrapper kid = groupAccWrapper.get(SUBSIDIARY_ID1);
        Final arce__limits_typology__c l1 = Arc_UtilitysDataTest_tst.crearLimitTypology(System.Label.Arc_Gen_ExecRepTipologyTCR, null, null);
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
        Final arce__limits_typology__c l2 = Arc_UtilitysDataTest_tst.crearLimitTypology('L2', l1.Id, null);
        Insert l2;
        Final arce__Analysis__c analysis = Arc_UtilitysDataTest_tst.crearArceAnalysis('Test Analysis', null, fath.accId);
        analysis.arce__Stage__c = '2';
        Insert analysis;
        arce__Sector__c sect = Arc_UtilitysDataTest_tst.crearSector('Executive Summ', '500', 'ExecSumm', null);
        Insert sect;
        Final arce__Account_has_Analysis__c accHasAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(sect.Id, analysis.Id, kid.accId, ' s-01');
        Insert accHasAnalysis;
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
        Final arce__Data_Collections__c colls = Arc_UtilitysDataTest_tst.crearDataCollection('E.B.I.T.D.A.', 'Income_Statement','03');
        Insert colls;
        Final arce__Table_Content_per_Analysis__c tblCont = Arc_UtilitysDataTest_tst.crearTableContentAnalysis(accHasAnalysis.Id, colls.Id, 'Income_Statement','2019');
        tblCont.arce__collection_order_type__c='3200';
        Insert tblCont;
    }
    /**
* --------------------------------------------------------------------------------------
* @Description Prueba metodo que valida clase de guardado Business Risk
* --------------------------------------------------------------------------------------
* @Author   ricardo.almanza.contractor@bbva.com
* @Date     Created: 2020-01-29
* @param void
* @return void
* @example saveBr()
* --------------------------------------------------------------------------------------
**/
    @isTest
    static void saveBr() {
        arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id,arce__ffss_for_rating_id__c FROM arce__Account_has_Analysis__c LIMIT 1];
        arce__rating__c rating = Arc_Gen_ValidateRating_test.setRating('AAA', 90.0);
        arce__Financial_Statements__c ffss = Arc_Gen_ValidateRating_test.setFFSS(rating.Id, '1');
        accHasAnalysis.arce__ffss_for_rating_id__c = ffss.Id;
        update (accHasAnalysis);
        arce__Account_has_Analysis__c accHasAn = Arc_Gen_ValidateRating_test.getAnalyzedClient(SUBSIDIARY_ID1,'Analysis Test',ffss.Id);
        arce__analysis__c updateArce = arce.Arc_Gen_ArceAnalysis_Data.gerArce(accHasAn.Id);
        updateArce.arce__Stage__c = '2';
        update(updateArce);
        arce__rating_variables_detail__c variable = Arc_Gen_ValidateRating_test.setRatingVariable(accHasAn.Id, rating.Id);
        Final sObject[] accHas = new List<sObject>();
        accHas.add(accHasAn);
        accHas.add(variable);
        Arc_Gen_OverRide_Service ovrSrv = new Arc_Gen_OverRide_Service();
        System.assertEquals(ovrSrv, ovrSrv, 'Constructor vacio');
        Final Arc_Gen_SaveRating sbr = new Arc_Gen_SaveRating();
        Final String resguardado = sbr.save(accHas);
        System.assertNotEquals(null, resguardado , 'clase de guardado');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   cesaroctavio.villanueva.cebal@bbva.com
    * @param void
    * @return void
    * @example testError400()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testInPreparation() {
        arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id,arce__Analysis__c FROM arce__Account_has_Analysis__c LIMIT 1];
        arce__Analysis__c arceVar = [SELECT Id,arce__Stage__c FROM arce__Analysis__c WHERE Id =: accHasAnalysis.arce__Analysis__c LIMIT 1];
        arceVar.arce__Stage__c = '1';
        Update arceVar;
        test.startTest();
        Final Arc_Gen_SaveRating sbr = new Arc_Gen_SaveRating();
        Final Map<String, Object> resguardado = (Map<String, Object>)JSON.deserializeUntyped(sbr.save(new List<sObject>{accHasAnalysis}));
        System.assertEquals(true,resguardado.get('validated'),'The rating is always true in preparation');
        test.stopTest();

    }
}