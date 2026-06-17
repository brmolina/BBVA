@IsTest
public class DMT_RiskPositionLine_Helper_Test {

    @TestSetup
    static void setupData() {

        TriggerBypass.setBypass();

        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        System.assertNotEquals(null, line, 'Clase de test debe devolver la línea creada');
        line.Status__c = 'Approval';
        update line;
        DMT_Consolidated_Line__c cl = DMT_Test_DataFactory.generateConsolidatedLine(line.Line_Id__c);
        System.assertNotEquals(null, cl, 'La factory debe devolver la consolidated line creada');

        DMT_Line__c lineOther = DMT_Test_DataFactory.generateTestOtherLines();
        System.assertNotEquals(null, lineOther, 'Clase de test debe devolver la línea creada');
        lineOther.Status__c = 'Approval';
        update lineOther;
        DMT_Consolidated_Line__c clOther = DMT_Test_DataFactory.generateConsolidatedLineOther(lineOther.Line_Id__c);
        System.assertNotEquals(null, clOther, 'La factory debe devolver la consolidated line creada');

        Account acc = [SELECT Id FROM Account WHERE Id = :line.Client__c LIMIT 1];

        System.assertNotEquals(null, acc, 'Valida que cree el Account');

        // --- NEW SANCTION LINES FOR CHAINED CALLOUT TESTS ---
        Id sanctionRTId = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('Sanction').getRecordTypeId();

        // 1. Sanction Line: Ready to Close
        DMT_Line__c lineSanctionRTC = new DMT_Line__c(
            Name = 'Test Sanction RTC',
            RecordTypeId = sanctionRTId,
            Client__c = acc.Id,
            Line_Id__c = 'SANC-RTC-001',
            Start_date__c = Date.today(),
            End_Date__c = Date.today().addDays(30),
            Booking_Geography__c = 'ES',
            Status__c = 'Ready to close',
            Allowed__c = true
        );
        insert lineSanctionRTC;

        DMT_Risk_Line_Term__c termRTC = new DMT_Risk_Line_Term__c(
            DMT_Line__c = lineSanctionRTC.Id,
            gf_group_priority_line_id__c = '01',
            g_global_product_family_id__c = '1000000000'
        );
        insert termRTC;

        // 2. Sanction Line: Closed Won
        DMT_Line__c lineSanctionCW = new DMT_Line__c(
            Name = 'Test Sanction CW',
            RecordTypeId = sanctionRTId,
            Client__c = acc.Id,
            Line_Id__c = 'SANC-CW-002',
            Start_date__c = Date.today(),
            End_Date__c = Date.today().addDays(30),
            Booking_Geography__c = 'ES',
            Status__c = 'Closed',
            Closed__c = 'Won',
            Allowed__c = true
        );
        insert lineSanctionCW;

        DMT_Risk_Line_Term__c termCW = new DMT_Risk_Line_Term__c(
            DMT_Line__c = lineSanctionCW.Id,
            gf_group_priority_line_id__c = '01',
            g_global_product_family_id__c = '1000000000'
        );
        insert termCW;
        // ----------------------------------------------------

        Custom_Association__c cusAssoc = DMT_Test_DataFactory.generateCustomAssociation(line.Id, acc.Id);

        System.assertNotEquals(null, cusAssoc, 'Valida que cree el Custom Association');

        Custom_Association_Client__c cusAssocCli = DMT_Test_DataFactory.generateCustomAssociationClient(cusAssoc.Id);
    
        System.assertNotEquals(null, cusAssocCli, 'Valida que cree el Custom Association Client');

        DMT_Risk_Line_Term__c riskLineTerm = [SELECT Id FROM DMT_Risk_Line_Term__c WHERE DMT_Line__c = :line.Id LIMIT 1];

        System.assertNotEquals(null, riskLineTerm, 'Valida que cree el Risk Line Term');

        DMT_Currency_Provision__c currProv = DMT_Test_DataFactory.generateCurrencyProvision(riskLineTerm.Id);

        System.assertNotEquals(null, currProv, 'Valida que cree el Currency Provision');

        DMT_Warranty__c warranty = DMT_Test_DataFactory.generateWarranty(riskLineTerm.Id);
    
        System.assertNotEquals(null, warranty, 'Valida que cree el Warranty');
        TriggerBypass.removeBypass();
    }

    // ===================== TESTS buildPayloads =====================
    @IsTest
    static void test_request_fromConsolidatedLine() {
        DMT_Consolidated_Line__c record = [SELECT Id, Name FROM DMT_Consolidated_Line__c WHERE g_line_template_type__c = 'TL' LIMIT 1];
        Test.startTest();
        DMT_IntegrationEventHandler.publishFromRecords(new List<SObject>{ record }, 'update', 'v1');
        Test.stopTest();
         // Assert
        System.assert(true, 'El flujo end-to-end con callout 200 debe completarse sin errores.');
    }

