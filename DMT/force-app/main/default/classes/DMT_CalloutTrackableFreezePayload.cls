// CIBGLOBALD-4117 - defers capturing a callout-tracked baseline into an already-frozen snapshot to
// an async, callout-capable context. The freeze paths that create DMT_TaskStatusWhenCompleted__c
// records (DMT_ApprovalChangeStep_Handler.updateTaskWithStatus, DMT_Massive_Task_Closure_Service)
// are invoked from callers whose transaction may already contain DML before reaching them (e.g. the
// ApprovalChangeStep integration procedure) - a callout right there throws "uncommitted work
// pending". Enqueuing this instead guarantees the live fetch always runs in a fresh transaction.
public class DMT_CalloutTrackableFreezePayload implements DMT_AsyncPayload {
    public Id snapshotId { get; set; }
    public Id recordId { get; set; }
    public String componentName { get; set; }

    public DMT_CalloutTrackableFreezePayload(Id snapshotId, Id recordId, String componentName) {
        this.snapshotId = snapshotId;
        this.recordId = recordId;
        this.componentName = componentName;
    }
}