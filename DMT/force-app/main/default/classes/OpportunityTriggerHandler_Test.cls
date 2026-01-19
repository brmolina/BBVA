/*
* @author       Aitor Martin
* @date         14/11/2019
* @description  Clase para los test realizados en OpportunityTriggerHandler en relacion con en Opportunity.trigger
*/
@isTest
public with sharing class OpportunityTriggerHandler_Test {
    /*
    * Variable para definir la region del nbc
    */
    static final String REGION = 'LATAM';
    /*
    * Variable de la clase DES_UtilTestClass
    */
    private final static DES_UtilTestClass UTIL_TEST_CLASS = new DES_UtilTestClass();

    // @isTest//NOSONAR
    /*
    *
    *Met0d0 para comprobar el funcionamiento de updateTemplate del trigger de oportunidad
    */
    public static void updateTemplateTest() {

        final NBC__c nbc = UTIL_TEST_CLASS.createNBC();
        nbc.NBC_Region_type__c = REGION;
        insert nbc;
        final Account acc = UTIL_TEST_CLASS.createClient();
        insert acc;
        final Opportunity opp = UTIL_TEST_CLASS.createOpportunity(acc);
        opp.DES_NBC_Region__c = REGION;
        opp.Template_approved_type__c = true;
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

        final Map<ID, Opportunity> mapOld = new Map<ID, Opportunity>([SELECT Id, Name, Committee_id__c FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1]);
        List <Opportunity> oppNueva = [SELECT id, Committee_id__c, Name  FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1]; //NOSONAR
        System.debug('mapOld ------------------------------->'+mapOld);
        System.debug('oppNueva------------------------------->'+oppNueva);
        for(Opportunity opComi : oppNueva) {
            opComi.Committee_id__c = null;//NOSONAR
        }
        update(oppNueva);
        final List<Opportunity> oppTrig = [SELECT id, Committee_id__c, Name  FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1]; //NOSONAR

        OpportunityTriggerHandler.updateTemplate(oppTrig, mapOld);
        final List <DES_Template__c> lstTemp = [SELECT id, gf_oppy_virtual_cmtee_id__c FROM DES_Template__c WHERE Id = :template.Id];
        system.assertEquals(oppTrig.get(0).Committee_id__c, lstTemp.get(0).gf_oppy_virtual_cmtee_id__c , 'El valor escrito y el del campo del template no son el mismo');

    }

    @isTest//NOSONAR
    /*
    *
    *Met0d0 para comprobar el funcionamiento de crearChatter del trigger de oportunidad
    */
    public static void crearChatterTest() {

        final list<NBC__c> listnbc = new list<NBC__c>();
        final NBC__c nbc = UTIL_TEST_CLASS.createNBC();
        nbc.NBC_Region_type__c = REGION;
        listnbc.add(nbc);
        final NBC__c nbc2 = UTIL_TEST_CLASS.createNBC();
        nbc2.NBC_Region_type__c = REGION;
        nbc2.Name = 'NBC PRUEBA AITOR';
        listnbc.add(nbc2);
        insert(listnbc);

        final list<Account> listacc = new list<Account>();
        final Account acc = UTIL_TEST_CLASS.createClient();
        listacc.add(acc);
     	final Account acc2 = UTIL_TEST_CLASS.createClient();
        listacc.add(acc2);
        insert listacc;

        final list<Opportunity> listopp = new list<Opportunity>();
        final Opportunity opp = UTIL_TEST_CLASS.createOpportunity(acc);
        opp.DES_NBC_Region__c = REGION;
        opp.Template_approved_type__c = true;
        opp.gf_oppy_virtual_cmtee_ind_type__c = true;
        opp.Committee_id__c = nbc.id;
        listopp.add(opp);

        final Opportunity opp2 = UTIL_TEST_CLASS.createOpportunity(acc2);
        opp2.DES_NBC_Region__c = REGION;
        opp2.Template_approved_type__c = true;
        opp2.gf_oppy_virtual_cmtee_ind_type__c = true;
        opp2.Name = 'Test Opportunity 2';
        listopp.add(opp2);
        insert(listopp);


        List<Product2> lstProd;
        lstProd = new List<Product2>();
        final Product2 prod = UTIL_TEST_CLASS.createProduct('Producto de prueba');
        lstProd.add(prod);
        final Product2 prod2 = UTIL_TEST_CLASS.createProduct('Producto de prueba');
        lstProd.add(prod2);
        insert lstProd;

        List<PricebookEntry> lstPB;
        lstPB = new List<PricebookEntry>();
        final PricebookEntry pricebook = UTIL_TEST_CLASS.createPricebookEntry(prod);
        pricebook.Pricebook2Id = opp.Pricebook2Id;
        lstPB.add(pricebook);
        final PricebookEntry pricebook2 = UTIL_TEST_CLASS.createPricebookEntry(prod2);
        pricebook2.Pricebook2Id = opp2.Pricebook2Id;
        lstPB.add(pricebook2);
        insert lstPB;

        List<OpportunityLineItem> lstoppLine;
        lstoppLine = new List<OpportunityLineItem>();
        final OpportunityLineItem oppLineItem = UTIL_TEST_CLASS.createOppLineItem(opp, prod, pricebook);
        lstoppLine.add(oppLineItem);
        final OpportunityLineItem oppLineItem2 = UTIL_TEST_CLASS.createOppLineItem(opp2, prod2, pricebook2);
        lstoppLine.add(oppLineItem2);
        insert lstoppLine;


        List<DES_Template__c> lstTem;
        lstTem = new List<DES_Template__c>();
        final DES_Template__c template = UTIL_TEST_CLASS.createTemplate(opp, oppLineItem);
        template.gf_oppy_virtual_cmtee_id__c = nbc.id;
        template.YTD_RORC_per_CDD__c = 1;
        template.Past_FY_RORC_per_CDD__c = 2;
        template.Standalone_CDD_RaR_number__c = 1;
        template.Standalone_CDD_RORC_number__c = 1;
        lstTem.add(template);
        final DES_Template__c template2 = UTIL_TEST_CLASS.createTemplate(opp2, oppLineItem2);
        template2.Name = 'Prueba Aitor';
        template2.YTD_RORC_per_CDD__c = 1;
        template2.Past_FY_RORC_per_CDD__c = 2;
        template2.Standalone_CDD_RaR_number__c = 1;
        template2.Standalone_CDD_RORC_number__c = 1;
        lstTem.add(template2);
        insert lstTem;

        Test.startTest();

        final Map<ID, Opportunity> mapOld = new Map<ID, Opportunity>([SELECT Id, Name, Committee_id__c FROM Opportunity LIMIT 2]);
        List <Opportunity> oppNueva = [SELECT id, Committee_id__c, Name  FROM Opportunity LIMIT 2]; //NOSONAR
        final List <NBC__c> lstNbc = [SELECT id, Name FROM NBC__c LIMIT 2];
        System.debug('mapOld ------------------------------->'+mapOld);
        System.debug('oppNueva------------------------------->'+oppNueva);
        System.debug('lstNbc------------------------------->'+lstNbc);

        oppNueva[0].Committee_id__c = lstNbc[1].id;
        oppNueva[1].Committee_id__c = lstNbc[0].id;

        System.debug('oppNueva------------------------------->'+oppNueva);
        update(oppNueva);

        final List <Chatter_NBC_Virtual__c> lstChat = [SELECT id, id_objeto__c FROM Chatter_NBC_Virtual__c LIMIT 2];
        system.assertEquals(2, lstChat.size() , 'No se han creado los objetos chatter necesarios.');

        Test.stopTest();
    }

    @isTest//NOSONAR
    /*
    *
    *Metodo para comprobar el funcionamiento de la confidencialidad de opp Clientes Venezolanos
    */
    public static void oppClientVenezuela() {

        List<Account> accs = new List <Account>();
        final Account acc = UTIL_TEST_CLASS.createClient();
        acc.DES_Country_Client__c = 'VE';
        accs.add(acc);
        final Account acc2 = UTIL_TEST_CLASS.createClient();
        acc2.DES_Country_Client__c = 'VE';
        accs.add(acc2);
        insert accs;

        final DES_Subsidiary_Group_Relation__c matrix = new DES_Subsidiary_Group_Relation__c();
        matrix.participant_child_id__c = acc.Id;
        matrix.participant_parent_id__c = acc2.Id;
        matrix.main_subsidiary_ind_type__c = true;
        insert matrix;

        Id idProfile = [Select Id, Name from Profile Where Name = 'BBVA Desktop GCC Standard'].Id;

        List<User> users = new List <user>();
        final User user1 = UTIL_TEST_CLASS.createUser(idProfile);
        final User user2 = UTIL_TEST_CLASS.createUser(idProfile,'Heyhey@oppven.com');
        users.add(user1);
        users.add(user2);
        insert users;

        List<DES_BBVA_Management_team__c> lstTeamMag = new List<DES_BBVA_Management_team__c>();
        final DES_BBVA_Management_team__c teamMmg1 = new DES_BBVA_Management_team__c();
        teamMmg1.DES_Local_Banker_Country__c = 'VE';
        teamMmg1.DES_Member_Role__c = Label.DES_Role_Transactional_Banker;
        teamMmg1.DES_User__c = user1.Id;
        teamMmg1.DES_Client__c = acc2.Id;
        lstTeamMag.add(teamMmg1);

        final DES_BBVA_Management_team__c teamMmg2 = new DES_BBVA_Management_team__c();
        teamMmg2.DES_Local_Banker_Country__c = 'Global';
        teamMmg2.DES_Member_Role__c = Label.DES_ROLE_GLOBAL_BANKER;
        teamMmg2.DES_User__c = user2.Id;
        teamMmg2.DES_Client__c = acc2.Id;
        lstTeamMag.add(teamMmg2);
        insert lstTeamMag;
		Test.startTest();
        final Opportunity opp = UTIL_TEST_CLASS.createOpportunity(acc);
        insert opp;

        final Product2 prod = UTIL_TEST_CLASS.createProduct('Credit');
        insert prod;

        final AccountTeamMember accTMmbr = new AccountTeamMember();
        accTMmbr.AccountId = acc2.Id;
        accTMmbr.AccountAccessLevel = 'Edit';
        accTMmbr.ContactAccessLevel = 'Edit';
        accTMmbr.OpportunityAccessLevel = 'Edit';
        accTMmbr.UserId = user2.Id;
        insert accTMmbr;

        final PricebookEntry pricebook = UTIL_TEST_CLASS.createPricebookEntry(prod);
        pricebook.Pricebook2Id = opp.Pricebook2Id;
        insert pricebook;

        final OpportunityLineItem oppLineItem = UTIL_TEST_CLASS.createOppLineItem(opp, prod, pricebook);
        insert oppLineItem;
		Test.stopTest();
        opp.StageName = 'Proposal';
        Update opp;

        final List<OpportunityShare> listToVerify = [Select Id, UserOrGroupId, OpportunityId from OpportunityShare Where OpportunityId = :opp.Id AND (UserOrGroupId =:user1.Id OR UserOrGroupId =:user2.Id)];

        system.assertEquals(4,listToVerify.size(),'No se han creado las Manual Sharing Rules necesarias');

    }

}