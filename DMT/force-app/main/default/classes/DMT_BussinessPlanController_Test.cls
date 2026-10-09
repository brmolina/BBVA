@isTest
public with sharing class DMT_BussinessPlanController_Test {

    @TestSetup
    static void makeData(){
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityClient(opp.Id);

        // Create Business Plan records linked to the Opportunity
        List<DMT_Opportunity_Business_Plan__c> bpRecords = new List<DMT_Opportunity_Business_Plan__c>();

        DMT_Opportunity_Business_Plan__c bpGlobal = new DMT_Opportunity_Business_Plan__c();
        bpGlobal.DMT_Opportunity__c = opp.Id;
        bpGlobal.DMT_Client__c = opp.AccountId;
        bpGlobal.DMT_Year__c = String.valueOf(Date.today().year());
        bpGlobal.DMT_Booking_Geography__c = 'GLOBAL';
        bpGlobal.DMT_Currency__c = 'EUR';
        bpGlobal.DMT_Active__c = true;
        bpGlobal.Current_FY_Total_X_Sell_amount__c = 500000;
        bpGlobal.Current_FY_Corp_Synd_Lending_amount__c = 100000;
        bpRecords.add(bpGlobal);

        DMT_Opportunity_Business_Plan__c bpSpain = new DMT_Opportunity_Business_Plan__c();
        bpSpain.DMT_Opportunity__c = opp.Id;
        bpSpain.DMT_Client__c = opp.AccountId;
        bpSpain.DMT_Year__c = String.valueOf(Date.today().year());
        bpSpain.DMT_Booking_Geography__c = 'SPAIN';
        bpSpain.DMT_Currency__c = 'EUR';
        bpSpain.DMT_Active__c = true;
        bpSpain.Current_FY_Total_X_Sell_amount__c = 200000;
        bpRecords.add(bpSpain);

        insert bpRecords;
    }

    @isTest
    static void testGetBussinessPlan() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<DMT_Opportunity_Business_Plan__c> results = DMT_BussinessPlanController.getBussinessPlan(opp.Id, 'GLOBAL');
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Should return Business Plan records');
        for (DMT_Opportunity_Business_Plan__c bp : results) {
            System.assertNotEquals(null, bp.DMT_Year__c, 'Year should be populated');
        }
    }

    @isTest
    static void testGetBussinessPlanByClient() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        List<DMT_Opportunity_Business_Plan__c> results = DMT_BussinessPlanController.getBussinessPlanByClient(acc.Id);
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Should return Business Plan records for client');
        System.assertEquals(2, results.size(), 'Should return both GLOBAL and SPAIN records');
    }

    @isTest
    static void testGetAccountFields() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<Opportunity> results = DMT_BussinessPlanController.getAccountFields(opp.Id);
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Should return Opportunity with Account fields');
    }

    @isTest
    static void testSearchGroupsBlankTerm() {
        Test.startTest();
        List<Map<String, Object>> results = DMT_BussinessPlanController.searchGroups('a');
        Test.stopTest();

        System.assert(results.isEmpty(), 'Should return no results for a search term shorter than 2 characters');
    }

    @isTest
    static void testSearchGroups() {
        Account accountGroup = new Account();
        accountGroup.Name = 'Test Company Group';
        accountGroup.DES_Structure_Type__c = DMT_Constants.TYPE_GROUP;
        accountGroup.DES_Main_Parent__c = accountGroup.Id;
        accountGroup.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(DMT_Constants.TYPE_GROUP).getRecordTypeId();
        insert accountGroup;
        Test.setFixedSearchResults(new List<Id>{ accountGroup.Id });

        Test.startTest();
        List<Map<String, Object>> results = DMT_BussinessPlanController.searchGroups('Test');
        Test.stopTest();

        System.debug('DIAG results=' + JSON.serialize(results));
        System.assert(!results.isEmpty(), 'Should return matching Group Accounts');
        System.assertEquals(String.valueOf(accountGroup.Id), (String) results[0].get('value'), 'Should return the Account Id as value');
    }
}