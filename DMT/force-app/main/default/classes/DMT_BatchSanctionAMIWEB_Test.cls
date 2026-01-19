@isTest
public with sharing class DMT_BatchSanctionAMIWEB_Test {

    @TestSetup
    static void setupTestData() {
        DMT_Test_DataFactory.generateTestSanctionLines();
    }

    @isTest
    static void testBatchExecution() {
    
        DMT_BatchSanctionAMIWEB batch = new DMT_BatchSanctionAMIWEB();

        Test.startTest();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        List<DMT_Line__c> updatedLines = [SELECT Status__c, Closed__c, g_line_status_type__c, DMT_line_status_type__c FROM DMT_Line__c WHERE DMT_Origin__c = 'AMIWEB'];

        for (DMT_Line__c line : updatedLines) {
            System.assertEquals(line.g_line_status_type__c, line.DMT_line_status_type__c, 'Status formula should be the same to informed value');
        }
    }

    @isTest
    static void testFinishMethod() {
        // Ejecutar el batch y verificar el método finish
        DMT_BatchSanctionAMIWEB batch = new DMT_BatchSanctionAMIWEB();

        Test.startTest();
        Id jobId = Database.executeBatch(batch, 200);
        Test.stopTest();

        // Verificar el envío del email
        AsyncApexJob job = [SELECT Status, NumberOfErrors, JobItemsProcessed, TotalJobItems FROM AsyncApexJob WHERE Id = :jobId];
        
        System.assertNotEquals(null, job, 'The AsyncApexJob task should exist.');
        System.assertEquals('Completed', job.Status, 'The job status should be Completed.');
        System.assertEquals(0, job.NumberOfErrors, 'There should be no errors in the batch.');
    }

}