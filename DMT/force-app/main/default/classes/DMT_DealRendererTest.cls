@IsTest
public with sharing class DMT_DealRendererTest {

    @IsTest
    static void testRenderHtml_nullData_returnsErrorMessage() {
        DMT_DealRenderer renderer = new DMT_DealRenderer();

        String html = renderer.renderHtml(null);

        System.assertEquals('<div>Error: Data not provided</div>', html);
    }

    @IsTest
    static void testRenderHtml_unknownRecordType_returnsErrorMessage() {
        DMT_ViewController.LineDataWrapper data = buildValidWrapper();
        data.recordTypeId = buildUnknownRecordTypeId(data.recordTypeId);

        DMT_DealRenderer renderer = new DMT_DealRenderer();
        String html = renderer.renderHtml(data);

        System.assertNotEquals(null, html);
        System.assert(html.contains('No Deal renderer for record type Id'));
    }

    @IsTest
    static void testRenderHtml_validData_delegatesToOpportunityRenderer() {
        DMT_ViewController.LineDataWrapper data = buildValidWrapper();
        DMT_DealRenderer renderer = new DMT_DealRenderer();

        String html = renderer.renderHtml(data);

        System.assertNotEquals(null, html);
        System.assert(html.contains('THE DEAL'));
    }

    private static DMT_ViewController.LineDataWrapper buildValidWrapper() {
        Opportunity baseOpp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityLineItem(baseOpp);

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = [
            SELECT Id, Name, RecordTypeId
            FROM Opportunity
            WHERE Id = :baseOpp.Id
            LIMIT 1
        ];
        data.recordTypeId = String.valueOf(data.opportunity.RecordTypeId);

        return data;
    }

    private static String buildUnknownRecordTypeId(String knownRtId) {
        String lastChar = knownRtId.right(1);
        String replacement = lastChar == 'A' ? 'B' : 'A';
        return knownRtId.left(knownRtId.length() - 1) + replacement;
    }
}