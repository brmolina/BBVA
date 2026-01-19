/**
* ────────────────────────────────────────────────────────────────────────────────────
* Test class for HPG_CapitalProvisionDetail apex class
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
public with sharing class HPG_CapitalProvisionDetail_Test {
    @isTest
    static void wrapperTest() {
        Test.startTest();
        HPG_CapitalProvisionDetail.Wrapper capitalProvisionDetail = new HPG_CapitalProvisionDetail.Wrapper();
            capitalProvisionDetail.data = new List<HPG_CapitalProvisionDetail.Data>();
            capitalProvisionDetail.pagination = new HPG_CapitalProvisionDetail.Pagination();
            capitalProvisionDetail.success = true;
            capitalProvisionDetail.errorMessage = 'Error Message';
            HPG_CapitalProvisionDetail.Data data = new HPG_CapitalProvisionDetail.Data();
            data.countryId = '';
            data.countryIfoId = '';
            data.customerId = '';
            data.customerName = '';
            data.detailConsumptions = new List<HPG_CapitalProvisionDetail.DetailConsumption>();
            HPG_CapitalProvisionDetail.DetailConsumption detailConsumption = new HPG_CapitalProvisionDetail.DetailConsumption();
            detailConsumption.activityRefinancedType = '';
            detailConsumption.authorizedRiskAmount = 1.00;
            detailConsumption.branchId = '';
            detailConsumption.capitalCalculationMtType = '';
            detailConsumption.capitalRegyAmount = 1.00;
            detailConsumption.catalogFieldValueEsDes = '';
            detailConsumption.committedContractsDisposedAmount = 1.00;
            detailConsumption.committedContractsNonDisposedAmount = 1.00;
            detailConsumption.consumptionLastLevelId = '';
            detailConsumption.contractDayDefault = 1;
            detailConsumption.contractId = '';
            detailConsumption.contractRegisterDate = Date.newInstance(2023,09,11);
            detailConsumption.currencyId = '';
            detailConsumption.currentExpirationDate = Date.newInstance(2023,09,11);
            detailConsumption.currentGuaranteedAmount = 1.00;
            detailConsumption.cutoffDate = Date.newInstance(2023,09,11);
            detailConsumption.eadAmount = 1.00;
            detailConsumption.entityId = '';
            detailConsumption.finalProvisionAmount = 1.00;
            detailConsumption.finalStageType = '';
            detailConsumption.globalProductId = '';
            detailConsumption.holdingProductId = '';
            detailConsumption.individualizedContType = '';
            detailConsumption.individualizedCustType = '';
            detailConsumption.localContractNumberId = '';
            detailConsumption.maturityTermNumber = 1.00;
            detailConsumption.maximumDeadlineDate = Date.newInstance(2023,09,11);
            detailConsumption.productTypeDesc = '';
            detailConsumption.regyCapitalAprAmount = 1.00;
            detailConsumption.regyCapitalEadAmount = 1.00;
            detailConsumption.unavailableRiskAmount = 1.00;
            detailConsumption.uncommittedContractsDisposedAmount = 1.00;
            detailConsumption.uncommittedContractsNonDisposedAmount = 1.00;
            detailConsumption.cNotSignedTrConsumptionAmount = 1.00;
            detailConsumption.economicCapitalEad1Amount = 1.00;
            detailConsumption.economicCapitalAmount = 1.00;
            detailConsumption.economicCapitalAprAmount = 1.00;
            detailConsumption.lineConsumptionExclusionIndType = '';
            detailConsumption.majorityShareholderRiskIndType = '';
            detailConsumption.directIndirectRiskType = '';
            detailConsumption.sustainabilityMarkId = '';
            detailConsumption.sustCategoryTradePerDesc = '';
            detailConsumption.originatesDataGeographyId = '';
            detailConsumption.frequencyType = '';
            detailConsumption.cibSegmentType = '';
            detailConsumption.bulletIndType = '';
            detailConsumption.collateralTypeName = '';
            detailConsumption.nonRealCollateralDesc = '';
            detailConsumption.expertCriteriaRiskType = '';
            detailConsumption.internalContractCodeDesc = '';
            detailConsumption.opportunityId = '';
            data.detailConsumptions.add(detailConsumption);
            data.groupId = '';
            data.groupName = '';
            data.residenceCountryId = '';
            data.subGroupId = '';
            data.level3groupName = '';
            data.level3groupId = '';
            data.subGroupName = '';
            data.taxpayerId = '';
            HPG_CapitalProvisionDetail.Pagination pagination = new HPG_CapitalProvisionDetail.Pagination();
            pagination.links = new HPG_CapitalProvisionDetail.Links();
            pagination.links.first = '';
            pagination.links.last = '';
            pagination.links.next = '';
            pagination.links.previous = '';
            pagination.page = 1;
            pagination.pageSize = 300;
            pagination.totalElements = 1;
            pagination.totalPages = 1;
            System.assertEquals(true, capitalProvisionDetail.success, 'wrapperTest - Not passed - success');
        Test.stopTest();
    }
}