@IsTest
private class DES_Tst_ToolingApiClientTest {
    // Avoid hard-coded IDs in assertions by centralizing sample IDs here.
    private static final String SAMPLE_RUN_ID = '707xx000000000A'; //NOSONAR
    private static final String SAMPLE_RUN_ID_ALT = '707xx000000000B'; //NOSONAR
    private static final String SAMPLE_RUN_RESULT_ID = '07Mxx000000000A'; //NOSONAR

  
    
    // Common mock implementing HttpCalloutMock to simulate Tooling API responses
    private class ToolingApiMock implements HttpCalloutMock {
        // Configure what to return based on the request
        String runTestsStatus;
        Integer runTestsCode;
        String runTestsBody;

        Integer queryStatusCode;
        String queryBody;

        ToolingApiMock withRunTests(Integer statusCode, String body, String statusText) {
            this.runTestsCode = statusCode;
            this.runTestsBody = body;
            this.runTestsStatus = statusText;
            return this;
        }
        ToolingApiMock withQuery(Integer statusCode, String body) {
            this.queryStatusCode = statusCode;
            this.queryBody = body;
            return this;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();

            // Dispatch by endpoint path
            String endpoint = req.getEndpoint();
            if (endpoint != null && endpoint.contains('/tooling/runTestsAsynchronous')) {
                res.setStatusCode(runTestsCode == null ? 200 : runTestsCode);
                res.setStatus(runTestsStatus == null ? 'OK' : runTestsStatus);
                res.setBody(runTestsBody == null ? '{"id":"707xx000000000A"}' : runTestsBody);
                return res;
            }
            if (endpoint != null && endpoint.contains('/tooling/query')) {
                res.setStatusCode(queryStatusCode == null ? 200 : queryStatusCode);
                res.setStatus('OK');
                res.setBody(queryBody == null ? '{"records":[{"Id":"07Mxx000000000A","Status":"Completed"}],"totalSize":1}' : queryBody);
                return res;
            }

            // Default 404 for unexpected endpoints
            res.setStatusCode(404);
            res.setStatus('Not Found');
            res.setBody('{"message":"Unknown endpoint"}');
            return res;
        }
    }

    @IsTest
    static void runAllLocalTests_returnsId_whenJsonObjectResponse() {
        Test.setMock(HttpCalloutMock.class, new ToolingApiMock()
            .withRunTests(200, '{"id":"' + SAMPLE_RUN_ID + '"}', 'OK'));

        Test.startTest();
        String id = DES_cls_ToolingApiClient.runAllLocalTests(false);
        Test.stopTest();

        System.assertNotEquals(null, id, 'Run id should not be null');
        System.assertEquals(SAMPLE_RUN_ID, id, 'Should return id from JSON object');
    }

    @IsTest
    static void runAllLocalTests_returnsId_whenPlainStringResponse() {
        // Tooling sometimes returns a plain string like "707xx000000000A"
        Test.setMock(HttpCalloutMock.class, new ToolingApiMock()
            .withRunTests(200, '"' + SAMPLE_RUN_ID_ALT + '"', 'OK'));

        Test.startTest();
        String id = DES_cls_ToolingApiClient.runAllLocalTests(true);
        Test.stopTest();

        System.assertEquals(SAMPLE_RUN_ID_ALT, id, 'Should strip quotes and return the id');
    }

    @IsTest
    static void runAllLocalTests_throwsOnHttpError() {
        Test.setMock(HttpCalloutMock.class, new ToolingApiMock()
            .withRunTests(400, '{"message":"Bad request"}', 'Bad Request'));

        try {
            Test.startTest();
            DES_cls_ToolingApiClient.runAllLocalTests(false);
            System.assert(false, 'Expected CalloutException to be thrown');
        } catch (CalloutException ex) {
            System.assert(ex.getMessage().contains('Error lanzando tests'), 'Message should indicate launch error');
        } finally {
            Test.stopTest();
        }
    }

