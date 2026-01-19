@isTest
public with sharing class DMT_DataTableCopyPasteController_test {

    @TestSetup
    static void setup() {
        User user = DMT_Test_DataFactory.generateUserWithoutPermissions();
    }

    @isTest
    private static void getUserIdsByUsernamesTest() {
        User user = [SELECT Id, Username FROM User WHERE Alias = 'ATest' LIMIT 1];

        List<String> usernames = new List<String>{user.Username};

        Test.startTest();
        Map<String, Id> result = DMT_DataTableCopyPasteController.getUserIdsByUsernames(usernames);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Expected a valid result, but got null.');
    }
}