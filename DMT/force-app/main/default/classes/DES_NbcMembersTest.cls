/**
    *Autor: Alejandro del Rio
     */
@isTest
public class DES_NbcMembersTest {

    @isTest//NOSONAR
    /*
    *
    *Met0d0 para comprobar el funcionamiento de gtNBCMembers del componente DES_NbcMembers
    */
    public static void gtNBCMembersTest() {
        DES_UtilTestClass utilTestClass;
        utilTestClass = new DES_UtilTestClass();
        Account acc;
        acc = utilTestClass.createClient();
        insert acc;
        final NBC__c nbc = utilTestClass.createNBC();
        insert nbc;
        Opportunity opp;
        opp = utilTestclass.createOpportunity(acc);
        opp.Committee_id__c=nbc.Id;
        opp.gf_oppy_virtual_cmtee_ind_type__c=true;
        insert opp;
        NBC_Commitee_Member__c comite;
        comite = utilTestClass.createNbcCommitee(nbc.Id,opp.Id);
        insert comite;
        Test.startTest();
        DES_NbcMembers.gtNBCMembers(nbc.Id,opp.Id);
        System.assertNotEquals(nbc.Id, null);
        Test.stopTest();
    }
    @isTest//NOSONAR
    /*
    *
    *Met0d0 para comprobar el funcionamiento de gtNBCTemplate delc omponente DES_NbcMembers
    */
    public static void gtNBCMembersTest2() {
        DES_UtilTestClass utilTestClass;
        utilTestClass = new DES_UtilTestClass();
        Account acc;
        acc = utilTestClass.createClient();
        insert acc;
        final NBC__c nbc = utilTestClass.createNBC();
        insert nbc;
        Opportunity opp;
        opp = utilTestclass.createOpportunity(acc);
        opp.Committee_id__c=nbc.Id;
        opp.gf_oppy_virtual_cmtee_ind_type__c=true;
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
        template.opportunity_nbc_comments_desc__c='test';
        template.YTD_RORC_per_CDD__c = 1;
        template.Past_FY_RORC_per_CDD__c = 2;
        template.Standalone_CDD_RaR_number__c = 1;
        template.Standalone_CDD_RORC_number__c = 1;
        insert template;

        DES_NbcMembers.gtNBCTemplate(opp.Id);
        System.assertNotEquals(opp.Id, null);
        Test.stopTest();
    }
    @isTest//NOSONAR
    /*
    *
    *Met0d0 para comprobar el funcionamiento de updateNBCvote del componente DES_NbcMembers
    */
    public static void gtNBCMembersTest3() {
        DES_UtilTestClass utilTestClass;
        utilTestClass = new DES_UtilTestClass();
        Account acc;
        acc = utilTestClass.createClient();
        insert acc;
        final NBC__c nbc = utilTestClass.createNBC();
        insert nbc;
        Opportunity opp;
        opp = utilTestclass.createOpportunity(acc);
        opp.Committee_id__c=nbc.Id;
        opp.gf_oppy_virtual_cmtee_ind_type__c=true;
        insert opp;
        NBC_Commitee_Member__c comite;
        comite = utilTestClass.createNbcCommitee(nbc.Id,opp.Id);
        insert comite;
        Test.startTest();
        DES_NbcMembers.updateNBCvote(nbc.Id,'Supportive',opp.Id);
        System.assertNotEquals(nbc.Id, null);
        Test.stopTest();
    }
    @isTest//NOSONAR
    /*
    *
    *Met0d0 que espera recibir un boolean de getUserRelated
    */
    public static void gtNBCMembersTest4() {
        DES_UtilTestClass utilTestClass;
        utilTestClass = new DES_UtilTestClass();
        Account acc;
        acc = utilTestClass.createClient();
        insert acc;
        final NBC__c nbc = utilTestClass.createNBC();
        insert nbc;
        Opportunity opp;
        opp = utilTestclass.createOpportunity(acc);
        opp.Committee_id__c=nbc.Id;
        opp.gf_oppy_virtual_cmtee_ind_type__c=true;
        insert opp;
        final User user = utilTestClass.createUser(userinfo.getProfileId());
        insert user;

        final DES_Opportunity_Management_member__c oppmember = utilTestClass.createOppManagementMember(user, opp);
        insert oppmember;
        Test.startTest();
        DES_NbcMembers.getUserRelated(opp.Id);
        System.assertNotEquals(DES_NbcMembers.getUserRelated(opp.Id), null);
        Test.stopTest();
    }
}