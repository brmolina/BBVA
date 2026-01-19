/**
* ------------------------------------------------------------------------------------------------
* @Name     HPG_MainTableCustomController_Test
* @Author   Global Hub
* @Date     Created: 2023-09-12
* ------------------------------------------------------------------------------------------------
* @Description Test class for HPG_MainTableCustomController
* ------------------------------------------------------------------------------------------------
* @Changes
*
* | 2023-09-07 ivan.garces.contractor@bbva.com
*             Class Creation
* -----------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class HPG_MainTableCustomController_Test {
	@testSetup
	static void setupTestData() {
		final Id userId = UserInfo.getUserId();
		User user = [SELECT Id, DES_Country__c FROM User WHERE Id =: userId];
		user.DES_Country__c = 'ESP';
		update user;
		HPG_Geography_Visibility_Configuration__c config = new HPG_Geography_Visibility_Configuration__c();
		config.Risk_Compacted__c = 'ES';
		config.No_Risk_Compacted__c = 'ES';
		config.Geography__c = 'ESP';
		insert config;
		final Local_Client__c acc = TestFactory.createLocalClient();
	}
	/* @isTest
	static void fetchClientDataFromServiceTest() {
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
				HPG_GlobalPosition.Wrapper wrapper = HPG_MainTableCustomController.fetchClientDataFromService(supraGroupAccount.Id, '1', '10', New List<String>{'ES','MX'}, Date.newInstance(2023,09,11), 'N');
				System.assertEquals(true, wrapper.success, 'fetchClientDataFromServiceTest - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void fetchConsumptionDataFromServiceTest() {
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
				HPG_Consumption.Wrapper wrapper = HPG_MainTableCustomController.fetchConsumptionDataFromService(supraGroupAccount.Id, 'Y', '1', Date.newInstance(2023,09,11), '10', New List<String>{'ES','MX'});
				System.assertEquals(true, wrapper.success, 'fetchConsumptionDataFromServiceTest - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void getClientIdTest1() {
		Account account = New Account();
		account.Name = 'Test Account';
		account.DES_Structure_Type__c = 'Group';
		account.DES_Group_Code__c = 'ES7202';
		insert account;
		Test.startTest();
			String alphaCode = HPG_MainTableCustomController.getClientId(account.Id);
			System.assertEquals(account.DES_Group_Code__c, alphaCode, 'getClientIdTest1 - Not passed - alphaCode');
		Test.stopTest();
	}
	@isTest
	static void getClientIdTest2() {
		final Local_Client__c localClient = [SELECT Id, Cib_Client__c, Alpha_code__c FROM Local_Client__c LIMIT 1 ];
		Test.startTest();
			String alphaCode = HPG_MainTableCustomController.getClientId(localClient.Cib_Client__c);
			System.assertEquals(localClient.Alpha_code__c, alphaCode, 'getClientIdTest2 - Not passed - alphaCode');
		Test.stopTest();
	}
	/* Test
	static void fetchCaProvisionDataFromServiceTest() {
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
				HPG_CapitalProvision.Wrapper wrapper = HPG_MainTableCustomController.fetchCaProvisionDataFromService(supraGroupAccount.Id, '1', '10', New List<String>{'ES','MX'}, Date.newInstance(2023,09,11), 'N');
				System.assertEquals(true, wrapper.success, 'fetchCaProvisionDataFromServiceTest - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void fetchUsedTablesDataFromServiceTest() {
		final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
		System.runAs(testUser) {
			Test.startTest();
				HPG_UsedTables.Wrapper wrapper = HPG_MainTableCustomController.fetchUsedTablesDataFromService(Date.newInstance(2023,09,11), '1', '10');
				System.assertEquals(true, wrapper.success, 'fetchUsedTablesDataFromServiceTest - Not passed - success');
			Test.stopTest();
		}
	}
	@isTest
	static void fetchConnectedClientFromServiceTest() {
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
				supraGroupAccount.DES_Group_Code__c = 'G00000000000000';
				insert supraGroupAccount;
				HPG_ConnectedClients.Wrapper wrapper = HPG_MainTableCustomController.fetchConnectedClientsFromService(supraGroupAccount.Id, '1', Date.newInstance(2023,09,11), '10', New List<String>{'ES','MX'});
				System.assertEquals(true, wrapper.success, 'fetchUsedTablesDataFromServiceTest - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void fetchOverrideConsumptionDataFromServiceTest() {
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
				supraGroupAccount.DES_Group_Code__c = 'G00000000000000';
				insert supraGroupAccount;
				HPG_OverrideConsumption.Wrapper wrapper = HPG_MainTableCustomController.fetchOverrideConsumptionDataFromService(supraGroupAccount.Id, '1', '10');
				System.assertEquals(true, wrapper.success, 'fetchOverrideConsumptionDataFromServiceTest - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void userIsAdminTest() {
		final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
		Test.startTest();
			System.runAs(testUser) {
				String userIsAdmin = HPG_MainTableCustomController.userIsAdmin();
				System.assertEquals('false', userIsAdmin, 'userIsAdminTest - Not passed - userIsAdmin');
			}
		Test.stopTest();
	}
	@isTest
	static void fetchDataConsumptionTest() {
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
				supraGroupAccount.DES_Group_Code__c = 'G00000000000000';
				insert supraGroupAccount;
				Object res = HPG_MainTableCustomController.fetchData('consumption', supraGroupAccount.Id, New List<String>{'ES','MX'}, '2023-09-11', 'N', '1', '10');
				HPG_Consumption.Wrapper wrapper = (HPG_Consumption.Wrapper) JSON.deserialize(JSON.serialize(res), HPG_Consumption.Wrapper.class);
				System.assertEquals(true, wrapper.success, 'fetchDataConsumptionTest - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void fetchDataCapitalProvisionTest() {
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
				supraGroupAccount.DES_Group_Code__c = 'G00000000000000';
				insert supraGroupAccount;
				Object res = HPG_MainTableCustomController.fetchData('capitalProvision', supraGroupAccount.Id, New List<String>{'ES','MX'}, '2023-09-11', 'N', '1', '10');
				HPG_GlobalPosition.Wrapper wrapper = (HPG_GlobalPosition.Wrapper) JSON.deserialize(JSON.serialize(res), HPG_GlobalPosition.Wrapper.class);
				System.assertEquals(true, wrapper.success, 'fetchDataCapitalProvisionTest - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void fetchDataConnectedClientsTest() {
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
				supraGroupAccount.DES_Group_Code__c = 'G00000000000000';
				insert supraGroupAccount;
				Object res = HPG_MainTableCustomController.fetchData('connectedClients', supraGroupAccount.Id, New List<String>{'ES','MX'}, '2023-09-11', 'N', '1', '10');
				HPG_GlobalPosition.Wrapper wrapper = (HPG_GlobalPosition.Wrapper) JSON.deserialize(JSON.serialize(res), HPG_GlobalPosition.Wrapper.class);
				System.assertEquals(true, wrapper.success, 'fetchDataConnectedClientsTest - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void fetchDataDataReportTest() {
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
				Object res = HPG_MainTableCustomController.fetchData('dataReport', supraGroupAccount.Id, New List<String>{'ES','MX'}, '2023-09-11', 'N', '1', '10');
				HPG_GlobalPosition.Wrapper wrapper = (HPG_GlobalPosition.Wrapper) JSON.deserialize(JSON.serialize(res), HPG_GlobalPosition.Wrapper.class);
				System.assertEquals(true, wrapper.success, 'fetchDataDataReportTest - Not passed - success');
			}
		Test.stopTest();
	}
	@isTest
	static void fetchDataOtherTest() {
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
				Object res = HPG_MainTableCustomController.fetchData('overrideConsumption', supraGroupAccount.Id, New List<String>{'ES','MX'}, '2023-09-11', 'N', '1', '10');
				HPG_GlobalPosition.Wrapper wrapper = (HPG_GlobalPosition.Wrapper) JSON.deserialize(JSON.serialize(res), HPG_GlobalPosition.Wrapper.class);
				System.assertEquals(true, wrapper.success, 'fetchDataOtherTest - Not passed - success');
			}
		Test.stopTest();
	} */
}