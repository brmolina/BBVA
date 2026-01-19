/**
* ────────────────────────────────────────────────────────────────────────────────────
* Test class for HPG_Derivatives apex class
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
public with sharing class HPG_Derivatives_Test {
	@isTest
	static void wrapperTest() {
		Test.startTest();
            HPG_Derivatives.Wrapper derivatives = new HPG_Derivatives.Wrapper();
			derivatives.data = new List<HPG_Derivatives.Data>();
        	derivatives.pagination = new HPG_Derivatives.Pagination();
        	derivatives.success = true;
			derivatives.errorMessage = 'Error Message';
			HPG_Derivatives.Data data = new HPG_Derivatives.Data();
			data.countryId = '';
			data.countryIfoId = '';
			data.customerId = '';
			data.customerName = '';
			data.detailDerivatives = new List<HPG_Derivatives.DetailDerivate>();
			HPG_Derivatives.DetailDerivate detailDerivative = new HPG_Derivatives.DetailDerivate();
			detailDerivative.creditRiskTypeName = '';
			detailDerivative.ctptyRiskExpsrAmount = 1.00;
			detailDerivative.currencyId = '';
			detailDerivative.maturityTermNumber = 1.00;
			detailDerivative.productType = '';
			detailDerivative.riskExpsMetricTypeName = '';
			detailDerivative.srceSystemCounterpartyId = '';
			detailDerivative.tenorDate = Date.newInstance(2023,09,11);
			detailDerivative.tenorId = '';
			data.detailDerivatives.add(detailDerivative);
			data.groupId = '';
			data.groupName = '';
			data.subGroupId = '';
			data.level3groupName = '';
			data.level3groupId = '';
			data.subGroupName = '';
			data.taxpayerId = '';
			HPG_Derivatives.Pagination pagination = new HPG_Derivatives.Pagination();
			pagination.links = new HPG_Derivatives.Links();
			pagination.links.first = '';
			pagination.links.last = '';
			pagination.links.next = '';
			pagination.links.previous = '';
			pagination.page = 1;
			pagination.pageSize = 300;
			pagination.totalElements = 1;
			pagination.totalPages = 1;
            System.assertEquals(true, derivatives.success, 'wrapperTest - Not passed - success');
		Test.stopTest();
	}
}