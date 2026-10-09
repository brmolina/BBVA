@IsTest
private class DMT_ApprovalTemplate_ControllerTest {

    private static Id approvalTaskRecordTypeId() {
        return Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
            .get('DMT_Step_Approval').getRecordTypeId();
    }

    private static DMT_Task_Type__c createTaskType(String externalId, Boolean approvalEdit, Boolean taskIndicator) {
        DMT_Task_Type__c taskType = new DMT_Task_Type__c(
            Name = 'UT Task ' + externalId,
            CurrencyIsoCode = 'EUR',
            DMT_External_Id__c = externalId,
            DMT_Yes_Flag__c = 'YES',
            DMT_No_Flag__c = 'NO',
            DMT_NA_Flag__c = 'NA',
            DMT_ApprovalEdit__c = approvalEdit,
            gf_task_ind_type__c = taskIndicator
        );
        insert taskType;
        return taskType;
    }

    private static Case createCase() {
        Opportunity opportunity = DMT_Test_DataFactory.generateOpportunity();
        Case caseRecord = DMT_Test_DataFactory.generateCase(null, opportunity.Id, UserInfo.getUserId());
        caseRecord.DMT_Passport_Sanction__c = 'approval';
        caseRecord.Status = 'In Progress';
        update caseRecord;
        return caseRecord;
    }

    private static Task createTask(Id caseId, Id taskTypeId, String result, String status) {
        Task taskRecord = new Task(
            WhatId = caseId,
            RecordTypeId = approvalTaskRecordTypeId(),
            Subject = 'UT Approval Task',
            Status = status,
            ActivityDate = Date.today(),
            Description = 'Initial comments',
            DMT_Task_Type__c = taskTypeId,
            DMT_Step_Result__c = result,
            DMT_Not_Restart__c = false,
            DMT_Committee_Label__c = 'Committee'
        );
        insert taskRecord;
        return taskRecord;
    }

    @IsTest
    static void loadData_withoutCase_returnsNoRecord() {
        Test.startTest();
        Map<String, Object> result = DMT_ApprovalTemplate_Controller.loadData(null);
        Test.stopTest();

        System.assertEquals('norecord', result.get('taskId'));
    }

    @IsTest
    static void loadData_withoutTask_returnsPermissionsAndNoRecord() {
        Case caseRecord = createCase();

        Test.startTest();
        Map<String, Object> result = DMT_ApprovalTemplate_Controller.loadData(caseRecord.Id);
        Test.stopTest();

        System.assertEquals('norecord', result.get('taskId'));
        System.assert(result.containsKey('hasEditCaseRole'));
        System.assert(result.containsKey('hasLineGodAccess'));
    }

    @IsTest
    static void loadData_withTaskAndRelations_returnsConfiguration() {
        Case caseRecord = createCase();
        DMT_Task_Type__c currentType = createTaskType('UT_CURRENT', false, false);
        DMT_Task_Type__c nextType = createTaskType('UT_NEXT', true, true);
        insert new DMT_Task_Relationship__c(
            DMT_From_Task_Type__c = currentType.Id,
            DMT_To_Task_Type__c = nextType.Id
        );
        Task relatedTask = createTask(caseRecord.Id, nextType.Id, 'No', 'In Progress');
        Task currentTask = createTask(caseRecord.Id, currentType.Id, 'Yes', 'In Progress');
        Datetime baseCreatedDate = Datetime.now();
        Test.setCreatedDate(relatedTask.Id, baseCreatedDate.addMinutes(-1));
        Test.setCreatedDate(currentTask.Id, baseCreatedDate);

        Test.startTest();
        Map<String, Object> result = DMT_ApprovalTemplate_Controller.loadData(caseRecord.Id);
        Test.stopTest();

        System.assertEquals(currentTask.Id, result.get('taskId'));
        System.assertEquals('Initial comments', result.get('comments'));
        System.assertEquals(false, result.get('buttonDisabled'));
        System.assert(result.containsKey('toTask'));
        System.assert(result.containsKey('validations'));
        System.assert(result.containsKey('proposalValidations'));
        System.assert(result.containsKey('relatedTasks'));
        System.assertEquals(true, ((List<Object>) result.get('relatedTasks')).size() > 0);
        System.assertNotEquals(null, relatedTask.Id);
    }

