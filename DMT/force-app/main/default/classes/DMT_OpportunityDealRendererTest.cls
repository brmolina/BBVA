@IsTest
public with sharing class DMT_OpportunityDealRendererTest {

    @IsTest
    static void testRenderHtml_nullData_returnsMissingDataMessage() {
        DMT_OpportunityDealRenderer renderer = new DMT_OpportunityDealRenderer();

        String html = renderer.renderHtml(null);

        System.assertEquals('<div>Opportunity data not provided</div>', html);
    }

    @IsTest
    static void testRenderHtml_validData_returnsDealSection() {
        DMT_ViewController.LineDataWrapper data = buildValidWrapper();
        DMT_OpportunityDealRenderer renderer = new DMT_OpportunityDealRenderer();

        String html = renderer.renderHtml(data);

        System.assertNotEquals(null, html);
        System.assert(html.contains('THE DEAL'));
        System.assert(html.contains('HISTORY OF THE DEAL'));
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
}