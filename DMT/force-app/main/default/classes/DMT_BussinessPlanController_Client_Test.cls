@isTest
public with sharing class DMT_BussinessPlanController_Client_Test {

    private static void assignDmtCommercialActivityPsToUser(Id userId) {
        PermissionSet ps = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = 'DMT_CommercialActivity'
            LIMIT 1
        ];

        Integer psaCount = [
            SELECT COUNT()
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId
            AND PermissionSetId = :ps.Id
        ];

        if (psaCount == 0) {
            insert new PermissionSetAssignment(
                AssigneeId = userId,
                PermissionSetId = ps.Id
            );
        }
    }

    @TestSetup
    static void makeData(){
        DMT_Test_DataFactory.generateAccount();
    }

    @isTest
    static void testGetBussinessPlanSuccess() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            assignDmtCommercialActivityPsToUser(UserInfo.getUserId());

            Account acc = [SELECT Id FROM Account LIMIT 1];
            insert new DMT_Client_Financials__c(
                Account__c = acc.Id,
                Past2_FY_Corp_Synd_Lending_amount__c = 13
            );

            Test.startTest();
            List<DMT_Client_Financials__c> records = DMT_BussinessPlanController_Client.getBussinessPlan(acc.Id);
            Test.stopTest();

            System.assertEquals(13, records.get(0).Past2_FY_Corp_Synd_Lending_amount__c, 'It is equals to the amount from the mock');

        }
    }
}