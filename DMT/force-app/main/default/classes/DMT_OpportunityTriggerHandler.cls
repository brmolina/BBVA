public with sharing class DMT_OpportunityTriggerHandler {

    //SINGLETON PATTERN
    private static DMT_OpportunityTriggerHandler instance;
    public static DMT_OpportunityTriggerHandler getInstance() { //NOSONAR
        if (instance == null) {
            instance = new DMT_OpportunityTriggerHandler();
        }
        return instance;
    }
    
  public void calculateAndUpdateNotionalAmounts(Map<ID,Opportunity> newOpps, Map<Id, Opportunity> oldOppMap) {
      Set<Id> opportunityIdsDMT = new Set<Id>();
        if (newOpps == null || newOpps.isEmpty()) {
            return;
        }

        String rtOppDmtID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get(DMT_Constants.RT_OPP_DMT_NAME)
            .getRecordTypeId();

      for(Opportunity opp :newOpps.values()){
        if(opp.RecordTypeId == rtOppDmtID && opp.DMT_CurrencyText__c != null && oldOppMap.get(opp.Id).DMT_CurrencyText__c != opp.DMT_CurrencyText__c) {
          opportunityIdsDMT.add(opp.Id);

        }
      }

        // Get all OpportunityLineItems for these opportunities
        List<OpportunityLineItem> allOliList = [
            SELECT Id, OpportunityId, DMT_Deal_amount__c, bbva_prtcp_tranche_amount__c, g_currency_id__c, Opportunity.DMT_CurrencyText__c
            FROM OpportunityLineItem
            WHERE OpportunityId IN :opportunityIdsDMT
        ];

        // Calculate converted amounts per opportunity
        Map<Id, Decimal> oppConvertedTotals = new Map<Id, Decimal>();
        Map<Id, Decimal> oppNotionalConvertedTotals = new Map<Id, Decimal>();

        for (OpportunityLineItem oli : allOliList) {
            if (!oppConvertedTotals.containsKey(oli.OpportunityId)) {
                oppConvertedTotals.put(oli.OpportunityId, 0);
            }
            if (!oppNotionalConvertedTotals.containsKey(oli.OpportunityId)) {
                oppNotionalConvertedTotals.put(oli.OpportunityId, 0);
            }

            // DMT_Opportunity_amount__c must be based on DMT_Deal_amount__c
            Decimal oliAmount = oli.DMT_Deal_amount__c != null ? oli.DMT_Deal_amount__c : 0;
            Decimal oliNotionalAmount = oli.bbva_prtcp_tranche_amount__c != null ? oli.bbva_prtcp_tranche_amount__c : 0;
            
            // Convert OLI amount to Opportunity's NEW currency
            Decimal convertedAmount = DMT_Currency.convert(
                oliAmount,
                oli.g_currency_id__c,
                newOpps.get(oli.OpportunityId).DMT_CurrencyText__c
            );
            // Convert notional amount to Opportunity's NEW currency with same logic
            Decimal convertedNotionalAmount = DMT_Currency.convert(
                oliNotionalAmount,
                oli.g_currency_id__c,
                newOpps.get(oli.OpportunityId).DMT_CurrencyText__c
            );
            if (convertedAmount == null) {
                newOpps.get(oli.OpportunityId).addError('Exchange rate not found for the currency pair: ' + oli.g_currency_id__c + ' to ' + newOpps.get(oli.OpportunityId).DMT_CurrencyText__c);
                return;
            }
            oppConvertedTotals.put(oli.OpportunityId, oppConvertedTotals.get(oli.OpportunityId) + convertedAmount);
            oppNotionalConvertedTotals.put(oli.OpportunityId, oppNotionalConvertedTotals.get(oli.OpportunityId) + convertedNotionalAmount);
        }

        // Build list for update
        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        for (Id oppId : oppConvertedTotals.keySet()) {
            Opportunity opp = newOpps.get(oppId);
            Decimal convertedTotal = oppConvertedTotals.get(oppId).setScale(2, RoundingMode.HALF_UP);
            Decimal convertedNotionalTotal = oppNotionalConvertedTotals.get(oppId).setScale(2, RoundingMode.HALF_UP);

            // Always update DMT_Opportunity_amount__c
            opp.DMT_Opportunity_amount__c = convertedTotal;

            // DMT_CUR_Notional_Amount__c must match the OLI BBVA participant tranche sum
            opp.DMT_CUR_Notional_Amount__c = convertedNotionalTotal;

            oppsToUpdate.add(opp);
        }
    }

    /**
     * @description Identifies new Opportunities that require X-Sell generation 
     * and enqueues the async payload for the Orchestrator.
     * @param newOpps List of newly inserted Opportunities (Trigger.new)
     */
    public void enqueueOppXSellGeneration(List<Opportunity> newOpps) {
        Set<Id> oppIdsForXSell = new Set<Id>();
        for (Opportunity opp : newOpps) {
            if (String.isNotBlank(opp.DMT_Entity__c) && opp.AccountId != null) {
                oppIdsForXSell.add(opp.Id);
            }
        }
        
        if (!oppIdsForXSell.isEmpty()) {
            DMT_AsyncOrchestrator.enqueue(new DMT_OppXSellPayload(oppIdsForXSell));
        }
    }
    /**
     * @description Called in AFTER UPDATE trigger.
     * Detects when a DMT_Opportunity moves to a closing stage (Closed Won / Closed Lost)
     * and enqueues an async payload to call the PAWIF integration via DMT_DynamicFieldMapper.
     * @param newOpps Trigger.new
     * @param oldMapOpps Trigger.oldMap
     */
    public void enqueueClosingIntegration(List<Opportunity> newOpps, Map<Id, Opportunity> oldMapOpps) {
        final Set<String> CLOSING_STAGES = new Set<String>{ 'Closed Won', 'Closed Lost' };

        Id oppRTId = Schema.SObjectType.Opportunity
            .getRecordTypeInfosByDeveloperName()
            .get('DMT_Opportunity')
            ?.getRecordTypeId();

        for (Opportunity opp : newOpps) {
            Opportunity oldOpp = oldMapOpps.get(opp.Id);

            Boolean isDMTRecord      = opp.RecordTypeId == oppRTId;
            Boolean isNowClosing     = CLOSING_STAGES.contains(opp.StageName);
            Boolean wasNotYetClosing = !CLOSING_STAGES.contains(oldOpp.StageName);

            if (isDMTRecord && isNowClosing && wasNotYetClosing) {
                DMT_AsyncOrchestrator.enqueue(
                    new DMT_DynamicMapperPayload(opp.Id, 'DMT_Finish_PAWIF', opp.StageName)
                );
            }
        }
    }

    /**
     */
    public void updatePassport_OppStatusChanged(List<Opportunity> newOpps, Map<Id, Opportunity> oldMapOpps) {

        Id oppRTId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity')?.getRecordTypeId();

        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : newOpps) {
            if (opp.RecordTypeId == oppRTId) {
                oppIds.add(opp.Id);
            }
        }

        for (Opportunity opp : newOpps) {
            Opportunity oldOpp = oldMapOpps.get(opp.Id);

            Boolean statusChanged = opp.StageName != oldOpp.StageName;
            Boolean passesIntegrity = opp.RecordTypeId == oppRTId;

            if (statusChanged && passesIntegrity) {
                DMT_AsyncOrchestrator.enqueue(new DMT_PassportPayload(opp.Id, opp.AccountId, 'DMTO_EvaluationOpportunity'));
            }
        }
    }

    /**
     * @description Dynamically validates if the Opportunity can advance to the target Stage 
     * based on the requiredAtStatus property in the Passport JSON payload.
     */
    public void validateDynamicStageChange(List<Opportunity> newOpps, Map<Id, Opportunity> oldOppMap) {
        Set<Id> oppIdsToCheck = new Set<Id>();
        
        for (Opportunity opp : newOpps) {
            if (opp.StageName != oldOppMap.get(opp.Id).StageName) {
                oppIdsToCheck.add(opp.Id);
            }
        }
        
        if (oppIdsToCheck.isEmpty()) return;

        Map<Id, Passport__c> passportMap = new Map<Id, Passport__c>();
        for (Passport__c p : [SELECT Opportunity__c, DMT_Passport_Save__c FROM Passport__c WHERE Opportunity__c IN :oppIdsToCheck WITH SYSTEM_MODE]) {
            if (String.isNotBlank(p.DMT_Passport_Save__c)) {
                passportMap.put(p.Opportunity__c, p);
            }
        }

        for (Opportunity opp : newOpps) {
            Passport__c passport = passportMap.get(opp.Id);
            if (passport == null) continue;

            try {
                // Parse the raw JSON map to access features
                Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(passport.DMT_Passport_Save__c);
                Map<String, Object> dataMap = (Map<String, Object>) root.get('data');
                
                if (dataMap == null || !dataMap.containsKey('features')) continue;
                
                List<Object> rawFeatures = (List<Object>) dataMap.get('features');
                
                for (Object featureObj : rawFeatures) {
                    Map<String, Object> featureMap = (Map<String, Object>) featureObj;
                    
                    // 1. Establish the Target Status (Fallback to 'Approval' if blank to prevent breaking)
                    String targetStatus = featureMap.containsKey('requiredAtStatus') && String.isNotBlank((String)featureMap.get('requiredAtStatus')) 
                        ? (String)featureMap.get('requiredAtStatus') 
                        : 'Approval';
                    
                    // 2. Check if the feature is Required ('Y')
                    String requiredType = featureMap.containsKey('requiredType') ? (String)featureMap.get('requiredType') : 'N';
                    Boolean isMandatory = requiredType.equalsIgnoreCase('Y');
                    
                    // 3. Dynamic Logic: If moving to the target stage, and it's mandatory, it MUST be GREEN
                    if (isMandatory && opp.StageName.equalsIgnoreCase(targetStatus)) {
                        String stateName = (String)featureMap.get('stateName');
                        String featureName = (String)featureMap.get('name');
                        
                        if (stateName == null || !stateName.equalsIgnoreCase('GREEN')) {
                            opp.addError('Cannot advance to ' + opp.StageName + '. The required Passport feature "' + featureName + '" is not approved (Current state: ' + stateName + ').');
                        }
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error parsing Passport JSON during dynamic validation: ' + e.getMessage());
            }
        }
    }
}