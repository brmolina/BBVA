// CIBGLOBALD-4477 - Carries everything DMT_Passport_Handler.startCase needs to open ONE approval Case for ONE
// Passport feature, so the Case creation runs in its own async transaction (see
// DMT_AsyncOrchestrator.flush(): more than one payload in the buffer means one payload per
// Batch chunk, each with a fresh set of governor limits).
//
// taskListJson is the feature's full task list; the first task is the one startCase creates
// itself (taskId), so DMT_Case_Steps_Controller.startApprovalCaseFromPayload drops it before
// calling startCase - same convention as DMT_Case_Steps_Controller.StartCaseQueueable.
public class DMT_StartApprovalCasePayload implements DMT_AsyncPayload {
    public String externalLineId { get; set; }
    public String approverId { get; set; }
    public String taskId { get; set; }
    public String taskListJson { get; set; }
    public String featureId { get; set; }
    public String featureName { get; set; }
    public String comment { get; set; }
    public String passportSanction { get; set; }

    public DMT_StartApprovalCasePayload(String externalLineId, String approverId, String taskId, String taskListJson, String featureId, String featureName, String comment, String passportSanction) {
        this.externalLineId = externalLineId;
        this.approverId = approverId;
        this.taskId = taskId;
        this.taskListJson = taskListJson;
        this.featureId = featureId;
        this.featureName = featureName;
        this.comment = comment;
        this.passportSanction = passportSanction;
    }
}
