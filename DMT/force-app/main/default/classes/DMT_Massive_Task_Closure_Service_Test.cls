/**
 * @description Comprehensive test for DMT_Massive_Task_Closure_Service
 * @author Test Suite
 * @created 2026-06-16
 */
@IsTest
public class DMT_Massive_Task_Closure_Service_Test {

    private static final String MASSIVE_QUEUE_NAME = 'DMT Massive Task Queue Test';
    private static final String MASSIVE_QUEUE_DEV  = 'DMT_MASSIVE_TASK_QUEUE_TEST';

    @TestSetup
    static void setupQueueObjects() {
        Group queueGroup = new Group(
            Name = MASSIVE_QUEUE_NAME,
            Type = 'Queue',
            DeveloperName = MASSIVE_QUEUE_DEV
        );
        insert queueGroup;

        insert new QueueSobject(QueueId = queueGroup.Id, SObjectType = 'Task');
        insert new QueueSobject(QueueId = queueGroup.Id, SObjectType = 'Case');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test Data Factory
    // ─────────────────────────────────────────────────────────────────────────

    private static Case createTestCase(String lineOppType) {
        Case testCase = new Case(
            DMT_Passport_Sanction__c = 'approval'
        );
        insert testCase;
        return testCase;
    }

    private static Task createTestTask(Id caseId) {
        Task testTask = new Task(
            WhatId = caseId,
            Subject = 'Test Task',
            Status = 'Open',
            ActivityDate = Date.today(),
            DMT_Committee_Label__c = 'Test Label'
        );
        insert testTask;
        return testTask;
    }

    private static Group createTestQueue(String queueName) {
        Group testQueue = new Group(
            Name = queueName,
            Type = 'Queue',
            DeveloperName = queueName
        );
        insert testQueue;
        return testQueue;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: confirmMassiveClosure - Happy Path
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testConfirmMassiveClosureSuccess() {
        // Setup
        Case testCase = createTestCase('L');
        Task testTask = createTestTask(testCase.Id);

        DMT_Massive_Task_Closure_Service.ClosurePayload payload =
            new DMT_Massive_Task_Closure_Service.ClosurePayload();
        payload.taskId = testTask.Id;
        payload.caseId = testCase.Id;
        payload.result = 'Yes';
        payload.comments = 'Test completion';
        payload.committeeLabel = 'Approved';
        payload.updateToDraft = false;

        // Execute
        Test.startTest();
        DMT_Massive_Task_Closure_Service.ClosureResult result =
            DMT_Massive_Task_Closure_Service.confirmMassiveClosure(
                new List<DMT_Massive_Task_Closure_Service.ClosurePayload>{ payload }
            );
        Test.stopTest();

        // Verify
        Assert.isTrue(result.success, 'Closure should succeed');
        Assert.isNull(result.errorMessage, 'No error message expected');

        // Verify task was updated
        Task updatedTask = [SELECT Id, DMT_Step_Result__c, Description, DMT_Committee_Label__c
                           FROM Task WHERE Id = :testTask.Id];
        Assert.areEqual('Yes', updatedTask.DMT_Step_Result__c, 'Result should be Yes');
        Assert.areEqual('Test completion', updatedTask.Description, 'Comments should be saved');
        Assert.areEqual('Approved', updatedTask.DMT_Committee_Label__c, 'Committee label should be saved');

        // Verify case was closed
        Case updatedCase = [SELECT Id, Status FROM Case WHERE Id = :testCase.Id];
        Assert.areEqual('Finished', updatedCase.Status, 'Case should be finished');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: confirmMassiveClosure - Null Payload
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testConfirmMassiveClosureNullPayload() {
        // Execute
        Test.startTest();
        DMT_Massive_Task_Closure_Service.ClosureResult result =
            DMT_Massive_Task_Closure_Service.confirmMassiveClosure(null);
        Test.stopTest();

        // Verify
        Assert.isFalse(result.success, 'Should fail with null payload');
        Assert.isNotNull(result.errorMessage, 'Error message should be provided');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: confirmMassiveClosure - Empty Payload
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testConfirmMassiveClosureEmptyPayload() {
        // Execute
        Test.startTest();
        DMT_Massive_Task_Closure_Service.ClosureResult result =
            DMT_Massive_Task_Closure_Service.confirmMassiveClosure(
                new List<DMT_Massive_Task_Closure_Service.ClosurePayload>()
            );
        Test.stopTest();

        // Verify
        Assert.isFalse(result.success, 'Should fail with empty payload');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: confirmMassiveClosure - Multiple Tasks
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testConfirmMassiveClosureMultipleTasks() {
        // Setup
        Case testCase1 = createTestCase('L');
        Case testCase2 = createTestCase('O');
        Task testTask1 = createTestTask(testCase1.Id);
        Task testTask2 = createTestTask(testCase2.Id);

        List<DMT_Massive_Task_Closure_Service.ClosurePayload> payloads =
            new List<DMT_Massive_Task_Closure_Service.ClosurePayload>();

        DMT_Massive_Task_Closure_Service.ClosurePayload payload1 =
            new DMT_Massive_Task_Closure_Service.ClosurePayload();
        payload1.taskId = testTask1.Id;
        payload1.caseId = testCase1.Id;
        payload1.result = 'Yes';
        payload1.comments = 'Completed 1';
        payload1.committeeLabel = 'Label1';
        payload1.updateToDraft = false;
        payloads.add(payload1);

        DMT_Massive_Task_Closure_Service.ClosurePayload payload2 =
            new DMT_Massive_Task_Closure_Service.ClosurePayload();
        payload2.taskId = testTask2.Id;
        payload2.caseId = testCase2.Id;
        payload2.result = 'No';
        payload2.comments = 'Completed 2';
        payload2.committeeLabel = 'Label2';
        payload2.updateToDraft = false;
        payloads.add(payload2);

        // Execute
        Test.startTest();
        DMT_Massive_Task_Closure_Service.ClosureResult result =
            DMT_Massive_Task_Closure_Service.confirmMassiveClosure(payloads);
        Test.stopTest();

        // Verify
        Assert.isTrue(result.success, 'Closure should succeed with multiple tasks');

        List<Task> updatedTasks = [SELECT Id, DMT_Step_Result__c, Description
                                   FROM Task WHERE Id IN (:testTask1.Id, :testTask2.Id)
                                   ORDER BY DMT_Step_Result__c];
        Assert.areEqual(2, updatedTasks.size(), 'Both tasks should be updated');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: confirmMassiveClosure - updateToDraft Flag
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testConfirmMassiveClosureWithUpdateToDraft() {
        // Setup - Create a Line for L type case
        DMT_Line__c testLine = DMT_Test_DataFactory.generateTestTreasuryLines();

        Case testCase = new Case(
            Status = 'Open',
            DMT_Line__c = testLine.Id
        );
        insert testCase;

        Task testTask = createTestTask(testCase.Id);

        DMT_Massive_Task_Closure_Service.ClosurePayload payload =
            new DMT_Massive_Task_Closure_Service.ClosurePayload();
        payload.taskId = testTask.Id;
        payload.caseId = testCase.Id;
        payload.result = 'Yes';
        payload.comments = 'Test with draft update';
        payload.committeeLabel = '';
        payload.updateToDraft = true;

        // Execute
        Test.startTest();
        DMT_Massive_Task_Closure_Service.ClosureResult result =
            DMT_Massive_Task_Closure_Service.confirmMassiveClosure(
                new List<DMT_Massive_Task_Closure_Service.ClosurePayload>{ payload }
            );
        Test.stopTest();

        // Verify
        Assert.isTrue(result.success, 'Closure with draft update should succeed');

        // Verify line was updated to Draft
        DMT_Line__c updatedLine = [SELECT Id, Status__c FROM DMT_Line__c WHERE Id = :testLine.Id];
        Assert.areEqual('Draft', updatedLine.Status__c, 'Line status should be Draft');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: confirmMassiveClosure - Related Tasks Finished
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testConfirmMassiveClosureFinishesRelatedTasks() {
        // Setup
        Case testCase = createTestCase('L');
        Task mainTask = createTestTask(testCase.Id);
        Task relatedTask = createTestTask(testCase.Id);
        relatedTask.Status = 'Not Started';
        update relatedTask;

        DMT_Massive_Task_Closure_Service.ClosurePayload payload =
            new DMT_Massive_Task_Closure_Service.ClosurePayload();
        payload.taskId = mainTask.Id;
        payload.caseId = testCase.Id;
        payload.result = 'Yes';
        payload.comments = 'Main task closed';
        payload.committeeLabel = '';
        payload.updateToDraft = false;

        // Execute
        Test.startTest();
        DMT_Massive_Task_Closure_Service.ClosureResult result =
            DMT_Massive_Task_Closure_Service.confirmMassiveClosure(
                new List<DMT_Massive_Task_Closure_Service.ClosurePayload>{ payload }
            );
        Test.stopTest();

        // Verify
        Task updatedRelatedTask = [SELECT Id, Status FROM Task WHERE Id = :relatedTask.Id];
        Assert.areEqual('Finished', updatedRelatedTask.Status, 'Related task should be finished');
    }

    // Document transfer moved to DMT_DocumentTransferService (async via DMT_DocumentTransferPayload) -
    // see DMT_DocumentTransferServiceTest for its coverage.

    // ─────────────────────────────────────────────────────────────────────────
    // Test: ClosureResult Data Class defaults
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testClosureResultDefaults() {
        DMT_Massive_Task_Closure_Service.ClosureResult result =
            new DMT_Massive_Task_Closure_Service.ClosureResult();

        Assert.isTrue(result.success, 'ClosureResult should default to success=true');
        Assert.isNull(result.errorMessage, 'errorMessage should be null by default');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: Payload with Null/Empty Fields
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testConfirmMassureClosurePayloadWithNullFields() {
        // Setup - Payload with null fields should be handled gracefully
        Case testCase = createTestCase('L');
        Task testTask = createTestTask(testCase.Id);

        DMT_Massive_Task_Closure_Service.ClosurePayload payload =
            new DMT_Massive_Task_Closure_Service.ClosurePayload();
        payload.taskId = testTask.Id;
        payload.caseId = testCase.Id;
        payload.result = null;
        payload.comments = null;
        payload.committeeLabel = null;
        payload.updateToDraft = false;

        // Execute
        Test.startTest();
        DMT_Massive_Task_Closure_Service.ClosureResult result =
            DMT_Massive_Task_Closure_Service.confirmMassiveClosure(
                new List<DMT_Massive_Task_Closure_Service.ClosurePayload>{ payload }
            );
        Test.stopTest();

        // Verify
        Assert.isTrue(result.success, 'Should handle null field values');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: Payload without CaseId
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testConfirmMassiveClosurePayloadWithoutCaseId() {
        // Setup
        Case testCase = createTestCase('L');
        Task testTask = createTestTask(testCase.Id);

        DMT_Massive_Task_Closure_Service.ClosurePayload payload =
            new DMT_Massive_Task_Closure_Service.ClosurePayload();
        payload.taskId = testTask.Id;
        payload.caseId = null;
        payload.result = 'Yes';
        payload.comments = 'Test';
        payload.committeeLabel = 'Label without caseId';
        payload.updateToDraft = false;

        // Execute
        Test.startTest();
        DMT_Massive_Task_Closure_Service.ClosureResult result =
            DMT_Massive_Task_Closure_Service.confirmMassiveClosure(
                new List<DMT_Massive_Task_Closure_Service.ClosurePayload>{ payload }
            );
        Test.stopTest();

        // Verify - caseId is optional in payload when taskId is valid
        Assert.isTrue(result.success, 'Should process with a valid taskId even without payload caseId');

        Task updatedTask = [
            SELECT Id, DMT_Step_Result__c, Description, DMT_Committee_Label__c
            FROM Task
            WHERE Id = :testTask.Id
        ];
        Assert.areEqual('Yes', updatedTask.DMT_Step_Result__c, 'Result should be updated');
        Assert.areEqual('Test', updatedTask.Description, 'Comments should be updated');
        Assert.areEqual('Label without caseId', updatedTask.DMT_Committee_Label__c, 'Committee label should be updated');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: confirmMassiveClosure - Deep snapshot/view path coverage
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testConfirmMassiveClosureDeepPathCoverage() {
        Group queueGroup = [
            SELECT Id, DeveloperName
            FROM Group
            WHERE DeveloperName = :MASSIVE_QUEUE_DEV
            LIMIT 1
        ];

        // Rich line + related records from org DataFactory
        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();

        // Ensure Custom Association + client exist to cover related queries
        Id accountId = [SELECT Client__c FROM DMT_Line__c WHERE Id = :line.Id].Client__c;
        Custom_Association__c customAssociation = DMT_Test_DataFactory.generateCustomAssociation(line.Id, accountId);
        DMT_Test_DataFactory.generateCustomAssociationClient(customAssociation.Id);

        // Ensure risk-line children exist for provision/warranty paths
        DMT_Risk_Line_Term__c riskLineTerm = [
            SELECT Id
            FROM DMT_Risk_Line_Term__c
            WHERE DMT_Line__c = :line.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        DMT_Test_DataFactory.generateCurrencyProvision(riskLineTerm.Id);
        DMT_Test_DataFactory.generateWarranty(riskLineTerm.Id);

        Id viewId = DMT_Test_DataFactory.generateView();

        // Approver for queue group + treasury view
        DMT_Approver__c approver = DMT_Test_DataFactory.generateApproverWithView(viewId);
        approver.DMT_Group__c = queueGroup.DeveloperName;
        update approver;

        // Approval case owned by queue
        Case closureCase = DMT_Test_DataFactory.generateCase(line.Id, null, queueGroup.Id);

        // Task type + selected task owned by queue
        DMT_Task_Type__c taskType = DMT_Test_DataFactory.generateTaskTypes()[0];
        Task selectedTask = new Task(
            OwnerId = queueGroup.Id,
            WhatId = closureCase.Id,
            Subject = 'Massive Closure Selected Task',
            Status = 'Open',
            ActivityDate = Date.today(),
            DMT_Task_Type__c = taskType.Id,
            DMT_Committee_Label__c = 'Initial Label'
        );
        insert selectedTask;

        // Related open task to cover finishRelatedTasks branch
        Task relatedOpenTask = new Task(
            OwnerId = queueGroup.Id,
            WhatId = closureCase.Id,
            Subject = 'Massive Closure Related Task',
            Status = 'Not Started',
            ActivityDate = Date.today(),
            DMT_Task_Type__c = taskType.Id
        );
        insert relatedOpenTask;

        DMT_Massive_Task_Closure_Service.ClosurePayload payload =
            new DMT_Massive_Task_Closure_Service.ClosurePayload();
        payload.taskId = selectedTask.Id;
        payload.caseId = closureCase.Id;
        payload.result = 'Yes';
        payload.comments = 'Deep path coverage';
        payload.committeeLabel = 'Deep Label';
        payload.updateToDraft = true;

        Test.startTest();
        DMT_Massive_Task_Closure_Service.ClosureResult result =
            DMT_Massive_Task_Closure_Service.confirmMassiveClosure(
                new List<DMT_Massive_Task_Closure_Service.ClosurePayload>{ payload }
            );
        Test.stopTest();

        Assert.isTrue(result.success, 'Deep-path massive closure should succeed');

        Task updatedSelectedTask = [
            SELECT Id, Status, DMT_Step_Result__c, Description, DMT_Committee_Label__c, DMT_ViewStatusAtClose__c
            FROM Task
            WHERE Id = :selectedTask.Id
        ];
        Assert.areEqual('Finished', updatedSelectedTask.Status, 'Selected task should be finished');
        Assert.areEqual('Yes', updatedSelectedTask.DMT_Step_Result__c, 'Result should be updated');
        Assert.areEqual('Deep path coverage', updatedSelectedTask.Description, 'Comments should be updated');
        Assert.areEqual('Deep Label', updatedSelectedTask.DMT_Committee_Label__c, 'Committee label should be updated');
        Assert.isNotNull(updatedSelectedTask.DMT_ViewStatusAtClose__c, 'Snapshot status link should be created');

        Task updatedRelatedTask = [SELECT Id, Status FROM Task WHERE Id = :relatedOpenTask.Id];
        Assert.areEqual('Finished', updatedRelatedTask.Status, 'Related open task should be finished');

        Case updatedCase = [SELECT Id, Status FROM Case WHERE Id = :closureCase.Id];
        Assert.areEqual('Finished', updatedCase.Status, 'Case should be finished');

        DMT_Line__c updatedLine = [SELECT Id, Status__c FROM DMT_Line__c WHERE Id = :line.Id];
        Assert.areEqual('Draft', updatedLine.Status__c, 'Line should be updated to Draft');

        // The view's "Client" item is a renderer-tracked component - confirms the renderer-based
        // resolution ran here and that DMT_TrackedComponents__c was populated from it.
        DMT_TaskStatusWhenCompleted__c snapshot = [
            SELECT DMT_TrackedComponents__c
            FROM DMT_TaskStatusWhenCompleted__c
            WHERE Id = :updatedSelectedTask.DMT_ViewStatusAtClose__c
        ];
        Assert.isTrue(snapshot.DMT_TrackedComponents__c.contains('Client'), 'DMT_TrackedComponents__c must record Client as one of this view\'s components.');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: confirmMassiveClosure - Opportunity + Business approver path
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testConfirmMassiveClosureOpportunityBusinessPathCoverage() {
        Group queueGroup = [
            SELECT Id, DeveloperName
            FROM Group
            WHERE DeveloperName = :MASSIVE_QUEUE_DEV
            LIMIT 1
        ];

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        OpportunityLineItem oli = DMT_Test_DataFactory.generateOpportunityLineItem(opp);
        DMT_Test_DataFactory.generateOpportunityTenor(oli);
        DMT_Test_DataFactory.generateOpportunityMitigant(oli);
        DMT_Test_DataFactory.generateOpportunityClient(opp.Id);
        DMT_Test_DataFactory.generatexSell(opp);

        Id viewId = DMT_Test_DataFactory.generateView();

        DMT_Approver_Type__c businessType = DMT_Test_DataFactory.generateApproverTypeBusiness();
        DMT_Approver__c approver = DMT_Test_DataFactory.generateApproverWithView(viewId);
        approver.DMT_Group__c = queueGroup.DeveloperName;
        approver.DMT_ApproverType__c = businessType.Id;
        approver.Approvers_View_Opportunity__c = viewId;
        update approver;

        Case closureCase = DMT_Test_DataFactory.generateCase(null, opp.Id, queueGroup.Id);
        closureCase.DMT_Passport_Sanction__c = 'approval';
        update closureCase;

        DMT_Task_Type__c taskType = DMT_Test_DataFactory.generateTaskTypes()[0];
        Task selectedTask = new Task(
            OwnerId = queueGroup.Id,
            WhatId = closureCase.Id,
            Subject = 'Massive Closure Opp Selected Task',
            Status = 'Open',
            ActivityDate = Date.today(),
            DMT_Task_Type__c = taskType.Id
        );
        insert selectedTask;

        DMT_Massive_Task_Closure_Service.ClosurePayload payload =
            new DMT_Massive_Task_Closure_Service.ClosurePayload();
        payload.taskId = selectedTask.Id;
        payload.caseId = closureCase.Id;
        payload.result = 'No';
        payload.comments = 'Opportunity deep path coverage';
        payload.committeeLabel = 'Opp Label';
        payload.updateToDraft = true;

        Test.startTest();
        DMT_Massive_Task_Closure_Service.ClosureResult result =
            DMT_Massive_Task_Closure_Service.confirmMassiveClosure(
                new List<DMT_Massive_Task_Closure_Service.ClosurePayload>{ payload }
            );
        Test.stopTest();

        Assert.isTrue(result.success, 'Opportunity business-path massive closure should succeed');

        Opportunity updatedOpp = [
            SELECT Id, StageName, DMT_Cancel__c, DMT_Bussiness_Approved_Date__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
        Assert.areEqual('Draft', updatedOpp.StageName, 'Opportunity should be moved to Draft');
        Assert.isTrue(updatedOpp.DMT_Cancel__c, 'Opportunity cancel flag should end as true');
        Assert.areEqual(Date.today(), updatedOpp.DMT_Bussiness_Approved_Date__c,
            'Business approved date should be stamped today');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: confirmMassiveClosure - Approval Process Data's 3 Opportunity child objects
    // (mirrors DMT_ApprovalChangeStep_Handler.updateTaskWithStatus)
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testConfirmMassiveClosureOpportunityApprovalProcessDataChildObjects() {
        Group queueGroup = [
            SELECT Id, DeveloperName
            FROM Group
            WHERE DeveloperName = :MASSIVE_QUEUE_DEV
            LIMIT 1
        ];

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOppGlobalStructure(opp.Id);

        DMT_ApproversView__c approverView = new DMT_ApproversView__c(
            Name = 'ApprovalProcessDataOppView',
            DMT_DeveloperName__c = 'DMT_ApprovalProcessDataOppView'
        );
        insert approverView;

        DMT_Items__c item = new DMT_Items__c(
            Name = 'Approval Process Data Item',
            DMT_Component_Item__c = 'Approval Process Data',
            DMT_order_display__c = 1,
            Type_Item__c = 'Component',
            DMT_View__c = approverView.Id
        );
        insert item;

        DMT_Approver__c approver = DMT_Test_DataFactory.generateApproverWithView(approverView.Id);
        approver.DMT_Group__c = queueGroup.DeveloperName;
        approver.Approvers_View_Opportunity__c = approverView.Id;
        update approver;

        Case closureCase = DMT_Test_DataFactory.generateCase(null, opp.Id, queueGroup.Id);

        DMT_Task_Type__c taskType = DMT_Test_DataFactory.generateTaskTypes()[0];
        Task selectedTask = new Task(
            OwnerId = queueGroup.Id,
            WhatId = closureCase.Id,
            Subject = 'Massive Closure Approval Process Data Task',
            Status = 'Open',
            ActivityDate = Date.today(),
            DMT_Task_Type__c = taskType.Id
        );
        insert selectedTask;

        DMT_Massive_Task_Closure_Service.ClosurePayload payload =
            new DMT_Massive_Task_Closure_Service.ClosurePayload();
        payload.taskId = selectedTask.Id;
        payload.caseId = closureCase.Id;
        payload.result = 'Yes';
        payload.comments = 'Approval Process Data child object coverage';
        payload.committeeLabel = 'APD Label';
        payload.updateToDraft = false;

        Test.startTest();
        DMT_Massive_Task_Closure_Service.ClosureResult result =
            DMT_Massive_Task_Closure_Service.confirmMassiveClosure(
                new List<DMT_Massive_Task_Closure_Service.ClosurePayload>{ payload }
            );
        Test.stopTest();

        Assert.isTrue(result.success, 'Approval Process Data massive closure should succeed');

        Task updatedTask = [SELECT Id, DMT_ViewStatusAtClose__c FROM Task WHERE Id = :selectedTask.Id];
        Assert.isNotNull(updatedTask.DMT_ViewStatusAtClose__c, 'Snapshot status link should be created');

        DMT_TaskStatusWhenCompleted__c snapshot = [
            SELECT DMT_TrackedComponents__c, DMT_AllFieldsInStatus__c, DMT_ViewFieldStatusAtClose__c
            FROM DMT_TaskStatusWhenCompleted__c
            WHERE Id = :updatedTask.DMT_ViewStatusAtClose__c
        ];
        Assert.isTrue(snapshot.DMT_TrackedComponents__c.contains('Approval Process Data'), 'DMT_TrackedComponents__c must record Approval Process Data as this view\'s component.');
        Assert.isTrue(snapshot.DMT_AllFieldsInStatus__c.contains('DMT_Global_Structure__c.'), 'The renderer-derived Global Structure fields must be in the frozen field list.');

        Map<String, Object> snapshotJson = (Map<String, Object>) JSON.deserializeUntyped(snapshot.DMT_ViewFieldStatusAtClose__c);
        Assert.isTrue(snapshotJson.containsKey('opportunityGlobalStructure'), 'The snapshot JSON must contain the opportunityGlobalStructure section.');
        Map<String, Object> globalStructureRows = (Map<String, Object>) snapshotJson.get('opportunityGlobalStructure');
        Assert.areEqual(16, globalStructureRows.size(), 'All 16 Global Structure rows generated for this Opportunity must be present.');
    }
}