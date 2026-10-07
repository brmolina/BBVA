@IsTest
public class DMT_OppCommercialProcessDataRendererTest {

    @IsTest
    static void testNullData() {
        DMT_OppCommercialProcessDataRenderer renderer = new DMT_OppCommercialProcessDataRenderer();
        String result = renderer.renderHtml(null);
        Assert.isTrue(result.contains('Opportunity data not provided'), 'Null data must return guard message.');
    }

    @IsTest
    static void testEmptyOpportunity() {
        DMT_OppCommercialProcessDataRenderer renderer = new DMT_OppCommercialProcessDataRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        // Default new Opportunity() has no populated fields
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Opportunity data not provided'), 'Opportunity with no populated fields must return guard message.');
    }

    @IsTest
    static void testNullCloseDate() {
        DMT_OppCommercialProcessDataRenderer renderer = new DMT_OppCommercialProcessDataRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Test Opp', StageName = 'Prospecting');
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Close Date not provided'), 'Null CloseDate must return close date guard message.');
    }

    @IsTest
    static void testWithValidCloseDate() {
        DMT_OppCommercialProcessDataRenderer renderer = new DMT_OppCommercialProcessDataRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Test Opp', StageName = 'Prospecting', CloseDate = Date.today());
        String result = renderer.renderHtml(data);
        Assert.isNotNull(result, 'Valid data must return a non-null result.');
        Assert.isTrue(result.contains('Estimated Closing Date'), 'Result should render the Estimated Closing Date field.');
        Assert.isTrue(!result.contains('Error:'), 'Happy path must not return an error div.');
    }

    @IsTest
    static void testForceException() {
        DMT_OppCommercialProcessDataRenderer renderer = new DMT_OppCommercialProcessDataRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Test Opp', StageName = 'Prospecting', CloseDate = Date.today());
        data.forceException = true;
        String result = renderer.renderHtml(data);
        Assert.isNotNull(result, 'Forced exception must return a non-null result.');
        Assert.isTrue(result.contains('Error'), 'Forced exception must return an error div.');
    }

    // CIBGLOBALD-4117: coverage for getTrackedFields, kept here (self-contained) so this component's
    // deploy never depends on DMT_ViewController_Test, which carries substantial unrelated drift.
    @IsTest
    static void testGetTrackedFieldsOppCommercialProcessDataMatchesRenderedField() {
        Id oppRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
        DMT_OppCommercialProcessDataRenderer renderer = new DMT_OppCommercialProcessDataRenderer();

        Test.startTest();
        List<String> trackedFields = renderer.getTrackedFields(new Opportunity(RecordTypeId = oppRtId));
        Test.stopTest();

        Assert.areEqual(new List<String>{ 'CloseDate' }, trackedFields,
            'Commercial Process Data must track exactly CloseDate - the only field it renders. Every other field belongs to the separate DMT_CommercialProcessDataController form.');
    }

    @IsTest
    static void testGetTrackedFieldsCommercialProcessDataDelegatorOpportunity() {
        Id oppRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();

        Test.startTest();
        List<String> trackedFields = DMT_RendererFactory.getTrackedFields('Commercial Process Data', new Opportunity(RecordTypeId = oppRtId));
        Test.stopTest();

        Assert.areEqual(new List<String>{ 'CloseDate' }, trackedFields,
            'The delegator must route to the Opportunity renderer for the DMT_Opportunity record type.');
    }

    @IsTest
    static void testGetTrackedFieldsCommercialProcessDataDelegatorUnregisteredRecordType() {
        Id treasuryRtId = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('TreasurySettlement').getRecordTypeId();

        Test.startTest();
        List<String> trackedFields = DMT_RendererFactory.getTrackedFields('Commercial Process Data', new DMT_Line__c(RecordTypeId = treasuryRtId));
        Test.stopTest();

        Assert.isTrue(trackedFields.isEmpty(), 'Commercial Process Data has no renderer registered for Treasury Lines, so nothing is tracked there.');
    }

    @IsTest
    static void testRenderHtmlDelegatorNullData() {
        DMT_CommercialProcessDataRenderer renderer = new DMT_CommercialProcessDataRenderer();
        String result = renderer.renderHtml(null);
        Assert.isTrue(result.contains('Error'), 'Null data must return the guard error message.');
    }

    @IsTest
    static void testRenderHtmlDelegatorUnregisteredRecordType() {
        Id treasuryRtId = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('TreasurySettlement').getRecordTypeId();
        DMT_CommercialProcessDataRenderer renderer = new DMT_CommercialProcessDataRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = treasuryRtId;
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Error'), 'A record type with no registered renderer must return the guard error message.');
    }

    @IsTest
    static void testRenderHtmlDelegatorOpportunityHappyPath() {
        Id oppRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
        DMT_CommercialProcessDataRenderer renderer = new DMT_CommercialProcessDataRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = oppRtId;
        data.opportunity = new Opportunity(Name = 'Test Opp', StageName = 'Prospecting', CloseDate = Date.today());
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Estimated Closing Date'), 'The delegator must route DMT_Opportunity records to DMT_OppCommercialProcessDataRenderer.');
        Assert.isTrue(!result.contains('Error:'), 'Happy path must not produce an error div.');
    }
}