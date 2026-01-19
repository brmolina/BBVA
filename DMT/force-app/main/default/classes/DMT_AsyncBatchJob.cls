public class DMT_AsyncBatchJob implements Database.Batchable<DMT_AsyncPayload>, Database.AllowsCallouts, Database.Stateful {

    private List<DMT_AsyncPayload> payloads;
    private List<DMT_LogExceptionPayload> exceptionsCollected = new List<DMT_LogExceptionPayload>();

    public DMT_AsyncBatchJob(List<DMT_AsyncPayload> payloads) {
        this.payloads = payloads;
    }

    public Iterable<DMT_AsyncPayload> start(Database.BatchableContext bc) {
        return payloads;
    }

    public void execute(Database.BatchableContext bc, List<DMT_AsyncPayload> scope) {
        for (DMT_AsyncPayload payload : scope) {
            try {
                DMT_AsyncDispatcher.dispatch(payload);
            } catch (Exception e) {
                System.debug('Error processing payload: ' + e.getMessage() + ' line number ' + e.getLineNumber());
                // Collect instead of enqueue
                exceptionsCollected.add(new DMT_LogExceptionPayload(
                    e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),
                    'DMT_AsyncBatchJob', 'execute', 'DMT', 'BatchPayload'
                ));
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('DMT_AsyncBatchJob finished processing ' + payloads.size() + ' payloads.');

        // Enqueue single queueable with all collected exceptions
        if (!exceptionsCollected.isEmpty()) {
            System.enqueueJob(new DMT_LogExceptionQueueable(exceptionsCollected));
        }
    }
}