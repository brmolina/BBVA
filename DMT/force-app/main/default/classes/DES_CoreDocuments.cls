/**-------------------------------------------------------------------------------------------
* @Name     DMT Expedient Folders
* @Author   torcuato.tejada.tech@bbva.com
* @Date     Created: 2025-11-05
* ------------------------------------------------------------------------------------------------
* @Description Wrapper class for Expedient-Folders CoreDocuments Service response
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ExcessivePublicCount, PMD.TooManyFields, PMD.ExcessiveParameterList')
public with sharing class DES_CoreDocuments {

    @TestVisible
    private static Map<String, Config> testConfigByName;

    @TestVisible
    static void setTestConfig(String configName, Config config) {
        if (testConfigByName == null) {
            testConfigByName = new Map<String, Config>();
        }
        testConfigByName.put(configName, config);
    }

    @TestVisible
    static void clearTestConfigs() {
        testConfigByName = null;
    }

    @TestVisible
    static Config createTestConfig() {
        return new Config(true);
    }
    /**
    * @description Get configuration from Custom Metadata and return wrapper with response data from Expedient-Folders service
    * @param request Request parameters
    * @param configName Custom Metadata developer name (e.g., 'DMT', 'ABC')
    * @return Wrapper with response data from Expedient-Folders service
    */
    public static Config getConfig(String configName) {
        if (String.isBlank(configName)) {
            throw new DES_CoreDocumentsConfigException('CoreDocuments configuration name is required. Provide the Custom Metadata DeveloperName (e.g., \'DMT\').');
        }

        if (Test.isRunningTest() && testConfigByName != null && testConfigByName.containsKey(configName)) {
            return testConfigByName.get(configName);
        }
        return new Config(configName);
    }

    /**
    * @description Get the CoreDocuments endpoint URL based on the configuration name
    * @param configName Custom Metadata developer name (e.g., 'DMT', 'ABC')
    * @return CoreDocuments endpoint URL
    */
    public static String getCoreDocumentsEndpoint(String configName) {
        Config config = getConfig(configName);

        String endpoint = config.coreDocEndpoint;
        if (!endpoint.endsWith('/')) {
            endpoint += '/';
        }

        return endpoint + 'ns/' + config.namespace + '/domains/' + config.domain + '/';
    }

    /**
    * @description Get the upload endpoint URL based on the configuration name
    * @param configName Custom Metadata developer name (e.g., 'DMT', 'ABC')
    * @return Upload endpoint URL
    */
    public static String getUploadUrl(String configName) {
        return getCoreDocumentsEndpoint(configName) + 'file:frontUpload';
    }

    /**
    * @description Get the download endpoint URL based on the configuration name and content locator
    * @param configName Custom Metadata developer name (e.g., 'DMT', 'ABC')
    * @param contentLocator Content locator for the file to be downloaded
    * @return Download endpoint URL
    */
    public static String getDownloadUrl(String configName, String contentLocator) {
        return getCoreDocumentsEndpoint(configName) + 'documents/' + contentLocator + ':getFrontFile';
    }

    /**
    * @description Get headers with configuration from Custom Metadata for downloading files
    * @param configName Custom Metadata developer name (e.g., 'DMT', 'ABC')
    * @return Map of headers
    */
    public static Map<String, String> getDownloadHeaders(String configName) {

        Map<String, String> headers = new Map<String, String>();
        Config cfg = getConfig(configName);
        String jwtToken = (String)Cache.Session.get(cfg.expedientFoldersJwtCacheKey);
        headers.put('Authorization', 'Bearer ' + jwtToken);
        return headers;
    }

    /**
    * @description Get headers with configuration from Custom Metadata
    * @param configName Custom Metadata developer name (e.g., 'DMT', 'ABC')
    * @return Map of headers
    */
    public static Map<String, String> getUploadHeaders(String configName) {
        Map<String, String> headers = new Map<String, String>();
        Config cfg = getConfig(configName);
        iaso__GBL_Authentication_Service__mdt authConfig = DES_CoreDocumentsUtils.getAuthenticationConfigFromService(cfg.expedientFoldersServiceName);
        String jwt = DES_CoreDocumentsJWT.getJWToken(configName);
        headers.put('vnd.bbva.user-id', authConfig.iaso__User__c);
        headers.put('service-id', cfg.serviceId);
        headers.put('Authorization', 'Bearer ' + jwt);
        return headers;
    }

    /**
    * @description Update file metadata with configuration from Custom Metadata
    * @param request Update parameters (includes configName)
    */
    public static void updateFileMetadata(UpdateFileMetadataRequest request) {
        try {

            Config cfg = getConfig(request.configName);

            DES_CoreDocuments.MetadataUpdateRequest metadataRequest = new DES_CoreDocuments.MetadataUpdateRequest();
            DES_CoreDocuments.DocumentInfo documentInfo = new DES_CoreDocuments.DocumentInfo();
            DES_CoreDocuments.Categorization categorization = new DES_CoreDocuments.Categorization();
            DES_CoreDocuments.OriginInfo originInfo = new DES_CoreDocuments.OriginInfo();
            DES_CoreDocuments.SecurityLevelInfo securityLevelInfo = new DES_CoreDocuments.SecurityLevelInfo();

            documentInfo.objectName = request.fileName;
            documentInfo.owner = DES_CoreDocumentsUtils.getFederationIdentifier();
            documentInfo.responsible = cfg.responsible;

            categorization.documentTypeId = request.docType;
            originInfo.documentCode = request.objectCode;

            securityLevelInfo.securityLevel = 3;
            securityLevelInfo.classificationLevel = 5;

            metadataRequest.fileId = request.fileId;
            metadataRequest.folderId = request.folderId;
            metadataRequest.documentInfo = documentInfo;
            metadataRequest.categorization = categorization;
            metadataRequest.originInfo = originInfo;
            metadataRequest.securityLevelInfo = securityLevelInfo;

            String metadataRequestStr = JSON.serialize(metadataRequest);

            Map<String, Object> serviceRequest = new Map<String, Object>();
            serviceRequest.put('payload', metadataRequestStr);
            System.debug(LoggingLevel.INFO, 'DES_CoreDocuments.updateFileMetadata - payload: ' + metadataRequestStr);
            System.debug(LoggingLevel.INFO, 'DES_CoreDocuments.updateFileMetadata - serviceRequest: ' + JSON.serialize(serviceRequest));
            

            HttpResponse response = DES_CoreDocumentsUtils.callService(cfg.metadataServiceName, serviceRequest);

            if (response.getStatusCode() >= 300) {
                throw new CalloutException('Metadata update failed: ' + response.getBody());
            }

        } catch (Exception e) {
            throw new CalloutException(e.getMessage());
        }
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
     *  @Description: Class UpdateFileMetadataRequest
    */
    public class UpdateFileMetadataRequest {
        @AuraEnabled
        public String fileId {get;set;}

        @AuraEnabled
        public String fileName {get;set;}

        @AuraEnabled
        public String docType {get;set;}

        @AuraEnabled
        public String folderId {get;set;}

        @AuraEnabled
        public String configName {get;set;}

        @AuraEnabled
        public String objectCode {get;set;}
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

        @AuraEnabled
        public OriginInfo originInfo {get;set;}
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
    public class OriginInfo {
       @AuraEnabled
        public String documentCode {get;set;}

        @AuraEnabled
        public String loc {get;set;}
    }

    public class DES_CoreDocumentsConfigException extends Exception {}

    public with sharing class Config {
        public String expedientFoldersServiceName {get; set;}
        public String jwtServiceName {get; set;}
        public String metadataServiceName {get; set;}

        public String domain {get; set;}
        public String namespace {get; set;}

        public String jwtCacheKey {get; set;}
        public String expedientFoldersJwtCacheKey {get; set;}

        public String serviceId {get; set;}
        public String responsible {get; set;}

        public String coreDocEndpoint {get; set;}

        private Boolean isTestConfig = false;
        
        @TestVisible
        private Config(Boolean isTestConfig) {
            this.isTestConfig = isTestConfig;
        }

        public Config(String configName) {
            if (isTestConfig) {
                return;
            }
            if (String.isBlank(configName)) {
                throw new DES_CoreDocumentsConfigException('CoreDocuments configuration name is required. Provide the Custom Metadata DeveloperName in DES_CoreDocuments_Config__mdt.');
            }

            DES_CoreDocuments_Config__mdt mdt = loadConfigMdt(configName);
            expedientFoldersServiceName = mdt.Expedient_Folders_Service_Name__c;
            jwtServiceName = mdt.JWT_Service_Name__c;
            metadataServiceName = mdt.Metadata_Service_Name__c;
            domain = mdt.Domain__c;
            namespace = mdt.Namespace__c;
            jwtCacheKey = mdt.JWT_Cache_Key__c;
            expedientFoldersJwtCacheKey = mdt.Expedient_Folders_JWT_Cache_Key__c;
            serviceId = mdt.Service_Id__c;
            responsible = mdt.Responsible__c;
            coreDocEndpoint = mdt.CoreDoc_Endpoint__c;

            validateRequiredFields(configName);
        }

        @SuppressWarnings('PMD.ApexCRUDViolation')
        private DES_CoreDocuments_Config__mdt loadConfigMdt(String configName) {
            List<DES_CoreDocuments_Config__mdt> records = [
                SELECT
                    Expedient_Folders_Service_Name__c,
                    JWT_Service_Name__c,
                    Metadata_Service_Name__c,
                    Domain__c,
                    Namespace__c,
                    JWT_Cache_Key__c,
                    Expedient_Folders_JWT_Cache_Key__c,
                    Service_Id__c,
                    Responsible__c,
                    CoreDoc_Endpoint__c
                FROM DES_CoreDocuments_Config__mdt
                WHERE DeveloperName = :configName
                LIMIT 1
            ];

            if (records.isEmpty()) {
                throw new DES_CoreDocumentsConfigException('No CoreDocuments configuration found for DeveloperName=\'' + configName + '\' in DES_CoreDocuments_Config__mdt.');
            }
            return records[0];
        }

        private void validateRequiredFields(String configName) {
            List<String> missing = new List<String>();
            Map<String, String> requiredFields = new Map<String, String>{
                'Expedient_Folders_Service_Name__c' => expedientFoldersServiceName,
                'JWT_Service_Name__c' => jwtServiceName,
                'Metadata_Service_Name__c' => metadataServiceName,
                'Domain__c' => domain,
                'Namespace__c' => namespace,
                'JWT_Cache_Key__c' => jwtCacheKey,
                'Expedient_Folders_JWT_Cache_Key__c' => expedientFoldersJwtCacheKey,
                'Service_Id__c' => serviceId,
                'Responsible__c' => responsible,
                'CoreDoc_Endpoint__c' => coreDocEndpoint
            };

            for (String fieldApiName : requiredFields.keySet()) {
                if (String.isBlank(requiredFields.get(fieldApiName))) {
                    missing.add(fieldApiName);
                }
            }

            if (!missing.isEmpty()) {
                throw new DES_CoreDocumentsConfigException(
                    'CoreDocuments configuration is incomplete for DeveloperName=\'' + configName + '\'. Missing: ' + String.join(missing, ', ') + '.'
                );
            }
        }
    }
}