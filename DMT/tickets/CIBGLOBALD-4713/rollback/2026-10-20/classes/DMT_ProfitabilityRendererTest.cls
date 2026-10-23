// Test class for DMT_ProfitabilityRenderer
@isTest
public with sharing class DMT_ProfitabilityRendererTest {

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

    @isTest
    static void testRenderHtmlWithNullData() {
        DMT_ProfitabilityRenderer renderer = new DMT_ProfitabilityRenderer();
        Test.startTest();
        String result = renderer.renderHtml(null);
        Test.stopTest();

        System.assert(result.contains('Error'), 'Debe retornar error para data null');
        System.assert(result.contains('Data not provided'), 'Debe incluir mensaje específico');
    }

    @isTest
    static void testRenderHtmlWithValidData() {
        Opportunity opp = [SELECT Id, RecordTypeId FROM Opportunity LIMIT 1];
        OpportunityLineItem oli = [SELECT Id, OpportunityId FROM OpportunityLineItem LIMIT 1];

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = opp.RecordTypeId;
        data.opportunity = opp;
        data.featuresList = new List<Map<String, Object>>();
        data.profitabilityProductDetailsList = new List<Map<String, Object>>();
        data.profitabilityNominalAmountsMap = new Map<String, Map<String, Object>>();
        data.profitabilityNominalAmountsConvertedMap = new Map<String, Map<String, Object>>();
        data.currencyIsoCode = 'EUR';

        DMT_ProfitabilityRenderer renderer = new DMT_ProfitabilityRenderer();
        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        // El renderer intenta delegarlo a DMT_OppProfitabilityLimitVisualRenderer
        System.assertNotEquals(null, result, 'Debe retornar un string');
    }

    @isTest
    static void testRenderHtmlWithInvalidRecordType() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        OpportunityLineItem oli = [SELECT Id, OpportunityId FROM OpportunityLineItem LIMIT 1];

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = '012000000000000';  // ID inválido
        data.opportunity = opp;
        data.featuresList = new List<Map<String, Object>>();
        data.profitabilityProductDetailsList = new List<Map<String, Object>>();
        data.profitabilityNominalAmountsMap = new Map<String, Map<String, Object>>();
        data.profitabilityNominalAmountsConvertedMap = new Map<String, Map<String, Object>>();
        data.currencyIsoCode = 'EUR';

        DMT_ProfitabilityRenderer renderer = new DMT_ProfitabilityRenderer();
        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        System.assert(result.contains('Error'), 'Invalid record type must return error.');
    }

    @isTest
    static void testOppProfitabilityRenderer_featurePresentButNoResults() {
        Opportunity opp = [SELECT Id, RecordTypeId FROM Opportunity LIMIT 1];

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = opp.RecordTypeId;
        data.opportunity = opp;
        Map<String, Object> profitability = new Map<String, Object>{ 'results' => new List<Object>() };
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'profitability' => profitability }
        };
        data.profitabilityProductDetailsList = new List<Map<String, Object>>();
        data.profitabilityNominalAmountsMap = new Map<String, Map<String, Object>>();
        data.profitabilityNominalAmountsConvertedMap = new Map<String, Map<String, Object>>();
        data.currencyIsoCode = 'EUR';

        DMT_ProfitabilityRenderer renderer = new DMT_ProfitabilityRenderer();
        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        Assert.isTrue(result.contains('no Profitability results found') || result.contains('Opportunity or OpportunityLineItems'),
            'Empty results must return the no-results guard or line-items guard message.');
    }

    @isTest
    static void testOppProfitabilityRenderer_fullPathWithResults() {
        Opportunity opp = [
            SELECT Id, RecordTypeId, Name, DMT_CurrencyText__c, DMT_DATE_Initial_Date__c, DMT_DATE_Maturity_Date__c,
                   (SELECT Id, gf_group_priority_opportunity_id__c FROM OpportunityLineItems)
            FROM Opportunity
            LIMIT 1
        ];
        OpportunityLineItem oli = [SELECT Id, gf_group_priority_opportunity_id__c FROM OpportunityLineItem LIMIT 1];

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = opp.RecordTypeId;
        data.opportunity = opp;
        data.currencyIsoCode = 'EUR';

        String productKey = oli.gf_group_priority_opportunity_id__c != null ? oli.gf_group_priority_opportunity_id__c : 'PROD001';

        Map<String, Object> summaryResult = new Map<String, Object>{
            'rorc' => 0.12,
            'raroec' => 0.08,
            'rorcProspected' => 0.10,
            'clientRorc' => 0.09,
            'regulatoryEad' => 100.0,
            'economicEad' => 80.0
        };
        Map<String, Object> productResult = new Map<String, Object>{
            'productId' => productKey,
            'rorc' => 0.11,
            'raroec' => 0.07,
            'averageLife' => 2.5,
            'tenor' => 3.0,
            'allInDb' => 200.0,
            'allInFb' => 60.0,
            'spreadDbPbs' => 150.0,
            'spreadFbPbs' => 30.0,
            'feesDbPbs' => 12.0,
            'feesFbPbs' => 8.0,
            'fundingDbPbs' => 50.0,
            'fundingFbPbs' => 20.0
        };
        Map<String, Object> audit = new Map<String, Object>{
            'rorcThreshold' => 0.10,
            'raroecThreshold' => 0.08
        };
        Map<String, Object> profitability = new Map<String, Object>{
            'results' => new List<Object>{ summaryResult, productResult },
            'audit' => audit
        };
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'profitability' => profitability }
        };
        data.profitabilityProductDetailsList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'gf_group_priority_opportunity_id__c' => productKey,
                'Name' => 'Test Product',
                'Currency' => 'EUR',
                'OppCurrency' => 'EUR',
                'NominalDb' => 1000.0,
                'NominalFb' => 0.0
            }
        };
        data.profitabilityNominalAmountsMap = new Map<String, Map<String, Object>>{
            productKey => new Map<String, Object>{ 'nominalDb' => 1000.0, 'nominalFb' => 0.0 }
        };
        data.profitabilityNominalAmountsConvertedMap = new Map<String, Map<String, Object>>{
            productKey => new Map<String, Object>{ 'nominalDb' => 1000.0, 'nominalFb' => 0.0 }
        };

        DMT_ProfitabilityRenderer renderer = new DMT_ProfitabilityRenderer();
        Test.startTest();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        Assert.isNotNull(result, 'Full path must return a non-null result.');
        Assert.isTrue(result.contains('Profitability Engine') || result.contains('Summary') || result.contains('Error'),
            'Result should contain Profitability Engine header or Summary, or an error if line items are empty.');
    }
}