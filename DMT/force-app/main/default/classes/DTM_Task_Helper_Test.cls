/**
 * @description CIBGLOBALD-4617 - coverage for DTM_Task_Helper: DMT_Task__e must be published only for
 * DMT approval Tasks of a Case of a Line / Opportunity, only when a watched field changed, keyed by the
 * Line / Opportunity Id; and for Passport__c only when the JSON or the Obsolete flag changed.
 * The events are asserted through the @TestVisible build methods, without going through the event bus.
 */
@isTest
public with sharing class DTM_Task_Helper_Test {
    private static final Id CASE_RT_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Approval').getRecordTypeId();
    private static final Id TASK_RT_ID = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval').getRecordTypeId();
    private static final String LINE_EXT_ID = 'L-4617';
    private static Id queueId;

    @TestSetup
    static void loadTestData() {
        TriggerBypass.setBypass();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Line__c line = new DMT_Line__c(Line_Id__c = LINE_EXT_ID, Status__c = DMT_Constants.APPROVAL);
        insert line;

        insert new List<Passport__c>{
            new Passport__c(DMT_Line__c = line.Id, DMT_Passport_Save__c = '{"data":{}}'),
            new Passport__c(Opportunity__c = opp.Id, DMT_Passport_Save__c = '{"data":{}}')
        };
        TriggerBypass.removeBypass();
    }

    private static DMT_Line__c getLine() {
        return [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = :LINE_EXT_ID LIMIT 1];
    }

    private static Id getOppId() {
        return [SELECT Opportunity__c FROM Passport__c WHERE Opportunity__c != null LIMIT 1].Opportunity__c;
    }

    private static Id getQueueId() {
        if (queueId == null) {
            queueId = [SELECT Id FROM Group WHERE DeveloperName = 'DMT_Approvers1' LIMIT 1].Id;
        }
        return queueId;
    }

    private static Case createCase(Id lineId, Id oppId, String featureId) {
        Case newCase = new Case(RecordTypeId = CASE_RT_ID, DMT_Line__c = lineId, opportunity_id__c = oppId, DMT_Feature_Id__c = featureId,
                                DMT_Passport_Sanction__c = 'passport', Status = DMT_Constants.PENDING, OwnerId = getQueueId(), Subject = 'Test 4617');
        insert newCase;
        return newCase;
    }

    private static Task createTask(Id whatId) {
        Task newTask = new Task(WhatId = whatId, Status = 'In Progress', Subject = 'Step 4617', OwnerId = getQueueId(), RecordTypeId = TASK_RT_ID);
        insert newTask;
        // Every field DTM_Task_Helper compares must be selected, as it is in Trigger.new / Trigger.oldMap
        return [SELECT Id, WhatId, Status, OwnerId, RecordTypeId, Description, DMT_Step_Result__c, DMT_Step_Type__c,
                       DMT_Task_Type__c, DMT_UserClosedTask__c, DMT_Committee_Label__c
                FROM Task WHERE Id = :newTask.Id];
    }

    // Returns {newVersion, oldVersion} where only Status differs
    private static List<Task> statusChange(Task original, String newStatus) {
        Task updated = original.clone(true);
        updated.Status = newStatus;
        return new List<Task>{ updated, original };
    }

    @isTest
    static void testInsertPublishesLineId() {
        TriggerBypass.setBypass();
        DMT_Line__c line = getLine();
        Task task = createTask(createCase(line.Id, null, '10').Id);

        List<DMT_Task__e> events = DTM_Task_Helper.buildTaskEvents(new List<Task>{ task }, null, DTM_Task_Helper.OP_CREATE);

        Assert.areEqual(1, events.size(), 'One event per transaction is expected.');
        Assert.areEqual(DTM_Task_Helper.OP_CREATE, events[0].Operation__c, 'Operation must be CREATE.');
        Assert.areEqual(String.valueOf(line.Id), events[0].records__c, 'The event must carry the Line Id, not the Task Id.');
        TriggerBypass.removeBypass();
    }

    @isTest
    static void testOpportunityCasePublishesOpportunityId() {
        TriggerBypass.setBypass();
        Id oppId = getOppId();
        Task task = createTask(createCase(null, oppId, '10').Id);

        List<DMT_Task__e> events = DTM_Task_Helper.buildTaskEvents(new List<Task>{ task }, null, DTM_Task_Helper.OP_CREATE);

        Assert.areEqual(1, events.size(), 'One event is expected.');
        Assert.areEqual(String.valueOf(oppId), events[0].records__c, 'The event must carry the Opportunity Id.');
        TriggerBypass.removeBypass();
    }

    @isTest
    static void testNonApprovalTaskIsIgnored() {
        TriggerBypass.setBypass();
        Task task = createTask(createCase(getLine().Id, null, '10').Id);
        task.RecordTypeId = null;

        List<DMT_Task__e> events = DTM_Task_Helper.buildTaskEvents(new List<Task>{ task }, null, DTM_Task_Helper.OP_CREATE);

        Assert.isTrue(events.isEmpty(), 'A Task that is not a DMT approval step must not publish anything.');
        TriggerBypass.removeBypass();
    }

    @isTest
    static void testTaskNotRelatedToACaseIsIgnored() {
        TriggerBypass.setBypass();
        Task task = createTask(createCase(getLine().Id, null, '10').Id);
        task.WhatId = getLine().Id;

        List<DMT_Task__e> events = DTM_Task_Helper.buildTaskEvents(new List<Task>{ task }, null, DTM_Task_Helper.OP_CREATE);

        Assert.isTrue(events.isEmpty(), 'A Task whose WhatId is not a Case must not publish anything.');
        TriggerBypass.removeBypass();
    }

    @isTest
    static void testUpdateWithoutWatchedChangeIsIgnored() {
        TriggerBypass.setBypass();
        Task original = createTask(createCase(getLine().Id, null, '10').Id);
        Task updated = original.clone(true);
        updated.Description = 'Only the description changed';

        List<DMT_Task__e> events = DTM_Task_Helper.buildTaskEvents(
            new List<Task>{ updated }, new Map<Id, Task>{ original.Id => original }, DTM_Task_Helper.OP_MODIFY);

        Assert.isTrue(events.isEmpty(), 'A change on a field the traffic lights do not use must not publish anything.');
        TriggerBypass.removeBypass();
    }

    @isTest
    static void testStatusChangePublishesModify() {
        TriggerBypass.setBypass();
        DMT_Line__c line = getLine();
        Task original = createTask(createCase(line.Id, null, '10').Id);
        List<Task> versions = statusChange(original, DMT_Constants.CANCELLED);

        List<DMT_Task__e> events = DTM_Task_Helper.buildTaskEvents(
            new List<Task>{ versions[0] }, new Map<Id, Task>{ original.Id => versions[1] }, DTM_Task_Helper.OP_MODIFY);

        Assert.areEqual(1, events.size(), 'One event is expected.');
        Assert.areEqual(DTM_Task_Helper.OP_MODIFY, events[0].Operation__c, 'Operation must be MODIFY.');
        Assert.areEqual(String.valueOf(line.Id), events[0].records__c, 'The event must carry the Line Id.');
        TriggerBypass.removeBypass();
    }

    @isTest
    static void testSeveralTasksOfSameRecordPublishModifyMulti() {
        TriggerBypass.setBypass();
        DMT_Line__c line = getLine();
        Task original1 = createTask(createCase(line.Id, null, '10').Id);
        Task original2 = createTask(createCase(line.Id, null, '11').Id);
        List<Task> versions1 = statusChange(original1, DMT_Constants.FINISHED);
        List<Task> versions2 = statusChange(original2, DMT_Constants.FINISHED);

        List<DMT_Task__e> events = DTM_Task_Helper.buildTaskEvents(
            new List<Task>{ versions1[0], versions2[0] },
            new Map<Id, Task>{ original1.Id => versions1[1], original2.Id => versions2[1] },
            DTM_Task_Helper.OP_MODIFY);

        Assert.areEqual(1, events.size(), 'One event is expected.');
        Assert.areEqual(DTM_Task_Helper.OP_MODIFY_MULTI, events[0].Operation__c, 'Several Tasks of the same record must publish MODIFY_MULTI.');
        Assert.areEqual(String.valueOf(line.Id), events[0].records__c, 'The record Id must be published once.');
        TriggerBypass.removeBypass();
    }

    @isTest
    static void testBypassSkipsPublishing() {
        TriggerBypass.setBypass();
        Task task = createTask(createCase(getLine().Id, null, '10').Id);
        insert new CIB_Bypass__c(SetupOwnerId = UserInfo.getUserId(), CIB_skip_platform_event__c = true);

        List<DMT_Task__e> events = DTM_Task_Helper.buildTaskEvents(new List<Task>{ task }, null, DTM_Task_Helper.OP_CREATE);

        Assert.isTrue(events.isEmpty(), 'The platform event bypass must still skip publishing.');
        TriggerBypass.removeBypass();
    }

    @isTest
    static void testPassportObsoleteFlipPublishesLineId() {
        Passport__c original = [SELECT Id, DMT_Line__c, Opportunity__c, DMT_Is_Obsoleted_Passport_Save__c, DMT_Passport_Save__c
                                FROM Passport__c WHERE DMT_Line__c != null LIMIT 1];
        Passport__c updated = original.clone(true);
        updated.DMT_Is_Obsoleted_Passport_Save__c = !original.DMT_Is_Obsoleted_Passport_Save__c;

        List<DMT_Task__e> events = DTM_Task_Helper.buildPassportEvents(
            new List<Passport__c>{ updated }, new Map<Id, Passport__c>{ original.Id => original });

        Assert.areEqual(1, events.size(), 'One event is expected.');
        Assert.areEqual(DTM_Task_Helper.OP_PASSPORT, events[0].Operation__c, 'Operation must be PASSPORT.');
        Assert.areEqual(String.valueOf(original.DMT_Line__c), events[0].records__c, 'The event must carry the Line Id.');
    }

    @isTest
    static void testPassportJsonChangePublishesOpportunityId() {
        Passport__c original = [SELECT Id, DMT_Line__c, Opportunity__c, DMT_Is_Obsoleted_Passport_Save__c, DMT_Passport_Save__c
                                FROM Passport__c WHERE Opportunity__c != null LIMIT 1];
        Passport__c updated = original.clone(true);
        updated.DMT_Passport_Save__c = '{"data":{"features":[]}}';

        List<DMT_Task__e> events = DTM_Task_Helper.buildPassportEvents(
            new List<Passport__c>{ updated }, new Map<Id, Passport__c>{ original.Id => original });

        Assert.areEqual(1, events.size(), 'One event is expected.');
        Assert.areEqual(String.valueOf(original.Opportunity__c), events[0].records__c, 'The event must carry the Opportunity Id.');
    }

    @isTest
    static void testPassportWithoutRelevantChangeIsIgnored() {
        Passport__c original = [SELECT Id, DMT_Line__c, Opportunity__c, DMT_Is_Obsoleted_Passport_Save__c, DMT_Passport_Save__c
                                FROM Passport__c WHERE DMT_Line__c != null LIMIT 1];

        List<DMT_Task__e> events = DTM_Task_Helper.buildPassportEvents(
            new List<Passport__c>{ original.clone(true) }, new Map<Id, Passport__c>{ original.Id => original });

        Assert.isTrue(events.isEmpty(), 'An unchanged Passport must not publish anything.');
    }

    @isTest
    static void testProcessMethodsPublishWithoutErrors() {
        TriggerBypass.setBypass();
        DMT_Line__c line = getLine();
        Task task = createTask(createCase(line.Id, null, '10').Id);

        Test.startTest();
        DTM_Task_Helper.processTask(new List<Task>{ task }, null, DTM_Task_Helper.OP_CREATE);
        Test.stopTest();

        Assert.isTrue(true, 'Publishing through EventBus must not throw.');
        TriggerBypass.removeBypass();
    }
}
