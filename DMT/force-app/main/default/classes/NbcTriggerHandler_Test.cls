/*
* @author       Alejandro del Rio Martin
* @date         21/01/2020
* @description  Clase para los test realizados en NBCTriggerHandler
*/
@isTest
public class NbcTriggerHandler_Test {
	
    /*
    * Variable para definir la region del nbc
    */
    static final String REGION = 'LATAM';
    /*
    * Variable de la clase DES_UtilTestClass
    */
    private final static DES_UtilTestClass UTIL_TEST_CLASS = new DES_UtilTestClass();

    @isTest//NOSONAR
    /*
    *
    *Met0d0 para comprobar el funcionamiento de deleteChatter del trigger de NBC
    */
    public static void deleteChatter() {
        Final RecordType recordT = [select Id from RecordType where Name = 'Virtual NBC'  limit 1];
        final NBC__c nbc = UTIL_TEST_CLASS.createNBC();
        nbc.NBC_Region_type__c = REGION;
        nbc.RecordTypeId=recordT.Id;
        insert nbc;
        final Account acc = UTIL_TEST_CLASS.createClient();
        insert acc;
        final Opportunity opp = UTIL_TEST_CLASS.createOpportunity(acc);
        opp.DES_NBC_Region__c = REGION;
        opp.Template_approved_type__c = true;
        opp.gf_oppy_virtual_cmtee_ind_type__c=true;
        opp.Committee_id__c = nbc.id;
        insert opp;
        final Product2 prod = UTIL_TEST_CLASS.createProduct('Producto de prueba');
        insert prod;
        final PricebookEntry pricebook = UTIL_TEST_CLASS.createPricebookEntry(prod);
        pricebook.Pricebook2Id = opp.Pricebook2Id;
        insert pricebook;
        final OpportunityLineItem oppLineItem = UTIL_TEST_CLASS.createOppLineItem(opp, prod, pricebook);
        insert oppLineItem;
        final DES_Template__c template = UTIL_TEST_CLASS.createTemplate(opp, oppLineItem);
        template.gf_oppy_virtual_cmtee_id__c = nbc.id;
        template.YTD_RORC_per_CDD__c = 1;
        template.Past_FY_RORC_per_CDD__c = 2;
        template.Standalone_CDD_RaR_number__c = 1;
        template.Standalone_CDD_RORC_number__c = 1;
        insert template;
        Test.startTest();
        delete Nbc;
        final List<Chatter_NBC_Virtual__c> ChatterVirtual = [SELECT Id from Chatter_NBC_Virtual__c where id_objeto__c =: Opp.Id];//NOSONAR
        system.assertEquals(true, ChatterVirtual.isEmpty() , 'No se ha borrado el chatter');//NOSONAR
        Test.stopTest();
    }
}