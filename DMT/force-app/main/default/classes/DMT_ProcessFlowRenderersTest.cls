@IsTest
public class DMT_ProcessFlowRenderersTest {

    // ============ MÉTODOS AUXILIARES PÚBLICOS ============

    public static DMT_Case_Steps_Controller.WRAPPER_Step createWrapperStep(
        Integer id,
        String featureType,
        String featureName,
        String approver,
        String status,
        String stepUrlLabel,
        String user,
        String startDate,
        String endDate,
        String result,
        Boolean hasSubitems
    ) {
        DMT_Case_Steps_Controller.WRAPPER_Step step = new DMT_Case_Steps_Controller.WRAPPER_Step();
        step.id = id;
        step.featureType = featureType;
        step.featureName = featureName;
        step.approver = approver;
        step.status = status;
        step.user = user;
        step.startDate = startDate;
        step.endDate = endDate;
        step.result = result;

        if (stepUrlLabel != null) {
            DMT_Case_Steps_Controller.WRAPPER_URL urlWrapper = new DMT_Case_Steps_Controller.WRAPPER_URL();
            urlWrapper.urlLabel = stepUrlLabel;
            step.step = urlWrapper;
        }

        if (hasSubitems) {
            step.subitems = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();
            DMT_Case_Steps_Controller.WRAPPER_Step subitem = new DMT_Case_Steps_Controller.WRAPPER_Step();
            subitem.id = id + 100;
            subitem.featureType = featureType;
            subitem.approver = 'Subitem Approver';
            subitem.status = 'Completed';
            subitem.user = 'subitem.user@test.com';
            subitem.startDate = '2024-01-02';
            subitem.endDate = '2024-01-03';
            subitem.result = 'Approved';

            DMT_Case_Steps_Controller.WRAPPER_URL subitemUrl = new DMT_Case_Steps_Controller.WRAPPER_URL();
            subitemUrl.urlLabel = 'Review Document';
            subitem.step = subitemUrl;

            step.subitems.add(subitem);
        } else {
            step.subitems = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();
        }

        return step;
    }

    public static DMT_ViewController.LineDataWrapper createTestDataWrapper(
        Boolean includeProcessSteps,
        String processType, // 'approval' o 'passport'
        Boolean includeOtherSteps,
        Boolean includeSubitems
    ) {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.allsteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();
        data.participantList = new List<DMT_TeamMember__c>();

        if (includeProcessSteps) {
            // Agregar step de proceso sin nombre de feature (debe tomar el subitem)
            DMT_Case_Steps_Controller.WRAPPER_Step stepWithoutName = new DMT_Case_Steps_Controller.WRAPPER_Step();
            stepWithoutName.featureType = processType;
            stepWithoutName.featureName = null;
            stepWithoutName.subitems = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();

            DMT_Case_Steps_Controller.WRAPPER_Step subitem = createWrapperStep(
                100, processType, 'Main ' + (processType == 'approval' ? 'Approval' : 'Validation') + ' Process',
                'John Doe', 'Pending', 'Initial Review',
                'john.doe@test.com', '2024-01-01', '', '',
                false
            );
            stepWithoutName.subitems.add(subitem);
            data.allsteps.add(stepWithoutName);

            // Agregar step de proceso con nombre y sin subitems
            data.allsteps.add(createWrapperStep(
                1, processType, processType == 'approval' ? 'Credit Approval' : 'Document Validation',
                'Jane Smith', 'Completed', processType == 'approval' ? 'Credit Review' : 'Document Check',
                'jane.smith@test.com', '2024-01-01', '2024-01-02', 'Approved',
                false
            ));

            // Agregar step de proceso con nombre y con subitems
            data.allsteps.add(createWrapperStep(
                2, processType, processType == 'approval' ? 'Risk Assessment' : 'Identity Verification',
                processType == 'approval' ? 'Risk Manager' : 'Security Officer',
                'In Progress', processType == 'approval' ? 'Risk Analysis' : 'ID Check',
                processType == 'approval' ? 'risk.manager@test.com' : 'security@test.com',
                '2024-01-03', '', 'Pending',
                includeSubitems
            ));
        }

        if (includeOtherSteps) {
            // Agregar step no relacionado al proceso
            data.allsteps.add(createWrapperStep(
                3, 'documentation', 'Document Upload',
                'Document Clerk', 'Completed', 'Upload Files',
                'clerk@test.com', '2024-01-01', '2024-01-01', 'Completed',
                false
            ));

            // Agregar step con featureType null (debe ser tratado como proceso)
            DMT_Case_Steps_Controller.WRAPPER_Step nullTypeStep = createWrapperStep(
                4, null, processType == 'approval' ? 'Legal Review' : 'Final Review',
                processType == 'approval' ? 'Legal Dept' : 'Review Team',
                'Pending', processType == 'approval' ? 'Legal Check' : 'Final Validation',
                processType == 'approval' ? 'legal@test.com' : 'review@test.com',
                '2024-01-04', '', '',
                false
            );
            data.allsteps.add(nullTypeStep);
        }

        // Agregar un participant para las pruebas de PDF
        DMT_TeamMember__c participant = new DMT_TeamMember__c();
        participant.Name = 'Test Participant';
        data.participantList.add(participant);

        return data;
    }

