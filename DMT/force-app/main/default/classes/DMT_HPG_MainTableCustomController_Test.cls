/**
* ------------------------------------------------------------------------------------------------
* @Name     DMT_HPG_MainTableCustomController_Test
* @Author   Global Hub
* @Date     Created: 2023-09-12
* ------------------------------------------------------------------------------------------------
* @Description Test class for DMT_HPG_MainTableCustomController
* ------------------------------------------------------------------------------------------------
* @Changes
*
* | 2023-09-07 ivan.garces.contractor@bbva.com
*             Class Creation
* -----------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class DMT_HPG_MainTableCustomController_Test {
  @testSetup
  static void setupTestData() {
    TriggerBypass.setBypass();
    final Id userId = UserInfo.getUserId();
    User user = [SELECT Id, DES_Country__c FROM User WHERE Id =: userId];
    user.DES_Country__c = 'ESP';
    update user;
    hpgr__Geography_Visibility_Configuration__c config = new hpgr__Geography_Visibility_Configuration__c();
    config.hpgr__Risk_Compacted__c = 'ES';
    config.hpgr__No_Risk_Compacted__c = 'ES';
    config.hpgr__Geography__c = 'ESP';
    insert config;
    final Local_Client__c acc = TestFactory.createLocalClient();

    final Opportunity oppTest = DMT_Test_DataFactory.generateOpportunity();

    List<iaso__GBL_Rest_Services_Url__c> settingsToInsert = new List<iaso__GBL_Rest_Services_Url__c>();

    settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMTO_Endpoint_INT', 'https://service.ok', 'ServicesPartition', false));
    settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_GrantingTicket', 'https://validation.ok', 'ServicesPartition', false));
    settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_HPGR_Endpoint', 'https://group-position.ok', 'ServicesPartition', false));
    settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_HPG_CommonEndPoint', 'https://group-position.ok', 'ServicesPartition', false));

    // Perform one single DML
    insert settingsToInsert;

    TriggerBypass.removeBypass();
  }
  @isTest
  static void fetchClientDataFromServiceTest() {
    final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'System Administrator');
    testUser.DES_Country__c = 'ESP';
    testUser.Access_GCE__c = 'RISK';
    update testUser;

    System.runAs(testUser) {
      Account supraGroupAccount = new Account();
      supraGroupAccount.Name = 'Test Supragroup Account';
      supraGroupAccount.DES_Structure_Type__c = 'Supragroup';
      supraGroupAccount.DES_Group_Code__c = 'X00000000000000';
      insert supraGroupAccount;
      Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
      Test.startTest();
        DMT_HPG_GlobalPosition.Wrapper wrapper = DMT_HPG_MainTableCustomController.fetchClientDataFromService(supraGroupAccount.Id, '1', '10', New List<String>{'ES','MX'}, Date.newInstance(2023,09,11), 'N', null);
        Test.stopTest();
        System.assertEquals(true, wrapper.success, 'fetchClientDataFromServiceTest - Not passed - success');
      }
  }
  @isTest
  static void fetchConsumptionDataFromServiceTest() {
    final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'System Administrator');
    testUser.DES_Country__c = 'ESP';
    testUser.Access_GCE__c = 'RISK';
    update testUser;

    System.runAs(testUser) {
      Account supraGroupAccount = new Account();
      supraGroupAccount.Name = 'Test Supragroup Account';
      supraGroupAccount.DES_Structure_Type__c = 'Supragroup';
      supraGroupAccount.DES_Group_Code__c = 'X00000000000000';
      insert supraGroupAccount;
      Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
      Test.startTest();
        DMT_HPG_Consumption.Wrapper wrapper = DMT_HPG_MainTableCustomController.fetchConsumptionDataFromService(supraGroupAccount.Id, 'Y', '1', Date.newInstance(2023,09,11), '10', New List<String>{'ES','MX'});
        Test.stopTest();
        System.assertEquals(true, wrapper.success, 'fetchConsumptionDataFromServiceTest - Not passed - success');
      }
  }
  @isTest
  static void getClientIdTest1() {
    Account account = New Account();
    account.Name = 'Test Account';
    account.DES_Structure_Type__c = 'Group';
    account.DES_Group_Code__c = 'ES7202';
    insert account;
    Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
    Test.startTest();
      String alphaCode = DMT_HPG_MainTableCustomController.getClientId(account.Id);
      Test.stopTest();
      System.assertEquals(account.DES_Group_Code__c, alphaCode, 'getClientIdTest1 - Not passed - alphaCode');
  }
  @isTest
  static void getClientIdTest2() {
    final Local_Client__c localClient = [SELECT Id, Cib_Client__c, Alpha_code__c FROM Local_Client__c LIMIT 1 ];
    Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
    Test.startTest();
      String alphaCode = DMT_HPG_MainTableCustomController.getClientId(localClient.Cib_Client__c);
      Test.stopTest();
      System.assertEquals(localClient.Alpha_code__c, alphaCode, 'getClientIdTest2 - Not passed - alphaCode');
  }
  @isTest
  static void fetchCaProvisionDataFromServiceTest() {
    DES_User_Roles__mdt userRoles = [SELECT Id, DES_Role_Developer_Name__c FROM DES_User_Roles__mdt WHERE DES_Access_Level__c = 'Read/Write' LIMIT 1];
    final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'System Administrator');
    testUser.DES_Country__c = 'ESP';
    testUser.Access_GCE__c = 'RISK';
    testUser.DMT_User_Role__c = userRoles.DES_Role_Developer_Name__c;
    update testUser;
      System.runAs(testUser) {
        Account supraGroupAccount = new Account();
        supraGroupAccount.Name = 'Test Supragroup Account';
        supraGroupAccount.DES_Structure_Type__c = 'Supragroup';
        supraGroupAccount.DES_Group_Code__c = 'X00000000000000';
        insert supraGroupAccount;
        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        Test.startTest();
        DMT_HPG_CapitalProvision.Wrapper wrapper = DMT_HPG_MainTableCustomController.fetchCaProvisionDataFromService(supraGroupAccount.Id, '1', '10', New List<String>{'ES','MX'}, Date.newInstance(2023,09,11), 'N');
        Test.stopTest();
        System.assertEquals(true, wrapper.success, 'fetchCaProvisionDataFromServiceTest - Not passed - success');
      }
  }
  @isTest
  static void fetchUsedTablesDataFromServiceTest() {
    final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'System Administrator');
    testUser.DES_Country__c = 'ESP';
    testUser.Access_GCE__c = 'RISK';
    update testUser;

    Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
    System.runAs(testUser) {
      Test.startTest();
        DMT_HPG_UsedTables.Wrapper wrapper = DMT_HPG_MainTableCustomController.fetchUsedTablesDataFromService(Date.newInstance(2023,09,11), '1', '10');
        System.assertEquals(true, wrapper.success, 'fetchUsedTablesDataFromServiceTest - Not passed - success');
      Test.stopTest();
    }
  }
  @isTest
  static void fetchConnectedClientFromServiceTest() {
    final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'System Administrator');
    testUser.DES_Country__c = 'ESP';
    testUser.Access_GCE__c = 'RISK';
    update testUser;
    System.runAs(testUser) {
      Account supraGroupAccount = new Account();
      supraGroupAccount.Name = 'Test Supragroup Account';
      supraGroupAccount.DES_Structure_Type__c = 'Supragroup';
      supraGroupAccount.DES_Group_Code__c = 'G00000000000000';
      insert supraGroupAccount;
      Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
      Test.startTest();
        DMT_HPG_ConnectedClients.Wrapper wrapper = DMT_HPG_MainTableCustomController.fetchConnectedClientsFromService(supraGroupAccount.Id, '1', Date.newInstance(2023,09,11), '10', New List<String>{'ES','MX'});
        Test.stopTest();
        System.assertEquals(true, wrapper.success, 'fetchConnectedClientFromServiceTest - Not passed - success');
      }
  }

  @isTest
  static void userIsAdminTest() {
    final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'System Administrator');
    testUser.DES_Country__c = 'ESP';
    testUser.Access_GCE__c = 'RISK';
    update testUser;
    Test.startTest();
      System.runAs(testUser) {
        String userIsAdmin = DMT_HPG_MainTableCustomController.userIsAdmin();
        System.assertEquals('false', userIsAdmin, 'userIsAdminTest - Not passed - userIsAdmin');
      }
    Test.stopTest();
  }
  @isTest
  static void fetchDataConsumptionTest() {
    final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'System Administrator');
    testUser.DES_Country__c = 'ESP';
    testUser.Access_GCE__c = 'RISK';
    update testUser;

    System.runAs(testUser) {
      Account supraGroupAccount = new Account();
      supraGroupAccount.Name = 'Test Supragroup Account';
      supraGroupAccount.DES_Structure_Type__c = 'Supragroup';
      supraGroupAccount.DES_Group_Code__c = 'G00000000000000';
      insert supraGroupAccount;
      Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
      Test.startTest();
        Object res = DMT_HPG_MainTableCustomController.fetchData('consumption', supraGroupAccount.Id, New List<String>{'ES','MX'}, '2023-09-11', 'N', '1', '10', null);
        Test.stopTest();
        DMT_HPG_Consumption.Wrapper wrapper = (DMT_HPG_Consumption.Wrapper) JSON.deserialize(JSON.serialize(res), DMT_HPG_Consumption.Wrapper.class);
        System.assertEquals(true, wrapper.success, 'fetchDataConsumptionTest - Not passed - success');
      }
  }
  @isTest
  static void fetchDataCapitalProvisionTest() {
    final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'System Administrator');
    testUser.DES_Country__c = 'ESP';
    testUser.Access_GCE__c = 'RISK';
    update testUser;

    System.runAs(testUser) {
      Account supraGroupAccount = new Account();
      supraGroupAccount.Name = 'Test Supragroup Account';
      supraGroupAccount.DES_Structure_Type__c = 'Supragroup';
      supraGroupAccount.DES_Group_Code__c = 'G00000000000000';
      insert supraGroupAccount;
      Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
      Test.startTest();
        Object res = DMT_HPG_MainTableCustomController.fetchData('capitalProvision', supraGroupAccount.Id, New List<String>{'ES','MX'}, '2023-09-11', 'N', '1', '10', null);
        Test.stopTest();
        DMT_HPG_GlobalPosition.Wrapper wrapper = (DMT_HPG_GlobalPosition.Wrapper) JSON.deserialize(JSON.serialize(res), DMT_HPG_GlobalPosition.Wrapper.class);
        System.assertEquals(true, wrapper.success, 'fetchDataCapitalProvisionTest - Not passed - success');
      }
  }
  @isTest
  static void fetchDataConnectedClientsTest() {
    final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'System Administrator');
    testUser.DES_Country__c = 'ESP';
    testUser.Access_GCE__c = 'RISK';
    update testUser;

    System.runAs(testUser) {
      Account supraGroupAccount = new Account();
      supraGroupAccount.Name = 'Test Supragroup Account';
      supraGroupAccount.DES_Structure_Type__c = 'Supragroup';
      supraGroupAccount.DES_Group_Code__c = 'G00000000000000';
      insert supraGroupAccount;
      Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
      Test.startTest();
        Object res = DMT_HPG_MainTableCustomController.fetchData('connectedClients', supraGroupAccount.Id, New List<String>{'ES','MX'}, '2023-09-11', 'N', '1', '10', null);
        Test.stopTest();
        DMT_HPG_GlobalPosition.Wrapper wrapper = (DMT_HPG_GlobalPosition.Wrapper) JSON.deserialize(JSON.serialize(res), DMT_HPG_GlobalPosition.Wrapper.class);
        System.assertEquals(true, wrapper.success, 'fetchDataConnectedClientsTest - Not passed - success');
      }
  }
  @isTest
  static void fetchDataDataReportTest() {
    final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'System Administrator');
    testUser.DES_Country__c = 'ESP';
    testUser.Access_GCE__c = 'RISK';
    update testUser;

    System.runAs(testUser) {
      Account supraGroupAccount = new Account();
      supraGroupAccount.Name = 'Test Supragroup Account';
      supraGroupAccount.DES_Structure_Type__c = 'Supragroup';
      supraGroupAccount.DES_Group_Code__c = 'X00000000000000';
      insert supraGroupAccount;
      Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
      Test.startTest();
        Object res = DMT_HPG_MainTableCustomController.fetchData('dataReport', supraGroupAccount.Id, New List<String>{'ES','MX'}, '2023-09-11', 'N', '1', '10', null);
        Test.stopTest();
        DMT_HPG_GlobalPosition.Wrapper wrapper = (DMT_HPG_GlobalPosition.Wrapper) JSON.deserialize(JSON.serialize(res), DMT_HPG_GlobalPosition.Wrapper.class);
        System.assertEquals(true, wrapper.success, 'fetchDataDataReportTest - Not passed - success');
      }
  }
  @isTest
  static void fetchDataOtherTest() {
    final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'System Administrator');
    testUser.DES_Country__c = 'ESP';
    testUser.Access_GCE__c = 'RISK';
    update testUser;

    System.runAs(testUser) {
      Account supraGroupAccount = new Account();
      supraGroupAccount.Name = 'Test Supragroup Account';
      supraGroupAccount.DES_Structure_Type__c = 'Supragroup';
      supraGroupAccount.DES_Group_Code__c = 'X00000000000000';
      insert supraGroupAccount;
      Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
      Test.startTest();
        Object res = DMT_HPG_MainTableCustomController.fetchData('overrideConsumption', supraGroupAccount.Id, New List<String>{'ES','MX'}, '2023-09-11', 'N', '1', '10', null);
        Test.stopTest();
        DMT_HPG_GlobalPosition.Wrapper wrapper = (DMT_HPG_GlobalPosition.Wrapper) JSON.deserialize(JSON.serialize(res), DMT_HPG_GlobalPosition.Wrapper.class);
        System.assertEquals(true, wrapper.success, 'fetchDataOtherTest - Not passed - success');
      }
  }

@IsTest
  static void getAccountIdFromRecordIdTest() {
    Account account = New Account();
    account.Name = 'Test Account';
    account.DES_Structure_Type__c = 'Group';
    account.DES_Group_Code__c = 'ES7202';
    insert account;
    final Id accountId = DMT_HPG_MainTableCustomController.getAccountIdFromRecordId(account.Id);
    System.assertEquals(account.Id, accountId, 'getAccountIdFromRecordIdTest - Not passed');
  }

  @IsTest
  static void getAccountIdFromRecordIdTestOpp() {
    Account account = [Select Id FROM Account WHERE Name='Test company 1' LIMIT 1];
    Opportunity oppTest = [Select Id FROM Opportunity WHERE Name='Test Opp' AND AccountId=:account.Id LIMIT 1];
    final Id accountId = DMT_HPG_MainTableCustomController.getAccountIdFromRecordId(oppTest.Id);
    System.assertEquals(account.Id, accountId, 'getAccountIdFromRecordIdTest - Not passed');
  }
}