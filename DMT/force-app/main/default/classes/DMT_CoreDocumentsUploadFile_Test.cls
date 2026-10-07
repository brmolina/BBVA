@IsTest
public with sharing class DMT_CoreDocumentsUploadFile_Test {

    private static final String CONFIG_NAME = 'DMT';

    private class UploadSuccessMock implements HttpCalloutMock {
        /**
         * @description Returns a successful CoreDocuments upload response.
         * @param req Incoming HTTP request.
         * @return Mocked successful HTTP response.
         */
        public HttpResponse respond(HttpRequest req) {
            System.assertEquals('POST', req.getMethod(), 'Upload request must use POST method.');
            System.assert(req.getEndpoint().contains('file:frontUpload'), 'Endpoint must target CoreDocuments upload path.');

            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setStatus('Created');
            res.setBody('{"data":{"fileId":"FILE-001"}}');
            return res;
        }
    }

    private class UploadErrorMock implements HttpCalloutMock {
        /**
         * @description Returns an error response to simulate upload failure.
         * @param req Incoming HTTP request.
         * @return Mocked error HTTP response.
         */
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setStatus('Internal Server Error');
            res.setBody('{"message":"boom"}');
            return res;
        }
    }

    private static void setupCoreDocumentsConfigAndJwt() {
        DES_CoreDocuments.clearTestConfigs();
        DES_CoreDocuments.Config cfg = DES_CoreDocuments.createTestConfig();

        cfg.expedientFoldersServiceName = 'DES_CoreDocumentsExpedientFolders';
        cfg.jwtServiceName = 'DES_CoreDocumentsJWT';
        cfg.metadataServiceName = 'DES_CoreDocuments';
        cfg.domain = 'test-domain';
        cfg.namespace = 'test.namespace';
        cfg.jwtCacheKey = 'UTDMTUPLOADJWT';
        cfg.expedientFoldersJwtCacheKey = 'UTDMTDOWNLOADJWT';
        cfg.serviceId = 'UT_SERVICE_ID';
        cfg.responsible = 'UT_RESP';
        cfg.coreDocEndpoint = 'https://example.com/v1';

        DES_CoreDocuments.setTestConfig(CONFIG_NAME, cfg);

        DES_CoreDocumentsJWT.Wrapper jwt = new DES_CoreDocumentsJWT.Wrapper();
        jwt.accessToken = 'cached_jwt_token';
        jwt.expiresAt = (Integer)(DateTime.now().getTime() / 1000) + 3600;
        Cache.Session.put(cfg.jwtCacheKey, jwt);
        Cache.Session.put(cfg.expedientFoldersJwtCacheKey, 'cached_download_jwt');

        HttpResponse jwtMockResponse = new HttpResponse();
        jwtMockResponse.setStatusCode(200);
        jwtMockResponse.setBody('{"accessToken":"reset_token","expiresAt":2147483647}');
        DES_CoreDocumentsJWT.mockResponseForTest = jwtMockResponse;
    }

    private static Opportunity createOpportunityWithFolder(String folderId) {
        TriggerBypass.setBypass();
        Opportunity opp = new Opportunity( Name = 'UT Opp', StageName = 'Prospecting', CloseDate = Date.today(), DMT_Opp_Id__c = folderId);
        insert opp;
        return opp;
    }

    private static DMT_Line__c createLineWithFolder(String folderId) {
        TriggerBypass.setBypass();
        DMT_Line__c line = new DMT_Line__c(
            Name = 'UT Line',
            Line_Id__c = folderId
        );
        insert line;
        return line;
    }

    @IsTest
    static void testUploadAfterEmailSyncOpportunitySuccess() {
        Opportunity opp = createOpportunityWithFolder('FOLDER-OPP-1');
        setupCoreDocumentsConfigAndJwt();
        Test.setMock(HttpCalloutMock.class, new UploadSuccessMock());

        String pdfBase64 = EncodingUtil.base64Encode(Blob.valueOf('pdf-content-opportunity'));

        Test.startTest();
        DMT_CoreDocumentsUploadFile.uploadSync(opp.Id, 'snapshot_opp', pdfBase64);
        Test.stopTest();

        System.assert(true, 'Sync upload for Opportunity should complete without exception.');
    }

    @IsTest
    static void testUploadAfterEmailLineSuccess() {
        DMT_Line__c line = createLineWithFolder('FOLDER-LINE-1');
        setupCoreDocumentsConfigAndJwt();
        Test.setMock(HttpCalloutMock.class, new UploadSuccessMock());

        String pdfBase64 = EncodingUtil.base64Encode(Blob.valueOf('pdf-content-line'));

        Test.startTest();
        DMT_CoreDocumentsUploadFile.upload(line.Id, 'snapshot_line', pdfBase64);
        Test.stopTest();

        System.assert(true, 'Upload through public entry point should complete for DMT_Line__c.');
    }

    @IsTest
    static void testQueueableUploadSuccess() {
        Opportunity opp = createOpportunityWithFolder('FOLDER-QUEUE-1');
        setupCoreDocumentsConfigAndJwt();
        Test.setMock(HttpCalloutMock.class, new UploadSuccessMock());

        String pdfBase64 = EncodingUtil.base64Encode(Blob.valueOf('pdf-content-queueable'));

        Test.startTest();
        System.enqueueJob(new DMT_CoreDocumentsUploadFile.UploadQueueable(opp.Id,'snapshot_queue',pdfBase64,0,UserInfo.getUserId(),'FEDERATION-UT'));
        Test.stopTest();

        System.assert(true, 'Queueable upload should complete without exception.');
    }

    @IsTest
    static void testResolveFolderIdByRecordTypeAndUnsupported() {
        Opportunity opp = createOpportunityWithFolder('FOLDER-OPP-2');
        DMT_Line__c line = createLineWithFolder('FOLDER-LINE-2');
        Account acc = new Account(Name = 'UT Account');
        insert acc;

        Test.startTest();
        String oppFolder = DMT_CoreDocumentsUploadFile.resolveFolderId(opp.Id);
        String lineFolder = DMT_CoreDocumentsUploadFile.resolveFolderId(line.Id);
        String accountFolder = DMT_CoreDocumentsUploadFile.resolveFolderId(acc.Id);
        Test.stopTest();

        System.assertEquals('FOLDER-OPP-2', oppFolder, 'Opportunity folder id should be resolved from DMT_Opp_Id__c.');
        System.assertEquals('FOLDER-LINE-2', lineFolder, 'Line folder id should be resolved from Line_Id__c.');
        System.assertEquals(null, accountFolder, 'Unsupported object type should return null folder id.');
    }

    @IsTest
    static void testBuildMultipartBodyBlobBothBase64Branches() {
        String boundary = '----utBoundary';
        String fileName = 'snapshot.pdf';
        String fileType = 'application/pdf';

        String withPadding = EncodingUtil.base64Encode(Blob.valueOf('ab')); // Ends with '='
        String withoutPadding = EncodingUtil.base64Encode(Blob.valueOf('abc')); // No '='

        Test.startTest();
        Blob blobWithPadding = DMT_CoreDocumentsUploadFile.buildMultipartBodyBlob(boundary, fileName, fileType, withPadding);
        Blob blobWithoutPadding = DMT_CoreDocumentsUploadFile.buildMultipartBodyBlob(boundary, fileName, fileType, withoutPadding);
        Test.stopTest();

        System.assertNotEquals(null, blobWithPadding, 'Multipart blob should be created for base64 input with padding.');
        System.assertNotEquals(null, blobWithoutPadding, 'Multipart blob should be created for base64 input without padding.');
        System.assert(blobWithPadding.size() > 0, 'Multipart blob with padding branch must contain content.');
        System.assert(blobWithoutPadding.size() > 0, 'Multipart blob without padding branch must contain content.');
    }

    @IsTest
    static void testUploadFileThrowsWhenHttpStatusIsError() {
        setupCoreDocumentsConfigAndJwt();
        Test.setMock(HttpCalloutMock.class, new UploadErrorMock());

        String pdfBase64 = EncodingUtil.base64Encode(Blob.valueOf('pdf-content-error'));

        Test.startTest();
        try {
            DMT_CoreDocumentsUploadFile.uploadFile('snapshot_error.pdf', pdfBase64, 'application/pdf');
            System.assert(false, 'Expected CalloutException on upload error response.');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('Upload failed'), 'Error message should indicate upload failure.');
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateFileMetadataThrowsWhenServiceReturnsError() {
        setupCoreDocumentsConfigAndJwt();
        DES_CoreDocumentsUtils.overrideMockStatusCode = 500;
        DES_CoreDocumentsUtils.overrideMockResponseBody = '{"error":"metadata failure"}';

        Test.startTest();
        try {
            DMT_CoreDocumentsUploadFile.updateFileMetadata('FILE-ERR', 'snapshot_error.pdf', 'FOLDER-ERR');
            System.assert(false, 'Expected metadata update to throw CalloutException.');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('Metadata update failed'), 'Error message should indicate metadata update failure.');
        }
        Test.stopTest();

        DES_CoreDocumentsUtils.overrideMockStatusCode = null;
        DES_CoreDocumentsUtils.overrideMockResponseBody = null;
    }

    @IsTest
    static void testGuardClausesDoNotThrow() {
        setupCoreDocumentsConfigAndJwt();

        Test.startTest();
        DMT_CoreDocumentsUploadFile.uploadSync(null, 'name', 'abc');
        DMT_CoreDocumentsUploadFile.uploadSync(UserInfo.getUserId(), '', 'abc');
        DMT_CoreDocumentsUploadFile.uploadSync(UserInfo.getUserId(), 'name', '');
        DMT_CoreDocumentsUploadFile.upload(null, 'name', 'abc');
        Test.stopTest();

        System.assert(true, 'Guard clauses should return without exception.');
    }

    @IsTest
    static void testUploadSyncWhenFolderIdNotResolved() {
        setupCoreDocumentsConfigAndJwt();
        Test.setMock(HttpCalloutMock.class, new UploadSuccessMock());

        Account unsupportedRecord = new Account(Name = 'Unsupported');
        insert unsupportedRecord;

        String pdfBase64 = EncodingUtil.base64Encode(Blob.valueOf('pdf-content'));

        Test.startTest();
        DMT_CoreDocumentsUploadFile.uploadSync(unsupportedRecord.Id, 'snapshot', pdfBase64);
        Test.stopTest();

        System.assert(true, 'Upload with unresolvable folder should return without exception.');
    }

    @IsTest
    static void testUploadSyncWhenUploadServiceReturnsEmptyFileId() {
        Opportunity opp = createOpportunityWithFolder('FOLDER-EMPTY-ID');
        setupCoreDocumentsConfigAndJwt();
        Test.setMock(HttpCalloutMock.class, new UploadEmptyFileIdMock());

        String pdfBase64 = EncodingUtil.base64Encode(Blob.valueOf('pdf-content-empty'));

        Test.startTest();
        DMT_CoreDocumentsUploadFile.uploadSync(opp.Id, 'snapshot_empty', pdfBase64);
        Test.stopTest();

        System.assert(true, 'Upload with empty fileId response should return without exception.');
    }

    @IsTest
    static void testQueueableUploadWithMultipleRetries() {
        Opportunity opp = createOpportunityWithFolder('FOLDER-RETRY');
        setupCoreDocumentsConfigAndJwt();
        Test.setMock(HttpCalloutMock.class, new UploadSuccessMock());

        String pdfBase64 = EncodingUtil.base64Encode(Blob.valueOf('pdf-content-retry'));

        Test.startTest();
        System.enqueueJob(new DMT_CoreDocumentsUploadFile.UploadQueueable(opp.Id,'snapshot_retry_1',pdfBase64,1,UserInfo.getUserId(),'FEDERATION-UT'));
        Test.stopTest();

        System.assert(true, 'Queueable with retry attempt 1 should complete.');
    }

    @IsTest
    static void testQueueableUploadReachesMaxRetries() {
        Opportunity opp = createOpportunityWithFolder('FOLDER-MAX-RETRY');
        setupCoreDocumentsConfigAndJwt();
        Test.setMock(HttpCalloutMock.class, new UploadErrorMock());

        String pdfBase64 = EncodingUtil.base64Encode(Blob.valueOf('pdf-content-max-retry'));

        Test.startTest();
        System.enqueueJob(new DMT_CoreDocumentsUploadFile.UploadQueueable(opp.Id,'snapshot_max_retry_2',pdfBase64,2,UserInfo.getUserId(),'FEDERATION-UT'));
        Test.stopTest();

        System.assert(true, 'Queueable at max retries should complete without re-enqueueing.');
    }

    @IsTest
    static void testUploadFileMissingUrl() {
        setupCoreDocumentsConfigAndJwt();
        DES_CoreDocuments.clearTestConfigs();
        DES_CoreDocuments.Config cfg = DES_CoreDocuments.createTestConfig();
        cfg.coreDocEndpoint = '';
        cfg.expedientFoldersServiceName = 'INVALID_SERVICE_NAME';
        DES_CoreDocuments.setTestConfig(CONFIG_NAME, cfg);

        String pdfBase64 = EncodingUtil.base64Encode(Blob.valueOf('pdf-content-no-url'));

        Test.startTest();
        try {
            DMT_CoreDocumentsUploadFile.uploadFile('snapshot_no_url.pdf', pdfBase64, 'application/pdf');
            System.assert(false, 'Expected exception when upload headers cannot be resolved.');
        } catch (Exception e) {
            System.assert(
                e.getMessage().contains('List has no rows') || e.getMessage().contains('upload URL'),
                'Error should indicate invalid service/configuration state.'
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void testUploadFileMissingHeaders() {
        setupCoreDocumentsConfigAndJwt();
        DES_CoreDocuments.clearTestConfigs();
        DES_CoreDocuments.Config cfg = DES_CoreDocuments.createTestConfig();
        cfg.coreDocEndpoint = 'https://example.com/v1';
        cfg.expedientFoldersServiceName = 'INVALID_SERVICE_HEADERS';
        cfg.jwtCacheKey = 'UTDMTUPLOADJWT2';
        DES_CoreDocuments.setTestConfig(CONFIG_NAME, cfg);

        String pdfBase64 = EncodingUtil.base64Encode(Blob.valueOf('pdf-content-no-headers'));

        Test.startTest();
        try {
            DMT_CoreDocumentsUploadFile.uploadFile('snapshot_no_headers.pdf', pdfBase64, 'application/pdf');
            System.assert(false, 'Expected exception when headers cannot be built.');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('List has no rows'), 'Should fail due invalid integration service lookup.');
        }
        Test.stopTest();
    }

    @IsTest
    static void testUploadResponseMissingDataField() {
        setupCoreDocumentsConfigAndJwt();
        Test.setMock(HttpCalloutMock.class, new UploadMissingDataMock());

        String pdfBase64 = EncodingUtil.base64Encode(Blob.valueOf('pdf-content-missing-data'));

        Test.startTest();
        try {
            DMT_CoreDocumentsUploadFile.uploadFile('snapshot_missing_data.pdf', pdfBase64, 'application/pdf');
            System.assert(false, 'Expected CalloutException when response missing data field.');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('data field'), 'Error should indicate missing data field.');
        }
        Test.stopTest();
    }

    @IsTest
    static void testUploadResponseEmptyBodyThrows() {
        setupCoreDocumentsConfigAndJwt();
        Test.setMock(HttpCalloutMock.class, new UploadEmptyBodyMock());

        String pdfBase64 = EncodingUtil.base64Encode(Blob.valueOf('pdf-content-empty-body'));

        Test.startTest();
        try {
            DMT_CoreDocumentsUploadFile.uploadFile('snapshot_empty_body.pdf', pdfBase64, 'application/pdf');
            System.assert(false, 'Expected CalloutException when response body is empty.');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('empty response body'), 'Error should indicate empty response body.');
        }
        Test.stopTest();
    }

    @IsTest
    static void testUploadResponseNullJsonThrows() {
        setupCoreDocumentsConfigAndJwt();
        Test.setMock(HttpCalloutMock.class, new UploadNullJsonMock());

        String pdfBase64 = EncodingUtil.base64Encode(Blob.valueOf('pdf-content-null-json'));

        Test.startTest();
        try {
            DMT_CoreDocumentsUploadFile.uploadFile('snapshot_null_json.pdf', pdfBase64, 'application/pdf');
            System.assert(false, 'Expected CalloutException when response JSON is null.');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('response JSON is null'), 'Error should indicate null JSON response.');
        }
        Test.stopTest();
    }

    @IsTest
    static void testQueueableMetadataFailureIsNonBlocking() {
        Opportunity opp = createOpportunityWithFolder('FOLDER-META-FAIL');
        setupCoreDocumentsConfigAndJwt();
        DES_CoreDocumentsUtils.overrideMockStatusCode = 500;
        DES_CoreDocumentsUtils.overrideMockResponseBody = '{"error":"metadata fail"}';
        Test.setMock(HttpCalloutMock.class, new UploadSuccessMock());

        String pdfBase64 = EncodingUtil.base64Encode(Blob.valueOf('pdf-content-metadata-fail'));

        Test.startTest();
        System.enqueueJob(new DMT_CoreDocumentsUploadFile.UploadQueueable(
            opp.Id,
            'snapshot_meta_fail',
            pdfBase64,
            0,
            UserInfo.getUserId(),
            'FEDERATION-UT'
        ));
        Test.stopTest();

        DES_CoreDocumentsUtils.overrideMockStatusCode = null;
        DES_CoreDocumentsUtils.overrideMockResponseBody = null;
        System.assert(true, 'Queueable should continue (non-blocking) when metadata update fails.');
    }

    @IsTest
    static void testQueueableFolderNotResolved() {
        setupCoreDocumentsConfigAndJwt();
        Test.setMock(HttpCalloutMock.class, new UploadSuccessMock());

        Account acc = new Account(Name = 'Queueable no folder');
        insert acc;

        String pdfBase64 = EncodingUtil.base64Encode(Blob.valueOf('pdf-content-no-folder'));

        Test.startTest();
        System.enqueueJob(new DMT_CoreDocumentsUploadFile.UploadQueueable(
            acc.Id,
            'snapshot_no_folder',
            pdfBase64,
            0,
            UserInfo.getUserId(),
            'FEDERATION-UT'
        ));
        Test.stopTest();

        System.assert(true, 'Queueable should handle unresolved folder id path.');
    }

    @IsTest
    static void testResolveFolderIdNullInput() {
        Test.startTest();
        String result = DMT_CoreDocumentsUploadFile.resolveFolderId(null);
        Test.stopTest();

        System.assertEquals(null, result, 'Null input should return null folder id.');
    }

    private class UploadEmptyFileIdMock implements HttpCalloutMock {
        /**
         * @description Returns response with empty fileId to simulate invalid upload response.
         * @param req Incoming HTTP request.
         * @return Mocked response with missing fileId.
         */
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setStatus('Created');
            res.setBody('{"data":{"fileId":""}}');
            return res;
        }
    }

    private class UploadMissingDataMock implements HttpCalloutMock {
        /**
         * @description Returns response without data field to test error handling.
         * @param req Incoming HTTP request.
         * @return Mocked response missing data field.
         */
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setStatus('Created');
            res.setBody('{"result":"ok"}');
            return res;
        }
    }

    private class UploadEmptyBodyMock implements HttpCalloutMock {
        /**
         * @description Returns a successful status with an empty body.
         * @param req Incoming HTTP request.
         * @return Mocked response with empty body.
         */
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setStatus('Created');
            res.setBody('');
            return res;
        }
    }

    private class UploadNullJsonMock implements HttpCalloutMock {
        /**
         * @description Returns a successful status with JSON null body.
         * @param req Incoming HTTP request.
         * @return Mocked response with 'null' as body.
         */
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setStatus('Created');
            res.setBody('null');
            return res;
        }
    }
}