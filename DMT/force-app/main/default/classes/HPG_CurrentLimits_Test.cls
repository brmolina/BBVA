/**
* ────────────────────────────────────────────────────────────────────────────────────
* Test class for HPG_CurrentLimits apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.tech@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2024-07-24
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@isTest
public with sharing class HPG_CurrentLimits_Test {
    @isTest
    static void wrapperTest() {
        Test.startTest();
            HPG_CurrentLimits.Wrapper currentLimits = new HPG_CurrentLimits.Wrapper();
            currentLimits.data = new List<HPG_CurrentLimits.Data>();
            currentLimits.success = true;
            currentLimits.errorMessage = 'Error Message';
            HPG_CurrentLimits.Data data = new HPG_CurrentLimits.Data();
            data.authorizedRiskAmount = 0;
            data.bulletIndType = '';
            data.cNotSignedTrConsumptionAmount = 0;
            data.collateralTypeName = '';
            data.committedContractsDisposedAmount = 0;
            data.committedContractsNonDisposedAmount = 0;
            data.consumptionLastLevelId = '';
            data.currencyId = '';
            data.currentApprovedAmount = 0;
            data.customerGroupId = '';
            data.customerId = '';
            data.customersNumber = 0;
            data.cutoffDate = Date.today();
            data.goldenCustomerId = '';
            data.groupId = '';
            data.limitCapitalTradeCnsNumber = 0;
            data.limitDesc = '';
            data.limitExceededActionDesc = '';
            data.limitId = '';
            data.limitType = '';
            data.nonRealCollateralDesc = '';
            data.originType = '';
            data.riskAnalysisExpDate = Date.today();
            data.riskAnalystId = '';
            data.unavailableRiskAmount = 0;
            data.uncommittedContractsDisposedAmount = 0;
            data.uncommittedContractsNonDisposedAmount = 0;
            data.sumDisposedAmount = 0;
            currentLimits.data.add(data);
            System.assertEquals(true, currentLimits.success, 'wrapperTest - Not passed - success');
        Test.stopTest();
    }
}