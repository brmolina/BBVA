public with sharing class DMT_NBC_ProfitabilityHelper {

    /**
     * Convenience method: extracts the summary row and returns the formatted All-in display in one call.
     * @param featuresList List<Map<String, Object>> from LineDataWrapper.featuresList.
     * @param withBps      When true, appends ' bps' suffix to each value.
     * @return Formatted "drawn | undrawn" string, or empty string if no data is available.
     */
    public static String getOpportunityAllInDisplay(List<Map<String, Object>> featuresList, Boolean withBps) {
        Map<String, Object> summary = getOpportunitySummaryRow(featuresList);
        return formatAllInSummary(summary, withBps);
    }

    // ====================================================================================================
    // OPPORTUNITY SUMMARY ROW
    // ====================================================================================================

    /**
     * Returns the Opportunity-level summary row from profitability results.
     * The summary row is identified by the absence of a 'productId' value (null or missing).
     * @param featuresList List<Map<String, Object>> from LineDataWrapper.featuresList.
     * @return The summary row map, or null if not found.
     */
    public static Map<String, Object> getOpportunitySummaryRow(List<Map<String, Object>> featuresList) {
        Map<String, Object> feature = getProfitabilityFeature(featuresList);
        if (feature.isEmpty() || !feature.containsKey('profitability')) {
            return null;
        }

        Map<String, Object> profitability = (Map<String, Object>) feature.get('profitability');
        if (profitability == null || !profitability.containsKey('results')) {
            return null;
        }

        List<Object> results = (List<Object>) profitability.get('results');
        if (results == null || results.isEmpty()) {
            return null;
        }

        for (Object rec : results) {
            Map<String, Object> row = (Map<String, Object>) rec;
            if (!row.containsKey('productId') || row.get('productId') == null) {
                return row;
            }
        }
        return null;
    }

    // ====================================================================================================
    // PROFITABILITY FEATURE EXTRACTION
    // ====================================================================================================

    /**
     * Extracts the first feature map containing a 'profitability' key from featuresList.
     * @param featuresList List<Map<String, Object>> from LineDataWrapper.featuresList.
     * @return The matching feature map, or an empty map if not found.
     */
    public static Map<String, Object> getProfitabilityFeature(List<Map<String, Object>> featuresList) {
        if (featuresList == null || featuresList.isEmpty()) {
            return new Map<String, Object>();
        }
        for (Map<String, Object> feature : featuresList) {
            if (feature != null && feature.containsKey('profitability')) {
                return feature;
            }
        }
        return new Map<String, Object>();
    }

    // ====================================================================================================
    // ALL-IN DISPLAY FORMATTING
    // ====================================================================================================

    /**
     * Formats allInDb and allInFb from a summary row into a "Drawn | Undrawn" display string.
     * @param summaryRow The Opportunity summary row extracted from profitability results.
     * @param withBps    When true, appends ' bps' suffix to each value.
     * @return Formatted "drawn | undrawn" string, or empty string if both values are absent.
     */
    public static String formatAllInSummary(Map<String, Object> summaryRow, Boolean withBps) {
        if (summaryRow == null) {
            return '';
        }
        String drawn   = formatBpsValue(summaryRow.get('allInDb'), withBps);
        String undrawn = formatBpsValue(summaryRow.get('allInFb'), withBps);

        if (String.isBlank(drawn) && String.isBlank(undrawn)) {
            return '';
        }
        return drawn + ' | ' + undrawn;
    }

    // ====================================================================================================
    // PRIVATE HELPERS
    // ====================================================================================================

    private static String formatBpsValue(Object value, Boolean withBps) {
        Decimal decValue = toDecimal(value);
        if (decValue == null) {
            return '';
        }
        String formatted = String.valueOf(decValue.setScale(0, RoundingMode.HALF_UP));
        return (withBps == true) ? formatted + ' bps' : formatted;
    }

    private static Decimal toDecimal(Object value) {
        if (value == null) {
            return null;
        }
        try {
            return Decimal.valueOf(String.valueOf(value));
        } catch (Exception e) {
            return null;
        }
    }
}