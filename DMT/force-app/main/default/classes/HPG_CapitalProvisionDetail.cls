/**-------------------------------------------------------------------------------------------
* @Name     HPG CapitalProvisionDetail
* @Author
* @Date     Created: 2023-10-17
* ------------------------------------------------------------------------------------------------
* @Description Wrapper Class for request operations service
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ExcessivePublicCount, PMD.TooManyFields')
public with sharing class HPG_CapitalProvisionDetail {

    /**
    * @description Call service and return wrapper
    */
    public static Wrapper getDetailCapitalProvision(Map<String, Object> request) {
        Wrapper res = new Wrapper();
        final HttpResponse response = HPG_Utils.callService('HPG_GetDetailCapitalProvision', request);
        switch on response.getStatusCode() {
            when 200, 201 {
                final Object obj = System.JSON.deserialize(response.getBody(), Wrapper.class);
                res = (Wrapper)obj;
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
    public class Data {

        /* @Description: groupId */
        @AuraEnabled
        public String groupId {get;set;}

        /* @Description: groupName */
        @AuraEnabled
        public String groupName {get;set;}

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

        /* @Description: taxpayerId */
        @AuraEnabled
        public String taxpayerId {get;set;}

        /* @Description: countryId */
        @AuraEnabled
        public String countryId {get;set;}

        /* @Description: residenceCountryId */
        @AuraEnabled
        public String residenceCountryId {get;set;}

        /* @Description: countryIfoId */
        @AuraEnabled
        public String countryIfoId {get;set;}

        /* @Description: detailConsumptions */
        @AuraEnabled
        public List<DetailConsumption> detailConsumptions {get;set;}

    }

    /**
    * @Description: Class DetailConsumption
    */
    public class DetailConsumption {

        /* @Description: consumptionLastLevelId */
        @AuraEnabled
        public String consumptionLastLevelId {get;set;}

        /* @Description: contractRegisterDate */
        @AuraEnabled
        public Date contractRegisterDate {get;set;}

        /* @Description: currentExpirationDate */
        @AuraEnabled
        public Date currentExpirationDate {get;set;}

        /* @Description: catalogFieldValueEsDes */
        @AuraEnabled
        public String catalogFieldValueEsDes {get;set;}

        /* @Description: currencyId */
        @AuraEnabled
        public String currencyId {get;set;}

        /* @Description: branchId */
        @AuraEnabled
        public String branchId {get;set;}

        /* @Description: activityRefinancedType */
        @AuraEnabled
        public String activityRefinancedType {get;set;}

        /* @Description: contractDayDefault */
        @AuraEnabled
        public Integer contractDayDefault {get;set;}

        /* @Description: contractId */
        @AuraEnabled
        public String contractId {get;set;}

        /* @Description: localContractNumberId */
        @AuraEnabled
        public String localContractNumberId {get;set;}

        /* @Description: holdingProductId */
        @AuraEnabled
        public String holdingProductId {get;set;}

        /* @Description: globalProductId */
        @AuraEnabled
        public String globalProductId {get;set;}

        /* @Description: entityId */
        @AuraEnabled
        public String entityId {get;set;}

        /* @Description: maximumDeadlineDate */
        @AuraEnabled
        public Date maximumDeadlineDate {get;set;}

        /* @Description: productTypeDesc */
        @AuraEnabled
        public String productTypeDesc {get;set;}

        /* @Description: capitalCalculationMtType */
        @AuraEnabled
        public String capitalCalculationMtType {get;set;}

        /* @Description: finalStageType */
        @AuraEnabled
        public String finalStageType {get;set;}

        /* @Description: individualizedCustType */
        @AuraEnabled
        public String individualizedCustType {get;set;}

        /* @Description: individualizedContType */
        @AuraEnabled
        public String individualizedContType {get;set;}

        /* @Description: maturityTermNumber */
        @AuraEnabled
        public Decimal maturityTermNumber {get;set;}

        /* @Description: currentGuaranteedAmount */
        @AuraEnabled
        public Decimal currentGuaranteedAmount {get;set;}

        /* @Description: committedContractsDisposedAmount */
        @AuraEnabled
        public Decimal committedContractsDisposedAmount {get;set;}

        /* @Description: uncommittedContractsDisposedAmount */
        @AuraEnabled
        public Decimal uncommittedContractsDisposedAmount {get;set;}

        /* @Description: committedContractsNonDisposedAmount */
        @AuraEnabled
        public Decimal committedContractsNonDisposedAmount {get;set;}

        /* @Description: uncommittedContractsNonDisposedAmount */
        @AuraEnabled
        public Decimal uncommittedContractsNonDisposedAmount {get;set;}

        /* @Description: authorizedRiskAmount */
        @AuraEnabled
        public Decimal authorizedRiskAmount {get;set;}

        /* @Description: unavailableRiskAmount */
        @AuraEnabled
        public Decimal unavailableRiskAmount {get;set;}

        /* @Description: eadAmount */
        @AuraEnabled
        public Decimal eadAmount {get;set;}

        /* @Description: finalProvisionAmount */
        @AuraEnabled
        public Decimal finalProvisionAmount {get;set;}

        /* @Description: regyCapitalEadAmount */
        @AuraEnabled
        public Decimal regyCapitalEadAmount {get;set;}

        /* @Description: capitalRegyAmount */
        @AuraEnabled
        public Decimal capitalRegyAmount {get;set;}

        /* @Description: regyCapitalAprAmount */
        @AuraEnabled
        public Decimal regyCapitalAprAmount {get;set;}

        /* @Description: cutoffDate */
        @AuraEnabled
        public Date cutoffDate {get;set;}

        /* @Description: cNotSignedTrConsumptionAmount */
        @AuraEnabled
        public Decimal cNotSignedTrConsumptionAmount {get;set;}

        /* @Description: economicCapitalEad1Amount */
        @AuraEnabled
        public Decimal economicCapitalEad1Amount {get;set;}

        /* @Description: economicCapitalAmount */
        @AuraEnabled
        public Decimal economicCapitalAmount {get;set;}

        /* @Description: economicCapitalAprAmount */
        @AuraEnabled
        public Decimal economicCapitalAprAmount {get;set;}

        /* @Description: lineConsumptionExclusionIndType */
        @AuraEnabled
        public String lineConsumptionExclusionIndType {get;set;}

        /* @Description: majorityShareholderRiskIndType */
        @AuraEnabled
        public String majorityShareholderRiskIndType {get;set;}

        /* @Description: directIndirectRiskType */
        @AuraEnabled
        public String directIndirectRiskType {get;set;}

        /* @Description: sustainabilityMarkId */
        @AuraEnabled
        public String sustainabilityMarkId {get;set;}

        /* @Description: sustCategoryTradePerDesc */
        @AuraEnabled
        public String sustCategoryTradePerDesc {get;set;}

        /* @Description: originatesDataGeographyId */
        @AuraEnabled
        public String originatesDataGeographyId {get;set;}

        /* @Description: frequencyType */
        @AuraEnabled
        public String frequencyType {get;set;}

        /* @Description: cibSegmentType */
        @AuraEnabled
        public String cibSegmentType {get;set;}

        /* @Description: bulletIndType */
        @AuraEnabled
        public String bulletIndType {get;set;}

        /* @Description: collateralTypeName */
        @AuraEnabled
        public String collateralTypeName {get;set;}

        /* @Description: nonRealCollateralDesc */
        @AuraEnabled
        public String nonRealCollateralDesc {get;set;}

        /* @Description: expertCriteriaRiskType */
        @AuraEnabled
        public String expertCriteriaRiskType {get;set;}

        /* @Description: internalContractCodeDesc */
        @AuraEnabled
        public String internalContractCodeDesc {get;set;}

        /* @Description: opportunityId */
        @AuraEnabled
        public String opportunityId {get;set;}
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