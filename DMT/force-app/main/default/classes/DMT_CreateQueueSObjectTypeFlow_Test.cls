@isTest
public with sharing class DMT_CreateQueueSObjectTypeFlow_Test {
    @TestSetup
    static void makeData(){
        Group testGroup1 = new Group(Name = 'Test Group 1', Type='Queue');
        Group testGroup2 = new Group(Name = 'Test Group 2', Type='Queue');
        insert new List<Group>{testGroup1, testGroup2};
    }

    @isTest
    static void testCreateQueueSObjectsSuccess() {
        List<Group> testGroups = [SELECT Id, Name FROM Group WHERE Name IN ('Test Group 1', 'Test Group 2')];
        
        DMT_CreateQueueSObjectTypeFlow.Request request1 = new DMT_CreateQueueSObjectTypeFlow.Request();
        request1.groupId = testGroups[0].Id;
        request1.sObjectTypes = new List<String>{'Case', 'Lead'};

        DMT_CreateQueueSObjectTypeFlow.Request request2 = new DMT_CreateQueueSObjectTypeFlow.Request();
        request2.groupId = testGroups[1].Id;
        request2.sObjectTypes = new List<String>{'Task'};

        List<DMT_CreateQueueSObjectTypeFlow.Request> requestList = new List<DMT_CreateQueueSObjectTypeFlow.Request>{request1, request2};

        Test.startTest();
        DMT_CreateQueueSObjectTypeFlow.createQueueSObjects(requestList);
        Test.stopTest();

        List<QueueSObject> queueSObjects = [SELECT QueueId, SObjectType FROM QueueSObject WHERE QueueId IN :new Set<Id>{testGroups[0].Id, testGroups[1].Id}];

        System.assertEquals(3, queueSObjects.size(), 'Debe haber cuatro registros de QueueSObject');
    }

    @isTest
    static void testDeleteQueueSObjectsSuccess() {
        List<Group> testGroups = [SELECT Id, Name FROM Group WHERE Name IN ('Test Group 1', 'Test Group 2')];
        
        DMT_CreateQueueSObjectTypeFlow.Request request1 = new DMT_CreateQueueSObjectTypeFlow.Request();
        request1.groupId = testGroups[0].Id;
        request1.sObjectTypes = new List<String>{'Case', 'Lead'};

        DMT_CreateQueueSObjectTypeFlow.Request request2 = new DMT_CreateQueueSObjectTypeFlow.Request();
        request2.groupId = testGroups[1].Id;
        request2.sObjectTypes = new List<String>{'Task'};

        List<DMT_CreateQueueSObjectTypeFlow.Request> requestList = new List<DMT_CreateQueueSObjectTypeFlow.Request>{request1, request2};

        Test.startTest();
        DMT_CreateQueueSObjectTypeFlow.createQueueSObjects(requestList);
        

        DMT_DeleteQueueSOjectTypeflow.Request requestDelete = new DMT_DeleteQueueSOjectTypeflow.Request();
        requestDelete.groupLst = testGroups[0];
        DMT_DeleteQueueSOjectTypeflow.Request requestDelete2 = new DMT_DeleteQueueSOjectTypeflow.Request();
        requestDelete2.groupLst = testGroups[1];

        List<DMT_DeleteQueueSOjectTypeflow.Request> requestListToDelete = new List<DMT_DeleteQueueSOjectTypeflow.Request>{requestDelete, requestDelete2};

        DMT_DeleteQueueSOjectTypeflow.deleteQueueSObjects(requestListToDelete);

        Test.stopTest();

        List<QueueSObject> queueSObjectsDelete = [SELECT QueueId, SObjectType FROM QueueSObject WHERE QueueId IN :new Set<Id>{testGroups[0].Id, testGroups[1].Id}];
        System.assertEquals(0, queueSObjectsDelete.size(), 'Debe haber 0 registros de QueueSObject');
    }
}