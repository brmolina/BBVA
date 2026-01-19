/** ********************************************************************************
* @author       JSS
* @date         09/03/2020
* @description  Controlador del componente lighning PRC_ProfitabilityLifeTimeChart
* @Revision
********************************************************************************* */
public without sharing class PRC_ProfitabilityLifeTimeChart_Ctrl {
    
    // ---------------
    // Public Methods
    // ---------------          
    
    /**
    * @author       JSS
    * @description  Método que devuelve el Id PRC_Pricing_Detail__c de la Opportunity que se pasa como parámetro
    */    
    @auraEnabled
    public static PRC_Pricing_Detail__c getOppLineItemData(String oppId) {
        final PRCPricingUtils pricingLogic = PRCPricingUtils.getInstance();    
        return pricingLogic.getPricingDetailsDataFromOpp(oppId);         
    }

}