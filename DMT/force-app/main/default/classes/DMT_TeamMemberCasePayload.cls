// CIBGLOBALD-4374 - Carries the approval Cases whose approver group members must become team members
// (DMT_TeamMember_Service.addApproversForCases). Replaces the one-Queueable-per-Case
// DMT_CreateTeamMemberCase: ONE payload covers all the Cases of a trigger context, so the whole
// batch costs a fixed number of queries.
public class DMT_TeamMemberCasePayload implements DMT_AsyncPayload {
    public List<Id> caseIds { get; set; }
    public Boolean sanctionEdit { get; set; }

    public DMT_TeamMemberCasePayload(List<Id> caseIds, Boolean sanctionEdit) {
        this.caseIds = caseIds;
        this.sanctionEdit = sanctionEdit == true;
    }
}
