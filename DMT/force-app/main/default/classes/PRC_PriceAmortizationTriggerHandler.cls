/*
    * @author       JSS
    * @date         2020/05/25
    * @description  Manejador del trigger para el objeto PRC_Price_Amortization_Data__c con lógica para las oportunidades de la funcionalidad PRICING. 
    * @Revision

    Version   Date            Author          Summary of changes
    ----------------------------------------------------------------------------------
*/
    public with sharing class PRC_PriceAmortizationTriggerHandler {
        //LOGIC
        /*Declarando variable*/
        private Integer timesExecuted = 0;
        /*Declarando variable*/
        private final CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();
        /*Declarando variable*/
        private final CIB_Bypass__c bypassSettings = CIB_Bypass__c.getInstance();

        private PRC_PriceAmortizationTriggerHandler() {
        }
    
        //SINGLETON PATTERN
        private static PRC_PriceAmortizationTriggerHandler instance;
        public static PRC_PriceAmortizationTriggerHandler getInstance() { //NOSONAR
            if (instance == null) {
                instance = new PRC_PriceAmortizationTriggerHandler();
            }
            return instance;
        }


        /**
		* @author       JSS
		* @description  metodo con la lógica que actualiza el PricingDetailId para relacionarlo con el PricingDetails
		*/
        public void updatePricingDetailId(List <PRC_Price_Amortization_Data__c> triggerNew) {
              final PRCPricingUtils pricingLogic = PRCPricingUtils.getInstance();
              list<id> idList = new list<id>();
              for (PRC_Price_Amortization_Data__c pad : triggerNew) {
                  if (pad.PRC_Pricing_Detail__c == null) {
                      idList.add(pad.PRC_Opportunity__c);
                  }
              }
              if (!idList.isEmpty()){
                 final map<id,PRC_Pricing_Detail__c> pdMap = pricingLogic.getPricingDetailsDataMapByOpp(idList);
                 if (!pdMap.isEmpty()) { // este if nunca debería ser vacío
                      for (PRC_Price_Amortization_Data__c pad : triggerNew) {
                          if (pad.PRC_Pricing_Detail__c == null) {
                              pad.PRC_Pricing_Detail__c = pdMap.get(pad.PRC_Opportunity__c).Id;
                          }
                      }
              	}
                      
              }
        }
    
}