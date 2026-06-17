/**-------------------------------------------------------------------------------------------
* @Name     HPG ClientsWrapper
* @Author
* @Date     Created: 2023-04-24
* ------------------------------------------------------------------------------------------------
* @Description Wrapper Class for request operations service
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ExcessivePublicCount, PMD.TooManyFields')
public with sharing class DMT_HPG_GlobalPosition {

    /**
    * @description Call service and return wrapper
    */
    public static Wrapper getGlobalPosition(Map<String, Object> request) {
        Wrapper res = new Wrapper();
        final HttpResponse response = DMT_HPG_Utils.callService('DMT_HPG_GlobalPosition', request);
        switch on response.getStatusCode() {
            when 200, 201 {
                final Object obj = System.JSON.deserialize(response.getBody(), Wrapper.class);
                res = DMT_HPG_Utils.anonymize((Wrapper)obj);
                res.success = true;
            }
            when else {
                res.success = false;
                res.errorMessage = String.valueOf(response.getBody());
            }
        }
        return res;
    }

    /**
    * @Description: Class Wrapper
    */
    public class Wrapper {

        /* @Description: data */
        @AuraEnabled
        public List<Data> data {get;set;}

        /* @Description: pagination */
        @AuraEnabled
        public Pagination pagination {get;set;}

        /* @Description: success */
        @AuraEnabled
        public boolean success {get;set;}

        /* @Description: errorMessage */
        @AuraEnabled
        public String errorMessage {get;set;}
    }

    /**
    * @Description: Class Data
    */
    @JsonAccess(serializable='always' deserializable='always')
    public class Data {

        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}

        /* @Description: groupName */
        @AuraEnabled
        public String groupName {get;set;}

        /* @Description: groupId */
        @AuraEnabled
        public String groupId {get;set;}

        /* @Description: subGroupName */
        @AuraEnabled
        public String subGroupName {get;set;}

        /* @Description: subGroupId */
        @AuraEnabled
        public String subGroupId {get;set;}

        /* @Description: level3groupName */
        @AuraEnabled
        public String level3groupName {get;set;}

        /* @Description: level3groupId */
        @AuraEnabled
        public String level3groupId {get;set;}

        /* @Description: customerName */
        @AuraEnabled
        public String customerName {get;set;}

        /* @Description: customerId */
        @AuraEnabled
        public String customerId {get;set;}

        /* @Description: goldenCustomerId */
        @AuraEnabled
        public String goldenCustomerId {get;set;}

        /* @Description: groupHeaderName */
        @AuraEnabled
        public String groupHeaderName {get;set;}

        /* @Description: countryId */
        @AuraEnabled
        public String countryId {get;set;}

        /* @Description: countryIfoId */
        @AuraEnabled
        public String countryIfoId {get;set;}

        /* @Description: residenceCountryId */
        @AuraEnabled
        public String residenceCountryId {get;set;}

        /* @Description: currentRatingToolDate */
        @AuraEnabled
        public Date currentRatingToolDate {get;set;}

        /* @Description: ffssRegulatoryRatingDate */
        @AuraEnabled
        public Date ffssRegulatoryRatingDate {get;set;}

        /* @Description: regyCurrRatgToolId */
        @AuraEnabled
        public String regyCurrRatgToolId {get;set;}

        /* @Description: adjSbsidRatingIndType */
        @AuraEnabled
        public String adjSbsidRatingIndType {get;set;}

        /* @Description: smsclInternalRatgType */
        @AuraEnabled
        public String smsclInternalRatgType {get;set;}

        /* @Description: lmsclInternalRatgType */
        @AuraEnabled
        public String lmsclInternalRatgType {get;set;}

        /* @Description: customerConsmIndType */
        @AuraEnabled
        public String customerConsmIndType {get;set;}

        /* @Description: ratingShortScaleInternal */
        @AuraEnabled
        public String ratingShortScaleInternal {get;set;}

        /* @Description: ratingLongScaleInternal */
        @AuraEnabled
        public String ratingLongScaleInternal {get;set;}

        /* @Description: wltClassificacionType */
        @AuraEnabled
        public String wltClassificacionType {get;set;}

        /* @Description: unLtSmsclExtRatgLcType */
        @AuraEnabled
        public String unLtSmsclExtRatgLcType {get;set;}

        /* @Description: specializedLendingType */
        @AuraEnabled
        public String specializedLendingType {get;set;}

        /* @Description: lei */
        @AuraEnabled
        public String lei {get;set;}

        /* @Description: outlookRpvGeographyDesc */
        @AuraEnabled
        public String outlookRpvGeographyDesc {get;set;}

        /* @Description: riskPortfolioViewDesc */
        @AuraEnabled
        public String riskPortfolioViewDesc {get;set;}

        /* @Description: rtFfssvldydtmtNumber */
        @AuraEnabled
        public String rtFfssvldydtmtNumber {get;set;}

        /* @Description: arceCaducidadEeff */
        @AuraEnabled
        public Date arceCaducidadEeff {get;set;}

        /* @Description: regyRatgOverrideIndType */
        @AuraEnabled
        public String regyRatgOverrideIndType {get;set;}

        /* @Description: naceActivityId */
        @AuraEnabled
        public String naceActivityId {get;set;}

        /* @Description: assetAllocationSectorType  */
        @AuraEnabled
        public String assetAllocationSectorType {get;set;}

        /* @Description: assetAllcSectorDesc  */
        @AuraEnabled
        public String assetAllcSectorDesc {get;set;}

        /* @Description: assetAllocationSubSecType  */
        @AuraEnabled
        public String assetAllocationSubSecType {get;set;}

        /* @Description: aaSubSectorDesc  */
        @AuraEnabled
        public String aaSubSectorDesc {get;set;}

        /* @Description: assetAllocationActvyType  */
        @AuraEnabled
        public String assetAllocationActvyType {get;set;}

        /* @Description: aaActivityDesc  */
        @AuraEnabled
        public String aaActivityDesc {get;set;}

        /* @Description: cutoffDate  */
        @AuraEnabled
        public String cutoffDate {get;set;}

        /* @Description: updSmsclInternalRatgType */
        @AuraEnabled
        public String updSmsclInternalRatgType {get;set;}

        /* @Description: updLmsclInternalRatgType */
        @AuraEnabled
        public String updLmsclInternalRatgType {get;set;}

        /* @Description: ratingGenerationDate */
        @AuraEnabled
        public String ratingGenerationDate {get;set;}

        /* @Description: currentRatingToolId */
        @AuraEnabled
        public String currentRatingToolId {get;set;}

        /* @Description: custRtgOvrdRsnType */
        @AuraEnabled
        public String custRtgOvrdRsnType {get;set;}

        /* @Description: ratingValidityStartDate */
        @AuraEnabled
        public String ratingValidityStartDate {get;set;}

        /* @Description: arceSmsclIntRatgType */
        @AuraEnabled
        public String arceSmsclIntRatgType {get;set;}

        /* @Description: arceLmsclIntRatgType */
        @AuraEnabled
        public String arceLmsclIntRatgType {get;set;}

        /* @Description: scaleLastUpdDate */
        @AuraEnabled
        public String scaleLastUpdDate {get;set;}

        /* @Description: unifiedExtRatgLtFcType */
        @AuraEnabled
        public String unifiedExtRatgLtFcType {get;set;}

        /* @Description: leveragedLendingIndType */
        @AuraEnabled
        public String leveragedLendingIndType {get;set;}

        /* @Description: customerSegmentName */
        @AuraEnabled
        public String customerSegmentName {get;set;}

        /* @Description: rtSbsidMtrxReInshpType */
        @AuraEnabled
        public String rtSbsidMtrxReInshpType {get;set;}

        /* @Description: frontAnalystId */
        @AuraEnabled
        public String frontAnalystId {get;set;}

        /* @Description: curskAnlSacntionDate */
        @AuraEnabled
        public String curskAnlSacntionDate {get;set;}

        /* @Description: riskAnalystId */
        @AuraEnabled
        public String riskAnalystId {get;set;}

        /* @Description: custTrdWorstStageType */
        @AuraEnabled
        public String custTrdWorstStageType {get;set;}

        /* @Description: ratingSystemId */
        @AuraEnabled
        public String ratingSystemId {get;set;}

        /* @Description: taxpayerId */
        @AuraEnabled
        public String taxpayerId {get;set;}

        /* @Description: sectorAA */
        @AuraEnabled
        public String sectorAA {get;set;}

        /* @Description: subSectorAA */
        @AuraEnabled
        public String subSectorAA {get;set;}

        /* @Description: activityAA */
        @AuraEnabled
        public String activityAA {get;set;}

        /* @Description: consentType */
        @AuraEnabled
        public String consentType {get;set;}

        /* @Description: consentTypeDesc */
        @AuraEnabled
        public String consentTypeDesc {get;set;}

        /* @Description: totalExposureAmount */
        @AuraEnabled
        public String totalExposureAmount {get;set;}

        /* @Description: customerGroupRelType */
        @AuraEnabled
        public String customerGroupRelType {get;set;}

        /* @Description: activityMinimumLevelCodeId */
        @AuraEnabled
        public String activityMinimumLevelCodeId {get;set;}

        /* @Description: activityMinimumLevelCodeDesc */
        @AuraEnabled
        public String activityMinimumLevelCodeDesc {get;set;}

        /* @Description: customerRatingToolDesc */
        @AuraEnabled
        public String customerRatingToolDesc {get;set;}

        /* @Description: customerCounterpartiesCodesDesc */
        @AuraEnabled
        public String customerCounterpartiesCodesDesc {get;set;}

        /* @Description: operationMitigantDesc */
        @AuraEnabled
        public String operationMitigantDesc {get;set;}

        /* @Description: moodysLtRatingFcType */
        @AuraEnabled
        public String moodysLtRatingFcType {get;set;}

        /* @Description: fitchLtRatingFcType */
        @AuraEnabled
        public String fitchLtRatingFcType {get;set;}

        /* @Description: spLtRatingFcType */
        @AuraEnabled
        public String spLtRatingFcType {get;set;}

        /* @Description: spStRatingLcType */
        @AuraEnabled
        public String spStRatingLcType {get;set;}

        /* @Description: spStRatingFcType */
        @AuraEnabled
        public String spStRatingFcType {get;set;}

        /* @Description: fitchLtRatingLcType */
        @AuraEnabled
        public String fitchLtRatingLcType {get;set;}

        /* @Description: moodysLtRatingLcType */
        @AuraEnabled
        public String moodysLtRatingLcType {get;set;}

        /* @Description: spLtRatingLcType */
        @AuraEnabled
        public String spLtRatingLcType {get;set;}

        @AuraEnabled
        public Double totalRatingScoreNumber {get;set;}

        @AuraEnabled
        public String g_sp_lt_rating_fc_type {get;set;}
        
        /* @Description: contextEntific */
        @AuraEnabled
        public String contextEntific {get;set;}

        /* @Description: activityMinimumLevelCode */
        @AuraEnabled
        public String activityMinimumLevelCode {
            get {
                String activityMinimumLevelCodeIdWr = 'N/A';
                String activityMinimumLevelCodeDescWr = 'N/A';
                if (activityMinimumLevelCodeId != null) {
                    activityMinimumLevelCodeIdWr = activityMinimumLevelCodeId;
                }
                if (activityMinimumLevelCodeDesc != null) {
                    activityMinimumLevelCodeDescWr = activityMinimumLevelCodeDesc;
                }
                return activityMinimumLevelCodeIdWr + ' / ' + activityMinimumLevelCodeDescWr;
            }
            private set;
        }
    }

    /**
    * @Description: Class Pagination
    */
    public class Pagination {

        /* @Description: links */
        @AuraEnabled
        public Links links {get;set;}

        /* @Description: page */
        @AuraEnabled
        public Integer page {get;set;}

        /* @Description: pageSize */
        @AuraEnabled
        public Integer pageSize {get;set;}

        /* @Description: totalElements */
        @AuraEnabled
        public Integer totalElements {get;set;}

        /* @Description: totalPages */
        @AuraEnabled
        public Integer totalPages {get;set;}
    }

    /**
    * @Description: Class Links
    */
    public class Links {

        /* @Description: first */
        @AuraEnabled
        public String first {get;set;}

        /* @Description: last */
        @AuraEnabled
        public String last {get;set;}

        /* @Description: previous */
        @AuraEnabled
        public String previous {get;set;}

        /* @Description: next */
        @AuraEnabled
        public String next {get;set;}
    }

}