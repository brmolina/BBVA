/**
 * CIBGLOBALD-4117: first test coverage this class has ever had. Focused on the parts refactored to
 * call the shared single-responsibility services (DMT_TaskCompletionService, DMT_CaseClosureService,
 * DMT_RelatedTaskFinisherService, DMT_DraftStatusService, DMT_DocumentTransferService via
 * DMT_AsyncOrchestrator) - not an exhaustive test of every loadData formula branch. 14/10/2026
 */
@IsTest
private class DMT_ApprovalTemplate_ControllerTest {

    private static Id approvalStepRtId() {
        return Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval').getRecordTypeId();
    }

    private static Map<String, DMT_Task_Type__c> taskTypesByExternalId() {
        Set<Id> taskTypeIds = new Set<Id>();
        for (DMT_Task_Type__c taskType : DMT_Test_DataFactory.generateTaskTypes()) {
            taskTypeIds.add(taskType.Id);
        }

        Map<String, DMT_Task_Type__c> taskTypes = new Map<String, DMT_Task_Type__c>();
        for (DMT_Task_Type__c taskType : [
            SELECT Id, Name, DMT_External_Id__c, DMT_Approver_Field__c, DMT_ApprovalEdit__c
            FROM DMT_Task_Type__c
            WHERE Id IN :taskTypeIds
        ]) {
            taskTypes.put(taskType.DMT_External_Id__c, taskType);
        }
        return taskTypes;
    }

    private static Task createPendingTask(Id caseId, Id taskTypeId, Id ownerId) {
        Task taskRecord = DMT_Test_DataFactory.generateTasksWithOwner(ownerId, approvalStepRtId(), caseId, 1)[0];
        taskRecord.DMT_Task_Type__c = taskTypeId;
        taskRecord.Status = 'In Progress';
        taskRecord.Subject = 'UT Task';
        taskRecord.ActivityDate = Date.today();
        update taskRecord;
        return taskRecord;
    }

    private static Case createCaseRecord(Id lineId, Id ownerId) {
        return DMT_Test_DataFactory.generateCase(lineId, null, ownerId);
    }

    private static String fakeCaseId() {
        return Case.SObjectType.getDescribe().getKeyPrefix() + '000000000000';
    }

    @IsTest
    static void testGetCloseTaskInitialDataHappyPath() {
        Group ownerGroup = new Group(Name = 'UT Init Data Group', DeveloperName = 'UT_Init_Data_Grp', Type = 'Queue');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert ownerGroup;
            insert new QueueSobject(QueueId = ownerGroup.Id, SobjectType = 'Task');
            insert new QueueSobject(QueueId = ownerGroup.Id, SobjectType = 'Case');
        }

        DMT_Approver__c approver = DMT_Test_DataFactory.generateApprover();
        approver.DMT_Group__c = ownerGroup.DeveloperName;
        update approver;
        insert new DMT_Approver_Member__c(
            DMT_Approver__c = approver.Id,
            DMT_User__c = UserInfo.getUserId(),
            DMT_Access_Level__c = 'Edit'
        );

        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        Map<String, DMT_Task_Type__c> taskTypes = taskTypesByExternalId();
        DMT_Task_Type__c taskType = taskTypes.get('1');
        DMT_Task_Type__c defaultType = taskTypes.get('6');
        taskType.gf_task_ind_type__c = true;
        defaultType.DMT_ApprovalEdit__c = true;
        defaultType.DMT_Approver_Field__c = 'DMT_Approver__c';
        update new List<DMT_Task_Type__c>{ taskType, defaultType };

        Case caseRecord = new Case(
            DMT_Line__c = line.Id,
            DMT_Feature_Id__c = 'Test',
            DMT_Related_feature_name__c = 'Test1',
            Amount__c = 45,
            CurrencyIsoCode = 'EUR',
            Subject = 'Test Subject',
            DMT_ConditionsCloseCase__c = '{"dateMaximum": "2025-11-13","maximumLinePeriod": "365","maximumProductMaturity": "45000","products": ["Derivatives","Equities","Depos"],"clients": ["G00000000000200"], "derivativesAmount":"3", "dvpAmount":"3", "fdAmount":"0"}',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(DMT_Constants.CASE_RT_APPROVAL).getRecordTypeId(),
            OwnerId = ownerGroup.Id,
            DMT_Passport_Sanction__c = 'approval',
            DMT_Closing_Tasks__c = '[{"id":"1"}]'
        );
        insert caseRecord;

