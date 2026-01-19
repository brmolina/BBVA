@isTest
public with sharing class DMT_TaskRelationshipRemoveTest {

    @TestSetup
    private static void makeData() {
        DMT_Approver__c approverTest = DMT_Test_DataFactory.generateApprover();
        List<DMT_Task_Type__c> taskTypes = DMT_Test_DataFactory.generateTaskTypes();
        DMT_Test_DataFactory.generateTaskApproverRelationship(approverTest, taskTypes.get(0));
        DMT_Test_DataFactory.generateTaskRelationship(taskTypes.get(1), taskTypes.get(2));
        List<DMT_Taxonomy_Values__c> taxonomyValues = DMT_Test_DataFactory.generateTaxonomies();
        DMT_Test_DataFactory.generateTaxonomyRelationship(taxonomyValues.get(0), taxonomyValues.get(1));
        DMT_Test_DataFactory.generateTaxonomyHierarchy();
    }

    @isTest
    private static void testBatch(){
        Test.startTest();
        Database.executeBatch(new DMT_TaskApproverRelationshipRemove(), 200);
        Database.executeBatch(new DMT_TaskRelationshipRemove(), 200);
        Database.executeBatch(new DMT_TaxonomyRelationshipRemove(), 200);
        Test.stopTest();

        List<DMT_Task_Approver_Relationship__c> task = [SELECT Id FROM DMT_Task_Approver_Relationship__c WHERE LastModifiedDate < LAST_N_DAYS:3];
        Assert.areEqual(task.size(), 0, 'There are no task approver relationship');
    }
}