// CIBGLOBALD-4117: recordId is the Case's parent record Id - a DMT_Line__c or an Opportunity Id,
// per DMT_LineOpportunity__c (a Case is always exactly one, never both).
public class DMT_RestartApprovalTasksPayload implements DMT_AsyncPayload {
    public Id recordId { get; set; }
    public List<Task> tasksToRestart { get; set; }

    public DMT_RestartApprovalTasksPayload(Id recordId, List<Task> tasksToRestart) {
        this.recordId = recordId;
        this.tasksToRestart = tasksToRestart;
    }
}