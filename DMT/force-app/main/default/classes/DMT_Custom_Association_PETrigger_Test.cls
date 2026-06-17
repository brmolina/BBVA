@isTest
private without sharing class DMT_Custom_Association_PETrigger_Test {

    @testSetup
    static void setupTestData() {
        DMT_Line__c testLine = DMT_Test_DataFactory.generateTestTreasuryLines();
    }

    @isTest
    static void testTriggerAfterInsert() {

        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        DMT_Line__c testLine = [SELECT Id FROM DMT_Line__c LIMIT 1];

        Test.startTest();
        Custom_Association__c assoc = DMT_Test_DataFactory.generateCustomAssociation(testLine.Id, testAccount.Id);
        Test.stopTest();

        Custom_Association__c inserted = [
            SELECT Id
            FROM Custom_Association__c 
            WHERE Id = :assoc.Id
        ];
        System.assertNotEquals(null, inserted, 'Custom Association should be inserted successfully');
    }
}