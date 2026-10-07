@isTest
public class DMT_NBC_XSellGeographiesTest {

    private static final String DMT_OPP_RT = 'DMT_Opportunity';

    // ── Factory ───────────────────────────────────────────────────────────────

    @isTest
    static void testFactoryRegistration() {
        Test.startTest();
        Boolean has = DMT_RendererFactory.hasRenderer('NBC XSell Geographies');
        DMT_ViewRenderer renderer = DMT_RendererFactory.getRenderer('NBC XSell Geographies');
        Test.stopTest();

        Assert.isTrue(has, 'Factory must contain NBC XSell Geographies entry');
        Assert.isInstanceOfType(renderer, DMT_NBC_XSellGeographies.class,
            'Factory must return a DMT_NBC_XSellGeographies instance');
    }

    // ── Delegator ─────────────────────────────────────────────────────────────

    @isTest
    static void testDelegatorNullData() {
        Test.startTest();
        String result = new DMT_NBC_XSellGeographies().renderHtml(null);
        Test.stopTest();

        Assert.isTrue(result.contains('Error'), 'Null data must return an error div');
    }

    @isTest
    static void testDelegatorUnknownRecordType() {
        DMT_ViewController.LineDataWrapper data = buildWrapper('012000000000000', new List<DMT_Opportunity_Business_Plan__c>());

        Test.startTest();
        String result = new DMT_NBC_XSellGeographies().renderHtml(data);
        Test.stopTest();

        Assert.isTrue(result.contains('Error'), 'Unknown record type must return an error div');
    }

    @isTest
    static void testDelegatorDispatchesToRenderer() {
        Id rtId = rtId();
        DMT_ViewController.LineDataWrapper data = buildWrapper(rtId, new List<DMT_Opportunity_Business_Plan__c>());

        Test.startTest();
        String result = new DMT_NBC_XSellGeographies().renderHtml(data);
        Test.stopTest();

        Assert.isNotNull(result, 'Delegator must return a non-null result for valid record type');
        Assert.isFalse(result.contains('Error: No NBC XSell'), 'Delegator must route to renderer, not throw');
    }

    // ── Renderer — null and empty data ────────────────────────────────────────

    @isTest
    static void testRendererNullData() {
        Test.startTest();
        String result = new DMT_NBC_OppXSellGeographies().renderHtml(null);
        Test.stopTest();

        Assert.isTrue(result.contains('not provided'), 'Null data must return not-provided message');
    }

    @isTest
    static void testRendererNoBpRecords() {
        DMT_ViewController.LineDataWrapper data = buildWrapper(rtId(), new List<DMT_Opportunity_Business_Plan__c>());

        Test.startTest();
        String result = new DMT_NBC_OppXSellGeographies().renderHtml(data);
        Test.stopTest();

        Assert.isTrue(result.contains('No Business Plan records found'), 'Empty records must show empty-state message');
    }

    // ── Renderer — active non-GLOBAL geography (15 rows rendered) ────────────

    @isTest
    static void testRendererActiveNonGlobal() {
        Integer yr = Date.today().year();
        List<DMT_Opportunity_Business_Plan__c> bps = makeBpRecords('ES01', true, yr);
        DMT_ViewController.LineDataWrapper data = buildWrapper(rtId(), bps);
        data.taxonomyH007BPMap = new Map<String, String>{ 'ES01' => 'Spain' };

        Test.startTest();
        String result = new DMT_NBC_OppXSellGeographies().renderHtml(data);
        Test.stopTest();

        Assert.isTrue(result.contains('Spain'),          'Active non-GLOBAL must render its geography label');
        Assert.isTrue(result.contains('No Cross Sell'),  'Must include No Cross Sell section');
        Assert.isTrue(result.contains('Cross Sell'),     'Must include Cross Sell section');
        Assert.isTrue(result.contains('SUBTOTAL'),       'Must include SUBTOTAL row');
        Assert.isFalse(result.contains('GLOBAL NET INCOME'), 'Non-GLOBAL block must not include GLOBAL summary rows');
    }

    // ── Renderer — inactive non-GLOBAL geography (not rendered) ──────────────

    @isTest
    static void testRendererInactiveNonGlobalSkipped() {
        Integer yr = Date.today().year();
        List<DMT_Opportunity_Business_Plan__c> bps = makeBpRecords('FR01', false, yr);
        DMT_ViewController.LineDataWrapper data = buildWrapper(rtId(), bps);
        data.taxonomyH007BPMap = new Map<String, String>{ 'FR01' => 'France' };

        Test.startTest();
        String result = new DMT_NBC_OppXSellGeographies().renderHtml(data);
        Test.stopTest();

        Assert.isFalse(result.contains('France'),   'Inactive geography must not be rendered');
        Assert.isFalse(result.contains('SUBTOTAL'), 'No geography rows should be rendered for inactive geo');
    }

    // ── Renderer — GLOBAL geography (19 rows, always rendered) ───────────────

