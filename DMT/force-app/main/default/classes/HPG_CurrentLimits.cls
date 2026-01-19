/**-------------------------------------------------------------------------------------------
* @Name     HPG Current LImits
* @Author   torcuato.tejada.tech@bbva.com
* @Date     Created: 2023-06-24
* ------------------------------------------------------------------------------------------------
* @Description Wrapper Class for current limits used in the summary chart
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ExcessivePublicCount, PMD.TooManyFields')
public with sharing class HPG_CurrentLimits {

    /**
    * @description Call service and return wrapper
    */
    public static Wrapper getCurrentLimits(Map<String, Object> request) {
        Wrapper res = new Wrapper();
        final HttpResponse response = HPG_Utils.callService('HPG_CurrentLimits', request);
        switch on response.getStatusCode() {
            when 200, 201 {
                final Object obj = System.JSON.deserialize(response.getBody(), Wrapper.class);
                res = (Wrapper)obj;
                for (Data lim : res.data) {
                    lim.sumDisposedAmount = 0;
                    if (lim.committedContractsDisposedAmount != null) {
                        lim.sumDisposedAmount = lim.sumDisposedAmount + lim.committedContractsDisposedAmount;
                    }
                    if (lim.uncommittedContractsDisposedAmount != null) {
                        lim.sumDisposedAmount = lim.sumDisposedAmount + lim.uncommittedContractsDisposedAmount;
                    }
                }
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

        /* @Description: cutoffDate */
        @AuraEnabled
        public Date cutoffDate {get;set;}

        /* @Description: limitId */
        @AuraEnabled
        public String limitId {get;set;}

        /* @Description: customerId */
        @AuraEnabled
        public String customerId {get;set;}

        /* @Description: goldenCustomerId */
        @AuraEnabled
        public String goldenCustomerId {get;set;}

        /* @Description: customerGroupId */
        @AuraEnabled
        public String customerGroupId {get;set;}

        /* @Description: groupId */
        @AuraEnabled
        public String groupId {get;set;}

        /* @Description: consumptionLastLevelId */
        @AuraEnabled
        public String consumptionLastLevelId {get;set;}

        /* @Description: limitDesc */
        @AuraEnabled
        public String limitDesc {get;set;}

        /* @Description: originType */
        @AuraEnabled
        public String originType {get;set;}

        /* @Description: limitType */
        @AuraEnabled
        public String limitType {get;set;}

        /* @Description: unavailableRiskAmount */
        @AuraEnabled
        public Double unavailableRiskAmount {get;set;}

        /* @Description: authorizedRiskAmount */
        @AuraEnabled
        public Double authorizedRiskAmount {get;set;}

        /* @Description: committedContractsDisposedAmount */
        @AuraEnabled
        public Double committedContractsDisposedAmount {get;set;}

        /* @Description: uncommittedContractsDisposedAmount */
        @AuraEnabled
        public Double uncommittedContractsDisposedAmount {get;set;}

        /* @Description: committedContractsNonDisposedAmount */
        @AuraEnabled
        public Double committedContractsNonDisposedAmount {get;set;}

        /* @Description: uncommittedContractsNonDisposedAmount */
        @AuraEnabled
        public Double uncommittedContractsNonDisposedAmount {get;set;}

        /* @Description: uncommittedContractsNonDisposedAmount */
        @AuraEnabled
        public Double sumDisposedAmount {get;set;}

        /* @Description: cNotSignedTrConsumptionAmount */
        @AuraEnabled
        public Double cNotSignedTrConsumptionAmount {get;set;}

        /* @Description: limitCapitalTradeCnsNumber */
        @AuraEnabled
        public Double limitCapitalTradeCnsNumber {get;set;}

        /* @Description: customersNumber */
        @AuraEnabled
        public Integer customersNumber {get;set;}

        /* @Description: currentApprovedAmount */
        @AuraEnabled
        public Double currentApprovedAmount {get;set;}

        /* @Description: currencyId */
        @AuraEnabled
        public String currencyId {get;set;}

        /* @Description: riskAnalysisExpDate */
        @AuraEnabled
        public Date riskAnalysisExpDate {get;set;}

        /* @Description: limitExceededActionDesc */
        @AuraEnabled
        public String limitExceededActionDesc {get;set;}

        /* @Description: riskAnalystId */
        @AuraEnabled
        public String riskAnalystId {get;set;}

        /* @Description: bulletIndType */
        @AuraEnabled
        public String bulletIndType {get;set;}

        /* @Description: collateralTypeName */
        @AuraEnabled
        public String collateralTypeName {get;set;}

        /* @Description: nonRealCollateralDesc */
        @AuraEnabled
        public String nonRealCollateralDesc {get;set;}
    }
}