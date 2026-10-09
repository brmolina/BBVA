@IsTest
private class DMT_PassportProfitabilityProcessorTest {

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
    static void testUpdateProfitabilityFieldsPersistsOpportunityAndProductValues() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        
        // Actualiza el field de matching para la deduplicación
        oli.gf_group_priority_opportunity_id__c = '01';
        update oli;

        String jsonPassport = '{' +
            '"data": {' +
                '"features": [' +
                    '{' +
                        '"name": "Profitability Engine",' +
                        '"profitability": {' +
                            '"results": [' +
                                '{' +
                                    '"allInDb": 11.111111,' +
                                    '"allInFb": 22.222222,' +
                                    '"economicEad": 1000.12,' +
                                    '"regulatoryEad": 2000.23,' +
                                    '"regulatoryCapital": 3000.34,' +
                                    '"economicCapital": 4000.45,' +
                                    '"franchiseDeal": 5000.56,' +
                                    '"bdiEco": 6000.67,' +
                                    '"bdiReg": 7000.78,' +
                                    '"rorc": 0.1111,' +
                                    '"raroec": 0.2222,' +
                                    '"economicApr": 8000.89,' +
                                    '"regulatoryApr": 9000.91,' +
                                    '"rorcProspected": 0.3333,' +
                                    '"clientRorc": 0.4444' +
                                '},' +
                                '{' +
                                    '"productId": "01",' +
                                    '"isLine": false,' +
                                    '"allInDb": 1.111111,' +
                                    '"allInFb": 1.222222,' +
                                    '"economicEad": 100.12,' +
                                    '"regulatoryEad": 200.23,' +
                                    '"regulatoryCapital": 300.34,' +
                                    '"economicCapital": 400.45,' +
                                    '"franchiseDeal": 500.56,' +
                                    '"bdiEco": 600.67,' +
                                    '"bdiReg": 700.78,' +
                                    '"rorc": 0.0101,' +
                                    '"raroec": 0.0202,' +
                                    '"economicApr": 800.89,' +
                                    '"regulatoryApr": 900.91,' +
                                    '"rorcProspected": 0.0303' +
                                '},' +
                                '{' +
                                    '"productId": "01",' +
                                    '"isLine": true,' +
                                    '"allInDb": 2.111111,' +
                                    '"allInFb": 2.222222,' +
                                    '"economicEad": 2100.12,' +
                                    '"regulatoryEad": 2200.23,' +
                                    '"regulatoryCapital": 2300.34,' +
                                    '"economicCapital": 2400.45,' +
                                    '"franchiseDeal": 2500.56,' +
                                    '"bdiEco": 2600.67,' +
                                    '"bdiReg": 2700.78,' +
                                    '"rorc": 0.1212,' +
                                    '"raroec": 0.1313,' +
                                    '"economicApr": 2800.89,' +
                                    '"regulatoryApr": 2900.91,' +
                                    '"rorcProspected": 0.1414' +
                                '}' +
                            ']' +
                        '}' +
                    '}' +
                ']' +
            '}' +
        '}';

        // Elimina Passports previos para evitar duplicación
        delete [SELECT Id FROM Passport__c WHERE Opportunity__c = :opp.Id];

        Passport__c passport = new Passport__c(
            Opportunity__c = opp.Id,
            DMT_Passport_Save__c = jsonPassport
        );
        insert passport;

        // Verifica que el Passport se insertó correctamente
        Passport__c savedPassport = [SELECT Id, DMT_Passport_Save__c FROM Passport__c WHERE Id = :passport.Id];
        System.assert(savedPassport.DMT_Passport_Save__c != null, 'JSON no se guardó en Passport');

        Test.startTest();
        DMT_PassportProfitabilityProcessor.updateProfitabilityFields(opp.Id, savedPassport.DMT_Passport_Save__c);
        Test.stopTest();

