/**-------------------------------------------------------------------------------------------
* @Name     HPG CapitalProvision
* @Author
* @Date     Created: 2023-07-18
* ------------------------------------------------------------------------------------------------
* @Description Wrapper Class for request operations service
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ExcessivePublicCount, PMD.TooManyFields')
public with sharing class DMT_HPG_CapitalProvision {

    /**
    * @description Call service and return wrapper
    */
    public static Wrapper getCapitalProvision(Map<String, Object> request) {
        Wrapper res = new Wrapper();
        final HttpResponse response = DMT_HPG_Utils.callService_DMT('DMT_HPG_GetCapitalProvision', request);
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

        /* @Description: customerId */
        @AuraEnabled
        public String customerId {get;set;}

        /* @Description: customerName */
        @AuraEnabled
        public String customerName {get;set;}

        /* @Description: taxpayerId */
        @AuraEnabled
        public String taxpayerId {get;set;}

        /* @Description: countryIfoId */
        @AuraEnabled
        public String countryIfoId {get;set;}

        /* @Description: residenceCountryId */
        @AuraEnabled
        public String residenceCountryId {get;set;}

        /* @Description: countryId */
        @AuraEnabled
        public String countryId {get;set;}

        /* @Description: level3groupId */
        @AuraEnabled
        public String level3groupId {get;set;}

        /* @Description: level3groupName */
        @AuraEnabled
        public String level3groupName {get;set;}

        /* @Description: currencyId */
        @AuraEnabled
        public String currencyId {get;set;}

        /* @Description: eadAmount */
        @AuraEnabled
        public String eadAmount {get;set;}

        /* @Description: finalProvisionAmount */
        @AuraEnabled
        public String finalProvisionAmount {get;set;}

        /* @Description: regulatoryEadCapital */
        @AuraEnabled
        public String regulatoryEadCapital {get;set;}

        /* @Description: capitalRegyAmount */
        @AuraEnabled
        public String capitalRegyAmount {get;set;}

        /* @Description: regyCapitalAprAmount */
        @AuraEnabled
        public String regyCapitalAprAmount {get;set;}

        /* @Description: cutoffDate */
        @AuraEnabled
        public String cutoffDate {get;set;}

        /* @Description: economicCapitalEad1Amount */
        @AuraEnabled
        public String economicCapitalEad1Amount {get;set;}

        /* @Description: economicCapitalAprAmount */
        @AuraEnabled
        public String economicCapitalAprAmount {get;set;}

        /* @Description: economicCapitalAmount */
        @AuraEnabled
        public String economicCapitalAmount {get;set;}
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