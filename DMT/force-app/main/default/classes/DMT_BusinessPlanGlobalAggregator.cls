public with sharing class DMT_BusinessPlanGlobalAggregator {

    /**
     * Builds synthetic, never-inserted GLOBAL DMT_Opportunity_Business_Plan__c records (one per
     * year found among the non-GLOBAL records) by summing each of apiFields across all non-GLOBAL
     * geography records for that year. Mirrors dmt_business_plan_table_geography.js's
     * _buildGlobalAggregatedRows(), so the GLOBAL table in HTML renderers always matches what the
     * live Business Plan Data tab shows, instead of relying on the separately persisted GLOBAL
     * record, which is only refreshed when a user saves through that tab.
     */
    public static List<DMT_Opportunity_Business_Plan__c> buildAggregatedGlobalRecords(
        List<DMT_Opportunity_Business_Plan__c> allRecords,
        List<String> apiFields
    ) {
        Map<String, DMT_Opportunity_Business_Plan__c> aggregatedByYear = new Map<String, DMT_Opportunity_Business_Plan__c>();
        Map<String, Map<String, Decimal>> sumsByYear = new Map<String, Map<String, Decimal>>();

        if (allRecords == null) {
            return new List<DMT_Opportunity_Business_Plan__c>();
        }

        for (DMT_Opportunity_Business_Plan__c rec : allRecords) {
            // A blank geography is treated as an existing GLOBAL entry (same convention as
            // groupByGeography() in the renderers), not as a distinct geography to sum.
            String geo = String.isBlank(rec.DMT_Booking_Geography__c) ? 'GLOBAL' : rec.DMT_Booking_Geography__c;
            if (geo == 'GLOBAL' || String.isBlank(rec.DMT_Year__c)) {
                continue;
            }

            Map<String, Decimal> sums = sumsByYear.get(rec.DMT_Year__c);
            if (sums == null) {
                sums = new Map<String, Decimal>();
                sumsByYear.put(rec.DMT_Year__c, sums);
                aggregatedByYear.put(rec.DMT_Year__c, new DMT_Opportunity_Business_Plan__c(
                    DMT_Booking_Geography__c = 'GLOBAL',
                    DMT_Year__c = rec.DMT_Year__c
                ));
            }

            for (String field : apiFields) {
                Object rawVal = rec.get(field);
                if (rawVal == null) {
                    continue;
                }
                Decimal num = (Decimal) rawVal;
                sums.put(field, (sums.containsKey(field) ? sums.get(field) : 0) + num);
            }
        }

        for (String year : aggregatedByYear.keySet()) {
            DMT_Opportunity_Business_Plan__c agg = aggregatedByYear.get(year);
            Map<String, Decimal> sums = sumsByYear.get(year);
            for (String field : apiFields) {
                if (sums.containsKey(field)) {
                    agg.put(field, sums.get(field));
                }
            }
        }

        return aggregatedByYear.values();
    }

    /**
     * Sums the given X-Sell component fields (ECM, M&A, DCM, Credit/Equity, FX/CCS, Cash
     * Management, Client Resources, Securities Services) on a single record, mirroring
     * dmt_business_plan_table_geography.js's transformApexData() override of the "Total X-Sell"
     * row. The LWC never trusts a geography's own stored Current_FY_Total_X_Sell_amount__c field
     * (its code comment notes it's "often null in DB"); it always recomputes the total live from
     * the component rows instead. Returns null (not 0) when every component is null, so display
     * stays "N/A" rather than a misleading zero.
     */
    public static Decimal computeXSellTotal(DMT_Opportunity_Business_Plan__c rec, List<String> xSellFields) {
        if (rec == null) {
            return null;
        }
        Decimal total = null;
        for (String field : xSellFields) {
            Object rawVal = rec.get(field);
            if (rawVal == null) {
                continue;
            }
            total = (total == null ? 0 : total) + (Decimal) rawVal;
        }
        return total;
    }
}