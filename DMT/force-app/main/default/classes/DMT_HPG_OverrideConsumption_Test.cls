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
public with sharing class DMT_HPG_OverrideConsumption_Test {
    @isTest
	static void wrapperTest() {
		Test.startTest();
            DMT_HPG_OverrideConsumption.Wrapper overrideConsumption = new DMT_HPG_OverrideConsumption.Wrapper();
			overrideConsumption.data = new List<DMT_HPG_OverrideConsumption.Data>();
        	overrideConsumption.pagination = new DMT_HPG_OverrideConsumption.Pagination();
        	overrideConsumption.success = true;
			overrideConsumption.errorMessage = 'Error Message';
			DMT_HPG_OverrideConsumption.Data data = new DMT_HPG_OverrideConsumption.Data();
			data.authorizedRiskAmount = '';
			data.capitalRegyAmount = '';
			data.committedContractsDisposedAmount = '';
			data.committedContractsNonDisposedAmount = '';
			data.consumptionLastLevelId = '';
			data.contractId = '';
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
			DMT_HPG_OverrideConsumption.Pagination pagination = new DMT_HPG_OverrideConsumption.Pagination();
			pagination.links = new DMT_HPG_OverrideConsumption.Links();
			pagination.links.first = '';
			pagination.links.last = '';
			pagination.links.next = '';
			pagination.links.previous = '';
			pagination.page = 1;
			pagination.pageSize = 100;
			pagination.totalElements = 1;
			pagination.totalPages = 1;
            System.assertEquals(true, overrideConsumption.success, 'wrapperTest - Not passed - success');
		Test.stopTest();
	}

}