@IsTest
private class DMT_RelatedTaskFinisherServiceTest {

    @IsTest
    static void testFinishesOpenTasksButNotCancelledOnes() {
        Case c = new Case(DMT_Passport_Sanction__c = 'approval');
        insert c;

        Task openTask = new Task(WhatId = c.Id, Subject = 'Open', Status = 'In Progress', ActivityDate = Date.today());
        Task cancelledTask = new Task(WhatId = c.Id, Subject = 'Cancelled', Status = 'Cancelled', ActivityDate = Date.today());
        insert new List<Task>{ openTask, cancelledTask };

        Test.startTest();
        DMT_RelatedTaskFinisherService.finishRelatedTasks(c.Id);
        Test.stopTest();

        Map<Id, Task> tasksAfter = new Map<Id, Task>([SELECT Id, Status FROM Task WHERE WhatId = :c.Id]);
        Assert.areEqual(DMT_Constants.FINISHED, tasksAfter.get(openTask.Id).Status, 'Open task must be finished.');
        Assert.areEqual('Cancelled', tasksAfter.get(cancelledTask.Id).Status, 'Cancelled task must be left untouched.');
    }

    @IsTest
    static void testMultipleCasesBulkSafe() {
        List<Case> cases = new List<Case>{
            new Case(DMT_Passport_Sanction__c = 'approval'),
            new Case(DMT_Passport_Sanction__c = 'approval')
        };
        insert cases;

        List<Task> tasks = new List<Task>{
            new Task(WhatId = cases[0].Id, Subject = 'T1', Status = 'In Progress', ActivityDate = Date.today()),
            new Task(WhatId = cases[1].Id, Subject = 'T2', Status = 'Not Started', ActivityDate = Date.today())
        };
        insert tasks;

        Test.startTest();
        DMT_RelatedTaskFinisherService.finishRelatedTasks(new List<Id>{ cases[0].Id, cases[1].Id });
        Test.stopTest();

        for (Task t : [SELECT Status FROM Task WHERE Id IN :tasks]) {
            Assert.areEqual(DMT_Constants.FINISHED, t.Status);
        }
    }

    @IsTest
    static void testNoOpWhenNoOpenTasks() {
        Case c = new Case(DMT_Passport_Sanction__c = 'approval');
        insert c;

        Test.startTest();
        DMT_RelatedTaskFinisherService.finishRelatedTasks(c.Id);
        DMT_RelatedTaskFinisherService.finishRelatedTasks((List<Id>) null);
        DMT_RelatedTaskFinisherService.finishRelatedTasks(new List<Id>());
        Test.stopTest();

        Assert.isTrue(true, 'No exception should be thrown when there is nothing to finish.');
    }
}