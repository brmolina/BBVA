/**
* ────────────────────────────────────────────────────────────────────────────────────
* Test class for HPG_GlobalClientsExposure_Ctrl apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2024-01-11
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@isTest
public with sharing class HPG_GlobalClientsExposure_Ctrl_Test {
    /* @IsTest
    static void getInitialDataTestLocalClientId1() {
        final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
        Account account = New Account();
        account.Name = 'Test Account';
        account.DES_Structure_Type__c = 'Subsidiary';
        insert account;
        Local_Client__c localClient = new Local_Client__c();
        localClient.Cib_Client__c = account.Id;
        localClient.Alpha_code__c = 'G00000000000460';
        insert localClient;
        Test.startTest();
            System.runAs(testUser) {
                Map<String, Object> retMap = HPG_GlobalClientsExposure_Ctrl.getInitialData(localClient.Id,'');
                Boolean success = (Boolean)retMap.get('success');
                String groupName = (String)retMap.get('groupName');
                String groupId = (String)retMap.get('groupId');
                String groupCode = (String)retMap.get('groupCode');
                System.assertEquals(true, success, 'getInitialDataTestLocalClientId1 - Not passed - success');
                System.assertEquals(account.Name, groupName, 'getInitialDataTestLocalClientId1 - Not passed - groupName');
                System.assertEquals(account.Id, groupId, 'getInitialDataTestLocalClientId1 - Not passed - groupId');
                System.assertEquals(localClient.Alpha_code__c, groupCode, 'getInitialDataTestLocalClientId1 - Not passed - groupCode');
            }
        Test.stopTest();
    } */
    @IsTest
    static void getInitialDataTestLocalClientIdError() {
        Account account = New Account();
        account.Name = 'Test Account';
        account.DES_Structure_Type__c = 'Subsidiary';
        insert account;
        Local_Client__c localClient = new Local_Client__c();
        localClient.Cib_Client__c = account.Id;
        insert localClient;
        Test.startTest();
            Map<String, Object> retMap = HPG_GlobalClientsExposure_Ctrl.getInitialData(localClient.Id,'');
            Boolean success = (Boolean)retMap.get('success');
            System.assertEquals(false, success, 'getInitialDataTestLocalClientIdError - Not passed - success');
        Test.stopTest();
    }
    /* @IsTest
    static void getInitialDataTestAccountId1() {
        final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
        Test.startTest();
            System.runAs(testUser) {
                Account account = New Account();
                account.Name = 'Test Account';
                account.DES_Group_Code__c = 'G00000000000460';
                account.DES_Structure_Type__c = 'Supragroup';
                insert account;
                Map<String, Object> retMap = HPG_GlobalClientsExposure_Ctrl.getInitialData(account.Id,'');
                Boolean success = (Boolean)retMap.get('success');
                String groupName = (String)retMap.get('groupName');
                String groupId = (String)retMap.get('groupId');
                String groupCode = (String)retMap.get('groupCode');
                System.assertEquals(true, success, 'getInitialDataTestAccountId1 - Not passed - success');
                System.assertEquals(account.Name, groupName, 'getInitialDataTestAccountId1 - Not passed - groupName');
                System.assertEquals(account.Id, groupId, 'getInitialDataTestAccountId1 - Not passed - groupId');
                System.assertEquals(account.DES_Group_Code__c, groupCode, 'getInitialDataTestAccountId1 - Not passed - groupCode');
            }
        Test.stopTest();
    }
    @IsTest
    static void getInitialDataTestAccountId2() {
        final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
        Account account = New Account();
        account.Name = 'Test Account';
        account.DES_Structure_Type__c = 'Subsidiary';
        insert account;
        Local_Client__c localClient = new Local_Client__c();
        localClient.Cib_Client__c = account.Id;
        localClient.Alpha_code__c = 'G00000000000460';
        insert localClient;
        Test.startTest();
            System.runAs(testUser) {
                Map<String, Object> retMap = HPG_GlobalClientsExposure_Ctrl.getInitialData(account.Id,'');
                Boolean success = (Boolean)retMap.get('success');
                String groupName = (String)retMap.get('groupName');
                String groupId = (String)retMap.get('groupId');
                String groupCode = (String)retMap.get('groupCode');
                System.assertEquals(true, success, 'getInitialDataTestAccountId2 - Not passed - success');
                System.assertEquals(account.Name, groupName, 'getInitialDataTestAccountId2 - Not passed - groupName');
                System.assertEquals(account.Id, groupId, 'getInitialDataTestAccountId2 - Not passed - groupId');
                System.assertEquals(localClient.Alpha_code__c, groupCode, 'getInitialDataTestAccountId2 - Not passed - groupCode');
            }
        Test.stopTest();
    } */
    @IsTest
    static void getInitialDataTestAccountIdError() {
        Account account = New Account();
        account.Name = 'Test Account';
        account.DES_Structure_Type__c = 'Subsidiary';
        insert account;
        Test.startTest();
            Map<String, Object> retMap = HPG_GlobalClientsExposure_Ctrl.getInitialData(account.Id,'');
            Boolean success = (Boolean)retMap.get('success');
            System.assertEquals(false, success, 'getInitialDataTestAccountIdError - Not passed - success');
        Test.stopTest();
    }
    @IsTest
    static void getInitialDataTestOtherIdError() {
        final Id userId = UserInfo.getUserId();
        Test.startTest();
            Map<String, Object> retMap = HPG_GlobalClientsExposure_Ctrl.getInitialData(userId,'');
            Boolean success = (Boolean)retMap.get('success');
            System.assertEquals(false, success, 'getInitialDataTestOtherIdError - Not passed - success');
        Test.stopTest();
    }



}