    @IsTest
    static void saveStep_updatesTaskAndCase() {
        Case caseRecord = createCase();
        DMT_Task_Type__c currentType = createTaskType('UT_SAVE', false, false);
        Task taskRecord = createTask(caseRecord.Id, currentType.Id, null, 'In Progress');
        String recordsJson = JSON.serialize(new Map<String, Object>{
            'taskId' => taskRecord.Id,
            'caseId' => caseRecord.Id,
            'stepResult' => 'No',
            'comments' => 'Saved comments',
            'Committee_Label' => 'Saved committee',
            'caseStatus' => 'Finished',
            'doNotAskCheck' => true,
            'stepSelected' => currentType.DMT_External_Id__c
        });

        Test.startTest();
        Map<String, Object> result = DMT_ApprovalTemplate_Controller.saveStep(recordsJson);
        Test.stopTest();

        System.assertNotEquals(null, result);
        Task updatedTask = [SELECT Description, DMT_Step_Result__c, DMT_Not_Restart__c FROM Task WHERE Id = :taskRecord.Id];
        System.assertEquals('Saved comments', updatedTask.Description);
        System.assertEquals('No', updatedTask.DMT_Step_Result__c);
        System.assertEquals(true, updatedTask.DMT_Not_Restart__c);
        System.assertEquals('Finished', [SELECT Status FROM Case WHERE Id = :caseRecord.Id].Status);
    }

    @IsTest
    static void saveAndCloseStep_returnsFreshButtonState() {
        Case caseRecord = createCase();
        DMT_Task_Type__c taskType = createTaskType('UT_CLOSE', false, false);
        Task taskRecord = createTask(caseRecord.Id, taskType.Id, null, 'In Progress');
        String recordsJson = JSON.serialize(new Map<String, Object>{
            'taskId' => taskRecord.Id,
            'caseId' => caseRecord.Id,
            'stepResult' => 'Yes',
            'comments' => 'Closed comments',
            'caseStatus' => 'In Progress'
        });

        Test.startTest();
        Map<String, Object> result = DMT_ApprovalTemplate_Controller.saveAndCloseStep(recordsJson);
        Test.stopTest();

        System.assertEquals('TRUE', result.get('saveCloseTask'));
        System.assertEquals(false, result.get('buttonDisabled'));
    }

    @IsTest
    static void finishAndReturnPaths_updateCaseAndRelatedTasks() {
        Case caseRecord = createCase();
        DMT_Task_Type__c taskType = createTaskType('UT_FINISH', false, false);
        Task taskRecord = createTask(caseRecord.Id, taskType.Id, 'Yes', 'In Progress');
        String contextJson = JSON.serialize(new Map<String, Object>{
            'DMT_LineOpportunity__c' => 'O',
            'OpportunityId' => [SELECT opportunity_id__c FROM Case WHERE Id = :caseRecord.Id].opportunity_id__c,
            'relatedTasks' => new List<Object>{ new Map<String, Object>{
                'taskId' => taskRecord.Id,
                'taskStatus' => 'Completed'
            }}
        });

        Test.startTest();
        DMT_ApprovalTemplate_Controller.finishCaseCondition(
            caseRecord.Id, taskRecord.Id, '{}', contextJson
        );
        Test.stopTest();

        // Case automation normalizes related task status to 'Finished' once the case closes
        System.assertEquals('Finished', [SELECT Status FROM Case WHERE Id = :caseRecord.Id].Status);
        System.assertEquals('Finished', [SELECT Status FROM Task WHERE Id = :taskRecord.Id].Status);
    }

    @IsTest
    static void returnToProposal_updatesOpportunityToDraft() {
        Case caseRecord = createCase();
        Id opportunityId = [SELECT opportunity_id__c FROM Case WHERE Id = :caseRecord.Id].opportunity_id__c;
        DMT_Task_Type__c taskType = createTaskType('UT_RETURN', false, false);
        Task taskRecord = createTask(caseRecord.Id, taskType.Id, 'Yes', 'In Progress');
        String contextJson = JSON.serialize(new Map<String, Object>{
            'DMT_LineOpportunity__c' => 'O',
            'OpportunityId' => opportunityId,
            'relatedTasks' => new List<Object>()
        });

        Test.startTest();
        DMT_ApprovalTemplate_Controller.returnToProposal(
            caseRecord.Id, taskRecord.Id, '{}', contextJson, 'Draft'
        );
        Test.stopTest();

        System.assertEquals('Finished', [SELECT Status FROM Case WHERE Id = :caseRecord.Id].Status);
        System.assertEquals('Draft', [SELECT StageName FROM Opportunity WHERE Id = :opportunityId].StageName);
    }

