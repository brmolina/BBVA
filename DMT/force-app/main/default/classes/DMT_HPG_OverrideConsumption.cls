/**-------------------------------------------------------------------------------------------
* @Name     HPG OverrideConsumption
* @Author
* @Date     Created: 2023-10-31
* ------------------------------------------------------------------------------------------------
* @Description Wrapper Class for request operations service
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ExcessivePublicCount, PMD.TooManyFields')
public with sharing class DMT_HPG_OverrideConsumption {

    /**
    * @description Call service and return wrapper
    */
    public static Wrapper callOverrideConsumption(String serviceName, Map<String, Object> request) {
        Wrapper res = new Wrapper();
        final HttpResponse response = DMT_HPG_Utils.callService_DMT(serviceName, request, true);
        switch on response.getStatusCode() {
            when 200, 201 {
                final Object obj = System.JSON.deserialize(response.getBody(), Wrapper.class);
                res = (Wrapper)obj;
                for (Data item : res.data) {
                    try {
                        item.consumptionLastLevelName = Label.get(null, 'grid_field_' + item.consumptionLastLevelId, 'en');
                    } catch (Exception e) { //NOSONAR
                        item.consumptionLastLevelName = item.consumptionLastLevelId + ' (Invalid ID)';
                        System.debug(e.getMessage());//NOSONAR
                        DES_Exception_Utils.logException(e,'DMT_HPG_OverrideConsumption', 'callOverrideConsumption', 'DMT', '');
                    }
                }
                res.success = true;
            }
            when 204 {
                res.success = true;
            }
            when else {
                res.success = false;
                if (response.getBody() == null) {
                    res.errorMessage = Label.HPG_Error_Save_Data;
                }else {
                    final Map<String,Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
                    if (responseMap.containsKey('messages')) {
                        List<Object> messageMapList = (List <Object>) responseMap.get('messages');
                        Map<String,Object> messageMap = (Map<String,Object>) messageMapList[0];
                        if (messageMap.containsKey('message')) {
                            res.errorMessage = (String) messageMap.get('message');
                        }else {
                            res.errorMessage = Label.HPG_Error_Save_Data;
                        }
                    }
                }
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

        /* @Description: customerId */
        @AuraEnabled
        public String customerId {get;set;}

        /* @Description: contractId */
        @AuraEnabled
        public String contractId {get;set;}

        /* @Description: overrideUploadDate */
        @AuraEnabled
        public String overrideUploadDate {get;set;}

        /* @Description: consumptionLastLevelId */
        @AuraEnabled
        public String consumptionLastLevelId {get;set;}

        /* @Description: consumptionLastLevelName */
        @AuraEnabled
        public String consumptionLastLevelName {get;set;}

        /* @Description: committedContractsDisposedAmount */
        @AuraEnabled
        public String committedContractsDisposedAmount {get;set;}

        /* @Description: uncommittedContractsDisposedAmount */
        @AuraEnabled
        public String uncommittedContractsDisposedAmount {get;set;}

        /* @Description: committedContractsNonDisposedAmount */
        @AuraEnabled
        public String committedContractsNonDisposedAmount {get;set;}

        /* @Description: uncommittedContractsNonDisposedAmount */
        @AuraEnabled
        public String uncommittedContractsNonDisposedAmount {get;set;}

        /* @Description: authorizedRiskAmount */
        @AuraEnabled
        public String authorizedRiskAmount {get;set;}

        /* @Description: unavailableRiskAmount */
        @AuraEnabled
        public String unavailableRiskAmount {get;set;}

        /* @Description: riskAnalystId */
        @AuraEnabled
        public String riskAnalystId {get;set;}

        /* @Description: overrideStartDate */
        @AuraEnabled
        public String overrideStartDate {get;set;}

        /* @Description: overrideEndDate */
        @AuraEnabled
        public String overrideEndDate {get;set;}

        /* @Description: overrideComments */
        @AuraEnabled
        public String overrideComments {get;set;}

        /* @Description: currencyId */
        @AuraEnabled
        public String currencyId {get;set;}

        /* @Description: eadAmount */
        @AuraEnabled
        public String eadAmount {get;set;}

        /* @Description: finalProvisionAmount */
        @AuraEnabled
        public String finalProvisionAmount {get;set;}

        /* @Description: regyCapitalEadAmount */
        @AuraEnabled
        public String regyCapitalEadAmount {get;set;}

        /* @Description: capitalRegyAmount */
        @AuraEnabled
        public String capitalRegyAmount {get;set;}

        /* @Description: regyCapitalAprAmount */
        @AuraEnabled
        public String regyCapitalAprAmount {get;set;}

        /* @Description: groupName */
        @AuraEnabled
        public String groupName {get;set;}

        /* @Description: groupId */
        @AuraEnabled
        public String groupId {get;set;}

        /* @Description: customerName */
        @AuraEnabled
        public String customerName {get;set;}

        /* @Description: taxpayerId */
        @AuraEnabled
        public String taxpayerId {get;set;}

        /* @Description: residenceCountryId */
        @AuraEnabled
        public String residenceCountryId {get;set;}

        /* @Description: countryIfoId */
        @AuraEnabled
        public String countryIfoId {get;set;}

        /* @Description: countryId */
        @AuraEnabled
        public String countryId {get;set;}
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