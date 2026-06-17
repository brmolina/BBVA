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
    static void testRenderPdfJsonWithNullData() {
        DMT_ProfitabilityRenderer renderer = new DMT_ProfitabilityRenderer();
        Test.startTest();
        Map<String, Object> result = renderer.renderPdfJson(null);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Debe retornar mapa vacío para data null');
    }

    @isTest
    static void testRenderPdfJsonWithValidData() {
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
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Debe retornar un mapa');
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

        System.assert(result.contains('Error'), 'Debe retornar error para record type inválido');
    }

    @isTest
    static void testRenderPdfJsonWithInvalidRecordType() {
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
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Debe retornar mapa vacío para record type inválido');
    }
}