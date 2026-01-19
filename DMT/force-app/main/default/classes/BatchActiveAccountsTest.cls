/*
 * @author	Global Desktop
 * @Description	Clase de test para la clase BatchActiveAccounts
 *
 */
@isTest
public with sharing class BatchActiveAccountsTest {
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
        padre.DES_Segment__c = '00005'; // Corporate
        padre.gf_prtcpt_act_status_ind_type__c = true;
		listaAcc.add(padre);
		final Account hijo = testClass.createClient();
		listaAcc.add(hijo);
		insert listaAcc;
		Test.startTest();
		final Id batchInstanceId = Database.executeBatch(new BatchActiveAccounts(), 8);
		Test.stopTest();
		system.debug('::::: batchInstanceId : ' + batchInstanceId);
		System.assertNotEquals(batchInstanceId, null);

	}

}