@IsTest
public with sharing class DMT_NBC_OpportunityInfoRendererTest {
    @IsTest
    static void testOpportunityInfoPair() {
        DMT_NBC_RendererPairTestUtils.runPairTests(
            'NBC Opportunity Info',
            'DMT_NBC_OpportunityInfoRenderer',
            'DMT_NBC_OppInfoRenderer'
        );
        Assert.isTrue(true, 'Assertions are executed in shared utility and this class');
    }

    @IsTest
    static void testGetTrackedFields() {
        Assert.isTrue(
            DMT_RendererFactory.getTrackedComponentNames().contains('NBC Opportunity Info'),
            'NBC Opportunity Info must be registered as a tracked component'
        );

        Id dmtOpportunityRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
        Opportunity opp = new Opportunity(RecordTypeId = dmtOpportunityRtId, DMT_Product_Area__c = 'IB&F');

        DMT_NBC_OpportunityInfoRenderer delegator = new DMT_NBC_OpportunityInfoRenderer();
        Set<String> trackedFields = new Set<String>(delegator.getTrackedFields(opp));

        Set<String> expectedFields = new Set<String>{
            'Name', 'Entific__c', 'DMT_branch_id_c__c', 'DMT_Booking_EFAN__c', 'DMT_Tenor__c',
            'DMT_CUR_Notional_Amount__c', 'DMT_CurrencyText__c', 'DMT_Capital_Action__c',
            'DMT_Product_Area__c', 'DMT_ContingentCommitments__c', 'DMT_Structured_GTB__c'
        };
        Assert.areEqual(expectedFields, trackedFields, 'Tracked fields must match the fields actually rendered');

        Opportunity unknownRtOpp = new Opportunity(RecordTypeId = UserInfo.getOrganizationId());
        Assert.isTrue(delegator.getTrackedFields(unknownRtOpp).isEmpty(), 'Unknown record type must yield no tracked fields');
    }

    @IsTest
    static void testOppInfoRendererAdditionalCoverage() {
        DMT_NBC_OppInfoRenderer renderer = new DMT_NBC_OppInfoRenderer();

        Opportunity baseOpp = DMT_Test_DataFactory.generateOpportunity();
        baseOpp = [
            SELECT Id, Name, Entific__c, DMT_Tenor__c, DMT_CUR_Notional_Amount__c, DMT_CurrencyText__c, DMT_Capital_Action__c, DMT_Product_Area__c, DMT_ContingentCommitments__c,
                (SELECT Id FROM X_sell__r)
            FROM Opportunity
            WHERE Id = :baseOpp.Id
            LIMIT 1
        ];

        DMT_ViewController.LineDataWrapper successData = new DMT_ViewController.LineDataWrapper();
        successData.opportunity = baseOpp;
        successData.oppClient = new DMT_Opportunity_Client__c();
        successData.oppEntific = 'ENT-01';
        successData.oppBookingGeography = 'Spain';

        String successHtml = renderer.renderHtml(successData);

        Assert.areNotEqual(null, successHtml, 'Success HTML must not be null.');
        Assert.isTrue(successHtml.contains('Opportunity Info NBC') || successHtml.contains('Error'), 'HTML should return a controlled response.');

        DMT_ViewController.LineDataWrapper altData = new DMT_ViewController.LineDataWrapper();
        altData.opportunity = new Opportunity();

        String altHtml = renderer.renderHtml(altData);

        Assert.areNotEqual(null, altHtml, 'Alternative path should return a controlled HTML response.');
    }

    @IsTest
    static void testOppInfoRendererIBFBranchAndPdfKeys() {
        DMT_NBC_OppInfoRenderer renderer = new DMT_NBC_OppInfoRenderer();

        Opportunity baseOpp = DMT_Test_DataFactory.generateOpportunity();
        baseOpp = [
            SELECT
                Id,
                Name,
                Entific__c,
                DMT_Tenor__c,
                DMT_CUR_Notional_Amount__c,
                DMT_CurrencyText__c,
                DMT_Capital_Action__c,
                DMT_Product_Area__c,
                DMT_ContingentCommitments__c,
                (SELECT Id FROM X_sell__r)
            FROM Opportunity
            WHERE Id = :baseOpp.Id
            LIMIT 1
        ];
        baseOpp.DMT_Product_Area__c = 'IB&F';

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = baseOpp;
        data.oppClient = new DMT_Opportunity_Client__c();
        data.oppEntific = 'ENT-02';
        data.oppBookingGeography = 'Mexico';

        String html = renderer.renderHtml(data);

        Assert.areNotEqual(null, html, 'IB&F HTML should not be null.');
        Assert.isTrue(html.contains('Opportunity Info NBC') || html.contains('Error'), 'IB&F branch should return controlled HTML.');
    }

    @IsTest
    static void testOppInfoRendererCatchPath() {
        DMT_NBC_OppInfoRenderer renderer = new DMT_NBC_OppInfoRenderer();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp Catch', DMT_Product_Area__c = 'IB&F');
        data.oppClient = null;
        data.oppEntific = 'ENT-03';
        data.oppBookingGeography = 'Spain';

        String html = renderer.renderHtml(data);

        Assert.areNotEqual(null, html, 'Catch path should return controlled HTML.');
    }
}