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

        List<Task> tasks = DMT_Test_DataFactory.generateTasksWithOwner(queueId.Id, taskSetpCaseRecordTypeID, createdCase.Id, 3);

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
        item.DMT_Text__c = 'Esto es un texto normal';
        item.Type_Item__c = 'Component';
        item.CurrencyIsoCode = 'EUR';
        item.DMT_View__c = approverView.Id;

        DMT_Items__c item2 = new DMT_Items__c();
        item2.Name = 'Basic client Opp ';
        item2.DMT_Component_Item__c = 'Client';
        item2.DMT_order_display__c = 2;
        item2.DMT_Text__c = 'Esto es un texto normal';
        item2.Type_Item__c = 'Component';
        item2.CurrencyIsoCode = 'EUR';
        item2.DMT_View__c = approverView.Id;

        DMT_Items__c item3 = new DMT_Items__c();
        item3.Name = 'Basic client Opp 2';
        item3.DMT_Component_Item__c = 'Products';
        item3.DMT_order_display__c = 3;
        item3.DMT_Text__c = 'Esto es un texto normal';
        item3.Type_Item__c = 'Component';
        item3.CurrencyIsoCode = 'EUR';
        item3.DMT_View__c = approverView.Id;

        insert new List<DMT_Items__c>{item, item2, item3};

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
        List<Task> tasksOppty = DMT_Test_DataFactory.generateTasksWithOwner(queueOppId.Id, taskSetpCaseRecordTypeID, createdCaseOppty.Id, 3);
        DMT_Opportunity_Client__c oppClient = DMT_Test_DataFactory.generateOpportunityClient(opp.Id);
        OpportunityLineItem oppLI = DMT_Test_DataFactory.generateOpportunityLineItem(opp);
        DMT_Opportunity_Tenor__c oppTenor = DMT_Test_DataFactory.generateOpportunityTenor(oppLI);
        DMT_Opportunity_Mitigant__c oppMitigant = DMT_Test_DataFactory.generateOpportunityMitigant(oppLI); 

    }

    @isTest
    private static void testUpdateTaskWithStatusWithPdf()
    {
        
        List<Task> tasks = [SELECT Id FROM Task];
        String action = 'saveValuesUpdate';
        Map<String, Object> input = new Map<String, Object>{'recordId' => tasks[0].Id};
        Map<String, Object> args = new Map<String, Object>{'output' => new Map<String, Object>(), 'options' => new Map<String, Object>(), 'input' => input};

        DMT_ApprovalChangeStep_Handler approvalStepHandlerClass = new DMT_ApprovalChangeStep_Handler();
        approvalStepHandlerClass.call(action, args);

        Task tasksModified = [SELECT Id, DMT_ViewStatusAtClose__c FROM Task WHERE Id=:tasks[0].Id];
        
        System.assertEquals(true, tasksModified.DMT_ViewStatusAtClose__c != null , 'Error creating taskStatus');
    }

    @isTest
    private static void testUpdateTaskWithStatusWithoutPdf()
    {

        List<Task> tasks = [SELECT Id FROM Task];
        String action = 'saveValuesInsert';
        Map<String, Object> input = new Map<String, Object>{'recordId' => tasks[0].Id};
        Map<String, Object> args = new Map<String, Object>{'output' => new Map<String, Object>(), 'options' => new Map<String, Object>(), 'input' => input};

        DMT_ApprovalChangeStep_Handler approvalStepHandlerClass = new DMT_ApprovalChangeStep_Handler();
        approvalStepHandlerClass.call(action, args);
        Task tasksModified = [SELECT Id, DMT_ViewStatusAtClose__c FROM Task WHERE Id=:tasks[0].Id];
        
        System.assertEquals(true, tasksModified.DMT_ViewStatusAtClose__c !=null, 'Error creating taskStatus');
    }

   
@isTest
    public static void testCompareTasksFromCase() {

        List<Task> tasks = [SELECT Id FROM Task];
        DMT_ApprovalChangeStep_Handler.updateTaskWithStatus(tasks[0].Id, false);

        List<Case> listCases = [SELECT Id,DMT_Line__c, opportunity_id__c, DMT_Line__r.Custom_Association__c, DMT_LineOpportunity__c,opportunity_id__r.RecordType.DeveloperName, DMT_Line__r.RecordType.DeveloperName FROM Case];
        DMT_ApprovalChangeStep_Handler.Request request = new DMT_ApprovalChangeStep_Handler.Request();
        request.records= listCases;
        DMT_ApprovalChangeStep_Handler.compareTasksFromCase(new List<DMT_ApprovalChangeStep_Handler.Request>{request});
        //System.assertEquals(!taskList.isEmpty(), true, 'Error comparing task');
    }

    @isTest
    public static void testUpdateCase() {

        List<Task> tasks = [SELECT Id FROM Task];

        List<Case> listCases = [SELECT Id,DMT_Line__c,opportunity_id__c, DMT_Line__r.Custom_Association__c, DMT_LineOpportunity__c,opportunity_id__r.RecordType.DeveloperName, DMT_Line__r.RecordType.DeveloperName FROM Case];
        List<DMT_ApprovalChangeStep_Helper.RequestFinishedCase> requestList = new List<DMT_ApprovalChangeStep_Helper.RequestFinishedCase>();
        DMT_ApprovalChangeStep_Helper.RequestFinishedCase request = new DMT_ApprovalChangeStep_Helper.RequestFinishedCase();
        request.caseId = listCases.get(0).Id;
        request.owners = UserInfo.getUserId();
        requestList.add(request);
        Test.startTest();
        DMT_ApprovalChangeStep_Helper.updateOwnerFromCase(requestList);
        Test.stopTest();
        List<Case> listCasesUpdated = [SELECT Id, OwnerId FROM Case ORDER BY LastModifiedDate DESC];
        System.assertEquals(listCasesUpdated.get(0).OwnerId, UserInfo.getUserId(), 'It is not the same owner');
    }
    @isTest
    private static void testUpdateTaskWithStatusWithPdfOpp()
    {
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
        
        System.assertEquals(true, tasksModified.DMT_ViewStatusAtClose__c != null , 'Error creating taskStatus');
    }
    @isTest
    public static void testCompareTasksFromCaseOpp() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        Case caseOpp = [SELECT Id,DMT_Line__c, opportunity_id__c, DMT_Line__r.Custom_Association__c, DMT_LineOpportunity__c,
                                opportunity_id__r.RecordType.DeveloperName, DMT_Line__r.RecordType.DeveloperName 
                        FROM Case
                        WHERE DMT_Related_feature_name__c = 'Test1' AND opportunity_id__c =: opp.Id LIMIT 1]; 
        
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId =: caseOpp.Id];
        DMT_ApprovalChangeStep_Handler.updateTaskWithStatus(tasks[0].Id, false);

        List<Case> listCases = [SELECT Id,DMT_Line__c, opportunity_id__c, DMT_Line__r.Custom_Association__c, DMT_LineOpportunity__c,opportunity_id__r.RecordType.DeveloperName, DMT_Line__r.RecordType.DeveloperName FROM Case WHERE opportunity_id__c =: opp.Id];
        DMT_ApprovalChangeStep_Handler.Request request = new DMT_ApprovalChangeStep_Handler.Request();
        request.records= listCases;
        DMT_ApprovalChangeStep_Handler.compareTasksFromCase(new List<DMT_ApprovalChangeStep_Handler.Request>{request});
        //System.assertEquals(!taskList.isEmpty(), true, 'Error comparing task');
    }
}