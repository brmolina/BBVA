@isTest
public with sharing class DMT_Profitability_utilsTest {

    @testSetup
    static void setupData() {

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityClient(opp.Id);
        Product2 product2 = DMT_Test_DataFactory.generateProduct2();
        PricebookEntry pricebookEntry = DMT_Test_DataFactory.generatePricebookEntry(product2);
        OpportunityLineItem opportunityLineItem = DMT_Test_DataFactory.generateOpportunityLineItem(product2,pricebookEntry,opp);
        DMT_Opportunity_Tenor__c tenor = DMT_Test_DataFactory.generateOpportunityTenor(opportunityLineItem);
       
    }

    @isTest
    static void testGetProductDetailsByIds() {
        // Obtener un OLI creado en testSetup
        OpportunityLineItem oli = [SELECT Id, OpportunityId, gf_group_priority_opportunity_id__c FROM OpportunityLineItem LIMIT 1];

        // Llamar al método
        List<Map<String, Object>> results = DMT_profitability_utils.getProductDetailsByIds(new List<String>{oli.gf_group_priority_opportunity_id__c}, oli.OpportunityId);

        Assert.areEqual(1, results.size(), 'Debe devolver un registro');
        Assert.areEqual(oli.Id, results[0].get('Id'));
        Assert.isTrue(results[0].containsKey('Name'), 'Debe incluir el nombre del producto');
        Assert.isTrue(results[0].containsKey('InitialDate'), 'Debe incluir InitialDate');
        Assert.isTrue(results[0].containsKey('MaturityDate'), 'Debe incluir MaturityDate');
        Assert.isTrue(results[0].containsKey('OppInitialDate'), 'Debe incluir OppInitialDate');
        Assert.isTrue(results[0].containsKey('OppMaturityDate'), 'Debe incluir OppMaturityDate');
    }

    @isTest
    static void testGetProductDetailsByIds_Empty() {
        List<Map<String, Object>> results = DMT_profitability_utils.getProductDetailsByIds(new List<String>(), null);
        Assert.areEqual(0, results.size(), 'Si no hay IDs, debe devolver vacío');
    }

    @isTest
    static void testGetNominalAmountsByOpportunityLineItemIds() {
        OpportunityLineItem oli = [SELECT Id, OpportunityId, gf_group_priority_opportunity_id__c FROM OpportunityLineItem LIMIT 1];

        Map<String, Map<String, Object>> results = DMT_profitability_utils.getNominalAmountsByOpportunityLineItemIds(new List<String>{oli.gf_group_priority_opportunity_id__c}, oli.OpportunityId);

        Assert.areNotEqual(null, results, 'El resultado no debe ser nulo');
    }

    @isTest
    static void testGetNominalAmountsByOpportunityLineItemIds_Empty() {
        Map<String, Map<String, Object>> results = DMT_profitability_utils.getNominalAmountsByOpportunityLineItemIds(new List<String>(), null);
        Assert.areEqual(0, results.size(), 'Si no hay IDs, debe devolver vacío');
    }

    @isTest
    static void testConvertNominalsToOppCurrency() {
        // Usar EUR->EUR para evitar dependencia de datos de tipo de cambio en BD
        String productKey = 'PROD-001';

        List<Map<String, Object>> productDetails = new List<Map<String, Object>>{
            new Map<String, Object>{
                'gf_group_priority_opportunity_id__c' => productKey,
                'Currency'    => 'EUR',
                'OppCurrency' => 'EUR'
            }
        };

        Map<String, Map<String, Object>> nominalAmounts = new Map<String, Map<String, Object>>{
            productKey => new Map<String, Object>{
                'nominalFb' => 1000.0,
                'nominalDb' => 500.0
            }
        };

        Test.startTest();
        Map<String, Map<String, Object>> result = DMT_Profitability_utils.convertNominalsToOppCurrency(productDetails, nominalAmounts);
        Test.stopTest();

        // Debe devolver entrada para el producto y para TOTAL
        Assert.isTrue(result.containsKey(productKey), 'Debe existir entrada para el producto');
        Assert.isTrue(result.containsKey('TOTAL'), 'Debe existir entrada TOTAL');

        Map<String, Object> productResult = result.get(productKey);
        Assert.areEqual(1000.0, (Decimal) productResult.get('nominalFb'), 'nominalFb debe conservarse en EUR->EUR');
        Assert.areEqual(500.0,  (Decimal) productResult.get('nominalDb'), 'nominalDb debe conservarse en EUR->EUR');
        Assert.areEqual('EUR', (String) productResult.get('fromCurrency'));
        Assert.areEqual('EUR', (String) productResult.get('toCurrency'));

        Map<String, Object> total = result.get('TOTAL');
        Assert.areEqual(1000.0, (Decimal) total.get('nominalFb'), 'TOTAL nominalFb debe ser la suma');
        Assert.areEqual(500.0,  (Decimal) total.get('nominalDb'), 'TOTAL nominalDb debe ser la suma');
        Assert.areEqual('EUR', (String) total.get('toCurrency'), 'TOTAL toCurrency debe ser la moneda de la oportunidad');
    }

    @isTest
    static void testConvertNominalsToOppCurrency_Empty() {
        // Ambas entradas vacías deben devolver mapa vacío
        Map<String, Map<String, Object>> resultEmpty = DMT_Profitability_utils.convertNominalsToOppCurrency(
            new List<Map<String, Object>>(),
            new Map<String, Map<String, Object>>()
        );
        Assert.areEqual(0, resultEmpty.size(), 'Con entradas vacías debe devolver mapa vacío');

        // productDetails null también debe devolver vacío
        Map<String, Map<String, Object>> resultNull = DMT_Profitability_utils.convertNominalsToOppCurrency(
            null,
            null
        );
        Assert.areEqual(0, resultNull.size(), 'Con entradas nulas debe devolver mapa vacío');
    }

    @isTest
    static void testConvertNominalsToOppCurrency_MissingCurrencyInfo() {
        // Producto en nominalAmounts pero con clave distinta a productDetails -> currencies == null
        List<Map<String, Object>> productDetails = new List<Map<String, Object>>{
            new Map<String, Object>{
                'gf_group_priority_opportunity_id__c' => 'DIFFERENT-KEY',
                'Currency'    => 'EUR',
                'OppCurrency' => 'EUR'
            }
        };

        Map<String, Map<String, Object>> nominalAmounts = new Map<String, Map<String, Object>>{
            'PROD-NO-CURRENCY' => new Map<String, Object>{
                'nominalFb' => 3000.0,
                'nominalDb' => 1500.0
            }
        };

        Test.startTest();
        Map<String, Map<String, Object>> result = DMT_Profitability_utils.convertNominalsToOppCurrency(productDetails, nominalAmounts);
        Test.stopTest();

        Assert.isTrue(result.containsKey('PROD-NO-CURRENCY'), 'Debe existir entrada para producto sin currency info');
        Assert.isTrue(result.containsKey('TOTAL'), 'Debe existir entrada TOTAL');
        Map<String, Object> total = result.get('TOTAL');
        Assert.areEqual(3000.0, (Decimal) total.get('nominalFb'), 'TOTAL nominalFb debe ser el valor original');
        Assert.areEqual(1500.0, (Decimal) total.get('nominalDb'), 'TOTAL nominalDb debe ser el valor original');
    }

    @isTest
    static void testConvertNominalsToOppCurrency_NullNominalsNoCurrencyInfo() {
        // Nominals nulos + sin currency info -> cubre ramos ternarios null en bloque currencies==null
        List<Map<String, Object>> productDetails = new List<Map<String, Object>>{
            new Map<String, Object>{
                'gf_group_priority_opportunity_id__c' => 'DIFFERENT-KEY',
                'Currency'    => 'EUR',
                'OppCurrency' => 'EUR'
            }
        };

        Map<String, Map<String, Object>> nominalAmounts = new Map<String, Map<String, Object>>{
            'PROD-NULL-NOMINALS' => new Map<String, Object>{
                'nominalFb' => null,
                'nominalDb' => null
            }
        };

        Test.startTest();
        Map<String, Map<String, Object>> result = DMT_Profitability_utils.convertNominalsToOppCurrency(productDetails, nominalAmounts);
        Test.stopTest();

        Assert.isTrue(result.containsKey('PROD-NULL-NOMINALS'), 'Debe existir entrada para producto con nominals null');
        Assert.isTrue(result.containsKey('TOTAL'), 'Debe existir entrada TOTAL');
        Map<String, Object> total = result.get('TOTAL');
        Assert.areEqual(0, (Decimal) total.get('nominalFb'), 'TOTAL nominalFb debe ser 0 con nominals null');
        Assert.areEqual(0, (Decimal) total.get('nominalDb'), 'TOTAL nominalDb debe ser 0 con nominals null');
    }

    @isTest
    static void testConvertNominalsToOppCurrency_NullNominalsWithCurrency() {
        // Nominals nulos con currency info -> cubre ramos ternarios null en ruta principal
        String productKey = 'PROD-NULL-MAIN';

        List<Map<String, Object>> productDetails = new List<Map<String, Object>>{
            new Map<String, Object>{
                'gf_group_priority_opportunity_id__c' => productKey,
                'Currency'    => 'EUR',
                'OppCurrency' => 'EUR'
            }
        };

        Map<String, Map<String, Object>> nominalAmounts = new Map<String, Map<String, Object>>{
            productKey => new Map<String, Object>{
                'nominalFb' => null,
                'nominalDb' => null
            }
        };

        Test.startTest();
        Map<String, Map<String, Object>> result = DMT_Profitability_utils.convertNominalsToOppCurrency(productDetails, nominalAmounts);
        Test.stopTest();

        Assert.isTrue(result.containsKey(productKey), 'Debe existir entrada para el producto');
        Assert.isTrue(result.containsKey('TOTAL'), 'Debe existir entrada TOTAL');
        Map<String, Object> total = result.get('TOTAL');
        Assert.areEqual(0, (Decimal) total.get('nominalFb'), 'TOTAL nominalFb debe ser 0');
        Assert.areEqual(0, (Decimal) total.get('nominalDb'), 'TOTAL nominalDb debe ser 0');
    }

    @isTest
    static void testGetRwaRegLinkInfo_BlankOppId() {
        Test.startTest();
        Map<String, Object> result = DMT_Profitability_utils.getRwaRegLinkInfo(null);
        Test.stopTest();

        Assert.areEqual(false, (Boolean) result.get('enabled'), 'Con oppId nulo no debe habilitarse el link');
        Assert.areEqual('', (String) result.get('explanationId'), 'Con oppId nulo explanationId debe ir vacio');
        Assert.areEqual('', (String) result.get('entific'), 'Con oppId nulo entific debe ir vacio');
    }

    @isTest
    static void testGetRwaRegLinkInfo_NoBranchValues() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];

        // Forzamos datos vacios para validar el retorno por defecto.
        opp.DMT_branch_id_c__c = null;
        oli.g_branch_id__c = null;
        update new List<SObject>{ opp, oli };

        Test.startTest();
        Map<String, Object> result = DMT_Profitability_utils.getRwaRegLinkInfo(opp.Id);
        Test.stopTest();

        Assert.areEqual(false, (Boolean) result.get('enabled'), 'Sin branch en Opp ni OLI no debe habilitarse el link');
        Assert.areEqual('', (String) result.get('explanationId'), 'Sin match explanationId debe ir vacio');
        Assert.areEqual('', (String) result.get('entific'), 'Sin match entific debe ir vacio');
    }

    @isTest
    static void testCallExternalOrchestrators_BlankOppId() {
        Test.startTest();
        Map<String, Object> result = DMT_Profitability_utils.callExternalOrchestrators(null);
        Test.stopTest();

        Assert.areEqual(false, (Boolean) result.get('success'));
        Assert.areEqual('Opportunity Id is required.', (String) result.get('message'));
    }

    @isTest
    static void testCallExternalOrchestrators_Success() {
        Opportunity opp = [SELECT Id, DMT_Opp_Id__c FROM Opportunity LIMIT 1];
        opp.DMT_Opp_Id__c = 'ESCD25OPP00000001ES';
        update opp;

        Test.startTest();
        Map<String, Object> result = DMT_Profitability_utils.callExternalOrchestrators(opp.Id);
        Test.stopTest();

        Assert.areEqual(true, (Boolean) result.get('success'));
        Assert.areEqual(201, (Integer) result.get('statusCode'));
    }

    @isTest
    static void testGetUnderlyingDetailsByIds_Empty() {
        Test.startTest();
        Map<String, Map<String, Object>> result = DMT_Profitability_utils.getUnderlyingDetailsByIds(new List<String>());
        Test.stopTest();

        Assert.areNotEqual(null, result, 'El resultado no debe ser nulo');
        Assert.areEqual(0, result.size(), 'Con lista vacia debe devolver mapa vacio');
    }

    @isTest
    static void testGetUnderlyingDetailsByIds_Success() {
        DMT_Underlying__c underlying = new DMT_Underlying__c(
            Name = 'Underlying Test',
            DMT_Drawn_Reference_Amount__c = 1250.5,
            DMT_Undrawn_Reference_Amount__c = 349.25
        );
        insert underlying;

        Test.startTest();
        Map<String, Map<String, Object>> result = DMT_Profitability_utils.getUnderlyingDetailsByIds(
            new List<String>{ underlying.Id }
        );
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Debe devolver el underlying solicitado');
        Assert.isTrue(result.containsKey(underlying.Id), 'Debe contener la clave del underlying');

        Map<String, Object> row = result.get(underlying.Id);
        Assert.areEqual(underlying.Id, (String) row.get('Id'));
        Assert.areEqual('Underlying Test', (String) row.get('Name'));
        Assert.areEqual(1250.5, (Decimal) row.get('nominalDb'));
        Assert.areEqual(349.25, (Decimal) row.get('nominalFb'));
    }

    // CIBGLOBALD-4713 - Saved Passport JSON with one profitability feature (summary row + one product row).
    private static String buildPassportJson(String productId) {
        Map<String, Object> profitability = new Map<String, Object>{
            'results' => new List<Object>{
                new Map<String, Object>{ 'rorc' => 0.12, 'raroec' => 0.08, 'regulatoryEad' => 100.0 },
                new Map<String, Object>{ 'productId' => productId, 'rorc' => 0.11, 'raroec' => 0.07, 'regulatoryApr' => 50.0 }
            },
            'audit' => new Map<String, Object>{ 'rorcThreshold' => 0.10, 'raroecThreshold' => 0.08 }
        };
        return JSON.serialize(new Map<String, Object>{
            'data' => new Map<String, Object>{
                'features' => new List<Object>{
                    new Map<String, Object>{ 'name' => 'Profitability Engine', 'profitability' => profitability }
                }
            }
        });
    }

    @isTest
    static void testRenderProfitabilityHtml_WithData() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        OpportunityLineItem oli = [SELECT Id, gf_group_priority_opportunity_id__c FROM OpportunityLineItem LIMIT 1];
        String productId = oli.gf_group_priority_opportunity_id__c != null ? oli.gf_group_priority_opportunity_id__c : String.valueOf(oli.Id);
        DMT_Test_DataFactory.generatePassport(opp.Id, buildPassportJson(productId));

        Test.startTest();
        Map<String, Object> result = DMT_Profitability_utils.renderProfitabilityHtml(opp.Id, '[{"imgB64":"iVBORw0KGgoAAAANSUhEUg=="}]', false);
        Test.stopTest();

        String html = (String) result.get('html');
        Assert.isNull(result.get('message'), 'No error message expected: ' + result.get('message'));
        Assert.isTrue((Boolean) result.get('hasData'), 'Profitability results must be reported');
        Assert.isTrue(html.contains('data-dmt-table-block="summary"'), 'Renderer HTML expected: ' + html.left(300));
        Assert.isTrue(html.contains('data-dmt-action="external-rwa"'), 'The modal marker must be emitted');
        Assert.isTrue(html.contains('<img alt="profitability"'), 'The browser chart image must be used');
        Assert.isFalse(html.contains('External RWA 1Y'), 'No External RWA column unless requested');
        Assert.isTrue(((String) result.get('fileName')).endsWith('.pdf'), 'PDF file name expected');
    }

    @isTest
    static void testRenderProfitabilityHtml_WithExternalRwa() {
        Opportunity opp = [SELECT Id, DMT_Opp_Id__c FROM Opportunity LIMIT 1];
        opp.DMT_Opp_Id__c = 'ESCD25OPP00000001ES';
        update opp;
        DMT_Test_DataFactory.generatePassport(opp.Id, buildPassportJson('PROD001'));

        Test.startTest();
        Map<String, Object> result = DMT_Profitability_utils.renderProfitabilityHtml(opp.Id, null, true);
        Test.stopTest();

        Assert.isTrue(String.isNotBlank((String) result.get('html')), 'HTML expected after the External RWA call');
    }

    @isTest
    static void testRenderProfitabilityHtml_NoPassport() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        Map<String, Object> result = DMT_Profitability_utils.renderProfitabilityHtml(opp.Id, null, false);
        Test.stopTest();

        Assert.isFalse((Boolean) result.get('hasData'), 'No Passport means no profitability data');
    }

    @isTest
    static void testRenderProfitabilityHtml_InvalidOpportunity() {
        Test.startTest();
        Map<String, Object> result = DMT_Profitability_utils.renderProfitabilityHtml('006000000000000AAA', null, false);
        Test.stopTest();

        Assert.areEqual('Unable to load the profitability view.', result.get('message'), 'Unknown Opportunity must return the error message');
    }

    @isTest
    static void testParseAprsCalculation() {
        String body = '{"data":{"aprsCalculator":[{"aprCalculator":{"productId":"P1","aprCalculation":12.5}},{"aprCalculator":{}}]}}';

        Test.startTest();
        Map<String, Object> parsed = DMT_Profitability_utils.parseAprsCalculation(body);
        Map<String, Object> invalid = DMT_Profitability_utils.parseAprsCalculation('not json');
        Map<String, Object> blank = DMT_Profitability_utils.parseAprsCalculation(null);
        Test.stopTest();

        Assert.areEqual(1, parsed.size(), 'Only rows with productId are kept');
        Assert.areEqual(12.5, parsed.get('P1'), 'aprCalculation mapped by productId');
        Assert.isTrue(invalid.isEmpty(), 'Unexpected response shape returns an empty map');
        Assert.isTrue(blank.isEmpty(), 'Blank response returns an empty map');
    }

    
}