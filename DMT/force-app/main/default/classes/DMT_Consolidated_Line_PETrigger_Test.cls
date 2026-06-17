@isTest
private without sharing class DMT_Consolidated_Line_PETrigger_Test {

    @testSetup
    static void setupTestData() {

        Account testAccount = new Account(
            Name = 'Test Account for Trigger Test',
            account_client__c = 'N',
            BBVA_Entity__c = 'BBVA SA',
            BillingCountry = 'ES',
            CurrencyIsoCode = 'EUR'
        );

        insert testAccount;
        
        DMT_Line__c testLine = new DMT_Line__c(
            Name = 'Test Line for Trigger',
            Status__c = 'Draft',
            Client__c = testAccount.Id,
            Line_Id__c = 'TEST001',
            Booking_Geography__c = 'ES',
            DMT_Client_Entific__c = 'ES',
            CurrencyIsoCode = 'EUR'
        );

        insert testLine;
    }

   @isTest
    static void testTriggerAfterInsert() {
       DMT_Line__c testLine = [SELECT Id FROM DMT_Line__c LIMIT 1];
        
        Test.startTest();
        
        DMT_Consolidated_Line__c newConsolidatedLine = new DMT_Consolidated_Line__c();
        newConsolidatedLine.line_id__c = testLine.Id;
        newConsolidatedLine.gf_group_line_id__c = 'TEST_GROUP_001';
        newConsolidatedLine.gf_group_priority_line_id__c = '01';
        newConsolidatedLine.g_entific_id__c = 'ES';
        
        insert newConsolidatedLine;
            
        Test.stopTest();
            
        // Verify successful insertion
         DMT_Consolidated_Line__c insertedRecord = [
            SELECT Id, line_id__c, gf_group_line_id__c 
            FROM DMT_Consolidated_Line__c 
            WHERE Id = :newConsolidatedLine.Id
        ];
            
        System.assertNotEquals(null, insertedRecord, 'Record should be inserted');
        System.assertEquals(testLine.Id, insertedRecord.line_id__c, 'Line ID should match');
    }
    
}