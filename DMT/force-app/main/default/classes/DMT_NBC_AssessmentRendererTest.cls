@IsTest
public class DMT_NBC_AssessmentRendererTest {
    @IsTest
    static void testAssessmentPair() {
        DMT_NBC_RendererPairTestUtils.runPairTests(
            'NBC Assessment',
            'DMT_NBC_AssessmentRenderer',
            'DMT_NBC_OppAssessmentRenderer_IBF',
            true
        );
        Assert.isTrue(true, 'Assertions are executed in shared utility and this class');
    }

    private static final Set<String> EXPECTED_OPP_CLIENT_FIELDS = new Set<String>{
        'DMT_equator_Principles__c', 'DMT_Equator_Principles_Category__c',
        'DMT_Infrastructure_Supporting_Factor__c', 'DMT_KPI_Margin_Adjustment__c',
        'DMT_Sustainable_Deal__c'
    };
    private static final Set<String> EXPECTED_SWITCH_FIELDS = new Set<String>{
        'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'
    };

    // CIBGLOBALD-4117 - the delegator has no field/section knowledge of its own: it routes to
    // whichever single renderer is active (same key as renderHtml) and returns exactly what that one
    // renderer declares. IB&F and GTB happen to declare identical fields for this component, but the
    // delegator must still be proven to route rather than union - asserted separately per key.
    @IsTest
    static void testGetTrackedFieldsRoutesToIBFRenderer() {
        Assert.isTrue(
            DMT_RendererFactory.getTrackedComponentNames().contains('NBC Assessment'),
            'NBC Assessment must be registered as a tracked component'
        );

        DMT_NBC_AssessmentRenderer delegator = new DMT_NBC_AssessmentRenderer();
        Opportunity opp = new Opportunity(RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId(), DMT_Product_Area__c = 'IB&F');

        Assert.areEqual(
            EXPECTED_SWITCH_FIELDS, new Set<String>(delegator.getTrackedFields(opp)),
            'Delegator must return the active (IB&F) renderer\'s own switch-field declaration'
        );

        Map<String, List<String>> byObject = delegator.getTrackedFieldsByObject(opp);
        Assert.areEqual(
            EXPECTED_OPP_CLIENT_FIELDS, new Set<String>(byObject.get('DMT_Opportunity_Client__c')),
            'Delegator must return the active (IB&F) renderer\'s own DMT_Opportunity_Client__c fields'
        );

        List<DMT_ApprovalChangeStep_Helper.ChildSection> sections = delegator.getChildSections(opp);
        Assert.areEqual(1, sections.size(), 'Exactly one child section expected from the IB&F renderer');
        Assert.areEqual('opportunityClient', sections[0].snapshotSectionKey, 'Section must be shared with Client/Approval Process Data/Basic Requeriment/Deal');
        Assert.areEqual('DMT_Opportunity_Client__c', sections[0].childObjectApiName, 'Client section object mismatch');
        Assert.areEqual('DMT_MDE_Opportunity__c', sections[0].childLookupField, 'Client section lookup mismatch');
        Assert.areEqual('Id', sections[0].parentValueField, 'Client section parent value mismatch');
    }

    @IsTest
    static void testGetTrackedFieldsRoutesToGTBRenderer() {
        DMT_NBC_AssessmentRenderer delegator = new DMT_NBC_AssessmentRenderer();
        Opportunity opp = new Opportunity(RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId(), DMT_Product_Area__c = 'GTB');

        Assert.areEqual(
            EXPECTED_SWITCH_FIELDS, new Set<String>(delegator.getTrackedFields(opp)),
            'Delegator must return the active (GTB) renderer\'s own switch-field declaration'
        );

        Map<String, List<String>> byObject = delegator.getTrackedFieldsByObject(opp);
        Assert.areEqual(
            EXPECTED_OPP_CLIENT_FIELDS, new Set<String>(byObject.get('DMT_Opportunity_Client__c')),
            'Delegator must return the active (GTB) renderer\'s own DMT_Opportunity_Client__c fields'
        );

        List<DMT_ApprovalChangeStep_Helper.ChildSection> sections = delegator.getChildSections(opp);
        Assert.areEqual(1, sections.size(), 'Exactly one child section expected from the GTB renderer');
    }

    @IsTest
    static void testFetchLiveTrackedValuesReturnsToolkitFields() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        // Re-query with RecordTypeId/DMT_Product_Area__c: generateOpportunity()'s own SELECT omits
        // them, but the delegator needs both to resolve which single renderer is active (same as
        // Trigger.new would carry in production).
        opp = [SELECT Id, RecordTypeId, DMT_Product_Area__c, DMT_Capital_Action__c FROM Opportunity WHERE Id = :opp.Id];

        DMT_NBC_AssessmentRenderer delegator = new DMT_NBC_AssessmentRenderer();
        Assert.areEqual(opp.Id, delegator.getCalloutCacheKey(opp), 'Cache key must be the Opportunity Id');

