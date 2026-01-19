@isTest
public class DES_DenormAccountVisitsTriggerTest {

	@isTest
	public static void DES_DenormAccountVisitsTriggerTest() {

		DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
		String profileTest = utilTestClass.createProfile();
		User userTest1 = utilTestClass.createUser(profileTest);
		insert userTest1;
		CIB_User_Org__c userSettings = utilTestClass.createCustomSetting();
		insert userSettings;

		system.runAs(userTest1) {
			Test.startTest();
			List<Account> listaCuentas = new List<Account>();
        	//GENERO UN CLIENTE
        	Account acc1 = utilTestClass.createClient();
        	listaCuentas.add(acc1);
        	Account acc2 = utilTestClass.createClient();
        	acc2.Name = 'Client Test 2';
        	listaCuentas.add(acc2);
        	insert listaCuentas;

        	dwp_acmh__GBL_Account_Relationship__c accRel1 = new dwp_acmh__GBL_Account_Relationship__c();
        	accRel1.dwp_acmh__Child_Account__c = listaCuentas.get(0).Id;
        	accRel1.dwp_acmh__Parent_Account__c = listaCuentas.get(1).Id;
        	accRel1.dwp_acmh__Type__c = '3'; // Subgroup
        	accRel1.dwp_acmh__Vision__c = 'Negocio';
        	insert accRel1;

        	dwp_kitv__Visit__c visit1 = utilTestClass.createVisit(listaCuentas.get(0), null);
			insert visit1;

        	DES_Denorm_AccountVisits__c denAcVisit = new DES_Denorm_AccountVisits__c();
        	denAcVisit.DES_Client__c = listaCuentas.get(0).Id;
        	//denAcVisit.DES_Country__c = 'Spain';
        	denAcVisit.DES_Visit_new__c = visit1.Id;
        	insert denAcVisit;

			final Id batchJobId = Database.executeBatch(new Batch_Total_Visit_YTD(), 200);
			system.debug('++ batchJobId' + batchJobId);

        	delete denAcVisit;
			System.assertEquals(acc2.Name,'Client Test 2','Error');

			Test.stopTest();

		}

	}
}