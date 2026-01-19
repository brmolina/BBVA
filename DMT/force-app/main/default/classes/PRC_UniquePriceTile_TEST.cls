/** ********************************************************************************
 * @author       JSS
 * @date         03/06/2020
 * @description  Clase para testear el controlador PRC_UniquePriceTile_Controller
 * @Revision
 ********************************************************************************* */
@isTest
public class PRC_UniquePriceTile_TEST {
    public static testmethod void getPricingDetail_test() {
        //INSERT DATA NEEDED
        PRC_TestUtils utils = new PRC_TestUtils();

        //START TEST
        PRC_Pricing_Detail__c pd = PRC_UniquePriceTile_Controller.getPricingDetail((String) utils.opp.Id);

        //ASSERTS -- se podrían añadir más asserts de OppLineItem
        System.assertEquals(utils.pd.Id, pd.id);
    }

}