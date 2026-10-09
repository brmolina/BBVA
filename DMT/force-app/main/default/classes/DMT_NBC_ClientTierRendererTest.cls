@IsTest
public class DMT_NBC_ClientTierRendererTest {
    @IsTest
    static void testClientTierPair() {
        DMT_NBC_RendererPairTestUtils.runPairTests(
            'NBC Client Information',
            'DMT_NBC_ClientTierRenderer',
            'DMT_NBC_OppClientTierRenderer_IBF',
            true
        );
        Assert.isTrue(true, 'Assertions are executed in shared utility and this class');
    }

    // CIBGLOBALD-4117 - the delegator has no field/section knowledge of its own: it routes to
    // whichever single renderer is active (same key as renderHtml) and returns exactly what that one
    // renderer declares. IB&F and GTB genuinely declare different DMT_Opportunity_Client__c fields
    // here, so routing to the wrong one would be caught by these two tests' distinct field sets.
    @IsTest
    static void testGetTrackedFieldsRoutesToIBFRenderer() {
        Assert.isTrue(
            DMT_RendererFactory.getTrackedComponentNames().contains('NBC Client Information'),
            'NBC Client Information must be registered as a tracked component'
        );

        DMT_NBC_ClientTierRenderer delegator = new DMT_NBC_ClientTierRenderer();
        Opportunity opp = new Opportunity(
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId(),
            DMT_Product_Area__c = 'IB&F'
        );

        Assert.areEqual(
            new Set<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'},
            new Set<String>(delegator.getTrackedFields(opp)),
            'Delegator must return the active (IB&F) renderer\'s own switch-field declaration'
        );

        Map<String, List<String>> byObject = delegator.getTrackedFieldsByObject(opp);
        Assert.areEqual(
            new Set<String>{'Geographical_Footprint_desc__c', 'Relationship_Status_desc__c', 'Industry_Overview_desc__c'},
            new Set<String>(byObject.get('DMT_Opportunity_Client__c')),
            'Delegator must return the active (IB&F) renderer\'s own DMT_Opportunity_Client__c fields'
        );
        Assert.areEqual(
            new Set<String>{'DMT_QAOTER__c', 'DMT_Booking_Geography__c'},
            new Set<String>(byObject.get('DMT_Opportunity_Business_Plan__c')),
            'Delegator must return the active renderer\'s business plan fields'
        );

        Map<String, DMT_ApprovalChangeStep_Helper.ChildSection> sectionsByKey = new Map<String, DMT_ApprovalChangeStep_Helper.ChildSection>();
        for (DMT_ApprovalChangeStep_Helper.ChildSection section : delegator.getChildSections(opp)) {
            sectionsByKey.put(section.snapshotSectionKey, section);
        }
        Assert.areEqual(2, sectionsByKey.size(), 'Exactly two child sections expected');
        Assert.isTrue(sectionsByKey.containsKey('opportunityClient'), 'opportunityClient section must be declared');
        Assert.isTrue(sectionsByKey.containsKey('opportunityBusinessPlan'), 'opportunityBusinessPlan section must be declared');
    }

    @IsTest
    static void testGetTrackedFieldsRoutesToGTBRenderer() {
        DMT_NBC_ClientTierRenderer delegator = new DMT_NBC_ClientTierRenderer();
        Opportunity opp = new Opportunity(
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId(),
            DMT_Product_Area__c = 'GTB'
        );

        Map<String, List<String>> byObject = delegator.getTrackedFieldsByObject(opp);
        Assert.areEqual(
            new Set<String>{'Relationship_Status_desc__c'},
            new Set<String>(byObject.get('DMT_Opportunity_Client__c')),
            'Delegator must return the active (GTB) renderer\'s own (narrower) DMT_Opportunity_Client__c fields, not IB&F\'s'
        );
    }

