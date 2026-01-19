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
public with sharing class HPG_OverrideConsumption_Test {
	@isTest
	static void wrapperTest() {
		Test.startTest();
            HPG_OverrideConsumption.Wrapper overrideConsumption = new HPG_OverrideConsumption.Wrapper();
			overrideConsumption.data = new List<HPG_OverrideConsumption.Data>();
        	overrideConsumption.pagination = new HPG_OverrideConsumption.Pagination();
        	overrideConsumption.success = true;
			overrideConsumption.errorMessage = 'Error Message';
			HPG_OverrideConsumption.Data data = new HPG_OverrideConsumption.Data();
			data.authorizedRiskAmount = '';
			data.capitalRegyAmount = '';
			data.committedContractsDisposedAmount = '';
			data.committedContractsNonDisposedAmount = '';
			data.consumptionLastLevelId = '';
			data.internalContractCodeDesc = '';
			data.countryId = '';
			data.countryIfoId = '';
			data.currencyId = '';
			data.customerId = '';
			data.customerName = '';
			data.eadAmount = '';
			data.finalProvisionAmount = '';
			data.groupId = '';
			data.groupName = '';
			data.overrideComments = '';
			data.overrideEndDate = '';
			data.overrideStartDate = '';
			data.overrideUploadDate = '';
			data.regyCapitalAprAmount = '';
			data.regyCapitalEadAmount = '';
			data.residenceCountryId = '';
			data.riskAnalystId = '';
			data.taxpayerId = '';
			data.unavailableRiskAmount = '';
			data.uncommittedContractsDisposedAmount = '';
			data.uncommittedContractsNonDisposedAmount = '';
			HPG_OverrideConsumption.Pagination pagination = new HPG_OverrideConsumption.Pagination();
			pagination.links = new HPG_OverrideConsumption.Links();
			pagination.links.first = '';
			pagination.links.last = '';
			pagination.links.next = '';
			pagination.links.previous = '';
			pagination.page = 1;
			pagination.pageSize = 300;
			pagination.totalElements = 1;
			pagination.totalPages = 1;
            System.assertEquals(true, overrideConsumption.success, 'wrapperTest - Not passed - success');
		Test.stopTest();
	}
}