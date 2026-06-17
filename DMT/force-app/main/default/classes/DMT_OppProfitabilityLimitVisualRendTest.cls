@isTest
public with sharing class DMT_OppProfitabilityLimitVisualRendTest {

    @testSetup
    static void setupData() {
        TriggerBypass.setBypass();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityClient(opp.Id);
        Product2 product2 = DMT_Test_DataFactory.generateProduct2();
        PricebookEntry pricebookEntry = DMT_Test_DataFactory.generatePricebookEntry(product2);
        OpportunityLineItem opportunityLineItem = DMT_Test_DataFactory.generateOpportunityLineItem(product2, pricebookEntry, opp);
        DMT_Opportunity_Tenor__c tenor = DMT_Test_DataFactory.generateOpportunityTenor(opportunityLineItem);
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private static Opportunity queryOpportunityWithLineItems() {
        return [SELECT Id, Name, DMT_CurrencyText__c,
                       DMT_DATE_Initial_Date__c, DMT_DATE_Maturity_Date__c,
                       (SELECT Id FROM OpportunityLineItems)
                FROM Opportunity LIMIT 1];
    }

    private static Map<String, Object> buildFullResultMap(Object productId) {
        Map<String, Object> row = new Map<String, Object>{
            'rorc'                        => 5.0,
            'raroec'                      => 10.0,
            'rorcProspected'              => 5.5,
            'raroecProspected'            => 10.5,
            'clientRorc'                  => 6.0,
            'averageLife'                 => 3.0,
            'spreadDbPbs'                 => 120.0,
            'spreadFbPbs'                 => 60.0,
            'feesDbPbs'                   => 30.0,
            'feesFbPbs'                   => 15.0,
            'fundingDbPbs'                => 90.0,
            'fundingFbPbs'                => 45.0,
            'countryRiskProvisionDbPbs'   => 5.0,
            'countryRiskProvisionFbPbs'   => 2.0,
            'expectedLossPbs'             => 20.0,
            'feesUpFrontPbs'              => 10.0,
            'periodicFeesPbs'             => 8.0,
            'taxRate'                     => 30.0,
            'franchiseDeal'               => 2000.0,
            'bdi'                         => 1000.0,
            'regulatoryEad'               => 2000000.0,
            'regulatoryCcf'               => 50.0,
            'regulatoryLgd'               => 40.0,
            'regulatoryApr'               => 10.0,
            'regulatoryCapital'           => 160000.0,
            'economicEad'                 => 1800000.0,
            'economicCcf'                 => 45.0,
            'economicLgd'                 => 35.0,
            'economicApr'                 => 9.0,
            'economicCapital'             => 140000.0
        };
        if (productId != null) {
            row.put('productId', productId);
        }
        return row;
    }

    private static Map<String, Object> buildFeatureMap(Boolean includeProductRow) {
        List<Object> results = new List<Object>{ buildFullResultMap(null) };
        if (includeProductRow) {
            results.add(buildFullResultMap('01'));
        }
        Map<String, Object> profMap = new Map<String, Object>{
            'results' => results,
            'audit'   => new Map<String, Object>{ 'rorcThreshold' => 3.0, 'raroecThreshold' => 8.0 }
        };
        return new Map<String, Object>{ 'profitability' => profMap };
    }

    private static DMT_ViewController.LineDataWrapper buildWrapper(Opportunity opp, Boolean includeProductRow) {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.featuresList                        = new List<Map<String, Object>>{ buildFeatureMap(includeProductRow) };
        data.opportunity                         = opp;
        data.profitabilityProductDetailsList     = new List<Map<String, Object>>();
        data.profitabilityNominalAmountsMap      = new Map<String, Map<String, Object>>();
        data.profitabilityNominalAmountsConvertedMap = new Map<String, Map<String, Object>>();
        data.currencyIsoCode                     = 'EUR';
        data.itemImgBase64                       = new List<DMT_ViewController.ItemImgB64>();
        data.isImg64                             = false;
        return data;
    }

    // ── renderHtml tests ─────────────────────────────────────────────────────

    @isTest
    static void testRenderHtmlWithNullData() {
        Test.startTest();
        String result = DMT_OppProfitabilityLimitVisualRenderer.renderHtml(null);
        Test.stopTest();

        System.assert(result.contains('Features data not provided'), 'Debe retornar error para data null');
    }

    @isTest
    static void testRenderHtmlWithEmptyFeaturesList() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.featuresList = new List<Map<String, Object>>();

        Test.startTest();
        String result = DMT_OppProfitabilityLimitVisualRenderer.renderHtml(data);
        Test.stopTest();

        System.assert(result.contains('Features data not provided'), 'Debe retornar error para featuresList vacía');
    }

    @isTest
    static void testRenderHtmlOpportunityWithoutLineItems() {
        // Opportunity queried without subquery: OpportunityLineItems not populated → guard returns error
        Opportunity opp = [SELECT Id, Name, DMT_CurrencyText__c FROM Opportunity LIMIT 1];

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.featuresList = new List<Map<String, Object>>{ buildFeatureMap(false) };
        data.opportunity  = opp;

        Test.startTest();
        String result = DMT_OppProfitabilityLimitVisualRenderer.renderHtml(data);
        Test.stopTest();

        System.assert(result.contains('Opportunity or OpportunityLineItems data not provided'),
                      'Debe retornar error cuando OpportunityLineItems no está poblado');
    }

    @isTest
    static void testRenderHtmlNoProfitabilityFeature() {
        Opportunity opp = queryOpportunityWithLineItems();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'otherFeature' => 'value' }
        };
        data.opportunity = opp;

        Test.startTest();
        String result = DMT_OppProfitabilityLimitVisualRenderer.renderHtml(data);
        Test.stopTest();

        System.assert(result.contains('Profitability data not provided'),
                      'Debe retornar error cuando no existe el nodo profitability');
    }

    @isTest
    static void testRenderHtmlWithEmptyResults() {
        Opportunity opp = queryOpportunityWithLineItems();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        Map<String, Object> profMap = new Map<String, Object>{
            'results' => new List<Object>(),
            'audit'   => new Map<String, Object>{ 'rorcThreshold' => 3.0 }
        };
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'profitability' => profMap }
        };
        data.opportunity = opp;

        Test.startTest();
        String result = DMT_OppProfitabilityLimitVisualRenderer.renderHtml(data);
        Test.stopTest();

        System.assert(result.contains('no Profitability results found'),
                      'Debe retornar error para lista de resultados vacía');
    }

    @isTest
    static void testRenderHtmlWithValidData() {
        Opportunity opp = queryOpportunityWithLineItems();

        DMT_ViewController.LineDataWrapper data = buildWrapper(opp, false);

        Test.startTest();
        String result = DMT_OppProfitabilityLimitVisualRenderer.renderHtml(data);
        Test.stopTest();

        System.assertNotEquals('', result, 'Debe retornar HTML no vacío');
        System.assertNotEquals(null, result, 'Debe retornar HTML no nulo');
    }

    @isTest
    static void testRenderHtmlWithProductDetails() {
        Opportunity opp = queryOpportunityWithLineItems();

        DMT_ViewController.LineDataWrapper data = buildWrapper(opp, true);

        Map<String, Object> productDetail = new Map<String, Object>{
            'gf_group_priority_opportunity_id__c' => '01',
            'Id'           => '01',
            'Name'         => 'Test Product',
            'InitialDate'  => Date.today(),
            'MaturityDate' => Date.today().addDays(365),
            'Currency'     => 'EUR',
            'OppCurrency'  => 'EUR'
        };
        data.profitabilityProductDetailsList = new List<Map<String, Object>>{ productDetail };

        Map<String, Object> rawNominals = new Map<String, Object>{
            'nominalDb' => 1000000.0,
            'nominalFb' => 0.0
        };
        Map<String, Object> convertedNominals = new Map<String, Object>{
            'nominalDb' => 1000000.0,
            'nominalFb' => 0.0
        };
        data.profitabilityNominalAmountsMap         = new Map<String, Map<String, Object>>{ '01' => rawNominals };
        data.profitabilityNominalAmountsConvertedMap = new Map<String, Map<String, Object>>{ '01' => convertedNominals };

        Test.startTest();
        String result = DMT_OppProfitabilityLimitVisualRenderer.renderHtml(data);
        Test.stopTest();

        System.assertNotEquals('', result, 'Debe retornar HTML con detalles de producto (Db)');
    }

    @isTest
    static void testRenderHtmlWithProductDetailsFb() {
        Opportunity opp = queryOpportunityWithLineItems();

        DMT_ViewController.LineDataWrapper data = buildWrapper(opp, true);

        Map<String, Object> productDetail = new Map<String, Object>{
            'gf_group_priority_opportunity_id__c' => '01',
            'Name'         => 'Test Product FB',
            'InitialDate'  => Date.today(),
            'MaturityDate' => Date.today().addDays(365),
            'Currency'     => 'USD'
        };
        data.profitabilityProductDetailsList = new List<Map<String, Object>>{ productDetail };

        Map<String, Object> rawNominals = new Map<String, Object>{
            'nominalDb' => 0.0,
            'nominalFb' => 500000.0
        };
        Map<String, Object> convertedNominals = new Map<String, Object>{
            'nominalDb' => 0.0,
            'nominalFb' => 500000.0
        };
        data.profitabilityNominalAmountsMap         = new Map<String, Map<String, Object>>{ '01' => rawNominals };
        data.profitabilityNominalAmountsConvertedMap = new Map<String, Map<String, Object>>{ '01' => convertedNominals };

        Test.startTest();
        String result = DMT_OppProfitabilityLimitVisualRenderer.renderHtml(data);
        Test.stopTest();

        System.assertNotEquals('', result, 'Debe retornar HTML con detalles de producto (Fb)');
    }

    @isTest
    static void testRenderHtmlWithImage() {
        Opportunity opp = queryOpportunityWithLineItems();

        DMT_ViewController.LineDataWrapper data = buildWrapper(opp, false);

        DMT_ViewController.ItemImgB64 imgItem = new DMT_ViewController.ItemImgB64();
        imgItem.imgB64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
        data.itemImgBase64 = new List<DMT_ViewController.ItemImgB64>{ imgItem };
        data.isImg64 = true;

        Test.startTest();
        String result = DMT_OppProfitabilityLimitVisualRenderer.renderHtml(data);
        Test.stopTest();

        System.assertNotEquals('', result, 'Debe retornar HTML con imagen');
    }

    // ── renderPdfJson tests ───────────────────────────────────────────────────

    @isTest
    static void testRenderPdfJsonWithNullData() {
        DMT_OppProfitabilityLimitVisualRenderer renderer = new DMT_OppProfitabilityLimitVisualRenderer();

        Test.startTest();
        Map<String, Object> result = renderer.renderPdfJson(null);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Debe retornar mapa vacío para data null');
    }

    @isTest
    static void testRenderPdfJsonOpportunityWithoutLineItems() {
        Opportunity opp = [SELECT Id, Name, DMT_CurrencyText__c FROM Opportunity LIMIT 1];

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.featuresList = new List<Map<String, Object>>{ buildFeatureMap(false) };
        data.opportunity  = opp;

        DMT_OppProfitabilityLimitVisualRenderer renderer = new DMT_OppProfitabilityLimitVisualRenderer();

        Test.startTest();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Debe retornar mapa vacío para opp sin LineItems');
    }

    @isTest
    static void testRenderPdfJsonNoProfitabilityFeature() {
        Opportunity opp = queryOpportunityWithLineItems();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'otherFeature' => 'value' }
        };
        data.opportunity = opp;

        DMT_OppProfitabilityLimitVisualRenderer renderer = new DMT_OppProfitabilityLimitVisualRenderer();

        Test.startTest();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Debe retornar mapa vacío sin nodo profitability');
    }

    @isTest
    static void testRenderPdfJsonWithEmptyResults() {
        Opportunity opp = queryOpportunityWithLineItems();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        Map<String, Object> profMap = new Map<String, Object>{
            'results' => new List<Object>(),
            'audit'   => new Map<String, Object>{ 'rorcThreshold' => 3.0 }
        };
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'profitability' => profMap }
        };
        data.opportunity = opp;

        DMT_OppProfitabilityLimitVisualRenderer renderer = new DMT_OppProfitabilityLimitVisualRenderer();

        Test.startTest();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Debe retornar mapa vacío para resultados vacíos');
    }

    @isTest
    static void testRenderPdfJsonWithValidData() {
        Opportunity opp = queryOpportunityWithLineItems();

        DMT_ViewController.LineDataWrapper data = buildWrapper(opp, true);
        data.currencyIsoCode = 'USD';

        DMT_OppProfitabilityLimitVisualRenderer renderer = new DMT_OppProfitabilityLimitVisualRenderer();

        Test.startTest();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Debe retornar un mapa no nulo');
        System.assert(result.containsKey('content'), 'Debe contener la clave content');
    }

    @isTest
    static void testRenderPdfJsonWithProductDetailsAndImage() {
        Opportunity opp = queryOpportunityWithLineItems();

        DMT_ViewController.LineDataWrapper data = buildWrapper(opp, true);

        Map<String, Object> productDetail = new Map<String, Object>{
            'gf_group_priority_opportunity_id__c' => '01',
            'Id'           => '01',
            'Name'         => 'Test Product PDF',
            'InitialDate'  => Date.today(),
            'MaturityDate' => Date.today().addDays(365),
            'Currency'     => 'EUR',
            'OppCurrency'  => 'EUR'
        };
        data.profitabilityProductDetailsList = new List<Map<String, Object>>{ productDetail };

        Map<String, Object> rawNominals = new Map<String, Object>{
            'nominalDb' => 1000000.0,
            'nominalFb' => 0.0
        };
        Map<String, Object> convertedNominals = new Map<String, Object>{
            'nominalDb' => 1000000.0,
            'nominalFb' => 0.0
        };
        data.profitabilityNominalAmountsMap         = new Map<String, Map<String, Object>>{ '01' => rawNominals };
        data.profitabilityNominalAmountsConvertedMap = new Map<String, Map<String, Object>>{ '01' => convertedNominals };

        DMT_ViewController.ItemImgB64 imgItem = new DMT_ViewController.ItemImgB64();
        imgItem.imgB64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
        data.itemImgBase64 = new List<DMT_ViewController.ItemImgB64>{ imgItem };
        data.isImg64 = true;

        DMT_OppProfitabilityLimitVisualRenderer renderer = new DMT_OppProfitabilityLimitVisualRenderer();

        Test.startTest();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Debe retornar un mapa no nulo');
        System.assert(result.containsKey('content'), 'Debe contener la clave content');
    }
}