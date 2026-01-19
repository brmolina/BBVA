/**
* ------------------------------------------------------------------------------------------------
* @Name     HPG_SecondaryTablesController_Test
* @Author   Global Hub
* @Date     Created: 2023-09-07
* ------------------------------------------------------------------------------------------------
* @Description Test class for HPG_SecondaryTablesController and HPG_ConsumptionSummary
* ------------------------------------------------------------------------------------------------
* @Changes
*
* | 2023-09-07 ivan.garces.contractor@bbva.com
*             Class Creation
* -----------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class HPG_SecondaryTablesController_Test {
	@testSetup
	static void setupTestData() {
		final Local_Client__c localClient = TestFactory.createLocalClient();
		localClient.local_customer_id__c='Test Local Client';
		update localClient;
	}
	/* @isTest
	static void getDataConsumptionSummaryTestGroup() {
		final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
		final Local_Client__c localClient = [SELECT Local_Customer_Id__c FROM Local_Client__c LIMIT 1 ];
		Test.startTest();
			System.runAs(testUser) {
				HPG_ConsumptionSummary.Wrapper wrapper = HPG_SecondaryTablesController.getConsumptionSummary('group', 'localClient.Local_Customer_Id__c', '1', '10', Date.newInstance(2023,09,11), 'NONE', Datetime.now().toString());
				System.assertEquals(true, wrapper.success, 'getDataConsumptionSummaryTestGroup - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void getDataConsumptionSummaryTestSubgroup() {
		final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
		final Local_Client__c localClient = [SELECT Local_Customer_Id__c FROM Local_Client__c LIMIT 1 ];
		Test.startTest();
			System.runAs(testUser) {
				HPG_ConsumptionSummary.Wrapper wrapper = HPG_SecondaryTablesController.getConsumptionSummary('subgroup', 'localClient.Local_Customer_Id__c', '1', '10', Date.newInstance(2023,09,11), 'NONE', Datetime.now().toString());
				System.assertEquals(true, wrapper.success, 'getDataConsumptionSummaryTestSubgroup - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void getDataConsumptionSummaryTestClient() {
		final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
		final Local_Client__c localClient = [SELECT Local_Customer_Id__c FROM Local_Client__c LIMIT 1 ];
		Test.startTest();
			System.runAs(testUser) {
				HPG_ConsumptionSummary.Wrapper wrapper = HPG_SecondaryTablesController.getConsumptionSummary('client', 'localClient.Local_Customer_Id__c', '1', '10', Date.newInstance(2023,09,11), 'NONE', Datetime.now().toString());
				System.assertEquals(true, wrapper.success, 'getDataConsumptionSummaryTestClient - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void getConsumptionDetailTestGroup() {
		final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
		final Local_Client__c localClient = [SELECT Local_Customer_Id__c FROM Local_Client__c LIMIT 1 ];
		Test.startTest();
			System.runAs(testUser) {
				HPG_ConsumptionDetail.Wrapper wrapper = HPG_SecondaryTablesController.getConsumptionDetail('group', 'localClient.Local_Customer_Id__c', '1', '10', New List<String>{'ES','MX'}, Date.newInstance(2023,09,11), 'TEXT', Datetime.now().toString());
				System.assertEquals(true, wrapper.success, 'getConsumptionDetailTestGroup - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void getConsumptionDetailTestSubgroup() {
		final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
		final Local_Client__c localClient = [SELECT Local_Customer_Id__c FROM Local_Client__c LIMIT 1 ];
		Test.startTest();
			System.runAs(testUser) {
				HPG_ConsumptionDetail.Wrapper wrapper = HPG_SecondaryTablesController.getConsumptionDetail('subgroup', 'localClient.Local_Customer_Id__c', '1', '10', New List<String>{'ES','MX'}, Date.newInstance(2023,09,11), 'TEXT', Datetime.now().toString());
				System.assertEquals(true, wrapper.success, 'getConsumptionDetailTestSubgroup - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void getConsumptionDetailTestClient() {
		final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
		final Local_Client__c localClient = [SELECT Local_Customer_Id__c FROM Local_Client__c LIMIT 1 ];
		Test.startTest();
			System.runAs(testUser) {
				HPG_ConsumptionDetail.Wrapper wrapper = HPG_SecondaryTablesController.getConsumptionDetail('client', 'localClient.Local_Customer_Id__c', '1', '10', New List<String>{'ES','MX'}, Date.newInstance(2023,09,11), 'TEXT', Datetime.now().toString());
				System.assertEquals(true, wrapper.success, 'getConsumptionDetailTestClient - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void getDetailCapitalProvisionTestGroup() {
		final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
		final Local_Client__c localClient = [SELECT Local_Customer_Id__c FROM Local_Client__c LIMIT 1 ];
		Test.startTest();
			System.runAs(testUser) {
				HPG_CapitalProvisionDetail.Wrapper wrapper = HPG_SecondaryTablesController.getDetailCapitalProvision('group', 'localClient.Local_Customer_Id__c', '1', '10', New List<String>{'ES','MX'}, Date.newInstance(2023,09,11));
				System.assertEquals(true, wrapper.success, 'getDetailCapitalProvisionTestGroup - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void getDetailCapitalProvisionTestSubgroup() {
		final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
		final Local_Client__c localClient = [SELECT Local_Customer_Id__c FROM Local_Client__c LIMIT 1 ];
		Test.startTest();
			System.runAs(testUser) {
				HPG_CapitalProvisionDetail.Wrapper wrapper = HPG_SecondaryTablesController.getDetailCapitalProvision('subgroup', 'localClient.Local_Customer_Id__c', '1', '10', New List<String>{'ES','MX'}, Date.newInstance(2023,09,11));
				System.assertEquals(true, wrapper.success, 'getDetailCapitalProvisionTestSubgroup - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void getDetailCapitalProvisionTestClient() {
		final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
		final Local_Client__c localClient = [SELECT Local_Customer_Id__c FROM Local_Client__c LIMIT 1 ];
		Test.startTest();
			System.runAs(testUser) {
				HPG_CapitalProvisionDetail.Wrapper wrapper = HPG_SecondaryTablesController.getDetailCapitalProvision('client', 'localClient.Local_Customer_Id__c', '1', '10', New List<String>{'ES','MX'}, Date.newInstance(2023,09,11));
				System.assertEquals(true, wrapper.success, 'getDetailCapitalProvisionTestClient - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void getIssuerRiskTestGroup() {
		final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
		final Local_Client__c localClient = [SELECT Local_Customer_Id__c FROM Local_Client__c LIMIT 1 ];
		Test.startTest();
			System.runAs(testUser) {
				HPG_IssuerRisk.Wrapper wrapper = HPG_SecondaryTablesController.getIssuerRisk('group', 'localClient.Local_Customer_Id__c', '1', '10', New List<String>{'ES','MX'}, Date.newInstance(2023,09,11));
				System.assertEquals(true, wrapper.success, 'getIssuerRiskTestGroup - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void getIssuerRiskTestSubgroup() {
		final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
		final Local_Client__c localClient = [SELECT Local_Customer_Id__c FROM Local_Client__c LIMIT 1 ];
		Test.startTest();
			System.runAs(testUser) {
				HPG_IssuerRisk.Wrapper wrapper = HPG_SecondaryTablesController.getIssuerRisk('subgroup', 'localClient.Local_Customer_Id__c', '1', '10', New List<String>{'ES','MX'}, Date.newInstance(2023,09,11));
				System.assertEquals(true, wrapper.success, 'getIssuerRiskTestSubgroup - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void getIssuerRiskTestClient() {
		final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
		final Local_Client__c localClient = [SELECT Local_Customer_Id__c FROM Local_Client__c LIMIT 1 ];
		Test.startTest();
			System.runAs(testUser) {
				HPG_IssuerRisk.Wrapper wrapper = HPG_SecondaryTablesController.getIssuerRisk('client', 'localClient.Local_Customer_Id__c', '1', '10', New List<String>{'ES','MX'}, Date.newInstance(2023,09,11));
				System.assertEquals(true, wrapper.success, 'getIssuerRiskTestClient - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void getDerivativesDataTestGroup() {
		final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
		final Local_Client__c localClient = [SELECT Local_Customer_Id__c FROM Local_Client__c LIMIT 1 ];
		Test.startTest();
			System.runAs(testUser) {
				HPG_Derivatives.Wrapper wrapper = HPG_SecondaryTablesController.getDerivativesData('group', 'localClient.Local_Customer_Id__c', '1', '10', New List<String>{'ES','MX'}, Date.newInstance(2023,09,11), true);
				System.assertEquals(true, wrapper.success, 'getDerivativesDataTestGroup - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void getDerivativesDataTestSubgroup() {
		final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
		final Local_Client__c localClient = [SELECT Local_Customer_Id__c FROM Local_Client__c LIMIT 1 ];
		Test.startTest();
			System.runAs(testUser) {
				HPG_Derivatives.Wrapper wrapper = HPG_SecondaryTablesController.getDerivativesData('subgroup', 'localClient.Local_Customer_Id__c', '1', '10', New List<String>{'ES','MX'}, Date.newInstance(2023,09,11), true);
				System.assertEquals(true, wrapper.success, 'getDerivativesDataTestSubgroup - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void getDerivativesDataTestClient() {
		final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
		final Local_Client__c localClient = [SELECT Local_Customer_Id__c FROM Local_Client__c LIMIT 1 ];
		Test.startTest();
			System.runAs(testUser) {
				HPG_Derivatives.Wrapper wrapper = HPG_SecondaryTablesController.getDerivativesData('client', 'localClient.Local_Customer_Id__c', '1', '10', New List<String>{'ES','MX'}, Date.newInstance(2023,09,11), true);
				System.assertEquals(true, wrapper.success, 'getDerivativesDataTestClient - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void validateOverrideConsumptionTest() {
		final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
		Test.startTest();
			System.runAs(testUser) {
				Account supraGroupAccount = new Account();
				supraGroupAccount.Name = 'Test Supragroup Account';
				supraGroupAccount.DES_Structure_Type__c = 'Supragroup';
				supraGroupAccount.DES_Group_Code__c = 'X00000000000000';
				insert supraGroupAccount;
				final iaso__GBL_integration_service__mdt serviceDetails = [SELECT iaso__Mock_LTA__c FROM iaso__GBL_integration_service__mdt WHERE DeveloperName = 'HPG_GetConsumptionDetail' LIMIT 1];
				HPG_ConsumptionDetail.Wrapper wrapper = (HPG_ConsumptionDetail.Wrapper) JSON.deserialize(serviceDetails.iaso__Mock_LTA__c, HPG_ConsumptionDetail.Wrapper.class);
				HPG_ConsumptionDetail.Wrapper wrapperValidated = HPG_SecondaryTablesController.validateOverrideConsumption(wrapper, supraGroupAccount.Id);
				System.assertEquals('EXPIRED', wrapperValidated.data[0].detailConsumptions[0].overrideAction, 'validateOverrideConsumptionTest - Not passed - overrideAction');
				System.assertEquals('utility:expired', wrapperValidated.data[0].detailConsumptions[0].overrideIcon, 'validateOverrideConsumptionTest - Not passed - overrideIcon');
			}
		Test.stopTest();
	}
	@isTest
	static void getCurrentLimitsTestGroup() {
		final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
		final Local_Client__c localClient = [SELECT Local_Customer_Id__c FROM Local_Client__c LIMIT 1 ];
		Test.startTest();
			System.runAs(testUser) {
				HPG_CurrentLimits.Wrapper wrapper = HPG_SecondaryTablesController.getCurrentLimits('localClient.Local_Customer_Id__c', 'group', Date.newInstance(2023,09,11));
				System.assertEquals(true, wrapper.success, 'getCurrentLimitsTestGroup - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void getCurrentLimitsTestSubgroup() {
		final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
		final Local_Client__c localClient = [SELECT Local_Customer_Id__c FROM Local_Client__c LIMIT 1 ];
		Test.startTest();
			System.runAs(testUser) {
				HPG_CurrentLimits.Wrapper wrapper = HPG_SecondaryTablesController.getCurrentLimits('localClient.Local_Customer_Id__c', 'subgroup', Date.newInstance(2023,09,11));
				System.assertEquals(true, wrapper.success, 'getCurrentLimitsTestGroup - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void getCurrenciesTestEUR() {
		final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
		SER_EUR_Currency_exchange_rate__c currencyExchangeRate = new SER_EUR_Currency_exchange_rate__c();
        currencyExchangeRate.SER_Counter_currency__c = 'USD';
        currencyExchangeRate.SER_Exchange_rate__c = 1.12;
        currencyExchangeRate.SER_Process_date__c = Date.today();
        insert currencyExchangeRate;
		Test.startTest();
			System.runAs(testUser) {
				HPG_Currency.Wrapper wrapper = HPG_SecondaryTablesController.getCurrencies('EUR');
				System.assertEquals('EUR', wrapper.baseCurrency, 'getCurrenciesTestEUR - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void getCurrenciesTestUSD() {
		final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
		SER_EUR_Currency_exchange_rate__c currencyExchangeRate = new SER_EUR_Currency_exchange_rate__c();
        currencyExchangeRate.SER_Counter_currency__c = 'USD';
        currencyExchangeRate.SER_Exchange_rate__c = 1.12;
        currencyExchangeRate.SER_Process_date__c = Date.today();
        insert currencyExchangeRate;
		Test.startTest();
			System.runAs(testUser) {
				HPG_Currency.Wrapper wrapper = HPG_SecondaryTablesController.getCurrencies('USD');
				System.assertEquals('USD', wrapper.baseCurrency, 'getCurrenciesTestEUR - Not passed - success');
			}
		Test.stopTest();
	} */
}