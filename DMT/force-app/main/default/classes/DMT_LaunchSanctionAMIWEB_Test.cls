@isTest
public class DMT_LaunchSanctionAMIWEB_Test {

    @isTest
    static void testRunSanctionBatch() {
        DMT_Test_DataFactory.generateTestSanctionLines();

        Test.startTest();
        Id batchInstanceId = DMT_LaunchSanctionAMIWEB.runSanctionBatch();
        Test.stopTest();

        List<DMT_Line__c> updatedLines = [SELECT Status__c, Closed__c, g_line_status_type__c, DMT_line_status_type__c, Client_Type__c FROM DMT_Line__c WHERE DMT_Origin__c = 'AMIWEB'];

        for (DMT_Line__c line : updatedLines) {system.debug('client type '+ line.Client_Type__c);
            System.assertEquals(line.g_line_status_type__c, line.DMT_line_status_type__c, 'Status__c field should be the same');
        }
        
        System.assertNotEquals(null, batchInstanceId, 'The runSanctionBatch method should return a batch Id');
        
        // Consultar la instancia AsyncApexJob para verificar que existe
        AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :batchInstanceId LIMIT 1];
        System.assertNotEquals(null, job, 'The AsyncApexJob instance should exist in the database.');
        System.assertEquals('Completed', job.Status, 'The batch status should be Completed.');
    }
}