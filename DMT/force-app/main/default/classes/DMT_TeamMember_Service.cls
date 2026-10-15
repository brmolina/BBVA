/**
 * CIBGLOBALD-4374 - Single place for the DMT_TeamMember__c logic of the approval process.
 *
 * Before this class the same participant logic lived in several flows and Apex classes, each one
 * running its own queries and DML per Case / Task / record (and one Queueable per Case). Everything
 * here takes COLLECTIONS and runs a fixed number of queries and one DML per operation, whatever the
 * number of Cases, Tasks or records involved.
 *
 * Operations:
 *   addApproversForCases()        - approver group members of a Case owner queue become team members
 *                                   of the Case Line / Opportunity (replaces DMT_CreateTeamMemberCase.processCase).
 *   syncApprovalEditAccess()      - withdraws the approval-edit grants once a step is closed
 *                                   (replaces the team member updates of the flow DMT_After_Task_Trigger).
 *   assignParticipantsByOwnerUO() - owner UO level 10 users become Edit participants
 *                                   (replaces the body of DMT_AssignParticipantsByUO).
 *   build* / insert* / update* / delete* - the only DML helpers other classes should use for team members.
 *   scheduleCaseRequests()        - runs now when already async, otherwise hands the work to DMT_AsyncOrchestrator
 *                                   (replaces the Queueable DMT_CreateTeamMemberCase).
 */
