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
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];

        // Llamar al método
        List<Map<String, Object>> results = DMT_profitability_utils.getProductDetailsByIds(new List<Id>{oli.Id});

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
        List<Map<String, Object>> results = DMT_profitability_utils.getProductDetailsByIds(new List<Id>());
        System.assertEquals(0, results.size(), 'Si no hay IDs, debe devolver vacío');
    }

    @isTest
    static void testGetNominalAmountsByOpportunityLineItemIds() {
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];

        Map<Id, Map<String, Object>> results = DMT_profitability_utils.getNominalAmountsByOpportunityLineItemIds(new List<Id>{oli.Id});

        System.assertEquals(true, results.containsKey(oli.Id), 'Debe contener el OLI');
    }

    @isTest
    static void testGetNominalAmountsByOpportunityLineItemIds_Empty() {
        Map<Id, Map<String, Object>> results = DMT_profitability_utils.getNominalAmountsByOpportunityLineItemIds(new List<Id>());
        System.assertEquals(0, results.size(), 'Si no hay IDs, debe devolver vacío');
    }
}