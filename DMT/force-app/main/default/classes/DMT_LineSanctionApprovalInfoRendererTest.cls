// CIBGLOBALD-4117 - this renderer had no dedicated test coverage at all before this fix (the
// DMT_Risk_Approval_Term__c correction below). Not field-trackable by design - Sanction Line Info
// tracking was explicitly ruled out of scope for this ticket, so this only covers rendering.
@IsTest
public class DMT_LineSanctionApprovalInfoRendererTest {

    @IsTest
    static void testNullData() {
        DMT_LineSanctionApprovalInfoRenderer renderer = new DMT_LineSanctionApprovalInfoRenderer();
        String result = renderer.renderHtml(null);
        Assert.isTrue(result.contains('Approval Info data not provided'), 'Null data must return guard message.');
    }

    @IsTest
    static void testEmptyLine() {
        DMT_LineSanctionApprovalInfoRenderer renderer = new DMT_LineSanctionApprovalInfoRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Approval Info data not provided'), 'Line with no populated fields must return guard message.');
    }

    @IsTest
    static void testHappyPathRendersHeader() {
        DMT_LineSanctionApprovalInfoRenderer renderer = new DMT_LineSanctionApprovalInfoRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(Name = 'TestLine001');

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('Approval Info'), 'Happy path must render the Approval Info header.');
        Assert.isTrue(!result.contains('Error:'), 'Happy path must not produce an error div.');
    }

    // CIBGLOBALD-4117 - "Risk Approval Term" reads Line_Term__c, a formula field
    // (TEXT(months between Start_Date__c/End_Date__c) + " month(s)") - matches the other branch's
    // version of this renderer. Formula fields can't be set via a normal constructor, so
    // JSON.deserialize is used to populate it directly for the test.
    @IsTest
    static void testRiskApprovalTermRendersLineTermFormulaValue() {
        DMT_LineSanctionApprovalInfoRenderer renderer = new DMT_LineSanctionApprovalInfoRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = (DMT_Line__c) JSON.deserialize(
            '{"Name":"TestLine001","Line_Term__c":"18 month(s)"}',
            DMT_Line__c.class
        );

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('Risk Approval Term'), 'Risk Approval Term label must be rendered.');
        Assert.isTrue(result.contains('18 month(s)'), 'Line_Term__c value must be rendered as-is.');
    }

    // CIBGLOBALD-4117 - the renderer appends " month(s)" only when the value doesn't already
    // contain it - this defensive branch rarely fires in practice since the formula always includes
    // the suffix itself, but it's real code worth covering.
    @IsTest
    static void testRiskApprovalTermAppendsSuffixWhenMissing() {
        DMT_LineSanctionApprovalInfoRenderer renderer = new DMT_LineSanctionApprovalInfoRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = (DMT_Line__c) JSON.deserialize(
            '{"Name":"TestLine001","Line_Term__c":"18"}',
            DMT_Line__c.class
        );

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('18 month(s)'), 'A bare number must get the month(s) suffix appended.');
    }

    @IsTest
    static void testBusinessApprovalTermStillRenders() {
        DMT_LineSanctionApprovalInfoRenderer renderer = new DMT_LineSanctionApprovalInfoRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(Name = 'TestLine001', DMT_Business_Approval_Term__c = 6);

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('Business Approval Term'), 'Business Approval Term label must still be rendered.');
        Assert.isTrue(result.contains('6 month(s)'), 'DMT_Business_Approval_Term__c value must still be rendered.');
    }
}