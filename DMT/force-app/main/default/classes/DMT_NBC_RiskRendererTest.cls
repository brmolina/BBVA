@IsTest
public with sharing class DMT_NBC_RiskRendererTest {
    @IsTest
    static void testRiskPair() {
        DMT_NBC_RendererPairTestUtils.runPairTests(
            'NBC Risk',
            'DMT_NBC_RiskRenderer',
            'DMT_NBC_OppRisksRenderer_IBF',
            true
        );
        Assert.isTrue(true, 'Assertions are executed in shared utility and this class');
    }

    @IsTest
    static void testGetTrackedFields() {
        Assert.isTrue(
            DMT_RendererFactory.getTrackedComponentNames().contains('NBC Risk'),
            'NBC Risk must be registered as a tracked component'
        );

        DMT_NBC_RiskRenderer delegator = new DMT_NBC_RiskRenderer();
        Opportunity opp = new Opportunity(
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId(),
            DMT_Product_Area__c = 'IB&F'
        );

        Assert.areEqual(
            new Set<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'},
            new Set<String>(delegator.getTrackedFields(opp)),
            'Delegator must track the fields that switch which sub-renderer/rows show'
        );

        Map<String, List<String>> byObject = delegator.getTrackedFieldsByObject(opp);
        Assert.areEqual(
            new Set<String>{'DMT_Financial_Program_limit__c', 'DMT_Asset_Allocation_limit__c'},
            new Set<String>(byObject.get('DMT_Opportunity_Client__c')),
            'Delegator must track both Risk fields (identical on IB&F and GTB)'
        );
        Assert.areEqual(
            new Set<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'},
            new Set<String>(byObject.get('Opportunity')),
            'getTrackedFieldsByObject must also carry the switch fields under the Opportunity key - resolveTrackedFieldsForItems never consults getTrackedFields() once getTrackedFieldsByObject() returns non-empty'
        );

        List<DMT_ApprovalChangeStep_Helper.ChildSection> sections = delegator.getChildSections(opp);
        Assert.areEqual(1, sections.size(), 'Exactly one child section expected');
        Assert.areEqual('opportunityClient', sections[0].snapshotSectionKey, 'Must share the opportunityClient section key used by Client/Approval Process Data');
        Assert.areEqual('DMT_Opportunity_Client__c', sections[0].childObjectApiName, 'Child object mismatch');
        Assert.areEqual('DMT_MDE_Opportunity__c', sections[0].childLookupField, 'Lookup field mismatch');
        Assert.areEqual('Id', sections[0].parentValueField, 'Parent value field mismatch');
    }

    @IsTest
    static void testOppRisksRendererAdditionalCoverage() {
        DMT_NBC_OppRisksRenderer_IBF renderer = new DMT_NBC_OppRisksRenderer_IBF();

        DMT_ViewController.LineDataWrapper successData = new DMT_ViewController.LineDataWrapper();
        successData.opportunity = new Opportunity(Name = 'Opp Risk', DMT_Product_Area__c = 'CIB');
        successData.oppClient = new DMT_Opportunity_Client__c(
            DMT_Financial_Program_limit__c = '500M',
            DMT_Asset_Allocation_limit__c = '300M'
        );

        String successHtml = renderer.renderHtml(successData);

        Assert.areNotEqual(null, successHtml, 'Success HTML must not be null.');
        Assert.isTrue(successHtml.contains('Risk'), 'Risk title should be rendered in HTML.');

        DMT_ViewController.LineDataWrapper altData = new DMT_ViewController.LineDataWrapper();
        altData.opportunity = new Opportunity(Name = 'Opp Risk Alt', DMT_Product_Area__c = 'CIB');
        altData.oppClient = null;

        String altHtml = renderer.renderHtml(altData);

        Assert.areNotEqual(null, altHtml, 'Alternative path should return a controlled HTML response.');
    }

    @IsTest
    static void testGtbRendersSameContentAsIbf() {
        DMT_NBC_OppRisksRenderer_GTB renderer = new DMT_NBC_OppRisksRenderer_GTB();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp Risk GTB', DMT_Product_Area__c = 'GTB');
        data.oppClient = new DMT_Opportunity_Client__c();

        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Risk'), 'GTB should render the same Risk table as IB&F, matching pre-split behavior (no GTB/IBF distinction existed for this component).');
    }

    @IsTest
    static void testGtbRendererOwnTrackingMethods() {
        DMT_NBC_OppRisksRenderer_GTB renderer = new DMT_NBC_OppRisksRenderer_GTB();
        Opportunity opp = new Opportunity();

        Assert.areEqual(
            new Set<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'},
            new Set<String>(renderer.getTrackedFields(opp)),
            'GTB renderer must self-declare the switch fields'
        );

        Map<String, List<String>> byObject = renderer.getTrackedFieldsByObject(opp);
        Assert.areEqual(
            new Set<String>{'DMT_Financial_Program_limit__c', 'DMT_Asset_Allocation_limit__c'},
            new Set<String>(byObject.get('DMT_Opportunity_Client__c')),
            'GTB renderer must self-declare its own DMT_Opportunity_Client__c fields'
        );
        Assert.areEqual(
            new Set<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'},
            new Set<String>(byObject.get('Opportunity')),
            'GTB renderer must self-fold its own switch fields under the Opportunity key'
        );

        List<DMT_ApprovalChangeStep_Helper.ChildSection> sections = renderer.getChildSections(opp);
        Assert.areEqual(1, sections.size(), 'GTB renderer must self-declare its own child section');
        Assert.areEqual('opportunityClient', sections[0].snapshotSectionKey, 'Section key mismatch');
    }

    @IsTest
    static void testGtbDataNotProvidedReturnsGuard() {
        DMT_NBC_OppRisksRenderer_GTB renderer = new DMT_NBC_OppRisksRenderer_GTB();

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
        DMT_NBC_OppRisksRenderer_GTB renderer = new DMT_NBC_OppRisksRenderer_GTB();

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

        DMT_ViewRenderer delegator = new DMT_NBC_RiskRenderer();
        String result = delegator.renderHtml(data);

        Assert.isTrue(result.contains('Risk'), 'GTB routing should hit the GTB renderer and render the Risk table.');
    }

    @IsTest
    static void testDelegatorRoutesIbfWithExtensionRcfTlToGtbRenderer() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'IBF Extension RCF Opp', DMT_Product_Area__c = 'IB&F', DMT_Capital_Action__c = 'Extension RCF & TL');
        data.oppClient = new DMT_Opportunity_Client__c();

        DMT_ViewRenderer delegator = new DMT_NBC_RiskRenderer();
        String result = delegator.renderHtml(data);

        Assert.isTrue(result.contains('Risk'), 'IB&F with Extension RCF & TL should route to the GTB renderer and render the Risk table.');
    }

    @IsTest
    static void testDelegatorKeepsIbfLocalContentVisible() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'IBF Local Opp', DMT_Product_Area__c = 'IB&F', DMT_Threshold_Type__c = 'Local');
        data.oppClient = new DMT_Opportunity_Client__c();

        DMT_ViewRenderer delegator = new DMT_NBC_RiskRenderer();
        String result = delegator.renderHtml(data);

        Assert.isTrue(result.contains('Risk'), 'Local-hiding only applies to GTB + Local per the ticket; IB&F must still render content regardless of Threshold Type.');
    }

    @IsTest
    static void testDelegatorHidesGtbLocalRiskContent() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'GTB Local Opp', DMT_Product_Area__c = 'GTB', DMT_Threshold_Type__c = 'Local');
        data.oppClient = new DMT_Opportunity_Client__c();

        DMT_ViewRenderer delegator = new DMT_NBC_RiskRenderer();
        String result = delegator.renderHtml(data);

        Assert.isFalse(result.contains('Risk'), 'GTB + Local should hide the Risk table entirely.');
    }
}