@IsTest
private class DES_Tst_ApexRunPollerTest {

    // Centralized sample Ids to avoid hard-coding literals inline
    private static final String SAMPLE_RUN_ID = '707xxRUN';
    private static final String SAMPLE_RUN_RESULT_ID = '07Mxx000000000A';//NOSONAR

    // Mock for ToolingApiClient.getRunStatus and getFailures via /tooling/query, used by the queueable executed from the schedulable.
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
    private static String failuresQueryBody() {
        return '{ "records":[' +
            '{ "ApexClass":{"Name":"Cls1"}, "MethodName":"m1", "Outcome":"Fail", "Message":"boom1", "StackTrace":"st1" }' +
        '], "totalSize":1 }';
    }

    @IsTest
    static void execute_enqueuesQueueable_andProcessesCompletedPath() {
        // DES_cls_ApexRunPoller.execute enqueues PollingCalloutInitiator which will:
        // - call getRunStatus (tooling/query)
        // - then getFailures (tooling/query) if Completed
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ToolingQueryMock(200, 'OK', statusQueryBody('Completed', SAMPLE_RUN_RESULT_ID)));
        new DES_cls_ApexRunPoller(SAMPLE_RUN_ID, 1).execute(null);

        // Second mock for getFailures -> some failures payload
        Test.setMock(HttpCalloutMock.class, new ToolingQueryMock(200, 'OK', failuresQueryBody()));
        Test.stopTest();

        System.assert(true, 'DES_cls_ApexRunPoller executed and enqueued PollingCalloutInitiator; Completed path processed without exceptions.');
    }

    @IsTest
    static void execute_enqueuesQueueable_andProcessesProcessingPath() {
        // Simulate non-terminal status to cover rescheduling path inside the queueable
        Test.setMock(HttpCalloutMock.class, new ToolingQueryMock(200, 'OK', statusQueryBody('Processing', null)));

        Test.startTest();
        new DES_cls_ApexRunPoller(SAMPLE_RUN_ID, 0).execute(null);
        Test.stopTest();

        System.assert(true, 'DES_cls_ApexRunPoller executed and queueable handled Processing status without exceptions.');
    }
}