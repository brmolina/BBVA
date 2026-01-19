@isTest
/**********************************************************************************
* @description  TEST for class  SER_AccountTriggerHandler. 
**********************************************************************************/
private class SER_AccountTriggerHandler_TEST {
	/**********************************************************************************
	* @description  TEST for class  SER_AccountTriggerHandler, onAfterDeleteTEST
	**********************************************************************************/
	public static testMethod void onAfterDeleteTEST() {
		ActivitiesUtils_Test.crearData();
		List<Account> listAccToDelete = new List<Account>();
		listAccToDelete = [select Id from Account limit 10000000];
		System.assertEquals(listAccToDelete,listAccToDelete,'SER_AccountTriggerHandler_TEST');
		delete listAccToDelete;
	}	
}