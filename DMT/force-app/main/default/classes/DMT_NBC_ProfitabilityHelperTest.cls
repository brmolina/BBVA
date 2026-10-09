@IsTest
private with sharing class DMT_NBC_ProfitabilityHelperTest {

    // ====================================================================================================
    // HELPERS
    // ====================================================================================================

    /**
     * Builds a featuresList with a 'profitability' entry containing the given results rows.
     */
    private static List<Map<String, Object>> buildFeaturesList(List<Map<String, Object>> results) {
        List<Object> resultObjects = new List<Object>();
        for (Map<String, Object> row : results) {
            resultObjects.add(row);
        }
        Map<String, Object> profitability = new Map<String, Object>{
            'results' => resultObjects
        };
        Map<String, Object> feature = new Map<String, Object>{
            'profitability' => profitability
        };
        return new List<Map<String, Object>>{ feature };
    }

    private static Map<String, Object> summaryRow(Object allInDb, Object allInFb) {
        Map<String, Object> row = new Map<String, Object>();
        row.put('allInDb', allInDb);
        row.put('allInFb', allInFb);
        return row;
    }

    private static Map<String, Object> productRow(String productId, Object allInDb, Object allInFb) {
        Map<String, Object> row = summaryRow(allInDb, allInFb);
        row.put('productId', productId);
        return row;
    }

    // ====================================================================================================
    // getProfitabilityFeature
    // ====================================================================================================

    @IsTest
    static void getProfitabilityFeature_nullList_returnsEmptyMap() {
        Map<String, Object> result = DMT_NBC_ProfitabilityHelper.getProfitabilityFeature(null);
        System.assert(result.isEmpty(), 'Expected empty map for null list');
    }

    @IsTest
    static void getProfitabilityFeature_emptyList_returnsEmptyMap() {
        Map<String, Object> result = DMT_NBC_ProfitabilityHelper.getProfitabilityFeature(
            new List<Map<String, Object>>()
        );
        System.assert(result.isEmpty(), 'Expected empty map for empty list');
    }

    @IsTest
    static void getProfitabilityFeature_noMatchingKey_returnsEmptyMap() {
        List<Map<String, Object>> featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'someOtherKey' => 'value' }
        };
        Map<String, Object> result = DMT_NBC_ProfitabilityHelper.getProfitabilityFeature(featuresList);
        System.assert(result.isEmpty(), 'Expected empty map when no profitability key present');
    }

    @IsTest
    static void getProfitabilityFeature_withProfitabilityKey_returnsFeature() {
        Map<String, Object> profFeature = new Map<String, Object>{
            'profitability' => new Map<String, Object>{ 'results' => new List<Object>() }
        };
        List<Map<String, Object>> featuresList = new List<Map<String, Object>>{ profFeature };

        Map<String, Object> result = DMT_NBC_ProfitabilityHelper.getProfitabilityFeature(featuresList);
        System.assert(result.containsKey('profitability'), 'Expected profitability key in result');
    }

    @IsTest
    static void getProfitabilityFeature_firstMatchReturned_skipsNonMatching() {
        Map<String, Object> other    = new Map<String, Object>{ 'other' => 1 };
        Map<String, Object> profFeat = new Map<String, Object>{ 'profitability' => 'data' };
        List<Map<String, Object>> featuresList = new List<Map<String, Object>>{ other, profFeat };

        Map<String, Object> result = DMT_NBC_ProfitabilityHelper.getProfitabilityFeature(featuresList);
        System.assert(result.containsKey('profitability'), 'Expected the profitability feature to be returned');
    }

    // ====================================================================================================
    // getOpportunitySummaryRow
    // ====================================================================================================

    @IsTest
    static void getOpportunitySummaryRow_nullList_returnsNull() {
        Map<String, Object> result = DMT_NBC_ProfitabilityHelper.getOpportunitySummaryRow(null);
        System.assertEquals(null, result, 'Expected null for null list');
    }

    @IsTest
    static void getOpportunitySummaryRow_noProfitabilityFeature_returnsNull() {
        List<Map<String, Object>> featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'other' => 'x' }
        };
        Map<String, Object> result = DMT_NBC_ProfitabilityHelper.getOpportunitySummaryRow(featuresList);
        System.assertEquals(null, result, 'Expected null when no profitability feature');
    }

    @IsTest
    static void getOpportunitySummaryRow_noResultsKey_returnsNull() {
        Map<String, Object> profitability = new Map<String, Object>{ 'otherKey' => 'x' };
        List<Map<String, Object>> featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'profitability' => profitability }
        };
        Map<String, Object> result = DMT_NBC_ProfitabilityHelper.getOpportunitySummaryRow(featuresList);
        System.assertEquals(null, result, 'Expected null when results key is absent');
    }

    @IsTest
    static void getOpportunitySummaryRow_emptyResults_returnsNull() {
        List<Map<String, Object>> featuresList = buildFeaturesList(new List<Map<String, Object>>());
        Map<String, Object> result = DMT_NBC_ProfitabilityHelper.getOpportunitySummaryRow(featuresList);
        System.assertEquals(null, result, 'Expected null for empty results list');
    }

    @IsTest
    static void getOpportunitySummaryRow_onlyProductRows_returnsNull() {
        List<Map<String, Object>> results = new List<Map<String, Object>>{
            productRow('prod-1', 100, 200),
            productRow('prod-2', 150, 250)
        };
        List<Map<String, Object>> featuresList = buildFeaturesList(results);
        Map<String, Object> result = DMT_NBC_ProfitabilityHelper.getOpportunitySummaryRow(featuresList);
        System.assertEquals(null, result, 'Expected null when all rows have a productId');
    }

    @IsTest
    static void getOpportunitySummaryRow_summaryRowPresentNoProductId_returnsSummary() {
        Map<String, Object> summary = summaryRow(120, 230);
        List<Map<String, Object>> results = new List<Map<String, Object>>{ summary };
        List<Map<String, Object>> featuresList = buildFeaturesList(results);

        Map<String, Object> result = DMT_NBC_ProfitabilityHelper.getOpportunitySummaryRow(featuresList);
        System.assertNotEquals(null, result, 'Expected summary row to be returned');
        System.assertEquals(120, result.get('allInDb'));
        System.assertEquals(230, result.get('allInFb'));
    }

    @IsTest
    static void getOpportunitySummaryRow_mixedRows_returnsSummaryOnly() {
        Map<String, Object> summary = summaryRow(50, 75);
        List<Map<String, Object>> results = new List<Map<String, Object>>{
            productRow('prod-1', 10, 20),
            summary,
            productRow('prod-2', 30, 40)
        };
        List<Map<String, Object>> featuresList = buildFeaturesList(results);

        Map<String, Object> result = DMT_NBC_ProfitabilityHelper.getOpportunitySummaryRow(featuresList);
        System.assertNotEquals(null, result);
        System.assertEquals(50, result.get('allInDb'));
    }

    @IsTest
    static void getOpportunitySummaryRow_productIdIsNull_treatedAsSummary() {
        Map<String, Object> row = summaryRow(99, 88);
        row.put('productId', null); // key present but value is null
        List<Map<String, Object>> featuresList = buildFeaturesList(
            new List<Map<String, Object>>{ row }
        );
        Map<String, Object> result = DMT_NBC_ProfitabilityHelper.getOpportunitySummaryRow(featuresList);
        System.assertNotEquals(null, result, 'Row with null productId should be treated as summary');
    }

    // ====================================================================================================
    // formatAllInSummary
    // ====================================================================================================

    @IsTest
    static void formatAllInSummary_nullRow_returnsEmptyString() {
        String result = DMT_NBC_ProfitabilityHelper.formatAllInSummary(null, false);
        System.assertEquals('', result);
    }

    @IsTest
    static void formatAllInSummary_bothValuesNull_returnsEmptyString() {
        Map<String, Object> row = summaryRow(null, null);
        String result = DMT_NBC_ProfitabilityHelper.formatAllInSummary(row, false);
        System.assertEquals('', result, 'Expected empty string when both values are null');
    }

    @IsTest
    static void formatAllInSummary_bothValuesPresent_withoutBps() {
        Map<String, Object> row = summaryRow(123.4, 456.7);
        String result = DMT_NBC_ProfitabilityHelper.formatAllInSummary(row, false);
        System.assertEquals('123 | 457', result);
    }

    @IsTest
    static void formatAllInSummary_bothValuesPresent_withBps() {
        Map<String, Object> row = summaryRow(123.4, 456.7);
        String result = DMT_NBC_ProfitabilityHelper.formatAllInSummary(row, true);
        System.assertEquals('123 bps | 457 bps', result);
    }

    @IsTest
    static void formatAllInSummary_onlyDrawnPresent() {
        Map<String, Object> row = summaryRow(300, null);
        String result = DMT_NBC_ProfitabilityHelper.formatAllInSummary(row, false);
        System.assertEquals('300 | ', result);
    }

    @IsTest
    static void formatAllInSummary_onlyUndrawnPresent() {
        Map<String, Object> row = summaryRow(null, 400);
        String result = DMT_NBC_ProfitabilityHelper.formatAllInSummary(row, false);
        System.assertEquals(' | 400', result);
    }

    @IsTest
    static void formatAllInSummary_integerValues_roundedCorrectly() {
        Map<String, Object> row = summaryRow(100, 200);
        String result = DMT_NBC_ProfitabilityHelper.formatAllInSummary(row, false);
        System.assertEquals('100 | 200', result);
    }

    @IsTest
    static void formatAllInSummary_decimalHalfUpRounding() {
        Map<String, Object> row = summaryRow(100.5, 200.5);
        String result = DMT_NBC_ProfitabilityHelper.formatAllInSummary(row, false);
        // HALF_UP: 100.5 -> 101, 200.5 -> 201
        System.assertEquals('101 | 201', result);
    }

    @IsTest
    static void formatAllInSummary_nonNumericValue_treatedAsBlank() {
        Map<String, Object> row = summaryRow('notANumber', 300);
        String result = DMT_NBC_ProfitabilityHelper.formatAllInSummary(row, false);
        System.assertEquals(' | 300', result);
    }

    @IsTest
    static void formatAllInSummary_stringNumericValue_parsedCorrectly() {
        Map<String, Object> row = summaryRow('150', '250');
        String result = DMT_NBC_ProfitabilityHelper.formatAllInSummary(row, false);
        System.assertEquals('150 | 250', result);
    }

    // ====================================================================================================
    // getOpportunityAllInDisplay (end-to-end)
    // ====================================================================================================

    @IsTest
    static void getOpportunityAllInDisplay_happyPath_withBps() {
        Map<String, Object> summary = summaryRow(125.3, 250.6);
        List<Map<String, Object>> featuresList = buildFeaturesList(
            new List<Map<String, Object>>{ summary }
        );
        String result = DMT_NBC_ProfitabilityHelper.getOpportunityAllInDisplay(featuresList, true);
        System.assertEquals('125 bps | 251 bps', result);
    }

    @IsTest
    static void getOpportunityAllInDisplay_happyPath_withoutBps() {
        Map<String, Object> summary = summaryRow(125.3, 250.6);
        List<Map<String, Object>> featuresList = buildFeaturesList(
            new List<Map<String, Object>>{ summary }
        );
        String result = DMT_NBC_ProfitabilityHelper.getOpportunityAllInDisplay(featuresList, false);
        System.assertEquals('125 | 251', result);
    }

    @IsTest
    static void getOpportunityAllInDisplay_noSummaryRow_returnsEmptyString() {
        List<Map<String, Object>> featuresList = buildFeaturesList(
            new List<Map<String, Object>>{ productRow('p1', 10, 20) }
        );
        String result = DMT_NBC_ProfitabilityHelper.getOpportunityAllInDisplay(featuresList, true);
        System.assertEquals('', result);
    }

    @IsTest
    static void getOpportunityAllInDisplay_nullList_returnsEmptyString() {
        String result = DMT_NBC_ProfitabilityHelper.getOpportunityAllInDisplay(null, false);
        System.assertEquals('', result);
    }
}