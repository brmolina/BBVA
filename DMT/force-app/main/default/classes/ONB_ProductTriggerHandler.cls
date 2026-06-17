public with sharing class ONB_ProductTriggerHandler {

    public static void handleAfter(
        List<ONB_Onboarding_Line__c> newList,
        Map<Id, ONB_Onboarding_Line__c> oldMap,
        Boolean isInsert,
        Boolean isUpdate,
        Boolean isDelete,
        Boolean isUndelete
    ) {
        Set<Id> fundIdsToRecalculate = new Set<Id>();

        if (isInsert || isUndelete) {
            for (ONB_Onboarding_Line__c row : newList) {
                if (row.FundItemId__c != null) {
                    fundIdsToRecalculate.add(row.FundItemId__c);
                }
            }
        }

        if (isDelete) {
            for (ONB_Onboarding_Line__c row : oldMap.values()) {
                if (row.FundItemId__c != null) {
                    fundIdsToRecalculate.add(row.FundItemId__c);
                }
            }
        }

        if (isUpdate) {
            for (ONB_Onboarding_Line__c newRow : newList) {
                ONB_Onboarding_Line__c oldRow = oldMap.get(newRow.Id);

                Boolean productChanged = newRow.Product2Id__c != oldRow.Product2Id__c;
                Boolean fundChanged = newRow.FundItemId__c != oldRow.FundItemId__c;

                if (productChanged || fundChanged) {
                    if (oldRow.FundItemId__c != null) {
                        fundIdsToRecalculate.add(oldRow.FundItemId__c);
                    }
                    if (newRow.FundItemId__c != null) {
                        fundIdsToRecalculate.add(newRow.FundItemId__c);
                    }
                }
            }
        }

        if (!fundIdsToRecalculate.isEmpty()) {
            ONB_FundLineRestrictionService.recalculateForFunds(fundIdsToRecalculate);
        }
    }
}