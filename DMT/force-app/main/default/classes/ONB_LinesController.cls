public with sharing class ONB_LinesController {
    @AuraEnabled(cacheable=true)
    public static List<ONB_Line__c> getLinesByOnboardingId(Id onboardingId, Id fundId) {
        if (onboardingId == null) {
            return new List<ONB_Line__c>();
        }

        if (fundId != null) {
            return [
                SELECT Id, Line_Type__c, ONB_Line_Subtype__c, ONB_Settlement_line_limit__c, ONB_Maturity__c,
                       ONB_Credit_line_limit__c, ONB_Repos_line_limit__c, CurrencyIsoCode, OnboardingId__c
                FROM ONB_Line__c
                WHERE FundItemId__c = :fundId
                ORDER BY CreatedDate DESC
            ];
        }

        return [
            SELECT Id, Line_Type__c, ONB_Line_Subtype__c, ONB_Settlement_line_limit__c, ONB_Maturity__c,
                   ONB_Credit_line_limit__c, ONB_Repos_line_limit__c, CurrencyIsoCode, OnboardingId__c
            FROM ONB_Line__c
            WHERE OnboardingId__c = :onboardingId
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Boolean hasRepoProduct(Id onboardingId) {
        if (onboardingId == null) {
            return false;
        }

        List<ONB_Onboarding_Line__c> repoLines = [
            SELECT Id
            FROM ONB_Onboarding_Line__c
            WHERE OnboardingId__c = :onboardingId
              AND Product2Id__r.ProductCode = 'ONB_REPO_REVERSE_REPO'
            LIMIT 1
        ];

        return !repoLines.isEmpty();
    }
}