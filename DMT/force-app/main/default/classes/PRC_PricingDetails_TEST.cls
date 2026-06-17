/** ********************************************************************************
 * @author
 * @date         07/05/2020
 * @description  Clase para testear la clase PRC_PricingDetails_CONTROLLER
 * @Revision
 ********************************************************************************* */
@isTest
public class PRC_PricingDetails_TEST {
  /**
   * @description
   * @author Global Desktop | 03-08-2021
   **/
  @isTest
  static void testcheckvisibility() {
    final PRC_TestUtils engine = new PRC_TestUtils();

    final OpportunityLineItem oli = engine.createOpportunityLineItem();
    final List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
    oliList.add(oli);

    final Boolean resultado = PRC_PricingDetails_CONTROLLER.checkvisibility(engine.opp, oliList);

    //ASSERTS
    System.assertEquals(false, resultado);
  }

  /**
   * @description
   * @author Global Desktop | 03-08-2021
   **/
  @isTest
  static void testloadrecords() {
    final PRC_TestUtils engine = new PRC_TestUtils();

    final Opportunity opp = PRC_PricingDetails_CONTROLLER.loadrecords(engine.opp.Id);

    //ASSERTS
    System.assertEquals(engine.opp.id, opp.id);
  }

  /**
   * @description
   * @author Global Desktop | 03-08-2021
   **/
  @isTest
  static void testinsertMitigant() {
    final DES_UtilTestClass utils = new DES_UtilTestClass();
    final Account acc = utils.createClient();
    acc.DES_Structure_Type__c = Label.DES_STR_TYPE_Subsidiary;
    acc.g_customer_id__c = 'Test';
    insert acc;

    final Opportunity opp = utils.createOpportunity(acc);
    insert opp;

    final PRC_Pricing_Detail__c pcd = new PRC_Pricing_Detail__c();
    pcd.opportunity_start_date__c = Date.today();
    pcd.gf_non_accrual_comission_per__c = 12;
    pcd.gf_accrual_per__c = 13;
    pcd.PRC_Opportunity__c = opp.Id;
    pcd.business_area_desc__c = 'GTB';
    pcd.gf_operation_term_number__c = 'true';
    insert pcd;

    Test.startTest();
    final Map<String, String> mapDataMitigant = new Map<String, String>();
    mapDataMitigant.put('DES_Client_Mitigant__c', acc.Id);
    mapDataMitigant.put('gf_cty_rqst_wrrnty_risk_per__c', '36');
    mapDataMitigant.put('gf_end_guarantee_date__c', '2021-03-10');
    mapDataMitigant.put('gf_external_rating_agncy_type__c', 'A+');
    mapDataMitigant.put('Pricing_Detail__c', pcd.Id);
    PRC_PricingDetails_CONTROLLER.insertMitigant(mapDataMitigant);

    final List<PRC_Mitigant__c> mitigants = PRC_PricingDetails_CONTROLLER.getMitigants(pcd.Id);
    final Boolean bool = PRC_PricingDetails_CONTROLLER.mitigantsVisibility(opp.Id); //NOSONAR

    system.assert(!mitigants.isEmpty(), 'mitigante no creado');

    PRC_PricingDetails_CONTROLLER.deleteMitigant(mitigants.get(0).Id);
    Test.stopTest();
  }

}