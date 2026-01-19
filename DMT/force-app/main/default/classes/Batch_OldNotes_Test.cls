/**********************************************************************************
* @author       Alejandro del Rio
* @date         11/12/2019
* @description  test que ejecuta el batch_oldNotes
* @Revision
**********************************************************************************/
@isTest
public with sharing class Batch_OldNotes_Test {
    /*
    *Inicia los datos de prueba del test
    */
    @isTest
	private static void initializeTest() {//NOSONAR
        DES_UtilTestClass utilTestClass;
        utilTestClass = new DES_UtilTestClass();
        Account acc;
        acc = utilTestClass.createClient();
        insert acc;

        Opportunity opp;
        opp = utilTestclass.createOpportunity(acc);
        insert opp;

        final User user = utilTestClass.createUser(userinfo.getProfileId());
        insert user;

        final DES_Opportunity_Management_member__c oppmember = utilTestClass.createOppManagementMember(user, opp);
        insert oppmember;

        Product2 product1;
        product1 = utilTestClass.createProduct(Label.DES_Project_Finance_Lending);
        insert product1;

        PricebookEntry pbEntryTest;
        pbEntryTest = utilTestClass.createPricebookEntry(product1);
        insert pbEntryTest;

        Test.startTest();
        OpportunityLineItem oppLineItem;
        oppLineItem = utilTestClass.createOppLineItem(opp, product1, pbEntryTest);
        oppLineItem.product_scope_type__c = 'CIB';
        oppLineItem.syndicated_loan_drawn_amount__c = 5;
        oppLineItem.bbva_prtcp_tranche_amount__c = 100000000;
        insert oppLineItem;

        DES_Template__c template;
        template = utilTestClass.createTemplate(opp, oppLineItem);
		template.Purpose_desc__c='adfasfdas. asdfasdf';
        template.YTD_RORC_per_CDD__c = 1;
        template.Past_FY_RORC_per_CDD__c = 2;
        template.Standalone_CDD_RaR_number__c = 1;
        template.Standalone_CDD_RORC_number__c = 1;
        insert template;
        final Id batchInstanceId2 = Database.executeBatch(new Batch_OldNotes(), 1);
        System.assertNotEquals(batchInstanceId2, null, 'notEquals');
        Test.stopTest();
    }
}