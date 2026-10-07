@IsTest
public class DMT_BasicFinancialsRendererTest {

    private static Integer currentDisplayYear() {
        Integer quarter = (Date.today().month() - 1) / 3 + 1;
        Integer yearOffset = (quarter == 4) ? 1 : 0;
        return Date.today().year() + yearOffset;
    }

    @IsTest
    static void testGuardEmptyWrapperReturnsOpportunityDataNotProvided() {
        DMT_OppBasicFinancialsRenderer renderer = new DMT_OppBasicFinancialsRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity();
        data.oppClient = new DMT_Opportunity_Client__c();

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('Opportunity data not provided'), 'Empty wrapper must return guard message.');
    }

    @IsTest
    static void testGuardNullDataReturnsOpportunityDataNotProvided() {
        DMT_OppBasicFinancialsRenderer renderer = new DMT_OppBasicFinancialsRenderer();
        String result = renderer.renderHtml(null);
        Assert.isTrue(result.contains('Opportunity data not provided'), 'Null data must short-circuit to the guard message.');
    }

    @IsTest
    static void testNoGlobalBusinessPlanRecordRendersBlankGrid() {
        DMT_OppBasicFinancialsRenderer renderer = new DMT_OppBasicFinancialsRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'No BP Opp');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>();

        String result = renderer.renderHtml(data);

        Assert.isFalse(result.contains('Error'), 'Missing business plan records must not raise an error.');
        Assert.isTrue(result.contains('Basic Financials'), 'Grid header should still render.');
    }

    @IsTest
    static void testGlobalRecordWithPartialYearsAndFieldsPopulated() {
        DMT_OppBasicFinancialsRenderer renderer = new DMT_OppBasicFinancialsRenderer();
        Integer year = currentDisplayYear();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Partial BP Opp');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>{
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'GLOBAL',
                DMT_Year__c = String.valueOf(year - 1),
                DMT_Revenues_number__c = 555
            )
        };

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('555'), 'The one populated field/year should appear in the grid.');
    }

    @IsTest
    static void testMultipleYearsMapToCorrectColumns() {
        DMT_OppBasicFinancialsRenderer renderer = new DMT_OppBasicFinancialsRenderer();
        Integer year = currentDisplayYear();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Multi Year BP Opp');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>{
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'GLOBAL',
                DMT_Year__c = String.valueOf(year - 1),
                DMT_EBITDA_number__c = 111
            ),
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'GLOBAL',
                DMT_Year__c = String.valueOf(year),
                DMT_EBITDA_number__c = 222
            ),
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'GLOBAL',
                DMT_Year__c = String.valueOf(year + 2),
                DMT_EBITDA_number__c = 333
            )
        };

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('111') && result.contains('222') && result.contains('333'),
            'Each year record should map into the grid without collapsing into a single column.');
    }

    @IsTest
    static void testNonGlobalOnlyRecordsRenderBlankGrid() {
        DMT_OppBasicFinancialsRenderer renderer = new DMT_OppBasicFinancialsRenderer();
        Integer year = currentDisplayYear();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Non Global BP Opp');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>{
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'ES01',
                DMT_Year__c = String.valueOf(year),
                DMT_Revenues_number__c = 888
            )
        };

        String result = renderer.renderHtml(data);

        Assert.isFalse(result.contains('888'), 'A geography-specific-only record must not leak into the GLOBAL Opportunity-level grid.');
    }

    @IsTest
    static void testCommentFieldsStillSourcedFromOppClient() {
        DMT_OppBasicFinancialsRenderer renderer = new DMT_OppBasicFinancialsRenderer();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Comments Opp');
        data.oppClient = new DMT_Opportunity_Client__c(
            Other_Relevant_Ratios_desc__c = 'Some ratio commentary',
            cstk_sust_indicators_comments__c = 'Some basic financials comment'
        );
        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>();

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('Some ratio commentary'), 'Other Relevant Ratios must still come from DMT_Opportunity_Client__c.');
        Assert.isTrue(result.contains('Some basic financials comment'), 'Basic Financials Comments must still come from DMT_Opportunity_Client__c.');
    }

    @IsTest
    static void testComparisonAccountNameInHeading() {
        DMT_OppBasicFinancialsRenderer renderer = new DMT_OppBasicFinancialsRenderer();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Heading Opp');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.oppAccountParentName = 'Parent Group';
        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>();

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('Basic Financials - Parent Group'), 'Header should include comparison account name branch.');
    }
}