    // ============ TESTS PARA DMT_DefaultApprovalProcessFlowRenderer ============

    @IsTest
    public static void testApprovalRenderHtml_NullData() {
        DMT_DefaultApprovalProcessFlowRenderer renderer = new DMT_DefaultApprovalProcessFlowRenderer();

        Test.startTest();
        String result = renderer.renderHtml(null);
        Test.stopTest();

        System.assert(result.containsIgnoreCase('Approval process not provided'),
                     'Should return message for null data');
    }

    @IsTest
    public static void testApprovalRenderHtml_EmptySteps() {
        DMT_DefaultApprovalProcessFlowRenderer renderer = new DMT_DefaultApprovalProcessFlowRenderer();
        DMT_ViewController.LineDataWrapper data = createTestDataWrapper(false, 'approval', false, false);
        data.allsteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();

        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        System.assert(result.containsIgnoreCase('Approval process not provided'),
                     'Should return message for empty steps');
    }


    @IsTest
    public static void testApprovalRenderHtml_WithApprovalStepsNoSubitems() {
        DMT_DefaultApprovalProcessFlowRenderer renderer = new DMT_DefaultApprovalProcessFlowRenderer();
        DMT_ViewController.LineDataWrapper data = createTestDataWrapper(true, 'approval', false, false);

        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        System.assert(result.containsIgnoreCase('APPROVAL PROCESS'),
                     'Should contain approval process header');
        System.assert(result.containsIgnoreCase('Credit Approval'),
                     'Should contain approval step name');
        System.assert(result.containsIgnoreCase('Jane Smith'),
                     'Should contain approver name');
        System.assert(result.containsIgnoreCase('Completed'),
                     'Should contain status');
        System.assert(result.containsIgnoreCase('Main Approval Process'),
                     'Should process step without name but with subitem');
    }

    @IsTest
    public static void testApprovalRenderHtml_WithApprovalStepsAndSubitems() {
        DMT_DefaultApprovalProcessFlowRenderer renderer = new DMT_DefaultApprovalProcessFlowRenderer();
        DMT_ViewController.LineDataWrapper data = createTestDataWrapper(true, 'approval', false, true);

        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        System.assert(result.containsIgnoreCase('Risk Assessment'),
                     'Should contain approval step with subitems');
        System.assert(result.containsIgnoreCase('Risk Manager'),
                     'Should contain main approver');
        System.assert(result.containsIgnoreCase('Subitem Approver'),
                     'Should contain subitem approver');
    }

    // ============ TESTS PARA DMT_SanctionOppApprovalProcessRenderer ============
    // (Sanction Line view: Approval Process for the Line's child Opportunity)

    public static DMT_ViewController.LineDataWrapper createSanctionOppTestDataWrapper(
        Boolean includeProcessSteps,
        Boolean includeOtherSteps,
        Boolean includeSubitems
    ) {
        DMT_ViewController.LineDataWrapper data = createTestDataWrapper(includeProcessSteps, 'approval', includeOtherSteps, includeSubitems);
        data.sanctionOppAllsteps = data.allsteps;
        data.allsteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();
        return data;
    }

    @IsTest
    public static void testSanctionOppApprovalRenderHtml_NullData() {
        DMT_SanctionOppApprovalProcessRenderer renderer = new DMT_SanctionOppApprovalProcessRenderer();

        Test.startTest();
        String result = renderer.renderHtml(null);
        Test.stopTest();

        System.assert(result.containsIgnoreCase('Approval process not provided'),
                     'Should return message for null data');
    }

