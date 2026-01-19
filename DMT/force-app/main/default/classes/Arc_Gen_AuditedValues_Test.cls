/*------------------------------------------------------------------
*Author:        israel.rodriguez.ramos.contractor@bbva.com
*Description:   Test class for Arc_Gen_AuditedValues
*_______________________________________________________________________________________
*Versión    Date           	Author                                         Description
*1.0        01/06/2021      israel.rodriguez.ramos.contractor@bbva.com     Created.
-----------------------------------------------------------------------------------------*/
@SuppressWarnings('sf:TooManyMethods,sf:UnitTestContainsTooManyAsserts')
@isTest
public class Arc_Gen_AuditedValues_Test {
    /**
    * @Method:      method that creates the data to use in the test.
    * @Description: testing method.
    */
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();

        final User userTest = Arc_UtilitysDataTest_tst.crearUsuario('UserTest',System.Label.Cls_arce_ProfileSystemAdministrator,'');
        userTest.ID_User__C = String.valueOf((Math.random()*100000));
        INSERT userTest;
        final Map<String, arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001','G000002','C000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');

        final arce__Analysis__c newAnalysis = new arce__Analysis__c();
        newAnalysis.Name = 'Analysis';
        newAnalysis.arce__bbva_committees_type__c = '1';
        newAnalysis.arce__anlys_wkfl_edit_br_level_type__c = '1';
        newAnalysis.OwnerId = userTest.Id;
        newAnalysis.arce__Group__c = groupAccount.accId;
        newAnalysis.arce__bbva_committees_type__c = '1';
        INSERT newAnalysis;

        final arce__Account_has_Analysis__c aha = new arce__Account_has_Analysis__c();
        aha.arce__Analysis__c = newAnalysis.Id;
        aha.arce__Stage__c = '3';
        aha.arce__InReview__c = true;
        aha.arce__Customer__c = groupAccount.accId;
        aha.arce__group_asset_header_type__c = arce.Arc_Gen_Constants.GROUP_ASSET_HEADER_TYPE_HEADER;
        aha.arce__long_rating_value_type__c = 'BBB-2';
        aha.arce__currency_id__c = 'EUR';
        aha.arce__current_formalized_amount__c = 0;
        aha.arce__outstanding_amount__c = 6000000;
        aha.arce__current_proposed_amount__c = 0;
        aha.arce__magnitude_unit_type__c = '1';
        aha.arce__last_approved_amount__c = 6000000;
        aha.arce__ll_after_adj_ind_type__c = '1';
        aha.arce__ll_before_adj_ind_type__c = '1';
        aha.arce__ll_after_adj_clsfn_type__c = 'FS';
        aha.arce__ll_before_adj_clsfn_type__c = 'FS';
        aha.arce__ll_test_manl_excl_rsn_type__c = 'C';
        aha.arce__risk_policy_type__c = '3';
        aha.arce__smes_eur_comuty_defn_type__c = '1';
        aha.arce__total_rating_score_number__c = 3;
        INSERT aha;

        final arce__limits_typology__c ll1 = new arce__limits_typology__c();
        ll1.arce__risk_typology_level_id__c = 'TP_0003';
        ll1.arce__risk_typology_level_type__c = '1';
        ll1.arce__Typology_Order__c = 1;
        INSERT ll1;

        final arce__limits_exposures__c ale = new arce__limits_exposures__c();
        ale.arce__account_has_analysis_id__c = aha.Id;
        ale.arce__curr_apprv_deleg_rm_amount__c = 2000;
        ale.arce__current_apprv_limit_term_id__c = '12';
        ale.arce__limits_typology_id__c = ll1.Id;
        INSERT ale;
    }

    /**
    * @Method:      test for method testInsertAuditedValues
    * @Description: testing method.
    */
    @isTest
    public static void testInsertAuditedValues() {
        final arce__Account_has_Analysis__c aha = [SELECT Id, Name, arce__long_rating_value_type__c, arce__currency_id__c, arce__current_formalized_amount__c, arce__outstanding_amount__c,
                                                    arce__current_proposed_amount__c, arce__magnitude_unit_type__c, arce__last_approved_amount__c, arce__ll_after_adj_ind_type__c,
                                                    arce__ll_before_adj_ind_type__c, arce__ll_after_adj_clsfn_type__c, arce__ll_before_adj_clsfn_type__c, arce__ll_test_manl_excl_rsn_type__c,
                                                    arce__risk_policy_type__c, arce__smes_eur_comuty_defn_type__c, arce__total_rating_score_number__c,
                                                    arce__ffss_for_rating_id__r.arce__rating_long_value_type__c, arce__ffss_for_rating_id__r.arce__pd_per__c
                                                    FROM arce__Account_has_Analysis__c LIMIT 1];
        final arce__Analysis__c analysis = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        Test.startTest();
        Arc_Gen_AuditedValues_service.checkAction(analysis.Id, 'propose');
        Arc_Gen_AuditedValues_service.checkAction(analysis.Id, 'sanction');
        Test.stopTest();
        final arce__Audited_Values__c avprop = [SELECT Id, Name, arce__stdln_long_rtg_val_psl_id__c, arce__stdln_long_rtg_val_sctn_id__c FROM arce__Audited_Values__c LIMIT 1];
        System.assertEquals(avprop.arce__stdln_long_rtg_val_psl_id__c, aha.arce__long_rating_value_type__c, 'Error, Audited Values has not been created/updated');
        System.assertEquals(avprop.arce__stdln_long_rtg_val_sctn_id__c, aha.arce__long_rating_value_type__c, 'Error, Audited Values has not been created/updated');
    }
}