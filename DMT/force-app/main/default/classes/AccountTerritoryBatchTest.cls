@isTest
/*
	*	@author		Global Desktop
	*	@desc			testTrigger method
	*
**/
public class AccountTerritoryBatchTest {

	@isTest
	/*
	 *	@author		Global Desktop
	 *	@desc			testTrigger method
	 *
	**/
	public static void testTrigger() {

		final DES_UtilTestClass testClass = new DES_UtilTestClass();
		final List<Account> listaAcc = new List<Account>();
		final Account padre = testClass.createClient();
		padre.DES_Country_Client__c = 'ES';
		padre.DES_Segment__c = '00005'; //Corporate
		listaAcc.add(padre);
		final Account hijo = testClass.createClient();
		listaAcc.add(hijo);
		insert listaAcc;
		Test.startTest();
		final Id batchInstanceId = Database.executeBatch(new AccountTerritoryBatch(), 8);
		Test.stopTest();
		final Id batch2InstanceId = Database.executeBatch(new AccountTerritoryDeleteBatch(), 8);
		system.debug('::::: batchInstanceId : ' + batchInstanceId);
		system.debug('::::: batch2InstanceId : ' + batch2InstanceId);
		System.assertNotEquals(batch2InstanceId, null);

	}

}