@isTest
public class DES_visitRedirectControllerTest {

    @isTest
	public static void DES_visitRedirectControllerTest(){
        DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        String profileTest = utilTestClass.createProfile();
        User userTest1 = utilTestClass.createUser(profileTest);
       	insert userTest1;
        CIB_User_Org__c userSettings = utilTestClass.createCustomSetting();
        insert userSettings;
       
        system.runAs(userTest1){
                	
        	//GENERO UN CLIENTE
        	Account acc1 = utilTestClass.createClient();
        	insert acc1;
			Test.startTest();
			dwp_kitv__Visit__c visit = utilTestClass.createVisit(acc1, null);
			insert visit;
			DES_Denorm_AccountVisits__c denAccVisit = new DES_Denorm_AccountVisits__c(); 
			denAccVisit.DES_Client__c = acc1.Id;
			denAccVisit.DES_Visit_new__c = visit.Id;
			insert denAccVisit;
			//Inform Test Class to set current page as your Page where Extension is used
			//Instantiate object of "ApexPages.StandardController" by passing object
			//PageReference pageRef = Page.DES_visitRedirect;
            //Test.setCurrentPage(pageRef);
            //pageRef.getParameters().put('Id', String.valueOf(denAccVisit.Id));
            Final ApexPages.StandardController scon = new ApexPages.StandardController(denAccVisit);
            Final DES_visitRedirectController testAccPlan = new DES_visitRedirectController(scon);
			DES_visitRedirectController.getInstance();
			system.assertNotEquals(testAccPlan,null,'Error');
			Test.stopTest();
			   
		}
		
	}
}