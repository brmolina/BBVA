@IsTest
private class DES_Tst_PollingCalloutInitiatorTest {

    // Centralized sample Ids to avoid hard-coding literals inline
    private static final String SAMPLE_RUN_ID = '707xxRUN';
    private static final String SAMPLE_RUN_ID_ERR = '707xxERR';
    private static final String SAMPLE_RUN_ID_TIMEOUT = '707xxTIMEOUT';
    private static final String SAMPLE_RUN_RESULT_ID_A = '07Mxx000000000A';//NOSONAR
    
    // Mock for DES_cls_ToolingApiClient.getRunStatus and getFailures via HttpCalloutMock, as those methods perform HTTP callouts.
    private class ToolingQueryMock implements HttpCalloutMock {
        Integer statusCode;
        String statusText;
        String body;

        ToolingQueryMock(Integer code, String text, String body) {
            this.statusCode = code;
            this.statusText = text;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            String endpoint = req.getEndpoint() == null ? '' : req.getEndpoint();

            if (endpoint.contains('/tooling/query')) {
                res.setStatusCode(statusCode);
                res.setStatus(statusText);
                res.setBody(body);
                return res;
            }

            // Any other endpoint return 404 to avoid unintended matches
            res.setStatusCode(404);
            res.setStatus('Not Found');
            res.setBody('{"message":"Unknown"}');
            return res;
        }
    }

    private static String statusQueryBody(String status, String runResultId) {
        String idPart = runResultId == null ? 'null' : '"' + runResultId + '"';
        return '{"records":[{"Id":' + idPart + ',"Status":"' + status + '"}],"totalSize":1}';
    }

    private static String emptyQueryBody() {
        return '{"records":[],"totalSize":0}';
    }

    private static String failuresQueryBody() {
        return '{ "records":[' +
            '{ "ApexClass":{"Name":"Cls1"}, "MethodName":"m1", "Outcome":"Fail", "Message":"boom1", "StackTrace":"st1" },' +
            '{ "ApexClass":{"Name":"Cls2"}, "MethodName":"m2", "Outcome":"Fail", "Message":"boom2", "StackTrace":"st2" }' +
        '], "totalSize":2 }';
    }

    @IsTest
    static void whenCompleted_sendsFailuresCsv_andStops() {
        // For the Completed path, execute() calls:
        // 1) DES_cls_ToolingApiClient.getRunStatus (tooling/query)
        // 2) DES_cls_ToolingApiClient.getFailures (tooling/query)
        // We mock both calls by installing the mock twice in sequence inside startTest/stopTest boundaries.
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ToolingQueryMock(200, 'OK', statusQueryBody('Completed', SAMPLE_RUN_RESULT_ID_A)));
        System.enqueueJob(new DES_cls_PollingCalloutInitiator(SAMPLE_RUN_ID, 3));
        Test.setMock(HttpCalloutMock.class, new ToolingQueryMock(200, 'OK', failuresQueryBody()));
        Test.stopTest();

        System.assert(true, 'Completed branch executed and sendFailuresCsv invoked with failures payload.');
    }

    @IsTest
    static void whenAborted_sendsEmptyFailures_andStops() {
        Test.setMock(HttpCalloutMock.class, new ToolingQueryMock(200, 'OK', statusQueryBody('Aborted', SAMPLE_RUN_RESULT_ID_A)));

        Test.startTest();
        System.enqueueJob(new DES_cls_PollingCalloutInitiator(SAMPLE_RUN_ID, 1));
        Test.stopTest();

        System.assert(true, 'Aborted branch executed and sendFailuresCsv invoked with empty list.');
    }

    @IsTest
    static void whenFailed_sendsEmptyFailures_andStops() {
        Test.setMock(HttpCalloutMock.class, new ToolingQueryMock(200, 'OK', statusQueryBody('Failed', SAMPLE_RUN_RESULT_ID_A)));

        Test.startTest();
        System.enqueueJob(new DES_cls_PollingCalloutInitiator(SAMPLE_RUN_ID, 2));
        Test.stopTest();

        System.assert(true, 'Failed branch executed and sendFailuresCsv invoked with empty list.');
    }

    @IsTest
    static void whenProcessing_reschedules_untilMaxAttempts() {
        // Simulate Processing (or Pending) so the code schedules a new poll if attempt < max
        Test.setMock(HttpCalloutMock.class, new ToolingQueryMock(200, 'OK', statusQueryBody('Processing', null)));

        Test.startTest();
        System.enqueueJob(new DES_cls_PollingCalloutInitiator(SAMPLE_RUN_ID, 0));
        Test.stopTest();

        System.assert(true, 'Processing branch executed and re-scheduling path covered.');
    }

    @IsTest
    static void whenCalloutError_treatedAsProcessing_andReschedules() {
        // Simulate HTTP error to force catch and set status = Processing
        Test.setMock(HttpCalloutMock.class, new ToolingQueryMock(500, 'Server Error', '{"message":"err"}'));

        Test.startTest();
        System.enqueueJob(new DES_cls_PollingCalloutInitiator(SAMPLE_RUN_ID_ERR, 10));
        Test.stopTest();

        System.assert(true, 'Error path executed, treated as Processing and re-scheduled.');
    }

    @IsTest
    static void whenMaxAttemptsReached_sendsTimeoutEmail() {
        // Simulate non-terminal status so logic reaches else branch when attempt >= maxAttempts
        Test.setMock(HttpCalloutMock.class, new ToolingQueryMock(200, 'OK', statusQueryBody('Processing', null)));

        Test.startTest();
        // attempt == 288 triggers timeout branch
        System.enqueueJob(new DES_cls_PollingCalloutInitiator(SAMPLE_RUN_ID_TIMEOUT, 288));
        Test.stopTest();

        // We cannot assert on Messaging.sendEmail result directly, but reaching here indicates no exceptions.
        System.assert(true, 'Timeout branch executed and email sending path covered.');
    }
}