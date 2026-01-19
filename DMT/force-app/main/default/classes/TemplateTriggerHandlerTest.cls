/**
* @author GlobalDesktop
*/
@isTest
public class TemplateTriggerHandlerTest {
  @isTest
    //Metodo1
    public static void updateOpp() {
        DES_Template__c template;
        template = initializeTest();
		Test.startTest();
        template.Pending_approval_type__c = true;
        template.YTD_RORC_per_CDD__c = 1;
        template.Past_FY_RORC_per_CDD__c = 2;
        template.Standalone_CDD_RaR_number__c = 1;
        template.Standalone_CDD_RORC_number__c = 1;
        DES_Template_Table__c tabTempl;
        tabTempl= [SELECT id FROM DES_Template_Table__c WHERE Parent_Template__c = :template.id];
        tabTempl.need_Update__c = true;
        update tabTempl;
        TemplateTableHandler.updateTemplate (template.id, true);
        TemplateTableHandler.searchTableTemplate (template.id);
        update template;
        Opportunity opp;
        opp = [SELECT id, Template_pending_approval_type__c from Opportunity where id = :template.Opportunity_id__c LIMIT 1];
		Test.stopTest();
        system.debug('opp.Template_pending_approval_type__c===='+opp.Template_pending_approval_type__c);
        system.assertEquals(opp.Template_pending_approval_type__c,false);
    }

    @isTest
    //Metodo2
    public static void deleteOpp() {
        DES_Template__c template;
        template = initializeTest();
        Test.startTest();
        template.Pending_approval_type__c = true;
        delete template;
        Opportunity opp;
        opp = [SELECT id, Template_pending_approval_type__c from Opportunity where id = :template.Opportunity_id__c LIMIT 1];
        system.assert(!opp.Template_pending_approval_type__c,'Error');
        Test.stopTest();
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
        template.Purpose_desc__c='adfasfdas. asdfasdf';
        template.YTD_RORC_per_CDD__c = 1;
        template.Past_FY_RORC_per_CDD__c = 2;
        template.Standalone_CDD_RaR_number__c = 1;
        template.Standalone_CDD_RORC_number__c = 1;
        insert template;
        return template;
    }

    @isTest
    /*
    *Method 3
    *
    */
    public static void updateTable() {
        DES_Template__c template;
        template = initializeTest();
        Test.startTest();
        template.Pending_approval_type__c = true;
        List<DES_Template_Table__c> ltabTempl;
        ltabTempl = [SELECT id FROM DES_Template_Table__c WHERE Parent_Template__c = :template.id];
        ltabTempl.get(0).need_Update__c = true;
        update ltabTempl.get(0);
        TemplateTableHandler.updateTemplate (template.id, true);
        delete ltabTempl;
        TemplateTableHandler.searchTableTemplate (template.id);
        Opportunity opp;
        opp = [SELECT id, Template_pending_approval_type__c from Opportunity where id = :template.Opportunity_id__c LIMIT 1];
        system.assert(!opp.Template_pending_approval_type__c,'Error');
        Test.stopTest();
    }

    @isTest
    /*
    * Method 4
    *
    */
    public static void createChatterTest() {
        DES_Template__c template;
        Test.startTest();
        template = initializeTest();
        Test.stopTest();
        DES_UtilTestClass utilTestClass;
        utilTestClass = new DES_UtilTestClass();
        final User user = utilTestClass.createUser(userinfo.getProfileId());
        insert user;
		Opportunity opp;
        opp = [SELECT id FROM Opportunity LIMIT 1];
        final DES_Opportunity_Management_member__c oppmember = utilTestClass.createOppManagementMember(user, opp);
        insert oppmember;
        final List<Chatter_NBC_Virtual__c> lsChatter = [SELECT Id, id_objeto__c FROM Chatter_NBC_Virtual__c LIMIT 1];
        system.assertEquals(template.id, lsChatter[0].id_objeto__c, 'Error al recuperar el campo id_objeto__c de Chatter_NBC_Virtual__c');
    }

    @isTest
    /*
    * Method 5
    *
    */
    public static void deleteChatterTest() {
        DES_Template__c template;
        template = initializeTest();
        Test.startTest();
        delete template;
        final List<Chatter_NBC_Virtual__c> lsChatter = [SELECT Id, id_objeto__c FROM Chatter_NBC_Virtual__c LIMIT 1];
        system.assert(lsChatter.isEmpty(), 'Error al eliminar el objeto de Chatter_NBC_Virtual__c');
        Test.stopTest();

    }
}