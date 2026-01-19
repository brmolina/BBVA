/**-------------------------------------------------------------------------------------------
* @Name     HPG UsedTablesWrapper
* @Author
* @Date     Created: 2023-10-02
* ------------------------------------------------------------------------------------------------
* @Description Wrapper Class for request used tables service
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ExcessivePublicCount, PMD.TooManyFields')
public with sharing class DMT_HPG_UsedTables {

    /**
    * @description Call service and return wrapper
    */
    public static Wrapper getUsedTables(Map<String, Object> request) {
        Wrapper res = new Wrapper();
        final HttpResponse response = DMT_HPG_Utils.callService('DMT_HPG_GetUsedTables', request);
        switch on response.getStatusCode() {
            when 200, 201 {
                final Object obj = System.JSON.deserialize(response.getBody().replace('"date"', '"tableDate"'), Wrapper.class);
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
        public List<Datac> data {get;set;}

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
    * @Description: Class Datac
    */
    public class Datac {

        /* @Description: data */
        @AuraEnabled
        public List<Data> data {get;set;}

        /* @Description: dateRangeTables */
        @AuraEnabled
        public List<DateRangeTable> dateRangeTables {get;set;}
    }

    /**
    * @Description: Class Data
    */
    public class Data {

        /* @Description: tblMeEngineNameConcatenationDesc */
        @AuraEnabled
        public String tblMeEngineNameConcatenationDesc {get;set;}

        /* @Description: tableDesc */
        @AuraEnabled
        public String tableDesc {get;set;}

        /* @Description: entificId */
        @AuraEnabled
        public String entificId {get;set;}

        /* @Description: cutoffDate */
        @AuraEnabled
        public String cutoffDate {get;set;}

        /* @Description: tableUpdateDateDesc */
        @AuraEnabled
        public String tableUpdateDateDesc {get;set;}

        /* @Description: originDataDesc */
        @AuraEnabled
        public String originDataDesc {get;set;}
    }

    /**
    * @Description: Class DateRangeTable
    */
    public class DateRangeTable {

        /* @Description: tableDate */
        @AuraEnabled
        public String tableDate {get;set;}
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