@IsTest
public with sharing class DMT_NBC_SustainabilityInd_Test {
    @IsTest
    static void testSustainabilityIndicatorsPair() {
        DMT_NBC_RendererPairTestUtils.runPairTests(
            'NBC Sustainability Indicators',
            'DMT_NBC_SustainabilityIndicatorsRenderer',
            'DMT_NBC_OppSustainabilityIndRenderer_IBF',
            true
        );
        Assert.isTrue(true, 'Assertions are executed in shared utility and this class');
    }

    // CIBGLOBALD-4117 - the delegator has no field/section/callout knowledge of its own: it routes to
    // whichever single renderer is active (same key as renderHtml) and returns exactly what that one
    // renderer declares. The GTB renderer reads nothing dynamic (hardcoded placeholder text only), so
    // routing there must return empty everything - a real, meaningful difference from IB&F, not just
    // a formality.
    @IsTest
    static void testGetTrackedFieldsRoutesToIBFRenderer() {
        Assert.isTrue(
            DMT_RendererFactory.getTrackedComponentNames().contains('NBC Sustainability Indicators'),
            'NBC Sustainability Indicators must be registered as a tracked component'
        );

        DMT_NBC_SustainabilityIndicatorsRenderer delegator = new DMT_NBC_SustainabilityIndicatorsRenderer();
        // A real, inserted record - fetchLiveTrackedValues() queries by Id, which an unsaved
        // in-memory Opportunity doesn't have.
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        opp.DMT_Product_Area__c = 'IB&F';
        update opp;
        opp = [SELECT Id, RecordTypeId, DMT_Product_Area__c, DMT_Capital_Action__c FROM Opportunity WHERE Id = :opp.Id];

        Assert.areEqual(
            new Set<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'},
            new Set<String>(delegator.getTrackedFields(opp)),
            'Delegator must return the active (IB&F) renderer\'s own switch-field declaration'
        );

        Map<String, List<String>> byObject = delegator.getTrackedFieldsByObject(opp);
        Assert.areEqual(
            new Set<String>{'DMT_Group_Engagement_Plan__c', 'DMT_comments__c'},
            new Set<String>(byObject.get('DMT_Opportunity_Client__c')),
            'Delegator must return the active (IB&F) renderer\'s own DMT_Opportunity_Client__c fields'
        );

        List<DMT_ApprovalChangeStep_Helper.ChildSection> sections = delegator.getChildSections(opp);
        Assert.areEqual(1, sections.size(), 'Exactly one child section expected from the IB&F renderer');
        Assert.areEqual('opportunityClient', sections[0].snapshotSectionKey, 'Section must be shared with Client/Approval Process Data/Basic Requeriment/Deal/Assessment/NBC Client');

        Assert.areEqual(opp.Id, delegator.getCalloutCacheKey(opp), 'Cache key must be the Opportunity Id');
        Map<String, Object> liveValues = delegator.fetchLiveTrackedValues(opp);
        Assert.isTrue(
            liveValues.containsKey('tri') && liveValues.containsKey('positioning')
                && liveValues.containsKey('emissionIntensityMetric') && liveValues.containsKey('planLink'),
            'The active (IB&F) renderer\'s toolkit-derived keys must be present, even with no cstk__Toolkit__c record for this Account'
        );
    }

    @IsTest
    static void testGetTrackedFieldsRoutesToGTBRendererReturnsNothing() {
        DMT_NBC_SustainabilityIndicatorsRenderer delegator = new DMT_NBC_SustainabilityIndicatorsRenderer();
        Opportunity opp = new Opportunity(RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId(), DMT_Product_Area__c = 'GTB');

        Assert.areEqual(
            new Set<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'},
            new Set<String>(delegator.getTrackedFields(opp)),
            'GTB still watches the switch fields even though it reads nothing else'
        );

        Map<String, List<String>> byObject = delegator.getTrackedFieldsByObject(opp);
        Assert.isTrue(
            byObject.get('DMT_Opportunity_Client__c') == null || byObject.get('DMT_Opportunity_Client__c').isEmpty(),
            'GTB reads no DMT_Opportunity_Client__c fields - hardcoded placeholder text only'
        );

        Assert.isTrue(delegator.getChildSections(opp).isEmpty(), 'GTB declares no child sections');
        Assert.isTrue(delegator.fetchLiveTrackedValues(opp).isEmpty(), 'GTB reads no toolkit data');
    }

    @IsTest
    static void testOppSustainabilityIndicatorsAdditionalCoverage() {
        DMT_NBC_OppSustainabilityIndRenderer_IBF renderer = new DMT_NBC_OppSustainabilityIndRenderer_IBF();

        DMT_ViewController.LineDataWrapper successData = new DMT_ViewController.LineDataWrapper();
        successData.opportunity = new Opportunity(Name = 'Opp Sustainability', DMT_Product_Area__c = 'CIB');
        successData.oppClient = new DMT_Opportunity_Client__c();

        String successHtml = renderer.renderHtml(successData);

        Assert.areNotEqual(null, successHtml, 'Success HTML must not be null.');
        Assert.isTrue(successHtml.contains('SUSTAINABILITY INDICATORS'), 'Sustainability title should be rendered.');

        DMT_ViewController.LineDataWrapper catchData = new DMT_ViewController.LineDataWrapper();
        catchData.opportunity = new Opportunity(Name = 'Opp Sustainability Catch', DMT_Product_Area__c = 'IB&F');
        catchData.oppClient = null;

        String catchHtml = renderer.renderHtml(catchData);

        Assert.areNotEqual(null, catchHtml, 'Catch path should return a controlled HTML response.');
    }

    @IsTest
    static void testGtbRendersDefaultPlaceholderValues() {
        DMT_NBC_OppSustainabilityIndRenderer_GTB renderer = new DMT_NBC_OppSustainabilityIndRenderer_GTB();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp Sustainability GTB', DMT_Product_Area__c = 'GTB');
        data.oppClient = new DMT_Opportunity_Client__c();

        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('SUSTAINABILITY INDICATORS'), 'GTB should still render the same table structure as pre-split, with default placeholder values.');
        Assert.isTrue(result.contains('>5<'), 'GTB should render the default TRI placeholder value, matching pre-split behavior.');
    }

    @IsTest
    static void testGtbDataNotProvidedReturnsGuard() {
        DMT_NBC_OppSustainabilityIndRenderer_GTB renderer = new DMT_NBC_OppSustainabilityIndRenderer_GTB();

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
        DMT_NBC_OppSustainabilityIndRenderer_GTB renderer = new DMT_NBC_OppSustainabilityIndRenderer_GTB();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp GTB Force', DMT_Product_Area__c = 'GTB');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.forceException = true;

        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Error'), 'Forced exception path must return error HTML.');
    }

    @IsTest
    static void testDelegatorRoutesGtbToGtbRenderer() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'GTB Opp', DMT_Product_Area__c = 'GTB');
        data.oppClient = new DMT_Opportunity_Client__c();

        DMT_ViewRenderer delegator = new DMT_NBC_SustainabilityIndicatorsRenderer();
        String result = delegator.renderHtml(data);

        Assert.isTrue(result.contains('SUSTAINABILITY INDICATORS'), 'GTB routing should hit the GTB renderer and render the default-value table.');
    }

    @IsTest
    static void testDelegatorRoutesIbfWithExtensionRcfTlToGtbRenderer() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'IBF Extension RCF Opp', DMT_Product_Area__c = 'IB&F', DMT_Capital_Action__c = 'Extension RCF & TL');
        data.oppClient = new DMT_Opportunity_Client__c();

        DMT_ViewRenderer delegator = new DMT_NBC_SustainabilityIndicatorsRenderer();
        String result = delegator.renderHtml(data);

        Assert.isTrue(result.contains('SUSTAINABILITY INDICATORS'), 'IB&F with Extension RCF & TL should route to the GTB renderer and render the default-value table.');
    }

    @IsTest
    static void testDelegatorKeepsIbfLocalContentVisible() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'IBF Local Opp', DMT_Product_Area__c = 'IB&F', DMT_Threshold_Type__c = 'Local');
        data.oppClient = new DMT_Opportunity_Client__c();

        DMT_ViewRenderer delegator = new DMT_NBC_SustainabilityIndicatorsRenderer();
        String result = delegator.renderHtml(data);

        Assert.isTrue(result.contains('SUSTAINABILITY INDICATORS'), 'Local-hiding only applies to GTB + Local per the ticket; IB&F must still render content regardless of Threshold Type.');
    }

    @IsTest
    static void testDelegatorHidesGtbLocalSustainabilityIndicators() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'GTB Local Opp', DMT_Product_Area__c = 'GTB', DMT_Threshold_Type__c = 'Local');
        data.oppClient = new DMT_Opportunity_Client__c();

        DMT_ViewRenderer delegator = new DMT_NBC_SustainabilityIndicatorsRenderer();
        String result = delegator.renderHtml(data);

        Assert.isFalse(result.contains('SUSTAINABILITY INDICATORS'), 'GTB + Local should hide the Sustainability Indicators table entirely.');
    }
}