    @IsTest
    public static void testSanctionOppApprovalRenderHtml_EmptySteps() {
        DMT_SanctionOppApprovalProcessRenderer renderer = new DMT_SanctionOppApprovalProcessRenderer();
        DMT_ViewController.LineDataWrapper data = createSanctionOppTestDataWrapper(false, false, false);
        data.sanctionOppAllsteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();

        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        System.assert(result.containsIgnoreCase('Approval process not provided'),
                     'Should return message for empty steps');
    }

    @IsTest
    public static void testSanctionOppApprovalRenderHtml_WithApprovalStepsNoSubitems() {
        DMT_SanctionOppApprovalProcessRenderer renderer = new DMT_SanctionOppApprovalProcessRenderer();
        DMT_ViewController.LineDataWrapper data = createSanctionOppTestDataWrapper(true, false, false);

        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        System.assert(result.containsIgnoreCase('APPROVAL PROCESS'),
                     'Should contain approval process header');
        System.assert(result.containsIgnoreCase('Credit Approval'),
                     'Should contain approval step name from the child Opportunity');
        System.assert(result.containsIgnoreCase('Jane Smith'),
                     'Should contain approver name');
        System.assert(result.containsIgnoreCase('Completed'),
                     'Should contain status');
        System.assert(result.containsIgnoreCase('Main Approval Process'),
                     'Should process step without name but with subitem');
    }

    @IsTest
    public static void testSanctionOppApprovalRenderHtml_WithApprovalStepsAndSubitems() {
        DMT_SanctionOppApprovalProcessRenderer renderer = new DMT_SanctionOppApprovalProcessRenderer();
        DMT_ViewController.LineDataWrapper data = createSanctionOppTestDataWrapper(true, false, true);

        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        System.assert(result.containsIgnoreCase('Risk Assessment'),
                     'Should contain approval step with subitems');
        System.assert(result.containsIgnoreCase('Risk Manager'),
                     'Should contain main approver');
        System.assert(result.containsIgnoreCase('Subitem Approver'),
                     'Should contain subitem approver');
    }

    // ============ TESTS PARA DMT_DefaultPassportProcessFlowRenderer ============

    @IsTest
    public static void testPassportRenderHtml_NullData() {
        DMT_DefaultPassportProcessFlowRenderer renderer = new DMT_DefaultPassportProcessFlowRenderer();

        Test.startTest();
        String result = renderer.renderHtml(null);
        Test.stopTest();

        System.assert(result.containsIgnoreCase('Validation process not provided'),
                     'Should return message for null data');
    }

    @IsTest
    public static void testPassportRenderHtml_EmptySteps() {
        DMT_DefaultPassportProcessFlowRenderer renderer = new DMT_DefaultPassportProcessFlowRenderer();
        DMT_ViewController.LineDataWrapper data = createTestDataWrapper(false, 'passport', false, false);
        data.allsteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();

        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        System.assert(result.containsIgnoreCase('Validation process not provided'),
                     'Should return message for empty steps');
    }

    @IsTest
    public static void testPassportRenderHtml_WithPassportStepsNoSubitems() {
        DMT_DefaultPassportProcessFlowRenderer renderer = new DMT_DefaultPassportProcessFlowRenderer();
        DMT_ViewController.LineDataWrapper data = createTestDataWrapper(true, 'passport', false, false);

        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        System.assert(result.containsIgnoreCase('VALIDATION PROCESS'),
                     'Should contain validation process header');
        System.assert(result.containsIgnoreCase('Document Validation'),
                     'Should contain validation step name');
        System.assert(result.containsIgnoreCase('Jane Smith'),
                     'Should contain approver name');
        System.assert(result.containsIgnoreCase('Completed'),
                     'Should contain status');
        System.assert(result.containsIgnoreCase('Main Validation Process'),
                     'Should process step without name but with subitem');
    }

    @IsTest
    public static void testPassportRenderHtml_WithPassportStepsAndSubitems() {
        DMT_DefaultPassportProcessFlowRenderer renderer = new DMT_DefaultPassportProcessFlowRenderer();
        DMT_ViewController.LineDataWrapper data = createTestDataWrapper(true, 'passport', false, true);

        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        System.assert(result.containsIgnoreCase('Identity Verification'),
                     'Should contain validation step with subitems');
        System.assert(result.containsIgnoreCase('Security Officer'),
                     'Should contain main approver');
        System.assert(result.containsIgnoreCase('Subitem Approver'),
                     'Should contain subitem approver');
    }

    // ============ TESTS PARA DMT_SanctionOppPassportProcessRenderer ============

