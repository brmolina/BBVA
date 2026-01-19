@isTest
/*
 *  Global Desktop
 *
 */
public class ContactTerritoryBatchTest {

	@isTest
    /*
		*	Global Desktop
		*
		*/
		static void testTrigger() {

    	final DES_UtilTestClass testClass = new DES_UtilTestClass();

    	final List<Account> listaAcc = new List<Account>();
    	Account padre;
			padre = testClass.createClient();
    	padre.DES_Country_Client__c = 'ES';
    	padre.DES_Segment__c = '00005'; // Corporate
    	listaAcc.add(padre);
    	insert listaAcc;
    	Contact con;
			con = testClass.createContact(padre);
    	insert con;
    	final Id batchInstanceId = Database.executeBatch(new ContactTerritoryBatch(), 8); //NOSONAR
			Test.startTest();
			final Id batchInstance2Id = Database.executeBatch(new ContactTerritoryDeleteBatch(true), 8); //NOSONAR
			Test.stopTest();
			System.assertNotEquals(batchInstance2Id, null);

    }
		@isTest
		/*
		*	Global Desktop
		*
		*/
    static void testBatchContactTerritoryDeleteBatch2() {

    	final DES_UtilTestClass testClass = new DES_UtilTestClass();

    	final List<Account> listaAcc = new List<Account>();
			final String idProfile = testClass.createProfile();
			final User userTest = testClass.createUser(idProfile);
			insert userTest;
			final CIB_User_Org__c userSettings = testClass.createCustomSetting();
			insert userSettings;
			Account padre;
			padre = testClass.createClient();
    	padre.DES_Country_Client__c = 'ES';
    	padre.DES_Segment__c = '00005'; // Corporate
    	listaAcc.add(padre);
    	insert listaAcc;
    	Contact con;
			con = testClass.createContact(padre);
    	insert con;
			final ContactShare conShare = new ContactShare();
			conShare.ContactId = con.Id;
			conShare.RowCause = 'Manual';
			conShare.UserOrGroupId =  userTest.Id;
			conShare.ContactAccessLevel = 'Edit';
			insert conShare;

			Test.startTest();
			final Id batchInstance2Id = Database.executeBatch(new ContactTerritoryDeleteBatch(false), 8);
			Test.stopTest();
			System.assertNotEquals(batchInstance2Id, null);

    }

}