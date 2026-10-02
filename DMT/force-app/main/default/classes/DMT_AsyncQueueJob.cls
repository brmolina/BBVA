public class DMT_AsyncQueueJob implements Queueable, Database.AllowsCallouts {
    private List<DMT_AsyncPayload> payloads;

    // A buffer larger than this is handed back to DMT_AsyncOrchestrator instead of being
    // dispatched inline - see the comment in execute() for why. Conservative: a payload like
    // DMT_PassportPayload can cost several SOQL queries plus callouts on its own, so even a
    // small multiple of that risks the 200-SOQL/100-callout per-transaction limits.
    private static final Integer INLINE_DISPATCH_LIMIT = 5;

    // Test-only: forces the deferral branch below to run even though Test.isRunningTest() is
    // true, so a test can exercise it deliberately with a small payload list.
    @TestVisible private static Boolean forceDeferForTest = false;

    public DMT_AsyncQueueJob(List<DMT_AsyncPayload> payloads) {
        this.payloads = payloads;
    }

    public void execute(QueueableContext context) {
        if (payloads == null || payloads.isEmpty()) {
            return;
        }

        // This Queueable execution is its own transaction, started after whatever
        // Batch/Future context originally enqueued it has already finished - so
        // System.isBatch()/isFuture() are both false here, even when this job was spawned
        // from inside DMT_BatchSanctionAMIWEB.execute() or another batch. A large buffer means
        // DMT_AsyncOrchestrator.flush() was called from an "illegal" (Batch/Future) context
        // and had no choice but to hand everything to one Queueable with no size check. From
        // here we can safely give it back to flush(): since we are a plain Queueable context,
        // it will take the Database.executeBatch(DMT_AsyncBatchJob, ...) path, which processes
        // ONE payload per chunk with a fresh governor-limit budget each - instead of this
        // method dispatching the whole buffer inline and blowing the SOQL/callout limits of a
        // single transaction (the root cause of the "Too many SOQL queries" failures seen on
        // DMT_BatchSanctionAMIWEB status updates).
        // Skipped during tests: flush() has its own test-only synchronous escape hatch
        // (Test.isRunningTest() && System.isQueueable()) that calls execute() directly instead
        // of enqueueing, which would re-enter this same check with the same buffer and loop
        // forever. forceDeferForTest lets a test opt into this branch deliberately instead.
        if (payloads.size() > INLINE_DISPATCH_LIMIT && (forceDeferForTest || !Test.isRunningTest())) {
            for (DMT_AsyncPayload p : payloads) {
                DMT_AsyncOrchestrator.enqueue(p);
            }
            DMT_AsyncOrchestrator.flush();
            return;
        }

        List<DMT_LogExceptionPayload> logsFoundInList = new List<DMT_LogExceptionPayload>();
        List<DMT_LogExceptionPayload> newlyCaughtErrors = new List<DMT_LogExceptionPayload>();

        for (DMT_AsyncPayload p : payloads) {
            if (p instanceof DMT_LogExceptionPayload) {
                logsFoundInList.add((DMT_LogExceptionPayload)p);
            } else {
                try {
                    DMT_AsyncDispatcher.dispatch(p);
                } catch (Exception e) {
                    newlyCaughtErrors.add(new DMT_LogExceptionPayload(
                        e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),
                        'DMT_AsyncQueueJob', 'execute', 'DMT', 'QueueableExecution'
                    ));
                }
            }
        }

        // 1. Handle logs that were passed into the Queueable
        if (!logsFoundInList.isEmpty()) {
            DMT_AsyncDispatcher.handleLogExceptions(logsFoundInList);
        }

        // 2. If errors were generated during this run, flush them to a separate transaction (Batch)
        if (!newlyCaughtErrors.isEmpty()) {
            List<DMT_AsyncPayload> errorPayloads = new List<DMT_AsyncPayload>();
            for(DMT_LogExceptionPayload log : newlyCaughtErrors) {
                errorPayloads.add((DMT_AsyncPayload)log);
            }
            Database.executeBatch(new DMT_AsyncBatchJob(errorPayloads), 20);
        }
        
        // Flush any new functional tasks generated during this queueable run
        DMT_AsyncOrchestrator.flush();
    }
}