/*
* @author Global Desktop
* @description Test de la clase RelatedAccOppInProgressCont
*/
@isTest
public class RelatedAccOppInProgressContTest {
	
	/*
	* @author Global Desktop
	* @description Testeo de la clase
	*/
  	@isTest
  	public static void accOppTest() {
	    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
	    list<Account> accList = new list<Account>();
	    final Account acc1 = utilTestClass.createClient();
	    accList.add(acc1);
	    final Account acc2 = utilTestClass.createClient();
	    accList.add(acc2);
	    insert accList;
	    System.assertNotEquals(acc1 ,acc2);
	    final Opportunity opp1 = utilTestClass.createOpportunity(acc2);
	    insert opp1;
	    final dwp_acmh__Denorm_Account_Opportunity__c oppDenorm = new dwp_acmh__Denorm_Account_Opportunity__c ();
	    oppDenorm.DES_Opportunity_Stage_Rollup__c = Label.DES_Proposal;
	    oppDenorm.dwp_acmh__AccountId__c = acc1.Id;
	    oppDenorm.dwp_acmh__OpportunityId__c = opp1.Id;
	    insert oppDenorm;
	    Test.StartTest();
	    RelatedAccOppInProgressController.getRelatedOpportunities('2',acc1.Id);
	    system.assertEquals(oppDenorm.DES_Opportunity_Stage_Rollup__c, Label.DES_Proposal, 'Correcto');
	    Test.StopTest();
  	}
}