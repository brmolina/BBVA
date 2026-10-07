@IsTest
private class DMT_DocumentTransferServiceTest {

    private static Id insertDocumentLinkedTo(Id entityId) {
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'test.txt',
            VersionData = Blob.valueOf('Test content'),
            FirstPublishLocationId = entityId
        );
        insert cv;
        return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
    }

    @IsTest
    static void testTransfersDocumentFromCaseToTask() {
        Case c = new Case(DMT_Passport_Sanction__c = 'approval');
        insert c;
        Task t = new Task(WhatId = c.Id, Subject = 'Task', Status = 'Finished', ActivityDate = Date.today());
        insert t;
        insertDocumentLinkedTo(c.Id);

        Test.startTest();
        DMT_DocumentTransferService.transferDocuments(c.Id, t.Id);
        Test.stopTest();

        Assert.isTrue(
            [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :t.Id] > 0,
            'Document must now be linked to the task.'
        );
        Assert.areEqual(
            0, [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :c.Id],
            'Document must no longer be linked to the case.'
        );
    }

    @IsTest
    static void testDoesNotDuplicateLinkAlreadyOnTargetTask() {
        Case c = new Case(DMT_Passport_Sanction__c = 'approval');
        insert c;
        Task t = new Task(WhatId = c.Id, Subject = 'Task', Status = 'Finished', ActivityDate = Date.today());
        insert t;
        Id contentDocumentId = insertDocumentLinkedTo(c.Id);
        insert new ContentDocumentLink(
            LinkedEntityId = t.Id, ContentDocumentId = contentDocumentId,
            ShareType = 'V', Visibility = 'InternalUsers'
        );

        Test.startTest();
        DMT_DocumentTransferService.transferDocuments(c.Id, t.Id);
        Test.stopTest();

        Assert.areEqual(
            1, [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :t.Id],
            'A link that already exists on the target task must not be duplicated.'
        );
    }

    @IsTest
    static void testBulkTransferAcrossMultipleCases() {
        List<Case> cases = new List<Case>{
            new Case(DMT_Passport_Sanction__c = 'approval'),
            new Case(DMT_Passport_Sanction__c = 'approval')
        };
        insert cases;
        List<Task> tasks = new List<Task>{
            new Task(WhatId = cases[0].Id, Subject = 'T1', Status = 'Finished', ActivityDate = Date.today()),
            new Task(WhatId = cases[1].Id, Subject = 'T2', Status = 'Finished', ActivityDate = Date.today())
        };
        insert tasks;
        insertDocumentLinkedTo(cases[0].Id);
        insertDocumentLinkedTo(cases[1].Id);

        Test.startTest();
        DMT_DocumentTransferService.transferDocuments(new Map<Id, Id>{
            cases[0].Id => tasks[0].Id,
            cases[1].Id => tasks[1].Id
        });
        Test.stopTest();

        Assert.isTrue([SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :tasks[0].Id] > 0);
        Assert.isTrue([SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :tasks[1].Id] > 0);
    }

    @IsTest
    static void testNoOpOnBlankOrEmptyInputs() {
        Test.startTest();
        DMT_DocumentTransferService.transferDocuments((Map<Id, Id>) null);
        DMT_DocumentTransferService.transferDocuments(new Map<Id, Id>());
        DMT_DocumentTransferService.transferDocuments(null, null);
        Test.stopTest();

        Assert.isTrue(true, 'No exception should be thrown for blank/empty inputs.');
    }

    @IsTest
    static void testDispatchedThroughAsyncDispatcher() {
        Case c = new Case(DMT_Passport_Sanction__c = 'approval');
        insert c;
        Task t = new Task(WhatId = c.Id, Subject = 'Task', Status = 'Finished', ActivityDate = Date.today());
        insert t;
        insertDocumentLinkedTo(c.Id);

        DMT_DocumentTransferPayload payload = new DMT_DocumentTransferPayload(
            new Map<Id, Id>{ c.Id => t.Id }
        );

        Test.startTest();
        DMT_AsyncDispatcher.dispatch(payload);
        Test.stopTest();

        Assert.isTrue(
            [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :t.Id] > 0,
            'Dispatching the payload must actually run the document transfer.'
        );
    }
}