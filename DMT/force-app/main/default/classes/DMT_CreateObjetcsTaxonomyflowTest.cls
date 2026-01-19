@isTest
public with sharing class DMT_CreateObjetcsTaxonomyflowTest {
    @TestSetup
    static void makeData(){
        DMT_Test_DataFactory.generateTaxonomies();
    }

    @isTest
    static void testCreateProducts() {
        List<DMT_Taxonomy_Values__c> taxonomies = [SELECT Id, DMT_Name__c, DMT_External_Id__c, DMT_Catalog__c, DMT_Key__c, DMT_Value__c, DMT_Name_EN__c FROM DMT_Taxonomy_Values__c];

        List<DMT_CreateObjetcsTaxonomyflow.Request> requestList = new List<DMT_CreateObjetcsTaxonomyflow.Request>();

        for(DMT_Taxonomy_Values__c t : taxonomies)
        {
            DMT_CreateObjetcsTaxonomyflow.Request request = new DMT_CreateObjetcsTaxonomyflow.Request();
            request.taxonomy = t;
            requestList.add(request);
        }

        Test.startTest();
        DMT_CreateObjetcsTaxonomyflow.createTaxonomyObjects(requestList);
        Test.stopTest();

        List<Product2> products = [SELECT Id FROM Product2];

        System.assertEquals(3, products.size(), 'Debe haber tres registros de Products');
    }
}