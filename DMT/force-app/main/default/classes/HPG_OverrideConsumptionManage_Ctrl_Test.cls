/**
* ────────────────────────────────────────────────────────────────────────────────────
* Test class for HPG_OverrideConsumptionManage_Ctrl Apex Class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-11-15
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@isTest
public with sharing class HPG_OverrideConsumptionManage_Ctrl_Test {
    @IsTest
    static void testInitialData() {
        final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
        Map<String, Object> params = new Map<String, Object>();
        params.put('action', 'CREATE');
        params.put('customerId', 'XXXXXXXXXXXX');
        params.put('consumptionLastLevelId', '');
        Test.startTest();
            System.runAs(testUser) {
                Map<String, Object> retMap = HPG_OverrideConsumptionManage_Ctrl.initialData(params);
                System.assertEquals(Date.today() - 1, (Date)retMap.get('overrideEndDateMin'), 'testInitialData - Not passed - overrideEndDateMin');
            }
        Test.stopTest();
    }
    @IsTest
    static void testValidateChangeField() {
        Map<String, Object> paramsNew = new Map<String, Object>();
        paramsNew.put('overrideStartDate', '2023-08-12');
        paramsNew.put('overrideEndDate', '2023-08-11');
        Test.startTest();
            Map<String, Object> retMap = HPG_OverrideConsumptionManage_Ctrl.validateChangeField(paramsNew);
            System.assertEquals(Date.today() - 1, (Date)retMap.get('overrideStartDateMin'), 'testValidateChangeField - Not passed - overrideStartDateMin');
        Test.stopTest();
    }
    @IsTest
    static void testValidateChangeFieldEmpty() {
        Map<String, Object> paramsNew = new Map<String, Object>();
        paramsNew.put('overrideStartDate', '');
        paramsNew.put('overrideEndDate', '');
        Test.startTest();
            Map<String, Object> retMap = HPG_OverrideConsumptionManage_Ctrl.validateChangeField(paramsNew);
            System.assertEquals(Date.today() - 1, (Date)retMap.get('overrideStartDateMin'), 'testValidateChangeFieldEmpty - Not passed - overrideStartDateMin');
        Test.stopTest();
    }
    /*@IsTest
    static void testManageOverrideConsumptionCreate() {
        final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
        Test.startTest();
            System.runAs(testUser) {
                Map<String, Object> paramsNew = new Map<String, Object>();
                paramsNew.put('action', 'CLIENT');
                paramsNew.put('customerId', 'G00000000000000');
                paramsNew.put('internalContractCodeDesc', '1234567890');
                String today = Datetime.now().format('yyyy-MM-dd');
                paramsNew.put('overrideUploadDate', today);
                paramsNew.put('consumptionLastLevelId', 'Treasury risk');
                paramsNew.put('committedContractsDisposedAmount', '100');
                paramsNew.put('uncommittedContractsDisposedAmount', '100');
                paramsNew.put('committedContractsNonDisposedAmount', '100');
                paramsNew.put('uncommittedContractsNonDisposedAmount', '100');
                paramsNew.put('authorizedRiskAmount', '100');
                paramsNew.put('riskAnalystId', HPG_utils.getFederationIdentifier());
                paramsNew.put('overrideStartDate', today);
                paramsNew.put('overrideEndDate', today);
                paramsNew.put('overrideComments', 'Comment');
                paramsNew.put('currencyId', 'EUR');
                HPG_OverrideConsumption.Wrapper overrideConsumption = HPG_OverrideConsumptionManage_Ctrl.manageOverrideConsumption(paramsNew);
                System.assertEquals(true, overrideConsumption.success, 'testManageOverrideConsumptionCreate - Not passed - success');
            }
        Test.stopTest();
    }
    @IsTest
    static void testManageOverrideConsumptionEdit() {
        final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
		testUser.DES_Country__c = 'ESP';
		testUser.Access_GCE__c = 'RISK';
		update testUser;
        Test.startTest();
            System.runAs(testUser) {
                Map<String, Object> paramsNew = new Map<String, Object>();
                paramsNew.put('action', 'EDIT');
                paramsNew.put('customerId', 'G00000000000000');
                paramsNew.put('internalContractCodeDesc', '1234567890');
                String today = Datetime.now().format('yyyy-MM-dd');
                paramsNew.put('overrideUploadDate', today);
                paramsNew.put('consumptionLastLevelId', 'Treasury risk');
                paramsNew.put('committedContractsDisposedAmount', '100');
                paramsNew.put('uncommittedContractsDisposedAmount', '100');
                paramsNew.put('committedContractsNonDisposedAmount', '100');
                paramsNew.put('uncommittedContractsNonDisposedAmount', '100');
                paramsNew.put('authorizedRiskAmount', '100');
                paramsNew.put('riskAnalystId', HPG_utils.getFederationIdentifier());
                paramsNew.put('overrideStartDate', today);
                paramsNew.put('overrideEndDate', today);
                paramsNew.put('overrideComments', 'Comment');
                paramsNew.put('currencyId', 'EUR');
                HPG_OverrideConsumption.Wrapper overrideConsumption = HPG_OverrideConsumptionManage_Ctrl.manageOverrideConsumption(paramsNew);
                System.assertEquals(true, overrideConsumption.success, 'testManageOverrideConsumptionEdit - Not passed - success');
            }
        Test.stopTest();
    } */
    @IsTest
    static void testManageOverrideConsumptionMissing() {
        final Profile profileArce = [SELECT Id FROM Profile WHERE Name = 'BBVA Desktop ARCE'];
        User testUser = TestFactory.createUser('testUserNameHPG', 'BBVA Desktop ARCE');
        testUser.DES_Country__c = 'ESP';
        testUser.Access_GCE__c = 'RISK';
        update testUser;
        Map<String, Object> paramsNew = new Map<String, Object>();
        Test.startTest();
            System.runAs(testUser) {
                HPG_OverrideConsumption.Wrapper overrideConsumption = HPG_OverrideConsumptionManage_Ctrl.manageOverrideConsumption(paramsNew);
                System.assertEquals(false, overrideConsumption.success, 'testManageOverrideConsumptionMissing - Not passed - success');
            }
        Test.stopTest();
    }
}