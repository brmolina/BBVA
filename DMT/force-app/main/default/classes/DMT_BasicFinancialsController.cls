public with sharing class DMT_BasicFinancialsController {

    @AuraEnabled(cacheable=false)
    public static List<DMT_Opportunity_Client__c> getFinancials(String recordId) {
            return [
                    SELECT
                        Id,
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
                    ];
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