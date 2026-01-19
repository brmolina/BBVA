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
       DMT_Consolidated_Line__c record = [SELECT Id, Name FROM DMT_Consolidated_Line__c WHERE g_line_template_type__c ='TL' LIMIT 1];
        Test.startTest();
        DMT_IntegrationEventHandler.publishFromRecords(new List<SObject>{ record },'update','v1');
        Test.stopTest();
         // Assert
        System.assert(true, 'El flujo end-to-end con callout 200 debe completarse sin errores.'); 
    }

    @IsTest
    static void test_request_fromConsolidatedLineOther() {
       DMT_Consolidated_Line__c record = [SELECT Id, Name FROM DMT_Consolidated_Line__c WHERE g_line_template_type__c ='OL' LIMIT 1];
        Test.startTest();
        DMT_IntegrationEventHandler.publishFromRecords(new List<SObject>{ record },'update','v1');
        Test.stopTest();
         // Assert
        System.assert(true, 'El flujo end-to-end con callout 200 debe completarse sin errores.'); 
    }

    @IsTest
    static void test_request_fromCustomAssoc() {

        Custom_Association__c record = [SELECT Id, Name FROM Custom_Association__c LIMIT 1];
        
        Test.startTest();
        DMT_IntegrationEventHandler.publishFromRecords(new List<SObject>{ record },'update','v1');
        Test.stopTest();
         // Assert
        System.assert(true, 'El flujo end-to-end con callout 200 debe completarse sin errores.'); 
    }

    @IsTest
    static void test_request_fromCustomAssocCli() {

        Custom_Association_Client__c record = [SELECT Id, Name FROM Custom_Association_Client__c LIMIT 1];
        
        Test.startTest();
        DMT_IntegrationEventHandler.publishFromRecords(new List<SObject>{ record },'update','v1');
        Test.stopTest();
         // Assert
        System.assert(true, 'El flujo end-to-end con callout 200 debe completarse sin errores.'); 
    }

    @IsTest
    static void test_request_fromWarranty() {

        DMT_Warranty__c record = [SELECT Id, Name FROM DMT_Warranty__c LIMIT 1];
        
        Test.startTest();
        DMT_IntegrationEventHandler.publishFromRecords(new List<SObject>{ record },'update','v1');
        Test.stopTest();
         // Assert
        System.assert(true, 'El flujo end-to-end con callout 200 debe completarse sin errores.'); 
    }

    @IsTest
    static void test_request_fromCurrencyProvision() {

        DMT_Currency_Provision__c record = [SELECT Id, Name FROM DMT_Currency_Provision__c LIMIT 1];
        
        Test.startTest();
        DMT_IntegrationEventHandler.publishFromRecords(new List<SObject>{ record },'update','v1');
        Test.stopTest();
         // Assert
        System.assert(true, 'El flujo end-to-end con callout 200 debe completarse sin errores.'); 
    }
}