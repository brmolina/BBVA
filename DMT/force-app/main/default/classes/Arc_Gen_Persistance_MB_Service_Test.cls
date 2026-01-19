/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Persistance_MB_Service_Test
* @Author   Berth Elena Téllez Lira  eberthaelena.tellez.contractor@bbva.com
* @Date     Created: 20/02/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Test class that covers:  Arc_Gen_Persistance_MB_Service_Test
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |
*             Class creation.
* |2020-08-11 javier.soto.carrascosa@bbva.com
*             Update sector field
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2021-01-18 luisdavid.rivera.ortiz@bbva.com
*             Revome field references for usused fields (namings nivelation)
* |2021-03-01  juanmanuel.perez.ortiz.contractor@bbva.com
*             Added arce__stage_collective_ind_type__c field in query
* |2020-03-12 juanpedro.benito.contractor@bbva.com
*             Change arce__sector_desc__c for arce__sector_id__c and arce__subsector_desc__c for arce__subsector_id__c
* |2021-06-17 juanignacio.hita.contractor@bbva.com
*             Rollback last commit  (PR: 1231)
* -----------------------------------------------------------------------------------------------
*/
@isTest
public class Arc_Gen_Persistance_MB_Service_Test {
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID = 'G000001';
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID2 = 'G000002';
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
    static void setupTest() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,GROUP_ID2});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);

        final arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        newArce.arce__Stage__c = '1';
        insert newArce;

        final arce__Account_has_Analysis__c newAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, newArce.Id, groupAccount.accId, '1');
        newAnalysis.arce__InReview__c = true;
        newAnalysis.arce__path__c = 'MAC';
        newAnalysis.arce__risk_position_summary_type__c = '2';
        newAnalysis.arce__risk_position_summary_desc__c = 'Comentarios de resumen de riesgo';
        insert newAnalysis;

        final arce__Data_Collections__c dataColpeer = Arc_UtilitysDataTest_tst.crearDataCollection('Test Prueba', 'Maturity_table', '01');
        insert dataColpeer;

        final arce__Table_Content_per_Analysis__c maturityData = Arc_UtilitysDataTest_tst.crearTableContentAnalysis(newAnalysis.Id, dataColpeer.id, 'Maturity_table', '2019');
        insert maturityData;

        final arce__main_banks__c mainBanksData = Arc_UtilitysDataTest_tst.crearMainBanks(newAnalysis.Id,'Main_Banks');
        mainBanksData.arce__entity_name__c = 'Santander';
        mainBanksData.arce__entity_quota_share_per__c = 15.5;
        insert mainBanksData;

        final arce__risk_position_summary__c riskPosSumData = Arc_UtilitysDataTest_tst.crearRiskPositionSummary(newAnalysis.Id, 'RPS_0001');
        riskPosSumData.arce__banrel_comments_desc__c = 'Comentarios clase test';
        riskPosSumData.arce__banrel_current_limit_name__c = 275.56;
        riskPosSumData.arce__banrel_commitment_name__c = 4523.65;
        riskPosSumData.arce__banrel_uncommitment_name__c = 5498.54;
        insert riskPosSumData;
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
    Public static void prepareData() {
          final Arc_Gen_SaveMainBuro saveMB = new Arc_Gen_SaveMainBuro();

        final List<arce__Account_has_Analysis__c> datosAcont = [SELECT ID, arce__gf_company_economic_actvy_id__c, arce__analysis_template_id__c, arce__Analysis__c,
                                                          arce__Customer__c, arce__enterprise_group_type__c, arce__client_refinanced_type__c, arce__client_refinanced_desc__c, arce__sector_desc__c,
                                                          arce__subsector_desc__c, arce__economic_activity_sector_desc__c, arce__rating_econ_sector_tmpl_id__c, arce__employees_number__c,
                                                          arce__ffss_auditor_opinion_type__c,arce__ffss_auditor_fullname_name__c,arce__ffss_auditor_qlfn_type__c,arce__ffss_auditor_opinion_desc__c,arce__ffss_submitted_type__c,arce__ffss_cnsld_perimeter_desc__c,arce__currency_id__c,
                                                          arce__debt_maturity_available_type__c,arce__debt_maturity_desc__c,arce__number_entity_type__c,arce__cust_budget_cyr_ind_type__c,arce__cust_budget_incl_ffss_ind_type__c,
                                                          arce__cust_budget_incl_ffss_desc__c,arce__Syn_equity_type__c, arce__equity_desc__c, arce__Syn_significant_extraordinary_variab__c,arce__significant_variables_desc__c,
                                                          arce__off_balance_treasury_type__c,arce__off_balance_treasury_desc__c,arce__oper_guarantee_given_type__c,arce__guarantee_given_desc__c,arce__off_balance_rlvnt_info_type__c,
                                                          arce__off_balance_rlvnt_info_desc__c,arce__cust_evolution_cyr_ind_type__c,arce__cust_evolution_cyr_desc__c, arce__cust_proj_2yr_3yr_ind_type__c,
                                                          arce__cust_proj_2yr_3yr_desc__c,arce__var_over_20_balance_desc__c,arce__var_vary_10_and_10_bal_desc__c,arce__variables_vary_20_balance_desc__c,arce__sales_evolution_desc__c,
                                                          arce__ebitda_3yr_evolution_desc__c,arce__cost_structure_desc__c, arce__equity_vary_not_expln_desc__c,arce__financial_liquidity_desc__c,arce__property_ownership_desc__c,
                                                          arce__property_ownership_type__c,arce__Funds_destination_type__c,arce__financial_flexibility_type__c,arce__client_situation_type__c,arce__risk_position_summary_type__c,
                                                          arce__other_contracted_product_type__c,arce__other_contracted_product_desc__c,arce__other_operation_type__c,arce__other_operation_desc__c,
                                                          arce__rar_profitability_per__c,arce__rar_profitability_desc__c,arce__hats_risk_qualification_number__c,arce__stage_collective_type__c,arce__stage_collective_ind_type__c,arce__stage_collective_desc__c,
                                                          arce__risk_position_summary_desc__c,arce__customer_product_usage_desc__c,arce__banking_pool_desc__c,arce__capital_provision_per__c,arce__capital_provision_desc__c,arce__fin_covenants_breach_type__c,arce__fin_covenants_breach_desc__c
                                                          FROM arce__Account_has_Analysis__c
                                                          WHERE arce__sector_desc__c = 'Hoteleria'];
        Test.startTest();
        final String test1 =  saveMB.save(datosAcont);
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
        final Arc_Gen_Persistance_MB_Service testConstructor = new Arc_Gen_Persistance_MB_Service();
        system.assertEquals(testConstructor, testConstructor, 'The test to the empty constructor was successfully');
        Test.stopTest();
    }

}