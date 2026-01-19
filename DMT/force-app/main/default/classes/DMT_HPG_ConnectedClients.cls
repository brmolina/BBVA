/**-------------------------------------------------------------------------------------------
* @Name     HPG Connected Clients
* @Author
* @Date     Created: 2023-11-02
* ------------------------------------------------------------------------------------------------
* @Description Wrapper Class and service call
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ExcessivePublicCount, PMD.TooManyFields')
public with sharing class DMT_HPG_ConnectedClients {

    /**
     * @description Call service and return wrapper
     */
    public static Wrapper getConnectedClients(Map<String, Object> request) {
        Wrapper res = new Wrapper();
        final HttpResponse response = DMT_HPG_Utils.callService_DMT('DMT_HPG_ConnectedCustomers', request);
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

        /* @Description: cutoffDate */
        @AuraEnabled
        public Date cutoffDate {get;set;}

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

        /* @Description: unavailableRiskAmount */
        @AuraEnabled
        public String unavailableRiskAmount {get;set;}
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