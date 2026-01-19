@isTest
public class LOCAL_PERU_Test {
    static Account createClient(){
        Account acc = new Account();
        acc.Name = 'Test Client';
        return acc;
    }
    static OpportunityLineItem_Local__c createOpp(){
        OpportunityLineItem_Local__c opp = new OpportunityLineItem_Local__c();
        opp.Name = 'Test Opportunity';
        opp.Email__c = 'test@test.com';
        return opp;
    }
    
    @isTest
    static void localClientViewTest2(){
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      	
        system.runAs(userTest){
            Local_Client__c acc = TestFactory.createLocalClient();
            System.debug('><<<>>>>>>>>>>>>>>>>>>'+acc.Id);
            System.assertNotEquals(Local_Client_View_Controller.getLocalClient(acc.Cib_Client__c), null,'Error');
        }
    } 
     @isTest
    static void localClientViewTest(){
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      	
        system.runAs(userTest){
            Account acc = createClient();
            acc.DES_Country_Client__c = acc.Id;
            insert acc;
            System.assertEquals(Local_Client_View_Controller.getCountry(acc.Id), null,'Error');
        }
    } 
    @isTest
    static void opportunityLocalTest(){
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      	
        system.runAs(userTest){
            OpportunityLineItem_Local__c opp = createOpp();
            insert opp;
        	dwp_cvad__Action_Audit__c aud = new dwp_cvad__Action_Audit__c();
        	aud.dwp_cvad__action_audit_name__c = 'Test Audit';
            aud.dwp_cvad__action_audit_object_api_name__c = 'OpportunityLineItem_Local__c';
            aud.dwp_cvad__action_audit_record_id__c = opp.Id;
            aud.dwp_cvad__action_audit_style__c = 'approve';
            aud.dwp_cvad__action_audit_type__c = 'Risk Approval';
            aud.Local_Opportunity__c = opp.Id;
            insert aud;
            System.assertNotEquals(aud.Id, null,'Error');
        }
    } 
}