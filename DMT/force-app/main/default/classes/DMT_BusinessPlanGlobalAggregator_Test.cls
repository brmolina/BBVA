@IsTest
private class DMT_BusinessPlanGlobalAggregator_Test {

    private static final List<String> FIELDS = new List<String>{
        'Current_FY_Corp_Synd_Lending_amount__c',
        'Current_FY_Total_Non_X_Sell_amount__c'
    };

    private static final List<String> X_SELL_FIELDS = new List<String>{
        'Current_FY_ECM_M_A_Amount__c', 'Current_FY_M_A_amount__c', 'Current_FY_DCM_amount__c', 'Current_FY_Credit_Equity_amount__c',
        'Current_FY_FX_CCS_amount__c', 'Current_FY_Cash_Management_amount__c', 'Current_FY_Client_Resources_amount__c', 'Current_FY_Securities_Services_amount__c'
    };

    @IsTest
    static void testComputeXSellTotalNullRecordReturnsNull() {
        Assert.isNull(DMT_BusinessPlanGlobalAggregator.computeXSellTotal(null, X_SELL_FIELDS), 'A null record must yield a null total.');
    }

    @IsTest
    static void testComputeXSellTotalAllComponentsNullReturnsNull() {
        DMT_Opportunity_Business_Plan__c rec = new DMT_Opportunity_Business_Plan__c(DMT_Booking_Geography__c = 'ES', DMT_Year__c = '2026');
        Assert.isNull(DMT_BusinessPlanGlobalAggregator.computeXSellTotal(rec, X_SELL_FIELDS), 'All-null components must yield null, not 0.');
    }

    @IsTest
    static void testComputeXSellTotalIgnoresStoredTotalFieldAndSumsComponents() {
        DMT_Opportunity_Business_Plan__c rec = new DMT_Opportunity_Business_Plan__c(
            DMT_Booking_Geography__c = 'ES',
            DMT_Year__c = '2026',
            Current_FY_Total_X_Sell_amount__c = 999999, // stale/irrelevant — must be ignored
            Current_FY_M_A_amount__c = 40,
            Current_FY_DCM_amount__c = 10,
            Current_FY_Cash_Management_amount__c = 5
        );
        Decimal total = DMT_BusinessPlanGlobalAggregator.computeXSellTotal(rec, X_SELL_FIELDS);
        Assert.areEqual(55, total, 'Must sum only the component fields, ignoring the stored total field entirely.');
    }

    @IsTest
    static void testNullRecordsReturnsEmptyList() {
        List<DMT_Opportunity_Business_Plan__c> result = DMT_BusinessPlanGlobalAggregator.buildAggregatedGlobalRecords(null, FIELDS);
        Assert.isTrue(result.isEmpty(), 'Null input should yield an empty aggregated list.');
    }