        Opportunity refreshedOpp = [
            SELECT DMT_Allin_Drawn__c, DMT_Allin_Undrawn__c, DMT_EAD_Eco__c,
                   DMT_EAD_Reg__c, DMT_Regulatory_Capital__c, DMT_Economic_Capital__c,
                   DMT_Franchise_Deal__c, DMT_Net_Income_Eco__c, DMT_Net_Income_Reg__c,
                   DMT_RORC__c, DMT_RAROEC__c, DMT_RWA_eco__c, DMT_RWA_reg__c,
                   DMT_RORC_CDD__c, DMT_Global_Expected_RORC__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        OpportunityLineItem refreshedOli = [
            SELECT DMT_Allin_Drawn__c, DMT_Allin_Undrawn__c, DMT_EAD_Eco__c,
                   DMT_EAD_Reg__c, DMT_Regulatory_Capital__c, DMT_Economic_Capital__c,
                   DMT_Franchise_Deal__c, DMT_Net_Income_Eco__c, DMT_Net_Income_Reg__c,
                   DMT_RORC__c, DMT_RAROEC__c, DMT_RWA_Eco__c, DMT_RWA_Reg__c,
                   DMT_RORC_CDD__c
            FROM OpportunityLineItem
            WHERE Id = :oli.Id
        ];

        // Verify Opportunity aggregate-level fields (all 15 fields)
        System.assertEquals(11.111111, refreshedOpp.DMT_Allin_Drawn__c, 'Opp: Allin Drawn from aggregate');
        System.assertEquals(22.222222, refreshedOpp.DMT_Allin_Undrawn__c, 'Opp: Allin Undrawn from aggregate');
        System.assertEquals(1000.12, refreshedOpp.DMT_EAD_Eco__c, 'Opp: EAD Eco from aggregate');
        System.assertEquals(2000.23, refreshedOpp.DMT_EAD_Reg__c, 'Opp: EAD Reg from aggregate');
        System.assertEquals(3000.34, refreshedOpp.DMT_Regulatory_Capital__c, 'Opp: Regulatory Capital from aggregate');
        System.assertEquals(4000.45, refreshedOpp.DMT_Economic_Capital__c, 'Opp: Economic Capital from aggregate');
        System.assertEquals(5000.56, refreshedOpp.DMT_Franchise_Deal__c, 'Opp: Franchise Deal from aggregate');
        System.assertEquals(6000.67, refreshedOpp.DMT_Net_Income_Eco__c, 'Opp: Net Income Eco from aggregate');
        System.assertEquals(7000.78, refreshedOpp.DMT_Net_Income_Reg__c, 'Opp: Net Income Reg from aggregate');
        System.assertEquals(0.1111, refreshedOpp.DMT_RORC__c, 'Opp: RORC from aggregate');
        System.assertEquals(0.2222, refreshedOpp.DMT_RAROEC__c, 'Opp: RAROEC from aggregate');
        System.assertEquals(8000.89, refreshedOpp.DMT_RWA_eco__c, 'Opp: RWA eco from aggregate');
        System.assertEquals(9000.91, refreshedOpp.DMT_RWA_reg__c, 'Opp: RWA reg from aggregate');
        System.assertEquals(0.3333, refreshedOpp.DMT_RORC_CDD__c, 'Opp: RORC CDD from aggregate');
        System.assertEquals(0.4444, refreshedOpp.DMT_Global_Expected_RORC__c, 'Opp: Global Expected RORC (Opp-only)');

        // Verify OpportunityLineItem product-level fields (14 shared fields, no clientRorc)
        // Should use isLine=true result (second productId "01" record) due to deduplication
        System.assertEquals(2.111111, refreshedOli.DMT_Allin_Drawn__c, 'OLI: Allin Drawn from isLine=true product (prioritized over isLine=false)');
        System.assertEquals(2.222222, refreshedOli.DMT_Allin_Undrawn__c, 'OLI: Allin Undrawn from isLine=true product');
        System.assertEquals(2100.12, refreshedOli.DMT_EAD_Eco__c, 'OLI: EAD Eco from isLine=true product');
        System.assertEquals(2200.23, refreshedOli.DMT_EAD_Reg__c, 'OLI: EAD Reg from isLine=true product');
        System.assertEquals(2300.34, refreshedOli.DMT_Regulatory_Capital__c, 'OLI: Regulatory Capital from isLine=true product');
        System.assertEquals(2400.45, refreshedOli.DMT_Economic_Capital__c, 'OLI: Economic Capital from isLine=true product');
        System.assertEquals(2500.56, refreshedOli.DMT_Franchise_Deal__c, 'OLI: Franchise Deal from isLine=true product');
        System.assertEquals(2600.67, refreshedOli.DMT_Net_Income_Eco__c, 'OLI: Net Income Eco from isLine=true product');
        System.assertEquals(2700.78, refreshedOli.DMT_Net_Income_Reg__c, 'OLI: Net Income Reg from isLine=true product');
        System.assertEquals(0.1212, refreshedOli.DMT_RORC__c, 'OLI: RORC from isLine=true product');
        System.assertEquals(0.1313, refreshedOli.DMT_RAROEC__c, 'OLI: RAROEC from isLine=true product');
        System.assertEquals(2800.89, refreshedOli.DMT_RWA_Eco__c, 'OLI: RWA Eco from isLine=true product');
        System.assertEquals(2900.91, refreshedOli.DMT_RWA_Reg__c, 'OLI: RWA Reg from isLine=true product');
        System.assertEquals(0.1414, refreshedOli.DMT_RORC_CDD__c, 'OLI: RORC CDD from isLine=true product');
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