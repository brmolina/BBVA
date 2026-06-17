@isTest
private without sharing class DMT_PassportProfitabilityProcessorTest {

    @testSetup
    static void setupData() {
        // Opportunity mínima válida
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        OpportunityLineItem opl = DMT_Test_DataFactory.generateOpportunityLineItem(opp);

        // JSON de prueba con nivel Opportunity y nivel Producto
        String jsonPassport = '{' +
            '"data": {' +
                '"features": [' +
                    '{' +
                        '"name": "Profitability Engine",' +
                        '"profitability": {' +
                            '"results": [' +
                                '{' +
                                    '"raroec": "12.345678",' +
                                    '"rorc": "8.765432"' +
                                '},' +
                                '{' +
                                    '"productId": "PROD_001",' +
                                    '"raroec": "20.123456",' +
                                    '"rorc": "10.654321"' +
                                '},' +
                                '{' +
                                    '"productId": "PROD_002",' +
                                    '"raroec": 15.5,' +
                                    '"rorc": 7.25' +
                                '}' +
                            ']' +
                        '}' +
                    '}' +
                ']' +
            '}' +
        '}';

        Passport__c passport = new Passport__c(
            Opportunity__c = opp.Id,
            DMT_Passport_Save__c = jsonPassport
        );
        insert passport;
    }

    @IsTest
    static void testObtenerProfitabilityOpportunityLevel() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        DMT_PassportProfitabilityProcessor.ProfitabilityRequest req =
            new DMT_PassportProfitabilityProcessor.ProfitabilityRequest();
        req.opportunityDMTId = opp.Id;
        req.isOpportunityLevel = true;

        Test.startTest();
        List<DMT_PassportProfitabilityProcessor.ProfitabilityResult> results =
            DMT_PassportProfitabilityProcessor.obtenerProfitability(
                new List<DMT_PassportProfitabilityProcessor.ProfitabilityRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Debe devolver un resultado');

        DMT_PassportProfitabilityProcessor.ProfitabilityResult res = results[0];
        System.assertEquals(true, res.success, 'Debe ser success=true');
        System.assertEquals(opp.Id, res.opportunityId, 'Debe devolver el Id de la oportunidad');
        System.assertNotEquals(null, res.passportId, 'Debe devolver el Id del passport');
        System.assertEquals(true, res.isOpportunityLevel, 'Debe indicar nivel oportunidad');
        System.assertEquals(12.345678, res.raroec, 'Debe mapear raroec correctamente');
        System.assertEquals(8.765432, res.rorc, 'Debe mapear rorc correctamente');
    }

    @IsTest
    static void testObtenerProfitabilityProductLevelMessage() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        DMT_PassportProfitabilityProcessor.ProfitabilityRequest req =
            new DMT_PassportProfitabilityProcessor.ProfitabilityRequest();
        req.opportunityDMTId = opp.Id;
        req.isOpportunityLevel = false;

        Test.startTest();
        List<DMT_PassportProfitabilityProcessor.ProfitabilityResult> results =
            DMT_PassportProfitabilityProcessor.obtenerProfitability(
                new List<DMT_PassportProfitabilityProcessor.ProfitabilityRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Debe devolver un resultado');

        DMT_PassportProfitabilityProcessor.ProfitabilityResult res = results[0];
        System.assertEquals(true, res.success, 'Debe ser success=true');
        System.assertEquals(false, res.isOpportunityLevel, 'Debe indicar nivel producto');
        System.assertEquals(
            'Usar método getProductLevelProfitability para nivel producto',
            res.mensaje,
            'Debe devolver el mensaje esperado'
        );
    }

    @IsTest
    static void testGetProductLevelProfitability() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<DMT_PassportProfitabilityProcessor.ProductProfitability> productos =
            DMT_PassportProfitabilityProcessor.getProductLevelProfitability(opp.Id);
        Test.stopTest();

        System.assertEquals(2, productos.size(), 'Debe devolver 2 productos');

        System.assertEquals('PROD_001', productos[0].productId);
        System.assertEquals(20.123456, productos[0].raroec);
        System.assertEquals(10.654321, productos[0].rorc);

        System.assertEquals('PROD_002', productos[1].productId);
        System.assertEquals(15.5, productos[1].raroec);
        System.assertEquals(7.25, productos[1].rorc);
    }

    @IsTest
    static void testObtenerProfitabilityWithInvalidOpportunity() {
        DMT_PassportProfitabilityProcessor.ProfitabilityRequest req =
            new DMT_PassportProfitabilityProcessor.ProfitabilityRequest();
        req.opportunityDMTId = '006000000000000AAA'; // Id inválido/no existente
        req.isOpportunityLevel = true;

        Test.startTest();
        List<DMT_PassportProfitabilityProcessor.ProfitabilityResult> results =
            DMT_PassportProfitabilityProcessor.obtenerProfitability(
                new List<DMT_PassportProfitabilityProcessor.ProfitabilityRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Debe devolver un resultado aunque falle');

        DMT_PassportProfitabilityProcessor.ProfitabilityResult res = results[0];
        System.assertEquals(false, res.success, 'Debe marcar success=false');
        System.assert(res.mensaje != null && res.mensaje.startsWith('Error:'), 'Debe informar del error');
    }
}