/**
 * @Name: DMT_AsyncOrchestrator
 * @Description: Centralized engine to collect and execute all async tasks (Passports, Snapshots, etc...)
 * ensures exactly one async job is fired per transaction to avoid governor and test limits.
 */
public with sharing class DMT_AsyncOrchestrator {

    // The "Shopping Cart" for all async work in this transaction
    public static List<DMT_AsyncPayload> payloadBuffer = new List<DMT_AsyncPayload>();

    /**
     * @description Adds a payload to the buffer. Call this from any logic method.
     */
    public static void enqueue(DMT_AsyncPayload p) {
        if (p != null) {
            payloadBuffer.add(p);
        }
    }

    /**
     * @description Fires the async engine. Call this ONCE at the end of the Trigger (After context).
     */
    public static void flush() {
        if (payloadBuffer == null || payloadBuffer.isEmpty()) {
            return;
        }

        // Context Check
        Boolean isIllegalBatchContext = System.isBatch() || System.isFuture();

        // 1. Legal Context AND (High Volume OR Queueable Used Up) -> Batch
        if (!isIllegalBatchContext && (Limits.getQueueableJobs() > 0 || payloadBuffer.size() > 1)) {
            Integer batchSize = Test.isRunningTest() ? payloadBuffer.size() : 1;
            Database.executeBatch(new DMT_AsyncBatchJob(payloadBuffer), batchSize);
            System.debug(LoggingLevel.INFO, '[DMT Async] Flushing via BATCH. Count: ' + payloadBuffer.size());
        }
        // 2. Illegal Batch Context OR Low Volume -> Queueable (as long as we have limits)
        else if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
            
            // --- TEST CONTEXT GUARDRAIL ---
            // Salesforce prevents deep Queueable chaining in tests. We run it synchronously to bypass the error.
            if (Test.isRunningTest() && System.isQueueable()) {
                System.debug(LoggingLevel.INFO, '[DMT Async] Test Context: Executing QueueJob synchronously to avoid Stack Depth limit.');
                List<DMT_AsyncPayload> syncBuffer = new List<DMT_AsyncPayload>(payloadBuffer);
                payloadBuffer.clear(); // Clear before execution to prevent loop
                new DMT_AsyncQueueJob(syncBuffer).execute(null);
                return;
            }
            
            System.enqueueJob(new DMT_AsyncQueueJob(payloadBuffer));
            System.debug(LoggingLevel.INFO, '[DMT Async] Flushing via QUEUEABLE. Count: ' + payloadBuffer.size());
        } 
        else {
            System.debug(LoggingLevel.ERROR, '[DMT Async] CRITICAL: Async limits reached. Cannot flush buffer.');
        }

        // 3. Clear buffer to prevent duplicate firing
        payloadBuffer.clear();
    }
}