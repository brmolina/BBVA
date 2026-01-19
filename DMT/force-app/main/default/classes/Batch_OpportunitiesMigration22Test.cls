/**
*
* @author Global Desktop
*/
@isTest
public class Batch_OpportunitiesMigration22Test {
    /**
     * Test method for Batch_OpportunitiesMigration2Test
     */
    @isTest
    public static void testMigrateOppliFields() {
        final DES_UtilTestClass iUtilClass = new DES_UtilTestClass();
        final Account iAccount = iUtilClass.createClient();
        insert iAccount;

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
        iOppLI.DES_Commitment_Fees__c = 5000;
        iOppLI.DES_Annual_Risk_Fee__c = 50;
        iOppLI.syndicated_loan_drawn_amount__c = 5000;
        iOppLI.DES_CIB_Client__c = 'Yes';
        iOppLI.DES_NBC_Approval_Date__c = Date.today();
        iOppLI.DES_Tenor__c = '10';
        insert iOppLI;

        Test.startTest();
            final Batch_OpportunitiesMigration2 iBatch = new Batch_OpportunitiesMigration2();
            Database.executeBatch(iBatch, 1);
        Test.stopTest();

        final OpportunityLineItem iOppLIFinal = [SELECT Id, Product2.Name FROM OpportunityLineItem LIMIT 1];

        System.assertEquals(Label.DES_Project_Finance_Lending, iOppLIFinal.Product2.Name, 'The product has not been migrated');
    }
}