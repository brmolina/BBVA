@isTest
public class DES_OpportunityManagMemberTriggerTest {
	
	@isTest
    public static void DES_OpportunityManagMemberTriggerTest() {
        
        DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        String profileTest = utilTestClass.createProfile();
        User userTest1 = utilTestClass.createUser(profileTest);
       	insert userTest1;
        CIB_User_Org__c userSettings = utilTestClass.createCustomSetting();
        insert userSettings;
       
        system.runAs(userTest1){
        	
        	Test.startTest();
        	Account acc1 = utilTestClass.createClient();
        	insert acc1;
        	List<Opportunity> listaOpps = new List<Opportunity>();
        	Opportunity opp1 = utilTestClass.createOpportunity(acc1);
        	listaOpps.add(opp1);
        	Opportunity opp2 = utilTestClass.createOpportunity(acc1);
        	listaOpps.add(opp2);
        	Opportunity opp3 = utilTestClass.createOpportunity(acc1);
        	listaOpps.add(opp3);
        	Test.stopTest();
        	insert listaOpps;
        	
        	List<DES_Opportunity_Management_member__c> listaOTM = new List<DES_Opportunity_Management_member__c>();
        	List<DES_Opportunity_Management_member__c> listaDuplicados = new List<DES_Opportunity_Management_member__c>();
        	
        	DES_Opportunity_Management_member__c otm1 = utilTestClass.createOppManagementMember(userTest1, opp1);
        	otm1.DES_Opportunity_member_role__c = Label.DES_ROLE_LOCAL_BANKER;
        	otm1.DES_Scope__c = 'ES';
        	listaOTM.add(otm1);
        	DES_Opportunity_Management_member__c otm2 = utilTestClass.createOppManagementMember(userTest1, opp2);
        	otm2.DES_Opportunity_member_role__c = Label.DES_ROLE_INDUSTRY_HEAD;
        	otm2.DES_Scope__c = 'ES';
        	listaOTM.add(otm2);
        	DES_Opportunity_Management_member__c otmPS1 = utilTestClass.createOppManagementMember(userTest1, opp2);
        	otmPS1.DES_Opportunity_member_role__c = Label.DES_Role_Product_Specialist;
        	otmPS1.DES_Scope__c = 'ES';
            Product2 product = utilTestClass.createProduct('Credit');
            insert product;
            otmPS1.DES_PS_Product_Family__c = 'GTB';
            otmPS1.DES_PS_Product__c = product.Id;
        	listaOTM.add(otmPS1);
        	insert listaOTM;
        	
        	
        	DES_Opportunity_Management_member__c otm3 = utilTestClass.createOppManagementMember(userTest1, opp1);
        	otm3.DES_Opportunity_member_role__c = Label.DES_ROLE_LOCAL_BANKER;
        	otm3.DES_Scope__c = 'ES';
        	listaDuplicados.add(otm3);
        	DES_Opportunity_Management_member__c otm4 = utilTestClass.createOppManagementMember(userTest1, opp2);
        	otm4.DES_Opportunity_member_role__c = Label.DES_ROLE_INDUSTRY_HEAD;
        	otm4.DES_Scope__c = 'ES';
        	listaDuplicados.add(otm4);
        	DES_Opportunity_Management_member__c otmPS2 = utilTestClass.createOppManagementMember(userTest1, opp2);
        	otmPS2.DES_Opportunity_member_role__c = Label.DES_Role_Product_Specialist;
        	otmPS2.DES_Scope__c = 'ES';
            otmPS2.DES_PS_Product_Family__c = 'GTB';
            otmPS2.DES_PS_Product__c = product.Id;
        	listaDuplicados.add(otmPS2);
        	
        	DES_Opportunity_Management_member__c otm6 = utilTestClass.createOppManagementMember(userTest1, opp1);
        	otm6.DES_Opportunity_member_role__c = Label.DES_ROLE_LOCAL_BANKER;
        	otm6.DES_Scope__c = 'ES';
        	try{
        		insert listaDuplicados;
        		insert otm6;
        	}catch(Exception e){
        		system.debug('>>>>> ERROR AL INSERTAR');
        	}
        	
        	delete listaDuplicados;
        }
        
    }
}