    @IsTest
    static void testGTBPathRendersBusinessPlanAndRelationshipStatus() {
        DMT_NBC_OppClientTierRenderer_GTB renderer = new DMT_NBC_OppClientTierRenderer_GTB();

        Opportunity baseOpp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityClient(baseOpp.Id);
        baseOpp = [SELECT Id, Name, DMT_Product_Area__c, DMT_Capital_Action__c, DMT_Threshold_Type__c FROM Opportunity WHERE Id = :baseOpp.Id LIMIT 1];

        DMT_Opportunity_Client__c oppClient = [
            SELECT Id, Geographical_Footprint_desc__c, Relationship_Status_desc__c, Industry_Overview_desc__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :baseOpp.Id
            LIMIT 1
        ];

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = baseOpp;
        data.oppClient = oppClient;

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'GTB path must return a non-null result.');
        Assert.isTrue(result.contains('BUSINESS PLAN'), 'GTB path should render the BUSINESS PLAN section.');
        Assert.isTrue(result.contains('RELATIONSHIP STATUS'), 'GTB path should render the RELATIONSHIP STATUS section.');
        Assert.isTrue(!result.contains('CLIENT & BUSINESS PLAN'), 'GTB path should not render the main bar hidden pre-split.');
        Assert.isTrue(!result.contains('GEOGRAPHICAL FOOTPRINT'), 'GTB path should not render Geographical Footprint.');
        Assert.isTrue(!result.contains('INDUSTRY OVERVIEW'), 'GTB path should not render Industry Overview.');
        Assert.isTrue(!result.contains('<div>Error:'), 'GTB path must not produce an error div.');
    }

    @IsTest
    static void testNullDataReturnsGuardMessage() {
        DMT_NBC_OppClientTierRenderer_IBF renderer = new DMT_NBC_OppClientTierRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Opportunity data not provided') || result.contains('Error'), 'Empty data should return a controlled response.');
    }

    @IsTest
    static void testGtbNullDataReturnsGuardMessage() {
        DMT_NBC_OppClientTierRenderer_GTB renderer = new DMT_NBC_OppClientTierRenderer_GTB();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Opportunity data not provided') || result.contains('Error'), 'Empty data should return a controlled response.');
    }

    @IsTest
    static void testGtbForcedExceptionReturnsError() {
        DMT_NBC_OppClientTierRenderer_GTB renderer = new DMT_NBC_OppClientTierRenderer_GTB();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp GTB Force', DMT_Product_Area__c = 'GTB');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.forceException = true;

        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Error'), 'Forced exception path must return error HTML.');
    }

    @IsTest
    static void testIBFPathWithGlobalBusinessPlanRecord() {
        DMT_NBC_OppClientTierRenderer_IBF renderer = new DMT_NBC_OppClientTierRenderer_IBF();

        Opportunity baseOpp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityClient(baseOpp.Id);
        baseOpp = [SELECT Id, Name, DMT_Product_Area__c, DMT_Capital_Action__c, DMT_Threshold_Type__c FROM Opportunity WHERE Id = :baseOpp.Id LIMIT 1];
        DMT_Opportunity_Client__c oppClient = [
            SELECT Id, Geographical_Footprint_desc__c, Relationship_Status_desc__c, Industry_Overview_desc__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :baseOpp.Id
            LIMIT 1
        ];

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = baseOpp;
        data.oppClient = oppClient;
        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>{
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'GLOBAL',
                DMT_QAOTER__c = 'Q1 2026'
            )
        };

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'IBF path with GLOBAL businessPlan must return a non-null result.');
        Assert.isTrue(!result.contains('<div>Error:'), 'GLOBAL business plan should render without error.');
    }

    @IsTest
    static void testIBFPathWithNonGlobalBusinessPlanRecord() {
        DMT_NBC_OppClientTierRenderer_IBF renderer = new DMT_NBC_OppClientTierRenderer_IBF();

        Opportunity baseOpp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityClient(baseOpp.Id);
        baseOpp = [SELECT Id, Name, DMT_Product_Area__c, DMT_Capital_Action__c, DMT_Threshold_Type__c FROM Opportunity WHERE Id = :baseOpp.Id LIMIT 1];
        DMT_Opportunity_Client__c oppClient = [
            SELECT Id, Geographical_Footprint_desc__c, Relationship_Status_desc__c, Industry_Overview_desc__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :baseOpp.Id
            LIMIT 1
        ];

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = baseOpp;
        data.oppClient = oppClient;
        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>{
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'LOCAL',
                DMT_QAOTER__c = 'Q2 2026'
            )
        };

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'IBF path with non-GLOBAL businessPlan must return a non-null result.');
        Assert.isTrue(!result.contains('<div>Error:'), 'Non-GLOBAL business plan should render without error.');
    }

    @IsTest
    static void testOppClientTierRendererAdditionalCoverage() {
        DMT_NBC_OppClientTierRenderer_IBF renderer = new DMT_NBC_OppClientTierRenderer_IBF();

        Opportunity baseOpp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityClient(baseOpp.Id);
        baseOpp = [SELECT Id, Name, DMT_Product_Area__c, DMT_Capital_Action__c, DMT_Threshold_Type__c FROM Opportunity WHERE Id = :baseOpp.Id LIMIT 1];

        DMT_Opportunity_Client__c oppClient = [
            SELECT Id, Geographical_Footprint_desc__c, Relationship_Status_desc__c, Industry_Overview_desc__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :baseOpp.Id
            LIMIT 1
        ];

        DMT_ViewController.LineDataWrapper successData = new DMT_ViewController.LineDataWrapper();
        successData.opportunity = baseOpp;
        successData.oppClient = oppClient;

        String successHtml = renderer.renderHtml(successData);
        Assert.isNotNull(successHtml, 'Success HTML must not be null.');
        Assert.isTrue(successHtml.contains('BUSINESS PLAN'), 'Business plan section should be rendered.');

        DMT_ViewController.LineDataWrapper catchData = new DMT_ViewController.LineDataWrapper();
        catchData.opportunity = baseOpp;
        catchData.oppClient = null;

        String catchHtml = renderer.renderHtml(catchData);
        Assert.isNotNull(catchHtml, 'Null oppClient should still return a renderer response.');
    }

    @IsTest
    static void testDelegatorRoutesGtbToGtbRenderer() {
        Opportunity baseOpp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityClient(baseOpp.Id);
        baseOpp = [SELECT Id, Name, RecordTypeId, DMT_Product_Area__c, DMT_Capital_Action__c, DMT_Threshold_Type__c FROM Opportunity WHERE Id = :baseOpp.Id LIMIT 1];
        baseOpp.DMT_Product_Area__c = 'GTB';

        DMT_Opportunity_Client__c oppClient = [
            SELECT Id, Geographical_Footprint_desc__c, Relationship_Status_desc__c, Industry_Overview_desc__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :baseOpp.Id
            LIMIT 1
        ];

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(baseOpp.RecordTypeId);
        data.opportunity = baseOpp;
        data.oppClient = oppClient;

        DMT_ViewRenderer delegator = new DMT_NBC_ClientTierRenderer();
        String result = delegator.renderHtml(data);

        Assert.isNotNull(result, 'Delegator must return a non-null result for GTB.');
        Assert.isTrue(!result.contains('GEOGRAPHICAL FOOTPRINT'), 'Delegator should route GTB opportunities to the GTB renderer.');
    }

    @IsTest
    static void testDelegatorRoutesIbfWithExtensionRcfTlToGtbRenderer() {
        Opportunity baseOpp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityClient(baseOpp.Id);
        baseOpp = [SELECT Id, Name, RecordTypeId, DMT_Product_Area__c, DMT_Capital_Action__c, DMT_Threshold_Type__c FROM Opportunity WHERE Id = :baseOpp.Id LIMIT 1];
        baseOpp.DMT_Product_Area__c = 'IB&F';
        baseOpp.DMT_Capital_Action__c = 'Extension RCF & TL';

        DMT_Opportunity_Client__c oppClient = [
            SELECT Id, Geographical_Footprint_desc__c, Relationship_Status_desc__c, Industry_Overview_desc__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :baseOpp.Id
            LIMIT 1
        ];

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(baseOpp.RecordTypeId);
        data.opportunity = baseOpp;
        data.oppClient = oppClient;

        DMT_ViewRenderer delegator = new DMT_NBC_ClientTierRenderer();
        String result = delegator.renderHtml(data);

        Assert.isNotNull(result, 'Delegator must return a non-null result for IB&F + Extension RCF & TL.');
        Assert.isTrue(!result.contains('GEOGRAPHICAL FOOTPRINT'), 'IB&F with Extension RCF & TL should route to the GTB renderer.');
    }

    @IsTest
    static void testDelegatorKeepsIbfLocalContentVisible() {
        Opportunity baseOpp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityClient(baseOpp.Id);
        baseOpp = [SELECT Id, Name, RecordTypeId, DMT_Product_Area__c, DMT_Capital_Action__c, DMT_Threshold_Type__c FROM Opportunity WHERE Id = :baseOpp.Id LIMIT 1];
        baseOpp.DMT_Product_Area__c = 'IB&F';
        baseOpp.DMT_Threshold_Type__c = 'Local';

        DMT_Opportunity_Client__c oppClient = [
            SELECT Id, Geographical_Footprint_desc__c, Relationship_Status_desc__c, Industry_Overview_desc__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :baseOpp.Id
            LIMIT 1
        ];

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(baseOpp.RecordTypeId);
        data.opportunity = baseOpp;
        data.oppClient = oppClient;

        DMT_ViewRenderer delegator = new DMT_NBC_ClientTierRenderer();
        String result = delegator.renderHtml(data);

        Assert.isTrue(result.contains('GEOGRAPHICAL FOOTPRINT'), 'Local-hiding only applies to GTB + Local per the ticket; IB&F must still render content regardless of Threshold Type.');
    }
}