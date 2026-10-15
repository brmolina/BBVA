/**
 * Assigns active users from the Owner's UO level 10
 * as Read/Write participants of a Line or Opportunity.
 */
public without sharing class DMT_AssignParticipantsByUO {

    // CIBGLOBALD-4374 - the logic moved to DMT_TeamMember_Service.assignParticipantsByOwnerUO; this
    // invocable only collects the record Ids.
    @InvocableMethod(
        label='Assign Participants Read/Write by UO'
        description='Assigns active users from the Owner UO as Read/Write participants.'
    )
    public static void assignParticipants(List<Request> requests) {
        if (requests == null || requests.isEmpty()) {
            return;
        }

        Set<Id> opportunityIds = new Set<Id>();
        Set<Id> lineIds = new Set<Id>();

        for (Request request : requests) {
            if (request == null || request.recordId == null) {
                continue;
            }

            Schema.SObjectType recordType = request.recordId.getSObjectType();

            if (recordType == Opportunity.SObjectType) {
                opportunityIds.add(request.recordId);
            } else if (recordType == DMT_Line__c.SObjectType) {
                lineIds.add(request.recordId);
            }
        }

        DMT_TeamMember_Service.assignParticipantsByOwnerUO(opportunityIds, lineIds);
    }

    public class Request {

        @InvocableVariable(
            required=true
            label='Line or Opportunity Id'
        )
        public Id recordId;
    }
}