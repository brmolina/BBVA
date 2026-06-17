public without sharing class DMT_OpportunityClientTriggerHelper {

    /**
     * @description Executed Before Insert. Queries existing X-Sell records related to the parent 
     * Opportunity and injects the rolled-up totals directly into the new Client records before they are saved.
     * @param newClients List of DMT_Opportunity_Client__c from Trigger.new
     */
    public void syncInitialXSellTotals(List<DMT_Opportunity_Client__c> newClients) {
        Set<Id> oppIds = new Set<Id>();

        for (DMT_Opportunity_Client__c client : newClients) {
            if (client.DMT_MDE_Opportunity__c != null) {
                oppIds.add(client.DMT_MDE_Opportunity__c);
            }
        }

        if (oppIds.isEmpty()) {
            return;
        }

        Map<Id, Map<String, Decimal>> oppToSumsMap = new Map<Id, Map<String, Decimal>>();

        for (AggregateResult ar : [
            SELECT Opportunity__c oppId, 
                   SUM(XSELL_Value_PY__c) sumPY, 
                   SUM(XSELL_Value_CY__c) sumCY, 
                   SUM(XSELL_Value_NY__c) sumNY, 
                   SUM(XSELL_Value_NY1__c) sumNY1
            FROM DMT_X_Sell__c
            WHERE Opportunity__c IN :oppIds
            WITH SYSTEM_MODE
            GROUP BY Opportunity__c
        ]) {
            Id oppId = (Id)ar.get('oppId');
            oppToSumsMap.put(oppId, new Map<String, Decimal>{
                'PY' => (Decimal)ar.get('sumPY'),
                'CY' => (Decimal)ar.get('sumCY'),
                'NY' => (Decimal)ar.get('sumNY'),
                'NY1' => (Decimal)ar.get('sumNY1')
            });
        }

        if (oppToSumsMap.isEmpty()) {
            return;
        }

        for (DMT_Opportunity_Client__c client : newClients) {
            if (client.DMT_MDE_Opportunity__c != null && oppToSumsMap.containsKey(client.DMT_MDE_Opportunity__c)) {
                Map<String, Decimal> sums = oppToSumsMap.get(client.DMT_MDE_Opportunity__c);
                
                // Inject sums directly into memory. Null coalescing ensures we don't insert nulls if the SUM returned null.
                client.Past2_FY_Child_X_Sell_amount__c = sums.get('PY') != null ? sums.get('PY') : 0;
                client.Past_FY_Child_X_Sell_amount__c  = sums.get('CY') != null ? sums.get('CY') : 0;
                client.Current_FY_Child_X_Sell_amount__c = sums.get('NY') != null ? sums.get('NY') : 0;
                client.Next_FY_Child_X_Sell_amount__c  = sums.get('NY1') != null ? sums.get('NY1') : 0;
            }
        }
    }
}