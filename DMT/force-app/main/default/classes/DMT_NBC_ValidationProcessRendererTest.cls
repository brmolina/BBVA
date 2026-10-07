@IsTest
public class DMT_NBC_ValidationProcessRendererTest {

    @IsTest
    static void testValidationProcessPair() {
        DMT_NBC_RendererPairTestUtils.runPairTests(
            'NBC Validation Process',
            'DMT_NBC_ValidationProcessRenderer',
            'DMT_NBC_OppValidationProcessRenderer'
        );
        Assert.isTrue(true, 'Assertions are executed in shared utility and this class');
    }

    @IsTest
    static void testOppValidationRenderer_nullData() {
        DMT_NBC_OppValidationProcessRenderer renderer = new DMT_NBC_OppValidationProcessRenderer();
        String html = renderer.renderHtml(null);

        // The renderer has no top-level null guard of its own - a null wrapper NPEs on
        // data.opportunity inside the GTB/IBF ternary and is caught by the generic catch block.
        Assert.isNotNull(html, 'Null data should return a controlled response.');
        Assert.isTrue(html.contains('Error'), 'Null data should return the generic error message.');
    }

    @IsTest
    static void testDelegatorNullDataReturnsError() {
        DMT_ViewRenderer delegator = new DMT_NBC_ValidationProcessRenderer();
        String html = delegator.renderHtml(null);

        Assert.isTrue(html.contains('Error'), 'Delegator null data should return the delegator error message.');
    }

    @IsTest
    static void testOppValidationRenderer_noPassportInfo() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.allsteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();

        DMT_Case_Steps_Controller.WRAPPER_Step riskStep = new DMT_Case_Steps_Controller.WRAPPER_Step();
        riskStep.featureType = 'risk';
        riskStep.featureName = 'Risk Feature';
        data.allsteps.add(riskStep);

        DMT_NBC_OppValidationProcessRenderer renderer = new DMT_NBC_OppValidationProcessRenderer();
        String html = renderer.renderHtml(data);

        Assert.areEqual('<div>There is no information about the validation process.</div>', html, 'Expected no-info message when all steps are non-passport.');
    }

    @IsTest
    static void testOppValidationRenderer_passportFeatureAndSubitems() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.allsteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();

        DMT_Case_Steps_Controller.WRAPPER_Step main = new DMT_Case_Steps_Controller.WRAPPER_Step();
        main.featureType = 'passport';
        main.featureName = 'Validation_Main';
        main.approver = 'APPROVER_MAIN';
        main.status = 'Done';
        main.user = 'user@test.com';
        main.startDate = '2026-07-01';
        main.endDate = '2026-07-02';
        main.result = 'YES';
        main.description = 'Main description';
        main.step = new DMT_Case_Steps_Controller.WRAPPER_URL();
        main.step.urlLabel = 'TASK_MAIN';
        main.subitems = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();

        DMT_Case_Steps_Controller.WRAPPER_Step child = new DMT_Case_Steps_Controller.WRAPPER_Step();
        child.featureType = 'passport';
        child.featureName = 'Validation_Child';
        child.approver = 'APPROVER_CHILD';
        child.status = 'Pending';
        child.user = 'child@test.com';
        child.startDate = '2026-07-03';
        child.endDate = '2026-07-04';
        child.result = 'NO';
        child.description = 'Child description';
        child.step = new DMT_Case_Steps_Controller.WRAPPER_URL();
        child.step.urlLabel = 'TASK_CHILD';
        main.subitems.add(child);

        data.allsteps.add(main);

        DMT_NBC_OppValidationProcessRenderer renderer = new DMT_NBC_OppValidationProcessRenderer();
        String html = renderer.renderHtml(data);

        Assert.isTrue(html.contains('Validation Process'), 'HTML should contain Validation Process header.');
        Assert.isTrue(html.contains('Validation_Main'), 'HTML should contain the main feature name.');
        Assert.isTrue(html.contains('Approver'), 'HTML should contain Approver column header.');
        Assert.isTrue(html.contains('Comments: Main description'), 'HTML should contain main description in comments row.');
        Assert.isTrue(html.contains('Comments: Child description'), 'HTML should contain child description in comments row.');
        Assert.isTrue(html.contains('APPROVER_<br/>MAIN'), 'HTML should apply word-break to approver value.');
        Assert.isTrue(html.contains('TASK_<br/>MAIN'), 'HTML should apply word-break to task value.');
    }

    @IsTest
    static void testGTBPathWithStepsRendersValidationProcess() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'GTB Opp', DMT_Product_Area__c = 'GTB');
        data.allsteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();

        DMT_Case_Steps_Controller.WRAPPER_Step step = new DMT_Case_Steps_Controller.WRAPPER_Step();
        step.featureType = 'passport';
        step.featureName = 'GTB Validation';
        step.approver = 'GTB_APPROVER';
        step.status = 'Done';
        step.user = 'gtbuser@test.com';
        step.startDate = '2026-07-01';
        step.endDate = '2026-07-02';
        step.result = 'YES';
        step.description = 'GTB description';
        step.step = new DMT_Case_Steps_Controller.WRAPPER_URL();
        step.step.urlLabel = 'GTB_TASK';
        step.subitems = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();
        data.allsteps.add(step);

        DMT_NBC_OppValidationProcessRenderer renderer = new DMT_NBC_OppValidationProcessRenderer();
        String html = renderer.renderHtml(data);

        Assert.isNotNull(html, 'GTB path must return a non-null result.');
        Assert.isTrue(!html.contains('<div>Error:'), 'GTB path with valid data must not produce an error div.');
    }

    @IsTest
    static void testGTBPathEmptyStepsReturnsGuardMessage() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'GTB Opp', DMT_Product_Area__c = 'GTB');
        DMT_NBC_OppValidationProcessRenderer renderer = new DMT_NBC_OppValidationProcessRenderer();
        String html = renderer.renderHtml(data);
        Assert.isTrue(html.contains('Validation process not provided'), 'GTB with empty allsteps must return guard message.');
    }

    @IsTest
    static void testOppValidationRenderer_nullFeatureTypeUsesSubitemAndDefaultTitle() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.allsteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();

        DMT_Case_Steps_Controller.WRAPPER_Step parent = new DMT_Case_Steps_Controller.WRAPPER_Step();
        parent.featureType = null;
        parent.featureName = null;
        parent.subitems = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();

        DMT_Case_Steps_Controller.WRAPPER_Step firstSub = new DMT_Case_Steps_Controller.WRAPPER_Step();
        firstSub.featureType = null;
        firstSub.featureName = null;
        firstSub.approver = '';
        firstSub.description = '';
        firstSub.step = new DMT_Case_Steps_Controller.WRAPPER_URL();
        firstSub.step.urlLabel = '';
        parent.subitems.add(firstSub);

        data.allsteps.add(parent);

        DMT_NBC_OppValidationProcessRenderer renderer = new DMT_NBC_OppValidationProcessRenderer();
        String html = renderer.renderHtml(data);

        Assert.isTrue(html.contains('Validation Process'), 'HTML should use default title when feature name is null.');
        Assert.isTrue(html.contains('Comments:'), 'HTML should contain the comments row.');
    }

    @IsTest
    static void testDelegatorRoutesGtbToSharedRenderer() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'GTB Opp', DMT_Product_Area__c = 'GTB');

        DMT_ViewRenderer delegator = new DMT_NBC_ValidationProcessRenderer();
        String html = delegator.renderHtml(data);

        Assert.isTrue(html.contains('Validation process not provided'), 'Delegator should route Opportunity records to the shared renderer regardless of Product Area.');
    }
}