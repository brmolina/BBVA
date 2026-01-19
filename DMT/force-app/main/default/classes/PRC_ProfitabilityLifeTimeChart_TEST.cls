/** ********************************************************************************
* @author       JSS
* @date         30/04/2020
* @description  Clase para testear la clase PRC_ProfitabilityLifeTimeChart_Ctrl
* @Revision
********************************************************************************* */
@isTest
public class PRC_ProfitabilityLifeTimeChart_TEST {
    public static testmethod void test01() {
         //INSERT DATA NEEDED
         PRC_TestUtils utils = new PRC_TestUtils();
         String resp = PrcPriceMatrixBrowser_Ctrl.callWsRegisterAmiweb((String) utils.opp.Id, utils.priceFullResponse, utils.selectedPrice);

         //START TEST
         
            PRC_Pricing_Detail__c oli = PRC_ProfitabilityLifeTimeChart_Ctrl.getOppLineItemData((String) utils.opp.Id);
         

         //ASSERTS
         System.assertEquals(utils.pd.id,oli.id);
     }

}