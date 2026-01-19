/**
* ────────────────────────────────────────────────────────────────────────────────────
* Test class for HPG_ConsumptionDetail apex class
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
public with sharing class HPG_ConsumptionDetail_Test {
    @isTest
    static void wrapperTest() {
        Test.startTest();
            HPG_ConsumptionDetail.Wrapper consumptionDetail = new HPG_ConsumptionDetail.Wrapper();
            consumptionDetail.data = new List<HPG_ConsumptionDetail.Data>();
            consumptionDetail.pagination = new HPG_ConsumptionDetail.Pagination();
            consumptionDetail.success = true;
            consumptionDetail.errorMessage = 'Error Message';
            HPG_ConsumptionDetail.Data data = new HPG_ConsumptionDetail.Data();
            data.countryId = '';
            data.countryIfoId = '';
            data.customerId = '';
            data.customerName = '';
            data.detailConsumptions = new List<HPG_ConsumptionDetail.DetailConsumption>();
            HPG_ConsumptionDetail.DetailConsumption detailConsumption = new HPG_ConsumptionDetail.DetailConsumption();
            detailConsumption.overrideAction = 'EDIT';
            detailConsumption.overrideIcon = 'utility:edit';
            detailConsumption.overrideTitle = 'Edit Override';
            detailConsumption.overrideComments = 'Comment';
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
            detailConsumption.consumptionExpired = true;
            detailConsumption.currentGuaranteedAmount = 0.0;
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
            detailConsumption.internalContractCodeDesc = '';
            detailConsumption.maturityTermNumber = 1.00000000;
            detailConsumption.maximumDeadlineDate = Date.newInstance(2023,09,11);
            detailConsumption.productTypeDesc = '';
            detailConsumption.regyCapitalAprAmount = 1.00;
            detailConsumption.regyCapitalEadAmount = 1.00;
            detailConsumption.unavailableRiskAmount = 1.00;
            detailConsumption.uncommittedContractsDisposedAmount = 1.00;
            detailConsumption.uncommittedContractsNonDisposedAmount = 1.00;
            detailConsumption.cNotSignedTrConsumptionAmount = 1.00;
            detailConsumption.economicCapitalEad1Amount = 1.00;
            detailConsumption.economicCapitalAprAmount = 1.00;
            detailConsumption.economicCapitalAmount = 1.00;
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
            HPG_ConsumptionDetail.Pagination pagination = new HPG_ConsumptionDetail.Pagination();
            pagination.links = new HPG_ConsumptionDetail.Links();
            pagination.links.first = '';
            pagination.links.last = '';
            pagination.links.next = '';
            pagination.links.previous = '';
            pagination.page = 1;
            pagination.pageSize = 300;
            pagination.totalElements = 1;
            pagination.totalPages = 1;
            System.assertEquals(true, consumptionDetail.success, 'wrapperTest - Not passed - success');
        Test.stopTest();
    }
}