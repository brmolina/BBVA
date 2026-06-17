public with sharing class FundItemTriggerHandler {

    private static final String DVP_VALUE = 'DVP';
    private static final String FREE_DELIVERY_VALUE = 'Free Delivery';
    private static final Decimal DEFAULT_SETTLEMENT_LINE_LIMIT = 500000;

    public static void afterInsert(List<ONB_Fund_Item__c> newFundItems) {
        if (newFundItems == null || newFundItems.isEmpty()) return;

        Set<Id> fundItemIds = new Set<Id>();
        for (ONB_Fund_Item__c fi : newFundItems) {
            if (fi.Id != null) fundItemIds.add(fi.Id);
        }
        if (fundItemIds.isEmpty()) return;

        Set<String> existingFundSubtypeKeys = new Set<String>();
        for (ONB_Line__c ln : [
            SELECT Id, FundItemId__c, ONB_Line_Subtype__c
            FROM ONB_Line__c
            WHERE FundItemId__c IN :fundItemIds
            AND ONB_Line_Subtype__c IN :new Set<String>{ DVP_VALUE, FREE_DELIVERY_VALUE }
        ]) {
            if (ln.FundItemId__c != null && ln.ONB_Line_Subtype__c != null) {
                existingFundSubtypeKeys.add(String.valueOf(ln.FundItemId__c) + '|' + ln.ONB_Line_Subtype__c);
            }
        }

        List<ONB_Line__c> toInsert = new List<ONB_Line__c>();
        for (ONB_Fund_Item__c fi : newFundItems) {
            if (fi.Id == null) continue;

            String dvpKey = String.valueOf(fi.Id) + '|' + DVP_VALUE;
            if (!existingFundSubtypeKeys.contains(dvpKey)) {
                ONB_Line__c dvpLine = new ONB_Line__c();
                dvpLine.FundItemId__c = fi.Id;
                dvpLine.Line_Type__c = 'LC_DVP';
                dvpLine.ONB_Line_Subtype__c = DVP_VALUE;
                dvpLine.ONB_Settlement_line_limit__c = DEFAULT_SETTLEMENT_LINE_LIMIT;
                toInsert.add(dvpLine);
            }

            String freeDeliveryKey = String.valueOf(fi.Id) + '|' + FREE_DELIVERY_VALUE;
            if (!existingFundSubtypeKeys.contains(freeDeliveryKey)) {
                ONB_Line__c freeDeliveryLine = new ONB_Line__c();
                freeDeliveryLine.FundItemId__c = fi.Id;
                freeDeliveryLine.Line_Type__c = 'LC_DVP';
                freeDeliveryLine.ONB_Line_Subtype__c = FREE_DELIVERY_VALUE;
                freeDeliveryLine.ONB_Settlement_line_limit__c = DEFAULT_SETTLEMENT_LINE_LIMIT;
                freeDeliveryLine.IsAutomatic__c = true;
                toInsert.add(freeDeliveryLine);
            }
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }

    public static void beforeDelete(List<ONB_Fund_Item__c> fundItemsToDelete) {
        if (fundItemsToDelete == null || fundItemsToDelete.isEmpty()) return;

        Set<Id> fundItemIds = new Set<Id>();
        for (ONB_Fund_Item__c fi : fundItemsToDelete) {
            if (fi.Id != null) fundItemIds.add(fi.Id);
        }

        if (fundItemIds.isEmpty()) return;

        // Get all lines associated with the funds being deleted
        List<ONB_Line__c> linesToDelete = [
            SELECT Id
            FROM ONB_Line__c
            WHERE FundItemId__c IN :fundItemIds
        ];

        // Delete the lines
        if (!linesToDelete.isEmpty()) {
            delete linesToDelete;
        }
    }
}