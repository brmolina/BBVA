@isTest(seeAllData=false)
public class DMT_OppBusinessPlanDataRenderer_Test {

    @isTest
    static void testRenderHtmlNullData() {
        DMT_OppBusinessPlanDataRenderer renderer = new DMT_OppBusinessPlanDataRenderer();
        Test.startTest();
        String result = renderer.renderHtml(null);
        Test.stopTest();
        Assert.isTrue(result.contains('Opportunity data not provided'), 'Should return not provided message for null data.');
    }

    @isTest
    static void testRenderHtmlEmptyBusinessPlanRecords() {
        DMT_OppBusinessPlanDataRenderer renderer = new DMT_OppBusinessPlanDataRenderer();
        DMT_ViewController.LineDataWrapper data = buildBaseWrapper();

        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        Assert.isTrue(result.contains('No Business Plan records found'), 'Should show no records message when list is empty.');
    }

    @isTest
    static void testRenderHtmlWithGlobalRecords() {
        DMT_OppBusinessPlanDataRenderer renderer = new DMT_OppBusinessPlanDataRenderer();
        DMT_ViewController.LineDataWrapper data = buildBaseWrapper();
        Integer currentYear = Date.today().year();

        // The GLOBAL record still supplies QAOTER/Currency metadata (via findGlobalRecord), but the
        // GLOBAL table itself is now computed live from non-GLOBAL geography records, so a source
        // geography record is required for the table to render at all.
        DMT_Opportunity_Business_Plan__c globalRec = new DMT_Opportunity_Business_Plan__c(
            DMT_Booking_Geography__c = 'GLOBAL',
            DMT_Year__c = String.valueOf(currentYear),
            DMT_QAOTER__c = 'High potential client',
            DMT_Currency__c = 'USD',
            DMT_Xsell_Cost_to_Income__c = 45
        );
        DMT_Opportunity_Business_Plan__c esRec = new DMT_Opportunity_Business_Plan__c(
            DMT_Booking_Geography__c = 'ES',
            DMT_Year__c = String.valueOf(currentYear),
            Current_FY_Corp_Synd_Lending_amount__c = 1000,
            Current_FY_Total_Non_X_Sell_amount__c = 5000,
            Current_FY_Total_Revenues_amount__c = 10000
        );
        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>{ globalRec, esRec };

        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        Assert.isTrue(result.contains('Business Plan Data'), 'Should contain title.');
        Assert.isTrue(result.contains('Business Plan - GLOBAL'), 'Should contain GLOBAL geography table, aggregated from ES.');
        Assert.isTrue(result.contains('High potential client'), 'Should contain qualitative assessment.');
        Assert.isTrue(result.contains('USD'), 'Should contain currency.');
    }

    @isTest
    static void testRenderHtmlWithMultipleGeographies() {
        DMT_OppBusinessPlanDataRenderer renderer = new DMT_OppBusinessPlanDataRenderer();
        DMT_ViewController.LineDataWrapper data = buildBaseWrapper();
        Integer currentYear = Date.today().year();

        data.taxonomyH007BPMap = new Map<String, String>{ 'ES' => 'Spain', 'GLOBAL' => 'Global' };

        DMT_Opportunity_Business_Plan__c esRec = new DMT_Opportunity_Business_Plan__c(
            DMT_Booking_Geography__c = 'ES',
            DMT_Year__c = String.valueOf(currentYear),
            Current_FY_Corp_Synd_Lending_amount__c = 500
        );
        DMT_Opportunity_Business_Plan__c globalRec = new DMT_Opportunity_Business_Plan__c(
            DMT_Booking_Geography__c = 'GLOBAL',
            DMT_Year__c = String.valueOf(currentYear),
            DMT_QAOTER__c = 'Assessment text',
            DMT_Currency__c = 'EUR'
        );
        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>{ esRec, globalRec };

        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        Assert.isTrue(result.contains('Business Plan - Spain'), 'Should use taxonomy label for ES geography.');
        Assert.isTrue(result.contains('Business Plan - Global'), 'Should render GLOBAL table.');
        Assert.isTrue(result.contains('Assessment text'), 'Should display qualitative assessment from GLOBAL record.');
    }

    @isTest
    static void testRenderHtmlWithAccountParentName() {
        DMT_OppBusinessPlanDataRenderer renderer = new DMT_OppBusinessPlanDataRenderer();
        DMT_ViewController.LineDataWrapper data = buildBaseWrapper();
        data.oppAccountParentName = 'ACME Corporation';
        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>();

        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        Assert.isTrue(result.contains('ACME Corporation'), 'Should include account parent name in heading.');
    }


    

