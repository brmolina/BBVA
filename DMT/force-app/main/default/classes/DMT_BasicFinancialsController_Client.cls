public with sharing class DMT_BasicFinancialsController_Client {
 @AuraEnabled(cacheable=false)
    public static List<Account> getFinancials(String recordId) {
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
                        Net_Debt_EBITDA_Next_Year_2_number__c
                    FROM Account 
                    WHERE Id =: recordId
                    WITH USER_MODE
                    ];
    }
}