/**
*
* @author Global Desktop
*/
@isTest
public class DES_MigrateProductsOpportunity_Test {
    /**
     * Test method for DES_MigrateProductsOpportunity_Batch
     */
    @isTest
    public static void testMigrateProduct() {
        final DES_UtilTestClass iUtilClass = new DES_UtilTestClass();
        final Account iAccount = iUtilClass.createClient();
        insert iAccount;

        final String profile = iUtilClass.createProfile();
        final User iUser = iUtilClass.createUser(profile);
        insert iUser;

        final Opportunity iOpportunity = iUtilClass.createOpportunity(iAccount);
        insert iOpportunity;

        final Product2 iProduct = iUtilClass.createProduct(Label.DES_Project_Finance_Lending);
        iProduct.ProductCode = 'codeTest';
        insert iProduct;

        final fprd__GBL_Product_version__c iProductVersion = iUtilClass.createVersionProduct(iProduct);
        insert iProductVersion;

        final PricebookEntry iPricebookEntry = iUtilClass.createPricebookEntry(iProduct);
        insert iPricebookEntry;

        final OpportunityLineItem iOppLI = iUtilClass.createOppLineItem(iOpportunity, iProduct, iPricebookEntry);
        iOppLI.product_scope_type__c = 'CIB';
        iOppLI.DES_BBVA_Final_Hold__c = 5;
        iOppLI.bbva_prtcp_tranche_amount__c = 100000000;
        insert iOppLI;

        iOppLI.fprd__GBL_Product_version__c = null;
        update iOppLI;

        Test.startTest();
            final DES_MigrateProductsOpportunity_Batch iBatch = new DES_MigrateProductsOpportunity_Batch('SELECT Id FROM Opportunity');
            Database.executeBatch(iBatch, 1);
        Test.stopTest();

        final OpportunityLineItem iOppLIFinal = [SELECT Id, Product2.Name FROM OpportunityLineItem LIMIT 1];

        System.assertEquals(Label.DES_Project_Finance_Lending, iOppLIFinal.Product2.Name, 'The product has not been migrated');
    }
}