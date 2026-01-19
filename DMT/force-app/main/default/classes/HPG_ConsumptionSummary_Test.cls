/**
* ------------------------------------------------------------------------------------------------
* @Name     HPG_ConsumptionSummary_Test
* @Author   Global Hub
* @Date     Created: 2023-09-07
* ------------------------------------------------------------------------------------------------
* @Description Test class for HPG_ConsumptionSummary
* ------------------------------------------------------------------------------------------------
* @Changes
*
* | 2023-09-07 ivan.garces.contractor@bbva.com
*             Class Creation
* -----------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class HPG_ConsumptionSummary_Test {
    @isTest
    static void wrapperTest(){
        HPG_ConsumptionSummary.Wrapper consumptionSummary = new HPG_ConsumptionSummary.Wrapper();
        consumptionSummary.data = new List<HPG_ConsumptionSummary.Data>();
        consumptionSummary.pagination = new HPG_ConsumptionSummary.Pagination();
        consumptionSummary.success = true;
        consumptionSummary.errorMessage = 'Error Message';
        HPG_ConsumptionSummary.Data data = new HPG_ConsumptionSummary.Data();
        data.id = '';
        data.consumptionLastLevelId = '';
        data.catalogs = new List<HPG_ConsumptionSummary.Catalog>();
        HPG_ConsumptionSummary.Catalog catalog = new HPG_ConsumptionSummary.Catalog();
        catalog.productTypeDesc = '';
        catalog.authorizedRiskAmount = 1.00;
        catalog.committedContractsDisposedAmount = 1.0000000;
        catalog.cNotSignedTrConsumptionAmount = 1.00;
        catalog.uncommittedContractsDisposedAmount = 1.00;
        catalog.committedContractsNonDisposedAmount = 1.00;
        catalog.uncommittedContractsNonDisposedAmount = 1.00;
        catalog.unavailableRiskAmount = 1.0000000;
        catalog.unauthorizedCount = 1;
        catalog.cutoffDate = Date.newInstance(2023,09,11);
        data.catalogs.add(catalog);
        HPG_ConsumptionSummary.Pagination pagination = new HPG_ConsumptionSummary.Pagination();
        pagination.links = new HPG_ConsumptionSummary.Links();
        pagination.links.first = '';
        pagination.links.last = '';
        pagination.links.next = '';
        pagination.links.previous = '';
        pagination.page = 1;
        pagination.pageSize = 300;
        pagination.totalElements = 1;
        pagination.totalPages = 1;
        System.assertEquals(true, consumptionSummary.success, 'wrapperTest - Not passed - success');
    }
}