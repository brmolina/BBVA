@isTest
public with sharing class DMT_WithoutSharingDAO_Test {

    @testSetup
    static void makeData() {
        DMT_Test_DataFactory.generateApprover();
        DMT_Test_DataFactory.generateUserWithoutPermissions();
    }

    @isTest
    static void testInsertRecords() {
        DMT_Approver__c approver = new DMT_Approver__c();
        approver.Name = 'TestWithoutSharing';
        approver.DMT_External_Id__c = 'TestExternalWithoutSharing';
        approver.DMT_Approver_Code__c = '12222555';

        Test.startTest();
        DMT_WithoutSharingDAO.insertRecord(approver);
        Test.stopTest();

        List<DMT_Approver__c> approverList = [SELECT Id FROM DMT_Approver__c WHERE Name LIKE '%WithoutSharing%'];

        System.assertEquals(approverList.size(), 1, 'The record is inserted');

    }

    @isTest
    static void testInsertRecordsWithUserNoPermissions() {
        DMT_Approver__c approver = new DMT_Approver__c();
        approver.Name = 'TestWithoutSharing';
        approver.DMT_External_Id__c = 'TestExternalWithoutSharing';
        approver.DMT_Approver_Code__c = '12222555';

        User userTest = [SELECT Id FROM User where LastName = 'Without Permissions' LIMIT 1];

        Test.startTest();
        system.runAs(userTest) {
            DMT_WithoutSharingDAO.insertRecord(approver);
        }

        Test.stopTest();

        List<DMT_Approver__c> approverList = [SELECT Id FROM DMT_Approver__c WHERE Name LIKE '%WithoutSharing%'];

        System.assertEquals(approverList.size(), 0, 'The record is not inserted');

    }

    @isTest
    static void testUpdateRecordsWithUserNoPermissions() {
        DMT_Approver__c approver = [SELECT Id FROM DMT_Approver__c LIMIT 1];

        approver.Name = 'TestApproverDataFactoryUpdate';

        User userTest = [SELECT Id FROM User where LastName = 'Without Permissions' LIMIT 1];

        Test.startTest();
        system.runAs(userTest) {
            DMT_WithoutSharingDAO.updateRecord(approver);
        }
        Test.stopTest();

        List<DMT_Approver__c> approverList = [SELECT Id, Name FROM DMT_Approver__c];

        System.assert(!approverList.get(0).Name.contains('Update'), 'The record is not updated');

    }

    @isTest
    static void testUpdateRecords() {
        DMT_Approver__c approver = [SELECT Id FROM DMT_Approver__c LIMIT 1];

        approver.Name = 'TestApproverDataFactoryUpdate';

        Test.startTest();
        DMT_WithoutSharingDAO.updateRecord(approver);
        Test.stopTest();

        List<DMT_Approver__c> approverList = [SELECT Id, Name FROM DMT_Approver__c];

        System.assert(approverList.get(0).Name.contains('Update'), 'The record is updated');

    }

    @isTest
    static void testQuery() {
        String query = 'SELECT Id FROM DMT_Approver__c LIMIT 1';

        Test.startTest();
        sObject[] approvers = DMT_WithoutSharingDAO.query(query, 'DMT_Approver__c');
        Test.stopTest();

        System.assertEquals(approvers.size(), 1, 'The query works');

    }

    @isTest
    static void testEmptyQuery() {
        String query = '';

        Test.startTest();
        sObject[] approvers = DMT_WithoutSharingDAO.query(query, 'DMT_Approver__c');
        Test.stopTest();

        System.assertEquals(approvers.size(), 0, 'The query is empty so returns nothing');

    }

    @isTest
    static void testDeleteRecordById() {
        DMT_Approver__c approver = [SELECT Id FROM DMT_Approver__c LIMIT 1];

        Test.startTest();
        DMT_WithoutSharingDAO.deleteRecordById(approver.Id);
        Test.stopTest();

        List<DMT_Approver__c> approverList = [SELECT Id FROM DMT_Approver__c WHERE Id = :approver.Id];

        System.assertEquals(0, approverList.size(), 'The record should be deleted');
    }
    
    @isTest
    static void testDeleteRecord() {
        DMT_Approver__c approver = [SELECT Id FROM DMT_Approver__c LIMIT 1];

        Test.startTest();
        DMT_WithoutSharingDAO.deleteRecord(approver);
        Test.stopTest();

        List<DMT_Approver__c> approverList = [SELECT Id FROM DMT_Approver__c WHERE Id = :approver.Id];

        System.assertEquals(0, approverList.size(), 'The record should be deleted');
    }

    @isTest
    static void testDeleteRecordByIdWithUserNoPermissions() {
        DMT_Approver__c approver = [SELECT Id FROM DMT_Approver__c LIMIT 1];

        User userTest = [SELECT Id FROM User WHERE LastName = 'Without Permissions' LIMIT 1];

        Test.startTest();
        system.runAs(userTest) {
            DMT_WithoutSharingDAO.deleteRecordById(approver.Id);
        }
        Test.stopTest();

        List<DMT_Approver__c> approverList = [SELECT Id FROM DMT_Approver__c WHERE Id = :approver.Id];

        System.assertEquals(1, approverList.size(), 'The record should not be deleted when user lacks permissions');
    }

}