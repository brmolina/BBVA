// CIBGLOBALD-4117 - defers one task's callout-tracked comparison (DMT_CalloutTrackableRenderer)
// to an async, callout-capable context, since the trigger context that decides a task needs this
// check is itself forbidden from making callouts.
//
// remainingComponentNames chains a task's callout-trackable components one at a time instead of
// firing them all into the same transaction - a managed package's post-callout DML (e.g. IASO's
// application log) can make a second callout in the same transaction throw "You have uncommitted
// work pending". See DMT_ApprovalChangeStep_Helper.checkCalloutTrackableComponent for the chain logic.
public class DMT_CalloutTrackableCheckPayload implements DMT_AsyncPayload {
    public Id recordId { get; set; }
    public Id taskId { get; set; }
    public String componentName { get; set; }
    public List<String> remainingComponentNames { get; set; }

    public DMT_CalloutTrackableCheckPayload(Id recordId, Id taskId, String componentName, List<String> remainingComponentNames) {
        this.recordId = recordId;
        this.taskId = taskId;
        this.componentName = componentName;
        this.remainingComponentNames = remainingComponentNames != null ? remainingComponentNames : new List<String>();
    }
}