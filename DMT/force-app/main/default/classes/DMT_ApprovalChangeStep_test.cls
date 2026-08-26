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
    public static void testCompareTasksFromCase() {
        TriggerBypass.setBypass();
        Group queueId = [SELECT Id FROM Group WHERE Type = 'Queue' and Name LIKE '%TestApproverDataFactory%' LIMIT 1];
        List<Task> tasks = [SELECT Id FROM Task WHERE OwnerId =: queueId.Id LIMIT 1];
        DMT_ApprovalChangeStep_Handler.updateTaskWithStatus(tasks[0].Id, false);

        List<Case> listCases = [SELECT Id,DMT_Line__c, opportunity_id__c,DMT_Related_feature_name__c, DMT_Line__r.Custom_Association__c, DMT_LineOpportunity__c,opportunity_id__r.RecordType.DeveloperName, DMT_Line__r.RecordType.DeveloperName FROM Case];
        DMT_ApprovalChangeStep_Handler.Request request = new DMT_ApprovalChangeStep_Handler.Request();
        request.records= listCases;
        DMT_ApprovalChangeStep_Handler.compareTasksFromCase(new List<DMT_ApprovalChangeStep_Handler.Request>{request});
        //System.assertEquals(!taskList.isEmpty(), true, 'Error comparing task');
    }

    @isTest
    public static void testCompareTasksFromCaseLWC() {

        List<Task> tasks = [SELECT Id FROM Task];
        DMT_ApprovalChangeStep_Handler.updateTaskWithStatus(tasks[0].Id, false);

        Case caseTest = [SELECT Id,DMT_Line__c,DMT_Related_feature_name__c FROM Case LIMIT 1];
        DMT_ApprovalChangeStep_Handler.compareTasksFromCaseLWC(caseTest.DMT_Line__c);
        //System.assertEquals(!taskList.isEmpty(), true, 'Error comparing task');
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
    @isTest
    public static void testCompareTasksFromCaseOpp() {
        TriggerBypass.setBypass();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        Case caseOpp = [SELECT Id,DMT_Line__c, opportunity_id__c, DMT_Line__r.Custom_Association__c, DMT_LineOpportunity__c,DMT_Related_feature_name__c,
                                opportunity_id__r.RecordType.DeveloperName, DMT_Line__r.RecordType.DeveloperName
                        FROM Case
                        WHERE DMT_Related_feature_name__c = 'Test1' AND opportunity_id__c =: opp.Id LIMIT 1];

        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId =: caseOpp.Id];
        DMT_ApprovalChangeStep_Handler.updateTaskWithStatus(tasks[0].Id, false);

        List<Case> listCases = [SELECT Id,DMT_Line__c, DMT_Related_feature_name__c,opportunity_id__c, DMT_Line__r.Custom_Association__c, DMT_LineOpportunity__c,opportunity_id__r.RecordType.DeveloperName, DMT_Line__r.RecordType.DeveloperName FROM Case WHERE opportunity_id__c =: opp.Id];
        DMT_ApprovalChangeStep_Handler.Request request = new DMT_ApprovalChangeStep_Handler.Request();
        request.records= listCases;
        DMT_ApprovalChangeStep_Handler.compareTasksFromCase(new List<DMT_ApprovalChangeStep_Handler.Request>{request});
        //System.assertEquals(!taskList.isEmpty(), true, 'Error comparing task');
    }

    @isTest
    private static void testOpportunityChildRecordsCompleteCoverage() {
        TriggerBypass.setBypass();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];

        // 1. Get the Opportunity Case and Task generated in TestSetup
        Case caseOpp = [SELECT Id, DMT_Line__c, opportunity_id__c, DMT_LineOpportunity__c,
                               opportunity_id__r.RecordType.DeveloperName, DMT_Line__r.RecordType.DeveloperName,
                               DMT_Line__r.Custom_Association__c, DMT_Related_feature_name__c
                        FROM Case
                        WHERE DMT_Related_feature_name__c = 'Test1' AND opportunity_id__c =: opp.Id LIMIT 1];

        Task taskOpp = [SELECT Id, Status, DMT_Not_Restart__c FROM Task WHERE WhatId = :caseOpp.Id LIMIT 1];

        // 2. THE FIX: Update the EXACT item your TestSetup already linked to the Opportunity View
        DMT_Items__c existingItem = [SELECT Id, DMT_Campos_componente_Refact__c FROM DMT_Items__c WHERE Name = 'Basic client' AND DMT_Component_Item__c = 'Opportunity Info' LIMIT 1];
        existingItem.DMT_Campos_componente_Refact__c = 'Opportunity.Name;DMT_Opportunity_Tenor__c.gj_nominal_amount_db__c;DMT_Opportunity_Mitigant__c.Mitigant_Type__c;OpportunityLineItem.DMT_Deal_Amount_Tenors__c;DMT_Opportunity_Client__c.Name;DMT_X_Sell__c.Name';
        update existingItem;

        Test.startTest();

        // 3. Cover Block 1: updateTaskWithStatus
        // This will now successfully find the item, populate the map, and run the queries!
        DMT_ApprovalChangeStep_Handler.updateTaskWithStatus(taskOpp.Id, false);

        // Ensure the task is considered 'In Progress' and not 'Cancelled' so compareTasksFromCase picks it up
        taskOpp.Status = 'In Progress';
        taskOpp.DMT_Not_Restart__c = false;
        update taskOpp;

        // 4. Cover Block 2 & 3: compareTasksFromCase
        DMT_ApprovalChangeStep_Handler.Request req = new DMT_ApprovalChangeStep_Handler.Request();
        req.records = new List<Case>{ caseOpp };
        DMT_ApprovalChangeStep_Handler.compareTasksFromCase(new List<DMT_ApprovalChangeStep_Handler.Request>{ req });

        Test.stopTest();

        // 5. Assert to ensure the data actually saved this time
        Task updatedTask = [SELECT Id, DMT_ViewStatusAtClose__c FROM Task WHERE Id = :taskOpp.Id];
        DMT_TaskStatusWhenCompleted__c statusRecord = [SELECT Id, DMT_AllFieldsInStatus__c FROM DMT_TaskStatusWhenCompleted__c WHERE Id = :updatedTask.DMT_ViewStatusAtClose__c];

        System.debug('JACG ' + statusRecord.DMT_AllFieldsInStatus__c);

        Assert.isNotNull(statusRecord.DMT_AllFieldsInStatus__c, 'Status field string should not be null');
        Assert.isTrue(statusRecord.DMT_AllFieldsInStatus__c.contains('DMT_Opportunity_Tenor__c'), 'The status record must contain the Opportunity keys.');
    }

    /**
     * @description CIBGLOBALD-4098: a tracked field that is null when the task's
     * snapshot is taken has no key in the stored JSON (System.JSON.serialize
     * suppresses nulls). If the diff in compareTasksFromCase only ever walks the
     * old snapshot's own keys, that field's later edit is never detected and the
     * Business Approval task never restarts. This proves the fix: after the field
     * goes from null to populated, the comparison must still detect the change and
     * cancel/recreate the task.
     *
     * Note: this deliberately does NOT try to set DMT_Items__c.DMT_Campos_componente_Refact__c
     * directly - the record-triggered flow UpdateComponentItemField (RecordAfterSave on
     * DMT_Items__c, not covered by TriggerBypass) unconditionally overwrites that field back
     * to a hardcoded constant whenever DMT_Component_Item__c = 'Opportunity Info' is saved,
     * which is exactly what TestSetup's 'Basic client' item already is. So instead this test
     * uses DMT_Capital_Action__c, a field that IS part of that flow's real constant list and
     * is genuinely null in test data (generateOpportunity() never sets it) - same effect as
     * the real-world repro (DES_Comments__c / DES_Description_rich__c), without fighting the flow.
     **/
    @isTest
    private static void testCompareTasksFromCase_DetectsFieldChangedFromNullToPopulated() {
        TriggerBypass.setBypass();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        Case caseOpp = [SELECT Id, DMT_Line__c, opportunity_id__c, DMT_LineOpportunity__c,
                               opportunity_id__r.RecordType.DeveloperName, DMT_Line__r.RecordType.DeveloperName,
                               DMT_Line__r.Custom_Association__c, DMT_Related_feature_name__c
                        FROM Case
                        WHERE DMT_Related_feature_name__c = 'Test1' AND opportunity_id__c =: opp.Id LIMIT 1];

        Task taskOpp = [SELECT Id, Status, DMT_Not_Restart__c FROM Task WHERE WhatId = :caseOpp.Id LIMIT 1];

        Assert.isNull([SELECT DMT_Capital_Action__c FROM Opportunity WHERE Id = :opp.Id].DMT_Capital_Action__c,
            'Test precondition: DMT_Capital_Action__c must be null so the snapshot omits it as a key.');

        Test.startTest();

        // Snapshot the task while DMT_Capital_Action__c is still null.
        DMT_ApprovalChangeStep_Handler.updateTaskWithStatus(taskOpp.Id, false);

        taskOpp.Status = 'In Progress';
        taskOpp.DMT_Not_Restart__c = false;
        update taskOpp;

        // Simulate the banker filling in a previously-blank tracked field while in Draft.
        opp.DMT_Capital_Action__c = 'New Facility';
        update opp;

        DMT_ApprovalChangeStep_Handler.Request req = new DMT_ApprovalChangeStep_Handler.Request();
        req.records = new List<Case>{ caseOpp };
        DMT_ApprovalChangeStep_Handler.compareTasksFromCase(new List<DMT_ApprovalChangeStep_Handler.Request>{ req });

        Test.stopTest();

        Task originalTask = [SELECT Id, Status FROM Task WHERE Id = :taskOpp.Id];
        Assert.areEqual('Cancelled', originalTask.Status,
            'The original task must be cancelled once the previously-null tracked field is populated.');

        List<Task> openTasksOnCase = [SELECT Id FROM Task WHERE WhatId = :caseOpp.Id AND Status != 'Cancelled'];
        Assert.areEqual(1, openTasksOnCase.size(),
            'A fresh task must be created to restart the approval for this feature.');
    }

    /**
     * @description CIBGLOBALD-3233 (restored - see CIBGLOBALD-4098): a Case whose related
     * feature is currently GREEN (already approved) in the Passport JSON must NOT be reset,
     * even when a tracked field genuinely changes. Covers the interaction between Alejandro's
     * green-feature-skip guard and the null-to-populated field detection fixed under
     * CIBGLOBALD-4098 - the field difference must be correctly detected AND then suppressed
     * by the green check, so the task stays untouched.
     **/
    @isTest
    private static void testCompareTasksFromCase_SkipsResetForGreenFeature() {
        TriggerBypass.setBypass();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        Case caseOpp = [SELECT Id, DMT_Line__c, opportunity_id__c, DMT_LineOpportunity__c,
                               opportunity_id__r.RecordType.DeveloperName, DMT_Line__r.RecordType.DeveloperName,
                               DMT_Line__r.Custom_Association__c, DMT_Related_feature_name__c
                        FROM Case
                        WHERE DMT_Related_feature_name__c = 'Test1' AND opportunity_id__c =: opp.Id LIMIT 1];

        Task taskOpp = [SELECT Id, Status, DMT_Not_Restart__c FROM Task WHERE WhatId = :caseOpp.Id LIMIT 1];

        // Mark this Case's feature as already-approved ("GREEN") in the Passport JSON.
        Passport__c passport = new Passport__c(
            Opportunity__c = opp.Id,
            DMT_Passport_Save__c = '{"data":{"features":[{"name":"' + caseOpp.DMT_Related_feature_name__c + '","stateName":"GREEN"}]}}'
        );
        insert passport;

        Test.startTest();

        // Snapshot the task while DMT_Capital_Action__c is still null.
        DMT_ApprovalChangeStep_Handler.updateTaskWithStatus(taskOpp.Id, false);

        taskOpp.Status = 'In Progress';
        taskOpp.DMT_Not_Restart__c = false;
        update taskOpp;

        // Same tracked-field edit that would normally trigger a restart.
        opp.DMT_Capital_Action__c = 'New Facility';
        update opp;

        DMT_ApprovalChangeStep_Handler.Request req = new DMT_ApprovalChangeStep_Handler.Request();
        req.records = new List<Case>{ caseOpp };
        DMT_ApprovalChangeStep_Handler.compareTasksFromCase(new List<DMT_ApprovalChangeStep_Handler.Request>{ req });

        Test.stopTest();

        Task originalTask = [SELECT Id, Status FROM Task WHERE Id = :taskOpp.Id];
        Assert.areEqual('In Progress', originalTask.Status,
            'A task on an already-approved (GREEN) feature must not be cancelled, even when a tracked field changes.');

        List<Task> allTasksOnCase = [SELECT Id FROM Task WHERE WhatId = :caseOpp.Id];
        Assert.areEqual(1, allTasksOnCase.size(),
            'No replacement task should be created for a GREEN feature.');
    }
}