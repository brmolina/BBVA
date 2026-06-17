/**-------------------------------------------------------------------------------------------
* @Name     DMT CoreDocuments Upload Integration Headers and utility methods
* @Author   torcuato.tejada.tech@bbva.com
* @Date     Created: 2025-11-06
* ------------------------------------------------------------------------------------------------
* @Description IASO Integration headers interface implementation for CoreDocuments service.
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class DMT_CoreDocumentsUpload implements iaso.GBL_Integration_Headers {

    private static final String SERVICENAME = 'DMT_CoreDocumentsUpload';
    private static final String DOMAIN = 'gl-finance-cib-ei';
    private static final String NAMESPACE = 'dmto.gl.int';

    global HttpRequest modifyRequest(HttpRequest request) {
        Map<String,String> headers = getHeaders();
        request.setHeader('vnd.bbva.user-id', headers.get('vnd.bbva.user-id'));
        request.setHeader('service-id', headers.get('service-id'));
        //request.setHeader('enctype', headers.get('enctype'));
        request.setHeader('Authorization', headers.get('Authorization'));
        return request;
    }

    public static Map<String,String> getHeaders() {

        Map<String,String> headers = new Map<String,String>();

        iaso__GBL_Authentication_Service__mdt authConfig = DMT_CoreDocumentsUtils.getAuthenticationConfigFromService(SERVICENAME);

        // Check if the session is stored in the cache
        Cache.Partition partition;
        if (!authConfig.iaso__isOrgCache__c) {
            Cache.SessionPartition sessionPart = Cache.Session.getPartition(authConfig.iaso__Cache_Partition__c);
            partition = sessionPart;
        } else {
            Cache.OrgPartition orgPart = Cache.Org.getPartition(authConfig.iaso__Cache_Partition__c);
            partition = orgPart;
        }

        // Retrieve cache value from the partition
        Map<String, String> credentials = (Map<String,String>)partition.get(authConfig.iaso__Cache_Key__c);

        String jwt = DMT_CoreDocumentsJWT.getJWToken();

        System.debug('DEBUG: DMT_CoreDocumentsUpload.getHeaders - JWT Token: ' + (jwt != null ? 'Token present' : 'Token null'));
        System.debug('DEBUG: DMT_CoreDocumentsUpload.getHeaders - Auth Config User: ' + authConfig.iaso__User__c);

        headers.put('vnd.bbva.user-id', authConfig.iaso__User__c);
        headers.put('service-id', 'SMGG20253303');
        //headers.put('enctype', 'multipart/form-data');
        headers.put('Authorization', 'Bearer ' + jwt);

        System.debug('DEBUG: DMT_CoreDocumentsUpload.getHeaders - Final Headers: ' + headers);

        return headers;
    }

    @AuraEnabled
    public static void updateFileMetadata(String fileId, String fileName, String docType, String opportunityId) {
        try {

            // send metadata for new file

            DMT_CoreDocuments.MetadataUpdateRequest metadataRequest = new DMT_CoreDocuments.MetadataUpdateRequest();
            DMT_CoreDocuments.DocumentInfo documentInfo = new DMT_CoreDocuments.DocumentInfo();
            DMT_CoreDocuments.Categorization categorization = new DMT_CoreDocuments.Categorization();
            DMT_CoreDocuments.SecurityLevelInfo securityLevelInfo = new DMT_CoreDocuments.SecurityLevelInfo();

            documentInfo.objectName = fileName;
            documentInfo.owner = DMT_HPG_Utils.getFederationIdentifier();
            documentInfo.responsible = 'BBVA-CIB';

            categorization.documentTypeId = docType;

            securityLevelInfo.securityLevel = 3;
            securityLevelInfo.classificationLevel = 5;

            metadataRequest.fileId = fileId;
            metadataRequest.folderId = opportunityId;
            metadataRequest.documentInfo = documentInfo;
            metadataRequest.categorization = categorization;
            metadataRequest.securityLevelInfo = securityLevelInfo;

            String metadataRequestStr = JSON.serialize(metadataRequest);
            System.debug('DEBUG: Metadata Request Payload: ' + metadataRequestStr);

            Map<String, Object> request = new Map<String, Object>();
            request.put('payload', metadataRequestStr);

            System.debug('request: ' + request);

            HttpResponse response = DMT_HPG_Utils.callService('DMT_CoreDocumentsMetadata', request);

            System.debug('DEBUG: Metadata Update Response Status: ' + response.getStatus());
            System.debug('DEBUG: Metadata Update Response Body: ' + response.getBody());

            if (response.getStatusCode() >= 300) {
                System.debug(LoggingLevel.ERROR, 'Metadata update failed. Status: ' + response.getStatus() + ', Body: ' + response.getBody());
                throw new CalloutException('Metadata update failed: ' + response.getBody());
            }

        } catch (Exception e) {
            throw new CalloutException(e.getMessage());
        }
    }
}