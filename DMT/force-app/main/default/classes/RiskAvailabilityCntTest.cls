/**
Name:            OpportunitiesPieCntTest
Description:
Test Class:      OpportunitiesPieCnt
*/
@isTest
public with sharing class RiskAvailabilityCntTest {

    /* Instancia de utilTestClass */
    private static DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    /* constante de accGroup.Name utilizada */
    private final static String NAME = 'Grupo_Risk_ES';


    /*
        Test Setup: account - consumo de linea
    */
    @testSetup
	public static void setupRows() { //NOSONAR - testSetup
        //Account - GROUP
        final Account accGroup = utilTestClass.createClient();
        	accGroup.Name = NAME;
        	accGroup.DES_BBVA_Segmentation__c = 'B';
        	accGroup.DES_Structure_Type__c = 'Group';
        	accGroup.DES_Country_Client__c = 'ES';
    	insert accGroup;

        //Rows Consumo_de_Linea__c
        List<Consumo_de_Linea__c> lstConsumos = new List<Consumo_de_Linea__c>();
        Consumo_de_Linea__c row1 = new Consumo_de_Linea__c();
            row1.business_group_id__c = accGroup.Id;
            row1.credit_drawn_amount__c = Decimal.valueOf('35000');
            row1.credit_limit_amount__c = Decimal.valueOf('45000');
            row1.deposits_drawn_amount__c = Decimal.valueOf('35000');
            row1.deposits_limit_amount__c = Decimal.valueOf('55000');
            row1.delivery_vs_pay_drawn_amount__c = Decimal.valueOf('15000');
            row1.delivery_vs_pay_limit_amount__c = Decimal.valueOf('35000');
            row1.repos_drawn_amount__c = Decimal.valueOf('65000');
            row1.repos_limit_amount__c = Decimal.valueOf('85000');
            row1.settlement_drawn_amount__c = Decimal.valueOf('65000');
            row1.settlement_limit_amount__c = Decimal.valueOf('95000');
            row1.derivatives_limit_amount__c = Decimal.valueOf('85000');
            row1.derivatives_drawn_amount__c = Decimal.valueOf('95000');
            row1.tenor_desc__c = 'Tenor1';
            row1.operation_date__c = Date.valueOf('2019-04-21');
        lstConsumos.add(row1);
        Consumo_de_Linea__c row2 = new Consumo_de_Linea__c();
            row2.business_group_id__c = accGroup.Id;
            row2.credit_drawn_amount__c = Decimal.valueOf('30000');
            row2.credit_limit_amount__c = Decimal.valueOf('40000');
            row2.deposits_drawn_amount__c = Decimal.valueOf('30000');
            row2.deposits_limit_amount__c = Decimal.valueOf('60000');
            row2.delivery_vs_pay_drawn_amount__c = Decimal.valueOf('10000');
            row2.delivery_vs_pay_limit_amount__c = Decimal.valueOf('30000');
            row2.repos_drawn_amount__c = Decimal.valueOf('60000');
            row2.repos_limit_amount__c = Decimal.valueOf('80000');
            row2.settlement_drawn_amount__c = Decimal.valueOf('60000');
            row2.settlement_limit_amount__c = Decimal.valueOf('90000');
            row2.derivatives_limit_amount__c = Decimal.valueOf('80000');
            row2.derivatives_drawn_amount__c = Decimal.valueOf('90000');
            row2.tenor_desc__c = 'Tenor2';
            row2.operation_date__c = Date.valueOf('2019-04-22');
        lstConsumos.add(row2);

        insert lstConsumos;
    }
    /**
    *   @author: GlobalDesktop - APC
    *   @Class: RiskAvailabilityCntTest
    *   @Description:  Caso 01 - Credit

    *   @Versions:
            v1 - 2019/04/26 - Initial version
    */
	@isTest
	public static void case01Credit() {
        final Account acc = [SELECT Id FROM Account WHERE Name = :NAME LIMIT 1];

        Test.startTest();


        final String result = RiskAvailabilityCnt.getData(acc.Id, 'Credit');
		Boolean response = false;
        if(result != null) {
            response = true;
        }
        System.assert(response, 'caso Credit ok');
    	Test.stopTest();
    }
    /**
    *   @author: GlobalDesktop - APC
    *   @Class: RiskAvailabilityCntTest
    *   @Description:  Caso 2 - Derivatives

    *   @Versions:
            v1 - 2019/04/26 - Initial version
    */
	@isTest
	public static void case02Derivatives() {
        final Account acc = [SELECT Id FROM Account WHERE Name = :NAME LIMIT 1];

        Test.startTest();


        final String result = RiskAvailabilityCnt.getData(acc.Id, 'Derivatives');
		Boolean response = false;
        if(result != null) {
            response = true;
        }
        System.assert(response, 'caso Derivatives ok');
    	Test.stopTest();
    }
    /**
    *   @author: GlobalDesktop - APC
    *   @Class: RiskAvailabilityCntTest
    *   @Description:  Caso 3 - Deposits

    *   @Versions:
            v1 - 2019/04/26 - Initial version
    */
	@isTest
	public static void case03Deposits() {
        final Account acc = [SELECT Id FROM Account WHERE Name = :NAME LIMIT 1];

        Test.startTest();


        final String result = RiskAvailabilityCnt.getData(acc.Id, 'Deposits');
		Boolean response = false;
        if(result != null) {
            response = true;
        }
        System.assert(response, 'caso Deposits ok');
    	Test.stopTest();
    }
    /**
    *   @author: GlobalDesktop - APC
    *   @Class: RiskAvailabilityCntTest
    *   @Description:  Caso 4 - Repos

    *   @Versions:
            v1 - 2019/04/26 - Initial version
    */
	@isTest
	public static void case04Repos() {
        final Account acc = [SELECT Id FROM Account WHERE Name = :NAME LIMIT 1];

        Test.startTest();


        final String result = RiskAvailabilityCnt.getData(acc.Id, 'Repos');
		Boolean response = false;
        if(result != null) {
            response = true;
        }
        System.assert(response, 'caso Repos ok');
    	Test.stopTest();
    }
    /**
    *   @author: GlobalDesktop - APC
    *   @Class: RiskAvailabilityCntTest
    *   @Description:  Caso 5 - DVP/other

    *   @Versions:
            v1 - 2019/04/26 - Initial version
    */
	@isTest
	public static void caso05DVP() {
        final Account acc = [SELECT Id FROM Account WHERE Name = :NAME LIMIT 1];

        Test.startTest();


        final String result = RiskAvailabilityCnt.getData(acc.Id, 'DVP');
		Boolean response = false;
        if(result != null) {
            response = true;
        }
        System.assert(response, 'caso DVP/other ok');
    	Test.stopTest();
    }
}