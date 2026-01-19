/**
* @author GlobalDesktop
*/
@isTest
public class TemplateVF_ControllerTest {
    @isTest
    /*
    * Method1
    */
    public static void templateVFControllerTest1(){
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        Account acc = utilTestClass.createClient();
        insert acc;

        Opportunity opp = utilTestclass.createOpportunity(acc);
        insert opp;

        Product2 product1 = utilTestClass.createProduct(Label.DES_Project_Finance_Lending);
        insert product1;

        PricebookEntry pbEntryTest = utilTestClass.createPricebookEntry(product1);
        insert pbEntryTest;

    OpportunityLineItem oppLineItem = utilTestClass.createOppLineItem(opp, product1, pbEntryTest);
    oppLineItem.product_scope_type__c = 'CIB';
    oppLineItem.syndicated_loan_drawn_amount__c = 5;
    oppLineItem.bbva_prtcp_tranche_amount__c = 100000000;
    insert oppLineItem;

    DES_Template__c template = utilTestClass.createTemplate(opp, oppLineItem);
        template.RecordTypeId =  Schema.SObjectType.DES_Template__c.getRecordTypeInfosByDeveloperName().get('PF').getRecordTypeId();
        template.YTD_RORC_per_CDD__c = 1;
        template.Past_FY_RORC_per_CDD__c = 2;
        template.Standalone_CDD_RaR_number__c = 1;
        template.Standalone_CDD_RORC_number__c = 1;
    insert template;

        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(template);
        TemplateVF_Controller controller = new TemplateVF_Controller(stdController);
        system.assertEquals(5.00,template.Transaction_Deal_Amount1_number__c,'Error');

        controller.saveBusinessPlan();
        controller.saveGlobalStructure();

    Test.stopTest();
    }

    @isTest
    /*
    *Method2
    */
    public static void templateVFControllerTest2() {
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final Account acc = utilTestClass.createClient();
        insert acc;

        final Opportunity opp = utilTestclass.createOpportunity(acc);
        insert opp;

        final Product2 product1 = utilTestClass.createProduct(Label.DES_Project_Finance_Lending);
        insert product1;

        final PricebookEntry pbEntryTest = utilTestClass.createPricebookEntry(product1);
        insert pbEntryTest;

    final OpportunityLineItem oppLineItem = utilTestClass.createOppLineItem(opp, product1, pbEntryTest);
    oppLineItem.product_scope_type__c = 'CIB';
    oppLineItem.syndicated_loan_drawn_amount__c = 5;
    oppLineItem.bbva_prtcp_tranche_amount__c = 100000000;
    insert oppLineItem;

    final DES_Template__c template = utilTestClass.createTemplate(opp, oppLineItem);
        template.RecordTypeId =  Schema.SObjectType.DES_Template__c.getRecordTypeInfosByDeveloperName().get('PF').getRecordTypeId();
        template.YTD_RORC_per_CDD__c = 1;
        template.Past_FY_RORC_per_CDD__c = 2;
        template.Standalone_CDD_RaR_number__c = 1;
        template.Standalone_CDD_RORC_number__c = 1;
    insert template;

        Test.startTest();
        final ApexPages.StandardController stdController = new ApexPages.StandardController(template);
        final TemplateVF_Controller controller = new TemplateVF_Controller(stdController);
        system.assertEquals(5.00,template.Transaction_Deal_Amount1_number__c,'Error');

        controller.saveBasicFinancials();
        controller.saveTransactionOverview();

    Test.stopTest();
    }

    @isTest
    /*
    *Method3
    */
    public static void templateVFControllerTest3() {
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final Account acc = utilTestClass.createClient();
        insert acc;

        final Opportunity opp = utilTestclass.createOpportunity(acc);
        insert opp;

        final Product2 product1 = utilTestClass.createProduct(Label.DES_Project_Finance_Lending);
        insert product1;

        final PricebookEntry pbEntryTest = utilTestClass.createPricebookEntry(product1);
        insert pbEntryTest;

    final OpportunityLineItem oppLineItem = utilTestClass.createOppLineItem(opp, product1, pbEntryTest);
    oppLineItem.product_scope_type__c = 'CIB';
    oppLineItem.syndicated_loan_drawn_amount__c = 5;
    oppLineItem.bbva_prtcp_tranche_amount__c = 100000000;
    insert oppLineItem;

    final DES_Template__c template = utilTestClass.createTemplate(opp, oppLineItem);
        template.RecordTypeId =  Schema.SObjectType.DES_Template__c.getRecordTypeInfosByDeveloperName().get('PF').getRecordTypeId();
        template.YTD_RORC_per_CDD__c = 1;
        template.Past_FY_RORC_per_CDD__c = 2;
        template.Standalone_CDD_RaR_number__c = 1;
        template.Standalone_CDD_RORC_number__c = 1;
    insert template;

        Test.startTest();
        final ApexPages.StandardController stdController = new ApexPages.StandardController(template);
        final TemplateVF_Controller controller = new TemplateVF_Controller(stdController);
        system.assertEquals(5.00,template.Transaction_Deal_Amount1_number__c,'Error');

        controller.saveSustainable();

    Test.stopTest();
    }
}