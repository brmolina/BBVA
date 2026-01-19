@isTest
public with sharing class DMT_DataTableIntervenersController_test {

    @isTest
    static void getApproverMemberFieldsTest() {

        Test.startTest();
        List<Map<String, String>> result = DMT_DataTableIntervenersController.getApproverMemberFields();
        Test.stopTest();

        System.assertNotEquals(null, result, 'The result should not be null');
    }
}