    @isTest
    static void testRendererGlobal() {
        Integer yr = Date.today().year();
        // Blank geography code is treated as GLOBAL by groupByGeography()
        List<DMT_Opportunity_Business_Plan__c> bps = makeBpRecords('', false, yr);
        DMT_ViewController.LineDataWrapper data = buildWrapper(rtId(), bps);

        Test.startTest();
        String result = new DMT_NBC_OppXSellGeographies().renderHtml(data);
        Test.stopTest();

        Assert.isTrue(result.contains('GLOBAL NET INCOME'),      'GLOBAL block must include GLOBAL NET INCOME row');
        Assert.isTrue(result.contains('TOTAL REVENUES'),          'GLOBAL block must include TOTAL REVENUES row');
        Assert.isTrue(result.contains('EXPECTED TOTAL XSELL'),    'GLOBAL block must include EXPECTED TOTAL XSELL row');
        Assert.isTrue(result.contains('EXPECTED TOTAL NO XSELL'), 'GLOBAL block must include EXPECTED TOTAL NO XSELL row');
        Assert.isTrue(result.contains('EXPECTED XSELL OPEX'),     'GLOBAL block must include EXPECTED XSELL OPEX row');
    }

    // ── Renderer — mixed geographies: active non-GLOBAL before GLOBAL ─────────

    @isTest
    static void testRendererNonGlobalRenderedBeforeGlobal() {
        Integer yr = Date.today().year();
        List<DMT_Opportunity_Business_Plan__c> bps = new List<DMT_Opportunity_Business_Plan__c>();
        bps.addAll(makeBpRecords('MX01', true, yr));  // active non-GLOBAL
        bps.addAll(makeBpRecords('',     false, yr)); // GLOBAL (blank geo = GLOBAL)

        DMT_ViewController.LineDataWrapper data = buildWrapper(rtId(), bps);
        data.taxonomyH007BPMap = new Map<String, String>{ 'MX01' => 'Mexico' };

        Test.startTest();
        String result = new DMT_NBC_OppXSellGeographies().renderHtml(data);
        Test.stopTest();

        Assert.isTrue(result.contains('Mexico'),             'Active non-GLOBAL must be rendered');
        Assert.isTrue(result.contains('GLOBAL NET INCOME'),  'GLOBAL block must be rendered');
        Assert.isTrue(result.indexOf('Mexico') < result.indexOf('GLOBAL NET INCOME'),
            'Non-GLOBAL geography must appear before GLOBAL block');
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private static Id rtId() {
        return Schema.SObjectType.Opportunity
            .getRecordTypeInfosByDeveloperName()
            .get(DMT_OPP_RT)
            .getRecordTypeId();
    }

    private static DMT_ViewController.LineDataWrapper buildWrapper(Object recordTypeId, List<DMT_Opportunity_Business_Plan__c> bps) {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(recordTypeId);
        data.businessPlanRecords = bps;
        data.taxonomyH007BPMap = new Map<String, String>();
        return data;
    }

    private static List<DMT_Opportunity_Business_Plan__c> makeBpRecords(String geoCode, Boolean active, Integer baseYear) {
        List<DMT_Opportunity_Business_Plan__c> records = new List<DMT_Opportunity_Business_Plan__c>();
        for (Integer offset = -1; offset <= 3; offset++) {
            DMT_Opportunity_Business_Plan__c bp = new DMT_Opportunity_Business_Plan__c();
            bp.DMT_Booking_Geography__c = geoCode;
            bp.DMT_Active__c            = active;
            bp.DMT_Year__c              = String.valueOf(baseYear + offset);
            bp.DMT_Currency__c          = 'EUR';
            bp.Current_FY_Corp_Synd_Lending_amount__c   = 100;
            bp.Current_FY_Structured_Finance_amount__c  = 200;
            bp.Current_FY_Rates_amount__c               = 300;
            bp.Current_FY_GTF_amount__c                 = 400;
            bp.Current_FY_Working_Capital_amount__c     = 500;
            bp.Current_FY_Str_Trade_Finance_amount__c   = 600;
            bp.Current_FY_ECM_M_A_Amount__c             = 700;
            bp.Current_FY_M_A_amount__c                 = 800;
            bp.Current_FY_Securities_Services_amount__c = 900;
            bp.Current_FY_Client_Resources_amount__c    = 1000;
            bp.Current_FY_DCM_amount__c                 = 1100;
            bp.Current_FY_FX_CCS_amount__c              = 1200;
            bp.Current_FY_Cash_Management_amount__c     = 1300;
            bp.Current_FY_Credit_Equity_amount__c       = 1400;
            bp.Current_FY_Total_X_Sell_amount__c        = 9000;
            bp.Current_FY_Total_Non_X_Sell_amount__c    = 2100;
            bp.Current_FY_Total_Revenues_amount__c      = 11100;
            bp.Current_FY_Child_X_Sell_amount__c        = 500;
            records.add(bp);
        }
        return records;
    }
}