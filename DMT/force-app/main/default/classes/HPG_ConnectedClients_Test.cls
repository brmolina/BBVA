/**
* ────────────────────────────────────────────────────────────────────────────────────
* Test class for HPG_ConnectedClients apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-11-13
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@isTest
public with sharing class HPG_ConnectedClients_Test {
    @isTest
    static void wrapperTest() {
        Test.startTest();
        HPG_ConnectedClients.Wrapper connectedClients = new HPG_ConnectedClients.Wrapper();
            List<HPG_ConnectedClients.Data> dataList = new List<HPG_ConnectedClients.Data>();
            HPG_ConnectedClients.Data data = new HPG_ConnectedClients.Data();
            data.countryId = '';
            data.countryIfoId = '';
            data.customerId = '';
            data.customerName = '';
            data.cutoffDate = Date.newInstance(2023,09,11);
            data.detailConsumptions = new List<HPG_ConnectedClients.DetailConsumption>();
            HPG_ConnectedClients.DetailConsumption detailConsumption = new HPG_ConnectedClients.DetailConsumption();
            detailConsumption.unavailableRiskAmount = '';
            detailConsumption.consumptionLastLevelId = '';
            data.detailConsumptions.add(detailConsumption);
            data.groupId = '';
            data.groupName = '';
            data.level3groupId = '';
            data.level3groupName = '';
            data.residenceCountryId = '';
            data.subGroupId = '';
            data.subGroupName = '';
            data.taxpayerId = '';
            HPG_ConnectedClients.Pagination pagination = new HPG_ConnectedClients.Pagination();
            pagination.page = 1;
            pagination.pageSize = 300;
            pagination.totalElements = 1;
            pagination.totalPages = 1;
            HPG_ConnectedClients.Links links = new HPG_ConnectedClients.Links();
            links.first = '';
            links.last = '';
            links.next = '';
            links.previous = '';
            pagination.links = links;
            dataList.add(data);
            connectedClients.data = dataList;
            connectedClients.pagination = pagination;
            connectedClients.errorMessage = 'Error Message';
            connectedClients.success = true;
            System.assertEquals(true, connectedClients.success, 'wrapperTest - Not passed - success');
        Test.stopTest();
    }
}