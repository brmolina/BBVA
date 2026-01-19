/** ********************************************************************************
* @author       JSS
* @date         10/04/2020
* @description  Controlador del componente lighning PRC_ProfitabilityEvolutionChart
* @Revision
********************************************************************************* */
public without sharing class PRC_ProfitabilityEvolutionChart_Ctrl {
    
    // ---------------
    // Public Methods
    // ---------------          
    
    /**
    * @author       JSS
    * @description  Método que devuelve la lista de PRC_Profitability_Scenarios__c de la Opportunity que se pasa como parámetro
    */    
    @auraEnabled
    public static list<PRC_Profitability_Scenarios__c> getScenariotData(String oppId) {
        final PRCPricingUtils pricingLogic = PRCPricingUtils.getInstance();    
        return pricingLogic.getScenarioWithoutSalesAgreementData(oppId);         
    }
}