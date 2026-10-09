public without sharing class DMT_AsyncBatchJob implements Database.Batchable<DMT_AsyncPayload>, Database.AllowsCallouts, Database.Stateful {
    private List<DMT_AsyncPayload> payloads;
    private List<DMT_LogExceptionPayload> errorsCaughtInBatch = new List<DMT_LogExceptionPayload>();

    public DMT_AsyncBatchJob(List<DMT_AsyncPayload> payloads) {
        this.payloads = payloads;
    }

    public Iterable<DMT_AsyncPayload> start(Database.BatchableContext bc) { return payloads; }

    public void execute(Database.BatchableContext bc, List<DMT_AsyncPayload> scope) {
        List<DMT_LogExceptionPayload> existingLogsToPublish = new List<DMT_LogExceptionPayload>();

        for (DMT_AsyncPayload p : scope) {
            if (p instanceof DMT_LogExceptionPayload) {
                // If it's already a log, add to list for bulk handling
                existingLogsToPublish.add((DMT_LogExceptionPayload)p);
            } else {
                // Functional Payload (Snapshot/Passport)
                try {
                    DMT_AsyncDispatcher.dispatch(p);
                } catch (Exception e) {
                    System.debug(LoggingLevel.ERROR, 'Error processing payload: ' + e.getMessage());
                    // Catch and store for the finish method
                    errorsCaughtInBatch.add(new DMT_LogExceptionPayload(
                        e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),
                        'DMT_AsyncBatchJob', 'execute', 'DMT', 'BatchExecution'
                    ));
                }
            }
        }

        // Dispatch pre-existing logs found in this scope chunk
        if (!existingLogsToPublish.isEmpty()) {
            DMT_AsyncDispatcher.handleLogExceptions(existingLogsToPublish);
        }
        
        // Flush any new tasks (like retries) generated during this batch chunk
        DMT_AsyncOrchestrator.flush();
    }

    public void finish(Database.BatchableContext bc) {
        // Log all exceptions that occurred DURING the processing of functional payloads // we will watch this, if this causes chaining issues, we will combine the two lists of exception logs and dispatch them here directly
        System.debug(LoggingLevel.INFO,'DMT_AsyncBatchJob finished processing ' + payloads.size() + ' payloads with ' + errorsCaughtInBatch.size() + ' exceptions.');

        if (!errorsCaughtInBatch.isEmpty()) {
            System.enqueueJob(new DMT_LogExceptionQueueable(errorsCaughtInBatch));
        }
    }
}