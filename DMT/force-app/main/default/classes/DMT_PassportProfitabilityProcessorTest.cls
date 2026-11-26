@IsTest
private class DMT_PassportProfitabilityProcessorTest {
    private static final DMT_UtilTestClass DMT_UTIL = new DMT_UtilTestClass();
    private static final DES_UtilTestClass DES_UTIL = new DES_UtilTestClass();

    @testSetup
    static void setupData() {
        // Opportunity mínima válida
        Opportunity opp = DMT_UTIL.createOpportunityForAccount(null);
        Product2 product = DES_UTIL.createProductRecord();
        PricebookEntry pricebookEntry = DMT_UTIL.createPricebookEntryRecord(product.Id);
        OpportunityLineItem opl = DES_UTIL.buildOppLineItem(opp.Id, product.Id, pricebookEntry.Id);

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
        insert opl;

        Passport__c passport = DMT_UTIL.createPassportRecord(
            new Map<Schema.SObjectField, Object>{
                Passport__c.Opportunity__c => opp.Id,
                Passport__c.DMT_Passport_Save__c => jsonPassport
            }
        );
        // CIBGLOBALD-4851 - Enhancement fix to existing process: DMT_PassportProfitabilityProcessor reads the newest passport
        // of the opportunity; other automation can create one in the same second, so this one is made the newest.
        Test.setCreatedDate(passport.Id, System.now().addMinutes(1));
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

        Assert.areEqual(1, results.size(), 'Debe devolver un resultado');

        DMT_PassportProfitabilityProcessor.ProfitabilityResult res = results[0];
        Assert.areEqual(true, res.success, 'Debe ser success=true');
        Assert.areEqual(opp.Id, res.opportunityId, 'Debe devolver el Id de la oportunidad');
        Assert.areNotEqual(null, res.passportId, 'Debe devolver el Id del passport');
        Assert.areEqual(true, res.isOpportunityLevel, 'Debe indicar nivel oportunidad');
        Assert.areEqual(12.345678, res.raroec, 'Debe mapear raroec correctamente');
        Assert.areEqual(8.765432, res.rorc, 'Debe mapear rorc correctamente');
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

        Assert.areEqual(1, results.size(), 'Debe devolver un resultado');

        DMT_PassportProfitabilityProcessor.ProfitabilityResult res = results[0];
        Assert.areEqual(true, res.success, 'Debe ser success=true');
        Assert.areEqual(false, res.isOpportunityLevel, 'Debe indicar nivel producto');
        Assert.areEqual(
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

        Passport__c passport = DMT_UTIL.createPassportRecord(
            new Map<Schema.SObjectField, Object>{
                Passport__c.Opportunity__c => opp.Id,
                Passport__c.DMT_Passport_Save__c => jsonPassport
            }
        );

        // Verifica que el Passport se insertó correctamente
        Passport__c savedPassport = [SELECT Id, DMT_Passport_Save__c FROM Passport__c WHERE Id = :passport.Id];
        Assert.isTrue(savedPassport.DMT_Passport_Save__c != null, 'JSON no se guardó en Passport');

        Test.startTest();
        DMT_PassportProfitabilityProcessor.updateProfitabilityFields(opp.Id, savedPassport.DMT_Passport_Save__c);
        Test.stopTest();

        List<DMT_Profitability_results__c> results = [
            SELECT DMT_Opportunity__c, DMT_OpportunityLineItem__c,
                   DMT_Allin_Drawn__c, DMT_Allin_Undrawn__c, DMT_EAD_Eco__c, DMT_EAD_Reg__c,
                   DMT_Regulatory_Capital__c, DMT_Economic_Capital__c, DMT_Franchise_Deal__c,
                   DMT_Net_Income_Eco__c, DMT_Net_Income_Reg__c, DMT_RORC__c, DMT_RAROEC__c,
                   DMT_RWA_Eco__c, DMT_RWA_Reg__c, DMT_RORC_CDD__c, DMT_Global_Expected_RORC__c
            FROM DMT_Profitability_results__c
            WHERE DMT_Opportunity__c = :opp.Id
        ];

        Assert.areEqual(2, results.size(), 'Debe crear 2 registros: Opportunity + Product');

        DMT_Profitability_results__c oppLevelResult;
        DMT_Profitability_results__c productLevelResult;

        for (DMT_Profitability_results__c record : results) {
            if (record.DMT_OpportunityLineItem__c == null) {
                oppLevelResult = record;
            } else {
                productLevelResult = record;
            }
        }

        Assert.areNotEqual(null, oppLevelResult, 'Debe existir registro a nivel Opportunity');
        Assert.areNotEqual(null, productLevelResult, 'Debe existir registro a nivel Product');

        // Opportunity level
        Assert.areEqual(opp.Id, oppLevelResult.DMT_Opportunity__c);
        Assert.areEqual(null, oppLevelResult.DMT_OpportunityLineItem__c);
        Assert.areEqual(11.111111, oppLevelResult.DMT_Allin_Drawn__c);
        Assert.areEqual(22.222222, oppLevelResult.DMT_Allin_Undrawn__c);
        Assert.areEqual(1000.12, oppLevelResult.DMT_EAD_Eco__c);
        Assert.areEqual(2000.23, oppLevelResult.DMT_EAD_Reg__c);
        Assert.areEqual(3000.34, oppLevelResult.DMT_Regulatory_Capital__c);
        Assert.areEqual(4000.45, oppLevelResult.DMT_Economic_Capital__c);
        Assert.areEqual(5000.56, oppLevelResult.DMT_Franchise_Deal__c);
        Assert.areEqual(6000.67, oppLevelResult.DMT_Net_Income_Eco__c);
        Assert.areEqual(7000.78, oppLevelResult.DMT_Net_Income_Reg__c);
        Assert.areEqual(11.11, oppLevelResult.DMT_RORC__c);
        Assert.areEqual(22.22, oppLevelResult.DMT_RAROEC__c);
        Assert.areEqual(8000.89, oppLevelResult.DMT_RWA_Eco__c);
        Assert.areEqual(9000.91, oppLevelResult.DMT_RWA_Reg__c);
        Assert.areEqual(33.33, oppLevelResult.DMT_RORC_CDD__c);
        Assert.areEqual(44.44, oppLevelResult.DMT_Global_Expected_RORC__c);

        // Product level (must use isLine=true record)
        Assert.areEqual(opp.Id, productLevelResult.DMT_Opportunity__c);
        Assert.areEqual(oli.Id, productLevelResult.DMT_OpportunityLineItem__c);
        Assert.areEqual(2.111111, productLevelResult.DMT_Allin_Drawn__c);
        Assert.areEqual(2.222222, productLevelResult.DMT_Allin_Undrawn__c);
        Assert.areEqual(2100.12, productLevelResult.DMT_EAD_Eco__c);
        Assert.areEqual(2200.23, productLevelResult.DMT_EAD_Reg__c);
        Assert.areEqual(2300.34, productLevelResult.DMT_Regulatory_Capital__c);
        Assert.areEqual(2400.45, productLevelResult.DMT_Economic_Capital__c);
        Assert.areEqual(2500.56, productLevelResult.DMT_Franchise_Deal__c);
        Assert.areEqual(2600.67, productLevelResult.DMT_Net_Income_Eco__c);
        Assert.areEqual(2700.78, productLevelResult.DMT_Net_Income_Reg__c);
        Assert.areEqual(12.12, productLevelResult.DMT_RORC__c);
        Assert.areEqual(13.13, productLevelResult.DMT_RAROEC__c);
        Assert.areEqual(2800.89, productLevelResult.DMT_RWA_Eco__c);
        Assert.areEqual(2900.91, productLevelResult.DMT_RWA_Reg__c);
        Assert.areEqual(14.14, productLevelResult.DMT_RORC_CDD__c);
        Assert.areEqual(null, productLevelResult.DMT_Global_Expected_RORC__c);
    }

    @IsTest
    static void testGetProductLevelProfitability() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<DMT_PassportProfitabilityProcessor.ProductProfitability> productos =
            DMT_PassportProfitabilityProcessor.getProductLevelProfitability(opp.Id);
        Test.stopTest();

        Assert.areEqual(2, productos.size(), 'Debe devolver 2 productos');

        Assert.areEqual('PROD_001', productos[0].productId);
        Assert.areEqual(20.123456, productos[0].raroec);
        Assert.areEqual(10.654321, productos[0].rorc);

        Assert.areEqual('PROD_002', productos[1].productId);
        Assert.areEqual(15.5, productos[1].raroec);
        Assert.areEqual(7.25, productos[1].rorc);
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

        Assert.areEqual(1, results.size(), 'Debe devolver un resultado aunque falle');

        DMT_PassportProfitabilityProcessor.ProfitabilityResult res = results[0];
        Assert.areEqual(false, res.success, 'Debe marcar success=false');
        Assert.isTrue(res.mensaje != null && res.mensaje.startsWith('Error:'), 'Debe informar del error');
    }
}