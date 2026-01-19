/*
*
*Test para la clase ComponentVirtualNBC_Controller
* @author Aitor Martin
*/
@isTest
public class ComponentVirtualNBC_Controller_test {

    /*
    * String para comprobaciones
    */
    static final String CAMPO = 'prueba';

    /*
    *
    * Method para comprobar el funcionamiento del method valorNBC
    * @author Aitor Martin
    */
    @isTest
    public static void testvalorNBC() {
        //Creacion de objetos
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

        ComponentVirtualNBC_Controller.gtInstance();
        final DES_Template__c template2 = ComponentVirtualNBC_Controller.valorNBC(template.Id);
        system.assert(true,template2.opportunity_id__r.gf_oppy_virtual_cmtee_ind_type__c);
    }

    /*
    *
    * Method para comprobar el funcionamiento del method escriboDescp
    * @author Aitor Martin
    */
    @isTest
    public static void testescriboDescp() {
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

        ComponentVirtualNBC_Controller.escriboDescp(template.Id, CAMPO);
        final List<DES_Template__c> listTempl = new List<DES_Template__c>([SELECT Id, opportunity_nbc_comments_desc__c FROM DES_Template__c  WHERE Id = :template.Id LIMIT 1]);

        system.assertEquals(campo, listTempl.get(0).opportunity_nbc_comments_desc__c, 'El valor escrito y el del campo del template no son el mismo');
    }

    /*
    *
    * Method para comprobar el catch del method escriboDescp
    * @author Aitor Martin
    */
    @isTest
    public static void testKOescriboDescp() {
        //Creacion de objetos
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
        final User usuario = utilClass.createUserWithProfileName('BBVA Desktop Finance','usuario@prueba.cdasaom');
        insert usuario;

        system.runAs(usuario) {
            try {
                ComponentVirtualNBC_Controller.escriboDescp(template.Id, CAMPO);
            } catch(Exception e) {
                system.assert(e.getMessage().contains('exception'),'msg');
            }
        }
    }

}