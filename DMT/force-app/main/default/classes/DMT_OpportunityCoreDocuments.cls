/**-------------------------------------------------------------------------------------------
* @Name     DMT Expedient Folders
* @Author   torcuato.tejada.tech@bbva.com
* @Date     Created: 2025-11-25
* ------------------------------------------------------------------------------------------------
* @Description Wrapper Class for DMT Expedient-Folders Service
* ------------------------------------------------------------------------------------------------
*/
public with sharing class DMT_OpportunityCoreDocuments {

    @AuraEnabled(cacheable=true)
    public static DMT_CoreDocumentsExpedientFolders.Wrapper getExpedientFolders(String opportunityId) {
        DMT_CoreDocumentsExpedientFolders.Wrapper expedientFolders = new DMT_CoreDocumentsExpedientFolders.Wrapper();
        try {
            Map<String, Object> request = new Map<String, Object>();
            request.put('qExpression', 'businessCode.folderCode==*' + opportunityId + '*');
            request.put('page', '1');
            request.put('pageSize', '100');
            expedientFolders = DMT_CoreDocumentsExpedientFolders.getExpedientFolders(request);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return expedientFolders;
    }

    @AuraEnabled
    public static String downloadFile(String contentLocator) {
        try {
            String fileContent;
            Map<String, Object> request = new Map<String, Object>();
            request.put('contentLocator', contentLocator);
            final HttpResponse response = DMT_HPG_Utils.callService('DMT_CoreDocumentsDownload', request);
            switch on response.getStatusCode() {
                when 200 {
                    fileContent = EncodingUtil.base64Encode(response.getBodyAsBlob());
                }
                when else {
                    throw new AuraHandledException('Error downloading file ' + contentLocator + ': '+ response.getStatus());
                }
            }
            return fileContent;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String getUploadEndpoint() {
        try {
           iaso__GBL_integration_service__mdt uploadService = DMT_CoreDocumentsUtils.getIntegrationServiceInfo('DMT_CoreDocumentsUpload');

            if (uploadService == null) {
                throw new AuraHandledException('No integration service found for DMT_CoreDocumentsUpload');
            }

            String uploadUrl = DMT_CoreDocumentsUtils.getUrlFromCustomSettings(uploadService.iaso__Custom_Setting__c);
            uploadUrl += uploadService.iaso__Querystring_Input_Template_LTA__c;

            System.debug('DEBUG: getUploadEndpoint: ' + uploadUrl);
            return uploadUrl;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, String> getUploadHeaders() {
        try {
            Map<String, String> headers = DMT_CoreDocumentsUpload.getHeaders();
            System.debug('DEBUG: getUploadHeaders: ' + headers);
            return headers;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String uploadFile(String fileName, String base64Data, String fileType) {
        try {
            return DMT_CoreDocumentsUpload.uploadFile(fileName, base64Data, fileType);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception in uploadFile: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateFileMetadata(String fileId, String fileName, String docType, String opportunityId) {
        try {
            DMT_CoreDocumentsUpload.updateFileMetadata(fileId, fileName, docType, opportunityId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}