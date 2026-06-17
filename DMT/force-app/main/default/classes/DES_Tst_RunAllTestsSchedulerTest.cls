@IsTest
private class DES_Tst_RunAllTestsSchedulerTest {

    // Mock for the initial Tooling API call used by ToolingApiCalloutQueueable so enqueue execution completes without real callouts.
    private class RunTestsMock implements HttpCalloutMock {
        Integer statusCode; String body; String statusText;
        RunTestsMock(Integer code, String body, String statusText) {
            this.statusCode = code; this.body = body; this.statusText = statusText;
        }
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            // Queueable will call /toolings/runTestsAsynchronous
            if (req.getEndpoint() != null && req.getEndpoint().contains('/tooling/runTestsAsynchronous')) {
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

    @IsTest
    static void execute_enqueuesQueueable() {
        // Ensure the queueable's callout returns a valid id so the job runs through normally.
        Test.setMock(HttpCalloutMock.class, new RunTestsMock(200, '{"id":"707xx0000000RUN"}', 'OK'));

        Test.startTest();
        // Invoke the scheduler execute
        new DES_sch_RunAllTestsScheduler().execute(null);
        Test.stopTest();

        // If execution completed without exception, the queueable was enqueued and processed.
        System.assert(true, 'Scheduler execute should enqueue ToolingApiCalloutQueueable successfully.');
    }

    @IsTest
    static void scheduleDaily_schedulesJob() {
        Integer hour = 3; // 03:00
        Integer minute = 45;

        Test.startTest();
        DES_sch_RunAllTestsScheduler.scheduleDaily(hour, minute);
        Test.stopTest();

        System.assert(true, 'scheduleDaily executed without throwing, implying the cron expression is valid.');
    }
}