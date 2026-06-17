@isTest
private without sharing class DMT_LineConcurrencyControllerTest {

    @IsTest
    static void testGetLineLockStatus() {
        String currentUserId = UserInfo.getUserId();

        DMT_Line__c line = new DMT_Line__c(
            DMT_Line_Lock__c = currentUserId
        );
        insert line;

        Test.startTest();
        String result = DMT_LineConcurrencyController.getLineLockStatus(line.Id);
        Test.stopTest();

        System.assertEquals(currentUserId, result);
    }
}