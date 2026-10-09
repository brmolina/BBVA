/**-------------------------------------------------------------------------------------------
* @Name     DMT CoreDocuments Upload File
* @Author   jorgeandrés.florentin.tech@bbva.com
* @Date     Created: 2026-16-06
* ------------------------------------------------------------------------------------------------
* @Description Uploads snapshot PDFs to CoreDocuments.
*              Uses DES_CoreDocuments as the single facade for URL resolution, headers,
*              JWT token management (Portunus / Session Cache) and metadata updates.
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ExcessiveParameterList, Design-ExcessiveParameterList, PMD.NcssMethodCount, Design-NcssCount, Documentation-ApexDoc')
public with sharing class DMT_CoreDocumentsUploadFile {

    private static final String CONFIG_NAME  = 'DMT';
    private static final String DOC_TYPE     = 'CO-OF-00242';
    private static final String OBJECT_CODE  = 'CO-OF-00242';
    private static final Integer MAX_RETRIES = 2;
    private static final String LOG_NAME     = 'DMT_CoreDocumentsUploadFile';

    // ─────────────────────────────────────────────────────────────────────────
    // Public entry-points
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @description Main entry-point for uploading a snapshot PDF to CoreDocuments.
     * @param recordId Salesforce Id of Opportunity or DMT_Line__c.
     * @param fileName File name without extension.
     * @param pdfBase64 PDF body encoded as base64.
     */
    public static void upload(Id recordId, String fileName, String pdfBase64) {
        uploadSync(recordId, fileName, pdfBase64);
    }

    /**
     * @description Enqueues asynchronous upload to CoreDocuments.
     *              Internal async path used by the sync fallback logic.
     * @param recordId Salesforce Id of Opportunity or DMT_Line__c.
     * @param fileName File name without extension.
     * @param pdfBase64 PDF body encoded as base64.
     */
    private static void enqueueUpload(Id recordId, String fileName, String pdfBase64) {
        if (recordId == null || String.isBlank(fileName) || String.isBlank(pdfBase64)) {
            return;
        }
        // Capture caller context while still in the user session
        String callerUserId = UserInfo.getUserId();
        String callerFederationId = DES_CoreDocumentsUtils.getFederationIdentifier();
        System.enqueueJob(new UploadQueueable(recordId, fileName, pdfBase64, 0, callerUserId, callerFederationId));
    }

    /**
     * @description Synchronously uploads a snapshot PDF to CoreDocuments with session context.
     * @param recordId Salesforce Id of Opportunity or DMT_Line__c.
     * @param fileName File name without extension.
     * @param pdfBase64 PDF body encoded as base64.
     */
    public static void uploadSync(Id recordId, String fileName, String pdfBase64) {
        if (recordId == null || String.isBlank(fileName) || String.isBlank(pdfBase64)) {
            return;
        }

        Datetime initTime = Datetime.now();
        String callerUserId = UserInfo.getUserId();
        String uploadedFileId;

        try {
            String folderId = resolveFolderId(recordId);
            if (String.isBlank(folderId)) {
                System.debug(LoggingLevel.WARN, '[DMT_CoreDocumentsUploadFile] Upload skipped. recordId=' + recordId + ', reason=folderId not resolved');
                return;
            }
            uploadedFileId = uploadFile(fileName + '.pdf', pdfBase64, 'application/pdf');
            if (String.isBlank(uploadedFileId)) {
                System.debug(LoggingLevel.WARN, '[DMT_CoreDocumentsUploadFile] Upload skipped. recordId=' + recordId + ', reason=fileId not returned from upload service');
                return;
            }
            
            try {
                updateFileMetadata(uploadedFileId, fileName + '.pdf', folderId);
            } catch (Exception metaEx) {
                // Metadata failure is non-blocking: file is already in CoreDocuments.
                System.debug(LoggingLevel.WARN,
                    '[DMT_CoreDocumentsUploadFile] Metadata update failed (partial success). recordId=' + recordId
                    + ', fileId=' + uploadedFileId + ', error=' + metaEx.getMessage()
                    + ', stackTrace=' + metaEx.getStackTraceString());

                return;
            }
            System.debug('[DMT_CoreDocumentsUploadFile] Upload completed. recordId=' + recordId + ', fileId=' + uploadedFileId);
        } catch (Exception ex) {
            if (!Test.isRunningTest() && shouldFallbackToAsync(ex)) {
                System.debug(LoggingLevel.WARN, '[DMT_CoreDocumentsUploadFile] Sync upload cannot perform callout in current transaction. ' + 'Falling back to async queueable. recordId=' + recordId + ', error=' + ex.getMessage());
                enqueueUpload(recordId, fileName, pdfBase64);
                return;
            }

            System.debug(LoggingLevel.ERROR,
                '[DMT_CoreDocumentsUploadFile] Upload failed (sync). recordId=' + recordId
                + ', error=' + ex.getMessage()
                + ', errorType=' + ex.getTypeName()
                + ', stackTrace=' + ex.getStackTraceString());
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Queueable inner class
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @description Queueable callout job that uploads the snapshot and updates metadata.
     *              Retries up to MAX_RETRIES times on failure.
     *              NOTE: Session Cache is not available in this async context.
     *              Main public entrypoint is upload().
     */
    public class UploadQueueable implements Queueable, Database.AllowsCallouts {
        private final Id      recordId;
        private final String  fileName;
        private final String  pdfBase64;
        private final Integer attempt;
        private final String  callerUserId;
        private final String  callerFederationId;

        /**
         * @description Creates queueable payload for one upload attempt.
         * @param recordId          Salesforce Id of the source record.
         * @param fileName          File name without extension.
         * @param pdfBase64         PDF body encoded as base64.
         * @param attempt           Current retry attempt (0-based).
         * @param callerUserId      Salesforce UserId captured in the originating sync context.
         * @param callerFederationId Federation identifier captured in the originating sync context.
         */
        @SuppressWarnings('Documentation-ApexDoc')
        public UploadQueueable(Id recordId, String fileName, String pdfBase64, Integer attempt,String callerUserId, String callerFederationId) {
            this.recordId          = recordId;
            this.fileName          = fileName;
            this.pdfBase64         = pdfBase64;
            this.attempt           = attempt;
            this.callerUserId      = callerUserId;
            this.callerFederationId = callerFederationId;
        }

        /**
         * @description Executes upload and metadata update, retrying on failure.
         * @param context Queueable execution context.
         */
        public void execute(QueueableContext context) {
            Datetime initTime = Datetime.now();
            String uploadedFileId;

            try {
                String folderId = resolveFolderId(recordId);
                if (String.isBlank(folderId)) {
                    throw new CalloutException('CoreDocuments folderId could not be resolved for recordId=' + recordId);
                }

                uploadedFileId = uploadFile(fileName + '.pdf', pdfBase64, 'application/pdf');
                if (String.isBlank(uploadedFileId)) {
                    throw new CalloutException('CoreDocuments upload did not return fileId for recordId=' + recordId);
                }

                try {
                    updateFileMetadata(uploadedFileId, fileName + '.pdf', folderId);
                } catch (Exception metaEx) {
                    // Metadata failure is non-blocking: file already uploaded.
                    System.debug(LoggingLevel.WARN,
                        '[DMT_CoreDocumentsUploadFile] Metadata update failed (async, partial success). recordId=' + recordId
                        + ', fileId=' + uploadedFileId + ', error=' + metaEx.getMessage()
                        + ', stackTrace=' + metaEx.getStackTraceString());
                    return;
                }

                System.debug('[DMT_CoreDocumentsUploadFile] Async upload completed. recordId=' + recordId + ', fileId=' + uploadedFileId + ', attempt=' + attempt);

            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, '[DMT_CoreDocumentsUploadFile] Async upload attempt failed. recordId=' + recordId + ', attempt=' + attempt + ', error=' + ex.getMessage());

                if (!Test.isRunningTest() && attempt < MAX_RETRIES) {
                    System.enqueueJob(new UploadQueueable( recordId, fileName, pdfBase64, attempt + 1, callerUserId, callerFederationId));
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Private helpers
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @description Resolves the CoreDocuments folderId from the source record.
     * @param recordId Salesforce record Id.
     * @return CoreDocuments folder id, or null if not found.
     */
    @TestVisible
    private static String resolveFolderId(Id recordId) {
        if (recordId == null) {
            return null;
        }

        Schema.SObjectType recordType = recordId.getSObjectType();
        if (recordType == Opportunity.SObjectType) {
            List<Opportunity> opportunities = [ SELECT DMT_Opp_Id__c FROM Opportunity WHERE Id = :recordId WITH SYSTEM_MODE LIMIT 1];
            return opportunities.isEmpty() ? null : opportunities[0].DMT_Opp_Id__c;
        }

        if (recordType == DMT_Line__c.SObjectType) {
            List<DMT_Line__c> lines = [ SELECT Line_Id__c FROM DMT_Line__c WHERE Id = :recordId WITH SYSTEM_MODE LIMIT 1 ];
            return lines.isEmpty() ? null : lines[0].Line_Id__c;
        }

        return null;
    }

    /**
     * @description Uploads a file to CoreDocuments using the DES_CoreDocuments facade.
     * @param fileName   File name with extension (e.g. 'snapshot.pdf').
     * @param base64Data File content encoded as base64.
     * @param fileType   MIME type (e.g. 'application/pdf').
     * @return CoreDocuments fileId returned by the upload service.
     */
    @TestVisible
    private static String uploadFile(String fileName, String base64Data, String fileType) {
        String uploadUrl = DES_CoreDocuments.getUploadUrl(CONFIG_NAME);
        if (String.isBlank(uploadUrl)) {
            throw new CalloutException('CoreDocuments upload URL is null or empty for config=' + CONFIG_NAME);
        }

        Map<String, String> headers = DES_CoreDocuments.getUploadHeaders(CONFIG_NAME);
        if (headers == null) {
            throw new CalloutException('CoreDocuments headers are null for config=' + CONFIG_NAME);
        }

        String boundary = '----------------------------741e90d31eff';
        Blob bodyBlob   = buildMultipartBodyBlob(boundary, fileName, fileType, base64Data);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(uploadUrl);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundary);
        req.setHeader('Content-Length', String.valueOf(bodyBlob.size()));
        req.setTimeout(120000);

        for (String key : headers.keySet()) {
            req.setHeader(key, headers.get(key));
        }
        req.setBodyAsBlob(bodyBlob);

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
            throw new CalloutException('Upload failed: ' + res.getStatus() + ' ' + res.getBody());
        }

        String responseBody = res.getBody();
        if (String.isBlank(responseBody)) {
            throw new CalloutException('CoreDocuments returned empty response body');
        }

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        if (responseMap == null) {
            throw new CalloutException('CoreDocuments response JSON is null');
        }

        Map<String, Object> dataMap = (Map<String, Object>) responseMap.get('data');
        if (dataMap == null) {
            throw new CalloutException('CoreDocuments response data field is null. Response: ' + responseBody);
        }

        String fileId = (String) dataMap.get('fileId');
        if (String.isBlank(fileId)) {
            throw new CalloutException('CoreDocuments response fileId is null or empty. Response: ' + responseBody);
        }

        return fileId;
    }

    /**
     * @description Builds an  multipart/form-data body as a Blob.
     * @param boundary  Multipart boundary string (without leading '--').
     * @param fileName  File name included in the Content-Disposition header.
     * @param fileType  MIME type included in the Content-Type header.
     * @param base64Data File content already encoded as base64.
     * @return          Binary Blob ready to be set as the HTTP request body.
     */
    @TestVisible
    private static Blob buildMultipartBodyBlob(String boundary, String fileName, String fileType, String base64Data) {
        // Build the multipart header parts
        String headerStart = '--' + boundary + '\r\n' + 'Content-Disposition: form-data; name="file"; filename="' + fileName + '"';
        String headerEnd   = '\r\nContent-Type: ' + fileType + '\r\n\r\n';

        // Pad header to 3-byte alignment so its base64 encoding has no trailing '='
        while (Math.mod(Blob.valueOf(headerStart + headerEnd).size(), 3) != 0) {
            headerStart += ' ';
        }

        String header        = headerStart + headerEnd;
        String footer        = '\r\n--' + boundary + '--';
        String headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header));
        String bodyEncoded;

        if (base64Data.endsWith('=')) {
            // PDF byte count is NOT a multiple of 3: strip the padded last 4-char block,
            // merge its decoded bytes with footer bytes via hex, then re-encode together.
            Integer lastIndex    = base64Data.length() - 4;
            String base64Prefix  = base64Data.substring(0, lastIndex);
            String base64Suffix  = base64Data.substring(lastIndex);

            Blob suffixBlob      = EncodingUtil.base64Decode(base64Suffix);
            Blob footerBlob      = Blob.valueOf(footer);
            String suffixHex     = EncodingUtil.convertToHex(suffixBlob);
            String footerHex     = EncodingUtil.convertToHex(footerBlob);
            Blob combinedBlob    = EncodingUtil.convertFromHex(suffixHex + footerHex);
            String combinedEncoded = EncodingUtil.base64Encode(combinedBlob);

            bodyEncoded = headerEncoded + base64Prefix + combinedEncoded;
        } else {
            // PDF byte count is already a 3-byte multiple; just append footer base64.
            String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
            bodyEncoded = headerEncoded + base64Data + footerEncoded;
        }

        return EncodingUtil.base64Decode(bodyEncoded);
    }

    /**
     * @description Updates CoreDocuments file metadata via DES_CoreDocuments facade.
     * @param fileId   CoreDocuments fileId returned after successful upload.
     * @param fileName File name with extension.
     * @param folderId CoreDocuments folder id (DMT_Opp_Id__c or Line_Id__c of the record).
     */
    @TestVisible
    private static void updateFileMetadata(String fileId, String fileName, String folderId) {
        DES_CoreDocuments.UpdateFileMetadataRequest request = new DES_CoreDocuments.UpdateFileMetadataRequest();
        request.fileId     = fileId;
        request.fileName   = fileName;
        request.docType    = DOC_TYPE;
        request.folderId   = folderId;
        request.configName = CONFIG_NAME;
        request.objectCode = OBJECT_CODE;
        DES_CoreDocuments.updateFileMetadata(request);
    }

    private static Boolean shouldFallbackToAsync(Exception ex) {
        if (ex == null || String.isBlank(ex.getMessage())) {
            return false;
        }

        String errorMessage = ex.getMessage().toLowerCase();
        return errorMessage.contains('uncommitted work pending')|| errorMessage.contains('please commit or rollback before calling out');
    }
}