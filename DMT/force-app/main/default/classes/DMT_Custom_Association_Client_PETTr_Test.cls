@IsTest
private class DMT_Custom_Association_Client_PETTr_Test {

    @testSetup
    static void setupTestData() {
        DMT_Line__c testLine = DMT_Test_DataFactory.generateTestTreasuryLines();
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Custom_Association__c testCA = DMT_Test_DataFactory.generateCustomAssociation(testLine.Id, testAccount.Id);
    }

    @isTest
    static void testTriggerAfterInsert() {

        Custom_Association__c testCA = [SELECT Id FROM Custom_Association__c LIMIT 1];

        Test.startTest();
        Custom_Association_Client__c assocClient = DMT_Test_DataFactory.generateCustomAssociationClient(testCA.Id);
        Test.stopTest();

        Custom_Association_Client__c inserted = [
            SELECT Id
            FROM Custom_Association_Client__c 
            WHERE Id = :assocClient.Id
        ];
        System.assertNotEquals(null, inserted, 'Custom Association Client should be inserted successfully');
    }
}