/**
 * Assigns active users from the Owner's UO level 10
 * as Read/Write participants of a Line or Opportunity.
 */
public without sharing class DMT_AssignParticipantsByUO {

    private static final String READ_ACCESS = 'Read';
    private static final String EDIT_ACCESS = 'Edit';

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

            Schema.SObjectType recordType =
                request.recordId.getSObjectType();

            if (recordType == Opportunity.SObjectType) {
                opportunityIds.add(request.recordId);
            } else if (recordType == DMT_Line__c.SObjectType) {
                lineIds.add(request.recordId);
            }
        }

        if (opportunityIds.isEmpty() && lineIds.isEmpty()) {
            return;
        }

        Map<Id, Id> ownerByRecordId = new Map<Id, Id>();

        if (!opportunityIds.isEmpty()) {
            for (Opportunity opportunityRecord : [
                SELECT Id, OwnerId
                FROM Opportunity
                WHERE Id IN :opportunityIds
            ]) {
                ownerByRecordId.put(
                    opportunityRecord.Id,
                    opportunityRecord.OwnerId
                );
            }
        }

        if (!lineIds.isEmpty()) {
            for (DMT_Line__c lineRecord : [
                SELECT Id, OwnerId
                FROM DMT_Line__c
                WHERE Id IN :lineIds
            ]) {
                ownerByRecordId.put(
                    lineRecord.Id,
                    lineRecord.OwnerId
                );
            }
        }

        Set<Id> ownerIds = new Set<Id>(ownerByRecordId.values());
        Map<Id, String> uoByOwnerId = new Map<Id, String>();
        Set<String> ownerUos = new Set<String>();

        for (User owner : [
            SELECT Id, DES_LevelUO_10__c
            FROM User
            WHERE Id IN :ownerIds
        ]) {
            if (String.isNotBlank(owner.DES_LevelUO_10__c)) {
                uoByOwnerId.put(
                    owner.Id,
                    owner.DES_LevelUO_10__c
                );

                ownerUos.add(owner.DES_LevelUO_10__c);
            }
        }

        if (ownerUos.isEmpty()) {
            return;
        }

        Map<String, Set<Id>> userIdsByUo =
            new Map<String, Set<Id>>();

        for (User userRecord : [
            SELECT Id, DES_LevelUO_10__c
            FROM User
            WHERE IsActive = true
            AND DES_LevelUO_10__c IN :ownerUos
        ]) {
            if (!userIdsByUo.containsKey(
                userRecord.DES_LevelUO_10__c
            )) {
                userIdsByUo.put(
                    userRecord.DES_LevelUO_10__c,
                    new Set<Id>()
                );
            }

            userIdsByUo
                .get(userRecord.DES_LevelUO_10__c)
                .add(userRecord.Id);
        }

        Map<String, DMT_TeamMember__c> existingMembers =
            new Map<String, DMT_TeamMember__c>();

        if (!opportunityIds.isEmpty()) {
            for (DMT_TeamMember__c member : [
                SELECT Id, Opportunity__c, User__c,
                       AccessLevel__c
                FROM DMT_TeamMember__c
                WHERE Opportunity__c IN :opportunityIds
            ]) {
                existingMembers.put(
                    buildKey(
                        member.Opportunity__c,
                        member.User__c
                    ),
                    member
                );
            }
        }

        if (!lineIds.isEmpty()) {
            for (DMT_TeamMember__c member : [
                SELECT Id, Line__c, User__c,
                       AccessLevel__c
                FROM DMT_TeamMember__c
                WHERE Line__c IN :lineIds
            ]) {
                existingMembers.put(
                    buildKey(member.Line__c, member.User__c),
                    member
                );
            }
        }

        List<DMT_TeamMember__c> membersToInsert =
            new List<DMT_TeamMember__c>();

        List<DMT_TeamMember__c> membersToUpdate =
            new List<DMT_TeamMember__c>();

        for (Id recordId : ownerByRecordId.keySet()) {
            Id ownerId = ownerByRecordId.get(recordId);
            String ownerUo = uoByOwnerId.get(ownerId);

            if (
                String.isBlank(ownerUo) ||
                !userIdsByUo.containsKey(ownerUo)
            ) {
                continue;
            }

            for (Id userId : userIdsByUo.get(ownerUo)) {
                // The Owner already has full access.
                if (userId == ownerId) {
                    continue;
                }

                String memberKey = buildKey(recordId, userId);

                DMT_TeamMember__c existingMember =
                    existingMembers.get(memberKey);

                if (existingMember == null) {
                    DMT_TeamMember__c newMember =
                        new DMT_TeamMember__c(
                            User__c = userId,
                            AccessLevel__c = EDIT_ACCESS
                        );

                    if (
                        recordId.getSObjectType() ==
                        Opportunity.SObjectType
                    ) {
                        newMember.Opportunity__c = recordId;
                    } else {
                        newMember.Line__c = recordId;
                    }

                    membersToInsert.add(newMember);
                    existingMembers.put(memberKey, newMember);
                } else if (
                    existingMember.AccessLevel__c == READ_ACCESS
                ) {
                    existingMember.AccessLevel__c = EDIT_ACCESS;
                    membersToUpdate.add(existingMember);
                }
            }
        }

        if (!membersToInsert.isEmpty()) {
            insert membersToInsert;
        }

        if (!membersToUpdate.isEmpty()) {
            update membersToUpdate;
        }
    }

    private static String buildKey(Id recordId, Id userId) {
        return String.valueOf(recordId) +
            ':' +
            String.valueOf(userId);
    }

    public class Request {

        @InvocableVariable(
            required=true
            label='Line or Opportunity Id'
        )
        public Id recordId;
    }
}