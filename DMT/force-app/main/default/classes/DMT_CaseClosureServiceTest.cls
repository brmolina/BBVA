@IsTest
private class DMT_CaseClosureServiceTest {

    @IsTest
    static void testSetStatusUpdatesSingleCase() {
        Case c = new Case(DMT_Passport_Sanction__c = 'approval');
        insert c;

        Test.startTest();
        DMT_CaseClosureService.setStatus(c.Id, 'Finished');
        Test.stopTest();

        Assert.areEqual('Finished', [SELECT Status FROM Case WHERE Id = :c.Id].Status);
    }

    @IsTest
    static void testSetStatusesUpdatesMultipleCases() {
        List<Case> cases = new List<Case>{
            new Case(DMT_Passport_Sanction__c = 'approval'),
            new Case(DMT_Passport_Sanction__c = 'approval')
        };
        insert cases;

        Test.startTest();
        DMT_CaseClosureService.setStatuses(
            new List<Id>{ cases[0].Id, cases[1].Id }, 'In Progress'
        );
        Test.stopTest();

        for (Case c : [SELECT Status FROM Case WHERE Id IN :cases]) {
            Assert.areEqual('In Progress', c.Status);
        }
    }

    @IsTest
    static void testSetStatusesNoOpOnBlankInputs() {
        // Must not throw for any of these - all are legitimate "nothing to do" calls.
        Test.startTest();
        DMT_CaseClosureService.setStatuses(null, 'Finished');
        DMT_CaseClosureService.setStatuses(new List<Id>(), 'Finished');
        DMT_CaseClosureService.setStatuses(new List<Id>{ '500000000000001AAA' }, null);
        Test.stopTest();

        Assert.isTrue(true, 'No exception should be thrown for blank inputs.');
    }
}