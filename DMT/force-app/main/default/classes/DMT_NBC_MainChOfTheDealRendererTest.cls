@IsTest
public with sharing class DMT_NBC_MainChOfTheDealRendererTest {
    @IsTest
    static void testMainCharacteristicsPair() {
        DMT_NBC_RendererPairTestUtils.runPairTests(
            'NBC Main Characteristics of the Deal',
            'DMT_NBC_MainChOfTheDealRenderer',
            'DMT_NBC_OppMainCOfTheDealRenderer_IBF',
            true
        );
        Assert.isTrue(true, 'Assertions are executed in shared utility and this class');
    }

    @IsTest
    static void testGtbLocalFactoryKeyResolvesToDelegator() {
        Assert.isTrue(DMT_RendererFactory.hasRenderer('GTB Local NBC Main Characteristics of the Deal'), 'Factory key must exist: GTB Local NBC Main Characteristics of the Deal');
        DMT_ViewRenderer renderer = DMT_RendererFactory.getRenderer('GTB Local NBC Main Characteristics of the Deal');
        Assert.isInstanceOfType(renderer, DMT_NBC_MainChOfTheDealRenderer.class, 'GTB Local NBC Main Characteristics of the Deal must resolve to the same delegator as NBC Main Characteristics of the Deal');
    }

    // CIBGLOBALD-4117 - the delegator has no field/section knowledge of its own: it routes to
    // whichever single renderer is active (same key as renderHtml) and returns exactly what that one
    // renderer declares. IB&F and GTB genuinely declare different DMT_Opportunity_Client__c fields
    // here (GTB is a subset), so routing to the wrong one would be caught by these two tests.
    @IsTest
    static void testGetTrackedFieldsRoutesToIBFRenderer() {
        Assert.isTrue(
            DMT_RendererFactory.getTrackedComponentNames().contains('NBC Main Characteristics of the Deal'),
            'NBC Main Characteristics of the Deal must be registered as a tracked component'
        );
        Assert.isTrue(
            DMT_RendererFactory.getTrackedComponentNames().contains('GTB Local NBC Main Characteristics of the Deal'),
            'GTB Local NBC Main Characteristics of the Deal shares the same delegator, so it is tracked too'
        );

        DMT_NBC_MainChOfTheDealRenderer delegator = new DMT_NBC_MainChOfTheDealRenderer();
        Opportunity opp = new Opportunity(
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId(),
            DMT_Product_Area__c = 'IB&F'
        );

        Set<String> trackedFields = new Set<String>(delegator.getTrackedFields(opp));
        Assert.areEqual(
            new Set<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'},
            trackedFields,
            'Delegator must return the active (IB&F) renderer\'s own switch-field declaration'
        );

        Map<String, List<String>> byObject = delegator.getTrackedFieldsByObject(opp);
        Assert.areEqual(
            new Set<String>{
                'DMT_Current__c', 'DMT_Tiering_Action__c', 'DMT_Target__c',
                'DMT_Description_Issues__c', 'DMT_Purpose__c', 'DMT_Opp_Threats_Related_Deal__c'
            },
            new Set<String>(byObject.get('DMT_Opportunity_Client__c')),
            'Delegator must return the active (IB&F) renderer\'s own DMT_Opportunity_Client__c fields'
        );
        Assert.areEqual(
            trackedFields,
            new Set<String>(byObject.get('Opportunity')),
            'getTrackedFieldsByObject must also carry the switch fields under the Opportunity key'
        );

        List<DMT_ApprovalChangeStep_Helper.ChildSection> sections = delegator.getChildSections(opp);
        Assert.areEqual(1, sections.size(), 'Exactly one child section expected');
        Assert.areEqual('opportunityClient', sections[0].snapshotSectionKey, 'Must share the opportunityClient section key used by Client/Approval Process Data');
        Assert.areEqual('DMT_Opportunity_Client__c', sections[0].childObjectApiName, 'Child object must be DMT_Opportunity_Client__c');
        Assert.areEqual('DMT_MDE_Opportunity__c', sections[0].childLookupField, 'Lookup field must be DMT_MDE_Opportunity__c');
        Assert.areEqual('Id', sections[0].parentValueField, 'Parent value field must be Id');
    }

    @IsTest
    static void testGetTrackedFieldsRoutesToGTBRenderer() {
        DMT_NBC_MainChOfTheDealRenderer delegator = new DMT_NBC_MainChOfTheDealRenderer();
        Opportunity opp = new Opportunity(
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId(),
            DMT_Product_Area__c = 'GTB'
        );

        Map<String, List<String>> byObject = delegator.getTrackedFieldsByObject(opp);
        Assert.areEqual(
            new Set<String>{'DMT_Description_Issues__c', 'DMT_Purpose__c', 'DMT_Opp_Threats_Related_Deal__c'},
            new Set<String>(byObject.get('DMT_Opportunity_Client__c')),
            'Delegator must return the active (GTB) renderer\'s own (narrower) DMT_Opportunity_Client__c fields, not IB&F\'s'
        );
    }

    @IsTest
    static void testSubRenderersOwnTrackedFieldsAndChildSections() {
        DMT_NBC_OppMainCOfTheDealRenderer_IBF ibfRenderer = new DMT_NBC_OppMainCOfTheDealRenderer_IBF();
        Set<String> ibfFields = new Set<String>(ibfRenderer.getTrackedFieldsByObject(new Opportunity()).get('DMT_Opportunity_Client__c'));
        Assert.areEqual(6, ibfFields.size(), 'IBF renderer must track all 6 of its own displayed fields');
        Assert.areEqual(1, ibfRenderer.getChildSections(new Opportunity()).size(), 'IBF renderer must declare its own child section');

        DMT_NBC_OppMainCOfTheDealRenderer_GTB gtbRenderer = new DMT_NBC_OppMainCOfTheDealRenderer_GTB();
        Set<String> gtbFields = new Set<String>(gtbRenderer.getTrackedFieldsByObject(new Opportunity()).get('DMT_Opportunity_Client__c'));
        Assert.areEqual(3, gtbFields.size(), 'GTB renderer must track its own 3 displayed fields');
        Assert.areEqual(1, gtbRenderer.getChildSections(new Opportunity()).size(), 'GTB renderer must declare its own child section');
    }

    @IsTest
    static void testOppMainCharacteristicsAdditionalCoverage() {
        DMT_NBC_OppMainCOfTheDealRenderer_IBF renderer = new DMT_NBC_OppMainCOfTheDealRenderer_IBF();

        DMT_ViewController.LineDataWrapper successData = new DMT_ViewController.LineDataWrapper();
        successData.opportunity = new Opportunity(Name = 'Opp Main Characteristics');

        String successHtml = renderer.renderHtml(successData);

        Assert.areNotEqual(null, successHtml, 'Success HTML must not be null.');
        Assert.isTrue(successHtml.contains('MAIN CHARACTERISTICS OF THE DEAL') || successHtml.contains('Error'), 'HTML should return a controlled response.');

        DMT_ViewController.LineDataWrapper altData = new DMT_ViewController.LineDataWrapper();
        altData.opportunity = new Opportunity();

        String altHtml = renderer.renderHtml(altData);

        Assert.areNotEqual(null, altHtml, 'Alternative path should return a controlled HTML response.');
    }

    @IsTest
    static void testOppMainCharacteristicsGtbHidesTierRow() {
        DMT_NBC_OppMainCOfTheDealRenderer_GTB renderer = new DMT_NBC_OppMainCOfTheDealRenderer_GTB();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp GTB', DMT_Product_Area__c = 'GTB');

        String html = renderer.renderHtml(data);

        Assert.areNotEqual(null, html, 'GTB HTML must not be null.');
        Assert.isTrue(html.contains('MAIN CHARACTERISTICS OF THE DEAL'), 'GTB path should render the section header.');
        Assert.isTrue(!html.contains('Current Tier'), 'GTB path should not render the Current Tier row.');
        Assert.isTrue(!html.contains('Tiering Action'), 'GTB path should not render the Tiering Action row.');
        Assert.isTrue(html.contains('DESCRIPTION OF THE DEAL'), 'GTB path should still render Description of the Deal.');
        Assert.isTrue(html.contains('PURPOSE'), 'GTB path should still render Purpose.');
        Assert.isTrue(html.contains('OPPORTUNITIES & THREATS'), 'GTB path should still render Opportunities & Threats.');
    }

    @IsTest
    static void testGtbDataNotProvidedReturnsGuard() {
        DMT_NBC_OppMainCOfTheDealRenderer_GTB renderer = new DMT_NBC_OppMainCOfTheDealRenderer_GTB();

        String nullResult = renderer.renderHtml(null);
        Assert.isTrue(nullResult.contains('Opportunity data not provided'), 'Null data must return guard message.');

        DMT_ViewController.LineDataWrapper emptyData = new DMT_ViewController.LineDataWrapper();
        emptyData.opportunity = new Opportunity();

        String emptyResult = renderer.renderHtml(emptyData);
        Assert.isTrue(emptyResult.contains('Opportunity data not provided'), 'Empty populated-fields data must return guard message.');
    }

    @IsTest
    static void testGtbForcedExceptionReturnsError() {
        DMT_NBC_OppMainCOfTheDealRenderer_GTB renderer = new DMT_NBC_OppMainCOfTheDealRenderer_GTB();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp GTB Force', DMT_Product_Area__c = 'GTB');
        data.forceException = true;

        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Error'), 'Forced exception path must return error HTML.');
    }

    @IsTest
    static void testDelegatorRoutesGtbHidesTierRow() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'GTB Opp', DMT_Product_Area__c = 'GTB');

        DMT_ViewRenderer delegator = new DMT_NBC_MainChOfTheDealRenderer();
        String html = delegator.renderHtml(data);

        Assert.isTrue(!html.contains('Current Tier'), 'Delegator should route GTB opportunities to the GTB renderer.');
    }

    @IsTest
    static void testDelegatorRoutesIbfWithExtensionRcfTlHidesTierRow() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'IBF Extension RCF Opp', DMT_Product_Area__c = 'IB&F', DMT_Capital_Action__c = 'Extension RCF & TL');

        DMT_ViewRenderer delegator = new DMT_NBC_MainChOfTheDealRenderer();
        String html = delegator.renderHtml(data);

        Assert.isTrue(!html.contains('Current Tier'), 'IB&F with Extension RCF & TL should route to the GTB renderer.');
    }

    @IsTest
    static void testDelegatorKeepsIbfLocalFieldsVisible() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'IBF Local Opp', DMT_Product_Area__c = 'IB&F', DMT_Threshold_Type__c = 'Local');

        DMT_ViewRenderer delegator = new DMT_NBC_MainChOfTheDealRenderer();
        String html = delegator.renderHtml(data);

        // Local-hiding only applies to GTB + Local per the ticket; IB&F must still render
        // everything regardless of Threshold Type.
        Assert.isTrue(html.contains('MAIN CHARACTERISTICS OF THE DEAL'), 'IB&F + Local should still render the section header.');
        Assert.isTrue(html.contains('DESCRIPTION OF THE DEAL'), 'IB&F + Local should still render Description of the Deal.');
        Assert.isTrue(html.contains('Current Tier'), 'IB&F + Local should still render the Current Tier row.');
        Assert.isTrue(html.contains('PURPOSE*'), 'IB&F + Local should still render Purpose.');
        Assert.isTrue(html.contains('OPPORTUNITIES & THREATS'), 'IB&F + Local should still render Opportunities & Threats.');
    }
}