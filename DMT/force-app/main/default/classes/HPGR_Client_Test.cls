/*-------------------------------------------------------------------------------------------
* @Name     HPGR_Client_Test
* @Author   torcuato.tejada.tech@bbva.com
*           cosme.alcazar.tech@bbva.com
* @Date     Created: 2024-07-18
* -------------------------------------------------------------------------------------------
* @Description Test class for 'HPGR_Client' apex class
* -------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class HPGR_Client_Test {

    static final String EXTERNAL_APP_ICON = 'hpgr__External_App_Icon';
    static final String EXTERNAL_APP_URL = '/lightning/cmp/c__dMT_page_Deal_Manament?c__recordAcc=';
    static final String CLIENT_CODE = 'X00000000000000';
    static final String TEST_ACCOUNT_NAME = 'HPGR Test Account';

    @IsTest
    static void getRecordCodeTestLocalClient() {
        Account testAccount = new Account();
        testAccount.Name = TEST_ACCOUNT_NAME;
        insert testAccount;
        Local_Client__c localClient = new Local_Client__c();
        localClient.Cib_Client__c = testAccount.Id;
        localClient.Alpha_code__c = CLIENT_CODE;
        insert localClient;
        Test.startTest();
            HPGR_Client hpgrClient = new HPGR_Client();
            Map<String, Object> retmap = hpgrClient.getRecordCode(localClient.Id);
            Boolean success = (Boolean)retMap.get('success');
            String recordCode = (String)retMap.get('recordCode');
            System.assertEquals(true, success, 'getRecordCodeTestLocalClient - Not passed - success');
            System.assertEquals(localClient.Alpha_code__c, recordCode, 'getRecordCodeTestLocalClient - Not passed - recordCode');
        Test.stopTest();
    }

    @IsTest
    static void getRecordCodeTestLocalClientError() {
        Account testAccount = new Account();
        testAccount.Name = TEST_ACCOUNT_NAME;
        insert testAccount;
        Local_Client__c localClient = new Local_Client__c();
        localClient.Cib_Client__c = testAccount.Id;
        insert localClient;
        Test.startTest();
            HPGR_Client hpgrClient = new HPGR_Client();
            Map<String, Object> retmap = hpgrClient.getRecordCode(localClient.Id);
            Boolean success = (Boolean)retMap.get('success');
            String errorMessage = (String)retMap.get('errorMessage');
            System.assertEquals(false, success, 'getRecordCodeTestLocalClientError - Not passed - success');
            System.assertEquals(Label.hpgr.Error_Get_Data, errorMessage, 'getRecordCodeTestLocalClientError - Not passed - errorMessage');
        Test.stopTest();
    }

    @IsTest
    static void getRecordCodeTestAccount1() {
        Account testAccount = new Account();
        testAccount.Name = TEST_ACCOUNT_NAME;
        testAccount.DES_Group_Code__c = CLIENT_CODE;
        insert testAccount;
        Test.startTest();
            HPGR_Client hpgrClient = new HPGR_Client();
            Map<String, Object> retmap = hpgrClient.getRecordCode(testAccount.Id);
            Boolean success = (Boolean)retMap.get('success');
            String recordCode = (String)retMap.get('recordCode');
            System.assertEquals(true, success, 'getRecordCodeTestAccount1 - Not passed - success');
            System.assertEquals(testAccount.DES_Group_Code__c, recordCode, 'getRecordCodeTestAccount1 - Not passed - errorMessage');
        Test.stopTest();
    }

    @IsTest
    static void getRecordCodeTestAccount2() {
        Account testAccount = new Account();
        testAccount.Name = TEST_ACCOUNT_NAME;
        insert testAccount;
        Local_Client__c localClient = new Local_Client__c();
        localClient.Cib_Client__c = testAccount.Id;
        localClient.Alpha_code__c = CLIENT_CODE;
        insert localClient;
        Test.startTest();
            HPGR_Client hpgrClient = new HPGR_Client();
            Map<String, Object> retmap = hpgrClient.getRecordCode(testAccount.Id);
            Boolean success = (Boolean)retMap.get('success');
            String recordCode = (String)retMap.get('recordCode');
            System.assertEquals(true, success, 'getRecordCodeTestAccount2 - Not passed - success');
            System.assertEquals(localClient.Alpha_code__c, recordCode, 'getRecordCodeTestAccount2 - Not passed - errorMessage');
        Test.stopTest();
    }

    @IsTest
    static void getRecordCodeTestAccountError() {
        Account testAccount = new Account();
        testAccount.Name = TEST_ACCOUNT_NAME;
        insert testAccount;
        Local_Client__c localClient = new Local_Client__c();
        localClient.Cib_Client__c = testAccount.Id;
        insert localClient;
        Test.startTest();
            HPGR_Client hpgrClient = new HPGR_Client();
            Map<String, Object> retmap = hpgrClient.getRecordCode(testAccount.Id);
            Boolean success = (Boolean)retMap.get('success');
            String errorMessage = (String)retMap.get('errorMessage');
            System.assertEquals(false, success, 'getRecordCodeTestAccountError - Not passed - success');
            System.assertEquals(Label.hpgr.Error_Get_Data, errorMessage, 'getRecordCodeTestAccountError - Not passed - errorMessage');
        Test.stopTest();
    }

    @IsTest
    static void getRecordCodeTestError() {
        final Id profileId = [SELECT Id FROM Profile LIMIT 1].Id;
        Test.startTest();
            HPGR_Client hpgrClient = new HPGR_Client();
            Map<String, Object> retmap = hpgrClient.getRecordCode(profileId);
            Boolean success = (Boolean)retMap.get('success');
            String errorMessage = (String)retMap.get('errorMessage');
            System.assertEquals(false, success, 'getRecordCodeTestError - Not passed - success');
            System.assertEquals(Label.hpgr.Error_Get_Data, errorMessage, 'getRecordCodeTestError - Not passed - errorMessage');
        Test.stopTest();
    }

    @IsTest
    static void getGroupDataTestAccount() {
        Account testAccount = new Account();
        testAccount.Name = TEST_ACCOUNT_NAME;
        testAccount.DES_Group_Code__c = CLIENT_CODE;
        insert testAccount;
        Test.startTest();
            HPGR_Client hpgrClient = new HPGR_Client();
            Map<String, Object> retmap = hpgrClient.getGroupData(CLIENT_CODE, CLIENT_CODE);
            Boolean success = (Boolean)retMap.get('success');
            Id groupId = (Id)retMap.get('groupId');
            String groupName = (String)retMap.get('groupName');
            String groupCode = (String)retMap.get('groupCode');
            System.assertEquals(true, success, 'getGroupDataTestAccount - Not passed - success');
            System.assertEquals(testAccount.Id, groupId, 'getGroupDataTestAccount - Not passed - recordCode');
            System.assertEquals(TEST_ACCOUNT_NAME, groupName, 'getGroupDataTestAccount - Not passed - recordCode');
            System.assertEquals(CLIENT_CODE, groupCode, 'getGroupDataTestAccount - Not passed - recordCode');
        Test.stopTest();
    }

    @IsTest
    static void getGroupDataTestLocalClient() {
        Account testAccount = new Account();
        testAccount.Name = TEST_ACCOUNT_NAME;
        insert testAccount;
        Local_Client__c localClient = new Local_Client__c();
        localClient.Cib_Client__c = testAccount.Id;
        localClient.Alpha_code__c = CLIENT_CODE;
        insert localClient;
        Test.startTest();
            HPGR_Client hpgrClient = new HPGR_Client();
            Map<String, Object> retmap = hpgrClient.getGroupData(CLIENT_CODE, CLIENT_CODE);
            Boolean success = (Boolean)retMap.get('success');
            Id groupId = (Id)retMap.get('groupId');
            String groupName = (String)retMap.get('groupName');
            String groupCode = (String)retMap.get('groupCode');
            System.assertEquals(true, success, 'getGroupDataTestLocalClient - Not passed - success');
            System.assertEquals(testAccount.Id, groupId, 'getGroupDataTestLocalClient - Not passed - recordCode');
            System.assertEquals(TEST_ACCOUNT_NAME, groupName, 'getGroupDataTestLocalClient - Not passed - recordCode');
            System.assertEquals(CLIENT_CODE, groupCode, 'getGroupDataTestLocalClient - Not passed - recordCode');
        Test.stopTest();
    }

    @IsTest
    static void getGroupDataTestError() {
        Test.startTest();
            HPGR_Client hpgrClient = new HPGR_Client();
            Map<String, Object> retmap = hpgrClient.getGroupData(CLIENT_CODE, CLIENT_CODE);
            Boolean success = (Boolean)retMap.get('success');
            String errorMessage = (String)retMap.get('errorMessage');
            System.assertEquals(false, success, 'getGroupDataTestError - Not passed - success');
            System.assertEquals(Label.hpgr.Error_Get_Data, errorMessage, 'getGroupDataTestError - Not passed - errorMessage');
        Test.stopTest();
    }

    @IsTest
    static void getAdditionalInfoTest() {
        Account testAccount = new Account();
        testAccount.Name = TEST_ACCOUNT_NAME;
        insert testAccount;
        cstk__Toolkit__c toolkit = new cstk__Toolkit__c();
        toolkit.cstk__account_id__c = testAccount.Id;
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
            HPGR_Client hpgrClient = new HPGR_Client();
            String triData = hpgrClient.getAdditionalInfo(testAccount.Id);
            system.assertEquals(' - TRI 1 - CCA 1.5 - CTA 2.3', triData, 'getAdditionalInfoTest - Not passed - triData');
        Test.stopTest();
    }

    @IsTest
    static void getExternalAppInfoTest() {
        Account testAccount = new Account();
        testAccount.Name = TEST_ACCOUNT_NAME;
        insert testAccount;
        Test.startTest();
            HPGR_Client hpgrClient = new HPGR_Client();
            Map<String, Object> retMap = hpgrClient.getExternalAppInfo(testAccount.Id);
            String externalAppIcon = (String)retMap.get('externalAppIcon');
            String externalAppName = (String)retMap.get('externalAppName');
            String externalAppUrl = (String)retMap.get('externalAppUrl');
            system.assertEquals(EXTERNAL_APP_ICON, externalAppIcon, 'getExternalAppInfoTest - Not passed - externalAppIcon');
            system.assertEquals(Label.GoToDMTLines, externalAppName, 'getExternalAppInfoTest - Not passed - externalAppName');
            system.assertEquals(EXTERNAL_APP_URL + testAccount.Id, externalAppUrl, 'getExternalAppInfoTest - Not passed - externalAppUrl');
        Test.stopTest();
    }
}