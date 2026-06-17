/**
 * Best-effort async document mover for the massive closure flow.
 * Moves ContentDocumentLink records from Case to Task after the main
 * transaction commits, so document issues never block the close.
 */
public without sharing class DMT_Massive_Task_DocMoveQueueable implements Queueable {
    private final Set<Id> caseIds;
    private final Map<Id, Id> taskIdByCaseId;

    public DMT_Massive_Task_DocMoveQueueable(Set<Id> caseIds, Map<Id, Id> taskIdByCaseId) {
        this.caseIds = caseIds == null ? new Set<Id>() : new Set<Id>(caseIds);
        this.taskIdByCaseId = taskIdByCaseId == null ? new Map<Id, Id>() : new Map<Id, Id>(taskIdByCaseId);
    }

    public void execute(QueueableContext context) {
        try {
            DMT_Massive_Task_Closure_Service.moveContentDocumentLinksAsync(caseIds, taskIdByCaseId);
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN,
                'DMT_Massive_Task_Closure_DocMoveQueueable failed: ' + e.getMessage());
            System.enqueueJob(new DMT_LogExceptionQueueable(
                e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),
                'DMT_Massive_Task_Closure_DocMoveQueueable', 'execute', 'DMT', ''
            ));
        }
    }
}