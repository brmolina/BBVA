/**
*
* @author: Global Desktop
*/
@isTest
private class NameRelatedListOverTest {
	
	@isTest static void NameRelatedListOverTest() {

		DES_UtilTestClass testClass = new DES_UtilTestClass();

		Account newAcc = testClass.createClient();
		insert newAcc;
		Opportunity newOpp = testClass.createOpportunity(newAcc);
		insert newOpp;
		dwp_kitv__Visit__c newVisit = testClass.createVisit(newAcc,newOpp);
		insert newVisit;
		NBC__c newNbc = testClass.createNBC();
		insert newNbc;
		newVisit.Committee_id__c = newNbc.Id;
		update newVisit;

		test.startTest();
			String result = NameRelatedListOver.checkNBC(newVisit.id);
			System.assertEquals(result,'true', 'checkNBC = true');

		test.stopTest();
	}
	

}