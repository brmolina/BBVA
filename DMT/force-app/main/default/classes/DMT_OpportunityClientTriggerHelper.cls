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

    /**
     * CIBGLOBALD-3981 - Executed Before Insert. Infers Client RORC NBC Last FY (%), Client RORC NBC
     * YTD (%) and Client RWA Last 12m from the Account associated with the parent Opportunity - from
     * the Account itself when it is already Group/Subgroup/Supragroup, or from its DES_Main_Parent__r
     * ("group of the subsidiary") when it is a Subsidiary - only while the target field is still
     * blank, so a value already present (typed by a user, or carried over by a clone/renewal) is
     * never overwritten.
     * @param newClients List of DMT_Opportunity_Client__c from Trigger.new
     */
    public void syncInferredAccountGroupFields(List<DMT_Opportunity_Client__c> newClients) {
        Set<Id> oppIds = new Set<Id>();

        for (DMT_Opportunity_Client__c client : newClients) {
            if (client.DMT_MDE_Opportunity__c != null) {
                oppIds.add(client.DMT_MDE_Opportunity__c);
            }
        }

        if (oppIds.isEmpty()) {
            return;
        }

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>([
            SELECT Id,
                   Account.DES_Structure_Type__c,
                   Account.DES_RORC_NBC__c,
                   Account.DES_RORC_YTD__c,
                   Account.DES_RWA_Last12m__c,
                   Account.DES_Main_Parent__r.DES_RORC_NBC__c,
                   Account.DES_Main_Parent__r.DES_RORC_YTD__c,
                   Account.DES_Main_Parent__r.DES_RWA_Last12m__c,
                   Account.DES_BDI_Last12m__c,
                   Account.DES_Main_Parent__r.DES_BDI_Last12m__c
            FROM Opportunity
            WHERE Id IN :oppIds
            WITH SYSTEM_MODE
        ]);

        for (DMT_Opportunity_Client__c client : newClients) {
            Opportunity opp = client.DMT_MDE_Opportunity__c != null ? oppById.get(client.DMT_MDE_Opportunity__c) : null;
            if (opp == null || opp.Account == null) {
                continue;
            }

            Account groupAccount = (DMT_Opportunity_Utils.isSubsidiaryType(opp.Account.DES_Structure_Type__c) && opp.Account.DES_Main_Parent__r != null)
                ? opp.Account.DES_Main_Parent__r
                : opp.Account;

            if (client.DMT_Clients_Global_RORC_CIB_Past_FY__c == null) {
                client.DMT_Clients_Global_RORC_CIB_Past_FY__c = groupAccount.DES_RORC_NBC__c;
            }
            if (client.DMT_Client_RORC_YTD__c == null) {
                client.DMT_Client_RORC_YTD__c = groupAccount.DES_RORC_YTD__c;
            }
            if (client.DMT_Client_RWA__c == null) {
                client.DMT_Client_RWA__c = groupAccount.DES_RWA_Last12m__c;
            }
            if (client.DMT_Client_Net_Incomes__c == null) {
                client.DMT_Client_Net_Incomes__c = groupAccount.DES_BDI_Last12m__c;
            }
        }
    }

    /**
     * CIBGLOBALD-3748 Executed After Update. Dynamically verify that the opportunities Client fields
     * meet the necessary requirements to be submitted to Clan.
     */
    public void checkOpportunityClientChanges(List<DMT_Opportunity_Client__c> newList, Map<Id, DMT_Opportunity_Client__c> oldMap) {

        Id dmtRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
        Set<Id> opportunityIds = new Set<Id>();

        for (DMT_Opportunity_Client__c client : newList) {
            DMT_Opportunity_Client__c oldClient = oldMap.get(client.Id);

            Boolean changed = client.DMT_Commitment_Deadline__c != oldClient.DMT_Commitment_Deadline__c || client.DMT_Applicable_Jurisdiction__c != oldClient.DMT_Applicable_Jurisdiction__c;

            if (changed && client.DMT_MDE_Opportunity__c != null) {
                opportunityIds.add(client.DMT_MDE_Opportunity__c);
            }
        }

        if (!opportunityIds.isEmpty()) {
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
                [SELECT Id,
                        RecordTypeId,
                        StageName,
                        DMT_Product_Area__c
                    FROM Opportunity
                    WHERE Id IN :opportunityIds]
            );
            for (Opportunity opp : oppMap.values()) {
                if (opp.RecordTypeId == dmtRecordTypeId && opp.StageName == 'Ready to close' && opp.DMT_Product_Area__c == 'IB&F') {
                    System.debug('checkOpportunityClientChanges opp: ' + opp.Id);
                    DMT_AsyncOrchestrator.enqueue(
                        new DMT_DynamicMapperPayload(
                            opp.Id,
                            'DMT_Opportunity_RTC_To_Clan',
                            opp.StageName
                        )
                    );
                }
            }
        }
    }
}