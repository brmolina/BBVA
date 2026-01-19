/**
* ────────────────────────────────────────────────────────────────────────────────────
* Test class for HPG_GroupPositions apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2024-06-24
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@isTest
public with sharing class HPG_GroupPositions_Test {
    @isTest
    static void wrapperTest() {
        Test.startTest();
            HPG_GroupPositions.Wrapper groupPositions = new HPG_GroupPositions.Wrapper();
            groupPositions.data = new HPG_GroupPositions.Data();
            groupPositions.data.groupId = '';
            groupPositions.success = true;
            groupPositions.errorMessage = 'Error Message';
            System.assertEquals(true, groupPositions.success, 'wrapperTest - Not passed - success');
        Test.stopTest();
    }
}