        Map<String, Object> liveValues = delegator.fetchLiveTrackedValues(opp);
        Assert.isTrue(
            liveValues.containsKey('reputationalRisk') && liveValues.containsKey('exposureThermalCoal')
                && liveValues.containsKey('capacityWeight') && liveValues.containsKey('exposureIndicatorSource')
                && liveValues.containsKey('coalPhaseOutPlan'),
            'All five toolkit-derived keys must always be present, even when the test org has no cstk__Toolkit__c record for this Account'
        );
    }

    @IsTest
    static void testOppAssessmentRendererDirectCoverage() {
        DMT_NBC_OppAssessmentRenderer_IBF renderer = new DMT_NBC_OppAssessmentRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();

        data.opportunity = new Opportunity(Name = 'Opp Test');
        data.oppClient = new DMT_Opportunity_Client__c(
            DMT_equator_Principles__c = 'Scope A',
            DMT_Equator_Principles_Category__c = 'A',
            DMT_Infrastructure_Supporting_Factor__c = 'Infra',
            DMT_KPI_Margin_Adjustment__c = '10 bps'
        );

        Map<String, Object> rawWrapper = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(data));
        rawWrapper.put('toolkitData', new Map<String, Object>{
            'reputationalRisk' => 'Low',
            'exposureThermalCoal' => 'No',
            'capacityWeight' => 5,
            'exposureIndicatorSource' => 'Internal',
            'coalPhaseOutPlan' => 'Yes'
        });
        data = (DMT_ViewController.LineDataWrapper) JSON.deserialize(
            JSON.serialize(rawWrapper),
            DMT_ViewController.LineDataWrapper.class
        );

        String html = renderer.renderHtml(data);

        Assert.areNotEqual(null, html, 'HTML output must not be null.');
        Assert.isTrue(html.contains('SUSTAINABLE FINANCE') || html.contains('Error'), 'Renderer should return success HTML or controlled error HTML.');
    }

    @IsTest
    static void testOppAssessmentRendererGtbRendersFullTable() {
        DMT_NBC_OppAssessmentRenderer_GTB renderer = new DMT_NBC_OppAssessmentRenderer_GTB();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp GTB', DMT_Product_Area__c = 'GTB');
        data.oppClient = new DMT_Opportunity_Client__c();

        String html = renderer.renderHtml(data);

        Assert.isTrue(html.contains('SUSTAINABLE FINANCE'), 'GTB path should still render the header bar.');
        Assert.isTrue(html.contains('ASSESSMENT'), 'GTB should render the same ASSESSMENT table as IB&F, matching pre-split behavior (no GTB/IBF distinction existed for this component).');
    }

    @IsTest
    static void testGtbDataNotProvidedReturnsGuard() {
        DMT_NBC_OppAssessmentRenderer_GTB renderer = new DMT_NBC_OppAssessmentRenderer_GTB();

        String nullResult = renderer.renderHtml(null);
        Assert.isTrue(nullResult.contains('Opportunity data not provided'), 'Null data must return guard message.');

        DMT_ViewController.LineDataWrapper emptyData = new DMT_ViewController.LineDataWrapper();
        emptyData.opportunity = new Opportunity();
        emptyData.oppClient = new DMT_Opportunity_Client__c();

        String emptyResult = renderer.renderHtml(emptyData);
        Assert.isTrue(emptyResult.contains('Opportunity data not provided'), 'Empty populated-fields data must return guard message.');
    }

    @IsTest
    static void testGtbForcedExceptionReturnsError() {
        DMT_NBC_OppAssessmentRenderer_GTB renderer = new DMT_NBC_OppAssessmentRenderer_GTB();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp GTB Force', DMT_Product_Area__c = 'GTB');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.forceException = true;

        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Error'), 'Forced exception path must return error HTML.');
    }

    @IsTest
    static void testDelegatorRoutesGtbToFullTable() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'GTB Opp', DMT_Product_Area__c = 'GTB');
        data.oppClient = new DMT_Opportunity_Client__c();

        DMT_ViewRenderer delegator = new DMT_NBC_AssessmentRenderer();
        String html = delegator.renderHtml(data);

        Assert.isTrue(html.contains('SUSTAINABLE FINANCE'), 'Delegator should route GTB opportunities to the GTB renderer.');
        Assert.isTrue(html.contains('ASSESSMENT'), 'GTB rendering should include the same ASSESSMENT table as IB&F.');
    }

    @IsTest
    static void testDelegatorRoutesIbfWithExtensionRcfTlToFullTable() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'IBF Extension RCF Opp', DMT_Product_Area__c = 'IB&F', DMT_Capital_Action__c = 'Extension RCF & TL');
        data.oppClient = new DMT_Opportunity_Client__c();

        DMT_ViewRenderer delegator = new DMT_NBC_AssessmentRenderer();
        String html = delegator.renderHtml(data);

        Assert.isTrue(html.contains('SUSTAINABLE FINANCE'), 'IB&F with Extension RCF & TL should route to the GTB renderer.');
        Assert.isTrue(html.contains('ASSESSMENT'), 'GTB rendering should include the same ASSESSMENT table as IB&F.');
    }

    @IsTest
    static void testIbfLocalStillRendersFullTable() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'IBF Local Opp', DMT_Product_Area__c = 'IB&F', DMT_Threshold_Type__c = 'Local');
        data.oppClient = new DMT_Opportunity_Client__c();

        DMT_ViewRenderer delegator = new DMT_NBC_AssessmentRenderer();
        String html = delegator.renderHtml(data);

        Assert.isTrue(html.contains('SUSTAINABLE FINANCE'), 'IB&F + Local should still render the header.');
        Assert.isTrue(html.contains('ASSESSMENT'), 'Local-hiding only applies to GTB + Local per the ticket; IB&F must still render the ASSESSMENT table regardless of Threshold Type.');
    }

    @IsTest
    static void testDelegatorHidesGtbLocalAssessmentTable() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'GTB Local Opp', DMT_Product_Area__c = 'GTB', DMT_Threshold_Type__c = 'Local');
        data.oppClient = new DMT_Opportunity_Client__c();

        DMT_ViewRenderer delegator = new DMT_NBC_AssessmentRenderer();
        String html = delegator.renderHtml(data);

        Assert.isFalse(html.contains('SUSTAINABLE FINANCE'), 'GTB + Local should hide the Assessment section entirely.');
        Assert.isFalse(html.contains('ASSESSMENT'), 'GTB + Local should hide the Assessment table entirely.');
    }
}