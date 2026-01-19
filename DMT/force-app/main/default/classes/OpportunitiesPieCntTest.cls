/**
Name:            OpportunitiesPieCntTest
Description:
Test Class:      OpportunitiesPieCnt
*/
@isTest
public with sharing class OpportunitiesPieCntTest {

    /* Instancia de utilTestClass */
    private static DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    /* constante de accGroup.Name utilizada */
    private final static String NAME = 'Grupo_Pie_ES';


    /*
        Test Setup: accounts - opp - product - pricebookEntry - Olis
    */
    @testSetup
	public static void setupRows() { //NOSONAR - testSetup
        //Accounts
        final Account accGroup = utilTestClass.createClient();
        	accGroup.Name = NAME;
        	accGroup.DES_BBVA_Segmentation__c = 'B';
        	accGroup.DES_Structure_Type__c = 'Group';
        	accGroup.DES_Country_Client__c = 'ES';
    	insert accGroup;

        //Opportunities
        final List<Opportunity> lstOpp = new List<Opportunity>();
        final Opportunity oppAR = utilTestClass.createOpportunity(accGroup);
            oppAR.DES_Booking_Geography__c = 'AR';
            oppAR.DES_Product_Family__c = Label.DES_Template_GTB;
            oppAR.DES_Expected_Probability__c = 90;
            oppAR.StageName = Label.DES_Approvals; //DES_Draft;
        lstOpp.add(oppAR);
        final Opportunity oppIT = utilTestClass.createOpportunity(accGroup);
            oppIT.DES_Booking_Geography__c = 'IT';
            oppIT.DES_Product_Family__c = 'GM';
            oppIT.DES_Expected_Probability__c = 90;
            oppIT.DES_Reasons_Lost__c = 'Pricing';
            oppIT.DES_Description_reason_for_lost_deal__c = 'test';
            oppIT.StageName = Label.DES_Closed_Lose;
            oppIT.opportunity_correct_ind_type__c = true;
        lstOpp.add(oppIT);
        final Opportunity oppMX = utilTestClass.createOpportunity(accGroup);
            oppMX.DES_Booking_Geography__c = 'MX';
            oppMX.DES_Product_Family__c = Label.DES_Template_GTB;
            oppMX.DES_Expected_Probability__c = 90;
            oppMX.StageName = Label.DES_Closed_Won;
            oppMX.opportunity_correct_ind_type__c = true;
        lstOpp.add(oppMX);

        insert lstOpp;

        //products
        final List<Product2> lstProds = new List<Product2>();
        final Product2 prod1 = utilTestClass.createProduct(Label.DES_Client_Resources);
        lstProds.add(prod1);
        final Product2 prod2 = utilTestClass.createProduct(Label.DES_Credit);
        lstProds.add(prod2);
        final Product2 prod3 = utilTestClass.createProduct(Label.DES_FX);
        lstProds.add(prod3);
        insert lstProds;

        //Pricebook entry
        final List<PricebookEntry> lstPBEntries= new List<PricebookEntry>();
        final PricebookEntry pb1 = utilTestClass.createPricebookEntry(prod1);
        lstPBEntries.add(pb1);
        final PricebookEntry pb2 = utilTestClass.createPricebookEntry(prod2);
        lstPBEntries.add(pb2);
        final PricebookEntry pb3 = utilTestClass.createPricebookEntry(prod3);
        lstPBEntries.add(pb3);
        insert lstPBEntries;

        //OpportunityLineItem
        final List<OpportunityLineItem> lstOlis = new List<OpportunityLineItem>();
        final OpportunityLineItem oli1 = utilTestClass.createOppLineItem(oppAR, prod1, pb1);
        // oli1.DES_Expected_Revenue__c => formula (pre_oppy_revenue_next_12m_amount__c * Opportunity.DES_Expected_Probability__c)
        oli1.pre_oppy_revenue_next_12m_amount__c = 50000;
        lstOlis.add(oli1);
        final OpportunityLineItem oli2 = utilTestClass.createOppLineItem(oppMX, prod1, pb1);
        oli2.pre_oppy_revenue_next_12m_amount__c = 70000;
        lstOlis.add(oli2);
        final OpportunityLineItem oli3 = utilTestClass.createOppLineItem(oppAR, prod2, pb2);
        oli3.pre_oppy_revenue_next_12m_amount__c = 60000;
        lstOlis.add(oli3);
        final OpportunityLineItem oli4 = utilTestClass.createOppLineItem(oppAR, prod2, pb2);
        oli4.pre_oppy_revenue_next_12m_amount__c = 80000;
        lstOlis.add(oli4);

        insert lstOlis;
    }
/**
*   @author: GlobalDesktop - APC
*   @Class: OpportunitiesPieCntTest
*   @Description:  Caso 1 - GTBAllByProductNoCountryAcc

*   @Versions:
        v1 - 2019/04/22 - Initial version
*/
	@isTest
	public static void testGTBAllByProductNoCountryAcc() {
        final Account acc = [SELECT Id FROM Account WHERE Name = :NAME LIMIT 1];

        Test.startTest();

        // getData(String clientId, String family, String stageOption, Boolean byProduct, Boolean byCountryBooking, String countryClient)
        final String result = OpportunitiesPieCnt.getData(acc.Id, Label.DES_Template_GTB, 'All', true, false, null);
		Boolean response = false;
        if(result != null) {
            response = true;
        }
        System.assert(response, 'caso 1 response ok');
    	Test.stopTest();
    }
/**
*   @author: GlobalDesktop - APC
*   @Class: OpportunitiesPieCntTest
*   @Description:  Caso 2 - GTBAllbyCountryBookingNoCountryAcc

*   @Versions:
        v1 - 2019/04/22 - Initial version
*/
	@isTest
	public static void testGTBAllbyCountryBookingNoCountryAcc() {
        final Account acc = [SELECT Id FROM Account WHERE Name = :NAME LIMIT 1];

        Test.startTest();

        final String result = OpportunitiesPieCnt.getData(acc.Id, Label.DES_Template_GTB, 'All', false, true, null);
		Boolean response = false;
        if(result != null) {
            response = true;
        }
        System.assert(response, 'caso 2 response ok');
    	Test.stopTest();
    }

/**
*   @author: GlobalDesktop - APC
*   @Class: OpportunitiesPieCntTest
*   @Description:  Caso 3 - testGTBAllByProduct

*   @Versions:
        v1 - 2019/04/22 - Initial version
*/
	@isTest
	public static void testGTBAllByProduct() {
        final Account acc = [SELECT Id FROM Account WHERE Name = :NAME LIMIT 1];

        Test.startTest();

        // getData(String clientId, String family, String stageOption, Boolean byProduct, Boolean byCountryBooking, String countryClient)
        final String result = OpportunitiesPieCnt.getData(acc.Id, Label.DES_Template_GTB, 'All', true, false, 'ES');
		Boolean response = false;
        if(result != null) {
            response = true;
        }
        System.assert(response, 'caso 3 response ok');
    	Test.stopTest();
    }
/**
*   @author: GlobalDesktop - APC
*   @Class: OpportunitiesPieCntTest
*   @Description:  Caso 4 - testGTBAllbyCountryBooking

*   @Versions:
        v1 - 2019/04/22 - Initial version
*/
	@isTest
	public static void testGTBAllbyCountryBooking() {
        final Account acc = [SELECT Id FROM Account WHERE Name = :NAME LIMIT 1];

        Test.startTest();

        final String result = OpportunitiesPieCnt.getData(acc.Id, Label.DES_Template_GTB, 'All', false, true, 'ES');
		Boolean response = false;
        if(result != null) {
            response = true;
        }
        System.assert(response, 'caso 4 response ok');
    	Test.stopTest();
    }
/**
*   @author: GlobalDesktop - APC
*   @Class: OpportunitiesPieCntTest
*   @Description:  Caso 5 - testGTBLivebyCountryBooking

*   @Versions:
        v1 - 2019/04/22 - Initial version
*/
	@isTest
	public static void testGTBLivebyCountryBooking() {
        final Account acc = [SELECT Id FROM Account WHERE Name = :NAME LIMIT 1];

        Test.startTest();

        final String result = OpportunitiesPieCnt.getData(acc.Id, Label.DES_Template_GTB, 'Live', false, true, 'ES');
		Boolean response = false;
        if(result != null) {
            response = true;
        }
        System.assert(response, 'caso 5 response ok');
    	Test.stopTest();
    }
/**
*   @author: GlobalDesktop - APC
*   @Class: OpportunitiesPieCntTest
*   @Description:  Caso 6 - GTBWonbyCountryBooking

*   @Versions:
        v1 - 2019/04/22 - Initial version
*/
	@isTest
	public static void testGTBWonbyProduct() {
        final Account acc = [SELECT Id FROM Account WHERE Name = :NAME LIMIT 1];

        Test.startTest();

        final String result = OpportunitiesPieCnt.getData(acc.Id, Label.DES_Template_GTB, 'Won', true, false, 'IT');
		Boolean response = false;
        if(result != null) {
            response = true;
        }
        System.assert(response, 'caso 6 response ok');
    	Test.stopTest();
    }
/**
*   @author: GlobalDesktop - APC
*   @Class: OpportunitiesPieCntTest
*   @Description:  Caso 7 - GTBLostbyCountryBooking

*   @Versions:
        v1 - 2019/04/22 - Initial version
*/
	@isTest
	public static void testGTBLostbyCountryBooking() {
        final Account acc = [SELECT Id FROM Account WHERE Name = :NAME LIMIT 1];

        Test.startTest();

        final String result = OpportunitiesPieCnt.getData(acc.Id, Label.DES_Template_GTB, 'Lost', false, true, 'IT');
		Boolean response = false;
        if(result != null) {
            response = true;
        }
        System.assert(response, 'caso 7 response ok');
    	Test.stopTest();
    }
/**
*   @author: GlobalDesktop - APC
*   @Class: OpportunitiesPieCntTest
*   @Description:  Caso 8 - GTBWonbyCountryBooking

*   @Versions:
        v1 - 2019/04/22 - Initial version
*/
	@isTest
	public static void getTableGTBWon() {
        final Account acc = [SELECT Id FROM Account WHERE Name = :NAME LIMIT 1];

        Test.startTest();
        //String clientId, String family, String stageOption, String countryClient
        final String result = OpportunitiesPieCnt.getRowsData(acc.Id, Label.DES_Template_GTB, 'Won', 'ES');
		Boolean response = false;
        if(result != null) {
            response = true;
        }
        System.assert(response, 'caso 8 response ok');
    	Test.stopTest();
    }
}