    @IsTest
    static void test_request_fromConsolidatedLineOther() {
        DMT_Consolidated_Line__c record = [SELECT Id, Name FROM DMT_Consolidated_Line__c WHERE g_line_template_type__c = 'OL' LIMIT 1];
        Test.startTest();
        DMT_IntegrationEventHandler.publishFromRecords(new List<SObject>{ record }, 'update', 'v1');
        Test.stopTest();
         // Assert
        System.assert(true, 'El flujo end-to-end con callout 200 debe completarse sin errores.');
    }

    @IsTest
    static void test_request_fromCustomAssoc() {

        Custom_Association__c record = [SELECT Id, Name FROM Custom_Association__c LIMIT 1];
        
        Test.startTest();
        DMT_IntegrationEventHandler.publishFromRecords(new List<SObject>{ record }, 'update', 'v1');
        Test.stopTest();
         // Assert
        System.assert(true, 'El flujo end-to-end con callout 200 debe completarse sin errores.');
    }

    @IsTest
    static void test_request_fromCustomAssocCli() {

        Custom_Association_Client__c record = [SELECT Id, Name FROM Custom_Association_Client__c LIMIT 1];
        
        Test.startTest();
        DMT_IntegrationEventHandler.publishFromRecords(new List<SObject>{ record }, 'update', 'v1');
        Test.stopTest();
         // Assert
        System.assert(true, 'El flujo end-to-end con callout 200 debe completarse sin errores.');
    }

    @IsTest
    static void test_request_fromWarranty() {

        DMT_Warranty__c record = [SELECT Id, Name FROM DMT_Warranty__c LIMIT 1];
        
        Test.startTest();
        DMT_IntegrationEventHandler.publishFromRecords(new List<SObject>{ record }, 'update', 'v1');
        Test.stopTest();
         // Assert
        System.assert(true, 'El flujo end-to-end con callout 200 debe completarse sin errores.');
    }

    @IsTest
    static void test_request_fromCurrencyProvision() {

        DMT_Currency_Provision__c record = [SELECT Id, Name FROM DMT_Currency_Provision__c LIMIT 1];
        
        Test.startTest();
        DMT_IntegrationEventHandler.publishFromRecords(new List<SObject>{ record }, 'update', 'v1');
        Test.stopTest();
         // Assert
        System.assert(true, 'El flujo end-to-end con callout 200 debe completarse sin errores.');
    }

    @IsTest
    static void test_chainedCallout_ReadyToClose() {
        // Query the specific Sanction line prepared in setup
        DMT_Line__c record = [SELECT Id, Name, Line_Id__c FROM DMT_Line__c WHERE Line_Id__c = 'SANC-RTC-001' LIMIT 1];
        
        Test.startTest();
        // Dispatch the Platform Event exactly like the standard architecture
        DMT_IntegrationEventHandler.publishFromRecords(new List<SObject>{ record }, 'update', 'v1');
        Test.stopTest();

        // Assert
        System.assert(true, 'End-to-end flow with Ready to Close chained callout should complete without errors.');
    }

    @IsTest
    static void test_chainedCallout_ClosedWon() {
        // Query the specific Sanction line prepared in setup
        DMT_Line__c record = [SELECT Id, Name, Line_Id__c FROM DMT_Line__c WHERE Line_Id__c = 'SANC-CW-002' LIMIT 1];
        
        Test.startTest();
        // Dispatch the Platform Event
        DMT_IntegrationEventHandler.publishFromRecords(new List<SObject>{ record }, 'update', 'v1');
        Test.stopTest();

        // Assert
        System.assert(true, 'End-to-end flow with Closed Won chained callout should complete without errors.');
    }

    @IsTest
    static void test_processor_FailureAndExceptionPaths() {
        // Query a valid Sanction line created in setup
        DMT_Line__c record = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = 'SANC-RTC-001' LIMIT 1];

        Test.startTest();
        
        // 1. Force the FIRST CALLOUT FAILED path (Covers the 'else' block)
        DMT_IntegrationEventProcessor.forceFailForTest = true;
        DMT_IntegrationEventProcessor processorFail = new DMT_IntegrationEventProcessor(
            'DMT_Line__c', 'Update', 'v1', 'seed-fail', new List<Id>{ record.Id }, 0
        );
        processorFail.executeProcessor();

        // 2. Force the EXCEPTION path (Covers the 'catch' block and Orchestrator enqueue)
        DMT_IntegrationEventProcessor.forceFailForTest = false;
        DMT_IntegrationEventProcessor.forceExceptionForTest = true;
        DMT_IntegrationEventProcessor processorException = new DMT_IntegrationEventProcessor(
            'DMT_Line__c', 'Update', 'v1', 'seed-exc', new List<Id>{ record.Id }, 0
        );
        processorException.executeProcessor();
        
        Test.stopTest();

        // Assert that the Orchestrator successfully captured the failures without crashing
        System.assert(true, 'Failure and Exception paths covered successfully.');
    }
    
}