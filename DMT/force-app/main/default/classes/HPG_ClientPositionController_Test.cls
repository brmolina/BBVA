/**
* ------------------------------------------------------------------------------------------------
* @Name     HPG_ClientPositionController_Test
* @Author   Global Hub
* @Date     Created: 2023-09-07
* ------------------------------------------------------------------------------------------------
* @Description Test class for HPG_ClientPositionController
* ------------------------------------------------------------------------------------------------
* @Changes
*
* | 2023-09-07 ivan.garces.contractor@bbva.com
*              Class Creation
* ------------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class HPG_ClientPositionController_Test {
    @testSetup
    static void setupTestData() {
        Account account = New Account();
        account.Name = 'Test Account';
        insert account;
        final Local_Client__c acc = TestFactory.createLocalClient();
    }
    @isTest
    static void getTriDataTest() {
        Account groupAccount = new Account();
        groupAccount.Name = 'Test Account';
        groupAccount.DES_Structure_Type__c = 'Group';
        groupAccount.DES_Group_Code__c = 'X00000000000000';
        insert groupAccount;
        cstk__Toolkit__c toolkit = new cstk__Toolkit__c();
        toolkit.cstk__account_id__c = groupAccount.Id;
        insert toolkit;
        cstk__General_Data__c generalData = new cstk__General_Data__c();
        generalData.cstk__toolkit_id__c = toolkit.Id;
        generalData.cstk__cta__c = 2.3;
        generalData.cstk__cca__c = 1.5;
        generalData.cstk__tri__c = 1;
        generalData.cstk__year__c = '0000';
        generalData.cstk__unique_id__c = 'GD0000X00000000000000';
        insert generalData;
        Test.startTest();
            String triData = HPG_ClientPositionController.getTriData(groupAccount.Id);
            system.assertEquals(' - TRI 1 - CCA 1.5 - CTA 2.3', triData, 'getTriDataTest - Not passed - triData');
        Test.stopTest();
    }
    @isTest
    static void userCanEditTest() {
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
        String userCanEdit = '';
        Test.startTest();
            System.runAs(testUser) {
                Map<String, Object> retMap = HPG_ClientPositionController.getUserPermissions();
                Boolean isAdmin = (Boolean)retMap.get('isAdmin');
                Boolean isDMTUser = (Boolean)retMap.get('isDMTUser');
                System.assertEquals(false, isAdmin, 'userCanEditTest - Not passed - isAdmin');
                System.assertEquals(false, isDMTUser, 'userCanEditTest - Not passed - isDMTUser');
            }
        Test.stopTest();
    }
    /* @isTest
    static void fetchCustomerDataFromServiceTest1() {
        final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
        testUser.DES_Country__c = 'ESP';
        testUser.Access_GCE__c = 'RISK';
        update testUser;
        List<String> countriesUser = new List<String>();
        HPG_Geography_Visibility_Configuration__c geographyVisibilityConfig = new HPG_Geography_Visibility_Configuration__c();
        geographyVisibilityConfig.Name = 'Spain';
        geographyVisibilityConfig.Geography__c = 'ESP';
        geographyVisibilityConfig.Risk_Anonymized__c = 'MX';
        geographyVisibilityConfig.Risk_Compacted__c = 'MX';
        geographyVisibilityConfig.No_Risk_Anonymized__c = 'MX';
        geographyVisibilityConfig.No_Risk_Compacted__c = 'MX';
        insert geographyVisibilityConfig;
        Test.startTest();
            System.runAs(testUser) {
                Map<String, Object> retMap = HPG_ClientPositionController.fetchCustomerDataFromService('X00000000000000', countriesUser, '1', '5000');
                Boolean success = (Boolean)retMap.get('success');
                System.assertEquals(true, success, 'fetchCustomerDataFromServiceTest1 - Not passed - success');
            }
        Test.stopTest();
    }
    @isTest
    static void fetchCustomerDataFromServiceTest2() {
        final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
        testUser.DES_Country__c = 'ESP';
        testUser.Access_GCE__c = 'RISK';
        update testUser;
        List<String> countriesUser = new List<String>();
        HPG_Geography_Visibility_Configuration__c geographyVisibilityConfig = new HPG_Geography_Visibility_Configuration__c();
        geographyVisibilityConfig.Name = 'Spain';
        geographyVisibilityConfig.Geography__c = 'ESP';
        geographyVisibilityConfig.Risk_Anonymized__c = 'MX';
        geographyVisibilityConfig.Risk_Compacted__c = 'MX';
        geographyVisibilityConfig.No_Risk_Anonymized__c = 'MX';
        geographyVisibilityConfig.No_Risk_Compacted__c = 'MX';
        insert geographyVisibilityConfig;
        Test.startTest();
            System.runAs(testUser) {
                Map<String, Object> retMap = HPG_ClientPositionController.fetchCustomerDataFromService('X00000000000000', countriesUser, '1', '5000');
                Boolean success = (Boolean)retMap.get('success');
                System.assertEquals(true, success, 'fetchCustomerDataFromServiceTest1 - Not passed - success');
            }
        Test.stopTest();
    }
    @isTest
    static void fetchCustomerDataFromServiceTest3() {
        final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
        testUser.DES_Country__c = 'ESP';
        testUser.Access_GCE__c = 'RISK';
        update testUser;
        List<String> countriesUser = new List<String>();
        countriesUser.add('MX');
        Test.startTest();
            System.runAs(testUser) {
                Map<String, Object> retMap = HPG_ClientPositionController.fetchCustomerDataFromService('X00000000000000', countriesUser, '1', '5000');
                Boolean success = (Boolean)retMap.get('success');
                System.assertEquals(true, success, 'fetchCustomerDataFromServiceTest2 - Not passed - success');
            }
        Test.stopTest();
    }
    @isTest
    static void getUsedTablesDatesTest() {
        final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
        testUser.DES_Country__c = 'ESP';
        testUser.Access_GCE__c = 'RISK';
        update testUser;
        Test.startTest();
            System.runAs(testUser) {
                Map<String,Object> retMap = HPG_ClientPositionController.getUsedTablesDates();
                List<HPG_Utils.PicklistValue_Wrapper> usedTablesDates = (List<HPG_Utils.PicklistValue_Wrapper>)retMap.get('usedTablesDates');
                System.assertEquals(usedTablesDates.size(), 3, 'getUsedTablesDatesTest - Not passed - dateRangeTables');
            }
        Test.stopTest();
    } */
}