@IsTest
public class DMT_NBC_OppApprovalProcessRendererTest {

    @IsTest
    static void testOppApprovalRendererNullData() {
        DMT_NBC_OppApprovalProcessRenderer renderer = new DMT_NBC_OppApprovalProcessRenderer();

        String html = renderer.renderHtml(null);

        System.assert(html.contains('Approval Process'), 'Null data should render the default approval section.');
        System.assert(html.contains('Approver'), 'Null data should render the approval table headers.');
    }

    @IsTest
    static void testOppApprovalRendererNonApprovalStepsReturnEmptyTable() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.allsteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();

        DMT_Case_Steps_Controller.WRAPPER_Step riskStep = new DMT_Case_Steps_Controller.WRAPPER_Step();
        riskStep.featureType = 'risk';
        riskStep.featureName = 'Risk Feature';
        data.allsteps.add(riskStep);

        DMT_NBC_OppApprovalProcessRenderer renderer = new DMT_NBC_OppApprovalProcessRenderer();
        String html = renderer.renderHtml(data);

        System.assert(html.contains('Approval Process'), 'Non-approval steps should still render the empty approval section.');
        System.assert(html.contains('Approver'), 'Non-approval steps should still render headers.');
        System.assert(!html.contains('Risk Feature'), 'Non-approval steps must be ignored.');
    }

    @IsTest
    static void testOppApprovalRendererApprovalFeatureAndSubitems() {
        DMT_ViewController.LineDataWrapper data = buildApprovalWrapper();

        DMT_NBC_OppApprovalProcessRenderer renderer = new DMT_NBC_OppApprovalProcessRenderer();
        String html = renderer.renderHtml(data);

        System.assert(html.contains('Approval Process'), 'Approval section title must be rendered.');
        System.assert(html.contains('Approval_Main'), 'Main approval feature must be rendered.');
        System.assert(html.contains('Approver'), 'Approval headers must be rendered.');
        System.assert(html.contains('Comments: Main description'), 'Main approval comments must be rendered.');
        System.assert(html.contains('Comments: Child description'), 'Child approval comments must be rendered.');
        System.assert(
            html.contains('APPROVER_<br/>MAIN') || html.contains('APPROVER_MAIN'),
            'Main approver value must be rendered.'
        );
        System.assert(
            html.contains('TASK_<br/>MAIN') || html.contains('TASK_MAIN'),
            'Main task value must be rendered.'
        );
        System.assert(
            html.contains('APPROVER_<br/>CHILD') || html.contains('APPROVER_CHILD'),
            'Child approver value must be rendered.'
        );
        System.assert(
            html.contains('TASK_<br/>CHILD') || html.contains('TASK_CHILD'),
            'Child task value must be rendered.'
        );
    }

    private static DMT_ViewController.LineDataWrapper buildApprovalWrapper() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.allsteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();

        DMT_Case_Steps_Controller.WRAPPER_Step main = buildMainApprovalStep();
        main.subitems = new List<DMT_Case_Steps_Controller.WRAPPER_Step>{
            buildChildApprovalStep()
        };
        data.allsteps.add(main);
        return data;
    }

    private static DMT_Case_Steps_Controller.WRAPPER_Step buildMainApprovalStep() {
        DMT_Case_Steps_Controller.WRAPPER_Step step = new DMT_Case_Steps_Controller.WRAPPER_Step();
        step.featureType = 'approval';
        step.featureName = 'Approval_Main';
        step.approver = 'APPROVER_MAIN';
        step.status = 'Done';
        step.user = 'user@test.com';
        step.startDate = '2026-07-01';
        step.endDate = '2026-07-02';
        step.result = 'YES';
        step.description = 'Main description';
        step.step = new DMT_Case_Steps_Controller.WRAPPER_URL();
        step.step.urlLabel = 'TASK_MAIN';
        return step;
    }

    private static DMT_Case_Steps_Controller.WRAPPER_Step buildChildApprovalStep() {
        DMT_Case_Steps_Controller.WRAPPER_Step step = new DMT_Case_Steps_Controller.WRAPPER_Step();
        step.featureType = 'approval';
        step.featureName = 'Approval_Child';
        step.approver = 'APPROVER_CHILD';
        step.status = 'Pending';
        step.user = 'child@test.com';
        step.startDate = '2026-07-03';
        step.endDate = '2026-07-04';
        step.result = 'NO';
        step.description = 'Child description';
        step.step = new DMT_Case_Steps_Controller.WRAPPER_URL();
        step.step.urlLabel = 'TASK_CHILD';
        return step;
    }
}