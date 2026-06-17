@IsTest
public with sharing class DMT_Opportunity_SelectorTest {
    
    @IsTest
    static void testProductId() {
       

        Test.startTest();
        List<OpportunityLineItem> results = DMT_Opportunity_Selector.getProductIds('',null);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Debe haber 0 resultados');
    }
}