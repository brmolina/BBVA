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
}