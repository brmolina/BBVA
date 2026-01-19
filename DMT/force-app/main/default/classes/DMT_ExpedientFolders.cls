/**-------------------------------------------------------------------------------------------
* @Name     DMT Expedient Folders
* @Author
* @Date     Created: 2025-11-05
* ------------------------------------------------------------------------------------------------
* @Description Wrapper Class for DMT Expedient-Folders Service
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ExcessivePublicCount, PMD.TooManyFields')
public with sharing class DMT_ExpedientFolders {

     private static final String EF_SERVICENAME = 'DMT_ExpedientFolders';
     private static final String JWT_CACHE_KEY = 'DMTExpedientFoldersJWT';

    /**
    * @description Call service and return wrapper
    */
    public static Wrapper getExpedientFolders(Map<String, Object> request) {
        Wrapper res = new Wrapper();
        final HttpResponse response = DMT_HPG_Utils.callService(EF_SERVICENAME, request);
        switch on response.getStatusCode() {
            when 200 {
                system.debug(response.getBody());
                final Object obj = System.JSON.deserialize(response.getBody(), Wrapper.class);
                res = (Wrapper)obj;
                if (res.data != null && !res.data.isEmpty()) {
                    String jwtToken = res.data[0].jwt;
                    Cache.Session.put(JWT_CACHE_KEY, jwtToken);
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

        @AuraEnabled
        public String id {get;set;}

        @AuraEnabled
        public BusinessCode businessCode {get;set;}

        @AuraEnabled
        public FolderInfo folderInfo {get;set;}

        @AuraEnabled
        public String origin {get;set;}

        @AuraEnabled
        public ProcessInfo processInfo {get;set;}

        @AuraEnabled
        public SecurityLevelInfo securityLevelInfo {get;set;}

        @AuraEnabled
        public Status status {get;set;}

        @AuraEnabled
        public List<Child> children {get;set;}

        @AuraEnabled
        public String jwt {get;set;}
    }

    public class BusinessCode {
        @AuraEnabled
        public String folderCode {get;set;}
    }

    public class FolderInfo {
        @AuraEnabled
        public String objectName {get;set;}

        @AuraEnabled
        public String creationDate {get;set;}

        @AuraEnabled
        public String creationUser {get;set;}
    }

    public class ProcessInfo {
        @AuraEnabled
        public String id {get;set;}

        @AuraEnabled
        public String code {get;set;}

        @AuraEnabled
        public String name {get;set;}

        @AuraEnabled
        public ProcessType processType {get;set;}
    }

    public class ProcessType {
        @AuraEnabled
        public String id {get;set;}
    }

    public class Status {
        @AuraEnabled
        public Date statusDate {get;set;}

        @AuraEnabled
        public String name {get;set;}
    }

    /**
     * @Description: Class children
     *
    */
    public class Child {
        @AuraEnabled
        public String id {get;set;}

        @AuraEnabled
        public NodeType nodeType {get;set;}

        @AuraEnabled
        public String objectCode {get;set;}

        @AuraEnabled
        public String objectName {get;set;}

        @AuraEnabled
        public String documentType {get;set;}

        @AuraEnabled
        public String contentLocator {get;set;}

        @AuraEnabled
        public SecurityLevelInfo securityLevelInfo {get;set;}
    }

    /**
     * @Description: Class NodeType
     *
    */
    public class NodeType {
        @AuraEnabled
        public String id {get;set;}
        @AuraEnabled
        public String description {get;set;}
    }

    /**
     * @Description: Class SecurityLevelInfo
     *
    */
    public class SecurityLevelInfo {
        @AuraEnabled
        public Integer classificationLevel {get;set;}
        @AuraEnabled
        public Integer securityLevel {get;set;}
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