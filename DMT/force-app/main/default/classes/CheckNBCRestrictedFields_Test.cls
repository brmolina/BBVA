/**
* @author GlobalDesktop
*/
@isTest
public with sharing class CheckNBCRestrictedFields_Test {
    @isTest
    /*
    * Method1
    */
    public static void updateOpp() {
        DES_Template__c template;
        template = initializeTest();
        final List<String> lTest = new List<String>();
        lTest.add(template.id);
        CheckNBCRestrictedFields.checkRestrictedFields(lTest);
        system.assertEquals(lTest.get(0),template.id,'Error');
    }

    private static DES_Template__c initializeTest() {
        DES_UtilTestClass utilTestClass;
        utilTestClass = new DES_UtilTestClass();
        Account acc;
        acc = utilTestClass.createClient();
        insert acc;

        Opportunity opp;
        opp = utilTestclass.createOpportunity(acc);
        insert opp;

        Product2 product1;
        product1 = utilTestClass.createProduct(Label.DES_Project_Finance_Lending);
        insert product1;

        PricebookEntry pbEntryTest;
        pbEntryTest = utilTestClass.createPricebookEntry(product1);
        insert pbEntryTest;

        OpportunityLineItem oppLineItem;
        oppLineItem = utilTestClass.createOppLineItem(opp, product1, pbEntryTest);
        oppLineItem.product_scope_type__c = 'CIB';
        oppLineItem.syndicated_loan_drawn_amount__c = 5;
        oppLineItem.bbva_prtcp_tranche_amount__c = 100000000;
        insert oppLineItem;

        DES_Template__c template;
        template = utilTestClass.createTemplate(opp, oppLineItem);
        template.curncy_trans_year_one_type__c = 'EUR';
        template.YTD_RORC_per_CDD__c = 1;
        template.Past_FY_RORC_per_CDD__c = 2;
        template.Standalone_CDD_RaR_number__c = 1;
        template.Standalone_CDD_RORC_number__c = 1;
        insert template;
        return template;
    }
}