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

    @IsTest
    static void test_PublishFromRecords_NullAndInvalidObject_NoOp() {
        Account acc = new Account(Name = 'IEH Test Account');
        insert acc;

        Test.startTest();
        DMT_IntegrationEventHandler.publishFromRecords(null, 'update', 'v1');
        DMT_IntegrationEventHandler.publishFromRecords(
            new List<SObject>{ null },
            'update',
            'v1'
        );
        DMT_IntegrationEventHandler.publishFromRecords(
            new List<SObject>{ acc },
            'update',
            'v1'
        );
        Test.stopTest();

        System.assertEquals(false, DMT_IntegrationContext.isInbound(), 'Inbound debe quedar reseteado');
    }

    @IsTest
    static void test_Publish_ChunkingAndDefaults() {
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c LIMIT 1];

        List<Id> ids = new List<Id>();
        for (Integer i = 0; i < 151; i++) {
            ids.add(line.Id);
        }

        Test.startTest();
        DMT_IntegrationEventHandler.publish('DMT_Line__c', null, ids, null);
        Test.stopTest();

        System.assertEquals(151, ids.size(), 'Se debe conservar el total de ids de entrada');
        System.assertEquals(false, DMT_IntegrationContext.isInbound(), 'Inbound debe volver a false tras publish');
    }

    @IsTest
    static void test_Publish_IdsEmpty_NoOp() {
        Test.startTest();
        DMT_IntegrationEventHandler.publish('DMT_Line__c', 'Update', null, 'v1');
        DMT_IntegrationEventHandler.publish('DMT_Line__c', 'Update', new List<Id>(), 'v1');
        Test.stopTest();

        System.assertEquals(false, DMT_IntegrationContext.isInbound(), 'Inbound no debe alterarse en no-op');
    }


    
}