@IsTest
private class DMT_DraftStatusServiceTest {

    @IsTest
    static void testMoveToDraftUpdatesLineAndOpportunity() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();

        Test.startTest();
        DMT_DraftStatusService.moveToDraft(
            new List<Id>{ line.Id }, new List<Id>{ opp.Id }
        );
        Test.stopTest();

        DMT_Line__c lineAfter = [SELECT Status__c, Allowed__c FROM DMT_Line__c WHERE Id = :line.Id];
        Opportunity oppAfter = [SELECT StageName, DMT_Cancel__c FROM Opportunity WHERE Id = :opp.Id];

        Assert.areEqual('Draft', lineAfter.Status__c, 'Line must move to Draft.');
        Assert.isTrue(lineAfter.Allowed__c, 'The two-phase toggle must end with Allowed__c true, matching the IP\'s CancelValue=false then true sequence.');
        Assert.areEqual('Draft', oppAfter.StageName, 'Opportunity must move to Draft.');
        Assert.isTrue(oppAfter.DMT_Cancel__c, 'The two-phase toggle must end with DMT_Cancel__c true.');
    }

    @IsTest
    static void testSingleRecordOverload() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();

        Test.startTest();
        DMT_DraftStatusService.moveToDraft(line.Id, null);
        Test.stopTest();

        Assert.areEqual('Draft', [SELECT Status__c FROM DMT_Line__c WHERE Id = :line.Id].Status__c);
    }

    @IsTest
    static void testNoOpOnBlankInputs() {
        Test.startTest();
        DMT_DraftStatusService.moveToDraft((Id) null, (Id) null);
        DMT_DraftStatusService.moveToDraft(new List<Id>(), new List<Id>());
        DMT_DraftStatusService.moveToDraft((List<Id>) null, (List<Id>) null);
        Test.stopTest();

        Assert.isTrue(true, 'No exception should be thrown for blank inputs.');
    }
}