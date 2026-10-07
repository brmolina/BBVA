@isTest
public with sharing class DMT_ApprovalChangeStep_test {

    @TestSetup
    static void loadTestData()
    {
        TriggerBypass.setBypass();
        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateTaskTypes();

        Id idView = DMT_Test_DataFactory.generateView();
        DMT_Test_DataFactory.generateApproverWithView(idView);

        Group queueId = [SELECT Id FROM Group WHERE Type = 'Queue' and Name LIKE '%TestApproverDataFactory%' LIMIT 1];
        System.runAs(new User(Id=UserInfo.getUserId()))
            {
                List<QueuesObject> queueSObjectList = new List<QueuesObject>();
                QueuesObject sobjectCaseQueue = new QueueSObject(QueueID = queueId.id, SObjectType = 'Case');
                queueSObjectList.add(sobjectCaseQueue);
                QueuesObject sobjectTaskQueue = new QueueSObject(QueueID = queueId.id, SObjectType = 'Task');
                queueSObjectList.add(sobjectTaskQueue);
                insert queueSObjectList;
            }

        Case createdCase = DMT_Test_DataFactory.generateCase(line.Id, null, UserInfo.getUserId());
        String taskSetpCaseRecordTypeID = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval').getRecordTypeId();

        DMT_Test_DataFactory.generateTasksWithOwner(queueId.Id, taskSetpCaseRecordTypeID, createdCase.Id, 1);

        //Create case for Opportuntity
        DMT_ApproversView__c approverView = new DMT_ApproversView__c(
            Name='PruebaLiOpp01',
            DMT_DeveloperName__c='DMT_PruebaOpp01',
            DMT_Type__c = 'Opportunity'
            );
        insert approverView;

        DMT_Items__c item = new DMT_Items__c();
        item.Name = 'Basic client';
        item.DMT_Component_Item__c = 'Opportunity Info';
        item.DMT_order_display__c = 1;
        item.DMT_Text__c = 'This is normal text';
        item.Type_Item__c = 'Component';
        item.CurrencyIsoCode = 'EUR';
        item.DMT_View__c = approverView.Id;

        DMT_Items__c item2 = new DMT_Items__c();
        item2.Name = 'Products Test';
        item2.DMT_Component_Item__c = 'Products';
        item2.DMT_order_display__c = 3;
        item2.DMT_Text__c = 'This is normal text';
        item2.Type_Item__c = 'Component';
        item2.CurrencyIsoCode = 'EUR';
        item2.DMT_View__c = approverView.Id;

        insert new List<DMT_Items__c>{item, item2};

        DMT_Approver__c approver = new DMT_Approver__c();
        approver.Name = 'TestApproverOPp01';
        approver.DMT_External_Id__c = 'TestExternalIdDATAFACTORY' + Integer.valueof((Math.random() * 100000000));
        approver.DMT_Approver_Code__c = '1222223316786';
        approver.Approvers_View_Opportunity__c= approverView.Id;
        insert approver;

        Group queueOppId = [SELECT Id FROM Group WHERE Type = 'Queue' and Name LIKE '%TestApproverOPp01%' LIMIT 1];
        System.runAs(new User(Id=UserInfo.getUserId()))
        {
            List<QueuesObject> queueOppSObjectList = new List<QueuesObject>();
            QueuesObject sobjectCaseOppQueue = new QueueSObject(QueueID = queueOppId.id, SObjectType = 'Case');
            queueOppSObjectList.add(sobjectCaseOppQueue);
            QueuesObject sobjectTaskOppQueue = new QueueSObject(QueueID = queueOppId.id, SObjectType = 'Task');
            queueOppSObjectList.add(sobjectTaskOppQueue);
            insert queueOppSObjectList;
        }
        Case createdCaseOppty = DMT_Test_DataFactory.generateCase(null, opp.Id, UserInfo.getUserId());
        DMT_Test_DataFactory.generateTasksWithOwner(queueOppId.Id, taskSetpCaseRecordTypeID, createdCaseOppty.Id, 1);
        DMT_Test_DataFactory.generateOpportunityClient(opp.Id);
        OpportunityLineItem oppLI = DMT_Test_DataFactory.generateOpportunityLineItem(opp);
        DMT_Test_DataFactory.generateOpportunityTenor(oppLI);
        DMT_Test_DataFactory.generateOpportunityMitigant(oppLI);

    }

    @isTest
    private static void testUpdateTaskWithStatusWithPdf()
    {
        TriggerBypass.setBypass();
        Group queueId = [SELECT Id FROM Group WHERE Type = 'Queue' and Name LIKE '%TestApproverDataFactory%' LIMIT 1];
        List<Task> tasks = [SELECT Id FROM Task WHERE OwnerId =: queueId.Id LIMIT 1];
        String action = 'saveValuesUpdate';
        Map<String, Object> input = new Map<String, Object>{'recordId' => tasks[0].Id};
        Map<String, Object> args = new Map<String, Object>{'output' => new Map<String, Object>(), 'options' => new Map<String, Object>(), 'input' => input};

        Test.startTest();
        DMT_ApprovalChangeStep_Handler approvalStepHandlerClass = new DMT_ApprovalChangeStep_Handler();
        approvalStepHandlerClass.call(action, args);
        Test.stopTest();

        Task tasksModified = [SELECT Id, DMT_ViewStatusAtClose__c FROM Task WHERE Id=:tasks[0].Id];

        Assert.isTrue(tasksModified.DMT_ViewStatusAtClose__c != null, 'Error creating taskStatus');
    }

    @isTest
    private static void testUpdateTaskWithStatusWithoutPdf()
    {
        TriggerBypass.setBypass();
        Group queueId = [SELECT Id FROM Group WHERE Type = 'Queue' and Name LIKE '%TestApproverDataFactory%' LIMIT 1];
        List<Task> tasks = [SELECT Id FROM Task WHERE OwnerId =: queueId.Id LIMIT 1];
        String action = 'saveValuesInsert';
        Map<String, Object> input = new Map<String, Object>{'recordId' => tasks[0].Id};
        Map<String, Object> args = new Map<String, Object>{'output' => new Map<String, Object>(), 'options' => new Map<String, Object>(), 'input' => input};

        Test.startTest();
        DMT_ApprovalChangeStep_Handler approvalStepHandlerClass = new DMT_ApprovalChangeStep_Handler();
        approvalStepHandlerClass.call(action, args);
        Test.stopTest();
        Task tasksModified = [SELECT Id, DMT_ViewStatusAtClose__c FROM Task WHERE Id=:tasks[0].Id];

        Assert.isTrue(tasksModified.DMT_ViewStatusAtClose__c != null, 'Error creating taskStatus');
    }


@isTest
    public static void testPreviewCompareTasksFromCase() {
        TriggerBypass.setBypass();

        Case lineCase = [SELECT Id, DMT_Line__c, DMT_Related_feature_name__c
                         FROM Case
                         WHERE DMT_Line__c != null
                         LIMIT 1];
        Task lineTask = [SELECT Id, DMT_ViewStatusAtClose__c
                         FROM Task
                         WHERE WhatId = :lineCase.Id
                         LIMIT 1];

        Test.startTest();
        DMT_ApprovalChangeStep_Handler.updateTaskWithStatus(lineTask.Id, false);
        List<DMT_ApprovalChangeStep_Handler.FeatureChangeWrapper> previewResult =
            DMT_ApprovalChangeStep_Handler.previewCompareTasksFromCase(lineCase.DMT_Line__c);
        Test.stopTest();

        Assert.isNotNull(previewResult, 'Preview result should not be null.');
        Assert.isTrue(previewResult.size() > 0, 'Preview should return at least one feature.');

        Boolean containsCaseFeature = false;
        for (DMT_ApprovalChangeStep_Handler.FeatureChangeWrapper featureWrapper : previewResult) {
            if (featureWrapper.featureName == lineCase.DMT_Related_feature_name__c) {
                containsCaseFeature = true;
                break;
            }
        }

        Assert.isTrue(containsCaseFeature, 'Preview should contain the related feature name from the case.');
    }

    @isTest
    public static void testPreviewCompareTasksFromCaseOpportunity() {
        TriggerBypass.setBypass();

        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        Case oppCase = [SELECT Id, opportunity_id__c, DMT_Related_feature_name__c
                         FROM Case
                         WHERE opportunity_id__c = :opp.Id
                         LIMIT 1];
        Task oppTask = [SELECT Id, DMT_ViewStatusAtClose__c
                         FROM Task
                         WHERE WhatId = :oppCase.Id
                         LIMIT 1];

        Test.startTest();
        DMT_ApprovalChangeStep_Handler.updateTaskWithStatus(oppTask.Id, false);
        List<DMT_ApprovalChangeStep_Handler.FeatureChangeWrapper> previewResult =
            DMT_ApprovalChangeStep_Handler.previewCompareTasksFromCase(oppCase.opportunity_id__c);
        Test.stopTest();

        Assert.isNotNull(previewResult, 'Preview result should not be null.');
        Assert.isTrue(previewResult.size() > 0, 'Preview should return at least one feature.');

        Boolean containsCaseFeature = false;
        for (DMT_ApprovalChangeStep_Handler.FeatureChangeWrapper featureWrapper : previewResult) {
            if (featureWrapper.featureName == oppCase.DMT_Related_feature_name__c) {
                containsCaseFeature = true;
                break;
            }
        }

        Assert.isTrue(containsCaseFeature, 'Preview should contain the related feature name from the case.');
    }

    @isTest
    public static void testUpdateCase() {
        TriggerBypass.setBypass();

        List<Case> listCases = [SELECT Id,DMT_Line__c,DMT_Related_feature_name__c,opportunity_id__c, DMT_Line__r.Custom_Association__c, DMT_LineOpportunity__c,opportunity_id__r.RecordType.DeveloperName, DMT_Line__r.RecordType.DeveloperName FROM Case];
        List<DMT_ApprovalChangeStep_Helper.RequestFinishedCase> requestList = new List<DMT_ApprovalChangeStep_Helper.RequestFinishedCase>();
        DMT_ApprovalChangeStep_Helper.RequestFinishedCase request = new DMT_ApprovalChangeStep_Helper.RequestFinishedCase();
        request.caseId = listCases.get(0).Id;
        request.owners = UserInfo.getUserId();
        requestList.add(request);
        Test.startTest();
        DMT_ApprovalChangeStep_Helper.updateOwnerFromCase(requestList);
        Test.stopTest();
        List<Case> listCasesUpdated = [SELECT Id, OwnerId FROM Case ORDER BY LastModifiedDate DESC];
        Assert.areEqual(listCasesUpdated.get(0).OwnerId, UserInfo.getUserId(), 'It is not the same owner');
    }
    @isTest
    private static void testUpdateTaskWithStatusWithPdfOpp()
    {
        TriggerBypass.setBypass();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        Case caseOpp = [SELECT Id,DMT_Line__c, opportunity_id__c, DMT_Line__r.Custom_Association__c, DMT_LineOpportunity__c,
                                opportunity_id__r.RecordType.DeveloperName, DMT_Line__r.RecordType.DeveloperName,DMT_Related_feature_name__c
                        FROM Case
                        WHERE DMT_Related_feature_name__c = 'Test1' AND opportunity_id__c =: opp.Id LIMIT 1];

        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId =: caseOpp.Id];
        String action = 'saveValuesUpdate';
        Map<String, Object> input = new Map<String, Object>{'recordId' => tasks[0].Id};
        Map<String, Object> args = new Map<String, Object>{'output' => new Map<String, Object>(), 'options' => new Map<String, Object>(), 'input' => input};

        DMT_ApprovalChangeStep_Handler approvalStepHandlerClass = new DMT_ApprovalChangeStep_Handler();
        approvalStepHandlerClass.call(action, args);

        Task tasksModified = [SELECT Id, DMT_ViewStatusAtClose__c FROM Task WHERE Id=:tasks[0].Id];

        Assert.isTrue(tasksModified.DMT_ViewStatusAtClose__c != null, 'Error creating taskStatus');
    }
    /**
     * @description CIBGLOBALD-4117: "Client" is the first renderer-tracked component whose
     * fields span more than one object (DMT_Line__c and Custom_Association_Client__c). Proves
     * updateTaskWithStatus's field-collection loop correctly prefixes each field with the object
     * it actually belongs to (sourced from DMT_RendererFactory.getTrackedFieldsByObject) instead
     * of blindly prefixing every renderer-returned field with the Line's own object name, which
     * would have produced an incorrect key like DMT_Line__c.Alpha_Code_Client__c. TestSetup's
     * DMT_PruebaLinea approver view already has a 'Client' DMT_Items__c row (Treasury RT), with
     * no DMT_Campos_componente_Refact__c value at all - before this fix, Client tracking for
     * this view was silently a no-op.
     **/
    @isTest
    private static void testUpdateTaskWithStatusPrefixesClientFieldsByTheirOwnObject() {
        TriggerBypass.setBypass();
        Group queueId = [SELECT Id FROM Group WHERE Type = 'Queue' and Name LIKE '%TestApproverDataFactory%' LIMIT 1];
        List<Task> tasks = [SELECT Id FROM Task WHERE OwnerId =: queueId.Id LIMIT 1];

        Test.startTest();
        DMT_ApprovalChangeStep_Handler.updateTaskWithStatus(tasks[0].Id, false);
        Test.stopTest();

        Task taskModified = [SELECT Id, DMT_ViewStatusAtClose__c FROM Task WHERE Id = :tasks[0].Id];
        DMT_TaskStatusWhenCompleted__c statusRecord = [SELECT Id, DMT_AllFieldsInStatus__c FROM DMT_TaskStatusWhenCompleted__c WHERE Id = :taskModified.DMT_ViewStatusAtClose__c];

        Assert.isNotNull(statusRecord.DMT_AllFieldsInStatus__c, 'Status field string should not be null');
        Assert.isTrue(statusRecord.DMT_AllFieldsInStatus__c.contains('DMT_Line__c.Client_Type__c'), 'DMT_Line__c-native Client field must be prefixed with DMT_Line__c.');
        Assert.isTrue(statusRecord.DMT_AllFieldsInStatus__c.contains('Custom_Association_Client__c.Alpha_Code_Client__c'), 'Custom_Association_Client__c field must be prefixed with its own object, not DMT_Line__c.');
        Assert.isFalse(statusRecord.DMT_AllFieldsInStatus__c.contains('DMT_Line__c.Alpha_Code_Client__c'), 'A Custom_Association_Client__c field must never be mis-prefixed with DMT_Line__c.');
    }

    // resolveApproverViewId reads Case.DMT_LineOpportunity__c, a formula field - it can't be set on
    // an in-memory Case (compile error), so the positive-match tests need a real inserted/queried
    // Line or Opportunity + Case. The no-match tests don't need that: leaving DMT_LineOpportunity__c
    // unset on an in-memory Case naturally exercises the "neither branch matches" path.
    @isTest
    private static void testResolveApproverViewIdTreasuryLine() {
        // TestSetup already created a TreasurySettlement Line - reuse it rather than generating a
        // second one, which collides on a duplicate rule against fixed Account/Line field values.
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c WHERE RecordType.DeveloperName = 'TreasurySettlement' LIMIT 1];
        Case insertedCase = DMT_Test_DataFactory.generateCase(line.Id, null, UserInfo.getUserId());
        Case c = [SELECT DMT_LineOpportunity__c, DMT_Line__c, DMT_Line__r.RecordType.DeveloperName FROM Case WHERE Id = :insertedCase.Id];
        DMT_Approver__c approver = new DMT_Approver__c(Approvers_View_Treasury__c = '000000000000001AAA');

        Assert.areEqual(approver.Approvers_View_Treasury__c, DMT_ApprovalChangeStep_Handler.resolveApproverViewId(approver, c));
    }

    @isTest
    private static void testResolveApproverViewIdOtherProductsLine() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
        Case insertedCase = DMT_Test_DataFactory.generateCase(line.Id, null, UserInfo.getUserId());
        Case c = [SELECT DMT_LineOpportunity__c, DMT_Line__c, DMT_Line__r.RecordType.DeveloperName FROM Case WHERE Id = :insertedCase.Id];
        DMT_Approver__c approver = new DMT_Approver__c(Approvers_View__c = '000000000000002AAA');

        Assert.areEqual(approver.Approvers_View__c, DMT_ApprovalChangeStep_Handler.resolveApproverViewId(approver, c));
    }

    @isTest
    private static void testResolveApproverViewIdOpportunity() {
        // TestSetup already created this Opportunity - reuse it rather than generating a second one.
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        Case insertedCase = DMT_Test_DataFactory.generateCase(null, opp.Id, UserInfo.getUserId());
        Case c = [SELECT DMT_LineOpportunity__c, opportunity_id__c, opportunity_id__r.RecordType.DeveloperName FROM Case WHERE Id = :insertedCase.Id];
        DMT_Approver__c approver = new DMT_Approver__c(Approvers_View_Opportunity__c = '000000000000003AAA');

        Assert.areEqual(approver.Approvers_View_Opportunity__c, DMT_ApprovalChangeStep_Handler.resolveApproverViewId(approver, c));
    }

    @isTest
    private static void testResolveApproverViewIdNoLineOrOpportunityReturnsNull() {
        // DMT_LineOpportunity__c is IF(!ISBLANK(opportunity_id__c),"O",IF(!ISBLANK(DMT_Line__c),"L"," "))
        // - with neither populated it resolves to a blank space, matching neither branch.
        Assert.isNull(DMT_ApprovalChangeStep_Handler.resolveApproverViewId(new DMT_Approver__c(), new Case()));
    }

    @isTest
    private static void testResolveApproverViewIdNullInputsReturnNull() {
        Assert.isNull(DMT_ApprovalChangeStep_Handler.resolveApproverViewId(null, new Case()));
        Assert.isNull(DMT_ApprovalChangeStep_Handler.resolveApproverViewId(new DMT_Approver__c(), null));
    }
}