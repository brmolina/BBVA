/** ********************************************************************************
* @author       JSS
* @date        
* @description  Trigger para objeto PRC_Price_Amortization_Data__c con lógica para las oportunidades de la funcionalidad PRICING. No crear más triggers para PRC_Price_Amortization_Data__c, para ello usar la clase con el handler.
* @Revision
********************************************************************************* */
trigger PRC_PriceAmortizationTrigger on PRC_Price_Amortization_Data__c (before insert) {
    final PRC_PriceAmortizationTriggerHandler pricingHandler = PRC_PriceAmortizationTriggerHandler.getInstance();

    if(Trigger.isBefore){
        if(Trigger.isInsert){
            pricingHandler.updatePricingDetailId(Trigger.new);
        } 
    }

}