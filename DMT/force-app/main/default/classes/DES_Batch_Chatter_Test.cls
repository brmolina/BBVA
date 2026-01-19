/*
*
*Test para probar Batch_Chatter_Template
*/
@isTest
public class DES_Batch_Chatter_Test {

    /*
    *
    *Test para probar Batch_Chatter_Template
    */
    @isTest
    public static void batchChatterTemplateTest() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final Opportunity opp = utilClass.createOpportunity(acc);
        opp.gf_oppy_virtual_cmtee_ind_type__c = true;
        insert opp;
        final Product2 prod = utilClass.createProduct('Producto de prueba');
        insert prod;
        final PricebookEntry pricebook = utilClass.createPricebookEntry(prod);
        pricebook.Pricebook2Id = opp.Pricebook2Id;
        insert pricebook;
        final OpportunityLineItem oppLineItem = utilClass.createOppLineItem(opp, prod, pricebook);
        insert oppLineItem;
        final DES_Template__c template = utilClass.createTemplate(opp, oppLineItem);
        template.YTD_RORC_per_CDD__c = 1;
        template.Past_FY_RORC_per_CDD__c = 2;
        template.Standalone_CDD_RaR_number__c = 1;
        template.Standalone_CDD_RORC_number__c = 1;
        insert template;

        Test.startTest();
        final Account acc2 = utilClass.createClient();
        insert acc2;
        final Opportunity opp2 = utilClass.createOpportunity(acc2);
        opp2.gf_oppy_virtual_cmtee_ind_type__c = true;
        insert opp2;
        final Product2 prod2 = utilClass.createProduct('Producto de prueba');
        insert prod2;
        final PricebookEntry pricebook2 = utilClass.createPricebookEntry(prod2);
        pricebook2.Pricebook2Id = opp2.Pricebook2Id;
        insert pricebook2;
        final OpportunityLineItem oppLineItem2 = utilClass.createOppLineItem(opp2, prod2, pricebook2);
        insert oppLineItem2;
        final DES_Template__c template2 = utilClass.createTemplate(opp2, oppLineItem2);
        template2.YTD_RORC_per_CDD__c = 1;
        template2.Past_FY_RORC_per_CDD__c = 2;
        template2.Standalone_CDD_RaR_number__c = 1;
        template2.Standalone_CDD_RORC_number__c = 1;
        insert template2;
        Test.stopTest();

        final List<Chatter_NBC_Virtual__c> lstChatter = [SELECT id, id_objeto__c FROM Chatter_NBC_Virtual__c WHERE id_objeto__c = :template.Id LIMIT 1];
        delete lstChatter;

		final Id batchJobId = Database.executeBatch(new Batch_Chatter_Template(), 200);
		system.debug('++ batchJobId' + batchJobId);

        System.assertNotEquals(batchJobId,null,'Error');
    }
}