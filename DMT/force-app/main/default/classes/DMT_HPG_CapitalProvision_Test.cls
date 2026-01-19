@isTest
public with sharing class DMT_HPG_CapitalProvision_Test {
    @isTest
    static void wrapperTest() {
        Test.startTest();
            DMT_HPG_CapitalProvision.Wrapper capitalProvision = new DMT_HPG_CapitalProvision.Wrapper();
            capitalProvision.data = new List<DMT_HPG_CapitalProvision.Data>();
            capitalProvision.pagination = new DMT_HPG_CapitalProvision.Pagination();
            capitalProvision.success = true;
            capitalProvision.errorMessage = 'Error Message';
            DMT_HPG_CapitalProvision.Data data = new DMT_HPG_CapitalProvision.Data();
            data.capitalRegyAmount = '';
            data.countryId = '';
            data.countryIfoId = '';
            data.currencyId = '';
            data.customerId = '';
            data.customerName = '';
            data.cutoffDate = '';
            data.eadAmount = '';
            data.economicCapitalEad1Amount = '';
            data.economicCapitalAprAmount = '';
            data.economicCapitalAmount = '';
            data.finalProvisionAmount = '';
            data.groupId = '';
            data.groupName = '';
            data.id = '';
            data.level3groupId = '';
            data.level3groupName = '';
            data.regulatoryEadCapital = '';
            data.regyCapitalAprAmount = '';
            data.residenceCountryId = '';
            data.subGroupId = '';
            data.subGroupName = '';
            data.taxpayerId = '';
            DMT_HPG_CapitalProvision.Pagination pagination = new DMT_HPG_CapitalProvision.Pagination();
            pagination.links = new DMT_HPG_CapitalProvision.Links();
            pagination.links.first = '';
            pagination.links.last = '';
            pagination.links.next = '';
            pagination.links.previous = '';
            pagination.page = 1;
            pagination.pageSize = 300;
            pagination.totalElements = 1;
            pagination.totalPages = 1;
            System.assertEquals(true, capitalProvision.success, 'wrapperTest - Not passed - success');
        Test.stopTest();
    }
}