public with sharing class DMT_BasicFinancialsController {

    @AuraEnabled(cacheable=false)
    public static List<DMT_Opportunity_Client__c> getFinancials(String recordId) {
            List<DMT_Opportunity_Client__c> clients = [
                    SELECT
                        Id,
                        Alpha_Code_Client__c,
                        Revenues_Last_Year_number__c,
                        Revenues_Current_Year_number__c, 
                        Revenues_Next_Year_number__c, 
                        Revenues_Next_Year_1_number__c, 
                        Revenues_Next_Year_2_number__c, 
                        EBITDA_Last_Year_number__c, 
                        EBITDA_Current_Year_number__c, 
                        EBITDA_Next_Year_number__c, 
                        EBITDA_Next_Year_1_number__c, 
                        EBITDA_Next_Year_2_number__c,
                        EBIT_Last_Year_number__c,
                        EBIT_Current_Year_number__c,
                        EBIT_Next_Year_number__c,
                        EBIT_Next_Year_1_number__c,
                        EBIT_Next_Year_2_number__c,                       
                        Net_Income_Last_Year_number__c,
                        Net_Income_Current_Year_number__c,
                        Net_Income_Next_Year_number__c,
                        Net_Income_Next_Year_1_number__c,
                        Net_Income_Next_Year_2_number__c,
                        Free_Cash_Flow_Last_Year_number__c,
                        Free_Cash_Flow_Current_Year_number__c,
                        Free_Cash_Flow_Next_Year_number__c,
                        Free_Cash_Flow_Next_Year_1_number__c,
                        Free_Cash_Flow_Next_Year_2_number__c,
                        Debt_EBITDA_Last_Year_number__c,
                        Debt_EBITDA_Current_Year_number__c,
                        Debt_EBITDA_Next_Year_number__c,
                        Debt_EBITDA_Next_Year_1_number__c,
                        Debt_EBITDA_Next_Year_2_number__c,
                        Net_Debt_EBITDA_Last_Year_number__c,
                        Net_Debt_EBITDA_Current_Year_number__c,
                        Net_Debt_EBITDA_Next_Year_number__c,
                        Net_Debt_EBITDA_Next_Year_1_number__c,
                        Net_Debt_EBITDA_Next_Year_2_number__c,
                        Last_Year_Formula__c

                    FROM DMT_Opportunity_Client__c
                    WHERE DMT_MDE_Opportunity__c =: recordId
                    WITH USER_MODE
                    ORDER BY CreatedDate
                    ];

            // Multiholder opportunities have several Opportunity Clients. The Basic Financials
            // table must show/save the Main Borrower's record, not an arbitrary one. Resolve the
            // Main Borrower and, when found, return only that record so the LWC (which uses the
            // first element for both display and the save target) targets the correct client.
            if (clients.size() <= 1) {
                return clients;
            }

            String mainCustomerId = getMainBorrowerCustomerId(recordId);
            if (String.isBlank(mainCustomerId)) {
                // Mono-holder / no Custom Association mapped: keep the original behaviour.
                return clients;
            }

            for (DMT_Opportunity_Client__c client : clients) {
                if (mainCustomerId.equals(client.Alpha_Code_Client__c)) {
                    return new List<DMT_Opportunity_Client__c>{ client };
                }
            }

            // Main Borrower could not be matched among the opportunity clients: fall back so the
            // table is never left empty because of a data inconsistency.
            return clients;
    }

    /**
     * @description Returns the customer code (Alpha Code) of the opportunity's Main Borrower.
     * The Main Borrower is flagged on the multiholder Custom Association Opportunity record via
     * the g_customer_id__c field, which matches the Alpha_Code_Client__c of one Opportunity Client.
     * @param opportunityId Id of the Opportunity
     * @return the Main Borrower customer code, or null when no Custom Association is mapped
     */
    private static String getMainBorrowerCustomerId(Id opportunityId) {
            List<Custom_Association_Opportunity__c> associations = [
                    SELECT g_customer_id__c
                    FROM Custom_Association_Opportunity__c
                    WHERE Opportunity__c =: opportunityId
                        AND g_customer_id__c != null
                    WITH USER_MODE
                    ORDER BY CreatedDate
                    LIMIT 1
                    ];
            return associations.isEmpty() ? null : associations[0].g_customer_id__c;
    }

    @AuraEnabled(cacheable=false)
    public static List<Opportunity> getAccountFields(String recordId) {
            return [
                    SELECT 
                        Account.Revenues_Last_Year_number__c, 
                        Account.Revenues_Current_Year_number__c, 
                        Account.Revenues_Next_Year_number__c, 
                        Account.Revenues_Next_Year_1_number__c, 
                        Account.Revenues_Next_Year_2_number__c, 
                        Account.EBITDA_Last_Year_number__c, 
                        Account.EBITDA_Current_Year_number__c, 
                        Account.EBITDA_Next_Year_number__c, 
                        Account.EBITDA_Next_Year_1_number__c, 
                        Account.EBITDA_Next_Year_2_number__c,
                        Account.EBIT_Last_Year_number__c,
                        Account.EBIT_Current_Year_number__c,
                        Account.EBIT_Next_Year_number__c,
                        Account.EBIT_Next_Year_1_number__c,
                        Account.EBIT_Next_Year_2_number__c,                       
                        Account.Net_Income_Last_Year_number__c,
                        Account.Net_Income_Current_Year_number__c,
                        Account.Net_Income_Next_Year_number__c,
                        Account.Net_Income_Next_Year_1_number__c,
                        Account.Net_Income_Next_Year_2_number__c,
                        Account.Free_Cash_Flow_Last_Year_number__c,
                        Account.Free_Cash_Flow_Current_Year_number__c,
                        Account.Free_Cash_Flow_Next_Year_number__c,
                        Account.Free_Cash_Flow_Next_Year_1_number__c,
                        Account.Free_Cash_Flow_Next_Year_2_number__c,
                        Account.Debt_EBITDA_Last_Year_number__c,
                        Account.Debt_EBITDA_Current_Year_number__c,
                        Account.Debt_EBITDA_Next_Year_number__c,
                        Account.Debt_EBITDA_Next_Year_1_number__c,
                        Account.Debt_EBITDA_Next_Year_2_number__c,
                        Account.Net_Debt_EBITDA_Last_Year_number__c,
                        Account.Net_Debt_EBITDA_Current_Year_number__c,
                        Account.Net_Debt_EBITDA_Next_Year_number__c,
                        Account.Net_Debt_EBITDA_Next_Year_1_number__c,
                        Account.Net_Debt_EBITDA_Next_Year_2_number__c
                    FROM Opportunity 
                    WHERE Id =: recordId
                    WITH USER_MODE
                    ];
    }
}