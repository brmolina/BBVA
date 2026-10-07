/**
 * @description Comprehensive test for DMT_Massive_Task_Closure_Controller
 * @author Test Suite
 * @created 2026-06-16
 */
@IsTest
public class DMT_Massive_Task_Closure_Controller_Test {

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

    private static Task createTestTask(Id caseId, String externalId) {
        // Create DMT_Task_Type__c
        DMT_Task_Type__c taskType = new DMT_Task_Type__c(
            Name = 'Test Task Type',
            DMT_External_Id__c = externalId,
            DMT_NA_Flag__c = 'N/A',
            DMT_No_Flag__c = 'No',
            DMT_Yes_Flag__c = 'Yes',
            gf_task_ind_type__c = false
        );
        insert taskType;

        Task testTask = new Task(
            WhatId = caseId,
            Subject = 'Test Task',
            Status = 'Open',
            ActivityDate = Date.today(),
            DMT_Task_Type__c = taskType.Id,
            DMT_Committee_Label__c = 'Test Approver Label'
        );
        insert testTask;
        return testTask;
    }

    private static Account createTestAccount() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        return acc;
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

    private static DMT_Line__c createTestLine() {
        return DMT_Test_DataFactory.generateTestOtherLines();
    }

    private static Opportunity createTestOpportunity() {
        return DMT_Test_DataFactory.generateOpportunity();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: getTasksForMassiveClosure - Null or Empty Input
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testGetTasksForMassiveClosureEmptyOrNullInput() {
        Test.startTest();
        List<DMT_Massive_Task_Closure_Controller.MassiveClosureWrapper> r1 =
            DMT_Massive_Task_Closure_Controller.getTasksForMassiveClosure(null);
        List<DMT_Massive_Task_Closure_Controller.MassiveClosureWrapper> r2 =
            DMT_Massive_Task_Closure_Controller.getTasksForMassiveClosure(new List<String>());
        Test.stopTest();

        Assert.areEqual(0, r1.size(), 'Should return empty list for null input');
        Assert.areEqual(0, r2.size(), 'Should return empty list for empty input');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: getTasksForMassiveClosure - Invalid Format
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testGetTasksForMassiveClosureInvalidFormat() {
        // Setup - Keys without underscore
        List<String> invalidKeys = new List<String>{
            'InvalidKey',
            'NoUnderscore'
        };

        // Execute
        Test.startTest();
        List<DMT_Massive_Task_Closure_Controller.MassiveClosureWrapper> results =
            DMT_Massive_Task_Closure_Controller.getTasksForMassiveClosure(invalidKeys);
        Test.stopTest();

        // Verify
        Assert.areEqual(0, results.size(), 'Should skip invalid keys');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: getTasksForMassiveClosure - Single Task
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testGetTasksForMassiveClosureSingleTask() {
        // Setup
        Case testCase = createTestCase('L');
        DMT_Line__c testLine = createTestLine();
        testCase.DMT_Line__c = testLine.Id;
        update testCase;

        Task testTask = createTestTask(testCase.Id, 'EXT001');

        String selectionKey = testCase.CaseNumber + '_' + testTask.Id;

        // Execute
        Test.startTest();
        List<DMT_Massive_Task_Closure_Controller.MassiveClosureWrapper> results =
            DMT_Massive_Task_Closure_Controller.getTasksForMassiveClosure(
                new List<String>{ selectionKey }
            );
        Test.stopTest();

        // Verify
        Assert.areEqual(1, results.size(), 'Should return one wrapper');
        Assert.areEqual(testTask.Id, results[0].taskId, 'taskId should match');
        Assert.areEqual(testCase.Id, results[0].caseId, 'caseId should match');
        Assert.areEqual('Test Approver Label', results[0].committeeLabel, 'committeeLabel should be populated');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: getTasksForMassiveClosure - Multiple Tasks
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testGetTasksForMassiveClosureMultipleTasks() {
        // Setup
        Case testCase1 = createTestCase('L');
        Case testCase2 = createTestCase('O');
        DMT_Line__c testLine = createTestLine();
        testCase1.DMT_Line__c = testLine.Id;
        update testCase1;

        Task testTask1 = createTestTask(testCase1.Id, 'EXT001');
        Task testTask2 = createTestTask(testCase2.Id, 'EXT002');

        String selectionKey1 = testCase1.CaseNumber + '_' + testTask1.Id;
        String selectionKey2 = testCase2.CaseNumber + '_' + testTask2.Id;

        // Execute
        Test.startTest();
        List<DMT_Massive_Task_Closure_Controller.MassiveClosureWrapper> results =
            DMT_Massive_Task_Closure_Controller.getTasksForMassiveClosure(
                new List<String>{ selectionKey1, selectionKey2 }
            );
        Test.stopTest();

        // Verify
        Assert.areEqual(2, results.size(), 'Should return two wrappers');
        Assert.areEqual(testTask1.Id, results[0].taskId, 'First taskId should match');
        Assert.areEqual(testTask2.Id, results[1].taskId, 'Second taskId should match');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: getTasksForMassiveClosure - Line Opportunity Type
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testGetTasksForMassiveClosureLineOppType() {
        // Setup
        Account testAccount = createTestAccount();
        Case testCase = createTestCase('L');
        testCase.AccountId = testAccount.Id;
        DMT_Line__c testLine = createTestLine();
        testCase.DMT_Line__c = testLine.Id;
        update testCase;

        Task testTask = createTestTask(testCase.Id, 'EXT_LINE');

        String selectionKey = testCase.CaseNumber + '_' + testTask.Id;

        // Execute
        Test.startTest();
        List<DMT_Massive_Task_Closure_Controller.MassiveClosureWrapper> results =
            DMT_Massive_Task_Closure_Controller.getTasksForMassiveClosure(
                new List<String>{ selectionKey }
            );
        Test.stopTest();

        // Verify
        Assert.areEqual(1, results.size(), 'Should return wrapper for Line type');
        Assert.isNotNull(results[0].lineOppId, 'lineOppId should be populated from Line');
        Assert.areEqual('Test Account', results[0].client, 'client should be Account Name');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: getTasksForMassiveClosure - Opportunity Type
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testGetTasksForMassiveClosureOpportunityType() {
        // Setup
        Opportunity testOpp = createTestOpportunity();
        Account testAccount = createTestAccount();
        Case testCase = new Case(
            Status = 'Open',
            DMT_Passport_Sanction__c = 'approval',
            opportunity_id__c = testOpp.Id,
            AccountId = testAccount.Id
        );
        insert testCase;

        Task testTask = createTestTask(testCase.Id, 'EXT_OPP');

        String selectionKey = testCase.CaseNumber + '_' + testTask.Id;

        // Execute
        Test.startTest();
        List<DMT_Massive_Task_Closure_Controller.MassiveClosureWrapper> results =
            DMT_Massive_Task_Closure_Controller.getTasksForMassiveClosure(
                new List<String>{ selectionKey }
            );
        Test.stopTest();

        // Verify
        Assert.areEqual(1, results.size(), 'Should return wrapper for Opportunity type');
        Assert.isNotNull(results[0].lineOppId, 'lineOppId should be populated from Opportunity');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: getTasksForMassiveClosure - Non-Case WhatId
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testGetTasksForMassiveClosureNonCaseWhatId() {
        // Setup
        Account acc = createTestAccount();
        Task testTask = new Task(
            WhatId = acc.Id, // Not a Case
            Subject = 'Test Task',
            Status = 'Open',
            ActivityDate = Date.today()
        );
        insert testTask;

        // Execute
        Test.startTest();
        List<DMT_Massive_Task_Closure_Controller.MassiveClosureWrapper> results =
            DMT_Massive_Task_Closure_Controller.getTasksForMassiveClosure(
                new List<String>{ 'ACC001_' + testTask.Id }
            );
        Test.stopTest();

        // Verify
        Assert.areEqual(1, results.size(), 'Should return selected task even when WhatId is not Case');
        Assert.areEqual(testTask.Id, results[0].taskId, 'Task should be returned');
        Assert.isNull(results[0].lineOppId, 'lineOppId should be null for non-Case WhatId');
        Assert.isNull(results[0].client, 'client should be null for non-Case WhatId');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: confirmMassiveClosure - Valid JSON Payload
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testConfirmMassiveClosureValidPayload() {
        // Setup
        Case testCase = createTestCase('L');
        Task testTask = createTestTask(testCase.Id, 'EXT001');

        String payloadJson = '[{' +
            '"taskId":"' + testTask.Id + '",' +
            '"caseId":"' + testCase.Id + '",' +
            '"result":"Yes",' +
            '"comments":"Test comments",' +
            '"committeeLabel":"Approved",' +
            '"updateToDraft":false' +
            '}]';

        // Execute
        Test.startTest();
        DMT_Massive_Task_Closure_Service.ClosureResult result =
            DMT_Massive_Task_Closure_Controller.confirmMassiveClosure(payloadJson);
        Test.stopTest();

        // Verify
        Assert.isTrue(result.success, 'Should successfully process valid payload');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: confirmMassiveClosure - Null Payload
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testConfirmMassiveClosureNullPayload() {
        // Execute
        Test.startTest();
        DMT_Massive_Task_Closure_Service.ClosureResult result =
            DMT_Massive_Task_Closure_Controller.confirmMassiveClosure(null);
        Test.stopTest();

        // Verify
        Assert.isFalse(result.success, 'Null payload should be rejected by service');
        Assert.isNotNull(result.errorMessage, 'Error message should be returned');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: confirmMassiveClosure - Empty Payload
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testConfirmMassiveClosureEmptyPayload() {
        // Execute
        Test.startTest();
        DMT_Massive_Task_Closure_Service.ClosureResult result =
            DMT_Massive_Task_Closure_Controller.confirmMassiveClosure('');
        Test.stopTest();

        // Verify
        Assert.isFalse(result.success, 'Empty payload should be rejected by service');
        Assert.isNotNull(result.errorMessage, 'Error message should be returned');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: confirmMassiveClosure - Invalid JSON
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testConfirmMassiveClosureInvalidJSON() {
        // Setup - Invalid JSON
        String invalidJson = '{invalid json structure}';

        // Execute
        Test.startTest();
        try {
            DMT_Massive_Task_Closure_Service.ClosureResult result =
                DMT_Massive_Task_Closure_Controller.confirmMassiveClosure(invalidJson);
            Assert.isFalse(result.success, 'Should fail with invalid JSON');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'Should throw AuraHandledException');
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: MassiveClosureWrapper Creation
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testMassiveClosureWrapperCreation() {
        // Setup
        Account testAccount = createTestAccount();
        Case testCase = createTestCase('L');
        testCase.AccountId = testAccount.Id;
        DMT_Line__c testLine = createTestLine();
        testCase.DMT_Line__c = testLine.Id;
        update testCase;

        Task testTask = createTestTask(testCase.Id, 'EXT001');

        // Execute
        DMT_Massive_Task_Closure_Controller.MassiveClosureWrapper wrapper =
            new DMT_Massive_Task_Closure_Controller.MassiveClosureWrapper(
                testTask, '', testCase, false
            );

        // Verify
        Assert.areEqual(testTask.Id, wrapper.taskId, 'taskId should be set');
        Assert.areEqual(testCase.Id, wrapper.caseId, 'caseId should be set');
        Assert.isNotNull(wrapper.taskName, 'taskName should be populated');
        Assert.isFalse(wrapper.returnToProposalDisabled, 'returnToProposalDisabled should be false');
        Assert.areEqual('Test Approver Label', wrapper.committeeLabel, 'committeeLabel should be populated');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: MassiveClosureWrapper with Null Task Type
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testMassiveClosureWrapperNullTaskType() {
        // Setup
        Case testCase = createTestCase('L');
        Task testTask = new Task(
            WhatId = testCase.Id,
            Subject = 'Simple Task',
            Status = 'Open',
            ActivityDate = Date.today()
        );
        insert testTask;

        // Execute
        DMT_Massive_Task_Closure_Controller.MassiveClosureWrapper wrapper =
            new DMT_Massive_Task_Closure_Controller.MassiveClosureWrapper(
                testTask, '', testCase, true
            );

        // Verify
        Assert.areEqual(testTask.Subject, wrapper.taskName, 'taskName should fallback to Subject');
        Assert.isTrue(wrapper.returnToProposalDisabled, 'returnToProposalDisabled should be true');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test: MassiveClosureWrapper with Null Case
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testMassiveClosureWrapperNullCase() {
        // Setup
        Case testCase = createTestCase('L');
        Task testTask = createTestTask(testCase.Id, 'EXT001');

        // Execute
        DMT_Massive_Task_Closure_Controller.MassiveClosureWrapper wrapper =
            new DMT_Massive_Task_Closure_Controller.MassiveClosureWrapper(
                testTask, '', null, false
            );

        // Verify
        Assert.areEqual(testTask.Id, wrapper.taskId, 'taskId should be set even with null case');
        Assert.isNull(wrapper.client, 'client should be null with null case');
    }

}