/**
 * CIBGLOBALD-4374 - Thin invocable entry point kept for the callers that still reference it
 * (flows not migrated yet and their tests). The logic lives in DMT_TeamMember_Service and is
 * handed over as ONE collection, not one Queueable per Case: already-async transactions run it
 * inline, user transactions go through DMT_AsyncOrchestrator (see DMT_TeamMemberCasePayload).
 * The class is no longer a Queueable.
 */
public without sharing class DMT_CreateTeamMemberCase {

    public class InputWrapper {
        @InvocableVariable public Id caseId;
        @InvocableVariable public Boolean sanctionEdit;
    }

    @InvocableMethod(
        label = 'Create Team Member'
        description = 'Creates read only team members for the approver group of the Case owner queue'
    )
    public static void createTeamMemberCase(List<InputWrapper> inputIds) {
        if (inputIds == null || inputIds.isEmpty()) {
            return;
        }

        List<DMT_TeamMember_Service.CaseRequest> requests = new List<DMT_TeamMember_Service.CaseRequest>();
        for (InputWrapper input : inputIds) {
            if (input != null && input.caseId != null) {
                requests.add(new DMT_TeamMember_Service.CaseRequest(input.caseId, input.sanctionEdit == true));
            }
        }

        DMT_TeamMember_Service.scheduleCaseRequests(requests);
        // An invocable has no trigger context of its own that flushes the buffer.
        DMT_AsyncOrchestrator.flush();
    }
}
