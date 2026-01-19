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

    public static String uploadFile(String fileName, String base64Data, String fileType) {
        Datetime initTime = Datetime.now();
        iaso__GBL_integration_service__mdt uploadService;
        HttpRequest req;
        HttpResponse res;
        String requestBodyLog = 'Request not constructed';

        try {

            uploadService = DMT_CoreDocumentsUtils.getIntegrationServiceInfo('DMT_CoreDocumentsUpload');
            if (uploadService == null) {
                throw new CalloutException('No integration service found for DMT_CoreDocumentsUpload');
            }

            String uploadUrl = DMT_CoreDocumentsUtils.getUrlFromCustomSettings(uploadService.iaso__Custom_Setting__c);
            uploadUrl += uploadService.iaso__Querystring_Input_Template_LTA__c;

            Map<String, String> headers = getHeaders();

            // Construct Multipart Body
            String boundary = '----------------------------741e90d31eff';

            String headerStart = '--' + boundary + '\r\n' +
                            'Content-Disposition: form-data; name="file"; filename="' + fileName + '"';
            String headerEnd = '\r\n' + 'Content-Type: ' + fileType + '\r\n\r\n';

            while (Math.mod(Blob.valueOf(headerStart + headerEnd).size(), 3) != 0) {
                headerStart += ' ';
            }

            String header = headerStart + headerEnd;
            String footer = '\r\n--' + boundary + '--';
            String headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header));
            String bodyEncoded;

            if (base64Data.endsWith('=')) {
                Integer lastIndex = base64Data.length() - 4;
                String base64Prefix = base64Data.substring(0, lastIndex);
                String base64Suffix = base64Data.substring(lastIndex);

                Blob suffixBlob = EncodingUtil.base64Decode(base64Suffix);
                Blob footerBlob = Blob.valueOf(footer);

                String suffixHex = EncodingUtil.convertToHex(suffixBlob);
                String footerHex = EncodingUtil.convertToHex(footerBlob);
                Blob combinedBlob = EncodingUtil.convertFromHex(suffixHex + footerHex);

                String combinedEncoded = EncodingUtil.base64Encode(combinedBlob);

                bodyEncoded = headerEncoded + base64Prefix + combinedEncoded;
            } else {
                String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
                bodyEncoded = headerEncoded + base64Data + footerEncoded;
            }

            Blob bodyBlob = EncodingUtil.base64Decode(bodyEncoded);

            // Prepare log string
            requestBodyLog = header + '\n<File Content: ' + bodyBlob.size() + ' bytes>\n' + footer;


            // Upload file directly (no IASO)
            req = new HttpRequest();
            req.setEndpoint(uploadUrl);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundary);
            req.setHeader('Content-Length', String.valueOf(bodyBlob.size()));

            // Add custom headers
            for(String key : headers.keySet()) {
                req.setHeader(key, headers.get(key));
            }

            req.setBodyAsBlob(bodyBlob);
            req.setTimeout(120000); // 2 mins

            // System.debug('DEBUG: --- Request Details ---');
            // System.debug('DEBUG: Endpoint: ' + req.getEndpoint());
            // System.debug('DEBUG: Method: ' + req.getMethod());
            // System.debug('DEBUG: Content-Type: ' + req.getHeader('Content-Type'));
            // System.debug('DEBUG: Content-Length: ' + req.getHeader('Content-Length'));
            // System.debug('DEBUG: Custom Headers: ' + headers);
            // System.debug('DEBUG: Body Size (bytes): ' + bodyBlob.size());
            // System.debug('DEBUG: Multipart Header (Plain): ' + header.replace('\r', '\\r').replace('\n', '\\n'));
            // System.debug('DEBUG: Multipart Footer (Plain): ' + footer.replace('\r', '\\r').replace('\n', '\\n'));

            Http http = new Http();
            res = http.send(req);

            // System.debug('DEBUG: Response Status: ' + res.getStatus());
            // System.debug('DEBUG: Response StatusCode: ' + res.getStatusCode());
            // System.debug('DEBUG: Response Body: ' + res.getBody());

            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                // Parse response to get fileId
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> dataMap = (Map<String, Object>) responseMap.get('data');
                return (String) dataMap.get('fileId');
            } else {
                System.debug(LoggingLevel.ERROR, 'Upload failed. Status: ' + res.getStatus() + ', Body: ' + res.getBody());
                throw new CalloutException('Upload failed: ' + res.getStatus() + ' ' + res.getBody());
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception in uploadFile: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw e;

        } finally {
            // if (uploadService != null) {
            //     try {
            //         String responseBody = (res != null) ? res.getBody() : 'No Response';
            //         String endpoint = (req != null) ? req.getEndpoint() : 'Unknown Endpoint';
            //
            //         iaso__GBL_Application_Log__c log = new iaso__GBL_Application_Log__c(
            //             iaso__Start_Time__c = initTime,
            //             iaso__End_Time__c = Datetime.now(),
            //             iaso__Message_LTA__c = 'REQUEST: ' + endpoint + '\n' + requestBodyLog + '\n--\n--\n\nRESPONSE:\n' + responseBody,
            //             Name = uploadService.iaso__Custom_Setting__c,
            //             iaso__Type__c = 'Integration',
            //             iaso__User__c = UserInfo.getUserId()
            //         );
            //         insert log;
            //     } catch(Exception logEx) {
            //         System.debug(LoggingLevel.ERROR, 'Failed to insert log: ' + logEx.getMessage());
            //     }
            // }
        }
    }

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