    @IsTest
    public static void testSanctionOppPassportRenderer_AllPaths() {
        DMT_SanctionOppPassportProcessRenderer r = new DMT_SanctionOppPassportProcessRenderer();

        // null / empty guards
        System.assert(r.renderHtml(null).containsIgnoreCase('Validation process not provided'));
        DMT_ViewController.LineDataWrapper empty = new DMT_ViewController.LineDataWrapper();
        System.assert(r.renderHtml(empty).containsIgnoreCase('Validation process not provided'));

        // no matching passport-type steps → no-info message (only non-passport/non-null types)
        DMT_ViewController.LineDataWrapper noPassport = new DMT_ViewController.LineDataWrapper();
        noPassport.sanctionOppAllsteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>{
            createWrapperStep(3, 'documentation', 'Doc Upload', 'Clerk', 'Done', 'Upload', 'clerk@test.com', '', '', '', false)
        };
        System.assert(r.renderHtml(noPassport).containsIgnoreCase('There is no information about the validation process'));

        // passport steps without subitems
        DMT_ViewController.LineDataWrapper noSub = createTestDataWrapper(true, 'passport', false, false);
        noSub.sanctionOppAllsteps = noSub.allsteps;
        noSub.allsteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();
        String htmlNoSub = r.renderHtml(noSub);
        System.assert(htmlNoSub.containsIgnoreCase('Document Validation'));
        System.assert(htmlNoSub.containsIgnoreCase('Jane Smith'));

        // passport steps with subitems
        DMT_ViewController.LineDataWrapper withSub = createTestDataWrapper(true, 'passport', false, true);
        withSub.sanctionOppAllsteps = withSub.allsteps;
        withSub.allsteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();
        String htmlSub = r.renderHtml(withSub);
        System.assert(htmlSub.containsIgnoreCase('Security Officer'));
        System.assert(htmlSub.containsIgnoreCase('Subitem Approver'));

        // renderPdfJson always returns empty map
        System.assert(r.renderPdfJson(noSub).isEmpty());
    }

    // ============ TESTS DE EXCEPCIONES ============

    @IsTest
    public static void testApprovalRenderHtml_ExceptionHandling() {
        DMT_DefaultApprovalProcessFlowRenderer renderer = new DMT_DefaultApprovalProcessFlowRenderer();
        DMT_ViewController.LineDataWrapper data = createTestDataWrapper(true, 'approval', false, false);

        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        System.assert(!result.containsIgnoreCase('Error:'),
                     'Should not contain error message when no exception occurs');
        System.assert(result.containsIgnoreCase('APPROVAL PROCESS'),
                     'Should process normally without errors');
    }

    @IsTest
    public static void testPassportRenderHtml_ExceptionHandling() {
        DMT_DefaultPassportProcessFlowRenderer renderer = new DMT_DefaultPassportProcessFlowRenderer();
        DMT_ViewController.LineDataWrapper data = createTestDataWrapper(true, 'passport', false, false);

        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        System.assert(!result.containsIgnoreCase('Error:'),
                     'Should not contain error message when no exception occurs');
        System.assert(result.containsIgnoreCase('VALIDATION PROCESS'),
                     'Should process normally without errors');
    }

    // ============ TEST DE COBERTURA COMPLETA ============

    @IsTest
    public static void testAllCodePathsForBothRenderers() {
        // Test Approval Renderer paths
        DMT_DefaultApprovalProcessFlowRenderer approvalRenderer = new DMT_DefaultApprovalProcessFlowRenderer();

        // renderHtml paths
        String html1 = approvalRenderer.renderHtml(null);
        System.assert(html1.containsIgnoreCase('not provided'));

        DMT_ViewController.LineDataWrapper data1 = new DMT_ViewController.LineDataWrapper();
        data1.allsteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();
        String html2 = approvalRenderer.renderHtml(data1);
        System.assert(html2.containsIgnoreCase('not provided'));

        // Test Passport Renderer paths
        DMT_DefaultPassportProcessFlowRenderer passportRenderer = new DMT_DefaultPassportProcessFlowRenderer();

        // renderHtml paths
        String html3 = passportRenderer.renderHtml(null);
        System.assert(html3.containsIgnoreCase('not provided'));

        DMT_ViewController.LineDataWrapper data3 = new DMT_ViewController.LineDataWrapper();
        data3.allsteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();
        String html4 = passportRenderer.renderHtml(data3);
        System.assert(html4.containsIgnoreCase('not provided'));
    }
}