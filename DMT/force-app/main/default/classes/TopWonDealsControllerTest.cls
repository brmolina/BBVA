@isTest
public class TopWonDealsControllerTest {

	/**
	* @author Global Desktop
	* @description Test de la clase FamilyProductCards_Controller
	*/
  	@isTest
  	public static void TopWonDealsController() {
  		final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

  		final id accountGroupRT = [SELECT id, DeveloperName FROM Recordtype WHERE DeveloperName = 'Group' AND SobjectType ='Account' Limit 1 ].Id;

	    //Creacion grupo
		final Account accGroup = utilTestClass.createClient();
	    accGroup.RecordTypeId = accountGroupRT;
	    accGroup.DES_Structure_Type__c = 'Group';
	    accGroup.DES_BBVA_Segmentation__c = 'C';
	    accGroup.DES_Country_Client__c = 'ES';
		insert accGroup;

	    final Account acc1 = utilTestClass.createClient();
	    acc1.DES_Main_Parent__c = accGroup.Id;
	    insert acc1;

		final DES_TopWonDeals__c topWonDeals1 = utilTestClass.createAggregatedTopWonDeals(acc1,accGroup);
		final List <DES_TopWonDeals__c> listTopWon = new List<DES_TopWonDeals__c>();
		listTopWon.add(topWonDeals1);
	    insert topWonDeals1;

	    Test.StartTest();
	    final String resRelFranchise = TopWonDealsController.getTopWonDeals('2',accGroup.Id,null);
	    final Integer resNumbFranchise = TopWonDealsController.getNumberDeals(accGroup.Id);
	    System.assertNotEquals(accGroup,null);
		Test.StopTest();

		final Integer dealsNumber = listTopWon.size();

		final List<TopWonDealsController.wrapperClass> listWrapperClass = new List<TopWonDealsController.wrapperClass>();
		for(DES_TopWonDeals__c iDeals :listTopWon) {
			listWrapperClass.add(new TopWonDealsController.wrapperClass(iDeals, dealsNumber));
		}
  	}

}