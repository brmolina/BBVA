/*************************************************************************************************************************
Name:             VisitsByRegionAndProductsYTDcntTest
Description:     Apex controller of VisitsByRegionAndProductsYTD Lightning component

Version        Date            Author            Summary of changes
------------------------------------------------------------------------------------------------------------------------
0.1            14/11/2018      Global Desktop    Test de la clase  VisitsByRegionAndProductsYTDcnt
*************************************************************************************************************************/
@isTest
public class VisitsByRegionAndProductsYTDcntTest {

	/* Declarando variable */
	final private static DES_UtilTestClass UTILTESTCLASS = new DES_UtilTestClass();

	/**
	* @author Global Desktop
	* @description Declaracion de variables
	*/
	@testSetup
	public static void setupRows() {
        final Account acc = UTILTESTCLASS.createClient();
    	acc.Name = 'TestOK';
    	insert acc;
 		final Opportunity opp = UTILTESTCLASS.createOpportunity(acc);
 		insert opp;
        Test.startTest();
	    final List<dwp_kitv__Visit__c> lstVisitas = new List<dwp_kitv__Visit__c>();
	    final List<String> lstLabelsRegiones = new List<String>{Label.RegionAmesur, Label.RegionAsia, Label.RegionEEUU,
	    						Label.RegionSpain, Label.RegionMexico, Label.RegionEuropa, Label.RegionRestoLatam};
	    for(Integer i = 0; i < lstLabelsRegiones.size(); i++) {
	    	dwp_kitv__Visit__c visita;
	    	visita = UTILTESTCLASS.createVisit(acc, opp);
    		visita.dwp_kitv__region_name__c = lstLabelsRegiones[i];
            visita.dwp_kitv__country_name__c = 'AR';
    		visita.dwp_kitv__solution_name_path_desc__c = 'GTB';
	    	lstVisitas.add(visita);
	    }
	    insert lstVisitas;
        Test.stopTest();
	    final Set<Profile> setProfilesId = new Set<Profile>([SELECT Id, Name FROM Profile
	    					WHERE Name IN ('BBVA Desktop GCC Standard', 'BBVA Desktop GTB Standard', 'BBVA Desktop GM Business Development',
	    									'BBVA Desktop IBF Standard', 'BBVA Desktop CIB Management')]);
	    final List<User> lstUser = new List<User>();
	    for(Profile profile : setProfilesId) {
	    	final String username = profile.Id + '@acme.com';
	    	User user;
	    	user = UTILTESTCLASS.createUser(profile.Id, username);
		    lstUser.add(user);
	    }
	    insert lstUser;
	    final List<dwp_kitv__Visit_Management_Team__c> lstPart = new List<dwp_kitv__Visit_Management_Team__c>();
	    for(User user : lstUser) {
	    	dwp_kitv__Visit_Management_Team__c part;
	    	part = UTILTESTCLASS.createVisitManagementTeam(lstVisitas[0], user);
    		part.dwp_kitv__user_id__c = user.Id; //user
    		part.dwp_kitv__visit_id__c = lstVisitas[0].Id; // visit
	    	lstPart.add(part);
	    }
	    insert lstPart;
	    final DES_Denorm_AccountVisits__c denAV = UTILTESTCLASS.createDenVisit(acc, lstVisitas[0]);
	    insert denAV;
    }

    /**
	* @author Global Desktop
	* @description Method 1 Test
	*/
	@isTest
	public static void responseDataOK() {
		Boolean devuelveJSON = false;
		final Account acc = [SELECT Id FROM Account WHERE Name = 'TestOK'];
    	Test.startTest();
		final String response = VisitsByRegionAndProductsYTDcnt.getData(acc.Id);
    	Test.stopTest();
    	if(response != null) {
			devuelveJSON = true;
		}
    	System.assertEquals(devuelveJSON, true, 'Assert Message');

	}

	/**
	* @author Global Desktop
	* @description Method 2 Test
	*/
	@isTest
	public static void responseRowsDataOK() {
		Boolean devuelveJSON = false;

    	final Account acc = [SELECT Id FROM Account WHERE Name = 'TestOK'];
    	Test.startTest();
		final String response = VisitsByRegionAndProductsYTDcnt.getRowsData(acc.Id);
    	Test.stopTest();
    	if(response != null) {
			devuelveJSON = true;
		}
    	System.assertEquals(devuelveJSON, true, 'Assert message');
	}

	/**
	* @author Global Desktop
	* @description Method 3 Test
	*/
	@isTest
	public static void deletionParticipant() {
		final Account acc = [SELECT Id FROM Account WHERE Name = 'TestOK'];
		final List<dwp_kitv__Visit_Management_Team__c> part = [SELECT Id, IsDeleted FROM dwp_kitv__Visit_Management_Team__c WHERE dwp_kitv__visit_id__r.dwp_kitv__account_id__c = :acc.Id LIMIT 1];
    	Test.startTest();
		Database.delete(part[0]);
		final List<dwp_kitv__Visit_Management_Team__c> partAfter = [SELECT Id, IsDeleted FROM dwp_kitv__Visit_Management_Team__c WHERE Id = :part[0].Id];
		Test.stopTest();
    	System.assertEquals(partAfter.isEmpty(), true, 'Assert message');
	}
}