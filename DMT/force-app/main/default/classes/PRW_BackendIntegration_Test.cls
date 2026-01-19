/**
* ────────────────────────────────────────────────────────────────────
* BackendIntegration_Test
* Test classes for Backend Integration Helper
* ────────────────────────────────────────────────────────────────────
* @author      Torcuato Tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2021-04-06
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
@isTest
public with sharing class PRW_BackendIntegration_Test {

  /**
  * @description field
  */
  final static String TEXTVAR = 'TEXT';

  /**
  * @description field
  */
  final static String AMOUNTVAR = 'AMOUNT';

  /**
  * @description field
  */
  final static String SUCCESSVAR = 'success';

  @testSetup
  static void setupTestData() {

    /* create catalog */
    final List<cuco__ps_catalog_family__c> families = cuco.Test_Utils.createPSCatalogFamilies(1);
    insert families;

    final List<cuco__ps_catalog_condition__c> conditions = cuco.Test_Utils.createPSCatalogConditons(5, families[0]);
    insert conditions;

    final List<cuco__ps_catalog_attribute__c> attributes = completeAttr();

    final List<cuco__ps_catalog_condition_attribute__c>  conditionAttr = completeCond(conditions, attributes);
    system.debug(conditionAttr);

    final cuco__ps_catalog_flat_rates_dp__c flatDp = new cuco__ps_catalog_flat_rates_dp__c();
    flatDp.cuco__gf_dp_item_classification_desc__c = 'Transferencias Internacionales';
    flatDp.cuco__gf_dynamic_pricing_item_id__c = 'dypri.inter.transfer.issued';
    flatDp.cuco__gf_pkg_fr_defn_avail_ind_type__c = true;
    insert flatDp;

    final List<cuco__ps_catalog_flat_rates_dp_attribute__c> listflat = new List<cuco__ps_catalog_flat_rates_dp_attribute__c>();
    final cuco__ps_catalog_flat_rates_dp_attribute__c flatDpAttr = new cuco__ps_catalog_flat_rates_dp_attribute__c();
    flatDpAttr.cuco__gf_psc_fr_dynamic_pricing_id__c = flatDp.Id;
    flatDpAttr.cuco__gf_psc_atribute_id__c = attributes[10].Id;
    flatDpAttr.cuco__gf_psc_dynamic_pricing_atrb_id__c = 'dypri.p.inter.transfer.issued';
    flatDpAttr.cuco__gf_psc_atrb_active_dp_ind_type__c = true;
    listflat.add(flatDpAttr);
    final cuco__ps_catalog_flat_rates_dp_attribute__c flatDpAttr2 = new cuco__ps_catalog_flat_rates_dp_attribute__c();
    flatDpAttr2.cuco__gf_psc_fr_dynamic_pricing_id__c = flatDp.Id;
    flatDpAttr2.cuco__gf_psc_atribute_id__c = attributes[11].Id;
    flatDpAttr2.cuco__gf_psc_dynamic_pricing_atrb_id__c = 'dypri.q.inter.transfer.issued';
    flatDpAttr2.cuco__gf_psc_atrb_active_dp_ind_type__c = true;
    listflat.add(flatDpAttr2);
    insert listflat;

    /* create conditions */
    final List<Account> accounts = cuco.Test_Utils.createAccounts(2);
    insert accounts;

    final List<cuco__profitability_sheet__c> profSheets = cuco.Test_Utils.createProfSheet(1, accounts[0]);
    insert profSheets;

    final List<cuco__profitability_sheet_participant__c> participants = cuco.Test_Utils.createProfSheetParticipant(1, profSheets[0].Id, new List<Id>{accounts[0].Id});
    insert participants;

    final cuco__ps_catalog_flat_rates_attribute__c frAtt = new cuco__ps_catalog_flat_rates_attribute__c();
    frAtt.cuco__gf_psc_atrb_active_fr_ind_type__c = true;
    frAtt.cuco__gf_psc_flat_attribute_id__c = 'comflat.account.unavailable.procedure';
    frAtt.cuco__gf_psc_attribute_id__c = attributes[12].Id;
    insert frAtt;
  }

  /*
  * Test
  */
  @isTest
  static void constructorTest() {
    Test.startTest();
      final PRW_BackendIntegration res = PRW_BackendIntegration.gtInstance();
      System.assertNotEquals(res, null, 'private constructor');
    Test.stopTest();
  }

  /*
  * Test
  */
  @isTest
  static void getProfSheetFullDetails1() {
    Test.startTest();
      final cuco.ProfitabilitySheet_Selector profSheetSelector = new cuco.ProfitabilitySheet_Selector(false);
      final Set<String> psNames = new Set<String>{'Prof sheet Test 0'};
      final List<cuco__profitability_sheet__c> profSheets = profSheetSelector.selectByName(psNames);
      final Map<String,Object> res = PRW_TabContainerCtrl.gtCuCoConditions(profSheets[0].Id, profSheets[0].cuco__gf_profitability_sheet_id__c);
      final Boolean resValue = (Boolean) res.get(SUCCESSVAR);
      System.assert(resValue, 'Error in PRW_TabContainerCtrl.gtCuCoConditions Expected map.success = true. got: ' + res.get(SUCCESSVAR) );
    Test.stopTest();
  }

  /*
  * Test
  */
  @isTest
  static void getConditionFlatWrapper() {
    Test.startTest();
      final cuco.ProfitabilitySheet_Selector profSheetSelector = new cuco.ProfitabilitySheet_Selector(false);
      final Set<String> psNames = new Set<String>{'Prof sheet Test 0'};
      final List<cuco__profitability_sheet__c> profSheets = profSheetSelector.selectByName(psNames);
      final Map<String,Object> res = PRW_TabContainerCtrl.gtCuCoConditions(profSheets[0].Id, profSheets[0].cuco__gf_profitability_sheet_id__c);
      final String resultado = Label.PRW_Response_Test;
      PRW_TabContainerCtrl.gtCucoNamesAndAmount(resultado);
      final Boolean resValue = (Boolean) res.get(SUCCESSVAR);
      System.assert(resValue, 'Error in PRW_TabContainerCtrl.gtCuCoConditions Expected map.success = true. got: ' + res.get(SUCCESSVAR) );
    Test.stopTest();
  }

  /*
  * Test
  */
  private static List<cuco__ps_catalog_attribute__c> completeAttr() {
    final List<cuco__ps_catalog_attribute__c> attributes = cuco.Test_Utils.createPSCatalogAttributes(11);
    attributes[0].cuco__gf_psc_bknd_svc_format_type__c =  TEXTVAR;
    attributes[1].cuco__gf_psc_bknd_svc_format_type__c =  TEXTVAR;
    attributes[2].cuco__gf_psc_bknd_svc_format_type__c =  AMOUNTVAR;
    attributes[3].cuco__gf_psc_bknd_svc_format_type__c = 'RATE';
    attributes[4].cuco__gf_psc_bknd_svc_format_type__c =  AMOUNTVAR;
    attributes[5].cuco__gf_psc_bknd_svc_format_type__c =  AMOUNTVAR;
    attributes[6].cuco__gf_psc_bknd_svc_format_type__c = 'TERM';
    attributes[7].cuco__gf_psc_bknd_svc_format_type__c = 'RATE';
    attributes[8].cuco__gf_psc_bknd_svc_format_type__c =  AMOUNTVAR;
    attributes[9].cuco__gf_psc_bknd_svc_format_type__c =  AMOUNTVAR;
    attributes[10].cuco__gf_psc_bknd_svc_format_type__c =  TEXTVAR;
    attributes[10].cuco__gf_stored_prps_atrb_field_name__c = 'gf_pa_fr_dp_annual_prc_amount__c';
    attributes[11].cuco__gf_psc_bknd_svc_format_type__c =  TEXTVAR;
    attributes[11].cuco__gf_stored_prps_atrb_field_name__c = 'gf_pa_fr_dp_neg_anl_ope_amount__c';
    attributes[12].cuco__gf_psc_bknd_svc_format_type__c =  TEXTVAR;
    insert attributes;
    return attributes;
  }

  /*
  * Test
  */
  private static List<cuco__ps_catalog_condition_attribute__c> completeCond(List<cuco__ps_catalog_condition__c> conditions, List<cuco__ps_catalog_attribute__c> attributes) {
    final List<cuco__ps_catalog_condition_attribute__c>  conditionAttr = cuco.Test_Utils.createPSCatalogConditonAttributes(10, conditions[0], attributes);
     conditionAttr[0].cuco__gf_psc_condition_attribute_id__c = 'debit.sepa.postal.ind';
     conditionAttr[0].cuco__gf_psc_condition_id__c = conditions[0].Id;
     conditionAttr[1].cuco__gf_psc_condition_attribute_id__c = 'extended.package';
     conditionAttr[1].cuco__gf_psc_condition_id__c = conditions[0].Id;
     conditionAttr[2].cuco__gf_psc_condition_attribute_id__c = 'np.nat.transfer.EEE.ob.tf.amount';
     conditionAttr[2].cuco__gf_psc_condition_id__c = conditions[1].Id;
     conditionAttr[3].cuco__gf_psc_condition_attribute_id__c = 'np.nat.transfer.EEE.ob.tf.type';
     conditionAttr[3].cuco__gf_psc_condition_id__c = conditions[2].Id;
     conditionAttr[4].cuco__gf_psc_condition_attribute_id__c = 'np.nat.transfer.EEE.ob.tf.min';
     conditionAttr[4].cuco__gf_psc_condition_id__c = conditions[2].Id;
     conditionAttr[5].cuco__gf_psc_condition_attribute_id__c = 'np.nat.transfer.EEE.ob.tf.max';
     conditionAttr[5].cuco__gf_psc_condition_id__c = conditions[2].Id;
     conditionAttr[6].cuco__gf_psc_condition_attribute_id__c = 'FX.issued.order.pay.days';
     conditionAttr[6].cuco__gf_psc_condition_id__c = conditions[3].Id;
     conditionAttr[7].cuco__gf_psc_condition_attribute_id__c = 'np.SEPA.day.payroll.eur.branch.type';
     conditionAttr[7].cuco__gf_psc_condition_id__c = conditions[4].Id;
     conditionAttr[8].cuco__gf_psc_condition_attribute_id__c = 'np.SEPA.day.payroll.eur.branch.min';
     conditionAttr[8].cuco__gf_psc_condition_id__c = conditions[4].Id;
     conditionAttr[9].cuco__gf_psc_condition_attribute_id__c = 'np.SEPA.day.payroll.eur.branch.max';
     conditionAttr[9].cuco__gf_psc_condition_id__c = conditions[4].Id;
    insert  conditionAttr;
    return  conditionAttr;
  }

}