    @isTest
    static void testRenderHtmlMultipleYears() {
        DMT_OppBusinessPlanDataRenderer renderer = new DMT_OppBusinessPlanDataRenderer();
        DMT_ViewController.LineDataWrapper data = buildBaseWrapper();
        Integer currentYear = Date.today().year();

        // GLOBAL is computed by aggregating non-GLOBAL geography records, so the source records
        // here use a real geography ('ES') and the GLOBAL record only supplies the QAOTER/Currency
        // metadata for the current year.
        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>{
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'ES',
                DMT_Year__c = String.valueOf(currentYear - 2),
                Current_FY_Corp_Synd_Lending_amount__c = 100
            ),
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'ES',
                DMT_Year__c = String.valueOf(currentYear - 1),
                Current_FY_Corp_Synd_Lending_amount__c = 200
            ),
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'ES',
                DMT_Year__c = String.valueOf(currentYear),
                Current_FY_Corp_Synd_Lending_amount__c = 300
            ),
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'GLOBAL',
                DMT_Year__c = String.valueOf(currentYear),
                DMT_QAOTER__c = 'Test assessment',
                DMT_Currency__c = 'GBP'
            ),
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'ES',
                DMT_Year__c = String.valueOf(currentYear + 1),
                Current_FY_Corp_Synd_Lending_amount__c = 400
            ),
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'ES',
                DMT_Year__c = String.valueOf(currentYear + 2),
                Current_FY_Corp_Synd_Lending_amount__c = 500
            )
        };

        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        Assert.isTrue(result.contains(String.valueOf(currentYear - 2)), 'Should show CY-2 column header.');
        Assert.isTrue(result.contains(String.valueOf(currentYear + 2)), 'Should show CY+2 column header.');
        Assert.isTrue(result.contains('Corp. Synd. Lending'), 'Should render row labels.');
        Assert.isTrue(result.contains('Total Revenues'), 'Should render Total Revenues row.');
    }

    @isTest
    static void testRenderHtmlBlankGeographyIsExcludedFromGlobalAggregation() {
        DMT_OppBusinessPlanDataRenderer renderer = new DMT_OppBusinessPlanDataRenderer();
        DMT_ViewController.LineDataWrapper data = buildBaseWrapper();
        Integer currentYear = Date.today().year();

        // A blank geography is treated the same as an existing persisted GLOBAL record: it must
        // NOT be summed into the aggregated GLOBAL table. Pairing it with a real geography record
        // proves the GLOBAL table still renders (from ES) without double-counting the blank one.
        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>{
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = null,
                DMT_Year__c = String.valueOf(currentYear),
                DMT_QAOTER__c = 'From blank geo',
                Current_FY_Corp_Synd_Lending_amount__c = 999999
            ),
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'ES',
                DMT_Year__c = String.valueOf(currentYear),
                Current_FY_Corp_Synd_Lending_amount__c = 100
            )
        };

        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        Assert.isTrue(result.contains('Business Plan - GLOBAL'), 'GLOBAL table should render, aggregated from ES.');
        Assert.isFalse(result.contains('999999'), 'The blank-geography record must not be summed into the GLOBAL table.');
    }

    @isTest
    static void testRenderHtmlNullYearRecordIsSkippedButOthersRender() {
        DMT_OppBusinessPlanDataRenderer renderer = new DMT_OppBusinessPlanDataRenderer();
        DMT_ViewController.LineDataWrapper data = buildBaseWrapper();
        Integer currentYear = Date.today().year();

        // A geography record with no year can't be placed in a year bucket and must be skipped
        // without breaking aggregation of the other, valid-year records.
        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>{
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'ES',
                DMT_Year__c = null,
                Current_FY_Corp_Synd_Lending_amount__c = 100
            ),
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'ES',
                DMT_Year__c = String.valueOf(currentYear),
                Current_FY_Corp_Synd_Lending_amount__c = 200
            )
        };

        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        Assert.isTrue(result.contains('Business Plan - GLOBAL'), 'Should still render GLOBAL table from the valid-year record.');
        Assert.isFalse(result.contains('<div>Error:'), 'A null-year record must not cause a rendering error.');
    }

    @isTest
    static void testFindGlobalRecordFallbackToFirst() {
        DMT_OppBusinessPlanDataRenderer renderer = new DMT_OppBusinessPlanDataRenderer();
        DMT_ViewController.LineDataWrapper data = buildBaseWrapper();
        Integer currentYear = Date.today().year();

        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>{
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'PE',
                DMT_Year__c = String.valueOf(currentYear),
                DMT_QAOTER__c = 'Peru assessment',
                DMT_Currency__c = 'PEN'
            )
        };

        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        Assert.isTrue(result.contains('Peru assessment'), 'Should use first record as fallback when no GLOBAL found.');
        Assert.isTrue(result.contains('PEN'), 'Should display currency from fallback record.');
    }

    @isTest
    static void testDelegatorRenderHtmlNullData() {
        DMT_BusinessPlanDataRenderer delegator = new DMT_BusinessPlanDataRenderer();
        Test.startTest();
        String result = delegator.renderHtml(null);
        Test.stopTest();
        Assert.isTrue(result.contains('Error'), 'Delegator should return error for null data.');
    }

    @isTest
    static void testDelegatorRenderHtmlInvalidRecordType() {
        DMT_BusinessPlanDataRenderer delegator = new DMT_BusinessPlanDataRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        String result = delegator.renderHtml(data);
        Test.stopTest();
        Assert.isTrue(result.contains('Error'), 'Delegator should return error for invalid record type.');
    }

    @isTest
    static void testRenderHtmlTotalRowsStyling() {
        DMT_OppBusinessPlanDataRenderer renderer = new DMT_OppBusinessPlanDataRenderer();
        DMT_ViewController.LineDataWrapper data = buildBaseWrapper();
        Integer currentYear = Date.today().year();

        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>{
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'ES',
                DMT_Year__c = String.valueOf(currentYear),
                Current_FY_Total_Non_X_Sell_amount__c = 5000,
                Current_FY_Total_X_Sell_amount__c = 3000,
                Current_FY_Total_Revenues_amount__c = 8000
            )
        };

        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        Assert.isTrue(result.contains('<strong>Total Non X-Sell</strong>'), 'Total Non X-Sell should be bold.');
        Assert.isTrue(result.contains('<strong>Total X-Sell</strong>'), 'Total X-Sell should be bold.');
        Assert.isTrue(result.contains('<strong>Total Revenues</strong>'), 'Total Revenues should be bold.');
    }

    @isTest
    static void testRenderHtmlTotalXSellIsRecomputedFromComponentsNotStoredField() {
        DMT_OppBusinessPlanDataRenderer renderer = new DMT_OppBusinessPlanDataRenderer();
        DMT_ViewController.LineDataWrapper data = buildBaseWrapper();
        Integer currentYear = Date.today().year();

        // The stored total field is intentionally stale/wrong; the rendered "Total X-Sell" must
        // reflect the live sum of the component rows instead, matching the LWC's own behavior.
        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>{
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'ES',
                DMT_Year__c = String.valueOf(currentYear),
                Current_FY_Total_X_Sell_amount__c = 999999,
                Current_FY_M_A_amount__c = 40,
                Current_FY_DCM_amount__c = 10,
                Current_FY_Cash_Management_amount__c = 5
            )
        };

        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        Assert.isTrue(result.contains('55'), 'Total X-Sell should show the live component sum (40 + 10 + 5 = 55).');
        Assert.isFalse(result.contains('999999'), 'The stale stored Total X-Sell field must not be used.');
    }

    @isTest
    static void testRenderHtmlNoXSellEmpty() {
        DMT_OppBusinessPlanDataRenderer renderer = new DMT_OppBusinessPlanDataRenderer();
        DMT_ViewController.LineDataWrapper data = buildBaseWrapper();
        Integer currentYear = Date.today().year();

        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>{
            new DMT_Opportunity_Business_Plan__c(DMT_Booking_Geography__c = 'GLOBAL', DMT_Year__c = String.valueOf(currentYear))
        };

        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        Assert.isFalse(result.contains('Cross SELL'), 'Should not contain Cross SELL section when xSellOpp is empty.');
    }

    @isTest
    static void testRenderHtmlGeoWithoutTaxonomyMap() {
        DMT_OppBusinessPlanDataRenderer renderer = new DMT_OppBusinessPlanDataRenderer();
        DMT_ViewController.LineDataWrapper data = buildBaseWrapper();
        Integer currentYear = Date.today().year();

        data.taxonomyH007BPMap = null;

        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>{
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'AR',
                DMT_Year__c = String.valueOf(currentYear)
            )
        };

        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        Assert.isTrue(result.contains('Business Plan - AR'), 'Should use geo code when taxonomy map is null.');
    }

    // ====================================================================================================
    // HELPER
    // ====================================================================================================

    private static DMT_ViewController.LineDataWrapper buildBaseWrapper() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>();
        data.taxonomyH007BPMap = new Map<String, String>();
        data.taxonomyH007Map = new Map<String, String>();
        data.xSellOpp = new List<DMT_X_Sell__c>();
        data.oppAccountParentName = '';
        return data;
    }
}