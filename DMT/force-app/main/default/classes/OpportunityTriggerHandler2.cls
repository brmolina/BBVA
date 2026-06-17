/**
 * @description Handler auxiliar optimizado del trigger de Opportunity
 *              Cambio principal: Evitar update recursivo en UpdateReopenOpportunity
 * @author Optimización de triggers - BBVA
 * @date 2024
 */
public with sharing class OpportunityTriggerHandler2 {
    
    private OpportunityTriggerHandler2() {
        // Empty constructor
    }

    /**
     * @description Actualiza la bandera de expiración cuando se reabre una oportunidad
     *              OPTIMIZADO: Usa control de recursión para evitar loop infinito
     */
    public static void UpdateReopenOpportunity(List<Opportunity> lstNewOpportunity, List<Opportunity> lstOldOpportunity) {
        // Verificar si ya se ejecutó para evitar recursión
        if (TriggerRecursionControl.hasOpportunityReopenUpdateExecuted()) {
            return;
        }
        
        List<Opportunity> lstReopenOpp = new List<Opportunity>();

        for (Integer i = 0; i < lstNewOpportunity.size(); i++) {
            Opportunity newOpp = lstNewOpportunity[i];
            Opportunity oldOpp = lstOldOpportunity[i];
            
            Boolean wasClosedWon = oldOpp.StageName == System.Label.DES_Closed_Won;
            Boolean wasClosedLose = oldOpp.StageName == System.Label.DES_Closed_Lose;
            Boolean stageChanged = newOpp.StageName != oldOpp.StageName;
            
            if (stageChanged && (wasClosedWon || wasClosedLose)) {
                lstReopenOpp.add(new Opportunity(
                    Id = newOpp.Id,
                    opportunity_expiration_ind_type__c = false
                ));
            }
        }

        if (!lstReopenOpp.isEmpty()) {
            // Marcar como ejecutado ANTES del update para evitar recursión
            TriggerRecursionControl.setOpportunityReopenUpdateExecuted();
            
          Database.SaveResult[] results = Database.update(lstReopenOpp, false);
            
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Database.Error err : results[i].getErrors()) {
                        System.debug(LoggingLevel.ERROR, 
                            'Error updating Opportunity ' + lstReopenOpp[i].Id + ': ' + err.getMessage());
                    }
                }
            }
        }
    }

    /**
     * @description Handler para after insert
     */
    public static void onAfterInsert(List<Opportunity> newList) {
        Opportunity_Helper_Comm_Alert.changeCommAlertStatusInsert(newList);
    }

    /**
     * @description Handler para after update
     */
    public static void onAfterUpdate(Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap) {
        Opportunity_Helper_Comm_Alert.changeCommAlertStatusUpdate(newMap, oldMap);
    }
}