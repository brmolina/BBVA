/** ********************************************************************************
* @author       JSS
* @date         30/04/2020
* @description  Clase para testear la clase PRC_ProfitabilityEvolutionChart_Ctrl
* @Revision
********************************************************************************* */
@isTest
public class PRC_ProfitabilityEvolutionChart_TEST {
    public static testmethod void test01() {
         //INSERT DATA NEEDED
         PRC_TestUtils utils = new PRC_TestUtils();
         String resp = PrcPriceMatrixBrowser_Ctrl.callWsRegisterAmiweb((String) utils.opp.Id, utils.priceFullResponse, utils.selectedPrice);

        
         //START TEST
         
            list<PRC_Profitability_Scenarios__c>  scenList = PRC_ProfitabilityEvolutionChart_Ctrl.getScenariotData((String) utils.opp.Id);
         

         //ASSERTS
         System.assertEquals(1,scenList.size());
     }

}