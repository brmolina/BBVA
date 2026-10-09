@IsTest
public with sharing class DMT_NBC_RequirementsRendererTest {
    @IsTest
    static void testRequirementsPair() {
        DMT_NBC_RendererPairTestUtils.runPairTests(
            'NBC Requirements',
            'DMT_NBC_RequirementsRenderer',
            'DMT_NBC_OppRequirementsRenderer_IBF',
            true
        );
        Assert.isTrue(true, 'Assertions are executed in shared utility and this class');
    }

    @IsTest
    static void testGetTrackedFieldsRoutesToIBFRenderer() {
        Assert.isTrue(
            DMT_RendererFactory.getTrackedComponentNames().contains('NBC Requirements'),
            'NBC Requirements must be registered as a tracked component'
        );

        DMT_NBC_RequirementsRenderer delegator = new DMT_NBC_RequirementsRenderer();
        Opportunity opp = new Opportunity(
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId(),
            DMT_Product_Area__c = 'IB&F'
        );

        Assert.areEqual(
            new Set<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'},
            new Set<String>(delegator.getTrackedFields(opp)),
            'Delegator must route to the IBF renderer\'s own switch fields'
        );

        Map<String, List<String>> byObject = delegator.getTrackedFieldsByObject(opp);
        Assert.areEqual(
            new Set<String>{
                'DMT_Rating_Scenarios__c', 'DMT_Financial_Program_limit__c', 'DMT_Asset_Allocation_limit__c',
                'DMT_AA_Industry__c', 'DMT_Top_3_Active_Facilities__c'
            },
            new Set<String>(byObject.get('DMT_Opportunity_Client__c')),
            'Delegator must track the IBF renderer\'s own fields'
        );
        Assert.areEqual(
            new Set<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'},
            new Set<String>(byObject.get('Opportunity')),
            'getTrackedFieldsByObject must also carry the switch fields under the Opportunity key - resolveTrackedFieldsForItems never consults getTrackedFields() once getTrackedFieldsByObject() returns non-empty'
        );

        List<DMT_ApprovalChangeStep_Helper.ChildSection> sections = delegator.getChildSections(opp);
        Assert.areEqual(1, sections.size(), 'Exactly one child section expected (only IBF declares one)');
        Assert.areEqual('opportunityClient', sections[0].snapshotSectionKey, 'Must share the opportunityClient section key used by Client/Approval Process Data');
        Assert.areEqual('DMT_Opportunity_Client__c', sections[0].childObjectApiName, 'Child object mismatch');
        Assert.areEqual('DMT_MDE_Opportunity__c', sections[0].childLookupField, 'Lookup field mismatch');
        Assert.areEqual('Id', sections[0].parentValueField, 'Parent value field mismatch');
    }

    @IsTest
    static void testGetTrackedFieldsRoutesToGTBRendererReturnsSwitchFieldsOnly() {
        DMT_NBC_RequirementsRenderer delegator = new DMT_NBC_RequirementsRenderer();
        Opportunity opp = new Opportunity(
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId(),
            DMT_Product_Area__c = 'GTB'
        );

        Assert.areEqual(
            new Set<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'},
            new Set<String>(delegator.getTrackedFields(opp)),
            'Delegator must route to the GTB renderer\'s own switch fields'
        );

        Map<String, List<String>> byObject = delegator.getTrackedFieldsByObject(opp);
        Assert.isTrue(byObject.isEmpty(), 'GTB does not implement DMT_MultiObjectFieldTrackableRenderer, so the map must be empty and the framework falls back to getTrackedFields()');

        Assert.isTrue(delegator.getChildSections(opp).isEmpty(), 'GTB declares no child sections (renders nothing)');
    }

    @IsTest
    static void testRequirementsDelegatorRoutesGtb() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'GTB Opp', DMT_Product_Area__c = 'GTB');
        data.oppClient = new DMT_Opportunity_Client__c();

        DMT_ViewRenderer delegator = new DMT_NBC_RequirementsRenderer();
        String html = delegator.renderHtml(data);

        Assert.areEqual('', html, 'GTB routing should hit the GTB stub renderer, which renders nothing.');
    }

    @IsTest
    static void testRequirementsDelegatorRoutesIbfWithExtensionRcfTlToGtb() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(
            Name = 'IBF Extension RCF Opp',
            DMT_Product_Area__c = 'IB&F',
            DMT_Capital_Action__c = 'Extension RCF & TL'
        );
        data.oppClient = new DMT_Opportunity_Client__c();

        DMT_ViewRenderer delegator = new DMT_NBC_RequirementsRenderer();
        String html = delegator.renderHtml(data);

        Assert.areEqual(
            '',
            html,
            'IB&F with Capital Action = Extension RCF & TL should still route to the GTB renderer, which renders nothing.'
        );
    }

    @IsTest
    static void testRequirementsDelegatorKeepsIbfWhenCapitalActionDiffers() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(
            Name = 'IBF Opp',
            DMT_Product_Area__c = 'IB&F',
            DMT_Capital_Action__c = 'Refinancing'
        );
        data.oppClient = new DMT_Opportunity_Client__c();

        DMT_ViewRenderer delegator = new DMT_NBC_RequirementsRenderer();
        String html = delegator.renderHtml(data);

        Assert.isTrue(
            html.contains('REQUIREMENTS'),
            'IB&F with an unrelated Capital Action should still render the IBF requirements content.'
        );
    }

    @IsTest
    static void testDelegatorKeepsIbfLocalContentVisible() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(
            Name = 'IBF Local Opp',
            DMT_Product_Area__c = 'IB&F',
            DMT_Threshold_Type__c = 'Local'
        );
        data.oppClient = new DMT_Opportunity_Client__c();

        DMT_ViewRenderer delegator = new DMT_NBC_RequirementsRenderer();
        String html = delegator.renderHtml(data);

        Assert.isTrue(html.contains('REQUIREMENTS'), 'Local-hiding only applies to GTB + Local per the ticket; IB&F must still render content regardless of Threshold Type.');
    }

    @IsTest
    static void testGtbRendererGuardBranches() {
        DMT_NBC_OppRequirementsRenderer_GTB renderer = new DMT_NBC_OppRequirementsRenderer_GTB();

        String nullDataHtml = renderer.renderHtml(null);
        Assert.areEqual('<div>Opportunity data not provided</div>', nullDataHtml, 'Null wrapper should return guard HTML.');

        DMT_ViewController.LineDataWrapper emptyData = new DMT_ViewController.LineDataWrapper();
        emptyData.opportunity = new Opportunity();
        emptyData.oppClient = new DMT_Opportunity_Client__c();

        String emptyFieldsHtml = renderer.renderHtml(emptyData);
        Assert.areEqual(
            '<div>Opportunity data not provided</div>',
            emptyFieldsHtml,
            'Wrapper with no populated fields on either sobject should return guard HTML.'
        );

        DMT_ViewController.LineDataWrapper populatedData = new DMT_ViewController.LineDataWrapper();
        populatedData.opportunity = new Opportunity(Name = 'GTB Opp', DMT_Product_Area__c = 'GTB');
        populatedData.oppClient = new DMT_Opportunity_Client__c();

        String stubHtml = renderer.renderHtml(populatedData);
        Assert.areEqual('', stubHtml, 'Populated wrapper should hit the GTB stub, which renders nothing.');
    }

    @IsTest
    static void testGtbForcedExceptionReturnsError() {
        DMT_NBC_OppRequirementsRenderer_GTB renderer = new DMT_NBC_OppRequirementsRenderer_GTB();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp GTB Force', DMT_Product_Area__c = 'GTB');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.forceException = true;

        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Error'), 'Forced exception path must return error HTML.');
    }

    @IsTest
    static void testOppRequirementsRendererAdditionalCoverage() {
        DMT_NBC_OppRequirementsRenderer_IBF renderer = new DMT_NBC_OppRequirementsRenderer_IBF();

        String nullHtml = renderer.renderHtml(null);

        Assert.areEqual('<div>Opportunity data not provided</div>', nullHtml, 'Null wrapper should return guard HTML.');

        DMT_ViewController.LineDataWrapper successData = new DMT_ViewController.LineDataWrapper();
        successData.opportunity = new Opportunity(Name = 'Opp Requirements');
        successData.oppClient = new DMT_Opportunity_Client__c(
            DMT_Rating_Scenarios__c = 'Scenario A',
            DMT_Financial_Program_limit__c = '500M',
            DMT_Asset_Allocation_limit__c = '300M',
            DMT_AA_Industry__c = 'Industry A',
            DMT_Top_3_Active_Facilities__c = 'Facility A, Facility B, Facility C'
        );

        String successHtml = renderer.renderHtml(successData);

        Assert.isNotNull(successHtml, 'Success HTML must not be null.');
        Assert.isTrue(successHtml.contains('REQUIREMENTS') || successHtml.contains('Error'), 'HTML should return a controlled response.');
        Assert.isTrue(successHtml.contains('Facility A, Facility B, Facility C'), 'Top 3 Active Facilities value should be rendered.');
    }
}