@isTest
private without sharing class DMT_feature_limitControllerTest {


    @TestSetup
    static void makeData() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityClient(opp.Id);
        Product2 product = DMT_Test_DataFactory.generateProduct2();
        PricebookEntry pricebookEntry = DMT_Test_DataFactory.generatePricebookEntry(product);
        OpportunityLineItem opportunityLineItem = DMT_Test_DataFactory.generateOpportunityLineItem(product, pricebookEntry, opp);
        DMT_Opportunity_Mitigant__c mitigant = DMT_Test_DataFactory.generateOpportunityMitigant(opportunityLineItem);
    }


    private static Opportunity getOpp() {
        return [SELECT Id FROM Opportunity LIMIT 1];
    }

    private static OpportunityLineItem getOLI() {
        return [SELECT Id, gf_group_priority_opportunity_id__c FROM OpportunityLineItem LIMIT 1];
    }

    private static DMT_Opportunity_Mitigant__c getMitigant() {
        return [SELECT Id FROM DMT_Opportunity_Mitigant__c LIMIT 1];
    }


    @isTest
    static void testGetMitigantsAndOppLineItems_withBothRecords() {
        Opportunity opp = getOpp();
        OpportunityLineItem oli = getOLI();
        DMT_Opportunity_Mitigant__c mit = getMitigant();

        Test.startTest();
        Map<String, Object> response = DMT_feature_limitController.getMitigantsAndOppLineItemsByField(
                opp.Id,
                new List<String>{ oli.gf_group_priority_opportunity_id__c },
                new List<String>{ mit.Id }
            );
        Test.stopTest();

        System.assertNotEquals(null, response, 'La respuesta no debe ser null');
        System.assert(response.containsKey('results'), 'Debe contener la clave results');

        List<Object> results = (List<Object>) response.get('results');
        System.assertEquals(2, results.size(), 'Debe haber 2 resultados (1 OLI + 1 Mitigant)');

        Map<String, Object> firstEntry = (Map<String, Object>) results.get(0);
        System.assertEquals(200, (Integer) firstEntry.get('statusCode'), 'statusCode debe ser 200');
        System.assertNotEquals(null, firstEntry.get('result'), 'El campo result no debe ser null');
    }


    @isTest
    static void testGetMitigantsAndOppLineItems_onlyOLI() {
        Opportunity opp = getOpp();
        OpportunityLineItem oli = getOLI();

        Test.startTest();
        Map<String, Object> response = DMT_feature_limitController.getMitigantsAndOppLineItemsByField(
                opp.Id,
                new List<String>{ oli.gf_group_priority_opportunity_id__c },
                new List<String>()
            );
        Test.stopTest();

        List<Object> results = (List<Object>) response.get('results');
        System.assertEquals(1, results.size(), 'Solo debe haber 1 resultado (el OLI)');

        Map<String, Object> entry  = (Map<String, Object>) results.get(0);
        Map<String, Object> result = (Map<String, Object>) entry.get('result');
        System.assertEquals('OpportunityLineItem', (String) result.get('apiName'),
            'apiName debe ser OpportunityLineItem');

        Map<String, Object> fields = (Map<String, Object>) result.get('fields');
        Map<String, Object> nameField = (Map<String, Object>) fields.get('DES_Product_Name__c');
        System.assertEquals('DMT-TEST', (String) nameField.get('value'),
            'El valor de DES_Product_Name__c debe coincidir');
    }


    @isTest
    static void testGetMitigantsAndOppLineItems_onlyMitigant() {
        Opportunity opp = getOpp();
        DMT_Opportunity_Mitigant__c mit = getMitigant();

        Test.startTest();
        Map<String, Object> response = DMT_feature_limitController.getMitigantsAndOppLineItemsByField(
                opp.Id,
                new List<String>{ 'ID-QUE-NO-EXISTE' },
                new List<String>{ mit.Id }
            );
        Test.stopTest();

        List<Object> results = (List<Object>) response.get('results');
        System.assertEquals(1, results.size(), 'Solo debe haber 1 resultado (el Mitigant)');

        Map<String, Object> entry  = (Map<String, Object>) results.get(0);
        Map<String, Object> result = (Map<String, Object>) entry.get('result');
        System.assertEquals('DMT_Opportunity_Mitigant__c', (String) result.get('apiName'),
            'apiName debe ser DMT_Opportunity_Mitigant__c');

        Map<String, Object> fields    = (Map<String, Object>) result.get('fields');
        Map<String, Object> nameField = (Map<String, Object>) fields.get('Name');
        System.assertEquals(mit.Id, (String) nameField.get('value'),
            'El nombre del mitigant debe coincidir');
    }


    @isTest
    static void testGetMitigantsAndOppLineItems_emptyLists() {
        Opportunity opp = getOpp();

        Test.startTest();
        Map<String, Object> response = DMT_feature_limitController.getMitigantsAndOppLineItemsByField(
                opp.Id,
                new List<String>(),
                new List<String>()
            );
        Test.stopTest();

        System.assert(response.containsKey('results'), 'La clave results debe existir');
        List<Object> results = (List<Object>) response.get('results');
        System.assertEquals(0, results.size(), 'No debe haber resultados con listas vacías');
    }
}