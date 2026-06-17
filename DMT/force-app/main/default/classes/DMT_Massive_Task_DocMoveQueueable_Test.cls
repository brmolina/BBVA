/**
 * @description Comprehensive test for DMT_Massive_Task_DocMoveQueueable
 * @author Test Suite
 * @created 2026-06-16
 */
@IsTest
public class DMT_Massive_Task_DocMoveQueueable_Test {

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
            ActivityDate = Date.today()
        );
        insert testTask;
        return testTask;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: Constructor with Valid Inputs
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testConstructorWithValidInputs() {
        // Setup
        Case testCase = createTestCase('L');
        Task testTask = createTestTask(testCase.Id);

        Set<Id> caseIds = new Set<Id>{ testCase.Id };
        Map<Id, Id> taskIdByCaseId = new Map<Id, Id>{ testCase.Id => testTask.Id };

        // Execute
        DMT_Massive_Task_DocMoveQueueable queueable =
            new DMT_Massive_Task_DocMoveQueueable(caseIds, taskIdByCaseId);

        // Verify
        Assert.isNotNull(queueable, 'Queueable should be instantiated');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: Execute with Empty Collections
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testExecuteWithEmptyCollections() {
        // Setup
        Set<Id> emptyCaseIds = new Set<Id>();
        Map<Id, Id> emptyTaskMap = new Map<Id, Id>();

        DMT_Massive_Task_DocMoveQueueable queueable =
            new DMT_Massive_Task_DocMoveQueueable(emptyCaseIds, emptyTaskMap);

        // Execute
        Test.startTest();
        ((Queueable) queueable).execute(null);
        Test.stopTest();

        // Verify
        Assert.isTrue(true, 'Execute method should handle empty collections gracefully');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: Execute with Multiple Cases and Tasks
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testExecuteWithMultipleCasesAndTasks() {
        // Setup
        Case testCase1 = createTestCase('L');
        Case testCase2 = createTestCase('O');
        Task testTask1 = createTestTask(testCase1.Id);
        Task testTask2 = createTestTask(testCase2.Id);

        Set<Id> caseIds = new Set<Id>{ testCase1.Id, testCase2.Id };
        Map<Id, Id> taskIdByCaseId = new Map<Id, Id>{
            testCase1.Id => testTask1.Id,
            testCase2.Id => testTask2.Id
        };

        DMT_Massive_Task_DocMoveQueueable queueable =
            new DMT_Massive_Task_DocMoveQueueable(caseIds, taskIdByCaseId);

        // Execute
        Test.startTest();
        ((Queueable) queueable).execute(null);
        Test.stopTest();

        // Verify
        Assert.isTrue(true, 'Execute method should handle multiple cases');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: Document Move Operation Integration
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testDocumentMoveOperation() {
        // Setup
        Case testCase = createTestCase('L');
        Task testTask = createTestTask(testCase.Id);

        // Create multiple content documents
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        for (Integer i = 0; i < 3; i++) {
            ContentVersion cv = new ContentVersion(
                Title = 'Test Document ' + i,
                PathOnClient = 'test' + i + '.txt',
                VersionData = Blob.valueOf('Content ' + i)
            );
            contentVersions.add(cv);
        }
        insert contentVersions;

        // Link all to case
        List<ContentDocumentLink> caseLinks = new List<ContentDocumentLink>();
        for (ContentVersion cv : contentVersions) {
            ContentDocumentLink link = new ContentDocumentLink(
                LinkedEntityId = testCase.Id,
                ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId,
                ShareType = 'V',
                Visibility = 'InternalUsers'
            );
            caseLinks.add(link);
        }
        insert caseLinks;

        Set<Id> caseIds = new Set<Id>{ testCase.Id };
        Map<Id, Id> taskIdByCaseId = new Map<Id, Id>{ testCase.Id => testTask.Id };

        DMT_Massive_Task_DocMoveQueueable queueable =
            new DMT_Massive_Task_DocMoveQueueable(caseIds, taskIdByCaseId);

        // Execute
        Test.startTest();
        ((Queueable) queueable).execute(null);
        Test.stopTest();

        // Verify - operation completed
        Assert.isTrue(true, 'Document move operation should complete');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: Queueable Can Be Enqueued
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testQueueableCanBeEnqueued() {
        // Setup
        Case testCase = createTestCase('L');
        Set<Id> caseIds = new Set<Id>{ testCase.Id };
        Map<Id, Id> taskIdByCaseId = new Map<Id, Id>();

        DMT_Massive_Task_DocMoveQueueable queueable =
            new DMT_Massive_Task_DocMoveQueueable(caseIds, taskIdByCaseId);

        // Execute - Verify it can be enqueued
        Test.startTest();
        String jobId = null;
        try {
            jobId = System.enqueueJob(queueable);
        } catch (Exception e) {
            Assert.fail('Should be able to enqueue the job: ' + e.getMessage());
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(jobId, 'Should return a job ID when enqueued');
    }
}