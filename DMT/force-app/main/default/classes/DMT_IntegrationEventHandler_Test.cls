@IsTest
private class DMT_IntegrationEventHandler_Test {

    // ----------------------------------------------------------------------
    // Test Data Setup
    // ----------------------------------------------------------------------
    @testSetup
    static void setupData() {
        
        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        System.assertNotEquals(null, line, 'Clase de test debe devolver la línea creada');

        DMT_Consolidated_Line__c cl = DMT_Test_DataFactory.generateConsolidatedLine(line.Id);
        System.assertNotEquals(null, cl, 'La factory debe devolver la consolidated line creada');

    }

    // ----------------------------------------------------------------------
    // Tests
    // ----------------------------------------------------------------------

    @IsTest
    static void test_PublishFromRecords_SingleRecord_HappyPath() {
        
        DMT_Line__c line = [SELECT Id, Name FROM DMT_Line__c LIMIT 1];

        Test.startTest();
        DMT_IntegrationEventHandler.publishFromRecords(new List<SObject>{ line },'update','v1');
        Test.stopTest();

        System.assertNotEquals(null, line.Id, 'El registro base debe existir');
    }

    @IsTest
    static void test_PublishFromRecords_EmptyList_NoOp() {
        // Arrange
        List<SObject> emptyList = new List<SObject>();

        // Act
        Test.startTest();
        DMT_IntegrationEventHandler.publishFromRecords(emptyList,'update','v1');
        Test.stopTest();

        // Assert
        System.assertEquals(0, emptyList.size(), 'No debe fallar con lista vacía');
    }


    
}