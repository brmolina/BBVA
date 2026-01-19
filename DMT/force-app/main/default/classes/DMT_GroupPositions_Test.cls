/**
* ────────────────────────────────────────────────────────────────────────────────────
* Test class for DMT_GroupPositions apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @version     1.0
* @created     2024-02-28
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@isTest
public with sharing class DMT_GroupPositions_Test {
    @isTest
    static void wrapperTest() {
        Test.startTest();
            DMT_GroupPositions.Wrapper groupPositions = new DMT_GroupPositions.Wrapper();
            groupPositions.data = new DMT_GroupPositions.Data();
            groupPositions.data.groupId = '';
            groupPositions.success = true;
            groupPositions.errorMessage = 'Error Message';
            System.assertEquals(true, groupPositions.success, 'wrapperTest - Not passed');
        Test.stopTest();
    }
}