/** ********************************************************************************
 * @author
 * @date         07/05/2020
 * @description  Clase para testear la clase PRC_PriceForm_CONTROLLER
 * @Revision
 ********************************************************************************* */
@isTest
public class PRC_PriceForm_TEST {
  /**
   * @description
   * @author Global Desktop | 03-08-2021
   **/
  @isTest
  static void testgetPricingDetail() {
    final PRC_TestUtils engine = new PRC_TestUtils();
    final PRC_Pricing_Detail__c pd = PRC_PriceForm_CONTROLLER.getPricingDetail(engine.opp.Id);

    //ASSERTS
    System.assertEquals(engine.pd.id, pd.id);
  }

  /**
   * @description
   * @author Global Desktop | 03-08-2021
   **/
  @isTest
  static void testgetPickList() {

    Test.startTest();
    final String plc = PRC_PriceForm_CONTROLLER.getPickList();
    Test.stopTest();
    //ASSERTS
    System.assertNotEquals(null, plc);
  }

  /**
   * @description
   * @author Global Desktop | 03-08-2021
   **/
  @isTest
  static void testgetPickRating() {
    Test.startTest();
    final PRC_bookingRating__mdt prc = PRC_PriceForm_CONTROLLER.getPickRating('BBVA S.A. - Spain');
    Test.stopTest();
    //ASSERTS
    System.assertNotEquals(null, prc);
  }

}