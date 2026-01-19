/**-------------------------------------------------------------------------------------------
* @Name     DMT Expedient Folders
* @Author   torcuato.tejada.tech@bbva.com
* @Date     Created: 2025-11-05
* ------------------------------------------------------------------------------------------------
* @Description Wrapper class and service call for Expedient-Folders Service
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ExcessivePublicCount, PMD.TooManyFields')
public with sharing class DMT_CoreDocuments {

    private static final String UPLOAD_SERVICENAME = 'DMT_CoreDocumentsUpload';
    private static final String COREDOC_SERVICENAME = 'DMT_CoreDocumentsUpload';

    /**
    * @description Call service and return wrapper
    */
    public static Wrapper postCoreDocuments(Map<String, Object> request) {
        Wrapper res = new Wrapper();
        final HttpResponse response = DMT_HPG_Utils.callService(COREDOC_SERVICENAME, request);
        switch on response.getStatusCode() {
            when 201 {
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

    public static UploadResult uploadCoreDocument(Map<String, Object> request) {

        UploadResult res = new UploadResult();
        final HttpResponse response = DMT_HPG_Utils.callService(UPLOAD_SERVICENAME, request);
        switch on response.getStatusCode() {
            when 201 {
                final Object obj = System.JSON.deserialize(response.getBody(), UploadResult.class);
                res = (UploadResult)obj;
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
        public Data data {get;set;}

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
        public String documentId {get;set;}
    }

    public class UploadResult {
        @AuraEnabled
        public UploadResultData data {get;set;}

        /* @Description: success */
        @AuraEnabled
        public boolean success {get;set;}

        /* @Description: errorMessage */
        @AuraEnabled
        public String errorMessage {get;set;}
    }

    public class UploadResultData {
        @AuraEnabled
        public String fileId {get;set;}
    }


    /**
     *  @Description: Class MetadataUpdateRequest
    */
    public class MetadataUpdateRequest {
        @AuraEnabled
        public String fileId {get;set;}

        @AuraEnabled
        public String folderId {get;set;}

        @AuraEnabled
        public DocumentInfo documentInfo {get;set;}

        @AuraEnabled
        public Categorization categorization {get;set;}

        @AuraEnabled
        public SecurityLevelInfo securityLevelInfo {get;set;}
    }

    /**
     *  @Description: Class DocumentInfo
    */
    public class DocumentInfo {
        @AuraEnabled
        public String objectName {get;set;}

        @AuraEnabled
        public String owner {get;set;}

        @AuraEnabled
        public String responsible {get;set;}
    }

    /**
     *  @Description: Class Categorization
    */
    public class Categorization {
        @AuraEnabled
        public String documentTypeId {get;set;}
    }

    /**
     *  @Description: Class SecurityLevelInfo
    */
    public class SecurityLevelInfo {
        @AuraEnabled
        public integer securityLevel {get;set;}

        @AuraEnabled
        public integer classificationLevel {get;set;}
    }

    /**
     *  @Description: Class OriginInfo
    */
    //public class OriginInfo {
    //   @AuraEnabled
    //    public String documentCode {get;set;}
    //
    //    @AuraEnabled
    //    public String loc {get;set;}
    //}
}