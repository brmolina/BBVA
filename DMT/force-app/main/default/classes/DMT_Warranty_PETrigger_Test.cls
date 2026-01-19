@IsTest
private class DMT_Warranty_PETrigger_Test {

    @testSetup
    static void setupTestData() {
        DMT_Line__c testLine = DMT_Test_DataFactory.generateTestTreasuryLines();
    }

    @isTest
    static void testTriggerAfterInsert() {
        // Setup
        DMT_Risk_Line_Term__c testRiskLineTerm = [SELECT Id FROM DMT_Risk_Line_Term__c LIMIT 1];

        Test.startTest();
        DMT_Warranty__c warranty = DMT_Test_DataFactory.generateWarranty(testRiskLineTerm.Id);
        Test.stopTest();

        DMT_Warranty__c inserted = [
            SELECT Id
            FROM DMT_Warranty__c 
            WHERE Id = :warranty.Id
        ];
        
        System.assertNotEquals(null, inserted, 'Warranty should be inserted successfully');
    }
}