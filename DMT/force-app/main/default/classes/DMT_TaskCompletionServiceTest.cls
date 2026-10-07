@IsTest
private class DMT_TaskCompletionServiceTest {

    @IsTest
    static void testCompleteTaskUpdatesExistingTask() {
        Case c = new Case(DMT_Passport_Sanction__c = 'approval');
        insert c;
        Task t = new Task(WhatId = c.Id, Subject = 'Original', Status = 'Not Started', ActivityDate = Date.today());
        insert t;

        DMT_TaskCompletionService.TaskCompletionRequest req = new DMT_TaskCompletionService.TaskCompletionRequest();
        req.taskId = t.Id;
        req.stepResult = 'Yes';
        req.comments = 'Looks good';
        req.committeeLabel = 'Committee A';
        req.doNotRestart = true;

        Test.startTest();
        DMT_TaskCompletionService.completeTask(req);
        Test.stopTest();

        Task after = [SELECT DMT_Step_Result__c, Description, DMT_Committee_Label__c, DMT_Not_Restart__c, Subject FROM Task WHERE Id = :t.Id];
        Assert.areEqual('Yes', after.DMT_Step_Result__c);
        Assert.areEqual('Looks good', after.Description);
        Assert.areEqual('Committee A', after.DMT_Committee_Label__c);
        Assert.isTrue(after.DMT_Not_Restart__c);
        Assert.areEqual('Original', after.Subject, 'A field left null on the request must not overwrite the existing value.');
    }

    @IsTest
    static void testCompleteTaskInsertsNewTaskWhenTaskIdIsBlank() {
        Case c = new Case(DMT_Passport_Sanction__c = 'approval');
        insert c;
        Id rtId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval').getRecordTypeId();

        DMT_TaskCompletionService.TaskCompletionRequest req = new DMT_TaskCompletionService.TaskCompletionRequest();
        req.caseId = c.Id;
        req.recordTypeId = rtId;
        req.status = 'In Progress';
        req.stepResult = 'Yes';

        Test.startTest();
        DMT_TaskCompletionService.completeTask(req);
        Test.stopTest();

        List<Task> tasks = [SELECT Id, Subject, Status, RecordTypeId, WhatId FROM Task WHERE WhatId = :c.Id];
        Assert.areEqual(1, tasks.size(), 'Exactly one new task must be inserted.');
        Assert.areEqual('Task', tasks[0].Subject, 'Subject must default to Task when none is given on insert.');
        Assert.areEqual('In Progress', tasks[0].Status);
        Assert.areEqual(rtId, tasks[0].RecordTypeId);
    }

    @IsTest
    static void testCompleteTasksBulkSafe() {
        Case c = new Case(DMT_Passport_Sanction__c = 'approval');
        insert c;
        List<Task> tasks = new List<Task>{
            new Task(WhatId = c.Id, Subject = 'T1', Status = 'Not Started', ActivityDate = Date.today()),
            new Task(WhatId = c.Id, Subject = 'T2', Status = 'Not Started', ActivityDate = Date.today())
        };
        insert tasks;

        List<DMT_TaskCompletionService.TaskCompletionRequest> requests = new List<DMT_TaskCompletionService.TaskCompletionRequest>();
        for (Task t : tasks) {
            DMT_TaskCompletionService.TaskCompletionRequest req = new DMT_TaskCompletionService.TaskCompletionRequest();
            req.taskId = t.Id;
            req.stepResult = 'Yes';
            requests.add(req);
        }

        Test.startTest();
        DMT_TaskCompletionService.completeTasks(requests);
        Test.stopTest();

        for (Task t : [SELECT DMT_Step_Result__c FROM Task WHERE Id IN :tasks]) {
            Assert.areEqual('Yes', t.DMT_Step_Result__c);
        }
    }

    @IsTest
    static void testCompleteTasksNoOpOnBlankInputs() {
        Test.startTest();
        DMT_TaskCompletionService.completeTasks(null);
        DMT_TaskCompletionService.completeTasks(new List<DMT_TaskCompletionService.TaskCompletionRequest>());
        DMT_TaskCompletionService.completeTasks(new List<DMT_TaskCompletionService.TaskCompletionRequest>{ null });
        Test.stopTest();

        Assert.isTrue(true, 'No exception should be thrown for blank/null inputs.');
    }
}