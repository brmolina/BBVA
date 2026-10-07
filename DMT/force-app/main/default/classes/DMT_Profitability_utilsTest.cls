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

        System.assertEquals(1, results.size(), 'Debe devolver un registro');
        System.assertEquals(oli.Id, results[0].get('Id'));
        System.assert(results[0].containsKey('Name'), 'Debe incluir el nombre del producto');
        System.assert(results[0].containsKey('InitialDate'), 'Debe incluir InitialDate');
        System.assert(results[0].containsKey('MaturityDate'), 'Debe incluir MaturityDate');
        System.assert(results[0].containsKey('OppInitialDate'), 'Debe incluir OppInitialDate');
        System.assert(results[0].containsKey('OppMaturityDate'), 'Debe incluir OppMaturityDate');
    }

    @isTest
    static void testGetProductDetailsByIds_Empty() {
        List<Map<String, Object>> results = DMT_profitability_utils.getProductDetailsByIds(new List<String>(), null);
        System.assertEquals(0, results.size(), 'Si no hay IDs, debe devolver vacío');
    }

    @isTest
    static void testGetNominalAmountsByOpportunityLineItemIds() {
        OpportunityLineItem oli = [SELECT Id, OpportunityId, gf_group_priority_opportunity_id__c FROM OpportunityLineItem LIMIT 1];

        Map<String, Map<String, Object>> results = DMT_profitability_utils.getNominalAmountsByOpportunityLineItemIds(new List<String>{oli.gf_group_priority_opportunity_id__c}, oli.OpportunityId);

        System.assertNotEquals(null, results, 'El resultado no debe ser nulo');
    }

    @isTest
    static void testGetNominalAmountsByOpportunityLineItemIds_Empty() {
        Map<String, Map<String, Object>> results = DMT_profitability_utils.getNominalAmountsByOpportunityLineItemIds(new List<String>(), null);
        System.assertEquals(0, results.size(), 'Si no hay IDs, debe devolver vacío');
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
        System.assert(result.containsKey(productKey), 'Debe existir entrada para el producto');
        System.assert(result.containsKey('TOTAL'), 'Debe existir entrada TOTAL');

        Map<String, Object> productResult = result.get(productKey);
        System.assertEquals(1000.0, (Decimal) productResult.get('nominalFb'), 'nominalFb debe conservarse en EUR->EUR');
        System.assertEquals(500.0,  (Decimal) productResult.get('nominalDb'), 'nominalDb debe conservarse en EUR->EUR');
        System.assertEquals('EUR', (String) productResult.get('fromCurrency'));
        System.assertEquals('EUR', (String) productResult.get('toCurrency'));

        Map<String, Object> total = result.get('TOTAL');
        System.assertEquals(1000.0, (Decimal) total.get('nominalFb'), 'TOTAL nominalFb debe ser la suma');
        System.assertEquals(500.0,  (Decimal) total.get('nominalDb'), 'TOTAL nominalDb debe ser la suma');
        System.assertEquals('EUR', (String) total.get('toCurrency'), 'TOTAL toCurrency debe ser la moneda de la oportunidad');
    }

    @isTest
    static void testConvertNominalsToOppCurrency_Empty() {
        // Ambas entradas vacías deben devolver mapa vacío
        Map<String, Map<String, Object>> resultEmpty = DMT_Profitability_utils.convertNominalsToOppCurrency(
            new List<Map<String, Object>>(),
            new Map<String, Map<String, Object>>()
        );
        System.assertEquals(0, resultEmpty.size(), 'Con entradas vacías debe devolver mapa vacío');

        // productDetails null también debe devolver vacío
        Map<String, Map<String, Object>> resultNull = DMT_Profitability_utils.convertNominalsToOppCurrency(
            null,
            null
        );
        System.assertEquals(0, resultNull.size(), 'Con entradas nulas debe devolver mapa vacío');
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

        System.assert(result.containsKey('PROD-NO-CURRENCY'), 'Debe existir entrada para producto sin currency info');
        System.assert(result.containsKey('TOTAL'), 'Debe existir entrada TOTAL');
        Map<String, Object> total = result.get('TOTAL');
        System.assertEquals(3000.0, (Decimal) total.get('nominalFb'), 'TOTAL nominalFb debe ser el valor original');
        System.assertEquals(1500.0, (Decimal) total.get('nominalDb'), 'TOTAL nominalDb debe ser el valor original');
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

        System.assert(result.containsKey('PROD-NULL-NOMINALS'), 'Debe existir entrada para producto con nominals null');
        System.assert(result.containsKey('TOTAL'), 'Debe existir entrada TOTAL');
        Map<String, Object> total = result.get('TOTAL');
        System.assertEquals(0, (Decimal) total.get('nominalFb'), 'TOTAL nominalFb debe ser 0 con nominals null');
        System.assertEquals(0, (Decimal) total.get('nominalDb'), 'TOTAL nominalDb debe ser 0 con nominals null');
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

        System.assert(result.containsKey(productKey), 'Debe existir entrada para el producto');
        System.assert(result.containsKey('TOTAL'), 'Debe existir entrada TOTAL');
        Map<String, Object> total = result.get('TOTAL');
        System.assertEquals(0, (Decimal) total.get('nominalFb'), 'TOTAL nominalFb debe ser 0');
        System.assertEquals(0, (Decimal) total.get('nominalDb'), 'TOTAL nominalDb debe ser 0');
    }

    @isTest
    static void testGetRwaRegLinkInfo_BlankOppId() {
        Test.startTest();
        Map<String, Object> result = DMT_Profitability_utils.getRwaRegLinkInfo(null);
        Test.stopTest();

        System.assertEquals(false, (Boolean) result.get('enabled'), 'Con oppId nulo no debe habilitarse el link');
        System.assertEquals('', (String) result.get('explanationId'), 'Con oppId nulo explanationId debe ir vacio');
        System.assertEquals('', (String) result.get('entific'), 'Con oppId nulo entific debe ir vacio');
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

        System.assertEquals(false, (Boolean) result.get('enabled'), 'Sin branch en Opp ni OLI no debe habilitarse el link');
        System.assertEquals('', (String) result.get('explanationId'), 'Sin match explanationId debe ir vacio');
        System.assertEquals('', (String) result.get('entific'), 'Sin match entific debe ir vacio');
    }

    @isTest
    static void testCallExternalOrchestrators_BlankOppId() {
        Test.startTest();
        Map<String, Object> result = DMT_Profitability_utils.callExternalOrchestrators(null);
        Test.stopTest();

        System.assertEquals(false, (Boolean) result.get('success'));
        System.assertEquals('Opportunity Id is required.', (String) result.get('message'));
    }

    @isTest
    static void testCallExternalOrchestrators_Success() {
        Opportunity opp = [SELECT Id, DMT_Opp_Id__c FROM Opportunity LIMIT 1];
        opp.DMT_Opp_Id__c = 'ESCD25OPP00000001ES';
        update opp;

        Test.startTest();
        Map<String, Object> result = DMT_Profitability_utils.callExternalOrchestrators(opp.Id);
        Test.stopTest();

        System.assertEquals(true, (Boolean) result.get('success'));
        System.assertEquals(201, (Integer) result.get('statusCode'));
    }

    @isTest
    static void testGetUnderlyingDetailsByIds_Empty() {
        Test.startTest();
        Map<String, Map<String, Object>> result = DMT_Profitability_utils.getUnderlyingDetailsByIds(new List<String>());
        Test.stopTest();

        System.assertNotEquals(null, result, 'El resultado no debe ser nulo');
        System.assertEquals(0, result.size(), 'Con lista vacia debe devolver mapa vacio');
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

        System.assertEquals(1, result.size(), 'Debe devolver el underlying solicitado');
        System.assert(result.containsKey(underlying.Id), 'Debe contener la clave del underlying');

        Map<String, Object> row = result.get(underlying.Id);
        System.assertEquals(underlying.Id, (String) row.get('Id'));
        System.assertEquals('Underlying Test', (String) row.get('Name'));
        System.assertEquals(1250.5, (Decimal) row.get('nominalDb'));
        System.assertEquals(349.25, (Decimal) row.get('nominalFb'));
    }

    
}