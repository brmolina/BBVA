@IsTest
public class DMT_OtherLineInfoRendererTest {

    @IsTest
    static void testNullData() {
        DMT_OtherLineInfoRenderer renderer = new DMT_OtherLineInfoRenderer();
        String result = renderer.renderHtml(null);
        Assert.isTrue(result.contains('Line data not provided'), 'Null data must return guard message.');
    }

    @IsTest
    static void testEmptyLine() {
        DMT_OtherLineInfoRenderer renderer = new DMT_OtherLineInfoRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        // Default DMT_Line__c() has no populated fields
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Line data not provided'), 'Line with no populated fields must return guard message.');
    }

    @IsTest
    static void testCommitmentTypeCOM() {
        DMT_OtherLineInfoRenderer renderer = new DMT_OtherLineInfoRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(Name = 'Test Line', g_line_commitment_level_type__c = 'COM');
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('COMMITTED'), 'COM commitment type should render as COMMITTED.');
    }

    @IsTest
    static void testCommitmentTypeUNC() {
        DMT_OtherLineInfoRenderer renderer = new DMT_OtherLineInfoRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(Name = 'Test Line', g_line_commitment_level_type__c = 'UNC');
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('UNCOMMITTED'), 'UNC commitment type should render as UNCOMMITTED.');
    }

    @IsTest
    static void testCommitmentTypePNG() {
        DMT_OtherLineInfoRenderer renderer = new DMT_OtherLineInfoRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(Name = 'Test Line', g_line_commitment_level_type__c = 'PNG');
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('PENDING FORMALIZATION'), 'PNG commitment type should render as PENDING FORMALIZATION.');
    }

    @IsTest
    static void testUnknownCommitmentType() {
        DMT_OtherLineInfoRenderer renderer = new DMT_OtherLineInfoRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(Name = 'Test Line', g_line_commitment_level_type__c = 'OTHER');
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('OTHER'), 'Unknown commitment type should be passed through as raw value.');
    }

    @IsTest
    static void testCheckboxTrue() {
        DMT_OtherLineInfoRenderer renderer = new DMT_OtherLineInfoRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(Name = 'Test Line', DMT_Individual_Disposal_Approval__c = true);
        String result = renderer.renderHtml(data);
        Assert.isNotNull(result, 'Checkbox true should render successfully.');
        Assert.isTrue(result.contains('LINE INFO'), 'Result should contain the LINE INFO header.');
    }

    @IsTest
    static void testHappyPathRendersHeader() {
        DMT_OtherLineInfoRenderer renderer = new DMT_OtherLineInfoRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(
            Name = 'TestLine001',
            g_line_commitment_level_type__c = 'COM',
            DMT_Individual_Disposal_Approval__c = false
        );
        data.currencyIsoCode = 'EUR';
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('LINE INFO'), 'Happy path must render the LINE INFO header.');
        Assert.isTrue(!result.contains('Error:'), 'Happy path must not produce an error div.');
    }
}