    @IsTest
    static void approverAndValidationHelpers_coverEmptyAndMissingBranches() {
        Test.startTest();
        List<Map<String, Object>> emptyResult = DMT_ApprovalTemplate_Controller.getApproversForStep('', null);
        List<Map<String, Object>> koResult = DMT_ApprovalTemplate_Controller.getApproversForStep('KO', null);
        List<Map<String, Object>> missingResult = DMT_ApprovalTemplate_Controller.getApproversForStep('DOES_NOT_EXIST', null);
        String validationMessage = DMT_ApprovalTemplate_Controller.extractValidationMessage('plain validation message');
        Test.stopTest();

        System.assertEquals(0, emptyResult.size());
        System.assertEquals(0, koResult.size());
        System.assertEquals(0, missingResult.size());
        System.assertEquals(
            'There is an incorrect value in the line, which is why the approval process cannot be completed.',
            validationMessage
        );
    }

    @IsTest
    static void getApproversForStep_withRelationship_returnsApproverList() {
        DMT_Task_Type__c fromType = createTaskType('UT_APP_FROM', false, false);
        DMT_Task_Type__c toType = createTaskType('UT_APP_TO', false, false);
        insert new DMT_Task_Relationship__c(
            DMT_From_Task_Type__c = fromType.Id,
            DMT_To_Task_Type__c = toType.Id
        );
        DMT_Approver__c approver = new DMT_Approver__c(
            Name = 'UT Approver',
            DMT_External_Id__c = 'UT_APPROVER_EXT',
            DMT_Approver_Code__c = '12222233199'
        );
        insert approver;
        insert new DMT_Task_Approver_Relationship__c(
            DMT_Task_Type__c = toType.Id,
            DMT_Approver__c = approver.Id
        );

        Test.startTest();
        List<Map<String, Object>> result = DMT_ApprovalTemplate_Controller.getApproversForStep(fromType.DMT_External_Id__c, null);
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('UT_APPROVER_EXT', result[0].get('value'));
    }

    @IsTest
    static void loadData_withGroupOwnerAndApproverMember_returnsAccessLevel() {
        Group ownerGroup = new Group(Name = 'UT Owner Group', DeveloperName = 'UT_Owner_Group', Type = 'Queue');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert ownerGroup;
            insert new QueueSobject(QueueId = ownerGroup.Id, SobjectType = 'Case');
        }

        Opportunity opportunity = DMT_Test_DataFactory.generateOpportunity();
        Case caseRecord = DMT_Test_DataFactory.generateCase(null, opportunity.Id, ownerGroup.Id);
        caseRecord.DMT_Passport_Sanction__c = 'approval';
        caseRecord.Status = 'In Progress';
        update caseRecord;
        DMT_Task_Type__c currentType = createTaskType('UT_ACCESS', false, false);
        createTask(caseRecord.Id, currentType.Id, 'Yes', 'In Progress');

        DMT_Approver__c approver = new DMT_Approver__c(
            Name = 'UT Access Approver',
            DMT_External_Id__c = 'UT_ACCESS_APPROVER',
            DMT_Approver_Code__c = '12222233198',
            DMT_Group__c = ownerGroup.DeveloperName
        );
        insert approver;
        // The After_Trigger_DMT_Approver flow may overwrite DMT_Group__c, so restore it
        DMT_Approver__c reloadedApprover = [SELECT Id, DMT_Group__c FROM DMT_Approver__c WHERE Id = :approver.Id LIMIT 1];
        if (reloadedApprover.DMT_Group__c != ownerGroup.DeveloperName) {
            reloadedApprover.DMT_Group__c = ownerGroup.DeveloperName;
            update reloadedApprover;
        }
        insert new DMT_Approver_Member__c(
            DMT_Approver__c = approver.Id,
            DMT_User__c = UserInfo.getUserId(),
            DMT_Access_Level__c = 'Edit'
        );

        Test.startTest();
        Map<String, Object> result = DMT_ApprovalTemplate_Controller.loadData(caseRecord.Id);
        Test.stopTest();

