@isTest
public class TotalAccountVisit_Test {

	@isTest
	public static void TotalAccountVisit_Test_method1() {
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
      	final Id accountGroupRT = [SELECT Id, DeveloperName FROM Recordtype WHERE DeveloperName = 'Group' Limit 1].Id;

		//Creacion grupo
		final Account accGroup = utilTestClass.createClient();
		insert accGroup;

    	final Opportunity oppAR = utilTestClass.createOpportunity(accGroup);
        oppAR.DES_Booking_Geography__c = 'AR';
        oppAR.DES_Product_Family__c = Label.DES_Template_GTB;
        oppAR.DES_Expected_Probability__c = 90;
        oppAR.StageName = Label.DES_Approvals;
        insert oppAR;

        final List<dwp_kitv__Visit__c> visitList = new List<dwp_kitv__Visit__c>();
        final dwp_kitv__Visit__c visTest = utilTestClass.createVisit(accGroup,oppAR);
        visTest.dwp_kitv__solution_name_path_desc__c = 'GTB';
        visTest.dwp_kitv__country_name__c = 'ES';
        visitList.add(visTest);
        final dwp_kitv__Visit__c visTest2 = utilTestClass.createVisit(accGroup,oppAR);
        visTest2.dwp_kitv__solution_name_path_desc__c = 'GTB;GM';
        visTest2.dwp_kitv__country_name__c = 'ES';
        visitList.add(visTest2);
        insert visitList;

        List<DES_Denorm_AccountVisits__c> denVisList = new List<DES_Denorm_AccountVisits__c>();
        final DES_Denorm_AccountVisits__c denVisTest = utilTestClass.createDenVisit(accGroup,visTest);
        denVisList.add(denVisTest);
        final DES_Denorm_AccountVisits__c denVisTest2 = utilTestClass.createDenVisit(accGroup,visTest2);
        denVisList.add(denVisTest2);
        insert denVisList;

        Test.startTest();
            delete visTest;
            delete denVisTest2;
        	denVisList = [SELECT id FROM DES_Denorm_AccountVisits__c WHERE id = :denVisTest2.id];
            System.assertEquals(denVisList.size(), 0, 'Error');
        Test.stopTest();
    }
}