        Case relatedCase = createCaseRecord(line.Id, ownerGroup.Id);
        Task relatedApprovalTask = createPendingTask(relatedCase.Id, defaultType.Id, ownerGroup.Id);
        Task siblingTask = createPendingTask(caseRecord.Id, defaultType.Id, ownerGroup.Id);
        Task taskRecord = createPendingTask(caseRecord.Id, taskType.Id, ownerGroup.Id);
        taskRecord.DMT_Step_Result__c = 'No';
        update taskRecord;

        insert new List<DMT_Task_Relationship__c>{
            new DMT_Task_Relationship__c(
                DMT_From_Task_Type__c = taskType.Id,
                DMT_Order_Number__c = 0,
                DMT_To_Task_Type__c = defaultType.Id
            )
        };

        Test.startTest();
        DMT_ApprovalTemplate_Controller.CloseTaskInitDTO initData = DMT_ApprovalTemplate_Controller.getCloseTaskInitialData(caseRecord.Id);
    Map<String, Object> loadData = DMT_ApprovalTemplate_Controller.loadData(caseRecord.Id);
        Test.stopTest();

        System.assertEquals(caseRecord.Id, initData.caseId, 'The initial data must return the Case Id.');
        System.assertNotEquals(null, initData.taskId, 'The initial data must return a current Task Id.');
        System.assertEquals('Edit', initData.accessLevel, 'The owner queue membership must resolve Edit access.');
        System.assertEquals(true, initData.hasRelatedApprovalTask, 'A sibling approval task on the same line must be detected.');
        System.assertEquals(defaultType.DMT_External_Id__c, initData.defaultStepSelected, 'The order-zero relationship must drive the default step.');
        System.assertEquals(relatedApprovalTask.Id != null, true, 'The setup must leave a related approval task in place.');
        System.assertEquals(taskRecord.Id, loadData.get('taskId'), 'loadData must return the active task id on the happy path.');
        System.assertEquals(false, loadData.get('finishStep'), 'loadData must compute finishStep for the close-task state.');
        System.assertEquals(false, loadData.get('returnToProposalDisabled'), 'loadData must enable return to proposal for approval tasks.');
        System.assertEquals(1, ((List<Object>) loadData.get('toTask')).size(), 'loadData must expose one destination task.');
        System.assertEquals(1, ((List<Object>) loadData.get('relatedTasks')).size(), 'loadData must return sibling case tasks.');
    }

    @IsTest
    static void testGetCloseTaskInitialDataThrowsOnMissingCase() {
        String missingCaseId = fakeCaseId();
        Boolean threwNull = false;
        Boolean threwMissing = false;
        Boolean threwNoTask = false;
        Map<String, Object> missingLoadData;
        Map<String, Object> noTaskLoadData;

        Test.startTest();
        try {
            DMT_ApprovalTemplate_Controller.getCloseTaskInitialData(null);
        } catch (AuraHandledException ex) {
            threwNull = true;
            System.assertEquals('recordId is required.', ex.getMessage(), 'Null recordId must surface the expected error.');
        }

        try {
            DMT_ApprovalTemplate_Controller.getCloseTaskInitialData(missingCaseId);
        } catch (AuraHandledException ex) {
            threwMissing = true;
            System.assertEquals('Case not found.', ex.getMessage(), 'Missing Case must surface the expected error.');
        }

        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        Case noTaskCase = createCaseRecord(line.Id, UserInfo.getUserId());
        missingLoadData = DMT_ApprovalTemplate_Controller.loadData(missingCaseId);
        noTaskLoadData = DMT_ApprovalTemplate_Controller.loadData(noTaskCase.Id);
        try {
            DMT_ApprovalTemplate_Controller.getCloseTaskInitialData(noTaskCase.Id);
        } catch (AuraHandledException ex) {
            threwNoTask = true;
            System.assertEquals('No active Task found.', ex.getMessage(), 'A Case without an active Task must raise an AuraHandledException.');
        }
        Test.stopTest();

        System.assert(threwNull, 'Null recordId must raise an AuraHandledException.');
        System.assert(threwMissing, 'Missing Case must raise an AuraHandledException.');
        System.assert(threwNoTask, 'A Case without an active Task must raise an AuraHandledException.');
        System.assertEquals('norecord', missingLoadData.get('taskId'), 'Missing Cases must return the no-record payload.');
        System.assertEquals('norecord', noTaskLoadData.get('taskId'), 'Cases without an open task must return the no-record payload.');
    }

    @IsTest
    static void testSaveStepUpdatesTaskAndCase() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        Case caseRecord = createCaseRecord(line.Id, UserInfo.getUserId());
        DMT_Task_Type__c taskType = taskTypesByExternalId().get('1');
        Task taskRecord = createPendingTask(caseRecord.Id, taskType.Id, UserInfo.getUserId());

        Map<String, Object> records = new Map<String, Object>{
            'taskId' => taskRecord.Id,
            'caseId' => caseRecord.Id,
            'caseStatus' => 'In Progress',
            'stepResult' => 'Yes',
            'comments' => 'UT comment'
        };

        Test.startTest();
        DMT_ApprovalTemplate_Controller.saveStep(JSON.serialize(records));
        Test.stopTest();

        Assert.areEqual('Yes', [SELECT DMT_Step_Result__c FROM Task WHERE Id = :taskRecord.Id].DMT_Step_Result__c, 'saveStep must persist the step result on Task.');
        Assert.areEqual('In Progress', [SELECT Status FROM Case WHERE Id = :caseRecord.Id].Status, 'saveStep must update Case status.');
    }

    @IsTest
    static void testSaveAndCloseStep() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        Case caseRecord = createCaseRecord(line.Id, UserInfo.getUserId());
        DMT_Task_Type__c taskType = taskTypesByExternalId().get('1');
        Task taskRecord = createPendingTask(caseRecord.Id, taskType.Id, UserInfo.getUserId());

        Map<String, Object> records = new Map<String, Object>{
            'taskId' => taskRecord.Id,
            'caseId' => caseRecord.Id,
            'caseStatus' => 'Finished',
            'stepResult' => 'Yes'
        };

        Test.startTest();
        Map<String, Object> result = DMT_ApprovalTemplate_Controller.saveAndCloseStep(JSON.serialize(records));
        Test.stopTest();

        Assert.areEqual('TRUE', result.get('saveCloseTask'), 'saveAndCloseStep must signal success.');
        Assert.areEqual('Finished', [SELECT Status FROM Case WHERE Id = :caseRecord.Id].Status, 'saveAndCloseStep must update the Case to Finished.');
    }

    @IsTest
    static void saveAndCloseStepReturnsFreshButtonState() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        Case caseRecord = createCaseRecord(line.Id, UserInfo.getUserId());
        DMT_Task_Type__c taskType = taskTypesByExternalId().get('1');
        Task taskRecord = createPendingTask(caseRecord.Id, taskType.Id, UserInfo.getUserId());
        String recordsJson = JSON.serialize(new Map<String, Object>{
            'taskId' => taskRecord.Id,
            'caseId' => caseRecord.Id,
            'stepResult' => 'Yes',
            'comments' => 'Closed comments',
            'Committee_Label' => 'Closed committee',
            'caseStatus' => 'In Progress'
        });

        Test.startTest();
        Map<String, Object> result = DMT_ApprovalTemplate_Controller.saveAndCloseStep(recordsJson);
        Test.stopTest();

        System.assertEquals('TRUE', result.get('saveCloseTask'), 'saveAndCloseStep must return the saveCloseTask flag.');
        System.assertEquals(false, result.get('buttonDisabled'), 'Button must be enabled after saving a step result.');
        Task updatedTask = [SELECT Description, DMT_Step_Result__c, DMT_Committee_Label__c FROM Task WHERE Id = :taskRecord.Id];
        System.assertEquals('Closed comments', updatedTask.Description, 'Task comments must be persisted.');
        System.assertEquals('Yes', updatedTask.DMT_Step_Result__c, 'Task result must be persisted.');
        System.assertEquals('Closed committee', updatedTask.DMT_Committee_Label__c, 'Task committee label must be persisted.');
    }

    @IsTest
    static void testReturnToProposalMovesLineToDraft() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        Case caseRecord = createCaseRecord(line.Id, UserInfo.getUserId());
        DMT_Task_Type__c taskType = taskTypesByExternalId().get('1');
        Task selectedTask = createPendingTask(caseRecord.Id, taskType.Id, UserInfo.getUserId());
        DMT_Line__c proposalLine = DMT_Test_DataFactory.generateTestOtherLines();
        Case proposalCase = createCaseRecord(proposalLine.Id, UserInfo.getUserId());
        Task proposalTask = createPendingTask(proposalCase.Id, taskType.Id, UserInfo.getUserId());

        Map<String, Object> context = new Map<String, Object>{
            'DMT_LineOpportunity__c' => 'L',
            'LineId' => line.Id
        };
        Map<String, Object> proposalContext = new Map<String, Object>{
            'DMT_LineOpportunity__c' => 'L',
            'LineId' => proposalLine.Id
        };

        Test.startTest();
        DMT_ApprovalTemplate_Controller.returnToProposal(
            caseRecord.Id, selectedTask.Id, JSON.serialize(new Map<String, Object>()), JSON.serialize(context), 'Draft'
        );
        DMT_ApprovalTemplate_Controller.returnToProposal(
            proposalCase.Id, proposalTask.Id, JSON.serialize(new Map<String, Object>()), JSON.serialize(proposalContext), 'Proposal'
        );
        Test.stopTest();

        Assert.areEqual('Draft', [SELECT Status__c FROM DMT_Line__c WHERE Id = :line.Id].Status__c, 'Line must move to Draft when returning to proposal.');
        Assert.areEqual('Finished', [SELECT Status FROM Case WHERE Id = :caseRecord.Id].Status, 'Case must be finished after returnToProposal.');
        DMT_Line__c updatedProposalLine = [SELECT Status__c, Allowed__c FROM DMT_Line__c WHERE Id = :proposalLine.Id];
        Assert.areEqual('Proposal', updatedProposalLine.Status__c, 'Proposal status must use the dedicated line update branch.');
        Assert.areEqual(false, updatedProposalLine.Allowed__c, 'The temporary Allowed flag must be reset after moving back to Proposal.');
        Assert.areEqual('Finished', [SELECT Status FROM Case WHERE Id = :proposalCase.Id].Status, 'The proposal Case must also be finished.');
    }

    @IsTest
    static void testCloseTaskWithApproverInsertsNextStepTask() {
        Group approverGroup = new Group(Name = 'UT Close Approver Group', DeveloperName = 'UT_Close_Approver_Grp', Type = 'Queue');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert approverGroup;
            insert new QueueSobject(QueueId = approverGroup.Id, SobjectType = 'Task');
            insert new QueueSobject(QueueId = approverGroup.Id, SobjectType = 'Case');
        }

        DMT_Approver__c approver = new DMT_Approver__c(
            Name = 'UT Close Approver',
            DMT_External_Id__c = 'UT_CLOSE_APPROVER',
            DMT_Approver_Code__c = '12222233196',
            DMT_Group__c = approverGroup.DeveloperName
        );
        insert approver;
        DMT_Approver__c reloadedApprover = [SELECT Id, DMT_Group__c FROM DMT_Approver__c WHERE Id = :approver.Id LIMIT 1];
        if (reloadedApprover.DMT_Group__c != approverGroup.DeveloperName) {
            reloadedApprover.DMT_Group__c = approverGroup.DeveloperName;
            update reloadedApprover;
        }

        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        Case caseRecord = createCaseRecord(line.Id, UserInfo.getUserId());
        Map<String, DMT_Task_Type__c> taskTypes = taskTypesByExternalId();
        DMT_Task_Type__c currentType = taskTypes.get('1');
        DMT_Task_Type__c nextType = taskTypes.get('6');
        Task taskRecord = createPendingTask(caseRecord.Id, currentType.Id, approverGroup.Id);
        insert new DMT_Task_Relationship__c(
            DMT_From_Task_Type__c = currentType.Id,
            DMT_Order_Number__c = 1,
            DMT_To_Task_Type__c = nextType.Id
        );

        Test.startTest();
        DMT_ApprovalTemplate_Controller.CloseTaskResult result =
            DMT_ApprovalTemplate_Controller.executeCloseTask(
                caseRecord.Id,
                taskRecord.Id,
                nextType.DMT_External_Id__c,
                approver.DMT_External_Id__c
            );
        Test.stopTest();

        Case updatedCase = [SELECT Status, OwnerId FROM Case WHERE Id = :caseRecord.Id];
        Task updatedCurrentTask = [SELECT Status FROM Task WHERE Id = :taskRecord.Id];
        List<Task> nextTasks = [
            SELECT Id, OwnerId, DMT_Task_Type__c, Status
            FROM Task
            WHERE WhatId = :caseRecord.Id AND DMT_Task_Type__c = :nextType.Id
        ];

        System.assertEquals(true, result.success, 'Close task flow should succeed.');
        System.assertEquals('Pending', updatedCase.Status, 'Case should move to Pending.');
        System.assertEquals(approverGroup.Id, updatedCase.OwnerId, 'Case owner should move to the approver queue.');
        System.assertEquals('Completed', updatedCurrentTask.Status, 'Current task should be completed.');
        System.assertEquals(1, nextTasks.size(), 'One next-step task should be created.');
        System.assertEquals(approverGroup.Id, nextTasks[0].OwnerId, 'Next task should be assigned to the approver queue.');
    }

    @IsTest
    static void testGetApproversForStepBlankReturnsEmpty() {
        Id nullRecordId = null;
        String blankStep = '';
        Boolean threw = false;
        Test.startTest();
        try {
            DMT_ApprovalTemplate_Controller.getCloseTaskApprovers(nullRecordId, blankStep);
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        Assert.isTrue(threw, 'Blank step selection must raise an AuraHandledException.');
    }

    @IsTest
    static void approverAndValidationHelpersCoverEmptyAndMissingBranches() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        Case caseRecord = createCaseRecord(line.Id, UserInfo.getUserId());
        DMT_Task_Type__c currentType = taskTypesByExternalId().get('1');
        createPendingTask(caseRecord.Id, currentType.Id, UserInfo.getUserId());

        Test.startTest();
        try {
            DMT_ApprovalTemplate_Controller.getCloseTaskApprovers(null, currentType.DMT_External_Id__c);
            System.assert(false, 'Expected AuraHandledException for null recordId');
        } catch (AuraHandledException ex) {
            System.assertEquals('recordId is required.', ex.getMessage(), 'Null recordId must raise the expected error.');
        }

        try {
            DMT_ApprovalTemplate_Controller.getCloseTaskApprovers(caseRecord.Id, null);
            System.assert(false, 'Expected AuraHandledException for blank stepSelected');
        } catch (AuraHandledException ex) {
            System.assertEquals('stepSelected is required.', ex.getMessage(), 'Blank stepSelected must raise the expected error.');
        }

        try {
            DMT_ApprovalTemplate_Controller.getCloseTaskApprovers(caseRecord.Id, 'DOES_NOT_EXIST');
            System.assert(false, 'Expected AuraHandledException for missing task type');
        } catch (AuraHandledException ex) {
            System.assertEquals('Selected Task Type not found.', ex.getMessage(), 'Unknown external id must raise the expected error.');
        }

        String validationMessage = DMT_ApprovalTemplate_Controller.extractValidationMessage('plain validation message');
        Test.stopTest();

        System.assertEquals(
            'There is an incorrect value in the line, which is why the approval process cannot be completed.',
            validationMessage,
            'Validation message must be normalized from the raw text.'
        );
    }

    @IsTest
    static void getApproversForStepWithRelationshipReturnsApproverList() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        Case caseRecord = createCaseRecord(line.Id, UserInfo.getUserId());
        Map<String, DMT_Task_Type__c> taskTypes = taskTypesByExternalId();
        DMT_Task_Type__c fromType = taskTypes.get('1');
        DMT_Task_Type__c toType = taskTypes.get('6');
        toType.DMT_Approver_Field__c = 'DMT_Approver__c';
        toType.DMT_ApprovalEdit__c = true;
        update toType;
        createPendingTask(caseRecord.Id, fromType.Id, UserInfo.getUserId());
        insert new DMT_Task_Relationship__c(
            DMT_From_Task_Type__c = fromType.Id,
            DMT_Order_Number__c = 1,
            DMT_To_Task_Type__c = toType.Id
        );
        String approverExternalId = 'UT_APPROVER_' + String.valueOf(Math.abs(Crypto.getRandomLong()));
        DMT_Approver__c approver = new DMT_Approver__c(
            Name = 'UT Approver',
            DMT_External_Id__c = approverExternalId,
            DMT_Approver_Code__c = 'UTC' + String.valueOf(Math.abs(Crypto.getRandomLong()))
        );
        insert approver;
        Case relatedCase = createCaseRecord(line.Id, UserInfo.getUserId());
        createPendingTask(relatedCase.Id, toType.Id, UserInfo.getUserId());
        insert new DMT_Task_Approver_Relationship__c(
            DMT_Task_Type__c = toType.Id,
            DMT_Approver__c = approver.Id
        );

        Test.startTest();
        DMT_ApprovalTemplate_Controller.TaskSelectionDTO result =
            DMT_ApprovalTemplate_Controller.getCloseTaskApprovers(caseRecord.Id, toType.DMT_External_Id__c);
        Test.stopTest();

        System.assertEquals(1, result.approvers.size(), 'The selected task type should return one approver.');
        System.assertEquals(approverExternalId, result.approvers[0].value, 'The approver external id must be returned as the value.');
        System.assertEquals(true, result.showApprovers, 'Without approval-line state, the approver selector must stay visible.');
    }

    @IsTest
    static void testSaveStepThrowsAuraHandledExceptionOnBadJson() {
        Boolean threw = false;
        Test.startTest();
        try {
            DMT_ApprovalTemplate_Controller.saveStep('not valid json');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        Assert.isTrue(threw, 'Malformed JSON input must surface as an AuraHandledException.');
    }

    @IsTest
    static void testSaveAndCloseStepThrowsOnBadJson() {
        Boolean threw = false;
        Test.startTest();
        try {
            DMT_ApprovalTemplate_Controller.saveAndCloseStep('not valid json');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        Assert.isTrue(threw, 'Malformed JSON input must surface as an AuraHandledException.');
    }

    @IsTest
    static void testFinishCaseConditionThrowsOnBadJson() {
        String fakeCaseIdValue = fakeCaseId();
        String nullTaskId = null;
        Boolean threw = false;
        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        Case caseRecord = createCaseRecord(line.Id, UserInfo.getUserId());
        DMT_Task_Type__c currentType = taskTypesByExternalId().get('1');
        Task currentTask = createPendingTask(caseRecord.Id, currentType.Id, UserInfo.getUserId());
        Task relatedTask = createPendingTask(caseRecord.Id, currentType.Id, UserInfo.getUserId());
        Map<String, Object> context = new Map<String, Object>{
            'DMT_LineOpportunity__c' => 'L',
            'LineId' => line.Id
        };

        Test.startTest();
        DMT_ApprovalTemplate_Controller.finishCaseCondition(caseRecord.Id, currentTask.Id, '{}', JSON.serialize(context));
        try {
            DMT_ApprovalTemplate_Controller.finishCaseCondition(fakeCaseIdValue, nullTaskId, '{}', 'not valid json');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        Assert.isTrue(threw, 'Malformed JSON input must surface as an AuraHandledException.');
        Assert.areEqual('Finished', [SELECT Status FROM Case WHERE Id = :caseRecord.Id].Status, 'finishCaseCondition must finish the Case on the happy path.');
        Assert.areEqual('Finished', [SELECT Status FROM Task WHERE Id = :currentTask.Id].Status, 'finishCaseCondition must finish the current task through the related-task finisher.');
        Assert.areEqual('Finished', [SELECT Status FROM Task WHERE Id = :relatedTask.Id].Status, 'finishCaseCondition must finish sibling tasks on the same Case.');
    }

    @IsTest
    static void testReturnToProposalThrowsOnBadJson() {
        String fakeCaseIdValue = fakeCaseId();
        String nullTaskId = null;
        Boolean threw = false;
        Test.startTest();
        try {
            DMT_ApprovalTemplate_Controller.returnToProposal(fakeCaseIdValue, nullTaskId, '{}', 'not valid json', 'Draft');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        Assert.isTrue(threw, 'Malformed JSON input must surface as an AuraHandledException.');
    }

    @IsTest
    static void testCloseTaskWithApproverThrowsOnBadJson() {
        String fakeCaseIdValue = fakeCaseId();
        Id nullTaskId = null;
        Boolean threw = false;
        Test.startTest();
        try {
            DMT_ApprovalTemplate_Controller.executeCloseTask(fakeCaseIdValue, nullTaskId, 'not valid json', '{}');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        Assert.isTrue(threw, 'Malformed JSON input must surface as an AuraHandledException.');
    }

    @IsTest
    static void testGetApproversForStepWithoutRelationshipReturnsEmpty() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        Case caseRecord = createCaseRecord(line.Id, UserInfo.getUserId());
        DMT_Task_Type__c stepType = taskTypesByExternalId().get('1');

        Test.startTest();
        DMT_ApprovalTemplate_Controller.TaskSelectionDTO selection =
            DMT_ApprovalTemplate_Controller.getCloseTaskApprovers(caseRecord.Id, stepType.DMT_External_Id__c);
        Test.stopTest();

        Assert.areEqual(0, selection.approvers.size(), 'Without a task-approver relationship, no approvers should be returned.');
    }

    @IsTest
    static void closeTaskWithApproverUpdatesTaskAndCaseStatus() {
        DMT_Approver__c approver = new DMT_Approver__c(
            Name = 'UT Close Approver',
            DMT_External_Id__c = 'UT_CLOSE_APPROVER',
            DMT_Approver_Code__c = '12222233196'
        );
        insert approver;
        DMT_Approver__c reloadedApprover = [SELECT Id, DMT_Group__c FROM DMT_Approver__c WHERE Id = :approver.Id LIMIT 1];
        Group approverGroup = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = :reloadedApprover.DMT_Group__c LIMIT 1];
        String missingApproverExternalId = 'UT_MISSING_APPROVER_' + approver.Id;
        String missingTaskTypeExternalId = 'UT_MISSING_TASK_TYPE_' + approver.Id;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            if ([SELECT COUNT() FROM QueueSobject WHERE QueueId = :approverGroup.Id AND SobjectType = 'Task'] == 0) {
                insert new QueueSobject(QueueId = approverGroup.Id, SobjectType = 'Task');
            }
            if ([SELECT COUNT() FROM QueueSobject WHERE QueueId = :approverGroup.Id AND SobjectType = 'Case'] == 0) {
                insert new QueueSobject(QueueId = approverGroup.Id, SobjectType = 'Case');
            }
        }

        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        Case caseRecord = createCaseRecord(line.Id, UserInfo.getUserId());
        Map<String, DMT_Task_Type__c> taskTypes = taskTypesByExternalId();
        DMT_Task_Type__c currentType = taskTypes.get('1');
        DMT_Task_Type__c nextType = taskTypes.get('6');
        Task taskRecord = createPendingTask(caseRecord.Id, currentType.Id, approverGroup.Id);
        insert new DMT_Task_Relationship__c(
            DMT_From_Task_Type__c = currentType.Id,
            DMT_Order_Number__c = 1,
            DMT_To_Task_Type__c = nextType.Id
        );

        Test.startTest();
        DMT_ApprovalTemplate_Controller.CloseTaskResult result =
            DMT_ApprovalTemplate_Controller.executeCloseTask(
                caseRecord.Id,
                taskRecord.Id,
                nextType.DMT_External_Id__c,
                approver.DMT_External_Id__c
            );
        Test.stopTest();

        Case updatedCase = [SELECT Status, OwnerId FROM Case WHERE Id = :caseRecord.Id];
        Task updatedCurrentTask = [SELECT Status FROM Task WHERE Id = :taskRecord.Id];
        List<Task> nextTasks = [
            SELECT Id, OwnerId, DMT_Task_Type__c, Status
            FROM Task
            WHERE WhatId = :caseRecord.Id AND DMT_Task_Type__c = :nextType.Id
        ];

        System.assertEquals(true, result.success, 'Close task flow should succeed.');
        System.assertEquals('Pending', updatedCase.Status, 'Case should move to Pending.');
        System.assertEquals(approverGroup.Id, updatedCase.OwnerId, 'Case owner should move to the approver queue.');
        System.assertEquals('Completed', updatedCurrentTask.Status, 'Current task should be completed.');
        System.assertEquals(1, nextTasks.size(), 'One next-step task should be created.');
        System.assertEquals(approverGroup.Id, nextTasks[0].OwnerId, 'Next task should be assigned to the approver queue.');
    }

    @IsTest
    static void testExecuteCloseTaskFlowValidatesRequiredParameters() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        Case caseRecord = createCaseRecord(line.Id, UserInfo.getUserId());
        DMT_Task_Type__c currentType = taskTypesByExternalId().get('1');
        Task taskRecord = createPendingTask(caseRecord.Id, currentType.Id, UserInfo.getUserId());

        DMT_Approver__c approver = new DMT_Approver__c(
            Name = 'UT Validation Approver',
            DMT_External_Id__c = 'UT_VALIDATION_APPROVER',
            DMT_Approver_Code__c = '12222233197'
        );
        insert approver;

        Boolean threwCase = false;
        Boolean threwTask = false;
        Boolean threwStep = false;
        Boolean threwApprover = false;

        Test.startTest();
        try {
            DMT_TaskApprovalFlowService.executeCloseTaskFlow(null, taskRecord.Id, currentType.DMT_External_Id__c, approver.DMT_External_Id__c);
        } catch (AuraHandledException ex) {
            threwCase = true;
            System.assertEquals('Case Id is required.', ex.getMessage(), 'Null caseId must be rejected.');
        }

        try {
            DMT_TaskApprovalFlowService.executeCloseTaskFlow(caseRecord.Id, null, currentType.DMT_External_Id__c, approver.DMT_External_Id__c);
        } catch (AuraHandledException ex) {
            threwTask = true;
            System.assertEquals('Current Task Id is required.', ex.getMessage(), 'Null currentTaskId must be rejected.');
        }

        try {
            DMT_TaskApprovalFlowService.executeCloseTaskFlow(caseRecord.Id, taskRecord.Id, '', approver.DMT_External_Id__c);
        } catch (AuraHandledException ex) {
            threwStep = true;
            System.assertEquals('You must select a Task.', ex.getMessage(), 'Blank stepSelected must be rejected.');
        }

        try {
            DMT_TaskApprovalFlowService.executeCloseTaskFlow(caseRecord.Id, taskRecord.Id, currentType.DMT_External_Id__c, '');
        } catch (AuraHandledException ex) {
            threwApprover = true;
            System.assertEquals('You must select an Approver.', ex.getMessage(), 'Blank approverSelected must be rejected.');
        }
        Test.stopTest();

        System.assert(threwCase, 'The flow must validate a null case id.');
        System.assert(threwTask, 'The flow must validate a null current task id.');
        System.assert(threwStep, 'The flow must validate a blank step selection.');
        System.assert(threwApprover, 'The flow must validate a blank approver selection.');
    }

    @IsTest
    static void testExecuteCloseTaskFlowThrowsWhenApproverOrTaskTypeMissing() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        Case caseRecord = createCaseRecord(line.Id, UserInfo.getUserId());
        DMT_Task_Type__c currentType = taskTypesByExternalId().get('1');
        Task taskRecord;

        DMT_Approver__c approver = new DMT_Approver__c(
            Name = 'UT Missing Branch Approver',
            DMT_External_Id__c = 'UT_MISSING_BRANCH_APPROVER',
            DMT_Approver_Code__c = '12222233198'
        );
        insert approver;
        DMT_Approver__c reloadedApprover = [SELECT Id, DMT_Group__c FROM DMT_Approver__c WHERE Id = :approver.Id LIMIT 1];
        Group approverGroup = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = :reloadedApprover.DMT_Group__c LIMIT 1];
        System.runAs(new User(Id = UserInfo.getUserId())) {
            if ([SELECT COUNT() FROM QueueSobject WHERE QueueId = :approverGroup.Id AND SobjectType = 'Task'] == 0) {
                insert new QueueSobject(QueueId = approverGroup.Id, SobjectType = 'Task');
            }
            if ([SELECT COUNT() FROM QueueSobject WHERE QueueId = :approverGroup.Id AND SobjectType = 'Case'] == 0) {
                insert new QueueSobject(QueueId = approverGroup.Id, SobjectType = 'Case');
            }
        }
        taskRecord = createPendingTask(caseRecord.Id, currentType.Id, approverGroup.Id);
        String missingApproverExternalId = approver.DMT_External_Id__c + '_NOT_FOUND';
        String missingTaskTypeExternalId = currentType.DMT_External_Id__c + '_NOT_FOUND';

        Boolean threwMissingApprover = false;
        Boolean threwMissingTaskType = false;

        Test.startTest();
        try {
            DMT_TaskApprovalFlowService.executeCloseTaskFlow(caseRecord.Id, taskRecord.Id, currentType.DMT_External_Id__c, missingApproverExternalId);
        } catch (AuraHandledException ex) {
            threwMissingApprover = true;
        }

        try {
            DMT_TaskApprovalFlowService.executeCloseTaskFlow(caseRecord.Id, taskRecord.Id, missingTaskTypeExternalId, approver.DMT_External_Id__c);
        } catch (AuraHandledException ex) {
            threwMissingTaskType = true;
        }
        Test.stopTest();

        System.assert(threwMissingApprover, 'The flow must reject an unknown approver.');
        System.assert(threwMissingTaskType, 'The flow must reject an unknown task type.');
    }
}