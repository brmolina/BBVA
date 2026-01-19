@IsTest
public class DMT_OppToSanctionUtilsTest {

    @TestSetup
    static void loadTestData() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityClient(opp.Id);
        Product2 product2 = DMT_Test_DataFactory.generateProduct2();
        PricebookEntry pricebookEntry = DMT_Test_DataFactory.generatePricebookEntry(product2);
        OpportunityLineItem opportunityLineItem = DMT_Test_DataFactory.generateOpportunityLineItem(product2, pricebookEntry, opp);
        DMT_Opportunity_Mitigant__c mitigant = DMT_Test_DataFactory.generateOpportunityMitigant(opportunityLineItem);
    }

    @IsTest
    static void testCreateRiskLinesAndWarranties() {
        Test.startTest();

        DMT_Test_DataFactory.generateTestSanctionLines();

        // Obtener OpportunityLineItems de los datos de TestSetup
        List<OpportunityLineItem> olis = [SELECT Id, Product2Id, DMT_Risk_Type__c, gf_amortization_type__c, opportunity_risk_name__c, gf_maturity_date__c, DMT_TXA_Comentarios__c 
                                          FROM OpportunityLineItem];
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c LIMIT 1];
        // Preparar wrapper
        List<DMT_OppToSanctionUtils.OpportunityLineItemWrapper> wrappers = new List<DMT_OppToSanctionUtils.OpportunityLineItemWrapper>();
        DMT_OppToSanctionUtils.OpportunityLineItemWrapper wrapper = new DMT_OppToSanctionUtils.OpportunityLineItemWrapper();
        wrapper.listOli = olis;
        wrapper.idLine = line.Id;
        wrappers.add(wrapper);

        DMT_OppToSanctionUtils.createRiskLinesAndWarranties(wrappers);
        Test.stopTest();

       

        // Verificar que se crearon Warranties
        List<DMT_Warranty__c> warranties = [SELECT Id, DMT_Risk_Line_Term__c, Name FROM DMT_Warranty__c];
        System.assertEquals([SELECT count() FROM DMT_Opportunity_Mitigant__c], warranties.size(), 'Se deben crear Warranties por cada mitigante');
    }
}