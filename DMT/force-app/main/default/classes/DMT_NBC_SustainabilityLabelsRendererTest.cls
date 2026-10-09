@IsTest
public with sharing class DMT_NBC_SustainabilityLabelsRendererTest {
    @IsTest
    static void testSustainabilityLabelsPair() {
        DMT_NBC_RendererPairTestUtils.runPairTests(
            'NBC Sustainability Labels',
            'DMT_NBC_SustainabilityLabelsRenderer',
            'DMT_NBC_OppSustainLabelsRenderer_IBF',
            true
        );
        Assert.isTrue(true, 'Assertions are executed in shared utility and this class');
    }

    @IsTest
    static void testGtbLocalFactoryKeyResolvesToDelegator() {
        Assert.isTrue(DMT_RendererFactory.hasRenderer('GTB Local NBC Sustainability Labels'), 'Factory key must exist: GTB Local NBC Sustainability Labels');
        DMT_ViewRenderer renderer = DMT_RendererFactory.getRenderer('GTB Local NBC Sustainability Labels');
        Assert.isInstanceOfType(renderer, DMT_NBC_SustainabilityLabelsRenderer.class, 'GTB Local NBC Sustainability Labels must resolve to the same delegator as NBC Sustainability Labels');
    }

    @IsTest
    static void testGetTrackedFields() {
        Assert.isTrue(
            DMT_RendererFactory.getTrackedComponentNames().contains('NBC Sustainability Labels'),
            'NBC Sustainability Labels must be registered as a tracked component'
        );
        Assert.isTrue(
            DMT_RendererFactory.getTrackedComponentNames().contains('GTB Local NBC Sustainability Labels'),
            'GTB Local NBC Sustainability Labels shares the same delegator, so it is tracked too'
        );

        DMT_NBC_SustainabilityLabelsRenderer delegator = new DMT_NBC_SustainabilityLabelsRenderer();
        Opportunity opp = new Opportunity(
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId(),
            DMT_Product_Area__c = 'IB&F'
        );

        Assert.areEqual(
            new Set<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'},
            new Set<String>(delegator.getTrackedFields(opp)),
            'Delegator must track the fields that switch which sub-renderer runs'
        );

        Map<String, List<String>> byObject = delegator.getTrackedFieldsByObject(opp);
        Assert.areEqual(
            new Set<String>{
                'DMT_sustainable_deal_assessment__c', 'DMT_Sustainable_Deal_Subtype__c',
                'DMT_sustainable_deal_value__c', 'DMT_Sustainability_deal_value_criteria__c',
                'DMT_PER_Sustainability_Percentage__c', 'DMT_Sustainability_bonus_eligible__c'
            },
            new Set<String>(byObject.get('OpportunityLineItem')),
            'Delegator must union both sub-renderers\' OpportunityLineItem fields (identical on both)'
        );
        Assert.areEqual(
            new Set<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'},
            new Set<String>(byObject.get('Opportunity')),
            'getTrackedFieldsByObject must also carry the switch fields under the Opportunity key - resolveTrackedFieldsForItems never consults getTrackedFields() once getTrackedFieldsByObject() returns non-empty'
        );

        List<DMT_ApprovalChangeStep_Helper.ChildSection> sections = delegator.getChildSections(opp);
        Assert.areEqual(1, sections.size(), 'Exactly one child section expected (both sub-renderers declare the same one)');
        Assert.areEqual('opportunityLineItems', sections[0].snapshotSectionKey, 'Must share the opportunityLineItems section key used by NBC Deal/Transaction Overview/Economics');
        Assert.areEqual('OpportunityLineItem', sections[0].childObjectApiName, 'Child object mismatch');
        Assert.areEqual('OpportunityId', sections[0].childLookupField, 'Lookup field mismatch');
        Assert.areEqual('Id', sections[0].parentValueField, 'Parent value field mismatch');
    }

    @IsTest
    static void testOppSustainabilityLabelsAdditionalCoverage() {
        DMT_NBC_OppSustainLabelsRenderer_IBF renderer = new DMT_NBC_OppSustainLabelsRenderer_IBF();

        DMT_ViewController.LineDataWrapper successData = new DMT_ViewController.LineDataWrapper();
        successData.opportunity = new Opportunity(Name = 'Opp Sustainability Labels', DMT_Product_Area__c = 'CIB');
        successData.oppClient = new DMT_Opportunity_Client__c();
        successData.oppProducts = new List<DMT_ViewController.OpportunityProduct>{
            new DMT_ViewController.OpportunityProduct()
        };
        successData.oppProducts[0].sustainableDealAssessment = 'green';
        successData.oppProducts[0].sustainableDealSubtype = 'subtypeA';
        successData.oppProducts[0].greenActivityFilter = 'delegated';
        successData.oppProducts[0].sustainableDealLabel = 'Label A';
        successData.oppProducts[0].sustainablePercentage = '35';
        successData.oppProducts[0].sustainabilityBonusEligible = 'Yes';

        String successHtml = renderer.renderHtml(successData);

        Assert.areNotEqual(null, successHtml, 'Success HTML must not be null.');
        Assert.isTrue(successHtml.contains('SUSTAINABILITY LABELS'), 'Title should be rendered in HTML.');

        DMT_ViewController.LineDataWrapper altData = new DMT_ViewController.LineDataWrapper();
        altData.opportunity = new Opportunity(Name = 'Opp Sustainability Labels Alt', DMT_Product_Area__c = 'CIB');
        altData.oppClient = new DMT_Opportunity_Client__c();
        altData.oppProducts = new List<DMT_ViewController.OpportunityProduct>();

        String altHtml = renderer.renderHtml(altData);

        Assert.areNotEqual(null, altHtml, 'Alternative path should return controlled HTML.');
    }

    @IsTest
    static void testGtbRendererOwnTrackingMethods() {
        DMT_NBC_OppSustainLabelsRenderer_GTB renderer = new DMT_NBC_OppSustainLabelsRenderer_GTB();
        Opportunity opp = new Opportunity();

        Assert.areEqual(
            new Set<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'},
            new Set<String>(renderer.getTrackedFields(opp)),
            'GTB renderer must self-declare the switch fields'
        );

        Map<String, List<String>> byObject = renderer.getTrackedFieldsByObject(opp);
        Assert.areEqual(
            new Set<String>{
                'DMT_sustainable_deal_assessment__c', 'DMT_Sustainable_Deal_Subtype__c',
                'DMT_sustainable_deal_value__c', 'DMT_Sustainability_deal_value_criteria__c',
                'DMT_PER_Sustainability_Percentage__c', 'DMT_Sustainability_bonus_eligible__c'
            },
            new Set<String>(byObject.get('OpportunityLineItem')),
            'GTB renderer must self-declare its own OpportunityLineItem fields'
        );
        Assert.areEqual(
            new Set<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'},
            new Set<String>(byObject.get('Opportunity')),
            'GTB renderer must self-fold its own switch fields under the Opportunity key'
        );

        List<DMT_ApprovalChangeStep_Helper.ChildSection> sections = renderer.getChildSections(opp);
        Assert.areEqual(1, sections.size(), 'GTB renderer must self-declare its own child section');
        Assert.areEqual('opportunityLineItems', sections[0].snapshotSectionKey, 'Section key mismatch');
    }

    @IsTest
    static void testOppSustainabilityLabelsGtbUsesTransactionTitle() {
        DMT_NBC_OppSustainLabelsRenderer_GTB renderer = new DMT_NBC_OppSustainLabelsRenderer_GTB();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp Sustainability Labels GTB', DMT_Product_Area__c = 'GTB');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.oppProducts = new List<DMT_ViewController.OpportunityProduct>();

        String result = renderer.renderHtml(data);

        Assert.areNotEqual(null, result, 'GTB HTML must not be null.');
        Assert.isTrue(result.contains('TRANSACTION'), 'GTB path should render the TRANSACTION title.');
        Assert.isTrue(!result.contains('SUSTAINABILITY LABELS'), 'GTB path should not use the IBF title.');
    }

    @IsTest
    static void testGtbWithSelectedProductRendersLabelValues() {
        DMT_NBC_OppSustainLabelsRenderer_GTB renderer = new DMT_NBC_OppSustainLabelsRenderer_GTB();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp Sustainability Labels GTB Product', DMT_Product_Area__c = 'GTB');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.oppProducts = new List<DMT_ViewController.OpportunityProduct>{
            new DMT_ViewController.OpportunityProduct()
        };
        data.oppProducts[0].sustainableDealAssessment = 'green';
        data.oppProducts[0].sustainableDealSubtype = 'subtypeA';
        data.oppProducts[0].greenActivityFilter = 'delegated';
        data.oppProducts[0].sustainableDealLabel = 'Label A';
        data.oppProducts[0].sustainablePercentage = '35';
        data.oppProducts[0].sustainabilityBonusEligible = 'Yes';

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('TRANSACTION'), 'GTB path should render the TRANSACTION title.');
        Assert.isTrue(result.contains('green'), 'GTB path should render the selected product\'s Sustainable Deal Assessment value - dealLabel/greenFilter are computed but never rendered by buildLabelsHtml, same as the IBF sibling.');
        Assert.isTrue(result.contains('subtypeA'), 'GTB path should render the selected product\'s Sustainable Deal Subcategory value.');
    }

    @IsTest
    static void testGtbDataNotProvidedReturnsGuard() {
        DMT_NBC_OppSustainLabelsRenderer_GTB renderer = new DMT_NBC_OppSustainLabelsRenderer_GTB();

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
        DMT_NBC_OppSustainLabelsRenderer_GTB renderer = new DMT_NBC_OppSustainLabelsRenderer_GTB();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp GTB Force', DMT_Product_Area__c = 'GTB');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.oppProducts = new List<DMT_ViewController.OpportunityProduct>();
        data.forceException = true;

        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Error'), 'Forced exception path must return error HTML.');
    }

    @IsTest
    static void testDelegatorRoutesGtbToTransactionTitle() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'GTB Opp', DMT_Product_Area__c = 'GTB');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.oppProducts = new List<DMT_ViewController.OpportunityProduct>();

        DMT_ViewRenderer delegator = new DMT_NBC_SustainabilityLabelsRenderer();
        String result = delegator.renderHtml(data);

        Assert.isTrue(result.contains('TRANSACTION'), 'Delegator should route GTB opportunities to the GTB renderer.');
    }

    @IsTest
    static void testDelegatorRoutesIbfWithExtensionRcfTlToTransactionTitle() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'IBF Extension RCF Opp', DMT_Product_Area__c = 'IB&F', DMT_Capital_Action__c = 'Extension RCF & TL');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.oppProducts = new List<DMT_ViewController.OpportunityProduct>();

        DMT_ViewRenderer delegator = new DMT_NBC_SustainabilityLabelsRenderer();
        String result = delegator.renderHtml(data);

        Assert.isTrue(result.contains('TRANSACTION'), 'IB&F with Extension RCF & TL should route to the GTB renderer.');
    }

    @IsTest
    static void testDelegatorKeepsIbfLocalOnIbfTitle() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'IBF Local Opp', DMT_Product_Area__c = 'IB&F', DMT_Threshold_Type__c = 'Local');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.oppProducts = new List<DMT_ViewController.OpportunityProduct>();

        DMT_ViewRenderer delegator = new DMT_NBC_SustainabilityLabelsRenderer();
        String result = delegator.renderHtml(data);

        Assert.isTrue(result.contains('SUSTAINABILITY LABELS'), 'Sustainability Labels must stay on the IBF title even when Local, unlike other NBC components.');
        Assert.isTrue(!result.contains('TRANSACTION'), 'Local must not force this component onto the GTB (TRANSACTION) title.');
    }
}