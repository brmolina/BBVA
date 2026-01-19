/*
    * @author       JSS
    * @date         2020/03/17
    * @description  Manejador del trigger para el objeto OpportunityLineItem.
    * @Revision

    Version   Date            Author          Summary of changes
    ----------------------------------------------------------------------------------
    0.1      2020/03/17       JSS             Se añaden métodos con lógica para las oportunidades de la funcionalidad PRICING
    
*/
    public with sharing class OpportunityLineItemPricingTriggerHandler {
        //LOGIC
            //private final ActivitiesUtils logic;
        /*Declarando variable*/
        private Integer timesExecuted = 0;
        /*Declarando variable*/
        private final CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();
        /*Declarando variable*/
        private final CIB_Bypass__c bypassSettings = CIB_Bypass__c.getInstance();

        private OpportunityLineItemPricingTriggerHandler() {
        }
    
        //SINGLETON PATTERN
        private static OpportunityLineItemPricingTriggerHandler instance;
        public static OpportunityLineItemPricingTriggerHandler getInstance() { //NOSONAR
            if (instance == null) {
                instance = new OpportunityLineItemPricingTriggerHandler();
            }
            return instance;
        }

    
          /**
          * @author       JSS
          * @description  metodo con la lógica para evitar que se eliminen OppLineItem con la funcionalidad de Pricing que ya se ha enviado a Workflow
          */
          public void checkLogicForDeletingPricingOLI(List <OpportunityLineItem> triggerOld) {
              System.debug('>>>>>>>>>> OpportunityLineItemPricingTriggerHandler. Entrando en el método checkLogicForDeletingPricingOLI, triggerlist: ' + triggerOld.toString());
                final PRCPricingUtils pricingLogic = PRCPricingUtils.getInstance();
                for (OpportunityLineItem oli : triggerOld) {
                  // Este IF primero es por seguridad, nunca debería pasar por él porque se desactiva el botón de eliminar producto en el componente ProductConfiguration
                    if (!pricingLogic.pricingOppLineItemCanBeDeleted(oli)) {
                        oli.addError(label.PRC_CANNOT_DELETE_PRICING_OPPORTUNITY);
                    }
                }
        }

        /**
          * @author       JSS
          * @description  metodo con la lógica para evitar que se eliminen oportunidades con la funcionalidad de Pricing que ya se ha enviado a Workflow
          */
          public void deletePricingData(List <OpportunityLineItem> triggerOld) {
              System.debug('>>>>>>>>>> OpportunityLineItemPricingTriggerHandler. Entrando en el método deletePricingData, triggerlist: ' + triggerOld.toString());
              final List<PRC_Pricing_Detail__c> prcdList = new List<PRC_Pricing_Detail__c>();
              map<Id,Opportunity> pricingOppMap = new map<Id,Opportunity>();
              final PRCPricingUtils pricingLogic = PRCPricingUtils.getInstance();
              for (OpportunityLineItem oli : triggerOld) {
                if (!String.isBlank(oli.PRC_Pricing_Detail__c)) {
                  final PRC_Pricing_Detail__c prcdetail = new PRC_Pricing_Detail__c(id = oli.PRC_Pricing_Detail__c);
                  prcdList.add(prcdetail);
                }
                System.debug('>>>>>>>>>> valores de amiweb ID: ' + oli.gf_amiweb_opportunity_id__c + ' --- workflow id: '+ oli.gf_workflow_opportunity_id__c);
                if (pricingLogic.oppLineItemHasPricingData(oli)) {
                      System.debug('>>>>>>>>>> Es un producto con datos rellenos de Pricing, hay que eliminarlos y actualizar la info de Opp: ' + oli.OpportunityId);
                      Opportunity oppToUpdate = new Opportunity(id = oli.OpportunityId,
                      gf_amiweb_opportunity_id__c = ''); // se pone a '' el amiwebID para que se dejen de mostrar las
                      pricingOppMap.put(oli.OpportunityId,oppToUpdate);
                }     
              }

              if (!prcdList.isEmpty()) {
                  System.debug('>>>>>>>>>> Antes del delete de PRC_Pricing_Detail__c y PRC_Profitability_Scenarios__c: ' + prcdList);
                  delete prcdList;
                  /* el segundo delete de PRC_Profitability_Scenarios__c no hace falta porque es Maestro-Detalle con PRC_Pricing_Detail__c
                  delete [Select Id From PRC_Profitability_Scenarios__c Where PRC_Pricing_Detail__c in :prcdList];*/
              }

              if (!pricingOppMap.isEmpty()) {
                  System.debug('>>>>>>>>>> Antes del update de Opportunities: ' + pricingOppMap.values().toString());
                  update pricingOppMap.values();
              }
          
  
      }



        /**
          * @author       JSS
          * @description  metodo con la lógica para evitar que se añada un nuevo producto de OppLineItem si ya existe alguno funcionalidad de Pricing
          */
          public void checkPricingLogicForAddNewOLI(List <OpportunityLineItem> triggerNew) {
            list<id> oppIdList = new list<id>();
            for (OpportunityLineItem oli : triggerNew) {
              oppIdList.add(oli.opportunityId);
            }

            list<PRC_Pricing_Detail__c> pdList = [Select id,PRC_Opportunity__c from PRC_Pricing_Detail__c where PRC_Opportunity__c in :oppIdList]; 
            Set<Id> oppPricingList = new Set<Id>();
            for (PRC_Pricing_Detail__c pd : pdList) {
              oppPricingList.add(pd.PRC_Opportunity__c);
            }

            // recorremos la lista de triggerNew y comprobamos si las opp de cada oppLineItem ya estaban en la lista de oppPricing
            for (OpportunityLineItem oli : triggerNew) {
              if (oppPricingList.contains(oli.opportunityId)) {
                    oli.addError(label.PRC_PRICING_CANNOT_ADD_NEW_PRODUCT);
              }
    
            }
        

    }
    
     }