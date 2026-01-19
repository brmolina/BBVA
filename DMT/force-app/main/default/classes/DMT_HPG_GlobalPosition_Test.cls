/**
* ------------------------------------------------------------------------------------------------
* @Name     DMT_HPG_GlobalPosition_Test
* @Author   Global Hub
* @Date     Created: 2023-09-07
* ------------------------------------------------------------------------------------------------
* @Description Test class for DMT_HPG_GlobalPosition
* ------------------------------------------------------------------------------------------------
* @Changes
*
* | 2023-09-07 ivan.garces.contractor@bbva.com
*             Class Creation
* -----------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class DMT_HPG_GlobalPosition_Test {
@isTest
	static void wrapperTest() {
		DMT_HPG_GlobalPosition.Wrapper globalPosition = new DMT_HPG_GlobalPosition.Wrapper();
		globalPosition.data= new List<DMT_HPG_GlobalPosition.Data>();
		globalPosition.pagination = new DMT_HPG_GlobalPosition.Pagination();
		globalPosition.success = true;
		globalPosition.errorMessage = 'Error Message';
		final DMT_HPG_GlobalPosition.Data data = new DMT_HPG_GlobalPosition.Data();
		data.id = '';
		data.groupName = '';
		data.groupId = '';
		data.subGroupName = '';
		data.subGroupId = '';
		data.level3groupName = '';
		data.level3groupId = '';
		data.customerName = '';
		data.customerId = '';
		data.goldenCustomerId = '';
		data.groupHeaderName ='' ;
		data.countryId = '';
		data.countryIfoId = '';
		data.residenceCountryId = '';
		data.currentRatingToolDate = Date.newInstance(2023,09,11);
		data.ffssRegulatoryRatingDate = Date.newInstance(2023,09,11);
		data.regyCurrRatgToolId = '';
		data.adjSbsidRatingIndType = '';
		data.smsclInternalRatgType = '';
		data.lmsclInternalRatgType = '';
		data.customerConsmIndType = '';
		data.ratingShortScaleInternal = '';
		data.ratingLongScaleInternal = '';
		data.wltClassificacionType = '';
		data.unLtSmsclExtRatgLcType = '';
		data.specializedLendingType = '';
		data.lei ='' ;
		data.outlookRpvGeographyDesc = '';
		data.rtFfssvldydtmtNumber = '';
		data.arceCaducidadEeff = Date.newInstance(2023,09,11);
		data.regyRatgOverrideIndType = '';
		data.naceActivityId = '';
		data.assetAllocationSectorType = '';
		data.assetAllcSectorDesc = '';
		data.assetAllocationActvyType = '';
		data.updSmsclInternalRatgType ='' ;
		data.updLmsclInternalRatgType = '';
		data.ratingGenerationDate = '';
		data.currentRatingToolId = '';
		data.custRtgOvrdRsnType = '';
		data.ratingValidityStartDate = '';
		data.arceSmsclIntRatgType = '';
		data.arceLmsclIntRatgType = '';
		data.scaleLastUpdDate = '';
		data.unifiedExtRatgLtFcType = '';
		data.leveragedLendingIndType = '';
		data.customerSegmentName = '';
		data.rtSbsidMtrxReInshpType = '';
		data.frontAnalystId= '';
		data.curskAnlSacntionDate= '';
		data.riskAnalystId= '';
		data.custTrdWorstStageType= '';
		data.ratingSystemId= '';
		data.taxpayerId= '';
		data.sectorAA= '';
		data.riskPortfolioViewDesc = '';
		data.assetAllocationSubSecType = '';
		data.aaSubSectorDesc = '';
		data.aaActivityDesc = '';
		data.cutoffDate = '';
		data.subSectorAA = '';
		data.activityAA = '';
		data.consentType = '';
		data.consentTypeDesc = '';
		data.totalExposureAmount = '';
		data.customerGroupRelType = '';
		data.activityMinimumLevelCodeId = '';
		data.activityMinimumLevelCodeDesc = '';
		String activityMinimumLevelCode = data.activityMinimumLevelCode;
		DMT_HPG_GlobalPosition.Pagination pagination = new DMT_HPG_GlobalPosition.Pagination();
		pagination.links = new DMT_HPG_GlobalPosition.Links();
        pagination.links.first = '';
        pagination.links.last = '';
        pagination.links.next = '';
        pagination.links.previous = '';
		pagination.page = 1 ;
		pagination.pageSize = 100 ;
		pagination.totalElements = 1 ;
		pagination.totalPages = 1 ;
		System.assertEquals(true, globalPosition.success, 'wrapperTest - Not passed - success');
	}
}