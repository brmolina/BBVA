@isTest
public class DES_Redirect_Visit_ControllerTest {
	
	@isTest
	public static void DES_Redirect_Visit_ControllerTest() {
		
		DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
		String profileTest = utilTestClass.createProfile();
		User userTest1 = utilTestClass.createUser(profileTest);
		insert userTest1;
		CIB_User_Org__c userSettings = utilTestClass.createCustomSetting();
		insert userSettings;
		system.runAs(userTest1){
			Test.startTest();
			List<Account> listaCuentas = new List<Account>();
			Account acc1 = utilTestClass.createClient();
			Account acc2 = utilTestClass.createClient();
			acc2.Name = 'Cuenta Test 2';
			listaCuentas.add(acc1);
			listaCuentas.add(acc2);
			insert listaCuentas; 
			dwp_acmh__GBL_Account_Relationship__c rel = utilTestClass.createAccRelationship(listaCuentas.get(0), listaCuentas.get(1));
			insert rel;
			dwp_kitv__Visit__c visit = utilTestClass.createVisit(listaCuentas.get(1), null);
			insert visit;
			DES_Denorm_AccountVisits__c denVis = utilTestClass.createDenVisit(listaCuentas.get(0), visit);
			insert denVis;
			DES_Redirect_Visit_Controller.visitRedirect((String)denVis.Id);
			Test.stopTest();
			
		}
		
	}
}