public without sharing class DMT_TeamMember_Service {

    public static final String READ_ACCESS = 'Read';
    public static final String EDIT_ACCESS = 'Edit';
    public static final String ROLE_APPROVER = 'approver';
    public static final String ROLE_VALIDATOR = 'validator';
    private static final String GROUP_ID_PREFIX = '00G';
    private static final String PASSPORT_SANCTION = 'passport';

    /** One Case to process; sanctionEdit mirrors the old invocable input of the same name. */
    public class CaseRequest {
        public Id caseId;
        public Boolean sanctionEdit;

        public CaseRequest(Id caseId, Boolean sanctionEdit) {
            this.caseId = caseId;
            this.sanctionEdit = sanctionEdit == true;
        }
    }

    // ---------------------------------------------------------------------------------------------
    // Builders and DML helpers (the only place that should construct / save team members)
    // ---------------------------------------------------------------------------------------------

    public static DMT_TeamMember__c buildLineMember(Id userId, Id lineId, String name, String accessLevel, String teamRole, Boolean approvalEdit) {
        DMT_TeamMember__c member = new DMT_TeamMember__c();
        member.User__c = userId;
        member.Line__c = lineId;
        member.AccessLevel__c = accessLevel;
        if (String.isNotBlank(name)) {
            member.Name = name;
        }
        if (String.isNotBlank(teamRole)) {
            member.Team_Role__c = teamRole;
        }
        if (approvalEdit != null) {
            member.DMT_ApprovalEdit__c = approvalEdit;
        }
        return member;
    }

    public static DMT_TeamMember__c buildOpportunityMember(Id userId, Id opportunityId, String name, String accessLevel, String teamRole, Boolean approvalEdit) {
        DMT_TeamMember__c member = buildLineMember(userId, null, name, accessLevel, teamRole, approvalEdit);
        member.Opportunity__c = opportunityId;
        return member;
    }

    public static void insertMembers(List<DMT_TeamMember__c> members) {
        if (members != null && !members.isEmpty()) {
            insert members;
        }
    }

    public static void insertMembers(List<DMT_TeamMember__c> members, AccessLevel mode) {
        if (members != null && !members.isEmpty()) {
            Database.insert(members, mode);
        }
    }

    public static void updateMembers(List<DMT_TeamMember__c> members) {
        if (members != null && !members.isEmpty()) {
            update members;
        }
    }

    public static void deleteMembers(List<DMT_TeamMember__c> members) {
        if (members != null && !members.isEmpty()) {
            delete members;
        }
    }

    // ---------------------------------------------------------------------------------------------
    // Approval Case participants
    // ---------------------------------------------------------------------------------------------

    /**
     * @description Runs the Case participant logic now when the transaction is already asynchronous
     * (a nested Queueable is not allowed there), otherwise hands it to DMT_AsyncOrchestrator. The
     * caller is responsible for DMT_AsyncOrchestrator.flush() at the end of its trigger context.
     */
    public static void scheduleCaseRequests(List<CaseRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            return;
        }
        if (System.isQueueable() || System.isBatch() || System.isFuture()) {
            addApproversForCases(requests);
            return;
        }
        List<Id> withoutEdit = new List<Id>();
        List<Id> withEdit = new List<Id>();
        for (CaseRequest request : requests) {
            if (request == null || request.caseId == null) {
                continue;
            }
            if (request.sanctionEdit) {
                withEdit.add(request.caseId);
            } else {
                withoutEdit.add(request.caseId);
            }
        }
        if (!withoutEdit.isEmpty()) {
            DMT_AsyncOrchestrator.enqueue(new DMT_TeamMemberCasePayload(withoutEdit, false));
        }
        if (!withEdit.isEmpty()) {
            DMT_AsyncOrchestrator.enqueue(new DMT_TeamMemberCasePayload(withEdit, true));
        }
    }

    /**
     * @description Query cost is fixed: Cases, queues, approvers, approver members and existing team
     * members, 5 queries in total, plus one update and one insert, whatever the number of Cases.
     * Same rules as the former DMT_CreateTeamMemberCase.processCase:
     *  - only Cases owned by a queue whose developer name matches an approver group are processed;
     *  - Line participants and Opportunity participants are handled independently;
     *  - sanctionEdit grants Edit to Risk approvers on the Line and to Business approvers on the Opportunity;
     *  - existing participants are never duplicated.
     */
    public static void addApproversForCases(List<CaseRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            return;
        }
        try {
            processCases(requests);
        } catch (Exception e) {
            DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(
                e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),
                'DMT_TeamMember_Service', 'addApproversForCases', 'DMT', 'Case/TeamMember'
            ));
            DMT_AsyncOrchestrator.flush();
        }
    }

    private static void processCases(List<CaseRequest> requests) {
        Map<Id, Boolean> sanctionEditByCaseId = new Map<Id, Boolean>();
        for (CaseRequest request : requests) {
            if (request == null || request.caseId == null) {
                continue;
            }
            Boolean current = sanctionEditByCaseId.get(request.caseId);
            sanctionEditByCaseId.put(request.caseId, current == true || request.sanctionEdit);
        }
        if (sanctionEditByCaseId.isEmpty()) {
            return;
        }

        List<Case> cases = new List<Case>();
        Set<Id> groupIds = new Set<Id>();
        for (Case caseRecord : [
            SELECT Id, DMT_Line__c, opportunity_id__c, OwnerId, DMT_Passport_Sanction__c
            FROM Case
            WHERE Id IN :sanctionEditByCaseId.keySet()
            WITH USER_MODE
        ]) {
            if (caseRecord.DMT_Line__c == null && caseRecord.opportunity_id__c == null) {
                continue;
            }
            if (!String.valueOf(caseRecord.OwnerId).startsWith(GROUP_ID_PREFIX)) {
                continue;
            }
            cases.add(caseRecord);
            groupIds.add(caseRecord.OwnerId);
        }
        if (cases.isEmpty()) {
            return;
        }

        Map<Id, String> groupNameById = new Map<Id, String>();
        for (Group queue : [SELECT Id, DeveloperName FROM Group WHERE Id IN :groupIds WITH USER_MODE]) {
            groupNameById.put(queue.Id, queue.DeveloperName);
        }

        Map<String, DMT_Approver__c> approverByGroupName = new Map<String, DMT_Approver__c>();
        for (DMT_Approver__c approver : [
            SELECT Id, DMT_Group__c, DMT_ApproverType__r.Name
            FROM DMT_Approver__c
            WHERE DMT_Group__c IN :groupNameById.values()
            WITH USER_MODE
            ORDER BY Id
        ]) {
            if (!approverByGroupName.containsKey(approver.DMT_Group__c)) {
                approverByGroupName.put(approver.DMT_Group__c, approver);
            }
        }
        if (approverByGroupName.isEmpty()) {
            return;
        }

        Set<Id> approverIds = new Set<Id>();
        for (DMT_Approver__c approver : approverByGroupName.values()) {
            approverIds.add(approver.Id);
        }
        Map<Id, List<DMT_Approver_Member__c>> membersByApproverId = new Map<Id, List<DMT_Approver_Member__c>>();
        for (DMT_Approver_Member__c approverMember : [
            SELECT Id, DMT_Approver__c, DMT_User__c, DMT_User__r.Name
            FROM DMT_Approver_Member__c
            WHERE DMT_Approver__c IN :approverIds
            AND DMT_User__r.IsActive = true
            WITH USER_MODE
        ]) {
            if (!membersByApproverId.containsKey(approverMember.DMT_Approver__c)) {
                membersByApproverId.put(approverMember.DMT_Approver__c, new List<DMT_Approver_Member__c>());
            }
            membersByApproverId.get(approverMember.DMT_Approver__c).add(approverMember);
        }

        Set<Id> lineIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        for (Case caseRecord : cases) {
            if (caseRecord.DMT_Line__c != null) {
                lineIds.add(caseRecord.DMT_Line__c);
            }
            if (caseRecord.opportunity_id__c != null) {
                opportunityIds.add(caseRecord.opportunity_id__c);
            }
        }

        // 'contextId_userId' -> existing participant, for Lines and for Opportunities in one query.
        Map<String, DMT_TeamMember__c> existingByKey = new Map<String, DMT_TeamMember__c>();
        for (DMT_TeamMember__c member : [
            SELECT Id, User__c, AccessLevel__c, Team_Role__c, DMT_ApprovalEdit__c, Line__c, Opportunity__c
            FROM DMT_TeamMember__c
            WHERE Line__c IN :lineIds OR Opportunity__c IN :opportunityIds
            WITH USER_MODE
        ]) {
            if (member.Line__c != null) {
                existingByKey.put(memberKey(member.Line__c, member.User__c), member);
            }
            if (member.Opportunity__c != null) {
                existingByKey.put(memberKey(member.Opportunity__c, member.User__c), member);
            }
        }

        Map<Id, DMT_TeamMember__c> membersToUpdate = new Map<Id, DMT_TeamMember__c>();
        List<DMT_TeamMember__c> membersToInsert = new List<DMT_TeamMember__c>();
        Set<String> plannedKeys = new Set<String>();

        for (Case caseRecord : cases) {
            DMT_Approver__c approver = approverByGroupName.get(groupNameById.get(caseRecord.OwnerId));
            if (approver == null) {
                continue;
            }
            List<DMT_Approver_Member__c> approverMembers = membersByApproverId.get(approver.Id);
            if (approverMembers == null || approverMembers.isEmpty()) {
                continue;
            }

            Boolean sanctionEdit = sanctionEditByCaseId.get(caseRecord.Id) == true;
            String approverType = approver.DMT_ApproverType__r?.Name;
            Boolean isRisk = approverType == DMT_Constants.APPROVER_TYPE_RISK;
            Boolean isBusiness = approverType == DMT_Constants.APPROVER_TYPE_BUSINESS;
            String teamRole = caseRecord.DMT_Passport_Sanction__c == PASSPORT_SANCTION ? ROLE_VALIDATOR : ROLE_APPROVER;

            if (sanctionEdit) {
                for (DMT_Approver_Member__c approverMember : approverMembers) {
                    if (caseRecord.DMT_Line__c != null) {
                        DMT_TeamMember__c existingOnLine = existingByKey.get(memberKey(caseRecord.DMT_Line__c, approverMember.DMT_User__c));
                        if (existingOnLine != null) {
                            existingOnLine.AccessLevel__c = isRisk ? EDIT_ACCESS : READ_ACCESS;
                            existingOnLine.DMT_ApprovalEdit__c = isRisk;
                            membersToUpdate.put(existingOnLine.Id, existingOnLine);
                        }
                    }
                    if (caseRecord.opportunity_id__c != null) {
                        DMT_TeamMember__c existingOnOpportunity = existingByKey.get(memberKey(caseRecord.opportunity_id__c, approverMember.DMT_User__c));
                        if (existingOnOpportunity != null) {
                            existingOnOpportunity.AccessLevel__c = isBusiness ? EDIT_ACCESS : READ_ACCESS;
                            existingOnOpportunity.DMT_ApprovalEdit__c = isBusiness;
                            membersToUpdate.put(existingOnOpportunity.Id, existingOnOpportunity);
                        }
                    }
                }
            }

            for (DMT_Approver_Member__c approverMember : approverMembers) {
                Id userId = approverMember.DMT_User__c;
                String userName = approverMember.DMT_User__r.Name;

                if (caseRecord.DMT_Line__c != null) {
                    String lineKey = memberKey(caseRecord.DMT_Line__c, userId);
                    if (!existingByKey.containsKey(lineKey) && plannedKeys.add(lineKey)) {
                        membersToInsert.add(buildLineMember(
                            userId, caseRecord.DMT_Line__c, userName,
                            sanctionEdit && isRisk ? EDIT_ACCESS : READ_ACCESS, teamRole, sanctionEdit
                        ));
                    }
                }
                if (caseRecord.opportunity_id__c != null) {
                    String opportunityKey = memberKey(caseRecord.opportunity_id__c, userId);
                    if (!existingByKey.containsKey(opportunityKey) && plannedKeys.add(opportunityKey)) {
                        membersToInsert.add(buildOpportunityMember(
                            userId, caseRecord.opportunity_id__c, userName,
                            sanctionEdit && isBusiness ? EDIT_ACCESS : READ_ACCESS, teamRole, sanctionEdit
                        ));
                    }
                }
            }
        }

        updateMembers(membersToUpdate.values());
        insertMembers(membersToInsert);
    }

    // ---------------------------------------------------------------------------------------------
    // Approval-edit grants of closed steps
    // ---------------------------------------------------------------------------------------------

    /**
     * @description When an approval step is closed the edit grants it opened are withdrawn:
     *  - Line participants flagged DMT_ApprovalEdit__c go back to Read;
     *  - Opportunity approvers flagged DMT_ApprovalEdit__c go back to Read;
     *  - Opportunity participants that are not approvers lose DMT_ApprovalEdit__c.
     * One query and one update for all the Lines and Opportunities received.
     */
    public static void syncApprovalEditAccess(Set<Id> lineIds, Set<Id> opportunityIds) {
        Set<Id> lines = lineIds == null ? new Set<Id>() : lineIds;
        Set<Id> opportunities = opportunityIds == null ? new Set<Id>() : opportunityIds;
        if (lines.isEmpty() && opportunities.isEmpty()) {
            return;
        }

        Map<Id, DMT_TeamMember__c> membersToUpdate = new Map<Id, DMT_TeamMember__c>();
        for (DMT_TeamMember__c member : [
            SELECT Id, AccessLevel__c, Team_Role__c, DMT_ApprovalEdit__c, Line__c, Opportunity__c
            FROM DMT_TeamMember__c
            WHERE DMT_ApprovalEdit__c = true
            AND (Line__c IN :lines OR Opportunity__c IN :opportunities)
        ]) {
            if (member.Line__c != null && lines.contains(member.Line__c)) {
                member.AccessLevel__c = READ_ACCESS;
                membersToUpdate.put(member.Id, member);
            }
            if (member.Opportunity__c != null && opportunities.contains(member.Opportunity__c)) {
                if (member.Team_Role__c == ROLE_APPROVER) {
                    member.AccessLevel__c = READ_ACCESS;
                } else {
                    member.DMT_ApprovalEdit__c = false;
                }
                membersToUpdate.put(member.Id, member);
            }
        }
        updateMembers(membersToUpdate.values());
    }

    // ---------------------------------------------------------------------------------------------
    // Participants by owner UO
    // ---------------------------------------------------------------------------------------------

    /**
     * @description Active users sharing the owner's UO level 10 become Edit participants of the
     * Opportunities / Lines received (moved here from DMT_AssignParticipantsByUO, same rules).
     */
    public static void assignParticipantsByOwnerUO(Set<Id> opportunityIds, Set<Id> lineIds) {
        Set<Id> opportunities = opportunityIds == null ? new Set<Id>() : opportunityIds;
        Set<Id> lines = lineIds == null ? new Set<Id>() : lineIds;
        if (opportunities.isEmpty() && lines.isEmpty()) {
            return;
        }

        Map<Id, Id> ownerByRecordId = new Map<Id, Id>();
        if (!opportunities.isEmpty()) {
            for (Opportunity opportunityRecord : [SELECT Id, OwnerId FROM Opportunity WHERE Id IN :opportunities]) {
                ownerByRecordId.put(opportunityRecord.Id, opportunityRecord.OwnerId);
            }
        }
        if (!lines.isEmpty()) {
            for (DMT_Line__c lineRecord : [SELECT Id, OwnerId FROM DMT_Line__c WHERE Id IN :lines]) {
                ownerByRecordId.put(lineRecord.Id, lineRecord.OwnerId);
            }
        }

        Set<Id> ownerIds = new Set<Id>(ownerByRecordId.values());
        Map<Id, String> uoByOwnerId = new Map<Id, String>();
        Set<String> ownerUos = new Set<String>();
        for (User owner : [SELECT Id, DES_LevelUO_10__c FROM User WHERE Id IN :ownerIds]) {
            if (String.isNotBlank(owner.DES_LevelUO_10__c)) {
                uoByOwnerId.put(owner.Id, owner.DES_LevelUO_10__c);
                ownerUos.add(owner.DES_LevelUO_10__c);
            }
        }
        if (ownerUos.isEmpty()) {
            return;
        }

        Map<String, Set<Id>> userIdsByUo = new Map<String, Set<Id>>();
        for (User userRecord : [
            SELECT Id, DES_LevelUO_10__c
            FROM User
            WHERE IsActive = true
            AND DES_LevelUO_10__c IN :ownerUos
        ]) {
            if (!userIdsByUo.containsKey(userRecord.DES_LevelUO_10__c)) {
                userIdsByUo.put(userRecord.DES_LevelUO_10__c, new Set<Id>());
            }
            userIdsByUo.get(userRecord.DES_LevelUO_10__c).add(userRecord.Id);
        }

        Map<String, DMT_TeamMember__c> existingMembers = new Map<String, DMT_TeamMember__c>();
        if (!opportunities.isEmpty()) {
            for (DMT_TeamMember__c member : [
                SELECT Id, Opportunity__c, User__c, AccessLevel__c
                FROM DMT_TeamMember__c
                WHERE Opportunity__c IN :opportunities
            ]) {
                existingMembers.put(memberKey(member.Opportunity__c, member.User__c), member);
            }
        }
        if (!lines.isEmpty()) {
            for (DMT_TeamMember__c member : [
                SELECT Id, Line__c, User__c, AccessLevel__c
                FROM DMT_TeamMember__c
                WHERE Line__c IN :lines
            ]) {
                existingMembers.put(memberKey(member.Line__c, member.User__c), member);
            }
        }

        List<DMT_TeamMember__c> membersToInsert = new List<DMT_TeamMember__c>();
        List<DMT_TeamMember__c> membersToUpdate = new List<DMT_TeamMember__c>();

        for (Id recordId : ownerByRecordId.keySet()) {
            Id ownerId = ownerByRecordId.get(recordId);
            String ownerUo = uoByOwnerId.get(ownerId);
            if (String.isBlank(ownerUo) || !userIdsByUo.containsKey(ownerUo)) {
                continue;
            }
            for (Id userId : userIdsByUo.get(ownerUo)) {
                // The Owner already has full access.
                if (userId == ownerId) {
                    continue;
                }
                String key = memberKey(recordId, userId);
                DMT_TeamMember__c existingMember = existingMembers.get(key);
                if (existingMember == null) {
                    DMT_TeamMember__c newMember = recordId.getSObjectType() == Opportunity.SObjectType
                        ? buildOpportunityMember(userId, recordId, null, EDIT_ACCESS, null, null)
                        : buildLineMember(userId, recordId, null, EDIT_ACCESS, null, null);
                    membersToInsert.add(newMember);
                    existingMembers.put(key, newMember);
                } else if (existingMember.AccessLevel__c == READ_ACCESS) {
                    existingMember.AccessLevel__c = EDIT_ACCESS;
                    membersToUpdate.add(existingMember);
                }
            }
        }

        insertMembers(membersToInsert);
        updateMembers(membersToUpdate);
    }

    private static String memberKey(Id contextId, Id userId) {
        return String.valueOf(contextId) + '_' + String.valueOf(userId);
    }
}
