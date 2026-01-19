@IsTest
private class DMT_Currency_Provision_PETrigger_Test {

    @testSetup
    static void setupTestData() {
        // Línea base para relacionar
        DMT_Line__c testLine = DMT_Test_DataFactory.generateTestTreasuryLines();
    }

    @isTest
    static void testTriggerAfterInsert() {
        // Setup
        DMT_Risk_Line_Term__c testRiskLineTerm = [SELECT Id FROM DMT_Risk_Line_Term__c LIMIT 1];

        Test.startTest();
        // Crea Currency Provision (la factory debería insertar y devolver el registro con Id)
        DMT_Currency_Provision__c prov = DMT_Test_DataFactory.generateCurrencyProvision(testRiskLineTerm.Id);
        Test.stopTest();

        // Verify
        DMT_Currency_Provision__c inserted = [
            SELECT Id /*, line_id__c */ 
            FROM DMT_Currency_Provision__c 
            WHERE Id = :prov.Id
        ];
        System.assertNotEquals(null, inserted, 'Currency Provision should be inserted successfully');
        // System.assertEquals(testLine.Id, inserted.line_id__c, 'Line ID should match'); // <- Ajusta el campo si aplica
    }
}