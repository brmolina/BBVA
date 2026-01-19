@isTest
public class DES_PlanVisitController_PCTest {
	
	@isTest
    public static void DES_PlanVisitController_PCTest() {
        
        DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        String profileTest = utilTestClass.createProfile();
        User userTest1 = utilTestClass.createUser(profileTest);
       	insert userTest1;
        CIB_User_Org__c userSettings = utilTestClass.createCustomSetting();
        insert userSettings;
       
        system.runAs(userTest1){
        	
        	Test.startTest();
        	//PageReference pr = DES_PlanVisitController_PC.getFinishPage();
        	Test.stopTest();
        	
        }
        
    }
}