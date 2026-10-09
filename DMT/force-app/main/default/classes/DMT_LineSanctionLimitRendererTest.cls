@IsTest
public class DMT_LineSanctionLimitRendererTest {

    @IsTest
    static void testNullData() {
        DMT_LineSanctionLimitRenderer renderer = new DMT_LineSanctionLimitRenderer();
        String result = renderer.renderHtml(null);
        Assert.isTrue(result.contains('Approval Limit features data not provided'), 'Null data must return guard message.');
    }

    @IsTest
    static void testEmptySanctionFeaturesList() {
        DMT_LineSanctionLimitRenderer renderer = new DMT_LineSanctionLimitRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Approval Limit features data not provided'), 'Empty sanctionFeaturesList must return guard message.');
    }

    @IsTest
    static void testWithStateNameRED() {
        DMT_LineSanctionLimitRenderer renderer = new DMT_LineSanctionLimitRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.sanctionFeaturesList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'name' => 'Limit Check', 'stateName' => 'RED', 'validations' => new List<Object>() }
        };
        String result = renderer.renderHtml(data);
        Assert.isNotNull(result, 'RED stateName must produce a non-null result.');
        Assert.isTrue(result.contains('Limit Check'), 'Feature name should be rendered in the header.');
    }

    @IsTest
    static void testWithStateNameGREEN() {
        DMT_LineSanctionLimitRenderer renderer = new DMT_LineSanctionLimitRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.sanctionFeaturesList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'name' => 'Limit Check', 'stateName' => 'GREEN', 'validations' => new List<Object>() }
        };
        String result = renderer.renderHtml(data);
        Assert.isNotNull(result, 'GREEN stateName must produce a non-null result.');
    }

    @IsTest
    static void testWithStateNameYELLOW() {
        DMT_LineSanctionLimitRenderer renderer = new DMT_LineSanctionLimitRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.sanctionFeaturesList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'name' => 'Limit Check', 'stateName' => 'YELLOW', 'validations' => new List<Object>() }
        };
        String result = renderer.renderHtml(data);
        Assert.isNotNull(result, 'YELLOW stateName must produce a non-null result.');
    }

    @IsTest
    static void testWithUnknownStateNameNoTrafficHeader() {
        DMT_LineSanctionLimitRenderer renderer = new DMT_LineSanctionLimitRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.sanctionFeaturesList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'name' => 'Limit Check', 'stateName' => 'BLUE', 'validations' => new List<Object>() }
        };
        String result = renderer.renderHtml(data);
        Assert.isNotNull(result, 'Unknown stateName must still produce a non-null result.');
    }

    @IsTest
    static void testWithValidations() {
        DMT_LineSanctionLimitRenderer renderer = new DMT_LineSanctionLimitRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        List<Object> validations = new List<Object>{
            new Map<String, Object>{ 'name' => 'Rule 1', 'state' => 'GREEN', 'message' => 'All good' },
            new Map<String, Object>{ 'name' => 'Rule 2', 'state' => 'RED', 'message' => 'Breach detected' }
        };
        data.sanctionFeaturesList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'name' => 'Feature A', 'stateName' => 'RED', 'validations' => validations }
        };
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Rule 1'), 'First validation name should be rendered.');
        Assert.isTrue(result.contains('Rule 2'), 'Second validation name should be rendered.');
        Assert.isTrue(result.contains('All good'), 'Validation message should be rendered.');
        Assert.isTrue(result.contains('Breach detected'), 'Second validation message should be rendered.');
    }

    @IsTest
    static void testOnlyFirstFeatureProcessed() {
        DMT_LineSanctionLimitRenderer renderer = new DMT_LineSanctionLimitRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.sanctionFeaturesList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'name' => 'First Feature', 'stateName' => 'GREEN', 'validations' => new List<Object>() },
            new Map<String, Object>{ 'name' => 'Second Feature', 'stateName' => 'RED', 'validations' => new List<Object>() }
        };
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('First Feature'), 'First feature should be rendered.');
        Assert.isTrue(!result.contains('Second Feature'), 'Second feature should be ignored (only i==0 is processed).');
    }
}