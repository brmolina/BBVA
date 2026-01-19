@isTest
public class DES_FranchiseAccordion_ControllerTest {
	
	@isTest
    public static void DES_FranchiseAccordion_ControllerTest() {
        
        DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        String profileTest = utilTestClass.createProfile();
        User userTest1 = utilTestClass.createUser(profileTest);
       	insert userTest1;
        CIB_User_Org__c userSettings = utilTestClass.createCustomSetting();
        insert userSettings;
       
        system.runAs(userTest1){
        	Account acc = utilTestClass.createClient();
        	insert acc;
        	Test.startTest();
        	List<DES_Franchises__c> listaFranchises = DES_FranchiseAccordion_Controller.returnFracnhise((String)acc.Id);
        	Test.stopTest();
        	
        }
        
    }
}