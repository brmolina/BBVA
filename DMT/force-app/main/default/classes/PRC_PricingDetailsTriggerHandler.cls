/*
    * @author       JSS
    * @date         2020/03/17
    * @description  Manejador del trigger para el objeto PRC_Pricing_Detail__c con lógica para las oportunidades de la funcionalidad PRICING. 
    * @Revision

    Version   Date            Author          Summary of changes
    ----------------------------------------------------------------------------------
*/
    public with sharing class PRC_PricingDetailsTriggerHandler {
        //LOGIC
        /*Declarando variable*/
        private Integer timesExecuted = 0;
        /*Declarando variable*/
        private final CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();
        /*Declarando variable*/
        private final CIB_Bypass__c bypassSettings = CIB_Bypass__c.getInstance();

        private PRC_PricingDetailsTriggerHandler() {
        }
    
        //SINGLETON PATTERN
        private static PRC_PricingDetailsTriggerHandler instance;
        public static PRC_PricingDetailsTriggerHandler getInstance() { //NOSONAR
            if (instance == null) {
                instance = new PRC_PricingDetailsTriggerHandler();
            }
            return instance;
        }


        /**
		* @author       JSS
		* @description  metodo con la lógica que actualiza el OpportunityLineItem para relacionarlo con el PricingDetails recién creado
		*/
        public void updatePricingDetailOnOpportunityLineItem(List <PRC_Pricing_Detail__c> triggerNew) {
              System.debug('>>>>>>>>>> PRC_PricingDetailsTriggerHandler. Entrando en el método updatePricingDetailOnOpportunityLineItem' );
              final PRCPricingUtils pricingLogic = PRCPricingUtils.getInstance();
              map<id,id> pricingOpportunityMap = new map<id,id>();
              //list<OpportunityLineItem> oppLIToUpdate = new list<OpportunityLineItem>();
              for (PRC_Pricing_Detail__c pd : triggerNew) {
                  pricingOpportunityMap.put(pd.PRC_Opportunity__c,pd.id);
              }
              if (!pricingOpportunityMap.isEmpty()){
                 list<OpportunityLineItem> oppLIToUpdate = [Select id, PRC_Pricing_Detail__c,OpportunityId From OpportunityLineItem Where OpportunityId in :pricingOpportunityMap.keyset()];
                 if (!oppLIToUpdate.isEmpty()) { // este if nunca debería ser vacío
                    System.debug('>>>>>>>>>> Actualizando campo PRC_Pricing_Detail__c en el OpportunityLineItem' );
                      for (OpportunityLineItem oli : oppLIToUpdate){
                          oli.PRC_Pricing_Detail__c = pricingOpportunityMap.get(oli.OpportunityId);
                      }
                     update oppLIToUpdate;
              	}
                      
              }

        }
    
}