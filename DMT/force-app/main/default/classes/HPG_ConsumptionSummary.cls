/**-------------------------------------------------------------------------------------------
* @Name     HPG ClientsWrapper
* @Author
* @Date     Created: 2023-04-24
* ------------------------------------------------------------------------------------------------
* @Description Wrapper Class for request operations service
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ExcessivePublicCount, PMD.TooManyFields')
public with sharing class HPG_ConsumptionSummary {

    /**
    * @description Call service and return wrapper
    */
    public static Wrapper getConsumptionSummary(Map<String, Object> request) {
        Wrapper res = new Wrapper();
        final HttpResponse response = HPG_Utils.callService('HPG_ConsumptionSummary', request);
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

        /* @Description: id */
        @AuraEnabled
        public String id {get;set;}

        /* @Description: consumptionLastLevelId */
        @AuraEnabled
        public String consumptionLastLevelId {get;set;}

        /* @Description: catalogs */
        @AuraEnabled
        public List<Catalog> catalogs {get;set;}
    }

    /**
    * @Description: Class Catalog
    */
    public class Catalog {

        /* @Description: productTypeDesc */
        @AuraEnabled
        public String productTypeDesc {get;set;}

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

        /* @Description: unavailableRiskAmount */
        @AuraEnabled
        public Double unavailableRiskAmount {get;set;}

        /* @Description: unauthorizedCount */
        @AuraEnabled
        public Integer unauthorizedCount {get;set;}

        /* @Description: cutoffDate */
        @AuraEnabled
        public Date cutoffDate {get;set;}

        /* @Description: cNotSignedTrConsumptionAmount */
        @AuraEnabled
        public Double cNotSignedTrConsumptionAmount {get;set;}
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