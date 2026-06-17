public with sharing class DMT_AsyncQueueJob implements Queueable, Database.AllowsCallouts {
    private List<DMT_AsyncPayload> payloads;

    public DMT_AsyncQueueJob(List<DMT_AsyncPayload> payloads) {
        this.payloads = payloads;
    }

    public void execute(QueueableContext context) {
        if (payloads == null || payloads.isEmpty()) {
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