        System.assertEquals('Edit', result.get('accessLevel'));
    }

    @IsTest
    static void loadData_withLineOpportunityAndClosingTasks_computesFormulas() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        Case caseRecord = DMT_Test_DataFactory.generateCase(line.Id, null, UserInfo.getUserId());
        caseRecord.DMT_Passport_Sanction__c = 'approval';
        caseRecord.Status = 'In Progress';
        DMT_Task_Type__c currentType = createTaskType('UT_LINE', false, true);
        caseRecord.DMT_Closing_Tasks__c = JSON.serialize(new List<Object>{
            new Map<String, Object>{ 'id' => currentType.DMT_External_Id__c }
        });
        update caseRecord;
        Task currentTask = createTask(caseRecord.Id, currentType.Id, 'No', 'In Progress');

        Test.startTest();
        Map<String, Object> result = DMT_ApprovalTemplate_Controller.loadData(caseRecord.Id);
        Test.stopTest();

        System.assertEquals(false, result.get('returnToProposalDisabled'));
        System.assertEquals(false, result.get('finishStep'));
    }

    @IsTest
    static void saveStep_withNextApprover_setsTaskOwnerFromGroup() {
        Group approverGroup = new Group(Name = 'UT Next Approver Group', DeveloperName = 'UT_Next_Approver_Grp', Type = 'Queue');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert approverGroup;
            insert new QueueSobject(QueueId = approverGroup.Id, SobjectType = 'Task');
        }

        DMT_Approver__c approver = new DMT_Approver__c(
            Name = 'UT Next Approver',
            DMT_External_Id__c = 'UT_NEXT_APPROVER',
            DMT_Approver_Code__c = '12222233197',
            DMT_Group__c = approverGroup.DeveloperName
        );
        insert approver;
        // The After_Trigger_DMT_Approver flow may overwrite DMT_Group__c, so restore it
        DMT_Approver__c reloadedApprover = [SELECT Id, DMT_Group__c FROM DMT_Approver__c WHERE Id = :approver.Id LIMIT 1];
        if (reloadedApprover.DMT_Group__c != approverGroup.DeveloperName) {
            reloadedApprover.DMT_Group__c = approverGroup.DeveloperName;
            update reloadedApprover;
        }

        Case caseRecord = createCase();
        DMT_Task_Type__c currentType = createTaskType('UT_NEXTAPP', false, false);
        Task taskRecord = createTask(caseRecord.Id, currentType.Id, null, 'In Progress');
        String recordsJson = JSON.serialize(new Map<String, Object>{
            'taskId' => taskRecord.Id,
            'caseId' => caseRecord.Id,
            'stepResult' => 'Yes',
            'comments' => 'Comments',
            'caseStatus' => 'In Progress',
            'stepSelected' => currentType.DMT_External_Id__c,
            'nextApprover' => approver.DMT_External_Id__c
        });

        Test.startTest();
        DMT_ApprovalTemplate_Controller.saveStep(recordsJson);
        Test.stopTest();

        Task updatedTask = [SELECT OwnerId FROM Task WHERE Id = :taskRecord.Id];
        System.assertEquals(approverGroup.Id, updatedTask.OwnerId);
    }

    @IsTest
    static void closeTaskWithApprover_updatesTaskAndCaseStatus() {
        Case caseRecord = createCase();
        DMT_Task_Type__c currentType = createTaskType('UT_CLOSEAPP', false, false);
        Task taskRecord = createTask(caseRecord.Id, currentType.Id, null, 'In Progress');
        String recordsJson = JSON.serialize(new Map<String, Object>{
            'taskId' => taskRecord.Id,
            'caseId' => caseRecord.Id,
            'stepResult' => 'Yes',
            'comments' => 'Approver comments',
            'stepSelected' => currentType.DMT_External_Id__c
        });

        Test.startTest();
        DMT_ApprovalTemplate_Controller.closeTaskWithApprover(caseRecord.Id, taskRecord.Id, recordsJson, '{}');
        Test.stopTest();

        System.assertEquals('In Progress', [SELECT Status FROM Case WHERE Id = :caseRecord.Id].Status);
        System.assertEquals('Approver comments', [SELECT Description FROM Task WHERE Id = :taskRecord.Id].Description);
    }
}