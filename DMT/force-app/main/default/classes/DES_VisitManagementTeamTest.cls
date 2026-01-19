/**
*
* @author Global Desktop
*/
@isTest
public class DES_VisitManagementTeamTest {
    /**
     * Test que crea una visita y un equipo de gestión de la visita.
     * Después borra el equipo y comprueba que la visita sigue existiendo.
     */
    @isTest
    public static void deleteOpportunityManagementMemberTest(){
        // Datos necesarios
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final String profileTest = utilTestClass.createProfile();
        final User userTest = utilTestClass.createUser(profileTest);
        insert userTest;
        final Account acc = utilTestClass.createClient();
        insert acc;
        Test.startTest();
        final List<DES_BBVA_Management_team__c> listaBBVAMT = new List<DES_BBVA_Management_team__c>();
        final DES_BBVA_Management_team__c bbvaMngmntTeam1 = utilTestClass.createBBVAManagementTeamMember(userTest, acc);
        bbvaMngmntTeam1.DES_Local_Banker_Country__c = 'ES';
        bbvaMngmntTeam1.DES_Member_Role__c = Label.DES_ROLE_INDUSTRY_HEAD;
        listaBBVAMT.add(bbvaMngmntTeam1);
        insert listaBBVAMT;

		final dwp_kitv__Visit__c visit1 = utilTestClass.createVisit(acc, null);
		insert visit1;
		final dwp_kitv__Visit__c visit2 = utilTestClass.createVisit(acc, null);
		visit2.RecordTypeId = Schema.SObjectType.dwp_kitv__Visit__c.getRecordTypeInfosByName().get('LeadVisit').getRecordTypeId();
		insert visit2;
		Test.stopTest();

		final dwp_kitv__Visit_Management_Team__c visitTM = utilTestClass.createVisitTM(userTest, visit1);
		insert visitTM;

        delete visitTM;
        System.assertNotEquals(visit1, null);


    }

    /**
     * Test que crea una visita y un equipo de gestión de la visita.
     * Después borra el equipo y comprueba no existe.
     */
    @isTest
	public static void deletionParticipant(){
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

        //Acc
        final Account acc = utilTestClass.createClient();
        	acc.Name = 'TestOK';
    	insert acc;
 		//Opportunity
 		final Opportunity opp = utilTestClass.createOpportunity(acc);
 		insert opp;
	    //Visitas dwp_kitv__Visit__c
	    final List<dwp_kitv__Visit__c> lstVisitas = new List<dwp_kitv__Visit__c>();
	    //'R.EUROPA','RESTO LATAM'
	    final List<String> lstLabelsRegiones = new List<String>{Label.RegionAmesur, Label.RegionAsia, Label.RegionEEUU,
	    						Label.RegionSpain, Label.RegionMexico, Label.RegionEuropa, Label.RegionRestoLatam};
	    for(Integer i = 0; i < lstLabelsRegiones.size(); i++){
	    	final dwp_kitv__Visit__c visita = utilTestClass.createVisit(acc, opp);
			visita.disclosure_info_type__c = Label.DES_OP_Inside;
/*	    		visita.region_name__c = lstLabelsRegiones[i];
                visita.country_name__c = 'AR'; //NOSONAR
	    		visita.solution_name_path_desc__c = 'GTB'; //lo rellenará el trigger, añadido 1 con valor anterior para cubrir más code*/
	    	lstVisitas.add(visita);
	    }
	    insert lstVisitas;
	    //System.debug('::::lstVisitas ' + lstVisitas);
	    //profiles
	    final Set<Profile> setProfilesId = new Set<Profile>([SELECT Id, Name FROM Profile
	    					WHERE Name IN ('BBVA Desktop GCC Standard', 'BBVA Desktop GTB Standard', 'BBVA Desktop GM Business Development',
	    									'BBVA Desktop IBF Standard', 'BBVA Desktop CIB Management')]);
	    System.debug(':::::setProfilesId : ' + setProfilesId);
	    //users
	    final List<User> lstUser = new List<User>();
	    for(Profile profile : setProfilesId){
	    	final String username = profile.Id + '@acme.com';
	    	final User user = utilTestClass.createUser(profile.Id, username);
		    lstUser.add(user);
	    }
	    System.debug(':::::lstUser : ' + lstUser);
	    insert lstUser;
	    //dwp_kitv__Visit_Management_Team__c participantes
		final DES_BBVA_Management_team__c bbvaTeam = new DES_BBVA_Management_team__c();
		bbvaTeam.DES_Client__c = lstVisitas[0].dwp_kitv__account_id__c;
		bbvaTeam.DES_User__c = lstUser[0].Id;
		insert bbvaTeam;
        Test.startTest();
	    final List<dwp_kitv__Visit_Management_Team__c> lstPart = new List<dwp_kitv__Visit_Management_Team__c>();
	    for(User user : lstUser){
	    	final dwp_kitv__Visit_Management_Team__c part = utilTestClass.createVisitManagementTeam(lstVisitas[0], user);
	    		part.dwp_kitv__user_id__c = user.Id; //user
	    		part.dwp_kitv__visit_id__c = lstVisitas[0].Id; // visit
	    	lstPart.add(part);
	    }
	    insert lstPart;
	    //DES_VisitManagementTeam_TriggerHandler.updateFamiliesOnVisit(lstPart, false); //tras participantes correrá ese mét0d0
	    //denorm AccVisit
	    final DES_Denorm_AccountVisits__c denAV = utilTestClass.createDenVisit(acc, lstVisitas[0]);
	    insert denAV;
		final List<dwp_kitv__Visit_Management_Team__c> part = [SELECT Id, IsDeleted FROM dwp_kitv__Visit_Management_Team__c WHERE dwp_kitv__visit_id__r.dwp_kitv__account_id__c = :acc.Id LIMIT 1];
		System.debug(':::::dwp_kitv__Visit_Management_Team__c a testear: ' + part[0]);
		//pasará por DES_VisitManagementTeam_TriggerHandler.updateFamiliesOnVisit(part, true);
		Database.delete(part[0]);
		final List<dwp_kitv__Visit_Management_Team__c> partAfter = [SELECT Id, IsDeleted FROM dwp_kitv__Visit_Management_Team__c WHERE Id = :part[0].Id];
		System.assert(partAfter.isEmpty(), 'partAfter is not empty');
		Test.stopTest();
	}

}