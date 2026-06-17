/**-------------------------------------------------------------------------------------------
* @Name     DMT CoreDocuments Upload File
* @Author   torcuato.tejada.tech@bbva.com
* @Date     Created: 2025-11-06
* ------------------------------------------------------------------------------------------------
* @Description Uploads email snapshot PDFs to CoreDocuments after email sending.
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ExcessiveParameterList, Design-ExcessiveParameterList, PMD.NcssMethodCount, Design-NcssCount, Documentation-ApexDoc')
public with sharing class DMT_CoreDocumentsUploadFile {

    private static final String CONFIG_NAME = 'DMT';
    private static final String DOC_TYPE = 'CO-OF-00242';
    private static final String OBJECT_CODE = 'CO-OF-00242';
    private static final Integer MAX_RETRIES = 2;

    /**
     * @description Enqueues asynchronous upload to CoreDocuments for a sent email snapshot PDF.
     * @param recordId Salesforce Id of Opportunity or DMT_Line__c.
     * @param fileName File name without extension.
     * @param pdfBase64 PDF body encoded as base64.
     */
    public static void enqueueUploadAfterEmail(Id recordId, String fileName, String pdfBase64) {
        if (recordId == null || String.isBlank(fileName) || String.isBlank(pdfBase64)) {
            return;
        }
        System.enqueueJob(new UploadQueueable(recordId, fileName, pdfBase64, 0));
    }

    /**
     * @description Queueable callout job that uploads the snapshot and updates metadata.
     */
    public class UploadQueueable implements Queueable, Database.AllowsCallouts {
        private final Id recordId;
        private final String fileName;
        private final String pdfBase64;
        private final Integer attempt;

        /**
         * @description Creates queueable payload for one upload attempt.
         * @param recordId Salesforce Id of the source record.
         * @param fileName File name without extension.
         * @param pdfBase64 PDF body encoded as base64.
         * @param attempt Current retry attempt.
         */
        @SuppressWarnings('Documentation-ApexDoc')
        public UploadQueueable(Id recordId, String fileName, String pdfBase64, Integer attempt) {
            this.recordId = recordId;
            this.fileName = fileName;
            this.pdfBase64 = pdfBase64;
            this.attempt = attempt;
        }

        /**
         * @description Executes upload and metadata update, retrying on failure.
         * @param context Queueable execution context.
         */
        public void execute(QueueableContext context) {
            try {
                String folderId = resolveFolderId(recordId);
                if (String.isBlank(folderId)) {
                    throw new CalloutException('CoreDocuments folderId could not be resolved for recordId=' + recordId);
                }

                String uploadedFileId = uploadFile(fileName + '.pdf', pdfBase64, 'application/pdf');
                if (String.isBlank(uploadedFileId)) {
                    throw new CalloutException('CoreDocuments upload did not return fileId for recordId=' + recordId);
                }

                updateFileMetadata(uploadedFileId, fileName + '.pdf', folderId);
                System.debug('CoreDocuments upload completed. recordId=' + recordId + ', fileId=' + uploadedFileId);
            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR,
                    'CoreDocuments upload attempt failed. recordId=' + recordId
                    + ', attempt=' + attempt
                    + ', error=' + ex.getMessage());

                if (!Test.isRunningTest() && attempt < MAX_RETRIES) {
                    System.enqueueJob(new UploadQueueable(recordId, fileName, pdfBase64, attempt + 1));
                }
            }
        }
    }

    @TestVisible
    private static String resolveFolderId(Id recordId) {
        if (recordId == null) {
            return null;
        }

        Schema.SObjectType recordType = recordId.getSObjectType();
        if (recordType == Opportunity.SObjectType) {
            List<Opportunity> opportunities = [SELECT DMT_Opp_Id__c FROM Opportunity WHERE Id = :recordId WITH SYSTEM_MODE LIMIT 1];
            return opportunities.isEmpty() ? null : opportunities[0].DMT_Opp_Id__c;
        }

        if (recordType == DMT_Line__c.SObjectType) {
            List<DMT_Line__c> lines = [SELECT Line_Id__c FROM DMT_Line__c WHERE Id = :recordId WITH SYSTEM_MODE LIMIT 1];
            return lines.isEmpty() ? null : lines[0].Line_Id__c;
        }

        return null;
    }

    @TestVisible
    private static String uploadFile(String fileName, String base64Data, String fileType) {
        String uploadUrl = DES_CoreDocuments.getUploadUrl(CONFIG_NAME);
        Map<String, String> headers = DES_CoreDocuments.getUploadHeaders(CONFIG_NAME);
        String boundary = '----------------------------741e90d31eff';
        Blob bodyBlob = buildMultipartBodyBlob(boundary, fileName, fileType, base64Data);

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

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Map<String, Object> dataMap = (Map<String, Object>) responseMap.get('data');
        return dataMap == null ? null : (String) dataMap.get('fileId');
    }

    @TestVisible
    private static Blob buildMultipartBodyBlob(String boundary, String fileName, String fileType, String base64Data) {
        String headerStart = '--' + boundary + '\r\n'
            + 'Content-Disposition: form-data; name="file"; filename="' + fileName + '"';
        String headerEnd = '\r\nContent-Type: ' + fileType + '\r\n\r\n';

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

        return EncodingUtil.base64Decode(bodyEncoded);
    }

    @TestVisible
    private static void updateFileMetadata(String fileId, String fileName, String folderId) {
        DES_CoreDocuments.UpdateFileMetadataRequest request = new DES_CoreDocuments.UpdateFileMetadataRequest();
        request.fileId = fileId;
        request.fileName = fileName;
        request.docType = DOC_TYPE;
        request.folderId = folderId;
        request.configName = CONFIG_NAME;
        request.objectCode = OBJECT_CODE;
        DES_CoreDocuments.updateFileMetadata(request);
    }
}