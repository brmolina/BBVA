/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_SaveLeverage_ctrl
* @Author   mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 28/02/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that get data and create json to persist.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-02-28 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-06-30 joseluis.garcia4.contractor@bbva.com
*             Modify tests to comply with the deletion of Arc_Gen_Save_Policies_ctrl
* |2020-08-11 javier.soto.carrascosa@bbva.com
*             Update sector field
* |2020-08-25 joseluis.garcia4.contractor@bbva.com
*             Add needed field arce__ll_test_scope_ind_type__c to query in method testPoliciesSaveDynamicForm().
* |2020-09-18 joseluis.garcia4.contractor@bbva.com
*             Fix leveraged test for groups.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-11-30 juanignacio.hita.contractor@bbva.com
*             Add test methods for persistence services
* |2021-01-26 joseluis.garcia4.contractor@bbva.com
*             Add field arce__limit_exposure_ext_ind_type__c to queries of test methods.
* |2021-02-18 joseluis.garcia4.contractor@bbva.com
*             Fix tests for action persistence service.
* |2021-03-05 juanignacio.hita.contractor@bbva.com
*             Changes in testPoliciesSaveKO method
* |2021-03-31 juanignacio.hita.contractor@bbva.com
*             Add new fields in testSaveChangeNoCurrKO, testSaveChangeCurrKO and testPoliciesSaveKO methods
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:NcssMethodCount, sf:ExcessiveMethodLength, PMD.ExcessivePublicCount, sf:TooManyMethods')
@isTest
public without sharing class Arc_Gen_Save_Policies_ctrl_test {
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID = 'G000001';
    /**
    * @Description: String with external id of test subsidiary
    */
    static final string SUBSIDIARY_ID = 'C000001';
    /**
    * @Description: String with external id of test subsidiary
    */
    static final string SUBSIDIARY_ID2 = 'C000003';
    /**
    * @Description: EUR currency
    */
    static final string EUR = 'EUR';
    /**
    * --------------------------------------------------------------------------------------
    * @Description Setup method for Arc_Gen_Validate_Customer_Controller_tst
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @param void
    * @return void
    * @example Arc_Gen_Validate_Customer_Controller_tst.setup()
    * --------------------------------------------------------------------------------------
    **/
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID,SUBSIDIARY_ID2});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(SUBSIDIARY_ID);

        final arce__Analysis__c arceVar = Arc_UtilitysDataTest_tst.crearArceAnalysis('arceAnalysis', null, groupAccount.accId);
        arceVar.arce__analysis_customer_relation_type__c = '01';
        arceVar.arce__Temporal_status__c = false;
        insert arceVar;

        final arce__Sector__c sector = new arce__Sector__c();
        sector.arce__developer_name__c = 's-01';
        sector.arce__analysis_template_id__c = '1';
        sector.arce__unique_id__c = String.valueOf((Math.random()*1000).round()); 
        insert sector;

        arce__rating__c rating = new arce__rating__c();
        rating.arce__rating_id__c = '8932748289234';
        insert rating;

        arce__Financial_Statements__c financial = new arce__Financial_Statements__c();
        financial.arce__ffss_submitted_type__c = '1';
        financial.arce__rating_id__c = rating.Id;
        insert financial;


        final arce__Account_has_Analysis__c accHasAnGp = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, arceVar.Id, groupAccount.accId, '1');
        accHasAnGp.arce__group_asset_header_type__c = '1';
        accHasAnGp.arce__ffss_for_rating_id__c = financial.Id;
        accHasAnGp.arce__currency_id__c = EUR;
        accHasAnGp.arce__risk_policy_type__c = '1';
        insert accHasAnGp;
        final arce__Account_has_Analysis__c accHasAnCl = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, arceVar.Id, childAccount.accId, '1');
        accHasAnCl.arce__group_asset_header_type__c = '2';
        accHasAnCl.arce__ll_before_adj_clsfn_type__c = 'NI';
        accHasAnCl.arce__fin_covenants_breach_type__c = '1';
        accHasAnCl.arce__ll_test_scope_ind_type__c = '2';
        accHasAnCl.arce__ffss_for_rating_id__c = financial.Id;
        accHasAnCl.arce__InReview__c = true;
        accHasAnCl.arce__currency_id__c = '';
        accHasAnCl.arce__risk_policy_type__c = '1';
        insert accHasAnCl;

        final dyfr__Template__c temp = Arc_UtilitysDataTest_tst.crearTemplate('s-01-500');
        insert temp;

        final dyfr__Tab__c tab = Arc_UtilitysDataTest_tst.crearTab('Policies', temp.Id);
        insert tab;

        final dyfr__Field_Config__c fieldConf = Arc_UtilitysDataTest_tst.crearfieldConfigData(null, tab.Id, 'arce__gf_total_revenues_ytd_amount__c');
        fieldConf.dyfr__Type__c = 'number';
        fieldConf.dyfr__Read_only__c = false;
        insert fieldConf;
        final dyfr__Field_Config__c fieldConf2 = Arc_UtilitysDataTest_tst.crearfieldConfigData(System.Label.Arc_Gen_Risk_request, tab.Id, 'arce__ll_before_adj_clsfn_type__c');
        fieldConf2.dyfr__Type__c = 'LIST';
        fieldConf2.dyfr__Read_only__c = false;
        insert fieldConf2;
        final dyfr__Field_Config__c fieldConf3 = Arc_UtilitysDataTest_tst.crearfieldConfigData(System.Label.Arc_Gen_Risk_request, tab.Id, 'arce__fin_covenants_breach_type__c');
        fieldConf3.dyfr__Type__c = 'radio group';
        fieldConf3.dyfr__Read_only__c = false;
        insert fieldConf3;
        final dyfr__Field_Config__c fieldConf4 = Arc_UtilitysDataTest_tst.crearfieldConfigData(System.Label.Arc_Gen_Risk_request, tab.Id, 'arce__gf_covenant_desc__c');
        fieldConf4.dyfr__Type__c = 'text';
        fieldConf4.dyfr__Read_only__c = false;
        insert fieldConf4;

        final dyfr__Field_Config__c fieldConf5 = Arc_UtilitysDataTest_tst.crearfieldConfigData(null, tab.Id, 'arce__current_proposed_amount__c');
        fieldConf5.dyfr__Type__c = 'number';
        fieldConf5.dyfr__Read_only__c = true;
        insert fieldConf5;
        final dyfr__Field_Config__c fieldConf6 = Arc_UtilitysDataTest_tst.crearfieldConfigData(null, tab.Id, 'arce__ll_after_adj_clsfn_type__c');
        fieldConf6.dyfr__Type__c = 'LIST';
        fieldConf6.dyfr__Read_only__c = true;
        insert fieldConf6;
        final dyfr__Field_Config__c fieldConf7 = Arc_UtilitysDataTest_tst.crearfieldConfigData(null, tab.Id, 'arce__ll_previous_anlys_ind_type__c');
        fieldConf7.dyfr__Type__c = 'radio group';
        fieldConf7.dyfr__Read_only__c = true;
        insert fieldConf7;
        final dyfr__Field_Config__c fieldConf8 = Arc_UtilitysDataTest_tst.crearfieldConfigData(null, tab.Id, 'arce__ll_previous_anlys_clsfn_type__c');
        fieldConf8.dyfr__Type__c = 'text';
        fieldConf8.dyfr__Read_only__c = true;
        insert fieldConf8;

        final dyfr__Field_Config__c fieldConf9 = Arc_UtilitysDataTest_tst.crearfieldConfigData(null, tab.Id, 'arce__ffss_for_rating_id__r.arce__ffss_submitted_type__c');
        fieldConf9.dyfr__Type__c = 'radio group';
        fieldConf9.dyfr__Read_only__c = true;
        insert fieldConf9;
        final dyfr__Field_Config__c fieldConf10 = Arc_UtilitysDataTest_tst.crearfieldConfigData(null, tab.Id, 'arce__ffss_for_rating_id__r.arce__rating_final__c');
        fieldConf10.dyfr__Type__c = 'text';
        fieldConf10.dyfr__Read_only__c = true;
        insert fieldConf10;

        final dyfr__Field_Config__c fieldConf11 = Arc_UtilitysDataTest_tst.crearfieldConfigData(null, tab.Id, 'arce__Analysis__r.arce__Temporal_status__c');
        fieldConf11.dyfr__Type__c = 'checkbox';
        fieldConf11.dyfr__Read_only__c = true;
        insert fieldConf11;

        final dyfr__Field_Config__c fieldConf12 = Arc_UtilitysDataTest_tst.crearfieldConfigData(null, tab.Id, 'arce__Customer__r.bbva_total_debt_amount__c');
        fieldConf12.dyfr__Type__c = 'number';
        fieldConf12.dyfr__Read_only__c = true;
        insert fieldConf12;

        final dyfr__Field_Config__c fieldConf13 = Arc_UtilitysDataTest_tst.crearfieldConfigData(null, tab.Id, 'arce__InReview__c');
        fieldConf13.dyfr__Type__c = 'checkbox';
        fieldConf13.dyfr__Read_only__c = false;
        insert fieldConf13;

        final arce__limits_typology__c projectFinance = Arc_UtilitysDataTest_tst.crearLimitTypology('Project Finance', null, 'TP_0013');
        projectFinance.arce__risk_typology_level_type__c = '1';
        projectFinance.arce__Typology_Order__c = 1;
        insert projectFinance;

        final arce__limits_typology__c limTypoTP0005 = Arc_UtilitysDataTest_tst.crearLimitTypology('TOTAL Financial Risk ST & Commercial Risk', null, 'TP_0005');
        insert limTypoTP0005;
        final arce__limits_typology__c limTypoTP0010 = Arc_UtilitysDataTest_tst.crearLimitTypology('Commercial Risk', limTypoTP0005.Id, 'TP_0010');
        insert limTypoTP0010;
        final arce__limits_typology__c limTypoTP0012 = Arc_UtilitysDataTest_tst.crearLimitTypology('Financial Risk ST', limTypoTP0005.Id, 'TP_0012');
        insert limTypoTP0012;
        final arce__limits_typology__c limTypoTP0003 = Arc_UtilitysDataTest_tst.crearLimitTypology('TOTAL CORPORATE RISK', null, 'TP_0003');
        insert limTypoTP0003;
        final arce__limits_typology__c limTypoTP0007 = Arc_UtilitysDataTest_tst.crearLimitTypology('TOTAL Financial Risk LT', null, 'TP_0007');
        insert limTypoTP0007;
        final arce__limits_typology__c limTypoTP0011 = Arc_UtilitysDataTest_tst.crearLimitTypology('Financial Risk LT - Unsecured - No real guarantee', limTypoTP0007.Id, 'TP_0011');
        insert limTypoTP0011;
        final arce__limits_typology__c limTypoTP0014 = Arc_UtilitysDataTest_tst.crearLimitTypology('Financial Risk LT - Secured - Real guarantee', limTypoTP0007.Id, 'TP_0014');
        insert limTypoTP0014;

        final Arc_UtilitysDataTest_tst createExposures = new Arc_UtilitysDataTest_tst();
        final arce__limits_exposures__c exposure1 = createExposures.crearExposures(limTypoTP0005.Id, accHasAnCl.Id, 0);
        insert exposure1;
        final arce__limits_exposures__c exposure2 = createExposures.crearExposures(limTypoTP0010.Id, accHasAnCl.Id, 0);
        insert exposure2;
        final arce__limits_exposures__c exposure3 = createExposures.crearExposures(limTypoTP0012.Id, accHasAnCl.Id, 0);
        insert exposure3;
        final arce__limits_exposures__c exposure5 = createExposures.crearExposures(limTypoTP0003.Id, accHasAnCl.Id, 0);
        insert exposure5;
        final arce__limits_exposures__c exposure6 = createExposures.crearExposures(limTypoTP0007.Id, accHasAnCl.Id, 0);
        insert exposure6;
        final arce__limits_exposures__c exposure7 = createExposures.crearExposures(limTypoTP0011.Id, accHasAnCl.Id, 0);
        insert exposure7;
        final arce__limits_exposures__c exposure8 = createExposures.crearExposures(projectFinance.Id, accHasAnCl.Id, 0);
        insert exposure8;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testPoliciesSaveLvgdKO() {
        arce__Account_has_Analysis__c aha = [SELECT arce__currency_id__c, arce__Analysis__r.arce__analysis_risk_sanction_date__c, arce__gf_anlys_risk_prps_expiry_date__c, arce__risk_policy_type__c,
                                    arce__risk_request_desc__c, arce__magnitude_unit_type__c, arce__debt_comt_not_disb_local_amount__c, arce__ll_test_scope_ind_type__c, arce__ll_adj_debt_auditor_amount__c,
                                    arce__ll_adj_ebitda_auditor_amount__c, arce__ll_adj_deb_excl_amount__c, arce__ll_adj_ebitda_excl_amount__c, arce__ll_other_adj_debt_amount__c,
                                    arce__ll_other_adj_ebitda_amount__c, arce__limit_exposure_ext_ind_type__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2' LIMIT 1];

        // Set initial info in DB.
        aha.arce__ll_adj_debt_auditor_amount__c = 1;
        aha.arce__ll_before_adj_ind_type__c = aha.arce__ll_after_adj_ind_type__c = '1';
        aha.arce__currency_id__c = EUR;
        update aha;

        // Update local "dynamic form" object.
        aha.arce__ll_adj_debt_auditor_amount__c = 2;

        Test.startTest();
        Arc_Gen_SavePolicies saveObj = new Arc_Gen_SavePolicies();
        saveObj.save(new List<SObject> { aha });
        Test.stopTest();

        // Assert that arce__ll_before_adj_ind_type__c is cleared.
        final arce__Account_has_Analysis__c newAha = [SELECT arce__ll_before_adj_ind_type__c, arce__ll_after_adj_ind_type__c FROM arce__Account_has_Analysis__c WHERE Id = :aha.Id];
        System.assert(newAha.arce__ll_before_adj_ind_type__c == null && newAha.arce__ll_after_adj_ind_type__c == null, 'Leveraged test results should be cleared.');
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testSaveChangeNoCurrKO() {
        try {
            final arce__Account_has_Analysis__c aha = [SELECT arce__currency_id__c, arce__Account_has_Analysis__c.arce__Analysis__r.arce__analysis_risk_sanction_date__c, arce__gf_anlys_risk_prps_expiry_date__c, arce__risk_policy_type__c,
                                        arce__magnitude_unit_type__c, arce__debt_comt_not_disb_local_amount__c, arce__ll_test_scope_ind_type__c, arce__ll_adj_debt_auditor_amount__c, arce__ll_adj_ebitda_auditor_amount__c,
                                        arce__ll_adj_deb_excl_amount__c, arce__ll_adj_ebitda_excl_amount__c, arce__ll_other_adj_debt_amount__c, arce__ll_other_adj_ebitda_amount__c, arce__limit_exposure_ext_ind_type__c,
                                        arce__risk_request_desc__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2' LIMIT 1];
            Test.startTest();
            final Arc_Gen_SavePolicies saveObj = new Arc_Gen_SavePolicies();
            saveObj.save(new List<SObject> { aha });
            Test.stopTest();
        } catch (Exception e) {
            System.assertEquals('A currency must be specified', e.getMessage(), 'Error when the not selected currency');
        }
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testSaveChangeCurrKO() {
        try {
            final arce__Account_has_Analysis__c aha = [SELECT arce__currency_id__c, arce__Account_has_Analysis__c.arce__Analysis__r.arce__analysis_risk_sanction_date__c, arce__gf_anlys_risk_prps_expiry_date__c, arce__risk_policy_type__c,
                                        arce__magnitude_unit_type__c, arce__debt_comt_not_disb_local_amount__c, arce__ll_test_scope_ind_type__c, arce__ll_adj_debt_auditor_amount__c, arce__ll_adj_ebitda_auditor_amount__c,
                                        arce__ll_adj_deb_excl_amount__c, arce__ll_adj_ebitda_excl_amount__c, arce__ll_other_adj_debt_amount__c, arce__ll_other_adj_ebitda_amount__c, arce__limit_exposure_ext_ind_type__c,
                                        arce__risk_request_desc__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1' LIMIT 1];

            // Update currency field
            aha.arce__currency_id__c = 'USD';
            Test.startTest();
            final Arc_Gen_SavePolicies saveObj = new Arc_Gen_SavePolicies();
            saveObj.save(new List<SObject> { aha });
            Test.stopTest();
        } catch (Exception e) {
            System.assertEquals('Saving failed, the currency selected by the user (USD) is different from the one retrieved from the local service (EUR)', e.getMessage(), 'Error when the selected currency is different from the currency retrieved from the service');
        }
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testPoliciesSaveKO() {
        try {
            final arce__Account_has_Analysis__c aha = [SELECT arce__currency_id__c, arce__magnitude_unit_type__c, arce__debt_comt_not_disb_local_amount__c, arce__ll_test_scope_ind_type__c, arce__ll_adj_debt_auditor_amount__c,
                                                        arce__ll_adj_ebitda_auditor_amount__c, arce__ll_adj_deb_excl_amount__c, arce__ll_adj_ebitda_excl_amount__c,arce__Analysis__r.arce__analysis_risk_sanction_date__c,
                                                        arce__gf_anlys_risk_prps_expiry_date__c,arce__ll_other_adj_debt_amount__c, arce__ll_other_adj_ebitda_amount__c,arce__risk_policy_type__c,
                                                        arce__risk_request_desc__c,arce__limit_exposure_ext_ind_type__c, arce__Account_has_Analysis__c.arce__Analysis__c
                                                        FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2' LIMIT 1];
            aha.arce__currency_id__c = EUR;
            Test.startTest();
            final Arc_Gen_SavePolicies saveObj = new Arc_Gen_SavePolicies();
            saveObj.save(new List<SObject> { aha });
            Test.stopTest();
        } catch (Exception e) {
            System.assertEquals(System.Label.Arc_Gen_ServicePersistenceError, e.getMessage(), 'Error persistence test when save policies');
        }
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testPoliciesSaveOK() {
        final arce__Account_has_Analysis__c aha = [SELECT arce__currency_id__c, arce__Analysis__r.arce__analysis_risk_sanction_date__c, arce__gf_anlys_risk_prps_expiry_date__c, arce__risk_policy_type__c,
                        arce__risk_request_desc__c, arce__magnitude_unit_type__c, arce__debt_comt_not_disb_local_amount__c, arce__ll_test_scope_ind_type__c, arce__ll_adj_debt_auditor_amount__c,
                        arce__ll_adj_ebitda_auditor_amount__c, arce__ll_adj_deb_excl_amount__c, arce__ll_adj_ebitda_excl_amount__c, arce__ll_other_adj_debt_amount__c,
                        arce__ll_other_adj_ebitda_amount__c, arce__limit_exposure_ext_ind_type__c FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2' LIMIT 1];
        aha.arce__currency_id__c = EUR;
        Test.startTest();
        final Arc_Gen_SavePolicies saveObj = new Arc_Gen_SavePolicies();
        saveObj.save(new List<SObject> { aha });
        final arce__Account_has_Analysis__c newAha = [SELECT arce__currency_id__c FROM arce__Account_has_Analysis__c WHERE Id = :aha.Id];
        System.assert(newAha != null, 'Assert policiesSaveOK');
        Test.stopTest();
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testPoliciesSaveLvgdOK() {
        final Map<String, arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID,SUBSIDIARY_ID2});
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(SUBSIDIARY_ID);
        List<sObject> listObject = [SELECT id,arce__gf_total_revenues_ytd_amount__c,arce__ll_before_adj_clsfn_type__c,arce__fin_covenants_breach_type__c,arce__gf_covenant_desc__c,
                                        arce__current_proposed_amount__c,arce__ll_after_adj_clsfn_type__c,arce__ll_previous_anlys_ind_type__c, arce__ll_previous_anlys_clsfn_type__c,
                                        arce__Analysis__r.arce__Temporal_status__c
                                        FROM arce__Account_has_Analysis__c WHERE arce__Customer__c =: childAccount.accId];
        Test.startTest();
        final Arc_Gen_Persistence_Leverage_Service.PoliciesWrapper json = Arc_Gen_Persistence_Leverage_Service.callPersistence(listObject);
        system.assert(json.success, 'The save was successfull');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testGroupLeveraga() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID,SUBSIDIARY_ID2});
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(GROUP_ID);
        List<sObject> listObject = [SELECT id,arce__gf_total_revenues_ytd_amount__c,arce__ll_before_adj_clsfn_type__c,arce__fin_covenants_breach_type__c,arce__gf_covenant_desc__c, arce__current_proposed_amount__c,arce__ll_after_adj_clsfn_type__c,arce__ll_previous_anlys_ind_type__c, arce__ll_previous_anlys_clsfn_type__c FROM arce__Account_has_Analysis__c WHERE arce__Customer__c =: childAccount.accId];
        Test.startTest();
        final Arc_Gen_Persistence_Leverage_Service.PoliciesWrapper json = Arc_Gen_Persistence_Leverage_Service.callPersistence(listObject);
        system.assert(json.success, 'The save was successfull');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testJsonInput() {
        Map<String,String> mapInfo = new Map<String,String>();
        mapinfo.put('arce__ffss_for_rating_id__r.arce__ffss_submitted_type__c', 'levTestType');
        mapinfo.put('arce__entity_covenants_type__c', 'covenantType');
        mapinfo.put('arce__ll_before_adj_clsfn_type__c', 'beforeAdjClassType');
        mapinfo.put('arce__ll_after_adj_clsfn_type__c', 'afterAdjClassType');
        mapinfo.put('arce__ll_previous_anlys_clsfn_type__c', 'prevAnalysClassType');
        mapinfo.put('arce__Analysis__r.arce__Temporal_status__c', 'tempStatus');
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID,SUBSIDIARY_ID2});
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(SUBSIDIARY_ID);
        List<sObject> listObject = [SELECT id,arce__gf_total_revenues_ytd_amount__c,arce__ll_before_adj_clsfn_type__c,arce__fin_covenants_breach_type__c,arce__gf_covenant_desc__c,
                                            arce__current_proposed_amount__c,arce__ll_after_adj_clsfn_type__c,arce__ll_previous_anlys_ind_type__c, arce__ll_previous_anlys_clsfn_type__c,
                                            arce__Analysis__r.arce__Temporal_status__c
                                    FROM arce__Account_has_Analysis__c WHERE arce__Customer__c =: childAccount.accId];

        Test.startTest();
        final String jsonInput = Arc_Gen_ServicePersitence_Utils.getJsonInput(mapinfo, listObject);
        system.assertEquals(true, jsonInput.contains('beforeAdjClassType'), 'The save was successfull');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testConfigInfoEmpty() {
        Map<String,String> info =  new Map<String,String>();
        Test.startTest();
        try {
            info = Arc_Gen_ServicePersitence_Locator.retConfigurationInfo('empty');
        } catch (Exception e) {
            system.assertEquals(true, e.getMessage().contains(Label.Arc_Gen_MetadataListEmpty), 'There was an error');
            system.assertEquals(true, info.isEmpty(), 'There was an error');
        }
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testEmptyCons() {
        Arc_Gen_ServicePersitence_Locator locator = new Arc_Gen_ServicePersitence_Locator();
        system.assertEquals(locator, locator, 'The test to the empty constructor was successfull');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testEmptyCons2() {
        Arc_Gen_Persistence_Leverage_Helper helper = new Arc_Gen_Persistence_Leverage_Helper();
        system.assertEquals(helper, helper, 'The test to the empty constructor was successfull');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testEmptyCons3() {
        Arc_Gen_FieldConfig_Data data = new Arc_Gen_FieldConfig_Data();
        system.assertEquals(data, data, 'The test to the empty constructor was successfull');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testEmptyCons4() {
        Arc_Gen_Persistence_Leverage_Service service = new Arc_Gen_Persistence_Leverage_Service();
        system.assertEquals(service, service, 'The test to the empty constructor was successfull');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testEmptyCons5() {
        Arc_Gen_ServicePersitence_Utils utils = new Arc_Gen_ServicePersitence_Utils();
        system.assertEquals(utils, utils, 'The test to the empty constructor was successfull');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testRelData() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID,SUBSIDIARY_ID2});
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(SUBSIDIARY_ID);
        final List<arce__Account_has_Analysis__c> accHasData = [SELECT id, arce__Analysis__r.arce__Temporal_status__c,arce__Customer__r.bbva_total_debt_amount__c
                                                                FROM arce__Account_has_Analysis__c WHERE arce__Customer__c =: childAccount.accId];
        final List<dyfr__Field_Config__c> fieldCon = [SELECT Id, dyfr__Type__c, dyfr__Read_only__c, dyfr__Map_field__c FROM dyfr__Field_Config__c WHERE dyfr__Map_field__c ='arce__Analysis__r.arce__Temporal_status__c' OR dyfr__Map_field__c = 'arce__Customer__r.bbva_total_debt_amount__c' ORDER BY dyfr__Map_field__c];
        Map<String,String> confInfMap = new Map<String,String>();
        confInfMap.put('arce__Analysis__r.arce__Temporal_status__c', 'temStat');
        confInfMap.put('arce__Customer__r.bbva_total_debt_amount__c', 'bbvaTot');
        Map<String,dyfr__Field_Config__c> mapFieldInfo = new Map<String,dyfr__Field_Config__c>();
        mapFieldInfo.put('arce__Analysis__r.arce__Temporal_status__c', fieldCon[0]);
        mapFieldInfo.put('arce__Customer__r.bbva_total_debt_amount__c', fieldCon[1]);

        Test.startTest();
        String json = Arc_Gen_ServicePersitence_Utils.buildRelatedJson('arce__Analysis__r.arce__Temporal_status__c', accHasData, confInfMap, mapFieldInfo);
        json = Arc_Gen_ServicePersitence_Utils.buildRelatedJson('arce__Customer__r.bbva_total_debt_amount__c', accHasData, confInfMap, mapFieldInfo);
        system.assertEquals(true,json.contains('bbvaTot'), 'Test successfull');
        Test.stopTest();
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test Method
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testCheckbox() {
        Arc_Gen_ServicePersitence_Utils.PersistenceUtils wrapperInfo = new Arc_Gen_ServicePersitence_Utils.PersistenceUtils();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID,SUBSIDIARY_ID2});
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(SUBSIDIARY_ID);
        final List<arce__Account_has_Analysis__c> accHasData = [SELECT id, arce__InReview__c FROM arce__Account_has_Analysis__c WHERE arce__Customer__c =: childAccount.accId];
        final List<dyfr__Field_Config__c> fieldCon = [SELECT Id, dyfr__Type__c, dyfr__Read_only__c, dyfr__Map_field__c FROM dyfr__Field_Config__c WHERE dyfr__Map_field__c ='arce__InReview__c'];
        wrapperInfo.dynamicFormData = accHasData;
        Map<String,String> confInfMap = new Map<String,String>();
        confInfMap.put('arce__InReview__c', 'arceReview');
        Map<String,dyfr__Field_Config__c> mapFieldInfo = new Map<String,dyfr__Field_Config__c>();
        mapFieldInfo.put('arce__InReview__c', fieldCon[0]);

        Test.startTest();
        String json = Arc_Gen_ServicePersitence_Utils.buildJson(mapFieldInfo,wrapperInfo,confInfMap,'arce__InReview__c');
        fieldCon[0].dyfr__Read_only__c = true;
        update fieldCon;
        wrapperInfo.readOnlyData = accHasData;
        json = Arc_Gen_ServicePersitence_Utils.buildJson(mapFieldInfo,wrapperInfo,confInfMap,'arce__InReview__c');
        system.assertEquals(true,json.contains('arceReview'), 'Test successfull');
        Test.stopTest();
    }
}