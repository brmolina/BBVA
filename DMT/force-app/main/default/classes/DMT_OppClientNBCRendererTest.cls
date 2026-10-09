@IsTest
public class DMT_OppClientNBCRendererTest {

    private static DMT_ViewController.LineDataWrapper buildValidWrapper() {
        Opportunity baseOpp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityClient(baseOpp.Id);

        baseOpp = [
            SELECT Id, Name, AccountId, Account.Name, Account.DES_Client_Type__c, Account.DES_Prospect_Client__c,
                   DMT_Product_Area__c, DMT_Threshold_Type__c
            FROM Opportunity
            WHERE Id = :baseOpp.Id
            LIMIT 1
        ];

        DMT_Opportunity_Client__c oppClient = [
            SELECT Id, DMT_Sector__c, DMT_Subsector__c, DMT_Activity__c, DMT_Industry__c, DMT_Sector_Head__c,
                   g_upd_lmscl_internal_ratg_type__c, DMT_Scoring__c, External_Rating__c, Counterpart__c,
                   SCRA__c, AVC_Check__c, European_Bank_Check__c, DMT_Leveraged_Lending__c,
                   DMT_Guarantor_Name_Fiscal_ID__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :baseOpp.Id
            LIMIT 1
        ];

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = baseOpp;
        data.oppClient = oppClient;
        return data;
    }

    @IsTest
    static void testNullDataReturnsGuardMessage() {
        DMT_OppClientNBCRenderer renderer = new DMT_OppClientNBCRenderer();
        String result = renderer.renderHtml(null);
        Assert.isTrue(result.contains('Client data not provided'), 'Null data must return guard message.');
    }

    @IsTest
    static void testEmptyOppClientReturnsGuardMessage() {
        DMT_OppClientNBCRenderer renderer = new DMT_OppClientNBCRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Client data not provided'), 'Empty oppClient must return guard message.');
    }

    @IsTest
    static void testForceExceptionReturnsErrorDiv() {
        DMT_OppClientNBCRenderer renderer = new DMT_OppClientNBCRenderer();
        DMT_ViewController.LineDataWrapper data = buildValidWrapper();
        data.forceException = true;
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Error'), 'Forced exception must return an error div.');
    }

    @IsTest
    static void testNonSubsidiaryNonFinInstHappyPath() {
        DMT_OppClientNBCRenderer renderer = new DMT_OppClientNBCRenderer();
        DMT_ViewController.LineDataWrapper data = buildValidWrapper();
        data.oppClient.Counterpart__c = 'Corporate';

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'Non-subsidiary/non-FinInst must render successfully.');
        Assert.isTrue(!result.contains('Client data not provided'), 'Should not return no-data message.');
        Assert.isTrue(result.contains('Client NBC'), 'Result should contain the Client NBC header.');
        Assert.isTrue(result.contains('Group / Client'), 'Group / Client row should be rendered.');
        Assert.isTrue(!result.contains('SCRA'), 'Non-FinInst path must not render SCRA row.');
    }

    @IsTest
    static void testFinInstPathRendersSCRAAndCheckboxes() {
        DMT_OppClientNBCRenderer renderer = new DMT_OppClientNBCRenderer();
        DMT_ViewController.LineDataWrapper data = buildValidWrapper();
        data.oppClient.Counterpart__c = 'Fin Inst';
        data.oppClient.AVC_Check__c = true;
        data.oppClient.European_Bank_Check__c = false;

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('SCRA'), 'FinInst path must render SCRA row.');
        Assert.isTrue(result.contains('Asset Value Correlation'), 'FinInst path must render AVC checkbox.');
        Assert.isTrue(result.contains('European Bank'), 'FinInst path must render European Bank checkbox.');
    }

    @IsTest
    static void testAccountIdNullProducesEmptyClientGroup() {
        DMT_OppClientNBCRenderer renderer = new DMT_OppClientNBCRenderer();
        DMT_ViewController.LineDataWrapper data = buildValidWrapper();
        data.opportunity.AccountId = null;
        data.clientGroupName = 'Should Not Appear';

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'Null AccountId should not crash the renderer.');
        Assert.isTrue(!result.contains('Should Not Appear'), 'Client group should be empty when AccountId is null.');
    }

    @IsTest
    static void testClientGroupNameSet() {
        DMT_OppClientNBCRenderer renderer = new DMT_OppClientNBCRenderer();
        DMT_ViewController.LineDataWrapper data = buildValidWrapper();
        data.clientGroupName = 'Parent Group XYZ';

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('Parent Group XYZ'), 'Pre-loaded clientGroupName should be rendered in Group / Client cell.');
    }
}