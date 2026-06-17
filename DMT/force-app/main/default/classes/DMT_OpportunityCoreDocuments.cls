/**-------------------------------------------------------------------------------------------
* @Name     DMT Expedient Folders
* @Author   torcuato.tejada.tech@bbva.com
* @Date     Created: 2025-11-25
* ------------------------------------------------------------------------------------------------
* @Description Wrapper Class for DMT Expedient-Folders Service
*              Uses 'DMT' Custom Metadata configuration
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ExcessiveParameterList')
public with sharing class DMT_OpportunityCoreDocuments {

    // Custom Metadata configuration name for DMT
    private static final String CONFIG_NAME = 'DMT';

    @AuraEnabled(cacheable=true)
    public static DES_CoreDocumentsExpedientFolders.Wrapper getDocuments(String opportunityId) {
        DES_CoreDocumentsExpedientFolders.Wrapper expedientFolders = new DES_CoreDocumentsExpedientFolders.Wrapper();
        try {
            Map<String, Object> request = new Map<String, Object>();
            request.put('qExpression', 'businessCode.folderCode==*' + opportunityId + '*');
            request.put('page', '1');
            request.put('pageSize', '100');
            expedientFolders = DES_CoreDocumentsExpedientFolders.getExpedientFolders(request, CONFIG_NAME);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return expedientFolders;
    }

    @AuraEnabled
    public static String getUploadEndpoint() {
        try {
            // Get base CoreDocuments endpoint from config
            String uploadUrl = DES_CoreDocuments.getUploadUrl(CONFIG_NAME);
            return uploadUrl;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string getDownloadEndpoint(String contentLocator){
        try {
            // Get base CoreDocuments endpoint from config
            String downloadUrl = DES_CoreDocuments.getDownloadUrl(CONFIG_NAME, contentLocator);
            return downloadUrl;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, String> getUploadHeaders() {
        try {
            Map<String, String> headers = DES_CoreDocuments.getUploadHeaders(CONFIG_NAME);
            return headers;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, String> getDownloadHeaders() {
        try {
            Map<String, String> headers = DES_CoreDocuments.getDownloadHeaders(CONFIG_NAME);
            return headers;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateFileMetadata(String fileId, String fileName, String docType, String opportunityId) {
        try {
            DES_CoreDocuments.UpdateFileMetadataRequest req = new DES_CoreDocuments.UpdateFileMetadataRequest();
            req.fileId = fileId;
            req.fileName = fileName;
            req.docType = docType;
            req.folderId = opportunityId;
            req.configName = CONFIG_NAME;
            DES_CoreDocuments.updateFileMetadata(req);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}