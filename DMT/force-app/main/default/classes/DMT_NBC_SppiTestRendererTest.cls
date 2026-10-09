@IsTest
public class DMT_NBC_SppiTestRendererTest {
    @IsTest
    static void testSppiPair() {
        DMT_NBC_RendererPairTestUtils.runPairTests(
            'NBC Sppi Test',
            'DMT_NBC_SppiTestRenderer',
            'DMT_NBC_OppSppiTestRenderer_IBF',
            true
        );
        Assert.isTrue(true, 'Assertions are executed in shared utility and this class.');
    }

    @IsTest
    static void testGetTrackedFieldsRoutesToIBFRenderer() {
        Assert.isTrue(
            DMT_RendererFactory.getTrackedComponentNames().contains('NBC Sppi Test'),
            'NBC Sppi Test must be registered as a tracked component'
        );

        DMT_NBC_SppiTestRenderer delegator = new DMT_NBC_SppiTestRenderer();
        Opportunity opp = new Opportunity(
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId(),
            DMT_Product_Area__c = 'IB&F'
        );
        Assert.areEqual(
            new Set<String>{
                'DMT_SPPI_File_Uploaded__c', 'DMT_SPPI_Status__c', 'DMT_SPPI_User__c',
                'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'
            },
            new Set<String>(delegator.getTrackedFields(opp)),
            'Delegator must route to the IBF renderer\'s own SPPI fields plus the switch fields'
        );
    }

    @IsTest
    static void testGetTrackedFieldsRoutesToGTBRendererReturnsSwitchFieldsOnly() {
        DMT_NBC_SppiTestRenderer delegator = new DMT_NBC_SppiTestRenderer();
        Opportunity opp = new Opportunity(
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId(),
            DMT_Product_Area__c = 'GTB'
        );
        Assert.areEqual(
            new Set<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'},
            new Set<String>(delegator.getTrackedFields(opp)),
            'Delegator must route to the GTB renderer\'s own switch fields'
        );
    }

    @IsTest
    static void testNullDataReturnsGuardMessage() {
        DMT_NBC_OppSppiTestRenderer_IBF renderer = new DMT_NBC_OppSppiTestRenderer_IBF();
        String result = renderer.renderHtml(null);
        Assert.isTrue(result.contains('Opportunity data not provided'), 'Null data must return guard message.');
    }

    @IsTest
    static void testBothMapsEmptyReturnsGuardMessage() {
        DMT_NBC_OppSppiTestRenderer_IBF renderer = new DMT_NBC_OppSppiTestRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Opportunity data not provided'), 'Both empty maps must return guard message.');
    }

    @IsTest
    static void testGtbBothMapsEmptyReturnsGuardMessage() {
        DMT_NBC_OppSppiTestRenderer_GTB renderer = new DMT_NBC_OppSppiTestRenderer_GTB();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Opportunity data not provided'), 'Both empty maps must return guard message.');
    }

    @IsTest
    static void testGTBPathReturnsEmptyString() {
        DMT_NBC_OppSppiTestRenderer_GTB renderer = new DMT_NBC_OppSppiTestRenderer_GTB();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'GTB Opp', DMT_Product_Area__c = 'GTB');
        String result = renderer.renderHtml(data);
        Assert.areEqual('', result, 'GTB path must return empty string.');
    }

    @IsTest
    static void testGtbForcedExceptionReturnsError() {
        DMT_NBC_OppSppiTestRenderer_GTB renderer = new DMT_NBC_OppSppiTestRenderer_GTB();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp GTB Force', DMT_Product_Area__c = 'GTB');
        data.forceException = true;

        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Error'), 'Forced exception path must return error HTML.');
    }

    @IsTest
    static void testIBFPathFileUploadedNull() {
        DMT_NBC_OppSppiTestRenderer_IBF renderer = new DMT_NBC_OppSppiTestRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = (Opportunity) JSON.deserialize(
            '{"Name":"IBF Opp","DMT_Product_Area__c":"IBF"}', Opportunity.class);
        String result = renderer.renderHtml(data);
        Assert.isNotNull(result, 'IBF with null DMT_SPPI_File_Uploaded__c must return a non-null result.');
        Assert.isTrue(result.contains('SPPI TEST'), 'IBF path should render SPPI TEST header.');
        Assert.isTrue(result.contains('File Uploaded'), 'File Uploaded label should be rendered.');
    }

    @IsTest
    static void testIBFPathFileUploadedTrue() {
        DMT_NBC_OppSppiTestRenderer_IBF renderer = new DMT_NBC_OppSppiTestRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = (Opportunity) JSON.deserialize(
            '{"Name":"IBF Opp","DMT_Product_Area__c":"IBF","DMT_SPPI_File_Uploaded__c":true}', Opportunity.class);
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Yes'), 'DMT_SPPI_File_Uploaded__c = true must render Yes.');
    }

    @IsTest
    static void testIBFPathFileUploadedFalse() {
        DMT_NBC_OppSppiTestRenderer_IBF renderer = new DMT_NBC_OppSppiTestRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = (Opportunity) JSON.deserialize(
            '{"Name":"IBF Opp","DMT_Product_Area__c":"IBF","DMT_SPPI_File_Uploaded__c":false}', Opportunity.class);
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('No'), 'DMT_SPPI_File_Uploaded__c = false must render No.');
    }

    @IsTest
    static void testIBFPathWithStatusAndUser() {
        DMT_NBC_OppSppiTestRenderer_IBF renderer = new DMT_NBC_OppSppiTestRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = (Opportunity) JSON.deserialize(
            '{"Name":"IBF Opp","DMT_Product_Area__c":"IBF","DMT_SPPI_File_Uploaded__c":true,'
            + '"DMT_SPPI_Status__c":"Passed","DMT_SPPI_User__c":"john.doe"}', Opportunity.class);
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Passed'), 'SPPI status should be rendered.');
        Assert.isTrue(result.contains('john.doe'), 'SPPI user should be rendered.');
    }

    @IsTest
    static void testDelegatorRoutesGtbToStub() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'GTB Opp', DMT_Product_Area__c = 'GTB');

        DMT_ViewRenderer delegator = new DMT_NBC_SppiTestRenderer();
        String result = delegator.renderHtml(data);

        Assert.areEqual('', result, 'GTB routing should hit the GTB stub renderer.');
    }

    @IsTest
    static void testDelegatorRoutesIbfWithExtensionRcfTlToStub() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'IBF Extension RCF Opp', DMT_Product_Area__c = 'IB&F', DMT_Capital_Action__c = 'Extension RCF & TL');

        DMT_ViewRenderer delegator = new DMT_NBC_SppiTestRenderer();
        String result = delegator.renderHtml(data);

        Assert.areEqual('', result, 'IB&F with Extension RCF & TL should route to the GTB stub renderer.');
    }

    @IsTest
    static void testDelegatorKeepsIbfLocalContentVisible() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'IBF Local Opp', DMT_Product_Area__c = 'IB&F', DMT_Threshold_Type__c = 'Local');

        DMT_ViewRenderer delegator = new DMT_NBC_SppiTestRenderer();
        String result = delegator.renderHtml(data);

        Assert.isTrue(result.contains('SPPI TEST'), 'Local-hiding only applies to GTB + Local per the ticket; IB&F must still render content regardless of Threshold Type.');
    }
}