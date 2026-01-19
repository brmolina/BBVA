/**
Name:           VisitsPieCntTest
Description:	Testeo de la clase VisitsPieCnt
Test Class:     VisitsPieCnt
*/
@isTest
public class VisitsPieCntTest {

	/* Instancia de utilTestClass */
    private static DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    /* constante de accGroup.Name utilizada */
    private final static String NAME = 'Grupo_Pie';

    /*
    * @author GlobalDesktop
    * @description Declaracion de variables
    */
    @testSetup
	public static void setupRows() { //NOSONAR
		//Accounts
        final Account accGroup = utilTestClass.createClient();
        accGroup.Name = NAME;
    	accGroup.DES_BBVA_Segmentation__c = 'B';
    	accGroup.DES_Structure_Type__c = 'Group';
    	accGroup.DES_Country_Client__c = 'ES';
    	insert accGroup;

    	final Opportunity oppAR = utilTestClass.createOpportunity(accGroup);
        oppAR.DES_Booking_Geography__c = 'AR';
        oppAR.DES_Product_Family__c = Label.DES_Template_GTB;
        oppAR.DES_Expected_Probability__c = 90;
        oppAR.StageName = Label.DES_Approvals;
        insert oppAR;

        final List<dwp_kitv__Visit__c> visitList = new List<dwp_kitv__Visit__c>();
        final dwp_kitv__Visit__c visTest = utilTestClass.createVisit(accGroup,oppAR);
        visTest.dwp_kitv__solution_name_path_desc__c = 'GTB';
        visTest.dwp_kitv__country_name__c = 'ES';
        visitList.add(visTest);
        final dwp_kitv__Visit__c visTest2 = utilTestClass.createVisit(accGroup,oppAR);
        visTest2.dwp_kitv__solution_name_path_desc__c = 'GTB;GM';
        visTest2.dwp_kitv__country_name__c = 'ES';
        visitList.add(visTest2);
        final dwp_kitv__Visit__c visTest3 = utilTestClass.createVisit(accGroup,oppAR);
        visTest3.dwp_kitv__country_name__c = 'ES';
        visitList.add(visTest3);
        insert visitList;

        final List<DES_Denorm_AccountVisits__c> denVisList = new List<DES_Denorm_AccountVisits__c>();
        final DES_Denorm_AccountVisits__c denVisTest = utilTestClass.createDenVisit(accGroup,visTest);
        denVisList.add(denVisTest);
        final DES_Denorm_AccountVisits__c denVisTest2 = utilTestClass.createDenVisit(accGroup,visTest2);
        denVisList.add(denVisTest2);
        final DES_Denorm_AccountVisits__c denVisTest3 = utilTestClass.createDenVisit(accGroup,visTest3);
        denVisList.add(denVisTest3);
        insert denVisList;

	}

	/*
    * @author GlobalDesktop
    * @description Testeo method 1
    */
	@isTest
	public static void testRelatedVisit() {
        final Account acc = [SELECT Id FROM Account WHERE Name = :NAME LIMIT 1];

        Test.startTest();

        // getData(String clientId, String family, String stageOption, Boolean byProduct, Boolean byCountryBooking, String countryClient)
        final String result = VisitsPieCnt.getData(acc.Id, true, false);
        final String result2 = VisitsPieCnt.getData(acc.Id, false, true);
        system.debug('++ result2 -> ' + result2);
		Boolean response = false;
        if(result != null) {
            response = true;
        }
        System.assert(response, 'caso 1 response ok');
    	Test.stopTest();
    }

    /*
    * @author GlobalDesktop
    * @description Testeo method 2
    */
	@isTest
	public static void testRelatedVisit2() {
        final Account acc = [SELECT Id FROM Account WHERE Name = :NAME LIMIT 1];

        Test.startTest();

        // getData(String clientId, String family, String stageOption, Boolean byProduct, Boolean byCountryBooking, String countryClient)
        final String result = VisitsPieCnt.getRowsData(acc.Id);
        final VisitsPieCnt instance = VisitsPieCnt.gtInstance();
        system.debug(instance);
		Boolean response = false;
        if(result != null) {
            response = true;
        }
        System.assert(response, 'caso 1 response ok');
    	Test.stopTest();
    }


}