    @IsTest
    static void getRunStatus_returnsCompletedRecord() {
        // Simulate a successful query returning one record
        String body = '{"records":[{"Id":"' + SAMPLE_RUN_RESULT_ID + '","Status":"Completed"}],"totalSize":1}';
        Test.setMock(HttpCalloutMock.class, new ToolingApiMock().withQuery(200, body));

        Test.startTest();
        DES_cls_ToolingApiClient.RunStatusDTO dto = DES_cls_ToolingApiClient.getRunStatus(SAMPLE_RUN_ID);
        Test.stopTest();

        System.assertEquals('Completed', dto.status, 'Status should be mapped from record');
        System.assertEquals(SAMPLE_RUN_RESULT_ID, dto.runResultId, 'RunResultId should be Id field');
    }

    @IsTest
    static void getRunStatus_returnsPendingWhenNoRecords() {
        String body = '{"records":[],"totalSize":0}';
        Test.setMock(HttpCalloutMock.class, new ToolingApiMock().withQuery(200, body));

        Test.startTest();
        DES_cls_ToolingApiClient.RunStatusDTO dto = DES_cls_ToolingApiClient.getRunStatus('707xxNONE');
        Test.stopTest();

        System.assertEquals('Pending', dto.status, 'Should return Pending when no records');
        System.assertEquals(null, dto.runResultId, 'RunResultId should be null when no records');
    }

    @IsTest
    static void getRunStatus_throwsOnHttpError() {
        Test.setMock(HttpCalloutMock.class, new ToolingApiMock().withQuery(500, '{"message":"Server error"}'));

        try {
            Test.startTest();
            DES_cls_ToolingApiClient.getRunStatus('707xxErr');
            System.assert(false, 'Expected CalloutException to be thrown');
        } catch (CalloutException ex) {
            System.assert(ex.getMessage().contains('Error consultando estado'), 'Message should indicate query state error');
        } finally {
            Test.stopTest();
        }
    }

    @IsTest
    static void getFailures_returnsParsedList() {
        // Prepare a query payload representing two failures
        String failuresBody = '{ "records":[' +
            '{ "ApexClass":{"Name":"ClassA"}, "MethodName":"testA", "Outcome":"Fail", "Message":"boom A", "StackTrace":"stA" },' +
            '{ "ApexClass":{"Name":"ClassB"}, "MethodName":"testB", "Outcome":"Fail", "Message":"boom B", "StackTrace":"stB" }' +
        '], "totalSize":2 }';

        // Mock will be used for /tooling/query
        Test.setMock(HttpCalloutMock.class, new ToolingApiMock().withQuery(200, failuresBody));

        Test.startTest();
        List<DES_cls_ToolingApiClient.TestFailureDTO> out = DES_cls_ToolingApiClient.getFailures(SAMPLE_RUN_RESULT_ID);
        Test.stopTest();

        System.assertEquals(2, out.size(), 'Should return 2 failures');
        System.assertEquals('ClassA', out[0].className);
        System.assertEquals('testA', out[0].methodName);
        System.assertEquals('Fail', out[0].outcome);
        System.assertEquals('boom A', out[0].message);
        System.assertEquals('stA', out[0].stackTrace);
        System.assertEquals('ClassB', out[1].className);
    }

    @IsTest
    static void getFailures_throwsOnHttpError() {
        Test.setMock(HttpCalloutMock.class, new ToolingApiMock().withQuery(403, '{"message":"Forbidden"}'));

        try {
            Test.startTest();
            DES_cls_ToolingApiClient.getFailures('07MxxForbidden');
            System.assert(false, 'Expected CalloutException');
        } catch (CalloutException ex) {
            System.assert(ex.getMessage().contains('Error consultando fallos'), 'Message should indicate failures query error');
        } finally {
            Test.stopTest();
        }
    }
}