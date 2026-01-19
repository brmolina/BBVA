/**
* ────────────────────────────────────────────────────────────────────────────────────
* Test class for HPG_CapitalProvision apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-11-08
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@isTest
public with sharing class HPG_Consumption_Test {
    @isTest
    static void wrapperTest() {
        Test.startTest();
            HPG_Consumption.Wrapper consumption = new HPG_Consumption.Wrapper();
            consumption.data = new List<HPG_Consumption.Data>();
            consumption.pagination = new HPG_Consumption.Pagination();
            consumption.success = true;
            consumption.errorMessage = 'Error Message';
            HPG_Consumption.Data data = new HPG_Consumption.Data();
            data.classConsumptions = new List<HPG_Consumption.ClassConsumption>();
            HPG_Consumption.ClassConsumption classConsumption = new HPG_Consumption.ClassConsumption();
            classConsumption.authorizedRiskAmount = 1.00;
            classConsumption.cNotSignedTrConsumptionAmount = 1.00;
            classConsumption.committedContractsDisposedAmount = 1.00;
            classConsumption.committedContractsNonDisposedAmount = 1.00;
            classConsumption.consumptionLastLevelId = '';
            classConsumption.unavailableRiskAmount = 1.00;
            classConsumption.unavailableRiskAmountAndDraft = 1.00;
            classConsumption.uncommittedContractsDisposedAmount = 1.00;
            classConsumption.uncommittedContractsNonDisposedAmount = 1.00;
            data.classConsumptions.add(classConsumption);
            data.countryId = '';
            data.countryIfoId = '';
            data.customerId = '';
            data.customerName = '';
            data.cutoffDate = Date.newInstance(2023,09,11);
            data.goldenCustomerId = '';
            data.groupHeaderName = '';
            data.groupId = '';
            data.groupName = '';
            data.residenceCountryId = '';
            data.subGroupId = '';
            data.level3groupName = '';
            data.level3groupId = '';
            data.subGroupName = '';
            data.taxpayerId = '';
            HPG_Consumption.Pagination pagination = new HPG_Consumption.Pagination();
            pagination.links = new HPG_Consumption.Links();
            pagination.links.first = '';
            pagination.links.last = '';
            pagination.links.next = '';
            pagination.links.previous = '';
            pagination.page = 1;
            pagination.pageSize = 300;
            pagination.totalElements = 1;
            pagination.totalPages = 1;
            System.assertEquals(true, consumption.success, 'wrapperTest - Not passed - success');
        Test.stopTest();
    }
}