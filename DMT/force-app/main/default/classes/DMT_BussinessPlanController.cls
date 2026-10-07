public with sharing class DMT_BussinessPlanController {
    @AuraEnabled(cacheable=false)
    public static List<DMT_Opportunity_Business_Plan__c> getBussinessPlan(String recordId, String bookingGeography) {
            return [
                    SELECT 
                        Current_FY_Corp_Synd_Lending_amount__c,
                        Current_FY_Structured_Finance_amount__c,
                        Current_FY_Str_Trade_Finance_amount__c,
                        Current_FY_Rates_amount__c,
                        Current_FY_GTF_amount__c,
                        Current_FY_Working_Capital_amount__c,
                        Current_FY_Total_Non_X_Sell_amount__c,
                        Current_FY_ECM_M_A_Amount__c,
                        Current_FY_M_A_amount__c,
                        Current_FY_DCM_amount__c,
                        Current_FY_Credit_Equity_amount__c,
                        Current_FY_FX_CCS_amount__c,
                        Current_FY_Cash_Management_amount__c,
                        Current_FY_Client_Resources_amount__c,
                        Current_FY_Securities_Services_amount__c,
                        Current_FY_Total_X_Sell_amount__c,
                        Current_FY_Child_X_Sell_amount__c,
                        Current_FY_Total_Revenues_amount__c,
                        gf_xb_cust_ope_revenue_2ya_per__c,
                        gf_xb_cust_ope_revenue_ly_per__c,
                        gf_xb_cust_ope_revenue_cyr_per__c,
                        gf_xb_cust_ope_revenue_nxy_per__c,
                        gf_kpi_trans_fees_2ya_amount__c,
                        gf_kpi_trans_fees_ly_amount__c,
                        gf_kpi_trans_fees_cyr_amount__c,
                        gf_kpi_trans_fees_nxy_amount__c,
                        DMT_Booking_Geography__c,
                        DMT_Year__c,
                        DMT_QAOTER__c,
                        DMT_Currency__c,
                        DMT_Xsell_Cost_to_Income__c,
                        DMT_Opportunity__r.AccountId,
                        DMT_Active__c
                    FROM DMT_Opportunity_Business_Plan__c 
                    WHERE DMT_Opportunity__c =: recordId
                    WITH USER_MODE
                    ];
    }   


    /**
     * Returns DMT_Opportunity_Business_Plan__c records linked to an Account (DMT_Client__c).
     * Use when the caller has an Account Id instead of an Opportunity Id.
     */
    @AuraEnabled(cacheable=false)
    public static List<DMT_Opportunity_Business_Plan__c> getBussinessPlanByClient(String clientId) {
            return [
                    SELECT 
                        Current_FY_Corp_Synd_Lending_amount__c,
                        Current_FY_Structured_Finance_amount__c,
                        Current_FY_Str_Trade_Finance_amount__c,
                        Current_FY_Rates_amount__c,
                        Current_FY_GTF_amount__c,
                        Current_FY_Working_Capital_amount__c,
                        Current_FY_Total_Non_X_Sell_amount__c,
                        Current_FY_ECM_M_A_Amount__c,
                        Current_FY_M_A_amount__c,
                        Current_FY_DCM_amount__c,
                        Current_FY_Credit_Equity_amount__c,
                        Current_FY_FX_CCS_amount__c,
                        Current_FY_Cash_Management_amount__c,
                        Current_FY_Client_Resources_amount__c,
                        Current_FY_Securities_Services_amount__c,
                        Current_FY_Total_X_Sell_amount__c,
                        Current_FY_Child_X_Sell_amount__c,
                        Current_FY_Total_Revenues_amount__c,
                        gf_xb_cust_ope_revenue_2ya_per__c,
                        gf_xb_cust_ope_revenue_ly_per__c,
                        gf_xb_cust_ope_revenue_cyr_per__c,
                        gf_xb_cust_ope_revenue_nxy_per__c,
                        gf_kpi_trans_fees_2ya_amount__c,
                        gf_kpi_trans_fees_ly_amount__c,
                        gf_kpi_trans_fees_cyr_amount__c,
                        gf_kpi_trans_fees_nxy_amount__c,
                        DMT_Booking_Geography__c,
                        DMT_Year__c,
                        DMT_QAOTER__c,
                        DMT_Currency__c,
                        DMT_Xsell_Cost_to_Income__c,
                        DMT_Active__c
                    FROM DMT_Opportunity_Business_Plan__c 
                    WHERE DMT_Client__c =: clientId
                    WITH USER_MODE
                    ];
    }

    /**
     * Searches Account records of RecordType "Group" to feed the Group selector used by
     * "Retrieve another Group's table". Uses SOSL instead of a SOQL LIKE filter because
     * Account.Name is Shield-encrypted and LIKE is not supported on encrypted fields.
     */
    @AuraEnabled
    public static List<Map<String, Object>> searchGroups(String searchTerm) {
        if (String.isBlank(searchTerm) || searchTerm.trim().length() < 2) {
            return new List<Map<String, Object>>();
        }

        String safeTerm = searchTerm.trim().replaceAll('[^\\w\\s]', '').trim();
        if (String.isBlank(safeTerm)) {
            return new List<Map<String, Object>>();
        }

        String sosl =
            'FIND {' + safeTerm + '*} IN ALL FIELDS ' +
            'RETURNING Account(' +
            'Id, Name ' +
            'WHERE RecordType.DeveloperName = \'Group\'' +
            ') LIMIT 50';

        List<Account> accounts = (List<Account>) Search.query(sosl)[0];

        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (Account acc : accounts) {
            result.add(new Map<String, Object>{
                'label' => acc.Name,
                'value' => String.valueOf(acc.Id)
            });
        }
        return result;
    }

    @AuraEnabled(cacheable=false)
    public static List<Opportunity> getAccountFields(String recordId) {
            return [
                    SELECT 
                        Account.Current_FY_Corp_Synd_Lending_amount__c,
                        Account.Current_FY_Structured_Finance_amount__c,
                        Account.Current_FY_Str_Trade_Finance_amount__c,
                        Account.Current_FY_Rates_amount__c,
                        Account.Current_FY_GTF_amount__c,
                        Account.Current_FY_Working_Capital_amount__c,
                        Account.Current_FY_Total_Non_X_Sell_amount__c,
                        Account.Current_FY_ECM_M_A_Amount__c,
                        Account.Current_FY_DCM_amount__c,
                        Account.Current_FY_Credit_Equity_amount__c,
                        Account.Current_FY_FX_CCS_amount__c,
                        Account.Current_FY_Cash_Management_amount__c,
                        Account.Current_FY_Client_Resources_amount__c,
                        Account.Current_FY_Securities_Services_amount__c,
                        Account.Current_FY_Total_X_Sell_amount__c,
                        Account.Current_FY_Total_Revenues_amount__c,
                        Account.gf_xb_cust_ope_revenue_2ya_per__c,
                        Account.gf_xb_cust_ope_revenue_ly_per__c,
                        Account.gf_xb_cust_ope_revenue_cyr_per__c,
                        Account.gf_xb_cust_ope_revenue_nxy_per__c,
                        Account.gf_kpi_trans_fees_2ya_amount__c,
                        Account.gf_kpi_trans_fees_ly_amount__c,
                        Account.gf_kpi_trans_fees_cyr_amount__c,
                        Account.gf_kpi_trans_fees_nxy_amount__c
                    FROM Opportunity 
                    WHERE Id =: recordId 
                    WITH USER_MODE
                    ];
    }
}