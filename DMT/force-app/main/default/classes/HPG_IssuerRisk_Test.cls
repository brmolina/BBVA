/**
* ────────────────────────────────────────────────────────────────────────────────────
* Test class for HPG_IssuerRisk apex class
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
public with sharing class HPG_IssuerRisk_Test {
	@isTest
	static void wrapperTest() {
		Test.startTest();
            HPG_IssuerRisk.Wrapper issuerRisk = new HPG_IssuerRisk.Wrapper();
			issuerRisk.data = new List<HPG_IssuerRisk.Data>();
        	issuerRisk.pagination = new HPG_IssuerRisk.Pagination();
        	issuerRisk.success = true;
			issuerRisk.errorMessage = 'Error Message';
			HPG_IssuerRisk.Data data = new HPG_IssuerRisk.Data();
			data.assetTypeId = '';
			data.businessAreaName = '';
			data.countryId = '';
			data.countryIfoId = '';
			data.currencyId = '';
			data.currencyPositionId = '';
			data.customerId = '';
			data.customerName = '';
			data.cutoffDate =
			data.glLocalAccountingEx1Id = '';
			data.groupId = '';
			data.groupName = '';
			data.ibondSectorDesc = '';
			data.instrumentTypeCodeId = '';
			data.issueId = '';
			data.originDataDate = Date.newInstance(2023,09,11);
			data.pfolioFrmWkInvstPlcyDesc = '';
			data.pfolioFwkInvstPlcyDesc = '';
			data.portfolioCountryId = '';
			data.residenceCountryId = '';
			data.securMaturityDate = Date.newInstance(2023,09,11);
			data.seniorityTextDesc = '';
			data.subGroupId = '';
			data.level3groupName = '';
			data.level3groupId = '';
			data.subGroupName = '';
			data.taxpayerId = '';
			data.totalNominalEurAmount = 1.00;
			HPG_IssuerRisk.Pagination pagination = new HPG_IssuerRisk.Pagination();
			pagination.links = new HPG_IssuerRisk.Links();
			pagination.links.first = '';
			pagination.links.last = '';
			pagination.links.next = '';
			pagination.links.previous = '';
			pagination.page = 1;
			pagination.pageSize = 300;
			pagination.totalElements = 1;
			pagination.totalPages = 1;
            System.assertEquals(true, issuerRisk.success, 'wrapperTest - Not passed - success');
		Test.stopTest();
	}
}