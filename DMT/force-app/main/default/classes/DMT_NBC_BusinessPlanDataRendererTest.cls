@IsTest
public class DMT_NBC_BusinessPlanDataRendererTest {
    @IsTest
    static void testBusinessPlanDataPair() {
        DMT_NBC_RendererPairTestUtils.runPairTests(
            'NBC Business Plan Data',
            'DMT_NBC_BusinessPlanDataRenderer',
            'DMT_NBC_OppBusinessPlanDataRenderer'
        );
        Assert.isTrue(true, 'Assertions are executed in shared utility and this class');
    }

    @IsTest
    static void testGetTrackedFields() {
        Assert.isTrue(
            DMT_RendererFactory.getTrackedComponentNames().contains('NBC Business Plan Data'),
            'NBC Business Plan Data must be registered as a tracked component'
        );

        Id dmtOpportunityRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
        Opportunity opp = new Opportunity(RecordTypeId = dmtOpportunityRtId);

        DMT_NBC_BusinessPlanDataRenderer delegator = new DMT_NBC_BusinessPlanDataRenderer();
        Map<String, List<String>> byObject = delegator.getTrackedFieldsByObject(opp);
        Assert.areEqual(
            new Set<String>{
                'Current_FY_Corp_Synd_Lending_amount__c', 'Current_FY_Structured_Finance_amount__c', 'Current_FY_Str_Trade_Finance_amount__c',
                'Current_FY_Rates_amount__c', 'Current_FY_GTF_amount__c', 'Current_FY_Working_Capital_amount__c', 'Current_FY_Total_Non_X_Sell_amount__c',
                'Current_FY_ECM_M_A_Amount__c', 'Current_FY_M_A_amount__c', 'Current_FY_DCM_amount__c', 'Current_FY_Credit_Equity_amount__c',
                'Current_FY_FX_CCS_amount__c', 'Current_FY_Cash_Management_amount__c', 'Current_FY_Client_Resources_amount__c',
                'Current_FY_Securities_Services_amount__c', 'Current_FY_Total_X_Sell_amount__c',
                'Current_FY_Total_Revenues_amount__c', 'gf_xb_cust_ope_revenue_cyr_per__c', 'gf_kpi_trans_fees_cyr_amount__c',
                'DMT_Year__c', 'DMT_Booking_Geography__c'
            },
            new Set<String>(byObject.get('DMT_Opportunity_Business_Plan__c')),
            'Delegator must route to the record-type renderer\'s Business Plan fields plus year/geography discriminators'
        );

        List<DMT_ApprovalChangeStep_Helper.ChildSection> sections = delegator.getChildSections(opp);
        Assert.areEqual(1, sections.size(), 'Exactly one child section expected');
        Assert.areEqual('opportunityBusinessPlan', sections[0].snapshotSectionKey, 'Must share the opportunityBusinessPlan section key used by Approval Process Data/Basic Financials/Client Information');
        Assert.areEqual('DMT_Opportunity_Business_Plan__c', sections[0].childObjectApiName, 'Child object mismatch');
        Assert.areEqual('DMT_Opportunity__c', sections[0].childLookupField, 'Lookup field mismatch');
        Assert.areEqual('Id', sections[0].parentValueField, 'Parent value field mismatch');

        Opportunity unknownRtOpp = new Opportunity(RecordTypeId = UserInfo.getOrganizationId());
        Assert.isTrue(delegator.getTrackedFieldsByObject(unknownRtOpp).isEmpty(), 'Unknown record type must yield no tracked fields');
        Assert.isTrue(delegator.getChildSections(unknownRtOpp).isEmpty(), 'Unknown record type must yield no child sections');
    }

    @IsTest
    static void testOppBusinessPlanDataRendererAdditionalCoverage() {
        DMT_NBC_OppBusinessPlanDataRenderer renderer = new DMT_NBC_OppBusinessPlanDataRenderer();

        DMT_ViewController.LineDataWrapper successData = new DMT_ViewController.LineDataWrapper();
        successData.opportunity = new Opportunity(Name = 'Opp BPD');
        successData.oppClient = new DMT_Opportunity_Client__c();
        successData.taxonomyH007BPMap = new Map<String, String>{ 'GLOBAL' => 'Global Label' };
        // GLOBAL is now computed by aggregating non-GLOBAL geography records, so the source record
        // must carry a real geography for the GLOBAL table to render.
        successData.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>{
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'ES',
                DMT_Year__c = String.valueOf(Date.today().year()),
                Current_FY_Total_Revenues_amount__c = 100
            )
        };

        String successHtml = renderer.renderHtml(successData);
        Assert.areNotEqual(null, successHtml, 'Success HTML must not be null.');
        Assert.isTrue(successHtml.contains('Business Plan - Global Label'), 'GLOBAL geography branch should use taxonomy label.');

        DMT_ViewController.LineDataWrapper errorData = new DMT_ViewController.LineDataWrapper();
        errorData.opportunity = new Opportunity(Name = 'Opp BPD Catch');
        errorData.oppClient = new DMT_Opportunity_Client__c();
        // A non-GLOBAL source with a malformed year still propagates into the aggregated GLOBAL
        // record's own DMT_Year__c (the aggregator only skips blank years, not invalid ones), which
        // then trips Integer.valueOf() when the GLOBAL table is rendered — exercising the catch branch.
        errorData.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>{
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'ES',
                DMT_Year__c = 'NOT_A_NUMBER'
            )
        };

        String errorHtml = renderer.renderHtml(errorData);
        Assert.isTrue(errorHtml.contains('Error'), 'Catch branch should return controlled error HTML.');
    }

    @IsTest
    static void testTotalXSellIsRecomputedFromComponentsNotStoredField() {
        DMT_NBC_OppBusinessPlanDataRenderer renderer = new DMT_NBC_OppBusinessPlanDataRenderer();

        // The stored total field is intentionally stale/wrong; the rendered "Total X-Sell" must
        // reflect the live sum of the component rows instead, matching the LWC's own behavior.
        // Amounts are stored as real amounts and displayed in thousands (55000 -> 55,00).
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>{
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'ES',
                DMT_Year__c = String.valueOf(Date.today().year()),
                Current_FY_Total_X_Sell_amount__c = 999999,
                Current_FY_M_A_amount__c = 40000,
                Current_FY_DCM_amount__c = 10000,
                Current_FY_Cash_Management_amount__c = 5000
            )
        };

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('55,00'), 'Total X-Sell should show the live component sum in thousands (40000 + 10000 + 5000 = 55,00).');
        Assert.isFalse(result.contains('999999'), 'The stale stored Total X-Sell field must not be used.');
    }

        @IsTest
    static void testAmountsAreDisplayedInThousands() {
        DMT_NBC_OppBusinessPlanDataRenderer renderer = new DMT_NBC_OppBusinessPlanDataRenderer();

        // Amounts are stored in DB as real amounts and must be displayed in thousands.
        // gf_* fields are not amounts and must be displayed as stored.
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>{
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'ES',
                DMT_Year__c = String.valueOf(Date.today().year()),
                Current_FY_Corp_Synd_Lending_amount__c = 123000,
                gf_xb_cust_ope_revenue_cyr_per__c = 15
            )
        };

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('123,00'), 'An amount stored as 123000 must be displayed in thousands (123,00).');
        Assert.isFalse(result.contains('123.000,00'), 'An amount must not be displayed as the real stored value.');
        Assert.isTrue(result.contains('15,00'), 'Non-amount gf_* fields must be displayed as stored.');
    }

}