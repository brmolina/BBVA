@IsTest
public class DMT_OppApprovalProcessDataRendererTest {

    private static DMT_ViewController.LineDataWrapper buildWrapper() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(
            Name = 'Test Approval Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(60)
        );
        data.oppClient = new DMT_Opportunity_Client__c(
            DMT_Applicable_Jurisdiction__c = 'Spain',
            DMT_Security_Package__c = 'Package A',
            DMT_Rating_Scenarios__c = 'Scenario A',
            DMT_Other_Relevant_Issues__c = 'Issue A',
            DMT_Competition_Deal__c = 'Competitor'
        );
        data.bankingPoolStructures = new List<DMT_Banking_Pool_Structure__c>();
        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>();
        data.participantList = new List<DMT_TeamMember__c>();
        data.riskLineList = new List<DMT_Risk_Line_Term__c>();
        data.featuresList = new List<Map<String, Object>>();
        return data;
    }

    @IsTest
    static void testGuardEmptyWrapperReturnsOpportunityDataNotProvided() {
        DMT_OppApprovalProcessDataRenderer renderer = new DMT_OppApprovalProcessDataRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity();
        data.oppClient = new DMT_Opportunity_Client__c();

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('Opportunity data not provided'), 'Empty wrapper must return guard message.');
    }

    @IsTest
    static void testGuardNullDataReturnsOpportunityDataNotProvided() {
        DMT_OppApprovalProcessDataRenderer renderer = new DMT_OppApprovalProcessDataRenderer();
        String result = renderer.renderHtml(null);
        Assert.isTrue(result.contains('Opportunity data not provided') || result.contains('Error'),
            'Null data must return a controlled response.');
    }

    @IsTest
    static void testHappyPathRendersApprovalProcessData() {
        DMT_OppApprovalProcessDataRenderer renderer = new DMT_OppApprovalProcessDataRenderer();
        DMT_ViewController.LineDataWrapper data = buildWrapper();

        // Inline opportunity with empty Global_Structures__r so the renderer doesn't NPE.
        String oppJson = '{"Name":"Test Approval Opp","StageName":"Prospecting","CloseDate":"2026-12-31",'
            + '"Global_Structures__r":{"totalSize":0,"done":true,"records":[]},'
            + '"OpportunityLineItems":{"totalSize":0,"done":true,"records":[]}}';
        data.opportunity = (Opportunity) JSON.deserialize(oppJson, Opportunity.class);

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'Happy path must return a non-null result.');
        Assert.isTrue(!result.contains('Opportunity data not provided'), 'Should not return no-data message.');
        Assert.isTrue(result.contains('Approval Process Data'), 'Result should contain the Approval Process Data heading.');
        Assert.isTrue(result.contains('Deal'), 'Result should contain the Deal tab header.');
    }

    @IsTest
    static void testWithComparisonAccountNameInHeading() {
        DMT_OppApprovalProcessDataRenderer renderer = new DMT_OppApprovalProcessDataRenderer();
        DMT_ViewController.LineDataWrapper data = buildWrapper();
        data.oppAccountParentName = 'Parent Corp';

        String oppJson = '{"Name":"Test","StageName":"Prospecting","CloseDate":"2026-12-31",'
            + '"Global_Structures__r":{"totalSize":0,"done":true,"records":[]},'
            + '"OpportunityLineItems":{"totalSize":0,"done":true,"records":[]}}';
        data.opportunity = (Opportunity) JSON.deserialize(oppJson, Opportunity.class);

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('Parent Corp'), 'Account parent name should appear in the Approval Process Data heading.');
    }

    @IsTest
    static void testWithBankingPoolStructureDataRendered() {
        DMT_OppApprovalProcessDataRenderer renderer = new DMT_OppApprovalProcessDataRenderer();
        DMT_ViewController.LineDataWrapper data = buildWrapper();

        String oppJson = '{"Name":"Test","StageName":"Prospecting","CloseDate":"2026-12-31",'
            + '"Global_Structures__r":{"totalSize":0,"done":true,"records":[]},'
            + '"OpportunityLineItems":{"totalSize":0,"done":true,"records":[]}}';
        data.opportunity = (Opportunity) JSON.deserialize(oppJson, Opportunity.class);

        DMT_Banking_Pool_Structure__c tier1 = new DMT_Banking_Pool_Structure__c(
            Name = 'Tier 1'
        );
        data.bankingPoolStructures = new List<DMT_Banking_Pool_Structure__c>{ tier1 };

        String result = renderer.renderHtml(data);

        Assert.isTrue(!result.contains('<div>Error:'), 'Banking Pool tier data should render without error.');
    }

    @IsTest
    static void testWithProfitabilityContextDoesNotCrash() {
        DMT_OppApprovalProcessDataRenderer renderer = new DMT_OppApprovalProcessDataRenderer();
        DMT_ViewController.LineDataWrapper data = buildWrapper();

        String oppJson = '{"Name":"Test","StageName":"Prospecting","CloseDate":"2026-12-31",'
            + '"Global_Structures__r":{"totalSize":0,"done":true,"records":[]},'
            + '"OpportunityLineItems":{"totalSize":0,"done":true,"records":[]}}';
        data.opportunity = (Opportunity) JSON.deserialize(oppJson, Opportunity.class);

        Map<String, Object> summaryResult = new Map<String, Object>{
            'rorc' => 0.12,
            'raroec' => 0.08
        };
        Map<String, Object> profitability = new Map<String, Object>{
            'results' => new List<Object>{ summaryResult }
        };
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'profitability' => profitability }
        };

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'Profitability context must return a non-null result.');
        Assert.isTrue(!result.contains('<div>Error:'), 'Profitability context must not produce an error div.');
    }

    @IsTest
    static void testBusinessPlanRendersGlobalAndGeographySpecificTables() {
        DMT_OppApprovalProcessDataRenderer renderer = new DMT_OppApprovalProcessDataRenderer();
        DMT_ViewController.LineDataWrapper data = buildWrapper();

        String oppJson = '{"Name":"Test","StageName":"Prospecting","CloseDate":"2026-12-31",'
            + '"Global_Structures__r":{"totalSize":0,"done":true,"records":[]},'
            + '"OpportunityLineItems":{"totalSize":0,"done":true,"records":[]}}';
        data.opportunity = (Opportunity) JSON.deserialize(oppJson, Opportunity.class);

        String currentYear = String.valueOf(Date.today().year());
        DMT_Opportunity_Business_Plan__c globalBp = new DMT_Opportunity_Business_Plan__c(
            DMT_Booking_Geography__c = 'GLOBAL',
            DMT_Year__c = currentYear,
            DMT_QAOTER__c = 'Qualitative text',
            DMT_Currency__c = 'EUR',
            DMT_Xsell_Cost_to_Income__c = 1.5
        );
        DMT_Opportunity_Business_Plan__c geoBp = new DMT_Opportunity_Business_Plan__c(
            DMT_Booking_Geography__c = 'ES01',
            DMT_Year__c = currentYear
        );
        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>{ globalBp, geoBp };
        data.taxonomyH007BPMap = new Map<String, String>{ 'ES01' => 'Spain' };

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'Business Plan geography tables must render.');
        Assert.isTrue(result.contains('Spain'), 'Non-GLOBAL geography label should be resolved via the taxonomy map.');
        Assert.isTrue(result.contains('Qualitative text'), 'GLOBAL record qualitative assessment should be rendered.');
    }

    @IsTest
    static void testBasicFinancialsRendersFromGlobalBusinessPlanData() {
        DMT_OppApprovalProcessDataRenderer renderer = new DMT_OppApprovalProcessDataRenderer();
        DMT_ViewController.LineDataWrapper data = buildWrapper();

        String oppJson = '{"Name":"Test","StageName":"Prospecting","CloseDate":"2026-12-31",'
            + '"Global_Structures__r":{"totalSize":0,"done":true,"records":[]},'
            + '"OpportunityLineItems":{"totalSize":0,"done":true,"records":[]}}';
        data.opportunity = (Opportunity) JSON.deserialize(oppJson, Opportunity.class);

        String currentYear = String.valueOf(Date.today().year());
        DMT_Opportunity_Business_Plan__c globalBp = new DMT_Opportunity_Business_Plan__c(
            DMT_Booking_Geography__c = 'GLOBAL',
            DMT_Year__c = currentYear,
            DMT_Revenues_number__c = 4321
        );
        DMT_Opportunity_Business_Plan__c geoBp = new DMT_Opportunity_Business_Plan__c(
            DMT_Booking_Geography__c = 'ES01',
            DMT_Year__c = currentYear,
            DMT_Revenues_number__c = 7777
        );
        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>{ globalBp, geoBp };

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('4321'), 'Basic Financials section should render the GLOBAL business plan Revenues value.');
        Assert.isFalse(result.contains('7777'), 'Non-GLOBAL geography record must not appear in the Basic Financials section.');
        Assert.isTrue(result.contains('Other Relevant Ratios'), 'Basic Financials section header rows should still be present.');
    }

    @IsTest
    static void testGlobalStructuresRendersDebtEquityUsesRecords() {
        DMT_OppApprovalProcessDataRenderer renderer = new DMT_OppApprovalProcessDataRenderer();
        DMT_ViewController.LineDataWrapper data = buildWrapper();

        String oppJson = '{"Name":"Test","StageName":"Prospecting","CloseDate":"2026-12-31",'
            + '"Global_Structures__r":{"totalSize":3,"done":true,"records":['
            + '{"attributes":{"type":"DMT_Global_Structure__c"},"Name":"Debt Line 1","DMT_Type__c":"Funding Debt","DMT_Funds__c":10},'
            + '{"attributes":{"type":"DMT_Global_Structure__c"},"Name":"Equity Line 1","DMT_Type__c":"Funding Equity","DMT_Funds__c":20},'
            + '{"attributes":{"type":"DMT_Global_Structure__c"},"Name":"Uses Line 1","DMT_Type__c":"Uses","DMT_Funds__c":30}'
            + ']},'
            + '"OpportunityLineItems":{"totalSize":0,"done":true,"records":[]}}';
        data.opportunity = (Opportunity) JSON.deserialize(oppJson, Opportunity.class);

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'Global Structures with debt/equity/uses records must render.');
        Assert.isTrue(!result.contains('<div>Error:'), 'Global Structures rendering should not error.');
        Assert.isTrue(result.contains('Debt Line 1') && result.contains('Equity Line 1') && result.contains('Uses Line 1'),
            'Debt, Equity, and Uses records should each be rendered.');
    }

    @IsTest
    static void testRenderHtmlReturnsErrorDivWhenBankingPoolStructuresIsNull() {
        DMT_OppApprovalProcessDataRenderer renderer = new DMT_OppApprovalProcessDataRenderer();
        DMT_ViewController.LineDataWrapper data = buildWrapper();

        String oppJson = '{"Name":"Test","StageName":"Prospecting","CloseDate":"2026-12-31",'
            + '"Global_Structures__r":{"totalSize":0,"done":true,"records":[]},'
            + '"OpportunityLineItems":{"totalSize":0,"done":true,"records":[]}}';
        data.opportunity = (Opportunity) JSON.deserialize(oppJson, Opportunity.class);
        data.bankingPoolStructures = null;

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('Error:'), 'A null banking pool structures list should be caught and return a controlled error message.');
    }

    @IsTest
    static void testGetTrackedFieldsReturnsOpportunityNativeFields() {
        // CIBGLOBALD-4117 - the SPPI TEST section (dmt_approval_deal_sppi_fields.js) and
        // DMT_Financial_Sponsors__c (dmt_OppApproversInfoForm) are both editable directly on
        // Opportunity; found untracked via a field-drift audit and fixed.
        DMT_OppApprovalProcessDataRenderer renderer = new DMT_OppApprovalProcessDataRenderer();
        List<String> trackedFields = renderer.getTrackedFields(null);
        Set<String> trackedFieldSet = new Set<String>(trackedFields);
        Assert.isTrue(trackedFieldSet.contains('DMT_SPPI_Status__c'), 'DMT_SPPI_Status__c must be tracked.');
        Assert.isTrue(trackedFieldSet.contains('DMT_SPPI_User__c'), 'DMT_SPPI_User__c must be tracked.');
        Assert.isTrue(trackedFieldSet.contains('DMT_SPPI_File_Uploaded__c'), 'DMT_SPPI_File_Uploaded__c must be tracked.');
        Assert.isTrue(trackedFieldSet.contains('DMT_Financial_Sponsors__c'), 'DMT_Financial_Sponsors__c must be tracked.');
    }

    @IsTest
    static void testRenderHtmlDisplaysFieldDriftAuditFixes() {
        // CIBGLOBALD-4117 - these fields were added to getTrackedFields()/getTrackedFieldsByObject()
        // by an earlier fix but never actually displayed - a tracked-but-invisible field defeats the
        // purpose of the restart mechanism, since the approver reviewing the restarted task would
        // have no way to see what changed. This test verifies the render side, not just tracking.
        DMT_OppApprovalProcessDataRenderer renderer = new DMT_OppApprovalProcessDataRenderer();
        DMT_ViewController.LineDataWrapper data = buildWrapper();

        // DMT_Financial_Sponsors__c and DMT_SPPI_File_Uploaded__c are both Checkbox (Boolean) fields,
        // not free text - confirmed via their own field-meta.xml.
        String oppJson = '{"Name":"Test Approval Opp","StageName":"Prospecting","CloseDate":"2026-12-31",'
            + '"DMT_SPPI_Status__c":"Passed","DMT_SPPI_User__c":"Jane Approver","DMT_SPPI_File_Uploaded__c":true,'
            + '"DMT_Financial_Sponsors__c":true,'
            + '"Global_Structures__r":{"totalSize":0,"done":true,"records":[]},'
            + '"OpportunityLineItems":{"totalSize":0,"done":true,"records":[]}}';
        data.opportunity = (Opportunity) JSON.deserialize(oppJson, Opportunity.class);
        data.oppClient = new DMT_Opportunity_Client__c(
            DMT_Currency__c = 'USD',
            DMT_Xsell_Cost_to_Income__c = 42.5,
            DMT_Top_3_Active_Facilities__c = 'Facility A, Facility B, Facility C'
        );

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('Jane Approver'), 'SPPI User value must be rendered.');
        Assert.isTrue(result.contains('Financial Sponsors'), 'Financial Sponsors label must be rendered.');
        Assert.isTrue(result.contains('data-dmt-checked="true"'), 'Financial Sponsors checkbox must render as checked.');
        Assert.isTrue(result.contains('Facility A, Facility B, Facility C'), 'Top 3 Active Facilities value must be rendered.');
        Assert.isTrue(result.contains('42.5') || result.contains('42.50'), 'Xsell Cost to Income value must be rendered.');
    }

    @IsTest
    static void testGetTrackedFieldsByObjectIncludesClientInfoAndProfitabilityGaps() {
        // CIBGLOBALD-4117 - found untracked via a field-drift audit against the live edit-side LWCs:
        // DMT_Currency__c (Client Info tab's basicFinancialsFieldsExtra), DMT_Xsell_Cost_to_Income__c
        // (Client Profitability tab), DMT_Top_3_Active_Facilities__c (Deal Risk tab).
        DMT_OppApprovalProcessDataRenderer renderer = new DMT_OppApprovalProcessDataRenderer();
        Set<String> oppClientFields = new Set<String>(renderer.getTrackedFieldsByObject(null).get('DMT_Opportunity_Client__c'));
        Assert.isTrue(oppClientFields.contains('DMT_Currency__c'), 'DMT_Currency__c on DMT_Opportunity_Client__c must be tracked.');
        Assert.isTrue(oppClientFields.contains('DMT_Xsell_Cost_to_Income__c'), 'DMT_Xsell_Cost_to_Income__c on DMT_Opportunity_Client__c must be tracked.');
        Assert.isTrue(oppClientFields.contains('DMT_Top_3_Active_Facilities__c'), 'DMT_Top_3_Active_Facilities__c must be tracked.');
    }
}