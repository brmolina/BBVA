@IsTest
public with sharing class DMT_NBC_ApprovalProcessRendererTest {
    @IsTest
    static void testApprovalProcessPair() {
        DMT_NBC_RendererPairTestUtils.runPairTests(
            'NBC Approval Process',
            'DMT_NBC_ApprovalProcessRenderer',
            'DMT_NBC_OppApprovalProcessRenderer'
        );
        Assert.isTrue(true, 'Assertions are executed in shared utility and this class');
    }

    @IsTest
    static void testGetTrackedFields() {
        Assert.isTrue(
            DMT_RendererFactory.getTrackedComponentNames().contains('NBC Approval Process'),
            'NBC Approval Process must be registered as a tracked component'
        );

        Id dmtOpportunityRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
        Opportunity opp = new Opportunity(RecordTypeId = dmtOpportunityRtId);

        DMT_NBC_ApprovalProcessRenderer delegator = new DMT_NBC_ApprovalProcessRenderer();
        Assert.areEqual(
            new Set<String>{'DMT_Financial_Sponsors__c'},
            new Set<String>(delegator.getTrackedFields(opp)),
            'Delegator must track only the genuinely persisted field - the rest of this component is the approval workflow\'s own live status, not deal content'
        );

        Opportunity unknownRtOpp = new Opportunity(RecordTypeId = UserInfo.getOrganizationId());
        Assert.isTrue(delegator.getTrackedFields(unknownRtOpp).isEmpty(), 'Unknown record type must yield no tracked fields');
    }

    @IsTest
    static void testApprovalProcessRendererNullData() {
        DMT_NBC_ApprovalProcessRenderer renderer = new DMT_NBC_ApprovalProcessRenderer();

        String html = renderer.renderHtml(null);

        Assert.areEqual('<div>Error: Data not provided</div>', html, 'Null data must return the expected error message.');
    }

    @IsTest
    static void testApprovalProcessRendererInvalidRecordType() {
        DMT_NBC_ApprovalProcessRenderer renderer = new DMT_NBC_ApprovalProcessRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = buildUnknownOpportunityRecordTypeId();

        String html = renderer.renderHtml(data);

        Assert.isTrue(html.contains('No Approval Process  renderer for record type Id'), 'Unknown record type must return the delegator error.');
    }

    @IsTest
    static void testOppApprovalProcessRendererRendersApprovalFeatureWithSubitems() {
        DMT_NBC_OppApprovalProcessRenderer renderer = new DMT_NBC_OppApprovalProcessRenderer();

        DMT_Case_Steps_Controller.WRAPPER_Step subitem = new DMT_Case_Steps_Controller.WRAPPER_Step();
        subitem.approver = 'Jane Approver';
        subitem.status = 'Completed';
        subitem.user = 'jane.doe';
        subitem.startDate = '2026-09-01';
        subitem.endDate = '2026-09-02';
        subitem.result = 'Approved';
        subitem.description = 'Looks good';

        DMT_Case_Steps_Controller.WRAPPER_Step feature = new DMT_Case_Steps_Controller.WRAPPER_Step();
        feature.featureType = 'approval';
        feature.featureName = 'Credit Committee';
        feature.subitems = new List<DMT_Case_Steps_Controller.WRAPPER_Step>{ subitem };

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp Approval Process', DMT_Financial_Sponsors__c = true);
        data.allsteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>{ feature };

        String html = renderer.renderHtml(data);

        Assert.isTrue(html.contains('Credit Committee'), 'Feature name must be rendered as the table title.');
        Assert.isTrue(html.contains('Jane Approver'), 'Subitem approver must be rendered.');
        Assert.isTrue(html.contains('Approved'), 'Subitem result must be rendered.');
        Assert.isTrue(html.contains('Looks good'), 'Subitem comments must be rendered.');
        Assert.isTrue(html.contains('>X<'), 'Financial Sponsors = true must render the checked checkbox.');
    }

    @IsTest
    static void testOppApprovalProcessRendererFallsBackToSanctionSteps() {
        DMT_NBC_OppApprovalProcessRenderer renderer = new DMT_NBC_OppApprovalProcessRenderer();

        DMT_Case_Steps_Controller.WRAPPER_Step feature = new DMT_Case_Steps_Controller.WRAPPER_Step();
        feature.featureType = null;
        feature.featureName = 'Sanction Approval';
        feature.approver = 'Sanction Approver';

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp Sanction', DMT_Financial_Sponsors__c = false);
        data.sanctionOppAllsteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>{ feature };

        String html = renderer.renderHtml(data);

        Assert.isTrue(html.contains('Sanction Approval'), 'Sanction fallback steps must be rendered when allsteps is empty.');
    }

    @IsTest
    static void testOppApprovalProcessRendererNoApprovalFeaturesReturnsEmptyTable() {
        DMT_NBC_OppApprovalProcessRenderer renderer = new DMT_NBC_OppApprovalProcessRenderer();

        DMT_Case_Steps_Controller.WRAPPER_Step nonApprovalFeature = new DMT_Case_Steps_Controller.WRAPPER_Step();
        nonApprovalFeature.featureType = 'passport';
        nonApprovalFeature.featureName = 'Validation Step';

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp No Approval Features');
        data.allsteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>{ nonApprovalFeature };

        String html = renderer.renderHtml(data);

        Assert.isTrue(html.contains('Approval Process'), 'Empty approval table must still render its title.');
        Assert.isFalse(html.contains('Validation Step'), 'A non-approval feature must not be rendered.');
    }

    private static String buildUnknownOpportunityRecordTypeId() {
        String knownRtId = String.valueOf(
            Schema.SObjectType.Opportunity
                .getRecordTypeInfosByDeveloperName()
                .get('DMT_Opportunity')
                .getRecordTypeId()
        );
        String lastChar = knownRtId.right(1);
        String replacement = lastChar == 'A' ? 'B' : 'A';
        return knownRtId.left(knownRtId.length() - 1) + replacement;
    }
}