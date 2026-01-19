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
public with sharing class HPG_CapitalProvision_Test {
    @isTest
    static void wrapperTest() {
        Test.startTest();
            HPG_CapitalProvision.Wrapper capitalProvision = new HPG_CapitalProvision.Wrapper();
            capitalProvision.data = new List<HPG_CapitalProvision.Data>();
            capitalProvision.pagination = new HPG_CapitalProvision.Pagination();
            capitalProvision.success = true;
            capitalProvision.errorMessage = 'Error Message';
            HPG_CapitalProvision.Data data = new HPG_CapitalProvision.Data();
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
            HPG_CapitalProvision.Pagination pagination = new HPG_CapitalProvision.Pagination();
            pagination.links = new HPG_CapitalProvision.Links();
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