/**
 * @description Controller for the new Financials table model.
 * Financials data lives on DMT_Opportunity_Business_Plan__c records (one per year),
 * using DMT_Year__c to identify the year. Records are filtered by
 * DMT_Opportunity__c (Opportunity case) or DMT_Client__c (Account/FlexCard case).
 * For Opportunity, only GLOBAL records hold financial data.
 * Save operations reuse DMT_ApprovalDataController.saveApprovalData (upsertBusinessPlans).
 */
public with sharing class DMT_FinancialsNewController {

    private static final String FINANCIAL_FIELDS =
        'Id, DMT_Year__c, DMT_Booking_Geography__c, ' +
        'DMT_Revenues_number__c, DMT_EBITDA_number__c, DMT_EBIT_number__c, ' +
        'DMT_Net_Income_number__c, DMT_Free_Cash_Flow_number__c, ' +
        'DMT_Debt_EBITDA_number__c, DMT_Net_Debt_EBITDA_number__c';

    /**
     * Returns financial records for an Opportunity.
     * Only GLOBAL geography records carry financial data for the Opportunity context.
     */
    @AuraEnabled(cacheable=false)
    public static List<DMT_Opportunity_Business_Plan__c> getFinancialsByOpportunity(String recordId) {
        return [
            SELECT Id, DMT_Year__c, DMT_Booking_Geography__c,
                   DMT_Revenues_number__c, DMT_EBITDA_number__c, DMT_EBIT_number__c,
                   DMT_Net_Income_number__c, DMT_Free_Cash_Flow_number__c,
                   DMT_Debt_EBITDA_number__c, DMT_Net_Debt_EBITDA_number__c,
                   DMT_Opportunity__r.AccountId
            FROM DMT_Opportunity_Business_Plan__c
            WHERE DMT_Opportunity__c = :recordId
              AND DMT_Booking_Geography__c = 'GLOBAL'
            WITH USER_MODE
        ];
    }

    /**
     * Returns financial records for an Account (FlexCard / Client case).
     * Account records are stored with DMT_Client__c lookup.
     */
    @AuraEnabled(cacheable=false)
    public static List<DMT_Opportunity_Business_Plan__c> getFinancialsByClient(String clientId) {
        return [
            SELECT Id, DMT_Year__c, DMT_Booking_Geography__c,
                   DMT_Revenues_number__c, DMT_EBITDA_number__c, DMT_EBIT_number__c,
                   DMT_Net_Income_number__c, DMT_Free_Cash_Flow_number__c,
                   DMT_Debt_EBITDA_number__c, DMT_Net_Debt_EBITDA_number__c
            FROM DMT_Opportunity_Business_Plan__c
            WHERE DMT_Client__c = :clientId
              AND DMT_Booking_Geography__c = 'GLOBAL'
            WITH USER_MODE
        ];
    }

    /**
     * Returns Account-level financial records for comparison (Redo).
     * Queries records linked to the Account via DMT_Client__c.
     */
    @AuraEnabled(cacheable=false)
    public static List<DMT_Opportunity_Business_Plan__c> getFinancialsAccountComparison(String accountId) {
        return [
            SELECT Id, DMT_Year__c, DMT_Booking_Geography__c,
                   DMT_Revenues_number__c, DMT_EBITDA_number__c, DMT_EBIT_number__c,
                   DMT_Net_Income_number__c, DMT_Free_Cash_Flow_number__c,
                   DMT_Debt_EBITDA_number__c, DMT_Net_Debt_EBITDA_number__c
            FROM DMT_Opportunity_Business_Plan__c
            WHERE DMT_Client__c = :accountId
              AND DMT_Booking_Geography__c = 'GLOBAL'
            WITH USER_MODE
        ];
    }

    /**
     * Upserts financial records. Accepts a JSON array of DMT_Opportunity_Business_Plan__c
     * objects with only financial fields + context fields (Id or Year+Opportunity/Client).
     */
    @AuraEnabled
    public static void saveFinancials(String financialsJson) {
        if (String.isBlank(financialsJson)) return;
        List<DMT_Opportunity_Business_Plan__c> records =
            (List<DMT_Opportunity_Business_Plan__c>) JSON.deserialize(
                financialsJson, List<DMT_Opportunity_Business_Plan__c>.class
            );
        if (!records.isEmpty()) {
            Database.upsert(records, AccessLevel.USER_MODE);
        }
    }
}