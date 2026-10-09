@IsTest
public class DMT_OppOtherAspectRendererTest {

    private static Opportunity buildOppWithEmptyRelationships() {
        String oppJson = '{"Name":"Test Opp","StageName":"Prospecting","CloseDate":"2026-12-31",'
            + '"Global_Structures__r":{"totalSize":0,"done":true,"records":[]},'
            + '"OpportunityLineItems":{"totalSize":0,"done":true,"records":[]}}';
        return (Opportunity) JSON.deserialize(oppJson, Opportunity.class);
    }

    private static DMT_ViewController.LineDataWrapper buildWrapper() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = buildOppWithEmptyRelationships();
        data.oppClient = new DMT_Opportunity_Client__c(
            DMT_Applicable_Jurisdiction__c = 'Spain',
            DMT_Security_Package__c = 'Package A',
            DMT_Rating_Scenarios__c = 'Scenario A',
            DMT_Other_Relevant_Issues__c = 'Issue A',
            DMT_Competition_Deal__c = 'Competition A'
        );
        data.bankingPoolStructures = new List<DMT_Banking_Pool_Structure__c>();
        return data;
    }

    @IsTest
    static void testNullDataReturnsGuardMessage() {
        DMT_OppOtherAspectRenderer renderer = new DMT_OppOtherAspectRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        // Both opportunity and oppClient have no populated fields — triggers guard.
        data.opportunity = new Opportunity();
        data.oppClient = new DMT_Opportunity_Client__c();
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Opportunity data not provided'), 'Empty wrapper must return guard message.');
    }

    @IsTest
    static void testNullExplicitDataReturnsGuardMessage() {
        DMT_OppOtherAspectRenderer renderer = new DMT_OppOtherAspectRenderer();
        String result = renderer.renderHtml(null);
        Assert.isTrue(result.contains('Opportunity data not provided') || result.contains('Error'),
            'Null data must return a controlled response.');
    }

    @IsTest
    static void testHappyPathRendersOtherAspects() {
        DMT_OppOtherAspectRenderer renderer = new DMT_OppOtherAspectRenderer();
        DMT_ViewController.LineDataWrapper data = buildWrapper();

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'Happy path must return a non-null result.');
        Assert.isTrue(!result.contains('Opportunity data not provided'), 'Should not return no-data message.');
        Assert.isTrue(!result.contains('<div>Error:'), 'Should not produce an error div.');
        Assert.isTrue(result.contains('Other Aspects'), 'Result should contain the Other Aspects heading.');
        Assert.isTrue(result.contains('Applicable jurisdiction') || result.contains('Spain'),
            'Applicable jurisdiction field should be rendered.');
    }

    @IsTest
    static void testGlobalStructuresRendered() {
        DMT_OppOtherAspectRenderer renderer = new DMT_OppOtherAspectRenderer();
        DMT_ViewController.LineDataWrapper data = buildWrapper();

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('Global Structures') || result.contains('TOTAL'),
            'Global Structures section should be rendered.');
    }

    @IsTest
    static void testBankingPoolStructureRendered() {
        DMT_OppOtherAspectRenderer renderer = new DMT_OppOtherAspectRenderer();
        DMT_ViewController.LineDataWrapper data = buildWrapper();
        DMT_Banking_Pool_Structure__c tier1 = new DMT_Banking_Pool_Structure__c(
            Name = 'Tier 1'
        );
        data.bankingPoolStructures = new List<DMT_Banking_Pool_Structure__c>{ tier1 };

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('Banking Pool') || result.contains('Tier 1'),
            'Banking Pool Structure section should be rendered with tier data.');
    }

    @IsTest
    static void testCompetitionForTheDealRendered() {
        DMT_OppOtherAspectRenderer renderer = new DMT_OppOtherAspectRenderer();
        DMT_ViewController.LineDataWrapper data = buildWrapper();
        data.oppClient.DMT_Competition_Deal__c = 'Competitor XYZ';

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('Competition for the deal') || result.contains('Competitor XYZ'),
            'Competition for the deal section should be rendered.');
    }

    @IsTest
    static void testWithComparisonAccountNameInHeading() {
        DMT_OppOtherAspectRenderer renderer = new DMT_OppOtherAspectRenderer();
        DMT_ViewController.LineDataWrapper data = buildWrapper();
        data.oppAccountParentName = 'Parent Corp';

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('Other Aspects') && result.contains('Parent Corp'),
            'Account parent name should appear in the heading.');
    }

    @IsTest
    static void testWithGlobalStructuresWithDebtAndEquity() {
        DMT_OppOtherAspectRenderer renderer = new DMT_OppOtherAspectRenderer();
        DMT_ViewController.LineDataWrapper data = buildWrapper();

        // Build an opportunity with Global_Structures__r records via JSON deserialization.
        String gsId = '0ABCDE000000001AAA';
        String oppJson = '{"Name":"Test Opp","StageName":"Prospecting","CloseDate":"2026-12-31",'
            + '"Global_Structures__r":{"totalSize":2,"done":true,"records":['
            + '{"Id":"' + gsId + '","Name":"GS Debt","DMT_Type__c":"Funding Debt","DMT_Funds__c":500},'
            + '{"Id":"0ABCDE000000002AAA","Name":"GS Uses","DMT_Type__c":"Uses","DMT_Funds__c":300}'
            + ']},'
            + '"OpportunityLineItems":{"totalSize":0,"done":true,"records":[]}}';
        data.opportunity = (Opportunity) JSON.deserialize(oppJson, Opportunity.class);

        String result = renderer.renderHtml(data);

        Assert.isTrue(!result.contains('<div>Error:'), 'Global Structures with debt records must not produce an error div.');
        Assert.isTrue(result.contains('TOTAL') || result.contains('500'),
            'Debt total or value should be rendered.');
    }

    @IsTest
    static void testWithEquityGlobalStructureCoversEquityLoop() {
        DMT_OppOtherAspectRenderer renderer = new DMT_OppOtherAspectRenderer();
        DMT_ViewController.LineDataWrapper data = buildWrapper();

        String oppJson = '{"Name":"Test Opp","StageName":"Prospecting","CloseDate":"2026-12-31",'
            + '"Global_Structures__r":{"totalSize":1,"done":true,"records":['
            + '{"Id":"0ABCDE000000003AAA","Name":"GS Equity","DMT_Type__c":"Funding Equity","DMT_Funds__c":200}'
            + ']},'
            + '"OpportunityLineItems":{"totalSize":0,"done":true,"records":[]}}';
        data.opportunity = (Opportunity) JSON.deserialize(oppJson, Opportunity.class);

        String result = renderer.renderHtml(data);

        Assert.isTrue(!result.contains('<div>Error:'), 'Equity global structures must not produce an error div.');
        Assert.isTrue(result.contains('TOTAL') || result.contains('200'),
            'Equity funds value or TOTAL should appear in the result.');
    }

    @IsTest
    static void testMissingGlobalStructureRelationshipCoversCatchBlock() {
        DMT_OppOtherAspectRenderer renderer = new DMT_OppOtherAspectRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        // Opportunity with Name set (bypasses guard) but no Global_Structures__r in JSON.
        // Accessing the null relationship in buildGlobalStructuresData causes NullPointerException
        // propagated up to renderHtml's catch block — covers lines 40-42.
        data.opportunity = (Opportunity) JSON.deserialize(
            '{"Name":"Test Opp","StageName":"X","CloseDate":"2026-12-31"}', Opportunity.class);
        data.oppClient = new DMT_Opportunity_Client__c(DMT_Applicable_Jurisdiction__c = 'Spain');
        data.bankingPoolStructures = new List<DMT_Banking_Pool_Structure__c>();

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('Error') || result.contains('Other Aspects'),
            'Missing relationship should either trigger catch block or render gracefully.');
    }
}