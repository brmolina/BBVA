/** ********************************************************************************
* @author       JSS
* @date        
* @description  Trigger para objeto PRC_Pricing_Detail__c con lógica para las oportunidades de la funcionalidad PRICING. No crear más triggers para PRC_Pricing_Detail__c, para ello usar la clase con el handler.
* @Revision
********************************************************************************* */
trigger PRC_PricingDetailsTrigger on PRC_Pricing_Detail__c (after insert) {
    final PRC_PricingDetailsTriggerHandler pricingHandler = PRC_PricingDetailsTriggerHandler.getInstance();

    if(Trigger.isAfter){
        if(Trigger.isInsert){
            pricingHandler.updatePricingDetailOnOpportunityLineItem(Trigger.new);
        } 
    }

}