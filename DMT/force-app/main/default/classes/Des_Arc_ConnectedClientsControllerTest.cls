/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-01-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
global with sharing class Des_Arc_ConnectedClientsControllerTest {
  
    @TestSetup
    static void testSetup() {
        Local_Client__c lclAcc = TestFactory.createLocalClient();
        Account testAcc1 = new Account();
        testAcc1.Name = 'grupo padre';
        testAcc1.Phone = '646171717';
        testAcc1.DES_Country_Client__c = 'ES';
        insert testAcc1;
        
        Local_Client__c lclAcc2 = TestFactory.createLocalClient();
        final List<Account> lstAccountSearch = [SELECT Id, Name, account_client__c FROM Account WHERE Id =: lclAcc2.Cib_Client__c LIMIT 1];
        System.debug('REVISAR PADRE 2 ' + lstAccountSearch);
        lstAccountSearch[0].account_client__c = 'S'; 
        lstAccountSearch[0].DES_Entity_Hierarchy__c = 'S'; 
        update lstAccountSearch;
        
        AMH_GBL_Account_Relationship__c testRelation2 = new AMH_GBL_Account_Relationship__c();
        testRelation2.AMH_Parent_Account__c = testAcc1.Id;
        testRelation2.AMH_Child_Account__c = lclAcc2.Cib_Client__c;
        testRelation2.AMH_Vision__c = 'Riesgos';
        testRelation2.DES_Main_Parent__c = 'S';
        insert testRelation2;
    }
    
    @isTest
    global static void checksubgroupParent() {
        Test.startTest(); 
        Map<String, List<String>> mappingRiskHeader = new Map<String, List<String>>();
        final List<Account> lstAccount1 = [SELECT Id, Name,  account_group__c FROM Account WHERE Name = 'grupo padre' LIMIT 1];
        Des_Arc_ConnectedClientsController.getAccountHasAnalysis(lstAccount1[0].Id);
        system.assertNotEquals(null,lstAccount1[0].Id, 'not null');
    }
}