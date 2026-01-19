@isTest
public class DES_NewOpportunityRedirectTest {
	
	@isTest
    public static void DES_NewOpportunityRedirectTest() {
        
        DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        String profileTest = utilTestClass.createProfile();
        User userTest1 = utilTestClass.createUser(profileTest);
       	insert userTest1;
        CIB_User_Org__c userSettings = utilTestClass.createCustomSetting();
        insert userSettings;
       
        system.runAs(userTest1){
        	
        	Test.startTest();
        	String dom = DES_NewOpportunityRedirect.getDomain();
        	Test.stopTest();
        	
        }
        
    }
}