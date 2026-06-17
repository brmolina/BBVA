public without sharing class XSellTriggerHelper {

    /**
     * Extracts Opportunity IDs only if the relevant numbers or the lookup itself changed.
     */
    public void recalculateTotals(List<DMT_X_Sell__c> records, Map<Id, DMT_X_Sell__c> mapOld) {
        Set<Id> oppIdsToRecalculate = new Set<Id>();

        for (DMT_X_Sell__c record : records) {
            if (mapOld == null) {
                // Insert, Delete, Undelete context
                if (record.Opportunity__c != null) {
                    oppIdsToRecalculate.add(record.Opportunity__c);
                }
            } else {
                // Update context: Dirty check
                DMT_X_Sell__c oldRecord = mapOld.get(record.Id);
                if (
                    record.XSELL_Value_PY__c != oldRecord.XSELL_Value_PY__c ||
                    record.XSELL_Value_CY__c != oldRecord.XSELL_Value_CY__c ||
                    record.XSELL_Value_NY__c != oldRecord.XSELL_Value_NY__c ||
                    record.XSELL_Value_NY1__c != oldRecord.XSELL_Value_NY1__c ||
                    record.Opportunity__c != oldRecord.Opportunity__c
                ) {
                    if (record.Opportunity__c != null) {
                        oppIdsToRecalculate.add(record.Opportunity__c);
                    }
                    if (oldRecord.Opportunity__c != null) {
                        oppIdsToRecalculate.add(oldRecord.Opportunity__c);
                    }
                }
            }
        }

        if (!oppIdsToRecalculate.isEmpty()) {
            updateOpportunityClientTotals(oppIdsToRecalculate);
        }
    }

    /**
     * Executes the Aggregate Math and updates the DMT_Opportunity_Client__c records.
     */
    private void updateOpportunityClientTotals(Set<Id> oppIds) {
        List<DMT_Opportunity_Client__c> clientsToEvaluate = [
            SELECT Id, DMT_MDE_Opportunity__c,
                   Past2_FY_Child_X_Sell_amount__c,
                   Past_FY_Child_X_Sell_amount__c,
                   Current_FY_Child_X_Sell_amount__c,
                   Next_FY_Child_X_Sell_amount__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c IN :oppIds
            WITH SYSTEM_MODE
        ];

        if (clientsToEvaluate.isEmpty()) return;

        Map<Id, Map<String, Decimal>> oppToSumsMap = new Map<Id, Map<String, Decimal>>();
        for (Id oppId : oppIds) {
            oppToSumsMap.put(oppId, new Map<String, Decimal>{
                'PY' => 0, 'CY' => 0, 'NY' => 0, 'NY1' => 0
            });
        }

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
            oppToSumsMap.get(oppId).put('PY', (Decimal)ar.get('sumPY'));
            oppToSumsMap.get(oppId).put('CY', (Decimal)ar.get('sumCY'));
            oppToSumsMap.get(oppId).put('NY', (Decimal)ar.get('sumNY'));
            oppToSumsMap.get(oppId).put('NY1', (Decimal)ar.get('sumNY1'));
        }

        List<DMT_Opportunity_Client__c> clientsToUpdate = new List<DMT_Opportunity_Client__c>();

        for (DMT_Opportunity_Client__c client : clientsToEvaluate) {
            Map<String, Decimal> sums = oppToSumsMap.get(client.DMT_MDE_Opportunity__c);
            Boolean isDirty = false;

            if (client.Past2_FY_Child_X_Sell_amount__c != sums.get('PY')) {
                client.Past2_FY_Child_X_Sell_amount__c = sums.get('PY');
                isDirty = true;
            }
            if (client.Past_FY_Child_X_Sell_amount__c != sums.get('CY')) {
                client.Past_FY_Child_X_Sell_amount__c = sums.get('CY');
                isDirty = true;
            }
            if (client.Current_FY_Child_X_Sell_amount__c != sums.get('NY')) {
                client.Current_FY_Child_X_Sell_amount__c = sums.get('NY');
                isDirty = true;
            }
            if (client.Next_FY_Child_X_Sell_amount__c != sums.get('NY1')) {
                client.Next_FY_Child_X_Sell_amount__c = sums.get('NY1');
                isDirty = true;
            }

            if (isDirty) {
                clientsToUpdate.add(client);
            }
        }

        if (!clientsToUpdate.isEmpty()) {
            update clientsToUpdate;
        }
    }
}