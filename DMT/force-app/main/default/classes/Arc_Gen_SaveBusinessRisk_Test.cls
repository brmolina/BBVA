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
* |2019-05-01 Javier Soto Carrascosa
*             Changes in setup and test methods class
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* -----------------------------------------------------------------------------------------------
*/
@isTest
public class Arc_Gen_SaveBusinessRisk_Test {
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
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001','C000001'});
        final arce.Arc_Gen_Account_Wrapper fath = groupAccWrapper.get('G000001');
        final arce.Arc_Gen_Account_Wrapper kid = groupAccWrapper.get('C000001');
        Final arce__Analysis__c analysis = Arc_UtilitysDataTest_tst.crearArceAnalysis('Test Analysis', null, fath.accId);
        Insert analysis;
        arce__Sector__c sect = Arc_UtilitysDataTest_tst.crearSector('Executive Summ', '500', 'ExecSumm', null);
        Insert sect;
        Final arce__Account_has_Analysis__c accHasAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(sect.Id, analysis.Id, kid.accId, ' s-01');
        Insert accHasAnalysis;
        Final arce__Data_Collections__c colls = Arc_UtilitysDataTest_tst.crearDataCollection('E.B.I.T.D.A.', 'Income_Statement','03');
        Insert colls;
        Final arce__Table_Content_per_Analysis__c tblCont = Arc_UtilitysDataTest_tst.crearTableContentAnalysis(accHasAnalysis.Id, colls.Id, 'Income_Statement','2019');
        tblCont.arce__collection_order_type__c='3200';
        Insert tblCont;
        Final sObject[] accHas = new List<sObject>();
        accHas.add(accHasAnalysis);
        Final String resguardado = Arc_Gen_BusinessRisk_Pers_service.save(accHas);
        accHasAnalysis.arce__market_share_type__c = '1';
        accHasAnalysis.arce__exch_rate_vulnerability_type__c = '1';
        accHasAnalysis.arce__new_business_venture_type__c = '1';
        accHasAnalysis.arce__concentration_suppliers_type__c = '1';
        accHasAnalysis.arce__cust_conc_clients_type__c = '1';
        accHasAnalysis.arce__new_business_venture_type__c = '1';
        accHasAnalysis.arce__new_business_venture_desc__c = 'test';
        accHasAnalysis.arce__dependency_degree_cust_type__c = '1';
        Arc_Gen_BusinessRisk_Pers_service.save(new List<arce__Account_has_Analysis__c>{accHasAnalysis});
        System.assertNotEquals(null, resguardado , 'clase de guardado');
    }
}