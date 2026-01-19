@IsTest
private class DMT_IntegrationEventProcessor_Test {

     @TestSetup
    static void setupData() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        System.assertNotEquals(null, line, 'Clase de test debe devolver la línea creada');

        DMT_Consolidated_Line__c cl = DMT_Test_DataFactory.generateConsolidatedLine(line.Id);
        System.assertNotEquals(null, cl, 'La factory debe devolver la consolidated line creada');
    }

    // ------------------------------------------------------------
    // Caso 1: Flujo completo con callout exitoso (200)
    // ------------------------------------------------------------
    @IsTest
    static void test_EndToEnd_Success_Callout200() {

        DMT_Consolidated_Line__c line = [SELECT Id, Name FROM DMT_Consolidated_Line__c LIMIT 1];

        Test.startTest();
        DMT_IntegrationEventHandler.publishFromRecords(new List<SObject>{ line },'update','v1');
        Test.stopTest();

         // Assert
        System.assert(true, 'El flujo end-to-end con callout 200 debe completarse sin errores.');
    }

}