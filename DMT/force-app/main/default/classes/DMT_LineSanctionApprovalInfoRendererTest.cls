// CIBGLOBALD-4117 - this renderer had no dedicated test coverage at all before this fix (the
// DMT_Risk_Approval_Term__c correction below). Not field-trackable by design - Sanction Line Info
// tracking was explicitly ruled out of scope for this ticket, so this only covers rendering.
@IsTest
public class DMT_LineSanctionApprovalInfoRendererTest {

    private static final DMT_UtilTestClass DMT_UTIL = new DMT_UtilTestClass();

    // CIBGLOBALD-4117 - queries every DMT_Line__c field DMT_LineSanctionApprovalInfoRenderer reads.
    // A queried row throws on a field that was not selected, and the renderer's catch then returns
    // an error div instead of the rendered fields, so this list must follow buildRenderFields().
    private static DMT_Line__c queryLineForRender(Id lineId) {
        return [
            SELECT Id, Name, Line_Id__c, Line_Term__c, Booking_Geography__c, Start_Date__c, End_Date__c, RecordTypeId,
                   DMT_Bussiness_Approved_Date__c, DMT_Business_Approved_End_Date__c, DMT_Business_Approval_Term_n__c,
                   gf_min_raroec_wo_fcg_per__c, gf_min_rorc_wo_fcg_per__c, DMT_Comments__c
            FROM DMT_Line__c
            WHERE Id = :lineId
        ];
    }

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
        data.line = DMT_UTIL.buildLine(
            null,
            DMT_UtilTestClassConstants.DEFAULT_RISK_APPROVAL_LINE_RECORD_TYPE_ID,
            '00001',
            new Map<Schema.SObjectField, Object>{
                DMT_Line__c.Name => 'TestLine001',
                DMT_Line__c.Booking_Geography__c => 'ES'
            }
        );

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('Approval Info'), 'Happy path must render the Approval Info header.');
        Assert.isTrue(!result.contains('Error:'), 'Happy path must not produce an error div.');
    }

    // CIBGLOBALD-4117 - "Risk Approval Term" reads Line_Term__c, a formula field
    // (TEXT(months between Start_Date__c/End_Date__c) + " month(s)"). Create real data, insert,
    // and query to obtain the calculated Line_Term__c value.
    @IsTest
    static void testRiskApprovalTermRendersLineTermFormulaValue() {
        DMT_LineSanctionApprovalInfoRenderer renderer = new DMT_LineSanctionApprovalInfoRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();

        // Create test account
        Account testAccount = DMT_UTIL.createAccount();

        // Create and insert line with dates 18 months apart (formula will calculate "18 month(s)")
        DMT_Line__c testLine = DMT_UTIL.buildLine(
            testAccount.Id,
            DMT_UtilTestClassConstants.DEFAULT_RISK_APPROVAL_LINE_RECORD_TYPE_ID,
            '00001',
            new Map<Schema.SObjectField, Object>{
                DMT_Line__c.Name => 'TestLine001',
                DMT_Line__c.Booking_Geography__c => 'ES',
                DMT_Line__c.Start_Date__c => Date.newInstance(2024, 11, 21),
                DMT_Line__c.End_Date__c => Date.newInstance(2026, 5, 21)
            }
        );
        insert testLine;

        // Query to get calculated Line_Term__c formula value
        data.line = queryLineForRender(testLine.Id);

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('Risk Approval Term'), 'Risk Approval Term label must be rendered.');
        Assert.isTrue(result.contains('month(s)'), 'Line_Term__c formula value must contain month(s) suffix.');
    }

    // CIBGLOBALD-4117 - the renderer appends " month(s)" only when the value doesn't already
    // contain it - this defensive branch rarely fires in practice since the formula always includes
    // the suffix itself, but it's real code worth covering. Create line with Start_Date = End_Date
    // to calculate "0 month(s)".
    @IsTest
    static void testRiskApprovalTermAppendsSuffixWhenMissing() {
        DMT_LineSanctionApprovalInfoRenderer renderer = new DMT_LineSanctionApprovalInfoRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();

        // Create test account
        Account testAccount = DMT_UTIL.createAccount();

        // Create and insert line with same Start/End date (formula will calculate "0 month(s)")
        DMT_Line__c testLine = DMT_UTIL.buildLine(
            testAccount.Id,
            DMT_UtilTestClassConstants.DEFAULT_RISK_APPROVAL_LINE_RECORD_TYPE_ID,
            '00002',
            new Map<Schema.SObjectField, Object>{
                DMT_Line__c.Name => 'TestLine001',
                DMT_Line__c.Booking_Geography__c => 'ES',
                DMT_Line__c.Start_Date__c => Date.newInstance(2024, 11, 21),
                DMT_Line__c.End_Date__c => Date.newInstance(2024, 11, 21)
            }
        );
        insert testLine;

        // Query to get calculated Line_Term__c formula value
        data.line = queryLineForRender(testLine.Id);

        String result = renderer.renderHtml(data);

        // Formula calculates "0 month(s)", renderer appends suffix if missing
        Assert.isTrue(result.contains('0 month(s)'), 'Bare number must get month(s) suffix appended.');
    }

    @IsTest
    static void testBusinessApprovalTermStillRenders() {
        DMT_LineSanctionApprovalInfoRenderer renderer = new DMT_LineSanctionApprovalInfoRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();

        data.line = DMT_UTIL.buildLine(
            null,
            DMT_UtilTestClassConstants.DEFAULT_RISK_APPROVAL_LINE_RECORD_TYPE_ID,
            '00003',
            new Map<Schema.SObjectField, Object>{
                DMT_Line__c.Name => 'TestLine001',
                DMT_Line__c.Booking_Geography__c => 'ES',
                DMT_Line__c.DMT_Business_Approval_Term_n__c => 6,
                DMT_Line__c.Start_Date__c => Date.newInstance(2024, 11, 21),
                DMT_Line__c.End_Date__c => Date.newInstance(2025, 5, 21)
            }
        );

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('Business Approval Term'), 'Business Approval Term label must still be rendered.');
        Assert.isTrue(result.contains('6 month(s)'), 'DMT_Business_Approval_Term_n__c value must still be rendered.');
    }
}