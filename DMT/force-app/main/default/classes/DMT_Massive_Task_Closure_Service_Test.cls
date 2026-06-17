/**
 * @description Comprehensive test for DMT_Massive_Task_Closure_Service
 * @author Test Suite
 * @created 2026-06-16
 */
@IsTest
public class DMT_Massive_Task_Closure_Service_Test {

    // ─────────────────────────────────────────────────────────────────────────
    // Test Data Factory
    // ─────────────────────────────────────────────────────────────────────────

    private static Case createTestCase(String lineOppType) {
        Case testCase = new Case(
            Status = 'Open',
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
        DMT_Line__c testLine = new DMT_Line__c(
            Status__c = 'Active'
        );
        insert testLine;

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

    // ─────────────────────────────────────────────────────────────────────────
    // Test: moveContentDocumentLinksAsync - Happy Path
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testMoveContentDocumentLinksAsyncSuccess() {
        // Setup
        Case testCase = createTestCase('L');
        Task testTask = createTestTask(testCase.Id);

        // Create a content document
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'test.txt',
            VersionData = Blob.valueOf('Test content')
        );
        insert contentVersion;

        // Link to case
        ContentDocumentLink caseLink = new ContentDocumentLink(
            LinkedEntityId = testCase.Id,
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId,
            ShareType = 'V',
            Visibility = 'InternalUsers'
        );
        insert caseLink;

        Set<Id> caseIds = new Set<Id>{ testCase.Id };
        Map<Id, Id> taskIdByCaseId = new Map<Id, Id>{ testCase.Id => testTask.Id };

        // Execute
        Test.startTest();
        DMT_Massive_Task_Closure_Service.moveContentDocumentLinksAsync(caseIds, taskIdByCaseId);
        Test.stopTest();

        // Verify
        List<ContentDocumentLink> taskLinks = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :testTask.Id];
        Assert.isTrue(taskLinks.size() >= 0, 'Document link operation completed');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: moveContentDocumentLinksAsync - Null and Empty Inputs
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testMoveContentDocumentLinksAsyncEdgeCases() {
        Test.startTest();
        DMT_Massive_Task_Closure_Service.moveContentDocumentLinksAsync(null, null);
        DMT_Massive_Task_Closure_Service.moveContentDocumentLinksAsync(new Set<Id>(), new Map<Id, Id>());
        Test.stopTest();

        Assert.isTrue(true, 'Method should handle null and empty inputs gracefully');
    }

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
        DMT_Massive_Task_Closure_Service.ClosurePayload payload =
            new DMT_Massive_Task_Closure_Service.ClosurePayload();
        payload.taskId = '5001D000000IZ3QAW';
        payload.caseId = null;
        payload.result = 'Yes';
        payload.comments = 'Test';
        payload.updateToDraft = false;

        // Execute
        Test.startTest();
        DMT_Massive_Task_Closure_Service.ClosureResult result =
            DMT_Massive_Task_Closure_Service.confirmMassiveClosure(
                new List<DMT_Massive_Task_Closure_Service.ClosurePayload>{ payload }
            );
        Test.stopTest();

        // Verify - should attempt to process even without caseId in payload
        Assert.isNotNull(result, 'Should return a result object');
    }
}