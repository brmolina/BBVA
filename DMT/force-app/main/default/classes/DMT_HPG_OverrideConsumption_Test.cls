/**
* ────────────────────────────────────────────────────────────────────────────────────
* Test class for HPG_OverrideConsumption apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-11-09
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@isTest
public with sharing class DMT_HPG_OverrideConsumption_Test {

    @isTest
    public static void test1() {
        Test.startTest();
        DMT_HPG_OverrideConsumption.testing();
        DMT_HPG_Consumption.testing();
        DMT_HPG_CapitalProvision.testing();
        DMT_HPG_ConnectedClients.testing();
        Test.stopTest();
    }
}