    @IsTest
    static void testExistingGlobalRecordIsIgnoredAsSource() {
        List<DMT_Opportunity_Business_Plan__c> input = new List<DMT_Opportunity_Business_Plan__c>{
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'GLOBAL',
                DMT_Year__c = '2026',
                Current_FY_Corp_Synd_Lending_amount__c = 999999
            )
        };
        List<DMT_Opportunity_Business_Plan__c> result = DMT_BusinessPlanGlobalAggregator.buildAggregatedGlobalRecords(input, FIELDS);
        Assert.isTrue(result.isEmpty(), 'A persisted GLOBAL record must never be used as an aggregation source.');
    }

    @IsTest
    static void testRecordWithBlankYearIsSkipped() {
        List<DMT_Opportunity_Business_Plan__c> input = new List<DMT_Opportunity_Business_Plan__c>{
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'ES',
                DMT_Year__c = null,
                Current_FY_Corp_Synd_Lending_amount__c = 100
            )
        };
        List<DMT_Opportunity_Business_Plan__c> result = DMT_BusinessPlanGlobalAggregator.buildAggregatedGlobalRecords(input, FIELDS);
        Assert.isTrue(result.isEmpty(), 'A record with a blank year cannot be aggregated into a year bucket.');
    }

    @IsTest
    static void testSingleGeographySumsToSameValue() {
        List<DMT_Opportunity_Business_Plan__c> input = new List<DMT_Opportunity_Business_Plan__c>{
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'ES',
                DMT_Year__c = '2026',
                Current_FY_Corp_Synd_Lending_amount__c = 100,
                Current_FY_Total_Non_X_Sell_amount__c = 200
            )
        };
        List<DMT_Opportunity_Business_Plan__c> result = DMT_BusinessPlanGlobalAggregator.buildAggregatedGlobalRecords(input, FIELDS);

        Assert.areEqual(1, result.size(), 'One geography for one year should produce a single aggregated GLOBAL record.');
        DMT_Opportunity_Business_Plan__c agg = result[0];
        Assert.areEqual('GLOBAL', agg.DMT_Booking_Geography__c, 'Aggregated record must be tagged as GLOBAL.');
        Assert.areEqual('2026', agg.DMT_Year__c, 'Aggregated record must carry the source year.');
        Assert.areEqual(100, agg.Current_FY_Corp_Synd_Lending_amount__c, 'Single-geography sum should equal the source value.');
        Assert.areEqual(200, agg.Current_FY_Total_Non_X_Sell_amount__c, 'Single-geography sum should equal the source value.');
    }

    @IsTest
    static void testMultipleGeographiesAreSummedPerYear() {
        List<DMT_Opportunity_Business_Plan__c> input = new List<DMT_Opportunity_Business_Plan__c>{
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'ES',
                DMT_Year__c = '2026',
                Current_FY_Corp_Synd_Lending_amount__c = 100,
                Current_FY_Total_Non_X_Sell_amount__c = 200
            ),
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'FR',
                DMT_Year__c = '2026',
                Current_FY_Corp_Synd_Lending_amount__c = 50,
                Current_FY_Total_Non_X_Sell_amount__c = 25
            ),
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'ES',
                DMT_Year__c = '2027',
                Current_FY_Corp_Synd_Lending_amount__c = 10
            )
        };
        List<DMT_Opportunity_Business_Plan__c> result = DMT_BusinessPlanGlobalAggregator.buildAggregatedGlobalRecords(input, FIELDS);

        Map<String, DMT_Opportunity_Business_Plan__c> byYear = new Map<String, DMT_Opportunity_Business_Plan__c>();
        for (DMT_Opportunity_Business_Plan__c rec : result) {
            byYear.put(rec.DMT_Year__c, rec);
        }

        Assert.areEqual(2, result.size(), 'Two distinct years should produce two aggregated GLOBAL records.');
        Assert.areEqual(150, byYear.get('2026').Current_FY_Corp_Synd_Lending_amount__c, 'ES + FR for 2026 should sum to 150.');
        Assert.areEqual(225, byYear.get('2026').Current_FY_Total_Non_X_Sell_amount__c, 'ES + FR for 2026 should sum to 225.');
        Assert.areEqual(10, byYear.get('2027').Current_FY_Corp_Synd_Lending_amount__c, 'Only ES has 2027 data.');
        Assert.isNull(byYear.get('2027').Current_FY_Total_Non_X_Sell_amount__c, 'A field never populated for a year should stay null, not zero.');
    }

    @IsTest
    static void testBlankGeographyIsTreatedAsGlobalAndExcluded() {
        List<DMT_Opportunity_Business_Plan__c> input = new List<DMT_Opportunity_Business_Plan__c>{
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = null,
                DMT_Year__c = '2026',
                Current_FY_Corp_Synd_Lending_amount__c = 999999
            ),
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'ES',
                DMT_Year__c = '2026',
                Current_FY_Corp_Synd_Lending_amount__c = 100
            )
        };
        List<DMT_Opportunity_Business_Plan__c> result = DMT_BusinessPlanGlobalAggregator.buildAggregatedGlobalRecords(input, FIELDS);

        Assert.areEqual(1, result.size(), 'Only the ES geography should seed a year bucket.');
        Assert.areEqual(100, result[0].Current_FY_Corp_Synd_Lending_amount__c, 'The blank-geography record must not be summed in, same as a real persisted GLOBAL record.');
    }

    @IsTest
    static void testNullFieldValuesAreSkippedNotTreatedAsZero() {
        List<DMT_Opportunity_Business_Plan__c> input = new List<DMT_Opportunity_Business_Plan__c>{
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'ES',
                DMT_Year__c = '2026',
                Current_FY_Corp_Synd_Lending_amount__c = null
            )
        };
        List<DMT_Opportunity_Business_Plan__c> result = DMT_BusinessPlanGlobalAggregator.buildAggregatedGlobalRecords(input, FIELDS);

        Assert.areEqual(1, result.size(), 'A geography record with an all-null field should still create a year bucket.');
        Assert.isNull(result[0].Current_FY_Corp_Synd_Lending_amount__c, 'All-null source should remain null, not 0.');
    }
}