/**
* ────────────────────────────────────────────────────────────────────────────────────
* Test class for DMT_HPG_Consumption_Test apex class
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
public with sharing class DMT_HPG_Consumption_Test {
@isTest
    static void wrapperTest() {
        Test.startTest();
            DMT_HPG_Consumption.Wrapper consumption = new DMT_HPG_Consumption.Wrapper();
            consumption.data = new List<DMT_HPG_Consumption.Data>();
            consumption.pagination = new DMT_HPG_Consumption.Pagination();
            consumption.success = true;
            consumption.errorMessage = 'Error Message';
            DMT_HPG_Consumption.Data data = new DMT_HPG_Consumption.Data();
            data.classConsumptions = new List<DMT_HPG_Consumption.ClassConsumption>();
            DMT_HPG_Consumption.ClassConsumption classConsumption = new DMT_HPG_Consumption.ClassConsumption();
            classConsumption.authorizedRiskAmount = 1.00;
            classConsumption.cNotSignedTrConsumptionAmount = 1.00;
            classConsumption.committedContractsDisposedAmount = 1.00;
            classConsumption.committedContractsNonDisposedAmount = 1.00;
            classConsumption.consumptionLastLevelId = '';
            classConsumption.unavailableRiskAmount = 1.00;
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
            DMT_HPG_Consumption.Pagination pagination = new DMT_HPG_Consumption.Pagination();
            pagination.links = new DMT_HPG_Consumption.Links();
            pagination.links.first = '';
            pagination.links.last = '';
            pagination.links.next = '';
            pagination.links.previous = '';
            pagination.page = 1;
            pagination.pageSize = 50;
            pagination.totalElements = 1;
            pagination.totalPages = 1;
            System.assertEquals(true, consumption.success, 'wrapperTest - Not passed - success');
        Test.stopTest();
    }
}