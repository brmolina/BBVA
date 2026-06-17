public with sharing class ONB_FundLineRestrictionService {

    private static Boolean isRunning = false;

    private static final String PRODUCT_FX_SPOT = 'FX Spot';
    private static final String PRODUCT_BONDS = 'Bonds';
    private static final String PRODUCT_REPO = 'Repo/Reverse Repo';

    private static final String LINE_TYPE_CREDIT = 'LC_CRED';
    private static final String LINE_TYPE_REPO_NOTIONAL = 'LC_REPOS';

    public static void recalculateForFunds(Set<Id> fundIds) {
        if (isRunning || fundIds == null || fundIds.isEmpty()) {
            return;
        }

        isRunning = true;
        try {
            Map<Id, FundProductFlags> flagsByFundId = buildFundFlags(fundIds);
            deleteInvalidLines(fundIds, flagsByFundId);
        } finally {
            isRunning = false;
        }
    }

    private static Map<Id, FundProductFlags> buildFundFlags(Set<Id> fundIds) {
        Map<Id, FundProductFlags> result = new Map<Id, FundProductFlags>();

        for (Id fundId : fundIds) {
            result.put(fundId, new FundProductFlags());
        }

        for (ONB_Onboarding_Line__c row : [
            SELECT Id, FundItemId__c, Product2Id__c, Product2Id__r.Name
            FROM ONB_Onboarding_Line__c
            WHERE FundItemId__c IN :fundIds
            AND Product2Id__c != null
        ]) {
            if (row.FundItemId__c == null) {
                continue;
            }

            FundProductFlags flags = result.get(row.FundItemId__c);
            if (flags == null) {
                flags = new FundProductFlags();
                result.put(row.FundItemId__c, flags);
            }

            String productName = row.Product2Id__r != null ? row.Product2Id__r.Name : null;

            if (productName == PRODUCT_FX_SPOT || productName == PRODUCT_BONDS) {
                flags.hasFxSpotOrBonds = true;
            }

            if (productName == PRODUCT_REPO) {
                flags.hasRepo = true;
            }
        }

        return result;
    }

    private static void deleteInvalidLines(Set<Id> fundIds, Map<Id, FundProductFlags> flagsByFundId) {
        List<ONB_Line__c> linesToDelete = new List<ONB_Line__c>();

        for (ONB_Line__c line : [
            SELECT Id, FundItemId__c, Line_Type__c
            FROM ONB_Line__c
            WHERE FundItemId__c IN :fundIds
            AND Line_Type__c IN :new Set<String>{ LINE_TYPE_CREDIT, LINE_TYPE_REPO_NOTIONAL }
        ]) {
            FundProductFlags flags = flagsByFundId.get(line.FundItemId__c);
            if (flags == null) {
                flags = new FundProductFlags();
            }

            Boolean deleteLine = false;

            if (line.Line_Type__c == LINE_TYPE_CREDIT && flags.hasFxSpotOrBonds) {
                deleteLine = true;
            }

            if (line.Line_Type__c == LINE_TYPE_REPO_NOTIONAL && !flags.hasRepo) {
                deleteLine = true;
            }

            if (deleteLine) {
                linesToDelete.add(line);
            }
        }

        if (!linesToDelete.isEmpty()) {
            delete linesToDelete;
        }
    }

    private class FundProductFlags {
        public Boolean hasFxSpotOrBonds = false;
        public Boolean hasRepo = false;
    }
}