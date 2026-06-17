/** ********************************************************************************
* @author       JSS
* @date        
* @description  Trigger para objeto PRC_Profitability_Scenarios__c con lógica para las oportunidades de la funcionalidad PRICING. No crear más triggers para PRC_Profitability_Scenarios__c, para ello usar la clase con el handler.
* @Revision
********************************************************************************* */
trigger PRC_ProfitabilityScenariosTrigger on PRC_Profitability_Scenarios__c (before insert) {
    final PRC_ProfitabilityScenariosTriggerHandler pricingHandler = PRC_ProfitabilityScenariosTriggerHandler.getInstance();

    if(Trigger.isBefore){
        if(Trigger.isInsert){
            pricingHandler.updatePricingDetailId(Trigger.new);
        } 
    }

}