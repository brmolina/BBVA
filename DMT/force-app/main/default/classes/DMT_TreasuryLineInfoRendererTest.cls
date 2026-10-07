/**
 * CIBGLOBALD-4117 - minimal dedicated coverage for the field-drift fix on
 * DMT_TreasuryLineInfoRenderer (cfSummaryTreasury_Flexcard's Business Approval / RAROEC-RORC
 * fields, tracked by an earlier fix but never actually displayed until this one).
 */
@IsTest
private class DMT_TreasuryLineInfoRendererTest {

    @IsTest
    static void testRenderHtmlDisplaysCfSummaryTreasuryFlexcardFields() {
        DMT_TreasuryLineInfoRenderer renderer = new DMT_TreasuryLineInfoRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        String lineJson = '{"Name":"TestLine001","DMT_Business_Approval_Term__c":"90 days",'
            + '"DMT_Bussiness_Approved_Date__c":"2026-01-15","DMT_Bussiness_Approved_End_Date__c":"2026-12-15",'
            + '"gf_min_raroec_wo_fcg_per__c":12.5,"gf_min_rorc_wo_fcg_per__c":8.25}';
        data.line = (DMT_Line__c) JSON.deserialize(lineJson, DMT_Line__c.class);

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('90 days'), 'DMT_Business_Approval_Term__c value must be rendered.');
        Assert.isTrue(result.contains('12.5') || result.contains('12.50'), 'gf_min_raroec_wo_fcg_per__c value must be rendered.');
        Assert.isTrue(result.contains('8.25'), 'gf_min_rorc_wo_fcg_per__c value must be rendered.');
    }
}