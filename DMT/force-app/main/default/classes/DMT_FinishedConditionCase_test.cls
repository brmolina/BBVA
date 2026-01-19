@isTest
public with sharing class DMT_FinishedConditionCase_test {
    @TestSetup
    static void loadTestData() {
      // GIVEN
      DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
      DMT_Test_DataFactory.generateTaskTypes();
      DMT_Test_DataFactory.generateApprover();
      Opportunity oppty = DMT_Test_DataFactory.generateOpportunity();
      DMT_Test_DataFactory.generateCase(line.Id, oppty.Id, UserInfo.getUserId());
    }

    @isTest
    private static void checkFinishConditionsTest()
    {
        List<Case> lines = [SELECT Id, DMT_Line__c, DMT_ConditionsCloseCase__c FROM Case];

        Test.startTest();

        List<List<Case>> cases =  DMT_FinishedConditionCase.checkFinishConditions(new List<List<Case>>{lines});
        Test.stopTest();

        System.assert(cases.size() > 0, 'It should return a list of lists');
    }

}