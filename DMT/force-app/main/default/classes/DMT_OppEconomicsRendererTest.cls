@IsTest
public class DMT_OppEconomicsRendererTest {

    private static Opportunity buildOppWithLineItems() {
        String oppJson = '{"Name":"Test Opp","StageName":"Prospecting","CloseDate":"2026-12-31",'
            + '"OpportunityLineItems":{"totalSize":1,"done":true,"records":['
            + '{"Id":"006000000000001AAA","Quantity":1,"UnitPrice":1,"TotalPrice":1,'
            + '"gf_group_priority_opportunity_id__c":"PROD001",'
            + '"DMT_PricingGrid_OR_StepUps__c":0.5,"DMT_Extension_Duration_Fees__c":0.25,'
            + '"DMT_Expected_Drawn__c":80,"CurrencyIsoCode":"EUR"}'
            + ']}}';
        return (Opportunity) JSON.deserialize(oppJson, Opportunity.class);
    }

    @IsTest
    static void testNullDataReturnsGuardMessage() {
        DMT_OppEconomicsRenderer renderer = new DMT_OppEconomicsRenderer();
        String result = renderer.renderHtml(null);
        Assert.isTrue(result.contains('Opportunity data not provided'), 'Null data must return guard message.');
    }

    @IsTest
    static void testEmptyWrapperReturnsGuardMessage() {
        DMT_OppEconomicsRenderer renderer = new DMT_OppEconomicsRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity();
        data.oppClient = new DMT_Opportunity_Client__c();
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Opportunity data not provided'), 'Empty wrapper must return guard message.');
    }

    @IsTest
    static void testEmptyLineItemsRendersHeadingOnly() {
        DMT_OppEconomicsRenderer renderer = new DMT_OppEconomicsRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        String oppJson = '{"Name":"Test","StageName":"Prospecting","CloseDate":"2026-12-31",'
            + '"OpportunityLineItems":{"totalSize":0,"done":true,"records":[]}}';
        data.opportunity = (Opportunity) JSON.deserialize(oppJson, Opportunity.class);
        data.oppClient = new DMT_Opportunity_Client__c();

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('Economics'), 'Economics heading should be present even with empty line items.');
    }

    @IsTest
    static void testWithLineItemsRendersEconomicsTable() {
        DMT_OppEconomicsRenderer renderer = new DMT_OppEconomicsRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = buildOppWithLineItems();
        data.oppClient = new DMT_Opportunity_Client__c();

        String result = renderer.renderHtml(data);

        Assert.isTrue(!result.contains('<div>Error:'), 'Line items must render without error.');
        Assert.isTrue(result.contains('Economics'), 'Economics heading should be present.');
        Assert.isTrue(result.contains('Applicable Margin') || result.contains('Commitment Fee'),
            'Economics labels should be rendered in the table.');
        Assert.isTrue(result.contains('Expected Drawn'), 'Expected Drawn label should appear.');
    }

    @IsTest
    static void testWithProfitabilityResultsCoversGetValueForLabel() {
        DMT_OppEconomicsRenderer renderer = new DMT_OppEconomicsRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = buildOppWithLineItems();
        data.oppClient = new DMT_Opportunity_Client__c();

        Map<String, Object> profitabilityResult = new Map<String, Object>{
            'productId' => 'PROD001',
            'periodicFeesPbs' => 10.0,
            'feesUpFrontPbs' => 5.0,
            'fundingDbPbs' => 50.0,
            'fundingFbPbs' => 20.0,
            'spreadDbPbs' => 150.0,
            'spreadFbPbs' => 30.0,
            'feesFbPbs' => 8.0,
            'feesDbPbs' => 12.0,
            'allInDb' => 200.0,
            'allInFb' => 60.0
        };
        Map<String, Object> profitability = new Map<String, Object>{
            'results' => new List<Object>{ profitabilityResult }
        };
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'profitability' => profitability }
        };

        String result = renderer.renderHtml(data);

        Assert.isTrue(!result.contains('<div>Error:'), 'Profitability path must render without error.');
        Assert.isTrue(result.contains('Up-Front Fee Accrual') || result.contains('Funding Cost'),
            'Profitability-sourced labels should be present.');
    }

    @IsTest
    static void testApplicableMarginBothSpreadsBranch() {
        DMT_OppEconomicsRenderer renderer = new DMT_OppEconomicsRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = buildOppWithLineItems();
        data.oppClient = new DMT_Opportunity_Client__c();

        Map<String, Object> profitabilityResult = new Map<String, Object>{
            'productId' => 'PROD001',
            'spreadDbPbs' => 100.0,
            'spreadFbPbs' => 50.0
        };
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'profitability' => new Map<String, Object>{
                    'results' => new List<Object>{ profitabilityResult }
                }
            }
        };

        String result = renderer.renderHtml(data);

        Assert.isTrue(!result.contains('<div>Error:'), 'Applicable Margin with both spreads must render without error.');
    }

    @IsTest
    static void testNullDataReturnsGuardMessageDirectly() {
        DMT_OppEconomicsRenderer renderer = new DMT_OppEconomicsRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity();
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Opportunity data not provided') || result.contains('Error'),
            'Null oppClient must return guard or error response.');
    }
}